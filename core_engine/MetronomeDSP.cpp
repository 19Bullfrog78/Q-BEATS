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
{
    std::memset(_accentPattern,  0, sizeof(_accentPattern));
    std::memset(_pendingPattern, 0, sizeof(_pendingPattern));
    _accentPattern[0]  = 1;
    _pendingPattern[0] = 1;
}

void MetronomeDSP::setBPM(double bpm) {
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
// di sezione in processBuffer, ancorato al downbeat dallo swap SEAMLESS. Identica a
// setBeatPosition tranne l'omissione del blocco beatIdx/beatInBar/_currentBeatInBar,
// che era la causa dello sfasamento dell'accento al cambio BPB in peer
// (ceil(linkBeat - _startAbsoluteBeat) % _beatsPerBar).
void MetronomeDSP::setBeatPositionTimeOnly(double beatPosition) {
    double spb              = (_sampleRate * 60.0) / _bpm;
    _absoluteSamplePosition = (uint64_t)std::round(beatPosition * spb);
    double epsilon          = 0.5 / _sampleRate * (_bpm / 60.0);

    // Sample del prossimo beat: phase origin + indice relativo.
    // NB: nessuna scrittura di _currentBeatInBar (vedi commento sopra).
    double relative         = beatPosition - _startAbsoluteBeat;
    double nextRelativeIdx  = std::ceil(relative - epsilon);
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
                if (_bpmChangeDirty.exchange(false, std::memory_order_acquire)) {
                    _bpm = _pendingBPM;
                    spb  = (_sampleRate * 60.0) / _bpm;
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
    return beats;
}
