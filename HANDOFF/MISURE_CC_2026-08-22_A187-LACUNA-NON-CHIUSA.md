# MISURE CC — A187 · LA LACUNA NON È CHIUSA

Da: CC · A: **referee** (+ Mauro)
Mandato: `A187-LACUNA-NON-CHIUSA` · **SCRITTURA, NESSUN COMMIT**
Completezza: **4 sezioni (§0→§3), ultima riga `A187-FINE-MANDATO` — integro.**
**[M] Modello: intestazione Opus 5, interfaccia Opus 5 — coincidono.**

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato, non rimisurato ·
**[A]** giudizio mio.
⛔ **Zero tocchi a `ios_app/`. Nessun commit, nessun `git add`, nessun push.**

---

# ⚠️ IL DIFETTO ERA ANCHE MIO, E IN DUE SITI NON UNO

**[A] La nota falsa l'ho scritta io in A176 e l'ho marcata `[M]`.** Avevo verificato che
l'osservazione di Mauro **esistesse** — non che fosse un **conteggio**. Ho controllato la
presenza del fatto, non la sua natura. La misura c'era; era della specie sbagliata.

🚨 **[M] E la stessa falsità viveva in DUE siti, formulati diversamente** — per questo una
sonda sulla frase esatta ne trovava uno solo:

| sito | testo |
|---|---|
| `BUGS:216` | «la lacuna di conteggio sulla riga «rientro senza STOP» **si chiude**» |
| `BUGS:1209` (changelog 60) | «la stessa osservazione **chiude la lacuna di conteggio** dichiarata a `:211`» |

**[A] Il §1 nominava solo il primo.** Ho corretto anche il secondo e lo dichiaro come
scelta: è la stessa affermazione, nella riga che il §2(a) mi fa comunque toccare, e
lasciarla avrebbe riprodotto **esattamente** l'incoerenza BOX5↔LIBRO di A185 — un commit
che si smentisce da solo a quindici righe di distanza.

⚠️ **[M] Un numero del mandato non combacia col canonico:** il §-preambolo parla di «test
a **dieci** giri», ma `BUGS:211` prescrive «**5+3**» = otto. Non cambia l'azione — la
lacuna è aperta con entrambi i numeri — ma è la stessa famiglia di ciò che stiamo
riparando, e lo segnalo.

---

## §0 · ID `A187` — LIBERO

**[M] Per NOME (potata):** 0 su repo, 0 su E:. Trappola ① **non morde** (0 anche non
potata). Controllo positivo forma identica (`A186`): 1 per gamba.

**[M] Per CONTENUTO:** **0 su repo**, 7 su E: — **tutti classe ②** (`F8BB5786-A187-407D-8F1E`,
`uuid: 0BA187A7-5CC0-48`, …). **[M] Classe ④ assente.**

**[M] Controllo positivo `A186`:** 4 su repo / 11 su E:. **Negativo tarato:** 0.

✅ **[M] Tutti i controlli positivi di questo giro sono stati tarati COPIANDO il testo dal
file**, come mi ero prescritto in A186 dopo aver ripetuto la sonda case-sensitive. Nessun
falso zero in questo giro.

---

## §1 · BUGS — la lacuna NON è chiusa *(eseguito, due siti)*

**[M] Faccia:** CRLF, CR = righe = 1213. **[M] Versione:** resta **60**.

### (a) La nota a `BUGS:216`

PRIMA:
```
- ✅ **CORROBORAZIONE INDIPENDENTE, 22/08 — la lacuna di conteggio sulla riga «rientro senza STOP» si chiude.** L'osservazione diretta di Mauro dello stesso giorno («parte sempre all'uno» — vedi `TD-rientro-senza-stop-sgancia-audio-e-grafica`) corrobora in modo indipendente l'esito già registrato in quella riga della matrice (grafica sempre da bar 1). ⛔ **Le altre due righe provvisorie (④, Sintomo ②) restano tali**: questa nota copre SOLO «rientro senza STOP».
```
DOPO:
```
- ⚠️ **CORROBORAZIONE INDIPENDENTE, 22/08 — e la riga «rientro senza STOP» RESTA PROVVISORIA.** L'osservazione diretta di Mauro dello stesso giorno («parte sempre all'uno» — vedi `TD-rientro-senza-stop-sgancia-audio-e-grafica`) **corrobora in modo indipendente** l'esito già registrato in quella riga della matrice (grafica sempre da bar 1). ⛔ **NON chiude la lacuna di conteggio:** è una descrizione qualitativa, e il conteggio prescritto a `:211` non è mai stato eseguito. **Una lacuna di CONTEGGIO la chiude solo un CONTEGGIO.** ⇒ restano provvisorie tutte e tre le righe dichiarate a `:211`: ④, Sintomo ②, «rientro senza STOP».
```
✅ La corroborazione **resta** (è vera) · la chiusura **è tolta** · la provvisorietà è
**dichiarata** · il numero «due» è **sostituito dall'elenco**, come suggerito dal §1(b).
✅ Anche l'emoji di testa passa da ✅ a ⚠️: **[A] un segno di spunta su una riga che resta
aperta è esso stesso una falsa chiusura.**

### (b) Il secondo sito — changelog 60

PRIMA:
```
Sulla riga «rientro senza STOP» della matrice di `TD-direttore-parte-da-bar2`: la stessa osservazione **chiude la lacuna di conteggio** dichiarata a `:211`, per QUESTA riga soltanto — ④ e Sintomo ② restano provvisorie.
```
DOPO:
```
Sulla riga «rientro senza STOP» della matrice di `TD-direttore-parte-da-bar2`: la stessa osservazione **corrobora** l'esito ma **NON chiude la lacuna di conteggio** dichiarata a `:211` — è qualitativa, il conteggio prescritto non è stato eseguito, e la riga resta provvisoria insieme a ④ e Sintomo ②.
```

### (b-bis) La matrice — nessun ripristino necessario

**[M] Verificato:** la riga della matrice `BUGS:207` **non è mai stata de-marcata**.
Verbatim, invariata da prima del commit:
```
| rientro senza STOP | Link ON, Director | ⚠️ **non registrato dal referee** | ✅ la grafica riparte sempre da bar 1, **con e senza STOP** |
```
E `BUGS:211` continua a dire «**TRE RIGHE SONO PROVVISORIE E NON CHIUDONO**», elencando
③④ e «rientro senza STOP» con «prescritti 5+3, riferito l'esito senza conteggio».
⇒ **[M] Dopo la correzione, i tre siti concordano.** Nessuna riga preesistente toccata.

---

## §2 · PATERNITÀ E MESSAGGIO DI COMMIT

### (a) Paternità *(eseguito)*
LIBRO: `**Edit author:** CC — mandati A176 + A178 + A180 + A181 + A182 + A184 + A185 + A186 + A187, 22/08/2026`
BUGS changelog 60: `zero codice (mandati A176 + A178 + A180 + A181 + A182 + A184 + A185 + A186 + A187).**`
**[M] `A179` e `A183` restano a 0** su tutti e cinque i file.

### (c) 🔍 Il messaggio di commit riletto con TUTTE le lenti

**[A] Trattato come un canonico, come chiesto.** Quattro reperti, tutti nel testo di A186:

| # | reperto | lente | verdetto |
|---|---|---|---|
| ① | «la stessa osservazione **chiude la lacuna di conteggio**» | chiusura | 🚨 **FALSO** — è il difetto che questo mandato ripara |
| ② | «**Ratifiche di Mauro** del 22/08/2026» come intestazione di tutto | censimento implicito | ⚠️ **SOVRADICHIARA** — il blocco-puntatori di BOX3 e il puntatore al freeze sono igiene documentale di referee+CC, non ratifiche di Mauro |
| ③ | «stesure precedenti ne portavano **due**, entrambi falsi» | censimento | ⚠️ **VERO ma INVERIFICABILE DOPO** — quei due censimenti falsi non sono mai entrati in git: dopo il commit nessuno potrà contarli |
| ④ | «il corpus **e' stratificato** e chi lo governa e'…» | caratterizzazione non copiata dalla sede | ⚠️ **VERA ma non verbatim** — in un messaggio di commit, che è permanente, meglio il solo puntatore |

**[M] Verificati e SANI:** «Cinque canonici» (5 file) · «sei nomi ratificati» · «cinque
corretti» · «sei punti (a)-(f)» · «sette intestazioni di versione» · «zero codice».

### Il messaggio di commit FINALE — senza `Co-Authored-By`

```
docs: vocabolario dei due orologi, comportamento atteso e stato al 22/08

Cinque canonici, zero codice. Mauro ha ratificato il 22/08/2026 il
vocabolario e il comportamento atteso; il resto e' igiene documentale.

BOX5 V30 - capitolo NUOVO «VOCABOLARIO DEI DUE OROLOGI»: sei nomi ratificati
(OROLOGIO MOTORE AUDIO/GRAFICA · ACCENTO AUDIO/GRAFICO · CAMBIO SEZIONE
AUDIO/GRAFICO), di cui cinque corretti da Mauro rispetto alla proposta del
referee. Regola delle descrizioni simmetriche senza colpevole, REGOLA DI
RIPARAZIONE (l'audio e' il riferimento e non si tocca), COMPORTAMENTO ATTESO
al rientro nel player, precisazione tecnica misurata a 4629ee9.

BOX3 V100 - in testa un blocco di SOLI PUNTATORI alle sedi vive, senza
censimenti: le stesure precedenti ne portavano, ed erano falsi. Il corpo
resta quello di V99 (2026-07-22), byte-identico.

SCALETTA v12 - marcatura additiva in coda a sez.C: SEXIT riformulato e
scomposto in sei punti (a)-(f). L'ordine ratificato il 31/07 e' INVARIATO.
Il freeze grafico e' indicato per SEDE, mai per numero di revisione: chi
dichiara cosa e' normativo su cosa e' DESIGN/QLive_Nav/README.md.

BUGS v60 - osservazione diretta di Mauro del 22/08 sul ticket
TD-rientro-senza-stop-sgancia-audio-e-grafica, con la condizione di metro
scritta accanto ai numeri. Sulla riga «rientro senza STOP» della matrice di
TD-direttore-parte-da-bar2 la stessa osservazione CORROBORA l'esito ma NON
chiude la lacuna di conteggio: e' qualitativa, il conteggio prescritto non
e' stato eseguito, e la riga RESTA PROVVISORIA.

LIBRO v60 - una riga in Sez.2: ratifica del vocabolario, sede unica BOX5.

Le sole righe rimosse sono sette intestazioni di versione: nessun ticket,
nessuna tabella, nessuna marcatura preesistente e' stata toccata.

Referti: HANDOFF/MISURE_CC_2026-08-22_A176 / A178 / A180 / A181 / A182 /
A184 / A185 / A186 / A187.
```

---

## §3 · AUDIT FINALE

**[M] Sonda: enumerazione esaustiva.** **166 righe aggiunte**, lette tutte.

### 🆕 LENTE NUOVA — ogni CHIUSA / RISOLTA / VALIDATA / CORROBORATA: dov'è la misura?

| affermazione | dove | misura che la sostiene | esito |
|---|---|---|---|
| «**corrobora** in modo indipendente… **NON chiude** la lacuna» | `BUGS:216` | osservazione device di Mauro 22/08, citata nel ticket vicino; e la nota **dichiara essa stessa** che non è un conteggio | ✅ **sostenuta, e nei limiti giusti** |
| «**corrobora** l'esito ma **NON chiude**» | changelog 60 | idem | ✅ |
| «ERA FALSA, e la **falsificazione** è di CC (referto A181)» | BOX5 | referto A181, con `MetronomeDSP.h:127`, `MetronomeDSPBridge.mm:44/55/129`, `AudioEngine.swift:2369` | ✅ **misura esiste e ha un indirizzo** |
| «PRECISAZIONE TECNICA… **misurata a `4629ee9`**» | BOX5 | idem, più le riverifiche di A182/A184 | ✅ |
| «⟦NODO A⟧ **CHIUSO device** 17/07» | SCALETTA, catena versioni | **testo PREESISTENTE trasportato**, non affermazione nuova; la sua misura sta in LIBRO | ✅ fuori scope |

⇒ **[M] Nessuna affermazione di chiusura senza misura, dopo le correzioni del §1.**
⚠️ **[A] E il caso che il mandato ripara mostra la forma esatta del pericolo:** la misura
c'**era** (Mauro ha osservato davvero) ma era **della specie sbagliata** per la lacuna che
si diceva chiusa. **La lente giusta non è «esiste una misura?» ma «esiste una misura DELLA
SPECIE che serve?».**

### ✅ Le altre lenti — pulite

- **(a) forme con colpevole:** 4 hit, **tutti dentro blocchi esclusi per ratifica**. Zero fuori.
- **(b) numeri:** nessun portante non verificato. Il «due» falso del §1 è stato sostituito
  da un elenco.
- **(c) condizioni:** la 4/4 resta dichiarata; nessuna condizione nascosta.
- **(d) censimenti:** tutti veri e verificati; **nessuno nuovo fuori da BOX5**.
- **(e) caratterizzazioni:** resta solo «STRATIFICATO» in SCALETTA — **[A] cosmesi, non
  rischio**, già classificata in A186 e invariata.

### [A] Fuori perimetro: nulla di sostanziale

**[M]** Ho ricontrollato tutti gli otto reperti dei giri A182→A186: **restano chiusi.**
**[A] Non ho trovato in questo giro nessun reperto sostanziale fuori dal perimetro.**

---

## §3-bis · IL CANCELLO

**[M] Versioni: NESSUNA alzata.** BOX5 **V30** · LIBRO **60** · BUGS **60** ·
SCALETTA **12** · BOX3 **V100**.

**[M] BOX3, BOX5 e SCALETTA INTATTI da A186** — sha256 identici, il divieto è rispettato:
`de9faecf…` · `6d2446e6…` · `aaa47038…`

**[M] Byte / righe / CR — sonda a BYTE (`tr -cd '\r' | wc -c`):**

| file | byte | righe | CR | faccia | sha256 |
|---|---|---|---|---|---|
| `BOX5_QBEATS.md` | 70718 | 821 | **0** | LF | `6d2446e6e6681c170554e19f5ce38b16490eda29cd356ab44b626729234100cc` |
| `LIBRO_MASTRO_QBEATS.md` | 283972 | 524 | **524** | CRLF puro | `dead5ebfe64daf2f9ab2a9e7e63ecded5038251e32b47d037bd5b7ab343e9477` |
| `BUGS_QBEATS.md` | 353694 | 1213 | **1213** | CRLF puro | `cd7c7fd5c5241c995cc7209bdfa18d535d4b36478d82d875c603fdb803602672` |
| `HANDOFF/SCALETTA_…md` | 69169 | 498 | **0** | LF | `aaa470383cd9117704a635bc815a6f929b6e9bfbd1690804afae05a59223de11` |
| `BOX3_QBEATS.md` | 90638 | 819 | **0** | LF | `de9faecfaaa59870537d31497eb384a2cd9e7d4c2c30aefa281db712a83ea866` |

**[M] CR = righe** sui due CRLF · **CR = 0** sui tre LF ⇒ **nessuna faccia mista.**

**[M] Diffstat rispetto a HEAD:**
```
 BOX3_QBEATS.md                          |  18 +++++-
 BOX5_QBEATS.md                          | 100 +++++++++++++++++++++++++++++++-
 BUGS_QBEATS.md                          |   5 +-
 HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md |  43 +++++++++++++-
 LIBRO_MASTRO_QBEATS.md                  |   7 ++-
 5 files changed, 166 insertions(+), 7 deletions(-)
```
**[M] Delezioni: 7, tutte e sole intestazioni di versione.** Invariato da A184.

**[M] Stato del repo:**
```
 M BOX3 · M BOX5 · M BUGS · M HANDOFF/SCALETTA · M LIBRO
stage=0 · ios_app=0 righe · HEAD = 4629ee9ec943a1ebb8a16a49164aa457a8b99514 (invariato)
```
⛔ **NESSUN COMMIT. NESSUN `git add`. NESSUN PUSH.**

---

## ⚠️ Un guard mio, tarato male — e perché è andata bene

**[M]** Il primo tentativo di scrittura si è **fermato all'asserzione**: avevo messo fra i
controlli il residuo generico `«si chiude»`, che in BUGS compare in **10 punti legittimi**
(fra cui `:443` «la tastiera della ricerca non si chiude»). Lo script è abortito
**prima di scrivere** — **[M] verificato: sha256 di BUGS e LIBRO identici allo stato di
A186 dopo l'abort.** Ho ristretto il guard alle due frasi esatte e rieseguito.

**[A] È il rovescio della lezione di A186.** Là un controllo POSITIVO troppo stretto rese
un falso zero; qui un controllo NEGATIVO troppo largo ha reso un falso allarme. **Il costo
dei due errori non è simmetrico: il positivo troppo stretto ti fa concludere a vuoto, il
negativo troppo largo ti ferma.** Se devo sbagliare taratura, preferisco questa direzione.

---

## Cosa NON ho fatto

⛔ Nessun file sotto `ios_app/` toccato · nessun commit · nessun `git add` · nessun push ·
**BOX3, BOX5 e SCALETTA non toccati** (sha identici ad A186) · nessuna versione alzata ·
nessuna riga preesistente di BUGS modificata (solo le due righe aggiunte da questo commit) ·
non ho letto il congedo del referee.

---

### Controllo d'integrità di QUESTO file — sul CONTENUTO

**Prima riga attesa:** `# MISURE CC — A187 · LA LACUNA NON È CHIUSA`

**Stringhe obbligatorie:**
`Una lacuna di CONTEGGIO la chiude solo un CONTEGGIO` · `la stessa falsità viveva in DUE siti` ·
`della specie sbagliata` · `RESTA PROVVISORIA` · `test a **dieci** giri` ·
`cd7c7fd5c5241c995cc7209bdfa18d535d4b36478d82d875c603fdb803602672` ·
`il negativo troppo largo ti ferma` · e il marcatore di fine qui sotto.

⚠️ **Contate le stringhe, non i titoli.**

---

*A187-FINE — MISURE CC 22/08/2026 COMPLETO*
