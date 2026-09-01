# MISURE CC — A173 · ANCORA GRAFICA E AVANZAMENTO FUORI DAL PLAYER

Da: CC · A: **referee** (+ Mauro)
Mandato: `A173-ANCORA-GRAFICA-E-AVANZAMENTO-FUORI-DAL-PLAYER` · **SOLA LETTURA**
Tutto misurato il **22/08/2026** contro il blob a **`4629ee9`** (`git show 4629ee9:<path>`),
salvo dove dichiarato diversamente. Modello: **l'interfaccia e' su Fable 5, non Sonnet**
(comando `/model claude-fable-5` dato da Mauro prima del mandato) — eseguito e dichiarato,
come prevede l'intestazione del mandato.

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato da altri, non
rimisurato · **[A]** giudizio mio.
⛔ **I tre registri non sono mai mescolati in una stessa frase.**
⛔ **Nessuna conclusione:** questo referto enumera e cita. Le ipotesi le tira il referee.
⛔ **Le osservazioni di Mauro (22/08) sono trattate come contesto [R], non come tesi da
dimostrare.** Non compaiono nelle misure.
⛔ Cio' che e' agli atti in A172 (mappa dei 7 ingressi, scrittori, azzeratori, 5 siti che
producono tick, censimento commenti) **non e' stato rimisurato**: dove serve, e' citato
come **[R-A172]**.

---

## §0 · ID `A173` — LIBERO su entrambe le gambe

### Per NOME (sonda potata)

```
find "$R" -path "$R/.git" -prune -o -iname "*A173*" -print   ->  0
find "$E"                          -iname "*A173*" -print    ->  0
```

**[M] Controllo positivo forma identica:** `A172` rende 1 per gamba (il referto A172).
⚠️ **[M] Trappola ① di nuovo presente:** la sonda NON potata rende 1 —
`.git/objects/08/1e923f87786c763a02171de1307e8f80a1735d`.

### Per CONTENUTO

| gamba | hit grezzi | dopo lettura hit-per-hit |
|---|---|---|
| repo (`--exclude-dir=.git`) | **0** | 0 |
| `E:` | **11** | **0** riferimenti a mandato |

**[M] Gli 11 hit su E:, classificati uno per uno:**
- **8** in `LOG/RUN/…` — classe ② (log device): `uuid=A173A`, `45886AA3-A173-461A-…`,
  `dealloc] A173B414-…`;
- **2** in `LOG/RUN/TEST LUNGA DISTANZA/LUNGA DISTANZA 1.txt` e `…2.txt` — stessa classe ②
  (`uuid=FA173`), due file che la sonda A172 non aveva incrociato;
- **1** nell'HTML di CD — classe ③, payload base64: `…7Z1wX4VnsLMiA173pzdSYWD35Mz+…`.

**[M] Tutte e tre le classi di rumore sono quindi PRESENTI e riconosciute su questo ID.**
**[M] Controllo negativo tarato:** `QBEATS-NEGATIVO-Z9X8` rende **0** sul repo.

=> **[M] `A173` e' LIBERO.**

---

## §1 · DOMANDA UNO — da dove viene il punto zero della grafica

### 1(a) · Al RIENTRO nel player: cosa rinasce, cosa sopravvive

**[M] La struttura che monta il player** e' lo `switch page` di
`QLiveRootView.swift:93-209 @ 4629ee9`. Il ramo `.metronome` (`:129-179`) renderizza:

```swift
                LiveView(onExit: { navigate(to: .shows) })
                    .environmentObject(runner)
```

**[M] Il back del player e' `navigate(to: .shows)`** (`:178`): `page` cambia ramo e
`LiveView` esce dallo `switch`. **[M] L'unico modo di rientrare nel ramo `.metronome`
e' `navigate(to: .metronome)`, che ha UN SOLO chiamante** (sonda:
`grep -rn 'navigate(to: .metronome)'` → 1 sito di codice, `QLiveRootView.swift:123`,
dentro `onStart`):

```swift
                    onStart: { runner in
                        roomSession.install(runner)
                        navigate(to: .metronome)
                    }
```

**RICOSTRUITI DA ZERO a ogni rientro** — tutto cio' che e' dichiarato dentro `LiveView`
(`LiveView.swift @ 4629ee9`):

| oggetto | riga | valore alla rinascita |
|---|---|---|
| `session` (`@StateObject … = LiveSession()`) | `:11` | oggetto NUOVO: `currentBar=1`, `totalBarsInSection=4`, `playbackState=.stopped`, … (`LiveSession.swift:11-40`) |
| `sectionStartTick` (`@State`) | `:16` | **1** |
| `pendingSectionStart` (`@State`) | `:17` | **false** |
| `sectionHold` (`@State`) | `:20` | false |
| `displayBpb` (`@State`) | `:41` | **4** |
| `displayAccentPattern` (`@State`) | `:42` | `[2,1,1,1]` |
| `pendingBpb` / `pendingAccentPattern` / `pendingReps` (`@State`) | `:43-45` | nil |

**Prova, su tre gambe:**
1. **[M] in-repo, dichiarativa:** `QLiveRootView.swift:20-21` — «montaggio via `switch` da
   AppRootView (condizionale) = sottoalbero distrutto all'uscita dalla stanza». ⚠️ **[M] Lo
   stesso file marca pero' NON SORGENTATA la meta' "rilascio memoria"**, `:64-67` verbatim:
   «⚠️ NON SORGENTATO (§7): la tesi "il ramo di `switch` rilascia la memoria del
   sottoalbero" … e' comportamento SwiftUI di cui NON abbiamo fonte.» E `LiveView.swift:147-150`
   difende esplicitamente il caso contrario («se LiveView NON si smontasse…»).
2. **[M] fonte Apple, `State`** (fetch 22/08,
   `developer.apple.com/documentation/swiftui/state`): «A `State` property always
   instantiates its default value when SwiftUI instantiates the view.»
3. **[M] fonte Apple, `StateObject`** (fetch 22/08,
   `developer.apple.com/documentation/swiftui/stateobject`): «SwiftUI creates a new
   instance of the model object only once during the lifetime of the container that
   declares the state object» e «changing the identity resets **all** state held by the
   view, including values that you manage as `State`, `FocusState`, `GestureState`, and
   so on.»
   ⚠️ **[A] Le pagine Apple non enunciano verbatim il caso «view rimossa dallo `switch` e
   rimontata»: la copertura esplicita di QUEL caso resta non sorgentata**, coerente col
   marcatore in-repo `:64-67`. **[M] Che l'ISTANZA di `LiveView` al rientro sia nuova e'
   pero' un fatto di costruzione: `LiveView(onExit:…)` a `:178` e' una chiamata di
   inizializzatore dentro il body.**

**SOPRAVVIVONO al rientro** (vivono sopra il gate):

| oggetto | dove nasce | prova |
|---|---|---|
| `AudioEngine` | singleton `static let shared` (`AudioEngine.swift:33`) + `@StateObject` in `QBeatsApp.swift:7`, iniettato a `:16` | vita = processo |
| `roomSession` (`QLiveSession`) | `@StateObject` in `QLiveRootView.swift:76` | vita = stanza `.qLive` |
| `runner` (`SetlistRunner`) | slot `QLiveSession.swift:35` | vita = vedi 1(b) |
| `page`, `selectedSetlist` (`@State` di QLiveRootView) | `:46-48` | vita = stanza |
| contatori del motore (`beatTickCounter`, `startBeatOffset`, …) | AudioEngine | [R-A172] mappa agli atti |

### 1(b) · `SetlistRunner`: sopravvive o viene ricreato? — MISURATO

**[M] Alla navigazione player→shows SOPRAVVIVE.** Il runner non e' posseduto da
`LiveView` (che lo riceve `@EnvironmentObject`, `LiveView.swift:6`): vive nello slot
`QLiveSession.swift:35` (`@Published private(set) var runner: SetlistRunner? = nil`),
posseduto da `roomSession`, che e' `@StateObject` della STANZA (`QLiveRootView.swift:76`).
Nessun codice lo azzera al back: la sonda `grep -rn 'runner *= *nil'` sul sorgente rende
**0** siti (l'unica scrittura e' `install`, sotto).

**[M] MA a ogni RIENTRO nel player viene SOSTITUITO da un runner NUOVO.** Catena misurata:
- l'unico ingresso al ramo `.metronome` e' `onStart` (sopra, `:121-124`);
- `onStart` e' invocato dal bottone START SHOW, `QLiveShowDetailView.swift:418` verbatim:
  `onStart(SetlistRunner(setlist: setlist, store: store))` — **costruzione di un runner
  nuovo nel gesto**;
- `install` sostituisce senza condizioni, `QLiveSession.swift:60-62`, e il commento
  `:40-44` lo dichiara verbatim: «⛔ SOSTITUISCE SEMPRE, ANCHE A SLOT PIENO … **Il vecchio
  runner perde qui il suo ultimo riferimento forte.**»

**[M] Gli altri detentori del vecchio runner lo tengono DEBOLE:** la closure end-of-section
registrata in AudioEngine cattura `[weak self, …]` (`SetlistRunner.swift:321`); la vecchia
`LiveView` (che lo riferiva via environment) e' fuori dall'albero.

**[M] All'uscita dalla STANZA (non solo dal player) il quadro cambia:**
`AppRootView.swift:70-77` verbatim:

```swift
        .onChange(of: screen) { newScreen in
            if newScreen == .qLive {
                audioEngine.triggerDNDReminderIfNeeded()
            } else if previousScreen == .qLive {
                audioEngine.stop()
            }
            previousScreen = newScreen
        }
```

— lo stop del motore vive al bordo-stanza; e con lo `switch screen` (`:32-54`)
`QLiveRootView` esce dall'albero con `roomSession` e runner.

### 1(c) · OGNI evento che al rientro puo' fissare un nuovo riferimento

**[M] Inventario completo delle sottoscrizioni/lifecycle di `LiveView`** (sonda:
`grep -nE '\.onReceive|\.onAppear|\.onDisappear|\.onChange|scenePhase|\.task'` sul blob;
controllo positivo: trova le 10 `.onReceive` + 1 `.onAppear`; **`.onDisappear` = 0 hit**):

**Fonti per il comportamento alla sottoscrizione** (fetch 22/08 via
`developer.apple.com/tutorials/data/documentation/...json`):
- **`@Published` CONSEGNA IL VALORE CORRENTE all'atto della sottoscrizione** — pagina
  `combine/published`: l'esempio stampa «Temperature now: 20.0» PRIMA di ogni cambiamento.
  Confermato in-repo da `LiveView.swift:272-277`, che cita la stessa pagina e lo stesso
  esempio («ⓘ Fatto SORGENTATO …»).
- **`PassthroughSubject` NON consegna nulla alla sottoscrizione** — pagina
  `combine/passthroughsubject`: «Unlike CurrentValueSubject, a PassthroughSubject doesn't
  have an initial value or a buffer of the most recently-published element.» e «drops
  values if there are no subscribers».

| # | evento | riga | al RIENTRO (motore in play) scatta? | effetto misurato dell'handler |
|---|---|---|---|---|
| 1 | `.onAppear` | `:211` | **SI** (nuova apparizione) | `displayBpb = audioEngine.beatsPerBar` (`:217`) · `displayAccentPattern` (`:218`) · `runner.primeDisplay(session:)` (`:239`) · se `runner.currentSection != nil`: `displayBpb = section.beatsPerBar` (`:245`) — **col runner NUOVO, indici 0/0** |
| 2 | `.onReceive($playbackState)` | `:250` | **SI, per sottoscrizione** (`@Published`) | col motore in `.playing`: `session.playbackState = .playing` (`:304`) · `sectionHold = false` (`:307`) · **`pendingSectionStart = false` (`:308`)** |
| 3 | `.onReceive($currentBPM)` | `:315` | **SI, per sottoscrizione** | `session.currentBPM = bpm` |
| 4 | `.onReceive($beatsPerBar)` | `:318` | **SI, per sottoscrizione** | con `isPlaying==true`: **`pendingBpb = beats` (`:323`)** → consumato al primo tick (`:374`), riscrive `displayBpb` e `currentTimeSig` |
| 5 | `.onReceive($currentAccentPattern)` | `:335` | **SI, per sottoscrizione** | `pendingAccentPattern = ap` (`:338`) |
| 6 | `.onReceive($currentSectionRepetitions)` | `:343` | **SI, per sottoscrizione** | `pendingReps = reps` (`:346`) → al primo tick `session.totalBarsInSection = reps` (`:387`) — **valore del MOTORE, non del runner nuovo** |
| 7 | `.onReceive(beatTickSubject)` | `:351` | **NO alla sottoscrizione** (PassthroughSubject); **SI al primo beat successivo** | vedi sotto, «il primo tick dopo il rientro» |
| 8 | `.onReceive(runner.$currentSectionIdx)` | `:403` | **SI, per sottoscrizione** (`@Published`, `SetlistRunner.swift:31`) — **e' l'evento che arriva SENZA un cambiamento vero** | **`pendingSectionStart = true` (`:404`)** |
| 9 | `.onReceive($audioMode)` | `:406` | **SI, per sottoscrizione** | `session.isProMode` |
| 10 | `.onReceive(sectionEndedSubject)` | `:420` | **NO alla sottoscrizione** (PassthroughSubject) | — |
| 11 | `.onReceive(linkStartedSubject)` | `:455` | **NO alla sottoscrizione** (PassthroughSubject) | — |

**[M] Il primo tick dopo il rientro** esegue `LiveView.swift:362-394` [R-A172: mappa agli
atti]. Fatti misurabili sul percorso «rientro con motore mai fermato»:
- `tickN` e' il contatore monotono del motore [R-A172: due soli azzeratori, `start()` e
  `stopSync()`]; su questo percorso nessuno dei due e' passato ⇒ **`tickN != 1`**;
- quindi il ramo `:363` non gira; gira `:368` (`sectionStartTick = tickN`) **se e solo se**
  `pendingSectionStart == true` in quel momento;
- `pendingSectionStart` al rientro e' scritto da DUE eventi-di-sottoscrizione in conflitto:
  riga 8 lo mette a `true` (`:404`), riga 2 lo mette a `false` (`:308`).
  **[M] L'ordine di ATTACCO dei modifier e' un fatto del sorgente: `:250` precede `:403`.**
  ⛔ **L'ordine di CONSEGNA dei valori iniziali fra sottoscrizioni diverse: non sorgentato.**
  Nessuna delle due pagine Apple lette lo definisce, e non ho prova in-repo. Mi fermo qui.
- **[M] I due esiti possibili sono entrambi enumerabili:**
  (i) `pendingSectionStart==true` al primo tick → `sectionStartTick = tickN` (`:368`) —
  un ancoraggio nuovo, al valore che il contatore ha in quel momento;
  (ii) `pendingSectionStart==false` al primo tick → **nessuno dei due rami gira**
  [R-A172: «non c'e' un else finale»] → `sectionStartTick` resta al default **1** della
  vista appena nata.

### 1(d) · Le PRECONDIZIONI dichiarate nel codice — verbatim, e cosa c'e' su questo percorso

**① `LiveView.swift:12-15`** (dichiarazione di `sectionStartTick`):

> «beatTickCounter di AudioEngine cresce monotono dalla partenza; per resettare il display
> "Battuta X di Y" ad ogni cambio sezione **manteniamo qui in Layer 3 il primo tick della
> sezione corrente**, e calcoliamo `currentBar` come tick relativo.»

**[M] Su questo percorso:** il «qui» e' un `@State` della vista; la vista al rientro e' una
istanza nuova (1(a)) e il valore mantenuto non c'e' piu' — c'e' il default 1.

**② `LiveView.swift:352-361`** (l'ancora del tick 1):

> «tickN==1 identifica intrinsecamente il primo beat dopo start() … L'offset e' gia'
> finale qui … Un avvio fresco supera SEMPRE il marker di cambio sezione (un avanzamento
> mid-canzone NON riavvia il motore → tickN!=1) → azzera pendingSectionStart.»

**[M] Su questo percorso:** non c'e' nessun `start()` — il motore non e' mai stato fermato
ne' riavviato; `tickN != 1` per costruzione.

**③ `LiveView.swift:396-402`** (il marker):

> «alla transizione di currentSectionIdx (ramo avanza o ramo standby), il prossimo tick
> generato dall'audio engine sara' il primo della nuova sezione e diventera'
> sectionStartTick.»

**[M] Su questo percorso:** la consegna di `runner.$currentSectionIdx` al rientro non e'
«una transizione»: e' il valore corrente consegnato alla sottoscrizione (fonte sopra), e
il runner e' NUOVO con indice 0. Il tick che «diventera' sectionStartTick» e' un tick
qualsiasi del contatore monotono, non il primo di una sezione.

**④ `QLiveRootView.swift:64-67`** — il rilascio del sottoalbero e' dichiarato
**NON SORGENTATO** dal file stesso (verbatim in 1(a)).

**⑤ `SetlistRunner.primeDisplay`, `:297-309`** — arma lo standby **solo da `.stopped`**:

```swift
        if case .stopped = session.playbackState, let song = currentSong {
            session.playbackState = .standby(nextSongName: song.name)
        }
```

**[M] Su questo percorso:** la `session` nuova nasce `.stopped`, quindi al momento di
`primeDisplay` (`onAppear`, `:239`) la condizione e' VERA e lo standby viene armato; la
consegna-di-sottoscrizione di `$playbackState` (riga 2 della tabella) scrive pero'
`session.playbackState = .playing` (`:304`) — **due scritture in conflitto sulla stessa
proprieta', ordine relativo `onAppear`↔consegne iniziali: non sorgentato.**
⚠️ **[M] Nota di guardia in-repo pertinente:** `LiveView.swift:280-282` protegge dagli
`.stopped` del motore gli stati `.standby`/`.fineSetlist`, ma il `case .playing` (`:303`)
non ha guardie sulla sessione.

---

## §2 · DOMANDA DUE — chi fa avanzare la scaletta mentre si e' fuori dal player

### 2(a) · TUTTI i punti che decidono un passaggio

**Sonde:** sweep su `_onSectionEnd|_pendingEndClosure|_sectionEndPending` (AudioEngine),
lettura integrale di `SetlistRunner.swift` (416 righe), sweep
`runner\.(startSetlist|startCurrentSong|…)` (7 siti), sweep
`func (nextSection|prevSection)…` (2+2 siti). Controllo positivo forma identica:
la sweep sui chiamanti di `scheduleNextBuffer` rende 14 righe non-commento [R-A172].

**LIVELLO MOTORE (audioQueue) — decide QUANDO una sezione finisce:**

| # | punto | file:riga | cosa decide |
|---|---|---|---|
| M1 | conteggio beat di sezione | `AudioEngine.swift:2495-2497` | `_sectionBeatCounter += 1`; al raggiungere `_sectionTotalBeats` biforca |
| M2 | ramo SEAMLESS (intra-canzone, preload presente) | `:2501-2538` | swap atomico dei parametri + `:2602-2604` `DispatchQueue.main.async { closureToDispatch?() }` |
| M3 | ramo DRAIN (fine canzone / fine setlist) | `:2606-2621` | `_pendingEndClosure = _onSectionEnd` · `_sectionEndPending = true` |
| M4 | fire del drain | `:2210-2219` + `:2235` | a playhead esauriti, dispatch della closure su main |
| M5 | registrazione della closure | `loadSection`, `:1140-1158` (`_onSectionEnd = onEnd` a `:1148`) e `preloadNextSection` (chiamate del runner `:209-211`, `:219-225`, `:364-371`) | chi ricevera' M2/M4 |

**LIVELLO RUNNER (main) — decide DOVE si va.** La closure e' costruita da
`makeSectionEndedClosure` (`SetlistRunner.swift:319-415`) e comincia cosi', verbatim
`:321-322`:

```swift
        return { [weak self, weak audioEngine, weak session] in
            guard let self, let audioEngine, let session else { return }
```

| # | ramo | riga | cosa fa |
|---|---|---|---|
| R1 | AVANZA (sezione→sezione) | `:326-373` | `currentSectionIdx += 1` · `pendingDisplayUpdate = true` · preload N+2 |
| R2 | STANDBY (canzone→canzone) | `:375-404` | `currentSongIdx += 1` · `currentSectionIdx = 0` · `session.playbackState = .standby(…)` (`:382`) · azzera i campi display (`:388-393`) · **`audioEngine.stop()` (`:404`)** |
| R3 | FINESETLIST | `:406-413` | `sectionEndedSubject.send()` · `session.playbackState = .fineSetlist` · `stop()` |
| R4 | degenerato | `:142-149` | `currentSection == nil` → `.fineSetlist` immediato |
| R5 | display al 1° beat di battuta | `:178-190` | sink su `session.$beatActive == 1`, `[weak self, weak session]`, applica `updateSessionDisplay` se `pendingDisplayUpdate` |

**LIVELLO VISTA (main) — le CONTINUAZIONI che riavviano l'audio o cambiano canzone:**

| # | punto | file:riga | gesto/evento |
|---|---|---|---|
| V1 | tap sullo StandbyOverlay | `LiveView.swift:135-137` | `runner.startCurrentSong(…)` — l'unico modo di far PARTIRE la canzone successiva dopo R2 |
| V2 | observer `linkStartedSubject` | `:455-466` | in `.standby` → `startCurrentSong`; altrimenti `startSetlist` |
| V3 | Play del transport | `TransportView.swift:62` | `startSetlist` |
| V4 | START LOCAL (Follower) | `LiveView.swift:190` | `startSetlist` |
| V5 | back da FineSetlist | `:160-163` | `.stopped` + `onExit()` |
| V6 | bottoni «prev sez» / «next sez» | `TransportView.swift:26-28`, `:66-68` | chiamano `audioEngine.prevSection()` / `.nextSection()` |

⚠️ **[M] V6 — i corpi sono VUOTI.** `AudioEngine.swift:1265-1269` verbatim:

```swift
    // Stub — implementazione in Fase Backtrack
    func restartCurrentSong() { restartFromBeginning() }
    func prevSection() {}
    func nextSection() {}
    func toggleLoop() {}
```

**[M] I bottoni avanti/indietro del transport (e il loop) non hanno alcun effetto a HEAD.**

### 2(b) · Dentro o fuori dalla vista?

| attore | vive | funziona col player NON a schermo? |
|---|---|---|
| M1-M5 (conteggi e dispatch) | AudioEngine (singleton di processo) | **[M] si'** — girano su audioQueue, nessun riferimento alla vista |
| la closure R1-R3 come OGGETTO | detenuta da AudioEngine (`_onSectionEnd`) | **[M] si', viene dispatchata** — ma il suo CORPO dipende dalle catture, sotto |
| il corpo della closure | catture `[weak self, weak audioEngine, weak session]` (`:321`) | **[M] condizionato:** `session` e' la `LiveSession` della vista che era montata quando la closure fu costruita (`:195`); la guardia `:322` esce in silenzio se una qualsiasi cattura e' nil |
| R5 (sink su `$beatActive`) | dentro il runner | **[M] condizionato due volte:** `session.beatActive` ha per unico scrittore l'handler del tick DELLA VISTA (`LiveView.swift:393` [R-A172]); vista assente ⇒ nessun `beatActive`, sink muto |
| V1-V6 | dentro il sottoalbero del player | **[M] no** — fuori schermo non esistono |

⚠️ **[M] La vita della VECCHIA `LiveSession` dopo il back e' la stessa questione marcata
NON SORGENTATA in-repo** (`QLiveRootView.swift:64-67`): la closure la tiene **debole**
(`:321`), il runner la tiene **debole** anche nel sink (`:181`). Non ho trovato nel
sorgente un detentore forte fuori dalla vista (sonda: lettura dei siti di cattura sopra).
⛔ Non concludo cosa accada a runtime: enumero i due esiti che il codice prevede —
(i) `session` viva → R2 gira per intero, compreso `audioEngine.stop()`;
(ii) `session` nil → la guardia `:322` esce **prima di tutto**, compreso lo stop.

### 2(c) · Cosa succede a quella logica quando il player viene lasciato e ripreso

Enumerazione, senza giudizio:

1. **[M] Al back (player→shows):** nessun codice tocca runner, closure, motore
   (`navigate` muta solo `page`, `QLiveRootView.swift:88-90`; decisione CD 18/07 in
   commento `:78-85`: «NESSUNO stop audio va agganciato alle transizioni di `page`»).
   L'audio continua.
2. **[M] Mentre si e' fuori:** M1-M5 continuano; il dispatch della closure avviene; il
   corpo esegue o esce alla guardia secondo la vitalita' delle catture (2(b)).
3. **[M] Alla ripresa (solo via START SHOW):** `install` sostituisce il runner e il
   vecchio «perde qui il suo ultimo riferimento forte» (`QLiveSession.swift:44`).
   **[M] Il runner NUOVO non ha closure registrata** (`sectionEndedClosure == nil` fino al
   primo `prepareAndStartCurrentSection`, `:194-196`) **e la closure VECCHIA resta
   registrata in `_onSectionEnd`** finche' un nuovo `loadSection` non la sovrascrive
   (`:1148`) — sovrascrittura che avviene solo dentro `startSetlist`/`startCurrentSong`
   del runner nuovo (V1-V4).
4. **[M] `stopSync()` NON de-registra la sezione:** `:1652` verbatim — «_sectionTotalBeats
   e _onSectionEnd RESTANO registrati» (azzera pero' `_pendingEndClosure`/`_sectionEndPending`,
   `:1701-1702`).
5. **[M] All'uscita dalla STANZA:** `AppRootView.swift:73-74` ferma il motore;
   `roomSession` e runner escono dall'albero con `QLiveRootView`.

---

## §3 · DOMANDA TRE — cosa sa dire il motore sul proprio inizio di battuta

### 3(a) · Esiste, verso la grafica, un segnale «questo battito e' il primo della battuta»?

**[M] NO.** Misure:

- **[M] Il tick e' un intero nudo.** `beatTickSubject = PassthroughSubject<Int, Never>`
  (`AudioEngine.swift:121`); l'emissione manda solo `tickN` (`:2373-2377`).
- **[M] `session.beatActive` (il LED 1-based che la UI mostra) NON viene dal motore: lo
  calcola la vista**, `LiveView.swift:393` — `session.beatActive = ((relativeTick - 1) % bpb) + 1`
  — dagli stessi ingressi del bar counter [R-A172].
- **[M] Il DSP la conosce ma non la esporta.** `_currentBeatInBar` vive in
  `core_engine/MetronomeDSP.cpp` — enumerazione completa delle 13 occorrenze (sweep
  rifatta due volte, la prima era monca di 3 righe su 6 scrittori): scrittori = init a 0
  (`:8`), tre reset a 0 (`:194`, `:228`, `:241`), scrittura calcolata
  `(uint32_t)beatInBar` (`:278`), incremento `(_currentBeatInBar + 1) % _beatsPerBar`
  (`:508`); letture = `:450`, `:455` (indice nell'accent pattern) e — pertinente per
  questa domanda — **`:468` verbatim `if (_currentBeatInBar == 0) {`: il DSP il «primo
  beat della battuta» lo TESTA, internamente**; il resto sono commenti (`:120`, `:267`,
  `:299`, `:336`). L'intestazione C completa del bridge (`MetronomeDSPBridge.h:11-63`,
  letta integralmente) **non contiene alcuna funzione che la restituisca** — l'elenco esportato e': create/destroy · setBPM/set_sample_rate/
  setBeatsPerBar/setAccentPattern/setSubdivision · schedule/cancel (bpm, bpb, accent,
  subdivision) · set_*_volume/set_muted · reset_for_start · set_beat_position(+_time_only)
  · set_diag_enabled/flush_diag · **processBuffer**. `getCurrentBeatInBar()` compare solo
  nei log del bridge (`MetronomeDSPBridge.mm:41-44`, `:52-55`, `:128-129`).
- **[M] I flag per-beat esistono ma muoiono dentro il motore.** `metronome_processBuffer`
  restituisce ad AudioEngine gli array `offsets/accents/isBeats` (`.h:58-63`); AudioEngine
  li usa per scegliere il campione da mixare (`:2367-2372`, `:2627-2631`) e **non li
  pubblica**: nel `if isBeat` parte solo `tickN`.

### 3(b) · Cosa espone oggi che ci va vicino — elenco e basta

| esposizione | tipo/dove | contenuto |
|---|---|---|
| `beatTickSubject` | `PassthroughSubject<Int,…>`, `:121` | numero di beat monotono dall'ultimo azzeramento |
| `currentBeat` | `@Published Double`, `:104`, scritto a `:2362-2365` | posizione di beat assoluta del MIDI engine, una volta per buffer |
| `currentAccentPattern` | `@Published [UInt8]`, `:97` | il PATTERN (accent/beat/subdiv per slot), non la posizione corrente |
| `beatsPerBar` | `@Published UInt32`, `:57` | quanti beat per battuta |
| `currentSectionRepetitions` | `@Published Int`, `:98` | battute totali della sezione caricata |
| `startBeatOffset` | `private(set) Int`, `:359` | seme d'ingresso del ramo SHARED [R-A172] |
| `isPlaying` / `playbackState` | `@Published`, `:56` / `:186` | stato transport |
| `accents[]`/`isBeats[]` per-beat | array locali in `scheduleNextBuffer` (`:2367-2372`) | il beat accentato E' identificato qui, ma non esce |
| ring diagnostico SPY | `MetronomeDSPBridge.mm:73-75` (`beatInBar=%u … downbeat=%u`), flush `metronome_flush_diag` (`.h:54-56`) | porta beat-in-bar e flag downbeat, ma **solo come os_log sotto `QB_DIAG_SPY`/diag, non come API** |
| `link_engine_probe_session` | usata in `start()` `:962-967` | `phaseAtHost` = fase dentro il quantum (battuta) al tempo dato |
| `midi_engine_get_beat_position` | `:2362` | beat assoluto |

⛔ **Nessun fix proposto, nessun costo stimato.**

---

## §4 · CONSEGNA — e la rettifica sul conteggio CR di A172

### La faccia di QUESTO file e di A172, misurata con sonde a BYTE

**[M] Sonde usate (due forme indipendenti, entrambe tarate):**

```
forma 1:  tr -cd '\r' < FILE | wc -c                        (conta i byte 0x0D)
forma 2:  wc -c < FILE  meno  (tr -d '\r' < FILE | wc -c)   (aritmetica)
taratura: su un file costruito con 2 CR veri entrambe rendono 2;
          su un file senza CR entrambe rendono 0.
```

**[M] `MISURE_CC_2026-08-22_A172-….md`: 0 CR** (forma 1 = 0 · forma 2 = 0 · 25 538 byte).
⇒ **la dichiarazione «501 CR» nel mio messaggio di chat di A172 era un FALSO PIENO: il
file era a 0 CR gia' allora** (sha e byte, che il referee ha verificato, identici a oggi).
La faccia 0 CR e' quella giusta per `HANDOFF/` e non e' mai stata sbagliata sul disco:
era sbagliata la sonda.

### La trappola — nona del registro: «grep non e' una sonda CR, in NESSUNA forma»

**[M] Riprodotta e tarata oggi.** La sonda di A172 era `grep -c $'\r' FILE` → **501 =
numero di righe**. Controprova: `printf 'a\nb\n' | grep -c $'\r'` → **2** su input SENZA
CR ⇒ in quell'esecuzione il pattern e' arrivato a grep **VUOTO** (un pattern vuoto matcha
ogni riga; `grep -c ''` sulle stesse due righe → 2).

**[M] Tabella delle forme misurate oggi contro il file di taratura (3 righe, 2 CR):**

| forma della sonda | esito | esito atteso da una sonda sana |
|---|---|---|
| `grep -c $'\r'` (CR letterale nel comando) | **3** (= tutte le righe) | 2 |
| `grep -c "$p"` con `p=$'\r'` via variabile | **0** | 2 |
| `grep -c -f patfile` (pattern CR da file) | **3** | 2 |
| `tr -cd '\r' \| wc -c` | **2** ✅ | 2 |
| aritmetica `wc -c` − `tr -d` | **2** ✅ | 2 |

⚠️ **[M] La stessa forma ha reso esiti DIVERSI in esecuzioni diverse della stessa
giornata** (misurato: `p=$'\r'; echo -n "$p" | wc -c` → 0 in un'esecuzione, 1 in un'altra;
`${#p}` → 1). Il canale fra il testo del comando e la shell **altera le sequenze CR in
modo non riproducibile** — stessa famiglia di [R] «il transito modello altera gli
apostrofi». ⛔ **Regola che ne segue per questo banco: il carattere cercato non deve MAI
viaggiare dentro il testo del comando. Per i CR: solo sonde a byte (tr / aritmetica wc).**

### I due depositi

| gamba | percorso | byte | CR (forma 1 · forma 2) | sha256 |
|---|---|---|---|---|
| C: repo | `HANDOFF/MISURE_CC_2026-08-22_A173-ANCORA-GRAFICA-E-AVANZAMENTO.md` | *dichiarati nel messaggio di consegna* | 0 · 0 | *idem* |
| E: mirror | `FILE X CLAUDE.MD\HANDOFF\` stesso nome | *identici, `cmp` exit 0* | 0 · 0 | *identico* |

(I valori numerici esatti sono dichiarati nel messaggio di consegna, misurati DOPO il
deposito — un'impronta incisa nel documento stesso non puo' coincidere con se stessa.)

⛔ Niente Drive. Niente commit: HEAD resta `4629ee9`, zero tracciati modificati,
`ios_app/` intatto.

---

## §5 · DIFETTI DEL MANDATO E DICHIARAZIONI

- **[A] Il mandato NON contiene la risposta travestita da domanda.** Le osservazioni di
  Mauro sono dichiarate come contesto e non prescrivono un colpevole; le mappe sono state
  compilate per enumerazione, non per conferma.
- **[M] Modello: interfaccia su Fable 5** (`/model claude-fable-5`), non Sonnet. Eseguito
  e dichiarato come da intestazione.
- **[M] Fonti esterne:** le quattro pagine Apple citate sono state lette il 22/08 via
  l'endpoint dati (`developer.apple.com/tutorials/data/documentation/…json`) perche' le
  pagine HTML rendono solo il titolo a un fetch non-JS. Le frasi sono riportate come
  restituite dal fetch; per `Published` c'e' la controprova in-repo indipendente
  (`LiveView.swift:272-277`).
- **[A] Un'assenza che dichiaro:** l'ordine di consegna dei valori iniziali fra
  sottoscrizioni Combine diverse, e fra queste e `onAppear`, e' rimasto **non sorgentato**
  dopo ricerca su entrambe le gambe (in-repo + doc Apple). Le enumerazioni di §1(c)
  elencano gli esiti possibili senza sceglierne uno.

## §6 · COSA NON HO FATTO

⛔ Nessun file sotto `ios_app/` toccato · nessun canonico modificato · nessun commit ·
nessuna build · nessun commento corretto (nemmeno gli stub vuoti di V6).
⛔ Non ho rimisurato nulla di A172 (citato [R-A172]).
⛔ Non ho letto il congedo del referee.

---

### Controllo d'integrita' di QUESTO file — sul CONTENUTO

**Prima riga attesa:**
`# MISURE CC — A173 · ANCORA GRAFICA E AVANZAMENTO FUORI DAL PLAYER`

**Stringhe obbligatorie — se una manca, il file e' arrivato mutilato:**
`Il vecchio runner perde qui il suo ultimo riferimento forte` ·
`guard let self, let audioEngine, let session else { return }` ·
`func nextSection() {}` ·
`doesn't have an initial value or a buffer` ·
`Temperature now: 20.0` ·
`pendingSectionStart = true` ·
`solo sonde a byte` ·
e il marcatore di fine qui sotto.

⚠️ **Contate le stringhe, non i titoli.**

---

*A173-FINE — MISURE CC 22/08/2026 COMPLETO*
