# MISURE CC — A263 — CONTO DEI TOCCHI E PORTE DELLA LISTA

Da: CC · A: referee. Sola lettura. Nessuna modifica sotto `ios_app/`.

Marcatura: **[M]** misurato ora a fonte · **[R]** riportato/citato da altri · **[A]** giudizio. Il mandato vieta conclusioni: **[A]** compare solo per segnalare un'ambiguità nella fonte, mai per dire quale mondo sia migliore.

---

## §0 — ID e HEAD

**[M]** ID **A263** verificato su due supporti (nome file + contenuto, grep ricorsivo su tutto il repo, `.git` escluso): **zero occorrenze su entrambi**, prima di questo deposito. Controllo positivo nella stessa forma su un ID noto-usato, **A261**: trovato su entrambi i supporti (`HANDOFF/MISURE_CC_2026-08-29_A261-LA-TESTATA-CHE-MENTE.md` + 3 file di contenuto) — la sonda vede, lo zero su A263 non è cieco.

**[M]** `HEAD = origin/master = b1b4c1fd0864b1713eec7cda5a4d142fac431339`. Orologio alla scrittura: domenica 30/08/2026, 11:15 locale — coincide con la data dichiarata, nessun cartello necessario stavolta.

⛔ **A262 dichiarato annullato dal referee** (premessa falsa in sezione 3, mai vista da me: A262 non compare in questa sessione). Non lo eseguo né lo riuso: il mandato non mi chiede di verificarlo, solo di dichiarare se l'ho già eseguito. Non l'ho eseguito.

---

## §1 — Il conto dei tocchi — otto conti

### Premessa dichiarata sull'interpretazione di «arrivare al comando»

Il mandato non scioglie un'ambiguità e la dichiaro invece di scioglierla da solo: per **(i)** «arrivare» è chiaramente uno stato (le canzoni sono leggibili, nessun tocco ulteriore necessario). Per **(ii)** «il comando che chiude lo show» nomina un controllo, non un luogo. Ho contato **fino al tocco che invoca il comando incluso** (l'ultima riga dell'elenco È quel tocco), perché «il comando» è un'azione, non uno schermo. Se il referee intendeva invece «fino a quando il comando è disponibile a schermo, tocco escluso», si toglie l'ultima riga da ognuno dei quattro conti-(ii): sono segnalati singolarmente sotto.

---

### CONTO 1 — (A) WaitingForDirector → (i) scaletta · COSTRUITO

1. **CANCEL** (testo a schermo) · simbolo: `Button { onExit() }`, [WaitingForDirectorView.swift:75-84](ios_app/QBeats/UI/Live/WaitingForDirectorView.swift:76) · atterra su: `onExit()` → catena fino a `QLiveRootView.leavePlayer()` ([QLiveRootView.swift:145-150](ios_app/QBeats/UI/QLive/QLiveRootView.swift:145)) — il guard `if case .fineSetlist` non scatta (stato è `.waitingForDirector`) ⇒ solo `navigate(to: .shows)` · schermata dopo: **QLiveShowsView** (Shows list)
2. **riga show** (testo dinamico = nome dello show, es. "Milano Assago 20 Jul") · simbolo: `showCard(_:)`, `.onTapGesture { onSelectShow(show) }`, [QLiveShowsView.swift:280-319](ios_app/QBeats/UI/QLive/QLiveShowsView.swift:319) · atterra su: closure `onSelectShow` passata da `QLiveRootView` — `selectedSetlist = show; navigate(to: .detail)` ([QLiveRootView.swift:178-181](ios_app/QBeats/UI/QLive/QLiveRootView.swift:179)) · schermata dopo: **QLiveShowDetailView**, `songList` già nel `body` ([QLiveShowDetailView.swift:180](ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:180)) — canzoni leggibili senza altro tocco

**Conto = 2.**

---

### CONTO 2 — (A) WaitingForDirector → (i) scaletta · RATIFICATO (rev2 27/08)

1. **freccia** (nessun testo, icona chevron in `.plhead .hit`) · simbolo: selettore `.plhead .hit` svg, frame `data-screen-label="01 — attesa vestita, velo corto, freccia al dettaglio"`, `2026-08-27_..._rev2-FRECCIA-AL-DETTAGLIO-SPIA...html` · atterra su: nessuna funzione (documento di disegno, **non costruito**) — regola dichiarata pannello ④: *«la freccia porta dove sta lo show. Player che gira → dettaglio... l'attesa gira, quindi va al dettaglio»* · schermata dopo: **frame `data-screen-label="02 — dettaglio in sessione, show che suona, spia PLAYING"`**, songlist già presente

**Conto = 1.**

⚠️ **Nota misurata, non giudizio:** il mockup del frame ① mostra `.nextlbl` "Next:" + `.nextname` "Roxanne" + `.taphint` "Tap anywhere to start" + `.cin` "Count-in · 2 bars" (righe 217-220 del file html). Questo testo **non corrisponde** alla copy reale di `WaitingForDirectorView` a COSTRUITO (`"WAITING FOR DIRECTOR…"`, bottoni `START LOCAL`/`CANCEL`, nessun "Next:", nessun "Tap anywhere" — [WaitingForDirectorView.swift:50-83](ios_app/QBeats/UI/Live/WaitingForDirectorView.swift:50)); corrisponde invece, testualmente, alla copy di `StandbyOverlayView` (nome canzone pulsante, tap-ovunque — [StandbyOverlayView.swift:19-46](ios_app/QBeats/UI/Live/StandbyOverlayView.swift:19), pur senza le etichette "Next:"/"Tap anywhere"/"Count-in", che in `StandbyOverlayView` non esistono a schermo). ⇒ **Applicare la regola della freccia allo stato (A) come lo definisce il mandato (`WaitingForDirectorView`) è un'estensione della lettera del disegno rev2, non una sua citazione diretta**: il disegno etichetta la schermata "ATTESA" ma la disegna con la copy dello stato Standby. Il Conto 2 sopra applica comunque la regola allo stato (A), perché il mandato lo chiede esplicitamente; la discrepanza testuale resta dichiarata qui.

---

### CONTO 3 — (A) WaitingForDirector → (ii) END SHOW · COSTRUITO

1. **CANCEL** · stesso simbolo del Conto 1, riga 1 · stesso atterraggio · schermata dopo: **QLiveShowsView**
2. **riga show** (stesso show: il runner non è stato smontato — `leavePlayer()` non chiama `endShow` in questo ramo) · stesso simbolo del Conto 1, riga 2 · atterra su: `navigate(to: .detail)` con `isShowLive: roomSession.runner != nil` → **true** ([QLiveRootView.swift:198](ios_app/QBeats/UI/QLive/QLiveRootView.swift:198)) · schermata dopo: **QLiveShowDetailView**, `isShowLive == true` ⇒ `endShowRow` visibile ([QLiveShowDetailView.swift:489-492](ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:490))
3. **END SHOW** (testo a schermo) · simbolo: `Button(action: onEndShow)`, [QLiveShowDetailView.swift:556-602](ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:562), testo "END SHOW" a [:569](ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:569) · atterra su: `onEndShow` → `QLiveRootView.endShowAndLeave()` ([QLiveRootView.swift:170-173](ios_app/QBeats/UI/QLive/QLiveRootView.swift:170)) — chiama `roomSession.endShow(audioEngine:)` poi `navigate(to: .shows)` · schermata dopo: **QLiveShowsView**

**Conto = 3.** (Se si esclude il tocco-comando per l'interpretazione alternativa dichiarata in premessa: **2**.)

---

### CONTO 4 — (A) WaitingForDirector → (ii) END SHOW · RATIFICATO (rev2 27/08)

1. **freccia** · stesso simbolo del Conto 2 · schermata dopo: **frame "02 — dettaglio in sessione, show che suona, spia PLAYING"**, `.vstack` con `Stop`/`Restart song`/`Return` già presente
2. **Stop** (testo a schermo, unico controllo del `.vstack` che porta il nome più vicino a "chiude lo show" — vedi nota sotto) · simbolo: selettore `.vrow.stop`, stesso frame · atterra su: nessuna funzione (non costruito) — pannello ④ dichiara: *«la conferma resta armata solo dove la sessione muore — cioè su STOP nel dettaglio»* · schermata dopo: **non specificata in questo foglio** — pannello ④ rimanda la forma dell'alert a un altro documento ("la domanda ④ del rev1... esce da questo foglio e resta viva là")

**Conto = 2** fino al tocco su Stop incluso. **Oltre questo punto il disegno rev2 stesso dichiara di non specificare**: non invento un terzo tocco per una conferma di cui rev2 non porta la forma.

⚠️ **Nota misurata sul nome del comando:** in rev2 il controllo che chiude lo show **non si chiama "END SHOW"**: si chiama **"Stop"**, e il nome vero resta esplicitamente indeciso — pannello ⑧, voce ③: *«Il nome della voce che chiude lo show — la tua D6, che resta rimandata. Qui compare come STOP nella lamella (25/08)»*. Il codice COSTRUITO (`endShowRow`, "END SHOW") cita come fonte "fogli CD 27/08 §② e 29/08 §B" — **non questo documento** (rev2 "Attesa e Dettaglio"), che è un foglio diverso della stessa giornata. Misurato, non risolto: quale dei due fogli del 27/08 sia "il" mondo RATIFICATO per END SHOW non è nel perimetro di questo mandato, che nomina specificamente rev2.

---

### CONTO 5 — (B) Stopped → (i) scaletta · COSTRUITO

1. **back chevron** (nessun testo, icona SF Symbol `chevron.left`) · simbolo: `Button { onExit() }`, [LiveHeaderView.swift:30-44](ios_app/QBeats/UI/Live/LiveHeaderView.swift:30) · atterra su: `onExit` iniettato da `QLiveRootView` sul gate `.metronome` — `LiveView(onExit: { leavePlayer() }, ...)` ([QLiveRootView.swift:324](ios_app/QBeats/UI/QLive/QLiveRootView.swift:324)) → `leavePlayer()`: guard `.fineSetlist` non scatta (stato è `.stopped`) ⇒ solo `navigate(to: .shows)` · schermata dopo: **QLiveShowsView**
2. **riga show** · stesso simbolo del Conto 1, riga 2 · stesso atterraggio · schermata dopo: **QLiveShowDetailView**, songlist visibile

**Conto = 2.** Identico al Conto 1: `.stopped` e `.waitingForDirector` condividono lo stesso, unico canale d'uscita in COSTRUITO (`onExit` → `leavePlayer()`), verificato che **nessun controllo di `TransportView`** naviga altrove — i sei bottoni (`prev sez`, `play/stop`, `next sez`, `loop`, `kill base`, `emerg`) sono tutti transport o no-op: `emerg` in particolare è un commento vuoto, `/* navigazione Vista LISTA — Fase successiva */` ([TransportView.swift:115-117](ios_app/QBeats/UI/Live/TransportView.swift:117)) — **non costruito**, citato perché è l'unico controllo il cui stesso commento dichiara un'intenzione di navigazione mai realizzata.

---

### CONTO 6 — (B) Stopped → (i) scaletta · RATIFICATO (rev2 27/08)

🚨 **Qui il disegno rev2 si contraddice, e le due letture danno conti diversi. Le presento entrambe, senza sceglierne una.**

**Lettura 1 — "Player fermo → card" preso alla lettera** (pannello ④: *«Player che gira → dettaglio. Player fermo → card.»* — e `.stopped` = "fermo" per nome):

1. **freccia** · selettore `.plhead .hit`, stesso file · atterra su: nessuna funzione (non costruito) — regola del pannello ④ · schermata dopo: **"card"** — la lista Shows, dichiarata esplicitamente **fuori perimetro** da questo foglio ("FUORI PERIMETRO, non toccato: ... card della lista"), quindi identica a `QLiveShowsView` COSTRUITO
2. **riga show** · simbolo COSTRUITO invariato (`showCard`, [QLiveShowsView.swift:319](ios_app/QBeats/UI/QLive/QLiveShowsView.swift:319)), perché rev2 non ridisegna questa schermata · atterra su: `onSelectShow` · schermata dopo: **QLiveShowDetailView** — variante **non specificata univocamente** da rev2 per questo caso preciso (show ancora installato ma player fermo): vedi Lettura 2

**Conto Lettura 1 = 2.**

**Lettura 2 — "con la sessione viva non sei nella lista" preso alla lettera** (pannello ⑥: *«Con il perimetro chiuso quella strada non esiste più (con la sessione viva NON SEI NELLA LISTA)»*):

Se una sessione viva (`runner != nil`, vero in questo stato: `.stopped` non smonta il runner) rende la lista **irraggiungibile per navigazione** a prescindere dal fatto che il Player "giri" o sia "fermo", allora la freccia da `.stopped` porterebbe **anch'essa** al DETTAGLIO, non alle card:

1. **freccia** · stesso simbolo · schermata dopo: **frame "02/03 — dettaglio in sessione"**, songlist già presente

**Conto Lettura 2 = 1.**

⚠️ Le due letture derivano dalla **stessa pagina dello stesso documento**, e non ho trovato in rev2 una terza frase che le concili. Non sciolgo l'ambiguità: la incido qui perché il conto per (B) dipende interamente da quale lettura vince.

---

### CONTO 7 — (B) Stopped → (ii) END SHOW · COSTRUITO

1. **back chevron** · stesso simbolo del Conto 5, riga 1 · schermata dopo: **QLiveShowsView**
2. **riga show** · stesso simbolo · atterra su: `navigate(to: .detail)` con `isShowLive == true` (il runner non è stato smontato da un semplice `.stopped`) · schermata dopo: **QLiveShowDetailView**, `endShowRow` visibile
3. **END SHOW** · stesso simbolo del Conto 3, riga 3 · schermata dopo: **QLiveShowsView**

**Conto = 3.** Identico al Conto 3, per lo stesso motivo del Conto 5: unico canale condiviso. (Interpretazione alternativa dichiarata in premessa: **2**.)

---

### CONTO 8 — (B) Stopped → (ii) END SHOW · RATIFICATO (rev2 27/08)

Eredita la stessa biforcazione del Conto 6.

**Lettura 1** ("Player fermo → card"): dalla card raggiunta al passo 1, rev2 pannello ⑥ dichiara — testualmente, senza condizionarlo allo stato del runner — che l'ingresso **dalla lista** porta "la freccia e lo Start", **non** la lamella con Stop: *«dalla lista ha la freccia e lo Start; dal Player non ha la freccia e ha la lamella»*. Preso alla lettera, questo significa che **in questa lettura il comando che chiude lo show non è raggiungibile affatto** da (B) — rev2 non disegna un caso "Start" quando il runner è già vivo, e non lo nomina come eccezione.

1. **freccia** → **card** (come Conto 6, Lettura 1, riga 1)
2. **riga show** → **dettaglio variante "dalla lista"** (arrow + Start, per la lettera di ⑥) — **nessun controllo di chiusura show presente in questa variante, per come rev2 la descrive**

**Conto Lettura 1 = non raggiungibile in questo disegno** (non è un "non costruito" di un passo — è l'assenza dell'intero passo successivo nella sequenza che rev2 descrive).

**Lettura 2** ("sessione viva ⇒ niente lista"): la freccia porta comunque al dettaglio-con-lamella, esattamente come nel Conto 4:

1. **freccia** → dettaglio-con-lamella (1 tocco)
2. **Stop** → conferma non specificata in questo foglio (2° tocco)

**Conto Lettura 2 = 2**, identico al Conto 4.

---

## Riepilogo numerico (nessuna conclusione — solo i numeri accertati sopra)

| da → a | COSTRUITO | RATIFICATO |
|---|---|---|
| (A) attesa → (i) scaletta | 2 | 1 |
| (A) attesa → (ii) END SHOW/Stop | 3 (o 2) | 2 |
| (B) stopped → (i) scaletta | 2 | 2 (L1) / 1 (L2) |
| (B) stopped → (ii) END SHOW/Stop | 3 (o 2) | non raggiungibile (L1) / 2 (L2) |

---

## §2 — Le due misure del piede — CONFERMA

File: [QLiveShowDetailView.swift](ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift), funzione `startfoot`.

**Testo vero (righe 488-497):**
```swift
private func startfoot(_ resolved: (songs: [Song], missingIDs: [UUID])) -> some View {
    VStack(spacing: 10) {
        if isShowLive {
            endShowRow
        }
        startButton(resolved)
    }
    .padding(.horizontal, 18)
    .padding(.top, 14)
    .padding(.bottom, 20)
```

### (a) — END SHOW sopra, BACK TO SHOW sotto → **CONFERMATA**

In un `VStack`, l'ordine di dichiarazione è l'ordine visivo top-to-bottom. `endShowRow` è dichiarata prima (riga 491), `startButton(resolved)` dopo (riga 493). Il testo del bottone inferiore, a show vivo, è "BACK TO SHOW" (`Text(isShowLive ? "BACK TO SHOW" : "START SHOW")`, [:654](ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:654)).

### (b) — 10pt reali, nessuna delle due voci aggiunge spazio verticale proprio → **CONFERMATA**

Meccanismo tracciato per intero, non fermato al container:

- **Container**: `VStack(spacing: 10)` — unica dichiarazione di spaziatura verticale fra i due figli.
- **`endShowRow`** ([:556-602](ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:556)): modificatori sull'`HStack` interno sono `.padding(.horizontal, 16)` (solo orizzontale), `.frame(maxWidth: .infinity)`, `.frame(height: subline == nil ? 56 : 64)` (altezza intrinseca fissa, non spaziatura), `.overlay(...)` (bordo, non spazio), `.contentShape(...)`. **Zero** `.padding(.vertical)`, **zero** `.padding(.top/.bottom)`.
- **`startButton(resolved)`** ([:604-707](ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:604)): modificatori sono `.frame(maxWidth: .infinity, minHeight: 56)`, `.background`, `.overlay` (×2), `.shadow`, `.opacity`. **Zero** `.padding(.vertical)`.
- Il container `startfoot` stesso porta `.padding(.top, 14)` / `.padding(.bottom, 20)` — margini VERSO L'ESTERNO del gruppo (sopra `endShowRow`, sotto `startButton`), non fra le due righe.

⇒ Nessun secondo contributo verticale trovato in nessuno dei due componenti: i 10pt del container sono l'intero spazio.

### (c) — nessun filetto separatore fra le due → **CONFERMATA**

`endShowRow` porta un `.overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).strokeBorder(Color(hex: "#ff3b30").opacity(0.52), lineWidth: 1))` ([:592-595](ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:592)) — un **bordo pieno tutto intorno al bottone stesso** (stesso pattern di `songRow`'s `.overlay(alignment: .bottom) { Rectangle()... }` visto altrove nel file per un VERO filetto — qui invece la forma è `RoundedRectangle`, senza `alignment:`, quindi contorna l'intera riga, non ne segna un bordo). Nessun `Divider()`, nessun `Rectangle()` con `alignment: .bottom/.top` fra `endShowRow` e `startButton` nel `VStack` di `startfoot`. Zero elementi fra le due righe oltre allo spazio del container.

---

## §3 — Tutte le porte da cui uno show entra nella collezione

Censimento per EFFETTO (chi scrive `QBeatsStore.setlists`), non per nome atteso.

**[M]** `@Published private(set) var setlists: [Setlist] = []` — [QBeatsStore.swift:18](ios_app/QBeats/Store/QBeatsStore.swift:18). Sweep di ogni sito che assegna, appende o rimuove da questo campo:

### SITE 1 — `QBeatsStore.load()` — SOSTITUISCE

1. **Sito, verbatim**: `songs = loadedSongs` / `setlists = loadedSetlists` / `backtracks = loadedBacktracks`, [QBeatsStore.swift:59-61](ios_app/QBeats/Store/QBeatsStore.swift:60) — rimpiazza **l'intero array** con quanto letto da `setlists.json` (iCloud o locale).
2. **Sostituisce o aggiunge**: **SOSTITUISCE**.
3. **Chi lo chiama, fino al gesto**: `QBeatsApp.swift`, `.task { try await QBeatsStore.shared.load() }` ([QBeatsApp.swift:17-25](ios_app/QBeats/QBeatsApp.swift:19)), agganciato al montaggio di `WindowGroup`. **Nessun gesto utente**: parte da sé all'avvio dell'app.
4. **Produzione o sviluppo**: nessun `#if DEBUG` attorno a questo `.task` — **PRODUZIONE**, ogni build.

### SITE 2 — `QBeatsStore.addSetlist(_:)` — AGGIUNGE

1. **Sito, verbatim**: `setlists.append(setlist)` poi `try? await save()`, [QBeatsStore.swift:104-107](ios_app/QBeats/Store/QBeatsStore.swift:105).
2. **Sostituisce o aggiunge**: **AGGIUNGE** (una entry, lascia intatte le altre).
3. **Chi lo chiama, fino al gesto** — **due catene distinte, stesso sito**:
   - **Catena 2a**: `QBeatsBackupManager.importSelected(...)`, `for entry in selectedSetlists { await store.addSetlist(entry.setlist) }` ([QBeatsBackupManager.swift:233](ios_app/QBeats/QBeatsBackupManager.swift:233)) ← `ImportView.swift:179` (bottone di conferma import, dentro la sheet) ← presentata da `QBeatsApp.swift`, `.sheet(isPresented: $showImportView)` ([QBeatsApp.swift:26-30](ios_app/QBeats/QBeatsApp.swift:26)) ← `onOpenURL { url in ... }` ([QBeatsApp.swift:31-45](ios_app/QBeats/QBeatsApp.swift:31)) — **il gesto è: l'utente apre un file `.qbeats` da FUORI l'app** (Files / Mail / AirDrop → "Apri con Q-BEATS").
   - **Catena 2b**: stesso `importSelected`, ma il `manifest` arriva da `DebugView.handleImporterResult` → `QBeatsBackupManager.parse(url)` ([DebugView.swift:78-99](ios_app/QBeats/DebugView.swift:88)) — **il gesto è: dentro l'app, bottone import di `DebugView`** (file picker interno).
4. **Produzione o sviluppo, mostrato non dedotto**:
   - Catena 2a (`onOpenURL`): **nessun** `#if DEBUG` in `QBeatsApp.swift` attorno a questo handler — **PRODUZIONE**, ogni build. Confermato device (`BUGS_QBEATS.md`, ticket `TD-backup-restore-no-ui`: *«Import passivo `.onOpenURL` — device-confermato 17/07... funzionante su device»*).
   - Catena 2b (bottone in `DebugView`): l'intero file `DebugView.swift` è racchiuso `#if DEBUG` ... `#endif` ([DebugView.swift:1](ios_app/QBeats/DebugView.swift:1) … [:808](ios_app/QBeats/DebugView.swift:808)); il suo unico ingresso, il bottone "⚙ DEBUG" di `HomeRootView`, è anch'esso `#if DEBUG` ([HomeRootView.swift:79-87](ios_app/QBeats/UI/HomeRootView.swift:79)). **In sorgente: solo sviluppo.** ⚠️ Ma `BUGS_QBEATS.md` (ticket `TD-build-palco-in-configurazione-debug`, righe 383-386) misura che l'IPA firmato che va in scena è compilato **`-configuration Debug`** (`.github/workflows/ios_build.yml:78`) con `SWIFT_ACTIVE_COMPILATION_CONDITIONS="DEBUG ..."` (:83) ⇒ **il codice `#if DEBUG`, compresa questa catena, è compilato e raggiungibile nella build che oggi va sul palco.** Due bandiere vere insieme: "solo sviluppo" per il sorgente, "presente anche in quella build specifica di produzione" per l'artefatto firmato attuale.

**Nota collaterale misurata**: `BackupView.swift` — grep `BackupView` su tutto `ios_app`: 3 occorrenze, **tutte nel proprio file**, zero call-site altrove. **Vista orfana**, irraggiungibile da qualunque gesto, in qualunque build. Non è una porta.

**Nota collaterale misurata**: nessuna funzione "crea nuovo show" esiste — [ShowsListView.swift:221](ios_app/QBeats/UI/QStage/ShowsListView.swift:221) lo dichiara nel proprio commento: *«la CREAZIONE (§8, differita) dà sempre "New Show"»* — nessun call-site di `addSetlist` da un bottone "New Show" in `ShowsListView`, confermato dal grep: l'unico chiamante di `addSetlist` in tutto `ios_app/QBeats/UI` è il commento di riga 223 che lo cita, non lo invoca.

### SITE 3 — `QBeatsStore.updateSetlist(_:)` — NÉ SOSTITUISCE NÉ AGGIUNGE

`setlists[idx] = setlist` ([QBeatsStore.swift:109-113](ios_app/QBeats/Store/QBeatsStore.swift:111)) sostituisce UN elemento già presente (per `id`), non introduce uno show nuovo nella collezione: nessuna riga della lista Shows appare o scompare. Censito per completezza dello sweep, non è una porta d'ingresso.

### SITE 4 — `QBeatsStore.deleteSetlist(id:)` / `moveSetlists(from:to:)` — RIMOZIONE / RIORDINO

`setlists.removeAll { $0.id == id }` ([:116](ios_app/QBeats/Store/QBeatsStore.swift:116)) e `.move(fromOffsets:toOffset:)` ([:121](ios_app/QBeats/Store/QBeatsStore.swift:121)): tolgono o riordinano, non aggiungono. Censiti per completezza, non sono porte d'ingresso.

### SITE 5 — `QBeatsStore.injectTestData(songs:setlists:)` — SOSTITUISCE

1. **Sito, verbatim**: `self.songs = songs` / `self.setlists = setlists`, [QBeatsStore.swift:198-201](ios_app/QBeats/Store/QBeatsStore.swift:200).
2. **Sostituisce o aggiunge**: **SOSTITUISCE** l'intero array (nessuna persistenza su disco: la funzione non chiama `save()`).
3. **Chi lo chiama, fino al gesto**: 8 bottoni distinti dentro `DebugView.swift` (righe 536, 564, 585, 614, 649, 691, 720, 762), ciascuno passa `setlists: [setlist]` — **un array a un solo elemento**, in tutti e otto i casi verificato sul testo delle chiamate stesse. Gesto: tap su uno di questi bottoni, dentro `DebugView`, raggiunta dal bottone "⚙ DEBUG" di `HomeRootView`.
4. **Produzione o sviluppo**: funzione dichiarata `#if DEBUG` alla fonte ([QBeatsStore.swift:193](ios_app/QBeats/Store/QBeatsStore.swift:193)) — stessa doppia bandiera del Sito 2/catena 2b: solo sviluppo in sorgente, compilata nell'IPA di palco odierno per lo stesso ticket `TD-build-palco-in-configurazione-debug`.

---

### ⇒ Risposta secca: due show nella lista contemporaneamente, oggi, su un device?

**[M] Sì, è possibile.** Nessuna combinazione di SITE 1 + SITE 5 la produce da sola (SITE 1 sostituisce da disco, SITE 5 sostituisce con un array a un elemento: nessuno dei due, da solo, porta a 2). **Serve SITE 2** (AGGIUNGE): con almeno uno show già presente (da SITE 1 al lancio, o da un tap di SITE 5), un secondo show entra senza cancellare il primo tramite il gesto **"apri un file `.qbeats` da fuori l'app"** (Files / Mail / AirDrop → "Apri con Q-BEATS" → `onOpenURL` → sheet `ImportView` → l'utente seleziona lo show e conferma). Questo gesto (catena 2a) **non porta alcuna bandiera `#if DEBUG`**: è raggiungibile allo stesso modo **in entrambe le app** (quella di produzione e quella di sviluppo), ed è l'unico, fra i cinque siti censiti, di cui esiste una conferma su device (`BUGS_QBEATS.md`, 17/07). La catena 2b (bottone import dentro `DebugView`) è una seconda via allo stesso esito, gated `#if DEBUG` in sorgente ma presente nell'IPA di palco per la ragione già mostrata al Sito 2.

---

## §5 — Percorsi e depositi

```
repo  HANDOFF\MISURE_CC_2026-08-30_A263-CONTO-DEI-TOCCHI-E-PORTE-DELLA-LISTA.md
E:    FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-30_A263-CONTO-DEI-TOCCHI-E-PORTE-DELLA-LISTA.md
```

⛔ **Le impronte di QUESTO file vivono nel messaggio di consegna, non qui dentro**: un file non può contenere il proprio hash — ogni modifica lo cambierebbe, rendendo il numero scritto qui falso dal momento stesso in cui lo scrivo (visto e riparato una volta in questa stessa stesura). Verifica eseguita: confronto sorgente↔destinazione (file NON tracciato, nessun blob — regime corretto per il caso scoperto dichiarato in `BOX5_QBEATS.md:49` sugli untracked di `HANDOFF/`), `cmp` exit 0.

Nessun indirizzo Drive scritto a mano (R-δ.4): riflesso automatico atteso.

*A263-MISURE-CC-2026-08-30-FINE*
