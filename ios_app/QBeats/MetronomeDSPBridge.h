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

// Fresh play: fissa phase origin, azzera _currentBeatInBar.
// Chiamare SOLO su start() senza resume.
void            metronome_reset_for_start(MetronomeHandle handle, double startBeat);

// Resume / Link phase sync: aggiorna posizione senza toccare phase origin.
void            metronome_set_beat_position(MetronomeHandle handle, double beatPosition);

uint32_t        metronome_processBuffer(MetronomeHandle handle,
                                        uint32_t        bufferSize,
                                        uint32_t* offsets,
                                        uint8_t* accents,
                                        uint32_t        maxBeats);

#ifdef __cplusplus
}
#endif
