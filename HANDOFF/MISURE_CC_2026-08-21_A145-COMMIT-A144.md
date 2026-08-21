# MISURE CC — A145-COMMIT-A144

**ID ricevuto e verificato: `A145-COMMIT-A144`.**
Da: CC · A: referee, + Mauro · 21/08/2026

🔎 **Integrità del mandato: PASSA.** Visti §0 · §1 · §2 · §3 · §4 · §5 e la
chiusura `FINE MANDATO A145`. Nessun taglio.

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ LE DUE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. Commit fatto, pushato, CI verde.** SHA
`a83353c382877037d27b35912f6d3bdda6ee1988` · `iOS Signed Build` → **success**,
run `32481404824` · `F1 — Build Check` → **NON PARTITO**.

**2. ✅ Il foglio di CD è atterrato INTEGRO in git.** Il sha256 del **blob
committato** è identico a quello del file che CD ha consegnato. Non è
un'inferenza dalla copia su disco: è misurato su ciò che sta nel commit.

Nessuna condizione di stop del §5 è scattata.

---

## §0 · L'ID

**[M]** Sonda stretta (perimetro documentale, `*.md`/`*.txt`, binari esclusi,
confine di parola), due supporti:

| ID | NOME repo | CONT repo | NOME E: | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A145** | **0** | **1** | **0** | **1** | ⇒ **LIBERO** |
| A146 | 0 | 0 | 0 | 0 | controllo negativo |
| A142 | 2 | 3 | 2 | 3 | controllo positivo |
| A143 | 0 | 2 | 0 | 2 | (mandato annullato, citato nei referti) |
| A144 | 2 | 3 | 2 | 2 | controllo positivo |

⛔ **Ispezione del contesto** — l'unico hit, identico sui due supporti:

```
HANDOFF/MISURE_CC_2026-08-21_A144-REV6-DEPOSITO-E-BASELINE.md:46:| A145 | 0 | 0 | 0 | 0 | controllo negativo |
```

È la riga del referto A144 che lo citava **come controllo negativo**. Menzione,
non uso. Nessuna collisione.

---

## §1 · LO STATO — verificato prima di toccare l'indice

**[M]** Letto con `git rev-parse HEAD` e `git ls-remote origin master`, **mai**
`rev-parse origin/master`:

```
locale : 981e109477937523fc8fe00c7e6d62f6c2dd8902
remoto : 981e109477937523fc8fe00c7e6d62f6c2dd8902
atteso : 981e109477937523fc8fe00c7e6d62f6c2dd8902
```

**[M] I due blob «prima»** — combaciano con quelli verificati dal referee:

| file | blob a HEAD | atteso |
|---|---|---|
| `DESIGN/QLive_Nav/README.md` | `507404e63a1cd0f6be4d2ca186c7381103de4292` | `507404e…` ✅ |
| `ios_app/…/QLiveShowDetailView.swift` | `ea9aa12d71499c0406f0e72216e18c4979a1f0e9` | `ea9aa12…` ✅ |

**[M] Controprova aggiuntiva, non richiesta:** il diff dei due file rigenerato dal
disco rende sha256
`e6dab581e308c51ae77229315a6c3cf71530cd29573003a93ead74ee76436557` — **identico**
a quello consegnato in A144. Nessuno aveva toccato nulla.

---

## §2 · RIVERIFICA DEL FOGLIO rev6 PRIMA DELLO STAGING

**[M] Rimisurato nel repo**, dove A144 l'aveva depositato:

| grandezza | misurato | atteso | esito |
|---|---:|---:|---|
| byte | **87 570** | 87 570 | ✅ |
| righe | **542** | 542 | ✅ |
| CR | **0** | 0 | ✅ |
| NUL | **0** | 0 | ✅ |
| sha256 | `ceeeb015edd0ebe83d94f928e9e009c43828e5891be39222a4e30c97e409f8e3` | idem | ✅ |

⛔ **CONTROLLO POSITIVO SUGLI ZERI**, perché uno zero non misurato non è un fatto:
la **stessa** sonda `tr -cd` rende **542 LF** sullo stesso file e **548 CR** su
`QLiveShowDetailView.swift`, che è CRLF. La sonda non è cieca.

**[A] È la quarta volta che questo file viene misurato oggi** — da me in A143, dal
referee, da me in A144 dopo il rename, e ora prima dello staging. Quattro misure,
stessa impronta.

---

## §3 · STAGING — TRE FILE, UNO ALLA VOLTA

**[M]** Nessun `git add -A`, nessun `git add .`, nessuna wildcard. Tre comandi
separati, file nominati per esteso. Indice **prima**: vuoto.

**[M] Indice dopo, riletto con `git diff --cached --name-status`:**

```
A   DESIGN/QLive_Nav/2026-08-21_QLive-Shows_rev6__SUPERSEDE-rev5-SU-2-SELETTORI__ancoraggio-Read-only-e-ritiro-4px_390x844.html
M   DESIGN/QLive_Nav/README.md
M   ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift
```

**Esattamente tre, nessun quarto.** Il foglio è entrato come **`A`** (aggiunta):
era untracked e, come avvisava il mandato, **non sarebbe entrato da solo**.

### ⚠️ Un controllo che ho aggiunto: il blob in INDICE, non solo il file su disco

**[A] Il motivo:** fra il file su disco e ciò che finisce nel commit c'è la
normalizzazione degli a-capo. `DESIGN/**` è `-text`, quindi non dovrebbe
avvenire — ma «non dovrebbe» non è una misura, e un foglio di CD alterato in
transito sarebbe il guasto peggiore di questo giro.

**[M]** Letto il blob direttamente dall'indice:

```
blob in indice : 12652452014b99def364a5680e491dd34133a7c4
byte del blob  : 87570
sha256 del blob: ceeeb015edd0ebe83d94f928e9e009c43828e5891be39222a4e30c97e409f8e3
sha256 su disco: ceeeb015edd0ebe83d94f928e9e009c43828e5891be39222a4e30c97e409f8e3
```

✅ **Identici. `-text` ha retto: nessuna normalizzazione.**

### Cosa è rimasto fuori

⛔ **`HANDOFF/` in stage: zero file** (verificato con un conteggio, non a occhio).
⛔ **La ritirata su `I:` NON toccata:** `_RITIRATA-NUMERI__non-usare…html` esiste,
**66 667 byte**, sha `4687df3647caeda9…` — invariata. Non stageata, non copiata,
non cancellata. Resta come atto.

---

## §4 · COMMIT E PUSH

**SHA a 40 caratteri: `a83353c382877037d27b35912f6d3bdda6ee1988`**

**[M] Autore e committer, riletti dal repo dopo il commit:**

```
autore:    Mauro Martintoni <di_tutto@icloud.com>
committer: Mauro Martintoni <di_tutto@icloud.com>
```

✅ **Fissato con `--author` sulla riga di comando. NESSUN `git config` toccato** —
lezione di A140 applicata per la seconda volta.

**[M] Corpo del messaggio, riletto dal repo con `git log -1 --format='%B'`, non
dal ricordo:**

```
Deposito freeze rev6 + indice normativo + ancoraggio baseline del .dhrow

La rev6 supera la rev5 sui DUE soli selettori che nomina — ancoraggio del badge
Read-only (.dhrow) e ritiro del padding 0 4px su .navbar .back. Su tutto il resto
la rev5 resta IN VIGORE, parola per parola: superata in parte, non abolita. La
riga dell'indice normativo e' quella scritta da CD nel pannello 4 del foglio,
riportata verbatim.

La riga di codice non introduce un valore nuovo: e' la STESSA espressione gia' in
uso al livello 1 (QLiveShowsView, scrhead, che porta gia'
HStack(alignment: .firstTextBaseline)), riletta a fonte prima di scrivere. Con lo
stesso ancoraggio sulle due schermate il badge non si muove quando il titolo va a
due righe — prima a spostarlo era il contenuto, perche' l'allineamento .center lo
ricentra sull'altezza del titolo, che a due righe raddoppia. L'esito e' zero
movimento e NON dipende da nessuna delle cifre che CD ha ritirato nella stessa
rev6: si cancellano fra loro.

Il padding 0 4px sul .back prescritto dalla rev4 e' RITIRATO dalla rev6: non si
costruisce, e la domanda che era rimasta aperta si chiude qui.

DEBITO DICHIARATO E NON RIPARATO: readOnlyBadge nel dettaglio e' una seconda
copia della specifica, perche' l'originale in QLiveShowsView e' private. Da oggi
anche la regola di ancoraggio vive in due punti e puo' divergere senza che il
compilatore dica nulla. Segnalato nel commento in loco; la cura e' un atomo suo.

TRASPORTO: il download ha troncato il NOME del foglio (tagliato dentro la parola
ancoraggio) ma non i BYTE. Una sonda per nome rendeva due file, uno RITIRATO da
CD; il nome non discriminava. La verifica e' passata solo perche' CD aveva
dichiarato il PESO, che ha reso una sola corrispondenza, confermata poi da
sha256, righe, CR e NUL. I byte sono l'unico giudice, mai il nome.
```

**[M] Zero trailer**, verificato con grep su
`co-authored|signed-off|generated with|claude|anthropic`: nessun hit.

**[M] File del commit:** i tre previsti, `+576 / −2`, col foglio in
`create mode 100644`.

**[M] Push:** `981e109..a83353c  master -> master`. HEAD remoto dopo il push =
`a83353c382877037d27b35912f6d3bdda6ee1988`, **combacia col locale**.

### ✅ IL FOGLIO È ATTERRATO INTEGRO — misurato sul blob COMMITTATO

**[A] Questo è il controllo che il mandato chiede in testata, ed è quello che
conta davvero:** non «la copia su disco è giusta», ma «ciò che è finito in git è
il file di CD».

**[M]** Letto con `git show HEAD:<path>`, cioè dal commit:

| grandezza | dal blob a HEAD | atteso |
|---|---:|---:|
| byte | **87 570** | 87 570 |
| righe | **542** | 542 |
| CR | **0** | 0 |
| sha256 | `ceeeb015edd0ebe83d94f928e9e009c43828e5891be39222a4e30c97e409f8e3` | identico |

⇒ **Il file che CD ha consegnato e il file che sta nel repo sono lo stesso file.**

---

## §4-bis · CI — CHIAMATA PER NOME

**[M]**

| workflow | run id | sha (40) | evento | esito |
|---|---|---|---|---|
| `iOS Signed Build` | `32481404824` | `a83353c382877037d27b35912f6d3bdda6ee1988` | `push` | **success** |
| `F1 — Build Check (zero errors, zero warnings)` | (ID `266323994`) | — | — | **NON PARTITO** |

⛔ **F1 non è «fallito» e non è «verde»: è NON PARTITO.** Interrogato per **ID**:
rende le sole quattro run storiche (25/04 e 31/07), tutte `workflow_dispatch`,
**nessuna per questo sha**.

⛔ **Non ho interrogato la CI prima che la run fosse sul server.** Prima query: la
run esisteva già come `in_progress`. L'ho attesa.

⛔ **Non ho usato `gh run watch | tail`.** Attesa con un until-loop su
`gh run view --json status` in processo separato, esito letto a `completed`, poi
**riconfermato con una query indipendente** per sha pieno.

### [M] I due falsi zero, riprodotti dal vivo per tarare le sonde

**(1) Nome abbreviato del workflow:**
```
gh run list --workflow "F1 — Build Check"
  → could not find any workflows named F1 — Build Check
```

**(2) SHA corto in `--commit`:**
```
gh run list --commit a83353c    → []           (exit 0 — FALSO ZERO)
gh run list --commit a83353c38…  → la run      (sha a 40)
```

**Controllo positivo della sonda `--commit`:** interrogata su uno sha noto-usato
(`981e109…`, il commit di A142) rende la sua run `32477532415` **success**. La
sonda vede.

---

## §5 · CONSEGNA

**[M] Verificato che i file esistono dopo la scrittura.**

| gamba | percorso |
|---|---|
| repo | `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\` |
| mirror `E:` | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` |

Un file per gamba: `MISURE_CC_2026-08-21_A145-COMMIT-A144.md`. **Nessun diff
allegato**: A145 non ha prodotto un diff proprio, ha eseguito quello già
ratificato in A144 — che resta consegnato lì.

### Le facce misurate — sono tre, diverse

| oggetto | faccia | perché |
|---|---|---|
| `DESIGN/QLive_Nav/**` (foglio rev6, README) | **LF, disco = blob** | `DESIGN/** -text` |
| `HANDOFF/**` (questo referto) | **LF, disco = blob** | `HANDOFF/** -text` |
| `ios_app/**` (il file Swift) | **CRLF su disco, LF nel blob** | non coperto ⇒ `core.autocrlf` |

⚠️ **R-δ: due gambe su tre.** Drive non autorizzato in scrittura ⇒ **scritto, non
consegnato**. La cartella `E:` **non è sincronizzata** verso Drive (misurato in
A140: il ramo `Il mio Drive/Qbeats/HANDOFF/` è fermo al 7 agosto).

---

## COSA NON HO FATTO — e lo dico

- ⛔ Non ho stageato i file di A144 in `HANDOFF/`: zero, verificato con conteggio.
- ⛔ Non ho toccato, copiato o cancellato la ritirata su `I:`.
- ⛔ **Nessun `git config`.** Autore fissato con `--author`.
- ⛔ Non ho aggiunto trailer, firme o riferimenti a strumenti.
- ⛔ Non ho toccato nulla oltre i tre file nominati.

---

## IN CODA

1. **Il collaudo device di A144** — il badge «Read-only» fermo con il titolo a due
   righe. La verifica è stata **statica**; `iOS Signed Build` verde **non è un
   collaudo**.
2. **[R] A139 è 7/7 su iPhone: resta l'iPad.** ⚠️ Quell'esito **vive solo in
   chat** — non è in BUGS né in LIBRO. Per la regola «ratificato ≠ inciso», finché
   non atterra in un canonico non esiste per chi arriva dopo. **Segnalato per la
   terza volta.**
3. **Il debito dell'ancoraggio in due punti** (`readOnlyBadge` seconda copia +
   `.firstTextBaseline` duplicato) — dichiarato nel commit e nel commento in loco,
   **non riparato**: è un atomo suo.
4. **La collocazione della riga rev6 nell'indice** — l'ho messa prima del catch-all
   `| gli altri |`, leggendo «in coda» come «ultima fra le righe di file
   specifici». **Ora è committata**: se il referee la vuole dopo, è una riga in un
   giro doc.
5. **Il §Workflow punto 4 di BUGS** (formato del messaggio di commit) — segnalato
   in A141 e A142, ancora da sanare.

---

*A145-FINE*
