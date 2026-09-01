# MISURE CC — A108, CONTRADDITTORIO SULLA BOZZA ⟦S5b⟧ (sola lettura)

Da: CC · A: Mauro + referee · 18/08/2026
Perimetro rispettato: **zero righe sotto `ios_app/`, zero commit, zero push, HEAD invariato.**
Scrittura: solo questo referto in `HANDOFF/` + R-δ.

Marcatura: **[M]** misurato ora, da me · **[R]** riportato, non rimisurato · **[A]** giudizio mio.

**[M]** HEAD = `44fea3e378414c300ffd50fcac527c683740735b`. Tutto estratto con `git show <sha>:<path>`,
**mai dal disco**. A106 e A107: ignorati come disposto, mai eseguiti, nessun artefatto prodotto.

⚠️ **PRESA D'ATTO, non adulazione:** la correzione di prodotto — *lo Start carica e parcheggia,
non fa partire* — coincide con il **primo ramo** del bivio che avevo lasciato aperto in A103
(«se apre e basta: la catena dei sei passi è completa»). Non è una conferma che mi do da solo: è
la ragione per cui, sotto questa decisione, **la catena non ha più il pezzo architetturale** che
avrebbe avuto sotto l'altro ramo. Il resto del referto è dedicato a dove la bozza **non** regge.

---

# LE CINQUE AFFERMAZIONI — verdetto per riga

## ① «Tre file bastano; `LiveView` non va toccata» → **REGGE** — ma con una riserva che non è piccola

**[M] Nessun quarto FILE serve.** Il montaggio del player è già costruito e non richiede modifiche:
il gate `if let runner` e la costruzione con l'iniezione stanno già a `ios_app/QBeats/UI/QLive/QLiveRootView.swift:110` e `:157-158`, e
`audioEngine` arriva dall'alto senza re-iniezione (dichiarato e motivato a `ios_app/QBeats/UI/QLive/QLiveRootView.swift:140-156`).
**[M]** `LiveView` non ha bisogno di nulla per il caso «carica e parcheggia»: la sua sessione se la
crea da sé (`ios_app/QBeats/UI/Live/LiveView.swift:11`) e il suo `onAppear` fa già il riempimento del display.

⛔ **MA IL LAVORO DENTRO `QLiveShowDetailView` NON È «aggiungere una closure», e questo la bozza
non lo dice.** Il bottone START SHOW **non è disabilitato**: `isEnabled` (`ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:288`) pilota
**solo** l'aspetto — ombra (`:323`), bordo (`:326-331`), opacità (`:333`) — e **non esiste alcun
`.disabled(`** nel file.

**[M]** `.disabled(` in `ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift` → **0**. **Controllo positivo, forma identica:** `.disabled(` rende
**6 file** nel corpus, e il modo di casa per un bottone spento è il parametro `disabled:` di
`RubberBtnView` — usato **6 volte** nel solo `TransportView.swift`. ⇒ Il difetto non è che manchi
l'idioma: **l'idioma c'è e qui non è stato usato.**

⇒ **[A] Conseguenza operativa:** cablando solo la closure, un tocco su una scaletta che non
risolve costruisce comunque un runner a catalogo vuoto. **La riserva è questa, e va nella scheda:
⟦S5b⟧ deve anche chiudere il tocco, non solo cablarlo.**

## ② «Il montaggio lascia il player CARICO E FERMO, videata piena» → **REGGE**, con una condizione

**[M] Nessuna delle tre porte di avvio scatta da sola.** `ios_app/QBeats/UI/Live/LiveView.swift:211-240` (`onAppear`) chiama
`runner.primeDisplay(session:)` e nient'altro; il commento a `:222` lo dichiara: «senza dover
tappare Play». Le tre porte reali (`ios_app/QBeats/UI/Live/LiveView.swift:190`, `ios_app/QBeats/UI/Live/LiveView.swift:433`, `TransportView.swift:62`) sono legate a
un tocco, a `linkStartedSubject`, o al Play del transport: **nessuna è innescata dal montaggio.**

**[M] E `primeDisplay` è display puro** — `audioEngine` rende **zero** occorrenze nel suo corpo:

```text
271	    func primeDisplay(session: LiveSession) {
272	        guard let section = currentSection else { return }
273	        updateSessionDisplay(session: session)
274	        session.currentBPM         = section.bpm
275	        session.totalBarsInSection = Int(section.repetitions)
276	    }
```


⚠️ **LA CONDIZIONE, ed è quella che rende ① e ② la stessa questione:** la prima riga è
`guard let section = currentSection else { return }`. Con un catalogo vuoto, `currentSong` rende
`nil` (`ios_app/QBeats/SetlistRunner.swift:71-74`), quindi `currentSection` rende `nil`, quindi **`primeDisplay` esce
immediatamente e la videata resta VUOTA.**
⇒ «videata piena» regge **solo se la scaletta risolve**. Su una scaletta orfana il player si monta
**bianco**, senza che nulla dica perché.

## ③ «Il ramo `else` è irraggiungibile per costruzione; c'è un precedente due rami sopra» → **REGGE la sostanza, NON REGGE il «due»**

**[M] Il precedente esiste ed è questo, verbatim** — `ios_app/QBeats/UI/QLive/QLiveRootView.swift:92-112`, lo `switch` intero:

```text
92	    var body: some View {
93	        switch page {
94	        case .shows:
95	            QLiveShowsView(onExit: onExit, onSwitchToStage: onSwitchToStage, onSelectShow: { show in
96	                selectedSetlist = show
97	                navigate(to: .detail)
98	            })
99	        case .detail:
100	            // ⟦S5a⟧: raggiunge QLiveShowDetailView col payload separato (:47). Ramo `else`
101	            // difensivo — non dovrebbe accadere (unico chiamante di navigate(.detail) è
102	            // onSelectShow sopra, che valorizza selectedSetlist nello stesso gesto).
103	            if let show = selectedSetlist {
104	                QLiveShowDetailView(setlist: show, onBack: { navigate(to: .shows) })
105	            } else {
106	                EmptyView()
107	            }
108	        case .metronome:
109	            // ⟦S4R⟧ GATE — MAI il player senza runner iniettato.
110	            if let runner = roomSession.runner {
111	                // UNICO punto in cui il runner entra nell'albero delle viste.
112	                // I figli lo osservano DIRETTAMENTE (`@EnvironmentObject` sul
```


⛔ **«Due rami sopra» è SBAGLIATO: è UNO.** I rami sono tre — `.shows` (`:94`), `.detail` (`:99`),
`.metronome` (`:108`) — e il precedente di guardia sta in `.detail`, cioè **immediatamente sopra**.
`.shows` non ha alcun ramo `else`. Il precedente resta valido: cambia il conteggio, non l'argomento.

**[M] E «irraggiungibile per costruzione» regge, ma poggia su una CONDIZIONE D'ORDINE che la bozza
non enuncia:** lo slot va riempito **PRIMA** di navigare. Se si navigasse prima e si riempisse dopo,
esisterebbe un frame in cui `page == .metronome` con `runner == nil`, e il ramo `else` **si
vedrebbe**. ⇒ Non è un difetto della bozza: è un vincolo che **deve essere scritto**, perché
l'irraggiungibilità dipende interamente da lui.

**[M]** A quel punto nessun'altra via porta a `.metronome`: `navigate(to:)` è `private` (`ios_app/QBeats/UI/QLive/QLiveRootView.swift:88`),
`QLivePage` è un `private enum` (`ios_app/QBeats/UI/QLive/QLiveRootView.swift:44`), l'unica scrittura di `page` è `ios_app/QBeats/UI/QLive/QLiveRootView.swift:89`, e il valore
di partenza è `.shows` (`ios_app/QBeats/UI/QLive/QLiveRootView.swift:46`).

## ④ «Reversibilità PULITA: un revert non lascia niente sul device» → **REGGE**

**[M]** Nessuno dei tre passi scrive. `store.resolve(_:)` è **puro** — legge `songs`, accumula due
array, logga:

```text
152	    func resolve(_ setlist: Setlist) -> (songs: [Song], missingIDs: [UUID]) {
153	        var resolved: [Song] = []
154	        var missing: [UUID] = []
155	        for id in setlist.songIDs {
156	            if let song = songs.first(where: { $0.id == id }) {
157	                resolved.append(song)
158	            } else {
159	                missing.append(id)
160	                logger.warning("resolve — songID \(id.uuidString) not found in catalog")
161	            }
162	        }
163	        return (resolved, missing)
164	    }
```


`SetlistRunner.init` legge lo store e fa un `os_log` (`ios_app/QBeats/SetlistRunner.swift:61-67`, già misurato in A105); il
mutatore assegnerebbe un `@Published` in RAM; `navigate(to:)` assegna uno `@State`.
⇒ **Zero scritture su disco, zero `UserDefaults`, zero iCloud, nessun cambio di formato dati.**
Un revert dei tre file riporta il codice indietro e **non c'è nulla da ripulire sul telefono**.

⚠️ **[A] Una precisazione che non intacca il verdetto:** «non lascia niente» vale per ⟦S5b⟧. Se il
collaudo è stato fatto con la porta DEBUG, ciò che resta sul device **non** è responsabilità di
⟦S5b⟧ ma della procedura — misurata in A105, e lì sta la regola per non fare danni.

## ⑤ «`injectTestData` produce scalette che compaiono in Shows con Start ABILITATO» → **REGGE**

**[M] La lista Shows NON filtra per appartenenza.** Legge `store.setlists` e basta — l'unico filtro
è il testo di ricerca:

```text
62	    private var visibleShows: [Setlist] {
63	        let filtered = searchText.isEmpty
64	            ? store.setlists
65	            : store.setlists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
66	        return store.sortedSetlists(filtered)
```


⇒ Non esiste alcun campo «appartiene a Q-Live» che possa nascondere le scalette iniettate. Il
campo di persistenza è materia di ⟦S4L⟧, **sospeso**, e oggi non esiste.

**[M]** `injectTestData` inietta **canzoni e scalette insieme**, con `songIDs` che puntano alle
canzoni iniettate nello stesso gesto (`DebugView.swift:528-536`) ⇒ `resolve()` le ritrova tutte,
`resolved.songs` non è vuoto, `isEnabled` è `true`, e il bottone si presenta acceso.

⇒ **Il collaudo è possibile. La scheda non va riscritta per questo motivo.**

---

# LA DOMANDA DI TERMINOLOGIA — e la risposta è: **due cose diverse**

**[M] Gli stati di playback che esistono davvero, verbatim, tutti e otto:**

```text
3	enum LivePlaybackState: Equatable {
4	    case standby(nextSongName: String)
5	    case countIn(countdown: Int)
6	    case playing
7	    case stopped
8	    case loopActive
9	    case overlayStop(sectionName: String, songName: String)
10	    case fineSetlist
11	    // CD-6 (27/05/2026) — Follower Collaborativo in attesa che il Director
12	    // cross-device prema Play. Entrato quando l'utente tappa Play in Vista LIVE
13	    // con `linkMode == .collaborativa`. Uscita: (a) Director starta → callback
14	    // Link emette `linkStartedSubject` → LiveView observer transita a .playing
15	    // via runner.startSetlist; (b) tap START LOCAL nella WaitingForDirectorView
16	    // → runner.startSetlist locale; (c) tap CANCEL → dismiss UIHostingController
17	    // a Bivio. CD-Q2=B ratificato libro mastro v14.
18	    case waitingForDirector
19	}
```


**[M] E lo stato in cui si trova il player SUBITO DOPO il montaggio è `.stopped`**, per valore di
default della sessione — con il commento che spiega perché, e che è esattamente il commento che
Mauro ha letto:

```text
29	    // MARK: - Stato
30	    // Default `.stopped`: all'avvio Vista LIVE niente em-dash centrale.
31	    // L'overlay `.standby` viene mostrato SOLO quando il SetlistRunner
32	    // imposta esplicitamente lo state tra una canzone e l'altra (vedi
33	    // SetlistRunner.swift ramo standby). Cambiato da `.standby(nextSongName: "—")`
34	    // il 17/05/2026 — TD #28, Step 2 roadmap pre-CD.
35	    @Published var playbackState: LivePlaybackState = .stopped
36	    @Published var isBacktrackLocked: Bool = false
```


⛔ **NON SONO LA STESSA COSA, e la differenza è strutturale, non di sfumatura.**

- **`.standby` del codice** porta un valore associato obbligatorio, `nextSongName: String`
  (`ios_app/QBeats/Models/LivePlaybackState.swift:4`). Non è uno stato di attesa generico: è **«canzone finita, la prossima è X»**, e lo
  imposta il runner **fra un brano e l'altro**. Renderizza un overlay dedicato
  (`ios_app/QBeats/UI/Live/LiveView.swift:132-133`, `StandbyOverlayView`). ⇒ Non esiste uno `.standby` senza una canzone successiva.
- **Lo «STANDBY» di Mauro** — *show caricato, fermo, pronto a partire* — nel codice si chiama
  **`.stopped`**, ed è il valore iniziale della sessione (`ios_app/QBeats/Models/LiveSession.swift:35`). Il commento a `ios_app/QBeats/Models/LiveSession.swift:30-34`
  registra anche **quando è cambiato e perché**: era `.standby(nextSongName: "—")` fino al
  17/05/2026, poi TD #28 l'ha portato a `.stopped` proprio per togliere l'em-dash centrale
  all'ingresso.

⇒ **[M] LA BUONA NOTIZIA: lo stato che Mauro descrive ESISTE GIÀ, e ⟦S5b⟧ NON deve costruirlo.**
È `.stopped` con il display già riempito da `primeDisplay`. La scheda **non cambia** per questo.

⚠️ **[A] LA CATTIVA NOTIZIA, ed è una trappola di puntatore:** la **parola** «sTANDBY» è già
occupata, da uno stato diverso, che ha un overlay suo e un significato suo. Se la scheda ⟦S5b⟧
scrive «lo show resta in standby», chi la implementa cercherà `.standby` nel codice e troverà la
cosa sbagliata. ⇒ **Non è una questione di stile: è la stessa classe di difetto dei puntatori
rotti.** La formula esatta da usare è **«caricato e fermo, `playbackState == .stopped`»**.
Chi decide come chiamarlo è Mauro; io registro che la parola è già presa.

---

# IL FRENO — quattro difetti che la bozza non vede

## ⓐ IL SECONDO SHOW DELLA SERATA — **serio, e non è un caso di laboratorio**

**[M] Uscire dal player NON ferma l'audio, ed è RATIFICATO che non lo fermi.** Il back del player
va all'imbuto interno (`ios_app/QBeats/UI/QLive/QLiveRootView.swift:157`), e il divieto è inciso in testa al file:

```text
78	    // DECISIONE CD 18/07 (ratificata — LIBRO Sez.2, riga 18/07/2026):
79	    // navigazione ≠ transport. NESSUNO stop audio va agganciato alle
80	    // transizioni di `page`, in NESSUNA forma (niente `.onChange(of: page)`
81	    // con stop — ruling D1; vietato anche inerte). Il click lo ferma SOLO uno
82	    // STOP esplicito del transport: con Link Director uno stop è un evento di
83	    // BANDA, non può essere il sottoprodotto di un «indietro». Lo stop
84	    // legittimo al bordo-stanza (uscita da `.qLive`) vive in AppRootView
85	    // `.onChange(of: screen)` — FUORI da questo strato.
```


**[M] L'unico stop reale è al BORDO-STANZA**, cioè uscendo da `.qLive` — `ios_app/QBeats/UI/AppRootView.swift:70-76`:

```text
70	        .onChange(of: screen) { newScreen in
71	            if newScreen == .qLive {
72	                audioEngine.triggerDNDReminderIfNeeded()
73	            } else if previousScreen == .qLive {
74	                audioEngine.stop()
75	            }
76	            previousScreen = newScreen
```


⇒ **[A] LO SCENARIO, passo per passo:** Mauro fa partire lo show A · suona · tocca il back del
player (**non** uno STOP del transport) · torna a Shows · apre lo show B · tocca START.
**Il motore audio sta ancora suonando lo show A**, mentre la videata mostra lo show B fermo.
Il nuovo runner è nello slot, il vecchio è stato sostituito, ma **il click non si è mai fermato**.

⚠️ **Non lo chiamo un difetto di ⟦S5b⟧ e non propongo il rimedio:** discende da una decisione
ratificata (navigazione ≠ transport, 18/07) che è giusta per il palco. Ma **oggi è invisibile
perché nessuno può far partire uno show; con ⟦S5b⟧ diventa raggiungibile al primo collaudo con due
show.** ⇒ Va **almeno messo nel piano di collaudo**, e la decisione se sia un difetto o il
comportamento voluto **è di Mauro, non mia**.

## ⓑ START SHOW NON È DISABILITATO — **serio**

**[M]** Già misurato al punto ①: zero `.disabled(` in `ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift`, contro **6 file** che lo usano e
**6** usi del parametro `disabled:` nel solo `TransportView.swift`.

**[A] Scenario:** una scaletta con canzoni orfane (i `songIDs` non risolvono) → `resolved.songs`
vuoto → il bottone si **dipinge** spento (opacità 0,4) ma resta **toccabile** → si costruisce un
runner a catalogo vuoto → si naviga → `primeDisplay` esce al primo `guard` → **il player si monta
bianco e non si sa perché**. Sul palco è il peggiore dei modi di fallire: silenzioso.

## ⓒ L'ORDINE DELLE DUE AZIONI — **minore, ma va scritto**

**[A]** Riempire lo slot **poi** navigare. L'ordine inverso apre un frame con `page == .metronome`
e `runner == nil`, cioè rende visibile il ramo `else` che il punto ③ dà per irraggiungibile.
⇒ **La correttezza del punto ③ dipende da questo vincolo.** Non è opzionale e non è ovvio.

## ⓓ END SHOW ARRIVA CON UN BOTTONE MORTO — **minore per ⟦S5b⟧, ma è ⟦S5b⟧ che lo fa vedere**

**[M]** `ios_app/QBeats/UI/Live/FineSetlistView.swift:28-33`, verbatim:

```text
28	                VStack(spacing: 12) {
29	                    Button("BACK TO SHOWS") { onBackToShows() }
30	                        .buttonStyle(OverlayStopButtonStyle(primary: true, scaleFactor: scaleFactor))
31	                    Button("RESTART SETLIST") { /* restart setlist — Fase successiva */ }
32	                        .buttonStyle(OverlayStopButtonStyle(primary: false, scaleFactor: scaleFactor))
33	                }
```


`RESTART SETLIST` ha la closure **vuota**, mentre `LIBRO_MASTRO_QBEATS.md:353` ratifica il
*comportamento* di toglierlo (opzione Ⓐ di CD) e `SCALETTA_ATOMI_S6_2026-07-10.md:311` dichiara che
la condizione del cancello va letta **al singolare**. ⇒ Il codice ha ancora **due** bottoni.
⚠️ È già tracciato (`TD-fineshow-bottoni-morti`), ma va detto qui perché **⟦S5b⟧ è ciò che rende
END SHOW raggiungibile per la prima volta**: al primo collaudo che arriva in fondo, quel bottone
morto si vede.

---

# ⛔ QUESTO REFERTO NON HA VERIFICA INDIPENDENTE, E VA DETTO

**[M]** Avevo lanciato un audit indipendente — otto verificatori, cinque sulle affermazioni e tre a
caccia di difetti (secondo show, lifecycle/corse, casi limite dei dati). **È morto per intero:
otto agenti su otto terminati per limite di sessione, zero risultati restituiti.**

⇒ **Tutto ciò che questo referto marca [M] l'ho misurato io, direttamente, a fonte** — e ogni zero
porta il suo controllo positivo. Ma **nessuno ha provato a confutare ME**, e per un referto il cui
compito era confutare è una lacuna che va dichiarata, non nascosta.
⚠️ **Dove sono più esposto**, e quindi dove un secondo paio d'occhi servirebbe di più: il punto ⓐ
(il secondo show) poggia su un ragionamento di **composizione** fra tre fatti misurati
separatamente — il back non ferma l'audio, lo stop vive solo al bordo-stanza, lo slot si sostituisce
— e la composizione è mia, non misurata come sequenza su un device.

---

# COSA NON HO FATTO

⛔ Non ho riscritto la scheda. Non ho deciso al posto di Mauro. Non ho proposto il disegno del
gate sul tocco, né il rimedio per il secondo show: ho misurato dove la bozza non regge e **mi fermo
lì**, come disposto.

---

## RIEPILOGO

| # | affermazione | verdetto |
|---|---|---|
| ① | tre file bastano, `LiveView` intatta | **REGGE** — nessun quarto file. ⚠️ Ma dentro `QLiveShowDetailView` manca il **gate sul tocco**: 0 `.disabled(` contro 6 file che lo usano |
| ② | montaggio = carico, fermo, videata piena | **REGGE** — nessuna porta di avvio scatta da sola. ⚠️ «Videata piena» **solo se la scaletta risolve**: `primeDisplay` esce al primo `guard` |
| ③ | ramo `else` irraggiungibile + precedente | **REGGE la sostanza, NON REGGE il conteggio**: il precedente è **UN** ramo sopra, non due. E l'irraggiungibilità **dipende dall'ordine** riempi→naviga, che va scritto |
| ④ | reversibilità pulita | **REGGE** — zero scritture su disco/UserDefaults/iCloud, `resolve()` puro |
| ⑤ | `injectTestData` → Start abilitato | **REGGE** — Shows legge `store.setlists` senza filtro d'appartenenza; il collaudo è possibile |
| **terminologia** | «standby» | **DUE COSE DIVERSE.** Lo stato di Mauro esiste ed è `.stopped`; ⟦S5b⟧ **non deve costruirlo**. Ma la **parola** è occupata da `.standby(nextSongName:)`, altro stato, altro overlay |
| **freno** | difetti | ⓐ secondo show con audio ancora acceso (**serio**) · ⓑ Start toccabile anche da spento (**serio**) · ⓒ ordine riempi→naviga (**minore, obbligatorio**) · ⓓ END SHOW con un bottone morto (**minore, ma lo scopre ⟦S5b⟧**) |

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1.

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `3f85e052bea04f31ae2d6a42190c58731eb14de2d87a351eba5d6d4e12768693`
- **byte** (file completo): `20753`
- **righe** (file completo): `369`
- **CR** (0x0D, contati sui byte, mai con grep): `0`

---

*A108-CONTRADDITTORIO-FINE*
