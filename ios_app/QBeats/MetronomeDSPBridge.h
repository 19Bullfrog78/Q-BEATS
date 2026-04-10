#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* MetronomeHandle;

MetronomeHandle metronome_create(double sampleRate, double bpm);
void            metronome_destroy(MetronomeHandle handle);
void            metronome_setBPM(MetronomeHandle handle, double bpm);
void            metronome_setBeatsPerBar(MetronomeHandle handle, uint32_t beatsPerBar);

// Ritorna il numero di beat trovati nel buffer (0..maxBeats).
// offsets[i] = sample offset del beat i dentro il buffer.
// accents[i] = 1 se beat 1 di battuta (1500 Hz), 0 se beat normale (1000 Hz).
uint32_t        metronome_processBuffer(MetronomeHandle handle,
                                        uint32_t        bufferSize,
                                        uint32_t*       offsets,
                                        uint8_t*        accents,
                                        uint32_t        maxBeats);

#ifdef __cplusplus
}
#endif
