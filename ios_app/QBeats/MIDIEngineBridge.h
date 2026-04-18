#pragma once
#include <stdint.h>
#include <stdbool.h>
#include "../../core_engine/MIDITypes.h"

typedef void* MIDIEngineHandle;

#ifdef __cplusplus
extern "C" {
#endif

void* midi_engine_create(void);
void  midi_engine_destroy(void* handle);
bool  midi_engine_start(void* handle);
void  midi_engine_stop(void* handle);
void  midi_engine_sync_clock(void* handle,
                              uint64_t currentSamplePosition,
                              uint64_t machTimeAtBufferStart,
                              double   sampleRate);
void  midi_engine_send(void* handle,
                        const uint8_t* packet,
                        uint32_t       length,
                        uint64_t       samplePosition);
void  midi_engine_set_bpm(void* handle, double bpm);
void  midi_engine_set_pattern(void* handle,
                               const MIDIEvent* events,
                               uint32_t count,
                               uint32_t lengthTicks);
void  midi_engine_process(void* handle, uint32_t bufferSize);
void  midi_engine_set_receive_callback(void* handle,
                                        void (*callback)(const uint8_t* data,
                                                         uint32_t       length,
                                                         void*          userData),
                                        void* userData);
void  midi_engine_network_enable(void* handle);
void  midi_engine_network_disable(void* handle);
void  midi_engine_scan_connect_ports(void* handle);

// === AGGIUNTO 6C — Link phase sync ===
double midi_engine_get_beat_position(void* handle);
void   midi_engine_set_beat_position(void* handle, double targetBeats);

// === MODIFICATO 6A ===
// === LinkEngine Bridge 6A ===
typedef void* LinkEngineHandle;

LinkEngineHandle link_engine_create(void);
void link_engine_destroy(LinkEngineHandle handle);
void link_engine_set_enabled(LinkEngineHandle handle, bool enabled);
bool link_engine_is_enabled(LinkEngineHandle handle);
uint32_t link_engine_num_peers(LinkEngineHandle handle);
double link_engine_get_quantum(LinkEngineHandle handle);
void link_engine_set_quantum(LinkEngineHandle handle, double quantum);
void link_engine_set_bpm(LinkEngineHandle handle, double bpm);
void link_engine_set_tempo_callback(LinkEngineHandle handle,
    void (*callback)(double bpm, void* context),
    void* context);
void link_engine_set_is_connected_callback(LinkEngineHandle handle,
    void (*callback)(bool isConnected, void* context),
    void* context);

// === AGGIUNTO 6C — Link phase sync ===
void link_engine_set_output_latency_ticks(LinkEngineHandle handle, uint64_t ticks);
// Chiamare su audioQueue — NON in un AURenderCallback Core Audio.
// hostTimeAtOutput = mach_absolute_time() + outputLatencyTicks + bufferDurationTicks
// Ritorna true se correzione applicata, scrive posizione assoluta in outNewBeatPosition.
bool link_engine_sync_phase(LinkEngineHandle handle,
                            uint64_t hostTimeAtOutput,
                            double   currentBeatPosition,
                            double*  outNewBeatPosition);

// === AGGIUNTO 6D — Start/Stop sync ===
void link_engine_set_is_playing(LinkEngineHandle handle,
                                bool isPlaying,
                                uint64_t hostTime);
void link_engine_set_start_stop_callback(LinkEngineHandle handle,
    void (*callback)(bool isPlaying, void* context),
    void* context);

#ifdef __cplusplus
}
#endif
