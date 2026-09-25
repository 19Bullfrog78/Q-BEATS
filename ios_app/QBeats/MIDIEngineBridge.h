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

// === RIENTRO-P1 (17/09/2026) — SONDA DI SOLA LETTURA sull'ora dell'ultimo avvio/stop ===
// Rende ABLLinkTimeForIsPlaying (ABLLink.h: «Get the time at which a transport
// start/stop occurs»), in mach ticks dell'orologio locale, e in *outIsPlaying lo stato
// ABLLinkIsPlaying letto dallo STESSO capture. Non scrive niente e non committa niente.
// A Link spento (enabled_ falso) rende 0 e *outIsPlaying = false.
// Serve a MISURARE su device che cosa riporta Link dopo un riaggancio (referto A364,
// §3.k e §4.2): in questo passo il valore si logga soltanto, nessuna decisione lo legge.
// Chiamare da audioQueue, come le altre letture App-thread di questo ponte.
uint64_t link_engine_time_for_is_playing(LinkEngineHandle handle,
                                         bool*            outIsPlaying);

// === RIENTRO-P2A (20/09/2026) — TIMBRO DELL'AVVIO, SONDA DI SOLA LETTURA ===
// Da UN SOLO ABLLinkCaptureAppSessionState rende lo stato avvio/stop e tre letture del
// battito ALL'ORA DELL'AVVIO T = ABLLinkTimeForIsPlaying(state). Non scrive niente e non
// committa niente, come `link_engine_time_for_is_playing`. In questo passo i valori si
// loggano soltanto (AudioEngine, etichetta [Q-BEATS][RIENTRO-P2A][TIMBRO]): nessuna
// decisione li legge. Servono a decidere, dai log di un collaudo, quale lettura resta ferma
// per lo stesso avvio e quale cambia a ogni avvio nuovo.
// Le tre letture, e perché tre (Ableton/link @ e9a2e41, il sorgente di LinkKit 4.0):
//   beatAtStampQ1    = ABLLinkBeatAtTime (state, T, 1.0): battito del CLIENT agganciato
//                      alla fase di sessione a quantum 1 (Link.ipp, `beatAtTime` →
//                      Phase.hpp, `toPhaseEncodedBeats` → `closestPhaseMatch`: scarta di
//                      un battito intero quando lo scarto client-sessione passa il mezzo
//                      battito).
//   phaseAtStampQBig = ABLLinkPhaseAtTime(state, T, 1e6): con un quantum così grande la
//                      fase è il battito di T contato dallo ZERO DELLA SESSIONE (Link.ipp,
//                      `phaseAtTime`; la timeline del client ha l'origine sullo zero di
//                      sessione: ClientSessionTimelines.hpp, `updateClientTimelineFromSession`).
//                      Se quel battito è negativo la fase rende 1e6 + battito (Phase.hpp,
//                      `phase`: «negative beat values are handled correctly»).
//   beatAtStampQ0    = ABLLinkBeatAtTime (state, T, 0.0): battito grezzo della timeline
//                      del CLIENT. ⚠️ ABLLink.h non dice niente su quantum 0. Lo gestisce il
//                      sorgente: Phase.hpp, `phase` («If the given quantum is zero, returns
//                      zero») e `nextPhaseMatch` («If the given quantum quantum is 0, x is
//                      returned»); Beats.hpp, `operator%` rende 0 col divisore 0;
//                      ABLLink.mm (tag LinkKit-4.0) passa il quantum a Link senza guardie.
// captureHostTime = mach_absolute_time() letto subito prima della cattura.
// numPeers = il contatore del ponte (0/1, vedi `link_engine_num_peers`).
// A Link spento (enabled_ falso) linkEnabled è false e i campi di Link restano a zero.
// ⛔ Chiamare SOLO da audioQueue. ABLLinkCaptureAppSessionState scrive in un membro
//    CONDIVISO dell'istanza e ne rende l'indirizzo (ABLLink.mm, tag LinkKit-4.0:
//    `ablLink->mAppSessionState.mImpl = ...captureAppSessionState(); return
//    &ablLink->mAppSessionState;`): una cattura da un altro thread sovrascriverebbe lo
//    stato che audioQueue sta leggendo o per committare (`link_engine_sync_phase` e
//    `link_engine_assert_session_state` catturano e committano a ogni buffer).
typedef struct {
    bool     linkEnabled;       // enabled_ del ponte
    bool     isPlaying;         // ABLLinkIsPlaying(state)
    uint64_t timeForIsPlaying;  // T = ABLLinkTimeForIsPlaying(state), mach ticks locali
    double   beatAtStampQ1;     // ABLLinkBeatAtTime (state, T, 1.0)
    double   phaseAtStampQBig;  // ABLLinkPhaseAtTime(state, T, 1e6)
    double   beatAtStampQ0;     // ABLLinkBeatAtTime (state, T, 0.0)
    uint64_t captureHostTime;   // mach_absolute_time() subito prima della cattura
    uint32_t numPeers;          // numPeers_ del ponte
} LinkStartStamp;

LinkStartStamp link_engine_read_start_stamp(LinkEngineHandle handle);

// === A386 · FASE B2A (25/09/2026) — IL 2D NEL PONTE: QUATTRO AGGIUNTE, NESSUNA MODIFICA ===
// Tutte dell'API dell'app (ABLLinkCaptureAppSessionState): ⛔ chiamare SOLO da audioQueue,
// per la ragione scritta sopra a `LinkStartStamp`. Le regole che le usano stanno in
// QBeats/Models (fase B1, commit 54247fc); qui c'è solo la lettura e la scrittura.

// (1) ISTANTANEA DEL TRASPORTO: una cattura, NESSUN commit. Da qui leggono il battito di
// trasporto a 1 s (il Direttore per ripetere, il Follower per «sentire»), il cancello della
// mezza battuta (D6) e la falsa partenza (D7-bis).
//   tempo              = ABLLinkGetTempo(state), il tempo di sessione.
//   phaseAtStampQBig   = ABLLinkPhaseAtTime(state, T, 1e6): il battito di T contato dallo zero
//                        di sessione, condiviso fra i peer (ABLLink.h: la fase rispetto al
//                        quantum è condivisa; il valore assoluto no). Per T = ora dell'avvio
//                        è la fase d'avvio, per T = ora dello stop la fase di stop: la loro
//                        differenza (a giro, `FalseStartDecision.beatDelta`) è la stessa su
//                        tutti gli apparecchi.
//   timelineWriteCount = quante volte QUESTO apparecchio ha scritto la propria linea temporale
//                        su Link (tempo o battito), contate dal ponte a ogni commit che le
//                        modifica. Il campione la confronta col valore precedente: un cambio
//                        dell'ora avvio/stop nello stesso intervallo NON è un colpo del
//                        Direttore ma l'eco di una scrittura propria (`DirectorHeardTracker`,
//                        `ownTimelineWriteSinceLastSample`).
// A Link spento (enabled_ falso) linkEnabled è false e i campi di Link restano a zero.
typedef struct {
    bool     linkEnabled;
    bool     isPlaying;
    uint64_t timeForIsPlaying;
    double   phaseAtStampQBig;
    double   tempo;
    uint64_t captureHostTime;
    uint64_t timelineWriteCount;
} LinkTransportSnapshot;

LinkTransportSnapshot link_engine_read_transport_snapshot(LinkEngineHandle handle);

// (2) LA RIPETIZIONE DEL DIRETTORE: una cattura, UN commit di {isPlaying catturato,
// timeForIsPlaying catturato + shiftTicks}, nessun tocco a tempo e battito. Per Link lo stato
// avvio/stop parte solo se è diverso da quello catturato ([R] Link.ipp:47-52) e porta come
// timbro l'ora del commit: basta spostare l'ora di 1 ms, col segno alternato dal chiamante
// (`DirectorReannounceDecision`), perché riparta ogni secondo senza derivare. Da fermo porta
// l'ora dello STOP, non «adesso» (D7-bis: chi riceve una ripetizione decide la falsa partenza
// come chi ha ricevuto lo Stop vero). `nowHostTime` si usa solo se l'ora catturata è zero
// (nessuno stato mai scritto). Uno spostamento negativo non scende sotto zero. A Link spento
// non fa niente (linkEnabled = false nel report).
typedef struct {
    bool     linkEnabled;
    bool     isPlaying;
    uint64_t timeBefore;
    uint64_t timeAfter;
} LinkReannounceReport;

LinkReannounceReport link_engine_reannounce_transport(LinkEngineHandle handle,
                                                      uint64_t nowHostTime,
                                                      int64_t  shiftTicks);

// (3) START STOP SYNC: il getter (ABLLink.h:83, «only controllable by the user via the Link
// settings dialog») e il richiamo di cambio (ABLLink.h:164-167, sul thread principale). Senza,
// il commit del Direttore non esce e il Follower non adotta niente ([R] Controller.hpp:443,
// :411): la ripetizione tace e la macchina del Follower resta FUORI.
bool link_engine_is_start_stop_sync_enabled(LinkEngineHandle handle);
void link_engine_set_start_stop_sync_enabled_callback(LinkEngineHandle handle,
    void (*callback)(bool isEnabled, void* context),
    void* context);

#ifdef __cplusplus
}
#endif
