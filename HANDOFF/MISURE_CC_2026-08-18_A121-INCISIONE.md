# MISURE CC — A121, INCISIONE DELLA SCHEDA ⟦S5b⟧

Da: CC · A: Mauro + referee · 18/08/2026
⛔ **NESSUN COMMIT, NESSUN PUSH.** HEAD invariato a `44fea3e378414c300ffd50fcac527c683740735b`.
⛔ **Zero righe sotto `ios_app/`.** Perimetro: `SCALETTA` + `BUGS`, e nient'altro.

Marcatura: **[M]** misurato ora, da me · **[R]** riportato · **[A]** giudizio mio.

---

## ⚠️ DUE DIFETTI MIEI, TROVATI E RIPARATI PRIMA DI CONSEGNARE

Li dichiaro perché sono **miei**, nati in questo giro, e perché il secondo era invisibile a occhio.

**① Fini-riga miste in `BUGS`.** La prima applicazione ha inserito 21 righe **LF** in un file la
cui faccia disco è **CRLF** (`text: unspecified`): il file è diventato **misto** — 1067 CRLF +
21 LF-sole. ⛔ Ripristinato da HEAD e rifatto adattando le righe inserite alla faccia del bersaglio.
**Controprova sul bersaglio, ora nel processo:** `BUGS` → **1088 CRLF, 0 LF-sole**;
`SCALETTA` → **456 LF, 0 CRLF**. Entrambi **omogenei**.

**② Avrei spezzato due puntatori interni al ticket `TD-emerg-bottone-morto`.** La marcatura di
`BUGS:167` andava messa a `:168` — dove morde. Ma il ticket contiene già una marcatura (`:171`)
che cita **per numero** i bullet `:168` e `:170`: inserire a `:168` li avrebbe spostati entrambi.
⇒ **Ho posato la mia marcatura in coda al ticket (`:172`), dopo quella esistente**, e ho scritto
**dentro la marcatura stessa** perché non sta sotto il suo bersaglio. **[M] Verificato dopo la
scrittura:** `:163`, `:167`, `:168`, `:170` puntano ancora al loro contenuto originale.

---

# B1 · SCALETTA

**[M] 1. La scheda ⟦S5b⟧, VERBATIM da A118.** Non l'ho ribattuta: l'ho **estratta
programmaticamente** dall'artefatto `HANDOFF/MISURE_CC_2026-08-18_A118-SCHEDA-STRETTA.md`
(righe 48-150, blockquote, prefisso `> ` rimosso) e innestata in sezione B **dopo ⟦S5⟧**, prima
di ⟦S6⟧.
**Controprova a scrittura avvenuta:** **103 righe confrontate una a una contro l'artefatto,
DIVERGENTI 0.**

**[M] 2. Il titolo di sezione è MARCATO, non riscritto.** `## B · Scaletta 12 atomi …` resta
**identico**; subito sotto è stata posata una riga di marcatura che dichiara che gli atomi sono
**tredici**, che il conteggio «12» va letto come storia, e che chi ricontasse le intestazioni e
trovasse 13 **non ha trovato un difetto**.
**Controprova:** intestazioni `###` in sezione B → **13**.

⛔ **Sezione C: NON toccata**, come disposto.

---

# B2 · BUGS — due ticket nuovi

**[M] ① `TD-countin-ratificato-mai-costruito`** — in coda a §1.2, **9 bullet**.
Porta: la ratifica a tre punti (`LIBRO:166`) col motivo di palco (`LIBRO:225`) · i tre punti
**tutti non costruiti**, ciascuno con la sua riga · le **due interruzioni indipendenti** della
catena · l'avvertimento sui **tre oggetti diversi** che si chiamano `countIn` · la nota che il
`countdown: 4` **è il valore ratificato mostrato senza suono** · e che al collaudo di ⟦S5b⟧
«parte subito, senza conto» **non va segnalato come guasto**.
Severità **🟠 OPEN MEDIA — PROPOSTA, non assegnata**, con il contro-argomento dichiarato.

**[M] ② `TD-canonici-puntatori-path-stale`** — in coda a §1.3, **8 bullet**.

**[A] La scelta fra le due strade, e l'argomento — come chiesto, tecnico e non di prodotto:**
**ho aperto un ticket proprio**, NON allargato `TD-doccomment-navigate-zero-chiamanti`.
Il motivo sta nella **condizione di chiusura**, che quel ticket dichiara di sé: «⛔ NON si tocca
in un giro doc-only: è **codice**. Si traccia qui e si corregge nel primo atomo che apre quel
file». Un puntatore stale **dentro un canonico** ha la condizione **opposta**: si chiude **in un
giro doc-only** e non ha alcun atomo di codice che lo apra. ⇒ Fonderli darebbe a un ticket solo
**due condizioni di chiusura che si escludono a vicenda** — che è il difetto «un nome per due
contratti» già pagato con ⟦S4L⟧ e inciso in `LIBRO_MASTRO_QBEATS.md:334`.
⇒ I due si **citano** e non si fondono; e nel nuovo ticket ho registrato che
`TD-doccomment-navigate-zero-chiamanti` porta **lo stesso difetto su di sé** (cita `:85` e `:145`;
a HEAD il bersaglio è `:87`), **lasciando la riparazione a quel ticket**.
Severità **🟡 OPEN BASSA — PROPOSTA, non assegnata**, col contro-argomento dichiarato (è in un
canonico, e i canonici sono la superficie su cui si verifica tutto il resto).

---

# B3 · BUGS — due marcature su righe misurate FALSE

⛔ **Il testo storico non è stato toccato in nessuna delle due.** Si marca, non si riscrive.

**[M] ① su `BUGS:167`** — «Il sesto è l'unico muto». La marcatura registra che **tre dei cinque**
che il bullet dichiara «chiamano codice reale» chiamano funzioni **vuote**
(`AudioEngine.swift:1267-1269`), col **controllo positivo** su `stopBacktrack` che ha corpo vero
(`:1522-1526`); che i tasti muti sono **quattro su sei**; che resta vera una distinzione di
**forma** ma non di **effetto**; e che **il perimetro del ticket non si allarga qui**.
⚠️ Posata a `:172` e non a `:168`, per la ragione del ② in testa, **scritta dentro la marcatura**.

**[M] ② su `BUGS:288`** — «l'equivalente UI mid-play ESISTE ⇒ MIDI = mirror del TAP».
⛔ Marcata **URGENTE**, come disposto. La marcatura registra che il **tap esiste e l'effetto no**,
che la conclusione «mirror del TAP» **resta vera alla lettera e per questo è pericolosa**, e la
conseguenza operativa: **il ticket non può chiudersi cablando il MIDI** finché l'equivalente UI non
fa qualcosa. Col controllo positivo su `stopBacktrack`, per cui **lo specchio è sano**.
**[M]** Il ticket MIDI non ha riferimenti interni per numero di riga (**0**), quindi qui l'inserzione
subito sotto il bersaglio non spezza nulla.

---

# B4 · COSA CONSEGNO

## 1 · I diff — artefatti separati, VERBATIM, riga per riga

⛔ **Non li riassumo qui: il diff è l'artefatto**, ed è depositato come `.txt` accanto a questo
referto — protocollo CONSEGNA-GATE.

| file | byte | sha256 |
|---|---:|---|
| `HANDOFF/DIFF_2026-08-18_A121-SCALETTA-S5b.txt` | 11 651 | `9dcb8b85ec18749596b403611003048fa0667eef28a3b41cb80d2c7854540dd7` |
| `HANDOFF/DIFF_2026-08-18_A121-BUGS.txt` | 16 850 | `1451c95328a5473bcac086b91cd52f7f12607eebaf95bb9ad96fab177a13e2c9` |

**[M] Controprova che vale, e non `--check`:** `git apply -R --check` → **OK su entrambi**, cioè
i diff descrivono davvero la trasformazione da HEAD allo stato su disco e sono reversibili.
Totale: **2 file, 127 inserzioni, 0 cancellazioni** — nessuna riga esistente è stata rimossa
o modificata in nessuno dei due canonici.

## 2 · Impronte prima / dopo

**[M]**

| file | | sha256 | byte | righe | CR |
|---|---|---|---:|---:|---:|
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | **prima** | `09bf3442a372a17e66dda7d53ca512e0d1bc551e80f42d2c7a08614811d84fe5` | 56 791 | 350 | 0 |
| | **dopo** | `f3e201b33e947d3e549adeb3f50a3387874435e048f4d27e7a94360cda4b267b` | 65 384 | 456 | 0 |
| `BUGS_QBEATS.md` | **prima** | `0d89110117a3ef4b823a0b529028327c84464849a23866028baa529d6480f0f3` | 300 839 | 1 067 | 1 067 |
| | **dopo** | `5261157b2236d5fe1317b20f7b136eb3a26832aa1c3025b15f342f92b17411df` | 310 426 | 1 088 | 1 088 |

⚠️ **Le impronte sono della FACCIA DISCO.** `SCALETTA` è LF (`CR 0`), `BUGS` è CRLF
(`CR = righe`): sono due facce diverse e vanno dichiarate, non confrontate fra loro.
**[M] Omogeneità verificata dopo la scrittura:** `SCALETTA` 456 LF / 0 CRLF · `BUGS` 1088 CRLF /
0 LF-sole.

## 3 · Cosa NON ho inciso, e perché

- ⛔ **Sezione C** — esclusa dal mandato.
- ⛔ **Il bump di versione dei due canonici** — il mandato autorizza «solo per quanto sotto», e il
  bump non è fra le voci. ⚠️ **Va deciso nel giro di deposito**, perché la convenzione di casa lo
  prevede a ogni modifica di canonico.
- ⛔ **`LIBRO_MASTRO_QBEATS.md`** — fuori perimetro. **E qui c'è un collaterale che devo
  dichiarare, non nascondere:** vedi sotto.
- ⛔ **Le altre otto porte mancanti** censite in A117 — nessun ticket aperto qui: il censimento va
  alla chat CC nuova.
- ⛔ **La decisione sull'artefatto A117** — resta pendente, come segnalato in apertura di A118.

### ⚠️ IL COLLATERALE, misurato e non riparabile in questo perimetro

**[M]** L'innesto della scheda sposta di **+106 righe** tutto ciò che segue in `SCALETTA`.
Una citazione **NUDA** a questo file, con riga nella regione spostata, esiste ed è **una sola**:

- `LIBRO_MASTRO_QBEATS.md:356` cita `SCALETTA_ATOMI_S6_2026-07-10.md:329` **senza ancora di commit**.
- Il contenuto che stava a `:329` («1. "+" create → SUPERATO da CD-Q7…») ora sta a **`:435`**.
- ⇒ **Quella citazione oggi punta alla riga sbagliata.**

**[M] Le altre due citazioni nella regione sono IMMUNI** perché **ancorate a commit**:
`LIBRO:…:314 @ …` e `BUGS:…:322 @ 2960f089…`.

⚠️ **E la marcatura che avrebbe dovuto proteggere questa regione è STALE.** `SCALETTA:324`
(marcatura A102) dichiara «zero citazioni **nude** a questo file con riga ≥320». **[M] Era VERA
al suo commit** (`779172e6` → **0**) ed è **FALSA a HEAD** (→ **1**): la citazione nuda è stata
introdotta **dopo**, dalla riga `2026-08-18` di LIBRO sui pulsanti inerti.
⇒ **Chi si fidasse di quella marcatura per dire «inserire qui è sicuro» concluderebbe male.**

⛔ **Non l'ho riparata e non ho toccato LIBRO: è fuori perimetro.** La riparazione è di una riga e
ha due forme possibili — aggiornare il numero a `:435`, oppure **ancorare la citazione a un
commit**, che la renderebbe immune per sempre. **Non scelgo io.**

---

## COSA NON HO FATTO

⛔ Nessun commit, nessun push, nessuna riga sotto `ios_app/`, nessun canonico fuori dai due
autorizzati. Non ho riaperto né riformulato la scheda: **103 righe su 103 identiche ad A118**.

⚠️ **Lacuna dichiarata:** nessuna verifica indipendente. I due difetti in testa li ho trovati io,
ma solo perché ho misurato **dopo** aver scritto — il primo giro di scrittura li conteneva
entrambi.

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1.

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `a69bc51a22808ca5be8bd5109893e9662d428074cbe68f3dc457df1f5d323837`
- **byte** (file completo): `10726`
- **righe** (file completo): `194`
- **CR** (0x0D, contati sui byte, mai con grep): `0`
- **byte NUL** (0x00, controprova sul bersaglio): `0`

---

*A121-INCISIONE-FINE*
