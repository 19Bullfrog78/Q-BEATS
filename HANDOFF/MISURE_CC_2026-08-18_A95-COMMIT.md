# MISURE CC — A95, CORREZIONE FINALE E COMMIT (doc-only)

Da: CC · A: referee + Mauro · 18/08/2026
Perimetro rispettato: zero righe sotto `ios_app/` · staging esplicito, tre file, nient'altro ·
nessun `--no-verify` · nessun trailer, nessun Co-Authored-By · autore = committer = Mauro (identità
git preesistente, non toccata).

Marcatura: **[M]** misurato ora · **[!]** difetto trovato da me, non nel mandato, corretto prima del
commit.

---

## AGGANCIO — A95 libero

**[M]** Forma a token: `\bA95\b` → **0** in `HANDOFF/` e **0** su E:. Controllo positivo `\bA94\b` →
**2** file su entrambi. Non collide.

---

## ① LA CORREZIONE DISPOSTA — confermata, tre cifre

**[M]** Rilanciato lo scan su corpo **e** colonna fonti delle righe `+` del diff, contro le soglie
del diff stesso: confermato `SCALETTA:329` corretto nel corpo, `SCALETTA:327` ancora rotto nella
colonna fonti della riga 3. Corretto a `:329`. Verificato per hash: nessun'altra parola della riga
toccata.

**[M] Metodologia recepita**: ogni citazione scritta *dentro* un diff va ora verificata contro i
delta *di quel diff*, corpo e fonti — non solo il corpus preesistente. Non incisa in un canonico,
come disposto: resta in questo referto.

---

## ② IL CAMBIAMENTO FUORI MANDATO — ratificato

Preso atto. Nessuna azione mia: la sostituzione di ①-SCALETTA di A94 resta come scritta.

---

## ③ IL COMMIT

### Un terzo difetto, trovato in fase di staging — non nel mandato, non nella cascata di ①

**[!] Prima di applicare avevo riletto solo le righe 1-4 di `LIBRO_MASTRO_QBEATS.md`.** Un blocco
intestazione a righe 5-7 (`**Versione:** 55 (07/08/2026)` / `**Ultima modifica:** …` /
`**Edit author:** …`) non è mai stato visto in nessuno dei mandati precedenti — né A92, né A93, né
la prima stesura di A94 — e per costruzione **non poteva** essere incluso nel diff, quindi
`git apply` lo ha lasciato intatto a v55 mentre il resto del documento saliva a v56.

**[M] È esattamente il difetto che il documento vieta a se stesso**, verbatim, `LIBRO_MASTRO_QBEATS.md:89`:
«**Versione = puntatore.** Se il contenuto di un documento cambia, il suo numero di versione DEVE
cambiare. Un numero non bumpato è peggio di un puntatore rotto: sembra sano, non lo è.»

**Trovato prima dello staging**, corretto sul file live con `Edit` (sostituzione a parità di righe:
3→3, «Ultima modifica» non accumula come l'header SCALETTA, sostituisce come BUGS — verificato il
pattern prima di scrivere): v55→v56, data 07/08→18/08, descrizione sostituita con un riassunto del
round, edit author aggiornato.

### Rigenerazione del diff — per eliminare il rischio di trascrizione a mano

**[M]** Dopo la terza correzione ho scelto di **non** ricomporre a mano una terza volta il corpo del
diff. Ho catturato `git diff` reale sui tre file (post-applicazione + le tre correzioni) e l'ho usato
come corpo autorevole, sostituendo la mia composizione precedente. **Un tentativo di concatenazione
tramite lo strumento di scrittura ha ricollassato le righe di contesto vuote** — lo stesso difetto di
forma già incontrato in A92 — e l'ho rilevato con un confronto byte-per-byte prima di procedere:
corretto concatenando i byte grezzi di `git diff` senza farli transitare per quello strumento.

**[M] Verificato per hash**: il corpo del diff finale è **byte-identico** all'output di
`git diff -- LIBRO_MASTRO_QBEATS.md BUGS_QBEATS.md HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`.

**[M] Verifica a ritroso, la più forte disponibile**: `git apply -R --check` → exit 0; applicato in
reverse su una copia di lavoro, i tre file tornano esattamente ai blob HEAD pre-diff
(`50ca123e…`, `a6bd89dc…`, `73f9f323…`) — confermato con `git hash-object`, non presunto. Working
tree poi ripristinato allo stato corretto (post-fix) dalle copie di backup.

### Applicazione e lettura del reale

**[M]** `git apply` → exit 0. `git status` subito dopo: **esattamente** tre file `M` (LIBRO, BUGS,
SCALETTA), nessun altro file tracciato toccato — il resto sono i consueti `??` di `HANDOFF/`, mai
cambiati in questa sessione. `git diff --stat` finale: **17 inserzioni, 6 cancellazioni** su 3 file —
riconciliato aritmeticamente: 14/3 (contenuto A94) + 3/3 (correzione intestazione LIBRO, riga per
riga) = 17/6.

### Staging e commit

**[M]** `git add` per file, tre comandi separati. `git status` dopo: **esattamente 3** righe `M `,
nient'altro in staging.

**[M] Commit `44fea3e378414c300ffd50fcac527c683740735b`**: autore e committer entrambi «Mauro
Martintoni <di_tutto@icloud.com>» — identità git già configurata nel repo, non toccata da CC.
Messaggio verificato: **zero** occorrenze di «co-authored» o «sha256». Nomina tutti gli otto punti
richiesti dal mandato.

### Push e CI

**[M]** `git push origin master` → `321293e..44fea3e master -> master`, exit 0. HEAD locale =
`git ls-remote origin master` = `44fea3e378414c300ffd50fcac527c683740735b`.

**[M] CI, dichiarato per nome come impone il reperto del 18/08**: workflow **`iOS Signed Build`**,
run `32148440889`, sha `44fea3e378414c300ffd50fcac527c683740735b`, **conclusion: success**. Letta
verbatim da `gh run view --json conclusion`, non dedotta da un exit code.

⚠️ **Non ho verificato F1** («Build Check», l'altro workflow, quello fermo dal 31/07): il mandato non
lo chiedeva e non tocca codice — resta il debito già censito, invariato da A92.

---

## PROPAGAZIONE R-δ

**[M] Le tre stampe canoniche**: estratte con `git show 44fea3e:<path>`, **non copiate dal disco**,
come impone il mandato — la ragione è misurata, non presunta.

### Le due facce, e perché non collidono

LIBRO e BUGS sono `text: unspecified`; SCALETTA è `-text`. Confronto diretto a tre gambe (C: · E: ·
Drive):

| file | esito grezzo | causa |
|---|---|---|
| SCALETTA | **1 impronta, `cmp` 0/0** | `-text`: una faccia sola, ovunque |
| LIBRO | 2 impronte, `cmp` fallito fra C: e {E:,Drive} | due facce: disco CRLF, blob LF |
| BUGS | 2 impronte, `cmp` fallito fra C: e {E:,Drive} | due facce: disco CRLF, blob LF |

**[M] Misurato sui byte** (mai `grep`, per la regola di questo stesso progetto): disco LIBRO CR =
**518**, blob CR = **0**; disco BUGS CR = **1067**, blob CR = **0**. **[M] Applicato il cancello
proprio del progetto — ci si ferma solo se il contenuto SPOGLIATO dei CR diverge**: spogliati,
LIBRO e BUGS rendono sha256 **identici** fra disco e blob su entrambi. **Non è un'anomalia**: è la
normalità autocrlf già documentata da questo stesso progetto, e il conteggio CR da solo non la
distingue da un guasto — da qui la regola di fermarsi solo sul contenuto spogliato.

⇒ **E: e Drive portano la faccia BLOB (LF)**, per costruzione (`git show`), su tutti e tre i file.
`cmp` fra loro due: **0/0** su tutti e tre. Il disco C: porterà CRLF su LIBRO/BUGS al prossimo
checkout che li tocchi — atteso, non un guasto, esattamente come lo `STATO_FINALE_2026-08-07`
aveva previsto per questo stesso file undici giorni fa.

### Le stampe HANDOFF (`-text`, faccia unica)

**[M]** Diff finale (versione corretta, post-rigenerazione) e questo referto: tre gambe, sha256
identico, `cmp` 0/0 su entrambe le coppie.

---

## RIEPILOGO

| # | esito |
|---|---|
| ① | Confermata la cascata sfuggita ad A94: `SCALETTA:327`→`:329` nella colonna fonti. Metodologia (corpo+fonti contro il delta del diff stesso) recepita, non incisa |
| ② | Ratificato senza azione: la sostituzione `[!]` di A94 resta |
| ③ | **Terzo difetto trovato da me**: intestazione LIBRO mai vista in 4 mandati, corretta prima dello staging · diff **rigenerato da `git diff` reale** dopo un secondo incidente di ricollasso spazi, verificato byte-identico e a ritroso (`git apply -R` → blob HEAD esatti) · commit `44fea3e` pulito (autore/committer Mauro, zero trailer, zero sha256) · push riuscito · **CI `iOS Signed Build` run `32148440889` success** |
| R-δ | Tre stampe canoniche estratte da blob via `git show`, non da disco — due facce disco/blob per LIBRO/BUGS, misurate, spiegate, non un'anomalia · diff e referto propagati a tre gambe |

**Stato a chiusura**: HEAD locale = HEAD remoto = `44fea3e378414c300ffd50fcac527c683740735b` · CI
verde nominata · albero pulito sui tracciati · `ios_app/` mai toccato in tutta la sessione A90-A95.

---

*A95-COMMIT-FINE*
