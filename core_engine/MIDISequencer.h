#pragma once
#include <cstdint>

// MIDISequencer — C++ puro, zero dipendenze Apple.
// Riceve tick dal DSP engine (in campioni), produrrà eventi MIDI con timestamp.
// Implementazione completa: Blocco 3.

struct MIDIEvent {
    uint64_t samplePosition; // posizione assoluta in campioni
    uint8_t  data[3];
    uint32_t length;
};

class MIDISequencer {
public:
    MIDISequencer() = default;
    ~MIDISequencer() = default;

    // Placeholder — implementazione Blocco 3
    void tick(uint64_t currentSamplePosition) {}
};
