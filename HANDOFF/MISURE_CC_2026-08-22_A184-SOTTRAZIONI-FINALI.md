# MISURE CC — A184 · SOTTRAZIONI FINALI

Da: CC · A: **referee** (+ Mauro)
Mandato: `A184-SOTTRAZIONI-FINALI` · **SCRITTURA, NESSUN COMMIT**
Completezza: **4 sezioni (§0→§3), ultima riga `A184-FINE-MANDATO` — integro.**
**[M] Modello: intestazione Opus 5, interfaccia Opus 5 — coincidono.**
A183: **annullato, mai ricevuto, mai eseguito.**

# 🚨 QUATTRO NUMERI SBAGLIATI CHE IL MIO PRIMO AUDIT AVEVA MANCATO

⚠️ **CORREZIONE DEL MIO §3(a).** La prima stesura di questo referto classificava i numeri
delle righe aggiunte e concludeva che i sopravvissuti erano «tutti sani». **Era una
conclusione sbagliata: il mio audit era incompleto.** Una corroborazione indipendente a
tre lenti ne ha trovati **quattro** che io non avevo classificato. **Li ho rimisurati tutti
e quattro di persona: reggono tutti e quattro.** Dettaglio in §3(a-bis).

| # | dove | dice | è | gravità |
|---|---|---|---|---|
| ① | `BOX3:8` | «**DUE** TICKET 🚨 BLOCCANTE PALCO, entrambi APERTI» | **cinque** | 🚨 censimento falso in un blocco «STATO VIVO» |
| ② | `BOX3:23-25` | i pulsanti morti del transport «prev sez, next sez, loop, **restart**» sono «PALETTI DI MEMORIA VOLUTI, non un difetto» | «restart» **non è nel transport**; è il bottone di END SHOW, governato da un ticket bloccante la cui gravità **l'ha decisa Mauro**. E la lista **omette «emerg»** | 🚨 ratificherebbe come voluto un difetto già ratificato |
| ③ | `BOX5:8` · `BOX5:194` · `LIBRO` Sez.2 | «**Tre** erano stati proposti diversamente» | **cinque su sei** cambiati; la lista ne nomina **quattro** | ⚠️ in **tre siti** |
| ④ | `SCALETTA` (marcatura 22/08) | «freeze grafico **rev3**» | rev4, rev5 e rev6 esistono e sono tracciati; i nomi-file dicono `SUPERSEDE-rev3` | ⚠️ puntatore a un artefatto superato |

⛔ **Nessuno dei quattro corretto:** BOX3 e SCALETTA sono intoccabili per questo mandato, e
il §1 limita BOX5 a tre sottrazioni («Nient'altro in BOX5»). **Sono elencati, come prescritto.**

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato, non rimisurato ·
**[A]** giudizio mio.
⛔ **Zero tocchi a `ios_app/`. Nessun commit, nessun `git add`, nessun push.**

⚠️ **Sul vincolo «questo mandato non aggiunge nulla»:** il §2 introduce `+ A184` nelle due
righe di paternità. **[A] È bookkeeping prescritto dal mandato stesso, non contenuto
nuovo** — non lo tratto come difetto. Tutto il resto del mandato è sottrattivo.

---

## §0 · ID `A184` — LIBERO

**[M] Per NOME (potata):** 0 su repo, 0 su E:. Trappola ① **morde** (1 hit non potato in
`.git/objects`). Controllo positivo forma identica (`A182`): 1 per gamba.

**[M] Per CONTENUTO:** **0 su repo**, 9 su E: — **tutti classe ②** (log di device:
`uuid: 193A184E-D459-4EB`, `3A8A046E-A184-4D7F-8C55`, …), zero riferimenti a mandato.
⚠️ **[M] Classe ④ assente su questo ID** — a differenza di A178/A180/A182, `A184` non era
stato tabulato come controllo negativo in nessun referto precedente.

**[M] Controllo positivo `A182`:** 7 su repo / 13 su E:. **Negativo tarato:** 0.

---

## §0-bis · Stato dei bersagli — tutti combaciavano

| § | bersaglio | trovato | ✓ |
|---|---|---|---|
| §1(a) | punto elenco «posizione di fase di Link» | presente, `BOX5:225-226` | ✅ |
| §1(b) | «lo legge in TRE punti che girano in produzione» | presente, 1 occorrenza | ✅ |
| §1(c) | «la falsificazione è di CC (mandato A182)» | presente, 1 occorrenza | ✅ |
| §2(a) | LIBRO `… + A181 + A182, 22/08/2026` | presente | ✅ |
| §2(b) | BUGS `(mandati A176 + A178 + A180 + A181 + A182)` | presente | ✅ |

### ✅ [M] Ho verificato il MOTIVO del §1(a) prima di eseguirlo

Il mandato giustifica la rimozione dicendo che le chiamate esistono solo con Link attivo.
**[M] Regge, misurato a `4629ee9`:**

| chiamata | cancello che la governa |
|---|---|
| `AudioEngine.swift:675` | `:663` `guard let lh = self.linkEngineHandle else { return }` |
| `AudioEngine.swift:739` | `:726` `let lhCaptured = self.linkEngineHandle` + `:738` `if let lhNow = lhCaptured` |
| `AudioEngine.swift:967` | `if let lh = self.linkEngineHandle` |

⇒ **[M] Tutte e tre esistono solo con un handle Link.** Il difetto capita anche senza Link
⇒ **[A] il punto elenco indicava, in un elenco che conclude «il canale esiste già», una
strada che nel caso comune non c'è. La rimozione è corretta.**

---

## §1 · BOX5 — tre sottrazioni e una correzione *(eseguito)*

**[M] Faccia:** LF, invariata (0 CR). **[M] Versione:** resta **V30**.
**[M] Righe del file: 822 → 819 (delta −3, atteso −3).**

### (a) ELIMINATO il punto elenco sulla fase di Link

RIMOSSO per intero (due righe fisiche):
```
· la posizione di fase di Link è dichiarata e GIÀ USATA in quattro punti
  di produzione.
```
**[M] Residuo `posizione di fase di Link` in BOX5: 0.**

### (b) TOLTO il numero dal punto sul ponte, parentesi conservata

PRIMA (due righe):
```
· il ponte lo legge in TRE punti che girano in produzione (zero compilazione
  condizionale nel file);
```
DOPO (una riga, 77 caratteri — larghezza coerente col blocco, che va da 70 a 78):
```
· il ponte lo legge in produzione (zero compilazione condizionale nel file);
```
**[M] Residuo `TRE punti`: 0.** **[M] La parentesi c'è**, ed è lei a reggere
l'affermazione: misurata, `MetronomeDSPBridge.mm` ha **zero** `#if/#ifdef/#ifndef`.

### (c) CORRETTA l'attribuzione

PRIMA: `modo di chiedere». ERA FALSA, e la falsificazione è di CC (mandato A182),`
DOPO: `modo di chiedere». ERA FALSA, e la falsificazione è di CC (referto A181),`

### [M] Il blocco risultante, verbatim

```
⚠️ PRECISAZIONE TECNICA DEL REFEREE — RETTIFICATA 22/08/2026, misurata a
`4629ee9`. Una versione precedente di questa riga diceva che il motore
«scarta la posizione senza consegnarla a nessuno» e che la grafica «non ha
modo di chiedere». ERA FALSA, e la falsificazione è di CC (referto A181),
rimisurata dal referee. In realtà:
· il DSP C++ espone un accessore PUBBLICO della posizione dentro la battuta;
· il ponte lo legge in produzione (zero compilazione condizionale nel file);
· il flag di accento per-battito ATTRAVERSA GIÀ il confine C→Swift e viene
  letto dentro AudioEngine;

⇒ CIÒ CHE MANCA È UN SOLO PASSAGGIO, L'ULTIMO: AudioEngine non ripubblica
quell'informazione alla vista — il messaggio che raggiunge la grafica a
ogni battito porta SOLTANTO il numero progressivo del battito.

⛔ CHI RIPARERÀ NON DEVE COSTRUIRE UN CANALE NUOVO: il canale esiste e
arriva già fino a Swift. Va esteso l'ultimo tratto. ⛔ E non deve toccare
il motore audio: vedi la REGOLA DI RIPARAZIONE sopra.
```
**[M] Controprove d'integrità superate:** i tre punti elenco rimasti presenti 1/1/1, la
conclusione `⇒ CIÒ CHE MANCA` e il divieto `⛔ CHI RIPARERÀ` presenti 1/1, nessun CRLF
introdotto.

---

## §2 · PATERNITÀ *(eseguito)*

**[M] Facce invariate:** LIBRO CR = righe = 524 · BUGS CR = righe = 1213.

**(a) LIBRO** — PRIMA: `**Edit author:** CC — mandati A176 + A178 + A180 + A181 + A182, 22/08/2026`
DOPO: `**Edit author:** CC — mandati A176 + A178 + A180 + A181 + A182 + A184, 22/08/2026`

**(b) BUGS changelog 60** — PRIMA: `zero codice (mandati A176 + A178 + A180 + A181 + A182).**`
DOPO: `zero codice (mandati A176 + A178 + A180 + A181 + A182 + A184).**`

**[M] A183 e A179 non compaiono in nessuna delle due righe** — verificato: `A179` e `A183`
rendono **0** occorrenze su tutti e cinque i file.

---

## §3 · L'AUDIT — grammatica, numeri, condizioni

**[M] Sonda: enumerazione esaustiva, non un pattern.** `git diff | grep '^+'` → **169
righe aggiunte**, lette tutte. `grep` usato per localizzare, mai per concludere.

### (c) GRAMMATICA — una violazione, invariata da A182

**[M] `BOX3_QBEATS.md:13-14` è ancora lì**, perché il §1 di questo mandato vieta di toccare
BOX3. Verbatim:
```
  a comando. Uscendo dal player senza STOP il motore non si ferma; al rientro
  l'avvio lo trova acceso, esce in silenzio e non azzera il contatore.
```
⛔ Resoconto **a una campana sola**: tutti i soggetti sul lato audio (`il motore`,
`l'avvio`), tutti con verbi di omissione; il lato grafica **non compare** (0 occorrenze
nelle due righe). Contraddice `BOX5:204-206`, ratificato, che dichiara la continuazione
del motore **scelta voluta dell'utente**. **Analisi completa nel referto A182 §4** —
qui la riporto per continuità, non la ri-argomento.

### 🚨 (b) CONDIZIONI NASCOSTE — ne ho trovata UNA, ed è mia

**[M] `BUGS_QBEATS.md:226`**, verbatim:
> «l'accento si sente sul **secondo, terzo o quarto** movimento di quello che il display
> mostra, e circa **una volta su quattro** i due coincidono per caso»

⛔ **Entrambi i numeri valgono SOLO in 4/4, e la condizione non è scritta.**

**[M] Misure che lo dimostrano:**
- `AudioEngine.swift:57` — `@Published var beatsPerBar : UInt32 = 4` — **è una variabile**,
  4 è solo il valore iniziale;
- `LiveView.swift:480` — `let denom: UInt32 = (beats == 6 || beats == 12) ? 8 : 4` — la UI
  gestisce esplicitamente anche **6/8 e 12/8**;
- **[M] metri diversi da 4/4 documentati in BUGS**: `3/4` → **28** occorrenze · `5/4` → **6**
  · `7/8` → **3** · `6/8` → **1**. Non è un caso teorico: è il pane del progetto (l'intera
  storia di Bug 2.b è sui passaggi 3/4↔4/4).

⇒ **[A] In 3/4 le posizioni sono «secondo o terzo» e la coincidenza è una volta su TRE.
La frase è vera nel metro più comune e falsa negli altri, e non lo dice.** È **esattamente
la forma d'errore che questo mandato sta togliendo dalla precisazione tecnica** — solo che
qui il condizionale non è «Link attivo» ma «4 movimenti per battuta».
⛔ **Non corretta** («elenca, NON correggere»). ⚠️ **Testo che ho scritto io in A180.**
**[A] Forma che toglierebbe la condizione senza aggiungere nulla:** «l'accento si sente su
un movimento diverso dal primo di quello che il display mostra, e ogni tanto i due
coincidono per caso».

**[M] Tutte le altre affermazioni tecniche aggiunte sono INCONDIZIONATE, verificate:**

| affermazione (riga aggiunta) | verdetto | prova |
|---|---|---|
| «il DSP C++ espone un accessore PUBBLICO…» | **SEMPRE** | `MetronomeDSP.h:127`, sezione `public:` (`:30`→`:147`) |
| «il ponte lo legge in produzione (zero compilazione condizionale…)» | **SEMPRE, condizione dichiarata** | 0 `#if` in `MetronomeDSPBridge.mm` |
| «il flag di accento… ATTRAVERSA GIÀ il confine C→Swift» | **SEMPRE** | `MetronomeDSP.cpp:455` → `…Bridge.mm:98` → `AudioEngine.swift:2369` |
| «il messaggio… porta SOLTANTO il numero progressivo» | **SEMPRE** | `AudioEngine.swift:121` `PassthroughSubject<Int, Never>`; `:2374-2376` |
| SCALETTA: «l'OROLOGIO MOTORE AUDIO prosegue e l'OROLOGIO GRAFICA riparte» | **SEMPRE** | descrizione del meccanismo, nessun cancello |
| BOX3: «il motore non si ferma… non azzera il contatore» | **SEMPRE** | `guard !isRunning` `AudioEngine.swift:859` → `:874` non eseguito |

### (a) I NUMERI — enumerati tutti, classificati

**[M] Estrazione meccanica** (cifre + numerali a lettere) sulle 169 righe aggiunte, poi
lettura in contesto. Escluse date e versioni ripetute (`08`, `22`, `2026`, `07`…), che sono
marche temporali e non reggono conclusioni.

| numero | dove | verdetto |
|---|---|---|
| **«una volta su quattro»** · **«secondo, terzo o quarto»** | `BUGS:226` | 🚨 **PORTANTE e CONDIZIONATO-NASCOSTO** (sopra) |
| «Tutti e **sei** i nomi sono ratificati» (3 siti: BOX5 Delta, BOX5 capitolo, LIBRO) | BOX5/LIBRO | **PORTANTE** — regge il passaggio da «solo due ratificati» a «tutti». **[M] Verificato: i nomi definiti nel capitolo sono esattamente 6.** |
| «⟦S-EXIT⟧ … in **sei** punti (a)-(f)» | SCALETTA, riga versione | **PORTANTE** — **[M] verificato: la marcatura porta (a)(b)(c)(d)(e)(f) = 6.** |
| `V100`, `V30`, `60`, `12` | intestazioni | **PORTANTI come puntatori** (R7.2: «versione = puntatore») |
| `` `:211` `` | `BUGS:227` | **PORTANTE** — ⚠️ **[M] RIVERIFICATO dopo gli inserimenti: la riga 211 di BUGS contiene ancora «TRE RIGHE SONO PROVVISORIE E NON CHIUDONO», cioè la lacuna citata. Il puntatore REGGE** (i miei inserimenti sono caduti a `:216` e `:226`, entrambi dopo). |
| «Intro **100**» | `BUGS:226` | **DECORATIVO** — il testo stesso lo dichiara «un esempio osservato, non un punto di arresto» |
| «**13** atomi», «≥**320**», `29912886883` | catene di versione / intestazione BOX3 | **DECORATIVI in questo commit** — testo preesistente trasportato, non affermazioni nuove |
| «le altre **due** righe provvisorie (④, Sintomo ②)» | `BUGS:216` | **PORTANTE** — delimita cosa NON si chiude. **[M] Verificato: le righe provvisorie erano tre, una si chiude, ne restano due.** |

⚠️ **[A] La frase che avevo scritto qui — «nessun altro numero sopravvissuto è del tipo
che il mandato ha appena tolto» — È SMENTITA dalla sezione seguente.** La lascio perché
è l'errore, non la sua correzione: avevo guardato i conteggi di call-site e non i
conteggi di *censimento*.

### 🚨 (a-bis) I QUATTRO NUMERI CHE AVEVO MANCATO — rimisurati da me

#### ① `BOX3:8` — «DUE TICKET», sono CINQUE

**[M]** Sonda: intestazioni `^### ` in Sezione 1 di BUGS (righe 59-873, i bug APERTI) che
portano `🚨 BLOCCANTE PALCO` → **4**:
`TD-mixer-copre-endshow` · `TD-direttore-parte-da-bar2` ·
`TD-rientro-senza-stop-sgancia-audio-e-grafica` · `TD-fineshow-bottoni-morti`.
**[M] Più un quinto** che lo porta nel campo Stato invece che nel titolo —
`TD-qlive-exit-unconfirmed-stop`, verbatim: `- **Stato:** 🔴 OPEN ALTA / 🚨 BLOCCANTE PALCO.`
**[M] Controllo positivo forma identica:** intestazioni `###` totali in Sez.1 = **79**.
**[M] Controprova:** in Sezione 2 (CHIUSI) le stesse intestazioni rendono **0**.

⇒ **[A] Sono cinque, non due.** La riga di supersede (`BOX3:2`) dice «Registra **i due**
ticket bloccanti palco aperti» — articolo determinativo, dentro un blocco intitolato
«STATO VIVO AL 22/08/2026». **Un lettore lo prende per il censimento, e mancano tre
ticket bloccanti.**

#### ② 🚨 `BOX3:23-25` — «restart» non è un pulsante del transport, e manca «emerg»

**[M]** `TransportView.swift` a `4629ee9` — sonda `grep -c restart` → **0**. Il transport
non contiene nessun «restart». I suoi `RubberBtnView` etichettati sono:
```
:26  "prev sez"   ·  :66  "next sez"  ·  :72  loopLabel  ·  :90  "emerg"
```
(più play/stop a `:30` e KILL BASE a `:76`).

**[M] «restart» è altrove:** `FineSetlistView.swift:31`
`Button("RESTART SETLIST") { /* restart setlist — Fase successiva */ }` — la schermata
**END SHOW**, governata da `TD-fineshow-bottoni-morti`, 🔴 OPEN ALTA / 🚨 BLOCCANTE PALCO,
**gravità DECISA da Mauro il 04/08/2026**.
⇒ ⛔ **[A] La riga ratificherebbe come «voluto, non un difetto» un bottone che un ticket
ratificato dichiara difetto bloccante.** Due ratifiche di Mauro in contraddizione.

**[M] E la lista omette «emerg»**, che È un pulsante morto del transport:
`TransportView.swift:90-92`, `disabled: false`, closure vuota — con ticket proprio
`TD-emerg-bottone-morto` (`BUGS:162`, 🔴 OPEN ALTA).

⇒ **[A] Il numerale «quattro» era stato tolto altrove in questo giro, ma qui è
sopravvissuta l'enumerazione a quattro voci, ed è sbagliata in entrambe le direzioni:
una voce di troppo e una mancante.**

#### ③ `BOX5:8` · `BOX5:194` · `LIBRO` Sez.2 — «Tre», sono CINQUE (e ne nomina quattro)

**[M]** Confronto fra i sei nomi **proposti** dal referee (referto A176 agli atti) e i sei
**finali**:

| proposto (A176) | finale | |
|---|---|---|
| OROLOGIO MOTORE | OROLOGIO MOTORE **AUDIO** | CAMBIATO |
| OROLOGIO GRAFICA | OROLOGIO GRAFICA | invariato |
| ACCENTO SONORO | ACCENTO AUDIO | CAMBIATO |
| PRIMO VERDE | ACCENTO GRAFICO | CAMBIATO |
| CAMBIO SUONATO | CAMBIO SEZIONE AUDIO | CAMBIATO |
| CAMBIO SCRITTO | CAMBIO SEZIONE GRAFICO | CAMBIATO |

⇒ **[M] cinque su sei cambiati; solo `OROLOGIO GRAFICA` sopravvive verbatim.**
**[M] E la frase, che dice «Tre», ne nomina quattro**: il terzo trattino è plurale e copre
**due** nomi (`CAMBIO SEZIONE AUDIO/GRAFICO`). **[M] `OROLOGIO MOTORE → OROLOGIO MOTORE
AUDIO` non è menzionato affatto.**
**[M] Il numero è in TRE siti:** `BOX5:8` (Delta V30) · `BOX5:194` (capitolo) ·
`LIBRO_MASTRO_QBEATS.md` Sez.2.

#### ④ `SCALETTA` — «freeze grafico rev3» punta a un artefatto superato

**[M]** `DESIGN/QLive_Nav/` contiene, **tutti tracciati in git**:
```
2026-08-06_…rev2-BUONA.html
2026-08-06_…rev3-NORMATIVA.html
2026-08-20_…rev4__SUPERSEDE-rev3__…html
2026-08-20_…rev5__SUPERSEDE-rev4-TESTO__…html
2026-08-21_…NOTA-DI-CORREZIONE-rev5__…html
2026-08-21_…rev6__SUPERSEDE-rev5-SU-2-SELETTORI__…html
```
⇒ **[A] I nomi-file stessi dichiarano la catena di supersede.** «rev3» come nome del freeze
in attesa è **stale**: `LIBRO:360` nomina già «deposito freeze **rev6**».
⚠️ **[A] La seconda metà della stessa voce — «le due decisioni di Mauro in attesa» — non
l'ho potuta verificare:** non ho trovato in nessun canonico un censimento che le fissi a
due. La segnalo come **non verificata**, non come sbagliata.

---

## §3-bis · IL CANCELLO — l'intero commit in una lettura

**[M] Versioni: NESSUNA alzata.**

| file | versione | toccato da A184 |
|---|---|---|
| `BOX5_QBEATS.md` | **V30** | sì — §1 |
| `LIBRO_MASTRO_QBEATS.md` | **60** | sì — §2(a) |
| `BUGS_QBEATS.md` | **60** | sì — §2(b), sola paternità |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | **12** | **no** |
| `BOX3_QBEATS.md` | **V100** | **no** |

**[M] SCALETTA `e9b23ac9…` e BOX3 `03ad18e0…` — sha256 identici a fine A182: intatti.**

**[M] Byte / righe / CR — sonda a BYTE (`tr -cd '\r' | wc -c`):**

| file | byte | righe | CR | faccia | sha256 |
|---|---|---|---|---|---|
| `BOX5_QBEATS.md` | 70463 | 819 | **0** | LF | `ba13c0a48f04b58d9bf6c054842a29fd09a0507c9fbb342547b84145ef9715f0` |
| `LIBRO_MASTRO_QBEATS.md` | 283838 | 524 | **524** | CRLF puro | `2700d44fd55051176416913b5d69c6b2f6d57fd36995aa32c6967443ebf8af15` |
| `BUGS_QBEATS.md` | 353240 | 1213 | **1213** | CRLF puro | `8d5210397e68764289bd9490f1c9259ca303c7ee3061a8aa0be78825c53e033d` |
| `HANDOFF/SCALETTA_…md` | 68886 | 494 | **0** | LF | `e9b23ac962ea5db8e62763bac0942d64b969f7cbb84defd055e5b2ea928ad74a` |
| `BOX3_QBEATS.md` | 91208 | 828 | **0** | LF | `03ad18e0a1081b96f8a03fc1869a1e3877bb2a16112fed38e376e33dbcba60b7` |

**[M] CR = righe** sui due CRLF · **CR = 0** sui tre LF ⇒ **nessuna faccia mista.**

**[M] Diffstat rispetto a HEAD:**
```
 BOX3_QBEATS.md                          | 27 ++++++++-
 BOX5_QBEATS.md                          | 98 ++++++++++++++++++++++++++++++++-
 BUGS_QBEATS.md                          |  5 +-
 HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md | 39 ++++++++++++-
 LIBRO_MASTRO_QBEATS.md                  |  7 ++-
 5 files changed, 169 insertions(+), 7 deletions(-)
```

**[M] AUDIT DELLE DELEZIONI — le 7 righe rimosse, tutte e sole intestazioni:**
```
BOX3 V99 — 2026-07-22 (AUTOPORTANTE) · HEAD=origin=bfa07eb (…)
**Versione:** V29 — 21/08/2026
**Versione:** 59
**Versione:** 11 (18/08/2026)  ·  **Ratificata dal referee:** …
**Versione:** 59 (21/08/2026)
**Ultima modifica:** 2026-08-21 (v59 — …)
**Edit author:** CC — mandato A162, 21/08/2026
```
⇒ **[M] Nessun ticket, nessuna riga di tabella, nessuna marcatura, nessun paragrafo
preesistente rimosso o riscritto in nessuno dei cinque file.**

**[M] Stato del repo:**
```
 M BOX3 · M BOX5 · M BUGS · M HANDOFF/SCALETTA · M LIBRO
stage=0 · ios_app=0 righe · HEAD = 4629ee9ec943a1ebb8a16a49164aa457a8b99514 (invariato)
```
⛔ **NESSUN COMMIT. NESSUN `git add`. NESSUN PUSH.**

---

## Messaggio di commit proposto

```
docs: vocabolario dei due orologi, comportamento atteso e stato al 22/08

Cinque canonici, zero codice. Ratifiche di Mauro del 22/08/2026.

BOX5 V30 — capitolo NUOVO «VOCABOLARIO DEI DUE OROLOGI»: sei nomi ratificati
(OROLOGIO MOTORE AUDIO/GRAFICA · ACCENTO AUDIO/GRAFICO · CAMBIO SEZIONE
AUDIO/GRAFICO), regola delle descrizioni simmetriche senza colpevole, REGOLA
DI RIPARAZIONE (l'audio e' il riferimento e non si tocca), COMPORTAMENTO
ATTESO al rientro nel player e precisazione tecnica misurata a 4629ee9.

BOX3 V100 — blocco additivo di stato vivo in testa: i due ticket bloccanti
palco aperti, il vocabolario obbligatorio, la sede dell'ordine dei lavori,
le misure agli atti. Il corpo resta quello di V99 (2026-07-22), invariato.

SCALETTA v12 — marcatura additiva in coda a sez.C: SEXIT riformulato e
scomposto in sei punti (a)-(f). L'ordine ratificato il 31/07 e' INVARIATO.

BUGS v60 — osservazione diretta di Mauro del 22/08 sul ticket
TD-rientro-senza-stop-sgancia-audio-e-grafica; sulla riga «rientro senza
STOP» della matrice di TD-direttore-parte-da-bar2 la stessa osservazione
chiude la lacuna di conteggio, per quella riga soltanto.

LIBRO v60 — una riga in Sez.2: ratifica del vocabolario, sede unica BOX5.

Le sole righe rimosse sono sette intestazioni di versione: nessun ticket,
nessuna tabella, nessuna marcatura preesistente e' stata toccata.

Referti: HANDOFF/MISURE_CC_2026-08-22_A176 / A178 / A180 / A181 / A182 / A184.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```
⚠️ **[A] Il trailer `Co-Authored-By` va TOLTO** se vale ancora la regola di casa
«commit autore Mauro, ZERO Co-Auth» che ho agli atti. L'ho lasciato visibile perché sia
una scelta e non una dimenticanza.

---

## Cose che segnalo e NON ho corretto

1. **🚨 `BOX3:23-25` — «restart» non è del transport, e manca «emerg»** (§3 a-bis ②).
   **La più grave: ratificherebbe come voluto un difetto che un ticket ratificato da Mauro
   dichiara bloccante.**
2. **🚨 `BOX3:8` — «DUE TICKET», sono cinque** (§3 a-bis ①). Censimento falso in un blocco
   intitolato «STATO VIVO».
3. **🚨 `BUGS:226` — «una volta su quattro» / «secondo, terzo o quarto» valgono solo in
   4/4**, condizione non scritta (§3(b)). **Testo mio di A180.**
4. **🚨 `BOX3:13-14`** — violazione grammaticale e contraddizione col canone
   (§3(c), analisi in A182 §4).
5. ⚠️ **«Tre erano stati proposti diversamente» → cinque, in tre siti** (§3 a-bis ③).
6. ⚠️ **`SCALETTA` «freeze grafico rev3» → rev6** (§3 a-bis ④); «le due decisioni in
   attesa» **non verificata**.

⚠️ **[A] Cinque dei sei riguardano BOX3 e BUGS, che questo mandato mi vieta di toccare, e
il sesto sta in BOX5 fuori dalle tre sottrazioni prescritte. Non è ostruzionismo: è che
il perimetro dei mandati recenti è più stretto dei difetti che l'audit trova.**

## Cosa NON ho fatto

⛔ Nessun file sotto `ios_app/` toccato · nessun commit · nessun `git add` · nessun push ·
SCALETTA e BOX3 non toccati (sha provati) · nessuna versione alzata · in BUGS solo la
paternità · nessun reperto dell'audit corretto · non ho letto il congedo del referee.

---

### Controllo d'integrità di QUESTO file — sul CONTENUTO

**Prima riga attesa:** `# MISURE CC — A184 · SOTTRAZIONI FINALI`

**Stringhe obbligatorie:**
`guard let lh = self.linkEngineHandle else { return }` ·
`· il ponte lo legge in produzione (zero compilazione condizionale nel file);` ·
`valgono SOLO in 4/4` · `una campana sola` · `169 righe aggiunte` ·
`8d5210397e68764289bd9490f1c9259ca303c7ee3061a8aa0be78825c53e033d` ·
`Co-Authored-By` · `QUATTRO NUMERI SBAGLIATI` · `restart» non è un pulsante del transport` ·
e il marcatore di fine qui sotto.

⚠️ **Contate le stringhe, non i titoli.**

---

*A184-FINE — MISURE CC 22/08/2026 COMPLETO*
