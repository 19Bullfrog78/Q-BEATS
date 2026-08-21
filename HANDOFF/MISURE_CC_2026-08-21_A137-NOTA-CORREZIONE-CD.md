# MISURE CC — A137, nota di correzione CD alla rev5 + rimando nell'indice

Commit: `f17aa7c3e90ae03bfbaf2edb1322708e7850fb9a`
Autore: Mauro Martintoni <di_tutto@icloud.com> — zero trailer
Data commit: 2026-08-21 08:25:02 +0200
Referto scritto: 2026-08-21, sotto mandato A138.

⚠️ **Anche questo referto nasce dopo il commit**, per la stessa ragione di A136:
il mandato non autorizzava scritture sotto `HANDOFF/`. Lacuna del mandato, non
omissione di CC.

Marcatura: **[M]** rimisurato alla fonte oggi · **[R]** riportato, non
riverificabile oggi · **[A]** giudizio.

---

## 1 · Cosa chiedeva il mandato

Depositare la nota di correzione emessa da CD sulla rev5 — un file che esisteva
**solo su Drive** — e aggiungere una riga nell'indice del README che la leghi
alla rev5, piu' la sostituzione di una frase nella riga della rev5.

⚠️ **La nota NON e' una rev6**: la rev5 resta normativa parola per parola, e la
nota **si legge accanto**. E' la distinzione che l'intero mandato serviva a
incidere: un documento che corregge non e' un documento che sostituisce.

## 2 · Passo per passo, coi comandi

### 2.1 · Collisione ID, prima di partire

**[M]** Sonda a **due forme** (per NOME e per CONTENUTO) su **due supporti**
(repo ed E:), perche' nessuna delle due da sola basta: la sonda per nome e' cieca
ai congedi (che non portano l'ID nel nome), quella per contenuto conta anche le
semplici menzioni.

| ID | nome-repo | cont-repo | nome-E: | cont-E: |
|---|---:|---:|---:|---:|
| A135 | 0 | 1 | 0 | 1 |
| A136 | 0 | 1 | 0 | 1 |
| A137 | 0 | 1 | 0 | 1 |
| A138 | 0 | 0 | 0 | 0 |

⛔ **Controllo positivo** nella forma esatta della sonda, su ID noto-usati:
`A133` → 2 e 2 · `A134` → 1 e 1. La sonda distingue davvero usato da libero.

🚨 **Rilievo emerso qui:** A136 rendeva **0 per nome su entrambi i supporti** —
non aveva alcun referto su disco, solo una menzione dentro il congedo del 20/08.
E' esattamente il buco che A138 e' venuto a chiudere.

### 2.2 · Mount Drive e selezione per byte

Stessa forma di A136: `I:` → `/i/`, con controllo positivo su `Il mio Drive`.

**[M]** In `Qbeats_IN_CD`, target 16 779 byte: **una sola corrispondenza**,
`2026-08-21_QLive-Shows_NOTA-DI-CORREZIONE-rev5__citazioni-e-scostamento.html`.

**[M] Controllo anti-segnaposto:** cercato anche per pattern di nome
(`*NOTA-DI-CORREZIONE*`) per verificare che non esistesse un omonimo con byte
diversi — che avrebbe significato **file in streaming, non scaricato**. Trovato
un solo file, e i suoi byte coincidono col target. Nessun segnaposto.

### 2.3 · Copia e verifica

**[M]** `cmp` exit **0**. sha256 identico fra le due facce:

| file | byte | sha256 sorgente = destinazione |
|---|---:|---|
| nota di correzione | 16 779 | `ae53a6403f029f141ccb4fe34108ff42a8fafc800719bf85c622aeebb831926a` |

⛔ Nulla scritto su `I:`. Originale intatto.

### 2.4 · Che non si rompesse niente

**[M]** `git status --porcelain` sui cinque path: `??` solo per la nota; i
**quattro fogli normativi** silenziosi ⇒ invariati. Confermato con blob-vs-disco:

| foglio | byte | esito |
|---|---:|---|
| rev5 | 79 120 | IDENTICO |
| rev4 | 68 605 | IDENTICO |
| rev3-NORMATIVA | 75 771 | IDENTICO |
| rev2-BUONA | 73 427 | IDENTICO |

⛔ **Controllo positivo** sulla stessa sonda: `HANDOFF/CONGEDO_CC_2026-08-20.md`
ha reso `??` ⇒ la sonda non e' cieca.

### 2.5 · Modifica chirurgica del README

Due operazioni sole, su un file gia' tracciato:

1. **Sostituzione** — nella riga della rev5, `Correzione richiesta a CD.` →
   `**Corretti dalla nota del 21/08, riga sotto.**`
2. **Inserimento** — una riga nuova **subito dopo la rev5 e prima della rev4**.

**[M] Verifica di unicita' PRIMA di toccare:** `grep -c` sulla frase bersaglio →
**1**. Se fosse stata 2, una sostituzione cieca ne avrebbe cambiate due.
L'operazione e' stata eseguita in Python con `assert content.count(target) == 1`:
il controllo e' **dentro** lo strumento, non solo nella testa di chi lo lancia.

**[M] Verifica dopo:** frase vecchia → **0 occorrenze**; frase nuova → **1**.
`git diff` ha mostrato **1 riga modificata, 1 riga aggiunta**, nient'altro.

⚠️ **Trappola di ambiente incontrata e risolta:** `python3` su questa macchina e'
il Python **nativo Windows**, non quello di MSYS ⇒ **non capisce i percorsi
`/c/...`**. Il primo tentativo e' fallito con `FileNotFoundError` su un file che
esisteva. Diagnosticato con un controllo a due forme
(`os.path.exists('/c/...')` → False, `os.path.exists('C:/...')` → True) invece di
indovinare. **Per gli script Python di questo repo servono percorsi `C:/...`.**

## 3 · Commit

**[M]** Stage **file per file**. `git diff --cached --name-only` → esattamente due.

```
f17aa7c3e90ae03bfbaf2edb1322708e7850fb9a
2 files changed, 152 insertions(+), 1 deletion(-)
```

| file | stato | byte (blob a HEAD) | righe | CR | NUL | sha256 blob |
|---|---|---:|---:|---:|---:|---|
| `DESIGN/QLive_Nav/2026-08-21_...citazioni-e-scostamento.html` | nuovo | 16 779 | 150 | 0 | 0 | `ae53a6403f029f141ccb4fe34108ff42a8fafc800719bf85c622aeebb831926a` |
| `DESIGN/QLive_Nav/README.md` | +1/−1 riga | 6 872 | 86 | 0 | 0 | `757d722cb30831dc949319c146c5b053d1cd12cbe09330152c7d42696c1073fe` |

**[M]** Autore `Mauro Martintoni <di_tutto@icloud.com>`, **zero trailer**.

## 4 · Push e CI

```
1f8ddad..f17aa7c  master -> master
```

**[M]** HEAD locale = HEAD remoto = `f17aa7c3e90ae03bfbaf2edb1322708e7850fb9a`.

**[M] Esito CI, rimisurato oggi, per NOME, interrogato con lo sha a 40 caratteri:**

| workflow | run id | stato | esito |
|---|---|---|---|
| `iOS Signed Build` | `32454319236` | completed | **success** |
| `F1 — Build Check` | — | **non partito** | — |

⚠️ Al riferimento originale la run era `in_progress`; **oggi e' `success`**.

⛔ Lo sha **corto** rende `[]` con exit 0 e sembra un fallimento: si interroga
sempre con i **40 caratteri**.

⛔ `F1` **non partito** — mai da push, e questo commit non tocca `ios_app/`.

## 5 · Cosa NON ho fatto, e perche'

- **Non ho toccato la rev5**: la nota la corregge **accanto**, non dentro. Se
  avessi emendato la rev5 avrei distrutto il referente dei ritiri.
- **Non ho creato una rev6**: non e' quello che CD ha emesso.
- **Non ho toccato canonici** ne' `ios_app/`.
- **Non ho riparato il buco di A136** (referto mancante): l'ho **rilevato e
  segnalato**, ma era fuori dal perimetro di A137. Chiuso da A138.
- **Non ho scritto un referto in quel giro**: non autorizzato.

*A137-REFERTO-FINE*
