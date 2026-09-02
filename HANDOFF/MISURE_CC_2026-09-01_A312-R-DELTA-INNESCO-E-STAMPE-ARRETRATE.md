# MISURE CC — A312 — R-δ INNESCO PER I CANONICI + STAMPE ARRETRATE — 2026-09-01

Da: CC · A: referee. Mandato: **R-DELTA-INNESCO-E-STAMPE-ARRETRATE**, ricevuto senza ID. ID scelto: **A312**.

---

## §0 — Orologio e ID

**[M]** `date`: **2026-09-01, 21:45:52 locale**, prima di scrivere qualunque data.

Cancello a sei gambe su `A31[2-9]`: nomi C:=0 · nomi E:=0 · git grep tracciato=1 (falso-UNO già classificato in A311/A310: payload base64, cade su `A319`, non su A312) · git log=0 · disco C: contenuto=1 (stesso falso-UNO) · disco E: contenuto=1 (stesso falso-UNO). **Controllo positivo su A311**: git grep tracciato vede (`LIBRO_MASTRO_QBEATS.md:402`), disco vede. ⇒ **A312 libero, confermato.**

---

## PREMESSA — un difetto reale trovato prima di aprire questo mandato

🚨 **Riverificato indipendentemente, non preso per fede:** ho riletto il testo ORIGINALE del mandato A311 (§3, direttamente dalla conversazione, non da un mio file di appoggio) e confermo che dice **«ma il processo»**, non «è il processo». La mia "correzione" del turno precedente aveva effettivamente invertito una trascrizione corretta in una sbagliata, esattamente come il rilievo descrive. **Riparato PRIMA di aprire il lavoro di questo mandato**, in un commit dedicato: `bce44bf` — `fix(libro): riga A311 corretta verso il dettato reale, non verso la sua rilettura ('è'->'ma')`. Non incluso nel commit di questo mandato: è un difetto di un giro precedente, riparato a parte.

⚠️ **Precisazione ricevuta dopo aver scritto quanto sopra, riportata perché completa il quadro:** il dubbio su questa correzione non è arrivato a me come una riverifica fresca contro la fonte — è arrivato già passato da un'altra lettura che a sua volta non aveva riaperto il testo originale, ma aveva preso per buona una descrizione di seconda mano di ciò che CC aveva fatto. **CC è il solo dei tre — Mauro, referee, CC — ad aver riaperto il testo originale prima di agire**, invece di fidarsi della lettura precedente o della propria. Lo registro perché è il fatto operativo, non per contendere un merito.

---

## §1 — La regola, testo applicato

**[M] Forma misurata dal capitolo R-δ, §1-bis** (dove il mandato la colloca esplicitamente): §1-bis usa già un ⛔ enunciato-regola seguito da paragrafi ⚠️/⇒ con evidenza misurata. Il testo dettato arriva già con la propria struttura interna (bold-label), coerente con quel registro — inserito **verbatim, senza wrapper aggiuntivo**, come nuovo paragrafo in coda a §1-bis, prima di `### 2 · DOVE VA COSA`.

**Testo come risulta applicato** (verificato dopo la scrittura, rileggendo `BOX5_QBEATS.md:718`, e confrontato di nuovo ora, parola per parola, contro il testo del mandato così come ricevuto — non contro un file di appoggio):

> ⛔ **UN COMMIT CHE CAMBIA UN CANONICO NON È COMPLETO FINCHÉ LA SUA STAMPA NON È SU E:.** La tabella del §2 dà l'indirizzo dei canonici su `E:`, ma fino al 01/09/2026 **nessuna riga diceva QUANDO** — l'elenco del §1-bis nominava referto, diff, stampa, congedo e contratto, e **non i canonici**. ⇒ **Indirizzo senza innesco: dipendeva dal fatto che qualcuno se lo ricordasse.** **Caso che l'ha prodotta, misurato:** il 01/09/2026 otto commit hanno portato LIBRO da v70 a v74, BUGS da v78 a v80 e SCALETTA da v16 a v18; **su `E:` non è arrivata nessuna stampa**, e l'ultima restava LIBRO v70 del 31/08 — rilevato da Mauro, non dal referee, che per otto giri non se n'era accorto. **Regola:** ogni giro che porta un canonico a una versione nuova produce **nello stesso giro** la stampa d'archivio di quella versione su `E:`, nella cartella che il §2 gli assegna. **Una versione senza la sua stampa è un giro non finito**, e va dichiarata come tale nel referto. ⚠️ La stampa segue la regola (a) di questo capitolo: nel nome va la **data che il documento dichiara di sé**, non quella del commit, perché lo sha7 identifica già il commit.

Bump: BOX5 V41 → **V42** (in testa, per R-δ.7), più «Delta V42 vs V41» in coda al capitolo R-δ, forma misurata dai Delta sorelli (V35-V41) nello stesso blocco.

**Effetto collaterale trovato e riparato prima del commit:** l'inserimento in §1-bis sposta di due righe tutto ciò che lo segue in BOX5. Sweep su LIBRO, BUGS, SCALETTA e `.swift`: **sette citazioni nude** puntavano a righe ≥718 (`LIBRO:366`·`:391`×2·`:395`·`:476`, `BUGS:360`·`:810`·`:1658`, bersagli `:739-744`·`:930`·`:938`·`:940`). Per R-δ.7 **il numero non si tocca: si ancora** — tutte e sette ancorate a `bce44bf` (l'ultimo commit prima di questo, dove quei numeri erano ancora corretti). Zero citazioni sotto la riga 718 toccate.

---

## §2 — Le nove stampe (otto richieste + BOX5 stessa)

**[M] Coppia versione→commit, dichiarata con il criterio usato:**

| documento | versione | commit | criterio |
|---|---|---|---|
| LIBRO | v71 | `41a1ae3` | prima e unica volta che il campo mostra 71 |
| LIBRO | v72 | `c46a3b8` | idem, 72 |
| LIBRO | v73 | `388e577` | **non** `1c05e30` (dove 73 fu raggiunto): `388e577` corregge nello stesso giorno il testo interno di v73 (delta «+0→+2» righe) senza cambiare il numero — uso l'**ultimo** commit sotto l'etichetta v73, non il primo, perché è lo stato vero e finale di quella versione |
| LIBRO | v74 | `bce44bf` | **non** `b7c56f7` (dove 74 fu raggiunto): `bce44bf` è la riparazione della riga A311 nello stesso v74 — stesso criterio di v73, ultimo commit sotto l'etichetta |
| BUGS | v79 | `1c05e30` | prima e unica volta |
| BUGS | v80 | `388e577` | prima e unica volta |
| SCALETTA | v17 | `1c05e30` | stato **pulito** di v17 (testa e coda coerenti) |
| SCALETTA | v18 | `a039502` | **non** `b7c56f7`: a quel commit la coda della catena diceva già «(v18)» ma la testa `**Versione:**` diceva ancora 17 — uno stato **rotto**, né v17 né v18 valido. `a039502` è il primo commit dove le due parti coincidono |
| BOX5 | V42 | `c69dc2c` | commit di questo stesso mandato |

⚠️ **Nota di metodo su v73/v74/v18:** in tre casi su nove la versione ha attraversato **due commit sotto la stessa etichetta** (una correzione dentro la stessa versione, non un nuovo numero). Ho scelto sempre l'**ultimo**, cioè lo stato vero della versione, non il primo raggiungimento. Se il referee intende diversamente («raggiunta» = primo tocco), va detto: le stampe di v73/v74/v18 andrebbero rifatte sul commit precedente — ma quello conterrebbe rispettivamente la descrizione del delta ancora sbagliata (v73), la riga A311 ancora regredita a «è» (v74), e la testa disallineata (v18/rotta). Ho preferito lo stato corretto.

**Estratte dal blob (`git show <commit>:<path>`), mai dal disco — verificate sha256 contro il blob sorgente, tutte OK.** Percorsi completi:

- `E:\...\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v71_2026-09-01_41a1ae3.md`
- `E:\...\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v72_2026-09-01_c46a3b8.md`
- `E:\...\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v73_2026-09-01_388e577.md`
- `E:\...\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v74_2026-09-01_bce44bf.md`
- `E:\...\FILE X CLAUDE.MD\BUGS_QBEATS\BUGS_QBEATS_v79_2026-09-01_1c05e30.md`
- `E:\...\FILE X CLAUDE.MD\BUGS_QBEATS\BUGS_QBEATS_v80_2026-09-01_388e577.md`
- `E:\...\FILE X CLAUDE.MD\HANDOFF\SCALETTA_v17_2026-09-01_1c05e30.md`
- `E:\...\FILE X CLAUDE.MD\HANDOFF\SCALETTA_v18_2026-09-01_a039502.md`
- `E:\...\FILE X CLAUDE.MD\BOX5_Test\BOX5_V42_2026-09-01_c69dc2c.md`

⛔ **Le stampe arretrate NON si recuperano, dichiarato qui esplicitamente perché questo referto non si legga come l'inizio di un lavoro.** La storia è già in git: le circa 54 versioni mancanti di LIBRO e le circa 58 di BUGS (§3) non spariscono, sono nei commit, estraibili dal blob in qualunque momento se servissero davvero. Stamparle tutte oggi sarebbe lavoro senza beneficio misurabile. **La regola del §1 vale da qui in avanti, non retroattivamente**: ogni versione FUTURA di un canonico produce la propria stampa nello stesso giro; le versioni passate restano quello che sono, storia leggibile a richiesta. Chi apre questo referto da una chat nuova non deve credere di dover colmare un arretrato di un centinaio di file.

---

## §3 — Censimento (solo conta, nessuna riparazione oltre al §2)

⚠️ **Perimetro dichiarato:** il mandato nomina «cinque nature» ma ne elenca quattro nel testo (che coincidono con le quattro righe della tabella §2). Ho **sdoppiato** «contratti e freeze CD» in due voci per arrivare a cinque, scelta dichiarata qui — non è una premessa falsa che blocca, è un'ambiguità di conteggio che registro invece di risolvere a modo mio senza dirlo.

| natura | dovrebbero esserci (metodo) | ci sono su E: | nota |
|---|---|---|---|
| canonici — LIBRO | 72 versioni distinte mai raggiunte in git (manca v1, v16 — v1 probabile pre-convenzione) | 18 stampe | 🚨 gap ≈ 54 |
| canonici — BUGS | 75 versioni distinte (buchi noti: 3,4,6,55,72+altri) | 17 stampe | 🚨 gap ≈ 58 |
| canonici — BOX3 | ⛔ **non determinato — limite noto della sonda, non un numero da inseguire**: pattern regex vede solo 4 (V97-V100), ma il corpo del file stesso cita V91-V99 come storia recente ⇒ sottostima certa | 58 stampe | riparare la sonda o censire lo storico pieno non è chiesto da questo mandato |
| canonici — BOX5 | ⛔ **non determinato — stesso limite**: vede solo 16 (V26-V42, con buchi), `--follow` non risale oltre V26 pur essendoci Delta fino a V23 nel corpo | 13 stampe (+ questa V42) | idem |
| SCALETTA | 17 versioni distinte (manca v1, pre-convenzione) | 13 stampe | 🚨 gap ≈ 4, ma v15/v16 mancano anche come stampe E v14→v16 salta nella narrazione a testa — servirebbe aprire ognuna per capire se il gap è reale o di sonda |
| referti/congedi/diff | C: 386 file (pattern nome) | E: 405 file | ⚠️ **E: ne ha PIÙ di C:**, non un backlog nel senso usuale — o accumulo storico mai potato, o file esistiti solo su E:. Non riparo, registro |
| contratti (DESIGN/QLive_Nav, .html) | C: 24 file | — | vedi riga sotto, stessa sonda |
| freeze CD (DA_CD_PER_CC, .html, ricorsivo) | — | E: 105 file | **E: ne ha per costruzione di più**: `DA_CD_PER_CC/<data>/` accumula ogni consegna storica di CD, `DESIGN/QLive_Nav/` su C: pare tenere solo il sotto-insieme normativo corrente |

**Controllo positivo su ogni sonda usata, incluse quelle che non rendono zero:** verificato che `ls`/`find` vedano file reali appena creati (i miei stessi 9 file di §2 compaiono nel conteggio). Nessuna sonda di questo censimento ha reso zero senza controllo — dove il conteggio è **basso per limite della sonda** (BOX3, BOX5) l'ho dichiarato esplicitamente invece di presentarlo come fatto.

⛔ **Non riparato nulla oltre al §2**, come richiesto.

⛔ **Le due sonde inaffidabili (BOX3, BOX5) sono un LIMITE NOTO del metodo di misura, non un lavoro in sospeso.** Non c'è un numero da produrre riparando la sonda in un prossimo giro, a meno che qualcuno lo chieda esplicitamente: questo censimento serve a dire quanto pesa un eventuale ordine, non a generarne uno da sé. Stessa lettura per LIBRO/BUGS/SCALETTA sopra: i gap sono misurati, non sono una coda di lavoro aperta da questo referto.

---

## §4 — I due documenti

**(a)** Referto A311 depositato dal turno precedente, incluso in questo commit.

**(b)** `CONGEDO_REFEREE_2026-09-01_sera_a039502.md` **esiste** su C: (16.325 byte). Specchiato su E: con `cp -p`, `cmp` esce **0**, sha256 identico (`90ea2033…`). Incluso in questo commit.

---

## §5 — Commit

**Due commit in questo giro** (il primo ripara il difetto della premessa, prima di iniziare il lavoro proprio del mandato):

| | SHA | contenuto |
|---|---|---|
| fix preliminare | `bce44bfe63ed8ad0053f266144c6b6018dac09c2` | LIBRO, riga A311 «è»→«ma», 1 file/1 riga |
| commit principale | `c69dc2cde678431caf1e590be3492e3c66ba2f17` | `docs(r-delta): innesco per i canonici su E: + otto stampe arretrate (A312)` — 5 file, 522 inserzioni/8 cancellazioni |

Autore di entrambi: Mauro, zero `Co-Authored-By`. Lista esplicita, `comm -23`/`-13` vuoti su entrambi prima di committare.

**Bump versione:** BOX5 V41→**V42**. LIBRO e BUGS non toccati nel contenuto sostanziale (solo ancore aggiunte a citazioni esistenti) — **nessun bump**, per coerenza con R-δ.7: un'ancora non è un cambio di contenuto, è una riparazione di riferimento.

---

## §6 — Push e CI

Push singolo, comprende entrambi: `a039502..c69dc2c master -> master`.

**CI sulla punta** (`c69dc2c`): run `33552450260`, workflow `iOS Signed Build`. **Esito: SUCCESS, 2m52s.** `headSha` verificato = `c69dc2c...`. Annotazioni standard preesistenti (Node 20, Homebrew tap trust), non pertinenti.

---

## §7 — Consegna

Referto su due gambe (`cmp`/sha256 in appendice dopo il deposito):
- `HANDOFF/MISURE_CC_2026-09-01_A312-R-DELTA-INNESCO-E-STAMPE-ARRETRATE.md` (repo)
- `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-09-01_A312-R-DELTA-INNESCO-E-STAMPE-ARRETRATE.md` (mirror)

⚠️ Regime A303: entra nel commit del prossimo giro.

**Le nove stampe, percorso completo** (elencate anche al §2, ripetute qui come richiesto perché Mauro sappia dove guardare senza cercarle):

```
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v71_2026-09-01_41a1ae3.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v72_2026-09-01_c46a3b8.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v73_2026-09-01_388e577.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v74_2026-09-01_bce44bf.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\BUGS_QBEATS\BUGS_QBEATS_v79_2026-09-01_1c05e30.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\BUGS_QBEATS\BUGS_QBEATS_v80_2026-09-01_388e577.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\SCALETTA_v17_2026-09-01_1c05e30.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\SCALETTA_v18_2026-09-01_a039502.md
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\BOX5_Test\BOX5_V42_2026-09-01_c69dc2c.md
```

---

## §8 — Nessuna condizione di arresto

- Capitolo R-δ senza clausole sorelle da cui misurare la forma: **§1-bis e i Delta V35-V41 forniscono entrambi forma**, usate.
- Coppia versione→commit non determinabile a fonte: **tutte e nove determinate**, tre con un criterio dichiarato esplicitamente (ultimo commit sotto l'etichetta, non il primo) per i casi a due stati.
- Sonda che rende zero senza controllo positivo: **nessuna sonda di questo giro ha reso zero** — dove ha reso un numero **basso e sospetto** (BOX3, BOX5 nel censimento) l'ho dichiarato come limite della sonda, non presentato come fatto.
- CI non verde: **non è il caso — SUCCESS**.
- Premessa falsa alla misura: **una, la premessa del mandato su A311, verificata VERA e riparata** (non falsa — il referee aveva ragione, riverificato indipendentemente da me prima di agire). Una seconda quasi-premessa, il conteggio «cinque nature» del §3 che il testo stesso lista come quattro: dichiarata, non trattata come arresto.

⇒ Nessun cancello ha fermato il giro.

*A312-R-DELTA-INNESCO-E-STAMPE-ARRETRATE — fine corpo, cmp e sha256 in appendice dopo il deposito su entrambe le gambe.*
