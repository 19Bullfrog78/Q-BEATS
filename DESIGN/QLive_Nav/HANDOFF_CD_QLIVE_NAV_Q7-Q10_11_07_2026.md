# HANDOFF GENERALE CD → CC — Q-Live Nav (Cancello 1) · Q7–Q10 + CD-02 — 11/07/2026

> **Fronte:** freeze §1 (Q-Live Nav, Cancello 1). Chiusura delle **4 aperture** rimaste (Q7–Q10) sul freeze `e141295`.
> **Cosa consegna:** 4 decisioni (non opzioni), con token/CSS/markup/copy **a valore** da cablare 1:1.
> **Rapporto col freeze:** è un *delta* su `e141295` — anchor e §1 restano validi. Non un nuovo freeze: 4 gap-fill ratificati da CD.
> **Lingua doc:** IT (CD↔CC). **Lingua UI:** EN. **Scala 390pt.**
> **Cancello:** CD ruled 11/07 → **ratifica LIBRO (nav)** → CC cabla.

---

## RECAP SESSIONE (per Mauro — cosa è successo, in breve)
1. **Punto di partenza:** 4 domande aperte dal freeze Q-Live Nav (`e141295`, 09/07) — Q7 (header Q-Stage senza «+»), Q8 (hit-area `.seg-mini`), Q9 (`.cta.dead` attivo o disabilitato?), Q10 (copy plurale su «all-orphan»).
2. **CD ha deciso** le 4 (non dato opzioni) → emendato il freeze in un taglio datato 11/07, aggiornato `shows-reference.css` e la *Riferimento Completo*, scritto l'handoff.
3. **Il referee (CD-02) ha controllato** il lavoro e trovato 3 problemi reali:
   - **3 identificatori diversi** del freeze mai riconciliati (`e141295` · `b23dfc78…` · `438fcaf3…`) — rischio di citare quello sbagliato in silenzio.
   - **Un fatto tecnico sbagliato** nella motivazione di Q9 («Go to Q-Stage funzionante oggi» — falso: closure no-op, cablaggio è S6, dopo Nodo A).
   - **Una tecnica prescritta fuori competenza** in Q8 (CD aveva scritto il «come» SwiftUI; è dominio CC/referee — e la tecnica proposta era anche sbagliata: avrebbe reso la pill 44pt visibile).
4. **CD ha corretto tutto** — vedi sezioni sotto: identità dichiarata **non riconciliata** (non inventata) · Q9 corretto (decisione di design resta, motivazione falsa rimossa) · Q8 ridotto a **risultato + vincolo** (tecnica tolta, il COME resta a CC/referee).
5. **Stato ora:** le 4 decisioni + le 3 correzioni sono ratificate da CD e propagate su **tutti** i file di questa sessione (elenco sotto). Prossimo passo: **ratifica LIBRO**, poi CC cabla.

---

## 0 · FILE DI QUESTA SESSIONE (dove, e cosa è cambiato in ciascuno)
`DA_CD_PER_CC/11_07_2026/`
- **`QLIVE_NAV_FROZEN_e141295_+Q7-Q10_11_07_2026.html`** — **l'HTML di riferimento 1:1 · il contratto su cui CC cabla.** Copia del freeze base + le 4 decisioni Q7–Q10 + il blocco d'identità/delta/numerazione CD-02 in testa (commento, prima riga utile).
- **`HANDOFF_CD_QLIVE_NAV_Q7-Q10_11_07_2026.md`** — questo file: recap + le 4 decisioni + le correzioni CD-02, a valore.

Fuori da questa cartella, **toccati nella stessa sessione:**
- **`shows-reference.css`** (root progetto) — riconciliato il vocabolario CTA (`.dead` / `.quiet` / `.ghost`), allineato `.startbtn.dead` al token `--disabled`, tolta la tecnica dal commento Q8.
- **`Q-BEATS Shows - Riferimento Completo.html`** (root progetto) — **il master Shows, l'html di riferimento visivo per tutta la sezione** (non solo Q-Live Nav): freeze section aggiornata (anchor +Q7–Q10, link ripuntato al taglio emendato), pannello **Addendum · Q7–Q10** aggiunto, Ⓔ/Ⓖ aggiornati (Q9/Q10), correzioni CD-02 (Q8 tecnica tolta, Q9 fatto corretto, nota identità) propagate, rev bump 11/07.

Non toccati/superati (restano validi per ciò che questa sessione non copre):
- `DA_CD_PER_CC/09_07_2026/FREEZE/QLIVE_NAV_FROZEN_e141295.html` — **base** del freeze, invariata (pre-Q7–Q10).
- `DA_CD_PER_CC/09_07_2026/HANDOFF_CD_SHOWS_09_07_2026.md` — handoff Shows precedente (creazione/Arrange/stati vuoti), ancora il riferimento per tutto ciò che questa sessione non tocca.

---

## IDENTITÀ DEL FREEZE (CD-02) — NON riconciliata
Tre identificatori in circolazione, mai riconciliati:
- `e141295` — «anchor HEAD» dichiarato nella banner del freeze (uso CD).
- `b23dfc78…` — citato in `RoomSwitchBar.swift:3` (codice già committato: S0/S1/S2F/S2).
- `438fcaf3…` — sha256 di `FREEZE_QLIVE_NAV_DECODED_2026-07-11.txt` (fonte del referee).

Se `e141295` e `b23dfc78…` siano **lo stesso contenuto** (naming diverso) o **versioni diverse**: **NON RICONCILIATO** — CD non ha accesso a git / al `.swift` / al `.txt` e non lo afferma. **Da chiudere: referee/CC/Mauro.**

**Derivazione esatta del taglio emendato:** copia 1:1 del **file** `…/09_07_2026/FREEZE/QLIVE_NAV_FROZEN_e141295.html` (che dichiara anchor e141295) + 4 emendamenti. Deriva dal **file**, non da un commit verificato: l'aggancio file↔commit è parte del «non riconciliato».

**Numerazione:** il taglio emendato **aggiunge righe** (commenti + pannello addendum) → le citazioni per riga (§CSS :669/:711/:749-750; §markup :834-837/:864-866/:1009) **slittano e falliscono in silenzio**. → **Citare per SELETTORE.** Delta per-selettore + mappa riga→selettore: **in testa all'HTML congelato** (commento CD-02).

---

## Q7 · HEADER Q-STAGE › SHOWS SENZA «+» (interim finché §8 non arriva)
**Decisione.** Finché **§8 «+ create show»** è differito, l'header **Q-Stage › Shows** si presenta **senza «+»**: **Home a sx (absolute-left) · segmento centrato**, identico all'header Q-Live. **Niente «+» disabilitato/morto** — coerente con la regola «empty-state onesto» del freeze (nessuna affordance che non fa nulla).

**Perché.** Oggi non esiste un flusso di creazione show (è §8): esporre un «+» inerte violerebbe la stessa onestà con cui il freeze uccide lo show-fantasma (`first ?? makeDefault()`) e rimuove il footer Sync non implementato.

**Quando arriva §8.** Il «+» rientra a **destra** come `.addmini` **absolute-right**; il segmento è già centrato → **nessun reflow**.

**Markup / CSS (contratto).**
- Header Q-Stage interim = layout `.roombar.center` + `.roomseg.nm0` (come Q-Live), **senza** `.addmini`.
- Regola pronta per §8: `.roombar.center .addmini{position:absolute; right:14px; top:50%; transform:translateY(-50%);}`
- CC: **un solo layout header** per entrambe le stanze finché §8 non spedisce il «+».

> Nota reference: nella *Riferimento Completo* i frame Q-Stage mostrano il «+» come **stato-target §8** (differito, etichettato); l'HTML **congelato** mostra l'**interim** (senza «+»). Due verità etichettate — il congelato = cosa CC cabla ora.

---

## Q8 · `.seg-mini` (navbar del detail) → hit-area ≥44pt
**Decisione.** **Sì, si espande** — stessa regola di `.roomseg`. La **pill resta visibile a 30pt** (variante compatta della navbar, intenzionale), ma il **tap target = altezza navbar 50pt ≥ 44pt**.

**Perché.** Era una **nota mancante**, non un intento diverso: il ≥44pt è vincolo globale (CLAUDE.md). La navbar è 50pt → lo spazio c'è già.

**Risultato (CD, ratificato).** ≥44pt tattili, chrome visibile **30pt** invariato. **Vincolo:** l'espansione tocca **solo l'hit-test, solo in verticale** — **mai** bg/bordo/clip (che restano 30pt), altrimenti la pill diventerebbe 44pt *visibili*, contraddicendo il risultato. **Il COME è dominio CC/referee** (il pattern corretto esiste già in codice) — non prescritto qui.

---

## Q9 · `.cta` «Go to Q-Stage» = ATTIVO (non disabilitato) · vocabolario «dead»
**Decisione (design).** «Go to Q-Stage» va trattato come **bottone ATTIVO** (navigazione → Q-Stage), **non** disabilitato. È lo **stile finale**, quindi è **corretto che NON abbia** `opacity:var(--disabled)`. ⚠️ **Non «funzionante oggi»:** a fonte (referee) la closure è un no-op `() -> Void = {}` e `AppRootView.Screen` **non ha** il caso `.qLive`; il **cablaggio arriva con S6** (dopo il Nodo A). La decisione di design è **indipendente** dal cablaggio: si stila come attivo a prescindere. Sciolgo l'omonimia «dead»:

| Suffisso | Significato | Resa | Dove |
|---|---|---|---|
| `.dead` | **DISABILITATO** | `opacity: var(--disabled)` (0.4) su fill neutro, non interattivo | `.startbtn.dead` (Start su show non-avviabile) |
| `.quiet` | **nav secondaria ATTIVA** | neutro solido: bg `rgba(255,255,255,0.04)`, bordo `1px var(--line)`, testo `--text2`, ≥44pt | `.cta.quiet` («Go to Q-Stage») |
| `.ghost` | **CTA di CREAZIONE attivo** | blu-tratteggiato (accento Q-Stage) | `.cta.ghost` («Create in Songs») — fuori dal freeze §1 |

**Delta.** `.cta.dead` (usato per «Go to Q-Stage») → **`.cta.quiet`**; testo alzato da `--text3` a `--text2` (leggibilità). «dead» **ritirato dai CTA**: da ora significa solo «disabilitato». Allineato `.startbtn.dead` al token `--disabled` (0.4) su entrambi i file.

**CC.** `.cta.quiet` è lo stile di un bottone **attivo** (navigazione a Q-Stage, cablaggio S6). **Mai** applicare il token disabled a `.quiet`.

---

## Q10 · Copy «show all-orphan» (Ⓖ) — N-agnostica
**Decisione.** **Una sola stringa**, valida per ogni N (nessun ramo singolare/plurale — l'app non è ancora localizzata):

> **`Every song in this show was deleted from the catalog. Restore them or rebuild the show in Q-Stage.`**

- «Every song … was» regge **N=1** e **N≥2** senza rotture grammaticali (soggetto singolare + verbo singolare).
- Rimosso **«tracks»** (ambiguo: si confonde con Media / file audio, e col caso distinto *FILE MISSING*).
- Il **numero** vive solo nel conteggio header `0 playable · N unavailable` (già N-safe: count aggettivale, nessun sostantivo plurale).
- Titolo invariato: **`No playable songs`**. Distinta da «This show is empty» (Ⓕ).

**CC.** Stringa unica, **nessuna interpolazione di N nel body**.

---

## STATO
- **CD-ruled 11/07** (impatto: Q8/Q9/Q10 = basso/medio, applicano regole DS/globali; Q7 = medio, interim coerente con la direzione già ratificata).
- **CD-02 (referee) recepito 11/07:** identità dichiarata non riconciliata (non inventata) · corretto un assunto falso in Q9 · tolta una tecnica fuori competenza in Q8. Propagato su tutti i file elencati in §0.
- **→ ratifica LIBRO (nav)** insieme al freeze §1, poi CC cabla.
- Nessuna delle 4 tocca il **modello dati** (restano restyle/regole UI + copy).

---
*CD · 11/07/2026 · delta su freeze `e141295` + `HANDOFF_CD_SHOWS_09_07_2026.md`. In conflitto con un brief di sessione attivo, prevale il brief.*
