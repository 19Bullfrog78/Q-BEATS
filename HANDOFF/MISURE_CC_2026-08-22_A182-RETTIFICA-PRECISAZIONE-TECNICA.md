# MISURE CC — A182 · RETTIFICA DELLA PRECISAZIONE TECNICA

Da: CC · A: **referee** (+ Mauro)
Mandato: `A182-RETTIFICA-PRECISAZIONE-TECNICA` · **SCRITTURA, NESSUN COMMIT**
Completezza: **5 sezioni (§0→§4), ultima riga `A182-FINE-MANDATO` — integro.**
**[M] Modello: intestazione Opus 5, interfaccia Opus 5 — coincidono.**

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato, non rimisurato ·
**[A]** giudizio mio.
⛔ **Zero tocchi a `ios_app/`. Nessun commit, nessun `git add`, nessun push.**
**[M] I quattro bersagli assoluti combaciavano tutti con lo stato reale: nessuna
discrepanza da dichiarare** (tabella in §0-bis).

---

# 🚨 UN NUMERO SBAGLIATO NELLA RETTIFICA — ed è MIO

**Ho eseguito le quattro modifiche. La nuova PRECISAZIONE TECNICA è vera su tutto,
tranne un numero — che le ho fornito io in A181 senza interrogarlo.**

**[M] Il testo appena inciso dice:**
> «· la posizione di fase di Link è dichiarata e **GIÀ USATA in quattro punti
> di produzione**.»

**[M] Sono TRE punti di produzione, non quattro.** Il quarto è sotto compilazione
condizionale. Misurato costruendo le regioni `#if…#endif` di `AudioEngine.swift` e
collocandoci dentro ciascuna chiamata:

```
  AudioEngine.swift:675  ->  produzione (nessun #if)
  AudioEngine.swift:739  ->  produzione (nessun #if)
  AudioEngine.swift:839  ->  DENTRO #if QB_DIAG_SPY (830-845)
  AudioEngine.swift:967  ->  produzione (nessun #if)
```

**[M] L'origine dell'errore è il mio referto A181, riga 167**, verbatim:
> «**[M] Chiamata quattro volte in produzione:**»

⛔ **[A] L'ho marcata `[M]` — misurata — e avevo misurato solo le chiamate, non le
guardie.** Il referee ha preso quel numero, l'ha ratificato in buona fede e l'ha inciso.
È **esattamente la forma d'errore** che questa catena di mandati sta correggendo da
A176 in poi: *un numero entra in un canonico travestito da misura*. Stavolta l'ho
prodotto io, e nella riga che rettifica una falsità altrui.

**[A] Correzione minima proposta** — una parola e un inciso:
```
· la posizione di fase di Link è dichiarata e GIÀ USATA in TRE punti di
  produzione (più un quarto sotto compilazione condizionale diagnostica).
```
⛔ **Non l'ho applicata:** è testo del referee, dato verbatim.

⚠️ **[A] Non cambia la conclusione operativa della riga** — «il canale esiste e arriva
già fino a Swift» resta vero con tre punti invece di quattro. Cambia la sua *precisione*,
e questa riga esiste proprio perché una imprecisione precedente aveva indirizzato male la
riparazione.

---

## §0 · ID `A182` — LIBERO

**[M] Per NOME (potata):** 0 su repo, 0 su E:. Trappola ① **non morde**.
Controllo positivo forma identica (`A181`): 1 per gamba.

**[M] Per CONTENUTO:** 3 su repo, 12 su E: — **tutti classificati, nessun uso come mandato**:

| classe | dove |
|---|---|
| ④ ID come esempio didattico | `HANDOFF/MISURE_CC_2026-08-21_A164-…md:74` — `\| A178 / A180 / A182 \| 0 \| 0 \| 0 \| 0 \| controllo **negativo** \|` |
| ④ di rimbalzo (1° livello) | `HANDOFF/MISURE_CC_2026-08-22_A178-…md:28` — cita quella riga |
| ④ di rimbalzo (2° livello) | `HANDOFF/MISURE_CC_2026-08-22_A180-…md:64` — cita a sua volta |
| ④+②, gli stessi su E: | 3 file mirror + 9 `LOG/RUN/…` (classe ②) |

⚠️ **[A] La quarta classe è ora a TRE livelli di propagazione.** A164 tabulò tre ID
futuri come controlli negativi; A178 lo documentò citandolo; A180 documentò A178 citandolo
ancora. **Ogni referto che spiega la classe ④ la estende di un livello.**

**[M] Controllo positivo `A181`:** 3 su repo / 8 su E:. **Negativo tarato:** 0.

---

## §0-bis · Stato dei quattro bersagli — tutti combaciavano

| § | bersaglio | stato trovato | combacia? |
|---|---|---|---|
| §1 | vecchia precisazione in BOX5 | presente, integra | ✅ |
| §2 | `L'audio è sano: è la grafica…` in BOX3 | presente, 1 occorrenza | ✅ |
| §3(a) | LIBRO `…+ A180 + A181, 22/08/2026` | presente | ✅ |
| §3(b) | BUGS `(mandati A176 + A178 + A180 + A181)` | presente | ✅ |

⚠️ **[M] Una collisione d'ancora incontrata e risolta:** cercando il blocco della
precisazione su una riga sola la sonda rendeva **0**, perché il testo va a capo
(`e la` / `scarta senza…`). Ho ancorato sul blocco a sei righe, `count == 1`. Segnalato
perché uno zero da riga-spezzata è indistinguibile da uno zero vero.

---

## §1 · BOX5 — precisazione rettificata *(eseguito verbatim)*

**[M] Faccia:** LF, invariata (0 CR). **[M] Versione:** resta **V30**.
**[M] La coda del blocco «COMPORTAMENTO ATTESO» è intatta** (asserzione di controllo sul
paragrafo `Questo comportamento atteso NON contraddice…`, `count == 1` dopo l'edit).

PRIMA:
```
⚠️ PRECISAZIONE TECNICA DEL REFEREE, misurata (A172/A173): oggi la grafica
non «rifiuta» di allinearsi — NON HA MODO DI CHIEDERE. Il motore calcola la
propria posizione dentro la battuta, la usa per suonare l'accento, e la
scarta senza consegnarla a nessuno. ⇒ Il difetto è UNA CAPACITÀ CHE MANCA,
non una scelta sbagliata del codice. Conta al momento di riparare: non c'è
una riga da correggere, c'è un'informazione da consegnare.
```
DOPO (testo del §1 del mandato, **parola per parola**):
```
⚠️ PRECISAZIONE TECNICA DEL REFEREE — RETTIFICATA 22/08/2026, misurata a
`4629ee9`. Una versione precedente di questa riga diceva che il motore
«scarta la posizione senza consegnarla a nessuno» e che la grafica «non ha
modo di chiedere». ERA FALSA, e la falsificazione è di CC (mandato A182),
rimisurata dal referee. In realtà:
· il DSP C++ espone un accessore PUBBLICO della posizione dentro la battuta;
· il ponte lo legge in TRE punti che girano in produzione (zero compilazione
  condizionale nel file);
· il flag di accento per-battito ATTRAVERSA GIÀ il confine C→Swift e viene
  letto dentro AudioEngine;
· la posizione di fase di Link è dichiarata e GIÀ USATA in quattro punti
  di produzione.

⇒ CIÒ CHE MANCA È UN SOLO PASSAGGIO, L'ULTIMO: AudioEngine non ripubblica
quell'informazione alla vista — il messaggio che raggiunge la grafica a
ogni battito porta SOLTANTO il numero progressivo del battito.

⛔ CHI RIPARERÀ NON DEVE COSTRUIRE UN CANALE NUOVO: il canale esiste e
arriva già fino a Swift. Va esteso l'ultimo tratto. ⛔ E non deve toccare
il motore audio: vedi la REGOLA DI RIPARAZIONE sopra.
```

### [M] Verifica di ogni affermazione contro il codice a `4629ee9`

| affermazione | esito | prova |
|---|---|---|
| accessore **PUBBLICO** della posizione | ✅ **VERO** | `core_engine/MetronomeDSP.h:127` `uint32_t getCurrentBeatInBar() const { return _currentBeatInBar; }`, dentro la sezione `public:` (`:30` → `private:` a `:147`) |
| ponte lo legge in **TRE** punti, **zero** compilazione condizionale | ✅ **VERO** | `MetronomeDSPBridge.mm:44`, `:55`, `:129`; sonda `grep -cE '^\s*#\s*(if\|ifdef\|ifndef)'` sul file → **0** |
| flag d'accento **attraversa il confine C→Swift** | ✅ **VERO** | `MetronomeDSP.cpp:455` → `MetronomeDSPBridge.mm:98` `accents[count] = ev.accent ? 1 : 0;` → `AudioEngine.swift:2369` `let isAccent = accents[i] != 0` |
| fase Link **dichiarata** | ✅ **VERO** | `MIDIEngineBridge.h:155` `double phaseAtHost;   // ABLLinkPhaseAtTime(state, hostTime, quantum), in [0, quantum)` |
| **«GIÀ USATA in quattro punti di produzione»** | ❌ **SONO TRE** | vedi riquadro rosso in testa |
| il tick alla grafica porta **solo il progressivo** | ✅ **VERO** | `AudioEngine.swift:121` `PassthroughSubject<Int, Never>`; `:2374-2376` invia `tickN` e nient'altro |

⚠️ **[A] Un secondo appunto, minore, sulla stessa riga:** il testo dice «la falsificazione
è di CC (**mandato A182**)». **[M] La falsificazione è del mandato A181** — è il referto
`HANDOFF/MISURE_CC_2026-08-22_A181-COMPORTAMENTO-ATTESO.md` a contenerla; A182 è il
mandato che la ratifica e la incide. Non corretto: testo del referee.

---

## §2 · BOX3 — l'ultima frase con un colpevole *(eseguito)*

**[M] Faccia:** LF, invariata. **[M] Versione:** resta **V100**.

PRIMA:
```
  uscita-rientro. L'audio è sano: è la grafica ad aver perso il riferimento.
```
DOPO:
```
  uscita-rientro. I due orologi sono partiti da punti diversi.
```
**[M] La frase intera, ora simmetrica su entrambe le metà** (`BOX3:15-16`):
```
  ⇒ ACCENTO AUDIO e ACCENTO GRAFICO NON COINCIDONO, e lo scarto CRESCE a ogni
  uscita-rientro. I due orologi sono partiti da punti diversi.
```
**[M] Nient'altro toccato in BOX3.**

---

## §3 · PATERNITÀ *(eseguito)*

**[M] Facce invariate:** LIBRO CR = righe = 524 · BUGS CR = righe = 1213.
**[M] Versioni:** LIBRO **60**, BUGS **60**.

**(a) LIBRO** — PRIMA: `**Edit author:** CC — mandati A176 + A178 + A180 + A181, 22/08/2026`
DOPO: `**Edit author:** CC — mandati A176 + A178 + A180 + A181 + A182, 22/08/2026`

**(b) BUGS changelog 60** — PRIMA: `zero codice (mandati A176 + A178 + A180 + A181).**`
DOPO: `zero codice (mandati A176 + A178 + A180 + A181 + A182).**`

---

## §4 · SPAZZATA GRAMMATICALE — progetto della sonda, taratura, esito

### [A] La sonda, e perché non è un pattern

⛔ **Una regex non può cercare la grammatica.** La sonda precedente cercava i **nomi** del
vocabolario e per questo mancò `BOX3:16` («L'audio è sano…»), che una colpa la assegna
senza nominare né ACCENTO né OROLOGIO. **[A] Qualunque elenco di pattern avrà sempre un
sinonimo fuori.**

**[M] Sonda adottata: ENUMERAZIONE ESAUSTIVA + LETTURA.**
```
git diff --no-color -- <i 5 file> | grep '^+' | grep -v '^+++'
```
→ **163 righe aggiunte**, lette **tutte**, una per una. `grep` usato solo per *localizzare*,
mai per concludere.
⛔ **Esclusi per ratifica:** citazioni-di-divieto in BOX5 · REGOLA DI RIPARAZIONE ·
COMPORTAMENTO ATTESO (compresi (1)(2)(3) e la PRECISAZIONE).

### ✅ [M] TARATURA — eseguita PRIMA della riparazione del §2

Ho fatto girare la sonda sullo stato **pre-§2**, quando sapevo esserci una violazione:
```
TROVATA: +  uscita-rientro. L'audio è sano: è la grafica ad aver perso il riferimento.
```
⇒ **la sonda vede ciò che la precedente mancava.** Solo dopo ho riparato e rieseguito.

### 🚨 [M] ESITO dopo la riparazione — UNA violazione, e l'avevo archiviata io

⚠️ **CORREZIONE DEL MIO PRIMO VERDETTO.** Nella prima stesura di questo referto avevo
scritto «ZERO violazioni», archiviando `BOX3:13-14` come «meccanismo, non giudizio». **Era
un verdetto sbagliato.** La corroborazione indipendente (tre lettori, lenti distinte) l'ha
segnalata tutte e tre le volte, una ad alta confidenza, con un argomento che io non avevo
fatto. **L'ho rimisurato di persona e regge: è una violazione, e per giunta produce una
contraddizione interna al commit.** Il verdetto corretto è quello che segue.

**[M] Righe aggiunte per file, tutte lette:** BOX3 26 · BOX5 100 · BUGS 4 · SCALETTA 38 ·
LIBRO 4.

### 🚨 VIOLAZIONE — `BOX3_QBEATS.md:13-14`

Verbatim, righe aggiunte da questo commit:
```
  a comando. Uscendo dal player senza STOP il motore non si ferma; al rientro
  l'avvio lo trova acceso, esce in silenzio e non azzera il contatore.
```

**[M] Quattro misure che la inchiodano:**

**(1) Tutti i soggetti stanno sul lato AUDIO, tutti con verbi di omissione.**
`il motore` → «**non si ferma**» · `l'avvio` → «**esce in silenzio**», «**non azzera** il
contatore». **[M] Il lato grafica non compare: sonda su `grafic|display|OROLOGIO GRAFICA`
nelle due righe → 0 occorrenze.** È un resoconto a una campana sola.

**(2) La forma conforme ESISTEVA GIÀ, nello stesso commit.**
`HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:443-444` descrive **lo stesso identico fatto**:
```
A173): uscendo dal player senza STOP l'OROLOGIO MOTORE AUDIO prosegue e
l'OROLOGIO GRAFICA riparte, con scarto crescente a ogni rientro.
```
⇒ verbo neutro «**prosegue**», entrambi i lati nominati, nessun giudizio. **La parola
giusta era già scritta a quattro file di distanza.**

**(3) 🚨 CONTRADDIZIONE INTERNA AL COMMIT — la misura che pesa di più.**
Il blocco **RATIFICATO** `COMPORTAMENTO ATTESO`, `BOX5:204-206`, verbatim:
```
(2) NON premere STOP è una SCELTA DELL'UTENTE: significa che non vuole
    fermare l'audio, per i più disparati motivi. Il motore infatti continua
    a suonare anche nelle videate Shows e Dettaglio;
```
⇒ **Il canone dichiara che il motore che prosegue È LA SCELTA DELL'UTENTE**, cioè
comportamento corretto. **`BOX3:13-14` descrive quella stessa continuazione come «il
motore NON SI FERMA», dentro la catena del difetto.** Lo stesso commit, quindi, ratifica
un comportamento come voluto e lo imputa come mancanza in un altro file.

**(4) Non è coperta da nessuna esclusione.** BOX3 non ha blocchi esclusi; la frase è
**descrittiva** (la riga successiva, `:15`, porta la forma simmetrica sanzionata), quindi
la deroga asimmetrica di riparazione non la tocca.

⛔ **NON corretta**, come prescritto («elenca, NON correggere»).
**[A] Forma conforme proposta**, presa in prestito dalla SCALETTA dello stesso commit:
```
  a comando. Uscendo dal player senza STOP l'OROLOGIO MOTORE AUDIO prosegue; al
  rientro l'avvio lo trova acceso e il contatore non viene azzerato.
```

### ⚠️ [A] UN SECONDO ITEM, al limite — `BUGS_QBEATS.md:226`

«l'accento si sente sul secondo, terzo o quarto movimento **di quello che il display
mostra**». Usa il lemma nudo `l'accento` (che `BOX5:177` ritira) e misura l'accento
**dentro il riquadro della grafica**, che diventa così il metro implicito.
**[A] Non attribuisce colpa né sanità** — `si sente` è impersonale — ma **[A] è
un'asimmetria di INQUADRAMENTO, e punta nella direzione OPPOSTA alla REGOLA DI
RIPARAZIONE**, che fa dell'audio il riferimento. Testo che ho scritto io in A180.
Decide il referee; non corretto.

### [M] Il resto delle righe aggiunte è conforme

| dove | testo | [A] perché va bene |
|---|---|---|
| `SCALETTA:443-444` | «l'OROLOGIO MOTORE AUDIO prosegue e l'OROLOGIO GRAFICA riparte» | entrambi nominati, verbi neutri |
| `BUGS:226` (prima metà) | «Il motore prosegue sul proprio OROLOGIO MOTORE AUDIO; la grafica riparte da bar 1 e avanza sul proprio OROLOGIO GRAFICA» | simmetrica per costruzione («proprio»/«proprio») |
| `BUGS:225` | «(grafica sempre da bar 1)» | constatazione di posizione |
| `BOX5` corpo del vocabolario | definizioni dei sei nomi | definitorio |
| `BOX3:15-16` | «ACCENTO AUDIO e ACCENTO GRAFICO NON COINCIDONO … I due orologi sono partiti da punti diversi.» | forma sanzionata, riparata dal §2 |

### [A] Che cosa ho imparato dalla mia svista

⛔ **La mia sonda era giusta e la mia LETTURA no.** L'enumerazione esaustiva ha messo
`BOX3:13-14` davanti ai miei occhi — l'ho letta e l'ho classificata «meccanismo».
**Il criterio che mi mancava:** non basta chiedersi *«c'è un giudizio esplicito?»*; va
chiesto *«un lato solo è soggetto di verbi di omissione, mentre l'altro non compare?»*.
Una descrizione a una campana sola imputa senza aggettivi. **[A] Una sonda esaustiva
protegge dal non-vedere, non dal vedere-e-derubricare.**

---

## §4-bis · IL CANCELLO — l'intero commit in una lettura

**[M] Versioni: NESSUNA alzata.**

| file | versione | toccato da A182 |
|---|---|---|
| `BOX5_QBEATS.md` | **V30** | sì — §1 |
| `LIBRO_MASTRO_QBEATS.md` | **60** | sì — §3(a) |
| `BUGS_QBEATS.md` | **60** | sì — §3(b) |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | **12** | **no** — intatto |
| `BOX3_QBEATS.md` | **V100** | sì — §2 |

**[M] Byte / righe / CR — sonda a BYTE (`tr -cd '\r' | wc -c`), mai grep:**

| file | byte | righe | CR | faccia | sha256 |
|---|---|---|---|---|---|
| `BOX5_QBEATS.md` | 70582 | 822 | **0** | LF | `3c1ef04ed79dbc74b967deda442c59118d7e42568199c0b278a8db2269b717e1` |
| `LIBRO_MASTRO_QBEATS.md` | 283831 | 524 | **524** | CRLF puro | `1ac88f206b6c903b0cbc8544810ccd08f11c7e3e90edf4b8f7139a8a91c9a8cd` |
| `BUGS_QBEATS.md` | 353233 | 1213 | **1213** | CRLF puro | `4f06a6dbb6570ee7152bec64adf5f95b742ff398e40852cf95be9a70b211059e` |
| `HANDOFF/SCALETTA_…md` | 68886 | 494 | **0** | LF | `e9b23ac962ea5db8e62763bac0942d64b969f7cbb84defd055e5b2ea928ad74a` |
| `BOX3_QBEATS.md` | 91208 | 828 | **0** | LF | `03ad18e0a1081b96f8a03fc1869a1e3877bb2a16112fed38e376e33dbcba60b7` |

**[M] CR = righe** sui due CRLF · **CR = 0** sui tre LF ⇒ **nessuna faccia mista.**
**[M] SCALETTA intatta**, sha `e9b23ac9…` identico da fine A178.

**[M] Diffstat rispetto a HEAD:**
```
 BOX3_QBEATS.md                          |  27 ++++++++-
 BOX5_QBEATS.md                          | 101 +++++++++++++++++++++++++++++++-
 BUGS_QBEATS.md                          |   5 +-
 HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md |  39 +++++++++++-
 LIBRO_MASTRO_QBEATS.md                  |   7 ++-
 5 files changed, 172 insertions(+), 7 deletions(-)
```

**[M] AUDIT DELLE DELEZIONI — le 7 righe rimosse, verbatim, una per una:**
```
BOX3 V99 — 2026-07-22 (AUTOPORTANTE) · HEAD=origin=bfa07eb (…)
**Versione:** V29 — 21/08/2026
**Versione:** 59
**Versione:** 11 (18/08/2026)  ·  **Ratificata dal referee:** …
**Versione:** 59 (21/08/2026)
**Ultima modifica:** 2026-08-21 (v59 — …)
**Edit author:** CC — mandato A162, 21/08/2026
```
⇒ **[M] TUTTE e SOLE righe di intestazione.** Nessun ticket, nessuna riga di tabella,
nessuna marcatura, nessun paragrafo preesistente è stato rimosso o riscritto.

**[M] Stato del repo:**
```
 M BOX3_QBEATS.md · M BOX5_QBEATS.md · M BUGS_QBEATS.md
 M HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md · M LIBRO_MASTRO_QBEATS.md
stage=0 · ios_app=0 righe · HEAD = 4629ee9ec943a1ebb8a16a49164aa457a8b99514 (invariato)
```

⛔ **NESSUN COMMIT. NESSUN `git add`. NESSUN PUSH.**

---

## Cose che segnalo e NON ho corretto

1. **🚨 «quattro punti di produzione» → sono TRE** (riquadro in testa). **Errore mio,
   propagato dal referto A181.** Correzione proposta lì.
2. ⚠️ **«la falsificazione è di CC (mandato A182)» → è di A181.** Testo del referee.
3. **🚨 `BOX3:13-14` — violazione del vocabolario e CONTRADDIZIONE INTERNA al commit**
   (§4). Descrive come mancanza («il motore non si ferma») ciò che `BOX5:204-206`, nello
   stesso commit, ratifica come scelta voluta dell'utente. Forma conforme proposta nel §4.
4. ⚠️ **`BUGS:226`** — asimmetria d'inquadramento, al limite. Testo mio di A180.

## Cosa NON ho fatto

⛔ Nessun file sotto `ios_app/` toccato · nessun commit · nessun `git add` · nessun push ·
SCALETTA non toccata (sha provato) · nessuna versione alzata · **la precisazione NON
riscritta oltre il testo dato** · nessun reperto della spazzata corretto · non ho letto il
congedo del referee.

---

### Controllo d'integrità di QUESTO file — sul CONTENUTO

**Prima riga attesa:**
`# MISURE CC — A182 · RETTIFICA DELLA PRECISAZIONE TECNICA`

**Stringhe obbligatorie — se una manca, il file è arrivato mutilato:**
`UN NUMERO SBAGLIATO NELLA RETTIFICA — ed è MIO` · `DENTRO #if QB_DIAG_SPY (830-845)` ·
`I due orologi sono partiti da punti diversi.` · `ENUMERAZIONE ESAUSTIVA + LETTURA` ·
`163 righe aggiunte` · `TRE livelli di propagazione` · `CONTRADDIZIONE INTERNA AL COMMIT` ·
`03ad18e0a1081b96f8a03fc1869a1e3877bb2a16112fed38e376e33dbcba60b7` ·
e il marcatore di fine qui sotto.

⚠️ **Contate le stringhe, non i titoli.**

---

*A182-FINE — MISURE CC 22/08/2026 COMPLETO*
