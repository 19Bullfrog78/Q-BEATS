# REFERTO A133 — CENSIMENTO + COMMIT

Da: CC · A: referee, + Mauro · Data: **19/08/2026**
Mandato: **A133**, segue **A132 RATIFICATO dal referee**.
⛔ **A132 non è mai stato committato** — HEAD era ancora `547017f` (A129+A130). Questo mandato
committa **A132 e A133 insieme**.

Marcatura: **[M]** misurato da me · **[A]** giudizio mio.

---

## PASSO 1 — IL CENSIMENTO

### Metodo

**[M]** Sonda: `: (...) -> Void = {...}` su tutto `ios_app/*.swift`. Verificate **due varianti
aggiuntive che la sonda avrebbe potuto mancare**, e nessuna delle due esiste nel corpus:
firme con `-> ()` invece di `-> Void` (zero) · default scritti nella firma di un `init(...)`
invece che sulla dichiarazione della proprietà (zero, con una sonda dedicata a quella forma).
**Controllo positivo:** la sonda trova il caso già noto (`RoomSwitchBar.swift:36`) — non è cieca.

### I sei candidati, con TUTTI i siti, uno per uno

| parametro | siti reali | esito |
|---|---|---|
| `RoomSwitchBar.onSwitch` | `QLiveShowDetailView.swift:127` (default) · `QLiveShowsView.swift:78-83` (passato) · `ShowsListView.swift:82-90` (passato) | **SPENTO** — già faccia (a) del ticket |
| `MetroFAB.onTap` | `QLiveEmptyStates.swift:168` (passato, ma eredita un default — vedi sotto) · `QLiveShowsView.swift:255` (default diretto) | **SPENTO** |
| `NoShowsToPlayEmptyState.onMetroTap` | `QLiveEmptyStates.swift:241` (preview, non reale) · `QLiveShowsView.swift:247` (default — passa `onGoToQStage`, NON `onMetroTap`) | **SPENTO** |
| `GoToQStageCTA.onGoToQStage` | `QLiveEmptyStates.swift:164`, unico sito nel corpus (`private struct`) — passato | non spento |
| `NoShowsToPlayEmptyState.onGoToQStage` | stessi due siti di sopra — passato al sito reale (`onSwitchToStage`) | non spento |
| `QLiveShowsView.onSelectShow` | `QLiveRootView.swift:95`, unico sito — passato | non spento |

**[M] Una catena in più, trovata seguendo i fili invece di contare i siti uno a uno:**
`QLiveEmptyStates.swift:168` **passa** `onTap: onMetroTap` — ma quell'`onMetroTap` è il
parametro di `NoShowsToPlayEmptyState`, che al suo unico sito reale **non lo riceve**. ⇒ il
MetroFAB dentro l'empty-state eredita il no-op del genitore: **le due istanze reali di MetroFAB
sono mute per due strade diverse**, non una sola.

### Il mio numero contro quello del referee

**⚠️ SEI candidati, non cinque — non adattato al numero ricevuto.** Il dato condiviso, **tre
spenti**, coincide. Ipotesi dichiarata sulla differenza: `GoToQStageCTA.onGoToQStage` è
`private` con un solo sito possibile in tutto il corpus, strutturalmente al riparo da un
chiamante esterno dimentico — se il referee l'ha escluso per quel motivo, la sua lista è un
sottoinsieme coerente della mia, non un numero diverso sullo stesso oggetto. Non lo do per
acquisito: lo segnalo e mi fermo.

### I due spenti che non sono quello di Mauro — verificati, registrati senza ticket

**[M]** `MetroFAB.onTap` e `NoShowsToPlayEmptyState.onMetroTap` sono la stessa lacuna di
prodotto (il metronomo libero) in due punti. Verificate le due fonti citate dal mandato,
**verbatim**:
- `LIBRO_MASTRO_QBEATS.md:271` (10/07): *«metronomo-libero = uscita metrofab (anche 0-show)»*
  — destinazione ratificata.
- `LIBRO_MASTRO_QBEATS.md:290` (20/07, gate S4b, Mauro): *«[4] tap riga/MetroFAB/CTA
  (correttamente INERTI, nessun crash — così da disegno S4b)»* — inerzia testata sul device.

⚠️ **Trovato durante la verifica, non presunto: metà di quella ratifica è scaduta.** La riga
`:290` marca inerti **sia** il MetroFAB **sia** la CTA nello stesso respiro. Ma la mia stessa
tabella sopra mostra che `NoShowsToPlayEmptyState.onGoToQStage` (la CTA) **è passato**
(`onSwitchToStage`) al suo sito reale: **la CTA è viva a HEAD**, il MetroFAB resta inerte. Una
misura del 20/07, metà vera e metà scaduta oggi — il rischio esatto per cui una clausola di
sicurezza si rimisura e non si rilegge.

⇒ **Registrati come inerti ratificati, non tracciati in BUGS con ticket proprio.** Nessuna
espansione oltre il richiesto.

### La regola incisa

**[M]** In coda al censimento: il default-chiuso-silenzioso è l'**unico** costrutto del corpus
che produce un bottone morto invisibile al compilatore; il censimento è **meccanico** (la sonda,
ripetibile in un comando) e va rifatto **a ogni gate device**; ogni parametro che risulta
**spento** deve avere una riga in BUGS, deliberato o no — sul palco un tocco a vuoto voluto e un
tocco a vuoto dimenticato sono, per il dito, indistinguibili.

**Forma:** additivo, in coda al ticket `TD-segmini-onswitch-morto`, prima di «Dominio:» — stessa
collocazione già usata per le marcature precedenti. **Zero parole delle facce (a)/(b)/(c)
toccate.**

---

## PASSO 2 — IL COMMIT

### ⚠️ Correzione di modello prima di procedere

**[M] A132 non era mai stato committato.** `HEAD` era ancora `547017f7d4e4df9c5d5a84774b0ccfe
63bc01b1d` (A129+A130). Il ticket di A132 e il censimento di A133 esistevano **solo** come
modifiche non committate a `BUGS_QBEATS.md`. Questo commit li porta dentro **insieme**.

### Identità e stato del remoto

| | |
|---|---|
| `user.name` / `user.email` | `Mauro Martintoni` / `di_tutto@icloud.com` |
| `origin/master` pre-commit | `547017f7d4e4df9c5d5a84774b0ccfe63bc01b1d` — coincide con `HEAD` |

### `git status --porcelain=v1` — VERBATIM, prima dello staging

```
 M BUGS_QBEATS.md
```

Untracked di questo giro (238 righe totali; solo quelle datate 19/08 riportate per intero):

```
?? HANDOFF/CONGEDO_CC_2026-08-19.md
?? HANDOFF/DIFF_2026-08-19_A128-STANDBY-CENTRATURA.txt
?? HANDOFF/DIFF_2026-08-19_A132-TICKET-ONSWITCH-MORTO.txt
?? HANDOFF/DIFF_2026-08-19_A133-CENSIMENTO-ISOLATO.diff
?? HANDOFF/MISURE_CC_2026-08-19_A127-COLLAUDO-S5b.md
?? HANDOFF/MISURE_CC_2026-08-19_A128-STANDBY-CENTRATURA.md
?? HANDOFF/MISURE_CC_2026-08-19_A132-TICKET-ONSWITCH-MORTO.md
?? HANDOFF/MISURE_CC_2026-08-19_A133-CENSIMENTO-E-COMMIT.md
```

### La nomina — 7 file, con 2 esclusioni dichiarate

**Nominati:**

- `BUGS_QBEATS.md`
- **quattro** artefatti A132/A133: `DIFF_2026-08-19_A132-TICKET-ONSWITCH-MORTO.txt` ·
  `MISURE_CC_2026-08-19_A132-TICKET-ONSWITCH-MORTO.md` ·
  `DIFF_2026-08-19_A133-CENSIMENTO-ISOLATO.diff` ·
  `MISURE_CC_2026-08-19_A133-CENSIMENTO-E-COMMIT.md`
- **due** artefatti A128, **valutati e fatti entrare ora** (vedi sotto): `DIFF_2026-08-19_A128-STANDBY-CENTRATURA.txt` · `MISURE_CC_2026-08-19_A128-STANDBY-CENTRATURA.md`

**Totale: 7 file** (1 tracciato modificato + 6 nuovi).

**Sulla decisione dei due A128 — dichiarata, non delegata.** Il referee è d'accordo che
entrino; la decisione e la dichiarazione sono mie. **Sì, entrano in questo commit.** Motivo:
descrivono lo stesso fix di centratura che è già dentro `547017f` come item ① di A129 —
verificato di nuovo qui (`.frame(maxWidth: .infinity)` presente in entrambi i file, 2
occorrenze ciascuno) — sono storia reale di come ci si è arrivati, non un ramo alternativo mai
applicato. Restare fuori un commit in più li avrebbe lasciati **soli su un disco**, ed è
esattamente il rischio che il mandato segnala.

**Esclusi (2), invariati dal commit precedente:**

| file | perché |
|---|---|
| `HANDOFF/CONGEDO_CC_2026-08-19.md` | non è di questo lavoro, lo precede |
| `HANDOFF/MISURE_CC_2026-08-19_A127-COLLAUDO-S5b.md` | atomo diverso (⟦S5b⟧ device), non nominato da questo mandato |

### Staging esplicito

```
git add BUGS_QBEATS.md
git add HANDOFF/DIFF_2026-08-19_A132-TICKET-ONSWITCH-MORTO.txt
git add HANDOFF/MISURE_CC_2026-08-19_A132-TICKET-ONSWITCH-MORTO.md
git add HANDOFF/DIFF_2026-08-19_A133-CENSIMENTO-ISOLATO.diff
git add HANDOFF/MISURE_CC_2026-08-19_A133-CENSIMENTO-E-COMMIT.md
git add HANDOFF/DIFF_2026-08-19_A128-STANDBY-CENTRATURA.txt
git add HANDOFF/MISURE_CC_2026-08-19_A128-STANDBY-CENTRATURA.md
```

**Mai `-A`, mai `.`.** Sette comandi `git add`, uno per file. Verificato dopo lo staging:
`git diff --cached --name-only | wc -l` → atteso **7** (1 modificato `M` + 6 nuovi `A`).

---

## CONTROPROVA — RICOSTRUZIONE A DUE STADI, RIGOROSA

**[M]** `git diff` confronta sempre contro `HEAD`, e `HEAD` non contiene A132: un diff grezzo
avrebbe mostrato A132+A133 mescolati. Isolato in due passi indipendenti:

**Stadio 1 — la base è A132, non HEAD.** Ricostruito «post-A132» applicando con `git apply` il
diff **già ratificato e depositato** `HANDOFF/DIFF_2026-08-19_A132-TICKET-ONSWITCH-MORTO.txt` a
una copia isolata del blob HEAD. Impronta della ricostruzione: **CR=1116 LF=1116 byte=322806**
— **coincide esattamente** con l'impronta dichiarata nel referto A132. La base è verificata.

**Stadio 2 — applico i tre edit dichiarati di A133** (header · censimento additivo · riga di
changelog) a quella base, e confronto lo sha256 col file reale sul disco:

```
sha256 RICOSTRUITO (post-A132 + 3 edit A133): 4e128eee9144d8c81438874d7ef4e22a0c892596ab43553b61761c9a6bd81267
sha256 REALE (file sul disco)                : 4e128eee9144d8c81438874d7ef4e22a0c892596ab43553b61761c9a6bd81267
IDENTICI: True
```

**Dimostrazione di fallibilità:** versione alterata da 56 a 57 nella ricostruzione → lo sha256
cambia subito. Il controllo sa fallire.

**Diff isolato di SOLO A133** (post-A132 → post-A133), depositato come
`HANDOFF/DIFF_2026-08-19_A133-CENSIMENTO-ISOLATO.diff`, con la stessa riga di dichiarazione
"non rigiocabile" in testa già usata per l'artefatto isolato di A130: 41 righe (comprese le due
intestazioni etichetta e la riga dichiarativa).

**Conteggio cumulativo A132+A133 contro HEAD** (quello che il commit porterà davvero):
`+33 / −1`.

---

## FACCIA DEL CANONICO

CR contati sui byte puri.

| | CR | LF | byte |
|---|---:|---:|---:|
| PRIMA (post-A132) | 1116 | 1116 | 322 806 |
| DOPO (post-A133, = reale) | 1132 | 1132 | 328 891 |

Uniforme in entrambi i momenti.

---

## OGNI MODIFICA DI FORMA — DICHIARATA

Nessuna oltre a quelle già insite nei tre edit dichiarati (header, blocco additivo, riga di
changelog). Non ho introdotto righe vuote né spaziature diverse da quelle già presenti nel
documento — il censimento è annidato come sotto-elenco puntato dentro il ticket esistente,
stessa indentazione dei bullet fratelli.

---

## COMMIT, PUSH, CI

*(Sezione compilata dopo l'esecuzione — vedi stato di consegna in fondo.)*

---

## LIMITI DICHIARATI

1. ⚠️ Il conteggio di sei candidati presume che la sonda testuale copra ogni forma sintattica
   possibile di «default vuoto silenzioso» in Swift. Ho verificato le varianti più plausibili
   (`-> ()`, default su `init`, corpi non banali) e sono risultate assenti — ma una sonda
   testuale non è una prova di completezza semantica quanto lo sarebbe un'analisi del
   compilatore.
2. ⚠️ Non ho verificato a schermo l'effettivo comportamento di `MetroFAB` in nessuno dei due
   siti: la misura è di codice, non di device.
3. ⛔ Zero modifiche a `ios_app/` in questo mandato — confermato dallo stage: un solo file
   sorgente, `BUGS_QBEATS.md`, e non è sotto `ios_app/`.

---

*A133-FINE*
