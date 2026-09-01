# MISURE CC — A178 · NOMI CORRETTI, ROADMAP E STATO

Da: CC · A: **referee** (+ Mauro)
Mandato: `A178-NOMI-CORRETTI-ROADMAP-E-STATO` · **SCRITTURA SUI CANONICI, NESSUN COMMIT**
Controllo di completezza: **7 sezioni (§0→§6) presenti, ultima riga `A178-FINE-MANDATO`
— integro.** A177 registrato come annullato, non eseguito.

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato da altri, non
rimisurato · **[A]** giudizio mio.
⛔ **Zero tocchi a `ios_app/`. Nessun commit. Nessun `git add`. Nessun push.**
Le cinque scritture sono **nel working tree**, in attesa del cancello di Mauro.

⚠️ **DISCORDANZA DI MODELLO, dichiarata:** l'intestazione del mandato dice **Sonnet 5**,
ma il comando `/model claude-opus-5` eseguito immediatamente prima ha impostato
l'interfaccia su **Opus 5**. Eseguito e dichiarato; non posso cambiare modello da qui.

---

## §0 · ID `A178` — LIBERO. La quarta classe morde di nuovo

**[M] Per NOME (sonda potata):** 0 su repo, 0 su E:. Trappola ① non morde (0 anche
non potata). Controllo positivo forma identica (`A176`): 1 per gamba.

**[M] Per CONTENUTO:** 1 hit su repo, 9 su E:. Classificati uno per uno:

| classe | dove | forma esatta |
|---|---|---|
| **④ ID come esempio didattico** (la classe che ho scoperto in A176) | `HANDOFF/MISURE_CC_2026-08-21_A164-COMMIT-BOX5-V29-E-LIBRO-v59.md:74` | `\| A178 / A180 / A182 \| 0 \| 0 \| 0 \| 0 \| controllo **negativo** \|` |
| ④, stesso file su E: | `<E>/FILE X CLAUDE.MD/HANDOFF/MISURE_CC_2026-08-21_A164-…md` | idem |
| ② log di device | 8 file `LOG/RUN/TEST LUNGA DISTANZA/td17_*.log` | request-id e UUID WiFi |

**[M] Controllo positivo:** `A176` rende 7 su repo / 10 su E: — la sonda vede.
**[M] Controllo negativo tarato:** `QBEATS-NEG-V5R2` rende **0**.

⇒ **[M] `A178` è LIBERO.** ⚠️ **[A] La quarta classe non è stata un caso isolato: ha
morso su A176 e ora su A178.** Un referto che tabula ID futuri come controlli negativi
li «occupa» per la sonda di chiunque venga dopo.

---

## §0-bis · UN DIFETTO DEL MANDATO, misurato prima di scrivere

⛔ **Il mandato dichiara: «BUGS/LIBRO/SCALETTA: due facce, edita su disco (CRLF)».
Per SCALETTA è FALSO, misurato.**

```
.gitattributes:  HANDOFF/** -text
SCALETTA: cmp disco vs blob HEAD  →  IDENTICO
SCALETTA: tr -cd '\r' | wc -c     →  0 CR su 494 righe
controprova, BUGS (che DAVVERO ha due facce): cmp → DIFFERISCE
```

⇒ **[M] SCALETTA è a FACCIA UNICA, LF.** L'ho editata in **LF**, non in CRLF: seguire
il mandato alla lettera avrebbe introdotto 457 CR in un file che non ne ha mai avuti —
la corruzione silenziosa esatta contro cui BOX5 V26/V27 mette in guardia.
**[M] BOX3 idem** (`-text`, `cmp` IDENTICO): LF, come il mandato dice correttamente.

---

## §1 · BOX5 — capitolo sostituito, testo del mandato VERBATIM

**[M] Faccia:** LF, invariata (0 CR prima e dopo).
**[M] Versione:** resta **V30** come prescritto — non ri-alzata.

### Edit 1 — riga di Delta V30

PRIMA:
```
- **Capitolo NUOVO «VOCABOLARIO DEI DUE OROLOGI».** Lessico che separa il conteggio del motore audio da quello della grafica, e nomina i due punti dove lo scarto si vede (accento/primo verde dentro la battuta; cambio suonato/cambio scritto fra le sezioni). Ratificato Mauro 22/08/2026 (mandato A176). **Solo due nomi sono ratificati da Mauro**: ACCENTO SONORO e PRIMO VERDE. **Quattro restano proposti dal referee, non ancora ratificati**: OROLOGIO MOTORE, OROLOGIO GRAFICA, CAMBIO SUONATO, CAMBIO SCRITTO — da tagliare se Mauro non li conferma al cancello.
```
DOPO:
```
- **Capitolo NUOVO «VOCABOLARIO DEI DUE OROLOGI».** Lessico che separa il conteggio del motore audio da quello della grafica, e nomina i due punti dove lo scarto si vede (ACCENTO AUDIO / ACCENTO GRAFICO dentro la battuta; CAMBIO SEZIONE AUDIO / CAMBIO SEZIONE GRAFICO fra le sezioni). **Tutti e sei i nomi sono ratificati da Mauro il 22/08/2026** (mandati A176 + A178). Tre erano stati proposti diversamente dal referee e corretti da Mauro prima della ratifica: ACCENTO AUDIO (era «accento sonoro»), ACCENTO GRAFICO (era «primo verde»), CAMBIO SEZIONE AUDIO/GRAFICO (erano «cambio suonato»/«cambio scritto», non italiano).
```

### Edit 2 — capitolo intero sostituito

PRIMA (29 righe, i nomi vecchi — riportata la sola struttura per non gonfiare il referto;
il testo integrale è nel referto A176 §2 e nella storia git del working tree):
```
## VOCABOLARIO DEI DUE OROLOGI — ratificato Mauro 22/08/2026

Il metronomo tiene DUE conteggi distinti, che possono divergere:
· OROLOGIO MOTORE — …
· OROLOGIO GRAFICA — …
[…]
 · ACCENTO SONORO — …
 · PRIMO VERDE — …
[…]
 · CAMBIO SUONATO — …
 · CAMBIO SCRITTO — …
[…]
⚠️ QUATTRO NOMI PROPOSTI DAL REFEREE E NON ANCORA RATIFICATI DA MAURO:
CAMBIO SUONATO, CAMBIO SCRITTO, OROLOGIO MOTORE, OROLOGIO GRAFICA.
Ratificati da Mauro solo: ACCENTO SONORO e PRIMO VERDE. Se Mauro non
ratifica gli altri quattro al cancello, vanno tagliati prima del commit.
```

DOPO (testo del §1 del mandato, **parola per parola**, con la sola aggiunta di `## ` al
titolo per farne un'intestazione di sezione — coerente con ogni altra `##` di BOX5):
```
## VOCABOLARIO DEI DUE OROLOGI — ratificato Mauro 22/08/2026

REGOLA UNICA: ogni cosa esiste in versione AUDIO e in versione GRAFICO.
Il difetto è SEMPRE la distanza fra le due, mai una delle due "sbagliata".

I due conteggi:
· OROLOGIO MOTORE AUDIO — il conteggio dei battiti tenuto dal motore audio.
  Riparte da zero SOLO quando il motore viene fermato e riavviato.
· OROLOGIO GRAFICA — il conteggio su cui il display costruisce battute e
  sezioni. Riparte da zero a OGNI rientro nel player.

Dentro la battuta:
· ACCENTO AUDIO — il click a frequenza diversa, prodotto dal motore audio.
· ACCENTO GRAFICO — l'accento reso dalla grafica. Oggi è il primo pallino
  verde della battuta; «primo pallino verde» è COME È RESO OGGI, non il nome
  della cosa. Se il disegno cambia, il nome resta.

Fra le sezioni:
· CAMBIO SEZIONE AUDIO — il motore comincia a suonare la sezione successiva.
· CAMBIO SEZIONE GRAFICO — il display aggiorna nome e numero della sezione.

⛔ VIETATE le forme «l'accento è sfasato», «l'accento è sbagliato», «la
sezione è sbagliata». Sono FALSE: ciascun orologio è corretto rispetto a sé
stesso. Le forme corrette sono:
· «l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO»
· «il CAMBIO SEZIONE GRAFICO non coincide col CAMBIO SEZIONE AUDIO»
L'oggetto del difetto è LA DISTANZA FRA DUE OROLOGI, non un accento rotto.

Tutti e sei i nomi sono ratificati da Mauro il 22/08/2026. Tre erano stati
proposti diversamente dal referee e corretti da Mauro: ACCENTO AUDIO (era
«accento sonoro»), ACCENTO GRAFICO (era «primo verde»), CAMBIO SEZIONE
AUDIO/GRAFICO (erano «cambio suonato»/«cambio scritto», non italiano).
```

---

## §2 · LIBRO — riga corretta

**[M] Faccia:** CRLF, invariata (CR = righe = 524, nessuna riga LF-nuda introdotta).
**[M] Versione:** resta **60** come prescritto.

PRIMA:
```
| 2026-08-22 | **VOCABOLARIO DEI DUE OROLOGI — ratificato Mauro 22/08/2026.** Sede unica: capitolo omonimo in `BOX5_QBEATS.md` (V30). Non si copia qui: si rinvia. Nomi ratificati da Mauro: ACCENTO SONORO, PRIMO VERDE. Nomi proposti dal referee, NON ancora ratificati: CAMBIO SUONATO, CAMBIO SCRITTO, OROLOGIO MOTORE, OROLOGIO GRAFICA. | Mauro (ratifica) + referee (proposta lessico) | `BOX5_QBEATS.md` cap. «VOCABOLARIO DEI DUE OROLOGI» (V30) | attiva | — |
```
DOPO:
```
| 2026-08-22 | **VOCABOLARIO DEI DUE OROLOGI — ratificato Mauro 22/08/2026.** Sede unica: capitolo omonimo in `BOX5_QBEATS.md` (V30). Non si copia qui: si rinvia. **REGOLA UNICA: ogni cosa esiste in versione AUDIO e in versione GRAFICO, e il difetto è SEMPRE la distanza fra le due, mai una delle due «sbagliata».** **Tutti e sei i nomi sono ratificati da Mauro:** OROLOGIO MOTORE AUDIO · OROLOGIO GRAFICA · ACCENTO AUDIO · ACCENTO GRAFICO · CAMBIO SEZIONE AUDIO · CAMBIO SEZIONE GRAFICO. ⚠️ **Tre erano stati proposti diversamente dal referee e sono stati CORRETTI da Mauro prima della ratifica:** ACCENTO AUDIO (era «accento sonoro»), ACCENTO GRAFICO (era «primo verde»), CAMBIO SEZIONE AUDIO/GRAFICO (erano «cambio suonato»/«cambio scritto», non italiano). | Mauro (ratifica, e correzione di tre nomi) + referee (proposta del lessico) | `BOX5_QBEATS.md` cap. «VOCABOLARIO DEI DUE OROLOGI» (V30) | attiva | — |
```

**[M] Citazione conforme a R7** (`LIBRO_MASTRO_QBEATS.md:87-90`): simbolo + versione,
zero sha256 inciso, zero riga nuda. Il vocabolario **non è copiato**: solo i sei nomi.

---

## §3 · BUGS — nomi aggiornati, NIENT'ALTRO

**[M] Faccia:** CRLF, invariata (CR = righe = 1213).
**[M] Versione:** resta **60** come prescritto.

### Edit 1 — bullet del ticket `TD-rientro-senza-stop-sgancia-audio-e-grafica`

PRIMA (frammento modificato):
```
Il motore prosegue sul proprio OROLOGIO MOTORE; la grafica riparte da bar 1 e avanza sul proprio OROLOGIO GRAFICA. ⇒ **l'ACCENTO SONORO cade su un PRIMO VERDE sbagliato**
```
DOPO:
```
Il motore prosegue sul proprio OROLOGIO MOTORE AUDIO; la grafica riparte da bar 1 e avanza sul proprio OROLOGIO GRAFICA. ⇒ **l'ACCENTO AUDIO cade su un ACCENTO GRAFICO sbagliato**
```
**[M] Il resto del bullet è invariato** (beat 2/3/4 · una volta su quattro · scarto NUOVO
e CRESCENTE · «Intro 100» esempio non punto d'arresto · uscita «<»/«< show»).

### Edit 2 — riga di changelog v60, due frammenti

PRIMA:
```
Vocabolario «due orologi» (OROLOGIO MOTORE/OROLOGIO GRAFICA, ACCENTO SONORO/PRIMO VERDE, CAMBIO SUONATO/CAMBIO SCRITTO)
```
DOPO:
```
Vocabolario «due orologi» (OROLOGIO MOTORE AUDIO/OROLOGIO GRAFICA, ACCENTO AUDIO/ACCENTO GRAFICO, CAMBIO SEZIONE AUDIO/CAMBIO SEZIONE GRAFICO)
```
PRIMA:
```
l'ACCENTO SONORO cade su un PRIMO VERDE sbagliato, scarto crescente a ogni uscita-rientro
```
DOPO:
```
l'ACCENTO AUDIO cade su un ACCENTO GRAFICO sbagliato, scarto crescente a ogni uscita-rientro
```

⛔ **[M] Riga delle ipotesi cadute NON toccata** (verificato per diff: non compare fra le
righe modificate). ⛔ **Nessuna riga esistente cancellata o riscritta.**

### 🚨 [A] UNA TENSIONE CHE SEGNALO E NON HO RISOLTO DA SOLO

La sostituzione pura dei nomi — che è ciò che il mandato prescrive, «⛔ Nient'altro» —
produce in BUGS la frase:

> «l'ACCENTO AUDIO cade su un **ACCENTO GRAFICO sbagliato**»

Il vocabolario che lo stesso commit incide in BOX5 **vieta** le forme «l'accento è
sbagliato» e prescrive «l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO».
⚠️ **Ho eseguito la sostituzione pura come ordinato e NON ho riformulato**: correggere
di mia iniziativa avrebbe superato il «nient'altro». **Segnalo la tensione al cancello:**
se il referee la ritiene reale, la forma conforme è

```
⇒ **l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO** — cade sul secondo, terzo o quarto, e circa una volta su quattro coincide per caso.
```

Una parola di conferma e la applico; senza conferma resta com'è.

---

## §4 · SCALETTA — marcatura ADDITIVA, v11 → v12

**[M] Faccia:** LF (0 CR prima e dopo — vedi §0-bis: il mandato la dava per CRLF).

### Edit 1 — campo Versione e catena

PRIMA:
```
**Versione:** 11 (18/08/2026)  ·  **Ratificata dal referee:** … **scheda ⟦S5b⟧ INCISA in sezione B (13 atomi, titolo marcato) + clausola «zero citazioni nude ≥320» di sez.C marcata SCADUTA, 18/08** (v11)
```
DOPO:
```
**Versione:** 12 (22/08/2026)  ·  **Ratificata dal referee:** … **scheda ⟦S5b⟧ INCISA in sezione B (13 atomi, titolo marcato) + clausola «zero citazioni nude ≥320» di sez.C marcata SCADUTA, 18/08** (v11) · **⟦S-EXIT⟧ RIFORMULATO E SCOMPOSTO in sei punti (a)-(f) — marcatura additiva in coda a sez.C, ordine 31/07 INVARIATO, 22/08** (v12)
```
**[M] Il resto della catena v1→v11 è invariato, byte per byte.**

### Edit 2 — marcatura in coda a Sezione C

⛔ **[M] NESSUNA riga esistente toccata**, verificato per diff: la riga d'ordine 31/07
(`:429`) e le tre marcature precedenti (`:430`, `:431`, `:432`, `:433`) escono **identiche**.
La marcatura è aggiunta **dopo** l'ultima (18/08 su ⟦S5a⟧) e **prima** di `## D`.

Testo inserito, **parola per parola dal mandato**:
```
⚠️ MARCATURA 22/08 — ⟦S-EXIT⟧ RIFORMULATO E SCOMPOSTO, ratificato Mauro
22/08/2026. Le righe sopra restano come scritte: si marca, non si riscrive.
⛔ L'ORDINE RATIFICATO 31/07 È INVARIATO: ⟦S-EXIT⟧ → ⟦S4L⟧ → ⟦S6⟧.
Questa marcatura scompone SOLO ⟦S-EXIT⟧ e non tocca ciò che viene dopo.
⚠️ Resta aperto il buco registrato il 07/08: ⟦S-EXIT⟧ NON HA SCHEDA in
Sezione B (come ⟦S6F⟧). Il punto (c) qui sotto è ciò che lo colma.

⟦S-EXIT⟧ non è più «cablare l'uscita». È: LO STATO DELLO SHOW DEVE
APPARTENERE ALLO SHOW, NON ALLA SCHERMATA. Motivo misurato 22/08 (A172,
A173): uscendo dal player senza STOP l'OROLOGIO MOTORE AUDIO prosegue e
l'OROLOGIO GRAFICA riparte, con scarto crescente a ogni rientro.

Scomposizione ratificata:
(a) MISURA PRIMA DI TUTTO — che cosa può smontare la schermata del player
    oltre al «<»: telefonata, blocco schermo, recupero memoria di iOS.
    È la domanda che DECIDE se (b) serve: se solo il «<» la smonta, fermare
    l'audio all'uscita è soluzione completa e il resto è sovraingegneria.
(b) quanto pesa spostare lo stato dello show dalla schermata alla stanza.
(c) SCHEDA ⟦S-EXIT⟧, scritta dal referee sul peso misurato — colma il buco
    del 07/08.
(d) decisioni di Mauro sul rientro in uno show che sta suonando.
(e) contratto CD: la schermata di rientro nel player NON è coperta da nessun
    disegno — il contratto del 18/07 esclude il player (misurato).
(f) CODICE + ATOMO DI STRUMENTAZIONE NELLO STESSO COMMIT, chat propria
    (tocca lo stop audio), gate su device.
⚠️ La strumentazione non è un atomo suo: stesso file della riparazione,
passiva, ed è il modo con cui la riparazione si verifica sul device.

TAGLI DI CHAT ratificati: dopo il commit documenti 22/08 · dopo (e) · dopo (f).

LAVORI NON-ATOMI che corrono a fianco, nell'ordine ratificato da Mauro:
1) TD-direttore-parte-da-bar2 — dopo (f) si legge ciò che la strumentazione
   ha catturato. Causa NON ATTRIBUITA, nessuna pista alternativa.
2) resto dell'igiene documenti: registro mandati, congedi fuori da git,
   arretrati, riscrittura piena di BOX3.
3) freeze grafico rev3 + le due decisioni di Mauro in attesa.
⛔ Non sono atomi della scaletta e non entrano nella riga d'ordine.
```

**✅ [M] Il claim «(come ⟦S6F⟧)» del mandato REGGE, verificato prima di scrivere:**
`SCALETTA:412` dice verbatim «**⟦S6F⟧ e ⟦S-EXIT⟧ non hanno scheda**». Unica occorrenza
di `S6F` nel file.

⚠️ **[M] Reperto collaterale, NON toccato:** la marcatura 07/08 (`:432`) afferma che
Sezione B contiene «esattamente **12** intestazioni `###`». **Oggi sono 13** (misurate una
per una: la scheda ⟦S5b⟧ è stata incisa in v11). La marcatura **era vera al suo commit**
e non si riscrive; lo registro qui perché chi la legge non la usi come misura viva.

---

## §5 · BOX3 — blocco additivo in testa, V99 → V100

**[M] Faccia:** LF (0 CR prima e dopo).

### Edit 1 — intestazione

PRIMA:
```
BOX3 V99 — 2026-07-22 (AUTOPORTANTE) · HEAD=origin=bfa07eb (⚠️ campo strutturalmente stale by-design, …)
```
DOPO:
```
BOX3 V100 — 2026-08-22 (AUTOPORTANTE — V100 aggiunge SOLO il blocco di stato in testa, 22/08; il CORPO resta quello di V99, datato 2026-07-22) · HEAD=origin=bfa07eb (⚠️ campo strutturalmente stale by-design, …)
```
**[M] La coda della riga — il caveat sull'HEAD stale e la verifica del 22/07 — è
invariata byte per byte.** ⚠️ **[A] Ho esplicitato nell'intestazione che il corpo resta
al 22/07**: senza quella clausola l'intestazione avrebbe detto «V100 — 2026-08-22» sopra
un corpo di luglio, cioè esattamente la trappola che il blocco additivo denuncia.

### Edit 2 — riga di delta + blocco, inseriti fra l'intestazione e «Supersede V98»

⛔ **[M] La riga `Supersede V98 (…)` e tutto ciò che segue sono invariati**, verificato
per diff. Inserito sopra di essa:
```
Supersede V99 (blocco additivo di STATO VIVO al 22/08/2026 — mandato A178; ZERO riscritture: il corpo di V99 è riportato sotto INVARIATO, e la sua data resta 2026-07-22. Registra i due ticket bloccanti palco aperti, il vocabolario obbligatorio, la sede dell'ordine dei lavori, le misure agli atti e una ratifica di Mauro sui pulsanti morti del transport):

⚠️ STATO VIVO AL 22/08/2026 — blocco additivo (mandato A178).
Il CORPO di questo documento è fermo al 22/07/2026 (V99): tutto ciò che segue
va letto con quella data.

DUE TICKET 🔴 ALTA / 🚨 BLOCCANTE PALCO, entrambi APERTI:
· TD-direttore-parte-da-bar2 — causa ⬜ NON ATTRIBUITA, caccia manuale
  SOSPESA. Il rientro senza STOP è escluso come sua causa: la falsificazione
  è corroborata dall'osservazione diretta di Mauro del 22/08.
· TD-rientro-senza-stop-sgancia-audio-e-grafica — CARATTERIZZATO, riproducibile
  a comando. Uscendo dal player senza STOP il motore non si ferma; al rientro
  l'avvio lo trova acceso, esce in silenzio e non azzera il contatore.
  ⇒ l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO, e lo scarto CRESCE a ogni
  uscita-rientro. L'audio è sano: è la grafica ad aver perso il riferimento.

⛔ SONO DUE DIFETTI DIVERSI. Chi ripara uno NON chiude l'altro.

VOCABOLARIO OBBLIGATORIO: BOX5 V30, cap. «VOCABOLARIO DEI DUE OROLOGI».
ORDINE DEI LAVORI: SCALETTA Sezione C v12, sede unica.
MISURE AGLI ATTI, non rimisurare: A166, A172, A173.
⚠️ Ratificato da Mauro: i pulsanti morti del transport («prev sez», «next
sez», loop, restart) sono PALETTI DI MEMORIA VOLUTI, non un difetto.
Condizione di chiusura: spariscono prima del rilascio.
```
**[A] La riga `Supersede V99 (…)` è la «riga di delta» chiesta dal mandato**, scritta
nell'idioma di BOX3 (ogni versione apre con `Supersede V<precedente> (sommario):`).
Il blocco che segue è **verbatim dal mandato**, parola per parola.

---

## §6 · IL CANCELLO — stato finale misurato

**[M] Versioni dopo le cinque scritture:**

| file | prima | dopo | prescritto |
|---|---|---|---|
| `BOX5_QBEATS.md` | V30 | **V30** (invariata) | ✅ non ri-alzare |
| `LIBRO_MASTRO_QBEATS.md` | 60 | **60** (invariata) | ✅ non ri-alzare |
| `BUGS_QBEATS.md` | 60 | **60** (invariata) | ✅ non ri-alzare |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 11 | **12** | ✅ v11→v12 |
| `BOX3_QBEATS.md` | V99 | **V100** | ✅ V99→V100 |

**[M] Byte, righe e CR — sonda a BYTE (`tr -cd '\r' | wc -c`), mai grep:**

| file | byte | righe | CR | faccia |
|---|---|---|---|---|
| `BOX5_QBEATS.md` | 67462 | 764 | **0** | LF, attesa (`-text`) |
| `LIBRO_MASTRO_QBEATS.md` | 283803 | 524 | **524** | CRLF puro (CR = righe) |
| `BUGS_QBEATS.md` | 353140 | 1213 | **1213** | CRLF puro (CR = righe) |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 68886 | 494 | **0** | LF, attesa (`HANDOFF/** -text`) |
| `BOX3_QBEATS.md` | 91223 | 828 | **0** | LF, attesa (`-text`) |

**[M] CR = righe** su LIBRO e BUGS ⇒ nessuna riga LF-nuda introdotta. **CR = 0** sui tre
LF ⇒ nessun CR introdotto per errore.

**[M] sha256 dello stato di lavoro corrente:**
```
BOX5_QBEATS.md                            8988962caf9a4ae8bd80cd50f3dbe9742bec0d77595fe20bea892b5ca372c835
LIBRO_MASTRO_QBEATS.md                    297028c157719ad4748ffa7867e96ed3f16986184203d18636372d60a7abe6be
BUGS_QBEATS.md                            58c7e71b99d39cf4fe6e2db3b5fe2245c8d89402c3ddbc59124f3523a0a84685
HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md   e9b23ac962ea5db8e62763bac0942d64b969f7cbb84defd055e5b2ea928ad74a
BOX3_QBEATS.md                            93e67132bcb6af6a709ff9697ee40174dc4fac1245a4956b520cd28248a436e4
```

**[M] Diffstat:**
```
 BOX3_QBEATS.md                          | 27 ++++++++++++++++++++-
 BOX5_QBEATS.md                          | 43 ++++++++++++++++++++++++++++++++-
 BUGS_QBEATS.md                          |  5 +++-
 HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md | 39 +++++++++++++++++++++++++++++-
 LIBRO_MASTRO_QBEATS.md                  |  7 +++---
 5 files changed, 114 insertions(+), 7 deletions(-)
```

**[M] Censimento dei nomi su TUTTI E CINQUE i file — nomi vecchi ELIMINATI:**

| nome vecchio | occorrenze totali | | nome nuovo | occorrenze totali |
|---|---|---|---|---|
| `ACCENTO SONORO` | **0** | | `ACCENTO AUDIO` | 8 |
| `PRIMO VERDE` | **0** | | `ACCENTO GRAFICO` | 8 |
| `CAMBIO SUONATO` | **0** | | `OROLOGIO MOTORE AUDIO` | 5 |
| `CAMBIO SCRITTO` | **0** | | `CAMBIO SEZIONE GRAFICO` | 5 |

Controllo positivo nella forma identica: i quattro nomi nuovi rendono tutti > 0 ⇒ la
sonda vede, lo zero sui vecchi non è un falso zero.

**[M] Stato del repo:**
```
 M BOX3_QBEATS.md
 M BOX5_QBEATS.md
 M BUGS_QBEATS.md
 M HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md
 M LIBRO_MASTRO_QBEATS.md
in stage: 0 · ios_app: 0 righe · HEAD = 4629ee9ec943a1ebb8a16a49164aa457a8b99514 (invariato)
```

⛔ **NESSUN COMMIT. NESSUN `git add`. NESSUN PUSH. ZERO tocchi a `ios_app/`.**

---

## Cose che segnalo e NON ho corretto da solo

1. **🚨 §3 — «ACCENTO GRAFICO sbagliato» contro il divieto del vocabolario.** Dettaglio e
   forma conforme proposta nel §3 sopra. Aspetto una parola.
2. ⚠️ **LIBRO, riga `**Edit author:** CC — mandato A176, 22/08/2026`.** Ora
   **sotto-dichiara**: anche A178 ha editato il file. Non l'ho toccata perché il §2 del
   mandato è scoped alla sola riga di Sezione 2. Se va aggiornata, è una riga.
3. ⚠️ **BUGS, riga di changelog v60, apre con «(mandato A176)».** Non c'è traccia di A178
   nel registro di BUGS, perché il mandato vieta il bump a v61 e la riga 60 è l'unica
   sede disponibile. **Chi cercherà «cosa ha fatto A178 in BUGS» non lo troverà nel
   registro.** Non l'ho aggiunto: sarebbe stato «nient'altro» violato.
4. ⚠️ **SCALETTA `:432` dice «12 intestazioni», oggi sono 13** (§4). Marcatura vera al suo
   commit, non toccata.

---

## Cosa NON ho fatto

⛔ Nessun file sotto `ios_app/` toccato · nessun commit · nessun `git add` · nessun push ·
nessuna build · nessuna riga esistente riscritta o cancellata in nessuno dei cinque file
(solo inserimenti e sostituzioni puntuali, verificati per diff) · non ho letto il congedo
del referee.

---

### Controllo d'integrità di QUESTO file — sul CONTENUTO

**Prima riga attesa:**
`# MISURE CC — A178 · NOMI CORRETTI, ROADMAP E STATO`

**Stringhe obbligatorie — se una manca, il file è arrivato mutilato:**
`SCALETTA è a FACCIA UNICA, LF` · `ACCENTO GRAFICO sbagliato` ·
`LO STATO DELLO SHOW DEVE` · `PALETTI DI MEMORIA VOLUTI` ·
`93e67132bcb6af6a709ff9697ee40174dc4fac1245a4956b520cd28248a436e4` ·
`NESSUN COMMIT. NESSUN` · `oggi sono 13` ·
e il marcatore di fine qui sotto.

⚠️ **Contate le stringhe, non i titoli.**

---

*A178-FINE — MISURE CC 22/08/2026 COMPLETO*
