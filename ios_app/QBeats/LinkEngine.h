// === Build #176 — Facade Pattern Link ===
#pragma once
#include "MIDIEngineBridge.h"   // per LinkEngineHandle, typedef e dichiarazioni pubbliche

#ifdef __cplusplus
extern "C" {
#endif

// LinkPeersChangedCallback typedef e link_engine_set_peers_changed_callback
// sono dichiarati in MIDIEngineBridge.h (visibile a Swift via bridging header).
// Qui ri-dichiariamo per completezza del modulo C++.
void link_engine_set_peers_changed_callback(LinkEngineHandle handle,
                                            LinkPeersChangedCallback callback,
                                            void* context);

#ifdef __cplusplus
}
#endif
