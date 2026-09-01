# MISURE CC — A102, TRE VERBATIM (sola lettura)

Da: CC · A: referee + Mauro · 18/08/2026
Perimetro rispettato: zero righe sotto `ios_app/`, zero commit, zero push. Scrittura: solo questo
referto, in `HANDOFF/` + R-δ.

Marcatura: **[M]** misurato ora, da me, in questa sessione · **[R]** riportato da altri, non
rimisurato da me · **[A]** assunzione o giudizio mio.

---

## RITIRO, IN TESTA, DI UNA MIA AFFERMAZIONE FALSA

**[M]** All'apertura di questa sessione ho scritto che il congedo `HANDOFF/CONGEDO_CC_2026-08-18.md`
l'avevo scritto io, e che rileggerlo valeva «come riverifica, non come scoperta».
⛔ **È falso e lo ritiro.** Quel congedo l'ha scritto un'altra istanza in un'altra chat; io l'ho
ricevuto in contesto e ne ho ereditato la paternità senza misurarla. È la stessa forma d'errore che
il congedo elenca al suo interno — un fatto dato per vero perché era presente, non perché era stato
verificato — e commetterla mentre si legge il documento che la denuncia la rende peggiore, non
minore.

⇒ **Da qui in avanti, in questo referto, il congedo A101 è trattato come CLAIM DA VERIFICARE.**
Ogni suo numero è stato rimisurato da zero prima di essere confermato.

---

## AGGANCIO — l'ID A102

**[M]** Forma a token, due supporti indipendenti (`HANDOFF/` nel repo su C: · `HANDOFF/` su E:).

| ricerca | repo | E: | lettura |
|---|---:|---:|---|
| `\bA102\b` | **1** | **1** | ⚠️ **non zero** — vedi sotto |
| `\bA101\b` (controllo positivo adiacente) | 1 | 1 | non nullo: la forma funziona |
| `\bA99\b` (secondo controllo positivo) | 2 | 2 | non nullo |

⚠️ **L'unica occorrenza di `A102` è una MENZIONE, non un artefatto:** è
`HANDOFF/CONGEDO_CC_2026-08-18.md:69`, la cella `| **A102** | **0** | **0** | ⇒ **PROSSIMO LIBERO** |`.
Stessa categoria che il congedo stesso applica ad A98. **L'ID è libero e lo uso.**

⚠️ **Rilievo, piccolo ma della stessa famiglia di quello che il congedo dichiara per il proprio
sha256:** quella cella dice `0 | 0` e nell'istante in cui è stata scritta è diventata `1 | 1`,
perché la scrittura è essa stessa l'occorrenza. Il congedo ha dichiarato l'autoriferimento per lo
sha e **non** per questa cella. Non cambia nulla di operativo — l'ID resta libero — ma è la stessa
classe di difetto: *il testo descrive un mondo che l'atto di scriverlo cambia.*

---

## B1 · R1 MISURATO DA ME, NON COPIATO

### 1 · HEAD e albero

**[M]** HEAD locale = HEAD remoto = **`44fea3e378414c300ffd50fcac527c683740735b`**

- `git rev-parse HEAD` → `44fea3e378414c300ffd50fcac527c683740735b`
- `git ls-remote origin master` → `44fea3e378414c300ffd50fcac527c683740735b	refs/heads/master`
  (interrogato il remoto, **non** `rev-parse origin/master`, che leggerebbe una copia locale)
- branch corrente: `master` · remoto: `https://github.com/19Bullfrog78/Q-BEATS`

**[M] Albero pulito sui tracciati: SÌ.**
`git status --porcelain=v1 | grep -vc '^??'` → **0**.
⚠️ **Non «lbero pulito» in assoluto:** gli untracked ci sono e sono molti — quasi tutta la
`HANDOFF/` recente, `DESIGN/QLive_EndShow/`, `.tmp.driveupload/`. La misura dice che **nessun file
tracciato è modificato**, che è cosa diversa.

### 2 · I workflow, per nome

**[M]** I workflow attivi sul repo sono **tre**, non due, e a HEAD esistono i tre file
corrispondenti (`.github/workflows/ios_build.yml`, `f1_build_check.yml`, `build_linkhut.yml`).

| workflow | run id | esito | data (UTC) | evento | headSha |
|---|---|---|---|---|---|
| **`iOS Signed Build`** | `32148440889` | **success** | 2026-08-18T14:27:32Z | push | `44fea3e378414c300ffd50fcac527c683740735b` |
| **`F1 — Build Check (zero errors, zero warnings)`** | `30639169986` | **failure** | 2026-07-31T14:34:28Z | workflow_dispatch | `bfc92285d165852a9c5618786a7e95f7166025e7` |
| `F1 — Build Check` (penultima) | `30638276963` | **failure** | 2026-07-31T14:21:52Z | workflow_dispatch | `40f099bb28ad87627e3c6df926993a3df297df90` |
| `Build LinkHut Diagnostic` (terzo, minore) | `26290451025` | success | 2026-05-22T13:25:01Z | workflow_dispatch | — |

**[M]** F1 ha **quattro run in tutta la sua storia**, non due: `30639169986` (failure, 31/07) ·
`30638276963` (failure, 31/07) · `24935301504` (success, 25/04) · `24935244603` (failure, 25/04).
⛔ **Non gira dal 31/07 e le sue ultime due run sono entrambe fallite.** È `workflow_dispatch`:
manuale, non parte da sola.
⚠️ La run verde di `iOS Signed Build` è **sullo sha esatto di HEAD**: verificato sul campo
`headSha` a 40 caratteri, non per data.

### 3 · Impronte dei cinque canonici a HEAD

**[M]** Estratte con `git show 44fea3e378414c300ffd50fcac527c683740735b:<path>`, **mai da disco**.
CR contati sui byte (`tr -cd '\r' | wc -c`), mai con `grep`.

| canonico | sha256 (blob) | byte | righe | CR | blob id |
|---|---|---:|---:|---:|---|
| `LIBRO_MASTRO_QBEATS.md` | `59c1fd73b431c04f6b289178999d6feb92231b171e5ce276af0ca199b4072722` | 275 470 | 518 | 0 | `c6f4d9ee6438df38ccf68f0f68791e438300e44e` |
| `BUGS_QBEATS.md` | `64f7df0927448915f2913e0281aeb0be3b96a0018bfd2dde7ba2a1123eb2ac06` | 299 772 | 1 067 | 0 | `9e06aa5a4535d2fb3134d9c6f18937c14db76608` |
| `BOX3_QBEATS.md` | `c728baccb7823f7f20d4544b72130147e7f72fc40104887f0da3fcf24d29fb3c` | 89 457 | 803 | 0 | `490d6d9b38c355dc53ddc9b31431f9a858f2b342` |
| `BOX5_QBEATS.md` | `cf425ff0d576910c9caa2899cad232e0c8447f605d240021262608aed184ff5b` | 57 158 | 596 | 0 | `21b23d621ac224c759b53d813196058483e3b056` |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | `09bf3442a372a17e66dda7d53ca512e0d1bc551e80f42d2c7a08614811d84fe5` | 56 791 | 350 | 0 | `60c1d860f78ad22da52b6bc616c4fd2a19b3eff6` |

⚠️ **CR=0 su tutti e cinque perché è la faccia BLOB.** Verificato da me con `git check-attr text`:
`LIBRO_MASTRO_QBEATS.md` → `text: unspecified` (faccia disco con CRLF, diversa dal blob) ·
`HANDOFF/**` → `text: unset`, cioè `-text` (disco e blob coincidono, faccia unica).

### 4 · Confronto con i valori dichiarati nel congedo A101

**[M] COINCIDONO. Tutti. Nessuna divergenza: niente si è mosso.**

| voce dichiarata in A101 | mia misura | esito |
|---|---|---|
| HEAD locale = remoto = `44fea3e3…735b` | identico | **coincide** |
| albero pulito sui tracciati → 0 | 0 | **coincide** |
| `iOS Signed Build` `32148440889` success 2026-08-18T14:27:32Z | identico | **coincide** |
| F1 `30639169986` failure 2026-07-31T14:34:28Z | identico | **coincide** |
| F1 `30638276963` failure 2026-07-31T14:21:52Z | identico | **coincide** |
| `Build LinkHut Diagnostic` `26290451025` 22/05 success | identico | **coincide** |
| LIBRO `59c1fd73…2722` / 275 470 B / 518 righe / 0 CR | identico | **coincide** |
| BUGS `64f7df09…ac06` / 299 772 B / 1 067 righe / 0 CR | identico | **coincide** |
| BOX3 `c728bacc…fb3c` / 89 457 B / 803 righe / 0 CR | identico | **coincide** |
| BOX5 `cf425ff0…4ff5b` / 57 158 B / 596 righe / 0 CR | identico | **coincide** |
| SCALETTA `09bf3442…4fe5` / 56 791 B / 350 righe / 0 CR | identico | **coincide** |
| prossimo ID libero = A102 | libero (l'unica occorrenza è la sua stessa cella) | **coincide nella sostanza** |

⇒ **Nessuna divergenza impone di fermarsi.** Proseguo con B2, B3, B4.

---

## B2 · LA SCHEDA ⟦S5⟧, INTERA E VERBATIM

**[M]** Estratta con `git show 44fea3e:HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`, righe **298-312**.
Confine **misurato, non assunto**: `298` è la sua intestazione `###`; `313` è
`### ⟦S6⟧ METROFAB — cablaggio porta (dest differita stub) · POST · CI`, la successiva. La riga
**312 è vuota** e appartiene alla scheda: è inclusa.
Nessun taglio, nessun riassunto. Il numero prima della tabulazione è il numero di riga nel file.

```text
298	### ⟦S5⟧ QLiveShowDetailView (frame ③) + Start · POST · CI+DEVICE
299	- **Scopo:** detail read-only pushato da S4, Start gattato su risolto-non-vuoto; consuma empty-states + launcher.
300	- **File:** `UI/QLive/QLiveShowDetailView.swift` NUOVO (navbar back + RoomSwitchBar `.segMini[active:.qLive]` INERTE; dhead; songlist idx/tag-rail R1-pending SOLO LAYOUT/nome/met; orfani `resolve().missingIDs` = SKIP + conteggio "N unavailable"; Start disabilitato DS opacity 0.4 se `resolve().songs` vuoto; Start→launcher **S4R**).
301	- ⚠️ **SUPERATO — 06/08/2026: la variante `.segMini` NON ESISTE PIÙ.** Le righe di questa scheda che la prescrivono — il **File:** qui sopra e il **Cond:** più sotto («A (`.segMini` INERTE)») — **non si riscrivono** e restano leggibili come sono: si marcano. Il freeze consolidato CD del 06/08 **abolisce** la variante `.seg-mini` (un solo room switch in tutta l'app) e sostituisce `.navbar .seg-mini .o` 9px/30pt con **`.roomseg .opt` 10,5px/34pt**; nello stesso atto `.dhead .nm` passa **23px → 29px** con max 2 righe poi troncamento. ⇒ Chi implementa ⟦S5⟧ cabla contro l'**ARTEFATTO NORMATIVO**, non contro questa riga: `DESIGN/QLive_Nav/2026-08-06_QLive-Shows_FREEZE-CONSOLIDATO_390x844__rev3-NORMATIVA.html`, blob `430c9894c2539c4753f8ab0b8c3baf64d73f5335` — ancorato in `LIBRO_MASTRO_QBEATS.md` Sez.2, riga `2026-08-06` «ARTEFATTO NORMATIVO — Q-LIVE › SHOWS». ⚠️ **L'area tattile resta 50pt**: cambia il chrome visibile, non il bersaglio. ⛔ **QUESTO BULLET SPOSTA DI UNA RIGA tutto ciò che lo segue** (341→342 righe totali). Verificato a fonte prima di scriverlo: la citazione **nuda** a `:300` in `ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:14` punta alla riga sopra, che **non si sposta**; l'unica citazione a riga ≥301 è `SCALETTA_ATOMI_S6_2026-07-10.md:314 @ e61efd0e9bc2f9174b755e5a25e02a611c795cea` (`LIBRO:329`), **ancorata a commit e quindi immune**. Stessa forma di dichiarazione del bullet `⟦S5⟧ CANCELLO` più sotto. ⚠️ **PERIMETRO DI QUESTA MARCATURA, dichiarato:** il termine compare in **cinque** punti del file — `:28` (mappa dei frame), `:50` (scheda ⟦S1⟧, le props del componente), `:113` (gate device ⟦S3⟧, «sblocca `.seg-mini` a S5»), più i due di questa scheda. **Questa marcatura copre SOLO i due di ⟦S5⟧**: marcare da qui le schede altrui sarebbe fuori forma. Gli altri tre **restano non marcati e lo si registra** — materia di un giro doc a sé, non di questo.
302	- **Reversibilità:** RISCHIO/accoppiata (pushato da S4; dip **S4R** — il launcher). Ordine: dopo S4 e dopo ⟦S4R⟧. ⚠️ Il nome «S4L» che questa riga portava prima del 28/07 indicava il launcher, oggi ⟦S4R⟧: S5 dipende dal launcher, **non** dalla prima scrittura.
303	- **Gate:** no write; DEVICE per Start audio-live.
304	- **Cond:** E (tag solo layout; iPad/editor differiti); Start su risolto-non-vuoto (F=`songIDs.isEmpty`; G=`!songIDs.isEmpty && resolve().songs.isEmpty`); A (`.segMini` INERTE).
305	- **OPEN:** badge `⚠ FILE MISSING` (≠ orfani; = esistenza `Song.backtrackFilename:22`, nessun helper oggi) **DIFFERITO**. Referee: quando si farà, esistenza calcolata FUORI dal render path (cache al load), MAI `FileManager.fileExists` per-riga a scroll-time (jank).
306	- **OPEN — tipo del runner:** `SetlistRunner.startSetlist(audioEngine:session:)` (`ios_app/QBeats/SetlistRunner.swift`) si aspetta un `LiveSession` (`ios_app/QBeats/Models/LiveSession.swift`), tipo DIVERSO da `QLiveSession` (`ios_app/QBeats/UI/QLive/QLiveSession.swift`) — il contenitore-stanza che ⟦S4R⟧ ha introdotto per possedere lo slot del runner. **⟦S5⟧ deve riconciliare i due tipi: non è cablaggio, è architettura.** Reperto CC (`HANDOFF/MISURE_CC_2026-08-02_P3-S5-RICOGNIZIONE.txt` punto 2), nessuna soluzione decisa qui — il reperto rende visibile la materia, non la scioglie.
307	- ⚠️ **MARCATURA 07/08 — IL BULLET SOPRA SI SEPARA IN DUE, E LA SUA PRIMA METÀ È CONFERMATA A FONTE. La riga resta come scritta: si marca, non si riscrive.** **PREMESSA — REGGE, rimisurata al blob a HEAD `779172e6353d6e51dcee542953725000f48dd05a`:** `SetlistRunner.startSetlist(audioEngine:session:)` (`ios_app/QBeats/SetlistRunner.swift:109 @ 779172e6353d6e51dcee542953725000f48dd05a`) si aspetta davvero un `LiveSession`, ed è davvero un tipo diverso da `QLiveSession`. Su questo il bullet sopra è esatto e non si tocca. **Ciò che la misura AGGIUNGE, e che il bullet non poteva sapere:** `LiveSession` (`ios_app/QBeats/Models/LiveSession.swift @ 779172e6353d6e51dcee542953725000f48dd05a`) porta **16** proprietà `@Published`, zero metodi, zero init, ed è istanziata in **UN SOLO punto di tutto il corpus** — `ios_app/QBeats/UI/Live/LiveView.swift:11 @ 779172e6353d6e51dcee542953725000f48dd05a`, `@StateObject private var session = LiveSession()`: **creata dal player, `private`, non iniettabile e non leggibile da fuori**. `QLiveSession` (`ios_app/QBeats/UI/QLive/QLiveSession.swift @ 779172e6353d6e51dcee542953725000f48dd05a`) porta **un solo campo**, `:35` `@Published private(set) var runner: SetlistRunner? = nil`, zero metodi, zero init; `extension QLiveSession` rende **0** su tutti i `.swift` tracciati (controllo positivo, stessa forma: `extension ` rende 11). Misure del referto `HANDOFF/MISURE_CC_2026-08-07_A78-RICOGNIZIONE-PERCORSO-DI-AVVIO.txt`, dove i quattro file sono stati letti PER INTERO. ⛔ **QUESTA RIGA E LA SEGUENTE SPOSTANO DI DUE RIGHE tutto ciò che le segue** (342→344 righe totali). Verificato a fonte prima di scriverle, con la stessa forma usata dalla marcatura del 06/08: le citazioni **nude** a questo file con riga ≥307 sono **ZERO** su tutti e cinque i canonici più i commenti `.swift`; le uniche citazioni ≥307 sono `SCALETTA_ATOMI_S6_2026-07-10.md:314 @ e61efd0e9bc2f9174b755e5a25e02a611c795cea` (due volte, in `LIBRO:329` e in questo stesso file) e `SCALETTA_ATOMI_S6_2026-07-10.md:322 @ 2960f089225b3c80cf56cb839fde871cf9738b3d` (in `BUGS_QBEATS.md`), **tutte ancorate a commit e quindi immuni**.
308	- ⚠️ **MARCATURA 07/08 — LA SECONDA METÀ DEL BULLET SOPRA È DEGRADATA A DOMANDA APERTA, E NON È NECESSARIA OGGI. Zero parole riscritte.** La frase «**⟦S5⟧ deve riconciliare i due tipi: non è cablaggio, è architettura**» **non è mai stata sorgentata**: il referto che il bullet cita copre la PREMESSA, e il bullet stesso lo ammette due frasi dopo («il reperto rende visibile la materia, non la scioglie»). ⇒ Si legge come **DOMANDA APERTA**, non come prescrizione. **E la misura di oggi dice che oggi non serve:** i due tipi **non si incontrano mai** — `QLiveSession` non nomina `LiveSession` in nessuna delle sue 36 righe; lo Start (⟦S5b⟧) **non può** chiamare `startSetlist`, perché la `LiveSession` che quella firma pretende non esiste ancora quando lo Start viene premuto e nasce `private` dentro `LiveView` solo al montaggio del player; lo Start può soltanto **far nascere il runner** e metterlo nello slot, e l'avvio parte più tardi da dentro `LiveView` (START LOCAL, `ios_app/QBeats/UI/Live/LiveView.swift:190 @ 779172e6353d6e51dcee542953725000f48dd05a`, una delle tre sole chiamate reali di `startSetlist` in tutto il corpus). ⚠️ **RISERVA DI CC, incisa insieme e non soppressa:** è misurato che **oggi** una riconciliazione non serve; **non** è misurato che non possa servire domani — se si volesse che la sessione di display SOPRAVVIVA alla navigazione interna della stanza, servirebbe davvero, e sarebbe una decisione di disegno che nessuno ha preso. ⚠️ **Perimetro della misura, dichiarato:** la fonte citata dal bullet sopra (`HANDOFF/MISURE_CC_2026-08-02_P3-S5-RICOGNIZIONE.txt`) **NON è stata riletta**; questo verdetto poggia sul codice a HEAD, non su un giudizio di quel referto.
309	- **VINCOLO TECNICO — vedi, nella scheda ⟦S4R⟧ di questo stesso file, il bullet «🔴 VINCOLO TECNICO — verbatim da `BOX3_QBEATS.md:34`»** (INDIRIZZO-NON-COPIA, per SIMBOLO — nessun numero di riga: il bersaglio è nello stesso file che questo diff modifica, un'ancora di commit qui non è possibile): un `ObservableObject` annidato non propaga; i figli devono osservare IL RUNNER, non la sessione — pena UI metronomo congelata. Testo verbatim, motivazione e ancora di commit già incisi lì, non ripetuti qui. ⚠️ **QUESTO BULLET SPOSTA DI UNA RIGA tutto ciò che lo segue** (339→340 righe totali). Verificato a fonte su tutti e cinque i canonici più i commenti `.swift`: l'unica citazione a questo file con numero di riga ≥306 è `LIBRO_MASTRO_QBEATS.md:329`, che cita `SCALETTA_ATOMI_S6_2026-07-10.md:314 @ e61efd0e9bc2f9174b755e5a25e02a611c795cea` — **ancorata**, quindi immune (indirizzo di contenuto a un commit storico, non a HEAD). Nessun'altra citazione nuda sopra quella soglia trovata.
310	- **CANCELLO — ⟦S5⟧ non chiude device finché i due bottoni di `FineSetlistView` non fanno qualcosa.** BACK TO SHOWS: quanto `LIBRO_MASTRO_QBEATS.md:154 @ c1556e57b1a81fafa7973b8647741ede9c92e6cf` dichiara attivo («torna alla libreria SHOWS»). RESTART SETLIST: quanto `LIBRO_MASTRO_QBEATS.md:153 @ c1556e57b1a81fafa7973b8647741ede9c92e6cf` propone (CD-3, «ricomincia la setlist appena suonata») — oggi **proposto**, non ratificato: per questo bottone resta aperta anche la domanda «cosa deve fare», non solo il cablaggio. ⚠️ **Deviazione dal testo dettato in prompt, dichiarata:** una prima forma equiparava i due bottoni come se entrambi avessero ratifica attiva — verificato a fonte che `LIBRO_MASTRO_QBEATS.md:155 @ c1556e57b1a81fafa7973b8647741ede9c92e6cf` **non copre l'azione di RESTART SETLIST**; corretto qui prima di scrivere. ⛔ **Che cosa quella riga dichiari, qui NON si qualifica:** vive per INDIRIZZO nel bullet «Contrasto con la ratifica» del ticket `TD-fineshow-bottoni-morti` in `BUGS_QBEATS.md`, dove è riportata in verbatim intero e misurata contro il codice. ⚠️ **SECONDA DEVIAZIONE, dichiarata (giro A25):** il prompt indicava `@ eeb725dd46363d6cdc428a5aa43ede5881389d31` per l'ancora di `:155`; Fase 1-bis dello stesso giro ha verificato che quell'ancora è falsificata anche per `:153` e `:154` (a quei commit il file si chiamava ancora `STATO_QBEATS.md`, per rename confermato con `git log --follow`, e la tabella era ancora `_(da popolare CD)_`) — sostituite tutte e tre le ancore con HEAD, non solo quella nuova. ⚠️ **RETTIFICA A26 (C6), dichiarata:** in A25 la qualifica «`:155` ratifica il titolo/momento «END SHOW»» era stata lasciata scritta com'era, per mandato ristretto di C4. È stata **rimossa qui**: con l'ancora ora corretta a HEAD quella glossa sarebbe stata un'affermazione falsa accanto a un indirizzo verificabile — chi lo apre legge il contrario. Resta il solo punto vero, che `:155` non copre l'azione di RESTART SETLIST; ciò che quella riga dice davvero vive per indirizzo in `BUGS_QBEATS.md`. **Motivo del cancello:** ⟦S5⟧ è ciò che rende raggiungibile END SHOW (`BUGS_QBEATS.md:132 @ 0ee9543d45d638df061c5a48872aaefeb8a88f26` — «⟦S5⟧ apre entrambe le serrature nello stesso atomo»). ⛔ **QUESTO BULLET SPOSTA DI UNA RIGA tutto ciò che lo segue** (340→341 righe totali). Verificato a fonte, stessa forma della verifica sopra: nessuna citazione nuda a questo file con riga ≥307 trovata su cinque canonici più commenti `.swift`; l'unica citazione ≥307 resta la stessa di sopra (`LIBRO:329`→`:314`, ancorata, immune).
311	- ⚠️ **MARCATURA 07/08 — LA CONDIZIONE DEL CANCELLO VA LETTA AL SINGOLARE, E NON È DICHIARATA SODDISFATTA. Il bullet sopra resta come scritto.** RESTART SETLIST **si toglie** da END SHOW: opzione Ⓐ di CD, ratificata in `LIBRO_MASTRO_QBEATS.md:353 @ 81740e48f24e089703b0199d0ffd20b9b3bfae7c` (proposta e disegno di CD; ratifica tecnica del referee e OK di Mauro, due cancelli distinti passati entrambi). ⇒ La condizione «i **DUE** pulsanti di `FineSetlistView` devono fare qualcosa» si legge da qui in avanti **AL SINGOLARE**: resta **un** pulsante, BACK TO SHOWS, ed è **cablato** — `ios_app/QBeats/UI/Live/FineSetlistView.swift:29 @ 779172e6353d6e51dcee542953725000f48dd05a`, `Button("BACK TO SHOWS") { onBackToShows() }`, atomo ⟦S5x⟧, commit `4e4c24113b21fed53b55c2a6d38a1903e52ecd1f`. ⛔ **QUESTO NON RENDE IL CANCELLO SODDISFATTO, e la distinzione è il punto:** il pulsante è **chiuso a codice** ma la sua validazione su device è **DIFFERITA**, perché END SHOW oggi è irraggiungibile — nessuno l'ha mai visto funzionare. Il cancello si chiude quando quel tocco è stato fatto su un device, non quando la closure smette di essere vuota. ⚠️ Rilievo di **CD**, accolto: era CD a chiedere che la condizione fosse riscritta al singolare e **non** dichiarata soddisfatta. ⛔ **QUESTA RIGA SPOSTA DI UNA RIGA tutto ciò che la segue** (344→345 righe totali). Verifica a fonte identica a quella delle due righe sopra: zero citazioni **nude** a questo file con riga ≥309; le uniche in quella regione sono ancorate a commit, quindi immuni.
312	
```

**[M] Composizione della scheda ⟦S5⟧:** **13** bullet di primo livello, di cui **7** campi di scheda
(`Scopo` · `File` · `Reversibilità` · `Gate` · `Cond` · `OPEN` · `OPEN — tipo del runner`),
**4** marcature di superamento (`:301` 06/08 · `:307`, `:308`, `:311` tutte 07/08) e **2** bullet di
vincolo (`VINCOLO TECNICO` `:309` · `CANCELLO` `:310`).
⇒ **Più della metà della scheda non è scheda: è sedimento di correzioni successive.**

---

## B3 · LA SCHEDA ⟦S4L⟧, INTERA E VERBATIM — modello di forma

**[M]** Stesso comando, righe **247-297**. Confine misurato: `247` è la sua intestazione `###`;
`298` è `### ⟦S5⟧ QLiveShowDetailView (frame ③) + Start · POST · CI+DEVICE`. La riga **297 è
vuota** e appartiene alla scheda: è inclusa.

```text
247	### ⟦S4L⟧ Prima scrittura: «Remove from Q-Live» + menu «···» · POST · CI+DEVICE
248	- **Scopo:** costruire «Remove from Q-Live» e il menu «···» come incisi in
249	  `BOX5_QBEATS.md:381 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3` (§ «Menu «···» e «Remove from
250	  Q-Live»»): entrambe le vie sulla riga — menu «···» a **una sola voce** più **swipe trailing rosso**
251	  — percorso al danno a due gesti intenzionali, voce disabilitata (visibile, non nascosta) con
252	  sessione armata o in play, popup di conferma nella forma ②. La spec vive in BOX5: questa scheda
253	  **non la duplica**, la indirizza.
254	- **🔴 Gate — UNICO ATOMO DELLA SCALETTA CHE SCRIVE DATI UTENTE.** Per ratifica
255	  `LIBRO_MASTRO_QBEATS.md:306 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`: «La prima scrittura sui dati
256	  utente entra con ⟦S4L⟧ ed è **limitata allo stato di appartenenza dello show a Q-Live**; ogni
257	  altra scrittura resta vietata in §6.» La scrittura è **solo** quello stato: `moveSetlists` e
258	  `addSetlist` restano NON cablati, e nessuna cancellazione vive in Q-Live
259	  (`LIBRO_MASTRO_QBEATS.md:307 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`). DEVICE obbligatorio: due
260	  affordance da provare invece di una, e il conflitto fra swipe trailing e gesti di navigazione
261	  **non è determinabile a fonte** (`LIBRO_MASTRO_QBEATS.md:308 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`).
262	- **Dipendenze (entrambe dure):** ⟦S4R⟧ — serve il runner iniettato; ⟦S4K⟧ — il congedo tastiera
263	  dev'essere già costruito e provato, perché questo atomo porta l'utente a operare sulla riga **con la
264	  ricerca in uso**: `LIBRO_MASTRO_QBEATS.md:312 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199` — «Finché il
265	  congedo non è nell'app e provato su device, a ⟦S4L⟧ l'utente resta con la tastiera alzata e l'unica
266	  uscita spegne la sessione del metronomo — sul palco.»
267	  ⛔ **NON si scriva che il popup di conferma collide con la tastiera: i canonici dicono l'opposto.**
268	  `LIBRO_MASTRO_QBEATS.md:311 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199` — «Nessuna collisione col
269	  congedo-tastiera Q20: lo stesso file marca ② «identico a ①»» — e `BOX5_QBEATS.md:390 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`
270	  — «Nessuna collisione col congedo tastiera.» La dipendenza regge sulla riga 312, non su una
271	  collisione che non esiste.
272	- **File:** la riga e il menu vivono nella vista di ⟦S4⟧ (`UI/QLive/QLiveShowsView.swift`).
273	  ⚠️ **Il file del campo di persistenza NON si dichiara qui:** la forma tecnica del campo è scelta
274	  CC ancora aperta (BOX5 V28, QL-SHOWS-01 e PENDENZE DEL CAPITOLO punto 5). Si fissa alla
275	  costruzione, non a naso adesso.
276	- **Reversibilità:** ⚠️ **NON pulita come gli altri atomi §6** — è il solo che tocca i dati
277	  dell'utente: un revert del codice non ripristina da sé gli stati di appartenenza già scritti sul
278	  device. Nessuna fonte prescrive una procedura di rollback dei dati: **pendenza da sciogliere prima
279	  della costruzione**, non qui.
280	- **⚠️ PENDENZA — lo stato «sessione armata» non esiste a HEAD**
281	  (`LIBRO_MASTRO_QBEATS.md:303 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`): l'unica occorrenza di `armed`
282	  è `backtrackArmed`, flag interno al buffer del backtrack, senza rapporto con l'armamento di uno
283	  show. Lo stato nasce con l'arma + standby: per la lettera della fonte «la dipendenza è soddisfatta
284	  per costruzione, ma va scritta perché non si perda **se il blocco venisse spezzato**»; l'ancora di
285	  codice che LIBRO porta è `AudioEngine.swift:370`.
286	- **⚠️ IL «BLOCCO UNICO» — definizione e indirizzo, perché questo atomo lo eredita.** È `QL-SHOWS-06`
287	  di `BOX5_QBEATS.md:328 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`, ratificato in
288	  `LIBRO_MASTRO_QBEATS.md:302 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199` (POSTILLA 2): **cinque pezzi,
289	  un blocco solo** — pillola ▶ · «···» a una sola voce · swipe trailing rosso · popup di conferma ·
290	  campo di persistenza; «non si separano, e Remove non si stacca dalla pillola».
291	- **⚠️ PENDENZA — la pillola ▶ non ha atomo assegnato in questa scaletta.** Delle cinque parti del
292	  blocco unico, questa scheda copre menu, swipe e popup; il campo di persistenza è rimandato (sopra);
293	  la **pillola ▶ non compare in NESSUNA delle dodici schede** (misurato: «pillola» = 0 righe, `▶` = 0
294	  righe nell'intero file). Il canonico la dichiara inseparabile da Remove, quindi o entra qui o il
295	  «blocco unico» è già spezzato dalla scaletta stessa. **Nessuna fonte assegna la pillola a un atomo:
296	  si registra, non si decide qui.**
297	
```

### I campi delle due schede, a confronto

**[M] Nomi esatti dei campi, come compaiono, nell'ordine in cui compaiono.**

**⟦S5⟧** (righe 298-312):

| # | riga | testo esatto dell'etichetta |
|---:|---:|---|
| 1 | 299 | `- **Scopo:**` |
| 2 | 300 | `- **File:**` |
| 3 | 301 | `- ⚠️ **SUPERATO — 06/08/2026: la variante `.segMini` NON ESISTE PIÙ.**` |
| 4 | 302 | `- **Reversibilità:**` |
| 5 | 303 | `- **Gate:**` |
| 6 | 304 | `- **Cond:**` |
| 7 | 305 | `- **OPEN:**` |
| 8 | 306 | `- **OPEN — tipo del runner:**` |
| 9 | 307 | `- ⚠️ **MARCATURA 07/08 — IL BULLET SOPRA SI SEPARA IN DUE…**` |
| 10 | 308 | `- ⚠️ **MARCATURA 07/08 — LA SECONDA METÀ DEL BULLET SOPRA È DEGRADATA A DOMANDA APERTA…**` |
| 11 | 309 | `- **VINCOLO TECNICO — vedi, nella scheda ⟦S4R⟧ di questo stesso file, il bullet …**` |
| 12 | 310 | `- **CANCELLO — ⟦S5⟧ non chiude device finché i due bottoni di `FineSetlistView` non fanno qualcosa.**` |
| 13 | 311 | `- ⚠️ **MARCATURA 07/08 — LA CONDIZIONE DEL CANCELLO VA LETTA AL SINGOLARE…**` |

**⟦S4L⟧** (righe 247-297):

| # | riga | testo esatto dell'etichetta |
|---:|---:|---|
| 1 | 248 | `- **Scopo:**` |
| 2 | 254 | `- **🔴 Gate — UNICO ATOMO DELLA SCALETTA CHE SCRIVE DATI UTENTE.**` |
| 3 | 262 | `- **Dipendenze (entrambe dure):**` |
| 4 | 272 | `- **File:**` |
| 5 | 276 | `- **Reversibilità:**` |
| 6 | 280 | `- **⚠️ PENDENZA — lo stato «sessione armata» non esiste a HEAD**` |
| 7 | 286 | `- **⚠️ IL «BLOCCO UNICO» — definizione e indirizzo, perché questo atomo lo eredita.**` |
| 8 | 291 | `- **⚠️ PENDENZA — la pillola ▶ non ha atomo assegnato in questa scaletta.**` |

**[M] CAMPI PRESENTI IN AMBEDUE — sono quattro**, elencati nell'ordine in cui compaiono in ⟦S5⟧:

1. **`Scopo`** — ⟦S5⟧ `:299` · ⟦S4L⟧ `:248`
2. **`File`** — ⟦S5⟧ `:300` · ⟦S4L⟧ `:272`
3. **`Reversibilità`** — ⟦S5⟧ `:302` · ⟦S4L⟧ `:276`
4. **`Gate`** — ⟦S5⟧ `:303` · ⟦S4L⟧ `:254`

⚠️ **L'ORDINE DEI QUATTRO CAMPI COMUNI NON È LO STESSO NELLE DUE SCHEDE.**
⟦S5⟧: `Scopo` → `File` → `Reversibilità` → `Gate`.
⟦S4L⟧: `Scopo` → `Gate` → `File` → `Reversibilità`.
Solo `Scopo` occupa la stessa posizione in entrambe.

⚠️ **E `Gate` non ha la stessa FORMA nelle due.** In ⟦S5⟧ è un'etichetta nuda con due punti,
`**Gate:**`. In ⟦S4L⟧ è una frase con emoji dentro il grassetto,
`**🔴 Gate — UNICO ATOMO DELLA SCALETTA CHE SCRIVE DATI UTENTE.**`. Stesso campo, due forme.

**[M] PRESENTI IN ⟦S5⟧ E ASSENTI IN ⟦S4L⟧** — nove bullet:

| campo | riga | natura |
|---|---:|---|
| `Cond` | 304 | **campo di scheda** — ⟦S4L⟧ non ne ha alcuno |
| `OPEN` | 305 | **campo di scheda** — ⟦S4L⟧ non ne ha alcuno |
| `OPEN — tipo del runner` | 306 | campo di scheda (secondo `OPEN`, con qualificatore) |
| `VINCOLO TECNICO` | 309 | bullet di vincolo |
| `CANCELLO` | 310 | bullet di vincolo |
| `SUPERATO — 06/08/2026` | 301 | marcatura |
| `MARCATURA 07/08` (×3) | 307, 308, 311 | marcature |

**[M] PRESENTI IN ⟦S4L⟧ E ASSENTI IN ⟦S5⟧** — quattro bullet:

| campo | riga | natura |
|---|---:|---|
| `Dipendenze (entrambe dure)` | 262 | **campo di scheda** — ⟦S5⟧ non ha un campo dipendenze: la sua dipendenza da ⟦S4R⟧ vive **dentro il testo** di `Reversibilità` (`:302`), non in un campo proprio |
| `⚠️ PENDENZA` (×2) | 280, 291 | pendenze registrate — ⟦S5⟧ non usa questa etichetta |
| `⚠️ IL «BLOCCO UNICO»` | 286 | vincolo ereditato |

⚠️ **Una divergenza di forma che vale la pena registrare, perché rende le due schede non
confrontabili a colpo d'occhio:** in ⟦S5⟧ le emoji di allerta stanno **fuori** dal grassetto
(`- ⚠️ **MARCATURA…**`); in ⟦S4L⟧ stanno **dentro** (`- **⚠️ PENDENZA…**`, `- **🔴 Gate…**`).
Misurato su tutti i bullet di primo livello delle due schede: **nessuna eccezione in nessuna delle
due**. Non è un difetto di contenuto; è il segno che le due schede sono state scritte con due
convenzioni diverse e nessuna delle due è scritta da nessuna parte.

⚠️ **[A] Il mio parere su ⟦S4L⟧ come modello di forma:** è il modello **migliore** delle due, e
non per stile. ⟦S4L⟧ ha `Dipendenze` come campo proprio ed etichetta le sue pendenze una per una;
⟦S5⟧ nasconde la dipendenza da ⟦S4R⟧ dentro la prosa di `Reversibilità` e affida tutto il resto a
quattro marcature successive che il lettore deve ricomporre da sé. ⛔ **Ma ⟦S4L⟧ è SOSPESO** (per
`SCALETTA:323`), quindi è un modello di forma che non ha ancora dovuto reggere una costruzione: la
sua qualità è dimostrata sulla carta, non alla prova.

---

## B4 · LA SEZIONE C, INTERA E VERBATIM

**[M]** Stesso comando, righe **322-327**. Confine misurato: `322` è `## C · Ordine (2 corsie)`;
`328` è `## D · Risposte referee alle 8 domande`. La riga **327 è vuota** e appartiene alla sezione:
è inclusa. La sezione C è lunga **sei righe**, di cui quattro portano contenuto.

```text
322	## C · Ordine (2 corsie)
323	**PRE:** S0 → {S1, S2F} → S2 → S2b → S2c → S2e → S2d → **S3** (indipendente Nodo A; i sub-atomi S2b/S2c/S2e/S2d = ciclo CD-decisioni + estrazione EmptyStateKit, tutti FATTI). → **SPINE NODO A** (N0→N1a→N1b) gattella POST. → **POST — ordine ratificato 31/07:** S4 → **S4K** → **S4R** → **S5** → **⟦S-EXIT⟧** → **S4L** → **S6** ultimo. ⚠️ I tre atomi S4K/S4R/S4L sostituiscono l'unico «S4L» della v2 (sdoppiamento 28/07) e il loro ordine reciproco resta **obbligatorio**: S4K → S4R → S4L. Sulla «coppia stretta» che la v2 prescriveva fra S4 e il launcher, vedi la pendenza nella scheda ⟦S4R⟧. ⛔ **⟦S4L⟧ è SOSPESO** fino a chiusura di tre pendenze (atomo della pillola ▶ · forma tecnica del campo di persistenza · procedura di rollback dati), e **⟦S-EXIT⟧ precede ⟦S4L⟧**, per condizione fisica e non per disciplina dell'operatore — `LIBRO_MASTRO_QBEATS.md:329 @ c00feb43361d01d961fd1e97cf4c1a77a5bf7c7e`. **QUESTA RIGA È LA SEDE UNICA DELL'ORDINE DEGLI ATOMI §6: ogni altra catena d'ordine in un canonico è storia — si legge, non si riscrive.**
324	⚠️ **MARCATURA 07/08 — ⟦S5⟧ SI È SPEZZATA IN TRE, E LA RIGA D'ORDINE SOPRA NON LO SA. La riga resta come scritta: si marca, non si riscrive.** Misurato sul blob a HEAD `779172e6353d6e51dcee542953725000f48dd05a`: `S5a`, `S5b`, `S5x` rendono **ZERO** occorrenze in tutto questo file — in **entrambe le casse**, minuscola e maiuscola — con controllo positivo `S5` = **24** sullo stesso blob; e il commit di ⟦S5a⟧, `25056b66`, rende **ZERO** su tutti e cinque i canonici, con controllo positivo `4e4c2411` = **5** in `LIBRO_MASTRO_QBEATS.md`. La sede unica dell'ordine non registra né i due atomi già consegnati né quello che resta. Si legga così: **(1) ⟦S5a⟧ — `QLiveShowDetailView`, frame ③ read-only. CONSEGNATA su master, commit `25056b66eda40ad76d91a886ace442b7064ca900` (05/08), CI verde. ⛔ NON validata su device.** ⚠️ **È RAGGIUNGIBILE OGGI** e il suo gate device **non dipende da ⟦S5b⟧**: percorso misurato Home → Q-LIVE → pagina `.shows` (che è il default, `ios_app/QBeats/UI/QLive/QLiveRootView.swift:46 @ 779172e6353d6e51dcee542953725000f48dd05a`) → tap-riga → ramo `.detail` (`:103-104`, senza alcun gate). **(2) ⟦S5x⟧ — cablaggio di BACK TO SHOWS in `FineSetlistView`. CONSEGNATO su master, commit `4e4c24113b21fed53b55c2a6d38a1903e52ecd1f` (06/08), CI verde.** ⛔ **Formula esatta, e non se ne usi un'altra: «CHIUSO A CODICE, validazione device DIFFERITA a ⟦S5b⟧».** Non «chiuso»: END SHOW è irraggiungibile perché lo slot del runner non ha mutatori, quindi nessuno ha mai visto quel bottone funzionare — ed è **impossibilità**, non indisciplina dell'operatore. **(3) ⟦S5b⟧ — cablaggio dello Start. È IL FRONTE.** UN solo bottone: lo Start diviso vive solo sulla card della lista, il `.startfoot` del dettaglio resta invariato (freeze consolidato del 06/08). **ORDINE RECIPROCO: ⟦S5a⟧ → ⟦S5x⟧ → ⟦S5b⟧, poi ⟦S-EXIT⟧ come già ratificato dalla riga sopra.** ⛔ **QUESTA RIGA E LA SEGUENTE SPOSTANO DI DUE RIGHE tutto ciò che le segue** (345→347 righe totali). Verificato a fonte: zero citazioni **nude** a questo file con riga ≥320; l'unica in quella regione è `SCALETTA_ATOMI_S6_2026-07-10.md:322 @ 2960f089225b3c80cf56cb839fde871cf9738b3d`, in `BUGS_QBEATS.md`, **ancorata a commit e quindi immune**.
325	⚠️ **MARCATURA 07/08 — ⟦S-EXIT⟧ È NELL'ORDINE RATIFICATO MA NON HA SCHEDA. Buco registrato, NON colmato in questo giro.** Misurato sul blob a HEAD `779172e6353d6e51dcee542953725000f48dd05a`: `S-EXIT` rende **2** occorrenze in tutto il file, ed **entrambe stanno sulla riga d'ordine qui sopra** — cioè in Sezione C. La **Sezione B**, che si intitola «Scaletta 12 atomi», contiene esattamente **12** intestazioni `###`, contate una per una: ⟦S0⟧ · ⟦S1⟧ · ⟦S2F⟧ · ⟦S2⟧ · ⟦S3⟧ · ⟦NODO A⟧ · ⟦S4⟧ · ⟦S4K⟧ · ⟦S4R⟧ · ⟦S4L⟧ · ⟦S5⟧ · ⟦S6⟧. **Nessuna è ⟦S-EXIT⟧.** ⇒ L'atomo su cui poggia il vincolo duro «niente data con la band» esiste in casa come **sola freccia in una riga d'ordine**: nessuno scopo, nessun file, nessuna reversibilità, nessun gate scritti da nessuna parte. ⛔ **La scheda NON si scrive qui:** scriverla sarebbe progettare un atomo dentro un giro di igiene documentale, ed è materia di un mandato suo. Si registra che manca, e da questo momento chi legge l'ordine sa che una delle sue tappe non ha contenuto.
326	- ✅ **MARCATURA 18/08 — ⟦S5a⟧ CHIUSO DEVICE, supera il punto (1) della marcatura 07/08 sopra. La marcatura 07/08 resta come scritta: si marca, non si riscrive.** Collaudo Mauro 18/08 su `Test Setlist L1.b`: apertura dettaglio, dati, ritorno a SHOWS, nessun dato stantio — tutti verdi, ancora dietro porta DEBUG (§8 assente). Dettaglio in `LIBRO_MASTRO_QBEATS.md`, riga `2026-08-18` (⟦S5a⟧ chiuso device). ⛔ **⟦S5x⟧ resta invariato: «CHIUSO A CODICE, validazione device DIFFERITA a ⟦S5b⟧»** — il collaudo del 18/08 non lo tocca, END SHOW resta irraggiungibile. **ORDINE RECIPROCO INVARIATO:** ⟦S5a⟧ (ora chiuso) → ⟦S5x⟧ → ⟦S5b⟧, poi ⟦S-EXIT⟧.
327	
```

**[M] Come sono scritte davvero le righe d'ordine — le tre cose che la struttura mostra:**

1. **La catena d'ordine è UNA SOLA RIGA**, la `323`, e si autodichiara sede unica: «QUESTA RIGA È
   LA SEDE UNICA DELL'ORDINE DEGLI ATOMI §6: ogni altra catena d'ordine in un canonico è storia —
   si legge, non si riscrive.»
2. **Le tre righe che seguono (324, 325, 326) NON riscrivono l'ordine: lo marcano.** Tutte e tre
   dicono la stessa cosa nella stessa forma — «La riga resta come scritta: si marca, non si
   riscrive». ⇒ L'ordine vero non si legge sulla riga d'ordine: si legge sulla riga d'ordine
   **più** le tre marcature, e chi legge solo la `323` legge una catena che la casa stessa sa
   incompleta.
3. **La catena scritta a `:323` è:** `S4 → S4K → S4R → S5 → ⟦S-EXIT⟧ → S4L → S6`, con `⟦S4L⟧`
   dichiarato **SOSPESO** e `⟦S-EXIT⟧` che **precede** `⟦S4L⟧`. La marcatura `:324` spezza `S5` in
   `⟦S5a⟧ → ⟦S5x⟧ → ⟦S5b⟧`; la `:326` chiude `⟦S5a⟧` su device. ⇒ **La catena operativa reale, a
   HEAD, è:** `S4 → S4K → S4R → [⟦S5a⟧ fatto] → [⟦S5x⟧ chiuso a codice, device differita] →
   ⟦S5b⟧ → ⟦S-EXIT⟧ (senza scheda) → ⟦S4L⟧ (sospeso) → S6`. Nessuna riga la scrive così: va
   ricomposta ogni volta da quattro righe.

---

## RILIEVI MISURATI IN QUESTO GIRO

### R1 · Dove sta davvero ⟦S5b⟧ — il congedo A101 lo localizza male in due punti

Il congedo scrive: «`⟦S5b⟧` esiste solo come una frase dentro la marcatura di `⟦S5⟧` a
`SCALETTA:324`».

**[M] La sostanza è VERA e la confermo:** `⟦S5b⟧` **non ha una scheda propria**. Le intestazioni
`###` della sezione B sono **dodici**, alle righe 42, 48, 54, 60, 66, 125, 132, 165, 194, 247, 298,
313, e nessuna è `⟦S5b⟧`. La sezione B si chiude a `⟦S6⟧` (`:313`).

⚠️ **Ma la localizzazione è sbagliata su due conti:**

- **«solo» non regge.** `⟦S5b⟧` rende **sette occorrenze su tre righe**: `:308` (una, dentro la
  scheda ⟦S5⟧), `:324` (quattro), `:326` (due). Controllo positivo con la stessa forma:
  `⟦S5x⟧` → cinque occorrenze su tre righe. La riga `:326` è del **18/08**, cioè dello stesso
  giorno del congedo, e il congedo non la nomina in quella frase.
- **`:324` non sta dentro la scheda ⟦S5⟧.** La scheda ⟦S5⟧ è `298-312`. La riga `324` sta in
  **Sezione C**, appesa alla riga d'ordine. È sì una marcatura *che parla di* ⟦S5⟧ — il suo titolo
  è «⟦S5⟧ SI È SPEZZATA IN TRE» — ma chi legge «dentro la marcatura di ⟦S5⟧» e va a cercarla
  nella scheda non la trova.

⇒ **[A]** Il difetto è lieve, ma è esattamente quello contro cui il congedo dedica una delle sue
tre risposte: un indirizzo che sembra puntare e non punta.

### R2 · Le due marcature del 18/08 non portano la dichiarazione anti-cascata — ma il danno non c'è, perché la dichiarazione è stata data dall'altra parte

**[M]** Il commit `44fea3e` ha aggiunto **due righe** alla SCALETTA (`+3 -1`, netto +2: da **348** a
**350** righe): una nella scheda ⟦S6⟧ (`:318`) e una in Sezione C (`:326`), più il bump di
intestazione.

**[M]** Nessuna delle due porta la formula `⛔ QUESTA RIGA SPOSTA DI … tutto ciò che la segue` che
**tutte** le marcature precedenti dello stesso file portano: `SPOSTA DI` rende **cinque** righe nel
file, e le due nuove non sono fra queste.

⚠️ **Ho verificato se questo ha rotto qualcosa, e la risposta è NO.** L'unica citazione **nuda**
(senza `@ <sha>`) a questo file con riga ≥ 318 è `SCALETTA_ATOMI_S6_2026-07-10.md:329`, in
`LIBRO_MASTRO_QBEATS.md:356` — e quella riga **dichiara lo spostamento e ha già pre-corretto il
numero**, verbatim: «riga **329, non 327**: questo stesso giro sposta quel contenuto di due, per le
due marcature che aggiunge più in alto nello stesso file; indirizzo dato già corretto per il file
come risulterà DOPO questo commit». **Verificato a bersaglio:** `SCALETTA:329` a HEAD è davvero
`1. "+" create → ⚠️ **SUPERATO da CD-Q7…** «NIENTE bottone morto … ora è VIETATO»`. Risolve.

⇒ **[A] Verdetto:** la disciplina anti-cascata è stata applicata, ma **da chi cita** invece che
**da chi sposta**. Il risultato oggi è corretto; il metodo è più fragile, perché funziona solo
finché chi sposta e chi cita sono la stessa persona nello stesso commit. È esattamente il metodo
che il congedo A101 rivendica come «nato oggi e mai inciso» — e questa è la sua prima applicazione
misurabile, riuscita.

### R3 · Un falso-positivo del mio primo filtro, dichiarato invece che nascosto

**[M]** Il mio primo passaggio sulle citazioni ha classificato **due** occorrenze di
`SCALETTA_ATOMI_S6_2026-07-10.md:297` in `LIBRO:342` come **nude**. È falso: sono **ancorate**, ma
in forme che la mia espressione non copriva — una è `…md:297 @` seguito dalle parole «stesso
commit» **fuori** dal backtick; l'altra è `…md:297` con l'ancora `@ 0ee9543d…` spostata dopo la
parola «entrambi». **Verificato a bersaglio:** a `0ee9543d45d638df061c5a48872aaefeb8a88f26` la riga
297 è `### ⟦S5⟧ QLiveShowDetailView (frame ③) + Start · POST · CI+DEVICE`. Ancorata, quindi immune,
e corretta.

⇒ **[A]** Lo scrivo perché è la classe di errore gemella del falso-zero già censito in casa: un
filtro troppo stretto che qui produce un **falso allarme** invece di un falso silenzio. La
controprova è la stessa: guardare il bersaglio, non fidarsi del conteggio.

**[M] Censimento risultante, per completezza** (citazioni a questo file nei cinque canonici):
**ancorate 9** (`:141`, `:297`×2, `:300`, `:314`×4, `:322`×3) · **nude 9** (`:8`×5, `:22`, `:144`,
`:219`, `:234`, `:329`). ⚠️ Delle nude, **solo `:329` sta sopra la soglia di spostamento di questo
commit** ed è quella verificata sopra. Le altre non sono state aperte: non erano nel mandato, e non
le dichiaro né sane né rotte.

### R4 · La gamba Drive di R-δ non ha un indirizzo unico per i referti

**[M]** Il mandato chiede di scrivere «nella cartella dei referti prevista dalle regole vigenti,
destinazione letta a fonte». L'ho cercata a fonte. **La regola non esiste.**

- ⛔ **Zero** occorrenze, su tutti e quattro i canonici, di qualunque frase che prescriva dove vanno
  referti o congedi (cercate le forme «i referti vanno/si scrivono/risiedono», «sede dei referti»,
  «cartella dei referti», «dove va il congedo»).
- **[M] Esiste solo un precedente di fatto, ed è fortissimo:** `HANDOFF/`. I canonici citano referti
  in quella forma **19** volte (LIBRO 12 · BUGS 5 · SCALETTA 2), sempre come
  `HANDOFF/MISURE_CC_<data>_<mandato>-<TITOLO>`. Su C: e su E: ci sono **70** referti `MISURE_CC_`
  per parte, **tutti** in `HANDOFF/`, senza una sola eccezione.

⚠️ **Ma la terza gamba di R-δ, Drive, è spaccata in due indirizzi, e la spaccatura è di oggi:**

| supporto | referti `MISURE_CC_` | dove |
|---|---:|---|
| C: (repo) | 70 | **tutti** in `HANDOFF/` |
| E: | 70 | **tutti** in `HANDOFF/` |
| Drive | 11 | `Il mio Drive/Qbeats/HANDOFF/` — nessuno del 18/08 |
| Drive | 8 | `Il mio Drive/Qbeats/` (radice) — **tutti e otto del 18/08** |

**[M]** Su Drive, l'intero lotto del 18/08 — gli otto referti A90-A99, la roadmap, i due DIFF e il
congedo A101 — sta nella **radice** `Qbeats/`, mentre gli undici referti più vecchi stanno in
`Qbeats/HANDOFF/`.

⇒ **[A] Decisione mia, dichiarata:** non esistendo una regola scritta, seguo il **precedente più
recente e omogeneo**, cioè quello dei suoi undici fratelli di giornata: questo referto va nella
radice `Qbeats/` su Drive, e in `HANDOFF/` su C: e su E:. ⚠️ **Registro che è una scelta, non
un'applicazione:** se Mauro o il referee preferiscono `Qbeats/HANDOFF/`, il file va spostato e con
lui i dodici del 18/08. **La decisione di quale sia l'indirizzo giusto non è tecnica e non è mia.**

⚠️ Questo conferma — misurandolo, non riportandolo — il debito già registrato il 07/08:
**nessuna regola scritta dice dove vanno congedi e referti.** È rimasto aperto undici giorni e oggi
ha prodotto il suo primo effetto visibile.

### R5 · Quello che ho verificato del congedo A101 e che REGGE

Perché il ritiro in testa non venga letto come sfiducia generale: **ho rimisurato dodici valori
meccanici del congedo e coincidono tutti** (tabella in B1.4). Reggono inoltre, verificati da me:

- **[M]** `HANDOFF/**` è `-text`: `git check-attr text` → `text: unset`. Disco e blob coincidono,
  una faccia sola. La premessa delle sue impronte è corretta.
- **[M]** A97 e A100 rendono **zero** su entrambi i supporti; A98 rende **uno** per parte, ed è la
  menzione dentro il referto A99, non un artefatto. La tabella degli ID è corretta.
- **[M]** `⟦S5b⟧` non ha scheda propria: dodici intestazioni `###` in sezione B, nessuna è la sua.
  La conclusione centrale del congedo — **il cardine non ha nemmeno una scheda** — è vera.

---

## RIEPILOGO

| blocco | esito |
|---|---|
| **ritiro** | Ritirata l'affermazione falsa «quel congedo l'ho scritto io». Congedo A101 trattato come claim, non come eredità |
| **aggancio** | A102 libero. L'unica occorrenza è la cella del congedo che lo dichiara libero — autoriferimento non dichiarato, innocuo |
| **B1** | HEAD locale=remoto `44fea3e3…735b`, tracciati puliti. Tre workflow, non due. F1 fermo dal 31/07 con due failure. Cinque impronte da blob. **Dodici valori confrontati col congedo: coincidono tutti, nessuna divergenza** |
| **B2** | Scheda `⟦S5⟧` verbatim, righe 298-312, confini misurati. 13 bullet: 7 campi, 4 marcature, 2 vincoli |
| **B3** | Scheda `⟦S4L⟧` verbatim, righe 247-297. **Quattro campi in comune** (`Scopo`, `File`, `Reversibilità`, `Gate`), **in ordine diverso** e con `Gate` in due forme. `Cond` e `OPEN` mancano in ⟦S4L⟧; `Dipendenze` manca in ⟦S5⟧ |
| **B4** | Sezione C verbatim, righe 322-327. **Sei righe.** L'ordine sta su **una** riga che si dichiara sede unica, più **tre** marcature che non la riscrivono: la catena reale va ricomposta da quattro righe |
| **R1** | Il congedo localizza male `⟦S5b⟧`: non è «solo» (7 occorrenze su 3 righe) e `:324` sta in Sezione C, non nella scheda ⟦S5⟧. **La sostanza — nessuna scheda — è vera** |
| **R2** | Le due righe nuove del 18/08 non portano la dichiarazione anti-cascata, ma **nessun puntatore è rotto**: `LIBRO:356` ha pre-corretto `SCALETTA:329`, verificato a bersaglio |
| **R3** | Falso-positivo del mio primo filtro sulle citazioni, dichiarato e corretto: i due `:297` sono ancorati, non nudi |
| **R4** | **Nessuna regola scritta dice dove vanno i referti.** Solo precedente (`HANDOFF/`, 19 citazioni, 140 file). Su Drive il lotto del 18/08 sta in radice, i più vecchi in `HANDOFF/`: gamba spaccata, decide Mauro |
| **R5** | Dodici valori meccanici del congedo rimisurati e confermati. `-text` su `HANDOFF/` confermato. Tabella ID confermata |

⛔ Nessuna azione eseguita oltre la misura e questo referto, come da perimetro: zero righe sotto
`ios_app/`, zero commit, zero push, HEAD invariato.

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma del congedo A101, e per la stessa ragione dichiarata: **lo sha256 del file
completo non può stare dentro il file**, perché inciderlo lo cambia. Si incide lo sha del **CORPO**
(tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`), che è stabile; lo sha del file
intero vive nel messaggio di consegna, come prescrive `LIBRO` R7 §1 («sha256 = trasporto, non
puntatore»).

Le impronte si riferiscono alla **faccia disco**, che qui è anche l'unica: `git check-attr text` su
`HANDOFF/**` → `text: unset` (`-text`), disco e blob coincidono.

- **sha256 del CORPO** (fino al marcatore, escluso): `08c27a87d5aa0888fb778e401187a901c60577ba21471ef759166c486c075a35`
  Riproducibile: `python -c "import hashlib,io; t=io.open(FILE,encoding='utf-8',newline='').read(); print(hashlib.sha256(t[:t.find('## IMPRONTE DI QUESTO REFERTO')].encode()).hexdigest())"`
- **byte** (file completo): `48892`
- **righe** (file completo): `499`
- **CR** (0x0D, contati sui byte, mai con grep): `0`

---

*A102-TRE-VERBATIM-FINE*
