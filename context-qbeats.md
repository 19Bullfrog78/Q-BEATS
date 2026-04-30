# Q-BEATS — Contesto Progetto per Claude Code (CC)
**Ultimo aggiornamento:** 29/04/2026 — Allineato a BOX 5 V7 (Build #192)

---

## 1. Architettura (Strada B — NON modificabile)

- **LAYER 3** — Swift / SwiftUI + ObjC++ Bridge 🔄 **In corso (Fase 1.4 completata)**
- **LAYER 2** — CoreMIDI C-API + Sequencer PPQN-960 + Ableton Link ✅ **CHIUSO** (Build #183)
- **LAYER 1** — Core Audio C-API + C++ DSP Engine ✅ **CHIUSO** (17/17 test CMake PASS)

**Regola:** L1 e L2 sono considerati stabili. Ogni modifica deve essere approvata dal supervisore.

---

## 2. Stato Progetto — Build #192

| Fase | Descrizione | Stato | Note |
|---|---|---|---|
| **0** | Estensioni L1 (Accent Pattern, Subdivision, BPM accurate) | ✅ | Completata (Build #185) |
| **1.1** | Modello dati + QBeatsStore (iCloud, async throws) | ✅ | Ratificato (Section, Song, Setlist) |
| **1.2** | ObjC++ Bridge Layer 3 | ✅ | Operativo |
| **1.3** | Backtrack AVAudioPlayerNode + ARMED state | ✅ | In RAM, no streaming |
| **1.4** | Mixer 4 canali | ✅ | Ch1-Ch4 con volumi indipendenti |
| **DebugView** | Schermata scaffolding test device | 🔲 **PROSSIMO** | Obbligatorio prima di 1.5 |
| **1.5** | Hardware detection Base/Pro | 🔲 | 1.5a (SW) / 1.5b (HW UMC404HD) |
| **1.6** | MappingTable MIDI Learn | 🔲 | Indipendente |

---

## 3. Invarianti Tecnici Layer 3 — Non negoziabili

| Regola | Dettaglio |
|---|---|
| **Feedback visivo beat** | Callback C++ → dispatch main — **MAI timer SwiftUI** |
| **Cambio BPM** | `scheduleBPMChange` (sample-accurate al downbeat) per cambi sezione |
| **Backtrack playback** | `AVAudioPlayerNode` in `AVAudioEngine` — **MAI `AVPlayer`** |
| **Streaming** | **VIETATO** — i backtrack devono essere file locali nella sandbox |
| **Route change** | Clock C++ non si ferma mai — B1 Hard Sync al rientro |
| **Debug** | `os_log` unico sistema ammesso (no `print()`) |
| **Portrait** | Solo modalità verticale per la v1 su tutti i device |
| **Storage** | `Documents/Backtracks/` per i file audio; iCloud per i JSON |
| **repetitions = -1** | Sentinel loop infinito — MAI null |
| **Tasto LOOP display** | 1 = LOOP / N>1 = LOOP · N / -1 = LOOP · ∞ |
| **Progress bar micro** | segmentata, N segmenti = N battute sezione corrente |
| **Count-in BPM** | prima sezione canzone target — MAI BPM canzone uscente |
| **Count-in scope** | solo tra canzoni — mai tra sezioni |
| **Sfondo Vista Bella** | nero obbligatorio |
| **Section.name** | è il teleprompter in Vista Bella — non modificare per altri scopi |
| **ALERT ultime 2 battute** | SCARTATO — le due progress bar bastano |

---

## 4. Modello Dati Ratificato

- **Section**: Include `bpm`, `beatsPerBar`, `beatUnit` (denominatore time signature: 4=quarti, 8=ottavi — default 4), `repetitions` (-1 per loop infinito), `accentPattern`, `subdivisionMultiplier`.
  - **TimeSignature**: lista chiusa 12 voci — 4/4 · 3/4 · 2/4 · 6/8 · 9/8 · 12/8 · 5/4 · 6/4 · 7/4 · 5/8 · 7/8 · 11/8. Nessuna combinazione libera.
- **Song**: Lista di `Section`, `countIn` (0/1/2 battute), riferimento a `backtrackFilename`.
- **Setlist**: Lista di ID di `Song` (riferimenti, mai copie).
- **BacktrackFile**: Metadati per la Libreria Backtrack (nome display, durata, dimensione).

**⚠️ Collisione naming**: `struct Section` nel modello collide con `SwiftUI.Section`. Usare sempre `SwiftUI.Section` esplicitamente nelle View.

---

## 5. Mixer e Routing (Fase 1.4)

| Canale | Contenuto | Modalità Base (Stereo) | Modalità Pro (Multi-out) |
|---|---|---|---|
| **Ch1** | Click / Metronomo | Out 1/2 (L) | Out 1 |
| **Ch2** | Backtrack musicale | Out 1/2 (R) | Out 2 |
| **Ch3** | Guide vocals / Cue | 🔒 Disabilitato | Out 3 |
| **Ch4** | FX / Pad | 🔒 Disabilitato | Out 4 |

---

## 6. Prossimi Step Operativi

1. **Implementazione DebugView**: Bottoni transport, slider volumi 4ch, log eventi a schermo.
2. **Validazione su device**: Test del mixer e del routing con `test_backtrack.mp3`.
3. **Fase 1.5a**: Logica software per la detection Base/Pro (`audioMode`).
4. **Fase 2**: Sviluppo della struttura app (Studio vs Live) e della **Vista Bella**.

---

## 7. Struttura Cartelle (Layer 3)

```
ios_app/QBeats/
  ├── AudioEngine.swift         # Singleton core (L3)
  ├── DebugView.swift           # Vista di scaffolding test
  ├── ContentView.swift         # Entry point UI
  ├── SettingsView.swift        # Impostazioni generali
  ├── Models/                   # Section.swift, Song.swift, etc.
  └── Store/                    # QBeatsStore.swift (Persistenza)
```

---

## 8. Note Hardware (Build #192)

- **Device Sviluppo**: iPhone 13 (Lightning).
- **Audio Interface**: Behringer UMC404HD (in arrivo).
- **Vincolo**: Per le uscite 3/4 su iOS è obbligatorio `setPreferredOutputNumberOfChannels(4)`.

---

## 9. AppSettings — Fase VOL (ratificata 29/04/2026)

```swift
struct AppSettings: Codable {
    var accentVolume: Double = 1.0   // [0.0, 1.0] — downbeat
    var beatVolume:   Double = 0.8   // [0.0, 1.0] — beat normale
    var subdivVolume: Double = 0.4   // [0.0, 1.0] — suddivisione
    var clickMuted:   Bool   = false // mute hard, slider invariati
}
```
Persistenza: `settings.json` in iCloud container.
I 4 setter DSP usano double-buffer + `std::atomic` dirty flag (stesso pattern accentPattern/subdivDirty build #185).
`muteClickToggle`: azione MIDI Learn disponibile, nessun default CC.

---

## 10. MIDI Learn

**Lista azioni completa:**
Play/Pause/Stop, Next/Prev Section, Next Song, Tap Tempo, Loop Toggle, Stop Backtrack, Start Song, Mute Click Toggle (nessun default CC)

---

## 11. REGOLE OPERATIVE — NON NEGOZIABILI

1. **STOP prima di agire**
   Non modificare, creare o sovrascrivere nessun file senza che Mauro abbia dato esplicito via libera in chat. "Procedo" non è un via libera.

2. **Nessuna iniziativa autonoma**
   Non proporre e poi eseguire nella stessa risposta. Prima proponi, aspetta conferma, poi esegui.

3. **Un file alla volta**
   Ogni modifica a un file va mostrata a Mauro prima di passare al file successivo. Non eseguire modifiche in sequenza autonoma.

4. **Output raw obbligatorio**
   Prima di qualsiasi push o commit, mostrare l'output completo del terminale. Nessun commit senza approvazione esplicita di Mauro.

5. **Nessuna lettura autonoma di file non richiesti**
   Non aprire, leggere o analizzare file che Mauro non ha indicato esplicitamente. "Vorrei leggere anche X" → aspetta risposta prima di farlo.

6. **Domande prima di implementare**
   Se una specifica è ambigua, fare una domanda precisa e aspettare risposta. Non interpretare e procedere.

7. **Review Claude referee obbligatoria**
   Ogni blocco di codice nuovo passa da Claude referee prima del commit. CC non decide autonomamente se una implementazione è corretta.
