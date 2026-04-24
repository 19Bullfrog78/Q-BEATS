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
{
}

void MetronomeDSP::setBPM(double bpm) {
    _bpm = bpm;
}

void MetronomeDSP::setBeatsPerBar(uint32_t beatsPerBar) {
    _beatsPerBar      = beatsPerBar;
    _currentBeatInBar = 0;
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
}

std::vector<BeatEvent> MetronomeDSP::processBuffer(uint32_t bufferSize) {
    std::vector<BeatEvent> beats;
    double spb = (_sampleRate * 60.0) / _bpm;

    for (uint32_t i = 0; i < bufferSize; ++i) {
        uint64_t currentAbsolute = _absoluteSamplePosition + i;
        uint64_t roundedNextBeat = (uint64_t)std::round(_exactNextBeatSample);

        if (currentAbsolute == roundedNextBeat) {
            BeatEvent ev;
            ev.offset = i;
            ev.accent = (_currentBeatInBar == 0);
            beats.push_back(ev);
            _currentBeatInBar    = (_currentBeatInBar + 1) % _beatsPerBar;
            _exactNextBeatSample += spb;
        }
    }

    _absoluteSamplePosition += bufferSize;
    return beats;
}
