# Q-BEATS — HANDOFF REFEREE — 27/07/2026, fine sessione

Vige la Costituzione V5 e §7 FONTE-O-NIENTE. Se questo file e i canonici
divergono, **vincono i canonici**. Stato vivo: leggi-per-primo BOX3.

**RUOLI** — Mauro (decisore/tester, unico committer, TRAMITE fra i ruoli, si
definisce supervisore e NON è developer) · REFEREE (ultima parola tecnica,
**nessun accesso a dischi o repo**) · CC (ha il repo) · CD (design/UX; scrive
nel proprio progetto, la pull su E: la fa Mauro a mano e può ritardare di giorni).

---

## 0 · COME LEGGERE QUESTO FILE

`[V]` = **misurato dal referee uscente con le proprie mani**, sui file caricati
nel Progetto Claude. Non è un racconto: è un numero calcolato.
`[R]` = riportato da CC, da CD o da Mauro. Il referee non vede i dischi: ogni
fatto su file, git o E: è per costruzione un resoconto finché CC non lo misura.

Non c'è nessuna terza categoria. Se una riga non porta un marcatore, è un errore
di questo file e va trattata come `[R]`.

⛔ **NON CHIEDERE QUESTE COSE: hanno già risposta.**
 · La riga 373 di LIBRO (ora 384). È stata chiesta a CC **quattro volte** perché
   una pendenza morta continuava a rinascere dai blocchi di apertura. Il referee
   la possiede dalla propria copia. Non si richiede mai più.
 · «Il diff v41 a cinque hunk è sopravvissuto?» — irrilevante: è stato ricostruito
   da zero, scritto, committato e propagato. Chiuso.
 · L'emendamento all'invariante (R6). Ratificato da Mauro il 26/07, inciso in v41.
   Era stato chiesto cinque volte prima di arrivare: non riaprirlo.

---

## 1 · STATO — cosa è chiuso oggi

**LIBRO_MASTRO v41 — COMMITTATO, CI VERDE, PROPAGATO.**

`[R]` commit `8fa50189b13f49ba3b291510f7d1a388d75b5909`, un solo file,
+16/−4, autore=committer Mauro, zero trailer. HEAD = origin/master = ls-remote,
tre riferimenti allineati.
`[R]` CI run `30266162467`, `conclusion: success`, `headSha` coincidente,
workflow `iOS Signed Build`, artifact prodotto.
`[V]` **La copia propagata su E: è byte-identica al v41 costruito dal referee
in modo indipendente.** Misurato: 141.762 byte · 445 righe · CR = 0 · sha256
`e096cbc63b069074d73c7064ff762a64a29718abbdcfbfe6ce295aab45e86922` · OID blob
`d8a2b7d07f72cf8de49879d62c67a07522506c9e` · nessun BOM · `6ded4ab` 7 occorrenze
alle righe 290×2, 384, 437×2, 438, 439 · `ee31281` 3 occorrenze alle righe 6,
384, 440 · header «Versione: 41 (27/07/2026)».

**Cosa contiene v41** — 10 righe in Sez.2, tutte ratifiche di Mauro:
card 24/07 (4 decisioni) · postilla 1 copy popup, ratificata **e superseded in
giornata** · copy popup definitiva (bottone `Cancel`) · postilla 2 («···» non
pre-⟦S4L⟧) · postilla 3 (Remove inerte in sessione) · contratto Q20 · tab-reset
Q-Stage · emendamento all'invariante · confine distruttivo · opzione A-bis.
Più: Sez.3 +1 (CD-8) e Sez.5 «HEAD codice pre-doc-commit» → `ee31281`.

**Canonici** `[R]`: BOX3 **V99** · LIBRO **v41** · BUGS **v43** · BOX5 **V27** ·
SCALETTA **v2**. Solo LIBRO si è mosso oggi.

### ⚠️ DIFETTO NOTO IN v41 — una clausola falsa, rettifica pronta

`[V]` La riga `2026-07-27` «opzione A-bis», nella cella Doc ref, incide:
*«…sha256 `6455c8a9…1d2e19fc` (40367 B) — **non depositato su E:**, vive nel
progetto CD; impronta misurata dal referee sulla copia caricata nel Progetto»*.
`[R]` **La clausola di non-deposito è falsa**: CC ha misurato il file su E: in
`DA_CD_PER_CC\27_07_2026\`, CreationTime 27/07 13:41:19.
`[V]` **Impronta e byte incisi sono corretti** — il referee uscente li ha
rimisurati sulla copia caricata: 40367 B, sha256
`6455c8a98976fcb78a79c2f06822b8f02a152ffdcc9158e4b6d2a4091d2e19fc`.
`[V]` **La ratifica non è toccata**: A-bis resta valida, il difetto è solo nella
descrizione della fonte.

**Causa vera, e non è il tempo che passa.** Quella clausola veniva da una
dichiarazione di CD («questo file non è depositato, vive nel progetto CD»), mai
misurata da nessuno. La regola «SCRITTURA ≠ DEPOSITO» era stata applicata in una
sola direzione — non credere a «depositato» — e non nell'altra. **Una negazione
di deposito è esattamente tanto non verificabile quanto un'affermazione.** Lo
stato di deposito entra in un canonico solo come misura, in entrambi i versi;
altrimenti non entra affatto.

**Rettifica da portare al prossimo tocco di LIBRO** (non un commit a sé: la
proporzione non lo giustifica, e LIBRO riga 194 vieta di cancellare righe —
si aggiunge una riga di rettifica, come fece v40 con le proprie due):

> `| <data> | **RETTIFICA DEL REGISTRO — la riga 2026-07-27 «opzione A-bis» porta una clausola di deposito falsa.** Dichiara il mockup di confronto «non depositato su E:»: a misura è invece in `DA_CD_PER_CC\27_07_2026\` (CC, 27/07). Impronta e byte incisi restano corretti (`6455c8a9…1d2e19fc`, 40367 B) e la ratifica di A-bis è invariata; cade solo la clausola di non-deposito. ⚠️ Causa: lo stato di deposito era una dichiarazione di CD mai misurata. «SCRITTURA ≠ DEPOSITO» vale **in entrambe le direzioni** — anche una negazione di deposito è una misura, o non entra. | referee + CC | misura CC a fonte | attiva | — |`

⚠️ **SCALETTA v2 è SCADUTA su ⟦S4L⟧**: non conosce il runner-che-sale, il vincolo
`ObservableObject` annidato, l'emendamento all'invariante, lo split S4a/S4b, né
la bonifica dei 5 commenti-stale. Va riscritta **prima** di aprire S4L.

---

## 2 · PROPAGAZIONE — COMPLETA, nulla in volo

`[R]` **Quattro sedi, un solo contenuto.** Repo (`8fa5018`) + tre su E::
snapshot per-versione `…_V41_2026-07-27_8fa5018.md` · mirror
`LIBRO_MASTRO\LIBRO_MASTRO_QBEATS.md` · mirror
`CC MEMORIA\LIBRO_MASTRO_QBEATS.md`. Le tre copie E: rendono tutte sha256
`e096cbc6…5e86922`, 141762 B, CR = 0, e `git hash-object --no-filters`
`d8a2b7d0…506c9e` = il blob del commit. Sono il blob al byte, non copie del file
di lavoro.

⚠️ Precisione da non perdere: «stessa impronta» vale per le **tre copie su E:**,
che sono a faccia LF. Il file nel repo è CRLF su disco (142206 B, sha256
`689df255…`) e coincide **come blob**, non come byte di disco. Confondere le due
facce è il modo in cui una propagazione «riesce» e non è il blob.

`[R]` Prima di sovrascrivere i due mirror, CC ha verificato che il v40 non
andasse perso: sopravvive nello snapshot `…_V40_2026-07-22_131a511.md` su E: e
nel blob `efef5320…` a `131a511`. Due fonti indipendenti. **Comportamento
corretto e da ripetere**: una sovrascrittura si fa dopo aver provato che il
contenuto vive altrove, non prima.

⚠️ **Questione strutturale, NON risolta dall'allineamento**: un archivio
per-versione che contiene anche copie a nome fisso è una contraddizione. Le copie
a nome fisso vanno stale in silenzio a ogni giro, e l'allineamento è una toppa da
rimettere ogni volta. Da decidere in un giro doc: o sono governate, o non
esistono. Non è urgente, è ricorrente.

`[R]` Igiene minore dal censimento (25 file con «LIBRO» nel nome):
`DESIGN_E_BRIEFING\LIBRO_MASTRO_QBEATS2.md` e `LIBRO_MASTRO_QBEATSv15.md` sono
byte-identici (`52685009…`) — un doppione con due nomi. In `LIBRO_MASTRO\`
convivono tre copie pre-convenzione (`…QBEATS36/37/38.md`).

---

## 3 · IL GIRO DOC — ordine fissato

**B3 · BOX5 V28 — è il prossimo, ed è più grosso di come suona.**
`[V]` BOX5 V27 **non contiene una sola occorrenza** di `QL-SHOWS`, `Q-Live`,
`Remove`, `Q20`, `alert`: misurato sulla copia nel Progetto, e `[R]` CC ha
verificato che la copia su disco è byte-identica. L'indice finisce a «Cambio open
per ratifica (da V19)». **B3 non è «riformulare due righe»: è incidere un
capitolo che non esiste.** Chi lo apre credendo il contrario sbaglia il
dimensionamento.

Payload di B3 = le dieci righe `QL-SHOWS-01…10` del rev2, **più** le correzioni:
 · `QL-SHOWS-01` e `QL-SHOWS-02` promettono un **sync che non esiste** `[R]`
   (entitlement iCloud rimossi da `4e9d12f`, zero CloudKit). Sono **due** righe da
   riformulare, non una. CD ha già proposto il testo nuovo. Non si riapre iCloud
   per una card: resta gated sul ticket Opzione B.
 · `QL-SHOWS-09` porta la **copy superata** (postilla 1). Non va incisa.
 · `QL-SHOWS-08` «resta la sede» → «sarà la sede»: atterra in ⟦S5⟧.
 · `QL-SHOWS-06` va allineata alla scelta **A-bis**.
 · Va aggiunta la **forma** dell'alert, non solo il testo: `[R]` a HEAD non esiste
   alcun alert distruttivo nell'app (un solo `.alert` non distruttivo in
   `ContentView.swift:85`, zero `.confirmationDialog`, zero `UIAlertController`,
   `role:.destructive` solo in `DebugView.swift:217`). Il popup Remove è il primo
   del suo genere: modale o foglio dal basso, ordine bottoni, default.
 · Vincolo duro: **Remove non si spedisce senza il chip «Not in Q-Live»**.

Poi: **B4** SCALETTA v3 → **B5** BUGS v44 → **B6** BOX3 V100.

**In B5 (BUGS v44)**, due voci:
 · **Accumulo setlist.** `[R]` `deleteSetlist` (`Store/QBeatsStore.swift:115-118`)
   ha **zero call-site**: nell'app non esiste alcun modo di cancellare una
   setlist, né in Q-Live né in Q-Stage. Voce **separata**, NON agganciata a
   `TD-setlist-id-orfani` — quel ticket riguarda l'integrità a valle di una
   cancellazione che avvenga; questo è che la cancellazione non esiste a monte.
   Il rifiuto di CC sull'aggancio è stato ratificato dal referee.
   Precondizioni da scrivere nella voce: la guardia «non si cancella in sessione»
   **non può stare nello Store** (`isPlaying` = zero occorrenze in `Store/`), e va
   deciso cosa succede al campo di appartenenza a Q-Live quando la setlist sparisce.
 · **Angolo del riordino** su `TD-qlive-libero-limbo` causa (i): `LiveRootView`
   prende sempre `setlists.first` (`// L1.b DEV FALLBACK`), e `moveSetlists`
   esiste — qualunque riordino cambia quale show Q-Live carica. Riga da aggiungere
   al ticket esistente, **non** ticket nuovo. Nota utile: la pillola ▶ di ⟦S4L⟧
   **è** il «ponte Select Setlist→Live» che quel ticket indica come cura.

**In B6 (BOX3 V100)** vanno i reperti della giornata, incluso quello nuovo al §5.

---

## 4 · APERTE VERSO CD

 · **Riemissione del freeze 24/07** — CD ha scelto il metodo (file nuovo, non
   errata) e attende. **Tre** frammenti da marcare: (i) la coda della decisione §4
   con la copy vecchia · (ii) la fascia-cancello «"···" sono già vivi» · (iii) il
   frame ② che disegna lo sheet a 3 voci come stato ⟦S4L⟧, mentre sotto A-bis a
   ⟦S4L⟧ la voce è una. ⚠️ La nota ④ del freeze («Sheet = 3 voci, non una di più»)
   **non è violata**: è un tetto, non un pavimento.
 · **Riemissione di QL-SHOWS** con la copy ratificata e le due righe sync corrette.
 · **Chip «Read-only»** in testa alla lista Q-Live: è la prima conseguenza visibile
   dell'emendamento all'invariante. Dal giorno in cui Remove esiste, quella scritta
   è falsa. **Va deciso prima di ⟦S4L⟧**, non al gate device.
 · `[R]` **`rev3` (`805e86c9…`) non è depositabile così com'è**: porta la copy
   superata e la claim-sync. Diff rev2↔rev3 = sole etichette di versione, zero
   design intrappolato. Cita inoltre `fd62da58…` come impronta di rev2: **non
   corrisponde ad alcun file**. La stessa impronta fantasma è girata anche nei
   blocchi di apertura del referee. Un'impronta che non nomina nulla ha viaggiato
   in almeno due documenti fingendo di nominare qualcosa.

---

## 5 · FASE C — il codice, dopo il giro doc

 · Pre-⟦S4L⟧, due atomi **senza scrittura**: forma ③ della riga compatta (gate CI)
   + congedo tastiera Q20 (gate **device** — la tastiera non si prova in CI).
   🔴 Q20 **blocca** ⟦S4L⟧.
 · ⟦S4L⟧, blocco unico: pillola accesa · «···» a **una voce** (Remove) · **swipe
   trailing** · popup · campo di persistenza · lato Q-Stage (toggle «Show in
   Q-Live», chip «Not in Q-Live», terzo stato vuoto).
   `[R]` Gate device: **due affordance da provare invece di una**. L'assenza di
   conflitto fra swipe trailing e gesti di navigazione **non è determinabile a
   fonte** — provata solo la metà di codice (zero `swipeActions` in
   `QLiveShowsView`). Si verifica su device.
 · ⟦S5⟧ dettaglio → ⟦S6⟧ MetroFAB. Gate device: solo S4L.
 · ⚠️ Durante ogni gate **NON premere «Carica dati test»** del ⚙ DEBUG:
   `injectTestData` SOSTITUISCE songs+setlists e un CRUD successivo li salva su
   disco al posto dei veri.

**Coda non bloccante**: TD#17 🟠 (chiude con run palco 2-3h su VR2800 in banda
singola senza perdita peer, OPPURE Soluzione C).

---

## 6 · TRAPPOLE VIVE — nominate, perché sono già scattate

**REPERTO NUOVO DI OGGI, da incidere in BOX3 V100:** `gh run watch … | tail`
restituisce l'exit code di **`tail`**, non del watch. `[R]` Un falso-verde in
potenza: la conclusione della CI si legge da `gh run view --json`, mai da un exit
code in fondo a una pipe. Stessa famiglia dello sha corto che rende `[]` con exit
0 — riprodotto anch'esso dal vivo oggi.

 · **Contare le righe che contengono X non è contare le X.** Il referee uscente ha
   dichiarato 7 occorrenze di `6ded4ab` dove erano 9, perché stampava un contesto
   per riga. CC aveva ragione. `6ded4ab` scende da 9 a **7**, non a 8: due
   sparizioni, l'ancora di Sez.5 e la riga 6 dell'header riscritta per intero.
 · **Due cartelle `HANDOFF`**, una nel repo su C: e una nell'archivio su E:. Un
   percorso scritto senza disco esplicito è ambiguo. Si cerca per **impronta**.
 · **Due `Q9` e due `Q10` in LIBRO**: serie 21/05 (CD-5, swipe Vista LIVE) e serie
   11/07 (freeze Q7-Q16). Una citazione «Q9» senza data è ambigua, come «BOX3 (g)»
   senza lo strato. ⚠️ Il problema è **strutturale** — ogni freeze riparte a
   numerare da capo — e merita una riga di convenzione in un canonico. Non è stato
   fatto: risolto solo dove mordeva.
 · **Troncamento dei nomi file a 64 caratteri**, con perdita dell'estensione.
   Archiviazione **per posizione** (`_SUPERATI\` dentro la cartella-data), mai per
   prefisso: la rinomina è il punto dove si perdono i caratteri.
 · **BOX3 è stratificato**: 9 strati Supersede, ognuno riparte da (a). Citare
   sempre lo strato — «BOX3 V99 (g)», mai «BOX3 (g)».
 · **Riferimenti per riga senza ancora**: «BUGS r.344-346» era sbagliato (il ticket
   va da 341 a 348) ed era stato **ereditato da un documento CD senza verificarlo**.
   Si cita per **simbolo**, non per numero di riga.
 · **Impronte che non nominano nulla**: `fd62da58…` (dentro rev3 e nei blocchi di
   apertura) e `04ce650a…`/`4d488900…` (versioni rigenerate da CD, `[R]` non più
   esistenti su alcun supporto dopo scansione di 601 file). Nessuna impronta entra
   in un documento senza essere stata misurata.
 · **Due versioni dello stesso canonico nel Progetto Claude** = il referee cita
   quella sbagliata credendola buona. ⚠️ **Azione per Mauro: togliere dal Progetto
   le due copie di LIBRO v40 e caricare la v41.**

---

## 7 · REGOLE DI CONDOTTA — quelle che sono costate care

 · **Il referee non scrive pareri in prima persona.** «Parere referee: favorevole»,
   mai «il mio parere è sì». Una frase del referee inoltrata da Mauro a CC è
   arrivata come ratifica del decisore e ha quasi fatto incidere una ratifica mai
   data. L'etichetta viaggia col testo, sempre.
 · **Una ratifica ENUMERA**: nomina la voce e la sua impronta. «Sì a tutte e tre»
   non è una ratifica. Non dedurne mai una; se fai un'inferenza, dichiarala.
   ⚠️ **Ma il contrario è altrettanto costoso**: se Mauro ha già risposto in
   parole chiare, richiedergli la stessa cosa in formato A/B/C è tempo bruciato.
   È successo due volte in un giorno.
 · **Il referee non decide di UX.** Il referee uscente ha inventato un'opzione di
   disegno, l'ha messa per prima in un prompt e l'ha etichettata «raccomandata dal
   referee»: CD l'ha ricevuta già vestita. Segnalare un vincolo è il mestiere;
   consegnare la soluzione no. Se serve un'opinione di design, si dà **dopo** che
   il decisore ha visto i pixel, e dichiarando che vale meno di quella di CD.
 · **SCRITTURA ≠ DEPOSITO.** Un deliverable CD non conta finché non è misurato su
   E:. «Depositato» detto da CD è una dichiarazione, non una prova.
 · **CONSEGNA ≠ RATIFICA. Due cancelli**: ratifica referee ≠ OK Mauro.
 · **Se CC rifiuta con una fonte in mano, di norma ha ragione.** Oggi è successo
   due volte ed entrambe le volte CC aveva ragione: sull'aggancio del ticket
   accumulo, e sulle due imprecisioni della FASE 1.
 · **Diff verbatim, mai riassunti.** Le impronte le calcola il referee, non CC.
   ⚠️ Ma se il referee scrive **anche** il testo, la protezione sul contenuto
   salta: resta solo quella sull'encoding. In quel caso serve una **fase di audit
   dei fatti da parte di CC prima della scrittura** — oggi ha intercettato due
   riferimenti sbagliati che sarebbero finiti in un canonico.
 · **Trasporto**: diffi e documenti viaggiano come **file**, mai incollati. Il
   testo di questo progetto è pieno di caratteri fragili (⟦⟧ › ③ ▶ em-dash).
 · **PROPORZIONE**: il cancello sta in rapporto al layer e alla reversibilità. Il
   rigore §7 va dove il danno è permanente, non su una copy reversibile.
 · **PROATTIVITÀ**: parere esplicito sempre, anche non richiesto. Criticità
   segnalata **prima** di procedere, non dopo.
 · **Mauro non è developer.** Si spiega raccontando cosa succede a chi usa l'app,
   non citando il contratto. Se una cosa va spiegata tre volte, il problema è la
   spiegazione.
 · **Ogni messaggio che implica un'azione CC o CD finisce con un prompt pronto
   copia-incolla**, con destinatario e modello. Mauro non riscrive i prompt.
 · **Modelli**: verifica meccanica (git, grep, metadati) → Haiku 4.5 · verifica di
   merito o scrittura su file a due facce → Opus 4.8 xhigh · L3 pre-flip CI-only →
   Sonnet 5. Se CC alza il modello e lo motiva, di norma ha ragione.
 · **Vincoli §6**: `SwiftUI.Section` qualificato (TD-1), `SongSection` vietato,
   flash metronomo via `PassthroughSubject` e mai timer SwiftUI.
 · Branch fiammifero = autorizzazione esplicita di Mauro. Commit single-purpose,
   staging file per file (mai `git add -A`), Mauro solo autore, zero trailer.
 · **«Chiuso» = confermato su device**, mai CI verde da solo. **«Pushato ≠
   propagato.»**
 · **«Dove siamo»** → 5 righe, niente prompt.

Apri dichiarando cosa hai letto (R1) e cosa resta `[R]`.
