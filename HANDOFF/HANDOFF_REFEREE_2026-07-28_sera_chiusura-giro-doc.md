# HANDOFF REFEREE — 2026-07-28 sera — chiusura giro doc

Scritto da CC. Destinatario: la prossima sessione referee, che legge questo file
come fonte. Nessun canonico è stato toccato per produrlo; il file è **untracked**,
vive in `HANDOFF/`.

## R0 — convenzione, e come leggere i numeri qui dentro

**[V]** = misurato da CC a fonte, in questa sessione, su questa macchina.
**[R]** = riferito da altri, non verificabile da qui.

⚠️ **Il referee non vede alcun disco.** Tutto ciò che qui è [V] per CC resta [R]
per chi legge, finché non lo rimisura per la propria via. Un [V] non si trasferisce:
si ricostruisce. Non appiattire le due marche.

**Notazione dei numeri.** Ogni numero porta unità, faccia e notazione:
`byte(blob)` vs `byte(disco)` · `righe(terminatori, wc -l)` · `CR` contati con
`tr -cd '\r' | wc -c`, mai con `grep`. Dove un conteggio è **0**, accanto c'è il
suo **controllo positivo nella forma esatta** — uno zero senza controllo positivo
non è una misura, è un'assenza di prova.

**Due facce.** LIBRO e BUGS sono a due facce (disco CRLF, blob LF): per loro
`byte(disco) ≠ byte(blob)`, e la differenza è esattamente il numero di CR.
BOX3, BOX5, la SCALETTA e la Costituzione sono a faccia unica LF (`-text` in
`.gitattributes` per i primi tre). Dichiarare SEMPRE da quale faccia viene
un'impronta.

---

## R1 — Impronte dei canonici a HEAD `c3caa58c2b9f84e413c4571ff415e03759d73b0d`

Tutte [V], misurate ora. La **versione dichiarata** è letta dal blob (`git show`),
non dedotta dal nome del file.

### LIBRO_MASTRO_QBEATS.md — **DUE FACCE**
- versione dichiarata (blob, r.5): `**Versione:** 43 (28/07/2026)`
- OID blob: `a15beefb2ed26556766da82707330c010754b812`
- **blob** : sha256 `17dd0bc4c1663493a3e64864f59c69dd397c569179a232e3d5cbdbcaee1cea08` · 162712 byte(blob) · 455 righe(terminatori) · **CR(blob) = 0**
- **disco**: sha256 `734c01585e4985de5fba5453940763d25383fc8f8fea8b6834b0bebf14355817` · 163167 byte(disco) · 455 righe(terminatori) · **CR(disco) = 455**
- invariante: 163167 − 162712 = **455** = i CR. `CR(disco) == righe(disco)`.

### BUGS_QBEATS.md — **DUE FACCE**
- versione dichiarata (blob, r.3): `**Versione:** 44`
- OID blob: `f71ea7e31987282b4bed71ab2d958f0a568414b7`
- **blob** : sha256 `bef02dd68e4b411dac4e17227eab929b8553732a61065833ac0d683a0010095e` · 207903 byte(blob) · 911 righe(terminatori) · **CR(blob) = 0**
- **disco**: sha256 `74fc8057f82cdc8c65009b7bd8e47330411639d5748cc211240eec4fc9ea0773` · 208814 byte(disco) · 911 righe(terminatori) · **CR(disco) = 911**
- invariante: 208814 − 207903 = **911** = i CR. `CR(disco) == righe(disco)`.

### BOX3_QBEATS.md — faccia unica LF
- versione dichiarata (blob, r.1): `BOX3 V99 — 2026-07-22 (AUTOPORTANTE)`
- OID blob: `490d6d9b38c355dc53ddc9b31431f9a858f2b342`
- sha256 `c728baccb7823f7f20d4544b72130147e7f72fc40104887f0da3fcf24d29fb3c` · 89457 byte (identici su blob e disco) · 803 righe(terminatori) · **CR = 0 su entrambe le facce**
- ⚠️ Il campo `HEAD=origin=bfa07eb` nell'intestazione di BOX3 è **stale by-design**
  (lo dichiara BOX3 stesso): cita l'HEAD al momento della scrittura, non si aggiorna.
  Chi ha bisogno dell'HEAD vero lo legge con `git log -1`.

### BOX5_QBEATS.md — faccia unica LF
- versione dichiarata (blob, r.2): `**Versione:** V28 — 28/07/2026`
- OID blob: `21b23d621ac224c759b53d813196058483e3b056`
- sha256 `cf425ff0d576910c9caa2899cad232e0c8447f605d240021262608aed184ff5b` · 57158 byte (identici su blob e disco) · 596 righe(terminatori) · **CR = 0 su entrambe le facce**

### HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md — faccia unica LF
- versione dichiarata (blob, r.3): `**Versione:** 3 (28/07/2026) · **Ratificata dal referee:** 13/07/2026 (v1) · **⟦NODO A⟧ CHIUSO device 17/07** (v2) · **sdoppiamento ⟦S4L⟧ in tre atomi 28/07** (v3)`
- OID blob: `533ea5622d7db860f598147b41653ac6de501ce0`
- sha256 `700d7caa7c20756e22c44665851203fd0e1fa279ccddcc37fa61cab5549c0e14` · 35661 byte (identici su blob e disco) · 333 righe(terminatori) · **CR = 0 su entrambe le facce**
- ⚠️ **NON è in root**: sta in `HANDOFF/`. Il path completo è parte dell'indirizzo.
  Misurato: `git ls-tree <HEAD> --name-only | grep -i SCALETTA` rende **0 righe**;
  `git ls-tree -r` ne rende **1**. Controllo positivo stessa forma: `BOX5_QBEATS.md`
  in root rende **1**.

### FILE.MD/QBEATS_SYSTEM_PROMPT_V5_21_06_2026.md — **È TRACCIATO**, faccia unica LF
- versione dichiarata (blob, r.2): `**Versione:** V5 — 21/06/2026`
- OID blob: `87a7919d661fe58ff259b61be0ad6bbb9967ccc9`
- sha256 `e4b3b26bd18ff9d78f22500089b31b6e065067db93370ad7afa7a20d12dea6b1` · 5812 byte (identici su blob e disco) · 101 righe(terminatori) · **CR = 0 su entrambe le facce**
- ⚠️ **NON è in root**: sta in `FILE.MD/`. Il prompt che ha generato questo handoff
  ipotizzava che potesse non essere tracciato: lo è. Misurato con
  `git ls-tree -r <HEAD> --name-only | grep -i QBEATS_SYSTEM_PROMPT` = **3 righe**
  (V5 in `FILE.MD/` + V3 e V4 in `ARCHIVIO.MD/`, storici).

**Controlli positivi per gli zero di questa sezione.** I `CR = 0` sui blob non
sono un fallimento dello strumento: lo stesso comando, nella stessa forma, rende
**455** su `LIBRO_MASTRO_QBEATS.md` e **911** su `BUGS_QBEATS.md` sul disco.
Il comando sa contare i CR; dove rende 0, i CR non ci sono.

---

## R2 — Stato, tutto [V]

### Git
- **HEAD** = `c3caa58c2b9f84e413c4571ff415e03759d73b0d`
- **origin/master** = `c3caa58c2b9f84e413c4571ff415e03759d73b0d` — coincidono
- **branch** = `master`
- `git status --porcelain -uno` verbatim:

```
```
  *(zero righe: nessun file tracciato modificato)*
  **Controllo positivo, stessa forma:** `git status --porcelain` nudo rende **53
  righe**, tutte `??` untracked in `HANDOFF/` (verbali e diff di consegna). Il
  comando funziona; lo zero di `-uno` è un'assenza vera.
  ⚠️ Formulazione: si dice «nessun file TRACCIATO modificato», **non** «working
  tree pulito» — l'ambito va dichiarato, gli untracked ci sono.

### I quattro commit del 28/07, in ordine cronologico
Tutti con autore e committer `Mauro Martintoni <di_tutto@icloud.com>`, zero
`Co-Authored-By`, scopo singolo.

| # | sha40 | ora | subject verbatim | file | diffstat |
|---|---|---|---|---|---|
| 1 | `4b55686c04e3bd14ccf06c31b5e89e74a38341ab` | 13:37:36 | `BUGS_QBEATS.md: v44 — tab-reset chiuso by-design + 2 ticket nuovi + angolo del riordino` | `BUGS_QBEATS.md` | 41+/12− |
| 2 | `0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3` | 18:27:28 | `BOX5 V28 — capitolo Q-Live > Shows` | `BOX5_QBEATS.md` | 123+/1− |
| 3 | `8289944dd98b3372a422e5c3481831b3fc727ca5` | 19:59:48 | `SCALETTA v3 — sdoppiamento S4L in tre atomi` | `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 162+/12− |
| 4 | `c3caa58c2b9f84e413c4571ff415e03759d73b0d` | 20:52:08 | `LIBRO v43 — ratifica sdoppiamento S4L in tre atomi` | `LIBRO_MASTRO_QBEATS.md` | 4+/2− |

### CI di ciascuno, letta a fonte con sha a 40 caratteri

| commit | run | conclusion | headSha coincide |
|---|---|---|---|
| `4b55686c04e3bd14ccf06c31b5e89e74a38341ab` | `30355563451` | **success** | sì |
| `0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3` | `30378358163` | **success** | sì |
| `8289944dd98b3372a422e5c3481831b3fc727ca5` | `30385438701` | **success** | sì |
| `c3caa58c2b9f84e413c4571ff415e03759d73b0d` | `30389422371` | **success** | sì |

Workflow: `iOS Signed Build` per tutte e quattro.
**Controllo negativo, stessa forma:** `gh run list --commit 0000…0000` rende `[]`.
⚠️ Trappola nota, agli atti: `gh run list --commit` con sha **corto** rende `[]`
exit 0 — un falso-zero. Usare sempre i 40 caratteri. Un `[]` va inoltre distinto
da un ritardo di registrazione: nel giro LIBRO v43 la prima interrogazione ha reso
`[]` e la run è comparsa poco dopo — l'ho isolato col controllo positivo sulla
stessa notazione applicata al commit precedente, che rispediva la sua run.

### Ultimo commit che tocca `ios_app/`
`ee31281b03a4898bfbccc29bd558cbb68f5e23e1` · 2026-07-23 ·
`FIX-PILL: la pill Q-Live in Q-Stage naviga davvero (TD-qstage-pill-qlive-morta)`

**Prova che da lì non si è più toccato codice:**
`git diff --stat ee31281…..HEAD -- ios_app/` rende **output vuoto**.
- *guardia di esistenza* (una directory assente renderebbe anch'essa vuoto):
  `git ls-tree -d HEAD ios_app/` rende due sottoalberi, `ios_app/QBeats` e
  `ios_app/QBeatsTests`. La directory esiste.
- *controllo positivo, stessa forma*: `git diff --stat 6ded4ab…..ee31281… -- ios_app/`
  rende 3 file / 19+ / 5− . Il meccanismo funziona; il vuoto è un'assenza vera.
- **Zero codice dal 23/07.** Il giro del 28/07 è interamente doc.

### Stampe E: scritte oggi

| stampa | path | sha256 | misura |
|---|---|---|---|
| `BOX5_V28_2026-07-28_0a6ebaf.md` | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\BOX5_Test\LUGLIO\` | `cf425ff0d576910c9caa2899cad232e0c8447f605d240021262608aed184ff5b` | 57158 byte(disco) · 596 righe(term) · CR 0 |
| `LIBRO_MASTRO_QBEATS_V43_2026-07-28_c3caa58.md` | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\LIBRO_MASTRO\` | `17dd0bc4c1663493a3e64864f59c69dd397c569179a232e3d5cbdbcaee1cea08` | 162712 byte(disco) · 455 righe(term) · CR 0 |

Entrambe estratte **dal blob** (`git show <sha40>:<path>`), mai copiate dal file
di lavoro; entrambe verificate: impronta della stampa **identica** a quella del
blob al commit introduttivo. Il commit introduttivo è stato verificato **unico**
in ciascun caso (un solo commit nella storia del file rende quella versione).

⚠️ **Le due cartelle NON hanno la stessa struttura, e non è un errore: è lo stato
attuale del disco.** `BOX5_Test\` è stata riorganizzata in sottocartelle mensili
(`APRILE`/`MAGGIO`/`GIUGNO`/`LUGLIO`) il 28/07 verso le 18:43 — le stampe BOX5
vivono ora in `LUGLIO\`. `LIBRO_MASTRO\` **non** è stata riorganizzata: è piatta,
e V43 sta accanto a V39-V42. Ho collocato ciascuna stampa accanto ai propri simili
per non creare un secondo standard. Archivio precedente intatto in entrambe:
mtime invariati.

### ⚠️ I due mirror a NOME FISSO di LIBRO su E: — solo misura, NON toccati

| path | sha256 | misura |
|---|---|---|
| `E:\…\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS.md` | `e096cbc63b069074d73c7064ff762a64a29718abbdcfbfe6ce295aab45e86922` | 141762 byte(disco) · 444 righe(term) · CR 0 |
| `E:\…\FILE X CLAUDE.MD\CC MEMORIA\LIBRO_MASTRO_QBEATS.md` | `e096cbc63b069074d73c7064ff762a64a29718abbdcfbfe6ce295aab45e86922` | 141762 byte(disco) · 444 righe(term) · CR 0 |

**A quale versione corrispondono — confronto per CONTENUTO contro i blob:**
- blob v41 (`8fa50189b13f49ba3b291510f7d1a388d75b5909`) → `e096cbc6…45e86922`, 141762 byte, 444 righe
- blob v42 (`8926c2af…`) → `06587362…f447a28a`
- blob v43 (`c3caa58c…`) → `17dd0bc4…aee1cea08`

**Entrambi i mirror = blob v41.** Erano indietro di una versione stamattina, ora
lo sono di **due**. Non aggiornati e non cancellati in questo giro: nessun prompt
lo autorizzava. Il parere del referee uscente su cosa farne è nella coda aperta,
punto (b).

---

## R3 — Testo del referee uscente, trascritto VERBATIM

> «GIRO DOC DEL 28/07 — CHIUSO. Quattro atomi di documento, tutti committati
> con CI verde e propagati: BOX5 V28 (capitolo Q-Live›Shows) · B3-bis (due
> rettifiche §7 sullo stesso capitolo) · SCALETTA v3 (sdoppiamento ⟦S4L⟧ in
> tre atomi) · LIBRO v43 (ratifica dello sdoppiamento). Zero codice toccato.
>
> DECISIONE PRINCIPALE, ratificata da Mauro e incisa in LIBRO v43: l'etichetta
> ⟦S4L⟧ portava due contratti opposti. È stata sdoppiata in tre atomi con
> ordine obbligatorio — ⟦S4K⟧ congedo tastiera → ⟦S4R⟧ launcher (iniezione
> setlist, kill del phantom makeDefault, vincolo ObservableObject annidato,
> emendamento invariante Nodo A, proprietà del runner) → ⟦S4L⟧ prima
> scrittura sui dati utente (Remove from Q-Live + menu «···»). La regola di
> rilettura delle citazioni di «S4L» anteriori al 28/07 vive in LIBRO v43 e
> si applica PER OGGETTO, non per parola: le sei enumerazioni d'ordine di
> BOX3 si leggono con quella regola, NON si riscrivono.
>
> PROSSIMO PASSO: ⟦S4K⟧, il congedo tastiera. È CODICE, ed è il primo dal
> 23/07. Il contratto completo (sette punti numerati più due divieti) vive in
> BOX5 V28, capitolo «Q-Live › Shows», § «Congedo tastiera» — la scheda
> d'atomo in SCALETTA v3 lo indirizza, non lo duplica. A HEAD non esiste una
> riga di quel congedo: misura M1 del 28/07, cinque pattern a zero su 19
> file. NODO DA SCIOGLIERE PRIMA DI EMETTERE IL PROMPT: il contratto CD della
> tastiera contiene una ventina di valori colore, ma buona parte sono la
> grafica del documento stesso (riquadri rossi/verdi degli esempi
> giusto-sbagliato), non token dell'app. Vanno separati per selettore CSS
> prima di dirli a CC, altrimenti finisce nell'app il rosso di un esempio.
> Il catalogo token NON è inciso in BOX5 (va in V29): l'atomo ⟦S4K⟧ prende i
> valori dalla fonte CD citandoli per file e riga, e li registra come debito
> per V29.
>
> QUATTRO ERRORI DEL REFEREE USCENTE, tutti presi da CC, tutti agli atti
> perché la prossima sessione non li ripeta: (1) path sbagliato nel prompt B4
> — la SCALETTA sta in HANDOFF/, non in root; (2) sha256 sbagliato del
> referto M1 nel prompt B4 — la coda citata non era un suffisso del digest
> reale; (3) motivazione inventata nel prompt B4 — «il popup di conferma apre
> sopra una tastiera senza via d'uscita» è FALSA, negata da LIBRO r.311 e
> BOX5 r.390 che dicono entrambi «nessuna collisione col congedo tastiera»;
> la dipendenza ⟦S4K⟧→⟦S4L⟧ regge sulla ragione vera, LIBRO r.312; (4)
> descrizione imprecisa nel prompt B6 — le sei enumerazioni BOX3 non portano
> una forma letterale unica, ne portano tre diverse. LEZIONE: il referee non
> vede i dischi; ogni fatto su git, su E: o sul filesystem che il referee
> scrive dentro un prompt è [R] e va misurato da CC prima di essere eseguito.
> Un'istruzione imprecisa eseguita alla lettera produce un documento falso.
>
> CORREZIONE DI PROCESSO ADOTTATA OGGI: quando il referee ratifica, il testo
> della ratifica va INCOLLATO VERBATIM dentro il prompt che arriva a CC, mai
> riassunto a parole da chi fa da tramite. Nel giro B4 la ratifica esisteva ma
> non è arrivata a CC, che ha giustamente trattato l'OK di Mauro come un
> cancello solo e l'ha messo agli atti. I due cancelli devono restare visibili
> anche a chi non ha la chat del referee davanti.
>
> CODA APERTA, nessuna voce bloccante, tutte rinviate per proporzione:
> (a) LIBRO — tre rettifiche minori da fare in un giro solo: il payload
>     2026-07-27_BOX5-V28__Token-Colore-PAYLOAD.md punta a V28 ma il suo
>     bersaglio è V29; la citazione `project.yml:14` di LIBRO r.304 è
>     incompleta nel path (il file sta in ios_app/) e porta un «iOS 16.0»
>     senza fonte, da declassare a [R]; manca un ticket sui tre file omonimi
>     2026-07-27_QL-SHOWS-01-10__RIEMISSIONE.html, di cui uno divergente.
> (b) I due mirror a nome fisso di LIBRO su E:, fermi a v41. Parere del
>     referee: vanno CANCELLATI, non aggiornati — le stampe per-versione
>     fanno già il lavoro e non possono mentire, un file a nome fisso mente
>     appena invecchia. Decisione di Mauro, atomo a sé.
> (c) BOX5 V29 — catalogo token colore, da misurare contro il codice a HEAD
>     (BUGS v44, ticket TD-design-system-non-ancorato). Dopo ⟦S4L⟧, quando i
>     file di UI/QLive/ sono stabili.
> (d) Regime della SCALETTA: tracciata ma fuori dal regime root+in-place.
>     Atomo doc a sé, agli atti da luglio.
> (e) Pendenza BOX5 V28 punto 9: disponibilità di
>     scrollDismissesKeyboard(.interactively) a partire da iOS 16.0, [R], si
>     chiude con l'annotazione @available letta nell'SDK usato dalla CI o con
>     URL Apple. Non blocca ⟦S4K⟧: «Done» e «×» non dipendono da quella API.
> (f) Pillola ▶: il canonico la dichiara inseparabile da Remove, ma non ha
>     atomo assegnato in nessuna delle dodici schede della SCALETTA v3.
>     Registrata come pendenza, nessuna fonte la assegna.»

---

## R4 — Note di misura di CC sul testo R3

Il testo di R3 è trascritto **verbatim, non corretto**. Dove la misura dice altro,
la misura sta qui accanto, non dentro la citazione.

**① «Quattro atomi … tutti committati» — quattro ATOMI, ma tre COMMIT.** [V]
Misurato: `BOX5_QBEATS.md` è stato toccato **una volta sola** il 28/07 (commit
`0a6ebaf`). B3 (capitolo) e B3-bis (le due rettifiche §7) sono **nello stesso
commit**: la seconda è stata applicata al file prima che il primo venisse
committato. I quattro atomi di lavoro mappano quindi su tre commit —
`0a6ebaf` (B3+B3-bis), `8289944` (SCALETTA v3), `c3caa58` (LIBRO v43).

**② Il quarto commit del 28/07 non è nell'elenco di R3.** [V] È
`4b55686` (BUGS v44, ore 13:37), che precede l'apertura di questa sessione: il
lavoro di oggi è partito da lì. Chi conta «quattro commit» e li mappa sui «quattro
atomi» di R3 sbaglia l'accoppiamento. Nessuna delle due affermazioni è falsa presa
per sé: sono due conteggi di cose diverse.

**③ Sulla lezione di R3 — vale anche al contrario.** Questo handoff è scritto da
CC, che i dischi li vede; ma il referee che lo legge no. Ogni impronta qui è [V]
per me e resta [R] per chi legge finché non la rimisura. Il modo di rimisurarla è
scritto accanto a ciascuna: `git show <sha40>:<path>` per i blob, `sha256sum` per
il disco, `gh run list --commit <sha40>` per la CI.

---

## R5 — Ripartenza: cosa leggere per primo

1. Questo file, sezione R1 — e **rimisurare** almeno una impronta per convincersi
   che l'albero è quello.
2. `LIBRO_MASTRO_QBEATS.md` Sez.2, **ultima riga** (`2026-07-28`, SDOPPIAMENTO
   ⟦S4L⟧ IN TRE ATOMI): porta la ratifica e la regola di rilettura.
3. `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` sez. B, le tre schede ⟦S4K⟧ / ⟦S4R⟧ /
   ⟦S4L⟧: il dettaglio operativo, le pendenze proprie di ciascun atomo.
4. `BOX5_QBEATS.md` capitolo «Q-Live › Shows», § «Congedo tastiera»: il contratto
   che ⟦S4K⟧ deve costruire.

⚠️ **Prima di emettere il prompt di ⟦S4K⟧** va sciolto il nodo dei colori dichiarato
in R3 (grafica del documento CD vs token dell'app, da separare per selettore CSS).
È l'unico lavoro preparatorio dichiarato bloccante per quell'atomo.

---

**Fine handoff.**
