// === MODIFICATO 6A ===
#pragma once
#import <Foundation/Foundation.h>
#include "MIDIEngineBridge.h"   // per LinkEngineHandle e typedef

#ifdef __cplusplus
extern "C" {
#endif

// LinkEngine funzioni già dichiarate in MIDIEngineBridge.h
void* link_engine_get_abl_ref(LinkEngineHandle handle);

#ifdef __cplusplus
}
#endif
