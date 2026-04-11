#pragma once
#include <stdint.h>

// Definizione C pura di MIDIEvent.
// Incluso sia da core_engine (C++/CMake) che da ios_app (ObjC++/Swift).
// Zero dipendenze Apple. Zero dipendenze C++.

typedef struct {
    uint32_t tick;    // posizione assoluta in tick (0-based)
    uint8_t  data[3]; // byte MIDI: es. { 0x90, 60, 100 }
    uint8_t  length;  // numero di byte validi: 1, 2 o 3
} MIDIEvent;
