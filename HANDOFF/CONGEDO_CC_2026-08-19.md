# CONGEDO CC — A123, 19/08/2026

Da: CC · A: chi apre la chat CC successiva, + referee + Mauro
Sessione: mandati **A101 → A123**. Scritto **alla cieca**, senza leggere il congedo del referee.

Marcatura: **[M]** misurato da me in questa sessione · **[R]** riportato da altri, non rimisurato ·
**[A]** assunzione o giudizio mio.

---

## PARTE MECCANICA

### 1 · HEAD e albero

**[M]** HEAD locale = HEAD remoto = **`fe2091a8434f801316ea59c15bb54b006150a3bd`**
(`git rev-parse HEAD` e `git ls-remote origin master`, non `rev-parse origin/master`).
Albero pulito sui tracciati: **sì** — `git status --porcelain=v1 | grep -vc '^??'` → **0**.

⚠️ **LA DATA NON TORNA, e va letta prima di fidarsi di qualunque cosa dica «18/08».**
Il commit è delle **2026-08-19 12:48:06 +0200**. Ma **tutti** i mandati di questa sessione, tutti i
referti e **le due voci di registro che ho appena scritto** (BUGS 53, LIBRO 57) dicono **18/08**.
La sessione ha attraversato la mezzanotte: il commit precedente `44fea3e` era del 18/08 alle 16:27.
⇒ **[A] È un difetto vero e l'ho lasciato**, invece di correggerlo da solo: la convenzione del
registro è che la data sia quella del commit, quindi le voci **dovrebbero dire 19/08**.
Non l'ho toccato perché avrebbe fatto divergere il registro da ogni referto della giornata, e la
scelta non è mia. **È una riga per file, e va decisa.**

### 2 · I due workflow, per nome

**[M]**

| workflow | run id | esito | data | evento | sha |
|---|---|---|---|---|---|
| **`iOS Signed Build`** | `32244528793` | **success** | 2026-08-19T10:49:06Z | push | `fe2091a8…` |
| `iOS Signed Build` (precedente) | `32148440889` | success | 2026-08-18T14:27:32Z | push | `44fea3e3…` |
| **`F1 — Build Check (zero errors, zero warnings)`** | `30639169986` | **failure** | 2026-07-31T14:34:28Z | workflow_dispatch |
| `F1` (penultima) | `30638276963` | **failure** | 2026-07-31T14:21:52Z | workflow_dispatch |

⛔ **F1 non gira dal 31/07 e le sue ultime due run sono entrambe fallite.** È `workflow_dispatch`:
non parte da sola. ⚠️ **«CI verde» in questo progetto significa sempre e solo `iOS Signed Build`.**
Un terzo workflow esiste (`Build LinkHut Diagnostic`) ma non tocca l'app.

### 3 · Impronte dei cinque canonici al nuovo HEAD

**[M]** Estratte con `git show fe2091a:<path>`, **mai da disco**. CR contati sui byte
(`tr -cd '\r' | wc -c`), **mai con grep**.

| canonico | sha256 (blob) | byte | righe | CR |
|---|---|---:|---:|---:|
| `LIBRO_MASTRO_QBEATS.md` | `ec643df46209b7ce50feabc3a41860b6f155efa031d7506105d1f8af45fdea8c` | 276 359 | 519 | 0 |
| `BUGS_QBEATS.md` | `122b094635bd1aa52ed9a8641b0a69d6f4cc3e27e05bcf43456f833263da90b7` | 311 069 | 1 089 | 0 |
| `BOX3_QBEATS.md` | `c728baccb7823f7f20d4544b72130147e7f72fc40104887f0da3fcf24d29fb3c` | 89 457 | 803 | 0 |
| `BOX5_QBEATS.md` | `cf425ff0d576910c9caa2899cad232e0c8447f605d240021262608aed184ff5b` | 57 158 | 596 | 0 |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | `d1d8b396cb7eefbe2e979fc9f3ae0a7695ca5031947b035213aeccf1a68f361a` | 66 467 | 457 | 0 |

⚠️ **CR=0 su tutti e cinque perché sono impronte del BLOB.** La **faccia disco** di LIBRO e BUGS
porta CRLF — controprova: LIBRO su disco ha **519 CR**. Se al rientro misuri su disco e non torna,
**non è un guasto**: è questo. **Dichiara sempre quale faccia stai misurando.**

⛔ **BOX3 e BOX5 sono invariati da `44fea3e`**: stesso sha256. Solo tre canonici sono cambiati.

### 4 · Prossimo ID libero

**[M] Sonda**: `grep -rlE '\bA<N>\b'` — forma **a token**, non nuda, su **due supporti indipendenti**
(`HANDOFF/` nel repo e `HANDOFF/` su E:).
⛔ **CONTROLLO POSITIVO IN FORMA DIVERSA DALLA SONDA**, come richiesto: la sonda cerca il **token
nel CONTENUTO**; il controllo cerca il **NOME DI FILE** (`ls | grep`), che è un meccanismo
indipendente. `A121` → **3 file per nome** su repo e **3** su E:; `A124` → **0 e 0**.
⇒ Il controllo sa distinguere presenza da assenza **senza usare la sonda**.

| ID | repo | E: | lettura |
|---|---:|---:|---|
| A116 | 3 | 3 | ⛔ **mai eseguito** — le 3 sono tutte **menzioni** dentro altri referti, **nessun file si chiama A116** |
| A117 | 4 | 4 | ✅ **ESEGUITO** — una delle 4 è l'artefatto `MISURE_CC_2026-08-18_A117-PORTE.md` |
| A118 | 3 | 3 | usato — la scheda ratificata |
| A119 · A120 | 0 | 0 | ⛔ mai eseguiti, **nessuna menzione** |
| A121 | 3 | 3 | ✅ **ESEGUITO** — referto + 2 diff |
| A122 | 3 | 2 | ✅ **ESEGUITO** — l'asimmetria è spiegata sotto, **non è una propagazione mancata** |
| A123 | 0 | 0 | questo congedo (l'occorrenza nasce con questo file) |
| **A124** | **0** | **0** | ⇒ **PROSSIMO LIBERO** (valori misurati *prima* di scrivere questo file) |

⛔ **AUTORIFERIMENTO, dichiarato perché non tragga in inganno:** i due zeri di A124 sono la misura
**precedente** alla scrittura di questo congedo. Da quando esiste questo file, `\bA124\b` rende
**1 su ciascun supporto** — ed è **questa riga**, una **menzione**, non un artefatto.
⇒ **Il criterio è il NOME DEL FILE, non il conteggio delle occorrenze:** nessun file si chiama
`…A124…`, quindi A124 è libero. È lo stesso controllo positivo in forma diversa usato sopra, ed è
la ragione per cui va usato quello e non il grep sul contenuto.

**[M] L'asimmetria di A122 spiegata, perché sembra un difetto e non lo è:** su repo il terzo file
è `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` — il canonico stesso, che ora contiene «(A122)» nella
marcatura di sezione C. Su E: quel file è **fermo alla versione precedente**, quindi non lo contiene.
**Entrambi gli artefatti A122 sono su entrambi i supporti.**

⚠️ **[M] E questo è il reperto vero: I TRE CANONICI SU E: SONO STALE.**

| file | sha su E: | sha nel repo | stato |
|---|---|---|---|
| `SCALETTA_ATOMI_S6_2026-07-10.md` | `09bf3442a372a17e…` | `d1d8b396cb7eefbe…` | ⛔ **STALE** (v10 contro v11) |
| `LIBRO_MASTRO_QBEATS.md` | `59c1fd73b431…` | `324cf8f3efa1…` | ⛔ **STALE** |
| `BUGS_QBEATS.md` | `64f7df092744…` | `4b25cc45141a…` | ⛔ **STALE** |

⚠️ **E manca anche lo snapshot per-versione**: su E: esistono `SCALETTA_v9_2026-08-07_321293e.md`,
`SCALETTA_v8_…`, `…v7`, `…v6` — la convenzione c'è e **non è stata onorata per v11, v53, v57**.
⛔ **Non li ho propagati io: non era nel perimetro di A123**, e il nome dello snapshot segue una
convenzione che non spetta a me inventare. **È lavoro da fare, ed è la prima cosa da sistemare.**

**[M] Bruciati verificati uno per uno:** A98, A100, A106, A107, A109, A112, A114, A116, A119, A120
→ **nessun artefatto porta quei nomi**. A117 e A121 → **artefatti presenti**, bruciati come
**ESEGUITI**. ⚠️ **Non riusare nessuno dei dodici**, in nessuna delle due categorie.

---

## LO STRUMENTO CHE DEVE SOPRAVVIVERE

⛔ **La controprova d'ordine.** Non è un aneddoto: è il miglior pezzo di metodo della giornata, e
si porta via così com'è.

**Il problema che risolve.** In A121 ho innestato la scheda ⟦S5b⟧ **dopo** l'intestazione di ⟦S6⟧
invece che prima: ⟦S6⟧ è rimasta senza corpo e ⟦S5b⟧ si è ritrovata due `Scopo:`. **Ho consegnato
quel difetto con tre controprove verdi in mano** — e tutte e tre erano **vere**:

| controprova | cosa dimostrava | perché era cieca |
|---|---|---|
| «103 righe su 103, divergenti 0» | il **contenuto** | confronta la scheda a partire dalla **sua** intestazione, ovunque essa sia |
| «13 intestazioni» | il **conteggio** | 13 è 13 anche in ordine sbagliato |
| `git apply -R --check` OK | la **reversibilità** | un diff che introduce un difetto è reversibile come uno sano |

⇒ **Nessuna guardava l'ordine, ed era l'unica cosa rotta.**

**Come funziona.** Estrae la sequenza **ordinata** delle intestazioni `###` fra `## B ·` e `## C ·`;
per ciascuna isola il blocco fino alla successiva e misura due invarianti:

1. la prima riga non vuota dopo l'intestazione **non deve essere un'altra intestazione**;
2. il blocco deve contenere **esattamente UN** `- **Scopo:**`.

⚠️ **La seconda è quella che morde:** una scheda innestata male lascia **una scheda a zero `Scopo`
e un'altra a due**. Il difetto non può nascondersi.
⚠️ **La regola è sul BLOCCO, non sulla prima riga**: ⟦S3⟧ apre con `🔴 **RISCRITTO 12/07**` e non
con `Scopo:`, e passa correttamente.

⛔ **E QUESTA È LA PARTE CHE NON SI TOGLIE: si autoverifica fallendo.** Prima di scrivere, lo
script **ricostruisce in memoria la disposizione difettosa di A121** e ci applica la controprova.
Se **non** fallisce, lo script **si ferma da solo** con «LA CONTROPROVA NON SA FALLIRE: inutile».
Uscita reale del giro A122:

```text
  [A121] intestazioni: 13  |  ANOMALE: 2
     ⛔ :313  ⟦S6⟧ METROFAB — cablaggio porta  -> blocco con 0 `Scopo:` invece di 1
     ⛔ :314  ⟦S5b⟧ Start del dettaglio → play -> blocco con 2 `Scopo:` invece di 1
  ✅ La controprova FALLISCE sulla disposizione di A121 -> è una controprova vera.
```

⇒ **[A] La regola generalizzata, che vale ben oltre la SCALETTA:**
**una controprova va applicata a un caso NOTO-CATTIVO prima di fidarsene su quello buono.**
Se non sai far fallire il tuo controllo, non hai un controllo: hai una conferma che ti dai da solo.
Il codice vive in `HANDOFF/` nei referti A122/A123 ed è poche righe: si riscrive in dieci minuti,
**ma solo se qualcuno sa che serve.**

---

## LE QUATTRO DOMANDE

### ① Cosa deve sapere chi arriva, e oggi non è scritto da nessuna parte

**[A] La cosa più importante l'ho già scritta sopra** (la controprova che sa fallire). Queste sono
le altre quattro, e **nessuna è in un canonico**:

**(a) Il modo tipico di sbagliare in questo progetto è la SONDA, non il ragionamento.** Oggi è
successo **quattro volte**, e ogni volta il referee ha visto prima di me:
`**Gate:**` cieca alla punteggiatura (⟦S4L⟧ usa `🔴 Gate —`, e il mio controllo positivo usava
**la forma della sonda**, quindi non poteva fallire) · aver risposto a una domanda di **spec** con
una misura di **codice** · aver misurato **un campo** e concluso sul **meccanismo** (count-in) · e
un quarto quasi-errore che ho intercettato da solo: cercare `countIn` nei percorsi d'avvio rende
**4 file** e sembra che il campo sia letto — sono **tutte occorrenze dello stato**, un simbolo
omonimo. ⇒ **Quando misuri, chiediti prima di che FORMA è il bersaglio, e scegli il controllo
positivo su una forma DIVERSA.**

**(b) Tre oggetti diversi si chiamano `countIn`** — il campo `Song.countIn`, lo stato di motore
`AudioEngine.PlaybackState.countIn`, lo stato di UI `LivePlaybackState.countIn(countdown:)`.
Ora è nel ticket nuovo, ma la lezione generale no: **in questo corpus gli omonimi sono la trappola
più economica in cui cadere.**

**(c) La faccia disco non è uniforme, e scrivere ciò che non le somiglia corrompe in silenzio.**
`SCALETTA` è **LF**, `LIBRO` e `BUGS` sono **CRLF**. In A121 ho inserito 21 righe LF in BUGS e l'ho
reso **misto** senza che nulla lo segnalasse. ⇒ **Chi scrive in un canonico misura prima la faccia
del bersaglio e adatta**, e **ricontrolla dopo**: `CRLF` e `LF-sole` devono essere uno zero e un
numero, mai due numeri.

**(d) Una clausola di sicurezza scritta in un canonico è una MISURA, e le misure scadono.**
`SCALETTA:324` dichiarava «zero citazioni nude con riga ≥320»: **vera al suo commit, falsa a HEAD**,
perché una citazione nuda è stata introdotta **dopo**. Chi si fosse fidato per dire «inserire qui
è sicuro» avrebbe rotto un puntatore. Ora è marcata — ma **la regola vale per ogni clausola di
quel tipo: si rimisura, non si rilegge.**

### ② Cosa NON va rimisurato — e cosa SÌ

**NON va rimisurato — misurato più volte, e in parte verificato in modo avversariale:**

- **[M] La catena dello Start e i quattro file di ⟦S5b⟧.** `SetlistRunner` mai costruito (zero siti)
  · slot senza mutatore · nessuno naviga a `.metronome` · START SHOW a closure vuota. Misurato in
  A99/A103 e **attaccato da cinque verificatori indipendenti istruiti a confutare: cinque REGGE,
  zero controesempi**.
- **[M] Il modello «arma + standby + secondo tap» è già tutto costruito** in `LiveView`
  (`:129` oscuramento, `:132-138` overlay + tap-ovunque). Manca solo accenderlo all'ingresso.
- **[M] `primeDisplay` ha UN SOLO chiamante** (`LiveView.swift:231`), ed è la sola porta già aperta
  verso la sessione al montaggio.
- **[M] Il count-in: catena rotta due volte** — campo mai letto **e** `startCountIn` stub. Tracciato.

**SÌ, va rimisurato — la mia misura è debole, e non voglio sia ereditata come solida:**

1. ⚠️ **Il difetto «secondo show con l'audio acceso» è una COMPOSIZIONE, non un'osservazione.**
   Poggia su tre fatti misurati **separatamente** (il back non ferma l'audio · lo stop vive solo al
   bordo-stanza · lo slot si sostituisce). **La sequenza non l'ha vista nessuno su un device**, e
   non può vederla finché ⟦S5b⟧ non esiste. **Non ereditarlo come fatto osservato.**
2. ⚠️ **Il censimento delle porte è completo rispetto a QUATTRO FORME, non all'universo.** Le
   sonde trovano ciò che il **codice** tradisce (closure vuota, seam col default, marcatore di
   rinvio, vista mai montata). Una capacità dichiarata in un canonico e **mai nemmeno abbozzata**
   non lascia traccia e sfugge a tutte e quattro — il count-in è emerso **solo** incrociando a mano.
3. ⚠️ **Tutto ciò che riguarda ciò che Mauro ha SENTITO sul device** resta fuori dalla mia portata.
   Sul count-in ho potuto misurare il codice, non il suo telefono. L'unico candidato per un conto
   udibile è l'attesa del confine di battuta di Link a due device, che il codice chiama
   «count-in **del Director**» — e resta **[A]**, non provato.
4. ⚠️ **Nessuno dei referti di oggi ha verifica indipendente.** Il giro avversariale che avevo
   lanciato è morto per intero — **otto agenti su otto per limite di sessione**. Ciò che è [M] l'ho
   misurato io, con controllo positivo su ogni zero; ma **A121 dimostra che non basta**.

### ③ Le undici porte — cosa so che la tabella non dice

**[M] Prima la correzione di conteggio, e va nella direzione buona:** il referee ha ragione che le
non tracciate erano **cinque** (#3 #4 #5 #8 #9) e non quattro — nel riepilogo di A117 ne avevo
contate quattro pur avendone elencate cinque nella tabella.
✅ **Con il commit di oggi la #9 (count-in) è TRACCIATA.** ⇒ **Restano QUATTRO non tracciate:
#3 `prev sez` · #4 `next sez` · #5 `loop` · #8 `RESTART` dopo stop.**

**[A] Quattro cose che la tabella non dice, e sono quelle che contano:**

- **Tre delle quattro sono nella PULSANTIERA, e sono ABILITATE IN PLAY.** `disabled: isCountIn ||
  isStandby` — cioè spente in count-in e in standby, **accese mentre suoni**. Sono i bottoni morti
  **più toccabili che ci siano**: stanno sotto il pollice nel momento peggiore.
- **Non sono soltanto non tracciate: il tracker afferma il CONTRARIO.** `BUGS:167` diceva «il sesto
  è l'unico muto» e `BUGS:288` diceva che l'equivalente UI di next/prev sezione **esiste**. Oggi
  sono **marcate** — ma **una marcatura non è un fix**: chi legge in fretta vede ancora la
  premessa vecchia in grassetto e la smentita sotto.
- **La #8 attraversa DUE stub in fila:** `restartCurrentSong()` → `restartFromBeginning()` →
  `resetToSongStart()` che è `{}`. Chi ripara il primo anello trova il secondo.
- **La #3/#4/#5 BLOCCANO la chiusura di un ticket già aperto.** `MIDI azioni-contenuto non cablate
  a L3` si chiuderebbe cablando il MIDI «come il TAP» — ma il TAP non fa nulla. **Cablarlo oggi
  specchierebbe il vuoto**, ed è scritto nella marcatura di `:288`.

⚠️ **E una cosa sulle sette già tracciate:** due (#2 METRONOME e #6 `emerg`) **non sono difetti** —
`LIBRO:356` le dichiara **scelta di prodotto**, pulsanti visibili e inerti come coda di lavoro.
**Nessuno ne proponga la rimozione come igiene.**

### ④ Cosa serve da Mauro — solo decisioni sue

1. **La severità dei due ticket nuovi** — `TD-countin-ratificato-mai-costruito` (proposta 🟠 MEDIA)
   e `TD-canonici-puntatori-path-stale` (proposta 🟡 BASSA). ⚠️ Sul primo il motivo ratificato è
   **di palco** (`LIBRO:225`, «ri-sincronizzazione mentale del batterista con la band»): potrebbe
   valere più di quanto pesi io. Precedente: i due ticket del 07/08, decisi da te.
2. **La data.** Le voci di registro dicono 18/08, il commit è del 19/08. Si correggono o si lascia?
3. **I mirror su E:.** I tre canonici sono **stale** e mancano gli snapshot per-versione di v11,
   v53, v57. Va fatto, e va deciso **da chi e quando**.
4. **Se F1 conta come cancello.** Non gira dal 31/07 e l'ultima volta è fallito. Finché non si
   decide, «CI verde» resta un'affermazione **parziale** a ogni consegna.
5. **Le quattro porte non tracciate** (#3 #4 #5 #8): si aprono ticket o no? Sono sul palco, in play.
6. **⟦S6F⟧ e ⟦S-EXIT⟧ sono ratificati e non hanno scheda.** ⟦S6F⟧ è la sede del difetto del
   secondo show; ⟦S-EXIT⟧ è nell'ordine ratificato. Due buchi noti e mai colmati.

---

## COSA NON RIFARE

**[M]** Il commit `fe2091a` è pushato e `iOS Signed Build` è **success** (`32244528793`): non
ri-committare, non ri-pushare. · I diff `A121-*` e `A122-*` in `HANDOFF/` sono **storia della
proposta**, già applicata: riapplicarli fallisce. · **A117 e A121 sono bruciati come ESEGUITI**:
i loro artefatti esistono e non vanno cercati altrove. · A98, A100, A106, A107, A109, A112, A114,
A116, A119, A120 **non hanno mai prodotto nulla**: non cercarne gli artefatti.

**[A] E la cosa che vale più di tutte, per chi arriva:** in questa sessione la scheda ⟦S5b⟧ è
**incisa** ma **il codice non è stato toccato** — `ios_app/` è a zero righe modificate da undici
giorni. ✅ **La differenza rispetto ai giri precedenti è che ora l'atomo ha una scheda con Gate e
Cond falsificabili, e un passo di collaudo che sa distinguere «armato» da «fermo».**
⛔ **Ma ⟦S5b⟧ resta da costruire, ed è il cardine: finché non esiste, l'app non può far partire
uno show.**

---

## IMPRONTE DI QUESTO CONGEDO

⛔ **Limite strutturale, dichiarato invece che aggirato:** lo sha256 del file **completo** non può
stare dentro il file stesso — inciderlo lo cambierebbe. Si incide lo sha del **CORPO** (tutto ciò
che precede il marcatore `## IMPRONTE DI QUESTO CONGEDO`); quello del file intero vive nel **messaggio di consegna**, come
prescrive `LIBRO` R7 §1 («sha256 = trasporto, non puntatore»).

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `e71047b6dadd19ca8be641324b95135f9a576318c5b2d385de5738f494e62cfa`
- **byte** (file completo): `18967`
- **righe** (file completo): `305`
- **CR** (0x0D, contati sui byte, mai con grep): `0`
- **byte NUL** (0x00, controprova sul bersaglio): `0`

---

*A123-CONGEDO-CC-FINE*
