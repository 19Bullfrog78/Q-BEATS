#pragma once
#include <cstdint>
#include <vector>

struct BeatEvent {
    uint32_t offset;  // sample offset dentro il buffer corrente
    bool     accent;  // true = beat 1 di battuta (1500 Hz), false = beat normale (1000 Hz)
};

class MetronomeDSP {
public:
    MetronomeDSP(double sampleRate, double bpm);

    void setBPM(double bpm);
    void setBeatsPerBar(uint32_t beatsPerBar);
    void setAbsolutePositionForTesting(uint64_t pos);
    std::vector<BeatEvent> processBuffer(uint32_t bufferSize);

private:
    double   _sampleRate;
    double   _bpm;
    uint32_t _beatsPerBar;
    uint32_t _currentBeatInBar;
    uint64_t _absoluteSamplePosition;
    double   _exactNextBeatSample;
};
