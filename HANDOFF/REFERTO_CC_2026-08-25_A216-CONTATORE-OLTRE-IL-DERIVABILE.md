# REFERTO CC — A216 — IL CONTATORE OLTRE IL DERIVABILE: IL DRAIN NON È UNO STATO TERMINALE

Da: CC · A: referee + Mauro · 25/08/2026 · Mandato: A216 + AGGIUNTA che
sostituisce la Q6 (marcatore `AGGIUNTA-Q6-A216-REFEREE-2026-08-25-FINE`,
verificato presente; la Q6 di questo referto è quella SOSTITUITA).
**ESITO: MECCANISMO TROVATO E SORGENTATO — ed è una correzione a un mio errore
di A215, dichiarata in §9 come chiede R5.** Sola lettura rispettata: zero
modifiche, zero diff, zero commit, zero push.
Marcatura: **[M]** misurato alla fonte · **[R]** riportato · **[A]** giudizio mio.

**[M] HEAD a inizio mandato = HEAD a fine mandato =
`160b927575e1864908f8f8ca171e3be254ab48dc` · 0 tracciati modificati, 0 in stage.**
Ogni `file:riga` è ancorata a quello sha (R3). Prendo atto delle due
informazioni del mandato: **[R]** finale ▶ = stop manuale di Mauro (voce
ritirata, zero sonde spese) · **[R]** build CI #643 = questo stesso sha.

Faccia del file: UTF-8, LF, CR=0.

---

## 0 · CANCELLO ID — A216 LIBERO

Stesse sei sonde di A215 §0 (nome e contenuto, tracciati e non, due gambe):

| ID | nome: git / discoC / discoE | contenuto: git / handoffC / handoffE |
|---|---|---|
| A216 | 0 / 0 / 0 | 0 / 0 / 0 |
| A211 (positivo) | 2 / 2 / 2 | 4 / 7 / 6 |

*(I conteggi contenuto del positivo salgono di 1 rispetto ad A215 §0: ora
includono il referto A215 stesso, che cita A211. Coerente, non anomalo.)*

---

## 1 · LA RISPOSTA IN UNA PAGINA

**[M] In A215 ho scritto «poi i tick si fermano». È sbagliato, e l'errore è
mio: il DRAIN non è uno stato terminale — è un ciclo di UN giro, e l'arresto
vero non abita nel motore.** La catena, tutta a codice:

1. Al beat che esaurisce le ripetizioni, se non c'è una sezione preloadata,
   il ramo DRAIN **arma** `_sectionEndPending = true`, salva la closure in
   `_pendingEndClosure` e azzera `_sectionBeatCounter`
   (`AudioEngine.swift:2623-2625`). ⚠️ `_sectionTotalBeats` e `_onSectionEnd`
   **restano registrati** — è dichiarato: «la sezione caricata persiste tra
   play/replay» (:2616-2620).
2. Nei giri successivi il flag fa saltare `metronome_processBuffer`
   (`beatCount = 0`, :2327-2331): niente beat nuovi, i playhead del click
   residuo drenano — **ma ogni giro schedula comunque il proprio buffer**
   (:2647-2649): il return anticipato NON è qui.
3. Quando i playhead sono esauriti scatta il drain-complete (:2214-2244):
   **il drain-complete azzera il flag che lo aveva armato**
   (`self._sectionEndPending = false`, **:2221**), dispatcha la closure su
   main (:2239-2241) e ritorna UNA volta senza schedulare (:2244).
4. Da qui il codice DELEGA l'arresto alla closure dispatchata: «È il callsite
   a decidere» (commento TD #16, :2233-2238). I soli stop del percorso
   end-of-section sono nella closure del runner — ramo standby
   (`SetlistRunner.swift:404`) e ramo fineSetlist (:412). **Nel test la
   closure apparteneva al runner sostituito da `install`: il suo guard
   `[weak self, weak audioEngine, weak session]` (:321-322) fallisce e
   ritorna senza effetti. fermare il motore era compito della closure morta.**
5. Intanto i buffer ancora in coda al playerNode consegnano i loro
   completion, e ognuno chiama `scheduleNextBuffer` (:2647-2649). Il flag ora
   è FALSE e `isRunning` è ancora true (nessuno ha fermato): il guard :2200
   passa, `metronome_processBuffer` RIPRENDE a generare beat, i tick
   ripartono, `_sectionBeatCounter` riconta 1..6 sul `_sectionTotalBeats`
   persistente → al 6° beat, DRAIN di nuovo → **sei beat per giro, e il giro ricomincia.**

⇒ **[M] Con una closure che non ferma, la sezione finale suona in cicli:
6 beat veri + una micro-pausa di drain, all'infinito, finché uno stop esterno
non arriva.** È esattamente ciò che il video mostra: battiti VERI a 140 in
3/4 per ~5 s oltre le due ripetizioni, chiusi solo dallo stop manuale [R].

**[M] E la sopravvivenza della coda non è una mia congettura: il codice
documenta entrambi gli esiti della coda.** La doc di `kickScheduling`
(:1199-1206): «Le sezioni lunghe … lasciano la coda vuota dopo il drain, e la
catena di completion handler si esaurisce naturalmente. **Sezioni brevi
sopravvivono per buffer residui** … Questo metodo ripristina 3 buffer in coda
incondizionatamente, eliminando la dipendenza dalla fortuna.» E lo
steady-state dichiarato è «~2 buffer in coda» (:2451-2454). Bridge è una
sezione da 6 beat (~2,6 s): il caso «breve» per definizione — e in più i
giri di drain del punto 2 rialimentano la coda fino all'ultimo.
⇒ **la coda dei buffer sopravvive al singolo return** del punto 3.

---

## 2 · Q1 — su cosa poggiava «i tick si fermano», e cosa non avevo misurato

**[M] Il meccanismo che AVEVO misurato (e regge):** flag `_sectionEndPending`
armato dal ramo DRAIN (:2624) ⇒ `beatCount = 0` (:2327-2331) ⇒ zero emissioni
di `beatTickSubject` (l'unico emit è :2377-2381, dentro `if isBeat` dentro
`if beatCount > 0`). Esecutore: `scheduleNextBuffer` su `audioQueue`.
Condizione d'armamento: `_sectionTotalBeats > 0 && _sectionBeatCounter >=
_sectionTotalBeats && _pendingNextSectionTotalBeats == nil` (:2499-2505, :2610).

**[M] Cosa NON avevo misurato, ed è il buco:** la riga **:2221** — il
drain-complete rimette il flag a false PRIMA di dispatchare la closure. Da
quel momento la fermata dei beat non ha più un custode dentro il motore:
o la closure ferma (`stop()` → `stopSync` → `isRunning=false` → il guard
:2200 uccide ogni giro successivo), o i completion residui fanno ripartire
la generazione. In A215 ho dato per scontato il primo esito senza sorgente.

---

## 3 · Q2 — l'aritmetica rifatta passo passo, e la premessa che cade

**[M] Passi (fixture confermata: Bridge = 2 rip × 3 beat = 6 beat; bpb
display flippa a 3 sul primo tick di Bridge, `LiveView.swift:373-379`):**

| passo | tick relativo | perché |
|---|---|---|
| ancora | 1 | consegna iniziale di `runner.$currentSectionIdx` arma `pendingSectionStart` (LV:404); il primo tick post-montaggio fa `sectionStartTick = tickN` (LV:368) ⇒ `relativeTick = 1`, Bar 1 |
| «Bar 1 of 3» dura ~2 s | 1-4 | Bar 1 = 4 tick a bpb 4; 4 beat a 120 BPM = 2,0 s — combacia col fotogramma |
| confine Verse→Bridge | 5 | primo beat di Bridge; verifica indipendente: `((5-1)/3)+1 = 2` ⇒ il fotogramma dice esattamente `Bar 2 of 2` |
| giro 1 di Bridge | 5-10 | 6 beat; Bar ai tick: 2·2·3·3·3·**4** — Bar 4 compare al tick 10, l'ultimo beat dichiarato |
| **fine di A215** | — | qui A215 fermava il mondo: «massimo Bar 4 of 2» |
| giro 2 (ripresa) | 11-16 | Bar 4·4·**5**·5·5·**6** — Bar 5 al tick 13, Bar 6 al 16 |
| giro 3 | 17-22 | Bar 6·6·**7**·7·7·8 — Bar 7 al tick 19; lo stop manuale arriva ~34 s, durante questo giro |

**[M] Riscontro sui tempi del referee:** un tick a 140 = 0,4286 s; una battuta
in 3/4 = 1,286 s; ogni giro aggiunge una micro-pausa di drain (~1-3 buffer da
512 campioni ≈ 10,7 ms l'uno a 48 kHz — `AudioEngine.swift:266` — più il
giro non schedulato). Periodo atteso ≈ 1,29-1,33 s per battuta ⇒ la media
misurata di ~1,33 s è compatibile; con granularità 0,5 s non distinguo oltre,
e la quota esatta del gap vive nel DSP C++ che non ho misurato (R4).
Beat totali di Bridge fino allo stop: ~17 ≈ 5-6 ripetizioni invece di 2 ≈
i «circa 5 secondi oltre» del referee.

**La premessa di A215 che deve cadere — ed è caduta:** «al 6° beat il DRAIN
ferma i tick, e fermi restano». Vera solo per i giri col flag armato; il
flag viene azzerato dal drain-complete stesso (:2221) e l'arresto è delegato
a una closure che nel test era morta. Con la premessa corretta il «massimo»
non esiste: Bar cresce di ~1 ogni ~1,3 s finché qualcuno ferma.

---

## 4 · Q3 — a ripetizioni esaurite: ogni comportamento del motore che NON è l'arresto

**[M] Il punto di decisione è UNO SOLO** (`:2499-2501`: `if _sectionTotalBeats
> 0 { _sectionBeatCounter += 1; if >= … }`) **con DUE rami** (:2505 / :2610)
più il non-ingresso. Enumerazione completa:

1. **SEAMLESS** (:2505-2608) — `_pendingNext*` armati: swap atomico alla
   sezione preloadata, beat continuano. Nessun arresto.
2. **DRAIN + ripresa spontanea** (:2610-2626 → :2214-2244 → :2647-2649) — il
   ciclo di §1: il motore NON si arresta; dispatcha la closure e, se la coda
   sopravvive, riprende. L'arresto avviene SOLO se la closure (o un agente
   esterno) chiama `stop()`.
3. **Fine mai rilevata** — `_sectionTotalBeats <= 0`: il check non entra
   proprio; beat senza limite. Vie: `loadSection` con `repetitions <= 0`
   (:1149-1157, documentato «loop infinito esplicito -1 o reset 0»,
   :1140-1141) oppure `preloadNextSection` con reps ≤ 0 — che, a differenza
   di `loadSection`, **non ha la guardia sul segno**: moltiplica e basta
   (`_pendingNextSectionTotalBeats = repetitions * Int(beatsPerBar)`, :1189)
   e allo swap il prodotto ≤ 0 entra in `_sectionTotalBeats` (:2538).

**L'«arresto autonomo del motore a fine ripetizioni» NON esiste: zero arresti autonomi a fine ripetizioni.**
Controllo positivo nella stessa forma dell'enumerazione: gli `audioEngine.stop()`
del percorso end-of-section sono esattamente i due della closure del runner —
sonda `grep -n 'audioEngine.stop()' ios_app/QBeats/SetlistRunner.swift` →
3 match: :401 (commento), **:404** (standby), **:412** (fineSetlist).

---

## 5 · Q4 — percorsi in cui il motore emette beat oltre le ripetizioni SENZA avanzamento del runner

**[M] Tre, enumerati; nessun quarto trovato:**

| # | percorso | fonte | nel test? |
|---|---|---|---|
| (a) | **Drain-loop**: closure end-of-section il cui guard fallisce (runner sostituito da `install`, o session morta — il guard :321-322 è congiunto su tutti e tre i weak) ⇒ ciclo di §1 | :2221 + :2647-2649 + :1199-1206 | **SÌ — è l'osservato**: unica via compatibile con la fixture (tutte le reps > 0, confermate dal referee) |
| (b) | `preloadNextSection` di una sezione con `repetitions <= 0`: nessuna guardia sul segno (:1189) ⇒ allo swap `_sectionTotalBeats <= 0` ⇒ fine mai rilevata, nemmeno il drain | :1189, :2499, :2538 | no (Bridge = 2) |
| (c) | `loadSection` con `repetitions <= 0`: nessun limite, closure non registrata — loop infinito esplicito, by design | :1149-1157 | no |

*(Caso contiguo, NON «oltre le ripetizioni»: closure VIVA che esegue dopo uno
stop — il tech-debt OSS2 già annotato in casa, :2600-2605. Non emette beat
extra: lo cito solo per perimetrare.)*

---

## 6 · Q5 — repetitions: valori ammessi e ogni lettore che decide la fine

**[M] Il campo:** `SongSection.repetitions: Int` — commento del modello:
«-1 = loop infinito (sentinel, non genericamente < 0)»
(`Models/SongSection.swift:9`). La UI lo vincola: Stepper **1...64**
(`SectionEditorView.swift:150`) oppure toggle che scrive **-1** ⇄ 1
(:236-240, `get: repetitions < 0`, `set: -1 o 1`). La decodifica da JSON è un
`Int` libero (:47): il range 1...64 è un vincolo di UI, non di modello.

**[M] Ogni sito che lo LEGGE per decidere quando una sezione finisce, e il
comportamento per valore:**

| sito | > 0 | 0 | -1 (o altro ≤ 0) |
|---|---|---|---|
| `loadSection` (:1149-1157) | `_sectionTotalBeats = reps × bpb`, closure registrata, fine al raggiungimento | nessun limite, closure NON registrata | idem 0 — infinito esplicito |
| `preloadNextSection` (:1189) → swap (:2538) | prodotto > 0: fine normale | prodotto 0 → check `> 0` mai vero → **fine mai rilevata** | prodotto negativo → idem — infinito NON dichiarato |
| check di fine (:2499-2501) | conta e chiude al `>=` | non entra | non entra |

Per il display (non decidono la fine, la MOSTRANO): `currentSectionRepetitions`
pubblicato da `loadSection` (:1159-1161) e dallo swap (:2597);
`BarCounterView.swift:20-30`: `-1 → ∞`, `> 0 → numero`, `0 → trattino`;
`primeDisplay` scrive `Int(section.repetitions)` in `totalBarsInSection`
(`SetlistRunner.swift:283`); `SongSection.duration` (:72-73) rende 0 per
reps ≤ 0.

---

## 7 · Q6 (SOSTITUITA dall'aggiunta) — stati di ripetizione, rilancio o prolungamento

### 7a · Gli stati che il motore legge al punto di decisione — censimento completo

**[M]** Il motore decide «fermo o proseguo» in DUE punti soli: il check di
fine sezione (:2499-2505/:2610) e il drain-complete (:2214). Gli stati letti
lì, TUTTI privati di `AudioEngine`, con OGNI scrittore (sonda:
`grep -nE '<nome>[[:space:]]*=' ios_app/QBeats/AudioEngine.swift`, una per
stato; dichiarazioni a :273, :288-290, :298-299, :309-310):

| stato (dove vive: AudioEngine) | default e da dove viene | scrittori | rimontaggio player | `install` |
|---|---|---|---|---|
| `_sectionTotalBeats` (:288) | **0** dalla dichiarazione = «nessun limite / nessuna sezione» (:286) | `loadSection` :1150 (reps×bpb) e :1154 (0) · swap SEAMLESS :2538 | **sopravvive** | **sopravvive** |
| `_sectionBeatCounter` (:289) | 0 dalla dichiarazione | incremento :2500 · azzeri: `start` :882 · `stopSync` :1660 · `loadSection` :1151/:1155 · swap :2539 · drain-arm :2625 · seed Follower ramo SHARED :805 (=offset) / :808 (=0) — non attraversato in standalone | **sopravvive** | **sopravvive** |
| `_pendingNext*` (famiglia, :309-310 e sorelle) | **nil** dalle dichiarazioni = «nessuna prossima» | `preloadNextSection` :1186-1195 · reset allo swap :2524-2531 · reset in `stopSync` :1693-1700 | **sopravvivono** | **sopravvivono** |
| `_sectionEndPending` (:298) | false dalla dichiarazione | drain-arm :2624 (true) · drain-complete :2221 (false) · `stopSync` :1705 (false) | **sopravvive** | **sopravvive** |
| `_onSectionEnd` / `_pendingEndClosure` (:290/:299) | nil dalle dichiarazioni | `loadSection` :1152/:1156 · swap :2540 · drain-arm :2623 · drain-complete :2223 · `stopSync` :1706 | **sopravvivono** (la closure resta registrata) | **sopravvive la REGISTRAZIONE, muore il BERSAGLIO**: `install` non tocca questi campi (`QLiveSession.swift:69-71` scrive solo lo slot) ma uccide il runner che la closure cattura weak ⇒ closure registrata e inerte |
| `isRunning` (:273) | false dalla dichiarazione | `start` :890 (true) · `stopSync` :1643 · `handleInterruption` :2691 · `handleRouteChange` :2908 · `handleEngineConfigChange` :3024 (false) | **sopravvive** | **sopravvive** |

⚠️ **[M] La colonna «sopravvivenza» vale in blocco per una ragione sola:** il
rimontaggio del player non contiene NESSUNA chiamata al motore che scriva
questi campi (misura A215: `install` scrive solo lo slot; `primeDisplay` non
tocca AudioEngine; l'`onAppear` di LiveView legge soltanto), e `install`
idem. Chi li azzera davvero sono `start()`/`stopSync()` — cioè il transport —
e gli handler di sistema.

### 7b · Uno stato di ripetizione/rilancio AZIONABILE: ZERO

**[M]** Nessuno degli stati sopra è «ripeti»: sono limite, conteggio,
prossima-sezione, drenaggio, closure, acceso/spento. Uno stato che DICA
ripetizione esiste in due sole forme, nessuna delle quali è runtime del
motore: **(1)** `repetitions = -1` nel MODELLO DATI (§6 — sentinel
dichiarato, `Models/SongSection.swift:9`), che il motore riceve già
moltiplicato; **(2)** il caso enum `.loopActive`
(`Models/LivePlaybackState.swift:8`): **2 occorrenze totali nel corpus** — la
dichiarazione e un commento (`SetlistRunner.swift:301`) — zero scrittori,
zero letture. Positivo, stessa forma: `fineSetlist` → 15. Sonda aggiuntiva
per effetto: `grep -niE '(repeat|replay|relaunch|loopEnabled|isLooping|loopMode)'
ios_app/QBeats/AudioEngine.swift` → solo commenti e `Array(repeating:)`,
nessuno stato; positivo `subdivision` → 22.
⇒ **Il «prolungamento» osservato non è uno stato: è il ciclo emergente di §1.**

### 7c · La pulsantiera, verificata comando per comando — e dove il ricordo va precisato

**[R]** Mauro: «vivi solo STOP e PLAY, slide apre il mixer, il resto inerte».
**[M] Misura su `TransportView.swift` (già letto integrale in A215):**

| comando | cablaggio | verdetto |
|---|---|---|
| ◀ prev sez (:26-28) | `audioEngine.prevSection()` = `{}` (:1271) | **inerte** ✓ |
| ▶/■ play-stop (:30-67) | `stop()` · `.waitingForDirector` · `runner.startSetlist` | **vivo** ✓ |
| ▶▶ next sez (:69-71) | `audioEngine.nextSection()` = `{}` (:1272) | **inerte** ✓ |
| ↺ loop (:75-77) | `audioEngine.toggleLoop()` = `{}` (:1273) — **toggleLoop e una funzione vuota**; la label è placeholder (:114-117), nessun aspetto «attivo» possibile | **inerte** ✓ — e non può essere causa dei beat extra; nemmeno via MIDI (`.loopToggle` → solo os_log, :1622-1624) |
| ⚠ emerg (:93-95) | closure vuota (`/* navigazione Vista LISTA — Fase successiva */`) | **inerte** ✓ (ticket già a ruolino) |
| **KILL BASE** (:79-91) | `audioEngine.stopBacktrack()` — **REALE**: ferma `backtrackPlayerNode` (:1526-1533) + flash visivo `killFlashing` | ⚠️ **QUI il ricordo va PRECISATO: non è inerte a codice.** È cablato a una funzione vera. Senza una base in riproduzione l'effetto udibile è nullo, e NON tocca il metronomo in nessun caso (nodo separato) — quindi ai fini di QUESTO guasto è irrilevante. Ma «tutti gli altri sono inerti» non è esatto: 4 su 6 lo sono, KILL BASE no. |
| capsula + drag (:98-111) | `session.showMixer = true` | **vivo** ✓ (lo «slide verso l'alto») |

⇒ **[M]** Nessun comando della pulsantiera — vivo o inerte — scrive alcuno
degli stati di 7a se non attraverso `stop()`/`start()` del tasto centrale.
La conclusione dell'aggiunta regge anche misurata: da quella pulsantiera non
si può armare nessuna ripetizione.

---

## 8 · Q7 — la strumentazione: per QUESTO bersaglio non serve nemmeno

**[M] I log per decidere esistono già a HEAD, e firmano il ciclo:**

- `[Q-BEATS][L1.a] fine ultima ripetizione — beat:%d/%d → drain mode` (:2612-2614)
- `[Q-BEATS][DRAIN] entered — bufCount:%d beatTick:%d` (:2218-2220)
- `[Q-BEATS][L1bSync] drain completato → onSectionEnd dispatch …` (:2230-2232)
- `[Q-BEATS][DRAIN] return — no buffer scheduled …` (:2242-2243)

**[A] Il verdetto su device, senza scrivere una riga:** si replica il test con
cattura log (procedura `idevicesyslog` già agli atti in casa). Firma del
drain-loop: il QUARTETTO di messaggi qui sopra che si RIPETE ogni ~2,6 s, con
`beatTick` crescente fra un giro e l'altro, mentre il click continua. Firma
dell'esito alternativo (catena morta, lo «stallo» che A215 dava per certo):
UN SOLO quartetto, poi silenzio nei log e click fermo. Una sola cattura
distingue le due firme.

La strumentazione descritta in A215-Q8 (os_log one-shot all'onAppear + al
primo tick post-montaggio) resta utile per l'ISTANTE DI MONTAGGIO — altra
domanda, non questa — e non va cambiata: va semmai affiancata dalla cattura
di cui sopra, che non richiede alcuna modifica.

---

## 9 · R5 — LE MIE CORREZIONI AD A215, apertamente

**[M] Tre affermazioni del mio referto A215 cadono, e le correggo qui —
tre affermazioni di A215 cadono, il resto regge:**

1. **«poi i tick si fermano»** (A215 §12.1) — FALSA come assoluto: vera solo
   nei giri col flag armato. Il drain-complete azzera il flag (:2221) e non
   ferma il motore.
2. **«il codice prevede l'esito OPPOSTO: motore in stallo silenzioso che
   dichiara .playing per sempre»** (A215 §12.2) — FALSA nel caso osservato:
   lo stallo è UNO dei due esiti che il codice documenta (:1199-1206), e
   quello reale — coda sopravvissuta — è un LOOP UDIBILE della sezione, non
   uno stallo. Ho scelto un esito senza averlo misurato.
3. **«massimo Bar 4 of 2»** (A215 §12.1) — vera SOLO sotto la premessa 1.
   Caduta quella, il massimo non esiste: cresce ~1 battuta ogni ~1,3 s fino
   a uno stop esterno.

**[M] Cosa di A215 REGGE integralmente:** i censimenti (Q1-Q7), le quattro
vie del display, la fixture (confermata dal referee per via indipendente),
e le risposte D1-D7 — nessuna delle quali poggiava sull'esito post-drain.

**[A] La lezione, per me prima che per gli altri:** avevo il commento di
`kickScheduling` sotto gli occhi — documenta ENTRAMBI gli esiti — e ho
scritto in referto solo quello che completava la mia catena. Un esito non
misurato non si sceglie: si dichiara doppio, come fa quel commento.

---

## 10 · IPOTESI — la sola parte non dimostrabile dal codice fermo

**[A]** Che nel video sia avvenuto proprio il drain-loop (esito «coda
sopravvissuta») e non lo stallo non è decidibile staticamente: il numero di
buffer in coda in quell'istante è stato runtime (R4). Lo selezionano le
osservazioni: battiti con periodo da battuta 3/4 a 140 (+micro-gap), per ~5 s
oltre le ripetizioni, striscia viva fino allo stop manuale — tutte e tre
incompatibili con lo stallo e previste dal ciclo di §1. La cattura log di §8
lo renderebbe un fatto.

**[A]** Per l'atomo che verrà, il perimetro resta quello di A215 §12 più
questo: il caso «closure end-of-section senza vivi» oggi non ha un
comportamento DEFINITO — ha un comportamento EMERGENTE (loop o stallo,
deciso dalla coda). ⛔ Nessuna proposta di riparazione: materia di
⟦S-EXIT⟧/decisore.

---

## R-δ — deposito

`HANDOFF/REFERTO_CC_2026-08-25_A216-CONTATORE-OLTRE-IL-DERIVABILE.md` sul
repo C: e copia identica nella `HANDOFF/` del mirror E:
(`FILE X CLAUDE.MD/HANDOFF/`). Verifica `cmp` + `sha256sum` nel messaggio di
consegna. ⛔ Niente Drive: ci arriva da solo.

### Controllo d'integrità di QUESTO file — sul contenuto, testo appiattito

⚠️ Stringhe da una riga sola, senza accenti né apostrofi; contarle sul testo
appiattito. Attese 2 occorrenze ciascuna (corpo + questa lista); il marcatore
di fine 1, in ultima riga (questa lista lo nomina senza citarlo).

`160b927575e1864908f8f8ca171e3be254ab48dc` ·
`il drain-complete azzera il flag che lo aveva armato` ·
`la coda dei buffer sopravvive al singolo return` ·
`fermare il motore era compito della closure morta` ·
`toggleLoop e una funzione vuota` ·
`sei beat per giro, e il giro ricomincia` ·
`il codice documenta entrambi gli esiti della coda` ·
`zero arresti autonomi a fine ripetizioni` ·
`tre affermazioni di A215 cadono, il resto regge` ·
e il marcatore di fine qui sotto.

---

MANDATO-A216-CONTATORE-OLTRE-IL-DERIVABILE-FINE
