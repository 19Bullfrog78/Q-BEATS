# MISURE CC — A172 · GLI INGRESSI DEL CONTATORE DI BATTUTA

Da: CC · A: **referee** (+ Mauro)
Mandato: `A172-INGRESSI-DEL-CONTATORE-BATTUTA` · **SOLA LETTURA**
Tutto misurato il **22/08/2026** contro il blob a **`4629ee9`** (`git show 4629ee9:<path>`),
non contro il disco.

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato da altri, non
rimisurato · **[A]** giudizio mio.
⛔ **I tre registri non sono mai mescolati in una stessa frase.**
⛔ **Nessuna conclusione**: questo referto enumera. L'ipotesi la formula il referee.
⛔ **Nulla e' stato modificato**: nessun edit sotto `ios_app/`, nessun commit, nessuna build.

---

## §0 · ID `A172` — LIBERO su entrambe le gambe

### Sonda per NOME (potata, trappola ①)

```
find "$R" -path "$R/.git" -prune -o -iname "*A172*" -print      ->  0
find "$E"                          -iname "*A172*" -print       ->  0
```

**[M] Controllo positivo nella forma identica:** `A170` rende **1** per gamba
(`HANDOFF/CONGEDO_CC_2026-08-22_A166-A170.md`), `A166` rende **2** per gamba. La sonda vede.

⚠️ **[M] La trappola ① MORDE proprio su A172.** La stessa sonda **senza potatura** rende **1**:

```
<REPO>/.git/objects/ba/aa172895cfafba57b187356ed8ae1036eee17e
```

**[M] E non e' un blob qualunque:** `baaa172895cfafba57b187356ed8ae1036eee17e` e' il commit
su cui gira la run `iOS Signed Build` del 21/08 alle 08:46. Un `find` non potato avrebbe
dichiarato `A172` **occupato**.

### Sonda per CONTENUTO

| gamba | hit grezzi | dopo lettura hit-per-hit |
|---|---|---|
| repo (`--exclude-dir=.git`) | **0** | 0 |
| `E:` (tutto) | **8** | **0** — tutti e 8 in `LOG/RUN/TEST LUNGA DISTANZA/` |

**[M] Forma esatta di cio' che matcha** — e' la classe ② (log di device), non un riferimento a mandato:

```
[corewifi] [8A172] Incoming QoS          uuid=1A172 pid=135 proc=...
0s, uuid: 0D4CA172-BAD7-4540-BC0         -AEEB-E3544538A172 Hostname#5d2f
```

**[M] Le tre classi di rumore sono state tutte coperte dalla sonda**, non solo cercate:

- classe ① `.git/objects` — **presente** su A172, neutralizzata dalla potatura (sopra);
- classe ② log di device — **presente**, 8 hit, tutti letti;
- classe ③ payload base64 negli HTML di CD — **controllo positivo eseguito**: la stessa sonda
  su `A170` trova `DA_CD_PER_CC/11_07_2026/1Q-BEATS/Q-BEATS Vista LIVE v2 (standalone).html`.
  Quindi la classe ③ **e' raggiungibile** dalla sonda usata, e su `A172` rende zero.

=> **[M] `A172` e' LIBERO.**

### La tua assunzione su A171 — MISURATA, REGGE

**[M] `A171` non esiste come mandato su nessuna delle due gambe.**
Per NOME: **0** e **0**. Per CONTENUTO: **0** su repo, **8** su `E:`, **tutti e 8 in `LOG/`**,
stessa classe ② (`uuid=3A171`, `[corewifi] [A171B]`, `A171681C-580B-42FE`).

⚠️ **[M] Anche `A171` fa scattare la trappola ①**: non potata, la sonda per nome rende
`.git/objects/b6/60399acf27b87a1091ec64567c717a17103b24`.

=> **[M] Nessun artefatto `A171` su disco. L'annullamento non ha lasciato residui.**

---

## §1 · LA MAPPA DEGLI INGRESSI

### 1.0 · Dove il valore viene scritto — sito UNICO

**[M] Sonda:** `grep -rn --include='*.swift' -E '\.currentBar *(=[^=]|\+=)' ios_app/QBeats`
**[M] Risultato: 1 riga.** **[M] Controllo positivo forma identica** su `.beatActive` = **5** righe. La sonda vede.

`ios_app/QBeats/UI/Live/LiveView.swift:390-394 @ 4629ee9`, verbatim:

```swift
            let bpb = max(1, Int(displayBpb))
            // Tick relativo alla sezione corrente (1-based dentro la sezione).
            let relativeTick = tickN - sectionStartTick + 1
            session.beatActive = ((relativeTick - 1) % bpb) + 1
            session.currentBar = ((relativeTick - 1) / bpb) + 1
```

**[M]** Il blocco vive dentro `.onReceive(audioEngine.beatTickSubject) { tickN in` (`:351`).
**[M]** L'unica altra scrittura di `currentBar` in tutto il progetto e' l'inizializzatore
`LiveSession.swift:19` -> `@Published var currentBar: Int = 1`.

### 1.1 · ⚠️ PRIMA del numero ci sono DUE CANCELLI DI VISUALIZZAZIONE

**[M]** `session.currentBar` **non e' cio' che l'utente legge**. Passa per
`BarCounterView.swift @ 4629ee9`, che ha due uscite alternative prima del numero:

```swift
 14        switch state {
 15        case .countIn, .standby:
 16            Text("— / —")
 ...
 20            let isInf   = total == -1
 21            let isReady = total > 0 || isInf
 ...
 25                + Text(isReady ? "\(current)" : "—")
```

**[M] Cancello A** — `state` = `session.playbackState`: se vale `.countIn` o `.standby`,
il contatore rende **`— / —`** e `current` **non viene nemmeno letto**.
**[M] Cancello B** — `total` = `session.totalBarsInSection`: se `total <= 0 && total != -1`,
al posto del numero compare **`—`**.

**[M]** `session.playbackState` ha **11** scritture (`SetlistRunner.swift:148/308/382/411` ·
`LiveView.swift:161/286/302/304/310` · `TransportView.swift:58`; init `.stopped` a `LiveSession.swift:35`).
**[M]** `session.totalBarsInSection` ha **3** scritture (`SetlistRunner.swift:283` ·
`LiveView.swift:348` · `LiveView.swift:387`; init **4** a `LiveSession.swift:20`).

### 1.2 · (a) LE VARIABILI CHE ENTRANO NEL CALCOLO — sette

| # | variabile | dove vive | entra come |
|---|---|---|---|
| 1 | `tickN` | parametro di chiusura, `LiveView.swift:351` | termine di `relativeTick` |
| 2 | `sectionStartTick` | `@State`, `LiveView.swift:16` | termine di `relativeTick` |
| 3 | `displayBpb` | `@State`, `LiveView.swift:41` | divisore `bpb` |
| 4 | `pendingBpb` | `@State`, `LiveView.swift:43` | puo' **riscrivere** `displayBpb` a `:374`, prima che `:390` lo legga |
| 5 | `pendingSectionStart` | `@State`, `LiveView.swift:17` | sceglie **quale** ramo scrive `sectionStartTick` |
| 6 | `audioEngine.startBeatOffset` | `AudioEngine.swift:359` | unico ingresso di `sectionStartTick` a `:363` |
| 7 | `beatTickCounter` | `AudioEngine.swift:122` | **sorgente** di `tickN` |

⚠️ **[M] `startBeatOffset` NON e' `@Published`**: `private(set) var startBeatOffset: Int = 0`
(`AudioEngine.swift:359`). Viene **letto** a `LiveView.swift:363` come proprieta' semplice.

### 1.2 · (b) TUTTI GLI SCRITTORI, con la condizione — non solo il primo

**[M] Sonda usata per ogni riga:**
`grep -rn --include='*.swift' --include='*.mm' --include='*.h' --include='*.cpp' -E "\b<VAR>\b *(=[^=]|\+=|-=|\*=)" ios_app/QBeats core_engine`
**[M] Righe di commento scartate a mano, hit per hit.**
**[M] Controllo positivo forma identica:** la stessa sonda su `scheduleNextBuffer` rende **14** righe non-commento.

---

**① `beatTickCounter`** — `AudioEngine.swift:122`, `private var beatTickCounter: Int = 0`

| riga | scrittura | condizione per eseguirla |
|---|---|---|
| `:874` | `self.beatTickCounter = 0` | dentro `start()` (`:851`), dopo il `guard` di `:859` e dentro il `do {` di `:871` |
| `:1650` | `self.beatTickCounter = 0` | dentro `stopSync()` (`:1625`), dopo il `guard self.isRunning` di `:1638` |
| `:2373` | `self.beatTickCounter += 1` | dentro `scheduleNextBuffer()` (`:2195`), sotto `if beatCount > 0` (`:2360`) **e** `if isBeat` (`:2372`) |

**[M]** `tickN` e' lo snapshot preso subito dopo l'incremento: `:2374` `let tickN = self.beatTickCounter`,
inviato a `:2376` dentro `DispatchQueue.main.async`.

---

**② `sectionStartTick`** — `LiveView.swift:16`, `@State private var sectionStartTick: Int = 1`

| riga | scrittura | condizione |
|---|---|---|
| `:363` | `sectionStartTick = 1 - audioEngine.startBeatOffset` | `if tickN == 1` |
| `:368` | `sectionStartTick = tickN` | `else if pendingSectionStart` |

⚠️ **[M] I due rami sono mutuamente esclusivi e non c'e' un `else` finale.** Se `tickN != 1`
**e** `pendingSectionStart == false`, **nessuno dei due gira** e `sectionStartTick` conserva
il valore precedente.

---

**③ `displayBpb`** — `LiveView.swift:41`, `@State private var displayBpb: UInt32 = 4`

| riga | scrittura | condizione |
|---|---|---|
| `:217` | `displayBpb = audioEngine.beatsPerBar` | dentro `.onAppear` (`:211`), incondizionata |
| `:245` | `displayBpb = section.beatsPerBar` | dentro `.onAppear`, sotto `if let section = runner.currentSection` — **sovrascrive `:217`** |
| `:329` | `displayBpb = beats` | in `.onReceive(audioEngine.$beatsPerBar)` (`:318`), ramo **`else`** di `if audioEngine.isPlaying` |
| `:374` | `displayBpb = bpb` | **dentro l'handler del tick**, sotto `if let bpb = pendingBpb` (`:373`) — gira **prima** che `:390` legga `displayBpb` |

**[M]** La sorgente `audioEngine.beatsPerBar` e' `@Published var beatsPerBar : UInt32 = 4`
(`AudioEngine.swift:57`) con `didSet`; ha **2** scritture in `AudioEngine` (`:1364`, `:2591`).

---

**④ `pendingBpb`** — `LiveView.swift:43`, `@State private var pendingBpb: UInt32? = nil`

| riga | scrittura | condizione |
|---|---|---|
| `:323` | `pendingBpb = beats` | ramo **`if audioEngine.isPlaying`** di `.onReceive($beatsPerBar)` |
| `:380` | `pendingBpb = nil` | dopo il consumo a `:374` |

---

**⑤ `pendingSectionStart`** — `LiveView.swift:17`, `@State private var pendingSectionStart: Bool = false`

| riga | scrittura | condizione |
|---|---|---|
| `:404` | `pendingSectionStart = true` | `.onReceive(runner.$currentSectionIdx)` — **unica scrittura a `true`** |
| `:308` | `pendingSectionStart = false` | `.onReceive(audioEngine.$playbackState)`, `case .playing` |
| `:364` | `pendingSectionStart = false` | `if tickN == 1` |
| `:369` | `pendingSectionStart = false` | `else if pendingSectionStart` |

---

**⑥ `startBeatOffset`** — `AudioEngine.swift:359`, `private(set) var startBeatOffset: Int = 0`

| riga | scrittura | condizione |
|---|---|---|
| `:800` | `self.startBeatOffset = offset` | dentro il `DispatchWorkItem` di `armSharedJoin` (`:727`), sotto `if offset > 0 && offset < self._sectionTotalBeats` (`:799`) |
| `:803` | `self.startBeatOffset = 0` | `else` dello stesso `if` — logga sempre come anomalia (`:808`) |
| `:944` | `self.startBeatOffset = 0` | `start()`, ramo **RESUME** (`if resumeAtBeat != nil`, `:937`) |
| `:975` | `self.startBeatOffset = 0` | `start()`, ramo **STANDALONE/DIRETTORE** (condizione a `:971`) |
| `:1658` | `self.startBeatOffset = 0` | `stopSync()`, dopo il `guard self.isRunning` di `:1638` |

**[M] La condizione di `:971`, verbatim:**

```swift
                        if (peersCount == 0 && !probe.isPlaying) || self._linkMode == .direttore {
```

**[M] Il valore di `offset` a `:800` viene da `:793-795`**, verbatim:

```swift
                let offset = bpb > 0
                    ? Int((startBeat / Double(bpb)).rounded()) * bpb
                    : Int(startBeat.rounded())
```

### 1.2 · (c) VALORE SE NESSUNO SCRITTORE GIRA — l'inizializzatore

| variabile | valore di default | dichiarato a |
|---|---|---|
| `beatTickCounter` | **0** | `AudioEngine.swift:122` |
| `sectionStartTick` | **1** | `LiveView.swift:16` |
| `displayBpb` | **4** | `LiveView.swift:41` |
| `pendingBpb` | **nil** | `LiveView.swift:43` |
| `pendingSectionStart` | **false** | `LiveView.swift:17` |
| `startBeatOffset` | **0** | `AudioEngine.swift:359` |
| `session.currentBar` | **1** | `LiveSession.swift:19` |
| `session.totalBarsInSection` | **4** | `LiveSession.swift:20` |
| `session.playbackState` | **`.stopped`** | `LiveSession.swift:35` |

### 1.2 · (d) QUALI SCRITTORI POSSONO NON ESSERE ESEGUITI IN UN AVVIO

**[M] ⑥.1 — `:975`, `:944` e `:800/:803` sono TRE RAMI ALTERNATIVI dello stesso avvio.**
`start()` ne sceglie uno solo: RESUME (`:937`), STANDALONE/DIRETTORE (`:971`), SHARED (`:1000`).
Sul ramo SHARED **nessuno dei tre gira dentro `start()`**: `:1007` chiama `armSharedJoin`,
e `:800/:803` vivono in un `DispatchWorkItem` (`:727`) dispatchato con
`audioQueue.asyncAfter` a `:848` — cioe' **dopo** che `start()` e' gia' tornato.

**[M] ⑥.2 — Sul ramo SHARED il work item puo' non arrivare mai a `:800`.** A `:741-747`:

```swift
                if distToBar > AudioEngine.kSharedJoinPhaseTolBeats {
                    if retriesLeft > 0 {
                        ...
                        self.armSharedJoin(retriesLeft: retriesLeft - 1)
                        return
                    }
```

**[M]** Il `return` di `:747` esce prima di `:800`. `kSharedJoinMaxRearms = 2` (`:660`).

**[M] ①.1 — `:874` (l'azzeramento del contatore) e' saltato se la guardia di `:859` non passa**, verbatim:

```swift
 851    func start(resumeAtBeat: Double? = nil) {
 ...
 857        audioQueue.async { [weak self] in
 858            guard let self else { return }
 859            guard !self.isRunning, let _ = self.metronomeHandle else {
 860                os_log("[Q-BEATS][START] -> NO METRONOME CALL in this branch", ...)
 862                return
 863            }
```

**[M] ①.2 — `:1650` (l'azzeramento in `stopSync()`) e' saltato** se `guard self.isRunning`
a `:1638` non passa.

**[M] ③.1 — `:217` e `:245` girano solo su `.onAppear`.** `:245` richiede in piu'
`runner.currentSection != nil`.
**[M] ③.2 — `:329` richiede `audioEngine.isPlaying == false`** al momento della consegna
del `@Published`; se e' `true` scrive `:323` (`pendingBpb`) invece.
**[M] ③.3 — `:374` richiede `pendingBpb != nil`.**

**[M] ②.1 — `:363` e `:368` possono non girare entrambi** (vedi ② sopra).

**[M] ⑤.1 — `:308` richiede una consegna `.playing` su `audioEngine.$playbackState`.**

### 1.3 · Aritmetica al primo battito — solo i valori, senza conclusione

**[M]** Con `tickN == 1` il ramo `:363` scrive `sectionStartTick = 1 - startBeatOffset`,
quindi `:392` da' `relativeTick = 1 - (1 - startBeatOffset) + 1 = startBeatOffset + 1`.

| `startBeatOffset` | `bpb` | `relativeTick` | `session.currentBar` a `:394` |
|---|---|---|---|
| 0 | 4 | 1 | **1** |
| 4 | 4 | 5 | **2** |
| 8 | 4 | 9 | **3** |
| 8 | 3 | 9 | **3** |

⛔ **Non traggo conclusioni da questa tabella: e' l'aritmetica di `:390-394` applicata ai valori
che gli scrittori enumerati sopra possono produrre.**

---

## §2 · LE DUE RIMISURE

### 2.1 · Il tick 1 accodato su main PRIMA del flip a `.playing`

**[R] Sonda del congedo A166->A170 §3.3:** ordine di programma delle due
`DispatchQueue.main.async` (`:2375` e `:1024`) + serialita' FIFO di `DispatchQueue.main`.

**[M] Sonda DIVERSA usata stavolta — tracciamento del grafo di chiamata a caccia di un hop asincrono:**

```
grep -nE 'DispatchQueue|\.async|\.sync|await'   sul tratto :2196-:2377
```

**[M] Rende 4 hit, tutte e quattro `DispatchQueue.main.async`** (`:2235`, `:2294`, `:2363`, `:2375`):
sono **accodamenti**, nessuna interrompe il flusso sincrono da `scheduleNextBuffer()` (`:2195`) a `:2375`.
**[M] Controllo positivo della sonda:** la stessa forma sul tratto `:727-:848` **trova**
l'`asyncAfter` di `:848`. La sonda sa vedere un hop quando c'e'.

**[M] ESITO — regge su due rami su tre, e sul terzo l'ordine si INVERTE.**

| ramo di `start()` | dove sono le `scheduleNextBuffer()` | rapporto con `:1024` |
|---|---|---|
| RESUME (`:937`) | `:953-955`, **sincrone** nello stesso blocco `audioQueue` | tick 1 accodato **PRIMA** ✅ |
| STANDALONE/DIRETTORE (`:971`) | `:993-995`, **sincrone** nello stesso blocco | tick 1 accodato **PRIMA** ✅ |
| **SHARED (`:1000`)** | `:814-816`, **dentro il `DispatchWorkItem` di `:727`**, dispatchato con `audioQueue.asyncAfter` a `:848` | ⛔ `start()` prosegue **subito** fino a `:1024` => `.playing` accodato **PRIMA** di qualunque tick |

⚠️ **[M] Il congedo cita `:993-995`, che sono le `scheduleNextBuffer()` del ramo
STANDALONE/DIRETTORE.** Su quel ramo la sua misura **regge**, verificata con sonda diversa.
**[M] Il congedo non dichiara un perimetro di ramo**, e i rami sono tre.

### 2.2 · Percorsi di avvio in cui il contatore dei battiti NON e' riportato a zero

**[M] Gli azzeratori di `beatTickCounter` sono DUE in tutto il progetto**: `:874` (in `start()`) e
`:1650` (in `stopSync()`). **Entrambi dietro una guardia.**

**[M] I siti che producono tick sono cinque** — sono le chiamate a `scheduleNextBuffer()`,
che a `:2373` incrementa il contatore:

| # | sito | passa da un azzeramento? |
|---|---|---|
| 1 | `:953-955` — ramo RESUME di `start()` | **SI** — `:874` gira prima, stesso blocco |
| 2 | `:993-995` — ramo STANDALONE/DIRETTORE di `start()` | **SI** — `:874` gira prima, stesso blocco |
| 3 | `:814-816` — work item di `armSharedJoin` | **SI** — `:874` e' girato quando `start()` ha armato |
| 4 | `:1210-1212` — `kickScheduling()` (`:1207`) | ⛔ **NO — nessun azzeramento nel corpo** |
| 5 | `:2643-2645` — completion handler in coda a `scheduleNextBuffer()` stesso | ⛔ **NO — catena auto-sostenuta** |

**[M] Il sito 4 ha ZERO chiamanti vivi a HEAD.** Sonda: `grep -rn 'kickScheduling' ios_app/QBeats`
al netto delle righe di commento rende **1 sola riga**, la dichiarazione `:1207`.
Il suo stesso doc-comment (`:1204`) dice «Chiamare SOLO dal ramo avanza di SetlistRunner», ma
`SetlistRunner.swift:333-335` dice verbatim: «NESSUNA chiamata a setBeatsPerBar/setAccentPattern/
loadSection/scheduleBPMChange/**kickScheduling**».

**[M] Il sito 5 e' la coda di `scheduleNextBuffer()` stessa**, verbatim `:2643-2645`:

```swift
        playerNode.scheduleBuffer(buffer) { [weak self] in
            self?.audioQueue.async { self?.scheduleNextBuffer() }
        }
```

**[M] I percorsi che possono raggiungere `start()` — enumerati, non giudicati:**

| chiamante | riga | su cosa e' condizionato |
|---|---|---|
| callback Link `set_start_stop_callback` | `AudioEngine.swift:542` | `if isPlaying && !engine.isPlaying` (`:537`) + `guard !engine._linkStartEmitInFlight` (`:540`) |
| `startCountIn(for:)` -> `start()` | `AudioEngine.swift:1562` | passacarte; chiamato da `resumeFromCurrentSection()` a `:1253` |
| azione MIDI `.playPause` | `AudioEngine.swift:1609` | `if isPlaying { stop() } else { start() }` |
| `activateSessionAndStart(...)` -> `start(resumeAtBeat:)` | `AudioEngine.swift:1784` | **13 siti di chiamata** (`:1807 :1821 :2717 :2750 :2814 :2850 :2897 :2936 :2975 :3013 :3046 :3065 :3077`) |
| `SetlistRunner` | `SetlistRunner.swift:233` | nessuna guardia sul call-site |
| `ContentView` | `ContentView.swift:53` | `if audioEngine.isPlaying { stop() } else { start() }` (`:50`) |
| `DebugView` | `DebugView.swift:164` | nessuna guardia sul call-site |

⚠️ **[M] I call-site esterni si regolano su `isPlaying`; la guardia dentro `start()` (`:859`) testa `isRunning`. Sono due variabili diverse.**

| variabile | dichiarazione | scritture |
|---|---|---|
| `isPlaying` | `AudioEngine.swift:56`, **`@Published`**, `false` | `true` a `:1025` (su `main`) · `false` a `:1710`, `:2694` |
| `isRunning` | `AudioEngine.swift:273`, **`private`**, `false` | `true` a `:886` (su `audioQueue`) · `false` a `:1639`, `:2687`, `:2904`, `:3020` |

**[M] Due delle scritture di `isRunning = false` NON passano da `stopSync()`**, quindi
**non azzerano `beatTickCounter`**:

- `:2904` — ramo `else if modeChanged` (cambio Base<->Pro). Prosegue a `:2936`
  `activateSessionAndStart(resumeAtBeat: recoveryBeat, ...)`, dietro `guard wasRunning` (`:2930`).
- `:3020` — ramo config change del motore. Prosegue a `:3046`
  `activateSessionAndStart(resumeAtBeat: resumeBeat, trigger: "engine_config_change")`.

**[M] Su entrambi, `activateSessionAndStart` arriva a `:1784` `self.start(resumeAtBeat:)`; a quel
punto `isRunning` e' gia' `false`, quindi la guardia di `:859` passa e `:874` azzera.**

⛔ **Non concludo se questo basti o no: e' l'enumerazione dei percorsi, come richiesto.**

---

## §3 · CENSIMENTO «COMMENTI-STALE» DI `BOX3_QBEATS.md:45`

**[M]** La lista vive su **una sola riga**, `BOX3_QBEATS.md:45 @ 4629ee9`, e nomina **7 siti**
in 5 voci. Nessuno e' stato toccato.
⛔ **I quattro riferimenti del §3.4 del congedo A166->A170 non sono qui: sono chiusi, li cito e basta**
(`LiveView.swift:354` · `AudioEngine.swift:764-765` · `AudioEngine.swift:2273` · `LiveView.swift:71`).

| # | sito nella lista | cosa dice il commento a HEAD (verbatim) | cosa c'e' davvero | esito |
|---|---|---|---|---|
| 1 | `SetlistRunner.swift` -> `AudioEngine.swift:503` | `SetlistRunner.swift:398`: `// audioEngine.start() ha guard '!isRunning' (AudioEngine.swift:503).` | a `AudioEngine.swift:503` c'e' `}` (graffa di chiusura); la guardia e' a **`:859`** | **SCADUTO** |
| 2 | `AudioEngine.swift:169` -> «~436-442» | `:169`: `// Emesso dal callback Link 'set_start_stop_callback' (righe ~436-442)` | `link_engine_set_start_stop_callback` e' a **`:524`** | **SCADUTO** |
| 3 | `LiveView.swift:378` -> «~436-442» | ⛔ a `:378` c'e' `// applicazione e non possono più divergere per costruzione.` — **non c'entra** | la citazione «~436-442» e' a **`LiveView.swift:432`** | **SCADUTO nel contenuto · ⚠️ il puntatore DI BOX3 e' esso stesso scaduto (378 -> 432)** |
| 4 | `AudioEngine.swift:616-618` deinit / Apple docs | `:618`: `// 2. engine.stop() — ferma render thread (blocking, sincrono per Apple docs)` | la frase e' **dentro** il tratto 616-618 dichiarato | **SCADUTO** (claim non sorgentato) · puntatore **VALIDO** |
| 5 | `HomeRootView` header -> `LiveView.swift:82` | `HomeRootView.swift:7`: `/// scaleFactor = geo.size.width / 390 (pattern Vista Live · LiveView.swift:82).` | a `:82` c'e' un commento; `let scaleFactor: CGFloat = geo.size.width / 390` e' a **`:87`** | **SCADUTO** |
| 6 | `LivePlaybackState.swift:16` -> «dismiss a Bivio» | `:16-17`: `// -> runner.startSetlist locale; (c) tap CANCEL -> dismiss UIHostingController` / `// a Bivio. CD-Q2=B ratificato libro mastro v14.` | la parola «Bivio» sta a **`:17`**, non `:16` (frase spezzata su due righe) | **SCADUTO nel contenuto · ⚠️ puntatore BOX3 fuori di 1** |
| 7 | `TransportView.swift:46` -> «dismiss a Bivio» | `:46`: `// (c) tap CANCEL -> dismiss a Bivio.` | esatto | **SCADUTO** · puntatore **VALIDO** |

**[M] Nessuno dei 7 siti e' NON PIU' ESISTENTE: tutti e 7 esistono a HEAD.**
**[M] Esito: 7 SCADUTI su 7 · 0 VALIDI · 0 NON PIU' ESISTENTI.**
**[M] Due puntatori della lista stessa hanno derivato** (n. 3 e n. 6).

### ⚠️ [M] La lista di BOX3 e' INCOMPLETA — due siti trovati dalla sweep per EFFETTO

**[M] Sonda:** `grep -rn --include='*.swift' -E 'LiveView\.swift:8[0-9]' ios_app/QBeats`
(cerca **chi cita quella riga**, non chi e' nella lista).

| sito | cita | a HEAD | esito |
|---|---|---|---|
| `SongListView.swift:6` | `LiveView.swift:82` | scaleFactor e' a `:87` | ⛔ **SCADUTO, NON in lista** |
| `QLiveShowDetailView.swift:99` | `LiveView.swift:87` | scaleFactor **e'** a `:87` | ✅ **VALIDO** |

**[M]** La sweep per effetto su «436-442» rende **2** hit: `AudioEngine.swift:169` (in lista)
e `LiveView.swift:432` (in lista con il numero sbagliato).
**[M]** La sweep per effetto su «Bivio» rende **3** hit: i due della lista piu'
`HomeRootView.swift:4` -> `/// Home (ex Bivio) — trivio top-level Q-STUDIO · Q-STAGE · Q-LIVE.`,
che **documenta la rinomina** e non e' un puntatore.

⛔ **Nessun commento e' stato toccato.**

---

## §4 · COSE CHE HO MISURATO E CHE NON ERANO CHIESTE

⚠️ **[M] `startCountIn(for:)` non fa count-in.** `AudioEngine.swift:1561-1563` verbatim:

```swift
    private func startCountIn(for section: String?) {
        start()
    }
```

Il parametro `section` non e' usato. **[M]** Sopra c'e' `// L3 stub — sostituito da Layer 3 quando disponibile.` (`:1560`).
**[M]** `resetToSongStart()` a `:1566` e' `{}` vuoto, stesso commento a `:1565`.

⚠️ **[M] Il cancello A del §1.1 e `.countIn` si toccano:** `LiveView.swift:302` scrive
`session.playbackState = .countIn(countdown: 4)`, e `BarCounterView.swift:15` rende `— / —`
su `.countIn`. **[M]** `resumeFromCurrentSection()` (`:1247`) mette `playbackState = .countIn`
a `:1251` **prima** di chiamare `startCountIn` a `:1253`.

⛔ **Non collego questi fatti fra loro e non ne traggo nulla: sono misure separate.**

---

## §5 · DIFETTI DEL MANDATO — uno solo, minore

**[A] Il mandato non contiene la risposta al posto della domanda.** §1 chiede la mappa e
lascia l'ipotesi al referee; l'ho potuta compilare senza sapere dove volesse arrivare.

⚠️ **[M] Una sola discordanza formale, dichiarata e non interpretata:** l'intestazione dice
**`MODELLO: Sonnet`**, ma questa sessione gira su **Opus 5**. Non posso cambiare modello da qui:
si sceglie dall'interfaccia. **[A] Ho eseguito lo stesso perche' il mandato e' di misura e
l'esito non dipende dal modello; se il referee vuole la misura rifatta su Sonnet, va rilanciata.**

---

## §6 · COSA NON HO FATTO

⛔ Nessun file sotto `ios_app/` toccato · nessun canonico modificato · nessun commit ·
nessun merge · nessuna build · nessun commento bonificato.
⛔ **Non ho riletto** HEAD, i cinque canonici, i non tracciati, i congedi, i quattro
riferimenti del §3.4: sono agli atti, come da mandato.
⛔ **Non ho letto il congedo del referee.**

---

### Controllo d'integrita' di QUESTO file — sul CONTENUTO

**Prima riga attesa:**
`# MISURE CC — A172 · GLI INGRESSI DEL CONTATORE DI BATTUTA`

**Stringhe obbligatorie — se una manca, il file e' arrivato mutilato:**
`baaa172895cfafba57b187356ed8ae1036eee17e` · `session.currentBar = ((relativeTick - 1) / bpb) + 1` ·
`guard !self.isRunning, let _ = self.metronomeHandle else` · `kSharedJoinMaxRearms` ·
`SCADUTO nel contenuto` · `7 SCADUTI su 7` · `L3 stub` · e il marcatore di fine qui sotto.

⚠️ **Contate le stringhe, non i titoli: un controllo che conta le sezioni non vede una sezione vuota.**

---

*A172-FINE — MISURE CC 22/08/2026 COMPLETO*
