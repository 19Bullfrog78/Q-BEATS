# MISURE CC — A304 — CENSIMENTO PUNTATORI CONTRATTO 18/07 — 2026-09-01

Da: CC · A: referee. Mandato: **A304-CENSIMENTO-PUNTATORI-CONTRATTO-18-07**, dichiarato in testa e coincidente con quello ricevuto.

**Orologio**: 2026-09-01, **11:32:57 locale (UTC+2)**.

⛔ **Zero commit, zero push, zero git add, zero modifiche ai documenti.** Solo censimento e proposta.

Marcatura: **[M]** misurato ora da me, alla fonte · **[R]** riportato, non verificato da me · **[A]** giudizio mio.

---

## 🚨 IN TESTA, PERCHÉ CONDIZIONA TUTTO IL RESTO — possibile NON-CONTRADDIZIONE, non risolta da me

Il §6 di questo mandato chiede di fermarmi e dichiarare se trovo *«un documento in cui il 18/07 e il 30/08 non si contraddicono ma si completano»*. **L'ho trovato, ed è al centro del censimento, non ai margini.**

**[M] Il contratto del 18/07 esclude esplicitamente il player, per testo proprio.** Citato verbatim in `BUGS_QBEATS.md:325`: *«Sfondi = **lista** e **dettaglio** (il player non ha uscita-stanza)»* e *«sui **DUE sfondi con barra stanze**: **lista** e **dettaglio**. Il **player (metronomo) non ha barra stanze**»* — indirizzi `DESIGN/QLive_Nav/2026-07-18_QLive-Exit-in-Play.html:366` e `:212`.

**[M] La Sezione G della SCALETTA (la scheda della conferma d'uscita) ripete la stessa esclusione in proprio:** riga 614, «PERIMETRO NEGATIVO»: *«player ⇒ nessuna barra stanze, nessuna uscita-stanza, NESSUN gate (contratto, Q2 e ◎)»*.

**[M] Il foglio del 30/08, misurato a testo diretto, è interamente dentro il player.** Controllo positivo (termini generici «END SHOW»/«Q-Live» → 20 occorrenze, la sonda legge il file). Poi la misura specifica:

| stringa cercata (copy/componenti di Sezione G) | occorrenze nel foglio 30/08 |
|---|---:|
| `Stop & Exit` | 0 |
| `Stop & Switch` | 0 |
| `onHome` / `onSwitch` / `RoomSwitchBar` | 0 |
| `N on Link` | 1 — ma è un **paragone retorico** su una targhetta già ritirata il 24/08, non una ridefinizione |

Il contenuto reale del foglio (letto a testo): il **bivio del player fermo** (X · END SHOW · SHOW DETAILS), il **velo** che dice da dove riparte la canzone, i pulsanti `SHOW DETAILS`/`END SHOW` **dentro il player**. Mai una volta la barra-stanze di lista o dettaglio, mai le due porte `onHome`/`onSwitch` che la Sezione G gate.

⇒ **Sul metro della misura, i due documenti sembrano governare schermate diverse e non sovrapposte**, non lo stesso terreno con vincitore-e-vinto. Non è la mia materia decidere se la ratifica di Mauro del 01/09 intendesse comunque «tutto ciò che nasce dal 18/07, anche se non si tocca nel merito» — **lo dichiaro e lo consegno**, e sotto propongo comunque le marcature richieste, con questa riserva scritta accanto a ognuna che ne dipende.

---

## 0 · Orologio e cancello sull'ID

**[M]** Cancello a sei gambe su `A304`: tutte e sei le gambe = **0**. Nessun falso-UNO trovato (verificato aprendo, non solo contando). Controllo positivo su `A303` (tracciato): git grep=1, git log=2. ⇒ **A304 libero.** Tree pulito, HEAD `976d986`.

---

## 2 · Censimento

**[M] Perimetro effettivamente misurato**: canonici (`BOX3`, `BOX5`, `BUGS`, `LIBRO`, `SCALETTA`), `DESIGN/QLive_Nav/` (README + HTML), commenti in `ios_app/`.

⚠️ **Restrizione dichiarata rispetto al perimetro letterale del mandato**: il mandato include anche `HANDOFF/` nel perimetro; una prima sonda grezza (`grep -rl` su `QLive-Exit-in-Play` / `S-EXIT` / `S6F`) rende **oltre 150 file**, quasi tutti congedi/diff/misure datati — **cronaca di sessioni passate**, non asserzioni vive. Un referto del 28/08 che cablava contro il contratto **era corretto allora**: marcarlo oggi falsificherebbe la storia, non la correggerebbe. Ho quindi trattato `HANDOFF/` come fuori-perimetro per i punti (a)/(b)/(c) — che riguardano ciò che **oggi** dichiara/cita/descrive — coerentemente con la distinzione già a verbale in questo progetto fra canonici (vivi, si marcano) e `HANDOFF/` (storico, non si tocca). **Il pavimento del referee (5 punti, 3 file) cade interamente dentro questa stessa restrizione** — nessun punto del suo pavimento sta in `HANDOFF/` — il che la conferma indirettamente. Se il referee vuole il perimetro letterale, `HANDOFF/` è un giro a parte: centinaia di file, non decine.

**Comando e controllo positivo**: `grep -rln '<termine>' <perimetro> --exclude-dir=.git --exclude-dir=ARCHIVIO.MD`, ripetuto per `QLive-Exit-in-Play`, `contratto.*18[/-]07`, `S-EXIT`, `S6F`. Controllo positivo integrato: ogni sonda ha reso risultati non-zero su più file (nessuna sonda cieca).

### 2.1 · Punti che dichiarano o citano il contratto come fonte (a)/(b)

| # | file:riga | citazione verbatim | stato |
|---|---|---|---|
| 1 | `DESIGN/QLive_Nav/README.md:20` | «**CONTRATTO rev.2 per ⟦S-EXIT⟧ e ⟦S6F⟧.**» | attivo, indice normativo |
| 2 | `DESIGN/QLive_Nav/README.md:23` | «**SI LEGGE ACCANTO AL CONTRATTO 18/07**... Chi legge il 18/07 deve leggere anche questa.» | attivo |
| 3 | `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:592` (Sezione G, riga 573-768) | «**Fonte normativa:** `DESIGN/QLive_Nav/2026-07-18_QLive-Exit-in-Play.html`...» | attivo — **è il caso ambiguo sopra** |
| 4 | `LIBRO_MASTRO_QBEATS.md:291` (2026-07-20) | «**FREEZE uscita-stanza CONSEGNATO E ANCORATO**...» | attiva |
| 5 | `LIBRO_MASTRO_QBEATS.md:315` (2026-07-28) | «Il **normativo TRACCIATO** resta `DESIGN/QLive_Nav/2026-07-18_QLive-Exit-in-Play.html`.» | attiva |

**Questi cinque coincidono col pavimento dichiarato dal referee** (README 2 righe, LIBRO 2 righe, SCALETTA 2 righe — la SCALETTA qui è contata come UNA voce, la Sezione G intera, non due righe separate: la sua unità naturale è la sezione, non la riga). Nessuna divergenza sul conteggio grezzo.

### 2.2 · Punti trovati IN PIÙ — esistenza degli atomi, non contenuto del disegno

| # | file:riga | natura | raccomandazione |
|---|---|---|---|
| 6 | `LIBRO_MASTRO_QBEATS.md:327` (2026-07-31) | Istituzione atomo ⟦S-EXIT⟧, cita il contratto come prova di consegna del disegno | **marcatura leggera** — l'atomo esiste ancora nell'ordine, cambia solo la fonte del suo disegno |
| 7 | `LIBRO_MASTRO_QBEATS.md:334` (2026-07-31) | Istituzione atomo ⟦S6F⟧, stessa natura | **marcatura leggera**, stessa ragione |
| 8 | `LIBRO_MASTRO_QBEATS.md:553` (Sez.6, riga 48) | Changelog storico dell'istituzione di ⟦S6F⟧ | **nessuna marcatura** — Sezione 6 è narrativa pura, come le righe changelog già esistenti non vengono mai riaperte |

### 2.3 · Trovati e ESCLUSI dal censimento — dichiarati per trasparenza, non per omissione

- `LIBRO_MASTRO_QBEATS.md:284` (2026-07-18, «Navigazione ≠ transport») e `:285` (proprietà del SetlistRunner) — **ratifiche del 18/07 ma di TUTT'ALTRA materia**: architettura audio/transport, non il contratto di design `QLive-Exit-in-Play.html`. Ancora citate correttamente da commenti vivi in `QLiveRootView.swift:100,118,210` — **nessuna delle due è toccata dalla decisione del 30/08**, e CLAUDE.md le riporta tuttora come invarianti correnti.
- `LIBRO_MASTRO_QBEATS.md:338` (2026-08-01, foglio 390×844) — usa il file del 18/07 come uno dei **sei** freeze storici per una misura di **dimensioni pixel**, materia estranea al contenuto della conferma d'uscita.
- `BUGS_QBEATS.md:325` — cita il contratto per **dire cosa NON copre** (il player): è la prova a favore della non-contraddizione sopra, non un'asserzione di normatività da correggere.
- `ios_app/QBeats/UI/QLive/QLiveRootView.swift:274,283,292` e `QLiveSession.swift:23,47` — citano ⟦S-EXIT⟧ come atomo di destinazione per un gate non ancora costruito **qui**: restano accurati finché l'atomo esiste nell'ordine, indipendentemente dal disegno.

### 2.4 · Punto (c) — la conferma d'uscita come lavoro da fare

**[M]** Sede primaria: `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`, righe **493-521** (dentro Sezione C, elenco lavori non-atomo, voce 4) e **Sezione G per intero** (righe 573-768, 196 righe — è la scheda stessa). Citazione chiave, riga 495: *«🚨 CONFERMA PRIMA DI USCIRE DALLA STANZA — il disegno è pronto, nessun atomo lo costruisce.»* e riga 517: *«✅ È PRONTO A PARTIRE, e l'istruzione è già ratificata.»* — descritta come lavoro **pronto e in attesa**, non come lavoro fatto.

---

## 3 · La lacuna nel README

**[M] Confermato: zero occorrenze del foglio 30/08 in `DESIGN/QLive_Nav/README.md`.** Controllo positivo: il nome del foglio (`IL-VELO-DICE-DA-DOVE`) rende **4** occorrenze altrove nel deposito — la sonda vede, il README no. Letto per intero (111 righe): nessuna forma equivalente (data, titolo parziale) lo nomina nemmeno indirettamente. L'indice normativo si ferma al foglio del 29/08 (riga 33).

---

## 4 · Proposte di marcatura — testo pronto, NON applicato

Tutte additive. Nessuna parola esistente toccata. Formato coerente con le marcature già in uso nei canonici (`⛔ MARCATURA <data> — ...`).

### Proposta 1 — `DESIGN/QLive_Nav/README.md`, riga 20 (dopo la riga della tabella)

> ⚠️ **MARCATURA 01/09/2026 — QUESTA RIGA È SUPERATA DALLE DECISIONI DEL 30/08, CON UNA RISERVA.** Zero parole riscritte sopra: si marca. Il foglio CD `2026-08-30_QLive-Player_IL-VELO-DICE-DA-DOVE...` (ratifica Mauro 01/09) supera il contratto del 18/07 e ciò che vi si appoggia. ⚠️ **Riserva misurata:** il foglio del 30/08, letto a testo, tratta solo il player; il contratto del 18/07 esclude esplicitamente il player per testo proprio (`BUGS_QBEATS.md:325`). Se l'intenzione è la sola autorità del documento, la marcatura regge; se è la sovrapposizione di contenuto, non è misurata — vedi il referto A304 in testa.

### Proposta 2 — `DESIGN/QLive_Nav/README.md`, riga 23 (dopo la riga della nota di correzione)

> ⚠️ **MARCATURA 01/09/2026 — SUPERATA CON LA RIGA SOPRA.** La nota si legge accanto a un contratto ormai superato; la stessa riserva della marcatura precedente si applica qui.

### Proposta 3 — `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`, subito dopo l'intestazione di Sezione G (riga 573), prima di «Incisa dal referee, 24/08/2026»

> ⚠️ **MARCATURA 01/09/2026 — QUESTA SCHEDA SI APPOGGIA A UN CONTRATTO SUPERATO, CON RISERVA MISURATA. Zero righe sotto riscritte: si marca solo qui.** Il contratto `DESIGN/QLive_Nav/2026-07-18_QLive-Exit-in-Play.html`, fonte normativa dichiarata alla riga 592, è superato dalle decisioni del foglio CD 30/08 (ratifica Mauro 01/09). ⚠️ **Ma la scheda stessa dichiara, al proprio PERIMETRO NEGATIVO (riga 614), che il player è escluso** — e il foglio del 30/08, misurato a testo (referto A304), tratta **solo** il player: zero occorrenze delle stringhe `Stop & Exit`, `Stop & Switch`, `RoomSwitchBar` in quel foglio. **Non è misurato se il perimetro POSITIVO di questa scheda (lista, dettaglio, le due porte, il modale di conferma) sia toccato nel merito.** Finché non è chiarito, questa scheda resta l'unica fonte scritta per quel perimetro.

### Proposta 4 — `LIBRO_MASTRO_QBEATS.md`, riga 291 (in coda alla riga, prima del suo `|`)

> ⛔ **MARCATURA 01/09/2026 — LA FONTE CHE QUESTA RIGA ANCORA È SUPERATA (con riserva, vedi A304). Zero parole riscritte sopra: si marca.** `DESIGN/QLive_Nav/2026-07-18_QLive-Exit-in-Play.html` è superato dal foglio CD 30/08 (ratifica Mauro 01/09). Il FREEZE che questa riga registra come consegnato resta storicamente vero; la sua **autorità come fonte corrente** è quella in discussione.

### Proposta 5 — `LIBRO_MASTRO_QBEATS.md`, riga 315 (in coda alla riga, prima del suo `|`)

> ⛔ **MARCATURA 01/09/2026 — «IL NORMATIVO TRACCIATO» NON LO È PIÙ, con la stessa riserva della riga 291.** Zero parole riscritte sopra: si marca.

### Proposta 6 (leggera) — `LIBRO_MASTRO_QBEATS.md`, righe 327 e 334 (in coda a ciascuna)

> ⚠️ **NOTA 01/09/2026 — non una marcatura di superamento: l'atomo esiste ancora nell'ordine ratificato (⟦S-EXIT⟧ → ⟦S4L⟧ → ⟦S6⟧, invariato). Cambia solo la fonte del suo disegno**, oggi superata dal foglio CD 30/08 — vedi le marcature su Sezione G della SCALETTA.

---

## 5 · Consegna

Referto depositato su due gambe, `cmp` misurato dopo il deposito — vedi coda.

⚠️ **Sotto il regime A303**: questo referto entra nel commit del prossimo giro, non di questo (non esisteva ancora quando l'ultimo commit tracciato è stato fatto).

---

## 6 · Fermarsi e dichiarare — esito

- **L'ID collide?** No.
- **Una sonda dà zero senza controllo positivo?** Nessuna: ogni zero di questo referto (README/30-08, copy di Sezione G nel foglio 30/08) ha un controllo positivo misurato accanto.
- **Un punto rende la decisione ambigua?** **Sì — vedi la sezione in testa al documento.** È la scoperta principale di questo censimento, non un dettaglio.
- **Una premessa è falsa alla misura?** Non falsa, ma **meno netta di come il mandato la descrive**: «il contratto e ciò che vi si appoggia sono superati» presume una sovrapposizione di contenuto fra 18/07 e 30/08 che la misura diretta del foglio 30/08 non conferma. Non mi fermo — consegno la misura e le proposte come richiesto — ma la dichiaro qui perché condiziona ogni riga del §4.

---

*A304-CENSIMENTO-PUNTATORI-CONTRATTO-18-07 — fine corpo.*
