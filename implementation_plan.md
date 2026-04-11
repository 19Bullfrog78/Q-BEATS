# MIDI Sequencer Integration Plan

The goal is to bridge the `MIDISequencer` C++ class into the `MIDIEngine` C-transport layer and integrate it into the `AudioEngine` Swift audio callback. This will allow the application to play back looping MIDI patterns with sample accuracy and MIDI Clock (F8) generation.

## User Review Required

> [!IMPORTANT]
> Il `MIDISequencer` è stato già aggiornato per essere **100% RT-Safe** (Real-Time Safe). Utilizza un buffer pre-allocato (`ScheduledEventBuffer`) per evitare ogni allocazione dinamica nel thread audio.

## Proposed Changes

### [Component] MIDI Engine (C++ / Obj-C++)

#### [MODIFY] [MIDIEngine.mm](file:///c:/Users/BULLFROG/Desktop/ANTIGRAVITY/Q-BEATS/ios_app/QBeats/MIDIEngine.mm)
- `#include "../../core_engine/MIDISequencer.h"`
- Aggiunta di `MIDISequencer sequencer;` e `ScheduledEventBuffer outBuffer;` alla struct `MIDIEngine`.
- In `midi_engine_sync_clock`:
    - Allineamento automatico di BPM e Sample Rate tra Swift e il sequencer C++.
- Implementazione di `midi_engine_process(void* handle, uint32_t bufferSize)`:
    - Esegue `sequencer.processBuffer(lastSamplePosition, bufferSize, outBuffer)`.
    - Spedisce gli eventi risultanti tramite il path MIDI fisico/virtuale esistente.
- Implementazione di `midi_engine_set_pattern(void* handle, const MIDIEvent* events, uint32_t count, uint32_t lengthTicks)`.

#### [MODIFY] [MIDIEngineBridge.h](file:///c:/Users/BULLFROG/Desktop/ANTIGRAVITY/Q-BEATS/ios_app/QBeats/MIDIEngineBridge.h)
- Esposizione di `midi_engine_process` e `midi_engine_set_pattern`.
- Passaggio dei `MIDIEvent` da Swift a C in modo trasparente.

### [Component] Audio Engine (Swift)

#### [MODIFY] [AudioEngine.swift](file:///c:/Users/BULLFROG/Desktop/ANTIGRAVITY/Q-BEATS/ios_app/QBeats/AudioEngine.swift)
- In `scheduleNextBuffer()`:
    - Chiamata a `midi_engine_process` immediatamente dopo la sincronizzazione del clock.
- Aggiunta di un pattern MIDI di test (es. rullante su ogni quarto) per validare l'integrazione.

## Verification Plan

### Automated Tests
- Esecuzione dei nuovi test RT-safe in `test_midi_sequencer.cpp`.

### Manual Verification
- Verifica del MIDI Clock (F8) e del playback del pattern tramite monitor MIDI esterno o virtuale.
