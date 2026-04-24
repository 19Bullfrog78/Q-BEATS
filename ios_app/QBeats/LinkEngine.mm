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
    std::atomic<bool> suppressNextIsPlayingBroadcast_{false};
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
    if (!handle) return;
    auto* le = static_cast<LinkEngine*>(handle);
    if (enabled) {
        le->enabled_.store(true);
        ABLLinkSetActive(le->link_, true);
    } else {
        le->enabled_.store(false);
        ABLLinkSetActive(le->link_, false);
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
    ABLLinkSetActive(static_cast<LinkEngine*>(handle)->link_, true);
    os_log(OS_LOG_DEFAULT, "[Q-BEATS][LINK][ACTIVATE] Link attivato dopo registrazione callback");
}

void link_engine_set_output_latency_ticks(LinkEngineHandle handle, uint64_t ticks) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    engine->outputLatencyTicks_.store(ticks, std::memory_order_relaxed);
}

void link_engine_set_is_playing(LinkEngineHandle handle,
                                bool isPlaying,
                                uint64_t hostTime) {
    if (!handle) return;
    LinkEngine* engine = (LinkEngine*)handle;
    if (!engine->enabled_.load(std::memory_order_relaxed)) return;

    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);

    if (isPlaying && engine->suppressNextIsPlayingBroadcast_.exchange(false)) {
        ABLLinkCommitAppSessionState(engine->link_, state);
        return;
    }

    double quantum = engine->quantum_.load(std::memory_order_relaxed);

    if (isPlaying) {
        double currentLinkBeat = ABLLinkBeatAtTime(state, hostTime, quantum);
        os_log(OS_LOG_DEFAULT,
               "[Q-BEATS][LINK][SET_PLAYING] isPlaying:%d beat:%.4f",
               (int)true, currentLinkBeat);
        ABLLinkSetIsPlayingAndRequestBeatAtTime(
            state, true, hostTime, currentLinkBeat, quantum);
        os_log(OS_LOG_DEFAULT,
               "[Q-BEATS][LINK][RESTART] set_is_playing=true beat=%.4f (join)",
               currentLinkBeat);
    } else {
        os_log(OS_LOG_DEFAULT,
               "[Q-BEATS][LINK][SET_PLAYING] isPlaying:%d beat:%.4f",
               (int)false, 0.0);
        ABLLinkSetIsPlayingAndRequestBeatAtTime(
            state, false, hostTime, 0.0, quantum);
        os_log(OS_LOG_DEFAULT,
               "[Q-BEATS][LINK][RESTART] set_is_playing=false");
    }

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

bool link_engine_sync_phase(LinkEngineHandle handle,
                            uint64_t hostTimeAtOutput,
                            double   currentBeatPosition,
                            double*  outNewBeatPosition) {
    if (!handle || !outNewBeatPosition) return false;
    LinkEngine* engine = (LinkEngine*)handle;
    if (!engine->enabled_.load(std::memory_order_relaxed)) return false;

    // ABLLinkCaptureAppSessionState — scheduleNextBuffer è su audioQueue
    // (DispatchQueue), NON in un AURenderCallback Core Audio.
    // Le versioni Audio sono riservate al render thread.
    ABLLinkSessionStateRef state =
        ABLLinkCaptureAppSessionState(engine->link_);

    double quantum  = engine->quantum_.load(std::memory_order_relaxed);
    // linkBeat = posizione beat assoluta che Link si aspetta a hostTimeAtOutput
    double linkBeat = ABLLinkBeatAtTime(state, hostTimeAtOutput, quantum);

    // Fase locale e fase Link, modulate per quantum
    double localPhase = fmod(currentBeatPosition, quantum);
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
        // NON currentBeatPosition + delta (relativo — accumula drift).
        // Allineamento esatto alla posizione beat di Link.
        *outNewBeatPosition = linkBeat;
        return true;
    }
    return false;
}
