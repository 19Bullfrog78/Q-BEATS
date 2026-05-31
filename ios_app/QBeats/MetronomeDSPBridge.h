#pragma once
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* MetronomeHandle;

MetronomeHandle metronome_create(double sampleRate, double bpm);
void            metronome_destroy(MetronomeHandle handle);
void            metronome_setBPM(MetronomeHandle handle, double bpm);
void            metronome_set_sample_rate(MetronomeHandle handle, double sampleRate);
void            metronome_setBeatsPerBar(MetronomeHandle handle, uint32_t beatsPerBar);
void            metronome_setAccentPattern(MetronomeHandle handle, const uint8_t* pattern, uint32_t length);
void            metronome_setSubdivision(MetronomeHandle handle, uint8_t multiplier, double swingRatio);
void            metronome_schedule_bpm_change(MetronomeHandle handle, double newBPM);
void            metronome_cancel_pending_bpm(MetronomeHandle handle);

// Strada A — C-API per pending BPB + accent pattern paralleli a BPM.
void            metronome_schedule_bpb_change(MetronomeHandle handle, uint32_t bpb);
void            metronome_cancel_pending_bpb(MetronomeHandle handle);
void            metronome_schedule_accent_pattern_change(MetronomeHandle handle,
                                                          const uint8_t* pattern,
                                                          uint32_t length);

void            metronome_set_accent_volume(MetronomeHandle handle, double v);
void            metronome_set_beat_volume(MetronomeHandle handle, double v);
void            metronome_set_subdiv_volume(MetronomeHandle handle, double v);
void            metronome_set_muted(MetronomeHandle handle, bool muted);

// Fresh play: fissa phase origin, azzera _currentBeatInBar.
// Chiamare SOLO su start() senza resume.
void            metronome_reset_for_start(MetronomeHandle handle, double startBeat);

// Resume (post-interruzione/recovery): aggiorna posizione senza toccare phase origin.
// NB (Bug 2.b): il Link phase sync usa metronome_set_beat_position_time_only;
// questa resta per il solo Resume.
void            metronome_set_beat_position(MetronomeHandle handle, double beatPosition);

// Bug 2.b — variante solo-temporale: allinea la timeline a campioni senza toccare
// la fase di battuta (_currentBeatInBar). Usata da Link sync_phase.
void            metronome_set_beat_position_time_only(MetronomeHandle handle, double beatPosition);

uint32_t        metronome_processBuffer(MetronomeHandle handle,
                                        uint32_t        bufferSize,
                                        uint32_t*       offsets,
                                        uint8_t*        accents,
                                        uint8_t*        isBeats,
                                        uint32_t        maxBeats);

#ifdef __cplusplus
}
#endif
