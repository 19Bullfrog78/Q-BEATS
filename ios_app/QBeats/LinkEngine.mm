// === Build #176 — Facade Pattern Link ===
// Thin ObjC++ wrapper su ABLLinkRef (API C pura di LinkKit 3.2.2)
#import "LinkEngine.h"
#include <ABLLink.h>
#include <atomic>
#include <mach/mach_time.h>
#include <cmath>
#import <os/log.h>

struct LinkEngine {
    ABLLinkRef link_;
    std::atomic<bool> enabled_{false};
    std::atomic<uint32_t> numPeers_{0};
    std::atomic<double> quantum_{4.0};
    std::atomic<int64_t> pendingPhaseJump_{-1};
    std::atomic<double> phaseJumpThresholdBeats_{0.01};
    std::atomic<uint64_t> outputLatencyTicks_{0};  // unità: mach ticks
    // Build #309: rimosso suppressNextIsPlayingBroadcast_ — era dead code,
    // nessun setter lo impostava mai a true.
    void (*tempoCallback_)(double bpm, void* context) = nullptr;
    void* tempoCallbackContext_ = nullptr;
    void (*startStopCallback_)(bool isPlaying, void* context) = nullptr;
    void* startStopCallbackContext_ = nullptr;
    void (*isConnectedCallback_)(bool isConnected, void* context) = nullptr;
    void* isConnectedCallbackContext_ = nullptr;
    // === Build #176 — Facade peers callback ===
    void (*peersChangedCallback_)(void* context, uint32_t numPeers) = nullptr;
    void* peersChangedCallbackContext_ = nullptr;
};

LinkEngineHandle link_engine_create(void) {
    LinkEngine* engine = new LinkEngine();
    // 120.0 = temporaneo — master BPM di AudioEngine verrà allineato in 6B
    engine->link_ = ABLLinkNew(120.0);
    ABLLinkSetActive(engine->link_, false); // STEP 2 — inattivo fino a toggle utente
    // Build #177: Link creato ma NON attivato. link_engine_activate() viene chiamato
    // da AudioEngine.swift dopo la registrazione di tutti i callback.
    ABLLinkSetIsConnectedCallback(engine->link_,
        [](bool isConnected, void* context) {
            auto* le = static_cast<LinkEngine*>(context);
            // ABLLinkIsConnectedCallback è boolean: 0=nessun peer, 1=almeno un peer.
            // LinkKit 3.x non espone un contatore nativo via callback.
            uint32_t peers = isConnected ? 1 : 0;
            le->numPeers_.store(peers);
            os_log(OS_LOG_DEFAULT,
                   "[Q-BEATS][LINK][CONNECTED] isConnected:%d numPeers:%u",
                   (int)isConnected, peers);
            if (le->isConnectedCallback_) {
                le->isConnectedCallback_(isConnected,
                                         le->isConnectedCallbackContext_);
            }
            if (le->peersChangedCallback_) {
                le->peersChangedCallback_(le->peersChangedCallbackContext_, peers);
            }
        }, engine);
    return (LinkEngineHandle)engine;
}

void link_engine_destroy(LinkEngineHandle handle) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    ABLLinkDelete(engine->link_);
    delete engine;
}

void link_engine_set_enabled(LinkEngineHandle handle, bool enabled) {
    if (!handle) {
        os_log(OS_LOG_DEFAULT,
               "[Q-BEATS][LINK][SET_ENABLED] ABORT — handle NULL");
        return;
    }
    auto* le = static_cast<LinkEngine*>(handle);
    os_log(OS_LOG_DEFAULT,
           "[Q-BEATS][LINK][SET_ENABLED] called — enabled:%d",
           (int)enabled);
    if (enabled) {
        le->enabled_.store(true);
        ABLLinkSetActive(le->link_, true);
        bool ablActive = ABLLinkIsEnabled(le->link_);
        uint32_t peers = le->numPeers_.load();
        os_log(OS_LOG_DEFAULT,
               "[Q-BEATS][LINK][SET_ENABLED] ABLLinkSetActive(true) done — abl_is_enabled:%d numPeers:%u",
               (int)ablActive, peers);
    } else {
        le->enabled_.store(false);
        ABLLinkSetActive(le->link_, false);
        os_log(OS_LOG_DEFAULT,
               "[Q-BEATS][LINK][SET_ENABLED] ABLLinkSetActive(false) done");
    }
}

bool link_engine_is_enabled(LinkEngineHandle handle) {
    if (!handle) return false;
    LinkEngine* engine = (LinkEngine*)handle;
    return engine->enabled_.load();
}

uint32_t link_engine_num_peers(LinkEngineHandle handle) {
    if (!handle) return 0;
    LinkEngine* engine = (LinkEngine*)handle;
    return engine->numPeers_.load();
}

double link_engine_get_quantum(LinkEngineHandle handle) {
    if (!handle) return 0;
    LinkEngine* engine = (LinkEngine*)handle;
    return engine->quantum_.load();
}

void link_engine_set_quantum(LinkEngineHandle handle, double quantum) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    engine->quantum_.store(quantum);
}

void link_engine_set_bpm(LinkEngineHandle handle, double bpm) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);
    ABLLinkSetTempo(state, bpm, mach_absolute_time());
    ABLLinkCommitAppSessionState(engine->link_, state);
}

void link_engine_set_tempo_callback(LinkEngineHandle handle,
    void (*callback)(double bpm, void* context),
    void* context) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    engine->tempoCallback_ = callback;
    engine->tempoCallbackContext_ = context;
    ABLLinkSetSessionTempoCallback(engine->link_,
        [](double bpm, void* ctx) {
            LinkEngine* e = (LinkEngine*)ctx;
            if (e->tempoCallback_) {
                e->tempoCallback_(bpm, e->tempoCallbackContext_);
            }
        },
        (void*)engine);
}

void link_engine_set_is_connected_callback(LinkEngineHandle handle,
    void (*callback)(bool isConnected, void* context),
    void* context) {
    if (!handle) return;
    auto* le = static_cast<LinkEngine*>(handle);
    le->isConnectedCallback_ = callback;
    le->isConnectedCallbackContext_ = context;
}

void link_engine_set_peers_changed_callback(LinkEngineHandle handle,
    void (*callback)(void* context, uint32_t numPeers),
    void* context) {
    if (!handle) return;
    auto* le = static_cast<LinkEngine*>(handle);
    le->peersChangedCallback_ = callback;
    le->peersChangedCallbackContext_ = context;
}

void link_engine_activate(LinkEngineHandle handle) {
    if (!handle) return;
    LinkEngine* le = static_cast<LinkEngine*>(handle);
    // ABLLinkSetActive rimosso — attivazione affidata esclusivamente al toggle UI.
    // Flap activate(true)→(false) al boot rompeva il discovery multicast di LinkKit.
    os_log(OS_LOG_DEFAULT, "[Q-BEATS][LINK][ACTIVATE] Link attivato dopo registrazione callback");

    // Diagnostic #293: poll stato Link ogni 5s dopo attivazione
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
        dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            bool conn = ABLLinkIsConnected(le->link_);
            bool en   = ABLLinkIsEnabled(le->link_);
            ABLLinkSessionStateRef state = ABLLinkCaptureAppSessionState(le->link_);
            double bpm = ABLLinkGetTempo(state);
            ABLLinkCommitAppSessionState(le->link_, state);
            os_log(OS_LOG_DEFAULT,
                "[Q-BEATS][LINK][POLL] enabled:%d connected:%d bpm:%.2f",
                (int)en, (int)conn, bpm);
    });
}

void* link_engine_get_abl_ref(LinkEngineHandle handle) {
    if (!handle) return nullptr;
    return (void*)static_cast<LinkEngine*>(handle)->link_;
}

bool link_engine_abl_is_enabled(LinkEngineHandle handle) {
    if (!handle) return false;
    return ABLLinkIsEnabled(static_cast<LinkEngine*>(handle)->link_);
}

bool link_engine_is_connected(LinkEngineHandle handle) {
    if (!handle) return false;
    return ABLLinkIsConnected(static_cast<LinkEngine*>(handle)->link_);
}

void link_engine_set_output_latency_ticks(LinkEngineHandle handle, uint64_t ticks) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    engine->outputLatencyTicks_.store(ticks, std::memory_order_relaxed);
}

// === Build #309 — Start/Stop API semantica (Opzione 2) ===
// Sostituisce il monolitico link_engine_set_is_playing con 4 funzioni di
// azione (semantica esplicita al call site) + 1 funzione probe atomica.
//
// Razionale: il vecchio set_is_playing leggeva currentLinkBeat dalla
// sessione condivisa e lo ripassava a Link. Con peer presenti, il
// consensus poteva spostarlo, generando divergenza δ tra timeline locale
// (MetronomeDSP a beat 0 dopo resetForStart) e timeline Link.
// Risultato osservato: BUG-LINK-A (beat 2 anticipato di 12-50ms in
// scenario master+peer fermo, intermittente correlato alla fase Link
// al momento del play).
//
// Nuovo approccio aderente a doc Ableton "chi entra si adegua, chi c'è
// già non si muove" (dove "già nella sessione" ≠ "in play"):
//   - peers == 0 && !isPlaying  → Q-BEATS standalone: start_at_beat_zero
//   - peers > 0                 → Q-BEATS si adegua: join_running_session
//   - resume                    → start_at_beat (posizione nota)

LinkSessionProbe link_engine_probe_session(LinkEngineHandle handle,
                                           uint64_t hostTime,
                                           double   quantum) {
    LinkSessionProbe probe = { false, 0.0, 0.0 };
    if (!handle) return probe;
    LinkEngine* engine = (LinkEngine*)handle;
    if (!engine->enabled_.load(std::memory_order_relaxed)) return probe;

    // Single CaptureAppSessionState — tutte le letture sono coerenti tra
    // loro (no race con i peer durante la probe).
    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);

    probe.isPlaying   = ABLLinkIsPlaying(state);
    probe.phaseAtHost = ABLLinkPhaseAtTime(state, hostTime, quantum);
    probe.tempo       = ABLLinkGetTempo(state);

    ABLLinkCommitAppSessionState(engine->link_, state);
    return probe;
}

void link_engine_start_at_beat_zero(LinkEngineHandle handle,
                                    uint64_t hostTime) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    if (!engine->enabled_.load(std::memory_order_relaxed)) return;

    double quantum = engine->quantum_.load(std::memory_order_relaxed);
    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);

    // beat 0 mappato a hostTime: Link adegua la propria timeline a Q-BEATS.
    // SOLO per standalone (peers == 0) — il chiamante è responsabile di
    // questo invariante. Se chiamato con peer presenti sovrascriverebbe
    // la timeline condivisa (regressione #307).
    ABLLinkSetIsPlayingAndRequestBeatAtTime(
        state, true, hostTime, 0.0, quantum);

    ABLLinkCommitAppSessionState(engine->link_, state);
}

void link_engine_start_at_beat(LinkEngineHandle handle,
                               uint64_t hostTime,
                               double   beat) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    if (!engine->enabled_.load(std::memory_order_relaxed)) return;

    double quantum = engine->quantum_.load(std::memory_order_relaxed);
    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);

    // beat noto (es. snappedBeat per resume) mappato a hostTime.
    ABLLinkSetIsPlayingAndRequestBeatAtTime(
        state, true, hostTime, beat, quantum);

    ABLLinkCommitAppSessionState(engine->link_, state);
}

void link_engine_join_running_session(LinkEngineHandle handle,
                                      uint64_t futureHostTime) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    if (!engine->enabled_.load(std::memory_order_relaxed)) return;

    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);

    // NESSUN RequestBeatAtTime: Q-BEATS sta entrando in sessione attiva
    // (peer presenti, fermi o in play), si adegua alla timeline condivisa
    // senza sovrascriverla.
    // futureHostTime è il timestamp del downbeat target già calcolato dal
    // chiamante; passandolo direttamente Link riceve il timestamp esatto
    // del target (insensibile al jitter dispatch).
    ABLLinkSetIsPlaying(state, true, futureHostTime);

    ABLLinkCommitAppSessionState(engine->link_, state);
}

void link_engine_stop(LinkEngineHandle handle, uint64_t hostTime) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    if (!engine->enabled_.load(std::memory_order_relaxed)) return;

    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);

    ABLLinkSetIsPlaying(state, false, hostTime);

    ABLLinkCommitAppSessionState(engine->link_, state);
}

void link_engine_set_start_stop_callback(LinkEngineHandle handle,
    void (*callback)(bool isPlaying, void* context),
    void* context) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    engine->startStopCallback_ = callback;
    engine->startStopCallbackContext_ = context;
    ABLLinkSetStartStopCallback(engine->link_,
        [](bool isPlaying, void* ctx) {
            LinkEngine* e = (LinkEngine*)ctx;
            os_log(OS_LOG_DEFAULT,
                   "[Q-BEATS][LINK][ISPLAYING] isPlaying:%d numPeers:%lu",
                   (int)isPlaying,
                   (unsigned long)e->numPeers_.load());
            if (e->startStopCallback_) {
                e->startStopCallback_(isPlaying,
                                     e->startStopCallbackContext_);
            }
        },
        (void*)engine);
}

double link_engine_beat_at_time(LinkEngineHandle handle,
                                uint64_t hostTime,
                                double quantum) {
    if (!handle) return 0.0;
    LinkEngine* engine = (LinkEngine*)handle;
    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);
    double beat = ABLLinkBeatAtTime(state, hostTime, quantum);
    ABLLinkCommitAppSessionState(engine->link_, state);
    return beat;
}

bool link_engine_sync_phase(LinkEngineHandle handle,
                            uint64_t hostTimeAtOutput,
                            double   currentBeatPosition,
                            double*  outNewBeatPosition) {
    if (!handle || !outNewBeatPosition) return false;
    LinkEngine* engine = (LinkEngine*)handle;
    if (!engine->enabled_.load(std::memory_order_relaxed)) return false;

    // mach_timebase_info cachata: inizializzata una sola volta.
    // Conversione tick → nanosecondi: ticks * numer / denom.
    // Su ARM64 iOS tipicamente numer==denom==1, ma manteniamo
    // l'aritmetica generale per portabilità.
    static mach_timebase_info_data_t timebase = {0, 0};
    if (timebase.denom == 0) {
        mach_timebase_info(&timebase);
    }

    // ABLLinkCaptureAppSessionState — scheduleNextBuffer è su audioQueue
    // (DispatchQueue), NON in un AURenderCallback Core Audio.
    // Le versioni Audio sono riservate al render thread.
    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);

    double quantum  = engine->quantum_.load(std::memory_order_relaxed);
    // linkBeat = posizione beat assoluta che Link si aspetta a hostTimeAtOutput
    double linkBeat = ABLLinkBeatAtTime(state, hostTimeAtOutput, quantum);

    // === FIX BUG-LINK-A — Allineamento temporale del confronto fase ===
    // Difetto pre-fix: localPhase calcolata su currentBeatPosition (tempo
    // PRESENTE) veniva confrontata con linkPhase letta a hostTimeAtOutput
    // (tempo FUTURO, ~16–23ms avanti). Lo scarto temporale sistematico,
    // sommato all'offset di negoziazione introdotto da peer Link connessi
    // (anche silenti), superava la soglia 0.01 beat producendo una
    // correzione spuria al 4° buffer dopo il play start. Risultato:
    // beat 2 anticipato di 12–50ms; beat 3+ corretti perché l'allineamento
    // post-correzione era ormai consistente.
    //
    // Fix: proiettare currentBeatPosition in avanti fino a hostTimeAtOutput
    // usando il BPM Link corrente, così entrambe le misure (locale e Link)
    // sono riferite allo stesso istante temporale → confronto coerente.
    //
    // deltaTicks può essere negativo se la funzione è invocata in ritardo
    // rispetto al timestamp pianificato: l'aritmetica resta valida (fmod
    // su valore negativo è normalizzato dalla guardia << 0.0 più sotto).
    double bpm           = ABLLinkGetTempo(state);
    uint64_t now         = mach_absolute_time();
    int64_t  deltaTicks  = (int64_t)hostTimeAtOutput - (int64_t)now;
    double   deltaSec    = (double)deltaTicks
                         * (double)timebase.numer
                         / (double)timebase.denom
                         / 1.0e9;
    double   deltaBeats  = deltaSec * bpm / 60.0;
    double   projectedBeatPosition = currentBeatPosition + deltaBeats;

    // Fase locale (proiettata a hostTimeAtOutput) e fase Link, modulate per quantum
    double localPhase = fmod(projectedBeatPosition, quantum);
    double linkPhase  = fmod(linkBeat, quantum);
    if (localPhase < 0.0) localPhase += quantum;
    if (linkPhase  < 0.0) linkPhase  += quantum;

    double delta = linkPhase - localPhase;
    // Percorso più breve su [-quantum/2, quantum/2]
    if (delta >  quantum * 0.5) delta -= quantum;
    if (delta < -quantum * 0.5) delta += quantum;

    double threshold = engine->phaseJumpThresholdBeats_
                           .load(std::memory_order_relaxed);

    // Commit obbligatorio — pattern ABLLink anche in lettura
    ABLLinkCommitAppSessionState(engine->link_, state);

    if (fabs(delta) > threshold) {
        // Hard sync ASSOLUTO — Phase Correction Policy v1.2.
        // Allineamento esatto alla posizione beat di Link.
        *outNewBeatPosition = linkBeat;
        return true;
    }
    return false;
}

// === Modalità Direttore — Phase assertion attiva ===
// Q-BEATS impone BPM e fase al session state in un singolo capture/commit
// atomico. Usato in scheduleNextBuffer di AudioEngine.swift quando
// _linkMode == .direttore, in alternativa a link_engine_sync_phase
// (modalità Collaborativa).
//
// Razionale: in modalità Direttore Q-BEATS è la sorgente di verità della
// timeline. ABLLinkSetTempo + ABLLinkRequestBeatAtTime nello stesso commit
// garantiscono che il peer riceva tempo e fase nello stesso evento di
// session update, evitando finestre intermedie di disallineamento.
//
// Vincolo critico: ABLLinkRequestBeatAtTime DEVE usare hostTimeAtOutput
// (passato dal chiamante), non mach_absolute_time() ricalcolato. L'uso del
// tempo sbagliato genera loop di rinegoziazione (regressione build #307).
void link_engine_assert_session_state(LinkEngineHandle handle,
                                      uint64_t hostTimeAtOutput,
                                      double   currentBeatPosition,
                                      double   bpm) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    if (!engine->enabled_.load(std::memory_order_relaxed)) return;

    static mach_timebase_info_data_t timebase = {0, 0};
    if (timebase.denom == 0) {
        mach_timebase_info(&timebase);
    }

    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);

    double quantum  = engine->quantum_.load(std::memory_order_relaxed);
    double linkBeat = ABLLinkBeatAtTime(state, hostTimeAtOutput, quantum);

    // Stessa proiezione di link_engine_sync_phase: portiamo
    // currentBeatPosition al tempo del buffer in arrivo per un confronto
    // coerente locale-vs-Link.
    double   linkTempo   = ABLLinkGetTempo(state);
    uint64_t now         = mach_absolute_time();
    int64_t  deltaTicks  = (int64_t)hostTimeAtOutput - (int64_t)now;
    double   deltaSec    = (double)deltaTicks
                         * (double)timebase.numer
                         / (double)timebase.denom
                         / 1.0e9;
    double   deltaBeats  = deltaSec * linkTempo / 60.0;
    double   projectedBeatPosition = currentBeatPosition + deltaBeats;

    double localPhase = fmod(projectedBeatPosition, quantum);
    double linkPhase  = fmod(linkBeat, quantum);
    if (localPhase < 0.0) localPhase += quantum;
    if (linkPhase  < 0.0) linkPhase  += quantum;

    double delta = linkPhase - localPhase;
    if (delta >  quantum * 0.5) delta -= quantum;
    if (delta < -quantum * 0.5) delta += quantum;

    double threshold = engine->phaseJumpThresholdBeats_
                           .load(std::memory_order_relaxed);

    if (fabs(delta) > threshold) {
        // Q-BEATS impone: tempo + posizione beat nello stesso commit.
        // hostTimeAtOutput identico per entrambe le chiamate → atomicità
        // semantica oltre che di commit.
        // CRITICO: passare projectedBeatPosition (beat proiettato a
        // hostTimeAtOutput), NON currentBeatPosition (beat a now). Confronto
        // e correzione devono usare lo stesso riferimento temporale,
        // altrimenti il delta sistematico ~0.02-0.04 beat (10-20ms a 120 BPM)
        // non scende mai sotto threshold → assertion ad ogni buffer →
        // loop di rinegoziazione (regressione #307).
        ABLLinkSetTempo(state, bpm, hostTimeAtOutput);
        ABLLinkRequestBeatAtTime(state, projectedBeatPosition,
                                 hostTimeAtOutput, quantum);
        os_log(OS_LOG_DEFAULT,
               "[Q-BEATS][LINK][DIRECTOR-ASSERT] delta:%.4f bpm:%.2f beat_proj:%.4f",
               delta, bpm, projectedBeatPosition);
    }

    ABLLinkCommitAppSessionState(engine->link_, state);
}
