# MISURE CC — A185 · CHIUSURA COMMIT

Da: CC · A: **referee** (+ Mauro)
Mandato: `A185-CHIUSURA-COMMIT` · **SCRITTURA, NESSUN COMMIT**
Completezza: **7 sezioni (§0→§6), ultima riga `A185-FINE-MANDATO` — integro.**
**[M] Modello: intestazione Opus 5, interfaccia Opus 5 — coincidono.**

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato, non rimisurato ·
**[A]** giudizio mio.
⛔ **Zero tocchi a `ios_app/`. Nessun commit, nessun `git add`, nessun push.**

---

# ⚠️ DUE COSE PRIMA DEL COMMIT — entrambe FUORI dal perimetro dei §1-§5

Il §6 mi chiede di dirlo esplicitamente invece di limitarmi a elencare. Lo dico.

| # | cosa | dove | perché non l'ho corretta |
|---|---|---|---|
| **①** | **Un CENSIMENTO sopravvive fuori da BOX5:** «+ le due decisioni di Mauro in attesa» | `SCALETTA`, stessa voce che il §2 mi ha fatto correggere — ma sull'**altra metà** | §2: «⛔ Nient'altro nella SCALETTA» |
| **②** | **«Tre erano stati proposti diversamente» sopravvive in LIBRO** | `LIBRO_MASTRO_QBEATS.md`, Sez.2 | §4: «⛔ Nient'altro in BOX5» — LIBRO non era nel perimetro |

**[A] Entrambe sono sostanziali. La ② è la stessa falsità che il §4 ha appena corretto in
due siti su tre: il commit uscirebbe dicendo «cinque su sei» in BOX5 e «tre» in LIBRO.**
Dettaglio misurato in §6. Basta una parola su ciascuna.

---

## §0 · ID `A185` — LIBERO

**[M] Per NOME (potata):** 0 su repo, 0 su E:. Trappola ① **morde** (1 hit non potato in
`.git/objects`). Controllo positivo forma identica (`A184`): 1 per gamba.

**[M] Per CONTENUTO:** **0 su repo**, 8 su E: — **tutti classe ②** (log di device:
`uuid: F96A185F-0ABC-439`, `3504DEFE-A185-4050-86CF`, …). **[M] Classe ④ assente.**

**[M] Controllo positivo `A184`:** 3 su repo / 10 su E:. **Negativo tarato:** 0.

---

## §1 · BOX3 — via il blocco di stato, dentro i puntatori *(eseguito)*

**[M] Faccia:** LF, invariata. **[M] Versione:** resta **V100**.

### (a) Intestazione

PRIMA: `BOX3 V100 — 2026-08-22 (AUTOPORTANTE — V100 aggiunge SOLO il blocco di stato in testa, 22/08; il CORPO resta quello di V99, datato 2026-07-22) · …`
DOPO: `BOX3 V100 — 2026-08-22 (AUTOPORTANTE — V100 aggiunge in testa SOLO UN BLOCCO DI PUNTATORI, senza censimenti; il CORPO resta quello di V99, datato 2026-07-22) · …`

### (b) Riga di delta

DOPO, verbatim:
```
Supersede V99 (blocco di SOLI PUNTATORI in testa, 22/08/2026 — mandato A185; ZERO riscritture: il corpo di V99 è riportato sotto INVARIATO, e la sua data resta 2026-07-22. ⛔ Il blocco NON contiene censimenti: una versione precedente ne portava due — «due ticket bloccanti palco» e un elenco dei pulsanti morti del transport — ed erano entrambi falsi. Sostituiti da indirizzi alle sedi vive):
```

### (c) Il blocco — RIMOSSO per intero e sostituito

RIMOSSE **22 righe** (il blocco «STATO VIVO AL 22/08/2026» completo: i due ticket, la riga
«SONO DUE DIFETTI DIVERSI», le tre righe di puntatori e la ratifica sui pulsanti morti).
INSERITO, **parola per parola dal §1**:
```
⚠️ QUESTO DOCUMENTO È FERMO AL 22/07/2026 (V99). Blocco di puntatori
aggiunto il 22/08/2026 (mandato A185). NON contiene censimenti: un
documento vecchio deve indicare, non raccontare.

Dove sta lo stato aggiornato:
· vocabolario obbligatorio dei due orologi → BOX5, capitolo «VOCABOLARIO
  DEI DUE OROLOGI»
· ordine dei lavori e scomposizione di ⟦S-EXIT⟧ → SCALETTA, Sezione C
· stato dei bug e delle gravità → BUGS, sede unica
· misure di agosto agli atti → HANDOFF/, referti A166, A172, A173

⛔ Non ricavare da questo documento nessun elenco completo: la riscrittura
piena è il punto 5 della roadmap in SCALETTA Sezione C.
```

**[M] Residui a zero in BOX3:** `DUE TICKET` · `PALETTI DI MEMORIA` · `restart` ·
`STATO VIVO AL 22/08` → **0** ciascuno.
✅ **[M] «ZERO riscritture» PROVATO, non asserito:** il corpo da `Supersede V98 (` in giù è
**byte-identico a HEAD** — 83 035 caratteri su disco, 83 035 a `4629ee9`, confronto di
stringa `True`.

---

## §2 · SCALETTA — via il numero di revisione *(eseguito)*

**[M] Faccia:** LF, invariata. **[M] Versione:** resta **12**.

PRIMA:
```
3) freeze grafico rev3 + le due decisioni di Mauro in attesa.
```
DOPO:
```
3) freeze grafico — revisione corrente da verificare a fonte in
   DESIGN/QLive_Nav/ (rev3 è SUPERSEDE) + le due decisioni di Mauro in attesa.
```
**[A] Il puntatore alla cartella non invecchia**, come prescritto: nessun numero nuovo da
sbagliare. **[M] Residuo `freeze grafico rev3`: 0.**
⚠️ **La seconda metà della voce è il reperto ① — vedi §6(d).**

---

## §3 · BUGS — la condizione mancante *(eseguito)*

**[M] Faccia:** CRLF, CR = righe = 1213. **[M] Versione:** resta **60**.

PRIMA:
```
…l'accento si sente sul secondo, terzo o quarto movimento di quello che il display mostra, e circa una volta su quattro i due coincidono per caso…
```
DOPO:
```
…l'accento si sente sul secondo, terzo o quarto movimento di quello che il display mostra, e circa una volta su quattro i due coincidono per caso — ⚠️ **posizioni e probabilità valgono in 4/4: dipendono dai movimenti per battuta, e in un altro metro cambiano entrambe** (in 3/4: secondo o terzo, una volta su tre)…
```
**[A] Ho scelto di rendere esplicita la dipendenza invece di togliere i numeri**: il dato
osservato da Mauro resta leggibile, e la condizione che lo governa è scritta accanto.

---

## §4 · BOX5 — cinque su sei, tutti nominati *(eseguito, DUE siti)*

**[M] Faccia:** LF. **[M] Versione:** resta **V30**.

⚠️ **[M] Il testo era in DUE siti, non uno — e uno era spezzato su più righe.** Sonda a
riga singola: 1. Sonda sul testo continuo (che attraversa i ritorni a capo): **2**.
`BOX5:8` (Delta, riga unica) e `BOX5:194` (capitolo, spezzato). **[A] È la stessa trappola
della riga-a-capo che mi era già costata un falso zero in A182: l'ho cercata apposta.**

**Sito 1 — capitolo.** PRIMA:
```
Tutti e sei i nomi sono ratificati da Mauro il 22/08/2026. Tre erano stati
proposti diversamente dal referee e corretti da Mauro: ACCENTO AUDIO (era
«accento sonoro»), ACCENTO GRAFICO (era «primo verde»), CAMBIO SEZIONE
AUDIO/GRAFICO (erano «cambio suonato»/«cambio scritto», non italiano).
```
DOPO:
```
Tutti e sei i nomi sono ratificati da Mauro il 22/08/2026. CINQUE SU SEI
erano stati proposti diversamente dal referee e corretti da Mauro:
OROLOGIO MOTORE AUDIO (era «orologio motore»), ACCENTO AUDIO (era «accento
sonoro»), ACCENTO GRAFICO (era «primo verde»), CAMBIO SEZIONE AUDIO (era
«cambio suonato»), CAMBIO SEZIONE GRAFICO (era «cambio scritto»; quei due
non erano italiano). Solo OROLOGIO GRAFICA è rimasto come proposto.
```

**Sito 2 — riga di Delta V30.** PRIMA: `Tre erano stati proposti diversamente dal referee e
corretti da Mauro prima della ratifica: ACCENTO AUDIO (era «accento sonoro»), ACCENTO
GRAFICO (era «primo verde»), CAMBIO SEZIONE AUDIO/GRAFICO (erano «cambio suonato»/«cambio
scritto», non italiano).`
DOPO: `Cinque su sei erano stati proposti diversamente dal referee e corretti da Mauro prima
della ratifica: OROLOGIO MOTORE AUDIO (era «orologio motore»), ACCENTO AUDIO (era «accento
sonoro»), ACCENTO GRAFICO (era «primo verde»), CAMBIO SEZIONE AUDIO (era «cambio suonato»),
CAMBIO SEZIONE GRAFICO (era «cambio scritto»). Solo OROLOGIO GRAFICA è rimasto come proposto.`

**[M] Residuo `Tre erano stati` in BOX5: 0.** ⚠️ **In LIBRO: 1 — reperto ②, §6.**

---

## §5 · PATERNITÀ E MESSAGGIO DI COMMIT

**(a)** LIBRO: `**Edit author:** CC — mandati A176 + A178 + A180 + A181 + A182 + A184 + A185, 22/08/2026`
BUGS changelog 60: `zero codice (mandati A176 + A178 + A180 + A181 + A182 + A184 + A185).**`
**[M] `A179` e `A183` rendono 0 su tutti e cinque i file.**

**(b) Messaggio di commit proposto — SENZA `Co-Authored-By`**, come confermato:

```
docs: vocabolario dei due orologi, comportamento atteso e stato al 22/08

Cinque canonici, zero codice. Ratifiche di Mauro del 22/08/2026.

BOX5 V30 - capitolo NUOVO «VOCABOLARIO DEI DUE OROLOGI»: sei nomi ratificati
(OROLOGIO MOTORE AUDIO/GRAFICA · ACCENTO AUDIO/GRAFICO · CAMBIO SEZIONE
AUDIO/GRAFICO), regola delle descrizioni simmetriche senza colpevole, REGOLA
DI RIPARAZIONE (l'audio e' il riferimento e non si tocca), COMPORTAMENTO
ATTESO al rientro nel player, precisazione tecnica misurata a 4629ee9.

BOX3 V100 - in testa un blocco di SOLI PUNTATORI alle sedi vive. Nessun
censimento: una stesura precedente ne portava due, entrambi falsi. Il corpo
resta quello di V99 (2026-07-22), byte-identico.

SCALETTA v12 - marcatura additiva in coda a sez.C: SEXIT riformulato e
scomposto in sei punti (a)-(f). L'ordine ratificato il 31/07 e' INVARIATO.

BUGS v60 - osservazione diretta di Mauro del 22/08 sul ticket
TD-rientro-senza-stop-sgancia-audio-e-grafica, con la condizione di metro
scritta accanto ai numeri; sulla riga «rientro senza STOP» della matrice di
TD-direttore-parte-da-bar2 la stessa osservazione chiude la lacuna di
conteggio, per quella riga soltanto.

LIBRO v60 - una riga in Sez.2: ratifica del vocabolario, sede unica BOX5.

Le sole righe rimosse sono sette intestazioni di versione: nessun ticket,
nessuna tabella, nessuna marcatura preesistente e' stata toccata.

Referti: HANDOFF/MISURE_CC_2026-08-22_A176 / A178 / A180 / A181 / A182 /
A184 / A185.
```

---

## §6 · AUDIT FINALE

**[M] Sonda: enumerazione esaustiva.** `git diff | grep '^+'` → **163 righe aggiunte**,
lette tutte.

### ✅ (a) FORME CON COLPEVOLE — ZERO fuori dai blocchi esclusi

**[M]** Sonda su `l'audio è | la grafica (ha|è|non) | il motore (non|è|ha) | è la grafica |
è il motore | sano | colpevole` → **4 hit, tutti dentro blocchi esclusi per ratifica**:
la riga del divieto stesso · il punto (3) del COMPORTAMENTO ATTESO · le due righe finali
che dichiarano la descrizione senza colpevole e la riparazione asimmetrica.

✅ **[M] La violazione `BOX3:13-14` trovata in A182 è SPARITA**: quel blocco è stato
sostituito dal §1. `L'audio è sano` rende **0**.

### 🚨 (d) CENSIMENTI — la lente nuova. UNO sopravvive fuori da BOX5

**[M] Metodo:** cercati i costrutti di completezza — articolo determinativo + numerale,
«tutti e», «solo», «unico», «nessun altro», «zero», «soltanto» — poi **contata la cosa
reale** per ciascuno.

| censimento | dove | verdetto |
|---|---|---|
| «Tutti e sei i nomi… CINQUE SU SEI… Solo OROLOGIO GRAFICA» | BOX5 | ✅ **VERO** — riconteggio in §4 |
| «(zero compilazione condizionale nel file)» | BOX5 | ✅ **VERO** — 0 `#if` in `MetronomeDSPBridge.mm` |
| «porta SOLTANTO il numero progressivo» | BOX5 | ✅ **VERO** — `PassthroughSubject<Int, Never>` |
| «ZERO riscritture: il corpo di V99… INVARIATO» | BOX3 | ✅ **VERO, PROVATO** — corpo byte-identico, 83 035 caratteri |
| «Le altre due righe provvisorie (④, Sintomo ②)» | BUGS | ✅ **VERO** — `BUGS:211` ne dichiara tre, una si chiude |
| «in sei punti (a)-(f)» | SCALETTA | ✅ **VERO** — la marcatura ne porta sei |
| **«+ le due decisioni di Mauro in attesa»** | **SCALETTA** | 🚨 **NON VERIFICABILE, e la fonte più vicina lo contraddice** |

#### 🚨 Il reperto ① — «le due decisioni di Mauro in attesa»

**[M]** Sonda su tutti e cinque i canonici per `decisioni di Mauro in attesa` /
`decisioni in attesa` → **una sola occorrenza, questa.** Nessun canonico contiene un
censimento che le fissi a due.

**[M] La fonte più vicina è `DESIGN/QLive_Nav/README.md:21`** (riga d'indice scritta da CD),
e distingue **due cose diverse**:
- «**Le due decisioni non si muovono**» — due decisioni **ferme**, non in attesa;
- «**Aperti:** H (altezza badge nell'app) · il titolo più in alto, inspiegato · lh 1.12
  ratificata ma inattuabile» — **TRE** voci aperte.

⇒ **[A] La frase conflaziona le due categorie:** chiama «in attesa» ciò che il README dice
fermo, e se «in attesa» significa gli aperti allora sono **tre**, non due. **È un censimento
con articolo determinativo dentro una roadmap ratificata** — la stessa forma che il §1 ha
appena tolto da BOX3.
⛔ **Non corretto:** §2 dice «Nient'altro nella SCALETTA», e ho toccato l'altra metà della
stessa riga.
**[A] Forma che toglierebbe il censimento senza aggiungere nulla:**
`+ le decisioni di Mauro in attesa (elenco a fonte in DESIGN/QLive_Nav/README.md)`.

#### 🚨 Il reperto ② — «Tre» sopravvive in LIBRO

**[M]** `Tre erano stati` per file: BOX5 **0** · BUGS **0** · SCALETTA **0** · BOX3 **0** ·
**LIBRO 1**. Testo verbatim in LIBRO, Sez.2:
> «**Tre** erano stati proposti diversamente dal referee e sono stati CORRETTI da Mauro
> prima della ratifica:** ACCENTO AUDIO (era «accento sonoro»), ACCENTO GRAFICO (era «primo
> verde»), CAMBIO SEZIONE AUDIO/GRAFICO …»

⇒ **[A] Il commit uscirebbe con «cinque su sei» in BOX5 e «tre» in LIBRO, sullo stesso
fatto.** ⛔ Non corretto: il §4 dice «Nient'altro in BOX5» e LIBRO non era nel perimetro.
**[A] Correzione: la stessa del §4**, applicata alla riga di LIBRO.

### (b) NUMERI · (c) CONDIZIONI

**[M] Nessun numero PORTANTE non verificato** fra le righe aggiunte. I portanti sono i sei
censimenti verdi della tabella sopra, più le versioni (`V30`, `60`, `12`, `V100`), che sono
puntatori per R7.2. Decorativi dichiarati: «Intro 100» (il testo stesso lo qualifica
esempio), gli identificativi di run e le catene di versione trasportate.

**[M] Nessuna CONDIZIONE NASCOSTA sopravvive.** L'unica trovata in A184 — i numeri
dell'accento validi solo in 4/4 — è stata **esplicitata dal §3**. ✅ **[M] Verificata la
correttezza della condizione aggiunta:** `beatsPerBar` è variabile (`AudioEngine.swift:57`),
la UI gestisce 6/8 e 12/8 (`LiveView.swift:480`), e in 3/4 le posizioni sono due e la
coincidenza è una su tre — che è ciò che la nuova parentesi dice.

Le affermazioni tecniche restanti sono **SEMPRE** vere: accessore pubblico · lettura del
ponte senza compilazione condizionale (condizione dichiarata) · flag d'accento che
attraversa C→Swift · tick che porta solo il progressivo.

### ⚠️ Un errore mio nella taratura, dichiarato

**[M]** Uno dei miei controlli positivi (`blocco di puntatori`) ha reso **0** perché era
**sensibile alle maiuscole**: il testo reale è `BLOCCO DI PUNTATORI` (riga 1) e
`Blocco di puntatori` (riga 4). **[A] Un controllo positivo che rende zero non prova che
il testo manchi: prova che la sonda è tarata male.** Ripetuto con `-i`: 2 hit. Non ha
toccato nessuna conclusione, ma è la stessa famiglia del falso zero da apostrofo.

---

## §6-bis · IL CANCELLO

**[M] Versioni: NESSUNA alzata.** BOX5 **V30** · LIBRO **60** · BUGS **60** ·
SCALETTA **12** · BOX3 **V100**.

**[M] Byte / righe / CR — sonda a BYTE (`tr -cd '\r' | wc -c`):**

| file | byte | righe | CR | faccia | sha256 |
|---|---|---|---|---|---|
| `BOX5_QBEATS.md` | 70718 | 821 | **0** | LF | `6d2446e6e6681c170554e19f5ce38b16490eda29cd356ab44b626729234100cc` |
| `LIBRO_MASTRO_QBEATS.md` | 283845 | 524 | **524** | CRLF puro | `3d2bee98f5ea9e4d35e34652f9fb32b816d9a86547f2b7472e677b3cef04ff92` |
| `BUGS_QBEATS.md` | 353422 | 1213 | **1213** | CRLF puro | `613df14a53df0d442910f21daa8c596d7533ebea7a7ce0e8bdb13699bfc12cde` |
| `HANDOFF/SCALETTA_…md` | 68970 | 495 | **0** | LF | `86c7214d517ecaf20720415e6cbd9938cbb48534f30330cc2c91daca3ff7b4d7` |
| `BOX3_QBEATS.md` | 90638 | 819 | **0** | LF | `de9faecfaaa59870537d31497eb384a2cd9e7d4c2c30aefa281db712a83ea866` |

**[M] CR = righe** sui due CRLF · **CR = 0** sui tre LF ⇒ **nessuna faccia mista.**

**[M] Diffstat rispetto a HEAD:**
```
 BOX3_QBEATS.md                          |  18 +++++-
 BOX5_QBEATS.md                          | 100 +++++++++++++++++++++++++++++++-
 BUGS_QBEATS.md                          |   5 +-
 HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md |  40 ++++++++++++-
 LIBRO_MASTRO_QBEATS.md                  |   7 ++-
 5 files changed, 163 insertions(+), 7 deletions(-)
```
⚠️ **[M] BOX3 è passato da +26 a +17 righe:** il blocco di puntatori è più corto del blocco
di stato che ha sostituito. È l'unico file il cui contributo si è **ridotto**.

**[M] AUDIT DELLE DELEZIONI — 7 righe, tutte e sole intestazioni:**
```
BOX3 V99 — 2026-07-22 (AUTOPORTANTE) · HEAD=origin=bfa07eb (…)
**Versione:** V29 — 21/08/2026
**Versione:** 59
**Versione:** 11 (18/08/2026)  ·  **Ratificata dal referee:** …
**Versione:** 59 (21/08/2026)
**Ultima modifica:** 2026-08-21 (v59 — …)
**Edit author:** CC — mandato A162, 21/08/2026
```
⇒ **[M] Nessun ticket, nessuna riga di tabella, nessuna marcatura preesistente rimossa.**
*(Le 22 righe del blocco BOX3 sostituito non compaiono qui: erano righe **aggiunte da questo
stesso commit** in A178, mai committate, quindi il diff verso HEAD non le vede.)*

**[M] Residui attesi a zero, verificati:** `A179` 0 · `A183` 0 · `DUE TICKET` 0 ·
`PALETTI DI MEMORIA` 0 · `freeze grafico rev3` 0 · `ACCENTO SONORO` 0 · `PRIMO VERDE` 0 ·
`STATO VIVO AL 22/08` 0. **Controlli positivi forma identica:** `CINQUE SU SEI` 1 ·
`valgono in 4/4` 1 · `rev3 è SUPERSEDE` 1 · `+ A185` 2.

**[M] Stato del repo:**
```
 M BOX3 · M BOX5 · M BUGS · M HANDOFF/SCALETTA · M LIBRO
stage=0 · ios_app=0 righe · HEAD = 4629ee9ec943a1ebb8a16a49164aa457a8b99514 (invariato)
```
⛔ **NESSUN COMMIT. NESSUN `git add`. NESSUN PUSH.**

---

## Cosa NON ho fatto

⛔ Nessun file sotto `ios_app/` toccato · nessun commit · nessun `git add` · nessun push ·
nessuna versione alzata · **reperto ① (SCALETTA) e reperto ② (LIBRO) non corretti**, fuori
perimetro e dichiarati esplicitamente · non ho letto il congedo del referee.

---

### Controllo d'integrità di QUESTO file — sul CONTENUTO

**Prima riga attesa:** `# MISURE CC — A185 · CHIUSURA COMMIT`

**Stringhe obbligatorie:**
`le due decisioni di Mauro in attesa` · `Le due decisioni non si muovono` ·
`byte-identico a HEAD` · `CINQUE SU SEI` · `sensibile alle maiuscole` ·
`de9faecfaaa59870537d31497eb384a2cd9e7d4c2c30aefa281db712a83ea866` ·
`SENZA \`Co-Authored-By\`` · e il marcatore di fine qui sotto.

⚠️ **Contate le stringhe, non i titoli.**

---

*A185-FINE — MISURE CC 22/08/2026 COMPLETO*
