# MISURE CC — A188 · COMMIT DEI DOCUMENTI 22/08

Da: CC · A: **referee** (+ Mauro)
Mandato: `A188-COMMIT-DOCUMENTI-22-08` · **COMMIT AUTORIZZATO DA MAURO — ESEGUITO**
Completezza: **6 sezioni (§0→§5), ultima riga `A188-FINE-MANDATO` — integro.**
**[M] Modello: intestazione Opus 5, interfaccia Opus 5 — coincidono.**

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato, non rimisurato ·
**[A]** giudizio mio.
⛔ **Zero tocchi a `ios_app/` e `core_engine/`. Nessun merge, nessuna build, nessun rebase.
Nessuna modifica al contenuto dei cinque file: questo mandato ha committato e basta.**

---

# ✅ COMMIT `9edc120eafd2999bf915f974e8b204492e7931f5` — ONLINE

Cinque canonici, `+166 −7`, autore = committer = Mauro, **zero trailer**.
Locale e remoto coincidono, verificati con `ls-remote`. Cinque stampe depositate su `E:`,
tutte **byte-identiche al blob**.

---

## §0 · PRE-VOLO — quattro controlli, tutti superati

| # | controllo | esito |
|---|---|---|
| 1 | HEAD era ancora `4629ee9…9514`? | ✅ **sì** |
| 2 | i cinque sha256 combaciavano con A187 §3-bis? | ✅ **tutti e cinque** |
| 3 | `git status`: cinque modificati, zero in stage, `ios_app` a zero? | ✅ 5 · 0 · 0 (e `core_engine` 0) |
| 4 | nessun altro file entrato nel perimetro? | ✅ **269 non tracciati, tutti fuori** |

**[M] Gli sha256 verificati uno per uno**, non a campione: `6d2446e6…` BOX5 ·
`dead5ebf…` LIBRO · `cd7c7fd5…` BUGS · `aaa47038…` SCALETTA · `de9faecf…` BOX3.

---

## §1 · COMMIT

**[M] Stage costruito con cinque `git add` per NOME, uno per uno** — mai `-A`, mai `.`,
mai glob. **[M] Cancello verificato PRIMA del commit:**
- file in stage: **5**, esattamente i cinque attesi;
- fuori dall'elenco atteso: **0**;
- `ios_app` in stage: **0** · `core_engine` in stage: **0**;
- diffstat dello stage: **`+166 −7`**.

### ⚠️ Un errore mio, e il commit che NON è avvenuto

**[M] Il primo tentativo è FALLITO e non ha prodotto nulla.** Avevo aggiunto un flag
inesistente:
```
git commit -F <msg> --no-verify=false
→ error: option `no-verify' takes no value
```
**[M] Verificato subito: HEAD era ancora `4629ee9`, lo stage intatto a 5 file.** Nessun
commit parziale, nessun hook saltato.
⛔ **[A] Quel flag non andava messo affatto:** stavo cercando di dire «esegui gli hook»,
che è già il comportamento predefinito. Ho aggiunto un'opzione per ottenere ciò che sarebbe
successo da solo, e l'ho scritta male. **La forma giusta era non scrivere niente.**

### Il commit

```
sha       : 9edc120eafd2999bf915f974e8b204492e7931f5
parent    : 4629ee9ec943a1ebb8a16a49164aa457a8b99514
autore    : Mauro Martintoni <di_tutto@icloud.com>
committer : Mauro Martintoni <di_tutto@icloud.com>
data      : 2026-08-23 09:46:57 +0200
trailers  : []
```

**[M] `git show --stat`, verbatim:**
```
 BOX3_QBEATS.md                          |  18 +++++-
 BOX5_QBEATS.md                          | 100 +++++++++++++++++++++++++++++++-
 BUGS_QBEATS.md                          |   5 +-
 HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md |  43 +++++++++++++-
 LIBRO_MASTRO_QBEATS.md                  |   7 ++-
 5 files changed, 166 insertions(+), 7 deletions(-)
```
**[M] Cancello del §1 superato:** file **5** (atteso 5) · inserzioni **166** (atteso 166) ·
delezioni **7** (atteso 7). **[M] `Co-Authored-By` nel messaggio: 0.**

### ⚠️ La data del commit non è la data del contenuto

**[M] Il commit porta `2026-08-23`; i cinque documenti dichiarano `22/08/2026`.** L'orologio
di sistema è passato a ieri-notte fra A187 e A188. **[A] Non l'ho corretto** — il lavoro è
del 22/08, come dicono i mandati, e riscrivere una data di commit sarebbe peggio del
disallineamento. Lo registro perché **è la prima volta in archivio che le due date
divergono**, e ha una conseguenza sui nomi delle stampe (§4).

---

## §2 · PUSH

**[M]** `git push origin master`, verbatim:
```
To https://github.com/19Bullfrog78/Q-BEATS
   4629ee9..9edc120  master -> master
```
**[M] Verifica NON sulla parola di git ma con `ls-remote`:**
```
locale : 9edc120eafd2999bf915f974e8b204492e7931f5
remoto : 9edc120eafd2999bf915f974e8b204492e7931f5
✅ COINCIDONO
```

### CI — detta per NOME, mai «verde» secco

**[M]** Elenco intero delle run, filtro a valle (trappola del falso-zero da `--commit`):

| workflow | esito su `9edc120` |
|---|---|
| **iOS Signed Build** | ✅ **success**, `2026-08-23T07:47:40Z` |
| **F1 — Build Check** | ⛔ **NON PARTITO** (ultima esecuzione 31/07, failure) |
| **Build LinkHut Diagnostic** | ⛔ **NON PARTITO** (ultima esecuzione 22/05) |

⚠️ **[A] «La CI è verde» sarebbe una frase falsa: verde è UN workflow su tre configurati.**
Invariato rispetto a `4629ee9` e a tutti i commit da agosto.

---

## §3 · PROVA CHE ONLINE E DISCO SIANO LO STESSO TESTO

**[M] Metodo dichiarato:** per ciascun file ho estratto il contenuto **dal blob del
commit** (`git show 9edc120:<path>`) e l'ho confrontato **byte-per-byte** con il file su
disco. Per i due file a due facce il confronto è stato ripetuto **dopo aver normalizzato
la faccia** (CRLF del disco → LF), e la differenza di byte è stata verificata **uguale
esattamente al numero di CR** — non «spiegabile», ma *calcolata*.

| file | faccia | blob | disco | esito |
|---|---|---|---|---|
| `BOX5_QBEATS.md` | LF (`-text`) | 70718 B · 0 CR | 70718 B · 0 CR | ✅ **identici byte-per-byte** |
| `LIBRO_MASTRO_QBEATS.md` | **due facce** | 283448 B · 0 CR | 283972 B · **524** CR | ✅ identici dopo normalizzazione — **283972 − 283448 = 524 = i CR** |
| `BUGS_QBEATS.md` | **due facce** | 352481 B · 0 CR | 353694 B · **1213** CR | ✅ identici dopo normalizzazione — **353694 − 352481 = 1213 = i CR** |
| `HANDOFF/SCALETTA_…md` | LF (`-text`) | 69169 B · 0 CR | 69169 B · 0 CR | ✅ **identici byte-per-byte** |
| `BOX3_QBEATS.md` | LF (`-text`) | 90638 B · 0 CR | 90638 B · 0 CR | ✅ **identici byte-per-byte** |

⇒ **[M] Nessun file diverge in modo non spiegato dalle facce.**

---

## §4 · SECONDA GAMBA (R-δ)

**[M] Regola letta alla sua sede prima di depositare** — BOX5, cap. «R-δ — dove vanno i
file», §2 (dove va cosa) e §3 (come si produce la stampa).
⛔ **[M] Per tutti e cinque: estrazione DAL BLOB con `git show`, mai copia dal disco.**
⛔ **Su Drive non ho scritto nulla:** arriva da solo come riflesso di `E:`.

**[M] Convenzione di nome presa dai file REALI già in archivio, non dalla memoria.**
⚠️ **[M] Una correzione alla mia memoria:** avevo agli atti «BOX5 → `BOX5_Test\LUGLIO\`»;
misurato, `BOX5_V29_2026-08-21_4e57870.md` sta nella **radice** di `BOX5_Test`. Depositato lì.

**[M] Nomi verificati liberi prima di scrivere**, con controllo positivo tarato (il v59 di
BUGS è stato trovato ⇒ la sonda vede).

| deposito su `E:\…\FILE X CLAUDE.MD\` | byte | CR | sha256 |
|---|---|---|---|
| `LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v60_2026-08-22_9edc120.md` | 283448 | 0 | `e2c5d022542d69e7d75becb5bc98e684c488433ef2034cc079809952613133cc` |
| `BUGS_QBEATS\BUGS_QBEATS_v60_2026-08-22_9edc120.md` | 352481 | 0 | `2c7958216a2eacab95c41480106a83c706a2a6d9dd6dc3568fb0008419f717b2` |
| `BOX3_Codice\BOX3_V100_2026-08-22_9edc120.md` | 90638 | 0 | `de9faecfaaa59870537d31497eb384a2cd9e7d4c2c30aefa281db712a83ea866` |
| `BOX5_Test\BOX5_V30_2026-08-22_9edc120.md` | 70718 | 0 | `6d2446e6e6681c170554e19f5ce38b16490eda29cd356ab44b626729234100cc` |
| `HANDOFF\SCALETTA_v12_2026-08-22_9edc120.md` | 69169 | 0 | `aaa470383cd9117704a635bc815a6f929b6e9bfbd1690804afae05a59223de11` |

**[M] Tutte e cinque le stampe sono IDENTICHE AL BLOB byte-per-byte**, e tutte a **0 CR** —
come dev'essere per un'estrazione da git.

### ⚠️ Reperto: la convenzione di nome non sa disambiguare due date

**[M] La forma canonica è `<CANONICO>_V<N>_<AAAA-MM-GG>_<sha7>.md`, e in tutti gli esempi
in archivio la data della versione e la data del commit COINCIDONO** — es.
`BUGS_QBEATS_v59_2026-08-22_4629ee9.md`: v59 è datata 22/08 e `4629ee9` è del 22/08.
**[M] Qui divergono per la prima volta:** versione 22/08, commit 23/08.
**[A] Ho scelto `2026-08-22`**, la data che i documenti dichiarano al proprio interno,
perché il nome identifica *la versione* e lo sha7 identifica già *il commit*. **La scelta è
mia, non è coperta da nessuna regola scritta**, e va ratificata o corretta: se il referee
preferisce la data d'estrazione, i cinque nomi vanno rifatti con `2026-08-23`.

---

## §5 · STATO FINALE

**[M]**
```
HEAD locale : 9edc120eafd2999bf915f974e8b204492e7931f5
HEAD remoto : 9edc120eafd2999bf915f974e8b204492e7931f5   (ls-remote)
tracciati modificati : 0
in stage             : 0
ios_app              : 0 righe
core_engine          : 0 righe
non tracciati        : 269
```

**[M] I 269 non tracciati sono ESATTAMENTE quelli di prima del commit** — il conteggio è
invariato fra il pre-volo e adesso, e nessuno è entrato: verificato al cancello dello stage
(zero file fuori dall'elenco dei cinque) e riverificato dopo il commit.
⚠️ **[A] 269, non 257 come dice il congedo A166→A170: la differenza sono i referti di
questa giornata**, che vivono in `HANDOFF/` e restano fuori da git — è il debito noto degli
11 congedi non tracciati, ora peggiorato dai referti A172→A188.

---

## §6 · IL REPERTO CHIESTO DAL MANDATO — le stringhe di controllo che spezzano

Il mandato registra che una delle stringhe obbligatorie che mi ero dato in **A187** risulta
assente anche in un file integro, perché **cade a cavallo di un a capo**.

**[M] Verificato: è la stringa `SENZA \`Co-Authored-By\``**, che nel referto A187 vive
spezzata fra due righe. La sonda `grep -cF` la rende **0** su un file perfettamente intero.

⛔ **[A] È la stessa trappola che ho incontrato tre volte oggi in tre forme diverse:**
1. **A182** — l'ancora della precisazione tecnica, cercata su una riga sola: falso zero.
2. **A185** — «Tre erano stati», due siti in BOX5 di cui uno spezzato: la sonda ne vedeva uno.
3. **A187** — la mia stessa stringa d'integrità, spezzata: falso allarme sul mio referto.

⇒ **[A] Regola per il giro di igiene, da incidere dove morde:** *una stringa di controllo
d'integrità va scelta in modo che non possa spezzare — dentro una riga sola, corta, senza
ritorni a capo — oppure la sonda va eseguita sul testo APPIATTITO.* La forma che ho usato
con successo in A186 e A187 è la seconda: `c.replace("\\r\\n"," ").replace("\\n"," ")` prima
di contare. **Chi sceglie le stringhe le copi da una riga sola del file.**

---

## Cosa NON ho fatto

⛔ Nessun tocco a `ios_app/` né `core_engine/` · nessun merge · nessuna build · nessun
rebase · **nessuna modifica al contenuto dei cinque file** · nessuna scrittura su Drive ·
nessun `git add -A`, `.` o glob · non ho letto il congedo del referee.

---

### Controllo d'integrità di QUESTO file — sul CONTENUTO

⚠️ **Stringhe scelte tutte da una riga sola, che non possono spezzare** — è il reperto §6
applicato a se stesso.

`9edc120eafd2999bf915f974e8b204492e7931f5` · `4629ee9..9edc120` ·
`option` · `283972 − 283448 = 524 = i CR` · `BOX5_V30_2026-08-22_9edc120.md` ·
`verde è UN workflow su tre` · `269` · e il marcatore di fine qui sotto.

---

*A188-FINE — MISURE CC 22/08/2026 COMPLETO*
