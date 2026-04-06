#import "MetronomeDSPBridge.h"
#include "MetronomeDSP.h"
#include <vector>
#include <algorithm>

MetronomeHandle metronome_create(double sampleRate, double bpm) {
    return new MetronomeDSP(sampleRate, bpm);
}

void metronome_destroy(MetronomeHandle handle) {
    delete static_cast<MetronomeDSP*>(handle);
}

void metronome_setBPM(MetronomeHandle handle, double bpm) {
    if (handle) static_cast<MetronomeDSP*>(handle)->setBPM(bpm);
}

void metronome_setAbsolutePositionForTesting(MetronomeHandle handle, uint64_t position) {
    if (handle) static_cast<MetronomeDSP*>(handle)->setAbsolutePositionForTesting(position);
}

uint32_t metronome_processBuffer(MetronomeHandle handle,
                                 uint32_t bufferSize,
                                 uint32_t* beatOffsetsOut,
                                 uint32_t maxOffsets) {
    if (!handle) return 0;
    
    std::vector<uint32_t> offsets = static_cast<MetronomeDSP*>(handle)->processBuffer(bufferSize);
    
    uint32_t count = (uint32_t)std::min(offsets.size(), (size_t)maxOffsets);
    for (uint32_t i = 0; i < count; ++i) {
        beatOffsetsOut[i] = offsets[i];
    }
    return count;
}
