# REFERTO CC — A215 — PERCHÉ LA SCHERMATA DEL PLAYER SI CONTRADDICE

Da: CC · A: referee + Mauro · 25/08/2026 · Mandato: A215 (referee, riemissione
di A214→A213 fermati al cancello ID).
**ESITO: MISURE COMPLETE, SOLA LETTURA RISPETTATA.** Zero modifiche sotto
`ios_app/`, zero diff, zero commit, zero push.
Marcatura: **[M]** misurato alla fonte · **[R]** riportato · **[A]** giudizio mio.

**[M] HEAD a inizio mandato = HEAD a fine mandato =
`160b927575e1864908f8f8ca171e3be254ab48dc` · 0 tracciati modificati, 0 in stage**
(`git rev-parse HEAD` · `git status --porcelain --untracked-files=no | wc -l` → 0).
⇒ Ogni citazione `file:riga` di questo referto è ancorata a quello sha (R3),
e il disco coincide col commit per tutti i file citati.

Faccia del file: UTF-8, terminatori LF, CR=0 — dichiarata per la regola dei due file.

---

## 0 · CANCELLO ID — A215 LIBERO, rimisurato nell'istante prima di scrivere

Sonde (le stesse due forme, nome e contenuto, su tracciati E non tracciati;
il path E: è la gamba `FILE X CLAUDE.MD/HANDOFF`):

    git ls-tree -r --name-only HEAD | grep -c "A215"
    find . -name "*A215*" -not -path './.git/*' -not -path './.tmp.driveupload/*' | wc -l
    find "<gamba E:>" -name "*A215*" | wc -l
    git grep -l "A215" HEAD -- | wc -l
    grep -rl "A215" HANDOFF | wc -l     (e la stessa forma sulla HANDOFF di E:)

| ID | nome: git / discoC / discoE | contenuto: git / handoffC / handoffE |
|---|---|---|
| A215 | 0 / 0 / 0 | 0 / 0 / 0 |
| A211 (positivo) | 2 / 2 / 2 | 4 / 6 / 5 |

---

## 1 · LA CHIAVE DI TUTTO — tre vite diverse alimentano la stessa finestra

**[M]** La schermata del player è scritta da TRE oggetti con TRE cicli di vita
diversi, e il guasto osservato è la loro divergenza dopo un rimontaggio:

1. **`AudioEngine`** — globale, iniettato da `QBeatsApp`, vive per tutta l'app.
   La navigazione non lo tocca per decisione ratificata («navigazione ≠
   transport», `QLiveRootView.swift:78-85`): il back del player va a
   `navigate(to: .shows)` (`QLiveRootView.swift:178`) e **il click continua**.
2. **`SetlistRunner`** — vive nello SLOT `QLiveSession.runner`
   (`UI/QLive/QLiveSession.swift:44`), posseduto dalla stanza
   (`QLiveRootView.swift:76`). `install(_:)` **sostituisce sempre, anche a slot
   pieno** (`QLiveSession.swift:49-53` e `:69-71`): alla sostituzione
   il runner vecchio muore dentro install — «il vecchio runner perde qui il suo
   ultimo riferimento forte», parole del file.
3. **`LiveSession`** (il display) — `@StateObject` DI `LiveView`
   (`LiveView.swift:11`): **muore e rinasce a ogni smontaggio/rimontaggio del
   player**. È l'unico dei tre che riparte da zero al rientro.

**[M]** E le facce della schermata NON leggono tutte dalla stessa via.
Le quattro facce sono quattro sorgenti:

| faccia (video) | proprietà | via di alimentazione |
|---|---|---|
| intestazione BPM | `session.currentBPM` | **diretta dal motore**: `.onReceive(audioEngine.$currentBPM)` scrive subito (`LiveView.swift:315-317`), MA `primeDisplay` la sovrascrive una volta al montaggio (`SetlistRunner.swift:282`) |
| intestazione tempo + totale «of N» | `session.currentTimeSig`, `session.totalBarsInSection` | **bufferizzata**: con `audioEngine.isPlaying==true` l'evento finisce in `pendingBpb`/`pendingReps` (`LiveView.swift:322-323`, `:345-346`) e si applica **al primo beat tick** (`:373-389`) |
| teleprompter + NEXT | `session.currentSectionName`, `nextSectionName` | **solo dal runner**: censimento completo in §2 — gli unici scrittori sono `updateSessionDisplay` e il ramo standby di `SetlistRunner` |
| numero di battuta | `session.currentBar` | **calcolata in LiveView** dal tick del motore e da un'ancora locale: `currentBar = ((relativeTick-1)/bpb)+1` (`LiveView.swift:392-394`) — unico scrittore nel corpus |

---

## 2 · Q1 — ogni sito che assegna le proprietà di LiveSession

Sonda (copre l'universo: **[M]** ogni receiver di tipo `LiveSession` nel corpus
si chiama `session` — verificato con `grep -rn ': LiveSession' ios_app/QBeats
--include='*.swift'`, 10 dichiarazioni, tutte `session`):

    grep -rnE 'session\.(currentBar|totalBarsInSection|currentBPM|currentTimeSig|currentSectionName|nextSectionName|nextSongName|currentSongName|playbackState|beatActive|accentPattern|macroBarCurrent|macroBarTotal)[[:space:]]*=[^=]' ios_app/QBeats --include='*.swift'

R = `SetlistRunner.swift` · LV = `UI/Live/LiveView.swift` · TV = `UI/Live/TransportView.swift`.

| proprietà | sito | condizione |
|---|---|---|
| `currentSongName` | R:240 | dentro `updateSessionDisplay`, se `currentSong` e `currentSection` non nil |
| | R:388 | ramo standby della closure end-of-section: azzerata a `""` |
| `currentBPM` | R:282 | `primeDisplay`, dopo `guard currentSection` |
| | LV:316 | `.onReceive(audioEngine.$currentBPM)` — sempre, senza condizioni |
| `currentTimeSig` | LV:332 | evento `$beatsPerBar` con `audioEngine.isPlaying == false` |
| | LV:379 | nel handler `beatTickSubject`, solo se `pendingBpb != nil` |
| `currentSectionName` | R:241 · R:389 | come currentSongName |
| `nextSectionName` | R:242 · R:390 | idem |
| `nextSongName` | R:243 | `isLastSectionInSong ? nextSong?.name : nil` |
| | R:391 | standby: nil |
| `currentBar` | LV:394 | **unico scrittore**: a ogni tick, `((relativeTick-1)/bpb)+1` |
| `totalBarsInSection` | R:283 | `primeDisplay`: `Int(section.repetitions)` |
| | LV:348 | evento `$currentSectionRepetitions` con `isPlaying == false` |
| | LV:387 | al tick, se `pendingReps != nil` |
| `macroBarCurrent/Total` | R:244-245 | `updateSessionDisplay` |
| | R:392-393 | standby: 0 / 1 |
| `playbackState` | R:148 | `prepareAndStartCurrentSection` con `currentSection` nil → `.fineSetlist` |
| | R:308 | `primeDisplay` → `.standby` **SOLO da `.stopped`** (`if case .stopped`, R:307) |
| | R:382 | ramo standby (closure viva) |
| | R:411 | ramo fineSetlist (closure viva) |
| | LV:161 | tap BACK TO SHOWS in FineSetlistView → `.stopped` |
| | LV:286 | motore dice `.stopped` → mirrorato, MA con guardia: se la sessione è `.standby` o `.fineSetlist`, return (LV:280-285) |
| | LV:302 | motore `.countIn` → `.countIn(countdown: 4)` letterale |
| | LV:304 | motore `.playing` → `.playing` — **nessuna guardia** |
| | LV:310 | motore `.pausedAwaitingChoice` → `.overlayStop` |
| | TV:61 | tap Play con `currentLinkMode == .collaborativa` → `.waitingForDirector` |
| `beatActive` | R:383 | standby: 0 |
| | LV:299 | motore `.stopped` e `!sectionHold`: 0 |
| | LV:311 | overlayStop: 0 |
| | LV:393 | a ogni tick: `((relativeTick-1) % bpb)+1` |
| | LV:426 | asyncAfter del fade, se ancora `.stopped`: 0 |
| `accentPattern` | — | **ZERO SCRITTORI.** Sonda: `grep -rnE '\.accentPattern[[:space:]]*=[^=]' ios_app/QBeats --include='*.swift'` → 2 match, entrambi su tipi DIVERSI (`SongSection.swift:34`, `SectionEditorView.swift:226`), nessuno su LiveSession. Positivo, stessa forma: `\.beatActive[[:space:]]*=` → 5. Il default di `Models/LiveSession.swift:26` non viene mai toccato: la striscia slot usa `displayAccentPattern` di LiveView (`LiveView.swift:99`), non questa proprietà. |

---

## 3 · Q2 — property wrapper sotto UI/Live/ e UI/QLive/, con la view proprietaria

Sonda: `grep -rnE '@(State|StateObject|ObservedObject|EnvironmentObject)\b'
ios_app/QBeats/UI/Live ios_app/QBeats/UI/QLive --include='*.swift'`

| view | wrapper | cosa |
|---|---|---|
| `LiveView` | `@EnvironmentObject` | `audioEngine: AudioEngine` (:5) — iniettato a monte, `AppRootView` |
| | `@EnvironmentObject` | `runner: SetlistRunner` (:6) — iniettato dal gate `QLiveRootView.swift:178-179` |
| | `@StateObject` **possiede** | `session = LiveSession()` (:11) |
| | `@State` ×8 | vedi tabella sotto |
| `LiveHeaderView` | `@ObservedObject` | `session` (:4) — riceve quella di LiveView |
| | `@EnvironmentObject` | `audioEngine` (:5) |
| `TeleprompterCapsuleView` | `@ObservedObject` | `session` (:4) |
| `TransportView` | `@ObservedObject` | `session` (:4) · ⚠️ **`audioEngine` è `let` NON osservato** (:5): il glifo ■/▶ legge `audioEngine.isPlaying` (:31-32) ma la view si ri-renderizza solo quando `session` cambia |
| | `@EnvironmentObject` | `runner` (:6) |
| | `@State` | `killFlashing = false` (:21) |
| `MixerOverlayView` | `@ObservedObject` ×2 | `session` (:4), `audioEngine` (:5) — e un secondo `@ObservedObject audioEngine` nella struct interna (:43) |
| `StandbyOverlayView` | `@State` | `pulseOpacity = 0.45` (:13) |
| `WaitingForDirectorView` | `@State` | `pulse = false` (:37) — file dichiaratamente presentational |
| `QLiveRootView` | `@State` | `page: QLivePage = .shows` (:46) · `selectedSetlist: Setlist? = nil` (:48) |
| | `@StateObject` **possiede** | `roomSession = QLiveSession()` (:76) |
| `QLiveShowDetailView` | `@ObservedObject` | `store = QBeatsStore.shared` (:105) |
| `QLiveShowsView` | `@ObservedObject` | `store = QBeatsStore.shared` (:54) · `@State searchText` (:57) |

**[M] Gli otto `@State` di LiveView — valore iniziale e OGNI scrittore**
(sonda: `grep -nE '(sectionStartTick|pendingSectionStart|sectionHold|displayBpb|displayAccentPattern|pendingBpb|pendingAccentPattern|pendingReps)[[:space:]]*=' ios_app/QBeats/UI/Live/LiveView.swift`):

| @State | init | scrittori (riga → condizione) |
|---|---|---|
| `sectionStartTick` | 1 (:16) | :363 → `tickN == 1` (avvio fresco: `1 - startBeatOffset`) · :368 → `pendingSectionStart == true` (`= tickN`) |
| `pendingSectionStart` | false (:17) | :308 → motore passa a `.playing` (false) · :364, :369 → consumato (false) · **:404 → `.onReceive(runner.$currentSectionIdx)`: true, A OGNI CONSEGNA — compresa quella iniziale della sottoscrizione** |
| `sectionHold` | false (:20) | :307 (playing→false) · :312 (overlayStop→false) · :421 (sectionEndedSubject→true) · :425 (asyncAfter→false) |
| `displayBpb` | 4 (:41) | :217 (onAppear, dal motore) · :245 (onAppear, dalla sezione del runner) · :329 (evento con motore fermo) · :374 (tick applica pending) |
| `displayAccentPattern` | [2,1,1,1] (:42) | :218 · :246 · :340 · :383 (stessi quattro momenti) |
| `pendingBpb` | nil (:43) | :323 (evento con `isPlaying`) · :380 (consumato) |
| `pendingAccentPattern` | nil (:44) | :338 · :384 |
| `pendingReps` | nil (:45) | :346 · :388 |

---

## 4 · Q3 — sectionStartTick e pendingSectionStart

Dichiarazioni: `LiveView.swift:16-17`, entrambi `@State private` di LiveView —
**quindi rinascono ai valori iniziali (1, false) a ogni rimontaggio del player.**

Scrittori e condizioni: tabella in §3. I due punti che decidono il guasto:

- **`pendingSectionStart = true` a :404** scatta a ogni consegna di
  `runner.$currentSectionIdx`. `@Published` consegna il valore CORRENTE
  all'atto della sottoscrizione — fatto sorgentato in casa con la
  documentazione Apple (`LiveView.swift:272-277`). ⇒ **al montaggio della view
  il flag si arma da solo**, anche se il runner non è mai avanzato.
- Al primo tick con `tickN != 1` e flag armato, **:368 ri-ancora il contatore:
  `sectionStartTick = tickN`** ⇒ `relativeTick = 1` ⇒ `currentBar = 1` (:392-394).

---

## 5 · Q4 — beatTickSubject e beatTickCounter

**[M]** `beatTickSubject`: `let beatTickSubject = PassthroughSubject<Int, Never>()`
— `AudioEngine.swift:121`. Emette in UN SOLO punto: `AudioEngine.swift:2377-2381`,
dentro il loop dei beat event di `scheduleNextBuffer`, SOLO per eventi con
`isBeat` (:2376), con dispatch su main del valore incrementato.

**[M]** `beatTickCounter`: `private var`, `AudioEngine.swift:122`. TUTTI i siti
di assegnazione (sonda: `grep -n 'beatTickCounter' ios_app/QBeats/AudioEngine.swift`
→ 28 match, di cui assegnazioni TRE):

| sito | cosa | quando |
|---|---|---|
| :878 | `= 0` | dentro `start()` — ogni avvio del motore |
| :1654 | `= 0` | dentro `stopSync()` — ogni stop |
| :2377 | `+= 1` | ogni beat event |

**Domanda diretta: un cambio di sezione SENZA fermata azzera quel contatore?
NO.** Fonte: il ramo SEAMLESS (`AudioEngine.swift:2505-2608`) azzera
`_sectionBeatCounter` (:2539) — che è un ALTRO contatore, quello del limite di
sezione — e **non contiene alcuna scrittura di `beatTickCounter`**: fra i tre
siti sopra nessuno cade nell'intervallo 2505-2608. Il commento di progetto lo
dice anche in chiaro: «un avanzamento mid-canzone NON riavvia il motore →
tickN != 1» (`LiveView.swift:359-361`). ⇒ **beatTickCounter non si azzera al cambio di sezione**:
cresce monotono dall'ultimo `start()`. Il reset del CONTEGGIO A DISPLAY è
interamente a carico di Layer 3 (ancora `sectionStartTick`, §4).

---

## 6 · Q5 — closure e sottoscrizioni di SetlistRunner che catturano session o audioEngine

Sonda: `grep -n 'sectionEndedClosure\|beatTickSubscribed\|cancellables'
ios_app/QBeats/SetlistRunner.swift` + lettura integrale del file (416 righe).

**Ne esistono DUE, e nessuna terza:**

**(1) La sottoscrizione display** — `session.$beatActive.filter{$0==1}.sink`
(`SetlistRunner.swift:179-188`). Cattura `[weak self, weak session]`. Costruita
in `prepareAndStartCurrentSection` sotto guard `if !beatTickSubscribed` (:178),
flag messo a true a :189. **Siti che la ricostruiscono: ZERO** — nel file
`beatTickSubscribed` non viene mai riportato a false e `cancellables` non viene
mai svuotato (le uniche occorrenze sono :43 dichiarazione, :188 store).
⚠️ **[A] Conseguenza strutturale: la sottoscrizione resta legata alla PRIMA
LiveSession con cui il runner è stato avviato**, per tutta la vita del runner.

**(2) La closure end-of-section** — costruita da `makeSectionEndedClosure`
(:319-415), cattura `[weak self, weak audioEngine, weak session]` (:321) con
`guard let self, let audioEngine, let session else { return }` (:322).
Costruita in `prepareAndStartCurrentSection` sotto `if sectionEndedClosure == nil`
(:194-196). **Siti che la ricostruiscono: ZERO** — `sectionEndedClosure` non
viene mai riassegnata a nil (occorrenze: :35 dichiarazione, :194-197 build lazy,
:337 lettura). È autopropagante: viaggia in ogni `loadSection`/`preloadNextSection`
(:209-211, :218-225, :364-371) e il motore la ri-dispatcha ai confini.

**Le guardie che impediscono la ricostruzione:** `beatTickSubscribed` (:48,
:178) e il check `== nil` (:194). **[M] Non esiste nel file alcun percorso che
le invalidi quando cambia la session o l'engine passati agli entry point.**

**Dentro la closure, chi tocca il motore:** ramo standby →
`audioEngine.stop()` (:404); ramo fineSetlist → `sectionEndedSubject.send()` +
`audioEngine.stop()` (:410-412). ⚠️ **[A] Se il guard di :322 fallisce (runner
o session morti), questi stop NON avvengono: nessun altro sito li fa per lui**
(vedi §10-D e IPOTESI).

---

## 7 · Q6 — chi costruisce il runner, chi installa, e il confronto che non esiste

Sonde: `grep -rn 'SetlistRunner(' ios_app/QBeats --include='*.swift'` ·
`grep -rn '\.install(' ios_app/QBeats --include='*.swift'`

- **Costruzione: UN SITO.** `QLiveShowDetailView.swift:427` —
  `onStart(SetlistRunner(setlist: setlist, store: store))`, dentro il Button
  START SHOW (`startfoot`, :416-483; disabilitato solo per scaletta vuota, :483).
  **Costruisce SEMPRE un runner nuovo: nessuna condizione oltre `isEnabled`.**
- **install: UN SITO.** `QLiveRootView.swift:122` — `roomSession.install(runner)`
  nella closure `onStart`, seguito nello stesso gesto sincrono da
  `navigate(to: .metronome)` (:123). `install` sostituisce incondizionatamente
  (`QLiveSession.swift:69-71`), per scelta documentata (:49-53, pensata per il
  caso «secondo show della serata»).
- **Confronto fra la setlist richiesta e quella eventualmente già in esecuzione:
  ZERO.** Due sonde: **(a)** `grep -cE 'roomSession|audioEngine'
  ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift` → **0** — il file che
  costruisce il runner **non ha accesso** né allo slot né al motore: i suoi soli
  ingressi sono `setlist`, `onBack`, `onStart` (:103-105). Positivo, stesso file,
  stessa forma: `\bstore\b` → 6. **(b)** nel gate `.metronome`
  (`QLiveRootView.swift:129-179`) l'unico controllo è `if let runner` —
  presenza, non identità. ⇒ **zero confronti fra la scaletta chiesta e quella in corsa**:
  premere START SHOW sullo show che sta già suonando produce runner nuovo +
  session nuova sopra il motore che continua la vecchia.

---

## 8 · Q7 — primeDisplay: chiamanti, condizione, e chi riscrive playbackState nel montaggio

- **Chiamanti: UNO.** Sonda `grep -rn 'primeDisplay' ios_app/QBeats
  --include='*.swift'` → definizione (R:279) + `LiveView.swift:239`
  (nell'`onAppear`). Nessun altro.
- **Sotto quali valori arma lo standby: SOLO `.stopped`.** `SetlistRunner.swift:307-309`:
  `if case .stopped = session.playbackState`, poi `.standby(nextSongName:
  currentSong.name)`. Il commento di progetto (R:297-306) la chiama «lista di
  permessi»: la lista dei permessi ha un solo membro, su otto casi possibili di
  `LivePlaybackState` (`Models/LivePlaybackState.swift:3-21`).
- **Chi altro scrive `playbackState` nello stesso ciclo di montaggio — in ordine:**

  1. **Le sottoscrizioni `.onReceive` si creano col body.** Fra queste
     `.onReceive(audioEngine.$playbackState)` (LV:250): un publisher `@Published`
     consegna il valore corrente all'atto della sottoscrizione (fatto sorgentato
     in casa: LV:272-277 con URL Apple). Col motore che suona, la consegna è
     `.playing` → **LV:304 scrive `session.playbackState = .playing`, senza
     alcuna guardia** (la guardia di LV:280-285 protegge solo il case `.stopped`).
  2. **`onAppear` → `primeDisplay`** (LV:239): trova `.playing` → il guard di
     R:307 fallisce → **niente standby**.

  ⛔ **[M→limite, R4] L'ordine relativo 1→2 non è dimostrabile dal codice fermo**:
  dipende da quando SwiftUI attiva le sottoscrizioni rispetto a `onAppear`, e in
  casa il comportamento del framework su montaggio/rilascio è già marcato NON
  SORGENTATO (`QLiveRootView.swift:64-67`). **Ma l'esito è identico nei due
  ordini:** (a) consegna prima → mai armato; (b) `onAppear` prima → armato
  `.standby` e sovrascritto dalla consegna `.playing` appena la sottoscrizione
  nasce — una finestra sotto il campionamento (il referee dichiara invisibile
  qualunque overlay < ~100 ms). In entrambi i casi: **player montato acceso,
  nessun overlay stabile.**

---

## 9 · Q8 — il contatore del motore all'istante del rimontaggio: leggibile? NO

**[M]** `beatTickCounter` è `private var` (`AudioEngine.swift:122`) senza
getter, senza `@Published`, senza specchio. Fuori dal playback non viene mai
esternato: l'unica uscita è `beatTickSubject`, che emette SOLO quando il motore
genera beat (:2377-2381). All'istante del rimontaggio — fra `onAppear` e il
primo tick — **il suo valore non è osservabile da nessuna superficie**: non dal
codice fermo (è stato runtime), non dai log esistenti in quel preciso istante.

**[M] Cosa esiste già di vicino:** un log periodico ogni 32 tick che stampa
`beatTick` (`AudioEngine.swift:2402-2406`, `[Q-BEATS][SinkDiag-AQ]`), e i log
`[Q-BEATS][DRAIN]`/`[Q-BEATS][SEAMLESS]` ai confini con `beatTick` incluso
(:2218-2220). Manca il MARCATORE dell'istante di rimontaggio da correlare.

**[A] Strumentazione MINIMA e PASSIVA che lo renderebbe leggibile su device
(descritta, NON scritta — come da mandato):** un singolo `os_log` one-shot
nell'`onAppear` di `LiveView` (file: `ios_app/QBeats/UI/Live/LiveView.swift`,
accanto a `primeDisplay`) che stampi ciò che è già pubblico —
`audioEngine.isPlaying`, `playbackState`, `beatsPerBar`,
`currentSectionRepetitions`, `currentBPM` — più, nel handler
`beatTickSubject` della stessa view, un one-shot al PRIMO tick post-montaggio
con `tickN` e `sectionStartTick`. Il `tickN` del primo tick, correlato ai
`SinkDiag` già esistenti, ricostruisce il valore all'istante del montaggio con
errore ≤ 1 beat, senza toccare AudioEngine né il DSP. In alternativa, una riga
`os_log` dentro `AudioEngine` che esponga `beatTickCounter` andrebbe collocata
nel medesimo punto del log SinkDiag (:2402) cambiandone il modulo — ma la prima
forma non tocca il motore affatto.

---

## 10 · LE RISPOSTE AI SETTE DUBBI — meccanismi misurati

**D1 — perché BPM e totale, adiacenti, si comportano all'opposto.**
[M] Sono due VIE diverse (§1). `currentBPM` è scritto direttamente a ogni
EVENTO del motore (LV:316) — e il motore emette `currentBPM` solo quando
cambia qualcosa (`setBPM` :1129, o il broadcast al tick bersaglio del cambio
sezione :2467-2469). Al montaggio la consegna iniziale porta il valore della
sezione in corso (120), ma subito dopo `primeDisplay` lo SOVRASCRIVE con la
prima sezione del runner nuovo (100, R:282). Da lì **nessun nuovo evento fino
al confine di sezione** ⇒ il 120 non si rivede mai: si vede 100, poi 140.
Il totale invece viaggia bufferizzato: la consegna iniziale (3) finisce in
`pendingReps` (LV:346) perché `isPlaying==true`, e **si applica al primo tick**
(LV:387) — DOPO che `primeDisplay` ha scritto 12 (R:283). ⇒ il totale sopravvive perche nessuno lo sovrascrive
dopo il tick. Il primo fotogramma del rientro (`100 4/4 | Bar 1 of 12`) è
esattamente lo stato post-onAppear/pre-primo-tick; il secondo (`… of 3`) è il
primo tick che applica il pending; il `140 3/4 … of 2` è il confine successivo.
**Stessa finestra, quattro sorgenti: per questo si contraddice.**

**D2 — perché intestazione e totale cambiano nel tempo e il teleprompter no.**
[M] Intestazione e totale hanno come sorgente i `@Published` del MOTORE, che è
vivo e condiviso. Il teleprompter ha come UNICA sorgente il RUNNER (§2:
`currentSectionName`/`nextSectionName` hanno scrittori solo in
`updateSessionDisplay` e nel ramo standby). Dopo il rientro nessun runner
collegato alla session nuova gira più (D3) ⇒ il teleprompter resta orfano.

**D3 — da dove vengono INTRO 100 / VERSE 120 al rientro, e cosa dovrebbe farli cambiare.**
[M] Sono RICALCOLATI al montaggio, non residui: la session nuova nasce vuota
(`""`, `Models/LiveSession.swift:11-16`) e `primeDisplay` → `updateSessionDisplay`
(R:281 → R:238-246) li scrive dagli indici del runner NUOVO, che valgono (0,0)
⇒ prima sezione della prima canzone: `Intro 100`, next `Verse 120`. Coincidono
con l'inizio del video perché sono la stessa fixture a indici zero, non perché
siano rimasti lì. Cosa dovrebbe farli cambiare: (a) `startSetlist`/
`startCurrentSong` (mai chiamati dopo il rientro: nessun tap su Play/overlay)
oppure (b) la sottoscrizione a `$beatActive` + `pendingDisplayUpdate` del
runner — che per il runner NUOVO **non esistono ancora** (nascono solo in
`prepareAndStartCurrentSection`, mai girato: closure nil, flag false), e per il
runner VECCHIO appartengono a una session morta e a un runner morto dentro
`install` (§6, §7). ⇒ Non c'è alcun percorso vivo che li aggiorni.

**D4 — il contatore supera il totale: chi dovrebbe impedirlo?**
[M] NIENTE, nell'albero. `currentBar` ha un solo scrittore (LV:394), che è
aritmetica pura sul tick relativo: nessun confronto con `totalBarsInSection`
in nessun punto (l'unico `min`/`max` nel handler è `max(1, Int(displayBpb))`,
LV:390, che protegge il divisore). `BarCounterView` è display puro
(`BarCounterView.swift:20-33`): l'unica logica è `total == -1 → ∞` e
`total > 0 → ready`; stampa `current` qualunque esso sia. I due numeri della
coppia `Bar X of Y` provengono da vie che non si parlano (X: tick + ancora
locale; Y: pending del motore o primeDisplay) e nessun sito li riconcilia.

**D5 — perché riparte da 1, e da cosa dipende il punto di partenza.**
[M] Dall'ancora locale: al montaggio la consegna iniziale di
`runner.$currentSectionIdx` (runner nuovo, valore 0) arma `pendingSectionStart`
(LV:404); il PRIMO tick post-montaggio trova `tickN != 1` (il motore non è mai
ripartito: contatore monotono, §5) e flag armato ⇒ `sectionStartTick = tickN`
(LV:368) ⇒ `relativeTick = 1` ⇒ `currentBar = 1` (LV:392-394). **Riparte da 1
perché l'ancora è per costruzione il tick corrente**: il punto di partenza è
l'istante del montaggio, non un confine musicale. (Il ramo `tickN == 1`,
LV:362-364, è per l'avvio fresco del motore: non è questo caso.)

**D6 — perché il player non si monta fermo e armato.**
[M] Perché l'armamento è concesso SOLO da `.stopped` (R:307, §8) e il motore
sta suonando: la consegna iniziale di `$playbackState` è `.playing` e LV:304 la
mirrora senza guardie. Nei due ordini possibili di montaggio l'esito è lo
stesso (§8): overlay mai armato, o armato e sovrascritto sotto la soglia di
campionamento. Il primo fotogramma (`Bar 1 of 12`) mostra i dati di
`primeDisplay` SENZA overlay: coerente con entrambi. Il glifo ■ e il «player
acceso»: `TransportView` legge `audioEngine.isPlaying` (TV:31-32), che è true.

**D7 — la lista Shows non segnala lo show che suona: per costruzione?**
[M] SÌ. Sonda: `grep -nE 'audioEngine|runner|roomSession|isPlaying|playbackState'
ios_app/QBeats/UI/QLive/QLiveShowsView.swift` → **0 occorrenze** (positivo,
stesso file: `etlist` → 11). Idem il dettaglio: `roomSession|audioEngine` → 0
(§7). La lista legge solo `QBeatsStore` (righe, conteggi, badge READ-ONLY —
stato dei DATI, non del transport). L'unico osservabile di stanza,
`QLiveSession`, pubblica per contratto la sola apparizione/scomparsa del runner
(`QLiveSession.swift:26-38`) — e nessuna delle due view lo riceve comunque.
Non esiste una via cablata da cui la lista POSSA sapere che qualcosa suona.

---

## 11 · LA FIXTURE — misurata nel codice, non dedotta dal video

**[M]** `Test Setlist L1.b` è hardcoded in `DebugView.swift:504-537`
(`loadTestDataL1b`, iniettata via `QBeatsStore.shared.injectTestData` :536):

| song | sezione | BPM | metro | ripetizioni |
|---|---|---|---|---|
| Test Song A | `Intro 100` | 100 | 4/4 | **12** |
| | `Verse 120` | 120 | 4/4 | **3** |
| | `Bridge 3/4` | **140** | **3/4** | **2** |
| Test Song B | `Slow 90` | 90 | 4/4 | 3 |
| | `Build 110` | 110 | 4/4 | 12 |

Combacia riga per riga con le coppie osservate: `100·4/4 of 12` = Intro ·
`120·4/4 of 3` = Verse · `140·3/4 of 2` = Bridge · nomi teleprompter compresi
(`INTRO 100`, `VERSE 120`, `BRIDGE 3/4` maiuscolizzati da
`TeleprompterCapsuleView.swift:41` e `POIView.swift:19`).

---

## 12 · IPOTESI — tenute fuori dalle misure, come da mandato

**[A] La catena che spiega il grosso del video.** All'uscita (back interno,
nessuno stop per decisione ratificata) il click prosegue su Verse col preload
di Bridge già armato nel motore (fatto dal ramo avanza al confine
Intro→Verse, quando runner e session erano vivi). Lo smontaggio uccide la
LiveSession vecchia; START SHOW costruisce un runner nuovo e `install` fa
morire il vecchio. Il player rimontato è alimentato da: session vergine +
`primeDisplay` del runner nuovo (Intro: 100, of 12, INTRO/VERSE) + consegne del
motore che sta ancora suonando Verse (of 3 bufferizzato al tick, 120
sovrascritto) + ri-ancora del contatore all'istante del montaggio (Bar 1). Al
confine il ramo SEAMLESS — che NON dipende dalla closure — swappa a Bridge e
pubblica 140 · 3/4 · of 2; la closure dispatchata trova il runner morto e
ritorna senza effetti; il contatore prosegue senza ri-ancora (il runner nuovo
non avanza mai) attraversando il confine, col divisore flippato a 3.

**[A] Le DUE osservazioni che le misure NON coprono, dichiarate:**

1. **`Bar 7 of 2` eccede il derivabile.** Con la fixture misurata, Bridge vale
   6 beat; dal fotogramma `140 3/4 | Bar 2 of 2` si ricava l'ancora a 4 beat
   dalla fine di Verse, e da lì il codice può produrre al massimo
   `Bar 4 of 2` prima che il DRAIN fermi i tick (relativeTick 5..10, divisore 3
   — oltre Bar 4 le misure non arrivano). La salita riportata fino a 5·6·7
   implica ~9 tick oltre la fine di Bridge, che il codice a HEAD non genera in
   nessun percorso da me trovato. O la lettura dei fotogrammi sovrastima gli
   ultimi valori, o esiste un meccanismo che questo censimento non copre.
   ⛔ Non lo decido da qui: lo decide la strumentazione di §9 su device.
2. **Il finale ▶ + striscia spenta.** Quel pattern completo (glifo su
   `isPlaying==false` + `beatActive=0` via il case `.stopped` di LV:298-300 +
   contatore congelato sull'ultimo valore) coincide con UNA sola catena nel
   codice: `stopSync` (unico produttore di `isPlaying=false` fuori
   dall'interruzione di sistema — sonda `grep -nE 'isPlaying\s*=\s*(true|false)'
   ios_app/QBeats/AudioEngine.swift`: :1029 true in start, :1714 false in
   stopSync, :2698 false in handleInterruption) più il dispatch `.stopped` di
   `stop()` (:1094-1096). Ma i chiamanti di `stop()` in scena sono: i rami
   standby/fineSetlist della closure — **morti** — e il tap Stop del transport
   (TV:36-37), che un video non può mostrare. Se nessuno dei due fosse
   avvenuto, il codice prevede l'esito OPPOSTO: motore in stallo silenzioso che
   dichiara `.playing` per sempre (il DRAIN dispatcha una closure morta e non
   ferma nulla: §6 — R:404 e R:412 sono gli unici stop di quel percorso).
   Anche qui: decide la strumentazione, o il racconto di chi teneva il device.

**[A] Il fatto di fondo, per chi scriverà l'atomo:** ogni pezzo di questo
comportamento discende da tre scelte già ratificate — navigazione ≠ transport
(il click sopravvive all'uscita) · lo stato dello show nella stanza (slot) ·
il display nella schermata (@StateObject) — più una quarta MAI presa: cosa
significa START SHOW quando la stanza ha già un runner e il motore sta
suonando. `install` che sostituisce è progettato per il «secondo show»; il
caso «STESSO show, audio vivo» non ha né un confronto (§7) né una semantica
scritta in alcun canonico che io abbia misurato. ⛔ Nessuna proposta di
riparazione qui: è materia di ⟦S-EXIT⟧/decisore.

---

## R-δ — deposito

Questo referto vive in `HANDOFF/REFERTO_CC_2026-08-25_A215-PLAYER-SI-CONTRADDICE.md`
sul repo C: e in copia identica nella `HANDOFF/` del mirror E:
(`FILE X CLAUDE.MD/HANDOFF/`). Verifica: `cmp` + `sha256sum` identici,
dichiarati nel messaggio di consegna. ⛔ Niente Drive: ci arriva da solo.

### Controllo d'integrità di QUESTO file — sul contenuto, testo appiattito

⚠️ Stringhe copiate da una riga sola, senza ritorni a capo; contatele sul testo
appiattito. Attese 2 occorrenze ciascuna (corpo + questa lista); il marcatore
di fine 1, in ultima riga (questa lista lo nomina senza citarlo).

`160b927575e1864908f8f8ca171e3be254ab48dc` ·
`Le quattro facce sono quattro sorgenti` ·
`beatTickCounter non si azzera al cambio di sezione` ·
`il runner vecchio muore dentro install` ·
`la lista dei permessi ha un solo membro` ·
`zero confronti fra la scaletta chiesta e quella in corsa` ·
`il totale sopravvive perche nessuno lo sovrascrive` ·
`oltre Bar 4 le misure non arrivano` ·
`il teleprompter resta orfano` · e il marcatore di fine qui sotto.

---

MANDATO-A215-PLAYER-SI-CONTRADDICE-FINE
