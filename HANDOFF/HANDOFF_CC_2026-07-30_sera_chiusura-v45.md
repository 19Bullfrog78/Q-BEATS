================================================================================
HANDOFF CC — 2026-07-30 sera — CHIUSURA v45 (LIBRO v45 + BUGS v45 committati)
================================================================================
Scritto da CC a chiusura sessione, ore 19:05 del 30/07/2026 (orologio macchina,
`date`). Per la PROSSIMA sessione CC.

⛔ NON sostituisce `HANDOFF/HANDOFF_CC_2026-07-30_sera.md`, che è di stamattina
   — scritto PRIMA dei due commit e PRIMA del giro sulla pendenza E3. Quel file
   NON è stato toccato (verificato: sha256 `a49522e2…ddaa`, 467 righe, 31215
   byte). Se i due divergono, quello vecchio racconta un mondo precedente ai
   commit di oggi: si legge come storia, non come stato.

Scritto ALLA CIECA: il referee ha scritto il proprio handoff senza vedere
questo, e non mi ha comunicato le proprie misure di proposito. Due misuratori
su due superfici diverse — lui il Progetto Claude, io il repo, E: e il codice —
che si incrociano solo dopo. Non ho tentato di ricostruire cosa abbia scritto,
e non ho scritto nulla in funzione del suo.

════════════════════════════════════════════════════════════════════════════════
(0) ISTRUZIONE AL ME STESSO DI DOMANI — LEGGERE PRIMA DI TUTTO
════════════════════════════════════════════════════════════════════════════════

**NULLA DI QUANTO SEGUE È EREDITABILE.** Ogni numero qui dentro è vero al
momento in cui l'ho misurato e in nessun altro momento. Il primo atto della
sessione nuova è **R1: ricalcolare tutto a fonte** — HEAD, impronte, CI,
versioni — e solo dopo confrontare con questo documento.

Questo handoff **racconta una storia**. Quello entrante **la verifica**. Se un
numero qui non torna, il numero giusto è quello che misuri tu, non quello che
leggi qui. E la divergenza è essa stessa un dato: significa che qualcosa si è
mosso, o che io ho sbagliato — vedi la sezione (G), che oggi è lunga.

**Marcatura, e non barare sul confine:**
- **[V]** = misurato da me, in questa sessione, con la fonte accanto.
- **[R]** = riferito, ereditato, o misurato da altri. Non rimisurato da me.

Oggi un **[R] travestito da [V]** ha prodotto il falso «xcodegen: zero
occorrenze in BUGS v44» — falsificato dal referee, che ne ha trovata una a
`r.698`. Il meccanismo: avevo letto quella misura in un handoff e l'avevo
trattata come acquisita. **Ereditare una misura senza rifarla la trasforma in
un [V] falso.**

════════════════════════════════════════════════════════════════════════════════
(A) HEAD E I DUE COMMIT DI OGGI — tutto [V], misurato in chiusura
════════════════════════════════════════════════════════════════════════════════

**HEAD = origin/master = `897d458e0777c2edbce349e4b0001c7c2c50c9b9`**
(con `git fetch origin master` prima del confronto, non un `rev-parse` locale
dato per buono).

| # | sha40 | subject | %b | trailer | file |
|---|---|---|---|---|---|
| 1 | `316456465a6adaebc5116bf5bbe20809c51b53e7` | LIBRO v45: colonna data di Sez.2 e registro = INDIRIZZO non data - 2 regole ratificate, zero righe storiche corrette | **1 byte** | vuoto | 1 |
| 2 | `897d458e0777c2edbce349e4b0001c7c2c50c9b9` | BUGS v45: blocco 1.5 Prerequisiti di distribuzione (5 ticket) + 4 ticket nuovi 1.3 + 2 allargati + rimando incrociato TD#32 | **1 byte** | vuoto | 1 |

Entrambi: **autore = committer = Mauro Martintoni `<di_tutto@icloud.com>`**,
`%aI` = `%cI`, `grep -ci "co-authored"` sul messaggio pieno → **0** (controllo
positivo dello stesso grep su stringa presente: «LIBRO» → 1, «BUGS» → 1 — il
comando conta, lo zero è vero).
Date: `2026-07-30T17:49:27+02:00` e `2026-07-30T17:53:28+02:00`.
Diffstat: #1 `1 file changed, 4 insertions(+), 2 deletions(-)` · #2 `1 file
changed, 101 insertions(+), 4 deletions(-)`.

⚠️ **Le date dei commit sono il 30/07 VERO** (orologio macchina 30/07, letto
con `date` prima di scrivere). È la prima applicazione della regola ratificata
in v45 stessa: *la data si scrive dall'orologio della macchina che committa*.
In v44 non era così — quel commit è del 29 e porta righe datate 30.

**LE DUE CI — sha a 40 caratteri, MAI il corto** (col corto `gh run list
--commit` rende `[]` con exit 0, falso-zero, BOX3 V99 (d)):

```
$ gh run view 30558601729 --json conclusion,status,headSha,headBranch,workflowName
{"conclusion":"success","databaseId":30558601729,"headBranch":"master",
 "headSha":"316456465a6adaebc5116bf5bbe20809c51b53e7","status":"completed",
 "workflowName":"iOS Signed Build"}          → run #599, LIBRO v45

$ gh run view 30558905744 --json conclusion,status,headSha,headBranch,workflowName
{"conclusion":"success","databaseId":30558905744,"headBranch":"master",
 "headSha":"897d458e0777c2edbce349e4b0001c7c2c50c9b9","status":"completed",
 "workflowName":"iOS Signed Build"}          → run #600, BUGS v45
```

`headSha` coincidente col rispettivo commit su entrambe. **Ordine R-γ
rispettato**: LIBRO prima, BUGS **solo dopo CI 1 verde** — perché BUGS cita in
avanti la regola di LIBRO v45 (ticket `TD-censimento-e-cartella-annidata`), e
invertire avrebbe fatto atterrare una citazione a una ratifica inesistente.

**METODO DI VERIFICA PRE-PUSH, e vale la pena riusarlo.** Invece di rileggere a
occhio 20 e 51 KB di diff, ho verificato che **il diff in staging fosse
byte-identico all'artefatto ratificato**:
`sha256(git diff --cached)` = `788beeff…5c38` (LIBRO) e `b726b1d1…d5ed` (BUGS),
identici agli sha256 degli artefatti che il referee aveva ratificato; e gli OID
in cache erano quelli ratificati. Staging **file-by-file**, mai `git add -A`.
Pre-volo: nessun hook attivo (solo i 14 `.sample`), `commit.gpgsign` non
impostato, `commit.template` non impostato.

⚠️ Reperto minore ma utile: il diff di BUGS in staging è risultato **identico
al byte** all'artefatto generato contro `4d1f974`, pur essendo HEAD nel
frattempo passato a `3164564`. Il commit di LIBRO non ha spostato di un byte il
diff di BUGS.

════════════════════════════════════════════════════════════════════════════════
(B) IMPRONTE DEI CANONICI A HEAD — tutto [V]
════════════════════════════════════════════════════════════════════════════════

| file | versione | sha256(disco) | byte(disco) | righe | CR | OID blob | byte(blob) | --eol |
|---|---|---|---|---|---|---|---|---|
| `LIBRO_MASTRO_QBEATS.md` | **45 (30/07/2026)** | `7ce1c1dd…46eb92` | 185662 | 473 | **473** | `786c231e…4b60` | 185189 | `i/lf w/crlf` |
| `BUGS_QBEATS.md` | **45** | `3032ed6a…36c9af` | 251089 | 1008 | **1008** | `fc571fbd…d0cb` | 250081 | `i/lf w/crlf` |
| `BOX3_QBEATS.md` | **V99 — 2026-07-22** | `c728bacc…` | 89457 | 803 | **0** | `490d6d9b…` | 89457 | `i/lf w/lf` |
| `BOX5_QBEATS.md` | **V28 — 28/07/2026** | `cf425ff0…` | 57158 | 596 | **0** | `21b23d62…` | 57158 | `i/lf w/lf` |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | **3 (28/07/2026)** | `700d7caa…` | 35661 | 333 | **0** | `533ea562…` | 35661 | `i/lf w/lf` |

sha256 e OID interi dei due toccati oggi:
- LIBRO disco `7ce1c1dd0982455bad6535995524328af040c3a63f64cdcb91ca107bdc46eb92` · blob `786c231eb73f4f073fdbd6699e63705079ec4b60`
- BUGS  disco `3032ed6a35b83c04a9e5057841b9b30f81588fdfc6b858b62d364921e936c9af` · blob `fc571fbd7b9fc82eafb1866d0d06bed29bf0d0cb`

**L'identità delle due facce chiude su entrambi:** disco = blob + CR.
185662 = 185189 + 473 · 251089 = 250081 + 1008. **Chi confronta un'impronta DEVE
dichiarare da quale faccia viene**, o il confronto non significa nulla.
BOX3/BOX5/SCALETTA hanno **una faccia sola** (CR=0, disco = blob) — e il
controllo positivo è nella stessa tabella, perché la stessa forma di comando
rende 473 e 1008 sugli altri due.

════════════════════════════════════════════════════════════════════════════════
(C) WORKING TREE E WORKTREE (R8) — [V]
════════════════════════════════════════════════════════════════════════════════

`git status --porcelain -uno` → **vuoto**. Controllo positivo stessa forma:
`git status --porcelain` nudo → **67 righe**, tutte `??`. Il comando funziona,
lo zero è un'assenza vera.
Delle 67: 65 in `HANDOFF/` (compresi i 3 artefatti di diff di oggi e **questo
file**, che si conta da sé) + 2 piani in root (`QBEATS_A5C_PIANO_2026-07-04.md`,
`QBEATS_ATOMC_PIANO_2026-07-06.md`).
⚠️ Chi rimisura DOPO che un handoff è stato scritto trova un numero diverso da
chi misura prima. Non è una discrepanza: è lo stesso fenomeno già visto due
volte (59 vs 60, 63 vs 64).

**Worktree dichiarati (R8):**
```
C:/Users/BULLFROG/Desktop/ANTIGRAVITY/Q-BEATS   897d458 [master]
C:/Users/BULLFROG/qb_fixB                       add556f [test/bug2b-test7-fixtures]
```
Il secondo è il worktree del debito «12 branch non-merged». Non toccato oggi.

════════════════════════════════════════════════════════════════════════════════
(D) PROPAGAZIONE SU E: — [V], e il metodo conta quanto il risultato
════════════════════════════════════════════════════════════════════════════════

«pushato ≠ propagato». Due stampe, **faccia BLOB (LF)**, nome per-versione
ancorato al commit:

```
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\LIBRO_MASTRO\
    LIBRO_MASTRO_QBEATS_V45_2026-07-30_3164564.md
    185189 byte · 473 righe · CR 0
    sha256 dd3f440510937e2e97c5a71ce7fc9582bfdfbbcd28cf854691ca164b667e465d

E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\BUGS_QBEATS\
    BUGS_QBEATS_V45_2026-07-30_897d458.md
    250081 byte · 1008 righe · CR 0
    sha256 1f310f4a4bbb2cd7968217af576dcc817a3e801f8b4329faece80b14cfa9c43d
```

**METODO — due controlli, non uno.** (1) sha256 della stampa confrontato con
sha256 di `git show <commit>:<path>`, **mai col disco**: coincidono su entrambe.
(2) `cmp` byte-a-byte fra lo stdout di `git show` e il file scritto: `cmp OK`
su entrambe. ⚠️ Il secondo non è ridondante: **su una scrittura troncata lo
sha256 sarebbe vero e passerebbe verde lo stesso** — l'impronta prova che il
file è QUELLO, non che è INTERO.

Le serie proseguono senza buchi: LIBRO V43 → V44 → **V45**; BUGS V44 → **V45**.

**IGIENE [4] — eseguita come SOLA LETTURA, e non era un'omissione.**
Pre-controllo e post-controllo sotto `FILE X CLAUDE.MD\`, ricorsivi:
- `BUGS_QBEATS.md` a nome vivo → **0** (già ripulite il 30/07 mattina)
- `LIBRO_MASTRO_QBEATS.md` a nome vivo → **1**, ed è
  `DA_CD_PER_CC\11_07_2026\1Q-BEATS\uploads\` — **il reperto di consegna che va
  escluso**
- controlli positivi stessa forma: `BUGS_QBEATS43.md` → 1 ·
  `HANDOFF/REFEREE_SYNC_2026-07-13/` → 3 file
⇒ **Non c'era una sola copia legittima da rimuovere. Zero cancellazioni.**
Entrambi i reperti intatti. Segnalato PRIMA di agire, non dopo: un'igiene
eseguita «perché era in lista» qui avrebbe distrutto un reperto.

**[R] — non fatto da me, da ricordare a Mauro:** il caricamento delle due
stampe nel Progetto Claude. Path e impronte sono quelli sopra.

════════════════════════════════════════════════════════════════════════════════
(E) LE MISURE SULLA PENDENZA E3 — VIVONO SOLO QUI. SE NON SI INCIDONO, MUOIONO
════════════════════════════════════════════════════════════════════════════════

È la parte che pesa di più. **Zero righe di questo materiale sono in
BOX3/BOX5/BUGS/LIBRO.** Stabilisce che il pericolo del runner **nasce con
⟦S4R⟧, non con ⟦S4L⟧** — cioè al PROSSIMO atomo, non a uno lontano.

--------------------------------------------------------------------------------
**E.1 — ANCORA DEL CODICE, e attenzione perché è una distinzione che morde**
--------------------------------------------------------------------------------
**[V]**, misurato in chiusura:
- ultimo commit che tocca **`ios_app/`** → **`6c7352a1`** (DARK-DECL,
  `project.yml` +5). `git diff --stat 6c7352a1..HEAD -- ios_app/` → **0 righe**;
  controllo positivo, `b9f4e5f..6c7352a1` → `1 file changed, 5 insertions(+)`.
- ultimo commit che tocca **`ios_app/**/*.swift`** → **`b9f4e5f`** (⟦S4K⟧).
  `git diff --stat b9f4e5f..HEAD -- "ios_app/**/*.swift"` → **0 righe**;
  controllo positivo, `6ded4ab..b9f4e5f` → `5 files changed, 115 insertions(+),
  9 deletions(-)`.

⚠️ **Le due ancore NON coincidono, e io ci ho sbattuto contro oggi** (vedi G.6).
È esattamente la distinzione che LIBRO v44 ha disambiguato in Sez.5: «commit di
CODICE» = ogni commit che cambia il **prodotto costruito**, qualunque file
tocchi sotto `ios_app/`, **NON** «commit che tocca un `.swift`».
⇒ **Per le misure sulle viste, l'ancora è `b9f4e5f`. Per lo stato del prodotto,
è `6c7352a1`.** Chi le scambia scrive una falsità.

--------------------------------------------------------------------------------
**E.2 — IL RUNNER NON ESISTE NEL BUILD CORRENTE. Quattro misure indipendenti.**
--------------------------------------------------------------------------------
Tutte **[V]**, sul blob a HEAD, notazione **righe-che-contengono** salvo dove
detto.

1. **Un solo sito di nascita del runner:** `= SetlistRunner(` → **1**, ed è
   `ios_app/QBeats/UI/LiveRootView.swift:12`, `@StateObject`. ⇒ la vita del
   runner È la vita di `LiveRootView`.
2. **`LiveRootView` ha ZERO call-site.** ⚠️ Il grep grezzo di `LiveRootView(`
   rende **1**, ma è `QLiveRootView(` — **`LiveRootView(` ne è sottostringa**.
   Filtrando: **0**. Controllo positivo stessa forma: `QLiveShowsView(` → **1**
   (`QLiveRootView.swift:61`). ⇒ `LiveView(`, montato solo da
   `LiveRootView:18`, è a sua volta irraggiungibile.
3. **Due rami su tre sono vuoti.** `QLiveRootView.swift:58-66`: `.shows` →
   `QLiveShowsView` · `.detail` → `EmptyView()` · `.metronome` →
   **`EmptyView()`**. Conteggio `EmptyView()` nel file → **2**; controllo
   positivo `case ` → **4**.
4. **Il funnel di navigazione ha ZERO chiamanti.** `navigate(to:` → 1 hit, ed è
   il **commento** a `:14`; la definizione è a `:54`
   (`func navigate(to newPage:`). Chiamanti reali: **0**. `page = ` compare
   **una volta**, a `:55`, dentro il funnel stesso.
   Il file lo dichiara da sé a `:53`: «A S4b ha **zero chiamanti** (la porta è
   installata per S5/S6)».
5. **L'altro ingresso non porta scaletta.** `HomeRootView.swift:48` monta
   `ContentView()` dentro `.fullScreenCover` sotto `#if DEBUG` (`:45-56`).
   `ios_app/QBeats/ContentView.swift`: 100 righe, `setlist` (insensibile) →
   **0**; controllo positivo `AudioEngine` → **1**. È il vecchio metronomo
   standalone.

**Verbatim dal codice, `QLiveRootView.swift:26-27`, che lo dice da sé:**
> ««mai il player senza runner iniettato» RESTA IN VIGORE: a S4b il player
> **NON è montato affatto** (ramo `.metronome` = EmptyView).»

--------------------------------------------------------------------------------
**E.3 — LE TRE RISPOSTE SECCHE**
--------------------------------------------------------------------------------
- **(a) Oggi, uscendo dalla stanza col click attivo, si perde il punto della
  scaletta? → NON OSSERVABILE.** Non esiste un punto di scaletta da perdere.
  ⚠️ Resta invece **presente** l'ALTRO difetto, già ticketato 🔴 in §1.1: uscire
  da `.qLive` esegue `audioEngine.stop()` (`AppRootView.swift:73-75`), che con
  Link è uno stop di **banda**. Sono due cose diverse; morde solo la seconda.
- **(b) Oggi, navigando DENTRO Q-Live? → NON OSSERVABILE.** La navigazione
  interna non avviene: funnel a zero chiamanti, due rami `EmptyView()`.
- **(c) Dopo ⟦S4R⟧/⟦S4L⟧? → il pericolo nasce con ⟦S4R⟧.** La scheda ⟦S4R⟧ lo
  scrive già, con la conseguenza di palco — `SCALETTA:215-218`, verbatim:
  > «oggi `SetlistRunner` è `@StateObject` in `…/LiveRootView.swift:12-13` … →
  > muore al pop, mentre `audioEngine` sopravvive; al rientro nascerebbe un
  > runner FRESCO (canzone 1) col click già avanti = **UI e clock divergenti sul
  > palco**.»

⚠️ **E L'ENUNCIATO STESSO VA RILETTO.** Dice «da ⟦S4L⟧ in poi», ma per la regola
ratificata in `LIBRO:317` — «se l'oggetto è il **launcher, il runner, il suo
ciclo di vita o la sua proprietà** … si legge **⟦S4R⟧**» — la lettura corretta è
**«da ⟦S4R⟧ in poi»**, e ⟦S4R⟧ è **il prossimo atomo**.

--------------------------------------------------------------------------------
**E.4 — LIMITE DICHIARATO DA ME, non scoperto da altri**
--------------------------------------------------------------------------------
Ho misurato la **struttura di montaggio**, **non ogni percorso a runtime**. Non
ho provato che sia impossibile trovarsi in `.qLive` con un click attivo
passando dal ramo DEBUG. Le conclusioni di E.2/E.3 valgono su ciò che ho
misurato e non oltre.

--------------------------------------------------------------------------------
**E.5 — SOSPETTO DA VERIFICARE, NON UNA CONCLUSIONE**
--------------------------------------------------------------------------------
`TD-qlive-exit-unconfirmed-stop` (§1.1, 🔴 BLOCCANTE) descrive una «metà
PRE-ESISTENTE» in cui «nel build attuale (`f8276f6`) Q-Live apre **dritta nel
metronomo**». **[V]**: `f8276f6` è anteriore al flip S4b, e a HEAD la root di
Q-Live è `QLiveShowsView` col player non montato (E.2). ⇒ **Quella metà
potrebbe essere stale.** ⛔ Non l'ho misurata: è fuori dal mandato del giro, e
un ticket 🔴 BLOCCANTE non si declassa per inferenza. **Va misurato a parte,
prima che qualcuno lo usi per dimensionare un atomo.**

════════════════════════════════════════════════════════════════════════════════
(F) LE QUATTRO DESTINAZIONI PER L'ENUNCIATO — precedenti misurati, non opinioni
════════════════════════════════════════════════════════════════════════════════

⚠️ **PREMESSA CHE RIBALTA LA DOMANDA, e nasce da un mio errore (G.5).**
L'enunciato **NON è senza casa**. Vive in **tre** posti canonici, tutti **[V]**:
- `LIBRO:285`, riga `2026-07-18` — la ratifica («muore SOLO all'uscita dalla
  STANZA Q-Live»)
- `LIBRO:317`, riga `2026-07-28` — **l'assegnazione a un atomo**, verbatim:
  «⟦S4R⟧ launcher: … + **proprietà del runner** (decisione Mauro 18/07,
  `BOX3:30`, qui trasportata: **prima viveva solo in un commento BOX3, ora ha
  casa in un atomo**)»
- `SCALETTA:212-221` — **il vincolo operativo dentro la scheda ⟦S4R⟧**, col
  meccanismo e la conseguenza di palco
⇒ **Non è E3.** E3 = «vive solo in chat/handoff e non atterra in un canonico».
Questa è atterrata tre volte. Ciò che è vero è più stretto: **non ha un ticket
in BUGS**.

**(A) TICKET BUGS CHE DORME — il precedente esiste, e sono DUE.** [V]
| ticket | trigger | sezione | severità mentre dorme |
|---|---|---|---|
| `TD-follower-stop-propaga` (r.146) | r.155 «se Start/Stop Sync risulta ATTIVO … la severità **sale a 🔴 ALTA**» | **§1.2** | r.157: «🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE. **Latente** …» |
| `TD-qlive-search-keyboard-trap` (r.345) | r.349 «all'apertura di ⟦S4L⟧ la severità sale a 🔴 ALTA» | **§1.2** | oggi 🟡 residuo (era 🟠) |
Conteggi: «TRIGGER DI RIVALUTAZIONE» → 1, «Trigger di rivalutazione» → 1 (due
in tutto); controllo positivo «Stato:» → **51**. ⇒ Lo schema esiste, sta sempre
in **§1.2**, e la severità dormiente è **🟠 con la parola «latente» esplicita**.

**(B) VINCOLO NELLA SCHEDA — È GIÀ FATTO.** [V]
La SCALETTA ospita vincoli di costruzione: `VINCOLO` → 1 · `INVARIANTE` → 1 ·
`⛔` → 2 · `VIETATO` → 1 · `obbligatorio` → 4 (controllo positivo `S4L` → 24 su
333 righe).
E **BOX3 V99 (e)** — `BOX3:34`, «**VINCOLO TECNICO S4L da incidere.** Un
`ObservableObject` ANNIDATO dentro un altro NON propaga…» — **è stato inciso**:
sta verbatim nella scheda ⟦S4R⟧ a `SCALETTA:204-207`, con l'ancora al blob.
⇒ **Il pattern ha un precedente riuscito su un vincolo adiacente.**
⚠️ **Ma la scheda porta una pendenza dichiarata**, `SCALETTA:219-221`:
> «Il re-instradamento è **lettura di CC, non una nuova ratifica: da confermare**
> quando lo sdoppiamento verrà inciso in LIBRO.»
**Lo sdoppiamento È stato inciso** (LIBRO v43, riga `2026-07-28` = `LIBRO:317`,
che ratifica la regola di rilettura). **La condizione è scattata il 28/07 e
nessuno ha tolto il «da confermare».**

**(C) DOMANDA CD IN Sez.4 — non c'è, ma l'attesa a CD esiste altrove.** [V]
Sez.4 (r.352-403, 53 righe, 5 intestazioni): «uscita» → 0 · «uscire» → 0 ·
«STOP-con-conferma» → 0 · «overlay» → 0 · «freeze atteso» → 0. Controllo
positivo «CD» → **25**.
Ma `LIBRO:286`, Sez.2, riga `2026-07-18`, stato **`attiva`**:
> «**Uscita-stanza col click attivo = STOP con conferma (CD, opzione iii)** …
> il **FREEZE del disegno è ATTESO da CD** … **Nessuna implementazione prima
> del freeze.**»
Confermato anche da `BUGS:125`. ⇒ La richiesta a CD c'è, ma vive come
**direzione ratificata con freeze atteso in Sez.2**, non come domanda in Sez.4.
**Attesa dal 18/07 — dodici giorni.**

**(D) QUARTA OPZIONE, emersa dalle misure e non nella lista del referee.**
**Non aggiungere niente: confermare un re-instradamento la cui condizione è già
scattata.** Costo: una riga in un file. Nessuna copia nuova.
⚠️ Unico punto da decidere, non da assumere: `LIBRO:317` cita la SCALETTA «sez.
B, **versione 3**». Bumpare la SCALETTA a v4 rende quella citazione storica —
per la regola v45 è una **chiave d'indirizzo congelata**, quindi non si rompe,
ma va deciso esplicitamente.

**COSTI, per ciascuna** [V]:
| | file | rompe puntatori? | se non si fa nulla, chi se ne accorge e quando |
|---|---|---|---|
| (A) | 1 (BUGS) | No, additivo. ⚠️ Crea la **quarta** copia dello stesso enunciato — ciò contro cui la riga `2026-07-30` INDIRIZZO, NON COPIA mette in guardia | Nessuno: il vincolo è già dove serve. Serve solo a chi cerca in BUGS invece che nella SCALETTA |
| (B) | 1 (SCALETTA) — contenuto già presente | vedi (D) | **Chi costruisce ⟦S4R⟧, cioè il prossimo atomo** |
| (C) | 1 (LIBRO) | No, additivo. ⚠️ Duplica in parte l'attesa di `LIBRO:286` | CD, mai: il freeze è atteso da 12 giorni |
| (D) | 1 (SCALETTA) | vedi sopra | idem (B) |

⚠️ **IL RISCHIO VERO, e non è quello che sembra.** Non è che l'enunciato si
dimentichi: chi costruisce ⟦S4R⟧ legge la scheda e lo trova. È che lo trova
**marcato «lettura di CC, non una ratifica»** — e lo tratti come non
vincolante. Il difetto non è l'assenza: è la **qualifica di provvisorietà
rimasta accesa su una pendenza chiusa**.

════════════════════════════════════════════════════════════════════════════════
(G) DOVE HO SBAGLIATO IO — con il MECCANISMO, non solo il fatto
════════════════════════════════════════════════════════════════════════════════

**G.1 — Due controlli positivi che hanno reso 0, cioè erano invalidi.**
(i) Su `QLiveKit.swift` ho scelto `grep -c "struct"` come controllo positivo: ha
reso **0** perché il file contiene un `enum`, non uno `struct`. (ii) Analogo su
un altro conteggio. **Meccanismo: un controllo positivo scelto per abitudine e
non per conoscenza del bersaglio non è un controllo — è un secondo zero.**
Rimedio applicato: sostituito col controllo massimo (il file intero, 17 righe)
più due controlli validi (`QLive` → 2, `Color` → 5).
✅ **Intercettato da me**, prima di consegnare.

**G.2 — 89 LF nudi che stavano per entrare in un canonico a due facce.**
I pezzi scritti nello scratchpad avevano terminatori LF; infilarli in
`BUGS_QBEATS.md` (CRLF su disco) avrebbe prodotto un file a terminatori misti.
Lo script l'ha reso: `LF nudi: 89` contro 0 attesi. **Meccanismo: lo strumento
di scrittura ha una convenzione diversa dal file di destinazione, e nessuno dei
due lo dichiara.** Rimedio: normalizzazione LF→CRLF + guardia che aborta se
restano LF nudi o se un pezzo termina con un fine-riga.
✅ **Intercettato dalla contabilità dello script**, file mai promosso.

**G.3 — Due titoli markdown che non si sarebbero renduti.**
`### TD-qlive-token-text2r-non-onorato` e `## 🚢 1.5` seguivano DIRETTAMENTE un
elemento di lista e un paragrafo, senza riga vuota: in markdown non si rendono
come titoli. **Meccanismo: la stessa operazione — «inserire prima di
un'ancora» — richiede CRLF **doppio** prima di un titolo e CRLF **singolo**
prima di una riga di tabella. Una regola sola applicata a due casi opposti.**
✅ **Intercettato** perché ho ispezionato le giunzioni invece di fidarmi del
conteggio byte, che tornava già.

**G.4 — Ho dichiarato 184686 byte per un file che ne pesava 185662.**
Ho pescato la dimensione dal **backup del turno precedente** invece che dal file
vero; l'output dei comandi diceva 185662. Il referee l'ha falsificato con
un'aritmetica: su `w/crlf` il disco è SEMPRE blob + una riga di CR, e **un disco
più piccolo del proprio blob non esiste**. **Meccanismo: nel referto in prosa ho
trascritto un numero da una fonte diversa da quella che avevo misurato. La
misura era giusta, la relazione era rotta.**
❌ **NON intercettato da me.**

**G.5 — Ho affermato «è E3» e l'ho falsificato io stesso, DOPO il commit.**
In BUGS v45 r.355 ho scritto che l'enunciato «resta senza casa» ed «è E3».
Misurato il giro dopo: vive in `LIBRO:285`, `LIBRO:317` e `SCALETTA:212-221`.
**Meccanismo: ho misurato correttamente l'assenza in BUGS e ho concluso
l'assenza ovunque. Un perimetro di ricerca scambiato per l'universo.** È la
stessa forma del difetto che ho ticketato lo stesso giorno
(`TD-censimento-e-cartella-annidata`: «un censimento va dichiarato insieme al
PERIMETRO che ha spazzato»). L'ho scritto in un ticket e commesso in un altro
file, lo stesso giorno.
❌ **NON intercettato prima del commit.** ⛔ **Va corretto nel giro prossimo.**

**G.6 — Etichetta hardcoded che contraddiceva il proprio output.**
Nel giro E3 ho stampato `[diff ios_app/ b9f4e5f..HEAD sopra: VUOTO]` — ma
l'output immediatamente sopra mostrava `ios_app/project.yml | 5 +++++`.
**Meccanismo: ho scritto l'etichetta con l'esito che mi aspettavo, prima di
leggere l'esito reale. Un `echo` non è una misura, ma sembra identico a una
misura nel referto.**
✅ **Intercettato in chiusura**, rimisurando per scrivere questo handoff. Ancore
corrette in E.1. ⚠️ Le conclusioni di E.2/E.3 **non cambiano** (riguardano
`.swift`, fermi a `b9f4e5f`), ma l'ancora dichiarata era sbagliata.

**G.7 — [R] travestito da [V]: «xcodegen zero occorrenze».**
Ereditato da un handoff e trattato come acquisito. Ce n'è **una**, `r.698`,
causa root di TD#44. ❌ **Falsificato dal referee.** Vedi la sezione (0).

--------------------------------------------------------------------------------
**QUALI DIFESE HANNO FUNZIONATO — serve saperlo quanto gli errori**
--------------------------------------------------------------------------------
Hanno **retto**: la contabilità byte dello script (G.2), l'ispezione delle
giunzioni invece del solo conteggio (G.3), la rimisura in chiusura (G.6), il
`cmp` oltre lo sha256 in propagazione, e il confronto
`sha256(git diff --cached)` **contro l'artefatto ratificato** invece della
rilettura a occhio.
Hanno **ceduto**: la trascrizione a mano dei numeri nel referto in prosa (G.4),
e il salto dal perimetro misurato alla conclusione universale (G.5). **Entrambi
i cedimenti sono avvenuti in PROSA, non nei comandi.** I comandi non hanno
mentito una volta; il racconto dei comandi sì, due volte.

════════════════════════════════════════════════════════════════════════════════
(H) DOVE HA SBAGLIATO IL REFEREE — si incide, non si tace
════════════════════════════════════════════════════════════════════════════════

**Il referee ha RATIFICATO la frase «è E3».** Il testo di r.355 gli è stato
consegnato **verbatim** nel diff, con quella frase dentro, e ha ratificato. Non
l'ha vista. Poi, nel giro successivo, ha chiesto lui stesso di verificare il
ticket ospite — ed è quella richiesta che ha fatto emergere la falsità.

**Non è un rimprovero, è un dato di metodo:** il cancello del referee ha
lasciato passare un'affermazione falsa **su un documento che aveva letto per
intero**, e l'ha intercettata solo quando ha cambiato domanda. ⇒ **La revisione
del diff cattura ciò che è scritto male, non ciò che è scritto bene ma è
falso.** Per il secondo serve una misura, e la misura è arrivata un giro dopo il
commit.

⚠️ Precedente della stessa famiglia, già agli atti: **BOX3 V99 (f)**, dove la
SOSTANZA era giusta e la PROCEDURA no. Qui è il contrario: la procedura ha
retto (due cancelli, diff verbatim, impronte) e **la sostanza è passata
sbagliata lo stesso**.

Altre correzioni del referee, tutte **fondate e accettate**: lo scarto
disco/blob (G.4) · i tre claim su Apple non sorgentati (§ sotto) · l'enunciato
orfano non nominato.

**Sui tre claim Apple**, per il registro: la doc ufficiale **non è
raggiungibile** (`developer.apple.com` richiede JavaScript). Il testo letterale
dell'errore di validazione **l'ho recuperato** — `developer.apple.com/forums/
thread/693838`, «*The bundle version, NNN, must be a higher than the previously
uploaded version*», col refuso «a higher» **nell'originale**, che è ciò che
rende la stringa riconoscibile come citazione. ⛔ **Contenuto generato dagli
utenti, NON documentazione ufficiale**: vale come indizio sulla **formulazione**
(crescita monotona, non unicità), non come prova della regola. Gli altri due
claim sono ridotti a **[R] non sorgentati** e **rimossi dalle motivazioni** dei
ticket.

════════════════════════════════════════════════════════════════════════════════
(I) COSA RESTA APERTO — elencato, non risolto. Con chi decide.
════════════════════════════════════════════════════════════════════════════════

1. **Dove va l'enunciato del runner — A / B / C / D, non mutuamente esclusive.**
   → **DECIDE MAURO.** Misure e costi in (F). Io non ho scelto.
2. **La correzione di BUGS r.355** («resta senza casa», «è E3»): falsa,
   misurata, **da rettificare nel giro prossimo**. → referee (formulazione) +
   Mauro (OK). ⛔ Non fatta oggi: v45 è committata e ratificata.
3. **Il caveat «da confermare» a `SCALETTA:219-221`**, su una condizione
   scattata il 28/07. → referee (ratifica) + Mauro.
4. **La metà PRE-ESISTENTE di `TD-qlive-exit-unconfirmed-stop`** (E.5): sospetta
   stale, **non misurata**. Ticket 🔴 BLOCCANTE: non si tocca per inferenza.
   → misura CC, poi referee.
5. **Il freeze CD dell'overlay uscita-stanza**, atteso dal 18/07 (`LIBRO:286`,
   stato `attiva`). **Nessuna implementazione prima del freeze.** → **CD**.
6. **CD-Q17 e CD-Q18** (Sez.4, aperte 30/07). → **CD**.
7. **Riclassificazione di severità di TD#17** in ottica commerciale. → **MAURO**,
   incisa come pendenza esplicitamente NON decisa.
8. **La build di DISTRIBUZIONE mai tentata** e l'entitlement multicast mai
   riverificato su quel profilo (`TD-ci-nessuna-build-distribution`, §1.5). →
   CC (workflow) + **Mauro** (certificati e profilo sul portale).
9. **Il caricamento delle due stampe V45 nel Progetto Claude.** → **MAURO**.
10. **La terza copia LIBRO a nome vivo** e **`REFEREE_SYNC_2026-07-13/`**:
    reperti di consegna, ticketati, **non candidati alla cancellazione**.
    → **MAURO**.
11. **`ios_app/QBeats/ContentView.swift`** — vecchio metronomo standalone, 100
    righe, raggiungibile a due tocchi nella build Debug che la CI archivia.
    Non è un ticket aperto oggi: **lo segnalo come osservazione**, non come
    pendenza. → nessuno, finché qualcuno non decide che lo sia.

**FRONTE CODICE — ⟦S4R⟧.** L'ordine ⟦S4K⟧ → ⟦S4R⟧ → ⟦S4L⟧ è inciso e
obbligatorio; ⟦S4K⟧ è chiuso device + CI. ⚠️ **Non ho visto un prompt che apra
⟦S4R⟧: l'ordine è legge, il via no.** Chi riprende legga la scheda ⟦S4R⟧ per
intero — contiene il vincolo sul runner (E.3), il vincolo `ObservableObject`
annidato, l'emendamento invariante Nodo A, e la pendenza «coppia stretta con S4
va ri-tarata».

════════════════════════════════════════════════════════════════════════════════
(J) TRAPPOLE TECNICHE — quelle nuove di oggi
════════════════════════════════════════════════════════════════════════════════

1. **`LiveRootView(` è SOTTOSTRINGA di `QLiveRootView(`.** Un grep per nome di
   vista in questo progetto conta anche le viste il cui nome lo contiene.
   Filtrare, o il call-site count è falso in eccesso. Vale per ogni coppia
   `X` / `QX` — e qui ce ne sono diverse.
2. **Lo strumento di scrittura usa LF, i canonici a due facce usano CRLF su
   disco.** Ogni pezzo va normalizzato PRIMA di essere inserito, e la guardia va
   messa nello script, non nella testa.
3. **Inserire prima di un'ancora: CRLF DOPPIO se segue un titolo `##`/`###`,
   CRLF SINGOLO se segue una riga di tabella.** La stessa operazione, due
   regole opposte. La contabilità byte non se ne accorge: bisogna guardare le
   giunzioni.
4. **`ios_app/` e `ios_app/**/*.swift` hanno ancore DIVERSE.** Oggi: `6c7352a1`
   e `b9f4e5f`. Scambiarle produce una falsità sullo stato del prodotto.
5. **Un `echo` che dichiara l'esito non è una misura.** Se l'etichetta e
   l'output confliggono, vince l'output — ma nel referto sembrano identici.
6. **`git diff --cached` confrontato per sha256 con l'artefatto ratificato** è
   una verifica più forte della rilettura a occhio, e costa un comando.
7. **In propagazione, `cmp` oltre lo sha256.** L'impronta prova che il file è
   QUELLO, non che è INTERO.
8. **Python su questa macchina stampa su cp1252 e muore sugli emoji.**
   `PYTHONIOENCODING=utf-8` davanti al comando, oppure scrivere su file con
   `encoding='utf-8'` e poi `cat`.

================================================================================
FINE HANDOFF.
================================================================================
