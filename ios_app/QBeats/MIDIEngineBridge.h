#pragma once
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Lifecycle
void* midi_engine_create(void);
void  midi_engine_destroy(void* handle);

// start: crea MIDIClient CoreMIDI, virtual input port, virtual output port.
bool  midi_engine_start(void* handle);
void  midi_engine_stop(void* handle);

// Sincronizzazione clock — chiamare all'inizio di ogni buffer audio
void  midi_engine_sync_clock(void* handle,
                              uint64_t currentSamplePosition,
                              uint64_t machTimeAtBufferStart,
                              double   sampleRate);

// MIDI Out
void  midi_engine_send(void* handle,
                        const uint8_t* packet,
                        uint32_t       length,
                        uint64_t       samplePosition);

// MIDI In — callback registrabile da Swift
void  midi_engine_set_receive_callback(void* handle,
                                        void (*callback)(const uint8_t* data,
                                                         uint32_t       length,
                                                         void*          userData),
                                        void* userData);

#ifdef __cplusplus
}
#endif
