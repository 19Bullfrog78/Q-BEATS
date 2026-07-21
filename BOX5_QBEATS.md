# Q-BEATS — BOX 5 — Specifiche e Contratti
**Versione:** V27 — 21/07/2026

> **Regola di aggiornamento:** aggiornare BOX5 quando cambiano spec, modello dati, token visivi, o invarianti Layer 3. NON aggiornare per avanzamento build o fix — quello va in BOX3.

**Delta V27 vs V26:**

- **BOX3 e BOX5 escono dai «canonici NON tracciati» ed entrano nei TRACCIATI** — commit `edaa80f`, 21/07/2026. Da lì vivono in root come `BOX3_QBEATS.md` e `BOX5_QBEATS.md`, tracciati in git, con `-text` in `.gitattributes`. Si modificano **in place**: il diff si legge riga per riga e le versioni precedenti stanno nella storia git, non in un file separato. Il bullet «Canonici NON tracciati» del Delta V26 è riscritto di conseguenza e resta valido per la sola SCALETTA. Per BOX3/BOX5 vale ora la **prescrizione** del bullet «Canonici TRACCIATI» — estrarre dal blob con `git show <commit>:<path>`, mai copiare dal file di lavoro — ma **non la motivazione scritta lì**: vedi la rettifica qui sotto.

- **RETTIFICA 21/07/2026 — il messaggio di commit di `edaa80f` motiva male il proprio vincolo.** Quel messaggio afferma che seguire il vecchio bullet «Canonici NON tracciati» produrrebbe, per BOX3/BOX5, la corruzione silenziosa descritta nel bullet dei tracciati. **È falso, e la rettifica vive qui perché un messaggio di commit è pushato e non si corregge.** Quella corruzione nasce dal divario CRLF-su-disco / LF-nel-blob, che è reale per `LIBRO_MASTRO_QBEATS.md` e `BUGS_QBEATS.md` ma **non esiste per BOX3 e BOX5**: lo stesso commit `edaa80f` ha messo `-text` su entrambi, e disco e blob coincidono al byte (verificato). Una copia dal disco non li corromperebbe. Il difetto reale del vecchio bullet era un altro, e regge: dichiarava «non esiste blob» — falso da `edaa80f` — e prescriveva una verifica d'impronta sorgente↔destinazione **non ancorata a un commit**, cioè una copia di cui non si sa a quale stato del documento corrisponda. Il vincolo di `edaa80f` era giusto; la ragione scritta accanto no.

- **Formato dei canonici propagati a E:/project — nome PER VERSIONE, con data e commit di estrazione in coda** (ratificato Mauro 21/07/2026). Forma: `BOX3_V98_2026-07-22_edaa80f.md`. Due motivi, entrambi vincolanti. **(1)** Su E: il file è una **stampa**, non l'originale: il nome per-versione lo distingue a colpo d'occhio dal file a nome fisso che vive nel repo, ed evita di ricostruire su E: la trappola-per-nome che ha già prodotto le due `SCALETTA` omonime e divergenti. **(2)** Il commit in coda rende la stampa **verificabile**: la sua impronta deve coincidere con quella del blob a quel commit, e il controllo resta eseguibile con un comando anche fra anni. ⚠️ **L'archivio esistente non si tocca:** i file da V8 a V97 restano col nome che hanno.

Tutto il resto invariato da V26.

**Delta V26 vs V25:**

- **Formato dei canonici propagati a E:/project — due regimi, secondo il tracciamento git.**
  · **Canonici TRACCIATI** (`BUGS_QBEATS.md`, `LIBRO_MASTRO_QBEATS.md`, `HANDOFF/**`): lo snapshot si produce ESTRAENDO DAL BLOB GIT (`git show <commit>:<path>`), MAI con Copy-Item dal file di lavoro. Il file di lavoro in root è CRLF, il blob è LF: i 32 snapshot storici su E: sono tutti LF, e una copia dal disco produrrebbe l'unico CRLF in mezzo a 32 LF — corruzione invisibile, scoperta mesi dopo. La verifica confronta l'impronta con quella del BLOB, non con quella del file su disco.
  · **Canonici NON tracciati** (dal 21/07/2026 la sola SCALETTA — vive fuori da git): l'estrazione da git è IMPOSSIBILE, non esiste blob. La copia dal disco è l'unica via → la verifica è un confronto d'impronta sorgente↔destinazione (stesso sha256 alle due estremità), e il formato del file sorgente È il formato canonico per definizione. ⚠️ **Limite noto del regime, ed è la ragione per cui se ne esce appena possibile:** un'impronta sorgente↔destinazione non è ancorata a un commit, quindi certifica che la copia è fedele ma NON a quale stato del documento corrisponda. **BOX3 e BOX5 sono usciti da questa categoria con `edaa80f` (21/07/2026)** e seguono ora il bullet «Canonici TRACCIATI» qui sopra — con la qualificazione della RETTIFICA nel Delta V27: ne vale la **prescrizione** (estrarre dal blob), non la **motivazione** CRLF/LF, che per loro non si applica.
  · **Regola generale:** non si dichiara mai una propagazione «verde» senza aver confrontato un'impronta con la sorgente giusta per il regime del file. Nato 17/07/2026, dopo che un prompt di propagazione diceva «Copy-Item dal disco» per un file tracciato e sarebbe passato verde producendo corruzione silenziosa.

Tutto il resto invariato da V25.

**Delta V25 vs V24:**

- **Invariante `@Published` (riga «@Published assignment») annotato — equivalenza `@MainActor`.** Il testo storico imponeva ESCLUSIVAMENTE `DispatchQueue.main.async`. Un tipo dichiarato `@MainActor` a livello di classe (es. `QBeatsStore`) soddisfa lo stesso invariante con garanzia più forte (compile-time, non runtime) e non richiede `DispatchQueue` esplicito. Annotazione, non cambio di intento. Esito accertamento 13/07 (sha `3c1a21a0…`), verdetto referee [C]. Tutto il resto invariato da V24.

**Delta V24 vs V23:**

- **Fix package Fase D "Rafforzamento modalità Direttore" (28/05/2026):** guard start/stop e BPM estesi a tutti gli stati (`isRunning` rimosso, Bug 5 + Bug 5-BPM fix). Modello fresh play branching evoluto da 3 a 4 rami (Director standalone ratificato — chiude latenza 1.j). Rimosso claim stale "tre callback condividono guard" — ogni callback documentato separatamente. **Default LinkMode corretto da `.direttore` a `.collaborativa`** (commit `cb92faa` 24/05/2026 — BOX5 V23 lo documentava ancora erroneamente come `.direttore`). Tutto il resto invariato da V23.

**Delta V23 vs V22:**

- **Correzione baseline scaling responsive 430pt → 390pt.** V22 dichiarava erroneamente `iPhone 13 portrait = 430pt larghezza` e tutte le percentuali in BOX5 erano calcolate su 430. Misurazione empirica 18/05/2026 (commit `adfcc39` Fase 1 TD #23) con `os_log(.default, "[QBEATS][ScaleFactor] geo.size.width = %f", geo.size.width)` su iPhone 13 portrait reale ha riportato **`390.000000`**. La specifica Apple iPhone 13 portrait è 390pt, non 430 (430pt è la specifica di iPhone 14/15 Plus o iPhone 14/15 Pro Max). La calibrazione V22 era teorica e sbagliata.
- **Cambio pattern: percentuali pre-calcolate → `pt_originale * scaleFactor`.** V22 indicava per ogni callsite font la percentuale calibrata (es. `geo.size.width * 0.065`). V23 sostituisce con il pattern moltiplicativo `pt_originale * scaleFactor` dove `scaleFactor = geo.size.width / 390` calcolato una sola volta in `LiveView.swift` e propagato come parametro `CGFloat` esplicito a tutti i sub-View che ne hanno bisogno. Vantaggi: leggibilità (la pt originale resta visibile nel codice = facile cross-reference con il design), unica fonte di verità del denominatore, propagazione esplicita evita catture implicite ambigue. Esempio: `song name 28pt` → `.font(.jbMono(.bold, size: 28 * scaleFactor))` (era `geo.size.width * 0.065`).
- **`scaleFactor` propagation pattern** (V23 — NUOVO): `LiveView` calcola `scaleFactor` dentro il `GeometryReader { geo in ... }` come `let scaleFactor: CGFloat = geo.size.width / 390`. Lo passa come parametro a tutti i sub-View della Vista LIVE che hanno callsite font. ButtonStyle (es. `OverlayStopButtonStyle`) riceve `scaleFactor` come parametro all'init, NON cattura dall'ambiente. Sub-component nested (es. `MixerChannelView` dentro `MixerOverlayView`) ricevono propagazione esplicita dal parent. **Niente cattura implicita.**
- **TD #23 chiuso V63** post-test su iPhone 13 (verde pixel-identico, `scaleFactor = 1.0`) + iPad portrait (verde proporzionato, `scaleFactor ≈ 1.97` su iPad pre-2018 a 768pt). Validato empiricamente, NON più tech debt.
- **Backlog CD raccolto in sessione 17-18/05/2026** (CD-1 schermata iniziale Vista LIVE "standby vestito", CD-2 perimetro rosso pulsante standby tra canzoni, CD-3 bottone "Ricomincia setlist" a fine setlist). Da consegnare a CD nel brief Fase 4 Vista Emergenza.

Tutto il resto invariato da V22: identità progetto (iPhone + iPad universal portrait v1), modello dati, token visivi, contratti Layer 3 esistenti, specifica vincolante L1.b "Fade scatta SOLO a fine vera", Task D (chiuso V53), Limite v1 Modalità Direttore, struttura file, backlog, decisioni UX 09/05, decisioni V22 (Strada A scaling proporzionale, TARGETED_DEVICE_FAMILY universal, API vietate Dynamic Type).

---

## Identità progetto

**Q-BEATS** — metronomo e sequencer live nativo iOS per musicisti professionisti.
**iPhone + iPad universal, portrait v1.** Livello: AUM / Cubasis / Drambo.

| Voce | Valore |
|---|---|
| Bundle ID | `com.bullfrog.qbeats` |
| Team ID | `X42CX3ZP3T` |
| iCloud Container | `iCloud.com.bullfrog.qbeats` |
| iOS deployment target | 16.0 |
| **Device family v22** | **Universal — `TARGETED_DEVICE_FAMILY` non impostato in `project.yml`, default Xcode `1,2` (iPhone + iPad). Decisione esplicita V55** |
| **Orientation v1** | **Portrait obbligato su tutti i device. Landscape iPad ("Vista Bella v2") rimandato a v2 reale** |
| **Layout strategy v1** | **Stesso layout componenti per tutti i device (Strada A — scaling proporzionale). Font/spacing ≥ 20pt tramite `pt_originale * scaleFactor` con `scaleFactor = geo.size.width / 390` (V23). Strada B (layout iPad dedicato multipanel) rimandata a v2 reale** |
| Repository | `github.com/19Bullfrog78/Q-BEATS` |

**Attori:**
- **Mauro** — supervisore, decisore, tester su device (Windows-only, debug via iMazing Console)
- **Claude referee** — arbitro tecnico senior, review ogni decisione architetturale
- **Claude Code (CC)** — implementazione Swift/SwiftUI Layer 3
- **Claude Design (CD)** — wireframe, mockup, specs visive — nessun codice Swift

**Flusso handoff:** CD produce → referee valida → Mauro approva → CC implementa.

**Device:**

| Device | Ruolo | Connettore | `geo.size.width` portrait |
|---|---|---|---|
| iPhone 13 | Sviluppo e test (baseline scaling — `scaleFactor = 1.0`) | Lightning | **390pt** (misurato empiricamente 18/05/2026) |
| iPhone 15+ | Produzione | USB-C — HDMI + audio interface simultanei via adattatore | ~393pt o 430pt secondo modello |
| iPad mini / iPad pre-2018 | Target leggio piccolo | Lightning/USB-C | **768pt** (`scaleFactor ≈ 1.97`) |
| iPad mini 8.3" (2021+) | Target leggio piccolo | USB-C | **744pt** (`scaleFactor ≈ 1.91`) |
| iPad Pro 11" | Target leggio | USB-C | **834pt** (`scaleFactor ≈ 2.14`) |
| iPad Pro 12.9" | Target leggio fisso | USB-C | **1024pt** (`scaleFactor ≈ 2.63`) |

**Hardware validato:** Behringer UMC404HD (4 uscite, class-compliant) · Adattatore Ticenpe MFi Lightning→USB-A · Akai MPK Mini 3 (validato con tap tempo MIDI Learn 17/05/2026)

---

## Architettura — Strada B (INVIOLABILE)

```
LAYER 3 — Swift / SwiftUI + ObjC++ Bridge        🔄 IN CORSO
LAYER 2 — CoreMIDI C-API + Sequencer PPQN-960 + Ableton Link    ✅ CHIUSO
LAYER 1 — Core Audio C-API + C++ DSP Engine      ✅ CHIUSO
```

**REGOLA ASSOLUTA:** qualsiasi problema visivo si risolve ESCLUSIVAMENTE in Layer 3. MAI toccare Layer 1/2 per problemi di carrozzeria.

---

## Modello dati — Ratificato

(invariato da V22, vedi `ARCHIVIO.MD/12_05_2026/BOX5_V22_12_05_2026.md` sezione "Modello dati — Ratificato")

---

## AudioEngine — @Published Properties

(invariato da V22)

---

## AudioEngine — Altri membri esposti (non @Published)

(invariato da V22)

---

## MIDI Learn — Ratificato

(invariato da V22)

---

## Token visivi — UNICA FONTE DI VERITÀ

(invariato da V22)

---

## Vista LIVE — Spec complete

### Grid verticale fissa

```
8%  header
10% slot metronomo
8%  bar counter
4%  micro bar
35% giant text (teleprompter)
2%  macro bar
10% NEXT zone (ex POI)
2%  handle strip
21% transport
```

Total: 100%.

### Header

```
[ ← BACK ]  [ LED·LED·LED  {song.name}  ·  {bpm}[🔒]  ·  {time sig} ]  [ SVG MUTE ]
```

**V23 — pattern font responsive**: tutti i font in formato `pt_originale * scaleFactor` dove `scaleFactor` è propagato come parametro da `LiveView` (calcolato come `geo.size.width / 390`).

- `song.name` — JetBrains Mono 700, **28pt * scaleFactor**
- BPM — JetBrains Mono 400, **17pt * scaleFactor**. Lucchetto SVG se `backtrackFilename != nil` (opacity 0.45)
- Time sig — JetBrains Mono 400, **15pt * scaleFactor**
- Mute button top-right: SVG speaker. Attivo = onde sonore bianco 85%. Muto = barra diagonale ambra `#f5b820`. Glyph `13pt * scaleFactor`.
- Chevron back: glyph `12pt * scaleFactor`
- 3 LED 5px (pt assoluti, sotto soglia 20pt), invisibili se non attivi
- Separatori `·`: `13pt * scaleFactor`
- Lock icon: `9pt * scaleFactor`
- Stato STOPPED: aggiunge separatore `·` + label "STOP" JBMono 600, **10pt * scaleFactor** caps, opacity 0.35

**Nota V23:** le dimensioni in pt riportate sono valori baseline iPhone 13 portrait (390pt larghezza, misurata empiricamente). Su iPad le stesse pt × scaleFactor producono dimensioni proporzionalmente maggiori (≈ 1.97× su iPad pre-2018, ≈ 2.63× su iPad Pro 12.9"). Calibrazione finale validata empiricamente su iPad portrait 18/05/2026.

### Slot metronomo

N slot = beatsPerBar. Flash singolo frame ~16ms, no decay, no easing.
- **Accento: `#28cd41` (V21)**
- Beat: `rgba(255,255,255,0.85)`
- Subdivisione: `rgba(255,255,255,0.20)`
- Off: `rgba(255,255,255,0.08)`

SubdivisionMultiplier = audio-only, zero impatto visivo.

### Bar counter

"Battuta X di Y". Display "— / —" se total ≤ 0.
- Count-in / Standby → "— / —"
- Loop ∞ → "Battuta X di ∞"
- Font: JetBrains Mono 500, **16pt * scaleFactor**

### Micro bar

Segmentata N segmenti = N battute della sezione corrente. (Niente font, solo Rectangle shapes — non interessato dal refactor V23.)

### Giant text (teleprompter)

`Section.name`. Se vuoto → BPM sezione come fallback. Mai coesistenti.

Font: Inter-Black, logica adattiva per lunghezza testo (in `TeleprompterCapsuleView.swift`):
- **`(56 * scaleFactor)` se `count ≤ 10`** caratteri
- **`(44 * scaleFactor)` altrimenti**

Count-in numero: JetBrains Mono 700, **80pt * scaleFactor**
BPM fallback (no section name): JetBrains Mono 700, **48pt * scaleFactor**
Label "BPM" fallback: JetBrains Mono 400, **11pt * scaleFactor**

### Macro bar (2%)

Segmentata N segmenti = N sezioni canzone. (Niente font.)

### Zona NEXT (10%)

Label statica `NEXT:` (JBMono semibold, **10pt * scaleFactor**, tracking 2, `rgba(255,255,255,0.25)`)
seguita da nome dinamico (Inter ExtraBold, **34pt * scaleFactor**, `rgba(255,255,255,0.45)`).

- Sezione successiva stessa canzone → `NEXT: {nextSection.name}`
- Ultima sezione + canzone successiva → `FINE · NEXT SONG: {nextSong.name}` (JBMono semibold, **10pt * scaleFactor**)
- Ultima sezione ultima canzone → zona vuota

### Handle strip (2%)

- Posizione: tra zona NEXT e Transport
- Contenuto: barretta 32×3pt, `rgba(255,255,255,0.20)`, corner radius 1.5 (pt assoluti, sotto soglia 20pt)
- Funzione: affordance visiva per gesture mixer

### Transport

Tasti: Play/Stop · Loop · KILL BASE · EMERG. Dettagli identici a V19.

Font interni gestiti da `RubberBtnView`: label **8pt * scaleFactor**, glyph **18pt * scaleFactor** se `glyph.count ≤ 3` altrimenti **13pt * scaleFactor**.

### Overlay mixer

Trigger apertura: swipe DOWN da zona estesa (Teleprompter+MacroBar+NEXT+HandleStrip = 49% schermo).
- DragGesture(minimumDistance: 10), threshold > 15
- Apparizione **istantanea** (zero animazione)

Trigger chiusura: tap.
- Tap sul pannello mixer → chiude
- Tap su `Color.clear` 49% sopra il pannello → chiude
- Sliders consumano gesture propri
- Chiusura **istantanea**

Aspetto:
- Pannello altezza 21% schermo
- Background `#16161a` (Surface token)
- 4 slider verticali: CLICK / BACKT / CH3 / CH4
- CH3/CH4 grayed out in modalità Base hardware
- Label canale (CLICK/BACKT/CH3/CH4): JBMono medium, **9pt * scaleFactor**

### Overlay Standby (tra canzoni)

`StandbyOverlayView` mostra il nome canzone successiva al centro schermo.
- Font: Inter-Black, **52pt * scaleFactor**
- Pulse animation: `easeInOut(duration: 2.2).repeatForever(autoreverses: true)` su `opacity` (0.45 ↔ 1.0)
- `GeometryReader` interno preservato — serve per layout verticale (`Spacer 0.27 × height`), NON per scaling font (quello arriva da parent via parametro `scaleFactor`)

### Overlay Stop (pausedAwaitingChoice)

`OverlayStopView` mostra 2 bottoni "Riprendi da X" / "Dall'inizio · Y".
- Background semi-trasparente `Color.black.opacity(0.65)` (intenzionale — overlay stop intermedio)
- Bottoni con `OverlayStopButtonStyle`: JBMono bold, **15pt * scaleFactor**

### Overlay Fine Setlist

`FineSetlistView` mostra "FINE SETLIST" + 2 bottoni "TORNA A SETLIST" / "RICOMINCIA".
- Background: `Color(hex: "#0e0e10")` — **V23: deve essere opacity 1.0** (TD #43 aperto in BOX3 V63, da fixare in Step 6: `.opacity(0.95)` è errore di copy-paste da `OverlayStopView`)
- Testo "FINE SETLIST": JBMono bold, **28pt * scaleFactor**, tracking 2
- Bottoni con `OverlayStopButtonStyle` (riusato da OverlayStopView): JBMono bold, **15pt * scaleFactor**

### Stati Vista LIVE

(invariati da V19)

### Comportamenti ratificati Vista LIVE — V21

(invariati da V21)

### Invarianti Vista LIVE

(invariati da V19)

---

## Vista LISTA — Spec complete

(invariati da V19)

---

## Modalità Vista — UX-9, UX-10, UX-11

(invariati da V19; UX-11 ratificata 09/05: long press confermato come gesture BPM Vista LIVE.)

---

## Invarianti tecnici Layer 3 — INVIOLABILI

| Regola | Dettaglio |
|---|---|
| Feedback visivo beat | Callback C++ → dispatch main via `PassthroughSubject` — MAI timer SwiftUI |
| `beatTickSubject` | `PassthroughSubject<Int, Never>` — MAI `@Published Double` per tick |
| `if isBeat` non `guard...continue` | Il `continue` rompe schedulazione audio subdivision |
| Cambio BPM sezione | `scheduleBPMChange` — sample-accurate al downbeat |
| `setBPM` vs `scheduleBPMChange` | `setBPM` = immediato (UI/Link/tap). `scheduleBPMChange` = cambio sezione |
| Backtrack | `AVAudioPlayerNode` in `AVAudioEngine` — MAI `AVPlayer` |
| Streaming backtrack | VIETATO |
| Route change | Clock C++ non si ferma |
| `midi_engine_start()` | Solo in `init()` — MAI in `start()`. Spostato dopo `setupGraph()` |
| `midi_engine_stop()` | RIMOSSO da `stopSync()` — MIDI sempre attivo |
| `os_log` | Unico debug — `print()` non catturato da iMazing |
| `@Published` assignment | ESCLUSIVAMENTE su main. Due forme equivalenti: (a) `DispatchQueue.main.async`; (b) tipo `@MainActor` a livello di classe (vedi `QBeatsStore`) — garanzia più forte, compile-time, non richiede `DispatchQueue` esplicito |
| `UIBackgroundModes: audio` | In `project.yml` — non toccare |
| **Portrait + universal v1 (V22)** | **Portrait obbligato su tutti i device (iPhone + iPad). Universal default Xcode `1,2`. Landscape iPad ("Vista Bella v2") rimandato a v2 reale** |
| `SwiftUI.Section` | Qualificare sempre fino a TD-1 risolto |
| DebugView | Solo `#if DEBUG` — mai in produzione |
| RT thread | Zero malloc/free/new/delete/ARC/ObjC/mutex/I-O |
| `MetSlotStripView` contratto | Riceve `pattern: [String]` e `beatActive: Int`. MAI riferimento diretto ad `AudioEngine` |
| `currentAccentPattern` mapping | `2→"accent"`, `1→"beat"`, `0→"subdiv"`. Conversione `[UInt8]→[String]` in LiveView |
| `totalBarsInSection` | Legge `repetitions`, NON `beatsPerBar` |
| Glyph STOP | Sempre "■" — mai "⏹" |
| Mute click UI | SVG speaker — mai emoji |
| `RubberBtnView` | Parametro `accentColor: Color? = nil`. V23: parametro `scaleFactor: CGFloat` (propagato da TransportView) |
| Link — init silente | `ABLLinkSetActive(false)` subito dopo `ABLLinkNew` |
| Link — fresh play branching | Modello a 4 rami: (peers==0 && !isPlaying) → standalone puro; (_linkMode == .direttore, qualsiasi stato peer) → direttore-standalone, detta la timeline con start_at_beat_zero (Director comanda sempre — i peer si adeguano); (collaborativa con peer in play) → join_running_session; resume → start_at_beat. Build #309 esteso 28/05/2026. Nota: in .direttore, start_at_beat_zero è chiamato anche con peers > 0. Comportamento progettato e ratificato. |
| Link — `start(resumeAtBeat:)` | Parametro `skipLinkWait` rimosso. Distinzione standalone/shared via probe + num_peers. Build #309 |
| Link — preference pane | `ABLLinkSettingsSheetView` sempre accessibile via Button in SettingsView quando linkEnabled. Commit `a5451bd` |
| `isIdleTimerDisabled` | Gestione centralizzata su root view via `onChange(of: scenePhase)`: true se `.active`, false altrimenti. Commit `341559d` |
| AppDelegate — applicationDidBecomeActive | V20 — al ritorno foreground, se `linkEnabled == true` ri-asserisce `setLinkEnabled(true)`. LinkKit best practice. Risolve "Link rotto mid-session". Commit `9a2e529` |
| Link — modalità Direttore/Collaborativa | V20 — `appSettings.linkMode` controlla comportamento Link. `_linkMode` audioQueue-private aggiornato in `applySettings()`. Default `.collaborativa` (cambiato da `.direttore` in `cb92faa` 24/05/2026). Commit `c8434b3`. V24 28/05/2026: guard start/stop e BPM estesi a tutti gli stati (`isRunning` rimosso). Phase guard invariato (implicito in play — vive dentro `scheduleNextBuffer`). Ogni callback documentato separatamente nelle righe seguenti. |
| Link — Direttore tempo callback | V20 — Re-broadcast del proprio BPM quando peer prova a cambiarlo, vincendo sempre la negoziazione. Check `bpm != _audioBPM` evita loop di re-broadcast quando peer riceve il valore Q-B e ritorna lo stesso. V24 28/05/2026: guard esteso a tutti gli stati — `if _linkMode == .direttore` (rimosso `isRunning`). Pre-fix: Director in stop avrebbe adottato BPM del peer (Bug 5-BPM latente). Director è sorgente unica del tempo in ogni stato. Commit `a42e877` + `4375ee3` |
| Link — Direttore phase sync | V20 — Skip silenzioso del `link_engine_sync_phase` quando in director play |
| Link — Direttore start/stop callback | V20/V24 — Ignora start/stop da peer in ogni stato (anche in stop). Guard: `if _linkMode == .direttore { return }`. Bug 5 fix 28/05/2026: pre-fix richiedeva `isRunning`, Director in stop accettava start da peer Collab via START LOCAL. |
| Link — UI Picker bloccato in play | V20 — Picker modalità in SettingsView ha `.disabled(audioEngine.isPlaying)` |
| Link — `_audioBPM` audioQueue-private | V20 — Mirror BPM su audioQueue. Aggiornato in `setBPM()`. NON aggiornato in `scheduleBPMChange()` (Task D — vedi sezione dedicata) |
| **Pattern reconciliation Layer 2 — Link** | **V21** — Schema `query → apply → propagate` per ogni flag persistito da LinkKit replicato in stato C++ locale. Boot reconciliation come secondo entry point Link (oltre a `ABLLinkSetIsEnabledCallback`). Indispensabile perché alcuni callback LinkKit non scattano se lo stato persistito è già allineato al target. Commit `97e2174` |
| **L1.a — Pattern closure end-of-section** | **V21** — AudioEngine NON deve avere hardcoded la decisione di "cosa fare a fine sezione". Il caller (Layer 3) passa una closure a `loadSection(beatsPerBar:repetitions:onEnd:)` che decide se: caricare prossima sezione, andare in standby, fermarsi. Commit `1da26bf` |
| **L1.a — Drain mode audio** | **V21** — A fine ultima ripetizione di una sezione, il flag `_sectionEndPending` in `scheduleNextBuffer` salta `metronome_processBuffer` per il buffer post-drain. Sample-accurate, deterministico, niente `asyncAfter` nel thread audio. Commit `f652f29` |
| **`AudioEngine.stop()` — allineamento stato** | **V21** — Ogni percorso di stop dispatcha `playbackState = .stopped` su main async dopo `stopSync()`. Pattern già usato in `handleStop()` per `.countIn` e in `restartFromBeginning()`. Senza questo, `TransportView` (che dichiara `let audioEngine` non `@ObservedObject`) non si re-rendera. Commit `217ebac` |
| **Pattern state-aware View — Vista LIVE** | **V21** — Ogni componente visivo che cambia aspetto in funzione dello stato di esecuzione (`BarCounterView`, `MicroSegBarView`, `MacroBarView`) riceve `state: LivePlaybackState` come parametro esplicito. MAI dedurlo implicitamente da campi numerici (es. `currentBar == 1` ≠ "siamo in play"). Commit `7720833` |
| **Pattern `sectionEndedSubject` + `sectionHold`** | **V21** — Per spegnimento sincronizzato di componenti UI multipli a fine ciclo naturale: AudioEngine espone `sectionEndedSubject: PassthroughSubject<Void, Never>`. LiveView riceve il subject, attiva `@State sectionHold: Bool` che funge da OVERRIDE del gate `state==.playing` per la durata del fade. Un `asyncAfter(60.0/currentBPM)` su main resetta `sectionHold` e `beatActive` insieme. Distinzione automatica autostop vs stop manuale via presenza/assenza dell'emissione del subject. Commit `5deabeb` + `89790fa` + `e38416e` |
| **`asyncAfter` cosmetico in UI — chiarimento** | **V21** — Il divieto "no asyncAfter con delay calcolato" stabilito in L1.a si applica al thread audio dove serve precisione al campione. In UI cosmetica su main thread è il meccanismo standard, ammesso. VIETATO invece l'`asyncAfter` "cosmetico per mascherare un problema di stato": va sempre preferito il modello di stato che non genera il problema in origine |
| **`let` vs `@ObservedObject` su View figli** | **V21** — TransportView dichiara `let audioEngine: AudioEngine`, NON si re-rendera sui cambi di proprietà di audioEngine. Si re-rendera solo quando cambia `session` (@ObservedObject). Conseguenza: ogni transizione di stato visibile in UI DEVE passare per `session.playbackState`. Soluzione adottata in P1+P3 invece di cambiare `let` in `@ObservedObject` |
| **Scaling responsive font (V23 — CORRETTO)** | **V23** — Tutti i font Vista LIVE in formato `pt_originale * scaleFactor` dove `scaleFactor: CGFloat = geo.size.width / 390` calcolato una sola volta in `LiveView.swift` (dentro `GeometryReader { geo in ... }`) e propagato come parametro CGFloat esplicito a tutti i sub-View. Pattern moltiplicativo invece di percentuali pre-calcolate (V22 era errato: baseline 430pt teorica, reale è 390pt iPhone 13). Baseline misurata empiricamente: `[QBEATS][ScaleFactor] geo.size.width = 390.000000` su iPhone 13 portrait (commit `adfcc39`). Specifica implementativa completa in BOX3 V63. ButtonStyle ricevono `scaleFactor` come parametro all'init (NON cattura ambiente). Sub-component nested ricevono propagazione esplicita dal parent (NON cattura implicita). |
| **API SwiftUI VIETATE per scaling device-aware (V22)** | **V22** — `@ScaledMetric`, `UIFont.preferredFont(forTextStyle:)`, `Font.preferredFont(...)`, `@Environment(\.sizeCategory)`. Tutte ancorate a Dynamic Type accessibility (preferenza testo dell'utente in Impostazioni iOS), NON a device size. Su iPad con accessibility default = identico a iPhone, esattamente il sintomo da evitare. Quando in futuro si aggiungerà supporto accessibility ipovedenti, allora `@ScaledMetric` SOPRA il geo.size scaling (composizione moltiplicativa) |
| **Spacing piccoli + frame fissi in pt assoluti (V22)** | **V22** — Spacing interni a `HStack`/`VStack` con valore < 20pt restano in pt assoluti (es. `spacing: 6` in TransportView resta 6, non `geo.size.width * 0.014`). V23 aggiunge: `frame(width:height:)` di bottoni icona (es. back/mute `34×34`) e bottoni overlay (`height: 56`) restano in pt assoluti — sono dimensioni hit-target/touch, non visuali |
| `Bridge MIDIEngineBridge.h` | Singola sorgente di verità. Disallineamento con `MIDIEngine.mm` = build rossa |
| Count-in BPM | Prima sezione canzone target |
| TempoMap | Campo opzionale in BacktrackFile. `nil` = BPM fisso invariato |
| La backtrack comanda | In modalità adaptive la sorgente di verità è la TempoMap, non il BPM utente |

---

## Specifica vincolante L1.b — Fade scatta SOLO a "fine vera"

(invariato da V22, vedi BOX5 V22 sezione "Specifica vincolante L1.b")

**Aggiornamento V23**: L1.b chiuso definitivamente in sessione 17/05/2026 (commit `dc1da0b`). TD #41 `pendingDisplayUpdate` flag + subscribe a `session.$beatActive` filter ==1 in SetlistRunner implementa la regola "fine vera vs transizione intermedia" senza fade spurio.

---

## Limite v1 — Modalità Direttore

(invariato da V22)

---

## Task D — Section BPM broadcast su Link

(invariato da V22, Task D chiuso V53)

---

## Struttura file Layer 3

```
ios_app/QBeats/
  AudioEngine.swift
  AppSettings.swift
  MIDILearnTypes.swift
  MIDILearnStore.swift
  ContentView.swift               ← V23: $audioEngine.beatsPerBar binding Picker (NON tocca scaling — modalità Studio metronomo libero)
  SettingsView.swift
  AppDelegate.swift               ← applicationWillTerminate + applicationDidBecomeActive
  QBeatsApp.swift
  DebugView.swift                 ← Solo #if DEBUG
  MIDIEngineBridge.h / MIDIEngine.mm
  MetronomeDSPBridge.h / .mm
  BTMIDICentralPickerView.swift
  MIDINetworkViewModel.swift
  LinkEngine.h / .mm
  LinkSettingsPresenter.h / .mm
  QBeats-Bridging-Header.h
  Models/
    Section.swift
    Song.swift
    Setlist.swift
    TimeSignature.swift
    LiveSession.swift
    LivePlaybackState.swift
  Store/
    QBeatsStore.swift
  UI/
    AppRootView.swift             ← onChange(of: scenePhase) per isIdleTimerDisabled
    BivioBoardView.swift
    SplashView.swift
    QStageRootView.swift
    LiveRootView.swift
    Live/
      LiveView.swift              ← GeometryReader principale + scaleFactor calcolo + propagazione (V23)
      LiveHeaderView.swift        ← V23: parametro scaleFactor, 8 callsite font scalati
      MetSlotStripView.swift      ← (no font, no scaleFactor)
      BarCounterView.swift        ← V23: parametro scaleFactor, 2 callsite font scalati
      SegBarViews.swift           ← (no font: MicroSegBarView + MacroBarView solo shapes)
      TeleprompterCapsuleView.swift ← V23: parametro scaleFactor, 4 callsite font scalati
      POIView.swift               ← V23: parametro scaleFactor, 3 callsite font scalati
      MixerOverlayView.swift      ← V23: parametro scaleFactor, propagato a MixerChannelView sub-component (1 callsite font)
      TransportView.swift         ← V23: parametro scaleFactor, propagato ai 6 RubberBtnView
      RubberBtnView.swift         ← V23: parametro scaleFactor, 3 callsite font scalati
      StandbyOverlayView.swift    ← V23: parametro scaleFactor, 1 callsite font (GeometryReader interno preservato per layout)
      OverlayStopView.swift       ← V23: parametro scaleFactor, propagato a OverlayStopButtonStyle (1 callsite font in ButtonStyle)
      FineSetlistView.swift       ← V23: parametro scaleFactor + TD #43 aperto (opacity 0.95 → 1.0 in Step 6)
```

---

## Backlog — feature da implementare

| # | Feature | Fase | Priorità | Specs CD |
|---|---|---|---|---|
| F2.1 | Splash animato + bivio Q-STAGE/LIVE | 2 | 🔴 | ✅ |
| F2.2 | Navigazione principale | 2 | 🔴 | ✅ |
| F2.3 | Selezione Setlist | 2 | 🔴 | ⏳ |
| F2.4 | Q-STAGE: libreria canzoni | 2 | 🔴 | ⏳ |
| F2.5 | Q-STAGE: editor canzone | 2 | 🔴 | ⏳ |
| F2.6 | Q-STAGE: libreria backtrack | 2 | 🟡 | ⏳ |
| F2.7 | Q-STAGE: gestione setlist | 2 | 🔴 | ⏳ |
| ~~Task D~~ | ~~`scheduleBPMChange` broadcast su Link~~ | ✅ CHIUSO V53 | — | — |
| ~~L1.b~~ | ~~Multi-section setlist — wiring Layer 3~~ | ✅ CHIUSO V62 + TD#41 v2 commit `dc1da0b` | — | — |
| ~~#23~~ | ~~Refactor font Vista LIVE responsive~~ | ✅ CHIUSO V63 commit `8a5432b` (V23) | — | — |
| **#43 (V63)** | **FineSetlistView opacity 0.95→1.0** | **6 (cleanup)** | 🟡 | — |
| F3.x | Vista LIVE — stati completi (Standby, Fine setlist, Swipe canzone) | 3 | 🔴 | ✅ |
| F4.x | Vista LISTA — completa | 4 | 🔴 | ✅ |
| F5.6 | Metronomo adattivo (aubio) | 5 | 🟡 | ✅ doc B7 |
| F6 | MIDI Learn UI completa | 6 | 🟡 | — |
| UX-1 | Banner post-VoIP | 3+ | 🟡 | — |
| UX-9 | Modalità Vista selezionabile | 2 | 🔴 | ✅ |
| UX-10 | Swipe orizzontale canzoni | 2 | 🟡 | ✅ |
| UX-11 | BPM swipe (solo senza backtrack) | 2 | 🟡 | ✅ (long press ratificato 09/05) |
| **CD-1** | **Schermata iniziale Vista LIVE "standby vestito"** (nome setlist + canzone, tap-anywhere start) | 3 | 🟡 | ⏳ raccolto V63 |
| **CD-2** | **Perimetro rosso sfumato pulsante su standby tra canzoni** | 3 | 🟡 | ⏳ raccolto V63 |
| **CD-3** | **Bottone "Ricomincia setlist" a fine setlist** (UX live) | 3 | 🟡 | ⏳ raccolto V63 |

**Schermate CD mancanti (bloccano CC):** Selezione Setlist · Lista Canzoni · Editor Canzone · Lista/Editor Setlist · Libreria Backtrack · Settings completi · CD-1/CD-2/CD-3 backlog raccolto.

---

## Decisioni UX 09/05/2026 — Ratificate

(invariate da V22)

---

## Decisioni V22 — Ratificate 12/05/2026 sera tardi

(invariate da V22, ma vedi correzione baseline V23 sotto)

---

## Decisioni V23 — Ratificate 18/05/2026 mattina

| Voce | Decisione |
|---|---|
| **Baseline scaling corretta** | iPhone 13 portrait = **390pt** (misurato empiricamente, NON 430pt come V22 dichiarava). Tutte le percentuali pre-calcolate di V22 sono state sostituite con il pattern `pt * scaleFactor` (V23). |
| **Pattern `pt_originale * scaleFactor`** | Sostituisce le percentuali pre-calcolate di V22. La pt originale del design resta visibile nel codice (es. `size: 28 * scaleFactor`), facilitando cross-reference con le specifiche tipografiche. Unica fonte di verità del denominatore (`390` calcolato una volta in `LiveView`). |
| **Propagazione `scaleFactor` esplicita** | Da `LiveView` a tutti i sub-View che ne hanno bisogno (via parametro `CGFloat`). ButtonStyle riceve all'init (NO cattura ambiente). Sub-component nested ricevono propagazione esplicita (NO cattura implicita). |
| **Spacing/padding/frame in pt assoluti** | V22 aveva soglia 20pt per spacing. V23 estende: `frame(width:height:)` di bottoni icona (`34×34`) e bottoni overlay (`height: 56`) restano in pt assoluti — sono dimensioni hit-target/touch, non visuali. |
| **Validazione empirica** | iPhone 13 portrait: `scaleFactor = 390/390 = 1.0` → layout pixel-identico al pre-refactor. iPad pre-2018 portrait (768pt): `scaleFactor ≈ 1.97` → proporzionato. Test verde 18/05/2026. |

---

## Cambio open per ratifica (da V19, invariato)

**Proporzioni layout Vista LIVE** — proposta in attesa di test su device con sessione live attiva e contenuti reali. Vedi V19 per dettagli.
