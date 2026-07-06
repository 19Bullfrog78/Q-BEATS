#include "MetronomeDSP.h"
#include <cmath>

MetronomeDSP::MetronomeDSP(double sampleRate, double bpm)
    : _sampleRate(sampleRate)
    , _bpm(bpm)
    , _beatsPerBar(4)
    , _currentBeatInBar(0)
    , _absoluteSamplePosition(0)
    , _exactNextBeatSample(0.0)
    , _startAbsoluteBeat(0.0)
    , _pendingPatternLength(4)
    , _patternDirty(false)
    , _subdivisionMultiplier(1)
    , _swingRatio(0.5)
    , _exactNextSubdivSample(std::numeric_limits<double>::max())
    , _swingPhase(false)
    , _pendingMultiplier(1)
    , _pendingSwingRatio(0.5)
    , _subdivDirty(false)
    , _pendingBPM(bpm)
    , _bpmChangeDirty(false)
    // Strada A — nuovi pending paralleli a _pendingBPM / _bpmChangeDirty.
    // _pendingBeatsPerBar(4) coerente con _beatsPerBar(4) di default
    // (il costruttore non ha parametro beatsPerBar, solo bpm).
    , _pendingBeatsPerBar(4)
    , _bpbChangeDirty(false)
    // ATOM C — pending schedulati subdivision, coerenti coi default
    // _subdivisionMultiplier(1) / _swingRatio(0.5).
    , _pendingScheduledMultiplier(1)
    , _pendingScheduledSwing(0.5)
    , _subdivScheduleDirty(false)
{
    std::memset(_accentPattern,  0, sizeof(_accentPattern));
    std::memset(_pendingPattern, 0, sizeof(_pendingPattern));
    _accentPattern[0]  = 1;
    _pendingPattern[0] = 1;
}

void MetronomeDSP::setBPM(double bpm) {
    // FIX-B hardening — il path IMMEDIATO (tempo-callback Link sul Follower,
    // AudioEngine:432) cambiava l'unità di misura del tempo senza ri-scalare
    // il mark pendente: la prima correzione successiva leggeva la distanza
    // al mark in unità vecchie (flip ±1 possibile = 1 click mangiato o
    // duplicato al cambio tempo). Qui la distanza, in campioni, viene
    // ri-scalata nella nuova durata di beat: l'IDENTITÀ di beat del mark è
    // preservata. Il path setlist (scheduleBPMChange → swap al downbeat in
    // processBuffer) era ed è sano. Il tracker suddivisioni si riallinea da
    // solo al fire/alla correzione successivi.
    if (bpm > 0.0 && _bpm > 0.0 && bpm != _bpm) {
        _exactNextBeatSample = (double)_absoluteSamplePosition
            + (_exactNextBeatSample - (double)_absoluteSamplePosition) * (_bpm / bpm);
    }
    _bpm = bpm;
}

void MetronomeDSP::setSampleRate(double sr) {
    _sampleRate = sr;
}

void MetronomeDSP::scheduleBPMChange(double newBPM) {
    _pendingBPM = newBPM;
    _bpmChangeDirty.store(true, std::memory_order_release);
}

void MetronomeDSP::cancelPendingBPM() {
    // Spegne il flag dirty. _pendingBPM non viene toccato: non sarà letto
    // finché _bpmChangeDirty è false (vedi processBuffer guard al downbeat).
    // memory_order_release per simmetria col writer di scheduleBPMChange,
    // accoppia col memory_order_acquire del reader in processBuffer.
    _bpmChangeDirty.store(false, std::memory_order_release);
}

// === B7-A3 — Follower adattivo: setter non-RT (audioQueue) ===
bool MetronomeDSP::setTempoMap(const TempoMap& map) {
    // Precondizione ② (contratto dominio-clock, TempoMap.h): il rate della
    // mappa DEVE coincidere col rate del DSP — in RT nessuna conversione,
    // i due assi devono essere numericamente lo stesso asse.
    if (!map.isValid()) return false;
    if (map.sourceSampleRate() != _sampleRate) return false;
    if (map.size() > TempoMap::kMaxPoints) return false;  // difensivo (già garantito da make)

    // Guardia anti-flip sul CONTATORE RT, non wall-clock: l'orologio non sa
    // se il thread RT ha davvero girato nel frattempo (media-services reset,
    // backgrounding — §6); il contatore incrementato da processBuffer sì.
    // Non applicabile al PRIMO flip: nessun "ultimo flip riuscito" da
    // proteggere, nessuno slot è mai stato letto in RT.
    const uint64_t processed = _processedBufferCount.load(std::memory_order_acquire);
    if (_hasEverFlipped && processed - _lastFlipBufferCount < 2) return false;

    // Copia nello slot INATTIVO (il RT legge solo l'attivo), poi flip con
    // release: chi acquisisce l'indice nuovo vede punti e count già scritti.
    const uint32_t inactive = 1u - _activeMapSlot.load(std::memory_order_relaxed);
    MapSlot& slot = _mapSlots[inactive];
    std::memcpy(slot.points, map.points().data(), map.size() * sizeof(TempoPoint));
    slot.count = map.size();
    _activeMapSlot.store(inactive, std::memory_order_release);
    _adaptiveActive.store(true, std::memory_order_release);
    _hasEverFlipped      = true;
    _lastFlipBufferCount = processed;

    // Anti-stantio (ratifica 03/07): un cambio BPM schedulato prima
    // dell'ingresso in adaptive non deve sopravvivere al modo — né sparare
    // durante (l'exchange al downbeat è gated) né al rientro in fixed.
    cancelPendingBPM();
    return true;
}

void MetronomeDSP::clearTempoMap() {
    _adaptiveActive.store(false, std::memory_order_release);
    // Ri-armo pulito del path fixed (ratifica 03/07): niente swap stantio al
    // primo downbeat dopo l'uscita. _bpm resta all'ultimo valore derivato
    // dalla mappa finché UI/setlist non impostano un nuovo tempo.
    cancelPendingBPM();
}

// Strada A — Schedula cambio BeatsPerBar al prossimo downbeat.
// Pattern parallelo a scheduleBPMChange. Il valore _pendingBeatsPerBar
// viene applicato a _beatsPerBar nell'exchange di processBuffer quando
// _currentBeatInBar == 0 (sample-accurate, race-free).
void MetronomeDSP::scheduleBeatsPerBarChange(uint32_t bpb) {
    _pendingBeatsPerBar = bpb;
    _bpbChangeDirty.store(true, std::memory_order_release);
}

// Strada A — Cancella cambio BPB schedulato non ancora scattato.
// _pendingBeatsPerBar non viene toccato: non sarà letto finché
// _bpbChangeDirty è false. Simmetrico a cancelPendingBPM.
void MetronomeDSP::cancelPendingBPB() {
    _bpbChangeDirty.store(false, std::memory_order_release);
}

// ATOM C — Schedula cambio subdivision/swing al prossimo downbeat.
// Pattern parallelo a scheduleBeatsPerBarChange; stessa validazione di
// setSubdivision (rifiuto fuori dominio; swing forzato a 0.5 se il
// multiplier non è 2 — lo swing esiste solo sulle crome).
void MetronomeDSP::scheduleSubdivisionChange(uint8_t multiplier, double swingRatio) {
    if (multiplier < 1 || multiplier > 4) return;
    if (swingRatio < 0.5 || swingRatio >= 1.0) return;
    _pendingScheduledMultiplier = multiplier;
    _pendingScheduledSwing      = (multiplier == 2) ? swingRatio : 0.5;
    _subdivScheduleDirty.store(true, std::memory_order_release);
}

// ATOM C — Cancella cambio subdivision schedulato non ancora scattato.
// I _pendingScheduled* non vengono toccati: non saranno letti finché
// _subdivScheduleDirty è false. Simmetrico a cancelPendingBPB.
// Chiamata INCONDIZIONATA allo stop (B1): se lo stop arriva tra l'armo
// (step d seamless) e il downbeat, il pending della transizione morta
// scatterebbe al primo downbeat del replay, sovrascrivendo il valore
// corretto del prepare (canale scheduled ≠ canale secco: il reload
// risana solo il secco).
void MetronomeDSP::cancelPendingSubdivision() {
    _subdivScheduleDirty.store(false, std::memory_order_release);
}

// Strada A — Schedula cambio accent pattern senza il check length
// != _beatsPerBar (necessario al pre-load quando _beatsPerBar è OLD).
// L'exchange a inizio buffer (in processBuffer) consuma _patternDirty
// e copia _pendingPattern in _accentPattern: tra inizio buffer e
// downbeat di transizione non esistono BeatEvent della sezione
// precedente da pubblicare, quindi nessun effetto udibile.
void MetronomeDSP::scheduleAccentPatternChange(const uint8_t* pattern, uint32_t length) {
    if (length == 0 || length > 16) return;
    std::memcpy(_pendingPattern, pattern, length);
    _pendingPatternLength = (uint8_t)length;
    _patternDirty.store(true, std::memory_order_release);
}

// --- Fase VOL: setter (chiamare solo da audioQueue, mai dal RT thread) ---

void MetronomeDSP::setAccentVolume(double v) {
    _pendingAccentVolume = v;
    _volumeDirty.store(true, std::memory_order_release);
}

void MetronomeDSP::setBeatVolume(double v) {
    _pendingBeatVolume = v;
    _volumeDirty.store(true, std::memory_order_release);
}

void MetronomeDSP::setSubdivVolume(double v) {
    _pendingSubdivVolume = v;
    _volumeDirty.store(true, std::memory_order_release);
}

void MetronomeDSP::setMuted(bool muted) {
    _pendingMuted = muted;
    _volumeDirty.store(true, std::memory_order_release);
}

void MetronomeDSP::setBeatsPerBar(uint32_t beatsPerBar) {
    _beatsPerBar      = beatsPerBar;
    _currentBeatInBar = 0;
    if (beatsPerBar > 0 && beatsPerBar <= 16) {
        std::memset(_pendingPattern, 0, beatsPerBar);
        _pendingPattern[0]    = 1;
        _pendingPatternLength = (uint8_t)beatsPerBar;
        _patternDirty.store(true, std::memory_order_release);
    }
}

void MetronomeDSP::setSubdivision(uint8_t multiplier, double swingRatio) {
    if (multiplier < 1 || multiplier > 4) return;
    if (swingRatio < 0.5 || swingRatio >= 1.0) return;
    _pendingMultiplier  = multiplier;
    _pendingSwingRatio  = (multiplier == 2) ? swingRatio : 0.5;
    _subdivDirty.store(true, std::memory_order_release);
}

double MetronomeDSP::subdivIntervalForPhase(double spb, bool phase) const {
    if (_subdivisionMultiplier == 2 && _swingRatio > 0.5) {
        return phase ? (1.0 - _swingRatio) * spb : _swingRatio * spb;
    }
    return spb / _subdivisionMultiplier;
}

void MetronomeDSP::setAccentPattern(const uint8_t* pattern, uint32_t length) {
    if (length == 0 || length != _beatsPerBar || length > 16) return;
    std::memcpy(_pendingPattern, pattern, length);
    _pendingPatternLength = (uint8_t)length;
    _patternDirty.store(true, std::memory_order_release);
}

void MetronomeDSP::setAbsolutePositionForTesting(uint64_t pos) {
    _startAbsoluteBeat      = 0.0;
    _absoluteSamplePosition = pos;
    _currentBeatInBar       = 0;
    double spb              = (_sampleRate * 60.0) / _bpm;
    double exactBeats       = (double)pos / spb;
    uint64_t nextBeatIdx    = (uint64_t)std::ceil(exactBeats - 1e-9);
    _exactNextBeatSample    = (double)nextBeatIdx * spb;
}

void MetronomeDSP::resetForStart(double startBeat) {
    // Fresh play: fissa la phase origin e azzera il contatore di battuta.
    // Primo click al sample corrispondente a _startAbsoluteBeat (downbeat).
    _startAbsoluteBeat      = startBeat;
    double spb              = (_sampleRate * 60.0) / _bpm;
    _absoluteSamplePosition = (uint64_t)std::round(startBeat * spb);
    _currentBeatInBar       = 0;
    _exactNextBeatSample    = startBeat * spb;
    _swingPhase = false;
    // B7-A3 — nota di correttezza (ratifica 03/07): con startBeat=0 la
    // giustificazione "0·spb=0" copre _absoluteSamplePosition e
    // _exactNextBeatSample, NON questo ramo: _exactNextSubdivSample resta
    // proporzionale allo spb del _bpm corrente (potenzialmente vecchio in
    // adaptive, dove _bpm arriva dalla mappa solo al primo buffer-top). È
    // comunque sicuro: con startBeat=0 il primo sample processato È il
    // downbeat (_exactNextBeatSample=0 coincide con currentAbsolute=0 a i=0)
    // → isBeatSample vero al primo giro → isSubdivSample forzato false dalla
    // guardia "&& !isBeatSample" (processBuffer) → questo tracker viene
    // riscritto al beat con lo spb GIÀ aggiornato dal follower, prima che
    // una sottodivisione possa mai uscire col valore vecchio.
    if (_subdivisionMultiplier > 1) {
        _exactNextSubdivSample = _exactNextBeatSample + subdivIntervalForPhase(spb, false);
    } else {
        _exactNextSubdivSample = std::numeric_limits<double>::max();
    }
}

void MetronomeDSP::setBeatPosition(double beatPosition) {
    // Resume (post-interruzione/recovery): NON tocca _startAbsoluteBeat.
    // NB (Bug 2.b): il Link phase sync NON passa più di qui — usa
    // setBeatPositionTimeOnly. Questa resta per il solo Resume.
    // Griglia coerente relativa a _startAbsoluteBeat per entrambi
    // _currentBeatInBar e _exactNextBeatSample.
    double spb              = (_sampleRate * 60.0) / _bpm;
    _absoluteSamplePosition = (uint64_t)std::round(beatPosition * spb);
    double epsilon          = 0.5 / _sampleRate * (_bpm / 60.0);

    // Indice del prossimo beat, relativo a _startAbsoluteBeat
    double relative         = beatPosition - _startAbsoluteBeat;
    double nextRelativeIdx  = std::ceil(relative - epsilon);
    int64_t beatIdx         = (int64_t)nextRelativeIdx;
    int64_t beatInBar       = beatIdx % (int64_t)_beatsPerBar;
    if (beatInBar < 0) beatInBar += _beatsPerBar;
    _currentBeatInBar       = (uint32_t)beatInBar;

    // Sample del prossimo beat: phase origin + indice relativo
    double nextAbsoluteBeat = _startAbsoluteBeat + nextRelativeIdx;
    _exactNextBeatSample    = nextAbsoluteBeat * spb;
    // Sincronizza tracker suddivisioni al prossimo confine di beat
    _swingPhase = false;
    if (_subdivisionMultiplier > 1) {
        double firstInterval = subdivIntervalForPhase(spb, false);
        double fromPrevBeat  = _exactNextBeatSample - spb + firstInterval;
        _exactNextSubdivSample = (fromPrevBeat > (double)_absoluteSamplePosition)
                                 ? fromPrevBeat
                                 : _exactNextBeatSample + firstInterval;
    } else {
        _exactNextSubdivSample = std::numeric_limits<double>::max();
    }
}

// === Bug 2.b — Variante solo-temporale di setBeatPosition (Direzione 2) ===
// Allinea la timeline a campioni (_absoluteSamplePosition / _exactNextBeatSample
// + tracker suddivisioni) al beat assoluto richiesto da Link sync_phase, SENZA
// ri-derivare _currentBeatInBar. La fase di battuta resta governata dal contatore
// di sezione in processBuffer, ancorato al downbeat dallo swap SEAMLESS.
// FIX-B (Ferita B): la ri-derivazione del prossimo beat è MARK-PRESERVING —
// l'etichetta del mark pendente attraversa la correzione invariata (frazionaria)
// o shiftata della sola parte intera del salto (re-map quantum, benigno come
// sempre). Il ceil amnesico, che mangiava (avanti) o duplicava (indietro) un
// click reale quando la correzione attraversava un confine di beat, esce dal
// percorso insieme alla sua finestra epsilon.
void MetronomeDSP::setBeatPositionTimeOnly(double beatPosition) {
    // Guardia: beat negativi (beat-zero di sessione nel futuro, re-anchor
    // post-attach) renderebbero UB il cast uint64 sotto, con mitraglia di
    // click a sample 0. Hazard PRE-esistente e identico col vecchio ceil:
    // chiuso alla fonte. Nessuna correzione persa: il gate L2 richiama a
    // ogni buffer finché il beat non è ≥ 0.
    if (beatPosition < 0.0) return;

    double spb              = (_sampleRate * 60.0) / _bpm;

    // Distanza fisica al mark pendente, in beat, catturata PRIMA di muovere
    // la timeline (ORDINE OBBLIGATORIO). Differenza CORTA sull'asse campioni:
    // mai posizioni assolute storiche, robusta attraverso i cambi tempo.
    // Clamp difensivo: sotto 0 = mark perso dalla race storica dell'== (il
    // fire-asap sotto lo recupera entro mezzo beat); sopra 1.5 = stato fuori
    // contratto, limitato per non flippare l'etichetta.
    double aheadBeats       = (_exactNextBeatSample
                               - (double)_absoluteSamplePosition) / spb;
    if (aheadBeats < 0.0) aheadBeats = 0.0;
    if (aheadBeats > 1.5) aheadBeats = 1.5;

    _absoluteSamplePosition = (uint64_t)std::round(beatPosition * spb);

    // Etichetta del mark pendente nella NUOVA timeline = etichetta nuova di
    // "adesso" + distanza fisica. Identità: relative+aheadBeats = R + δ (la
    // frazione d'anticipo del mark si elide). round(): |frac(δ)| < 0.5 →
    // etichetta PRESERVATA (gate 0.01 / drift ~0.025 → margine >10×);
    // re-map intero ±k → etichetta shiftata di k (= comportamento storico:
    // cambia il nome del beat, non la fisica del click).
    // NB: nessuna scrittura di _currentBeatInBar (vedi commento sopra).
    double relative         = beatPosition - _startAbsoluteBeat;
    double pendingRelIdx    = std::round(relative + aheadBeats);
    _exactNextBeatSample    = (_startAbsoluteBeat + pendingRelIdx) * spb;

    // Fire-asap: se la correzione ha scavalcato in avanti il mark pendente,
    // il suo sample è nel passato del nuovo cursore e l'uguaglianza stretta
    // di processBuffer (:283) non scatterebbe MAI PIÙ (silenzio perpetuo).
    // Col clamp il click arretrato esce al 1° sample del processBuffer dello
    // STESSO giro di scheduleNextBuffer, in ritardo dell'ampiezza dello
    // scavalco (0,2 ms nel caso RUN6; fino a ~δ nei casi sopra-soglia); la
    // griglia rientra alla prima correzione gated successiva. Durante il
    // drain (_sectionEndPending) processBuffer è saltato: il mark "surfa"
    // sul cursore senza mai sparare, e ogni ripartenza passa da
    // resetForStart/setBeatPosition che riscrivono la terna.
    if (_exactNextBeatSample < (double)_absoluteSamplePosition) {
        _exactNextBeatSample = (double)_absoluteSamplePosition;
    }

    // Sincronizza tracker suddivisioni al prossimo confine di beat
    _swingPhase = false;
    if (_subdivisionMultiplier > 1) {
        double firstInterval = subdivIntervalForPhase(spb, false);
        double fromPrevBeat  = _exactNextBeatSample - spb + firstInterval;
        _exactNextSubdivSample = (fromPrevBeat > (double)_absoluteSamplePosition)
                                 ? fromPrevBeat
                                 : _exactNextBeatSample + firstInterval;
    } else {
        _exactNextSubdivSample = std::numeric_limits<double>::max();
    }
}

// === Bug 2.b — SPIA passiva: drain consumer (thread NON-RT). ===
// SPSC: unico consumer (questo), unico producer (thread audio via pushDiag).
// Copia i record disponibili in `out`, avanza readIdx. Nessun lock.
size_t MetronomeDSP::drainDiag(MetronomeDiagRecord* out, size_t maxOut) {
    uint64_t r = _diagRead.load(std::memory_order_relaxed);
    const uint64_t w = _diagWrite.load(std::memory_order_acquire);
    size_t n = 0;
    while (r < w && n < maxOut) {
        out[n++] = _diagRing[r & (kDiagRingCap - 1)];
        ++r;
    }
    _diagRead.store(r, std::memory_order_release);
    return n;
}

std::vector<BeatEvent> MetronomeDSP::processBuffer(uint32_t bufferSize) {
    // --- Fase VOL: PRIMA istruzione assoluta — dirty-check volume/mute ---
    if (_volumeDirty.load(std::memory_order_acquire)) {
        _accentVolume = _pendingAccentVolume;
        _beatVolume   = _pendingBeatVolume;
        _subdivVolume = _pendingSubdivVolume;
        _muted        = _pendingMuted;
        _volumeDirty.store(false, std::memory_order_release);
    }

    std::vector<BeatEvent> beats;

    // === B7-A3 — Follower adattivo: update di _bpm a INIZIO buffer ===
    // Mappa-vince (ratifica 03/07): in adaptive il tempo viene dalla TempoMap,
    // letta UNA volta per buffer alla posizione corrente. Scrittura DIRETTA di
    // _bpm (stessa ownership dello swap al downbeat sotto): NIENTE setBPM, che
    // riscala il mark e sposterebbe un beat già schedulato a metà gap — salto
    // di fase vietato; il nuovo tempo agisce dal += spb successivo.
    // Contratto dominio-clock (② in TempoMap.h): _absoluteSamplePosition è
    // legittimo qui SOLO sotto le precondizioni IMPOSTE dal setter — stesso
    // sample-rate (rifiuto al set) e start allineato (resetForStart(0), nessun
    // reposition con mappa attiva nello scope A3). Lo stato adaptive è letto
    // UNA volta per buffer (decisione coerente per l'intero giro, anche per il
    // gate al downbeat sotto). RT-safe: atomic acquire + binary search su
    // array preallocato — zero alloc/lock/syscall (Costituzione §4).
    const bool adaptive = _adaptiveActive.load(std::memory_order_acquire);
    if (adaptive) {
        const MapSlot& slot = _mapSlots[_activeMapSlot.load(std::memory_order_acquire)];
        _bpm = tempomap::bpmAt(slot.points, slot.count, _absoluteSamplePosition);
    }

    double spb = (_sampleRate * 60.0) / _bpm;

    if (_patternDirty.exchange(false, std::memory_order_acquire)) {
        std::memcpy(_accentPattern, _pendingPattern, _pendingPatternLength);
    }

    if (_subdivDirty.exchange(false, std::memory_order_acquire)) {
        _subdivisionMultiplier = _pendingMultiplier;
        _swingRatio            = _pendingSwingRatio;
        _swingPhase            = false;
        if (_subdivisionMultiplier > 1) {
            double firstInterval = subdivIntervalForPhase(spb, false);
            double fromPrevBeat  = _exactNextBeatSample - spb + firstInterval;
            _exactNextSubdivSample = (fromPrevBeat > (double)_absoluteSamplePosition)
                                     ? fromPrevBeat
                                     : _exactNextBeatSample + firstInterval;
        } else {
            _exactNextSubdivSample = std::numeric_limits<double>::max();
        }
    }

    for (uint32_t i = 0; i < bufferSize; ++i) {
        uint64_t currentAbsolute = _absoluteSamplePosition + i;
        uint64_t roundedNextBeat = (uint64_t)std::round(_exactNextBeatSample);

        bool isBeatSample  = (currentAbsolute == roundedNextBeat);
        bool isSubdivSample = false;
        if (_subdivisionMultiplier > 1) {
            uint64_t roundedNextSubdiv = (uint64_t)std::round(_exactNextSubdivSample);
            isSubdivSample = (currentAbsolute == roundedNextSubdiv) && !isBeatSample;
        }

        if (isBeatSample) {
            // === Bug 2.b — SPIA passiva (no-op se disabilitata) ===
            // Snapshot dell'asse ACCENTO PRIMA dello swap/incremento. Nessun
            // os_log/malloc/lock: solo cattura locale + push lock-free a valle.
            const uint32_t _diagBeatInBar = _currentBeatInBar;  // indice accento di QUESTO beat
            const uint32_t _diagBpbBefore = _beatsPerBar;       // metro prima dello swap
            if (!_muted) {
                BeatEvent ev;
                ev.offset = i;
                ev.accent = (_accentPattern[_currentBeatInBar] > 0);
                ev.isBeat = true;
                // Fase VOL: gain applicato in Swift al momento della scrittura PCM.
                // _accentVolume/_beatVolume/_subdivVolume sono accessibili via BeatEvent.volume
                // ma poiché BeatEvent non ha campo volume, il gain viene letto da AudioEngine
                // tramite le proprietà pubblicate. Il mute blocca qui l'emissione dell'evento.
                beats.push_back(ev);
            }
            // Strada A — Atomic exchange BPB + BPM al downbeat.
            // Ordine: BPB prima di BPM. L'ordine reciproco BPB↔BPM non ha
            // importanza tra loro — ciascuno precede il proprio consumer:
            // BPB precede il modulo % _beatsPerBar (riga sotto),
            // BPM precede _exactNextBeatSample += spb (riga sotto-sotto).
            if (_currentBeatInBar == 0) {
                if (_bpbChangeDirty.exchange(false, std::memory_order_acquire)) {
                    _beatsPerBar = _pendingBeatsPerBar;
                }
                // B7-A3 — GATING SELETTIVO (ratifica 03/07): in adaptive viene
                // saltato SOLO lo scambio BPM (mappa-vince sul TEMPO); lo
                // scambio BPB qui sopra resta ATTIVO — tempo e metro sono
                // ortogonali, il metro continua a seguire le sezioni anche in
                // adaptive. Il flag _bpmChangeDirty NON viene consumato qui:
                // i transiti di modo lo azzerano via cancelPendingBPM()
                // (setter, non-RT). `adaptive` è lo snapshot di inizio buffer:
                // decisione coerente per l'intero giro.
                if (!adaptive
                    && _bpmChangeDirty.exchange(false, std::memory_order_acquire)) {
                    _bpm = _pendingBPM;
                    spb  = (_sampleRate * 60.0) / _bpm;
                }
                // ATOM C — swap subdivision al downbeat (blocco separato,
                // ratifica ①). NON gated su `adaptive` (come BPB sopra:
                // la suddivisione segue la sezione, tempo⊥suddivisione).
                // Ratifica ③: _swingPhase NON toccato qui — lo resetta il
                // ri-arm del tracker più sotto quando multiplier>1;
                // irrilevante a multiplier==1. Ratifica ⑤:
                // _exactNextSubdivSample NON toccato qui — lo ricalcola lo
                // stesso ri-arm col multiplier/spb nuovi; a multiplier==1
                // resta stantio ma MAI letto (isSubdivSample è calcolato
                // solo con _subdivisionMultiplier > 1).
                if (_subdivScheduleDirty.exchange(false, std::memory_order_acquire)) {
                    _subdivisionMultiplier = _pendingScheduledMultiplier;
                    _swingRatio            = _pendingScheduledSwing;
                }
            }
            // Push spia DOPO lo swap (beatsPerBar aggiornato), PRIMA dell'incremento.
            // bpbSwapFired inferito dal post-stato (nessuna scrittura aggiunta alle
            // righe di produzione sopra): downbeat + metro cambiato ⇒ swap scattato.
            if (_diagEnabled.load(std::memory_order_acquire)) {   // acquire: vede _diagSeq=0 (release in setDiagEnabled)
                pushDiag((uint64_t)currentAbsolute, _exactNextBeatSample,
                         _diagBeatInBar, _beatsPerBar,
                         (_diagBeatInBar == 0u) && (_beatsPerBar != _diagBpbBefore));
            }
            _currentBeatInBar = (_currentBeatInBar + 1) % _beatsPerBar;
            _exactNextBeatSample += spb;
            if (_subdivisionMultiplier > 1) {
                _swingPhase            = false;
                _exactNextSubdivSample = (double)currentAbsolute + subdivIntervalForPhase(spb, false);
            }
        } else if (isSubdivSample) {
            if (!_muted) {
                BeatEvent ev;
                ev.offset = i;
                ev.accent = false;
                ev.isBeat = false;
                beats.push_back(ev);
            }
            _swingPhase            = !_swingPhase;
            _exactNextSubdivSample = (double)currentAbsolute + subdivIntervalForPhase(spb, _swingPhase);
        }
    }

    _absoluteSamplePosition += bufferSize;
    // B7-A3 — battito cardiaco RT per la guardia anti-flip di setTempoMap
    // (incremento a FINE buffer = "questo giro è concluso, slot non più in
    // lettura"). Relaxed: conta e basta, stesso pattern di _diagWrite.
    _processedBufferCount.fetch_add(1, std::memory_order_relaxed);
    return beats;
}
