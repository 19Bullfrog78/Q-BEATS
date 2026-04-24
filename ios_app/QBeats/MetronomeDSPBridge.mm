#include "MetronomeDSPBridge.h"
#include "../../core_engine/MetronomeDSP.h"
#import <os/log.h>

MetronomeHandle metronome_create(double sampleRate, double bpm) {
    return new MetronomeDSP(sampleRate, bpm);
}

void metronome_destroy(MetronomeHandle handle) {
    delete static_cast<MetronomeDSP*>(handle);
}

void metronome_setBPM(MetronomeHandle handle, double bpm) {
    static_cast<MetronomeDSP*>(handle)->setBPM(bpm);
}

void metronome_setBeatsPerBar(MetronomeHandle handle, uint32_t beatsPerBar) {
    static_cast<MetronomeDSP*>(handle)->setBeatsPerBar(beatsPerBar);
}

void metronome_reset_for_start(MetronomeHandle handle, double startBeat) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->resetForStart(startBeat);
}

void metronome_set_beat_position(MetronomeHandle handle, double beatPosition) {
    if (!handle) return;
    auto _dsp = static_cast<MetronomeDSP*>(handle);
    _dsp->setBeatPosition(beatPosition);
    os_log(OS_LOG_DEFAULT,
           "[METRO] setBeatPosition: beat=%.6f startAbs=%.6f beatInBar=%u",
           beatPosition,
           _dsp->getStartAbsoluteBeat(),
           _dsp->getCurrentBeatInBar());
}

uint32_t metronome_processBuffer(MetronomeHandle handle,
                                  uint32_t        bufferSize,
                                  uint32_t* offsets,
                                  uint8_t* accents,
                                  uint32_t        maxBeats) {
    auto beats = static_cast<MetronomeDSP*>(handle)->processBuffer(bufferSize);
    uint32_t count = 0;
    for (const auto& ev : beats) {
        if (count >= maxBeats) break;
        offsets[count] = ev.offset;
        accents[count] = ev.accent ? 1 : 0;
        ++count;
    }
    return count;
}
