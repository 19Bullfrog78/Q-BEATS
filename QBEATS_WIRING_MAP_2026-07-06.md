# MAPPA WIRING — Song → Setlist/Show → Metronomo (Q-BEATS)

**Data:** 2026-07-06 · **HEAD:** `fcf9260` · **Autore:** CC (repo) — ricognizione sub-agente + **spot-check §7 a source di CC** (correzioni marcate ⚠️)
**Scopo:** pianificare il wiring post-B7 (metronomo adattivo + campi persistiti-non-letti). Classi: **WIRED** (usato a runtime/Play) · **PERSISTED-NOT-READ** (salvato, nessun consumatore runtime) · **PLACEHOLDER** (UI stub).
**Livello di verifica:** i campi PERSISTED-NOT-READ chiave (metronomeMode, countIn, subdivision/swing, backtrack) = **verificati a source da CC**; la catena di consumo WIRED (SetlistRunner→AudioEngine, numeri di riga) = **da ricognizione sub-agente, da ri-spot-checkare al wiring**.

---

## 1 · WIRED — guidano metronomo/teleprompter a Play

| Elemento | Sorgente | Consumatore (recon, da ri-verificare al wiring) |
|---|---|---|
| `Song.id` | catalogo | `QBeatsStore.resolve()` · `SetlistRunner` catalog lookup |
| `Song.name` | catalogo | `SetlistRunner.updateSessionDisplay` → teleprompter |
| `Song.sections` | catalogo | `SetlistRunner` (currentSection, loop Live) |
| `SongSection.bpm` | sezione | `SetlistRunner.setBPM` → `AudioEngine` → `metronome_setBPM` |
| `SongSection.beatsPerBar` | sezione | `SetlistRunner.setBeatsPerBar` → `metronome_setBeatsPerBar` + quantum Link |
| `SongSection.accentPattern` | sezione | `SetlistRunner.setAccentPattern` → `metronome_setAccentPattern` + `MetSlotStripView` |
| `SongSection.repetitions` | sezione | `SetlistRunner.loadSection` → `_sectionTotalBeats` (drain / fine sezione) |
| `SongSection.name` | sezione | teleprompter / info sezione |
| `Setlist.id` / `Setlist.songIDs` | scaletta | `QBeatsStore.resolve` → `SetlistRunner` catalog |

---

## 2 · PERSISTED-NOT-READ — i tasselli che il wiring dovrà collegare (VERIFICATI a source)

| Campo | UI authoring? | Consumo runtime | Verbatim |
|---|---|---|---|
| **`Song.metronomeMode`** | ❌ nessuna | ❌ nessuno | unico uso fuori Models = `QBeatsBackupManager.swift:222` (clone import). Enum `MetronomeMode` off/fixed/adaptive. |
| **`Song.countIn`** (valore) | ✅ `SongEditorView.swift:34` (picker 0/1/2) | ❌ non letto | a Play il count-in è **hardcoded a 4**: `LiveView.swift:248` `session.playbackState = .countIn(countdown: 4)` — NON legge `song.countIn`. |
| **`Song.backtrackFilename`** + audio base | (metadato) | ❌ non suona in Live | `armBacktrack`/`backtrackPlayerNode` (`AudioEngine.swift:~1463-1530`) chiamati **solo da `DebugView`** (`:519-757`), mai nel flusso Live. = TD noto "base non suona in Live". |
| **`SongSection.subdivisionMultiplier`** | ⚠️ ✅ `SectionEditorView.swift:165/247-248` (Stepper `×N`) | ❌ non wired a Live | `setSubdivision`→`metronome_setSubdivision` (`AudioEngine.swift:1377/1380`) chiamato **solo da `DebugView:239`**; `SetlistRunner` NON lo passa. |
| **`SongSection.swingRatio`** | ⚠️ ✅ `SectionEditorView.swift:175/181/183` (Slider 0.5–0.75, attivo solo se subdiv=2) | ❌ non wired a Live | idem sopra (viaggia con `setSubdivision`, solo DebugView). |
| **`SongSection.beatUnit`** | ❌ | ❌ | legacy compat decoder (default 4, `SongSection.swift:46`), nessun consumatore. |
| **`SongSection.notes`** | ✅ `SectionEditorView.swift:153` | ❌ non mostrato in Live | memo authoring. |
| **`BacktrackFile.tempoMap` + tempoMapSampleRate/Confidence/AnalyzedAt** | ❌ | ❌ | nessun analyzer collegato, nessun wiring DSP-adaptive. Modello `TempoPoint` serializzato, zero consumatori Swift. |

> ⚠️ **Correzione alla ricognizione sub-agente:** `subdivisionMultiplier`/`swingRatio` NON sono "nessun form field authoring" — **hanno UI in `SectionEditorView`**. Il difetto vero è che **non sono consumati a runtime nel flusso Live** (solo DebugView chiama `setSubdivision`). L'API motore esiste già (`metronome_setSubdivision`): manca il ponte `SetlistRunner`→`setSubdivision` in `prepareAndStartCurrentSection`.

---

## 3 · PLACEHOLDER — UI da costruire

| UI | Ubicazione | Stato |
|---|---|---|
| **Shows tab** (authoring setlist) | `QStageRootView.swift:22-27` | stub "prossima fetta" — TD-shows-authoring (BUGS §1.2) |
| **Media tab** (libreria basi) | `QStageRootView.swift:29-34` | stub — cantiere Tracce (BUGS §1.2) |
| **Setlist picker (ingresso Live)** | `LiveRootView.swift:7-9` | HARDCODED `setlists.first ?? makeDefault()` — Nodo A / F2.3 |
| **Backup/Restore (import/export)** | — | nessun ingresso (BackupView orfana + import solo onOpenURL) — TD-backup-restore-no-ui (BUGS v31) |

---

## 4 · Catena di consumo a Play (recon — da ri-spot-checkare al wiring)

`SetlistRunner.prepareAndStartCurrentSection` (~:197-223):
1. `setBeatsPerBar(section.beatsPerBar)` → quantum Link + DSP
2. `setAccentPattern(section.accentPattern)` → DSP + `MetSlotStripView`
3. `loadSection(beatsPerBar, repetitions, onEnd:)` → `_sectionTotalBeats`
4. `setBPM(section.bpm)` → DSP + Link broadcast al downbeat
5. `preloadNextSection(...)` → SEAMLESS
6. `start()`

Fuori da questa catena (⊗): `beatUnit`, `subdivisionMultiplier`, `swingRatio`, `notes`, `metronomeMode`, `tempoMap*`, `countIn`(valore), backtrack-audio.

---

## Sintesi per la pianificazione wiring
Per il **metronomo adattivo** (B7): l'anello mancante è `BacktrackFile.tempoMap` (+ `Song.metronomeMode` = interruttore fixed/adaptive) → nessun analyzer li produce ancora, nessun ponte al DSP-follower (A3 esiste nel DSP ma scollegato dalla Song). Tasselli minori già "a un ponte di distanza" (UI+API presenti, manca il wiring in `SetlistRunner`): **subdivision/swing** e **count-in-value**. Prerequisiti UI: **Shows-authoring** e **Setlist-picker** (oggi `.first` hardcoded).
