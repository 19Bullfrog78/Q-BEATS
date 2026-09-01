# CONGEDO CC — sessione 21/08/2026 notte, mandati A150 → A165

Da: CC · A: **la chat CC che apre dopo di me**, + Mauro
Scritto **da solo**: il referee non mi ha detto cosa metterci, ed e' il punto del
mandato. Cio' che segue e' quello che so io perche' ho toccato i file.

⚠️ **Non sono la stessa CC del congedo `CONGEDO_CC_2026-08-21_SERA.md`.** Quello
firma `A149-FINE` ed e' di un'altra sessione, che ha continuato fino ad A153.
**Io ho aperto leggendo quel congedo e ho lavorato da A150 a A165.**

Marcatura: **[M]** misurato da me alla fonte in questa sessione · **[R]**
riportato da altri, non rimisurato · **[A]** giudizio mio. **Non marcata = [R].**

---

## ⛔ LE QUATTRO RIGHE DA LEGGERE PRIMA DI TUTTO

**1. 🚨 OGGI C'ERANO DUE SESSIONI CC VIVE, E L'HO SCOPERTO PER CASO.**
**[M]** Ho letto la cartella `HANDOFF/` alle ~15:19; due minuti dopo, rimisurando,
e' comparso `MISURE_CC_2026-08-21_A151-…md` scritto alle **15:21:20**. Quella
sessione ha poi prodotto **A152** (15:31) e **A153** (15:39). ⇒ **Il congedo che
avevo in mano era superato di due mandati e non lo diceva nessuno.**
⛔ **Non me l'ha segnalato nessun meccanismo: l'ho visto perche' ho RIMISURATO
invece di rileggere.**
✅ **Cura, nata li' e usata in ogni mandato successivo — chiamala R2:** prima di
scrivere un byte, quattro misure — HEAD locale **e** remoto, mtime del file
bersaglio, working tree pulito, **nessun file nuovo comparso**. ⚠️ **[A] Ma resta
una clausola scritta a mano in ogni mandato: dipende da chi si ricorda di
metterla. Non e' un meccanismo, e' una consuetudine.**

**2. ⛔ IL MIO ERRORE PEGGIORE: HO SCRITTO UNA CONCLUSIONE PIU' FORTE DELLA MIA
MISURA, E ME LA SONO PORTATA IN PRIMA RIGA.**
In **A159** ho concluso: *«la sincronizzazione E: → Drive e' ferma da meta'
agosto»*. **E' FALSO.** ⚠️ **Nello stesso referto avevo dichiarato il limite**
(«non misurabile dal mio posto»)… **a pagina tre**, mentre la conclusione stava
a pagina uno.
**[M] La misura era giusta:** su `I:\Il mio Drive\Qbeats\HANDOFF` ci sono **186**
file contro i **370** di `E:`. **Ma confrontavo due cose diverse**, non due copie
della stessa: `I:` non rimonta la sezione «Il mio computer», dove vive il vero
riflesso di `E:`, quindi **da li' e' invisibile per costruzione**.
⇒ **[A] Un limite dichiarato a pagina tre non annulla una conclusione data per
certa a pagina uno.** ⛔ Il referto A159 **non e' stato corretto**: la rettifica
vive in **BOX5 V29 §6**, ed e' committata.

**3. ⛔ IL MANDATO NON E' UNA FONTE, E OGGI NON E' UN PRINCIPIO: E' UN CONTEGGIO.**
**[M] Mandati arrivati difettosi che ho fermato o corretto — e li elenco perche'
il numero da solo non serve a chi arriva:**

| mandato | difetto | come e' venuto fuori |
|---|---|---|
| **A150** | ID **gia' bruciato**: emesso, annullato da Mauro, tre file orfani | 4 hit per contenuto — ⚠️ **il conteggio era ambiguo, l'ha deciso l'ISPEZIONE DEL CONTESTO** |
| **A155 §4** | indirizzo Drive `HANDOFF\` sbagliato | misurato: i referti del giorno stavano in radice |
| **A156** 1ª stesura | dichiarava un albero Drive **inesistente** | cercato a profondita' 5: zero, con sonda tarata |
| **A157 §4** | «vive sotto Il mio computer» — **non verificabile da `I:`** | `Altri computer\Il mio Computer\` contiene **un solo file**: `desktop.ini` |
| **A158 §4** | «su Drive si copia la struttura del repo» | **falso**: Drive replica `E:`, non il repo |
| **A161 §3** | **segnaposto** al posto del testo da incidere | il testo diceva «[il referee allega qui…]» |
| **A163** 1ª consegna | **troncato** a meta' del §2 | mancavano §3, §4, chiusura |
| **A164 §2** | esigeva **due sha256** e ne conteneva **zero** | ⚠️ **le sezioni c'erano tutte: un controllo formale sarebbe passato** |
| **A165** 1ª consegna | **troncato** a meta' del §3 | mancava la riga di chiusura |

⚠️ **[A] Il caso A164 e' quello da ricordare**, perche' e' il primo controllo
**sull'obiettivo** della giornata che ha preso il proprio autore. Le cinque
sezioni c'erano e la chiusura pure. **Solo guardare il contenuto l'ha visto.**

**4. ✅ UNA REGOLA NUOVA E' STATA COMMITTATA, E LA SUA STORIA VALE PIU' DELLA
REGOLA.** Il capitolo **«R-δ — dove vanno i file»** in BOX5 V29 dice: **quattro
destinazioni, DUE sole scritture**; su Drive **non si scrive**, perche' arriva da
solo. E il **§1-bis**: ogni artefatto si deposita **nell'istante in cui esiste**,
non a fine mandato.
⚠️ **[A] Il §1-bis esiste per un errore mio.** In A162 mi sono fermato al cancello
— comportamento corretto — e i due diff sono rimasti **solo su `C:`**. **[M] La
sonda lo diceva gia'**: `A162` rendeva **2 su C: e 0 su E:**, la stessa firma che
avevo visto per `A155`. **Ma nessuno la stava guardando.** ⇒ Meta' del difetto era
del mandato che metteva R-δ in coda; **meta' mia, che sapevo di fermarmi a meta'
e non ho chiesto.**

---

## PARTE MECCANICA — tutto [M], rimisurato alle 21:25

### 1 · HEAD

```
HEAD locale = HEAD remoto = 6527d82b8e9314f50a6ae354a3e86c30a77aacf9
```

Letto con `git rev-parse HEAD` e `git ls-remote origin master`. Working tree
**pulito**. ⛔ **Mai `rev-parse origin/master`**: legge una copia locale.

### 2 · I tre commit della mia sessione

Tutti **`Mauro Martintoni <di_tutto@icloud.com>`** come **author E committer**,
**zero trailer**, zero riferimenti a strumenti, **un file ciascuno**.

| sha (40) | ora | cosa |
|---|---|---|
| `e4764f9aedea2e9cc0d98c92b48553bd60b3d93f` | 19:50 | LIBRO **v58** — collaudo device 21/08 di A139 e A144 |
| `4e57870191ffb4cc067fc8b3a6ce1b0af148b370` | 21:11 | BOX5 **V29** — capitolo «R-δ» + marcatura sul Delta V26 |
| `6527d82b8e9314f50a6ae354a3e86c30a77aacf9` | 21:11 | LIBRO **v59** — la gamba «Drive a mano» esce da R-δ |

### 3 · CI — per NOME, mai «verde» secco

| sha | `iOS Signed Build` | `F1 — Build Check` |
|---|---|---|
| `e4764f9…` | **success** | **NON PARTITO** |
| `4e57870…` | ⛔ **NESSUNA RUN** | NON PARTITO |
| `6527d82…` | **success** (run `32517225324`) | **NON PARTITO** |

⛔ **[M] Il commit di BOX5 non ha una propria run.** `gh run list --commit
4e57870…` (sha a **40**) rende **`[]`**. ✅ **Controllo positivo nella stessa
forma:** lo stesso comando su `6527d82…` rende la run ⇒ **lo zero e' tarato**, non
e' il falso zero dello sha corto. La ragione: **due commit pushati insieme fanno
partire una sola run, sull'ultimo sha.**
⇒ ⚠️ **[A] «BOX5 V29 e' verde» sarebbe una frase falsa.** Verde e' l'albero
**combinato** a `6527d82`.

⛔ **`F1` interrogato per ID `266323994`:** quattro run in tutto, **le due piu'
recenti (31/07) ENTRAMBE FALLITE**, l'ultima riuscita **25/04/2026**. **Non parte
da quasi quattro mesi.**

### 4 · Le versioni dei canonici

| canonico | versione | ultimo commit |
|---|---|---|
| `BUGS_QBEATS.md` | **58** | `c46c0d4` — 21/08 |
| `LIBRO_MASTRO_QBEATS.md` | **59** (21/08) | `6527d82` — **oggi** |
| `BOX5_QBEATS.md` | **V29** (21/08) | `4e57870` — **oggi** |
| `HANDOFF/SCALETTA_ATOMI_S6…` | **11** (18/08) | `fe2091a` — 19/08 |
| `BOX3_QBEATS.md` | ⛔ **NESSUNA riga `Versione`** | `7c804c1` — **22/07** |

⛔ **[M] Lo zero di BOX3 e' tarato:** `^**Versione` rende **0** su tutto il file,
mentre su BOX5 rende **1**. ⇒ **BOX3 e' fermo da trenta giorni e non dichiara
nemmeno la propria staleness.**

### 5 · Prossimo ID libero

**[M]** Sonda a due forme su due supporti, piu' ispezione del contesto.

| ID | NOME repo | NOME E: | CONT repo | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A166** | **0** | **0** | **0** | **0** | ⇒ **PROSSIMO LIBERO** |
| A164 | 1 | 1 | 1 | 1 | controllo positivo |
| A163 | 2 | 2 | 1 | 1 | controllo positivo |
| A176 | 0 | 0 | 0 | 0 | controllo **negativo** |

⚠️ **AUTORIFERIMENTO dichiarato:** questo congedo cita `A165` e `A166`. Dopo che
esiste, **entrambi renderanno per contenuto.** A166 resta libero **come ID di
mandato**, ma la sonda non lo dira' piu' a zero.

---

## ⛔ I MIEI ERRORI, PER NOME — cinque

**[M] 1. A159 — conclusione piu' forte del misurato.** Vedi riga 2 in testa. **E'
il peggiore, e non per il danno ma per la forma:** avevo la misura giusta e ne ho
tratto una conclusione che non seguiva, mettendola dove si legge per prima.

**[M] 2. A156 — la mia rilettura in chat si e' corrotta, e il file era sano.**
Ricopiando una riga del LIBRO ho scritto `«8/8**` dove il file porta `«8/8»`.
Il file **non e' mai stato sbagliato**: sha256 invariato, e il gate di A157 lo ha
dimostrato (`«8/8»` = 3, `«8/8**` = 0, con controllo positivo).
✅ **Lezione operativa:** ⛔ **una rilettura passata attraverso il modello non e'
una prova sul file. Si ratifica su una MISURA, che in transito non si corrompe.**

**[M] 3. A162 — mi sono fermato al cancello e ho lasciato i diff su una gamba
sola.** Vedi riga 4 in testa. **Sapevo di fermarmi a meta' e non ho chiesto.**

**[M] 4. Ho calpestato una trappola ereditata MENTRE la verificavo.** Ho usato
`grep -c … || grep -c …` per contare tre stringhe: `grep -c` che rende **0 esce
con codice 1**, quindi `||` ha eseguito **entrambi i rami** e l'output ha mostrato
`0` e `1` incolonnati. Nessuno dei due era il valore giusto letto da solo.
⚠️ **[A] Era la trappola ② del congedo che avevo ereditato, e l'ho pestata
sapendola.** ✅ **Cura: separare con `;`, mai con `&&` o `||`, quando uno zero e'
un esito legittimo.**

**[M] 5. Ho misurato con una finestra troppo stretta e l'ho chiamato fatto.**
Ho cercato la riga `**Versione:**` con `head -3`, ma nel LIBRO sta alla riga **5**
e nella SCALETTA alla **2**: ho dichiarato «nessuna riga Versione» per due file
che ce l'hanno. Corretto in trenta secondi rimisurando con `head -8`.
⚠️ **[A] E' la stessa malattia dell'errore 1, in piccolo: uno strumento che non
puo' vedere la cosa, e un risultato preso per fatto.** ⛔ **Un `head -N` e' una
finestra, non una misura: se il numero e' arbitrario, lo e' anche l'esito.**

---

## ⛔ COSA NON CREDERE — affermazioni ereditate che ho SMENTITO alla fonte

**[M] 1. «HEAD = `c46c0d4`, quattro commit» (congedo 21/08 sera).** Erano
**cinque**: il quinto, `638b7383`, conteneva il congedo stesso. ⚠️ Il congedo
dichiarava l'autoriferimento per `A149` **ma non per `A150`**, che pure citava
nella propria tabella — **ed e' proprio A150 quello che poi e' stato riusato.**

**[M] 2. «A150 = PROSSIMO LIBERO».** Falso: emesso, annullato da Mauro, **tre file
orfani** su `E:`, gia' censiti da A152 e trattati da A153.

**[M] 3. «A155 e' chiuso» (premessa di A156).** Falso: era **interrotto**. Il
LIBRO era inciso e il diff generato, ma **referto e R-δ non esistevano.**

**[M] 4. «La stesura precedente di A156 non e' mai stata inviata».** Falso: mi era
arrivata ed ero a meta' esecuzione. Aveva un **§4 diverso**.

**[M] 5. «Su Drive esiste l'albero `FILE X CLAUDE.MD`».** **Non esiste.** Cercato
`*FILE*CLAUDE*` a profondita' **5** su tutto `I:`: **zero**. ✅ **Controllo
positivo:** `*LIBRO*` trova `Qbeats/LIBRO_MASTRO` ⇒ la sonda vede. Gli alberi
Q-BEATS su Drive sono **due** (`Qbeats`, `Qbeats_IN_CD`) piu'
`.Encrypted\Il mio Drive\Qbeats`, che e' **una struttura di cartelle con ZERO
file** — sembra un terzo albero a chi lo trova con un `find` largo.

**[M] 6. «Su Drive si copia la struttura del repo» (A158, ratificato).** Falso:
**19 delle 20** sottocartelle di `E:\…\FILE X CLAUDE.MD\` hanno l'omonimo su
Drive; le cartelle-chiave del repo (`ios_app`, `core_engine`, `ARCHIVIO.MD`,
`Vendors`) **su Drive non esistono**.

**[M] 7. Il bullet del Delta V26 di BOX5: «dal 21/07 la sola SCALETTA — vive fuori
da git».** **Era gia' falso quando fu scritto:** la SCALETTA e' tracciata dal
commit **`fe6d34b` del 18/07/2026**, **tre giorni prima** di `edaa80f` (21/07).
✅ Oggi `git ls-files` rende tracciati **tutti e cinque** i canonici ⇒ **quel
regime non ha piu' alcun soggetto.** Marcato in loco in BOX5 V29, **non
riscritto**.

⚠️ **[A] Le mie ipotesi:** non ne ho di rivelatesi false, **e non e' merito** —
dove non avevo la misura mi sono fermato (A161, A163, A165) o ho dichiarato la
divergenza invece di appianarla.

---

## ⚠️ LE TRAPPOLE NUOVE — cinque, oltre alle undici che ho ereditato

**① [M] Un controllo che CONTA le sezioni non vede una sezione VUOTA.** A161
aveva tutte le sue sezioni e la chiusura; il §3 conteneva un **segnaposto**.
✅ **Cura, usata da A162 in poi: l'integrita' si dichiara sul CONTENUTO** — «il
testo deve cominciare con X e contenere Y» — non sul numero di sezioni.

**② [M] Due commit pushati insieme = UNA sola run di CI**, sull'ultimo sha. Il
primo commit resta **senza run propria** e nessuno lo segnala.

**③ [M] `head -N` e' una finestra, non una misura.** Vedi errore 5.

**④ [M] Due alberi con le stesse cartelle sembrano allineati anche quando non lo
sono.** In A159 ho confrontato `E:\…\HANDOFF` (370) con
`I:\Il mio Drive\Qbeats\HANDOFF` (186) **come se fossero due copie**. Non lo
erano: **erano due destinazioni diverse.** ⛔ **Prima di confrontare due alberi,
stabilisci se uno e' davvero la copia dell'altro.**

**⑤ [M] «CRLF preservato» ha DUE risposte, e vanno date entrambe.** Il LIBRO sul
**disco** ha **523 CR**; nel **blob** ne ha **0**, perche' git normalizza.
✅ **Controprova che vale piu' della verifica:** la stampa del LIBRO estratta con
`git show` **non** coincide col disco (`cmp` exit **1**) — ed e' proprio quella la
prova che viene da git e non da una copia.

---

## LE PENDENZE CHE LASCIO

| # | pendenza | anzianita' |
|---|---|---|
| 1 | **🚨 `BOX3_QBEATS.md` fermo dal 22/07** — trenta giorni, **e senza riga `Versione`**: non dichiara la propria staleness. Zero tarato (BOX5 rende 1) | **30 giorni** |
| 2 | **🚨 Il clone su `F:`** — `F:\QBEATS_PREFLIGHT_A61_2026-08-06`, branch `master`, **[M] oggi 23 commit indietro**, working tree pulito, **antenato in catena**, push configurato sul GitHub **vero**. ⚠️ **[A] Il rischio non e' che diverga: e' che sia in catena e sembri sano.** **[M] Non contiene nulla di unico**: zero rami solo locali, zero stash, zero commit non pushati, e i **177** file non tracciati esistono **tutti** anche su C: o E: | 16 giorni |
| 3 | **🚨 Nove congedi su undici NON sono tracciati** in un repo **pubblico** — compresi i **due del referee** (01/08, 04/08). **[M] `git ls-files` ne rende 2 su 11.** ⚠️ **[A] Non e' archivistica: la riga v58 del LIBRO esiste proprio perche' un congedo non tracciato non poteva smentire due punteggi falsi** | preesistente |
| 4 | **🚨 `F1` non parte da quasi quattro mesi**, ultime due esecuzioni **fallite** | preesistente |
| 5 | **Il commit BOX5 `4e57870` senza run propria** — nessun gate per-commit esiste oggi | oggi |
| 6 | **Doppia serie di diff `A162`/`A163`** in `HANDOFF/`. ⛔ **La buona e' A163** (BOX5 128/1). Non cancellata, non prescritto | oggi |
| 7 | **Il TEST 8 su iPad resta NON ESEGUITO**, inciso come tale in LIBRO v58. Si chiudera' con una **marcatura additiva**, non riscrivendo | oggi |
| 8 | **L'esito di ⟦S5b⟧ non e' inciso in nessun canonico** — ereditato, **[R] non rimisurato da me** | 2 giorni |
| 9 | **`.tmp.driveupload/` — 790 file** di staging Google **dentro l'albero del repo**, l'ultimo del 05/08 | preesistente |
| 10 | **`Claude Setup.exe` e `tmp_fix.ps1`** in radice di un repo **pubblico** | preesistente |
| 11 | **I referti su Drive stanno in DUE posti** — radice e `HANDOFF\`. Riordino gia' deciso da Mauro, rimandato | oggi |

---

## [A] CIO' CHE VALE PIU' DI TUTTO

⛔ **Uno strumento che non puo' vedere una cosa non ti dice che non la vede: ti
rende zero.**

E' la forma comune di tre cose diverse successe oggi. In **A159** ho misurato su
`I:` un riflesso che vive altrove, e ho letto lo zero come «assente». Con
**`head -3`** ho cercato una riga che sta alla 5 e ho letto lo zero come «non
c'e'». Con **`gh run list --commit <sha corto>`** si ottiene `[]` **con exit 0**,
e sembra «nessuna run».
⇒ **In tutti e tre i casi lo zero era vero e la conclusione falsa.**

✅ **L'unica difesa che ha funzionato, ogni volta, e' il CONTROLLO POSITIVO nella
stessa forma:** qualcosa che **deve** rendere. Su BOX3 (`^**Versione` = 0) ho
messo accanto BOX5 (= 1). Sul commit senza run ho messo accanto l'altro sha, che
la run ce l'ha. **Uno zero senza sonda tarata non e' un fatto, e' un'assenza di
informazione travestita da informazione.**

⚠️ **La seconda, e la lascio a chi arriva perche' oggi mi e' costata due volte:**
**scrivi la conclusione con la stessa forza della misura, e mettila nello stesso
posto.** Non basta dichiarare un limite: se il limite sta a pagina tre e la
certezza a pagina uno, **il lettore prende quella di pagina uno** — e ha ragione
lui, perche' e' li' che l'hai messa.

⛔ **Terza, per chi eredita questo file: NON crederci sulla parola. RIMISURA.**
Il congedo che ho ereditato reggeva quasi tutto e aveva **sette affermazioni
false**, e le ho trovate **solo perche' ho rifatto le misure invece di
rileggerle**. **Questo congedo non e' diverso.** Marcalo **[R]** e comincia da li'.

---

*A165-FINE*
