#include "MetronomeDSP.h"
#include <cmath>

MetronomeDSP::MetronomeDSP(double sampleRate, double bpm)
    : _sampleRate(sampleRate)
    , _bpm(bpm)
    , _beatsPerBar(4)
    , _currentBeatInBar(0)
    , _absoluteSamplePosition(0)
    , _exactNextBeatSample(0.0)
{
}

void MetronomeDSP::setBPM(double bpm) {
    _bpm = bpm;
}

void MetronomeDSP::setBeatsPerBar(uint32_t beatsPerBar) {
    _beatsPerBar       = beatsPerBar;
    _currentBeatInBar  = 0;
}

void MetronomeDSP::setAbsolutePositionForTesting(uint64_t pos) {
    _absoluteSamplePosition = pos;
    _currentBeatInBar       = 0;
    double spb              = (_sampleRate * 60.0) / _bpm;
    double exactBeats       = (double)pos / spb;
    uint64_t nextBeatIdx    = (uint64_t)std::ceil(exactBeats - 1e-9);
    _exactNextBeatSample    = (double)nextBeatIdx * spb;
}

void MetronomeDSP::setBeatPosition(double beatPosition) {
    double spb = (_sampleRate * 60.0) / _bpm;
    _absoluteSamplePosition = (uint64_t)(beatPosition * spb);
    double nextBeatIndex = std::ceil(beatPosition - 1e-9);
    _currentBeatInBar = ((uint32_t)(uint64_t)nextBeatIndex) % _beatsPerBar;
    _exactNextBeatSample = nextBeatIndex * spb;
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
            _currentBeatInBar  = (_currentBeatInBar + 1) % _beatsPerBar;
            _exactNextBeatSample += spb;
        }
    }

    _absoluteSamplePosition += bufferSize;
    return beats;
}
