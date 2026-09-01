# MISURE CC — A159-CENSIMENTO-TRE-GAMBE

**ID ricevuto e verificato: `A159`.**
Da: CC · A: referee, + Mauro · 21/08/2026

🔎 **Integrita' del mandato: PASSA.** Visti §0 §1 §2 §3 §4 §5 e la chiusura
`FINE MANDATO A159`. Nessun taglio.

⛔ **SOLA LETTURA. Zero file spostati, rinominati, cancellati o creati sulle tre
destinazioni, tranne questo referto.** Nessun commit.

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ LE QUATTRO RIGHE DA LEGGERE PRIMA DI TUTTO

**1. 🚨 LA REGOLA IN VIGORE E LA REALTA' DEL DISCO DICONO DUE COSE DIVERSE.**
La regola ratificata in A158 e' *«su Drive si copia la struttura del repo»*.
**[M] Ma Drive non replica il repo: replica `E:\…\FILE X CLAUDE.MD\`.**
**Diciannove** delle **venti** sottocartelle di E: hanno l'omonimo esatto su Drive
(l'unica assente e' `.tmp.driveupload`). Le cartelle del repo — `ios_app`,
`core_engine`, `ARCHIVIO.MD`, `Vendors`, `DESIGN` — **su Drive non esistono**;
quelle di Drive — `BOX1_Memoria`, `DA_CD_PER_CC`, `GRAFICA`, `IMMAGINI` — **nel
repo non esistono**. ⇒ **La regola descrive una struttura che nessuna delle tre
gambe ha.** ⛔ Non la risolvo: decide Mauro.

**2. 🚨 LA SINCRONIZZAZIONE E: → DRIVE E' FERMA DA META' AGOSTO, E LA STRUTTURA
GEMELLA LO NASCONDE.** **[M]** Le cartelle combaciano, i contenuti no:

| cartella | E: | Drive | mancanti su Drive |
|---|---:|---:|---:|
| `HANDOFF` | **370** | **186** | **−184** |
| `LIBRO_MASTRO` | 23 | 17 | −6 |
| `BUGS_QBEATS` | 50 | 46 | −4 |
| `BOX3_Codice` | 92 | 92 | 0 |

⛔ **Centottantaquattro referti che esistono su E: non sono su Drive.** Campione:
`CONGEDO_CC_2026-08-18.md`, `CONGEDO_CC_2026-08-19.md`,
`MISURE_CC_2026-08-19_A128-…md` — **tutti su E:, nessuno su Drive.**
✅ **Controllo positivo, che data il guasto:** `SCALETTA_v9_2026-08-07_321293e.md`
sta su **entrambi**. ⇒ La sonda vede, e **la sincronizzazione ha funzionato fino a
circa il 7 agosto**. Coerente: `.tmp.driveupload/` nel repo porta **790 file**, il
piu' recente del **5 agosto**.
⚠️ **[A] Questo e' il difetto piu' insidioso del censimento: due alberi con le
stesse cartelle sembrano allineati. Solo il conteggio per cartella lo smentisce.**

**3. ⛔ `FILE X CLAUDE.MD` NON ESISTE SU DRIVE. La correzione di A157 §4 non
regge alla misura.** **[M]** A157 diceva che vive «sotto Il mio computer».
`I:\Altri computer\Il mio Computer\` contiene **un solo file: `desktop.ini`**.
Cercato `*FILE*CLAUDE*` su tutto `I:` a profondita' **5**: **zero**.
✅ **Controllo positivo:** `*LIBRO*` trova `Qbeats/LIBRO_MASTRO` ⇒ la sonda vede.
⇒ **La mia misura di A156 era giusta e resta giusta.** La cartella `FILE X
CLAUDE.MD` esiste **solo su `E:`**.

**4. ⚠️ GLI ALBERI Q-BEATS SU DRIVE SONO DUE, PIU' UNO VUOTO CHE SEMBRA UN TERZO.**
**[M]** `I:\Il mio Drive\Qbeats` (lavoro, 20 cartelle + 56 file sciolti) ·
`I:\Il mio Drive\Qbeats_IN_CD` (di CD, 17 file, **non toccato**) ·
`I:\.Encrypted\Il mio Drive\Qbeats` — **struttura di cartelle con ZERO file**,
artefatto del client Drive. Il file di controllo **non c'e' dentro**.
⇒ **Non e' un terzo albero di contenuti. Ma chi lo trova con un `find` largo puo'
crederlo.**

---

## §0 · L'ID

**[M]** Due forme, due supporti, contesto, controllo positivo **e negativo**.

| ID | NOME repo | NOME E: | CONT repo | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A159** | **0** | **0** | **0** | **0** | ✅ **LIBERO**, contesto vuoto |
| A158 | 1 | 1 | 1 | 1 | controllo positivo |
| A157 | 0 | 0 | 2 | 2 | controllo positivo — **0 per nome** |
| A188 | 0 | 0 | 0 | 0 | controllo **negativo** |

⚠️ `A157` conferma il precedente citato dal mandato: **zero per nome, due per
contenuto.** Nome da solo non basta, mai.

---

## §1 · CANCELLO R2 — prima di leggere

**[M]** HEAD locale = remoto = `e4764f9aedea2e9cc0d98c92b48553bd60b3d93f` ·
tracciati puliti · **nessun `index.lock`** · **zero file toccati negli ultimi
dieci minuti su tutti e tre i supporti** (C: 0 · E: 0 · I: 0).
✅ Controllo positivo: i piu' recenti in `HANDOFF/` sono i miei — 19:56, 19:40,
18:53. ⇒ **Nessun'altra sessione attiva.**

---

## §2 · IL CENSIMENTO — le tre gambe

### GAMBA 1 — `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\` (repo git)

**Primo livello:** 16 cartelle · **17 file sciolti**.
`.claude` · `.github` · `.tmp.driveupload` · `ARCHIVIO.MD` · `DESIGN` · `FILE.MD` ·
`HANDOFF` · `Vendors` · `_cc_processo` · `core_engine` · `ios_app` ·
`ipa-fase-d{,-v2,-v3}` · `test_data` · `tools`

| famiglia | dove | conteggio |
|---|---|---:|
| **canonici** | **radice**, in place | LIBRO 280 023 B · BUGS 339 874 B · BOX3 89 457 B · BOX5 57 158 B |
| | SCALETTA | `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` |
| **referti e mandati** | `HANDOFF/` — **tutti, zero altrove** | MISURE **110** · CONGEDO **11** · DIFF **97** · tot. **283** |
| **contratti CD `.html`** | `DESIGN/QLive_Nav` (12) · `DESIGN/QLive_EndShow/…` (1) | **13** |
| **il resto** | `.tmp.driveupload` **790** · `core_engine` 251 · `ARCHIVIO.MD` 196 · `ios_app` 105 · `Vendors` 21 · `_cc_processo` 16 · `DESIGN` 15 | |

🚨 **[M] Due file in radice di un repo PUBBLICO che non sono documenti di
progetto:** `Claude Setup.exe` e `tmp_fix.ps1`. Il secondo e' gia' noto agli atti.
⚠️ **[M] `.tmp.driveupload/` — 790 file di staging Google dentro l'albero di
lavoro**, l'ultimo del 5 agosto. Non tracciato, quindi non pubblicato, **ma vive
dentro il repo**.

### GAMBA 2 — `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\` (NON git)

**Primo livello:** 13 cartelle, fra cui `FILE X CLAUDE.MD` — l'area mirror.
**Dentro `FILE X CLAUDE.MD`:** 20 sottocartelle · **2 soli file sciolti**
(`INDICE.md`, `TD44_REPORT_20_05_2026.md`).

| famiglia | dove | conteggio |
|---|---|---:|
| **canonici** | cartelle dedicate | `BUGS_QBEATS/` **50** · `LIBRO_MASTRO/` **23** · `BOX3_Codice/` **92** · `BOX5_Test/` 30 (0 di primo livello) |
| | SCALETTA | **12** stampe in `HANDOFF/` |
| **referti e mandati** | `HANDOFF/` | MISURE **110** · CONGEDO **11** · DIFF **103** · tot. **370** |
| **contratti CD `.html`** | `DA_CD_PER_CC/` per data | **97** |
| **il resto** | `DA_CD_PER_CC` 224 · `GRAFICA` 34 · `IMMAGINI` 23 · `DESIGN_E_BRIEFING` 20 | |

⚠️ **[M] `HANDOFF` di E: porta 370 file di primo livello e 386 in ricorsivo**: e'
il piu' grande dei tre. **DIFF: 103 su E: contro 97 nel repo** — sei diff esistono
solo su E:.

### GAMBA 3 — `I:\Il mio Drive\Qbeats\` (Drive)

**Primo livello:** 20 cartelle · **56 file SCIOLTI in radice**.

| famiglia | dove | conteggio |
|---|---|---:|
| **canonici** | cartelle dedicate | `BUGS_QBEATS/` **46** · `LIBRO_MASTRO/` **17** · `BOX3_Codice/` **92** · `BOX5_Test/` 30 |
| | ⚠️ **e anche sciolti in radice** | `LIBRO_MASTRO_QBEATS.md` · `BUGS_QBEATS.md` · `SCALETTA_ATOMI_S6_2026-07-10.md` |
| **referti e mandati** | 🚨 **DUE POSTI** | **radice:** MISURE **34** · DIFF **13** · CONGEDO **3** |
| | | **`HANDOFF/`:** MISURE **12** · DIFF **41** · CONGEDO **1** · tot. 186 |
| **contratti CD `.html`** | `DA_CD_PER_CC/` | **95** |
| **il resto** | `DA_CD_PER_CC` 222 · `GRAFICA` 34 · `IMMAGINI` 23 · `test/` 2 | |

⚠️ **[M] Su Drive i canonici stanno in DUE regimi contemporaneamente:** una copia
sciolta in radice **e** le stampe versionate nella cartella dedicata.

---

## §3 · LA DOMANDA CHE DECIDE TUTTO

**(a) Quanti alberi Q-BEATS su Drive** — vedi riga 4 in testa. **Due reali, uno
vuoto.** `FILE X CLAUDE.MD` **non esiste** su Drive, con sonda tarata.

**(b) La sincronizzazione E: → Drive e' attiva?** ⛔ **NO, non oggi.** Vedi riga 2.
Struttura gemella, contenuti divergenti di **184 file** nel solo `HANDOFF`.
Ultimo segno di vita: **7 agosto** (controllo positivo `SCALETTA_v9`), coerente
con `.tmp.driveupload` fermo al **5 agosto**.
⚠️ **[A] Quello che NON posso misurare da qui:** se il client Drive giri adesso
come processo, e su quale cartella sia puntato. **Non misurabile dal mio posto** —
posso solo dire che **il suo effetto non c'e' piu'.**
⚠️ Non posso nemmeno distinguere fra «sync spenta» e «sync attiva ma su un
perimetro ridotto»: i file che oggi stanno su Drive **ce li ho messi io con `cp`**.

**(c) File di controllo** — scelto `MISURE_CC_2026-08-21_A151-STAMPE-E-CHIUSURA-RDELTA.md`,
**perche' l'ha depositato l'altra sessione, non io**.
**[M] Esiste in UN SOLO punto** su tutto `I:`:
`\Il mio Drive\Qbeats\MISURE_CC_2026-08-21_A151-STAMPE-E-CHIUSURA-RDELTA.md`,
14 102 byte, sha256 `ce82c39c98478cc6…`. ⇒ **Nessuna duplicazione.**

**(d) Il clone su `F:`** — **[M] esiste**, e non l'ho toccato:

```
percorso : F:\QBEATS_PREFLIGHT_A61_2026-08-06
branch   : master
HEAD     : 25056b66eda40ad76d91a886ace442b7064ca900
remote   : https://github.com/19Bullfrog78/Q-BEATS  (fetch E push)
```

**[M] 21 commit indietro** rispetto a `e4764f9…`. ✅ **E' un ANTENATO del master
vero** (`merge-base --is-ancestor` exit 0) ⇒ **in catena, non divergente.**
Working tree **pulito**.
🚨 **[A] Il rischio non e' che diverga: e' che sia in catena e sembri sano.** Ha
il push configurato verso il GitHub **vero** e legge canonici fermi al 6 agosto:
chi ci lavora dentro non vede niente di strano.
⚠️ Il congedo del 21/08 sera lo dava a **19** commit indietro; da allora ne sono
entrati **due** (`638b7383` e `e4764f9`). **21 = 19 + 2: la misura ereditata
torna.**

---

## §4 · LE DIVERGENZE — dichiarate, NON risolte

⛔ **Nessuna di queste la sistemo io. Decide Mauro.**

| # | divergenza | misura |
|---|---|---|
| 1 | **La regola «su Drive si copia la struttura del repo» non descrive nessuna gamba** | Drive replica **E:**, non il repo: 19/20 cartelle di E: contro 0 cartelle-chiave del repo |
| 2 | **Referti su Drive in due posti** | radice **50** (34+13+3) · `HANDOFF/` **54** (12+41+1). Gia' nota, entra come misura |
| 3 | **E: → Drive divergono di 184 file** nel solo `HANDOFF` | 370 contro 186 |
| 4 | **DIFF: 103 su E: contro 97 nel repo** | sei diff esistono solo su E: |
| 5 | **Canonici su Drive in due regimi** | copia sciolta in radice **e** stampe versionate in cartella |
| 6 | **`LIBRO_MASTRO/`: 23 su E: contro 17 su Drive** | sei stampe del LIBRO non sono su Drive |
| 7 | **`.Encrypted` sembra un terzo albero** | struttura di cartelle, **zero file** |
| 8 | **`Claude Setup.exe` e `tmp_fix.ps1`** in radice di un repo **pubblico** | non documenti di progetto |
| 9 | **`.tmp.driveupload/` con 790 file dentro l'albero del repo** | ultimo 05/08, non tracciato |

---

## COSA NON HO FATTO — e lo dico

- ⛔ **Non ho spostato, rinominato, copiato o cancellato NULLA** sulle tre
  destinazioni. L'unica scrittura e' questo referto.
- ⛔ **Non sono entrato nel clone `F:`** se non per tre letture git che non
  modificano nulla (`rev-parse`, `remote -v`, `status`).
- ⛔ **Non ho toccato `Qbeats_IN_CD`** (17 file), ne' `INDICE.md`, ne'
  `TD44_REPORT`.
- ⛔ **Non ho scelto quale struttura sia quella giusta.** Non e' una decisione mia.
- ⛔ **Nessun commit. Nessuna memoria.**

---

## IN CODA

1. **🚨 La sincronizzazione E: → Drive e' ferma da meta' agosto** e nessuno se n'era
   accorto, perche' le cartelle combaciano. **184 referti mancano su Drive.**
2. **🚨 Il clone su `F:`** — 21 commit indietro, in catena, con push sul remoto
   vero. Pendenza aperta da sedici giorni.
3. **La regola sulle destinazioni Drive** e' cambiata tre volte in quattro
   mandati, e nessuna delle tre versioni descrive la struttura misurata.
4. **`F1` non parte da quasi quattro mesi**, ultime due esecuzioni fallite.
5. **Restano le pendenze del congedo del 21/08 sera**: BOX3 fermo dal 22/07,
   BOX5 dal 28/07, l'esito di **⟦S5b⟧** mai inciso in nessun canonico.

---

*A159-FINE*
