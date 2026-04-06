#include "MetronomeDSP.h"
#include <cmath>

MetronomeDSP::MetronomeDSP(double sampleRate, double bpm) 
    : _sampleRate(sampleRate)
    , _bpm(bpm)
    , _absoluteSamplePosition(0)
    , _exactNextBeatSample(0.0)
{
}

void MetronomeDSP::setTempo(double bpm) {
    _bpm = bpm;
}

void MetronomeDSP::setAbsolutePositionForTesting(uint64_t pos) {
    _absoluteSamplePosition = pos;
    double spb = (_sampleRate * 60.0) / _bpm;
    double exactBeats = (double)pos / spb;
    uint64_t nextBeatIdx = (uint64_t)std::ceil(exactBeats - 1e-9);
    _exactNextBeatSample = (double)nextBeatIdx * spb;
}

std::vector<uint32_t> MetronomeDSP::processBuffer(uint32_t bufferSize) {
    std::vector<uint32_t> beats;
    double spb = (_sampleRate * 60.0) / _bpm;
    
    for (uint32_t i = 0; i < bufferSize; ++i) {
        uint64_t currentAbsolute = _absoluteSamplePosition + i;
        uint64_t roundedNextBeat = (uint64_t)std::round(_exactNextBeatSample);
        
        if (currentAbsolute == roundedNextBeat) {
            beats.push_back(i);
            _exactNextBeatSample += spb;
        }
    }
    
    _absoluteSamplePosition += bufferSize;
    return beats;
}
