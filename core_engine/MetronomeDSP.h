#pragma once
#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <vector>
#include "beat_tracker/TempoMap.h"

struct BeatEvent {
    uint32_t offset;
    bool     accent;
    bool     isBeat;   // true = beat principale, false = suddivisione
};

// === Bug 2.b — SPIA passiva: record per-beat dell'asse ACCENTO (L1/DSP). ===
// POD: scritto lock-free dal thread audio (processBuffer), letto da thread
// non-RT (drainDiag). NB: _sectionBeatCounter (asse CONTATORE) è stato
// Swift/L3, NON è qui — si unisce a questi record al flush, per absSample.
struct MetronomeDiagRecord {
    uint64_t absSample;            // _absoluteSamplePosition + i del beat emesso
    double   exactNextBeatSample;  // snapshot al beat (pre-incremento += spb)
    uint32_t currentBeatInBar;     // indice accento di QUESTO beat (pre-incremento)
    uint32_t beatsPerBar;          // metro corrente (post eventuale swap seamless)
    uint32_t isDownbeat;           // 1 se currentBeatInBar==0 al beat
    uint32_t bpbSwapFired;         // 1 se lo swap seamless BPB è scattato a questo beat
    uint32_t seq;                  // 1-based ↔ beatTick L3 (join/ordering)
};

class MetronomeDSP {
public:
    MetronomeDSP(double sampleRate, double bpm);

    void setBPM(double bpm);
    void setSampleRate(double sr);
    void setBeatsPerBar(uint32_t beatsPerBar);
    void setAccentPattern(const uint8_t* pattern, uint32_t length);
    // multiplier: 1=nessuna, 2=crome, 3=terzine, 4=semicrome
    // swingRatio: [0.5, 1.0[ — 0.5=dritto, >0.5=swing (solo con multiplier==2)
    void setSubdivision(uint8_t multiplier, double swingRatio = 0.5);
    // Schedula cambio BPM al prossimo downbeat (thread-safe, non-RT).
    void scheduleBPMChange(double newBPM);
    // Cancella un cambio BPM schedulato non ancora scattato (thread-safe, non-RT).
    // No-op se nessun cambio è pendente. Simmetrica a scheduleBPMChange.
    void cancelPendingBPM();

    // === B7-A3 — Follower adattivo (piano ratificato referee 03/07) ===
    // Setter non-RT (audioQueue). Rifiuta: mappa non valida · sourceSampleRate
    // != _sampleRate (contratto dominio-clock ② di TempoMap.h: in RT nessuna
    // conversione, i domini devono coincidere numericamente) · flip a meno di
    // 2 buffer RT dall'ultimo riuscito (guardia sul contatore RT
    // _processedBufferCount, NON wall-clock: l'orologio non sa se il thread
    // RT ha davvero girato — media-services reset/backgrounding, §6; il
    // contatore sì). Su successo: copia nello slot INATTIVO + flip atomico +
    // adaptive ON + cancelPendingBPM() (anti-stantio, ratifica 03/07).
    bool setTempoMap(const TempoMap& map);

    // non-RT. Adaptive OFF + cancelPendingBPM() (ri-armo pulito del path
    // fixed). _bpm resta all'ultimo valore derivato dalla mappa finché
    // UI/setlist non impostano un nuovo tempo.
    void clearTempoMap();

    bool isAdaptiveActive() const {
        return _adaptiveActive.load(std::memory_order_acquire);
    }

    // Strada A — Schedula cambio BeatsPerBar al prossimo downbeat
    // (thread-safe, non-RT). Estende il pattern di scheduleBPMChange
    // a BPB per transizioni di sezione seamless. NON resetta
    // _currentBeatInBar (lo gestisce il modulo % _beatsPerBar al downbeat).
    // NON scrive accent pattern di default.
    void scheduleBeatsPerBarChange(uint32_t bpb);

    // Strada A — Cancella un cambio BPB schedulato non ancora scattato
    // (thread-safe, non-RT). No-op se nessun cambio è pendente.
    // Simmetrica a cancelPendingBPM.
    void cancelPendingBPB();

    // Strada A — Schedula cambio accent pattern al prossimo inizio buffer
    // (thread-safe, non-RT). Variante di setAccentPattern senza il check
    // length != _beatsPerBar — al pre-load _beatsPerBar è ancora OLD
    // (es. BPB cambia 4→3 alla transizione: pattern nuovo è length 3,
    // _beatsPerBar è ancora 4).
    void scheduleAccentPatternChange(const uint8_t* pattern, uint32_t length);

    // === ATOM C — Schedula cambio subdivision/swing al prossimo downbeat ===
    // (thread-safe, non-RT). Estende il pattern di scheduleBeatsPerBarChange
    // alla suddivisione: transizioni di sezione seamless sample-accurate
    // (il setter secco setSubdivision applica a inizio buffer = lag ~1
    // buffer al confine; questa si arma e scatta a _currentBeatInBar == 0).
    // Canale DISTINTO dal setter secco (_subdivScheduleDirty vs _subdivDirty):
    // il secco resta per prepare/DebugView (audio fermo o cambio immediato).
    // Stessa validazione di setSubdivision (multiplier 1-4, swing [0.5,1.0[,
    // swing→0.5 se multiplier≠2).
    void scheduleSubdivisionChange(uint8_t multiplier, double swingRatio);

    // ATOM C — Cancella un cambio subdivision schedulato non ancora scattato
    // (thread-safe, non-RT). No-op se nessun cambio è pendente. Simmetrica a
    // cancelPendingBPB: spegne SOLO il flag dirty, i _pendingScheduled* non
    // vengono toccati (mai letti finché il dirty è false). OBBLIGATORIA allo
    // stop (stop-mid-transizione: senza, il pending della transizione morta
    // scatterebbe al primo downbeat del replay — B1 piano C v2).
    void cancelPendingSubdivision();

    void setAbsolutePositionForTesting(uint64_t pos);

    // --- Fase VOL: volume click + mute (chiamare solo da audioQueue) ---
    void setAccentVolume(double v);   // [0.0, 1.0]
    void setBeatVolume(double v);     // [0.0, 1.0]
    void setSubdivVolume(double v);   // [0.0, 1.0]
    void setMuted(bool muted);        // mute hard

    // Fresh play: fissa _startAbsoluteBeat e azzera _currentBeatInBar.
    // Chiamare SOLO su start() senza resume.
    void resetForStart(double startBeat);

    // Resume (post-interruzione/recovery): aggiorna posizione senza toccare
    // _startAbsoluteBeat. NB (Bug 2.b): il Link phase sync NON usa più questa
    // funzione — usa setBeatPositionTimeOnly. Questa resta per il solo Resume.
    void setBeatPosition(double beatPosition);

    // Bug 2.b — Variante solo-temporale: allinea la timeline a campioni SENZA
    // ri-derivare _currentBeatInBar (governato dal contatore di sezione). Usata da
    // Link sync_phase per non sfasare l'accento al cambio BPB in peer.
    void setBeatPositionTimeOnly(double beatPosition);

    // A424/A432 — rinomina il battito in attesa: la sua posizione nella battuta diventa
    // beatInBar (modulo i battiti per battuta). Non tocca la linea a campioni
    // (_absoluteSamplePosition), il battito in attesa (_exactNextBeatSample, anche
    // quando la correzione lo ha messo a «subito»), la sua identità (_pendingBeatIdx),
    // l'origine (_startAbsoluteBeat): il battito in attesa esce allo stesso campione.
    // I cambi armati (metro, tempo, suddivisione) non li scrive, ma sposta il battito a
    // cui scattano: processBuffer apre lo scambio al battito con etichetta 0, quindi con
    // un cambio armato lo scambio scatta sul nuovo «uno» e i click DOPO cambiano campione
    // (un tempo armato cambia il passo dei battiti da lì; una suddivisione armata parte da
    // lì). Col SOLO metro armato i click dopo non cambiano campione: cambiano gli accenti,
    // perché lo scambio del metro (processBuffer, «_beatsPerBar = _pendingBeatsPerBar») tocca
    // solo il modulo delle etichette (A432 parte 2b). Chi non lo vuole annulla i cambi armati
    // e usa i setter immediati prima della rinomina (A424 par. 2.2 a). Chiamare SOLO su
    // audioQueue, prima di processBuffer.
    void renamePendingBeat(uint32_t beatInBar);

    double getStartAbsoluteBeat() const { return _startAbsoluteBeat; }
    uint32_t getCurrentBeatInBar() const { return _currentBeatInBar; }

    // A431/A432 — il battito che processBuffer suonerà per primo (P26, R1): la sua identità
    // sulla linea dei battiti del DSP, origine + indice. Sola lettura, chiamare SOLO su audioQueue.
    double getPendingBeat() const { return _startAbsoluteBeat + (double)_pendingBeatIdx; }
    // Campioni fra l'inizio del prossimo processBuffer e il battito in attesa: 0 = al primo
    // campione (il battito messo a «subito»). La stessa regola d'arrotondamento e lo stesso
    // confronto con cui processBuffer fa uscire il battito (roundedNextBeat == currentAbsolute).
    // Il valore non è mai negativo (A432 parti 2a e 2b), dentro questo dominio: un tempo finito
    // maggiore di zero e un battito finito maggiore o uguale a zero. Il dominio lo tengono le
    // guardie: setBPM e scheduleBPMChange ignorano un tempo fuori dominio; resetForStart,
    // setBeatPosition e setBeatPositionTimeOnly ignorano un battito fuori dominio; la chiamata
    // rifiutata non scrive nessun campo. Il costruttore e setSampleRate NON hanno guardia:
    // vogliono un tempo e una frequenza finiti maggiori di zero (l'app crea il DSP a 120 e
    // sceglie la frequenza con SampleRateDecision). Dentro il dominio ogni scrittura del
    // battito in attesa lo lascia col campione arrotondato sul cursore o dopo:
    // - il costruttore: campione e cursore a 0;
    // - resetForStart: il cursore è l'arrotondamento del campione;
    // - setAbsolutePositionForTesting: il primo battito della griglia non prima del cursore;
    // - setBPM e setBeatPosition: lo portano al cursore se il campione ARROTONDATO finirebbe
    //   prima (il confronto è sull'arrotondato, lo stesso di processBuffer);
    // - setBeatPositionTimeOnly: il suo «subito» confronta il campione ESATTO (non
    //   l'arrotondato) e lo porta al cursore: più largo, mai meno;
    // - processBuffer: il battito avanza solo quando esce, e a fine buffer il suo campione
    //   arrotondato sta sul cursore nuovo o dopo.
    // Un valore < bufferSize vuol dire che il battito esce nel prossimo processBuffer, a quell'offset;
    // ma non che un click suona in quella chiamata: nel drenaggio di fine sezione Swift non
    // chiama processBuffer (ios_app/QBeats/AudioEngine.swift, `_sectionEndPending`), e col
    // click muto il battito avanza senza evento. Sola lettura, chiamare SOLO su audioQueue.
    int64_t getPendingSamplesAhead() const {
        return (int64_t)(std::round(_exactNextBeatSample) - (double)_absoluteSamplePosition);
    }

    // === Bug 2.b — SPIA passiva (diagnostica, OFF di default) ===
    // Abilita/disabilita la cattura per-beat nel path audio (thread-safe, non-RT).
    // Su enable ri-azzera il seq (chiamare PRE-play, thread audio idle): il 1°
    // beat avrà seq=1 (++_diagSeq) = beatTickCounter=1 (L3) → join 1:1 per ordinale.
    void setDiagEnabled(bool on) {
        if (on) { _diagSeq = 0; }
        // release: pubblica _diagSeq=0 PRIMA che il thread audio veda l'enable
        // (load-acquire nel cancello) → happens-before, primo seq allineato.
        _diagEnabled.store(on, std::memory_order_release);
    }
    // Consumer NON-RT: copia fino a maxOut record dal ring, avanza readIdx.
    // Ritorna il numero copiato. Chiamare SOLO da thread non audio.
    size_t drainDiag(MetronomeDiagRecord* out, size_t maxOut);
    // Record persi per overflow del ring (monotono; 0 = nessuna perdita).
    uint64_t diagDropped() const { return _diagDropped.load(std::memory_order_relaxed); }

    std::vector<BeatEvent> processBuffer(uint32_t bufferSize);

private:
    double   _sampleRate;
    double   _bpm;
    uint32_t _beatsPerBar;
    uint32_t _currentBeatInBar;
    // A431/A432 — l'indice del battito in attesa rispetto all'origine (_startAbsoluteBeat): il battito
    // che processBuffer suonerà per primo è _startAbsoluteBeat + _pendingBeatIdx. Lo scrivono solo:
    // il costruttore e resetForStart (0), setBeatPosition (nextRelativeIdx), setBeatPositionTimeOnly
    // (pendingRelIdx, anche col battito messo a «subito»), setAbsolutePositionForTesting (nextBeatIdx)
    // e processBuffer (+1 a ogni battito, accanto a _exactNextBeatSample += spb). setBPM (riscala la
    // distanza e tiene l'identità), setBeatsPerBar e renamePendingBeat non lo toccano.
    int64_t  _pendingBeatIdx;
    uint64_t _absoluteSamplePosition;
    double   _exactNextBeatSample;
    // Phase origin: fissato al momento del Play originale.
    // setBeatPosition calcola _currentBeatInBar come
    // floor(nextBeatIndex - _startAbsoluteBeat) % _beatsPerBar.
    double   _startAbsoluteBeat;

    // Double buffer accent pattern (thread safety: RT legge, audioQueue scrive)
    uint8_t           _accentPattern[16];
    uint8_t           _pendingPattern[16];
    uint8_t           _pendingPatternLength;
    std::atomic<bool> _patternDirty;

    // Subdivision state (RT thread legge, audioQueue scrive via double-buffer)
    uint8_t  _subdivisionMultiplier;   // 1=nessuna, 2=crome, 3=terzine, 4=semicrome
    double   _swingRatio;              // 0.5=dritto (solo con _subdivisionMultiplier==2)
    double   _exactNextSubdivSample;   // tracker parallelo a _exactNextBeatSample
    bool     _swingPhase;              // false=long, true=short (solo swing)

    uint8_t           _pendingMultiplier;
    double            _pendingSwingRatio;
    std::atomic<bool> _subdivDirty;

    // Scheduled BPM change — applied at next downbeat (_currentBeatInBar == 0)
    double            _pendingBPM;
    std::atomic<bool> _bpmChangeDirty;

    // Strada A — Scheduled BPB change — applied at next downbeat
    // (_currentBeatInBar == 0). Ordine exchange in processBuffer:
    // BPB prima di BPM, ciascuno precede il proprio consumer
    // (BPB precede il modulo % _beatsPerBar, BPM precede += spb).
    uint32_t          _pendingBeatsPerBar;
    std::atomic<bool> _bpbChangeDirty;

    // ATOM C — Scheduled subdivision change — applied at next downbeat
    // (_currentBeatInBar == 0), PRIMA del ri-arm del tracker suddivisioni
    // (che così riparte col multiplier nuovo). Canale distinto dal setter
    // secco (_pendingMultiplier/_subdivDirty, applicato a inizio buffer).
    uint8_t           _pendingScheduledMultiplier;
    double            _pendingScheduledSwing;
    std::atomic<bool> _subdivScheduleDirty;

    // === B7-A3 — Follower adattivo: double-buffer mappa PREALLOCATO ===
    // 2 slot a capacità fissa (~128 KB l'uno, membri fissi allocati col
    // costruttore off-audio-thread). Il thread lento scrive SOLO lo slot
    // inattivo e poi flippa l'indice (release); il thread RT legge indice
    // (acquire) + punti una volta per buffer: mai alloc/free/lock nel render
    // path (Costituzione §4).
    struct MapSlot {
        TempoPoint points[TempoMap::kMaxPoints];
        size_t     count = 0;
    };
    MapSlot               _mapSlots[2];
    std::atomic<uint32_t> _activeMapSlot { 0 };
    std::atomic<bool>     _adaptiveActive { false };

    // Contatore buffer RT (monotono, incremento relaxed a fine processBuffer,
    // stesso pattern di _diagWrite): la guardia anti-flip di setTempoMap lo
    // legge dal thread lento per sapere se il RT ha DAVVERO girato tra due
    // flip — un wall-clock non lo saprebbe.
    std::atomic<uint64_t> _processedBufferCount { 0 };
    uint64_t              _lastFlipBufferCount = 0;  // solo thread setter (non-RT)
    bool                  _hasEverFlipped      = false;  // idem; al 1° flip la guardia
                                                         // non si applica (nessuno slot
                                                         // mai letto in RT prima)

    // --- Fase VOL: volume click — double-buffer + atomic dirty ---
    std::atomic<bool> _volumeDirty { false };
    double _pendingAccentVolume { 1.0 };
    double _pendingBeatVolume   { 0.8 };
    double _pendingSubdivVolume { 0.4 };
    bool   _pendingMuted        { false };

    // live (RT thread only):
    double _accentVolume { 1.0 };
    double _beatVolume   { 0.8 };
    double _subdivVolume { 0.4 };
    bool   _muted        { false };

    // === Bug 2.b — SPIA passiva: ring-buffer lock-free SPSC ===
    // Producer = thread audio (processBuffer). Consumer = thread non-RT (drainDiag).
    // Pre-allocato (membro fisso, allocato col costruttore off-audio-thread).
    // Nessun malloc/lock/os_log nel path audio. Cap potenza di 2 → modulo via &.
    static constexpr size_t kDiagRingCap = 4096;   // ~34 min @120bpm prima di overflow (drop contato)
    MetronomeDiagRecord   _diagRing[kDiagRingCap];
    std::atomic<uint64_t> _diagWrite   { 0 };   // solo producer (thread audio)
    std::atomic<uint64_t> _diagRead    { 0 };   // solo consumer (thread non-RT)
    std::atomic<uint64_t> _diagDropped { 0 };   // overflow contati
    std::atomic<bool>     _diagEnabled { false };
    uint32_t              _diagSeq      { 0 };   // solo producer

    // Push wait-free dal thread audio. Ring pieno ⇒ conta il drop e ritorna
    // (mai bloccare il path audio). Nessun malloc/lock/os_log.
    inline void pushDiag(uint64_t absSample, double exactNextBeatSample,
                         uint32_t currentBeatInBar, uint32_t beatsPerBar,
                         bool bpbSwapFired) {
        const uint64_t w = _diagWrite.load(std::memory_order_relaxed);
        const uint64_t r = _diagRead.load(std::memory_order_acquire);
        if (w - r >= kDiagRingCap) {
            _diagDropped.fetch_add(1, std::memory_order_relaxed);
            return;
        }
        MetronomeDiagRecord& rec = _diagRing[w & (kDiagRingCap - 1)];
        rec.absSample           = absSample;
        rec.exactNextBeatSample = exactNextBeatSample;
        rec.currentBeatInBar    = currentBeatInBar;
        rec.beatsPerBar         = beatsPerBar;
        rec.isDownbeat          = (currentBeatInBar == 0u) ? 1u : 0u;
        rec.bpbSwapFired        = bpbSwapFired ? 1u : 0u;
        rec.seq                 = ++_diagSeq;   // 1-based ⇒ join 1:1 con beatTickCounter (L3)
        _diagWrite.store(w + 1, std::memory_order_release);
    }

    double subdivIntervalForPhase(double spb, bool phase) const;
};
