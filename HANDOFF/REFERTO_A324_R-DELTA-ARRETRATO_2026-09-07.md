# REFERTO CC — A324 · R-δ ARRETRATO, i canonici su E: · 07/09/2026

Esecuzione del mandato «A324 — R-δ ARRETRATO · i canonici non sono su E:».
Autorizzazione di Mauro ricevuta il 07/09.

**Marcature:** `[M]` = misurato da me alla fonte in questa sessione · `[R]` = riportato da altri e non verificato da me · `[A]` = mio giudizio.

⛔ Questo documento non e' una fonte. Se una mia affermazione e il repo non concordano, ha ragione il repo.

---

## In una riga

**Mancava UN giro, non tre.** Tre stampe scritte, due gia' allineate e non riscritte. La causa e' **(a)**: il mandato che ha prodotto i canonici non nominava la seconda gamba. E lungo la strada ho trovato **due premesse del mandato che oggi non reggono** — sono nel §6.

---

## R1 — Inventario PRIMA, misurato senza scrivere nulla

`[M]` Tutte e cinque le cartelle prescritte **esistono**: `LIBRO_MASTRO/`, `BUGS_QBEATS/`, `BOX5_Test/`, `BOX3_Codice/`, `HANDOFF/`. Nessuna e' stata creata, nessun percorso alternativo scelto.

Stampa piu' alta presente per canonico, **prima** di questo mandato:

| canonico | stampa su E: | byte | sha256 (primi 16) |
|---|---|---|---|
| LIBRO_MASTRO | `LIBRO_MASTRO_QBEATS_v77_2026-09-05_871de34.md` | 364.287 | `003b7241faa54691` |
| BUGS_QBEATS | `BUGS_QBEATS_v83_2026-09-05_871de34.md` | 510.215 | `a35f7a5ea98051e3` |
| BOX5 | `BOX5_V44_2026-09-02_d61e823.md` | 148.659 | `e385df5a8efa6e9d` |
| BOX3 | `BOX3_V100_2026-08-22_9edc120.md` | 90.638 | `de9faecfaaa59870` |
| SCALETTA | `SCALETTA_v19_2026-09-03_3329f86.md` | 102.915 | `d2cbb242a1a0c1f8` |

⚠️ **Difetto della mia prima sonda, dichiarato:** ho elencato le cartelle con `ls | tail -5`, che ordina **alfabeticamente** — e `BOX3_V100` viene prima di `BOX3_V96`. Per un momento ho creduto che la stampa piu' alta di BOX3 fosse `V99`. **`V100` c'era.** Rifatto con ordinamento numerico. `[A]` Famiglia **P2**, fatto-che-sembra-vuoto.

---

## R2 — I file copiati, verificati sui due lati

`[M]` Estratti **dal blob** a `8ea30ce8882440983adb4ab684d9d9494c9bc12c` con `git show <sha>:<path>`, mai dal disco, come prescritto.

| stampa scritta su E: | byte | sha256 (primi 16) | verifica |
|---|---|---|---|
| `LIBRO_MASTRO/LIBRO_MASTRO_QBEATS_v78_2026-09-06_8ea30ce.md` | 367.771 | `afe60a01808053af` | `cmp` vs blob **exit 0** |
| `BUGS_QBEATS/BUGS_QBEATS_v84_2026-09-06_8ea30ce.md` | 518.574 | `0d74f71243f26330` | `cmp` vs blob **exit 0** |
| `BOX5_Test/BOX5_V45_2026-09-06_8ea30ce.md` | 154.925 | `771593d751a5a035` | `cmp` vs blob **exit 0** |

**La data nel nome viene dalla TESTA, non dal commit**, come prescritto `[M]`: tutte e tre le teste dichiarano `Decisione: 2026-09-06` (la regola ratificata il 06/09), mentre il commit e' del `2026-09-07`. ⇒ Nel nome sta **`2026-09-06`**.

⚠️ **Drive non e' stato toccato**, come ordinato: si popola da solo da `E:`.

---

## R3 — Cio' che era gia' allineato e NON ho riscritto

`[M]` Due canonici erano **gia' presenti e byte-identici al blob** a `8ea30ce`:

| canonico | stampa | byte | esito |
|---|---|---|---|
| BOX3 | `BOX3_V100_2026-08-22_9edc120.md` | 90.638 | **identica al blob** — `de9faecfaaa59870` su entrambi i lati |
| SCALETTA | `SCALETTA_v19_2026-09-03_3329f86.md` | 102.915 | **identica al blob** — `d2cbb242a1a0c1f8` su entrambi i lati |

⇒ **Dichiarate allineate, non riscritte.** Nessun file toccato inutilmente, nessuna impronta nuova creata dove non serviva.

---

## R4 — Perche' non era successo: e' **(a)**, e la misura lo mostra

### Prima cosa: la gamba E' mancata UNA volta, non tre

`[M]` Ho contato le stampe su `E:` per ogni giro che ha toccato canonici, cercandole per `sha7` nel nome:

| giro | commit | stampe su E: **prima** di questo mandato |
|---|---|---|
| A315 | `d61e823` | **3** — LIBRO v75 · BUGS v81 · BOX5 V44 |
| A317 | `3329f86` | **3** — LIBRO v76 · BUGS v82 · SCALETTA v19 |
| A318 | `871de34` | **2** — LIBRO v77 · BUGS v83 |
| **A322** | `8ea30ce` | **0** ⇐ **l'unico buco** |

E la **data di scrittura** dei file su `E:` chiude la questione `[M]`:

```
v75  scritta 2026-09-03 14:48   <- commit d61e823 delle 14:47:57
v76  scritta 2026-09-04 16:52   <- commit 3329f86 delle 16:52:13
v77  scritta 2026-09-06 13:28   <- commit 871de34 delle 13:28:34
v78  scritta 2026-09-07 13:26   <- questo mandato, cioe' io, adesso
```

⇒ **Per tre giri di fila la stampa su `E:` e' stata depositata NELLO STESSO MINUTO del commit.** La pratica funzionava. Si e' rotta **una volta sola**, ad A322.

`[A]` **La premessa «da tre giri la seconda gamba manca» e' misurabilmente falsa.** Non lo dico per puntiglio: se la diagnosi e' «da tre giri», si cerca una causa sistemica — un permesso, uno strumento, un'abitudine persa. La causa vera e' puntuale, e la si trova solo se si guarda il giro giusto.

⚠️ **Cosa puo' aver prodotto il numero «tre», ipotesi non misurabile da me** `[A]`: i congedi di A315, A317 e A318 portano tutti e tre la stessa nota — **«DA FARE MAURO: caricare nel Project le stampe nuove»**. Quella e' una **terza gamba**, il Project di Claude, che non e' `E:` e che io non posso ne' leggere ne' scrivere. Se quelle tre non sono state caricate, dal punto di vista di Mauro «i canonici aggiornati non arrivano» **da tre giri** — ed e' vero, ma su una gamba diversa da quella che questo mandato ripara. ⛔ **Non l'ho verificato e non posso: dichiarato come ipotesi, non come misura.**

### Seconda cosa: la risposta al §6 e' **(a)**

`[M]` I due mandati che ho ricevuto dopo l'ultimo deposito riuscito:

- **A320 Fase 2** — «Autorizzata anche la scrittura del referto in `HANDOFF/` + mirror E:». ⇒ Nomina la seconda gamba **solo per il referto**. Ed era corretto cosi': A320 era un giro di **codice**, non ha toccato alcun canonico, quindi non c'era nessuna stampa da depositare.
- **A322** — «R4 · Referto in `HANDOFF/` + mirror, verificati identici» e «R5 · Le versioni nuove dei canonici toccati». ⇒ **Chiede il mirror del REFERTO e l'ELENCO delle versioni nuove, ma non chiede mai di depositare le stampe dei canonici su `E:`.**

⇒ **A322 ha toccato tre canonici e nessuna riga del mandato chiedeva la seconda gamba per essi.** Ho eseguito cio' che il mandato chiedeva, incluso il mirror del referto, che infatti e' su `E:`. **La stampa dei canonici non e' stata chiesta e non e' stata fatta.**

⛔ **Non e' (b): nessun ostacolo tecnico.** `E:` e' scrivibile — l'ho appena fatto tre volte — ed era scrivibile anche prima, visto che il referto A322 ci e' arrivato nello stesso giro.

`[A]` ⇒ **Il difetto e' nel prompt, ed e' esattamente il caso che il §6 prevede:** «non si chiede a un esecutore di ricordarsi una regola che il mandato non nomina». Aggiungo pero' la mia parte: **R-δ e' una regola ratificata, e avrei dovuto applicarla anche senza che il mandato la nominasse.** Il mandato non e' una fonte, ma nemmeno un'esenzione. `[A]` La contromisura piu' solida non e' «CC si ricorda»: e' una riga fissa nel modello di mandato, perche' una regola che dipende dalla memoria di qualcuno e' una regola che prima o poi salta.

---

## 🚨 Due premesse del mandato che oggi NON reggono

### 1 · Le «due facce» non ci sono piu', e `.gitattributes` copre piu' di quanto il mandato dice

Il §3 afferma: «LIBRO e BUGS hanno DUE FACCE — CRLF sul working tree, LF nel blob — e `.gitattributes` copre solo `HANDOFF/**`, `DESIGN/**`, BOX3 e BOX5».

`[M]` **Misurato: `.gitattributes` copre anche LIBRO e BUGS, esplicitamente.**

```
HANDOFF/** -text
DESIGN/** -text
BOX3_QBEATS.md -text
BOX5_QBEATS.md -text
BUGS_QBEATS.md -text        <- il mandato dice che non c'e'
LIBRO_MASTRO_QBEATS.md -text  <- idem
.gitattributes -text
```

Ci sono dal **30/08/2026**, commit `b962c48` — *«chore(git): BUGS, LIBRO e .gitattributes protetti con -text (A285)»*.

E la conseguenza si misura sui byte `[M]` — **disco `C:` e blob coincidono per tutti e cinque i canonici, CRLF = 0 ovunque**:

| canonico | blob | disco C: | stampa E: | CRLF |
|---|---|---|---|---|
| LIBRO | 367.771 | 367.771 | 367.771 | 0 / 0 / 0 |
| BUGS | 518.574 | 518.574 | 518.574 | 0 / 0 / 0 |
| BOX5 | 154.925 | 154.925 | 154.925 | 0 / 0 / 0 |
| BOX3 | 90.638 | 90.638 | 90.638 | 0 / 0 / 0 |
| SCALETTA | 102.915 | 102.915 | 102.915 | 0 / 0 / 0 |

⇒ **Oggi una copia dal disco avrebbe prodotto lo stesso identico file.** Il metodo prescritto resta quello giusto — dal blob, sempre, perche' non dipende dallo stato del working tree — ma **la ragione scritta nel mandato e' scaduta da una settimana**, e la cura che l'ha fatta scadere e' stata applicata da noi in A285.

`[A]` Va corretto dove e' inciso: un cartello che descrive un pericolo rimosso insegna a temere la cosa sbagliata, e chi lo legge fra sei mesi puo' andare a «riparare» due facce che non esistono.

### 2 · La numerosita' del buco

Gia' detta in R4: **uno**, non tre. La ripeto qui perche' e' la premessa che orienta la ricerca della causa.

---

## Cosa resta aperto

1. **La riga fissa nel modello di mandato** per la seconda gamba dei canonici — se la scrive il referee, il difetto (a) non si ripresenta.
2. **La terza gamba, il Project di Claude:** tre giri di stampe (A315, A317, A318) risultano dichiarate «da caricare» e io non posso verificarlo. **Se e' li' che manca qualcosa, e' compito di Mauro** — ed e' probabilmente cio' che ha fatto nascere questo mandato.
3. **Correggere le due premesse scadute** dove sono incise, con un giro doc: le due facce di LIBRO/BUGS e la copertura reale di `.gitattributes`.
4. **I documenti fuori dal deposito**: erano sette, con questo referto **otto** — ma questo si committa, quindi tornano a sette.
