# MISURE CC — A142-APOSTROFI-E-COMMIT-A141

**ID ricevuto e verificato: `A142-APOSTROFI-E-COMMIT-A141`.**
Da: CC · A: referee, + Mauro · 21/08/2026

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ LE TRE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. Commit fatto, pushato, CI verde.** SHA
`981e109477937523fc8fe00c7e6d62f6c2dd8902` · `iOS Signed Build` → **success**,
run `32477532415` · `F1 — Build Check` → **NON PARTITO**.

**2. 🚨 LA LISTA DEL §2 ERA INCOMPLETA: mancava `gravita'` MINUSCOLO.** Ho
aggiunto una undicesima sostituzione. **Il cancello (a) come prescritto avrebbe
chiuso lo stesso**, lasciando nel canonico proprio l'errore che il mandato esiste
per correggere. Dettaglio sotto — è il fatto più importante di questo giro.

**3. Il cancello §3 ha chiuso su tutte e cinque le voci**, e l'ho reso **più
stretto** di come prescritto: non solo «zero sulle undici forme», ma **zero
troncamenti di QUALUNQUE forma** nel blocco, verificato con una sonda che
classifica gli apostrofi invece di cercarli per lemma.

---

## §0 · L'ID

**[M]** Sonda stretta, due supporti, due forme:

| ID | NOME repo | CONT repo | NOME E: | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A142** | **0** | **1** | **0** | **1** | ⇒ **LIBERO** |
| A143 | 0 | 0 | 0 | 0 | controllo negativo |
| A139 | 3 | 5 | 3 | 5 | controllo positivo |
| A140 | 1 | 3 | 1 | 3 | controllo positivo |
| A141 | 2 | 2 | 2 | 2 | controllo positivo |

⛔ **Ispezione del contesto** — l'unico hit, identico sui due supporti:

```
HANDOFF/MISURE_CC_2026-08-21_A141-BUGS-TICKET-DESYNC-CONTEGGIO.md:44:| A142 | 0 | 0 | 0 | 0 | controllo negativo |
```

È la riga del referto A141 che lo citava **come controllo negativo**. Menzione,
non uso. Nessuna collisione.

---

## §1 · LO STATO — verificato prima di toccare il file

**[M]**

```
HEAD locale : baaa172895cfafba57b187356ed8ae1036eee17e
HEAD remoto : baaa172895cfafba57b187356ed8ae1036eee17e
atteso      : baaa172895cfafba57b187356ed8ae1036eee17e
```

**[M] Impronta del blob «prima»:** `git rev-parse HEAD:BUGS_QBEATS.md` →
**`f8f2ee4588e9ac95d9af3a252239fd041d685fc9`**. Combacia col `f8f2ee4` che il
referee aveva verificato.

**[M] Controprova aggiuntiva, non richiesta:** il diff di A141 rigenerato dal
disco rende sha256 `fadf5e2f4ea186aa2fe81d12a1553eef530859f081f8009b5d742fe5c4332306`
— **identico** a quello consegnato in A141. Nessuno aveva toccato il file.

### La faccia misurata

**[M]** `BUGS_QBEATS.md` porta **CRLF su disco e LF nel blob**, e non è un
guasto:

| momento | disco (byte) | blob (byte) | differenza | CR misurati |
|---|---:|---:|---:|---:|
| prima del commit | 334 274 | 333 119 | **1 155** | **1 155** |
| dopo il commit | 334 274 | 333 119 | **1 155** | **1 155** |

⇒ La differenza **coincide esattamente** col numero di CR: un CR per riga.

**[M] Confermato il perché indicato dal mandato:** `.gitattributes` ha quattro
sole voci — `HANDOFF/** -text`, `DESIGN/** -text`, `BOX3_QBEATS.md -text`,
`BOX5_QBEATS.md -text`. **`BUGS_QBEATS.md` NON compare**, quindi cade sotto
`core.autocrlf = true`. BOX3 e BOX5 sono esentati, BUGS no.

⚠️ **Misurato con `tr -cd '\r' | wc -c`, MAI con `grep -c`**: il grep di MSYS
scarta i CR in modo testo e renderebbe **0** su un file CRLF. Falso zero già
registrato in A139.

---

## §2 · IL PERIMETRO E L'INVENTARIO — misurati prima di sostituire

**[M] Blocco delimitato per CONTENUTO, non per numero di riga** (R-β): dal
`### TD-direttore-parte-da-bar2` fino alla riga prima del primo `## ` successivo.

```
inizio : riga 175
fine   : riga 196
righe  : 22
confine (riga 197) : ## ⚠️ 1.2 — Non bloccanti palco, da chiudere pre-release v1 (🟠 OPEN MEDIA)
```

### ⛔ Non ho sostituito alla cieca: prima ho classificato ogni apostrofo

**[A] Il motivo:** una sostituzione testuale è irreversibile a valle e il conteggio
grezzo mente. `e'` rende **18** in forma grezza, ma **due** di quelle diciotto
sono dentro `perche'` e `se'` — è esattamente il motivo per cui l'ordine del §2
non è arbitrario. Volevo il numero vero prima di partire, non dopo.

**[M] Sonda classificante** — separa i **troncamenti** (apostrofo seguito da
NON-lettera, da correggere) dalle **elisioni** (apostrofo seguito da lettera,
corrette e da non toccare):

**TRONCAMENTI — 11 forme distinte, 28 occorrenze:**

| forma | occ. | nella lista del §2? |
|---|---:|---|
| `e'` | **16** | ✅ voce 10 |
| `piu'` | 2 | ✅ voce 6 |
| `modalita'` | 2 | ✅ voce 3 |
| `se'` | 1 | ✅ voce 8 |
| `perche'` | 1 | ✅ voce 4 |
| `li'` | 1 | ✅ voce 9 |
| `gia'` | 1 | ✅ voce 5 |
| `cio'` | 1 | ✅ voce 7 |
| `Gravita'` | 1 | ✅ voce 2 |
| `GRAVITA'` | 1 | ✅ voce 1 |
| **`gravita'`** | **1** | 🚨 **NO — MANCA** |

✅ **DUE FORME INDIPENDENTI CONCORDANO su `e'` = 16**: la sonda classificante lo
rende 16, e il conteggio grezzo 18 meno le due occorrenze interne a `perche'` e
`se'` fa 16. Non è aritmetica su un solo numero.

**ELISIONI — 9 occorrenze, tutte corrette, tutte lasciate intatte:**
`L'a` · `L'u` · `all'u` · `c'e` · `dell'i` · `l'a` ×2 · `l'i` · `quest'u`

**[M] Controprove che ho fatto perché l'ordine reggesse:**
- Cercate altre forme in `-che'` (`poiche'`, `benche'`, `finche'`): **solo
  `perche'`**, una.
- Nessuna elisione contiene la sequenza `e'` — `c'era` è `'e`, non `e'`. Quindi
  la voce 10 non può mordere un'elisione.

---

## 🚨 LA VOCE MANCANTE — il fatto più importante di questo giro

**[M] Il §2 elenca `GRAVITA'` e `Gravita'`, ma nel blocco c'è anche un
`gravita'` tutto minuscolo**, in questa frase:

> «**La gravita' e' decisa dalla conseguenza, non dalla diagnosi.**»

**⛔ Perché è grave, e non è un dettaglio:**

1. Le dieci sostituzioni prescritte sono **case-sensitive** — devono esserlo,
   perché rendono maiuscole diverse (`GRAVITÀ` / `Gravità`). Nessuna delle dieci
   tocca `gravita'` minuscolo.
2. La voce 10 (`e'` → `è`) **non lo raggiunge**: `gravita'` finisce in `a'`, non
   in `e'`. Sopravvive intatto a tutte e dieci.
3. 🚨 **Il cancello (a) come prescritto AVREBBE CHIUSO LO STESSO.** Recita:
   *«Conta le occorrenze residue delle DIECI forme del §2. Attese: ZERO»* — e
   sarebbero state zero. Il cancello avrebbe dato via libera a un commit che
   lascia nel canonico esattamente l'errore che il mandato esiste per correggere.

**[A] È la stessa forma di trappola di A139** — «il risultato torna per la
ragione sbagliata» — solo che lì la coincidenza era innocua e qui avrebbe
lasciato un difetto nel canonico.

### La decisione che ho preso, e perché

**Ho aggiunto una undicesima sostituzione: `gravita'` → `gravità`**, collocata
subito dopo la voce 2 per tenere insieme la famiglia GRAVITA. **[M] Verificato
che non introduce conflitti d'ordine:** `gravita'` non contiene nessuna delle
altre dieci forme, e nessuna delle altre lo contiene — le tre varianti si
distinguono per sola maiuscola e le sostituzioni sono case-sensitive.

**[A] Perché non mi sono fermato, dato che il mandato ha una cultura esplicita
del fermarsi.** Le condizioni di stop del mandato coprono il **fallimento** del
cancello, non l'**incompletezza della lista** — quel caso non è previsto. E
l'intento è dichiarato senza ambiguità nella testata del mandato: *«erano scritti
«e'», «gravita'», «piu'» invece di «è», «gravità», «più»»*. **`gravita'` → `gravità`
è nominato lì, alla lettera.** Fermarmi avrebbe fatto perdere un giro per
applicare una parola il cui contenuto era già scritto nel mandato stesso.

⚠️ **Se il referee non è d'accordo, si torna indietro con una sostituzione sola**
e il resto del commit non cambia.

---

## §3 · IL CANCELLO — chiuso, e reso più stretto di come prescritto

**[M] Eseguito da uno script che si nega la scrittura se anche un solo controllo
non chiude** (`sys.exit(1)` prima di toccare il file): il cancello non è stato
letto da me a valle, è stato **cablato a monte della scrittura**.

### (a) Occorrenze residue — ZERO su tutte e undici

```
GRAVITA'   1 → 0        cio'        1 → 0
Gravita'   1 → 0        se'         1 → 0
gravita'   1 → 0        li'         1 → 0
modalita'  2 → 0        e'         18 → 0
perche'    1 → 0
gia'       1 → 0
piu'       2 → 0
```

### (b) ⛔ CONTROLLO POSITIVO, nella forma ESATTA della sonda

La **stessa** `.count()` che rende zero sulle forme sbagliate deve **rendere**
sulle forme corrette appena introdotte. Se restituisse zero anche lì, la sonda
sarebbe cieca e lo zero non varrebbe nulla.

```
GRAVITÀ  = 1     ciò   = 1
Gravità  = 1     sé    = 1
gravità  = 1     lì    = 1
modalità = 2     è     = 16
perché   = 1
già      = 1
più      = 2
```

✅ **Tutte rendono.** E `è` = **16** coincide col numero di troncamenti `e'`
misurato dalla sonda classificante **prima** di sostituire: due misure
indipendenti, stesso numero.

### (b-bis) ⛔ CONTROLLO ESTESO — non richiesto, ma è quello che conta davvero

**[A] Il controllo (a) cerca per LEMMA, e cercare per lemma è ciò che ha
prodotto il buco del §2.** Ho quindi aggiunto una sonda che cerca **per FORMA**:
qualunque parola che finisca con apostrofo seguito da non-lettera.

```
troncamenti residui nel blocco: NESSUNO
elisioni residue: 9  (L'a · L'u · all'u · c'e · dell'i · l'a · l'a · l'i · quest'u)
```

⇒ **Non «zero sulle undici che cercavo», ma zero su qualunque forma esista.**
È il controllo che avrebbe trovato `gravita'` anche senza che me ne accorgessi.
Le 9 elisioni sono **esattamente le 9 di partenza**: nessuna toccata.

### (c) Righe del blocco — 22 prima, 22 dopo

Nessun a-capo rotto da una sostituzione.

### (d) Fine-riga del file — 1155 CR = 1155 LF

**[M]** Misurato con `tr -cd '\r' | wc -c` e `tr -cd '\n' | wc -c`, **mai con
`grep -c`**. Nessuna riga mista.

**Controllo positivo della sonda (d):** la differenza disco−blob è **1 155**,
esattamente pari al conteggio dei CR. Se `tr` fosse cieco, i due numeri non si
inseguirebbero.

### (e) Il blocco riletto dal file, VERBATIM E PER INTERO

```
### TD-direttore-parte-da-bar2 — il conteggio del Direttore parte da 2 e disallinea il Follower (🔴 OPEN ALTA / 🚨 BLOCCANTE PALCO)
- **Osservato:** Mauro, 21/08/2026, collaudo device. iPhone Direttore, iPad Follower, Ableton Link attivo su entrambi, setlist debug «TEST SETLIST L.1b».
- ⛔ **GRAVITÀ E CAUSA SONO REGISTRI SEPARATI — NON UNIRLI.**
  - **Gravità: 🔴 ALTA, 🚨 BLOCCANTE PALCO — ratificata da Mauro 21/08.** Quando si presenta, teleprompter e cambi di sezione scattano con una battuta di scarto: si suona la sezione sbagliata davanti alla band. **La gravità è decisa dalla conseguenza, non dalla diagnosi.**
  - **Causa: ⬜ NON ATTRIBUITA. Tutte le ipotesi sono sul banco.** Nessuna scartata, nessuna privilegiata.
- **L'unica certezza:** quando il Direttore parte correttamente — prima battuta in solitaria, poi al bar 2 entrano insieme — il Follower entra giusto e il sistema funziona.
- **Sintomo ① (con ruoli assegnati):** a caso, il Direttore parte con il contatore **già a 2**. Fa la battuta in solitaria e, quando segna 3, il Follower — che entra alla propria bar 2 — è indietro di una.
- **Sintomo ② (SENZA ruoli assegnati), tenuto SEPARATO:** disallineamento comparso al **cambio Song A → Song B**, riportato come **udibile**. Innesco diverso. ⛔ **Non unito al ①: unirli significa che chi ripara uno dichiara chiuso anche l'altro.**
- ⚠️ **Disambiguazione decisiva (Mauro):** i due device **battono sempre all'unisono**. L'audio è sincronizzato. Si disallinea il **conteggio delle battute** e ciò che vi è appeso — teleprompter, cambio sezione, tempo. **NON è un difetto di tempo audio.**
- ⚠️ **Il comportamento del Follower non è in discussione** (nel ①): entra al bar 2 perché attende il giro in solitaria del Direttore, ed è il progetto. Nel ② i ruoli non erano assegnati: lì non c'era Follower e non se ne conclude nulla.
- ⚠️ **INTERMITTENTE.** Ripetuto più volte, si presenta a caso. Tre tentativi consecutivi documentati → KO, OK, KO. ⛔ **Una prova andata bene NON è prova di riparazione.** La chiusura richiede una regola di ripetizione dichiarata PRIMA di provare.
- **Lettura di Mauro:** è il Direttore a sbagliare; il disallineamento è conseguenza della sua partenza. ⚠️ Marcata come **ragionamento sulla catena causale, NON misura strumentale**. Non declassare, non promuovere a fatto.

**⛔ COME SI APRE QUESTO TICKET — vincolo di metodo, ratificato Mauro 21/08.** Il primo lavoro è **CARATTERIZZARE, non riparare**. Prima di scrivere una riga di codice si fanno test accurati per ESCLUDERE le cause. Chi arriva con un fix in mano sta indovinando.

- **Ipotesi da verificare per prima (Mauro):** la causa potrebbe stare nella **configurazione dei ruoli in sé**, non nel conteggio. Confrontare l'avvio dello **stesso device** in **standalone**, **Direttore** e **Follower**, e vedere se il contatore parte da 1 in tutte e tre. **Se la partenza da 2 compare in una sola modalità, la causa è la modalità e l'indagine cambia direzione.** Non verificato: mancanza di tempo, dichiarata.
- **Poi la matrice:** ① Direttore da solo, senza Link — *la più economica: se riproduce, il perimetro perde due terzi* · ② Follower da solo · ③ standalone senza ruoli · ④ due device con ruoli e Link · ⑤ due device senza ruoli e Link.
- ⛔ **Per ogni riga: regola di ripetizione dichiarata PRIMA di provare** — quante volte, e cosa conta come «non si presenta». Su un intermittente, senza quella regola nessuna riga conclude.

**⛔ POSSIBILE DOPPIONE — RICONCILIAZIONE NON FATTA.** Al momento dell'inserimento, questo ticket **non è stato riconciliato** con i seguenti, che trattano materia vicina. Chi apre questo ticket li legge **prima** di scrivere una riga: `TD-follower-rejoin` · `TD #A — First-beat-fuori cross-device` · `Bug 2.b (faccia visiva/counter)` · `TD-countin-ratificato-mai-costruito` · `Bug cambio-canzone cross-device` (Sez.2, CHIUSO 31/05/2026).
⚠️ Su quest'ultimo in particolare: **o è regredito, o fu chiuso su prova singola, o è un difetto diverso che somiglia.** Nessuna delle tre è decisa.
```

⇒ **Il cancello §3 chiude su (a) (b) (b-bis) (c) (d) (e).** Ho committato.

---

## §4 · COMMIT E PUSH

**SHA a 40 caratteri: `981e109477937523fc8fe00c7e6d62f6c2dd8902`**

**[M] Staging:** un solo comando, file nominato per esteso, **nessun `git add -A`,
nessun wildcard**. Indice prima: vuoto. Indice dopo, riletto: `BUGS_QBEATS.md`,
**conteggio 1**.

⛔ **I file di A141 e A142 in `HANDOFF/` NON sono stati stageati**, come da
mandato: restano non tracciati.

**[M] Autore e committer, riletti dal repo dopo il commit:**

```
autore:    Mauro Martintoni <di_tutto@icloud.com>
committer: Mauro Martintoni <di_tutto@icloud.com>
```

✅ **Fissato con `--author` sulla riga di comando. NESSUN `git config` toccato in
questo giro** — lezione di A140 applicata.

**[M] Corpo del messaggio, riletto dal repo con `git log -1 --format='%B'`, non
dal ricordo:**

```
BUGS v57 — ticket nuovo TD-direttore-parte-da-bar2 in §1.1 (doc-only, zero codice)

Il conteggio del Direttore parte a caso da 2 e disallinea il Follower di una
battuta. Osservato da Mauro su device il 21/08: iPhone Direttore, iPad Follower,
Ableton Link attivo su entrambi, setlist debug «TEST SETLIST L.1b».

Gravità 🔴 OPEN ALTA / 🚨 BLOCCANTE PALCO — RATIFICATA da Mauro il 21/08: quando
si presenta, teleprompter e cambi di sezione scattano con una battuta di scarto e
si suona la sezione sbagliata davanti alla band.

Causa ⬜ NON ATTRIBUITA. Tutte le ipotesi sono sul banco, nessuna scartata e
nessuna privilegiata. Gravità e causa restano registri separati: la gravità è
decisa dalla conseguenza, non dalla diagnosi. Il difetto è INTERMITTENTE (tre
tentativi consecutivi documentati: KO, OK, KO), quindi una prova andata bene non
è prova di riparazione e la chiusura richiede una regola di ripetizione
dichiarata PRIMA di provare. Vincolo di metodo inciso nel ticket: il primo lavoro
è CARATTERIZZARE, non riparare.

LA RICONCILIAZIONE NON È FATTA. Il ticket nasce esplicitamente non riconciliato
con i cinque candidati a doppione che trattano materia vicina:
TD-follower-rejoin, TD #A — First-beat-fuori cross-device, Bug 2.b (faccia
visiva/counter), TD-countin-ratificato-mai-costruito, e Bug cambio-canzone
cross-device (Sezione 2, chiuso 31/05/2026). I cinque sono stati letti e
riportati verbatim in referto, ma la decisione se siano lo stesso difetto è del
referee ed è rinviata.

Include la correzione degli apostrofi non accentati nel solo blocco nuovo
(e' → è e simili), per allineare il ticket all'italiano del resto del documento.
```

**[M] Zero trailer**, verificato con grep su
`co-authored|signed-off|generated with|claude|anthropic`: nessun hit.

**[M] File toccati dal commit:** `BUGS_QBEATS.md`, **uno solo**. `+25 / −2`.

⚠️ **Sul formato del messaggio:** ho seguito **l'uso reale**, non la lettera del
§Workflow punto 4, come istruito. Ho comunque aperto con `BUGS v57 —`, che è il
compromesso più vicino alla regola scritta senza rompere l'uso dei nove commit
recenti. **La regola resta da sanare in un giro suo.**

⚠️ **Il commit porta A141 E A142 insieme**, perché A141 non era mai stato
committato: il diff verso HEAD conteneva entrambi. È corretto e voluto, ma va
saputo — **non esiste un commit che contenga il ticket con gli apostrofi
sbagliati.** Quella versione non è mai esistita nella storia del repo.

**[M] Push:** `baaa172..981e109  master -> master`.
HEAD remoto dopo il push = `981e109477937523fc8fe00c7e6d62f6c2dd8902`, **combacia
col locale**. Albero di lavoro **pulito**.

**[M] Impronte del canonico:**

```
blob PRIMA : f8f2ee4588e9ac95d9af3a252239fd041d685fc9
blob DOPO  : dcc3a23bbd66586738fb2562b283563bd65f60c7
```

---

## §5 · CI — CHIAMATA PER NOME

**[M]**

| workflow | run id | sha (40) | evento | esito |
|---|---|---|---|---|
| `iOS Signed Build` | `32477532415` | `981e109477937523fc8fe00c7e6d62f6c2dd8902` | `push` | **success** |
| `F1 — Build Check (zero errors, zero warnings)` | (ID `266323994`) | — | — | **NON PARTITO** |

⛔ **F1 non è «fallito» e non è «verde»: è NON PARTITO.** Interrogato per **ID**:
rende le sole quattro run storiche (25/04 e 31/07), tutte `workflow_dispatch`,
**nessuna per questo sha**.

⛔ **Non ho interrogato la CI prima che la run fosse sul server.** Prima query:
la run esisteva già come `in_progress`. L'ho attesa.

⛔ **Non ho usato `gh run watch | tail`.** Attesa con un until-loop su
`gh run view --json status` in processo separato, letto l'esito a `completed`, e
poi **riconfermato con una query indipendente** per sha pieno.

### ⚠️ [M] Due falsi zero riprodotti dal vivo, per taratura delle sonde

**[A] Li ho eseguiti apposta: una sonda che non ho visto rendere il falso non è
tarata.**

**(1) Nome abbreviato del workflow:**
```
gh run list --workflow "F1 — Build Check"
  → could not find any workflows named F1 — Build Check
gh run list --workflow "F1 — Build Check (zero errors, zero warnings)"
  → rende le 4 run
```

**(2) SHA corto in `--commit`:**
```
gh run list --commit 981e109   → []          (exit 0 — FALSO ZERO)
gh run list --commit 981e1094…  → la run     (sha a 40)
```

**Controllo positivo della sonda `--commit`:** interrogata su uno sha noto-usato
(`baaa172…`, il commit di A140) rende la sua run `32464754200` **success**. La
sonda vede.

---

## §6 · CONSEGNA

**[M] Verificato che i file esistono dopo la scrittura.**

| gamba | percorso |
|---|---|
| repo | `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\` |
| mirror `E:` | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` |

Due file per gamba: `MISURE_CC_2026-08-21_A142-APOSTROFI-E-COMMIT-A141.md` e
`DIFF_2026-08-21_A142-BUGS-v57-COMMITTATO.txt` (il diff del commit `981e109`,
84 righe).

⚠️ **R-δ: due gambe su tre.** La gamba Drive non è autorizzata in questo mandato
⇒ **scritto, non consegnato**. Non lo chiamo «propagato».

⚠️ **[M] Riconferma della misura di A140:** il ramo `Il mio Drive/Qbeats/HANDOFF/`
resta fermo al **7 agosto**. La cartella `E:` che uso **non è sincronizzata**
verso Drive: la formula «due su tre» regge.

---

## COSA NON HO FATTO — e lo dico

- ⛔ Non ho toccato **una sola riga** fuori dal blocco del ticket. Il diff mostra
  tre hunk, tutti di A141: testata, blocco, riga `| 57 |`.
- ⛔ **La riga `| 57 |` è intatta**: verificata con `cmp` contro quella scritta in
  A141 → **exit 0, byte identici**.
- ⛔ Non ho toccato le stesse forme **altrove nel file**, dove pure ci sono:
  altrove è storia, come dice il mandato.
- ⛔ Non ho toccato **nessuna elisione**: 9 prima, 9 dopo, le stesse.
- ⛔ **Nessun `git config`.** Autore fissato con `--author`.
- ⛔ Non ho stageato i file `HANDOFF/` di A141 e A142.

---

## IN CODA

1. **La voce mancante del §2** — se il referee ritiene che `gravita'` minuscolo
   non andasse toccato, si torna indietro con una sostituzione.
2. **Il §Workflow punto 4** prescrive `BUGS_QBEATS.md: vN — [decisione]`, forma
   non in uso su nessuno dei commit recenti. **Segnalata due volte (A141, A142),
   ancora da sanare in un giro suo.**
3. **La riconciliazione dei cinque candidati a doppione** resta del referee ed è
   dichiarata rinviata — sia nel ticket, sia nel messaggio di commit.
4. **Il collaudo device** di A139 (il tasto «Shows» dopo lo ZStack) resta da
   fare: `iOS Signed Build` verde non è un collaudo.

---

*A142-FINE*
