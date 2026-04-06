#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* MetronomeHandle;

MetronomeHandle metronome_create(double sampleRate, double bpm);
void metronome_destroy(MetronomeHandle handle);

void metronome_setBPM(MetronomeHandle handle, double bpm);
void metronome_setAbsolutePositionForTesting(MetronomeHandle handle, uint64_t position);

uint32_t metronome_processBuffer(MetronomeHandle handle,
                                 uint32_t bufferSize,
                                 uint32_t* beatOffsetsOut,
                                 uint32_t maxOffsets);

#ifdef __cplusplus
}
#endif
