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

// ATOM C — subdivision schedulata al downbeat (seamless sample-accurate)
// + cancel incondizionato allo stop (B1: stop-mid-transizione).
void            metronome_schedule_subdivision(MetronomeHandle handle, uint8_t multiplier, double swingRatio);
void            metronome_cancel_pending_subdivision(MetronomeHandle handle);

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

// A424/A432 — rinomina il battito in attesa (MetronomeDSP::renamePendingBeat): cambia solo
// l'etichetta nella battuta, mai il momento di un click. Chiamare SOLO su audioQueue, prima di
// metronome_processBuffer. Scrive la riga [METRO] renamePendingBeat (os_log su audioQueue, come
// le righe [METRO] delle due funzioni qui sopra).
void            metronome_rename_pending_beat(MetronomeHandle handle, uint32_t beatInBar);

// A431/A432 — il battito che il DSP suonera' per primo al prossimo metronome_processBuffer (P26, R1):
// beat = l'identita' sulla linea dei battiti del DSP (origine + indice); samplesAhead = campioni
// dall'inizio del prossimo buffer (0 = al primo campione, il battito messo a 'subito'). Sola lettura,
// nessuna riga di registro. Chiamare SOLO su audioQueue, dopo l'ultima scrittura del DSP della
// chiamata e prima di metronome_processBuffer.
typedef struct {
    double  beat;
    int64_t samplesAhead;
} MetronomePendingBeat;
MetronomePendingBeat metronome_pending_beat(MetronomeHandle handle);

// === Bug 2.b — SPIA passiva L1 (diagnostica, OFF di default) ===
// Abilita/disabilita la cattura per-beat nel path audio (thread-safe, non-RT).
void            metronome_set_diag_enabled(MetronomeHandle handle, bool enabled);
// Drena il ring-buffer diagnostico ed emette i record via os_log.
// Chiamare SOLO da thread NON-RT (es. timer di background / su stop).
void            metronome_flush_diag(MetronomeHandle handle);

uint32_t        metronome_processBuffer(MetronomeHandle handle,
                                        uint32_t        bufferSize,
                                        uint32_t*       offsets,
                                        uint8_t*        accents,
                                        uint8_t*        isBeats,
                                        uint32_t        maxBeats);

#ifdef __cplusplus
}
#endif
