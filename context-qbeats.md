# Q-BEATS — Contesto di Progetto
*Incolla questo come primo messaggio in ogni nuova chat del progetto.*

---

## Identità progetto

**Q-BEATS** (ex LiveHost) — metronomo e sequencer live nativo iOS per musicisti professionisti. iPhone-first. Livello: AUM / Cubasis / Drambo. Non un DAW.

**Mauro** = supervisore e architetto. Non scrive codice direttamente.
**AG** (Antigravity IDE) = agente AI Google, esegue codice in locale su Windows.
**Claude** = referee tecnico senior del panel AI (Claude + Gemini + GPT).

Repository: `github.com/19Bullfrog78/Q-BEATS`

---

## Architettura approvata — Strada B (NON modificabile)

```
LAYER 3 — Swift / SwiftUI + ObjC++ Bridge
LAYER 2 — CoreMIDI C-API + Sequencer PPQN-960 + Ableton Link SDK
LAYER 1 — Core Audio C-API + C++ DSP Engine  ← fase attuale
```

**Strada A (React Native + Expo + JSI) = scartata. Non riaprire.**

### Regole RT thread — inviolabili nel render callback
- Zero malloc/free/new/delete
- Zero Swift ARC
- Zero ObjC messaging
- Zero mutex bloccanti
- Zero I/O / syscall bloccanti
- Consentito: `std::atomic`, memoria pre-allocata, lock-free ring buffer

---

## Strategia operativa — Cervello + Orecchie

| Componente | Dove | Come |
|---|---|---|
| `core_engine/` C++ puro | locale Windows | CMake, test in ms |
| `ios_app/` ObjC++ + Swift | cloud build | GitHub Actions, macOS runner |

**iOS shell va in cloud build SOLO dopo che il C++ è verificato.**

### Struttura cartelle — realtà su GitHub

```
Q-BEATS/
  core_engine/          ← C++ puro, CMakeLists.txt, unit test
  ios_app/
    QBeats/             ← tutto in una cartella (no sottocartelle Bridge/ UI/)
      MetronomeDSPBridge.h
      MetronomeDSPBridge.mm
      AudioEngine.swift
      ContentView.swift
      (altri file Swift/ObjC++)
  Vendors/
    TPCircularBuffer/
    AbletonLink/
```

> ⚠️ La struttura Bridge/ e UI/ come sottocartelle separate è ideale ma non corrisponde alla realtà attuale del repo. Tutto è piatto in `ios_app/QBeats/`.

---

## Stato attuale

### Completato ✅
- `MetronomeDSP.h` / `.cpp` — Layer 1 C++, testato (3 test: `test_basic_beat`, `test_buffer_wrap`, `test_long_term_drift`)
- `MetronomeDSPBridge.h` / `.mm` — bridge C puro (`extern "C"` + `void* handle`)
- Expo / RN / expo-modules-core — rimossi definitivamente
- Click sintetico — rimosso `click.wav`, seno 1000 Hz / 40ms con decay esponenziale in `generateClickSamples()`
- Playhead persistente — bug troncamento click ai boundary di buffer risolto con `clickPlayhead: Int`
- Commenti `test_main.cpp` — corretti e pushati (commit `8c8690f`)
- **Task #1 — Race condition start() / completion handler** — `scheduleNextBuffer()` serializzato via `DispatchQueue(label: "com.bullfrog.qbeats.audio")`. Testato con interruzione WhatsApp e schermo spento: nessun colpo perso, nessun crash ✅
- **Data race AudioEngine.swift** — `isRunning`, `clickPlayhead`, `bufferCount`, `beatTotal`, `clickSamples`, `clickStatus`, `setBPM` tutti thread-safe via `audioQueue`. `AudioEngine.swift` rev. 2 verificato e pushato ✅
- **Build #5 su device** — silenzio pulito + click secco ogni mezzo secondo a 120 BPM ✅

### Prossimo step immediato
**Task #5 — MIDI Output / CoreMIDI Stage**

### Backlog follow-up

| # | Priorità | Stato | Descrizione |
|---|---|---|---|
| 1 | 🔴 Alta | ✅ Completato | Race condition `start()` — serializzato via DispatchQueue seriale |
| Data race | 🔴 Alta | ✅ Completato | `isRunning`/`clickPlayhead`/`clickSamples`/`clickStatus`/`setBPM` — tutti su `audioQueue`. `AudioEngine.swift` rev. 2 |
| 3 | 🟡 Media | ✅ Completato | Time signature configurabile — `beatsPerBar` in C++, accento beat 1 (1500 Hz), normale (1000 Hz). |
| 4 | 🟡 Media | ✅ Completato | Fix `clickStatus` SwiftUI — `AudioEngine` è ora `ObservableObject`, UI reattiva. |
| 2 | 🟢 Bassa | 🔲 Aperto | Playhead singolo → array playhead (polimetria, suddivisioni future) |

### Orizzonte
- **Fase 2**: CoreMIDI (tag Apple Developer Forums già flaggato)
- **Fase 3**: AVAudioSession interruption handling (spec già definita — vedi sotto)
- **MIDI 2.0**: rinviato, richiede iOS 17+

---

## Regole tre inviolabili di progetto

1. **No fix senza diagnosi completa** — capire esattamente perché esiste il bug prima di toccare qualcosa.
2. **No patch su patch** — correggere la causa root al punto X, mai compensare al punto Y.
3. **No shortcut architetturali** — Strada B / Cervello+Orecchie / sample-accurate è inviolabile.

---

## Note tecniche fisse — sempre valide

| Argomento | Regola |
|---|---|
| Buffer size | Sempre da `ioBufferDuration` — iOS può ignorare il preferred |
| AUv3 host | Impone buffer size dall'esterno — engine deve adattarsi |
| Ableton Link SDK | Lock-free by design → va nel render callback, zero thread extra |
| HDMI audio | AVAudioSession reindirizza automaticamente se configurato |
| HDMI video | Offset compensazione manuale obbligatorio (latenza ≠ audio) |
| Media server reset | `mediaServicesWereResetNotification` → full engine rebuild |
| BT A2DP | 100–200ms — inutilizzabile per monitoring live |
| BT LE MIDI | 5–15ms — accettabile MIDI, non audio |
| 120 BPM test | 24000 samples esatti → **non** rivela drift, non usare |
| 121 BPM test | 23801.65… → rivela immediatamente troncamenti, **obbligatorio** |
| setBPM | È `setBPM`, mai `setTempo` — distinzione critica nei prompt |
| Bridge | È `extern "C"` + `void* handle` — NON `@interface` ObjC |
| Path relativi | Vietati su GitHub Actions — solo path risolvibili in cloud |
| `os_log` | Unico sistema debug catturato da iMazing Device Console (`print()` Swift non catturato) |

### AudioEngine.swift — regole thread (inviolabili)

- `isRunning`, `clickPlayhead`, `bufferCount`, `beatTotal`, `clickSamples` — accesso ESCLUSIVO su `audioQueue`
- `clickStatus` — UI only, ogni write su `audioQueue.async`
- `stopSync()` — NON chiamare dall'interno di `audioQueue` (deadlock). Usa `audioQueue.sync` internamente
- `setBPM()` — `audioQueue.async { metronome_setBPM(h, bpm) }` — write C++ su `audioQueue`
- Notification handlers — usare `audioQueue.sync`/`audioQueue.async` per ogni accesso a stato; mai chiamare `start()`/`stop()` direttamente senza prima serializzare su `audioQueue`

### Fase 3 — AVAudioSession interruption (spec confermata)
- Tracciare `wasPlayingBeforeInterruption`
- Su `.ended`: verificare `shouldResume` prima di riprendere
- Chiamare `AVAudioSession.setActive(true, options: .notifyOthersOnDeactivation)` — obbligatorio
- Resume path idempotente: stessa sessione = resume, non reinit
- Notification handler su `@MainActor` via `Task`

---

## Bug catches da Prompt Zero — non dimenticare

- Buffer target in **samples**, non millisecondi
- Swift ARC warning **deve** essere aggiunto esplicitamente
- `test_buffer_wrap`: `setAbsolutePositionForTesting` = `samplesPerBeat - (bufferSize - 1)` — no hardcode
- `setAbsolutePositionForTesting` deve resettare **tutto** lo stato floating-point, non solo il contatore int
- Commenti fuorvianti = bug nei prompt — ogni commento deve essere letteralmente vero

---

## Gerarchia LLM per prompt AG

| Modello | Quando usarlo |
|---|---|
| **Gemini 3 Flash** | Task meccanici / routine — usare il più possibile |
| **Gemini 3.1 PRO LOW/HIGH** | Ragionamento complesso dove Flash non basta |
| **Claude Sonnet 4.6 Thinking / Opus 4.6 Thinking / GPT-OSS 230B** | Crediti limitati — riservare a task che richiedono davvero queste capacità |

**iMazing**: 8 install IPA rimanenti (aggiornato 10/04/2026). Installare solo codice verificato e stabile.

---

## Target hardware e deployment

- **Device**: iPhone, chip A12 minimo (iPhone XS 2018+)
- **iOS deployment target**: 16.0
- **MIDI 2.0**: fase successiva (richiede iOS 17+)
- **UI**: iPhone portrait. HDMI = landscape su `UIWindow` separata — non mirroring.

---

## Flusso di lavoro standard

```
Mauro definisce obiettivo
    ↓
Claude verifica architettura e prompt → semaforo verde / verde con correzioni / rosso
    ↓
Gemini / GPT elaborano proposte
    ↓
Claude review finale
    ↓
Mauro lancia prompt su AG
    ↓
AG scrive e testa il codice in locale
```

**Mandato verbatim**: per file critici (bridge headers, DSP interfaces, build config, CI/CD workflow), AG riceve codice verbatim esatto — zero libertà creativa.

---

*Ultimo aggiornamento: 11/04/2026*
