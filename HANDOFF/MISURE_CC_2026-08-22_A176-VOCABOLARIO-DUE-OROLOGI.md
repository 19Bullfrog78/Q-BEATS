# MISURE CC — A176 · VOCABOLARIO DEI DUE OROLOGI

Da: CC · A: **referee** (+ Mauro)
Mandato: `A176-VOCABOLARIO-DUE-OROLOGI` · **SCRITTURA SUI CANONICI, NESSUN COMMIT**
Controllo di completezza sul mandato ricevuto: **7 sezioni (§0→§6) presenti, ultima riga
`A176-FINE-MANDATO` — integro.** A174 e A175 registrati come annullati, non eseguiti.
Modello: **Sonnet 5**, impostato da Mauro prima del mandato, coincide con l'intestazione.

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato da altri, non
rimisurato · **[A]** giudizio mio.
⛔ **Nessun file sotto `ios_app/` toccato. Nessun commit. Nessuno stage (`git add`).**
Le tre scritture sono **nel working tree, non committate**: Mauro le autorizza dopo aver
letto questo testo.

---

## §0 · ID `A176` — LIBERO, con una QUARTA classe di rumore

**[M] Sonda per nome (potata):** 0 su repo, 0 su E:. Controllo positivo forma identica
(`A175`): 0/0 — atteso, A175 fu annullato senza lasciare artefatti.

**[M] Sonda per contenuto — 3 hit sul REPO, non 0.** Non erano rumore di device: erano
**due referti precedenti che usavano la stringa `A176` come esempio didattico del proprio
controllo negativo**, scritti quando l'ID era davvero libero:

```
HANDOFF/CONGEDO_CC_2026-08-21_NOTTE.md:144
| A176 | 0 | 0 | 0 | 0 | controllo **negativo** |

HANDOFF/CONGEDO_CC_2026-08-22_A166-A170.md:219-220
Il controllo **negativo** `A176`, che deve rendere zero, rendeva **1 su repo e 7
su E:**: sei `LOG/RUN/…/td17_*.log` contengono `[1A176]` come request-id WiFi.

HANDOFF/MISURE_CC_2026-08-21_A166-CONTATORE-BATTUTA-ORIGINE.md:30,62,64
(stesso contenuto, riportato nel referto sorgente)
```

⇒ **[A] Quarta classe di rumore, distinta dalle tre note:** un ID può risultare
«occupato» perché una sessione precedente l'ha usato come cavia nella propria
metodologia di verifica, non come mandato reale. **[M] Nessun uso semantico reale di
A176 come mandato**, su nessuna delle due gambe. **A176 è LIBERO.**

---

## §1 · SEDE DEL VOCABOLARIO — verbatim delle due righe

**[M] `BOX5_QBEATS.md:143-145 @ 4629ee9`, verbatim, byte per byte dal blob:**

```
143	---
144	(riga vuota)
145	## Vista LIVE — Spec complete
```

Sede confermata: il nuovo capitolo si innesta fra la riga 143 (`---`) e la riga 145
(l'intestazione di Vista LIVE), con un proprio `---` di chiusura prima di essa — stessa
convenzione con cui OGNI sezione `##` di BOX5 è separata dalla precedente.

---

## §2 · BOX5 — vocabolario inserito, verbatim prima/dopo

**[M] Faccia del file:** `.gitattributes` porta `-text` su `BOX5_QBEATS.md` → disco e
blob coincidono byte per byte (nessuna faccia CRLF). Verificato: `cmp` disco↔blob HEAD
= **IDENTICO** prima di editare.

### Edit 1 — intestazione versione

PRIMA:
```
**Versione:** V29 — 21/08/2026
```
DOPO:
```
**Versione:** V30 — 22/08/2026
```

### Edit 2 — nuovo blocco Delta, inserito PRIMA di «Delta V29 vs V28»

PRIMA (righe 4-6):
```
> **Regola di aggiornamento:** aggiornare BOX5 quando cambiano spec, modello dati, token visivi, o invarianti Layer 3. NON aggiornare per avanzamento build o fix — quello va in BOX3.

**Delta V29 vs V28:**
```
DOPO:
```
> **Regola di aggiornamento:** aggiornare BOX5 quando cambiano spec, modello dati, token visivi, o invarianti Layer 3. NON aggiornare per avanzamento build o fix — quello va in BOX3.

**Delta V30 vs V29:**

- **Capitolo NUOVO «VOCABOLARIO DEI DUE OROLOGI».** Lessico che separa il conteggio del motore audio da quello della grafica, e nomina i due punti dove lo scarto si vede (accento/primo verde dentro la battuta; cambio suonato/cambio scritto fra le sezioni). Ratificato Mauro 22/08/2026 (mandato A176). **Solo due nomi sono ratificati da Mauro**: ACCENTO SONORO e PRIMO VERDE. **Quattro restano proposti dal referee, non ancora ratificati**: OROLOGIO MOTORE, OROLOGIO GRAFICA, CAMBIO SUONATO, CAMBIO SCRITTO — da tagliare se Mauro non li conferma al cancello.

Tutto il resto invariato da V29.

**Delta V29 vs V28:**
```

⚠️ **[A] Questa riga di changelog l'ho scritta io**, seguendo la regola R7.2 di LIBRO
(sotto, §5) che impone il bump di versione a ogni contenuto cambiato — il mandato non
me l'aveva data verbatim. È puro bookkeeping (nome del capitolo + stato di ratifica),
non contenuto nuovo: **tagliabile o riformulabile da Mauro senza toccare il vocabolario.**

### Edit 3 — il capitolo, testo del §2 del mandato VERBATIM, senza una parola cambiata

Inserito fra la riga 143 (`---`) e la riga 145 (`## Vista LIVE`), con apertura `##` propria
(la sede ratificata in §1) e chiusura `---` prima di «Vista LIVE», stessa forma di ogni
altra sezione del file:

```
---

## VOCABOLARIO DEI DUE OROLOGI — ratificato Mauro 22/08/2026

Il metronomo tiene DUE conteggi distinti, che possono divergere:
· OROLOGIO MOTORE — il conteggio dei battiti tenuto dal motore audio.
  Riparte da zero SOLO quando il motore viene fermato e riavviato.
· OROLOGIO GRAFICA — il conteggio su cui il display costruisce battute e
  sezioni. Riparte da zero a OGNI rientro nel player.

Lo scarto fra i due si vede in due punti, che vanno SEMPRE nominati separati:

dentro la battuta:
 · ACCENTO SONORO — il click a frequenza diversa, prodotto dal motore audio
 · PRIMO VERDE — il pallino verde del primo movimento, acceso dalla grafica

fra le sezioni:
 · CAMBIO SUONATO — il motore comincia a suonare la sezione successiva
 · CAMBIO SCRITTO — il display aggiorna nome e numero della sezione

⛔ VIETATE le forme «l'accento è sfasato», «l'accento è sbagliato», «la
sezione è sbagliata». Sono FALSE: ciascun orologio è corretto rispetto a sé
stesso. Le forme corrette sono:
 · «l'ACCENTO SONORO non cade sul PRIMO VERDE»
 · «il CAMBIO SCRITTO non coincide col CAMBIO SUONATO»
L'oggetto del difetto è LA DISTANZA FRA DUE OROLOGI, non un accento rotto.

⚠️ QUATTRO NOMI PROPOSTI DAL REFEREE E NON ANCORA RATIFICATI DA MAURO:
CAMBIO SUONATO, CAMBIO SCRITTO, OROLOGIO MOTORE, OROLOGIO GRAFICA.
Ratificati da Mauro solo: ACCENTO SONORO e PRIMO VERDE. Se Mauro non
ratifica gli altri quattro al cancello, vanno tagliati prima del commit.

---

## Vista LIVE — Spec complete
```

**[M] Verifica automatica di corrispondenza:** confrontato programmaticamente col blocco
del mandato — **0 differenze di carattere** nel corpo del vocabolario (titolo escluso, a
cui ho solo anteposto `## ` per farne un'intestazione di sezione, coerente con TUTTE le
altre intestazioni di BOX5, es. `## Invarianti tecnici Layer 3 — INVIOLABILI`).

---

## §3 · LIBRO — riga di rinvio, verbatim prima/dopo

**[M] Faccia del file:** NON in `.gitattributes` → CRLF su disco, LF nel blob (due
facce). Editato sul disco (CRLF), che è la faccia viva del working tree; al commit git
rinormalizza a LF nel blob, come fa sempre per questo file — non è un'azione mia.

### Edit 1 — header (tre righe)

PRIMA:
```
**Versione:** 59 (21/08/2026)
**Ultima modifica:** 2026-08-21 (v59 — **una riga sola in Sez.2, doc-only, zero codice**: la gamba «Drive scritto a mano» esce dal regime R-δ — quattro destinazioni, **due sole scritture** — e la sede operativa diventa il capitolo «R-δ — dove vanno i file» di **BOX5 V29**. Agli atti la rettifica della conclusione di A159: **falsa la conclusione, giusta la misura**. Le righe `2026-08-01` e `2026-08-04` non sono riscritte, sono circoscritte.)
**Edit author:** CC — mandato A162, 21/08/2026
```
DOPO:
```
**Versione:** 60 (22/08/2026)
**Ultima modifica:** 2026-08-22 (v60 — **una riga sola in Sez.2, doc-only, zero codice**: ratifica del vocabolario «due orologi» proposto dal referee, sede unica il capitolo omonimo di **BOX5 V30**. Non si copia qui: si rinvia. Nessun'altra riga toccata.)
**Edit author:** CC — mandato A176, 22/08/2026
```

### Edit 2 — nuova riga in Sezione 2 (Decisioni ratificate), subito dopo l'ultima riga esistente (2026-08-21)

PRIMA (ultima riga della tabella, invariata, per contesto — NON toccata):
```
| 2026-08-21 | **⛔ LA GAMBA «DRIVE SCRITTO A MANO» ESCE DAL REGIME R-δ. […] | Mauro (dettatura) + referee (verifica cloud e forma) + CC (misure A159 e A161, e presa d'atto) | `BOX5_QBEATS.md` cap. «R-δ — dove vanno i file» (V29) · `HANDOFF/MISURE_CC_2026-08-21_A159-CENSIMENTO-TRE-GAMBE.md` · `HANDOFF/MISURE_CC_2026-08-21_A161-MISURA-F-E-STOP-SU-BOX5.md` | attiva | — |
```
DOPO (riga NUOVA, aggiunta subito sotto, stessa riga di tabella immediatamente successiva — nessuna riga vuota fra le due, come tutte le altre righe della tabella):
```
| 2026-08-22 | **VOCABOLARIO DEI DUE OROLOGI — ratificato Mauro 22/08/2026.** Sede unica: capitolo omonimo in `BOX5_QBEATS.md` (V30). Non si copia qui: si rinvia. Nomi ratificati da Mauro: ACCENTO SONORO, PRIMO VERDE. Nomi proposti dal referee, NON ancora ratificati: CAMBIO SUONATO, CAMBIO SCRITTO, OROLOGIO MOTORE, OROLOGIO GRAFICA. | Mauro (ratifica) + referee (proposta lessico) | `BOX5_QBEATS.md` cap. «VOCABOLARIO DEI DUE OROLOGI» (V30) | attiva | — |
```

**[M] Citazione conforme a R7 (`LIBRO_MASTRO_QBEATS.md:87-90`):** simbolo (nome del
capitolo) prima della versione, **zero sha256 inciso**, **zero riga di codice/numero di
riga citata da sola** — solo `path` + `cap. «nome»` + `(versione)`, esattamente la forma
della riga precedente (`BOX5_QBEATS.md` cap. «R-δ — dove vanno i file» (V29)).
Il vocabolario **non è copiato**: solo i sei nomi e il loro stato di ratifica.

---

## §4 · BUGS — due aggiunte, verbatim prima/dopo, zero righe esistenti toccate

**[M] Faccia del file:** stessa situazione di LIBRO — CRLF su disco, LF nel blob.

### Edit 1 — header (una riga)

PRIMA:
```
**Versione:** 59
```
DOPO:
```
**Versione:** 60
```
(«Ultima modifica: 2026-08-22» resta identica: stesso giorno, secondo bump.)

### Edit 2 — nuovo bullet sul ticket `TD-rientro-senza-stop-sgancia-audio-e-grafica`

PRIMA (contesto, righe 224-225 — la seconda riga NON toccata, solo il punto d'innesto):
```
- Uscendo dal player col «<» **senza premere STOP**, il metronomo continua a suonare. […] L'unica traccia è un `os_log` che nessuno legge.
- ⛔ **TENUTO SEPARATO da `TD-direttore-parte-da-bar2`**: chi ripara uno non deve poter dichiarare chiuso anche l'altro.
```
DOPO (bullet NUOVO inserito fra le due righe esistenti, che restano intatte prima e dopo):
```
- Uscendo dal player col «<» **senza premere STOP**, il metronomo continua a suonare. […] L'unica traccia è un `os_log` che nessuno legge.
- **Osservazione diretta di Mauro, 22/08/2026 (seconda ricognizione, stesso device).** Il motore prosegue sul proprio OROLOGIO MOTORE; la grafica riparte da bar 1 e avanza sul proprio OROLOGIO GRAFICA. ⇒ **l'ACCENTO SONORO cade su un PRIMO VERDE sbagliato** — beat 2, 3 o 4 — e circa una volta su quattro coincide per caso. Lo scarto fra i due orologi è **NUOVO e CRESCENTE a ogni uscita-rientro**. Il punto della scaletta su cui si trova la grafica dipende da **quante volte si è rientrati**, non dal guasto: «Intro 100» era un esempio osservato, non un punto di arresto. **L'uscita usata è la navigazione «<» / «< show», NON i pulsanti «prev sez»/«next sez» del transport.**
- ⛔ **TENUTO SEPARATO da `TD-direttore-parte-da-bar2`**: chi ripara uno non deve poter dichiarare chiuso anche l'altro.
```

**[M] Copertura dei 5 punti del mandato — tutti presenti, nessuno omesso:**
motore/grafica su conteggi propri · ACCENTO SONORO su PRIMO VERDE sbagliato (beat 2/3/4,
1 su 4 per caso) · scarto NUOVO e CRESCENTE · dipendenza da QUANTE VOLTE (non dal guasto,
«Intro 100» = esempio non punto d'arresto) · uscita «<»/«< show», non prev/next sez.

**[A] Scelta editoriale mia, dichiarata:** ho collocato il bullet subito dopo la
descrizione principale (riga 224) e prima di «TENUTO SEPARATO» (riga 225), perché
approfondisce la stessa osservazione del 22/08 di cui riga 224 già parla. Il mandato non
fissava la posizione esatta: se Mauro/referee preferiscono un altro punto del ticket, è
uno spostamento di blocco, non una riscrittura di contenuto.

### Edit 3 — nuovo bullet fra «IPOTESI CADUTE» e «Lettura di Mauro»

PRIMA (contesto, righe 215-216 — nessuna delle due toccata, solo il punto d'innesto):
```
- ⛔ **IPOTESI CADUTE, NON RIPESCARLE.** […] **(b)** *il rientro senza STOP come causa di bar2*: falsificata, la grafica riparte sempre da 1.
- **Lettura di Mauro (22/08):** la causa sta probabilmente in difetti minori fra grafica e motore — modalità sbagliate, o uscite senza STOP. ⚠️ Marcata come **ragionamento**, non misura.
```
DOPO (bullet NUOVO inserito fra le due):
```
- ⛔ **IPOTESI CADUTE, NON RIPESCARLE.** […] **(b)** *il rientro senza STOP come causa di bar2*: falsificata, la grafica riparte sempre da 1.
- ✅ **CORROBORAZIONE INDIPENDENTE, 22/08 — la lacuna di conteggio sulla riga «rientro senza STOP» si chiude.** L'osservazione diretta di Mauro dello stesso giorno («parte sempre all'uno» — vedi `TD-rientro-senza-stop-sgancia-audio-e-grafica`) corrobora in modo indipendente l'esito già registrato in quella riga della matrice (grafica sempre da bar 1). ⛔ **Le altre due righe provvisorie (④, Sintomo ②) restano tali**: questa nota copre SOLO «rientro senza STOP».
- **Lettura di Mauro (22/08):** la causa sta probabilmente in difetti minori fra grafica e motore — modalità sbagliate, o uscite senza STOP. ⚠️ Marcata come **ragionamento**, non misura.
```

⛔ **[M] Riga 215 (ipotesi cadute) NON è stata toccata**, verificato per diff: la riga
esce identica, sopra e sotto il nuovo bullet. **La riga 211 (lacuna di conteggio) NON è
stata riscritta**: resta agli atti come scritta, la mia nota si limita a dichiararne la
chiusura parziale, per una sola riga della matrice.

### Edit 4 — nuova riga di changelog, Sezione 5, subito dopo la riga 59

PRIMA (ultima riga esistente, riga 59, NON toccata — per contesto):
```
| 59 | 2026-08-22 | Mauro (collaudo) + CC + referee | **Una marcatura additiva + due ticket NUOVI, doc-only, zero codice.** […] |
```
DOPO (riga NUOVA 60, aggiunta subito sotto):
```
| 60 | 2026-08-22 | Mauro (osservazione) + CC + referee | **Solo additivo, zero correzioni, zero codice (mandato A176).** Vocabolario «due orologi» (OROLOGIO MOTORE/OROLOGIO GRAFICA, ACCENTO SONORO/PRIMO VERDE, CAMBIO SUONATO/CAMBIO SCRITTO) ratificato da Mauro nella sola sede `BOX5_QBEATS.md` (V30) — non copiato qui. Su `TD-rientro-senza-stop-sgancia-audio-e-grafica` (§1.1): aggiunta l'osservazione diretta di Mauro 22/08 (seconda ricognizione) — l'ACCENTO SONORO cade su un PRIMO VERDE sbagliato, scarto crescente a ogni uscita-rientro, uscita usata è «<»/«< show», non i tasti prev/next sez. Sulla riga «rientro senza STOP» della matrice di `TD-direttore-parte-da-bar2`: la stessa osservazione **chiude la lacuna di conteggio** dichiarata a `:211`, per QUESTA riga soltanto — ④ e Sintomo ② restano provvisorie. Nessuna riga esistente modificata o cancellata. |
```

---

## §5 · IL CANCELLO — versioni nuove, verifica d'integrità, nessun commit

**[M] Versioni che i tre file assumerebbero al commit:**

| file | prima | dopo |
|---|---|---|
| `BOX5_QBEATS.md` | V29 — 21/08/2026 | **V30 — 22/08/2026** |
| `LIBRO_MASTRO_QBEATS.md` | 59 (21/08/2026) | **60 (22/08/2026)** |
| `BUGS_QBEATS.md` | 59 | **60** |

**[M] Il bump di versione non era nel testo del mandato: l'ho applicato io**, per
`LIBRO_MASTRO_QBEATS.md:89` (R7.2), verbatim: «**Versione = puntatore.** Se il contenuto
di un documento cambia, il suo numero di versione DEVE cambiare. Un numero non bumpato è
peggio di un puntatore rotto: sembra sano, non lo è.» Le tre righe di changelog che ho
scritto per accompagnare i bump (Delta BOX5, riga Ultima-modifica LIBRO, riga 60 BUGS)
sono **bookkeeping mio**, non testo del mandato: Mauro può riformularle liberamente senza
toccare il vocabolario o le osservazioni, che restano quelle date verbatim.

**[M] git status — 3 file modificati, 0 in stage, 0 sotto `ios_app/`, HEAD invariato:**

```
 M BOX5_QBEATS.md
 M BUGS_QBEATS.md
 M LIBRO_MASTRO_QBEATS.md
HEAD = 4629ee9ec943a1ebb8a16a49164aa457a8b99514 (invariato)
```

**[M] Stato dei tre file dopo le scritture — byte e CR misurati a BYTE, non con grep**
(sonda: `tr -cd '\r' | wc -c`, tarata su un file di controllo a CR noti prima dell'uso —
vedi nona trappola in A172, mai più affidata a `grep -c $'\r'`):

| file | byte | righe | CR | sha256 (lavoro corrente) |
|---|---|---|---|---|
| `BOX5_QBEATS.md` | 67189 | 761 | **0** (faccia LF, `-text`) | `24e4a13845670e84e27c7f0344eef4d3753ebd697f6b28e3b185c29f3bdc6065` |
| `LIBRO_MASTRO_QBEATS.md` | 283328 | 524 | **524** (CR = righe, CRLF puro) | `d288f1db3f55400a0aa108f66f3f3f6da59bf21cd5981b71b4aa3ac1e42ad723` |
| `BUGS_QBEATS.md` | 353105 | 1213 | **1213** (CR = righe, CRLF puro) | `7fb7223cc043721441fee72855bdaefaa938015ace769df88253a83c4d6d9691` |

**[M] CR uguale a righe su LIBRO e BUGS** ⇒ nessuna riga LF-nuda introdotta per errore:
la faccia CRLF è uniforme su tutto il file, non solo sulle righe che ho toccato.

**[M] Diffstat:** `BOX5 +40/−1` · `BUGS +5/−1` · `LIBRO +7/−3` (`git diff --stat`).

⛔ **NESSUN COMMIT ESEGUITO.** ⛔ **NESSUN `git add`.** Le tre scritture restano nel
working tree per la lettura di Mauro.

---

## §6 · CONSEGNA — questo referto, due gambe

⛔ **Non si scrive su Drive**: arriva da solo come riflesso di `E:` (regime R-δ, BOX5
V29/V30 cap. omonimo).

| gamba | percorso |
|---|---|
| C: repo | `HANDOFF/MISURE_CC_2026-08-22_A176-VOCABOLARIO-DUE-OROLOGI.md` |
| E: mirror | `FILE X CLAUDE.MD\HANDOFF\` stesso nome |

*(byte, CR-a-byte e sha256 dei due depositi dichiarati nel messaggio di consegna, misurati
DOPO la scrittura — un'impronta incisa nel documento non può coincidere con se stessa.)*

---

## Cose che NON ho fatto

⛔ Nessun file sotto `ios_app/` toccato · nessun commit · nessun `git add` · nessuna
build · nessuna riga esistente di BOX5/LIBRO/BUGS modificata o cancellata (solo
inserimenti, verificati per diff riga per riga) · non ho letto il congedo del referee.

---

### Controllo d'integrità di QUESTO file — sul CONTENUTO

**Prima riga attesa:**
`# MISURE CC — A176 · VOCABOLARIO DEI DUE OROLOGI`

**Stringhe obbligatorie — se una manca, il file è arrivato mutilato:**
`quarta classe di rumore` · `Un numero non bumpato è peggio di un puntatore rotto` ·
`CORROBORAZIONE INDIPENDENTE` · `NESSUN COMMIT ESEGUITO` · `CR = righe` ·
`24e4a13845670e84e27c7f0344eef4d3753ebd697f6b28e3b185c29f3bdc6065` ·
e il marcatore di fine qui sotto.

⚠️ **Contate le stringhe, non i titoli.**

---

*A176-FINE — MISURE CC 22/08/2026 COMPLETO*
