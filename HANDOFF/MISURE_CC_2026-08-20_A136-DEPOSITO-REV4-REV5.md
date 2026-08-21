# MISURE CC — A136, deposito rev4 + rev5 Q-Live›Shows + indice normativo

Commit: `1f8ddad88ba58fecce38b331e3ff848b12a1ae65`
Autore: Mauro Martintoni <di_tutto@icloud.com> — zero trailer
Data commit: 2026-08-20 19:47:14 +0200
Referto scritto: 2026-08-21, sotto mandato A138.

⚠️ **Questo referto nasce un giorno dopo il commit** perche' il mandato A136 non
autorizzava scritture sotto `HANDOFF/`. Non e' un'omissione di CC: e' una lacuna
del mandato, riconosciuta dal referee in A138.

Marcatura: **[M]** rimisurato alla fonte oggi · **[R]** riportato, non
riverificabile oggi · **[A]** giudizio.

---

## 1 · Cosa chiedeva il mandato

Depositare nel repo due fogli di disegno CD che esistevano **su una sola
destinazione** (Google Drive), coi predecessori cestinati, e aggiungere al
`README.md` della cartella un indice normativo che dicesse quale file governa
cosa. Vincoli: zero `ios_app/`, zero canonici, nessuna rinomina, i file si
depositano **come sono**, difetti compresi.

⛔ **Il mandato e' stato riscritto tre volte** perche' le prime due versioni
davano percorsi sorgente **sbagliati**, scritti dal referee senza misurarli:

1. `DESIGN/QLive_Nav/` nel repo — il file non c'era.
2. `I:\Il mio Drive\Qbeats_IN_CD\...ritmo-testata_390x844.html` — nome
   inesistente (quello vero portava un ` (1)` che il mandato non menzionava).
3. La cartella Downloads — i file non erano mai passati di li'.

Mi sono fermato tutte e tre le volte senza copiare nulla.

## 2 · Passo per passo, coi comandi

### 2.1 · Risoluzione del mount Drive

Forma usata: `I:` → `/i/` (convenzione git-bash/MSYS).

```
ls -ld /i/
ls "/i/" | grep -x 'Il mio Drive'
```

**[M] Controllo positivo:** `Il mio Drive` compare alla radice ⇒ il mount e'
quello giusto, non un altro disco per coincidenza. Senza questo controllo, un
`/i/` esistente ma vuoto avrebbe reso uno zero indistinguibile da «file assente».

### 2.2 · Discesa dell'albero, un livello per volta

Radice di `/i/`: `$RECYCLE.BIN`, `.Encrypted`, `.shortcut-targets-by-id`,
`Altri computer`, `Il mio Drive`.

Dentro `Il mio Drive`: presente `Qbeats_IN_CD` — nome VERBATIM, con underscore e
maiuscole come scritte.

⚠️ Esiste anche una cartella `Qbeats` (senza `_IN_CD`): **non e' quella**, e non
l'ho aperta.

### 2.3 · Selezione per BYTE, non per nome

**[M]** Elencata `Qbeats_IN_CD` con `wc -c` su ogni file. Corrispondenze:

| target | esito | file |
|---|---|---|
| 68 605 B (rev4) | **1 sola** | `..._rev4__SUPERSEDE-rev3__navbar-centrata-ritmo-testata_390x844 (1).html` |
| 79 120 B (rev5) | **1 sola** | `..._rev5__SUPERSEDE-rev4-TESTO__ritiri-e-correzioni_390x844.html` |

⛔ **Il file rev4 sulla sorgente portava ` (1)` nel nome** — segno di doppio
caricamento su Drive. E' stato copiato **rinominandolo in copia** al nome
canonico (senza `(1)`): la sorgente non e' stata toccata.

⚠️ **[R] Copie SPURIE, non riverificabili oggi.** In un giro precedente la stessa
cartella conteneva due file ri-salvati da browser: `...navbar-centrata-rit.htm`
(67 812 B, nome troncato, estensione `.htm`) e un rev5 da 79 121 B. Al momento
della copia **non c'erano piu'**. ⛔ **Avevo ipotizzato «sync Drive completato»:
era SBAGLIATO.** Li ha **cestinati CD** dopo che gli e' stato chiesto conto delle
copie spurie — misurato dal referee su Drive, non da me.

### 2.4 · Copia e verifica

```
cp -- "<sorgente>" "<destinazione>"
cmp "<sorgente>" "<destinazione>"
```

**[M]** `cmp` exit **0** su entrambi. sha256 identico fra le due facce:

| file | byte | sha256 sorgente = destinazione |
|---|---:|---|
| rev4 | 68 605 | `0e0122ce5d46ca262b835121a550efccb5305ec6261ade43cff16ea983df3085` |
| rev5 | 79 120 | `ab81dbefcc8b59f8131f9f06c0c84153adc120a7af23d763cd398388febcd3dc` |

⛔ Nulla e' stato scritto su `I:`. Originali intatti, dimensioni invariate.

### 2.5 · Verifica che non si rompesse niente

```
git status --porcelain -- <i quattro path>
```

**[M]** rev4/rev5 resi `??` (non tracciati); rev3-NORMATIVA e rev2-BUONA:
**nessuna riga** ⇒ invariati.

⛔ **Controllo positivo indispensabile:** la stessa sonda su un path **noto
untracked** (`HANDOFF/CONGEDO_CC_2026-08-20.md`) ha reso `?? HANDOFF/...`. Senza
questo, il silenzio su rev2/rev3 sarebbe stato indistinguibile da una sonda cieca.

Doppia conferma con confronto **blob HEAD vs disco**: sha256 identici per
entrambi ⇒ rev3 (75 771 B) e rev2 (73 427 B) davvero invariati.

### 2.6 · Indice nel README

Inserito **subito dopo il paragrafo introduttivo e prima di `## Contratto VIVO`**,
via `awk`, senza toccare altro. Zero sha256 e zero numeri di riga dentro il testo
— lo vieta la regola anti-cascata che il README stesso dichiara.

**[M] Verifica di fedelta':** il blocco e' stato scritto in un file di appoggio,
inserito, e poi **riestratto dal README con `sed -n '7,25p'` e confrontato con
`diff`** contro il file di appoggio → **identico**. Verbatim provato, non asserito.

## 3 · Commit

**[M]** Stage **file per file** (`git add -- <path>`, mai `git add -A`).
`git diff --cached --name-only` ha reso **esattamente tre** percorsi.

```
1f8ddad88ba58fecce38b331e3ff848b12a1ae65
3 files changed, 995 insertions(+)
```

| file | stato | byte (blob) | righe | CR | NUL | sha256 blob |
|---|---|---:|---:|---:|---:|---|
| `DESIGN/QLive_Nav/...rev4...390x844.html` | nuovo | 68 605 | 463 | 0 | 0 | `0e0122ce5d46ca262b835121a550efccb5305ec6261ade43cff16ea983df3085` |
| `DESIGN/QLive_Nav/...rev5...390x844.html` | nuovo | 79 120 | 512 | 0 | 0 | `ab81dbefcc8b59f8131f9f06c0c84153adc120a7af23d763cd398388febcd3dc` |
| `DESIGN/QLive_Nav/README.md` | +20 righe | 6 401 | 66 | 0 | 0 | `ba52e6a56f53eb6c702668490441e2179867851f2f1de877252b46804ca79007` |

⚠️ **Le impronte del README sono quelle AL COMMIT `1f8ddad`**; a HEAD sono diverse
perche' A137 lo ha modificato di nuovo. **Dichiarare sempre a quale commit** — un
sha di README senza il suo commit e' un puntatore che mente.

**[M]** CR=0 su tutti: `DESIGN/** -text` nel `.gitattributes` ⇒ faccia LF, disco
e blob coincidono. Contati sui byte con `tr -cd '\r' | wc -c`, mai con grep.

**[M]** Autore verificato: `Mauro Martintoni <di_tutto@icloud.com>`, corpo del
messaggio **senza alcun trailer**.

## 4 · Push e CI

Push eseguito in un secondo momento, **autorizzato separatamente** (Passo 5).

```
178042b..1f8ddad  master -> master
```

**[M]** HEAD locale = HEAD remoto al momento del push.

⛔ **Prima del push non ho interrogato la CI, di proposito, e l'ho dichiarato:**
un `gh run list` su uno sha mai arrivato al server rende `[]` con exit 0, che si
legge come «fallito» e invece significa «mai partito». **Interrogare un server su
un commit che non ha e' un modo di farsi mentire da una sonda.**

**[M] Esito CI, rimisurato oggi (21/08), per NOME:**

| workflow | run id | stato | esito |
|---|---|---|---|
| `iOS Signed Build` | `32399773355` | completed | **success** |
| `F1 — Build Check` | — | **non partito** | — |

⚠️ Al momento del riferimento originale la run era `in_progress` e fu riportata
come tale, senza dichiarare un esito che non esisteva ancora. **Oggi e' `success`.**

⛔ `F1` e' **non partito**, non «fallito» e non «verde»: in tutta la sua storia
parte solo da `workflow_dispatch` manuale, mai da push.

⛔ **Mai scrivere «CI verde» secco**: in questo progetto significa solo
`iOS Signed Build`.

## 5 · Cosa NON ho fatto, e perche'

- **Non ho pushato nello stesso giro**: il mandato autorizzava COMMIT, non push.
- **Non ho toccato i cinque canonici** ne' `ios_app/`: fuori perimetro.
- **Non ho corretto i due difetti noti** di rev4/rev5 (l'affermazione errata su
  «List view»; lo sforo di un pannello): **si depositano come sono**. Un file di
  CD non si emenda a valle — si supera con una revisione di CD.
- **Non ho rinominato nulla**, incluso il ` (1)` sulla sorgente Drive.
- **Non ho scritto un referto in quel giro**: non era autorizzato. E' il buco che
  A138 chiude.

*A136-REFERTO-FINE*
