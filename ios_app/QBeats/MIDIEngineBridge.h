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
// Restituisce la beat position proiettata a hostTime (mach_absolute_time).
// RT-safe. Usare durante interruzioni audio quando midi_engine_process()
// non viene chiamato e il clock C++ si è congelato.
double midi_engine_get_beat_at_time(void* handle, uint64_t hostTime);
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
// Fix #3 — variante con hostTime futuro esplicito. Usata per propagare
// scheduleBPMChange a Link allineato al downbeat sample-accurate del DSP
// audio invece che a "adesso" (che causava offset di fase residuo su SB
// di ~10-20ms post-cambio sezione, fisso non convergente — verificato
// 11/05/2026 dopo fix #1+#2).
void link_engine_set_bpm_at_time(LinkEngineHandle handle, double bpm, uint64_t hostTime);
// === Step 4 (15/05/2026) — Set BPM + Beat atomically (App-thread, AudioQueue-callable) ===
// Variante atomica di link_engine_set_bpm_at_time che invia anche la fase.
// Risolve il drift sistemico ai cambi BPM in modalità Direttore (test L2.b
// 15/05/2026 sera, riprodotto su Tick e Metronome Pro). Il vecchio
// set_bpm_at_time mandava solo il tempo; Link conservava il proprio beat
// counter accelerando/decelerando dal punto pre-cambio, generando offset
// di ~30-50 ms al primo buffer post-skip-buffer. Questa funzione fa
// ABLLinkSetTempo + ABLLinkForceBeatAtTime nello stesso capture/commit —
// peer riceve tempo e fase nello stesso session update.
//
// Parametri:
//   bpm:         nuovo BPM al hostTime indicato
//   currentBeat: beat di Q-B al momento della call (midi_engine_get_beat_position)
//   hostTime:    hostTime futuro del primo sample del nuovo tempo
//
// La fase a hostTime è calcolata internamente come:
//   beatAtHostTime = currentBeat + (hostTime - now) * bpm / 60
void link_engine_set_bpm_and_beat_at_time(LinkEngineHandle handle,
                                          double bpm,
                                          double currentBeat,
                                          uint64_t hostTime);
// Fix #18 — variante audio-thread per chiamata dal vero render thread.
// Usa ABLLinkCaptureAudioSessionState / ABLLinkCommitAudioSessionState
// (lockfree, audio-thread only). Sample-accurate per design.
// MAI chiamare da audioQueue Swift o altri thread non-RT.
void link_engine_set_bpm_audio_thread(LinkEngineHandle handle, double bpm, uint64_t hostTime);
void link_engine_set_tempo_callback(LinkEngineHandle handle,
    void (*callback)(double bpm, void* context),
    void* context);
void link_engine_set_is_connected_callback(LinkEngineHandle handle,
    void (*callback)(bool isConnected, void* context),
    void* context);

// === Reattività pane Ableton ===
// Registra il user callback per ABLLinkSetIsEnabledCallback.
// LinkKit invoca il callback sul main thread quando l'utente cambia
// l'enabled state nel preference pane Ableton (toggle dentro il pane).
// Il C++ sincronizza enabled_ PRIMA di chiamare il callback Swift, così
// quando il callback Swift accede ai guard interni (es. via altre
// link_engine_* su audioQueue) il flag è già coerente.
//
// Pattern di parità comportamentale con Soundbrenner: peer compare nel
// pane mentre è ancora aperto, senza necessità di chiudere.
void link_engine_set_is_enabled_callback(LinkEngineHandle handle,
    void (*callback)(bool isEnabled, void* context),
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

// === Modalità Direttore — Phase assertion attiva ===
// Q-BEATS impone BPM e fase al session state in un singolo capture/commit
// atomico. Usato in scheduleNextBuffer quando _linkMode == .direttore, in
// alternativa a link_engine_sync_phase (modalità Collaborativa).
//
// hostTimeAtOutput: stesso valore passato a link_engine_sync_phase.
// currentBeatPosition: posizione beat locale (Q-BEATS source of truth).
// bpm: BPM corrente di Q-BEATS (_audioBPM su audioQueue).
//
// Vincolo: hostTimeAtOutput MAI sostituibile con mach_absolute_time()
// ricalcolato — l'uso del tempo sbagliato genera loop di rinegoziazione
// (regressione build #307). Vedi commento estensivo in LinkEngine.mm.
void link_engine_assert_session_state(LinkEngineHandle handle,
                                      uint64_t hostTimeAtOutput,
                                      double   currentBeatPosition,
                                      double   bpm);

// === Build #309 — Start/Stop API semantica (Opzione 2) ===
// Sostituisce il vecchio link_engine_set_is_playing con 4 funzioni
// dal nome parlante, una per ciascuno scenario di transport. La quinta
// funzione (probe_session) è una probe single-capture atomica per
// leggere coerentemente isPlaying + phase + tempo dalla sessione Link.
//
// Modello a 3 rami al play start (vedi AudioEngine.swift):
//   peers==0 && !isPlaying → start_at_beat_zero (Q-BEATS detta)
//   peers>0  && !isPlaying → quantized launch (master con peer fermo)
//   peers>0  && isPlaying  → quantized launch (follower)

// Probe atomica della sessione Link.
// Una sola CaptureAppSessionState → letture coerenti (no race tra peer).
// quantum è il numero di beat per battuta.
typedef struct {
    bool   isPlaying;     // ABLLinkIsPlaying(state)
    double phaseAtHost;   // ABLLinkPhaseAtTime(state, hostTime, quantum), in [0, quantum)
    double tempo;         // ABLLinkGetTempo(state), BPM corrente sessione
} LinkSessionProbe;

LinkSessionProbe link_engine_probe_session(LinkEngineHandle handle,
                                           uint64_t hostTime,
                                           double   quantum);

// Standalone puro (Q-BEATS solo nella sessione Link): Q-BEATS detta la timeline.
// Internamente chiede a Link di mappare beat 0 a hostTime.
// USARE SOLO SE peers == 0 — altrimenti sovrascrive timeline condivisa.
void link_engine_start_at_beat_zero(LinkEngineHandle handle, uint64_t hostTime);

// Resume da posizione nota (es. seek): Q-BEATS riparte allineato a beat.
// Internamente chiede a Link di mappare beat a hostTime.
void link_engine_start_at_beat(LinkEngineHandle handle,
                               uint64_t hostTime,
                               double   beat);

// Sessione condivisa con peer (peer fermo o in play): Q-BEATS si adegua.
// NESSUN RequestBeatAtTime — solo SetIsPlaying.
// futureHostTime = istante (mach ticks) del downbeat target a cui
// allineare l'avvio.
void link_engine_join_running_session(LinkEngineHandle handle,
                                      uint64_t futureHostTime);

// Stop transport.
void link_engine_stop(LinkEngineHandle handle, uint64_t hostTime);

void link_engine_set_start_stop_callback(LinkEngineHandle handle,
    void (*callback)(bool isPlaying, void* context),
    void* context);

// === AGGIUNTO Build #176 — Facade peers callback ===
typedef void (*LinkPeersChangedCallback)(void* context, uint32_t numPeers);
void link_engine_set_peers_changed_callback(LinkEngineHandle handle,
                                            LinkPeersChangedCallback callback,
                                            void* context);

// === AGGIUNTO Build #177 — Activate after callbacks ===
// Chiamare UNA SOLA VOLTA in init, dopo la registrazione di tutti i callback.
void link_engine_activate(LinkEngineHandle handle);

// === AGGIUNTO Build #181 — Direct peer query ===
// ABLLinkIsConnectedCallback è edge-triggered e non ri-scatta per peer già noti al re-enable.
// Questa funzione legge ABLLinkIsConnected direttamente per sincronizzare la UI dopo toggle ON.
bool link_engine_is_connected(LinkEngineHandle handle);

// === Build #300 — beat position at time ===
// Legge la posizione beat assoluta della sessione Link a hostTime.
// Usare per calcolare il delay fino al prossimo beat 1 prima di avviare il metronomo.
double link_engine_beat_at_time(LinkEngineHandle handle,
                                uint64_t hostTime,
                                double quantum);

#ifdef __cplusplus
}
#endif
