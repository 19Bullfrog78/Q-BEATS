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
void link_engine_activate(LinkEngineHandle handle);

// Internal use only — LinkSettingsPresenter.mm. Never in MIDIEngineBridge.h.
void* link_engine_get_abl_ref(LinkEngineHandle handle);
bool  link_engine_abl_is_enabled(LinkEngineHandle handle);

#ifdef __cplusplus
}
#endif
