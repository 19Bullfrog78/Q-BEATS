#pragma once
#include <stdint.h>
#include <stdbool.h>

// === Task D refactor #18 — Atomic pending state per cambio BPM ===
// Ponte lockfree fra audioQueue Swift (arming) e render thread reale
// (sink block AVAudioSinkNode). Pattern release/acquire sul flag
// `scheduled` per pubblicazione dati. Identico schema di
// _bpmChangeDirty in MetronomeDSP.cpp (riga 40/211) gia' ratificato.
//
// Tutte le funzioni RT-safe per il render thread (no malloc, no lock,
// no I/O). Solo qbeats_link_pending_create/destroy chiamano malloc/free
// — usate UNA volta a init/deinit di AudioEngine, MAI dal render thread.

typedef struct QBeatsLinkPending QBeatsLinkPending;

// Lifecycle (chiamato UNA volta da audioQueue o init, MAI da render thread).
QBeatsLinkPending* qbeats_link_pending_create(void);
void qbeats_link_pending_destroy(QBeatsLinkPending* p);

// audioQueue side — non RT-critical (chiamati da arming nel beat callback
// e da scheduleNextBuffer su audioQueue).
void qbeats_link_pending_arm(QBeatsLinkPending* p,
                             double bpm,
                             uint32_t sample_offset,
                             uint64_t buffer_id);
void qbeats_link_pending_set_sample_rate(QBeatsLinkPending* p, double sr);
void qbeats_link_pending_set_sched_buffer_count(QBeatsLinkPending* p, uint64_t bc);
uint64_t qbeats_link_pending_get_sched_buffer_count(QBeatsLinkPending* p);

// RT-safe — chiamabili anche dal render thread (atomic store/load relaxed).
// (Correzione 2 referee: set_delta/get_delta sono usate sia da audioQueue
// che dal sink block per la calibrazione del delta sched-render.)
void qbeats_link_pending_set_delta(QBeatsLinkPending* p, int64_t delta);
int64_t qbeats_link_pending_get_delta(QBeatsLinkPending* p);

// Render thread side — RT-safe accessors (atomic loads/stores lockfree).
bool     qbeats_link_pending_load_scheduled(QBeatsLinkPending* p);
double   qbeats_link_pending_load_bpm(QBeatsLinkPending* p);
uint32_t qbeats_link_pending_load_sample_offset(QBeatsLinkPending* p);
uint64_t qbeats_link_pending_load_buffer_id(QBeatsLinkPending* p);
double   qbeats_link_pending_load_sample_rate(QBeatsLinkPending* p);
void     qbeats_link_pending_clear_scheduled(QBeatsLinkPending* p);
uint64_t qbeats_link_pending_increment_render_buffer(QBeatsLinkPending* p);
uint64_t qbeats_link_pending_get_render_buffer_id(QBeatsLinkPending* p);
