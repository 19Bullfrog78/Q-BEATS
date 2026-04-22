# Q-BEATS — Contesto Progetto per AG
**Ultimo aggiornamento:** 22/04/2026

---

## 1. Architettura (Strada B — NON modificabile)

- **LAYER 3** — Swift / SwiftUI + ObjC++ Bridge (roadmap)
- **LAYER 2** — CoreMIDI C-API + Sequencer PPQN-960 + Ableton Link ← fase attuale
- **LAYER 1** — Core Audio C-API + C++ DSP Engine ✅ COMPLETATO

Strada A (React Native) scartata. Non riaprire.

---

## 2. Regole RT thread — inviolabili nel render callback

- Zero `malloc`/`free`/`new`/`delete`
- Zero Swift ARC (retain/release)
- Zero ObjC messaging
- Zero mutex bloccanti
- Zero I/O, zero syscall bloccanti
- Consentito: `std::atomic`, memoria pre-allocata, lock-free ring buffer

---

## 3. Thread safety in `AudioEngine.swift`

- **`audioQueue`** (Serial, `.userInteractive`): unica coda per stato audio (`isRunning`, `clickPlayhead`, `bufferCount`, `beatTotal`, `clickSamples`, ecc.)
- **`@Published`**: ogni write su `DispatchQueue.main.async` (`clickStatus`, `isPlaying`, `currentBPM`, `linkEnabled`, `linkIsConnected`, `beatsPerBar`)
- **Deadlock prevention**: mai chiamare `stopSync()` dall'interno di `audioQueue` (usa `sync` internamente)
- Start/Stop callback Link: dispatcha su `DispatchQueue.main` (NON `audioQueue` — deadlock con `stopSync()`)

---

## 4. Stato Layer 2 — build corrente #118

| Blocco | Stato |
|---|---|
| 1–5 (CoreMIDI, USB, Network, BT LE) | ✅ CHIUSO |
| 6A–6E (Ableton Link) | ✅ CHIUSO |
| Fix phase/click/quantum | ✅ CHIUSO (build #98–#100) |
| Validazione Link test 7a, 7b | ✅ PASS |
| Validazione Link test 7c, 7d | 🔲 Da fare |
| **Blocco 7 — Interruption Handling** | ✅ CHIUSO (build #155) |

### Blocco 7 — sotto-blocchi

| Step | Stato |
|---|---|
| 7A — Registrare InterruptionNotification, salvare stato in `.began` | ✅ |
| 7B — Resume in `.ended` + `.categoryChange` (calcolo beat position) | ✅ |
| 7C — Sync MetronomeDSP + MIDISequencer al resume | ✅ |
| 7D — `mediaServicesWereResetNotification` (full engine rebuild) | ✅ |
| 7E — Test su device (tutti gli scenari) | 🔄 IN CORSO |

### Bug fixati Blocco 7

| Bug | Fix | Build |
|---|---|---|
| False riprese durante chiamata attiva (SR 32000) | Guard `SR >= 44100` in `categoryChange` | #109 |
| False riprese durante suoneria (elapsed breve) | Guard `elapsed >= 0.5s` in `categoryChange` | #110–#111 |
| Doppio `setActive` su chiamata rifiutata | Copia locale + reset `wasPlayingBeforeInterruption` in `.ended` | #112 |
| iOS ferma engine per riconfigurazione IO dopo `.ended` | Observer `AVAudioEngineConfigurationChange` — clean restart con `resumeBeat` | #118 |
| Stop improprio a fine chiamata (oldDeviceUnavailable) | Guard `previousRoute.outputs` in `handleRouteChange` | #117 |
| Spostamento accento post-interruzione | Snap al Downbeat (ceil beat / beatsPerBar) | #147 |
| Doppio restart post-VoIP (configChange ravvicinati) | Temporal Guard (skip < 20s dal resume) | #148 |
| Rientro prematuro GSM/VoIP handoff | Guard CallActive sincrona in `handleRouteChange` | #152 |
| Instabilità rientro GSM/VoIP | Async Guard 500ms + Reset stato vincolato | #153 |
| Race condition background & Zombie retries | Token-based cancellation + exclusive setActive reset | #155 |

---

## 5. Decisioni architetturali chiave

### Bridge e file critici
- `MIDIEngineBridge.h` = singola sorgente di verità firme bridge — disallineamento con `.mm` = build rossa
- Bridge: `extern C` + `void*` handle
- `setBPM` (mai `setTempo`)
- Prompt verbatim obbligatorio per file critici

### LinkEngine
- **`struct LinkEngine {}` C++** definita in `LinkEngine.mm` (NON `@interface NSObject`)
- API C pura: handle `ABLLinkRef` (LinkKit 3.2.2 xcframework, static lib)
- `link_engine_get_abl_ref` in `LinkEngine.h` — NON in `MIDIEngineBridge.h`
- `ABLLinkSettingsViewController`: class method `+ (instancetype)instance:` — NON `initWithLink:`
- `ABLLinkSetPeerCountCallback` NON ESISTE in LinkKit 3.2.2
- `ABLLinkClockMicros` NON è in `ABLLink.h`
- `ABLLinkSetTempo(state, bpm, hostTime)` — hostTime = mach ticks
- Quantum dinamico: segue `beatsPerBar`

### Phase Correction Policy v1.2
- Hard sync assoluto: `*outNewBeatPosition = linkBeat`
- Soglia: 0.01 beats
- Punto applicazione: buffer boundary (`scheduleNextBuffer()`)
- `scheduleNextBuffer()` è su `audioQueue` (DispatchQueue) — versioni `App` di ABLLink

### Interruption Handling
- `.began`: salva stato + ferma engine
- `.ended`: guard SR + copia locale stato + reset flag + `start(resumeAtBeat:)`
- `.categoryChange`: guard SR >= 44100 + guard elapsed >= 0.5s + copia locale + reset flag + resume
- `wasPlayingBeforeInterruption` resettato in ENTRAMBI i path (`.ended` e `categoryChange`)
- `AVAudioEngineConfigurationChange`: se `isRunning && !engine.isRunning` → restart engine + playerNode + 3 buffer
- `playerNode.reset()` va chiamato PRIMA di `playerNode.play()` — MAI dopo

### Coordinamento metronomo
- Opzione B: moduli indipendenti coordinati da AudioEngine
- `MetronomeDSP::setBeatPosition` + bridge `metronome_set_beat_position` — in `start()` e dopo phase sync
- Bridge metronomo = `MetronomeDSPBridge.h` / `.mm` — **NON dentro `MIDIEngine.mm`**
- `MetronomeDSP._beatFractionAccumulator` **NON ESISTE** — rifiutare se compare

---

## 6. Flusso operativo

- **AG (Windows)**: scrive codice, build/test `core_engine` C++ via CMake
- **GitHub Actions (macOS)**: CI su push, genera IPA
- **Claude**: referee tecnico finale — ogni prompt deve essere approvato
- **Mauro**: supervisore/architetto — non scrive codice
- **Commit Strategy**: Separare sempre il refactoring (consolidamento, pulizia) dai fix funzionali in commit distinti per non sporcare il `git blame`.

---

## 7. Note tecniche fisse

| Regola | Dettaglio |
|---|---|
| Buffer size | Sempre da `ioBufferDuration` — iOS può ignorare preferred |
| Debug | `os_log` unico — `print()` non catturato da iMazing Console |
| `os_log` in Swift | `os_log("...", log: .default, type: .debug, ...)` — `OS_LOG_DEFAULT` è macro C |
| Test drift | 121 BPM (120 = intero esatto, maschera drift) |
| Path build | Path relativi `../../../` vietati su GitHub Actions |
| `UIBackgroundModes: audio` | Obbligatorio in `project.yml` |
| `machTimebase` | Cachato come `let` in `AudioEngine.swift` — non chiamare ogni route change |
| Re-sign manuale CI | Obbligatorio per entitlement restricted — non rimuovere step `codesign --force` |
| Entitlement multicast | `com.apple.developer.networking.multicast` — confermato nel binario |

---

## 8. Struttura cartelle

```
Q-BEATS/
  core_engine/
    MIDITypes.h
    MIDISequencer.h / .cpp
  ios_app/
    QBeats/
      AudioEngine.swift
      ContentView.swift
      SettingsView.swift
      MIDIEngineBridge.h
      MIDIEngine.mm
      MetronomeDSPBridge.h / .mm
      BTMIDICentralPickerView.swift
      MIDINetworkViewModel.swift
      LinkEngine.h / .mm
      LinkSettingsPresenter.h / .mm
      LinkSettingsUIView.swift
      QBeats-Bridging-Header.h
  Vendors/
    TPCircularBuffer/
    AbletonLink/
      LinkKit.xcframework
      LinkKitResources.bundle
```

---

## 9. Prossimi step

1. Build #116 su CI → installare → test 7E (chiamata rifiutata, risposta+riagganciata, YouTube, sveglia, Siri, Link+chiamata)
2. Se PASS → test Link 7c e 7d
3. Backlog #3 — test BLE controller terze parti (opzionale)
4. Briefing prodotto — sessione dedicata zero codice
5. Apertura Layer 3 — Swift/SwiftUI

---

## 10. Test suite CMake — 8 test, tutti PASS

| Test | Copertura |
|---|---|
| test_tick_accuracy | Precisione tick PPQN-960 |
| test_drift_121bpm | Drift 121 BPM |
| test_buffer_wrap | Edge case buffer wrap |
| test_loop_restart | Riavvio loop/pattern |
| test_absolute_position | setAbsolutePositionForTesting |
| test_bpm_change | Cambio BPM mid-playback |
| test_ppqn_960 | Risoluzione PPQN-960 |
| test_event_scheduling | Scheduling eventi MIDI |
