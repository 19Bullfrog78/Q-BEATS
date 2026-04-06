#pragma once
#include <cstdint>
#include <vector>

class MetronomeDSP {
public:
    MetronomeDSP(double sampleRate, double bpm);

    void setBPM(double bpm);
    void setAbsolutePositionForTesting(uint64_t pos);
    std::vector<uint32_t> processBuffer(uint32_t bufferSize);

private:
    double _sampleRate;
    double _bpm;
    uint64_t _absoluteSamplePosition;
    
    // Internal floating point cumulative state for exact timing without drift
    double _exactNextBeatSample;
};
