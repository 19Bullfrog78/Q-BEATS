# MISURE CC — A152-DOVE-SONO-I-FILE

**ID ricevuto e verificato: `A152-DOVE-SONO-I-FILE`.**
Da: CC · A: Mauro, + referee · 21/08/2026

🔎 **Integrità del mandato: PASSA.** Visti §0 · §1 · §2 · §3 e `FINE MANDATO A152`.

⛔ **SOLA LETTURA.** Nessuno spostamento, nessuna copia, nessuna cancellazione,
nessun commit. **Non ho «sistemato» niente.**

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## 🚨 IL FATTO, PRIMA DI TUTTO: MAURO HA RAGIONE, ED È UN MIO ERRORE

**[M] In A151 ho creato una cartella nuova — `STAMPE_PER_PROGETTO_2026-08-21\` —
quando le collocazioni esistevano già.** Non ho cercato: ho inventato.

⚠️ **[A] La cosa che rende l'errore peggiore, e la dichiaro perché è la lezione:
su Drive AVEVO misurato il perimetro con cura** e ho trovato `Qbeats\BUGS_QBEATS\`
e `Qbeats\LIBRO_MASTRO\`. **Su `E:` non ho fatto la stessa ricerca** — ho dato per
scontato che non esistessero, quando **le stesse due cartelle erano lì, con 48 e
21 file dentro**. Ho applicato la disciplina su una gamba e non sull'altra.

**Bilancio del mio errore, misurato:**

| oggetto | dove l'ho messo | dove doveva andare | esito |
|---|---|---|---|
| BUGS su Drive | `Qbeats\BUGS_QBEATS\` | idem | ✅ **giusto** |
| LIBRO su Drive | `Qbeats\LIBRO_MASTRO\` | idem | ✅ **giusto** |
| SCALETTA su Drive | `Qbeats\` (radice) | `Qbeats\HANDOFF\` | ⛔ **sbagliato** |
| BUGS su E: | `STAMPE_PER_PROGETTO…\` | `FILE X CLAUDE.MD\BUGS_QBEATS\` | ⛔ **sbagliato** |
| LIBRO su E: | `STAMPE_PER_PROGETTO…\` | `FILE X CLAUDE.MD\LIBRO_MASTRO\` | ⛔ **sbagliato** |
| SCALETTA su E: | `STAMPE_PER_PROGETTO…\` | `FILE X CLAUDE.MD\HANDOFF\` | ⛔ **sbagliato** |
| le tre su C: | `Desktop\ANTIGRAVITY\STAMPE_PER_PROGETTO…\` | **da nessuna parte** — vedi sotto | ⛔ **cartella di troppo** |

---

## §1 · I PERCORSI COMPLETI DELLE TRE STAMPE

**[M] Tutte e nove le copie ESISTONO e COMBACIANO** con byte e sha256 dichiarati
in A151. Nessuna manca, nessuna è corrotta.

### `BUGS_QBEATS_v58_2026-08-21_638b738.md` — 338 704 byte · `6a26367a8f377420…`

```
C:\Users\BULLFROG\Desktop\ANTIGRAVITY\STAMPE_PER_PROGETTO_2026-08-21\BUGS_QBEATS_v58_2026-08-21_638b738.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\STAMPE_PER_PROGETTO_2026-08-21\BUGS_QBEATS_v58_2026-08-21_638b738.md
I:\Il mio Drive\Qbeats\BUGS_QBEATS\BUGS_QBEATS_v58_2026-08-21_638b738.md
```

### `LIBRO_MASTRO_QBEATS_v57_2026-08-21_638b738.md` — 276 359 byte · `ec643df46209b7ce…`

```
C:\Users\BULLFROG\Desktop\ANTIGRAVITY\STAMPE_PER_PROGETTO_2026-08-21\LIBRO_MASTRO_QBEATS_v57_2026-08-21_638b738.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\STAMPE_PER_PROGETTO_2026-08-21\LIBRO_MASTRO_QBEATS_v57_2026-08-21_638b738.md
I:\Il mio Drive\Qbeats\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v57_2026-08-21_638b738.md
```

### `SCALETTA_v11_2026-08-21_638b738.md` — 66 467 byte · `d1d8b396cb7eefbe…`

```
C:\Users\BULLFROG\Desktop\ANTIGRAVITY\STAMPE_PER_PROGETTO_2026-08-21\SCALETTA_v11_2026-08-21_638b738.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\STAMPE_PER_PROGETTO_2026-08-21\SCALETTA_v11_2026-08-21_638b738.md
I:\Il mio Drive\Qbeats\SCALETTA_v11_2026-08-21_638b738.md
```

---

## §2 · LE DUE CARTELLE CHE MAURO PRESCRIVE — LE STAMPE NON CI SONO

**[M] Le due cartelle ESISTONO su `E:`, e sono le destinazioni storiche:**

| cartella | file dentro | ultimo per data |
|---|---:|---|
| `E:\…\FILE X CLAUDE.MD\BUGS_QBEATS\` | **48** | `BUGS_QBEATS_V51_2026-08-07_779172e.md` |
| `E:\…\FILE X CLAUDE.MD\LIBRO_MASTRO\` | **21** | `LIBRO_MASTRO_QBEATS_V55_2026-08-07_81740e4.md` |

⛔ **Le stampe di oggi NON sono lì.** Sono in
`E:\…\FILE X CLAUDE.MD\STAMPE_PER_PROGETTO_2026-08-21\`, la cartella che ho
creato io.

✅ **NON esistono in entrambi i posti: non ci sono copie doppie.** Sono solo nel
posto sbagliato — misurato file per file.

⛔ **CONTROLLO POSITIVO della sonda `-d`**, perché un «esiste/non esiste» non
tarato non è un fatto: la stessa sonda rende **SI** su `HANDOFF\` e su
`STAMPE_PER_PROGETTO_2026-08-21\`.

⚠️ **[M] E c'è una divergenza di nome che va decisa insieme allo spostamento:** le
48 e 21 stampe storiche usano la **`V` MAIUSCOLA** (`_V51_`, `_V55_`). Le mie
usano la **`v` minuscola**, come prescriveva il mandato A151. ⇒ **Se si spostano,
vanno anche rinominate**, altrimenti l'unico file minuscolo starà in mezzo a 48
maiuscoli.

---

## §3 · LA SCALETTA — DOVE VANNO LE SUE VERSIONI

### §3a · Cartelle di primo livello sotto `E:\…\FILE X CLAUDE.MD\`

```
.tmp.driveupload · ALTRI · ARCHIVI_ZIP · BOX1_Memoria · BOX2_Istruzioni
BOX3_Codice · BOX4 · BOX5_Test · BUGS_QBEATS · CC MEMORIA · DA_CD_PER_CC
DESIGN_E_BRIEFING · DOC  MIX · DUPLICATI · GRAFICA · HANDOFF · IMMAGINI
LIBRO_MASTRO · STAMPE_PER_PROGETTO_2026-08-21 · SYSTEM_PROMPT · tools
```

⚠️ **`STAMPE_PER_PROGETTO_2026-08-21` è la cartella che ho creato io.** Le altre
venti sono preesistenti.

### §3b · Le versioni precedenti della SCALETTA — **NON sono zero**

**[M] Stanno in `HANDOFF\`.** Non in una cartella dedicata: la SCALETTA non ne ha
una, e **non serve inventarla**.

**`E:\…\FILE X CLAUDE.MD\HANDOFF\` — otto stampe versionate:**

```
SCALETTA_v3_2026-07-28_8289944.md               35 661 byte
SCALETTA_v4_2026-07-30_a393466.md               36 070 byte
SCALETTA_v4-non-bumpata_2026-08-02_07e0926.md   36 673 byte
SCALETTA_v5_2026-08-02_c00feb4.md               37 691 byte
SCALETTA_v6_2026-08-02_e386264.md               39 354 byte
SCALETTA_v7_2026-08-04_ea3f94a.md               42 035 byte
SCALETTA_v8_2026-08-06_2960f08.md               44 101 byte
SCALETTA_v9_2026-08-07_321293e.md               54 558 byte
```

Più il canonico `SCALETTA_ATOMI_S6_2026-07-10.md` (56 791 byte) nella stessa
cartella.

✅ **[M] E usano la `v` MINUSCOLA** — quindi per la SCALETTA il nome che ho dato è
**già coerente**: è solo la cartella a essere sbagliata.

**Su Drive**, le precedenti stanno in `I:\Il mio Drive\Qbeats\HANDOFF\` (tre:
v3, v4, v9) ⇒ **anche lì la mia SCALETTA a radice è nel posto sbagliato.**

### Il quadro delle collocazioni, misurato su tutte e tre le gambe

| stampa | C: (repo) | E: | Drive |
|---|---:|---|---|
| BUGS versionati | **0** | `BUGS_QBEATS\` (8) | `Qbeats\BUGS_QBEATS\` (6) |
| LIBRO versionati | **0** | `LIBRO_MASTRO\` (17) | `Qbeats\LIBRO_MASTRO\` (13) |
| SCALETTA versionate | **0** | `HANDOFF\` (8) | `Qbeats\HANDOFF\` (3) |

🚨 **[M] LA COLONNA C: È ZERO SU TUTTE E TRE LE RIGHE, e non è un caso.** Nel repo
**non si sono mai tenute stampe versionate**: vivono su `E:` e su Drive.
⇒ **La cartella che ho creato su C: non è «nel posto sbagliato»: è di troppo.**

⛔ **CONTROLLO POSITIVO**, perché tre zeri di fila vanno tarati: la stessa sonda
rende **8**, **17** e **8** sulle rispettive cartelle di `E:`. **La sonda vede: gli
zeri su C: sono veri.**

---

## 🚨 UN REPERTO CHE NESSUNO CERCAVA: TRE FILE ORFANI DEL MANDATO A150

**[M] Trovati mentre misuravo, non cercandoli.** Il mandato **A150 è stato
annullato**, ma **aveva già scritto su disco prima dell'annullamento**:

```
E:\…\FILE X CLAUDE.MD\STAMPE_PER_PROGETTO_2026-08-21\BUGS_QBEATS_v58_2026-08-21_c46c0d4.md          338 704 byte
E:\…\FILE X CLAUDE.MD\STAMPE_PER_PROGETTO_2026-08-21\LIBRO_MASTRO_QBEATS_v57_2026-08-21_c46c0d4.md  276 359 byte
E:\…\FILE X CLAUDE.MD\STAMPE_PER_PROGETTO_2026-08-21\SCALETTA_v11_2026-08-21_c46c0d4.md              66 467 byte
```

⚠️ **Portano `c46c0d4` nel nome — lo sha di A150 — mentre le stampe buone portano
`638b738`.** Stesso peso, stesso contenuto, **nome che dichiara un commit
diverso**.

⛔ **[A] È esattamente la trappola contro cui questo progetto si difende da
settimane: due file che si somigliano nel nome, in cui il nome dice cose diverse.**
Chi ne carica uno a caso nel Progetto carica un file ancorato a un commit che non
è HEAD.

**[M] Nessun residuo su C: e nessuno su Drive: sono tre, tutti su `E:`.**
Controllo positivo: la stessa sonda rende **9** file con `638b738`.

⛔ **Non li ho toccati.** Cancellare è irreversibile e nessun mandato lo autorizza.

---

## ⛔ COSA SERVIREBBE PER RIPARARE — misurato, NON eseguito

**[A] Lo scrivo perché Mauro possa autorizzarlo in una riga, non perché intenda
farlo di mia iniziativa.**

**Spostamenti (6):**
```
E:  BUGS     STAMPE_PER_PROGETTO_2026-08-21\  ->  BUGS_QBEATS\
E:  LIBRO    STAMPE_PER_PROGETTO_2026-08-21\  ->  LIBRO_MASTRO\
E:  SCALETTA STAMPE_PER_PROGETTO_2026-08-21\  ->  HANDOFF\
Drive SCALETTA  Qbeats\  ->  Qbeats\HANDOFF\
```
(BUGS e LIBRO su Drive sono **già** al posto giusto: non si toccano.)

**Rimozioni (7):**
```
E:  i 3 orfani _c46c0d4
E:  la cartella STAMPE_PER_PROGETTO_2026-08-21\  (vuota dopo lo spostamento)
C:  le 3 stampe + la cartella STAMPE_PER_PROGETTO_2026-08-21\  (C: non ospita stampe: zero storiche)
```

**Rinomine da decidere (2):** `_v58_` → `_V58_` e `_v57_` → `_V57_`, per allinearsi
alle 48 e 21 storiche. **La SCALETTA no**: la sua convenzione è già minuscola.

⚠️ **Non lo faccio senza un OK esplicito**: comporta **cancellazioni**, e una
cancellazione sbagliata non si misura, si subisce.

---

## CONSEGNA

**[M] Referto su tutte e tre le destinazioni, nella cartella `HANDOFF\` che è la
collocazione esistente dei referti — nessuna cartella nuova creata:**

| gamba | percorso |
|---|---|
| C: | `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\` |
| E: | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` |
| Drive | `I:\Il mio Drive\Qbeats\` (radice — è dove stanno i 13 referti del 19/08) |

⛔ **Perimetro su Drive rispettato:** nulla scritto in `Qbeats_IN_CD\`, e la
ritirata di CD non è stata toccata.

---

## IN CODA

1. **L'autorizzazione a riparare** — 6 spostamenti, 7 rimozioni, 2 rinomine.
   Decide Mauro.
2. **I tre orfani `_c46c0d4`** — residui di A150 annullato, ancora su `E:`.
3. **La `v` minuscola contro la `V` maiuscola** per BUGS e LIBRO.
4. ⚠️ **Restano valide tutte le pendenze del congedo** — in particolare che **il
   LIBRO MASTRO è fermo al 19/08**: la stampa v57 appena prodotta porta un
   registro che non sa cosa è successo dopo il 19.

---

*A152-FINE*
