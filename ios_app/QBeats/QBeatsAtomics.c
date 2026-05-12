#include "QBeatsAtomics.h"
#include <stdatomic.h>
#include <stdlib.h>
#include <string.h>

struct QBeatsLinkPending {
    _Atomic uint64_t bpm_bits;          // bit-cast Double per atomic
    _Atomic uint32_t sample_offset;
    _Atomic uint64_t buffer_id;
    _Atomic uint64_t render_buffer_id;
    _Atomic int64_t  delta;
    _Atomic uint64_t sched_buffer_count;
    _Atomic uint64_t sample_rate_bits;  // bit-cast Double
    _Atomic bool     scheduled;
};

QBeatsLinkPending* qbeats_link_pending_create(void) {
    QBeatsLinkPending* p = malloc(sizeof(QBeatsLinkPending));
    if (!p) return NULL;
    memset(p, 0, sizeof(QBeatsLinkPending));
    return p;
}

void qbeats_link_pending_destroy(QBeatsLinkPending* p) {
    free(p);
}

void qbeats_link_pending_arm(QBeatsLinkPending* p, double bpm, uint32_t off, uint64_t bid) {
    uint64_t bits;
    memcpy(&bits, &bpm, sizeof(bits));
    atomic_store_explicit(&p->bpm_bits, bits, memory_order_relaxed);
    atomic_store_explicit(&p->sample_offset, off, memory_order_relaxed);
    atomic_store_explicit(&p->buffer_id, bid, memory_order_relaxed);
    // Release: publish — tutti i campi sopra sono visibili al reader
    // quando vede scheduled=true via acquire.
    atomic_store_explicit(&p->scheduled, true, memory_order_release);
}

void qbeats_link_pending_set_delta(QBeatsLinkPending* p, int64_t d) {
    atomic_store_explicit(&p->delta, d, memory_order_relaxed);
}

int64_t qbeats_link_pending_get_delta(QBeatsLinkPending* p) {
    return atomic_load_explicit(&p->delta, memory_order_relaxed);
}

void qbeats_link_pending_set_sched_buffer_count(QBeatsLinkPending* p, uint64_t bc) {
    atomic_store_explicit(&p->sched_buffer_count, bc, memory_order_relaxed);
}

uint64_t qbeats_link_pending_get_sched_buffer_count(QBeatsLinkPending* p) {
    return atomic_load_explicit(&p->sched_buffer_count, memory_order_relaxed);
}

void qbeats_link_pending_set_sample_rate(QBeatsLinkPending* p, double sr) {
    uint64_t bits;
    memcpy(&bits, &sr, sizeof(bits));
    atomic_store_explicit(&p->sample_rate_bits, bits, memory_order_relaxed);
}

double qbeats_link_pending_load_sample_rate(QBeatsLinkPending* p) {
    uint64_t bits = atomic_load_explicit(&p->sample_rate_bits, memory_order_relaxed);
    double d;
    memcpy(&d, &bits, sizeof(d));
    return d;
}

bool qbeats_link_pending_load_scheduled(QBeatsLinkPending* p) {
    // Acquire: pair col release di arm. Garantisce visibilita' campi.
    return atomic_load_explicit(&p->scheduled, memory_order_acquire);
}

double qbeats_link_pending_load_bpm(QBeatsLinkPending* p) {
    uint64_t bits = atomic_load_explicit(&p->bpm_bits, memory_order_relaxed);
    double d;
    memcpy(&d, &bits, sizeof(d));
    return d;
}

uint32_t qbeats_link_pending_load_sample_offset(QBeatsLinkPending* p) {
    return atomic_load_explicit(&p->sample_offset, memory_order_relaxed);
}

uint64_t qbeats_link_pending_load_buffer_id(QBeatsLinkPending* p) {
    return atomic_load_explicit(&p->buffer_id, memory_order_relaxed);
}

void qbeats_link_pending_clear_scheduled(QBeatsLinkPending* p) {
    atomic_store_explicit(&p->scheduled, false, memory_order_relaxed);
}

uint64_t qbeats_link_pending_increment_render_buffer(QBeatsLinkPending* p) {
    return atomic_fetch_add_explicit(&p->render_buffer_id, 1, memory_order_relaxed) + 1;
}
