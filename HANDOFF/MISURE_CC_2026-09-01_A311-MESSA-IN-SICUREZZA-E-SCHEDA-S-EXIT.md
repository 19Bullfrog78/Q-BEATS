# MISURE CC — A311 — MESSA IN SICUREZZA CONGEDO+CASSAFORTE, SCHEDA ⟦S-EXIT⟧ — 2026-09-01

Da: CC · A: referee. Mandato: **MESSA-IN-SICUREZZA-E-SCHEDA-S-EXIT**, ricevuto senza ID — assegnazione delegata a CC. ID scelto: **A311**, cancello a sei gambe eseguito prima di scrivere.

---

## §0 — Orologio

**[M]** `date` sul sistema, prima di scrivere qualunque data in questo referto: **2026-09-01, 20:59:35 locale.** Coerente con tutte le date usate.

---

## Governo (§0/§0-bis del mandato) — registrato

- **[R]** Due chat referee erano attive; Mauro ha deciso il 01/09 che comanda quella che ha emesso questo mandato, l'altra ha consegnato il proprio congedo (i due file di §1) e si chiude.
- 🚨 **[R]** `A308` resta CONGELATO. ⛔ Non toccato in questo giro — nessuna lettura, nessuna scrittura, nessuna misura.
- ⚠️ **[R]** Registrato per quando A308 riprenderà: il punto d'inserimento va riverificato a fonte — il LIBRO è avanzato di **due commit ulteriori** da quando A310 lo dichiarava (`b7c56f7`, `a039502`).
- 🚨 **[R]** Registrato, non investigato: verifica meccanica dei backtick (nome di file fabbricato intercettato in `D-59`, altre 140 voci dallo stesso processo) va eseguita prima di qualunque OK su A308.

---

## ID — `A311` libero, confermato

**[M]** Cancello a sei gambe su `A31[1-9]` (range): nomi C:=0 · nomi E:=0 · `git grep` tracciato=0 · `git log --all --grep`=0 · disco C: contenuto=0 · disco E: contenuto=0. **Zero su tutte e sei — nessun falso-UNO da classificare**, a differenza di A310.

⚠️ **Nota di metodo, dichiarata:** la stessa sonda su `A31[1-9]` aveva trovato un residuo (il payload base64 già classificato in A310); isolato con `grep -oE`: il match cade **esattamente su `A319`**, in due copie (il file CD originale e la mia stessa citazione verbatim di quel payload nel referto A310). **A311 non ne è toccato**, unico e pulito.

**Controllo positivo:** `A310` (il mio giro precedente) → git grep tracciato vede (`FineSetlistView.swift` non lo cita, ma `BUGS`/referti sì), git log vede (`388e577`), disco vede. La sonda distingue.

⇒ **A311 libero, confermato.** Usato per: commit di questo giro e questo referto.

---

## §1 — I due file: verifica, specchia, non riscrivere

**[M]** Entrambi esistono, leggibili, UTF-8 confermato (`file`):

| file | byte | righe | sha256 |
|---|---|---|---|
| `CONGEDO_REFEREE_2026-09-01_A308-CONSEGNA-PRIMA-DELLA-CHIUSURA.md` | 11.641 | 165 | `dc9d622aecc0ff0d59c6fb891680cc0815f353e86268dc87b48a83671850bb64` |
| `CASSAFORTE_2026-09-01_ratifiche-non-incise-e-scheda-S-EXIT.md` | 16.266 | 318 | `3d46e53e61e08a863c99d43800c2276b874997f57fddfcf1b01edabca41f465d` |

**Verifica di non-troncamento, sui due capi richiesti:**
- CONGEDO — premessa «Accetto la decisione senza discuterla» trovata alla riga **31** ✅ · consiglio finale «la prima cosa da fare nell'altra chat non è riprendere A308» trovato alla riga **130** ✅. ⚠️ Il file stesso dichiara in testa (nota di provenienza) di essere già una **ricomposizione**: un export `.txt` precedente aveva troncato l'originale a entrambi i capi. La ricomposizione ricevuta da Mauro **non è troncata** — è quanto verificato qui.
- CASSAFORTE — «COME SI LEGGE» trovato alla riga **3** ✅ · «FINE CASSAFORTE» trovato all'**ultima riga, 318** ✅.

⛔ Nessun capo mancante: nessun arresto dovuto.

**Specchio su E:, `cmp` per entrambi:**
```
CONGEDO_REFEREE...: identici
CASSAFORTE...:      identici
```
Copia diretta `cp -p` (mai attraverso Drive), verificata byte-per-byte dopo la copia.

⛔ **Zero parole corrette, riformattate o riscritte in nessuno dei due file**: sono documenti di un'altra parte.

---

## §2 — La scheda ⟦S-EXIT⟧ entra nella SCALETTA

**[M] Forma misurata dalle 12 sorelle di Sezione B** (`### ⟦ID⟧ <descrizione> · PRE|POST · CI[+DEVICE]`, corpo a bullet con etichette **grassette:**), prima di scrivere. Tre etichette del corpo sono riprese **verbatim** dalla convenzione già in uso nelle schede sorelle (non inventate): **🔴 VINCOLO TECNICO** (misurata in ⟦S4R⟧, ⟦S5⟧) · **CANCELLO** (misurata in ⟦S5⟧) · **OPEN** (misurata in ⟦S5⟧, usata due volte lì come qui). Le altre (Scopo, Già costruito, Resta da costruire, Cond, Perimetro) adattano i titoli B.1-B.8 della CASSAFORTE nella stessa forma a bullet, **contenuto preso dal file, non da memoria**.

**Dove:** in coda a Sezione B, dopo ⟦S6⟧ (tredicesima scheda), non inserita a metà nell'ordine di esecuzione — la stessa scelta additiva-in-coda usata da ogni altra crescita di questo documento.

**Marcatura additiva, verbatim, accanto alla riga del 07/08 (`SCALETTA:459` nuova numerazione, la riga «MARCATURA 07/08 — ⟦S-EXIT⟧ È NELL'ORDINE RATIFICATO MA NON HA SCHEDA»):** testo applicato riportato per intero al §"Testo applicato" più sotto — **verificato byte-per-byte contro il dettato del mandato, identico**.

**Sweep citazioni nude, dopo l'inserimento (+27 righe totali: +25 alla scheda in Sez.B, +2 alla marcatura in Sez.C):** cercato `SCALETTA_ATOMI_S6_2026-07-10\.md:\d+` su LIBRO, BUGS, BOX3, BOX5, SCALETTA stessa e i due `.swift` che la citano. **Nessuna citazione trovata, in nessuno dei sei posti, punta a una riga ≥427** (il punto di inserimento più basso): la più alta di tutte è `:356` (LIBRO, ancorata) seguita da `:329` (bare, ma comunque sotto soglia). ⇒ **Zero citazioni rotte da questo giro**, indipendentemente dal fatto che fossero ancorate o nude.

⚠️ **Autocorrezione, dichiarata prima del commit:** avevo scritto una marcatura aggiuntiva non richiesta dal mandato (riferita a un cancello diverso, quello del lavoro non-atomo 4, con un ID `A311` non ancora verificato in quel momento). **Rimossa prima di procedere**, verificato `git diff` vuoto su quel punto: non è mai entrata in un commit.

---

## §3 — Una riga in LIBRO

**[M] Forma misurata dalle righe sorelle di Sezione 2** (tabella a 6 colonne: Data | Decisione | Proposta da | Doc ref | Stato | Superseded da). Nuova riga datata `2026-09-01`, in coda, Stato `attiva` (coerente con l'uso della colonna: «attiva» segna «non superseded/non revocata», non «ratificata» — vedi riga `2026-08-25` sorella, marcata attiva pur essendo «APPROVATO, non ratificato»).

**Testo applicato, verificato byte-per-byte contro il dettato del mandato:** riportato per intero più sotto.

🚨 **Difetto trovato e corretto PRIMA del commit, dichiarato invece che nascosto:** la prima stesura scriveva «…il difetto non è il file **ma** il processo…» — il dettato dice «…il difetto non è il file, **è** il processo…». Trovato dal confronto `cmp` fra il testo dettato e il testo applicato, **prima** di mettere in scena. Corretto, riverificato: `cmp` esce **0**.

---

## Testo applicato — verbatim, le due marcature

### SCALETTA, marcatura in coda alla riga del 07/08 (Sezione C)

> ✅ **MARCATURA 01/09/2026 — IL BUCO DEL 07/08 È COLMATO: ⟦S-EXIT⟧ HA LA SUA SCHEDA.** Le righe sopra restano come scritte: si marca, non si riscrive. La scheda sta in Sezione B ed è il punto **(c)** della scomposizione ratificata il 22/08. ⚠️ **Non chiude il punto (a):** la gamba «**recupero memoria di iOS**» resta **senza prova**, né in codice né su device. ⚠️ **Il punto (d) è aperto:** una delle sue domande — dove si trova il Follower quando il Direttore preme Play col player chiuso — è **senza risposta in ogni documento del progetto**, misurato dal referee il 01/09 su BOX5, LIBRO e i fogli CD.

### LIBRO, nuova riga di Sezione 2 (colonna Decisione)

> **OTTO RATIFICHE DI MAURO DEL 01/09 ESISTONO IN UN SOLO FILE E ATTENDONO RICONFERMA — REGISTRATE, NON RATIFICATE.** Una seconda chat referee, chiusa il 01/09 per decisione di governo di Mauro, ha consegnato un congedo che dichiara **otto ratifiche di Mauro mai incise in nessun canonico**, e le marca da sé «**ricordate, nessuna misurata**». ⛔ **Questa riga NON le ratifica e NON le riporta:** le voci vivono verbatim in `HANDOFF/CASSAFORTE_2026-09-01_ratifiche-non-incise-e-scheda-S-EXIT.md` (Parte A) e in `HANDOFF/CONGEDO_REFEREE_2026-09-01_A308-CONSEGNA-PRIMA-DELLA-CHIUSURA.md`, depositati con questo stesso commit. **Perché non sono incise qui:** sono dichiarate `ricordate` dalla loro stessa fonte, e la **regola ② del 31/08** vieta che un valore ricordato entri in un canonico come misurato. **Condizione per inciderle:** riconferma esplicita di Mauro, voce per voce, e incisione con la provenienza «ricostruita da un congedo di chiusura, non misurata» scritta accanto. 🚨 **Nel frattempo `A308` (DECISIONI_ATTIVE) è CONGELATO, e prima di qualunque OK va eseguita la VERIFICA MECCANICA DEI BACKTICK**: un nome di file fabbricato è stato intercettato in `D-59` e le altre 140 voci vengono dallo stesso processo. ⚠️ Il mandato che la eseguirà deve chiedere **QUANTE**, non solo **SE**: «un'altra» e «trenta» portano a decisioni diverse — nel secondo caso il difetto non è il file, è il processo che l'ha prodotto.

---

## §4 — Il regime, referti ancora fuori

Depositati in questo commit (già presenti su C: e su E: da giri precedenti, mai committati):
- `MISURE_CC_2026-09-01_A307-MARCATURE-CHIUSE-E-ID-RICONCILIATO.md`
- `MISURE_CC_2026-09-01_A308-CENSIMENTO-E-RESA-DECISIONI-ATTIVE.md`
- `MISURE_CC_2026-09-01_A310-CHIUSURA-GIRO-RESTART-SETLIST.md`
- `MISURE_CC_2026-09-01_ARRESTO-AL-CANCELLO_mandato-A304-v5.md`

⚠️ Questo stesso referto (A311) **non** è fra questi: non esisteva ancora al momento del commit — entra nel commit del prossimo giro, stesso regime di A304.

---

## §5 — Commit

**Due commit in questo giro** (non uno solo: il secondo ripara un difetto trovato DOPO il primo, mai in un file già pubblico si riscrive — si ripara aggiungendo):

| | SHA | messaggio | file |
|---|---|---|---|
| commit① | `b7c56f731e20296789bb6a422696f38049b624f0` | `docs: messa in sicurezza congedo+cassaforte, scheda S-EXIT in Sez.B (A311)` | 8 file, 1899 inserzioni / 3 cancellazioni |
| commit② | `a039502bbd15def7e5b4422b5db2b33266118f83` | `fix(scaletta): numero di versione in testa disallineato dalla propria coda, 17->18 (A311)` | 1 file, 1 inserzione / 1 cancellazione |

🚨 **Difetto trovato DOPO commit①, dichiarato:** avevo bumpato la coda della catena di SCALETTA a `(v18)` ma non il campo `**Versione:** 17` in testa alla stessa riga — le due parti dello stesso campo erano rimaste disallineate. Trovato rileggendo il file per comporre questo referto, **dopo** che commit① era già pushato: non si riscrive un commit pubblico, si ripara in un secondo commit additivo (commit②), stessa disciplina della v5 tardiva già a verbale in SCALETTA stessa.

Autore di entrambi: Mauro, zero `Co-Authored-By`. Messa in scena da lista esplicita, verifica bidirezionale (`comm -23`/`-13` vuoti) prima di ciascun commit.

**Bump di versione, dove il file ne ha una:**
- `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`: v17 → **v18** (ora coerente in testa e in coda)
- `LIBRO_MASTRO_QBEATS.md`: v73 → **v74**
- `BUGS_QBEATS.md`: non toccato questo giro, resta v80 — verificato, non per omissione

---

## §6 — Push e CI

Push singolo per ciascun commit (il secondo, per commit②, dopo il primo): `388e577..b7c56f7` poi `b7c56f7..a039502`, entrambi `master -> master`.

**CI sulla punta finale** (`a039502`, che include per definizione anche commit① sotto di sé): run `33548361478`, titolo "fix(scaletta): numero di versione in testa disallineato dalla propria coda, 17->18 (A311)", workflow `iOS Signed Build`. **Esito: SUCCESS, 2m53s.** `headSha` verificato = `a039502...`, coincide con la punta pushata. Annotazioni standard preesistenti (Node 20, Homebrew tap trust), non pertinenti a questo giro.

Per riferimento, CI su commit① isolato (`b7c56f7`, prima che commit② lo seguisse): run `33548184729`, **SUCCESS, 2m40s**. Annotazioni standard preesistenti (Node 20, Homebrew tap trust), non pertinenti.

---

## §7 — L'innesco esatto del rischio dati, prima che Mauro lo usi col telefono in mano

**[M] Ricognizione completa del meccanismo, non solo la prima riga del ticket** — delegata a un agente di ricerca dedicato, che ha letto per intero `Store/QBeatsStore.swift` e tracciato ogni call-site.

**L'innesco reale, in una frase:** `save()` (`QBeatsStore.swift:65-77`, riscrive `songs.json`+`setlists.json`+`backtracks.json` insieme) è chiamato da **dieci** funzioni, non le quattro che il ticket nomina — le quattro su Song (`addSong:83` · `updateSong:89` · `deleteSong:94` · `moveSongs:99`) **più sei non documentate**: `addSetlist:106` · `updateSetlist:112` · `deleteSetlist:117` · `moveSetlists:122` · `upsertBacktrack:138` · `deleteBacktrack:143`. **«Tocchi» e «modifichi» NON sono la stessa cosa**: l'innesco è sempre una **scrittura CRUD** (aggiungi/modifica/cancella/riordina) su Song, Setlist **o Backtrack** — mai una lettura, una vista o una riproduzione. `injectTestData` (`:198-202`) e `resolve()`/`estimatedDuration()` (`:152-168`) non chiamano mai `save()`.

⚠️ **Correzione al ticket, dichiarata qui e non ancora incisa in BUGS** (fuori dal perimetro di questo mandato, materia di un giro a sé): il rischio è più largo di quanto scritto — riordinare gli Show o toccare un Backtrack scrive anche i dati di test iniettati, non solo un tocco su una Song.

**Il giro del collaudo tocca l'innesco? NO — tracciato per intero, zero chiamate.** `Shows → Start → SetlistRunner(store:)` chiama solo `store.resolve()` (lettura). La riproduzione (`SetlistRunner`) tocca solo `audioEngine.*`/`session.*`. END SHOW e BACK TO SHOWS instradano entrambi su `endShowAndLeave()` → `QLiveSession.endShow` (`audioEngine.stop()`, `runner=nil`, `playbackState=.stopped`) — **zero tocco allo store**. `LiveView.swift`, `FineSetlistView.swift`, `QLiveSession.swift` rendono **zero** occorrenze di `QBeatsStore`/`save`/le dieci funzioni; `QLiveShowDetailView.swift` è read-only (`store.resolve` · `store.estimatedDuration`); `QLiveShowsView.swift` si autodichiara «READ-ONLY: nessuna scrittura su QBeatsStore» nel proprio codice.

⇒ **Il passo di collaudo descritto al §6 sotto è sicuro rispetto a questo rischio specifico**, verificato a fonte e non dedotto. Resta valido l'avviso generale di non toccare Song/Setlist/Backtrack per NESSUN altro motivo mentre i dati di test sono in RAM.

---

## §8 — Consegna

Questo referto, su due gambe (`cmp`/sha256 in fondo, misurati dopo il deposito):
- `HANDOFF/MISURE_CC_2026-09-01_A311-MESSA-IN-SICUREZZA-E-SCHEDA-S-EXIT.md` (repo)
- `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-09-01_A311-MESSA-IN-SICUREZZA-E-SCHEDA-S-EXIT.md` (mirror)

⚠️ Sotto il regime A303: entra nel commit del prossimo giro.

### Frase precisa per Mauro, telefono in mano

**Sicuro:** aprire una setlist, premere Start, farla suonare, uscire con END SHOW e poi BACK TO SHOWS. Nessuno di questi passi scrive sul disco al posto dei dati veri.

**Da NON fare, per nessun motivo, finché i dati di test sono caricati:** aggiungere, modificare, cancellare o riordinare una **Song**, una **Setlist**, o un **Backtrack** — in qualunque schermata, anche fuori da Q-Live. Una sola di queste azioni scrive tutti e tre i cataloghi di test sopra quelli veri. Chiudere l'app senza averle toccate = niente è stato scritto.

---

## §9 — Nessuna condizione di arresto

- File mancante, illeggibile o troncato a un capo: **nessuno dei due, verificato aprendo entrambi i capi di entrambi i file**.
- Sezione B senza schede sorelle da cui misurare la forma: **dodici sorelle trovate e lette, forma misurata da loro**.
- Testo applicato non coincidente col dettato: **una discrepanza trovata (§3) — corretta PRIMA del commit, non dopo. Verificato `cmp` = 0 su entrambe le marcature dopo la correzione.**
- Staged e lista non coincidenti: **`comm -23`/`-13` vuoti su entrambi i commit.**
- CI non verde: **non è il caso.**
- Premessa falsa alla misura: **nessuna trovata in questo giro** — a differenza del precedente, dove la falsa premessa era già stata gestita.

🚨 **Un'ottava condizione, non elencata dal mandato ma della stessa famiglia, si è materializzata e va dichiarata: un difetto nel MIO stesso lavoro, trovato DOPO un commit già pubblico** (il numero di versione disallineato di SCALETTA, §5). Non era un arresto previsto dal §9, perché riguarda la mia esecuzione e non una precondizione del mandato — ma la stessa disciplina si applica: **si dichiara, si ripara in coda, non si nasconde e non si riscrive la storia.**

⇒ Nessun cancello del §9 ha fermato il giro. Un difetto proprio, trovato e riparato prima di consegnare.

*A311-MESSA-IN-SICUREZZA-E-SCHEDA-S-EXIT — fine corpo, cmp e sha256 in appendice dopo il deposito su entrambe le gambe.*
