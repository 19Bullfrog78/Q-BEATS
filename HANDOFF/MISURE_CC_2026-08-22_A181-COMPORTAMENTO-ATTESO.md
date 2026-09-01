# MISURE CC — A181 · COMPORTAMENTO ATTESO E ULTIMA CONFORMITÀ

Da: CC · A: **referee** (+ Mauro)
Mandato: `A181-COMPORTAMENTO-ATTESO-E-ULTIMA-CONFORMITA` · **SCRITTURA, NESSUN COMMIT**
Completezza: **5 sezioni (§0→§4), ultima riga `A181-FINE-MANDATO` — integro.**
**[M] Modello: intestazione Opus 5, interfaccia Opus 5 — coincidono.**

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato, non rimisurato ·
**[A]** giudizio mio.
⛔ **Zero tocchi a `ios_app/`. Nessun commit, nessun `git add`, nessun push.**

---

# 🚨 CANCELLO ROSSO — IL COMMIT NON DEVE PARTIRE COM'È

**Ho eseguito tutte e quattro le modifiche del mandato. Due cose che ho trovato dopo
rendono il commit, così com'è, dannoso. Nessuna delle due l'ho corretta di mia
iniziativa: una è testo ratificato del referee, l'altra me la vieta il mandato.**

| # | cosa | gravità |
|---|---|---|
| **①** | **La «PRECISAZIONE TECNICA» del §2 è FALSA su due affermazioni su tre**, ed è quella che DIRIGE LA RIPARAZIONE. Sta per entrare in un canonico attribuita alle mie misure A172/A173, che **non dicono quello**. | 🚨 blocca |
| **②** | **`BOX3_QBEATS.md:16` viola il vocabolario dello stesso commit**, e annulla in fondo alla frase la correzione che il §1 ha appena fatto all'inizio. | 🚨 blocca |

Dettaglio misurato nelle sezioni ①/② più sotto. **Basta una parola su ciascuna e chiudo.**

---

## §0 · ID `A181` — LIBERO

**[M] Per NOME (potata):** 0 su repo, 0 su E:. Trappola ① **non morde** (0 anche non
potata). Controllo positivo forma identica (`A180`): 1 per gamba.

**[M] Per CONTENUTO:** 0 su repo, 7 su E:, classificati uno per uno — **nessun uso come
mandato**: 6 file `LOG/RUN/…/td17_*.log` (classe ②: `uuid=A1810`, `A181AD4D8A26`) + 1
`DA_CD_PER_CC/…/Q-BEATS Vista LIVE v2 (standalone).html` (classe ③, base64).
**[M] Classe ④ assente su questo ID.**

**[M] Controllo positivo `A180`:** 5 su repo / 10 su E:. **Negativo tarato:** 0.

---

## §1 · BOX3 — l'ultima frase con un colpevole *(eseguito)*

**[M] Faccia:** LF, invariata (0 CR). **[M] Versione:** resta **V100**.

PRIMA:
```
  ⇒ l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO, e lo scarto CRESCE a ogni
```
DOPO:
```
  ⇒ ACCENTO AUDIO e ACCENTO GRAFICO NON COINCIDONO, e lo scarto CRESCE a ogni
```
**[M]** La vecchia forma rende **0** occorrenze in BOX3. **[M] Nient'altro toccato in BOX3.**

---

## §2 · BOX5 — COMPORTAMENTO ATTESO *(eseguito verbatim, ma vedi ①)*

**[M] Faccia:** LF, invariata. **[M] Versione:** resta **V30**.

⚠️ **[M] Un'ancora si è rivelata AMBIGUA e l'asserzione l'ha fermata.** Il testo di coda
del capitolo (`AUDIO/GRAFICO (erano «cambio suonato»…)`) compare **due volte** nel file:
nel capitolo **e** nella riga di Delta V30 in testa. Il primo tentativo è abortito con
`count=2`, senza scrivere. Ho usato un'ancora a **due righe**, unica al capitolo, e
verificato l'inserimento. ⇒ Nessun rischio corso, ma è il tipo di collisione che una
sostituzione senza guardia avrebbe risolto **nel posto sbagliato**.

Inserito in coda al capitolo, fra il paragrafo che finisce «non italiano).» e il `---`
che precede `## Vista LIVE`, **parola per parola dal mandato**:

```
COMPORTAMENTO ATTESO AL RIENTRO NEL PLAYER — ratificato Mauro 22/08/2026.

Ragionamento di Mauro, nelle sue parole:
(1) premendo STOP prima di uscire, al rientro grafica e audio ripartono
    correttamente;
(2) NON premere STOP è una SCELTA DELL'UTENTE: significa che non vuole
    fermare l'audio, per i più disparati motivi. Il motore infatti continua
    a suonare anche nelle videate Shows e Dettaglio;
(3) ⇒ al rientro nel player, poiché l'utente ha scelto di non fermare la
    canzone, la grafica NON deve ripartire da zero: deve RECUPERARE LA
    POSIZIONE DELL'AUDIO E ALLINEARSI AD ESSO. Ripartire da zero è il
    difetto.

⇒ QUESTO È IL REQUISITO. Non è una preferenza estetica: la grafica che
riparte da zero sta ignorando una scelta esplicita dell'utente.

⚠️ PRECISAZIONE TECNICA DEL REFEREE, misurata (A172/A173): oggi la grafica
non «rifiuta» di allinearsi — NON HA MODO DI CHIEDERE. Il motore calcola la
propria posizione dentro la battuta, la usa per suonare l'accento, e la
scarta senza consegnarla a nessuno. ⇒ Il difetto è UNA CAPACITÀ CHE MANCA,
non una scelta sbagliata del codice. Conta al momento di riparare: non c'è
una riga da correggere, c'è un'informazione da consegnare.

⛔ Questo comportamento atteso NON contraddice la simmetria della
descrizione: descrivere il sintomo resta senza colpevole (i due orologi
partono da punti diversi); il comportamento atteso e la riparazione sono
asimmetrici, e puntano entrambi nella stessa direzione — è la grafica che
si riallinea, il motore audio non si tocca.
```

**[A] Il ragionamento (1)(2)(3) di Mauro non lo giudico:** è dato come sua ratifica e la
clausola di taglio è già scritta nel mandato. **[A] Il requisito che ne discende è
coerente con quanto ho misurato** e non lo contesto.

---

# ① 🚨 LA PRECISAZIONE TECNICA È FALSA — misurata da me, non riportata

**[M] Ho rimisurato ogni parte della frase contro il codice a `4629ee9`. Due su tre non
reggono.**

### ✅ Regge: «Il motore calcola la propria posizione dentro la battuta»
`core_engine/MetronomeDSP.cpp` mantiene `_currentBeatInBar`, incrementato mod bpb.

### ✅ Regge: «la usa per suonare l'accento»
`core_engine/MetronomeDSP.cpp:455` verbatim:
```cpp
                ev.accent = (_accentPattern[_currentBeatInBar] > 0);
```

### ❌ FALSO: «e la scarta senza consegnarla a nessuno»

**[M] Tre vie di consegna, tutte misurate:**

**(a) Il DSP la espone con un accessore PUBBLICO.** `core_engine/MetronomeDSP.h:127`:
```cpp
    uint32_t getCurrentBeatInBar() const { return _currentBeatInBar; }
```

**(b) Il bridge la EMETTE, e in modo INCONDIZIONATO.** Tre chiamate in
`ios_app/QBeats/MetronomeDSPBridge.mm` — `:44`, `:55`, `:129` — dentro altrettanti
`os_log`. **[M] Il file non contiene NESSUN `#if`/`#ifdef`**: sonda
`grep -cE '^\s*#\s*(if|ifdef|ifndef)'` rende **0** ⇒ **girano anche in produzione.**
Esempio `:40-44`:
```objc
    os_log(OS_LOG_DEFAULT,
           "[METRO] setBeatPosition: beat=%.6f startAbs=%.6f beatInBar=%u",
           beatPosition,
           _dsp->getStartAbsoluteBeat(),
           _dsp->getCurrentBeatInBar());
```

**(c) Il flag DERIVATO da essa attraversa il confine C ed è già letto da Swift.**
`MetronomeDSPBridge.mm:98` `accents[count] = ev.accent ? 1 : 0;` → out-parameter di
`metronome_processBuffer` (`MetronomeDSPBridge.h:58-63`) → `AudioEngine.swift:2369`
`let isAccent = accents[i] != 0`.

### ❌ FALSO: «NON HA MODO DI CHIEDERE»

**[M] Un modo di chiedere la posizione dentro la battuta ESISTE, ed è già in uso in
produzione.** `ios_app/QBeats/MIDIEngineBridge.h:153-161` verbatim:
```c
typedef struct {
    bool   isPlaying;     // ABLLinkIsPlaying(state)
    double phaseAtHost;   // ABLLinkPhaseAtTime(state, hostTime, quantum), in [0, quantum)
    double tempo;         // ABLLinkGetTempo(state), BPM corrente sessione
} LinkSessionProbe;

LinkSessionProbe link_engine_probe_session(LinkEngineHandle handle,
                                           uint64_t hostTime,
                                           double   quantum);
```
`phaseAtHost` **è** la posizione dentro la battuta (il quantum è il numero di beat per
battuta, dichiarato a `:152`). **[M] Chiamata quattro volte in produzione:**
`AudioEngine.swift:675`, `:739`, `:839`, `:967`.

### ⚠️ E la fonte citata non dice quello

**[M] A173 era NARROW e corretto.** Verbatim, `HANDOFF/MISURE_CC_2026-08-22_A173-…md:395`:
> «**[M] I flag per-beat esistono ma muoiono dentro il motore.**»

e `:390`, sul solo header del bridge del metronomo:
> «**non contiene alcuna funzione che la restituisca**»

⇒ **[A] A173 diceva: `MetronomeDSPBridge.h` non la esporta, e AudioEngine non ripubblica
i flag. Vero. La §2 lo generalizza in «nessuno» e «non ha modo di chiedere» — e questo è
falso**, perché esistono l'accessore C++, i tre log incondizionati e la probe Link.

### 🚨 Perché blocca, e non è pedanteria

La frase non finisce lì. Prosegue: «⇒ **Il difetto è UNA CAPACITÀ CHE MANCA**, non una
scelta sbagliata del codice. Conta al momento di riparare: **non c'è una riga da
correggere, c'è un'informazione da consegnare.**»

⛔ **[A] Quella conclusione DIRIGE LA RIPARAZIONE, e poggia su una premessa falsa.**
Se la capacità c'è già — e c'è — allora la riparazione è di natura diversa e più
economica di come la riga la dipinge, e chi la leggerà domani partirà dalla strada
sbagliata. **Con la mia firma sopra**, perché è attribuita ad A172/A173.

**[A] Testo che proporrei, se il referee lo ratifica:**
```
⚠️ PRECISAZIONE TECNICA DEL REFEREE, misurata (A172/A173/A181): oggi la
grafica non «rifiuta» di allinearsi — NESSUNO GLIELA CONSEGNA. Il motore
calcola la propria posizione dentro la battuta e la usa per suonare
l'accento; il DSP la espone (`MetronomeDSP.h:127`) e la logga
(`MetronomeDSPBridge.mm:44/55/129`, incondizionati), ma il tick pubblicato
alla grafica è un intero nudo e non la porta. Esiste già anche una seconda
via mai usata a questo scopo: `link_engine_probe_session` restituisce
`phaseAtHost`, la fase dentro la battuta (`MIDIEngineBridge.h:155`), ed è
chiamata in quattro punti di produzione. ⇒ Il difetto è UN'INFORMAZIONE CHE
NON VIENE CONSEGNATA, non una capacità che manca: al momento di riparare,
il pezzo esiste già e va instradato.
```
⛔ **Non l'ho scritto io nel canonico:** è testo del referee, e la riscrittura è sua.

---

# ② 🚨 `BOX3:16` VIOLA IL VOCABOLARIO DELLO STESSO COMMIT

**[M]** La frase riparata dal §1 **continua sulla riga successiva**, e la seconda metà
disfa la prima. `BOX3_QBEATS.md:15-16` come sta ORA:

```
  ⇒ ACCENTO AUDIO e ACCENTO GRAFICO NON COINCIDONO, e lo scarto CRESCE a ogni
  uscita-rientro. L'audio è sano: è la grafica ad aver perso il riferimento.
```

**[M] La riga 16 è AGGIUNTA da questo commit** (`git diff -- BOX3_QBEATS.md` la mostra
come `+`), quindi non è storia da marcare: è testo nuovo.

⛔ **[A] «L'audio è sano: è la grafica ad aver perso il riferimento» ha un soggetto e
assegna una colpa.** Dichiara un orologio sano e l'altro in difetto — esattamente ciò che
BOX5:172-174 vieta nello stesso commit («nessuno dei due orologi sbaglia … una frase con
un soggetto attribuisce comunque la colpa a uno dei due»).
⛔ **Non è coperta dalla deroga di riparazione** (BOX5:186-192): quella è asimmetrica per
la *riparazione*; questa è una frase **descrittiva** del sintomo, e la descrizione resta
simmetrica per regola esplicita («descrivere il sintomo resta senza colpevole»).
⚠️ **Aggravante di posizione:** sta **quattro righe sopra** `BOX3:20`
«VOCABOLARIO OBBLIGATORIO: BOX5 V30, cap. «VOCABOLARIO DEI DUE OROLOGI».» — il blocco che
si vincola alla regola la viola.

**[M] Non corretta:** il §1 dice «⛔ Nient'altro in BOX3».
**[A] Forma conforme proposta:** `uscita-rientro. I due orologi sono partiti da punti diversi.`

---

## §3 · PATERNITÀ *(eseguito)*

**[M] Faccia LIBRO:** CRLF, CR = righe = 524. **[M] Faccia BUGS:** CRLF, CR = righe = 1213.
**[M] Versioni:** LIBRO resta **60**, BUGS resta **60**.

**(a) LIBRO** — PRIMA: `**Edit author:** CC — mandati A176 + A178 + A180, 22/08/2026`
DOPO: `**Edit author:** CC — mandati A176 + A178 + A180 + A181, 22/08/2026`

**(b) BUGS changelog 60** — PRIMA: `zero codice (mandati A176 + A178 + A180).**`
DOPO: `zero codice (mandati A176 + A178 + A180 + A181).**`

**[M] `A179` rende 0 occorrenze in tutti e cinque i file** — l'annullamento regge.

---

## §4 · SPAZZATA RIPETUTA — l'esito richiesto è RAGGIUNTO, con una riserva

**[M] Sonde identiche a quelle di A180 §3(c).**
**[M] Controllo positivo forma identica:** `NON COINCIDONO` rende 2/0/2/0/**1** (BOX3 è
salito a 1 = la riparazione del §1 è atterrata); `ACCENTO AUDIO` rende 5/1/3/0/1.
⇒ **le sonde vedono, gli zeri non sono ciechi.**

**[M] Forme con SOGGETTO fra i nomi del vocabolario — solo DUE hit, entrambe legittime:**
`BOX5:175` e `BOX5:176`, che sono le forme vietate **citate dentro il divieto stesso**.
⇒ **✅ ZERO forme-con-soggetto fuori dalle citazioni-di-divieto, come il §4 richiede.**

⚠️ **RISERVA — la sonda del §4 non copre il reperto ②.** `BOX3:16` («L'audio è sano: è la
grafica…») **non nomina** ACCENTO/CAMBIO SEZIONE/OROLOGIO, quindi **passa sotto la sonda
prescritta**. È una forma con colpevole scritta con parole comuni. **[A] La sonda del §4
misura il lessico, non la grammatica: il suo zero è vero e insufficiente.**

**[M] Altri due hit su «sbagliat*», entrambi già elencati in A180 e invariati:**
`BUGS:178` («si suona la sezione sbagliata davanti alla band» — [A] parla della band, non
dei due orologi) e `BUGS:931` (ticket **CHIUSO** il 31/05/2026, altro difetto).

⚠️ **Un terzo reperto, [A] plausibile, che segnalo perché nasce da testo che ho scritto
io in A180:** `BUGS:226` — «l'accento si sente sul secondo, terzo o quarto movimento **di
quello che il display mostra**». Usa il lemma nudo `l'accento` (che BOX5:177 ritira) e lo
colloca rispetto all'altro orologio. **[A] Difendibile** — `si sente` è impersonale, non
c'è un agente — **ma BOX5:174 vieta la presenza di un soggetto, non solo di un agente.**
Decide il referee; non l'ho toccato.

---

## §4-bis · IL CANCELLO — l'intero commit in una lettura

**[M] Versioni: NESSUNA alzata, come prescritto.**

| file | versione | toccato da A181 |
|---|---|---|
| `BOX5_QBEATS.md` | **V30** | sì — §2 |
| `LIBRO_MASTRO_QBEATS.md` | **60** | sì — §3(a) |
| `BUGS_QBEATS.md` | **60** | sì — §3(b) |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | **12** | **no** — intatto, sha `e9b23ac9…` |
| `BOX3_QBEATS.md` | **V100** | sì — §1 |

**[M] Byte / righe / CR — sonda a BYTE (`tr -cd '\r' | wc -c`), mai grep:**

| file | byte | righe | CR | faccia | sha256 |
|---|---|---|---|---|---|
| `BOX5_QBEATS.md` | 69886 | 808 | **0** | LF | `507e4406e28572e838b481e1ebdef9371006aed25376b13d315e16804c412218` |
| `LIBRO_MASTRO_QBEATS.md` | 283824 | 524 | **524** | CRLF puro | `8574dc79a860d387a79f0daa4b38dbf60883cee7b6b9493d6b0eca075afee896` |
| `BUGS_QBEATS.md` | 353226 | 1213 | **1213** | CRLF puro | `f40bb66a8e8bd520be29b77b73307258058fc9f1176aff9ccd3d693231943565` |
| `HANDOFF/SCALETTA_…md` | 68886 | 494 | **0** | LF | `e9b23ac962ea5db8e62763bac0942d64b969f7cbb84defd055e5b2ea928ad74a` |
| `BOX3_QBEATS.md` | 91224 | 828 | **0** | LF | `9a35b991eb82902992d4d90b02e8b3684efcffcb7784c4d92f5407f10ae94437` |

**[M] CR = righe** sui due CRLF ⇒ nessuna riga LF-nuda. **CR = 0** sui tre LF ⇒ nessun CR
intruso. Nessuna faccia mista.

**[M] Diffstat rispetto a HEAD — l'intero commit:**
```
 BOX3_QBEATS.md                          | 27 +++++++++-
 BOX5_QBEATS.md                          | 87 ++++++++++++++++++++++++++++++++-
 BUGS_QBEATS.md                          |  5 +-
 HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md | 39 ++++++++++++++-
 LIBRO_MASTRO_QBEATS.md                  |  7 +--
 5 files changed, 158 insertions(+), 7 deletions(-)
```

**[M] Le 7 delezioni sono TUTTE e SOLE righe di intestazione**, verificate una per una:
BOX5 `Versione V29` · BUGS `Versione 59` · LIBRO `Versione 59` + `Ultima modifica` +
`Edit author` · SCALETTA `Versione 11` · BOX3 riga 1 `V99`.
⇒ **[M] Nessun ticket, nessuna riga di tabella, nessuna marcatura preesistente è stata
rimossa o riscritta in nessuno dei cinque file.**

**[M] Stato del repo:**
```
 M BOX3_QBEATS.md · M BOX5_QBEATS.md · M BUGS_QBEATS.md
 M HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md · M LIBRO_MASTRO_QBEATS.md
stage=0 · ios_app=0 righe · HEAD = 4629ee9ec943a1ebb8a16a49164aa457a8b99514 (invariato)
```

⛔ **NESSUN COMMIT. NESSUN `git add`. NESSUN PUSH.**

---

## Come ho verificato, e un errore mio

**[A]** Dopo aver eseguito le quattro modifiche ho fatto girare **sei revisori
indipendenti in sola lettura**, ognuno istruito a **refutare** un grappolo: delezioni
inattese · conformità al vocabolario · facce e impronte · versioni e paternità · i
quattro bersagli di A181 · **la veridicità della precisazione tecnica contro il codice**.
36 claim controllati. **Tutto ciò che hanno refutato l'ho poi rimisurato di persona**, e
in questo referto compare solo ciò che ho verificato io: i comandi e gli esiti sono i
miei, non i loro.

⚠️ **Un errore mio, nel modo in cui ho scritto la verifica.** Nell'elenco delle delezioni
attese che ho dato ai revisori avevo messo due voci fantasma (un «blocco di 6 righe» in
BOX5 e una «frase ACCENTO» in BUGS) che **non sono mai state cancellate da nessuno**: la
somma della mia lista faceva 14 contro le 7 reali. I revisori l'hanno colto e hanno
verificato il numero giusto. **Non ha toccato il commit** — è sloppiness nella stesura del
controllo, non nel lavoro controllato — ma un elenco di attese sbagliato può far passare
per «atteso» un guasto vero, ed è la stessa forma di errore che questo referto contesta al
§2.

---

## Cosa NON ho fatto

⛔ Nessun file sotto `ios_app/` toccato · nessun commit · nessun `git add` · nessun push ·
SCALETTA non toccata (sha provato identico) · nessuna versione alzata · **la precisazione
tecnica del §2 NON riscritta** (testo del referee) · **`BOX3:16` NON corretta** (vietato
dal §1) · i reperti della spazzata non corretti · non ho letto il congedo del referee.

---

### Controllo d'integrità di QUESTO file — sul CONTENUTO

**Prima riga attesa:**
`# MISURE CC — A181 · COMPORTAMENTO ATTESO E ULTIMA CONFORMITÀ`

**Stringhe obbligatorie — se una manca, il file è arrivato mutilato:**
`IL COMMIT NON DEVE PARTIRE COM'È` · `getCurrentBeatInBar() const` ·
`ABLLinkPhaseAtTime(state, hostTime, quantum), in [0, quantum)` ·
`L'audio è sano: è la grafica ad aver perso il riferimento` ·
`misura il lessico, non la grammatica` ·
`9a35b991eb82902992d4d90b02e8b3684efcffcb7784c4d92f5407f10ae94437` ·
`due voci fantasma` · e il marcatore di fine qui sotto.

⚠️ **Contate le stringhe, non i titoli.**

---

*A181-FINE — MISURE CC 22/08/2026 COMPLETO*
