# MISURE CC — A298 — 31/08/2026

Da: CC · A: referee. **Orologio**: 31/08/2026, 14:05 locale (UTC+2), da `date` di sistema.

Marcatura: **[M]** misurato da me ORA alla fonte · **[R]** riportato, non verificato da me · **[A]** giudizio mio.

⛔ **NIENTE È COMMITTATO. Nessun file è in staging.** I tre commit sono preparati e fermi al cancello.

---

## APERTURA (R1 + R8)

**[M]** LIBRO **v69** letto (testa, `:5`). Working directory `C:\Users\BULLFROG\`. `git worktree list`: repo Desktop @ `5eb18c7` [master] + `qb_fixB` @ `add556f`. HEAD locale = `origin/master` = `5eb18c7de46dba72483710feb18416c8a9eed0a9` — **coincide con l'ancoraggio del referee**.

**[M] Versioni verificate sulle teste**: BUGS **v77** · LIBRO **v69** · SCALETTA **v15** (dal campo `Versione`, non dalla data nel nome). Tutte e tre coincidono col mandato.

**[M] Cancello ID `A298`**: **0 su sei gambe**. Controlli positivi `A297`/`A295`/`A293` tutti >0. Nessuna collisione.

**[M] Metodo**: la regola di `BUGS_QBEATS.md:1600` esiste **verbatim** all'indirizzo indicato. È la **voce 47** del registro. ⚠️ Due precisazioni di natura, non di posizione: sul disco la frase porta i marcatori di grassetto che la citazione del mandato non riporta; e **non è una norma in un capitolo di Convenzioni**, è un enunciato **storico** dentro una riga di tabella del registro. Applicata alla lettera: **in tutto il giro sono state riscritte 5 righe in totale**, tutte bump di versione o cambi di STATO.

---

## DIVERGENZE TROVATE — riparate e dichiarate, non aggirate

1. ⚠️ **Path sbagliato nel mandato.** `AppRootView.swift` è indirizzato a `ios_app/QBeats/`; il file sta in **`ios_app/QBeats/UI/`**. **I numeri di riga `:57-62` e `:70-77` sono ESATTI** — misurati. Riparato e dichiarato dentro la marcatura SCALETTA, per la regola ③ che questo stesso mandato ratifica.
2. ⚠️ **Collocazione dei due ticket nuovi.** Il mandato propone §1.2 «o dove la struttura lo vuole». Entrambi sono **BASSA**, e la regola ratificata del 20/07 (punto 5 di `Workflow aggiornamento`) manda **in coda alla sottosezione di severità che compete** ⇒ **§1.3 — Backlog (🟡 OPEN BASSA)**.
3. ✅ **Controlli positivi della sonda ID: nessuna divergenza, era una lettura non dichiarata.** Il mandato dà `A244`=5 · `A253`=8 · `A290`=11 · `A291`=2. La lettura **per occorrenza** rende 5/9/13/3; la lettura **per riga** rende **5/8/11/2** ⇒ coincide. Dichiarato nel canonico quale lettura è.
4. ✅ **Controllo positivo «CC» = 243 / 293**: coincide **sul blob** a `5eb18c7`. Sul disco BUGS rende 299 perché **le mie stesse righe contengono «CC»** — il documento altera la misura che descrive (`R-δ.9`). Nel canonico è scritto «misurate sul blob».
5. ⚠️ **Un'affermazione mia era troppo larga, e l'ho ristretta.** Avevo scritto che «l'audio si ferma uscendo dalla STANZA, non dal player». La spazzata per effetto rende **altri chiamanti** di `audioEngine.stop()`, fra cui **il comando STOP del transport** (`UI/Live/TransportView.swift:58`). La frase ora afferma **soltanto** che nessuna transizione di **navigazione** ferma l'audio, con la spazzata dichiarata in loco.

---

## COMMIT 1 — `BUGS_QBEATS.md` v77 → v78

- **(1a)** `TD-rientro-senza-stop-sgancia-audio-e-grafica` (`:310`, indirizzo **verificato esatto**; blocco 310-317): **STATO chiuso**. Titolo cambiato **solo** nello STATO; la parte descrittiva è byte-identica. Marcatore di bloccante **tolto dal titolo di proposito**, come già per `TD-stop-perde-il-punto` (precedente della casa, `:354`). Sotto il titolo, blocco di chiusura con protocollo, verbatim di Mauro e 4/4.
- **(1b)** Il **meccanismo** è inciso: `LiveView.swift:439` dentro l'**unico** `.onAppear` del file (`:324`; fratello successivo `.onReceive` a `:452` ⇒ annidamento **verificato**, non assunto), scritture a `:447`/`:448`. ⛔ **Non misurato e scritto così**: se la callback sia sincrona. ⚠️ **In più, misurato da me e non presente nel mandato**: la guardia `:445` lascia una **finestra ≤1 beat** — la chiusura è compatibile con 4/4, **non** è prova che i trattini non possano apparire mai.
- **(1c)** `A242` **zero su tutti e cinque i canonici, su entrambe le letture**. Legame **A242 + A247/A248 ↔ ticket** ora nel tracker. ⚠️ `A248` invece **c'è** (2 righe), ma mai in rapporto con questo ticket. Sospetto di altri ID mancanti registrato **in una riga**; censimento **non aperto**.
- **(1d)** Ticket nuovo `TD-start-esce-in-silenzio` in **§1.3**. `AudioEngine.swift:869` **verbatim verificato**, occorrenza **unica** nel file. La citazione vecchia a `:859` è **marcata, non riscritta**. ⛔ Non misurato: se il ramo sia ancora raggiungibile.
- **(1e)** Ticket nuovo `TD-commento-liveview-superato-dal-commit-successivo` in **§1.3**. ⚠️ **Cronologia misurata da me, più forte della premessa del mandato**: il commento è di `6deea5248f7268c4087a2f2f9c2b26c92f730a78` (29/08 **10:35:27**), il meccanismo che lo smentisce è di `6aa9072bf4d917fb24441a9d860a9212ff6d0fbd` (29/08 **11:55:17**) — **un'ora e venti dopo, stessa mattina**, e il secondo è discendente del primo. ⇒ **Il commento era VERO quando fu scritto e falso ottanta minuti dopo. Mai aggiornato.** Il titolo del commit che lo supera lo dice verbatim. L'incidente del referee è registrato nel ticket.
- **Voce di registro 78** in coda alla tabella (4 colonne, **5 separatori — verificato**).

## COMMIT 2 — `LIBRO_MASTRO_QBEATS.md` v69 → v70

Tre righe datate `2026-08-31` in **Sezione 2 — Decisioni ratificate**, **sei colonne ciascuna (7 separatori — verificato)**: ① chi decide cosa · ② non si cita a memoria · ③ CC misura dove il referee non vede.

✅ **`R-δ.7` rispettata e verificata a misura**: il file cresce di **esattamente 3 righe** (571 → 574). La testa **non è cresciuta**: versione e descrizione v70 sono state inserite **dentro** la riga `Ultima modifica`, che resta **una riga sola** (assert nel codice di scrittura).

## COMMIT 3 — `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` v15 → v16

Marcatura additiva **fra il punto (a) e il punto (b)** della scomposizione di ⟦S-EXIT⟧ in Sezione C — **dove morde**. Punti (a)-(f) **intatti**: una sola riga rimossa in tutto il file, la riga `Versione`.

⛔ Inciso che **il punto (a) NON è chiuso**: si è chiusa **una delle sue tre gambe**. «Recupero memoria di iOS» resta **senza prova**. ⚠️ Dichiarata (non riparata) una **lacuna di catena**: la catena di versioni in testa salta da (v13) a (v16) — **v14 e v15 non vi furono mai registrate**.

---

## IMPRONTE — per ricostruzione indipendente

| file | OID blob (PRIMA, a HEAD) | OID disco (DOPO) | byte | righe |
|---|---|---|---|---|
| `BUGS_QBEATS.md` | `b330752f3ad2eb49dcca798cde5104abe3ffb0ca` | `f6d586f98d6dbced69ea2a6f342cdaae3dde428b` | 487771 → 498740 | 1634 → 1661 |
| `LIBRO_MASTRO_QBEATS.md` | `4457dd3ce1af12781eeb6e63c446e9bb89413533` | `4855017ec4c9d788db33c2c74460d08f20e92262` | 343140 → 347714 | 571 → 574 |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | `6579b9cd51dd0e178a4bb11ec57c90309ca316cf` | `ce3acf455649c573b76f3703dd85c3ef43bcbae1` | 89757 → 92157 | 750 → 768 |

**[M]** Tutti e tre **tracciati** e tutti e tre con `-text` attivo (`git check-attr` rende `unset`) ⇒ **disco ≡ blob**: l'OID disco è quello che il commit inciderà.

## DIFF LETTERALI — depositati su due gambe, `cmp` exit 0

`HANDOFF/DIFF_BUGS-v78_A298_2026-08-31_CC.txt` · `HANDOFF/DIFF_LIBRO-v70_A298_2026-08-31_CC.txt` · `HANDOFF/DIFF_SCALETTA-v16_A298_2026-08-31_CC.txt`

## GUARDIA DI SOSTANZA (evoluzione di quella di A296)

In A296 il difetto era un'impronta **plausibile e inesistente**. Il rischio gemello qui sono gli **SHA di commit**. La guardia estrae ogni token di 40 hex dalle righe **aggiunte** e verifica che risolva a un oggetto git reale con `git cat-file -e`.

- **Controllo positivo**: uno SHA inventato **non risolve** ⇒ verrebbe bocciato. Verificato.
- **Sui tre file**: **PASSATA** — tutti e cinque gli SHA risolvono, con il soggetto atteso.
- Guardie di forma: separatori di tabella **invariati** (5 e 7), **zero** separatori introdotti in prosa, backtick **pari su ogni riga aggiunta**. ⚠️ Il conteggio **globale** dei backtick di BUGS è dispari, ma lo era **già nel blob**: **3 righe preesistenti**, tutte delimitatori di blocco di codice — markdown corretto. Prima 3, dopo 3: **nessuna introdotta**. ⇒ La guardia globale era troppo grossolana; quella significativa è **per riga**, e passa.

---

## COMANDI PRONTI, NON ESEGUITI

    git add -- BUGS_QBEATS.md
    git commit -m "BUGS_QBEATS.md: v78 — un bloccante palco CHIUSO su device, due ticket nuovi in 1.3 (A298)"

    git add -- LIBRO_MASTRO_QBEATS.md
    git commit -m "LIBRO_MASTRO_QBEATS.md: v70 — tre ratifiche di Mauro su processo e gerarchia (A298)"

    git add -- HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md
    git commit -m "SCALETTA_ATOMI_S6: v16 — gamba blocco schermo del punto (a) misurata su device (A298)"

Autore = committer = `Mauro Martintoni <di_tutto@icloud.com>` (config locale già così, nessun hook, nessun `commit.template`) ⇒ zero trailer.

## PERIMETRO NEGATIVO — rispettato

⛔ Zero codice · zero BOX3 · zero BOX5 · zero `DESIGN/` · `E:` non riordinato (residuo in `_TRANSITO_DA_VERIFICARE/` invariato) · nessuna scrittura su Drive · nessun censimento di altri ID aperto · scheda ⟦S-EXIT⟧ **non** scritta. `git status` rende **esattamente i tre file**.

---

*MISURE_CC A298 — FINE. Il commit parte SOLO dopo ratifica del referee e OK esplicito di Mauro.*
