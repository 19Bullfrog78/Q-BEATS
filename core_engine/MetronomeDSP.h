#pragma once
#include <cstdint>
#include <vector>

struct BeatEvent {
    uint32_t offset;
    bool     accent;
};

class MetronomeDSP {
public:
    MetronomeDSP(double sampleRate, double bpm);

    void setBPM(double bpm);
    void setBeatsPerBar(uint32_t beatsPerBar);
    void setAbsolutePositionForTesting(uint64_t pos);

    // Fresh play: fissa _startAbsoluteBeat e azzera _currentBeatInBar.
    // Chiamare SOLO su start() senza resume.
    void resetForStart(double startBeat);

    // Resume / Link phase sync: aggiorna posizione senza toccare _startAbsoluteBeat.
    // Chiamare su resume dopo interruzione e su ogni phase sync Link.
    void setBeatPosition(double beatPosition);

    double getStartAbsoluteBeat() const { return _startAbsoluteBeat; }
    uint32_t getCurrentBeatInBar() const { return _currentBeatInBar; }

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
};
