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

void metronome_set_sample_rate(MetronomeHandle handle, double sampleRate) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->setSampleRate(sampleRate);
}

void metronome_setBeatsPerBar(MetronomeHandle handle, uint32_t beatsPerBar) {
    static_cast<MetronomeDSP*>(handle)->setBeatsPerBar(beatsPerBar);
}

void metronome_setAccentPattern(MetronomeHandle handle, const uint8_t* pattern, uint32_t length) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->setAccentPattern(pattern, length);
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

void metronome_set_beat_position_time_only(MetronomeHandle handle, double beatPosition) {
    if (!handle) return;
    auto _dsp = static_cast<MetronomeDSP*>(handle);
    _dsp->setBeatPositionTimeOnly(beatPosition);
    os_log(OS_LOG_DEFAULT,
           "[METRO] setBeatPositionTimeOnly: beat=%.6f startAbs=%.6f beatInBar=%u",
           beatPosition,
           _dsp->getStartAbsoluteBeat(),
           _dsp->getCurrentBeatInBar());
}

// === Bug 2.b — SPIA passiva L1: enable + flush (os_log, thread NON-RT) ===
void metronome_set_diag_enabled(MetronomeHandle handle, bool enabled) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->setDiagEnabled(enabled);
}

void metronome_flush_diag(MetronomeHandle handle) {
    if (!handle) return;
    auto _dsp = static_cast<MetronomeDSP*>(handle);
    MetronomeDiagRecord buf[256];
    size_t n;
    while ((n = _dsp->drainDiag(buf, 256)) > 0) {
        for (size_t k = 0; k < n; ++k) {
            const MetronomeDiagRecord& r = buf[k];
            os_log(OS_LOG_DEFAULT,
                   "[Q-BEATS][Bug2b-SPY-L1] seq=%u absSample=%llu beatInBar=%u bpb=%u downbeat=%u bpbSwap=%u exactNextBeat=%.3f",
                   r.seq, (unsigned long long)r.absSample,
                   r.currentBeatInBar, r.beatsPerBar,
                   r.isDownbeat, r.bpbSwapFired, r.exactNextBeatSample);
        }
    }
    const uint64_t dropped = _dsp->diagDropped();
    if (dropped > 0) {
        os_log(OS_LOG_DEFAULT,
               "[Q-BEATS][Bug2b-SPY-L1] WARN ring overflow dropped=%llu",
               (unsigned long long)dropped);
    }
}

uint32_t metronome_processBuffer(MetronomeHandle handle,
                                  uint32_t        bufferSize,
                                  uint32_t*       offsets,
                                  uint8_t*        accents,
                                  uint8_t*        isBeats,
                                  uint32_t        maxBeats) {
    auto beats = static_cast<MetronomeDSP*>(handle)->processBuffer(bufferSize);
    uint32_t count = 0;
    for (const auto& ev : beats) {
        if (count >= maxBeats) break;
        offsets[count]  = ev.offset;
        accents[count]  = ev.accent  ? 1 : 0;
        isBeats[count]  = ev.isBeat  ? 1 : 0;
        ++count;
    }
    return count;
}

void metronome_setSubdivision(MetronomeHandle handle, uint8_t multiplier, double swingRatio) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->setSubdivision(multiplier, swingRatio);
}

void metronome_schedule_bpm_change(MetronomeHandle handle, double newBPM) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->scheduleBPMChange(newBPM);
}

void metronome_cancel_pending_bpm(MetronomeHandle handle) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->cancelPendingBPM();
}

// Strada A — Bridge per nuove API DSP.
void metronome_schedule_bpb_change(MetronomeHandle handle, uint32_t bpb) {
    if (!handle) return;
    auto _dsp = static_cast<MetronomeDSP*>(handle);
    // Bug 2.b — diagnostica arm-after-emit: fase di battuta del DSP all'ISTANTE
    // dell'arm, PRIMA dello store del dirty flag. beatInBarAtArm != 0 al confine
    // ⇒ il downbeat è già passato ⇒ swap perso ⇒ +1 bar. Letta come la riga [METRO].
    os_log(OS_LOG_DEFAULT,
           "[Q-BEATS][Bug2b-ARM] schedule_bpb_change reqBpb=%u beatInBarAtArm=%u",
           bpb, _dsp->getCurrentBeatInBar());
    _dsp->scheduleBeatsPerBarChange(bpb);
}

void metronome_cancel_pending_bpb(MetronomeHandle handle) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->cancelPendingBPB();
}

void metronome_schedule_accent_pattern_change(MetronomeHandle handle,
                                               const uint8_t* pattern,
                                               uint32_t length) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->scheduleAccentPatternChange(pattern, length);
}

// ATOM C — Bridge subdivision schedulata al downbeat (+ cancel allo stop).
void metronome_schedule_subdivision(MetronomeHandle handle, uint8_t multiplier, double swingRatio) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->scheduleSubdivisionChange(multiplier, swingRatio);
}

void metronome_cancel_pending_subdivision(MetronomeHandle handle) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->cancelPendingSubdivision();
}

void metronome_set_accent_volume(MetronomeHandle handle, double v) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->setAccentVolume(v);
}

void metronome_set_beat_volume(MetronomeHandle handle, double v) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->setBeatVolume(v);
}

void metronome_set_subdiv_volume(MetronomeHandle handle, double v) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->setSubdivVolume(v);
}

void metronome_set_muted(MetronomeHandle handle, bool muted) {
    if (!handle) return;
    static_cast<MetronomeDSP*>(handle)->setMuted(muted);
}
