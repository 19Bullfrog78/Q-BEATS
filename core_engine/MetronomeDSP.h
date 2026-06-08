#pragma once
#include <atomic>
#include <cstdint>
#include <cstring>
#include <limits>
#include <vector>

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

    // Bug 2.b α — L2 fornisce la beat-position Link del downbeat di sezione.
    void setSectionAnchor(double linkBeat);

    double getStartAbsoluteBeat() const { return _startAbsoluteBeat; }
    uint32_t getCurrentBeatInBar() const { return _currentBeatInBar; }

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
    uint64_t _absoluteSamplePosition;
    double   _exactNextBeatSample;
    // Phase origin: fissato al momento del Play originale.
    // setBeatPosition calcola _currentBeatInBar come
    // floor(nextBeatIndex - _startAbsoluteBeat) % _beatsPerBar.
    double   _startAbsoluteBeat;
    // Bug 2.b α — àncora PER-SEZIONE: beat-position Link del downbeat di sezione,
    // alimentata da L2 (setSectionAnchor) al 1° beat di ogni sezione. L1 ne deriva
    // _currentBeatInBar in setBeatPositionTimeOnly. Lock-free (set 1x/sezione, read
    // per-buffer). _valid=false finché L2 non fornisce la 1ª àncora (free-run).
    std::atomic<double> _sectionAnchorBeat;
    std::atomic<bool>   _sectionAnchorValid;

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
