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
{
    std::memset(_accentPattern,  0, sizeof(_accentPattern));
    std::memset(_pendingPattern, 0, sizeof(_pendingPattern));
    _accentPattern[0]  = 1;
    _pendingPattern[0] = 1;
}

void MetronomeDSP::setBPM(double bpm) {
    _bpm = bpm;
}

void MetronomeDSP::scheduleBPMChange(double newBPM) {
    _pendingBPM = newBPM;
    _bpmChangeDirty.store(true, std::memory_order_release);
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
    // Resume / Link phase sync: NON tocca _startAbsoluteBeat.
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

std::vector<BeatEvent> MetronomeDSP::processBuffer(uint32_t bufferSize) {
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
            BeatEvent ev;
            ev.offset = i;
            ev.accent = (_accentPattern[_currentBeatInBar] > 0);
            ev.isBeat = true;
            beats.push_back(ev);
            if (_currentBeatInBar == 0 && _bpmChangeDirty.exchange(false, std::memory_order_acquire)) {
                _bpm = _pendingBPM;
                spb  = (_sampleRate * 60.0) / _bpm;
            }
            _currentBeatInBar = (_currentBeatInBar + 1) % _beatsPerBar;
            _exactNextBeatSample += spb;
            if (_subdivisionMultiplier > 1) {
                _swingPhase            = false;
                _exactNextSubdivSample = (double)currentAbsolute + subdivIntervalForPhase(spb, false);
            }
        } else if (isSubdivSample) {
            BeatEvent ev;
            ev.offset = i;
            ev.accent = false;
            ev.isBeat = false;
            beats.push_back(ev);
            _swingPhase            = !_swingPhase;
            _exactNextSubdivSample = (double)currentAbsolute + subdivIntervalForPhase(spb, _swingPhase);
        }
    }

    _absoluteSamplePosition += bufferSize;
    return beats;
}
