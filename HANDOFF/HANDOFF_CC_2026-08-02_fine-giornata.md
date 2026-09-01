# HANDOFF CC — fine giornata, 2026-08-02

**Chi scrive:** CC. **Prompt:** `QB-2026-08-02-P21-HANDOFF-CAMBIO-CHAT`.
**Che cos'è:** un **deposito**, non una ratifica. È il mio handoff sul mio lavoro. Niente qui è
ratificato dal fatto di starci scritto.

**Marcatura, riga per riga:** `[V]` = misurata da me **in questo turno**, a fonte · `[R]` = riferita
da altri, con la fonte nominata · **NON RICORDO** scritto così, non aggiustato.
⛔ **Nessun path, commit, sha o numero di riga a memoria.**

⚠️ **Il contenuto di questo file non mi è stato dettato**, per scelta esplicita di Mauro: un
riassunto dettato sarebbe il riassunto di qualcun altro con la mia firma — ed è esattamente il
difetto più caro della giornata (un riassunto scambiato per una misura). Quello che segue è ciò
che ho visto io su disco, in git e nella CI.

---

## §1 — STATO A FONTE, RIMISURATO ADESSO `[V]`

```
HEAD                     c00feb43361d01d961fd1e97cf4c1a77a5bf7c7e
branch                   master
origin/master            c00feb43361d01d961fd1e97cf4c1a77a5bf7c7e   (git ls-remote, non output locale)
```

`[V]` **I cinque canonici a HEAD** — OID del blob e byte da `git rev-parse` / `git cat-file -s`,
versione letta dall'intestazione del blob:

| documento | versione dichiarata | OID blob | byte |
|---|---|---|---|
| `LIBRO_MASTRO_QBEATS.md` | 51 (02/08/2026) | `06caa750d93130d0ff189b5eeaac15f2fd7d712a` | 240691 |
| `BUGS_QBEATS.md` | 47 | `c896f919b1ba93437eff56eee3ab592136203337` | 272339 |
| `BOX3_QBEATS.md` | V99 — 2026-07-22 | `490d6d9b38c355dc53ddc9b31431f9a858f2b342` | 89457 |
| `BOX5_QBEATS.md` | V28 — 28/07/2026 | `21b23d621ac224c759b53d813196058483e3b056` | 57158 |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 5 (02/08/2026) | `4bacc529e75dc06f5fcefb4d4c80343da305149e` | 37691 |

⚠️ **Il quinto canonico NON si chiama `SCALETTA_QBEATS.md`.** Quel nome non esiste in nessuna forma
nel repo né nel corpus: è il fatto inciso in **LIBRO v51** oggi. Chi lo cerca con quel nome trova
zero e conclude che manchi.

`[V]` **Conteggi, presi PRIMA che questo file esistesse** — quindi lo escludono per costruzione:

```
porcelain totale         120   -> untracked 120, tracciati modificati 0
untracked in HANDOFF/    116
file totali in HANDOFF/  120   di cui tracciati 4
staging                  VUOTO (0 file)
stash                    0
```

Due forme concordi sui 116: `git status --porcelain | grep '^?? HANDOFF/'` e
`find HANDOFF -type f` (120) meno `git ls-files HANDOFF` (4). **Con questo file diventano 121 e
117.** È la lezione già pagata: chi conta una cartella scrivendoci dentro sbaglia.

`[V]` **Worktree — sono DUE:**

```
C:/Users/BULLFROG/Desktop/ANTIGRAVITY/Q-BEATS   c00feb4 [master]
C:/Users/BULLFROG/qb_fixB                       add556f [test/bug2b-test7-fixtures]
```

⚠️ Il secondo **non è stato toccato oggi**. Chi fa sweep sul «repo» fermandosi alla cartella
principale misura meno di quello che c'è.

`[V]` **CI — tre commit oggi, DUE run.** Misurate con lo sha a **40** (`gh run list --commit <40>`)
e lette con `gh run view`, **mai** `gh run watch | tail`:

| commit | run | esito | durata |
|---|---|---|---|
| `c00feb43361d01d961fd1e97cf4c1a77a5bf7c7e` | `30741123002` | `completed` / `success` | 09:07:04Z → 09:09:12Z |
| `07e09260bffa446a3fba1893267c2567aed88616` | `30740537711` | `completed` / `success` | 08:49:46Z → 08:52:43Z |
| `d7371413aa0fb7b5ff8c9ace900b2c73b56f08c1` | **nessuna** | — | — |

⚠️ **Lo zero su `d737141` NON è un buco.** LIBRO v51 e SCALETTA-S5 sono stati pushati **insieme**:
un push con due commit innesca **una** run, sul commit di testa. Chi lo legge come «CI mancante»
apre un'indagine su niente. Il `headSha` di entrambe le run coincide col commit atteso, verificato.

⚠️ **«Verde» qui significa build firmata riuscita, non comportamento provato.** Tutti e tre i
commit di oggi sono **doc-only, zero righe di codice**: la CI non poteva dire altro.
**«push ≠ chiuso» resta in piedi** per tutto ciò che tocca il prodotto.

---

## §2 — COSA HO COMMITTATO OGGI `[V]`

Tre commit, tutti **autore e committer `Mauro Martintoni <di_tutto@icloud.com>`**, `Co-Authored-By`
**zero** (verificato con grep su ciascuno), nessun `--no-verify`, **un file per commit**, staging
file per file.

| # | commit | file | cosa |
|---|---|---|---|
| 1 | `d7371413aa0fb7b5ff8c9ace900b2c73b56f08c1` | `LIBRO_MASTRO_QBEATS.md` | v51 — nome reale del quinto canonico · abolizione in avanti della forma `r.NNN` |
| 2 | `07e09260bffa446a3fba1893267c2567aed88616` | `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | scheda ⟦S5⟧, voce «OPEN — tipo del runner» |
| 3 | `c00feb43361d01d961fd1e97cf4c1a77a5bf7c7e` | `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | v5 — bump R7 tardivo, riparazione **per aggiunta** |

**Ogni commit è passato due prove, non una:** `cmp` fra il diff in staging e il diff ratificato
(**exit 0** su tutti e tre) **più** identità di oggetto sul blob — che è la prova che non dipende
dai path. ⚠️ Sul `cmp` della SCALETTA ho normalizzato il solo segmento `HANDOFF/`, assente nei diff
ratificati perché generati su directory di scratch: dichiarato al momento, non taciuto.

⚠️ **Il commit 3 esiste perché il commit 2 era difettoso.** Il 2 ha cambiato il contenuto della
SCALETTA **senza bumpare** `**Versione:** 4`, e **R7** — voce 31 del registro Sez.6 del LIBRO —
prescrive il bump quando il contenuto cambia. Il difetto è **mio**: il diff quel bump non lo
conteneva perché non ce l'ho messo. L'ho trovato **dopo il push**, durante la propagazione R-δ, non
mentre lo scrivevo. ⛔ `07e0926` **non è stato riscritto né emendato**: è pushato, è storia, il repo
è **PUBLIC** — R7 si è riparata aggiungendo.

`[V]` **Il difetto R7 è ISOLATO, non di famiglia.** Misurato su tutta la storia tracciata: **ogni**
commit che tocca `BOX3_QBEATS.md` e `BOX5_QBEATS.md` ha toccato anche la propria riga di versione
nello stesso commit (BOX3 `V98→V99` in `7c804c1`; BOX5 `V27→V28` in `0a6ebaf`; `edaa80f` è rinomino
puro, il file entra intero). Il LIBRO oggi ha bumpato `50→51`. **La SCALETTA era l'unico buco.**

---

## §3 — COSA IL PROSSIMO DEVE RIMISURARE PRIMA DI COSTRUIRCI SOPRA

Non «tutto». Queste, e il motivo per cui proprio queste.

1. **HEAD e allineamento remoto, interrogando il REMOTO.** `git ls-remote origin master`, mai
   l'output locale. **Motivo:** un valore copiato invecchia in falsità in meno di un giorno — è
   successo con «v50 NON pushato», che era vero quando fu scritto e falso il mattino dopo.
2. **Le cinque impronte del §1.** Se una non combacia, quel file è più vecchio o più nuovo di quello
   che credi, e ogni misura che ci costruisci sopra è sbagliata a monte.
3. **Il conteggio degli untracked, PRIMA di scrivere qualsiasi file.** Chi conta dopo aver
   depositato conta anche sé stesso.
4. **Se `⟦S-EXIT⟧` è chiuso su device.** ⛔ Da questo dipende un **vincolo ratificato di sicurezza**
   (§7), non una preferenza. Se lo si eredita sbagliato si sale su un palco con una build che può
   fermare la band.
5. **Se il congedo del referee del 02/08 è arrivato** (§6bis). Se manca, il referee nuovo apre con
   metà del quadro.

⛔ **Non ereditare da riassunti — questo compreso.** Riapri misurando.

---

## §4 — TRAPPOLE DI STRUMENTO

**Il catalogo vive altrove e NON si duplica:** §4 di
`HANDOFF/HANDOFF_CC_2026-08-02_saturazione.md` (⚠️ quel nome porta `08-02` per un errore ma il file
**PRECEDE** l'handoff del 01/08 sera: mtime 17:04 contro 23:52). Qui **solo il delta di oggi**.

- `[V]` **La console Windows uccide lo script, non la misura.** `python3` che stampa su console
  cp1252 muore con `UnicodeEncodeError` sul primo carattere non-latin1 (emoji, `⛔`, `⟦`). **I
  risultati già stampati restano validi**: è un guasto di trasporto, non di calcolo. Rimedio:
  `PYTHONIOENCODING=utf-8`. Mi è successo **due volte**, e la prima ho rischiato di rileggere il
  crash come «la misura non torna».
- `[V]` **Path in stile bash dentro Python fallisce con `FileNotFoundError`.** `/c/Users/...` è
  valido per gli strumenti bash e **non esiste** per l'interprete Python, che vuole `C:\Users\...`.
  Preso **due volte**, e la seconda su una verifica di impronta: un istante prima di leggerlo come
  «il file non c'è».
- `[V]` **Il troncamento a 200 caratteri ha quasi prodotto uno STOP falso.** Le righe di Sez.2 del
  LIBRO arrivano a **~3400 caratteri**; leggendone 200 di `LIBRO:317` ho visto solo l'apertura
  («SDOPPIAMENTO ⟦S4L⟧») e ho creduto che il contenuto atteso non ci fosse. C'era, più avanti nella
  **stessa riga**. ⇒ **Su un canonico, "non l'ho trovato in 200 caratteri" non è una misura.**
- `[V]` **Un `.html` di design può essere per il 90% un font in base64.** Il freeze standalone pesa
  464 KB e un `grep -o` con contesto ampio ha riversato ~444 KB di base64. Rimedio: ricerca mirata
  con finestra limitata, non lettura del file.
- `[V]` **`grep -c` su una stringa che compare in un nome di file rende un falso positivo.**
  Cercando «26» come cifra ho trovato 16 occorrenze — quasi tutte dentro `2026`. Serve il confine
  di parola, altrimenti si conta l'anno.
- `[R]` (referee, riferito da Mauro) **il connettore del referee rende il testo con escape
  markdown:** il referee ratifica il **contenuto**, non i byte. **La garanzia byte-esatta è mia.**

---

## §5 — LAVORO APERTO, COME LO VEDO IO DAL REPO

**a) 🔴 `⟦S5⟧` è il fronte, ed è aperto.** Dettaglio in §7.

**b) 🟠 L'àncora R7 nel lint — accolta nel merito, non fatta.** `[R]` (referee, via Mauro): la
proposta «se il diff cambia un canonico, la riga di versione deve comparire fra le righe
modificate» è accolta e va in un giro suo, legata al fatto che `tools/lint_canonici.py` è ancora
**untracked**. `[V]` Ho verificato che il file esiste e non è tracciato. ⇒ **Due problemi, una
mossa.** È il rimedio strutturale al difetto di oggi: le àncore automatiche hanno preso, in questa
giornata, difetti che due riletture non avevano visto; per R7 quella sonda non esisteva.

**c) 🔵 Il debito `LIBRO:467` in BUGS — NON è quello che sembra.** `[V]` Rimisurato: 9 occorrenze su
4 righe. Ma la composizione dice che **nessuna è riparabile**: 2 sono già coperte dalla marcatura
che sta subito sotto, 4 **sono** quella marcatura (riscriverle è un controsenso), 3 stanno nel
registro, dichiarato ⛔ intoccabile da v46 e v47. ⇒ Chi lo eredita come «debito urgente» apre un
giro su niente. **Il debito vero, e non è tracciato:** BUGS indirizza **sé stesso** con numeri nudi
già slittati (v46/v47 citano il bullet come `r.355`/`r.356`, oggi sta a `r.360`; una marcatura dice
«non tocca `r.1006`», e `r.1006` oggi è la voce 29 del registro). **La regola per ripararlo è stata
ratificata oggi in v51**; il giro di riparazione, no.

**d) 🔵 Alberi paralleli su Drive — dichiarato, non chiuso.** `[V]` Ogni file che deposito compare
su **due** `parentId` distinti. Il censimento non è chiuso: l'interrogazione è paginata e non l'ho
esaurita, non stimo un totale. ⛔ **Non ripulire alla cieca:** su un albero sincronizzato la
cancellazione si propaga (L3). È decisione di Mauro.

**e) ⚠️ Un file superato con nome confondibile, lasciato apposta.** `[V]`
`HANDOFF/DIFF_LIBRO-v51_2026-08-02_rev3.txt` (17747 B) è ancora su disco e su Drive accanto a
`rev4` (17548 B, quello ratificato e committato). Due nomi quasi identici, contenuti diversi: è la
trappola nome↔contenuto che questo progetto ha già catalogato più volte. **Non l'ho cancellato** —
su Drive la cancellazione si propaga.

**f) ✅ Cosa NON è aperto, benché possa sembrarlo.** La coppia di snapshot
`SCALETTA_v4-non-bumpata_2026-08-02_07e0926.md` (36673 B) e `SCALETTA_v5_2026-08-02_c00feb4.md`
(37691 B) **coesiste per disegno**: il primo è la storia del difetto R7 e il suo nome è **vero** per
quello snapshot; il secondo dichiara v5. Nessuno dei due va rinominato o rimosso.

### ⚠️ Dove la lista del referee e il mio repo divergono

`[V]` **Il congedo del referee del 02/08 non esiste su nessuna delle tre destinazioni** — vedi
§6bis. È la divergenza più grossa, e ha un precedente identico ieri.

`[R]`→`[V]` **«Il diff ratificato è quello da 17548 B»**: vero, ma quando quel messaggio è arrivato
il file consegnato era **17747 B** — un contenuto diverso, prodotto da una correzione successiva.
La ratifica era su un testo che non era più quello sul tavolo. **L'ho intercettato confrontando i
byte prima del commit, non perché l'avessi previsto.** Il giro di ricostruzione (rev4) è servito a
tornare byte-identici al testo davvero letto, e l'ho **provato con l'impronta** invece di affermarlo.

---

## §6 — DOVE IL REFEREE MI SEMBRA FUORI STRADA

Parte obbligatoria, e la scrivo per intero perché il prossimo referee la sappia da me. ⚠️ **Il
referee di oggi è stato tecnicamente forte e ha preso difetti reali nei miei diff**: quanto segue
non è un bilancio del suo lavoro, è l'elenco delle volte in cui ho dovuto fermarmi.

1. **Misure non depositate citate come prova — il caso più grave, e si è ripresentato tre volte.**
   Il «26» del referee sul conteggio delle forme composte è una misura che vive **solo in una
   finestra di chat**: zero destinazioni su tre. È entrata in un diff diretto a un canonico come
   fonte (P4), poi è rientrata etichettata «misura di parte» (P11/P12), ed è uscita solo al terzo
   giro. **L'etichetta sposta il problema dall'attribuzione alla verificabilità, e la
   verificabilità resta zero.** ⇒ Una riga canonica che cita una prova inesistente è indifendibile
   il giorno che qualcuno la va a controllare. **Regola pratica per il prossimo:** se una misura non
   sta su un supporto, non entra in un canonico — nemmeno vera, nemmeno attribuita.
2. **Due prompt con lo stesso ID `P12` e istruzioni opposte sullo stesso punto.** Ho arbitrato
   scegliendo «il più informato» — **criterio sbagliato**, e Mauro l'ha corretto: due prompt con lo
   stesso ID **non si arbitrano, si bloccano**. La regola nuova (un ID non si riusa mai; una
   correzione prende un ID nuovo e dichiara quale annulla) è di Mauro, oggi.
3. **Una formula dettata già falsa nel momento in cui l'ho ricevuta.** «Nessuna regola di
   rilevamento è dichiarata» mi è arrivata **dopo** che una regola l'avevo dichiarata io: la riga si
   contraddiceva dentro la stessa frase. Corretto poi dal referee stesso.
4. **Un'etichetta sbagliata sul mio numero.** «Regola CC = 19» attribuiva al criterio «nome
   immediatamente precedente» un valore che quel criterio non rende: quello dà **20**; 19 viene da
   un criterio diverso (bersaglio risolto ≠ fonte). Lo scarto è **una sola riga**,
   `LIBRO_MASTRO_QBEATS.md:317 @ 7ec6c1b86a7acb869c1f927fa4833374ffabb0cc`, che cita «LIBRO r.311»
   — LIBRO nomina sé stesso.
5. **R7 non controllata in ratifica.** Il referee dichiara di aver letto il diff da 1569 byte parola
   per parola **tranne l'intestazione del documento che modificava**, mentre sul LIBRO il bump
   l'aveva verificato. **Due standard nello stesso turno.** ⚠️ **La metà mia è più pesante:** il
   diff difettoso l'ho prodotto io.

⚠️ **Sulla lista di calibrazione di Mauro, due voci non le confermo come mie:** «censimento ritirato
per decreto» e «sonda cercata minuscolo» **non le ho viste** in questo turno — o sono di un giro che
non ho eseguito, o riguardano il referee precedente. **Non le trascrivo per compiacenza.**
Su `r.1361`: `[V]` confermo che è una **riga di log iMazing** citata dentro `BUGS_QBEATS.md`, non un
difetto del canonico — e questo è esattamente uno dei quattro tipi di bersaglio che hanno motivato
l'abolizione della forma `r.NNN`.

**La lezione che tengo per me, non per il referee:** quattro volte oggi il freno ha funzionato, ma
in tre casi su quattro il difetto **l'ho comunque scritto io per primo** e il freno è scattato al
controllo automatico, non alla rilettura. **Chi scrive un canonico a mano prima o poi sbaglia; chi
ci mette davanti una sonda che abortisce, no.**

---

## §6bis — ⚠️ IL CONGEDO DEL REFEREE 02/08: **NON È ARRIVATO** `[V]`

Misurato adesso, su tutte e tre le destinazioni:

```
C: repo/HANDOFF/CONGEDO_REFEREE_2026-08-02.md   ASSENTE  (find + ls, due forme)
E: .../HANDOFF/CONGEDO_REFEREE_2026-08-02.md    ASSENTE  (find su tutto l'albero)
Drive  title contains 'CONGEDO_REFEREE'         SOLO la versione 2026-08-01
```

**Controllo positivo nella stessa forma:** `CONGEDO_REFEREE_2026-08-01.md` **esiste** su C: (7851 B),
su E: e su Drive (7851 B, su entrambi gli alberi paralleli). ⇒ **La ricerca funziona e lo zero sul
02/08 è uno zero vero**, non un falso-zero da filtro.

⛔ **Questa è la ripetizione esatta di ieri, a parti invertite.** Il 01/08 un documento citava un
congedo che non esisteva su alcun supporto; oggi il congedo è annunciato e non è atterrato.
**Una ratifica — o un congedo — che vive solo in una finestra di chat non esiste operativamente.**

⇒ **Al referee nuovo servono ENTRAMBI i documenti**, il suo congedo e questo handoff: `[R]` (Mauro)
stamattina il referee nuovo ha ricevuto il congedo **senza** l'handoff di CC, che ne falsificava tre
righe. **Con un solo documento su due si riparte con un quadro falso in un punto preciso.**

---

## §7 — IL FRONTE ⟦S5⟧: COSA SERVE, COSA MANCA, E QUANTO È GRANDE

⚠️ **Non progetto la soluzione: l'atomo lo scrive il referee.** Qui c'è la **dimensione**.

### Cosa esiste oggi `[V]`

- `QLiveShowDetailView` (frame ③) **non esiste**: zero come file, zero come simbolo in tutto
  `ios_app/` (controllo positivo: 66 file `.swift` presenti). Path dichiarato dalla scheda:
  `UI/QLive/QLiveShowDetailView.swift`.
- Lo **slot del runner esiste e non è riempibile**: `QLiveSession` porta
  `@Published private(set) var runner: SetlistRunner? = nil` e **zero funzioni, zero assegnamenti**.
  ⟦S4R⟧ ha omesso il mutatore **apposta**.
- **Nessuno costruisce un `SetlistRunner`**: zero call-site reali di `SetlistRunner(`.
- La pagina `.metronome` è **irraggiungibile**: zero chiamanti di `navigate(to: .metronome)`
  (controllo positivo: `navigate(to: .shows)` → 2).

### La riconciliazione `LiveSession` / `QLiveSession`: **NON è un merge di tipi** `[V]`

È il punto su cui mi è stato chiesto il parere, e la misura cambia la domanda. I due tipi **non
sono in competizione**: sono due cose diverse con nomi che si somigliano.

| | `LiveSession` | `QLiveSession` |
|---|---|---|
| dove | `ios_app/QBeats/Models/LiveSession.swift`, 41 righe | `ios_app/QBeats/UI/QLive/QLiveSession.swift`, 36 righe |
| cos'è | **stato di display** del player: nome brano, BPM, sezione, battuta, pattern accenti, `playbackState`… | **contenitore-stanza**: possiede il solo slot del runner |
| chi lo possiede | `LiveView`, come `@StateObject private var session` | `QLiveRootView`, come `@StateObject roomSession` |
| chi lo consuma | 4 leaf: `LiveHeaderView`, `MixerOverlayView`, `TeleprompterCapsuleView`, `TransportView` | il solo gate `if let runner` |
| chi ci scrive | **il runner**, via `updateSessionDisplay` / `primeDisplay` | nessuno: il mutatore non esiste |

⇒ **Il problema vero non è unire due tipi: sono due VITE DIVERSE.** Il runner vive a livello di
**stanza** (sopravvive alla navigazione interna, muore al bordo-stanza); la `LiveSession` vive a
livello di **vista** (nasce quando `LiveView` monta, muore quando smonta) — **e il runner ci
scrive dentro**.

**Conseguenza concreta, che chi scrive l'atomo deve decidere esplicitamente:** allo Start premuto nel
frame ③ **la `LiveSession` non esiste ancora** — la crea `LiveView` montando. Quindi
`startSetlist(audioEngine:session:)` **non è chiamabile dal punto in cui si preme Start**. Oggi
tutte le chiamate a `startSetlist`/`startCurrentSong` stanno **dentro il sottoalbero di `LiveView`**
(`LiveView` stesso e `TransportView`). ⇒ **«Start» non è un gesto solo, sono due momenti:** la
**nascita del runner** (frame ③) e l'**avvio dell'audio** (montaggio del player). Chi legge
«Start→launcher ⟦S4R⟧» come un unico call-site costruisce la cosa sbagliata.

✅ **Metà del ponte è già scritta, e questo riduce la stima:** `SetlistRunner.primeDisplay(session:)`
esiste **ed è già chiamato** da `LiveView` — serve esattamente a ri-idratare una `LiveSession`
appena nata dallo stato di un runner già vivo. Il caso «player → indietro → player» ha già il suo
meccanismo.

**Dimensione onesta:** la riconciliazione è **piccola come codice** (un mutatore sullo slot, e la
decisione di dove cade la chiamata di avvio) e **grande come decisione** (la sequenza dello Start e
il confine di vita fra runner e display). ⛔ Non è cablaggio, e non è nemmeno una riscrittura: è
**una scelta di sequenza da ratificare prima di scrivere**.

### Il mio parere: **⟦S5⟧ va spezzato in due atomi** 🔧

Non vincolante — è la decisione di Mauro col referee. Il taglio che vedo dal codice:

- **⟦S5a⟧ — il frame ③, read-only.** `QLiveShowDetailView` nuova: lista che scorre, `.startfoot`
  ancorato al fondo (contratto già ratificato in LIBRO v50), conteggio orfani, Start **disegnato**
  ma inerte/disabilitato secondo `resolve()`, tap riga → `navigate(.detail)`. **Zero runner, zero
  audio, zero mutatore.** Reversibile in modo pulito, gate = CI + resa su device come
  non-regressione.
- **⟦S5b⟧ — lo Start.** Mutatore sullo slot, nascita del runner con la setlist **scelta**,
  `navigate(.metronome)`, e la decisione su dove cade `startSetlist`. **È qui che sta tutto il
  rischio**, ed è **questo** il gate device nominato della decisione Mauro 18/07 sulla proprietà del
  runner (per la riga «ORDINE DEGLI ATOMI §6 EMENDATO»,
  `LIBRO_MASTRO_QBEATS.md:329 @ 7ec6c1b86a7acb869c1f927fa4833374ffabb0cc`).

**Perché proprio lì il taglio:** ⟦S5a⟧ è verificabile **senza audio e senza rete**, ⟦S5b⟧ no. Oggi
sono un atomo solo, e un atomo solo significa che il gate device deve provare insieme la resa
grafica e la vita del runner — due cose che falliscono per ragioni diverse.

### ⛔ Il prerequisito che blocca ⟦S5b⟧ e **non dipende da CC** `[V]`

Il codice stesso lo dichiara, in `QLiveRootView` nel ramo `else` del gate: la pagina metronomo senza
runner ha bisogno di un **empty-state onesto**, il cui **disegno è materia CD** e per cui **non
esiste freeze**. Verbatim dal file: «**⟦S5⟧ NON parte senza questo empty-state**» e «⛔ NON messo in
⟦S4R⟧: il disegno è materia CD e NON esiste freeze per questa pagina. CC non genera UX.»
⇒ **Serve una consegna CD prima che ⟦S5b⟧ possa chiudersi.**

### ⛔ Il vincolo di sicurezza, verbatim dal canonico

`LIBRO_MASTRO_QBEATS.md:329 @ 7ec6c1b86a7acb869c1f927fa4833374ffabb0cc`:

> ⛔ **VINCOLO RATIFICATO: nessuna sessione multi-device e nessuna data con band su una build che contenga ⟦S5⟧ finché ⟦S-EXIT⟧ non è chiuso device.**

⚠️ **Questo vale dal momento in cui ⟦S5⟧ entra in una build, non da quando è "finito".** Se ⟦S5⟧ si
spezza in due, chi decide deve dire **esplicitamente** se il vincolo scatta già con ⟦S5a⟧ — la
riga parla dell'atomo, e due atomi sono un caso che la riga non prevedeva.

---

## §8 — AL CC SUCCESSIVO

- **Non ereditare da riassunti: lo stato vive nei file.** Vale anche per questo documento.
- **Le non negoziabili:** staging **file per file**, mai `git add -A` (repo **PUBLIC**, 120
  untracked) · mai `--no-verify` · commit **monoscopo**, autore e committer Mauro, zero Co-Auth ·
  **due cancelli separati** (ratifica del referee sul diff verbatim **e** OK esplicito di Mauro sul
  **commit**: nessuno sostituisce l'altro, e l'OK di Mauro sul *contenuto* non è l'OK sul *commit*)
  · ogni prompt porta un **ID**, e **un ID non si riusa mai** · consegnato solo quando il
  destinatario conferma di aver **letto**.
- **Prima di ogni commit multi-giro: ri-confrontare byte e impronta** del diff che stai per
  applicare contro quello davvero ratificato. Oggi è il controllo che ha impedito di committare un
  testo diverso da quello letto dal referee.
- **La cosa che oggi ha impedito gli errori più grossi non è stata l'attenzione: sono state le
  sonde automatiche messe DAVANTI alla scrittura** — conteggio dei pipe, audit dei numeri di riga
  nudi, `cmp` con impronta. Hanno preso difetti sopravvissuti a due riletture. **Dove la sonda non
  c'era — R7 — il difetto è passato.** È esattamente lì che va il prossimo giro di lint.

---

*Fine del deposito. Non è una ratifica.*
