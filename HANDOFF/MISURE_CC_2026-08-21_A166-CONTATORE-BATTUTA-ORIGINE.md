# MISURE CC — A166-CONTATORE-BATTUTA-ORIGINE

**ID ricevuto e verificato: `A166-CONTATORE-BATTUTA-ORIGINE`.**
**HEAD = `6527d82b8e9314f50a6ae354a3e86c30a77aacf9`** (locale = remoto via
`git ls-remote origin master`, rimisurato alle 21:46 del 21/08/2026).

⛔ **Referto di SOLA LETTURA. Nessuna modifica sotto `ios_app/`, nessun commit,
nessun merge, nessun cherry-pick, nessuna build. Nessuna conclusione: le tira il
referee.**

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio.
In questo referto **non ci sono [A]**, per mandato.

⚠️ **A163 e A164 NON mi sono arrivati.** Ho ricevuto un solo mandato. Li conosco
solo perche' il congedo che eredito li documenta come eseguiti dalla sessione
precedente, e su disco esistono `DIFF_2026-08-21_A163-*` (21:06) e
`MISURE_CC_2026-08-21_A164-*` (21:16).

---

## §0 · L'ID — due supporti, due forme, ispezione del contesto

### Esito: **A166 LIBERO**

| ID | NOME repo | NOME E: | CONT repo | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A166** | **0** | **0** | 1 | 7 | ⇒ **LIBERO** — ogni hit di contenuto e' rumore identificato (sotto) |
| A164 | 1 | 1 | 2 | 10 | controllo **positivo** — rende il file reale |
| A165 | 0 | 0 | 1 | 8 | controllo positivo (solo `*A165-FINE*`, nessun file proprio) |
| A176 | 0 | 0 | 1 | 7 | controllo **negativo** — ⚠️ **NON rende zero per contenuto** |

**[M] Ogni hit di `A166` per contenuto, VERBATIM:**

```
HANDOFF/CONGEDO_CC_2026-08-21_NOTTE.md:141:| **A166** | **0** | **0** | **0** | **0** | ⇒ **PROSSIMO LIBERO** |
HANDOFF/CONGEDO_CC_2026-08-21_NOTTE.md:146:⚠️ **AUTORIFERIMENTO dichiarato:** questo congedo cita `A165` e `A166`. Dopo che
HANDOFF/CONGEDO_CC_2026-08-21_NOTTE.md:147:esiste, **entrambi renderanno per contenuto.** A166 resta libero **come ID di
```

piu', su `E:` soltanto, frammenti di UUID/request-id nei log di device di giugno
(`LOG/RUN/TEST LUNGA DISTANZA/td17_*.log`): `uuid=1A166`, `uuid=0A166`,
`[A1666]`, `398BA166-D983-...`, `...-A166-...`. **Zero hit di A166 come ID di
mandato.**

### ⚠️ DUE CLASSI DI FALSO-POSITIVO DELLA SONDA ID — misurate, non ipotizzate

**[M] (1) `find -iname '*A1NN*'` senza escludere `.git/objects` conta gli HASH.**
Il controllo positivo su `A164` rendeva **5**; i path reali sono:

```
.git/objects/0a/a1649626cc6f10d1e551010119944046fb5dd8
.git/objects/cc/57710693b23c683c17a164b734ddd44f8b22ee
.git/objects/ef/5a07fc883f0e01d91a1192d6a164dcf5207108
HANDOFF/MISURE_CC_2026-08-21_A164-COMMIT-BOX5-V29-E-LIBRO-v59.md
```

⇒ **3 hit su 4 erano nomi di blob git.** Gli ID mandato `A1NN` sono stringhe
**esadecimali valide**: la sonda per nome su un repo non potato puo' rendere una
**collisione FALSA**. Con `.git` escluso: `A164` = 1 su repo, 1 su E:.

**[M] (2) La sonda per CONTENUTO ha un rumore di fondo dai log di device.**
Il controllo **negativo** `A176`, che deve rendere zero, rende **1 su repo e 7 su
E:**. Ispezione: 1 e' la riga di controllo del congedo stesso (`:144`), 6 sono
`td17_*.log` che contengono `[1A176]` come request-id WiFi.
⇒ **Su questi due supporti una sonda ID per contenuto non e' leggibile per
conteggio: va letta hit per hit.**

**Ispezione del contesto:** l'ID piu' alto con artefatto in `HANDOFF/` e' **A164**;
`A165` esiste solo come marcatore `*A165-FINE*` dentro il congedo, senza file
proprio. `A166` e `A167` non compaiono.

---

## §1 · Regole di misura applicate

· Ogni zero riportato qui ha accanto il proprio **controllo positivo nella forma
  identica**, dichiarato in loco.
· Conteggi CR fatti sui **byte** (`tr -dc '\r' | wc -c`), mai con `grep`.
· ⚠️ **La faccia dei file di codice e' DOPPIA e la dichiaro:**
  `ios_app/QBeats/AudioEngine.swift` — **disco 163540 byte / 3079 CR**,
  **blob a HEAD 160461 byte / 0 CR**. `cmp` disco-vs-blob rende **exit 1**, e la
  differenza di byte e' **163540 - 160461 = 3079**, esattamente il conteggio dei
  CR. **Stesso contenuto, due facce.** Righe: 3079 su entrambe ⇒ **i numeri di
  riga di questo referto valgono su entrambe le facce.**

### ✅ Cancello §6 — l'indirizzo citato dal mandato CORRISPONDE a HEAD

```
 971:                         if (peersCount == 0 && !probe.isPlaying) || self._linkMode == .direttore {
 972:                             // === STANDALONE PURO o DIRETTORE (sorgente unica autoritativa) ===
 973:                             // Bug 2.b ramo X — sorgente autoritativa parte da bar 1: nessun
 974:                             // offset d'ingresso. Garantisce Director/standalone bit-identici.
 975:                             self.startBeatOffset = 0
```

`:971` e' il capo del ramo; il range `971-975` contiene davvero il commento
citato. **L'assunzione del referee regge. Nessuna condizione di stop del §6 si e'
verificata.**

---

## §2 · Da dove esce il numero della battuta

### §2.1 · Il simbolo che rende, e da dove legge la X

**[M] Rende `BarCounterView`** — `ios_app/QBeats/UI/Live/BarCounterView.swift:3`
@ `6527d82b8e9314f50a6ae354a3e86c30a77aacf9`.

⚠️ **La stringa «Battuta X di Y» NON ESISTE nel sorgente.** Il testo reso e' in
inglese. VERBATIM, `BarCounterView.swift:12-35`:

```
 12:     var body: some View {
 13:         HStack {
 14:             switch state {
 15:             case .countIn, .standby:
 16:                 Text("— / —")
 17:                     .font(.jbMono(.medium, size: 16 * scaleFactor))
 18:                     .foregroundColor(Color.white.opacity(0.88))
 19:             default:
 20:                 let isInf   = total == -1
 21:                 let isReady = total > 0 || isInf
 22:                 Group {
 23:                     Text("Bar ")
 24:                         .foregroundColor(Color.white.opacity(0.88))
 25:                     + Text(isReady ? "\(current)" : "—")
 26:                         .fontWeight(.bold)
 27:                         .foregroundColor(.white)
 28:                     + Text(" of ")
 29:                         .foregroundColor(Color.white.opacity(0.88))
 30:                     + Text(isInf ? "∞" : isReady ? "\(total)" : "—")
 31:                         .fontWeight(.bold)
 32:                         .foregroundColor(.white)
 33:                 }
 34:                 .font(.jbMono(.medium, size: 16 * scaleFactor))
 35:             }
```

**[M] Sonda per la stringa italiana, su tutto `ios_app` per `*.swift`:**
`grep -rn 'Battuta'` rende **1 sola riga**, ed e' un **commento**:
`LiveView.swift:14`. **Zero occorrenze come letterale di UI.**
✅ Controllo positivo nella stessa forma: `grep -rn 'var body' --include='*.swift'`
rende **53**. (⚠️ Il mio primo controllo positivo, `'Brano'`, rendeva **0** — non
era tarato, e l'ho scartato.)

**La X e' il parametro `current`**, passato da
`ios_app/QBeats/UI/Live/LiveView.swift:101` VERBATIM:

```
101:                    BarCounterView(current: session.currentBar, total: session.totalBarsInSection, state: session.playbackState, scaleFactor: scaleFactor)
```

Lo stesso valore alimenta un secondo consumatore, `LiveView.swift:103`:

```
103:                    MicroSegBarView(current: session.currentBar, total: session.totalBarsInSection, state: session.playbackState, sectionHold: sectionHold)
```

⇒ **X = `session.currentBar`**, dichiarata in
`ios_app/QBeats/Models/LiveSession.swift:19`:

```
 19:     @Published var currentBar: Int = 1
```

`LiveSession` e' `@MainActor` (`:7`) e **non ha alcun metodo di reset**: il file
e' 41 righe, tutte dichiarazioni `@Published`.

### §2.2 · Percorso di SCRITTURA completo della X

**[M] `grep -rn 'currentBar' --include='*.swift'` su tutto `ios_app` rende SEI
righe, e le riporto tutte** (due sono commenti, due sono letture, una e' la
dichiarazione, **una sola e' una scrittura**):

```
Models/LiveSession.swift:19:    @Published var currentBar: Int = 1                       <- DICHIARAZIONE/INIZIALIZZAZIONE
UI/Live/LiveView.swift:15:    // il primo tick della sezione corrente, e calcoliamo `currentBar` come tick relativo.   <- commento
UI/Live/LiveView.swift:101:  BarCounterView(current: session.currentBar, ...)            <- LETTURA
UI/Live/LiveView.swift:103:  MicroSegBarView(current: session.currentBar, ...)            <- LETTURA
UI/Live/LiveView.swift:367:  // della nuova sezione diventa l'ancora → currentBar=1.      <- commento
UI/Live/LiveView.swift:394:  session.currentBar = ((relativeTick - 1) / bpb) + 1          <- UNICA SCRITTURA
```

⇒ **La X ha esattamente DUE origini di valore: l'inizializzatore a 1
(`LiveSession.swift:19`) e l'unica assegnazione a `LiveView.swift:394`.**
Non esiste alcun sito che la incrementi: **`:394` la RICALCOLA da zero a ogni
tick**, non la incrementa.

Terza via di ritorno a 1, **strutturale e non testuale**: `LiveView.swift:11`
dichiara `@StateObject private var session = LiveSession()` — alla creazione di
una nuova identita' della vista l'oggetto e' nuovo e `currentBar` riparte da 1.

**Il blocco che la scrive, VERBATIM** — `LiveView.swift:351-395`:

```
351:         .onReceive(audioEngine.beatTickSubject) { tickN in
352:             // Bug 2.b — ancora deterministica del 1° beat di un avvio fresco.
353:             // tickN==1 identifica intrinsecamente il primo beat dopo start()
354:             // (beatTickCounter azzerato in start(), AudioEngine.swift:635): nessun
355:             // flag armato in .playing, nessuna corsa col primo tick. L'offset è
356:             // già finale qui (work item SHARED pubblica startBeatOffset PRIMA del
357:             // 1° scheduleNextBuffer). Director/standalone: startBeatOffset=0 →
358:             // sectionStartTick=1. Follower: startBeatOffset = bar d'ingresso →
359:             // sectionStartTick = 1 - offset. Un avvio fresco supera SEMPRE il marker
360:             // di cambio sezione (un avanzamento mid-canzone NON riavvia il motore
361:             // → tickN!=1) → azzera pendingSectionStart.
362:             if tickN == 1 {
363:                 sectionStartTick = 1 - audioEngine.startBeatOffset
364:                 pendingSectionStart = false
365:             } else if pendingSectionStart {
366:                 // L1.b — avanzamento sezione mid-canzone (seamless): il 1° tick
367:                 // della nuova sezione diventa l'ancora → currentBar=1.
368:                 sectionStartTick = tickN
369:                 pendingSectionStart = false
370:             }
...
390:             let bpb = max(1, Int(displayBpb))
391:             // Tick relativo alla sezione corrente (1-based dentro la sezione).
392:             let relativeTick = tickN - sectionStartTick + 1
393:             session.beatActive = ((relativeTick - 1) % bpb) + 1
394:             session.currentBar = ((relativeTick - 1) / bpb) + 1
395:         }
```

e l'unico armamento del marker di sezione, `LiveView.swift:403-405`:

```
403:         .onReceive(runner.$currentSectionIdx) { _ in
404:             pendingSectionStart = true
405:         }
```

**Le tre grandezze in ingresso a `:394` sono dunque `tickN`, `sectionStartTick`,
`displayBpb`.** `sectionStartTick` e' `@State` in Layer 3 (`LiveView.swift:16`,
inizializzato a 1) con **due soli siti di scrittura**: `:363` e `:368`.

### 🚨 §2.2-bis · RIFERIMENTO DI RIGA SCADUTO nel commento a `:354`

**[M]** Il commento dice «beatTickCounter azzerato in start(),
**AudioEngine.swift:635**». A HEAD, `AudioEngine.swift:635` e':

```
 633:         if let lh = linkEngineHandle { link_engine_destroy(lh) }
 634:         qbeats_link_pending_destroy(linkPending)
 635:     }
```

cioe' la **chiusura di un blocco di distruzione**. `grep -n 'beatTickCounter = 0'`
rende **due** siti, entrambi diversi da 635:

```
 874:                self.beatTickCounter  = 0        <- dentro func start(resumeAtBeat:), aperta a :851
1650:            self.beatTickCounter = 0             <- dentro private func stopSync(), aperta a :1625
```

✅ Controllo positivo nella stessa forma: `grep -n '_sectionBeatCounter = 0'`
rende **7** siti (`804, 878, 1147, 1151, 1656, 2535, 2621`) ⇒ la sonda vede.

### §2.3 · `startBeatOffset` — TUTTI i siti, e il collegamento alla X

**[M] `grep -rn 'startBeatOffset' --include='*.swift'` rende DIECI righe. Tutte:**

| riga | sito | contesto (func aperta a) |
|---|---|---|
| `AudioEngine.swift:359` | `private(set) var startBeatOffset: Int = 0` | dichiarazione |
| `AudioEngine.swift:800` | `self.startBeatOffset = offset` | `armSharedJoin(retriesLeft:)` @ `:662` — **dentro il DispatchWorkItem aperto a `:727`** |
| `AudioEngine.swift:803` | `self.startBeatOffset = 0` | idem (ramo else, con `os_log` di anomalia a `:808`) |
| `AudioEngine.swift:944` | `self.startBeatOffset = 0` | `start(resumeAtBeat:)` @ `:851` — ramo **RESUME** |
| `AudioEngine.swift:975` | `self.startBeatOffset = 0` | `start(resumeAtBeat:)` @ `:851` — ramo **STANDALONE/DIRETTORE** |
| `AudioEngine.swift:1658` | `self.startBeatOffset = 0` | `stopSync()` @ `:1625` |
| `LiveView.swift:356-358` | tre righe di **commento** | — |
| `LiveView.swift:363` | `sectionStartTick = 1 - audioEngine.startBeatOffset` | **UNICA LETTURA** |

**Dichiarazione di concorrenza, VERBATIM** — `AudioEngine.swift:355-359`:

```
 355:     // Bug 2.b ramo X — offset d'ingresso del Follower in BEAT (multiplo di bpb
 356:     // su downbeat); 0 per Director/standalone/resume. Seminato nel work item
 357:     // SHARED prima del pre-roll; letto da LiveView al primo tick per allineare
 358:     // sectionStartTick (visivo). Accesso scrittura su audioQueue, lettura su main.
 359:     private(set) var startBeatOffset: Int = 0
```

**Il seme del Follower, VERBATIM** — `AudioEngine.swift:792-804`:

```
 792:                 let bpb = Int(self._beatsPerBarQ)
 793:                 let offset = bpb > 0
 794:                     ? Int((startBeat / Double(bpb)).rounded()) * bpb
 795:                     : Int(startBeat.rounded())
 796:                 // Rete portante: semina SOLO se l'offset è coerente con la
 797:                 // sezione. Fuori (0, _sectionTotalBeats) → no-op = comportamento
 798:                 // di oggi (counter da bar 1), niente swap immediato né brano rotto.
 799:                 if offset > 0 && offset < self._sectionTotalBeats {
 800:                     self.startBeatOffset = offset
 801:                     self._sectionBeatCounter = offset
 802:                 } else {
 803:                     self.startBeatOffset = 0
 804:                     self._sectionBeatCounter = 0
```

#### RISPOSTA ALLA DOMANDA DEL §2.3: **SI'.**

**La X dipende da `startBeatOffset`, e il collegamento e' a tre passi, tutti
dentro la stessa closure su main:**

1. `LiveView.swift:363` — `sectionStartTick = 1 - audioEngine.startBeatOffset`
2. `LiveView.swift:392` — `relativeTick = tickN - sectionStartTick + 1`
3. `LiveView.swift:394` — `session.currentBar = ((relativeTick - 1) / bpb) + 1`

Sostituendo, **al primo tick** (`tickN == 1`, ramo `:362`), con
`k = startBeatOffset` e `b = bpb`:

```
sectionStartTick = 1 - k
relativeTick     = 1 - (1 - k) + 1 = k + 1
currentBar       = (k / b) + 1
```

⇒ **`k = 0` (Director/standalone/resume, siti `:944` `:975`) ⇒ `currentBar = 1`.**
⇒ **`k = offset` (Follower, sito `:800`, sempre multiplo di `b` per `:793-795`)
⇒ `currentBar = (offset / b) + 1`.**

### §2.4 · Ordine d'esecuzione dal tocco su Play al primo beat udibile

**[M] Callsite di `start()` in Vista LIVE:** `SetlistRunner.swift:233`
(`audioEngine.start()`). Gli altri callsite misurati sono
`ContentView.swift:53`, `DebugView.swift:164`, `AudioEngine.swift:542` (callback
Link), `AudioEngine.swift:1784` (`start(resumeAtBeat:)`).

**Sequenza, con la coda dichiarata a ogni passo:**

| # | coda | riga | atto |
|---|---|---|---|
| 1 | **main** | `TransportView.swift:35-37` | tap: `if audioEngine.isPlaying { stop() } else …` |
| 2 | **main** | `SetlistRunner.swift:233` | `audioEngine.start()` |
| 3 | **chiamante** | `AudioEngine.swift:852-855` | `os_log` ENTRY — **fuori da audioQueue** |
| 4 | **→ audioQueue** | `AudioEngine.swift:857` | `audioQueue.async { [weak self] in` |
| 5 | audioQueue | `:872-881` | `bufferCount=0`, `beatTotal=0`, **`beatTickCounter = 0`** (`:874`), `_sectionBeatCounter = 0` (`:878`), playhead a -1 |
| 6 | audioQueue | `:883-886` | `try engine.start()`, `playerNode.reset()`, `playerNode.play()`, `isRunning = true` |
| 7 | audioQueue | `:929-931` | `link_engine_set_quantum(lh, …)` |
| 8 | audioQueue | `:937` / `:971` / `:1000` | **biforcazione a tre rami** |
| 9a | audioQueue | `:944` … `:953-955` | RESUME: `startBeatOffset=0`, `linkSyncSkipBuffers=3` (`:949`), `link_engine_start_at_beat`, **3x `scheduleNextBuffer()`** |
| 9b | audioQueue | `:975` … `:993-995` | STANDALONE/DIRETTORE: `startBeatOffset=0`, `metronome_reset_for_start(h, 0.0)` (`:987`), `linkSyncSkipBuffers=3` (`:989`), `link_engine_start_at_beat_zero` (`:991`), **3x `scheduleNextBuffer()`** |
| 9c | audioQueue → **DispatchWorkItem ritardato** | `:1007` → `:727` → `:800`/`:803` → `:813-816` | SHARED: arm, ri-validazione al fire, `join_running_session` (`:757`), `metronome_reset_for_start` (`:760`), **seme** (`:800`), `linkSyncSkipBuffers=3` (`:813`), **3x `scheduleNextBuffer()`** (`:814-816`) |
| 10 | audioQueue | `:2373-2374` | dentro `scheduleNextBuffer()` @ `:2195`, per ogni beat del buffer: `beatTickCounter += 1`; `let tickN = self.beatTickCounter` |
| 11 | **→ main** | `:2375-2377` | `DispatchQueue.main.async { self?.beatTickSubject.send(tickN) }` |
| 12 | audioQueue | `:2643-2645` | `playerNode.scheduleBuffer(buffer) { self?.audioQueue.async { self?.scheduleNextBuffer() } }` |
| 13 | **→ main** | `:1024-1026` | `DispatchQueue.main.async { self.isPlaying = true; self.playbackState = .playing; … }` |
| 14 | **main** | `LiveView.swift:351` → `:363` → `:394` | l'handler legge `audioEngine.startBeatOffset` e scrive `session.currentBar` |

#### Dove l'ordine dipende da un dispatch asincrono — i siti

**[M] (1) Il seme del Follower e il pre-roll sono nella STESSA closure ritardata.**
Il work item si apre a `AudioEngine.swift:727` (`let work = DispatchWorkItem { … }`);
il seme e' a `:800`, le tre `scheduleNextBuffer()` a `:814-816`. **Sono nello
stesso blocco, in quest'ordine.** Il commento `:766-769` lo dichiara come
requisito: *«Seminiamo QUI, PRIMA del pre-roll sottostante … Seminare dopo il
pre-roll = off-by-one.»*

**[M] (2) `armSharedJoin` puo' RI-ARMARSI dall'interno del proprio work item** —
`:742-747`: se al fire il target non cade su un confine di barra e restano
re-arm, chiama `self.armSharedJoin(retriesLeft: retriesLeft - 1)` e fa `return`
**prima** di raggiungere il seme e il pre-roll.

**[M] (3) 🚨 Il tick 1 e' accodato a `main` PRIMA del blocco che pubblica
`playbackState = .playing`.** Entrambe sono `DispatchQueue.main.async` emesse
dalla stessa esecuzione su `audioQueue`, in quest'ordine di programma:

- `:993-995` chiamano `scheduleNextBuffer()` **sincronamente su audioQueue** →
  dentro, `:2375` accoda su main il `send(tickN)`;
- l'esecuzione prosegue a `:996` (`os_log`), `:1008`, `:1011-1015`, e **solo a
  `:1024`** accoda su main il blocco `isPlaying = true` / `playbackState = .playing`.

`DispatchQueue.main` e' seriale FIFO ⇒ **l'handler di `LiveView.swift:351` per il
tick 1 gira PRIMA che `session.playbackState` diventi `.playing`.**
⛔ **Nessuna conclusione: riporto i due siti e l'ordine di accodamento.**

**[M] (4) Il tick e' emesso al RIEMPIMENTO del buffer, non al render.** `:2373-2377`
sta dentro `scheduleNextBuffer()`; la consegna al player e' successiva, a `:2643`.
La dimensione del buffer e' dichiarata a `AudioEngine.swift:266`:
`private let bufferSize : AVAudioFrameCount = 512`. Tre buffer sono accodati in
tutti e tre i rami prima che il completion handler di `:2643-2645` ne accodi altri.

### §2.5 · Lo stato `.countIn` partecipa?

⚠️ **I TRE OMONIMI, separati e nominati** (trappola gia' documentata in
`HANDOFF/MISURE_CC_2026-08-18_A115-COUNTIN.md`):

| # | oggetto | dichiarazione | tipo |
|---|---|---|---|
| **[1] CAMPO del brano** | `Models/Song.swift:21` | `var countIn: Int` — commento: `// 0=nessuno, 1=1 battuta, 2=2 battute` | dato del brano |
| **[2] STATO DEL MOTORE** | `AudioEngine.swift:26` | `case countIn` dentro `enum PlaybackState` (`:24-29`) | stato engine |
| **[3] STATO DELLA UI** | `Models/LivePlaybackState.swift:5` | `case countIn(countdown: Int)` | stato vista |

**[M] Risposta, per ciascuno:**

**[1] Il CAMPO del brano non tocca la X.** `grep -rn 'countIn'` non rende alcun
sito in cui `Song.countIn` entri nel calcolo di `currentBar`: i suoi hit sono
`Song.swift` (decodifica), `QBeatsBackupManager.swift:217`, `PreviewData.swift:49`,
`SongEditorView.swift:34` (picker), `DebugView.swift` (9 costruttori a `countIn: 0`)
e i test.

**[2] Lo STATO DEL MOTORE `.countIn` non genera beat propri.** VERBATIM,
`AudioEngine.swift:1561-1563`:

```
1561:     private func startCountIn(for section: String?) {
1562:         start()
1563:     }
```

⇒ **e' un passacarte: chiama `start()` e nient'altro.** Il parametro `section`
non e' usato. Unico callsite: `:1253`, dentro `resumeFromCurrentSection`
(`os_log` a `:1248`, `playbackState = .countIn` a `:1251`).

**[3] Lo STATO DELLA UI: la X viene scritta ANCHE mentre lo stato e' `.countIn`,
e non e' visibile.** Due misure:

- **La scrittura `LiveView.swift:394` non ha alcun gate di stato.** Nel blocco
  `:351-395` riportato sopra non compare `playbackState` in nessuna condizione:
  la X e' ricalcolata a **ogni** tick ricevuto.
- **La resa la nasconde:** `BarCounterView.swift:15-16` — `case .countIn, .standby:
  Text("— / —")`. ⇒ mentre lo stato e' `.countIn` il valore esiste ed e'
  aggiornato, ma a schermo compare `— / —`.

**Cosa le succede NELL'ISTANTE in cui si esce da `.countIn`** — VERBATIM,
`LiveView.swift:301-308`:

```
301:             case .countIn:
302:                 session.playbackState = .countIn(countdown: 4)
303:             case .playing:
304:                 session.playbackState = .playing
305:                 // P2: chiusura della finestra fade se l'utente preme Play durante
306:                 // i ~500ms post-autostop (asyncAfter pendente sara' poi no-op via guard).
307:                 sectionHold = false
308:                 pendingSectionStart = false
```

⇒ **[M] All'uscita da `.countIn` NON viene toccata ne' `session.currentBar` ne'
`sectionStartTick`.** Vengono azzerati `sectionHold` e `pendingSectionStart`.
⚠️ **`pendingSectionStart = false` a `:308` spegne il ramo di ri-ancoraggio
`:365-369`**: dopo quella riga, l'unico ri-ancoraggio possibile e' `tickN == 1`
(`:362`) oppure un nuovo `runner.$currentSectionIdx` (`:403-405`).
Il valore mostrato passa da `— / —` (`BarCounterView.swift:16`) a `Bar N of M`
(`:23-32`) **con la N gia' presente in `session.currentBar` dal tick precedente.**

### §2.6 · Esiste un percorso per cui la X vale 2 prima del primo beat udibile?

⛔ **NON CONCLUDO. Espongo i siti e le relazioni misurate.**

**Percorso A — per `startBeatOffset` (aritmetico, al tick 1).**
Dalla sostituzione del §2.3: al primo tick `currentBar = (k / b) + 1` con
`k = startBeatOffset`, `b = bpb`. ⇒ **`currentBar = 2` quando `b <= k < 2b`.**
Siti che determinano `k`:
- `AudioEngine.swift:793-795` — `k` e' costruito come **multiplo intero di `b`**;
- `AudioEngine.swift:799` — seminato **solo se** `offset > 0 && offset < _sectionTotalBeats`;
- `AudioEngine.swift:975` e `:944` — forzato a **0** nei rami STANDALONE/DIRETTORE e RESUME;
- `AudioEngine.swift:1658` — riportato a **0** in `stopSync()`;
- lettura unica: `LiveView.swift:363`.

**Percorso B — per accumulo di tick prima del render.** Siti:
- `AudioEngine.swift:2373` — `beatTickCounter += 1` avviene al **riempimento**;
- `AudioEngine.swift:993-995` (e `:953-955`, `:814-816`) — **tre** buffer riempiti
  in sequenza sincrona su `audioQueue` prima di qualsiasi ritorno;
- `AudioEngine.swift:266` — `bufferSize = 512` frame;
- `AudioEngine.swift:2326` — `beatCount = metronome_processBuffer(h, UInt32(bufferSize), …)`
  determina quanti tick nascono da un singolo buffer;
- `AudioEngine.swift:2643-2645` — solo dopo, la consegna al player e il
  ri-aggancio del successivo.

**Percorso C — per ri-ancoraggio mancato.** Siti: `LiveView.swift:362` (ramo
`tickN == 1`), `:365` (ramo `pendingSectionStart`), `:308` (spegnimento di
`pendingSectionStart` all'ingresso in `.playing`), `:404` (unico accendimento).
Se nessuno dei due rami di `:362`/`:365` scatta, `sectionStartTick` conserva il
valore precedente e `:392` calcola `relativeTick` su un'ancora vecchia.

**Percorso D — `displayBpb`.** `LiveView.swift:390` — `let bpb = max(1, Int(displayBpb))`.
`displayBpb` e' un mirror `@State` alimentato dal ramo bufferizzato `:373-381`
(applicato **dentro lo stesso handler, PRIMA** di `:390`) e da
`.onReceive(audioEngine.$beatsPerBar)` (`:318`). Il divisore di `:394` e' quindi
`displayBpb`, **non** `_beatsPerBarQ` usato da `AudioEngine.swift:792` per
costruire `k`.

---

## §3 · La frase «Garantisce Director/standalone bit-identici» — misura

**Oggetto**: `AudioEngine.swift:974` @ `6527d82b8e9314f50a6ae354a3e86c30a77aacf9`.
**Ipotesi del mandato**: un solo device, **zero peer**.

**[M] Punto di partenza misurato: con zero peer, i due modi prendono lo STESSO
ramo.** La condizione `:971` e' una disgiunzione: `(peersCount == 0 && !probe.isPlaying)`
e' vera per `.standalone`, `self._linkMode == .direttore` e' vera per `.direttore`.
⇒ **il corpo `:972-999` e' lo stesso testo per entrambi**, e al suo interno
`startBeatOffset = 0` (`:975`), `metronome_reset_for_start(h, 0.0)` (`:987`),
`linkSyncSkipBuffers = 3` (`:989`) e le tre `scheduleNextBuffer()` (`:993-995`)
sono **identici**.

### Cio' che invece E' REALMENTE DIVERSO — elenco verbatim

**[M] (1) `linkEngineHandle`: NON e' nil in nessuno dei due casi.**
`AudioEngine.swift:409` — `linkEngineHandle = link_engine_create()` — creato
**incondizionatamente** in fase di setup; l'unico annullamento e'
`link_engine_destroy` a `:633`, in distruzione. ⇒ **tutti i
`if let lh = self.linkEngineHandle` del percorso d'avvio (`:929`, `:950`, `:966`,
`:990`) passano in entrambi i modi.**

**[M] (2) `linkEnabled` e' un ASSE INDIPENDENTE da `_linkMode`, e chi lo decide e'
un altro.**
- `AudioEngine.swift:37` — `@Published var linkEnabled: Bool = false`;
- deciso da `func setLinkEnabled(_ enabled: Bool)` @ `:1295`, che a `:1304` chiama
  `link_engine_set_enabled(lh, enabled)`; secondo callsite `disableLinkOnTerminate()`
  @ `:1337-1343`;
- `_linkMode` e' scritto **in un solo punto**: `AudioEngine.swift:209` —
  `self._linkMode = s.linkMode`, dalle impostazioni, con mirror UI a `:227`;
- `AppSettings.swift:5` VERBATIM: `// Isolamento = Link OFF (linkEnabled default false). RUOLO scelto, ≠ stato-connessione "nessun peer".`

⇒ **Il ramo `:971-999` non consulta `linkEnabled` in nessun punto.**

**[M] (3) 🚨 L'early-return del bridge NON copre tutte le funzioni Link. Due non
hanno il guard.** Mappa completa di `LinkEngine.mm` @ HEAD:

| funzione | riga | guard `enabled_` |
|---|---|---|
| `link_engine_probe_session` | `:406` | **SI'** — `:412` |
| `link_engine_start_at_beat_zero` | `:427` | **SI'** — `:431` |
| `link_engine_start_at_beat` | `:447` | **SI'** — `:452` |
| `link_engine_join_running_session` | `:465` | **SI'** — `:469` |
| `link_engine_stop` | `:485` | **SI'** — `:488` |
| `link_engine_sync_phase` | `:532` | **SI'** — `:538` |
| `link_engine_assert_session_state` | `:626` | **SI'** — `:632` |
| `link_engine_set_bpm_and_beat_at_time` | `:192` | **SI'** — `:198` |
| **`link_engine_num_peers`** | `:111` | ⛔ **NO** |
| **`link_engine_set_quantum`** | `:123` | ⛔ **NO** |

VERBATIM, `LinkEngine.mm:111-127`:

```
111: uint32_t link_engine_num_peers(LinkEngineHandle handle) {
112:     if (!handle) return 0;
113:     LinkEngine* engine = (LinkEngine*)handle;
114:     return engine->numPeers_.load();
115: }
...
123: void link_engine_set_quantum(LinkEngineHandle handle, double quantum) {
124:     if (!handle) return;
125:     LinkEngine* engine = (LinkEngine*)handle;
126:     engine->quantum_.store(quantum);
127: }
```

e la forma del guard, VERBATIM da `link_engine_probe_session`:

```
409:     LinkSessionProbe probe = { false, 0.0, 0.0 };
410:     if (!handle) return probe;
411:     LinkEngine* engine = (LinkEngine*)handle;
412:     if (!engine->enabled_.load(std::memory_order_relaxed)) return probe;
```

**[M] (4) Conseguenza misurabile sul percorso d'avvio, riga per riga:**

| riga | chiamata | Link **abilitato** | Link **disabilitato** |
|---|---|---|---|
| `:930` | `link_engine_set_quantum` | esegue | **esegue lo stesso** (nessun guard) |
| `:967` | `link_engine_probe_session` | probe reale (`ABLLinkCaptureAppSessionState` … `Commit`) | **early-return**: `probe = {false, 0.0, 0.0}` |
| `:968` | `link_engine_num_peers` | legge `numPeers_` | **legge `numPeers_` lo stesso** (nessun guard) |
| `:991` | `link_engine_start_at_beat_zero` | esegue **`ABLLinkSetIsPlayingAndRequestBeatAtTime(state, true, hostTime, 0.0, quantum)`** + capture/commit (`LinkEngine.mm:434-444`) | **early-return: NO-OP** |

**[M] (5) Divergenza `_linkMode` FUORI dal ramo d'avvio — tre siti.**
- `AudioEngine.swift:428-434` (callback tempo): `if engine._linkMode == .direttore { … return }`
  — il Direttore **ri-impone** il proprio BPM a Link (`:431`) e **non adotta**
  quello del peer;
- `AudioEngine.swift:533`: `if engine._linkMode == .direttore { return }` — il
  Direttore non segue lo start/stop del peer;
- `AudioEngine.swift:2267-2290` — **sul percorso audio, dentro `scheduleNextBuffer()`**:

```
2267:                 if self.linkSyncSkipBuffers > 0 {
2268:                     self.linkSyncSkipBuffers -= 1
...
2271:                 } else if _linkMode == .direttore {
...
2284:                     link_engine_assert_session_state(lh, hostTimeAtOutput,
2285:                                                     currentBeat, _audioBPM)
2286:                 } else if link_engine_sync_phase(lh, hostTimeAtOutput, currentBeat, &newBeat) {
2287:                     midi_engine_set_beat_position(mh, newBeat)
...
2290:                     metronome_set_beat_position_time_only(h, newBeat)
```

⇒ **`linkSyncSkipBuffers = 3` e' identico nei due modi** (`:989`, stesso testo),
ma **dal quarto buffer in poi i due modi imboccano rami diversi**: `.direttore` →
`link_engine_assert_session_state` (`:2284`), `.standalone` → `link_engine_sync_phase`
(`:2286`), che in caso di successo **riscrive la posizione di beat** a `:2287` e
`:2290`.

### 🚨 §3-bis · Altri TRE riferimenti di riga scaduti, trovati strada facendo

**[M]** Oltre a quello del §2.2-bis:

| commento | dice | a HEAD e' |
|---|---|---|
| `AudioEngine.swift:764-765` | «`_sectionBeatCounter` … azzerato da **loadSection (936-944)** e da **start() (~634)**» | `func loadSection` apre a **`:1140`** (azzeramenti a `:1147` e `:1151`); l'azzeramento in `start()` e' a **`:878`**. Le righe 936-944 sono il ramo RESUME di `start()`; la riga 634 e' `qbeats_link_pending_destroy(linkPending)` |
| `AudioEngine.swift:2273` | «isRunning è già garantito true dal **guard a riga 1359**» | `:1359` e' una parentesi graffa di chiusura. Il guard reale e' `AudioEngine.swift:2196` — `guard isRunning, let h = metronomeHandle else { return }` |
| `LiveView.swift:354` | «beatTickCounter azzerato in start(), **AudioEngine.swift:635**» | vedi §2.2-bis: **`:874`** |

⛔ **Non ho toccato nessuno di questi commenti.**

---

## §4 · Inventario dello strumento di diagnosi — nessuna esecuzione

### §4.1 · Il ramo e i due commit

**[M] Il ramo ESISTE sul remoto.**
`git ls-remote origin refs/heads/feat/diag-first-beat-and-beat-drop-and-3-4-long`:

```
b239b1d6f5d8acb8db1359a3223733cc95d76ebe	refs/heads/feat/diag-first-beat-and-beat-drop-and-3-4-long
```

✅ Controllo positivo nella stessa forma: `refs/heads/master` rende
`6527d82b8e9314f50a6ae354a3e86c30a77aacf9`.
**Tip locale = tip remoto = `b239b1d6f5d8acb8db1359a3223733cc95d76ebe`.**

**[M] I due commit sono RAGGIUNGIBILI** — verificati come **antenati del tip del
ramo** con `git merge-base --is-ancestor`, non solo come oggetti esistenti:

| commit (40) | antenato del ramo | in master | data | oggetto |
|---|---|---|---|---|
| `70bb86a13ef22c30aa7727f50662d7370a9f79a6` | **SI'** | **NO** | 2026-05-24 | `diag: setlist 3/4 Long per prerequisito Item 5 TD #39` |
| `31dddbb9aaa561c1e3a83fafde60687e45b23de3` | **SI'** | **NO** | 2026-05-24 | `diag: log T0-T9 dispatch chain play start Collaborative (TD #A)` |

### §4.2 · `[Q-BEATS][DIAG-A]` vive su master?

**[M] NO — zero su master, dieci sul ramo.** Misurato con `git grep` **sui ref**,
non sul disco:

| ref | `DIAG-A` | esito |
|---|---|---|
| `master` | **0** (exit 1) | assente |
| `feat/diag-first-beat-…` | **10** in `ios_app/QBeats/AudioEngine.swift` | presente |

✅ **Controllo positivo nella stessa forma su master:**
`git grep -c 'Q-BEATS\]\[LINK' master -- '*.swift'` rende
`ios_app/QBeats/AudioEngine.swift:13` ⇒ **la sonda vede su master.**
✅ **Controllo negativo nella stessa forma:** una stringa inventata rende 0 su
entrambi i ref.

**Le dieci righe, VERBATIM (numeri di riga SUL RAMO):**

```
AudioEngine.swift:430:   os_log("[Q-BEATS][DIAG-A][T0] t=%llu isPlaying=%d",
AudioEngine.swift:439:   os_log("[Q-BEATS][DIAG-A][T1] t=%llu isPlaying=%d",
AudioEngine.swift:542:   os_log("[Q-BEATS][DIAG-A][T2] t=%llu",
AudioEngine.swift:664:   os_log("[Q-BEATS][DIAG-A][T3] t=%llu peers=%u probeIsPlaying=%d probePhase=%.4f probeTempo=%.2f",
AudioEngine.swift:700:   os_log("[Q-BEATS][DIAG-A][T4] t=%llu futureHostTime=%llu delaySec=%.6f",
AudioEngine.swift:717:   os_log("[Q-BEATS][DIAG-A][T5] t=%llu futureHostTime=%llu",
AudioEngine.swift:725:   os_log("[Q-BEATS][DIAG-A][T6] t=%llu",
AudioEngine.swift:731:   os_log("[Q-BEATS][DIAG-A][T7] t=%llu",
AudioEngine.swift:739:   os_log("[Q-BEATS][DIAG-A][T8] t=%llu skipBufs=%d",
AudioEngine.swift:1911:  os_log("[Q-BEATS][DIAG-A][T9] t=%llu bufCount=0 skipBufs=%d",
```

### §4.3 · Censimento della divergenza — ⛔ nessun tentativo di merge

**[M] MERGE-BASE** = `cb92faa5337fb1e5646023aee8ba9a99ce679184`
— `2026-05-24`, `fix(settings): default LinkMode da .direttore a .collaborativa`.

**[M] DIVERGENZA**: **master avanti di 200 commit · ramo avanti di 9 commit.**

**[M] File toccati dal ramo (merge-base → tip): QUATTRO.**

| file | commit su master dal merge-base |
|---|---|
| `ARCHIVIO.MD/24_05_2026/BOX3_V66_24_05_2026.md` | **0** |
| `ARCHIVIO.MD/24_05_2026/RECAP_BUG_SESSIONE_24_05_2026.md` | **0** |
| `ios_app/QBeats/AudioEngine.swift` | **5** |
| `ios_app/QBeats/DebugView.swift` | **5** |

⚠️ **Il «5» l'ho rimisurato con TRE forme** perche' `rev-list` con pathspec
semplifica la storia e puo' sotto-contare: **semplificata = 5, `--full-history` = 5,
`--follow` = 5.** Le tre concordano.
✅ Controllo positivo: `git rev-list --count cb92faa..master` (senza pathspec) = **200**.

**[M] I cinque commit di master su `AudioEngine.swift`:**

```
9a78d4b  2026-07-15  NODO A atomo 1 — ruolo Link Solo come default: +case .standalone, badge SOLO, 3 default → .standalone
06b17b6  2026-07-06  ios_app+core: ATOM C — subdivision schedulata al downbeat (seamless sample-accurate) + cancel allo stop
dfe758d  2026-06-18  Bug 1 (faccia visiva Bug 2.b, BUGS 1.2): rimosso republish stantio di currentAccentPattern in start()
ee0cbc0  2026-06-11  Bug 2.b - Ferita A + Ferita B (mark-preserving L1)
007de87  2026-05-29  feat(link): Fase 6-7 — Bug 4 + CD-6 WAITING FOR DIRECTOR + badge HEAD + rafforzamento modalità Direttore
```

**[M] Ampiezza reale della divergenza sui due file di codice** (`git diff --stat`):

```
merge-base → master:   AudioEngine.swift | 551 ++++--    DebugView.swift | 210 ++++
                       2 files changed, 663 insertions(+), 98 deletions(-)

merge-base → ramo:     AudioEngine.swift |  35 ++++      DebugView.swift |  34 ++++
                       2 files changed, 69 insertions(+)
```

**[M] Righe totali di `AudioEngine.swift`: ramo = 2759, master = 3079.**

**[M] La regione strumentata da T3-T8 non esiste piu' nella stessa forma su master.**
`git grep -c 'armSharedJoin'`:

| ref | esito |
|---|---|
| `feat/diag-first-beat-…` | **0** (exit 1) — la funzione **non esiste sul ramo** |
| `master` | **5** in `ios_app/QBeats/AudioEngine.swift` |

✅ Lo zero e' tarato dal controllo positivo su master nella forma identica.
`armSharedJoin` e' introdotta da `ee0cbc0` (11/06, *Bug 2.b - Ferita A*), che su
`AudioEngine.swift` porta **299 inserzioni e 74 delezioni**. Le righe di ramo
`:664`-`:739` (T3…T8) cadono nella regione dell'ingresso SHARED che quel commit
ha riscritto.

**[M] I nove commit del ramo: due sono `diag:`, sette sono `docs(archivio):`.**

```
b239b1d  2026-05-24  docs(archivio): BOX3 V66 — roadmap ratificata referee + correzione timebase 24 MHz
6135a57  2026-05-24  docs(archivio): recap 24/05 — roadmap ratificata referee + correzione timebase iPad 24 MHz
db3094a  2026-05-24  docs(archivio): BOX3 V66 stub — sessione diagnostica 24/05/2026
deea3bd  2026-05-24  docs(archivio): aggiorna recap 24/05 — validazione esterna pattern via Soundbrenner
411a240  2026-05-24  docs(archivio): aggiorna recap 24/05 — precisazione first-mover vs Director
ff97ef0  2026-05-24  docs(archivio): aggiorna recap 24/05 — chiarimento Mauro Bug 1 = feature UX incompleta
1814f3e  2026-05-24  docs(archivio): recap bug sessione CC 24/05/2026 — 8 bug + note referee
31dddbb  2026-05-24  diag: log T0-T9 dispatch chain play start Collaborative (TD #A)
70bb86a  2026-05-24  diag: setlist 3/4 Long per prerequisito Item 5 TD #39
```

⛔ **Nessun merge, nessun cherry-pick, nessun test di merge e' stato tentato.**

---

## §5 · R-δ — deposito

**[M] DUE scritture, nessun indirizzo Drive** (Drive e' il riflesso di `E:` e
arriva da solo — BOX5 V29, capitolo «R-δ»).

```
C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\MISURE_CC_2026-08-21_A166-CONTATORE-BATTUTA-ORIGINE.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-21_A166-CONTATORE-BATTUTA-ORIGINE.md
```

Verifica delle due gambe (`cmp` exit e sha256) dichiarata nel messaggio di
consegna che accompagna questo referto.

⛔ **Nulla e' stato committato. `ios_app/` non e' stato toccato. Nessun file
spostato o cancellato.**

---

*A166-FINE*
