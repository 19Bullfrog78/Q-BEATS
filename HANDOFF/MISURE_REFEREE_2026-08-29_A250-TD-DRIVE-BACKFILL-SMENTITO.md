# MISURE REFEREE — A250 — `TD-drive-backfill` SMENTITO, e il difetto vero che ne esce

**Data:** 2026-08-29 · **HEAD:** `2e1d542cf10e13d08d3956619f4884fc4ddd9f45` (verificato a fonte, sha a 40: `git log -1` = `git rev-parse origin/master`)
**Autore:** referee entrante (prima sessione) · **Mandato:** A250
**Cancello ID A250 — quattro gambe, controlli positivi non ciechi:**

| gamba | A250 | A249 (ctrl+) | A247 (ctrl+) |
|---|---|---|---|
| nome (`git ls-files`) | 0 | 1 | 1 |
| contenuto (`git grep HEAD -- ':!DESIGN'`) | 0 | 4 | 6 |
| disco (`ls HANDOFF/`) | 0 | 1 | 2 |
| commit (`git log --all --grep`) | 0 | 1 | 1 |

⇒ A250 libero su tutte e quattro. Gamba commit inclusa per la **regola di metodo 6** (BOX5 V37): una sonda ID senza `git log --grep` ha un buco. Gamba contenuto con `':!DESIGN'` per **R-δ.10**.

---

## 1 · VERDETTO

⛔ **`TD-drive-backfill` NON entra in BUGS. La sua premessa è FALSA, e la misura che la sostiene è stata presa con uno strumento che questo progetto ha già dichiarato CIECO, per iscritto, otto giorni fa.**

Il ticket afferma: *«la gamba Drive (`Il mio Drive/Qbeats/`, mount locale `I:`) era ferma al 21/08/2026 su tutte e quattro le sottocartelle»* e *«Mancano BOX5 V29-V36, BUGS 60-68, LIBRO 55-64»*.

**Entrambe le affermazioni sono falsificate dalla misura in §2.**

⚠️ **Ciò che il ticket ha di GIUSTO, e che sopravvive al blocco:** la sua riga più forte — *«prima del backfill va misurato SE il riflesso funziona»* — è corretta come metodo, ed è precisamente la misura che il ticket **non ha fatto**. Il blocco non è sulla prudenza: è sulla conclusione data per certa senza quella misura.

---

## 2 · LA MISURA — dal lato cloud, non da `I:`

**Strumento:** connettore Google Drive (interrogazione dell'API dal lato cloud). ⚠️ **È lo stesso lato da cui BOX5 V37 § «R-δ · 6 · CARTELLO DI RETTIFICA — A159» dichiara che il referee aveva già verificato il riflesso il 21/08.** Non è lo strumento del ticket.

### 2.1 · Su Drive esistono DUE alberi, e le loro sottocartelle portano lo STESSO NOME

| albero | id cartella radice | nata il | natura |
|---|---|---|---|
| `FILE X CLAUDE.MD` | `1BSsFiju0nt1xbXZZYvg5OPex0B-RzoZn` | **2026-08-01T15:47:13Z** | **il RIFLESSO di `E:`** |
| `Qbeats` (sotto la radice `0AM1aRMB96q77Uk9PVA`) | `1GNzk9WUIrB7g-5T-npAIOGldRI0SGGBc` | **2026-08-01T13:09:36Z** | **l'albero MANUALE abbandonato** = `I:\Il mio Drive\Qbeats\` |

⇒ **Le due date coincidono al secondo con BOX5 V37, § R-δ.4**, che le incide entrambe **senza che questa misura le abbia usate come input**: *«albero manuale creato il 01/08/2026 alle **13:09**, due ore e mezza **prima** che nascesse il riflesso di `E:` (**15:47**)»*. Corroborazione **non circolare**: la fonte documentale e la misura API sono indipendenti.

Sotto entrambi esiste una cartella `BOX5_Test` (`1807XG5S…` nel riflesso · `1YzkAWUT…` nell'albero manuale), una `BUGS_QBEATS`, una `LIBRO_MASTRO`. **Stessi nomi, alberi diversi.**

### 2.2 · Il riflesso NON si è mai fermato

Contenuto del **riflesso** (`FILE X CLAUDE.MD`), per data di creazione del file su Drive:

| file | creato su Drive | peso |
|---|---|---|
| `BOX5_V34_2026-08-26_88acb31.md` | 2026-08-26T10:46:16Z | 92 445 |
| `BOX5_V35_2026-08-27_ee9d20c.md` | 2026-08-27T16:56:29Z | 108 187 |
| `BOX5_V36_2026-08-28_e13b192.md` | 2026-08-28T12:40:51Z | 110 163 |
| `BOX5_V37_2026-08-29_2e1d542.md` | 2026-08-29T11:08:38Z | 113 042 |
| `LIBRO_MASTRO_QBEATS_v63_2026-08-24_8727f8e.md` | 2026-08-24T10:40:44Z | 296 211 |
| `LIBRO_MASTRO_QBEATS_v64_2026-08-26_619be20.md` | 2026-08-26T10:03:38Z | 300 590 |
| `LIBRO_MASTRO_QBEATS_v65_2026-08-29_2e1d542.md` | 2026-08-29T11:08:38Z | 309 039 |
| `BUGS_QBEATS_v68_2026-08-28_e13b192.md` | 2026-08-28T12:40:51Z | 419 936 |
| `BUGS_QBEATS_v69_2026-08-29_2e1d542.md` | 2026-08-29T11:08:38Z | 429 392 |
| `BUGS_QBEATS.md` (nome fisso) | modificato 2026-08-28T12:40:51Z | 419 936 |
| `LIBRO_MASTRO_QBEATS.md` (nome fisso) | modificato 2026-08-26T07:21:53Z | 300 590 |

⇒ **Arrivi il 24, il 26, il 27, il 28 e il 29 agosto.** «Ferma al 21/08» è falso. «Mancano BOX5 V29-V36 / LIBRO 55-64 / BUGS 60-68» è falso almeno su **BOX5 V34·V35·V36**, **LIBRO v63·v64**, **BUGS v68** — sei file, tutti presenti, tutti datati nel periodo dichiarato vuoto.

### 2.3 · L'albero manuale è fermo perché NESSUNO CI SCRIVE, per decisione

BOX5 V37, § R-δ.4 «CIÒ CHE NON È UNA DESTINAZIONE», verbatim:

> **`I:\Il mio Drive\Qbeats\`** — albero manuale creato il 01/08/2026 alle 13:09 […] **Non e' piu' una destinazione: non si scrive.** ⛔ **Non si cancella e non si sposta:** resta agli atti.

⇒ **Una cartella che nessuno aggiorna, per regola scritta, risulta ferma. Non è un guasto: è la regola che funziona.**

---

## 3 · È LA SECONDA VOLTA, E IL CARTELLO ESISTEVA GIÀ

BOX5 V37, § R-δ.6, verbatim:

> Il referto `HANDOFF/MISURE_CC_2026-08-21_A159-CENSIMENTO-TRE-GAMBE.md` conclude in prima riga che **la sincronizzazione E: → Drive e' ferma da meta' agosto**.
> ⛔ **La conclusione e' FALSA. La misura era GIUSTA.**
> `I:` e' Drive montato come disco e **non rimonta la sezione «Il mio computer» della macchina locale**: da li' il riflesso e' **invisibile per costruzione**, e lo zero misurato su `I:` e' uno zero vero che non dice nulla su Drive.

⇒ **Stesso strumento, stesso buco, stessa conclusione, otto giorni dopo — con il cartello di rettifica già inciso in un canonico.**

⚠️ **Il reperto che vale più del ticket:** il cartello **c'era e non ha fermato la ripetizione**. Sta in BOX5 §R-δ.6, cioè nel capitolo «dove vanno i file», che si legge quando si depositano file — **non** quando si misura una gamba. Chi misurava non è passato di lì. ⛔ **Non propongo il rimedio qui:** dove vada l'avviso è materia di un giro doc, non di questo referto.

---

## 4 · CIÒ CHE NON È STATO MISURATO — dichiarato, non taciuto

1. ⚠️ **NON è provato che il riflesso sia COMPLETO file per file** contro i ~370 di `E:`. Ho falsificato **«ferma dal 21/08»**; **non** ho dimostrato **«integra»**. Il limite è già dichiarato in BOX5 §R-δ.6 (*«il referee ha verificato che il riflesso riceve, non che sia completo»*) e **resta aperto identico**. Nessuno citi questo referto per dire che Drive è una copia integrale.
2. ⚠️ **NON ho enumerato le versioni più vecchie** — BOX5 V29-V33, LIBRO v55-v62, BUGS v60-v67. Le ricerche hanno reso la prima pagina di risultati. Che manchino **alcune** di quelle resta possibile; che manchino **tutte** è falso, ed è ciò che il ticket afferma.
3. ⚠️ **NON ho verificato i byte** dei file su Drive: ho confrontato **nomi, date e pesi**. I pesi dei sei doppioni coincidono con i blob a HEAD (BUGS 429 392 · LIBRO 309 039 · BOX5 113 042), ma **un peso uguale non è un `cmp`**.
4. ⚠️ **NON ho misurato `I:`**: non è collegato a questa sessione. La misura di CC su `I:` **non è contestata** — è la conclusione tratta da essa che è falsa. Come in A159: **la misura era giusta, la conclusione no.**

---

## 5 · IL DIFETTO VERO — nasce dal RIMEDIO, non dalla diagnosi

Il ticket riporta: *«COLMATO SOLO IL SALTO DI OGGI (A249): sei snapshot depositati alle 11:08, due gambe»*.

**Misurato:** i sei file del 29/08 esistono su Drive **in DUE alberi**, con **nome identico** e **peso identico**:

| file | nel riflesso | nell'albero manuale |
|---|---|---|
| `BOX5_V37_2026-08-29_2e1d542.md` | `11CQceVZ6RX4fmB-KGYcTqjcfXENbHcp5` | `1_p6dwPBGulewKiUZF3UHN7AMxmhoYUfY` |
| `BUGS_QBEATS_v69_2026-08-29_2e1d542.md` | `1DsPROKXisNtUb5nmwbkLNsI9Uc_v3DE6` | `1GyEtTgSAdzYnzkS7J6kP4fy3Qyh1p77z` |
| `LIBRO_MASTRO_QBEATS_v65_2026-08-29_2e1d542.md` | `1nwPAKvRbPCR_UTJP1DX588ZatlJdntEQ` | `1zmSzZ0lPv0cB1Ogu5rAYGU73BFYYeGWR` |

⇒ **Si è scritto nell'albero che R-δ.4 vieta di scrivere**, e si è costruita una **trappola-per-nome** dentro il sistema di archiviazione: due cartelle `BOX5_Test`, due `BUGS_QBEATS`, due `LIBRO_MASTRO`, ciascuna con un file dallo stesso nome.

🚨 **Perché morde nel tempo, non oggi:** oggi le due copie sono dello stesso peso. Il riflesso però **continua a crescere** e l'albero manuale **no**. Fra una settimana chi naviga Drive per nome può atterrare sul ramo morto e leggere un canonico **stale credendolo corrente** — senza alcun segnale. È la stessa forma delle **due SCALETTA omonime e divergenti** e dei **due fogli CD del 25/08 distinguibili solo per peso**.

---

## 6 · DA INCIDERE IN BUGS — due voci, doc-only, zero codice

### 6.1 · Sezione 1.3 (🟡 OPEN BASSA) — ticket NUOVO, in coda alla sottosezione

```
### TD-drive-doppioni-albero-abbandonato — i canonici di oggi esistono due volte su Drive, in due cartelle omonime (🟡 OPEN BASSA / doc-hygiene — famiglia «trappola per nome-file» — **PROPOSTA del referee, gravità non ratificata da Mauro**)

- **Fatto, misurato dal lato cloud il 29/08 (referto A250):** i sei snapshot canonici del 29/08 sono stati depositati **anche** in `I:\Il mio Drive\Qbeats\` (albero radice `1GNzk9WUIrB7g-5T-npAIOGldRI0SGGBc`, nato 2026-08-01T13:09:36Z), che **BOX5 V37 §R-δ.4 dichiara NON essere una destinazione**: «Non e' piu' una destinazione: non si scrive».
- **Conseguenza misurata:** BOX5 V37, BUGS v69 e LIBRO v65 esistono su Drive **due volte**, con **nome identico e peso identico**, sotto due cartelle **omonime** (`BOX5_Test`, `BUGS_QBEATS`, `LIBRO_MASTRO`) appartenenti a due alberi diversi — il riflesso di `E:` (`1BSsFiju0nt1xbXZZYvg5OPex0B-RzoZn`, nato 15:47) e l'albero manuale (nato 13:09).
- 🚨 **Il danno è DIFFERITO, non immediato.** Oggi le copie coincidono di peso. Il riflesso continua ad aggiornarsi, l'albero manuale no ⇒ **la divergenza è garantita nel tempo**, e chi naviga per nome può leggere un canonico stale credendolo corrente. Stessa forma delle due `SCALETTA` omonime divergenti (BOX3 V97 (g)) e dei due fogli CD del 25/08 distinguibili solo per peso (`DESIGN/QLive_Nav/README.md`).
- **Origine:** il deposito fu eseguito credendo rotto il riflesso di `E:`. **La premessa è falsa** — vedi la voce `TD-drive-backfill` in Sezione 3.
- **Rimedio proposto, NON eseguito:** rimuovere i sei file dall'albero manuale ⚠️ **e NON l'albero** — R-δ.4 dice «non si cancella e non si sposta: resta agli atti». ⛔ **Da fare solo dopo che qualcuno ha VISTO che i sei esistono nel riflesso** (misurati presenti in A250, ma il controllo va rifatto al momento della rimozione: un'impronta di ieri non autorizza una cancellazione di oggi).
- ⚠️ **Debito adiacente, NON risolto qui:** resta aperto e invariato il dubbio di BOX5 §R-δ.6 — nessuno ha mai verificato che il riflesso sia **completo** file per file contro `E:`. A250 ha falsificato «fermo», non dimostrato «integro».
- **Dominio:** referee (misura) → Mauro (cancellazione, è azione manuale sua su Drive).
```

### 6.2 · Sezione 3 — Bug SCARTATI / SMENTITI (per evitare ri-aperture)

```
### TD-drive-backfill — «sette giorni di canonici mai propagati sulla gamba Drive» — ⚫ SCARTATO 29/08/2026, premessa falsificata

- **Proposto** dal referee uscente il 29/08 su misura di CC: la gamba Drive sarebbe stata «ferma al 21/08/2026 su tutte e quattro le sottocartelle», con mancanti BOX5 V29-V36, BUGS 60-68, LIBRO 55-64.
- ⛔ **FALSIFICATO dal lato cloud il 29/08 (referto A250).** Nel **riflesso di `E:`** (`FILE X CLAUDE.MD`, `1BSsFiju0nt1xbXZZYvg5OPex0B-RzoZn`, nato 2026-08-01T15:47:13Z) sono presenti e datati nel periodo dichiarato vuoto: **BOX5 V34** (26/08) · **V35** (27/08) · **V36** (28/08) · **LIBRO v63** (24/08) · **v64** (26/08) · **BUGS v68** (28/08). Il riflesso non si è mai fermato.
- **La misura di CC su `I:` NON è contestata: è la conclusione tratta da essa.** `I:` monta `Il mio Drive` e **non rimonta la sezione «Il mio computer»**, dove vive il riflesso ⇒ da lì il riflesso è **invisibile per costruzione**. La cartella che `I:` mostra è l'**albero manuale abbandonato** (nato 13:09), che è fermo perché **R-δ.4 vieta di scriverci**.
- 🚨 **SECONDA OCCORRENZA DELLO STESSO ERRORE.** La prima è A159 (21/08), già rettificata in **BOX5 V37 §R-δ.6**. ⇒ **Il cartello esisteva e non ha fermato la ripetizione**: sta nel capitolo «dove vanno i file», che si legge depositando, non misurando. ⛔ Registrato, **non risolto**: dove vada l'avviso è materia di un giro doc.
- ⚠️ **Ciò che del ticket resta VALIDO e non è scartato con lui:** la sua riga di metodo — «prima del backfill va misurato SE il riflesso funziona» — è corretta, ed è esattamente la misura che mancava. E il dubbio di BOX5 §R-δ.6 sulla **completezza** del riflesso **resta aperto**: A250 ha falsificato «fermo», non ha dimostrato «integro».
- **Difetto vero emerso dal rimedio:** ticket `TD-drive-doppioni-albero-abbandonato`, §1.3.
```

---

## 7 · RIGA DA INCOLLARE NEL PROMPT DI COMMIT PER CC

> **Ratifica referee A250, 29/08/2026 — `TD-drive-backfill` SMENTITO dal lato cloud; due voci doc-only da incidere in `BUGS_QBEATS.md`, zero codice, zero riscritture: (1) ticket NUOVO `TD-drive-doppioni-albero-abbandonato` in coda a §1.3 · (2) voce `TD-drive-backfill` in Sezione 3 (scartati/smentiti). Testi verbatim in `HANDOFF/MISURE_REFEREE_2026-08-29_A250-TD-DRIVE-BACKFILL-SMENTITO.md` §6.1 e §6.2. Header bump 69→70 + riga in Sezione 5. ⛔ Nessuna riga esistente si riscrive. Cancello Mauro: APERTO — la gravità 🟡 del ticket nuovo è PROPOSTA del referee, non ratificata.**

---

## 8 · DEPOSITO — consegna INCOMPLETA, dichiarata

- ✅ **Gamba `C:`** — questo file in `HANDOFF/`, scritto.
- ⛔ **Gamba `E:` — NON SCRITTA.** `E:` non è collegato a questa sessione: il referee non può raggiungerlo. ⚠️ **Per la regola «PUSHATO ≠ PROPAGATO» (BOX3 §7) la consegna NON è chiusa.** Chi ha accesso a `E:` copi questo file in `E:\…\FILE X CLAUDE.MD\HANDOFF\` — e **solo allora** Drive lo rifletterà da solo.
- ⛔ **Su Drive non si scrive** (R-δ.4). Il riflesso arriva da `E:`.
