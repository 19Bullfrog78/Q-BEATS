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

class MetronomeDSP {
public:
    MetronomeDSP(double sampleRate, double bpm);

    void setBPM(double bpm);
    void setBeatsPerBar(uint32_t beatsPerBar);
    void setAccentPattern(const uint8_t* pattern, uint32_t length);
    // multiplier: 1=nessuna, 2=crome, 3=terzine, 4=semicrome
    // swingRatio: [0.5, 1.0[ — 0.5=dritto, >0.5=swing (solo con multiplier==2)
    void setSubdivision(uint8_t multiplier, double swingRatio = 0.5);
    // Schedula cambio BPM al prossimo downbeat (thread-safe, non-RT).
    void scheduleBPMChange(double newBPM);
    void setAbsolutePositionForTesting(uint64_t pos);

    // --- Fase VOL: volume click + mute (chiamare solo da audioQueue) ---
    void setAccentVolume(double v);   // [0.0, 1.0]
    void setBeatVolume(double v);     // [0.0, 1.0]
    void setSubdivVolume(double v);   // [0.0, 1.0]
    void setMuted(bool muted);        // mute hard

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

    double subdivIntervalForPhase(double spb, bool phase) const;
};
