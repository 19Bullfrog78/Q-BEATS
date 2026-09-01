# MISURE CC — A310 — CHIUSURA GIRO RESTART SETLIST — 2026-09-01

Da: CC · A: referee (Mauro in copia, tramite cui il mandato è arrivato). Mandato: **CHIUSURA-GIRO-RESTART-SETLIST**, ricevuto **senza ID** — assegnazione delegata esplicitamente a CC (\"L'ID lo scegli TU\"). ID scelto: **A310**, cancello a sei gambe eseguito PRIMA di scrivere qualunque riga di questo referto.

---

## Governo (§0 e §0-bis del mandato) — registrato, non misurabile da qui

- **[R]** Due chat referee erano attive sullo stesso repository. Mauro ha deciso il 01/09 che comanda la chat che ha emesso questo mandato; l'altra ha consegnato il suo congedo e si chiude. Non ho visibilità sull'altra chat: registro la dichiarazione, non la verifico.
- **[R]** 🚨 `A308` (DECISIONI_ATTIVE) è dichiarato CONGELATO da questo mandato. ⛔ Non l'ho toccato in questo giro — nessuna lettura, nessuna scrittura, nessuna misura su quel fronte in questo documento.
- **[R]** ⚠️ Registrato per quando A308 riprenderà: il suo punto d'inserimento andrà riverificato a fonte, perché il LIBRO è avanzato di due commit da quando quel mandato è stato scritto (`70d5aa9` e `388e577`, entrambi dopo).
- **[R]** 🚨 Registrato, non investigato: prima di qualunque OK su A308 va eseguita la verifica dei backtick — il nome di file fabbricato intercettato in D-59. Non è materia di questo giro; portato qui solo perché non si perda.
- **[R]** §0-bis: la riserva del referee sul commit② (documenti) si scioglie con il meccanismo del §3 di questo stesso mandato — testo applicato incollato verbatim, ratifica su quello e non su un riassunto. Il commit① (codice) non è mai stato in discussione: due cancelli distinti già passati il 07/08 (ratifica tecnica del referee + OK di Mauro).

---

## ID — `A310` libero, confermato

**[M]** Cancello a sei gambe, eseguito su `A31[0-9]` (range, non solo il singolo candidato, per efficienza) prima di scrivere:

| gamba | esito |
|---|---|
| nomi file, C: | 0 |
| nomi file, E: | 0 |
| `git grep` tracciato | 0 |
| `git log --all --grep` | 0 |
| disco C: contenuto (`grep -rI`) | 0 |
| disco E: contenuto (`grep -rI`) | **1 grezzo — aperto, non contato** |

⚠️ **Il quinto valore è un falso-UNO, stessa classe R-δ.10 del precedente `A300`-in-UUID.** Aperto: `E:\...\DA_CD_PER_CC\11_07_2026\1Q-BEATS\Q-BEATS Vista LIVE v2 (standalone).html:176`, dentro `<script type="__bundler/manifest">`. Estratto il contesto attorno al match (80 caratteri per lato, per non caricare la riga intera — è un unico blob minificato che da solo eccede 1,5M token):

```
8QEFuVKAyTy/Qv6JrdpsGcomaX08bEjK8F3BrEp4MJHJGhczjvAIfnYBT+wvkr0VWPIg439/fw9mmMFtA319VKFbGgU93RBRFGOYnBMqHwA0e0M9Q5dYeWk++2Q2eHc4Hcr7Z2sMBPvOo/D7JYlBY6hYI42SxOC4dkp1
```

È **payload base64 di un bundler**, non testo: `A31` più una cifra è pura coincidenza dentro rumore alfanumerico casuale, non un identificativo di mandato. Nessun'altra occorrenza sul resto del range.

**Controllo positivo, stessa sonda:** `A309` (il mio stesso commit① di questo giro, appena fatto) → `git grep` tracciato **vede** (`BUGS_QBEATS.md:659`, `FineSetlistView.swift:25`), `git log --all --grep` **vede** (`70d5aa9`), disco C: e E: **vedono** lo stesso testo. `A308` (untracked, tre file `HANDOFF/MISURE_CC_...`) → disco C: ed E: **vedono**, `git grep`/`git log` correttamente **non vedono** (mai committato). La sonda distingue presenza-su-disco da presenza-in-git, e distingue rumore binario da testo reale.

⇒ **A310 libero, confermato.** Usato d'ora in poi per questo giro: commit② e questo referto.

---

## §1 — Verifica di non-duplicazione

**[M]** Il commit② (`388e577`) tocca **esclusivamente** `LIBRO_MASTRO_QBEATS.md` e `BUGS_QBEATS.md` — verificato da `git status`/`git diff` prima di committare: `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` non è nel diff, non è stato aperto in scrittura, non è stato toccato.

**Controllo positivo, aprendo e non solo contando:** ho riletto `SCALETTA_ATOMI_S6_2026-07-10.md:313` per intero. La marcatura **esiste già**, datata 07/08, e recita (estratto operativo):

> «⚠️ **MARCATURA 07/08 — LA CONDIZIONE DEL CANCELLO VA LETTA AL SINGOLARE, E NON È DICHIARATA SODDISFATTA.** [...] ⇒ La condizione «i **DUE** pulsanti di `FineSetlistView` devono fare qualcosa» si legge da qui in avanti **AL SINGOLARE**: resta **un** pulsante, BACK TO SHOWS [...]»

Stessa fonte citata dal mandato (`LIBRO_MASTRO_QBEATS.md:353`). ⇒ **Nessun doppione è entrato: non c'era nulla da duplicare, perché il file non è stato toccato, e la marcatura che il mandato temeva di veder duplicata era già lì dal 07/08** (misura riportata dal turno precedente, oggi riconfermata a fonte fresca).

---

## §2 — Nessun numero assoluto nel LIBRO

**[M]** L'unica riga toccata in `LIBRO_MASTRO_QBEATS.md` è la testa (riga 6, «**Ultima modifica:**»). Cercato `204|205` sull'intero file: **due hit, righe 309 e 363** — nessuno dei due sulla riga 6. La riga 6 contiene solo il delta corretto, **nessun numero assoluto**:

`v73 — **Sez.2 +0 righe**` → `v73 — **Sez.2 +2 righe**`

⇒ **Verificato: zero numeri assoluti entrati nel LIBRO.**

---

## §3 — Testo applicato, verbatim

### 3.a — `LIBRO_MASTRO_QBEATS.md`, voce v73 corretta (dentro la testa, riga 6)

> v73 — **Sez.2 +2 righe, doc-only, zero codice**: chiusura del giro di marcature 18/07↔30/08 — riconciliato l'ID del mandato (A305—A306, dichiarato e motivato, non una terza rinomina), sostituita la regola di processo con la formulazione di Mauro (ratificata 01/09: il referee rimisura E porta la propria opinione, non solo rimisura), sciolta la riserva sul modale di Sezione G (si restringe alla sola Lista Shows). Nello stesso giro: BUGS v78→v79 (marcatura su TD-segmini-onswitch-morto), SCALETTA v16→v17. ⚠️ **Per R-δ.7 la testa NON CRESCE IN RIGHE e resta UNA riga: nessuna coda tagliata.**

*(il resto della riga — v72 era: ... fino a v61 era: ... — è byte-identico a prima, non riscritto: R-δ.7.)*

### 3.b — `BUGS_QBEATS.md`, marcatura sul ticket `TD-fineshow-bottoni-morti`

> ✅ **MARCATURA 01/09 — LA RIMOZIONE RATIFICATA IL 07/08 È STATA ESEGUITA (mandato A309). Zero parole riscritte sopra: si marca.** **[M]** Commit `70d5aa9` (01/09/2026): `ios_app/QBeats/UI/Live/FineSetlistView.swift` non contiene più `Button("RESTART SETLIST") { /* restart setlist — Fase successiva */ }` né il suo `.buttonStyle(OverlayStopButtonStyle(primary: false, scaleFactor: scaleFactor))` — l'unico figlio del `VStack` è oggi `Button("BACK TO SHOWS")`. La rimozione porta la propria marcatura in testa al file (`FineSetlistView.swift:25-27`). ⛔ **QUESTA MARCATURA NON CHIUDE IL TICKET — chiuso vuol dire device.** Restano aperte le due condizioni già nominate dalla marcatura precedente: **(1)** il collaudo su device di Mauro, non ancora fatto su questa build; **(2)** il DISEGNO del piede con un pulsante solo, che la stessa riga del LIBRO (`LIBRO_MASTRO_QBEATS.md:353`) dichiara NON ratificato. **Stato** sopra resta invariato: 🔴 OPEN ALTA / 🚨 BLOCCANTE PALCO.

### 3.c — `FineSetlistView.swift`, righe aggiunte in coda al commento (25-27, rilette a fonte fresca prima di scrivere questo referto)

> /// ✅ ESEGUITO 01/09/2026 (mandato A309): il bottone RESTART SETLIST e il suo
> /// `.buttonStyle` sono stati rimossi da questo file. Resta aperto il disegno
> /// del piede con un pulsante solo — non ratificato — e il collaudo su device.

Il referee ratifica su questi tre blocchi, non su un riepilogo.

---

## §4 — Il conteggio, risolto: registrato, non riaperto

Il mandato dichiara chiusa la differenza di uno fra referee e CC sulle righe di Sezione 2 a `2c9b0bf`: 206 righe che iniziano con `|`, di cui 1 separatore e 1 intestazione → **205** (solo separatore sottratto) o **204** (separatore + intestazione sottratti), **entrambi corretti** secondo la convenzione; il delta (+2) è invariante. **Registrato qui come richiesto, non rimisurato, non riaperto.** Regola a verbale, riportata: quando due misure attente differiscono di esattamente uno, si sospetta la convenzione prima del file.

---

## §5 — Push e CI

**[M]** Due commit in questo giro, un push solo:

| | SHA | messaggio |
|---|---|---|
| commit① (codice, pre-autorizzato dal mandato precedente) | `70d5aa92c65ae97bd2cb7b4309c83d99bed7f253` | `fix(live): rimuove RESTART SETLIST da END SHOW (A309)` |
| commit② (docs, autorizzato da questo mandato) | `388e577da45de0885bfe5cb77e8920a5a1ee8a1e` | `docs: rimozione eseguita, cancello al singolare, conteggio v73 (A310)` |

Push: `2c9b0bf..388e577 master -> master` — un solo push, comprende entrambi (①  è antenato di ②).

**CI sulla punta**: run `33544199692`, titolo "docs: rimozione eseguita, cancello al singolare, conteggio v73 (A310)", workflow `iOS Signed Build`, job `build`. **Esito: SUCCESS, 2m44s.** `headSha` verificato = `388e577...`, coincide con la punta pushata. Annotazioni presenti sono le due standard preesistenti di ogni run recente (deprecazione Node.js 20 nelle action, trust dei tap Homebrew) — non toccano questo giro, nessuna riguarda i file modificati.

---

## §6 — Consegna e collaudo

Questo referto, su due gambe (`cmp` e sha256 in fondo, misurati dopo il deposito):
- `HANDOFF/MISURE_CC_2026-09-01_A310-CHIUSURA-GIRO-RESTART-SETLIST.md` (repo)
- `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-09-01_A310-CHIUSURA-GIRO-RESTART-SETLIST.md` (mirror)

⚠️ **Sotto il regime A303**: questo referto entra nel commit del prossimo giro, non di questo — non esisteva ancora quando l'ultimo commit tracciato (`388e577`) è stato fatto.

### Passo di collaudo per Mauro (copiabile)

**Come arrivare a END SHOW** (l'app non sa ancora creare show da zero — serve il percorso DEBUG):

1. Build di palco (compilata `-configuration Debug`): apri la schermata di **debug**.
2. Usa l'iniezione dati di test (**una sola setlist**, `TESTSONG L1.b`) per popolare Songs/Setlists in RAM.
3. ⚠️ **REGOLA DI SICUREZZA, da non saltare**: da qui in avanti **non toccare NESSUNA Song** (niente aggiungi/modifica/elimina) finché non chiudi l'app. Toccarne anche una sola fa scrivere i dati di test su disco **al posto di quelli veri** (`TD-injecttestdata-sovrascrive-dati-reali`, tuttora 🔴 OPEN ALTA — non è materia di questo giro, ma è la stessa procedura che questo collaudo attraversa).
4. In **Shows**, apri `TESTSONG L1.b` e premi **Start**: il player si monta armato e fermo.
5. Percorri la setlist fino in fondo.
6. Al termine compare **END SHOW**.

**Cosa deve vedere, e che cos'è la misura di questo giro:**
- **Un solo pulsante**: **BACK TO SHOWS**. RESTART SETLIST **non c'è più** — né visibile né come riga di codice morta.
- Premendo BACK TO SHOWS: ritorno alla libreria Shows.

⛔ **Chiuso vuol dire device**: finché questo passo non è stato fatto da Mauro su un device reale, il ticket `TD-fineshow-bottoni-morti` resta 🔴 OPEN ALTA — la marcatura di questo giro (§3.b) lo dichiara esplicitamente.

---

## §7 — Nessuna condizione di arresto

- Doppione del §1: **non trovato**.
- Numero assoluto nel LIBRO: **non entrato**.
- CI non verde: **non è il caso — SUCCESS**.
- L'altra chat ha toccato uno dei file di questo giro: **nessuna prova** — `git status` prima di iniziare mostrava esattamente lo stato atteso (stessi due file modificati, stesso set di untracked già noto dal turno precedente), nessuna sorpresa.
- Premessa falsa alla misura: **una c'era, dichiarata al turno precedente e riconfermata qui (§1) — la SCALETTA era già corretta dal 07/08, non serviva un secondo intervento.** Non ha richiesto arresto, solo la non-azione già presa.

⇒ Nessun cancello del §7 scattato. Giro chiuso fino al collaudo device di Mauro.

*A310-CHIUSURA-GIRO-RESTART-SETLIST — fine corpo, cmp e sha256 in appendice dopo il deposito su entrambe le gambe.*
