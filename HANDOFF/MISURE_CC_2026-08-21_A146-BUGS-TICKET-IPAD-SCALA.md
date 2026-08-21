# MISURE CC — A146-BUGS-TICKET-IPAD-SCALA

**ID ricevuto e verificato: `A146-BUGS-TICKET-IPAD-SCALA`.**
Da: CC · A: referee, + Mauro · 21/08/2026
Ancoraggio: **HEAD = `a83353c382877037d27b35912f6d3bdda6ee1988`**, locale = remoto.

🔎 **Integrità del mandato: PASSA.** Visti §0 · §1 · §2 · §3 · §4 e la chiusura
`FINE MANDATO A146`. Nessun taglio.

⛔ **NESSUN COMMIT.** Diff in `HANDOFF/DIFF_2026-08-21_A146-BUGS-TICKET-IPAD-SCALA.txt`.
⛔ **DOC-ONLY:** un solo file, `BUGS_QBEATS.md`. Zero codice.
⛔ **NON HO INDAGATO:** nessun file di codice aperto per cercare la causa, nessun
fix proposto, nessuna mia ipotesi nel ticket.

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ LE TRE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. Nessuna condizione di stop è scattata.** ID libero · HEAD combacia · la
regola di posizione **conferma** il mandato alla lettera · **tutti e tre** i
ticket iPad sono CHIUSI.

**2. ✅ LA MISURA IN CODA HA UNA RISPOSTA NETTA, e non è «da nessuna parte».**
Il precedente esiste ed è **doppio**: `LIBRO` Sezione 2 (riga datata) **+**
marcatura additiva sull'atomo in `SCALETTA`. BOX3 e BOX5 rendono **zero**, con
sonda tarata. Dettaglio in fondo — è il pezzo che serve per incidere il 7/7 di
A139 nel posto giusto.

**3. ⚠️ Un difetto trovato mentre leggevo i tre candidati: `TD #23` NON DICHIARA
LA PROPRIA CHIUSURA.** È chiuso solo **per posizione**. Segnalato, non riparato.

---

## §0 · L'ID

**[M]** Sonda stretta (perimetro documentale, `*.md`/`*.txt`, binari esclusi,
confine di parola), due supporti:

| ID | NOME repo | CONT repo | NOME E: | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A146** | **0** | **1** | **0** | **1** | ⇒ **LIBERO** |
| A147 | 0 | 0 | 0 | 0 | controllo negativo |
| A143 | 0 | 3 | 0 | 3 | (mandato annullato) |
| A144 | 3 | 4 | 3 | 3 | controllo positivo |
| A145 | 1 | 2 | 1 | 2 | controllo positivo |

⛔ **Ispezione del contesto** — l'unico hit, identico sui due supporti:

```
HANDOFF/MISURE_CC_2026-08-21_A145-COMMIT-A144.md:35:| A146 | 0 | 0 | 0 | 0 | controllo negativo |
```

È la riga del referto A145 che lo citava **come controllo negativo**. Menzione,
non uso. Nessuna collisione.

---

## §1 · LO STATO E LA FACCIA

**[M]** Letto con `git rev-parse HEAD` e `git ls-remote origin master`, mai
`rev-parse origin/master`:

```
locale : a83353c382877037d27b35912f6d3bdda6ee1988
remoto : a83353c382877037d27b35912f6d3bdda6ee1988
atteso : a83353c382877037d27b35912f6d3bdda6ee1988
```

**[M] Faccia dichiarata**, misurata con `tr -cd` e **mai con `grep -c`** (che su
CRLF renderebbe zero — falso zero registrato in A139):

| momento | disco (byte) | blob (byte) | differenza | CR misurati |
|---|---:|---:|---:|---:|
| prima | 334 274 | 333 119 | **1 155** | **1 155** |
| dopo | — | — | — | **1 169** |

⇒ Differenza disco−blob **coincide** col conteggio dei CR: un CR per riga.
`.gitattributes` esenta solo `HANDOFF/**`, `DESIGN/**`, BOX3 e BOX5 — **BUGS non
è coperto**, quindi cade sotto `core.autocrlf`. Dopo la scrittura:
**CR = LF = 1 169**, zero righe miste.

---

## §2 · REGOLE DI CASA — VERBATIM

### §Workflow aggiornamento, righe 50-55

```
### Workflow aggiornamento
1. Nuovo bug emerge in chat → CC lo aggiunge qui PRIMA di proporre fix
2. Bug viene fixato → CC aggiorna stato a 🟢 CHIUSO con commit di riferimento
3. Diagnosi smentita → CC sposta in Sezione "Scartati / smentiti" con motivazione
4. Modifiche al file → diff letterale in chat, commit `BUGS_QBEATS.md: vN — [decisione]`
5. Posizione: un ticket nuovo si inserisce IN CODA alla sottosezione di severità che gli compete. La posizione non porta significato: lo porta la severità. (Ratificata referee 20/07 — prima non era scritta e i due casi più recenti si comportavano in modo opposto.)
```

✅ **Il punto 5 conferma la posizione prescritta dal mandato alla lettera.** Non
la smentisce.

### §Priorità palco, righe 45-48 — per leggere la severità proposta

```
### Priorità palco
- 🚨 **BLOCCANTE PALCO** — non possiamo suonare live con questo bug aperto
- ⚠️ **NON BLOCCANTE** — fastidio ma palco fattibile
- 📦 **BACKLOG** — pre-release v1 o post-v1
```

---

## §2-bis · I TRE CANDIDATI A DOPPIONE — RIPORTATI, NON GIUDICATI

**[M] Localizzati per NOME, mai per riga** (R-β). Tutti e tre cadono dentro
**Sezione 2 — Bug CHIUSI** (righe 822-997), verificato coi confini di sezione.

⛔ **Riporto e basta.** L'unica determinazione che faccio è quella che il §2
impone: **nessuno dei tre è aperto**. Se siano lo stesso difetto **non lo dico**:
è del referee ed è dichiarato rinviato, anche dentro il ticket stesso.

### 1 · `TD-ipad-editor-fontsize` — Sez.2

**Titolo intero:**
```
### TD-ipad-editor-fontsize — editor Q-Stage con testo non scalato su iPad — 🟢 CHIUSO 01/07/2026
```

**Riga di stato:**
```
- **🟢 CHIUSO 01/07/2026 (device-confermato, Mauro «ok tutto bene»):** su HEAD `11e5017`, editor canzone/sezione **scalati su iPad** + **tipografia DS uniforme** — 4 header sezione uniformi (JBMono 10 UPPER) + Repeat&Feel coerente iPhone/iPad. *(Il device ha confermato scaling + tipografia = il bug vero; per il glifo Subdivision vedi PIN ②.)*
```

⇒ **CHIUSO**, dichiarato **due volte** — nel titolo e nella riga di stato.

### 2 · `TD-ipad-home` — Sez.2

**Titolo intero:**
```
### TD-ipad-home — overflow portrait + landscape iPad — 🟢 CHIUSO 30/06/2026
```

**Riga di stato:**
```
- **🟢 CHIUSO 30/06/2026 (device-confermato, collaudo `b1c50ab`, Mauro):** "home va benissimo" + "non si gira resta bloccato in verticale".
```

⇒ **CHIUSO**, dichiarato due volte.

### 3 · `TD #23 — Font responsive iPad (Strada A scaling)` — Sez.2

**Titolo intero:**
```
### TD #23 — Font responsive iPad (Strada A scaling)
```

**Riga di stato:** ⚠️ **[M] NON ESISTE.** Questo ticket **non ha alcuna riga di
Stato**, e il suo titolo **non porta `🟢 CHIUSO`**, a differenza degli altri due.
Le righe che più vi si avvicinano sono:

```
- **Fix:** commit `adfcc39` (Fase 1 log baseline 390pt) + `8a5432b` (Fase 2 refactor 11 file, 24 callsite) 18/05/2026.
- **Validato:** iPhone 13 + iPad portrait pre-2018.
```

⇒ **CHIUSO — ma solo PER POSIZIONE.** Sta dentro Sezione 2 («Bug CHIUSI»), sotto
l'intestazione `## 🟢 Maggio 2026`. **[M] Verificato coi confini:** Sezione 2 va
da 822 a 997, e il ticket è a 952.

**⇒ Nessuno dei tre è aperto: la condizione di stop del §2 non scatta.**

---

## §3-§4 · COSA HO SCRITTO

**Diff:** `HANDOFF/DIFF_2026-08-21_A146-BUGS-TICKET-IPAD-SCALA.txt`
· 40 righe · sha256 `89f897ab51de0c09e4b38d07e685bb86f477f755cf873beaa6974f5ef97e3f4b`
· **1 file, +15 / −1**.

| # | cosa | esito |
|---|---|---|
| §3 | ticket `TD-qlive-non-scalata-ipad`, **in coda a §1.2** | inserito a `:472`; `## 📦 1.3` ora a `:485` |
| §4 | `**Versione:**` 57 → **58** | fatto |
| §4 | `**Ultima modifica:**` → **2026-08-21** | **era già 2026-08-21** (l'ha portata A141): nessuna modifica necessaria, e infatti il diff **non la tocca** |
| §4 | riga `| 58 |` in coda alla tabella di Sezione 5 | fatto, formato delle due precedenti |

**[M] L'UNICA riga rimossa dal diff è `-**Versione:** 57`.** Tutto il resto è
puramente additivo: nessun ticket esistente toccato, nessuna riga di storico
riscritta.

**[M] Conteggio ticket in §1.2: erano 23, ora sono 24.** Nessuno spostato.

### Il testo del ticket: cosa ho adattato

⛔ **Non ho riformulato, abbreviato né aggiunto nulla.** Unico adattamento, quello
autorizzato: **titolo su UNA riga sola** — il mandato lo presenta spezzato su due,
tutti i ticket vicini lo portano su una. Ricongiunto senza cambiare una parola.

✅ **Gli apostrofi:** il testo del mandato arriva già in italiano corretto
(`è`, `già`, `più`, `perché`), a differenza di A141. **Nessuna sostituzione
necessaria, nessuna fatta.** Verificato: zero troncamenti con apostrofo nel
blocco nuovo.

---

## ✅ LA MISURA IN CODA — dove sono registrati gli ESITI DEI GATE DEVICE

**[A] È la parte che serve davvero, quindi la do per intero invece che a
conteggi.** Un `grep -c` dice *dove compare il nome dell'atomo*, non *dove sta
l'esito* — sono due domande diverse, e la seconda è quella posta.

### Censimento per canonico

| canonico | `S5a` | `S5b` | l'ESITO c'è? |
|---|---:|---:|---|
| `LIBRO_MASTRO_QBEATS.md` | 3 | 2 | **SÌ per S5a** · no per S5b |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 4 | 11 | **SÌ per S5a** · no per S5b |
| `BUGS_QBEATS.md` | 2 | 5 | **NO** — solo menzioni |
| `BOX3_QBEATS.md` | **0** | **0** | no |
| `BOX5_QBEATS.md` | **0** | **0** | no |

⛔ **CONTROLLO POSITIVO sugli zeri di BOX3/BOX5**, perché uno zero non tarato non
è un fatto: la stessa sonda rende **43** su `S4` in BOX3 e **23** su `Q-Live` in
BOX5. **Gli zeri sono veri: i gate device non si registrano lì.**

⚠️ **E le 2 occorrenze di `S5a` in BUGS non sono registrazioni d'esito**, sono
menzioni — verificate col contesto: «*scheda di ⟦S5a⟧*» e «*prodotta da ⟦S5a⟧*».

### ⟦S5a⟧ — il precedente, ed è DOPPIO

**[M] L'esito è inciso in DUE posti, entrambi per esteso:**

**(1) `LIBRO_MASTRO_QBEATS.md:358`** — riga datata nel registro di Sezione 2
(cross-team):
> `| 2026-08-18 | **⟦S5a⟧ CHIUSO DEVICE — collaudo Mauro 18/08 su `Test Setlist L1.b`.** Apertura del dettaglio da tap sul corpo della riga: **nessun crash**. Dati corretti (nome show, elenco SONG, ordine): **verde**. Ritorno a SHOWS dalla freccia: **ve…**`

**(2) `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:433`** — **marcatura additiva sulla
scheda dell'atomo**:
> `- ✅ **MARCATURA 18/08 — ⟦S5a⟧ CHIUSO DEVICE, supera il punto (1) della marcatura 07/08 sopra. La marcatura 07/08 resta come scritta: si marca, non si riscrive.** Collaudo Mauro 18/08 su `Test Setlist L1.b`: apertura dettaglio, dati, ritorno a SHOWS…`

⚠️ **Notare la forma:** la SCALETTA **non riscrive** la riga d'ordine dell'atomo —
le appende una marcatura che la supera. È lo stesso principio «si marca, non si
riscrive» usato in tutto il corpus.

### ⟦S5b⟧ — l'esito NON è registrato da nessuna parte

**[M]** In LIBRO le due occorrenze sono la testata (`:6`) e la riga di registro
v57 (`:516`), ed entrambe parlano di **ancoraggio di un puntatore**, non di
esito. In SCALETTA c'è la **scheda** dell'atomo (`:315`) e i suoi rimandi, ma
**nessuna marcatura di chiusura device**.

⇒ Coerente con lo stato noto: il collaudo ⟦S5b⟧ è **pendente**, il documento
`HANDOFF/MISURE_CC_2026-08-19_A127-COLLAUDO-S5b.md` esiste ma l'esito non è mai
atterrato. **[A] È il precedente NEGATIVO, e vale quanto quello positivo:
dimostra che un gate senza esito inciso resta invisibile ai canonici.**

### ⇒ IL POSTO GIUSTO PER IL 7/7 DI A139

**[A] Il precedente dice: `LIBRO` Sezione 2, riga datata.** È l'unico canonico che
porta l'esito di un gate device come **evento cross-team**, ed è dove ⟦S5a⟧ è
stato inciso.

⚠️ **Con una differenza da dichiarare, non da nascondere:** la seconda gamba del
precedente — la marcatura in SCALETTA — vale perché ⟦S5a⟧ **è un atomo con una
scheda lì**. **A139 non è un atomo ⟦…⟧: è un mandato.** Quindi il precedente si
applica **per intero solo sulla prima gamba**; sulla seconda va deciso se
l'oggetto abbia una scheda che lo ospiti.

⛔ **Non l'ho scritto: non è autorizzato qui.** Ma ora il posto è misurato, non
indovinato.

---

## ⚠️ DIFETTI NOTATI ALTROVE — SEGNALATI, NON RIPARATI

**1. 🚨 `TD #23` non dichiara la propria chiusura.** È l'unico dei tre ticket iPad
senza `🟢 CHIUSO` nel titolo **e** senza riga di Stato. È chiuso **solo perché sta
in Sezione 2**. Chi lo citasse per nome fuori contesto — e il mio stesso ticket
nuovo lo cita **due volte** — non troverebbe in esso nulla che dica «chiuso».
**[A] È la stessa classe di fragilità dei puntatori `file:riga` senza ancora: il
fatto è vero, ma non è portato dall'oggetto che viene citato.**

**2. Il §Workflow punto 4** prescrive il formato di commit
`` `BUGS_QBEATS.md: vN — [decisione]` ``, che i commit recenti su questo file non
usano. **Terza segnalazione** (A141, A142, ora). Da sanare in un giro suo.

---

## CONTROLLI DI INTEGRITÀ

| controllo | esito |
|---|---|
| a-capo dopo la scrittura | **CR = LF = 1 169** ⇒ CRLF uniforme, zero righe miste |
| file toccati | **1** (`BUGS_QBEATS.md`), verificato su diff e `git status` |
| righe rimosse dal diff | **1**, la sola `**Versione:** 57` |
| ticket in coda a §1.2 | `:472`, con `## 📦 1.3` subito dopo a `:485` |
| nessun ticket spostato | §1.2 passa da **23** a **24** intestazioni `###` |
| apostrofi nel blocco nuovo | zero troncamenti: il testo arriva già corretto |

---

## §4 · CONSEGNA

**[M] Verificato che i file esistono dopo la scrittura.**

| gamba | percorso |
|---|---|
| repo | `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\` |
| mirror `E:` | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` |

Due file per gamba: `MISURE_CC_2026-08-21_A146-BUGS-TICKET-IPAD-SCALA.md` e
`DIFF_2026-08-21_A146-BUGS-TICKET-IPAD-SCALA.txt`.

**Facce:** `HANDOFF/**` è `-text` ⇒ **LF, disco = blob**. `BUGS_QBEATS.md` **non**
è coperto ⇒ **CRLF su disco, LF nel blob**.

⚠️ **R-δ: due gambe su tre.** Drive non autorizzato ⇒ **scritto, non consegnato**.

---

## IN CODA

1. **Il 7/7 di A139** — ora il posto è misurato: `LIBRO` Sezione 2, riga datata.
   Serve un mandato.
2. **L'esito di ⟦S5b⟧** — documento pronto dal 19/08, mai atterrato in un
   canonico. Stesso buco, più vecchio.
3. **`TD #23` senza dichiarazione di chiusura** — segnalato sopra.
4. **La severità di `TD-qlive-non-scalata-ipad`** — proposta 🟠 MEDIA, **decide
   Mauro**: dipende da se l'iPad sia device di palco o di prova.
5. **Il §Workflow punto 4** — formato del messaggio di commit, terza segnalazione.
6. **Il collaudo device di A144 su iPhone è verde**; su iPad il badge scivola, ed
   è il ticket che nasce qui.

---

*A146-FINE*
