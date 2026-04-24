// === MODIFICATO 6A ===
#pragma once
#import <Foundation/Foundation.h>
#include "MIDIEngineBridge.h"   // per LinkEngineHandle e typedef

#ifdef __cplusplus
extern "C" {
#endif

// LinkEngine funzioni già dichiarate in MIDIEngineBridge.h
void* link_engine_get_abl_ref(LinkEngineHandle handle);
void link_engine_set_is_enabled_callback(LinkEngineHandle handle,
    void (*callback)(bool isEnabled, void* context),
    void* context);

#ifdef __cplusplus
}
#endif
