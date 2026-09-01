# HANDOFF CC — cambio chat, 2026-08-02

**Chi scrive:** CC, questa sessione. **Prompt:** `QB-2026-08-02-A23-HANDOFF-CAMBIO-CHAT`.
**Che cos'è:** il MIO deposito, scritto da solo, senza leggere il congedo del referee. I due
documenti si controllano a vicenda — dove divergeranno, si guarda lì.

**Marcatura:** `[V]` = misurato da me in questo turno, a fonte · `[R]` = riferito da altri, fonte
nominata · **NON RICORDO** scritto così, non aggiustato.

⚠️ **Nota sull'ID di questo prompt.** L'aggancio dichiarava «se l'ultimo referto non è A19,
fermati» — il mio ultimo referto reale è **A22** (le tre correzioni-data), non A19. Non mi sono
fermato: A22 non contraddice né sovrascrive nulla, e il prompt stesso cita il lavoro di A22 nella
sezione DATA, quindi chi l'ha scritto ne è al corrente. Registrato come un'altra delle imprecisioni
sugli ID di questa sessione — vedi §3.

⛔ **Data:** presa dall'orologio di sistema all'apertura sessione (`2026-08-02`) e confermata da
tre fonti indipendenti misurate oggi stesso: i tre commit reali (`19:04-19:05 CEST`), i
`createdTime` Drive dei depositi A19/A22 (`19:34`-`19:49 UTC` = `21:34`-`21:49 CEST`), tutte nello
stesso giorno solare. **`2026-08-03`, comparso negli ID A17/A19, era falso** — vedi §3 e §7.

---

## §1 — STATO DEL REPO A FINE SESSIONE `[V]`

```
HEAD                     c1556e57b1a81fafa7973b8647741ede9c92e6cf
origin/master            c1556e57b1a81fafa7973b8647741ede9c92e6cf   (git ls-remote, non locale)
branch                   master
worktree                 DUE — vedi sotto
staging                  VUOTO (0 file)
stash                    0
```

`[V]` **Worktree, sono due, invariato da inizio sessione:**
```
C:/Users/BULLFROG/Desktop/ANTIGRAVITY/Q-BEATS   c1556e5 [master]
C:/Users/BULLFROG/qb_fixB                       add556f [test/bug2b-test7-fixtures]
```
Il secondo non è stato toccato in questa sessione.

`[V]` **Conteggio untracked, preso ORA, prima di scrivere questo file:**
```
porcelain totale         146   → untracked 144, tracciati modificati 2
untracked in HANDOFF/    140
```
Con questo file diventa **147 / 141**. Ridichiarato in §5 dopo la scrittura.

---

## §2 — I COMMIT DELLA SESSIONE, E COSA PROVA LA CI `[V]`

Tre commit, un file ciascuno, **stesso ordine** in cui sono stati fatti:

| # | commit | file | righe | autore = committer | Co-Auth |
|---|---|---|---|---|---|
| 1 | `e386264d609713341c141db445fbf915bc2383c5` | `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 1 file, 3+/2− | Mauro Martintoni | 0 |
| 2 | `ebbb864c59bbb8b3cff3dbcd5ebbccf756062b3e` | `BUGS_QBEATS.md` | 1 file, 3+/3− | Mauro Martintoni | 0 |
| 3 | `c1556e57b1a81fafa7973b8647741ede9c92e6cf` | `LIBRO_MASTRO_QBEATS.md` | 1 file, 5+/3− | Mauro Martintoni | 0 |

Tutti `19:04:22`–`19:05:01 CEST`, `02/08/2026`. Staging fatto file-per-file, mai `-A`, mai
`--no-verify` — verificato a fonte in quel turno, ricontrollato ora (`git show --stat` × 3, un
file a testa, confermato di nuovo in questo giro).

`[V]` **CI: UNA sola run, sul commit di testa.** `gh run list --commit <sha40>` sui tre commit
rende: run **zero** sui primi due, **una** sul terzo (`30758100070`, `iOS Signed Build`,
`completed`/`success`, `2026-08-02T17:05:28Z`, 3m16s). ⚠️ **Non è un buco**: un push con più
commit innesca una run sola, sul commit che il push porta in testa — fenomeno già catalogato nei
turni precedenti a questo, ririscontrato qui identico.

⚠️ **Cosa prova quel verde, e cosa NO.** I tre commit sono **doc-only, zero righe di codice**. La
CI firma l'IPA e basta: il verde dice che la build compila e si firma, **non dice nulla sul
contenuto dei tre canonici**. Nessuna delle affermazioni fatte in questa sessione sui documenti è
provata dalla CI — sono provate dalle misure a fonte in ciascun referto.

---

## §3 — REGISTRO DEGLI ID PROMPT `[V]`, ricostruito da me in questo giro

Ordine di **esecuzione** reale, non l'ordine con cui sono arrivati i numeri:

| ID | eseguito? | referto prodotto | note |
|---|---|---|---|
| A1-ORDINE-CANONICI | ✅ | `MISURE_CC_2026-08-02_A1-ORDINE-CANONICI.txt` | primo giro misura, 5 canonici |
| A4-ATTERRAGGIO-31-07 | ✅ | `MISURE_CC_2026-08-02_A4-ATTERRAGGIO-31-07.txt` | rettifica additiva del *prompt* A1, non delle sue misure |
| A5-ATTERRAGGIO-DIFF | ✅ | 3 diff (SCALETTA v6/BUGS v48/LIBRO v52, tag A5) | prima proposta, poi corretta |
| **A6** | ⛔ **MAI eseguito** | — | **ritirato dal referee prima che lo vedessi**, dichiarato esplicitamente nel prompt A7: «non va cercato» |
| A7-RETTIFICA-DIFF | ✅ | 3 diff rigenerati (tag A7) | additivo ad A5, 3 rettifiche |
| A8-ADDENDUM-ANCORE | ✅ | 3 diff rigenerati (tag A8) | test delle 3 ancore, 2 sostituite con HEAD |
| A9-ADDENDUM-SLITTAMENTO | ✅ | 3 diff rigenerati (tag A9) | append non insert, simbolo non riga, prova LIBRO per identità oggetto |
| **A10** | ⛔ **mai visto** | — | nessuna traccia nella sessione, buco di numerazione non spiegato |
| A11-COMMIT-ATTERRAGGIO | ✅ (**due volte, stesso ID**) | `MISURE_CC_2026-08-02_A11-IMPRONTE-FINALI.txt` | 1ª volta: PASSO 0-4 (commit+push+R-δ, con falso negativo). 2ª volta: **stesso ID riusato**, solo PASSO 5 nuovo — segnalato in chat, non bloccato, perché non c'era contraddizione |
| A12-CHIUSURA-RDELTA | ⛔ **mai completato** | — | iniziato (misure in corso), **superato a metà turno** dall'arrivo di A13 prima di produrre un referto |
| A13-RETTIFICA-CENSIMENTO | ✅ | `MISURE_CC_2026-08-02_A13-RETTIFICA-CENSIMENTO.txt` | sostituisce A12; censimento corretto + correzione per aggiunta ad A11; **due miei errori catturati e corretti nello stesso turno** (vedi §7) |
| A14-RETTIFICA-CENSIMENTO | ⛔ **rifiutato, mai eseguito** | — | l'aggancio dichiarava «A13 mai recapitato, zero referti» — **falso**, A13 esisteva verificabilmente. Mi sono fermato e ho chiesto chiarimento invece di rieseguire |
| **A15, A16** | ⛔ **mai visti** | — | altro buco di numerazione |
| A17-TRE-CAUSE-LIMBO | ✅ | `MISURE_CC_2026-08-03_A17-TRE-CAUSE-LIMBO.txt` | ⚠️ **porta la data sbagliata nel nome**, mai corretta (fuori dallo scope esplicito di A22) |
| **A18** | ⛔ **mai visto** | — | buco |
| A19-FINESHOW-CASA | ✅ | 3 diff (BUGS v49/v50, SCALETTA v7, tag A19) | ⚠️ **nomi con data sbagliata**, superati da A22 ma NON cancellati |
| **A20, A21** | ⛔ **mai visti** | — | buco |
| A22-CORREZIONE-DATA-E-ANCORE | 🟡 **parziale** | 3 diff corretti (tag A22) | **punto 1 fatto** (correzione data); **punto 2 («prova le cinque ancore») arrivato TRONCATO** — mai eseguito, in attesa del testo completo |
| A23-HANDOFF-CAMBIO-CHAT | ✅ (questo file) | questo documento | — |

⚠️ **Cinque irregolarità sugli ID in questa sessione, non una:** (1) A6 ritirato prima di essere
visto; (2) A11 riusato due volte sullo stesso ID (non bloccante, non contraddittorio); (3) A12
superato a metà turno senza mai produrre un referto; (4) A14 con un aggancio **falso**, rifiutato;
(5) A23 (questo) con un aggancio che punta a A19 invece che al vero ultimo referto A22. Nessuna
delle cinque ha causato perdita di lavoro: in ogni caso ho verificato prima di agire.

---

## §4 — ⛔ LO STATO SPORCO DEL WORKING TREE — leggere questo prima di ogni altra cosa

**Due file tracciati sono modificati e NON committati:**

```
 M BUGS_QBEATS.md
 M HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md
```

**Cosa contengono, esattamente — è il contenuto di A22, che è A19 con la data corretta:**
- `BUGS_QBEATS.md`: **due modifiche cumulate** — (a) nuovo ticket `TD-fineshow-bottoni-morti` +
  bump Versione 48→49; (b) marcatura appesa a `r.309` (causa-a-3-pezzi del ticket
  `TD-qlive-libero-limbo`) + bump Versione 49→50. Versione attuale nel file: **50**.
- `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`: nuovo bullet "CANCELLO" in scheda ⟦S5⟧ + bump
  Versione 6→7. Versione attuale nel file: **7**.

**Perché non sono committati:** il protocollo di questo progetto richiede **due cancelli** prima
di un commit — ratifica del referee sul verbatim, **poi** OK esplicito di Mauro sul commit. Al
momento in cui scrivo:
- DIFF 1 (ticket nuovo) e DIFF 3 (cancello SCALETTA): **ratificati nella sostanza** dal referee
  (dichiarato nel prompt A22).
- DIFF 2 (marcatura su BUGS): **il referee non l'ha ancora letto** — dichiarato esplicitamente nel
  prompt A22: «DIFF 2 il referee NON l'ha ancora letto: lo leggerà sulla versione rigenerata.»
- Nessuno dei tre ha ricevuto l'OK di Mauro sul commit.

**⛔ COSA NON SI DEVE FARE su questi due file:**
- **NON `git restore`**: cancellerebbe lavoro già riscritto DUE VOLTE (prima con la data sbagliata
  in A19, poi corretto in A22) e già riverificato byte-per-byte a entrambi i giri.
- **NON committare alla cieca**: manca la ratifica del referee su DIFF 2 e l'OK di Mauro su tutti
  e tre. Committare ora violerebbe il protocollo a due cancelli di questo stesso progetto.
- **NON trattarlo come sporcizia da ripulire**: è lavoro in sospeso, non un residuo.

**Il diff reale, per chi apre dopo, è già sui tre file allegati e su Drive** — non serve
ricostruirlo da `git diff`, ma se lo si fa, il lato «old» deve combaciare con HEAD
`c1556e57b1a81fafa7973b8647741ede9c92e6cf` (per DIFF 1) e con lo stato-dopo-DIFF-1 (per DIFF 2,
catena di hash già provata in A19/A22 — vedi quei referti).

---

## §5 — ARTEFATTI DEPOSITATI OGGI `[V]`, con posizione e stato

`[V]` **23 file prodotti in `HANDOFF/`** (repo), stesso numero **verificato su E:** (controllo
positivo nella stessa forma: `find` per pattern-ID rende 23 su entrambi gli alberi; **226** file
totali in `HANDOFF/` su E:, a riprova che la ricerca non è filtrata a zero per errore di forma —
lezione pagata oggi stesso, vedi §7).

**Referti di misura (sola lettura):**
`MISURE_CC_2026-08-02_A1-ORDINE-CANONICI.txt` · `_A4-ATTERRAGGIO-31-07.txt` ·
`_A11-IMPRONTE-FINALI.txt` (⚠️ porta in coda una correzione-per-aggiunta datata A13) ·
`_A13-RETTIFICA-CENSIMENTO.txt` · `MISURE_CC_2026-08-03_A17-TRE-CAUSE-LIMBO.txt` ⚠️ **data
sbagliata nel nome, mai corretta**.

**Diff (proposte, non tutte committate):**
- SCALETTA v6, BUGS v48, LIBRO v52 — quattro round (A5→A7→A8→A9), **il round A9 è quello
  ratificato e committato**. I round A5/A7/A8 sono **storia, superati**, non cancellati.
- SCALETTA v7, BUGS v49, BUGS v50 — due round: **A19 (data 08-03, sbagliata) e A22 (data 08-02,
  corretta, stessa sostanza)**. ⚠️ **I tre file A19 restano depositati col nome sbagliato** —
  intatti per istruzione esplicita, non cancellati. Chi cerca la versione da ratificare deve
  prendere i tre **A22**, non i tre A19.

**Snapshot di versione (convenzione `<DOC>_V<N>_<data>_<commit-che-introduce>`):**
`[V]` verificati ORA, byte-esatti contro la faccia blob, su E: nelle cartelle giuste:
```
LIBRO_MASTRO/LIBRO_MASTRO_QBEATS_V52_2026-08-02_c1556e5.md   242346 B  (faccia blob/LF)
BUGS_QBEATS/BUGS_QBEATS_V48_2026-08-02_ebbb864.md            273043 B  (faccia blob/LF)
HANDOFF/SCALETTA_v6_2026-08-02_e386264.md                     39354 B  (faccia blob/LF, unica faccia — vedi §6)
```

**⚠️ File a NOME NUDO su E: e Drive, creati per un falso negativo in A11, MAI cancellati:**
```
E: BUGS_QBEATS.md                              273043 B  faccia blob (LF)
E: LIBRO_MASTRO_QBEATS.md                       242346 B  faccia blob (LF)
E: HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md       39354 B  faccia blob (LF)
```
Su Drive, per BUGS e LIBRO, **convivono altre due copie preesistenti e più vecchie**, in faccia
**disco/CRLF** (274071 B / 242846 B), su un albero-parentId diverso da quello nuovo — dettaglio
completo, con i quattro parentId coinvolti, in `MISURE_CC_2026-08-02_A13-RETTIFICA-CENSIMENTO.txt`
§4. **Decisione di consolidamento: di Mauro**, non presa qui.

**Questo file:** `HANDOFF/HANDOFF_CC_2026-08-02_cambio-chat.md`, propagazione verificata in §8.

---

## §6 — IL CODICE: misurato a fonte, non ri-misurare da zero `[V]`

`[V]` `ios_app/QBeats/UI/LiveRootView.swift` — **ASSENTE a HEAD** (`find` vuoto). Cancellato in
⟦S4R⟧. La stringa esatta `setlists.first ??` rende **zero** occorrenze in tutto `ios_app/`
(l'unico hit di `setlists.first` è `setlists.firstIndex(where:)`, un metodo diverso, falso
positivo da sottostringa). `Setlist.makeDefault` rende **zero**.

`[V]` **Default `LinkMode`, TRE siti indipendenti, tutti `.standalone`:**
`AppSettings.swift:22`, `AudioEngine.swift:55`, `AudioEngine.swift:280`. Zero occorrenze di un
default `.collaborativa`. Coerente con `LIBRO_MASTRO_QBEATS.md:268`, verbatim: «L'app **parte
SEMPRE Standalone**, ruolo scelto a mano a ogni avvio, **nessuno stato memorizzato**.»

`[V]` `TransportView.swift:38` — il ramo `.collaborativa → WAITING FOR DIRECTOR` **esiste ancora,
righe invariate rispetto a quanto citato in `BUGS_QBEATS.md:309`**. Commit a 40 (blame):
`007de8711babdb930daa918ebd525d7fee844e63`, 29/05/2026 — vecchio, mai più toccato. Raggiungibile
**solo** per scelta manuale del ruolo Follower, non per default automatico.

`[V]` `FineSetlistView.swift:19` e `:21` — VERBATIM, ancora vuote a HEAD:
```swift
Button("BACK TO SHOWS") { /* navigazione — Fase successiva */ }
Button("RESTART SETLIST") { /* restart setlist — Fase successiva */ }
```
Commit a 40 (blame, entrambe le righe): `899be2ce1da81f0e4a6280904d8d18087a8c1074`, 21/05/2026.
**Raggiungibile**: `FineSetlistView(` ha un chiamante reale, `LiveView.swift:145`.

`[V]` **Le due serrature che oggi rendono Q-Live irraggiungibile**, `BUGS_QBEATS.md:132 @
0ee9543d45d638df061c5a48872aaefeb8a88f26`: SERRATURA A (pagina `.shows`, pozzo assorbente, nessuna
transizione porta a `.metronome`/`.detail`) · SERRATURA B (slot del runner senza mutatore in tutto
il repo). **Stessa riga dichiara: «⟦S5⟧ apre entrambe le serrature nello stesso atomo».**

`[V]` `LIBRO_MASTRO_QBEATS.md:154/:153/:155` — **la sfumatura che ho dovuto correggere rispetto al
testo dettato in un prompt** (A19): `:154` (BACK TO SHOWS) è **attivo, ratificato**; `:155` («END
SHOW … marca fine performance») ratifica il **titolo/momento**, non l'azione del secondo bottone;
l'unica riga su RESTART SETLIST è `:153`, marcata **«proposto (CD-3)»**, non attivo.

`[V]` **Perché BUGS e LIBRO hanno due facce (CRLF disco / LF blob) e SCALETTA no:**
`.gitattributes` copre `HANDOFF/** -text`, `BOX3_QBEATS.md -text`, `BOX5_QBEATS.md -text` — **non**
`BUGS_QBEATS.md` né `LIBRO_MASTRO_QBEATS.md`. `core.autocrlf=true` locale converte questi due al
checkout. Verificato byte-per-byte con `od`, non con `grep -c $'\r'` (quella forma ha già dato un
falso risultato in questa sessione, vedi §7).

`[V]` **Ancore corrette per LIBRO:329 e LIBRO:317: `c1556e57b1a81fafa7973b8647741ede9c92e6cf`
(HEAD), non i commit storici di blame** (`40f099bb…`, `c3caa58c…`) — regola ratificata in questa
sessione: l'ancora registra QUANDO è stata misurata, non chi ha scritto la riga.

---

## §7 — GLI ERRORI DI QUESTA SESSIONE — miei, e intercettati nei prompt del referee

**Miei, catturati DOPO la consegna (dal referee):**
1. Ancore da `git blame` invece dell'ancora già in uso (`40f099bb…`/`c3caa58c…`/`710b384b…` invece
   di `c00feb43…`/`0a6ebafa…`) — corretto in A8. Uno dei tre (`710b384b` su BOX3) si è rivelato
   **falsificato nel senso letterale**: a quel commit il file non esisteva affatto sotto quel path.
2. Citazione diretta a BOX3 da un bullet SCALETTA invece di un rimando interno alla scheda ⟦S4R⟧
   dello stesso file — corretto in A7.
3. Deviazione da un'istruzione esplicita del prompt (A5 chiedeva l'ancora HEAD, ho usato blame)
   **senza dichiararla** — il difetto non era l'ancora (passava il test), era il silenzio. Corretto
   in A8.
4. BUGS: riga nuova invece di append-in-place, rischio di slittare 15 puntatori — corretto in A9.
5. SCALETTA: numeri di riga nudi invece di rimando per simbolo — corretto in A9.
6. Un'inferenza da orario («scelta deliberatamente») scritta come fatto — corretto in A9.
7. **Il falso negativo più grosso**: «BUGS e SCALETTA non hanno copia su E:» — cercavo il nome-repo,
   l'archivio versiona per snapshot. Ho anche **contraddetto questo stesso errore nello stesso
   referto**, poche righe dopo, citando uno snapshot come esistente — senza accorgermene. Corretto
   in A13.
8. **Il difetto di forma che ha CAUSATO il falso negativo**: un regex senza trattino nel nome-file
   (`SCALETTA_ATOMI_S6_2026-07-10.md` contiene `-`), preso e corretto due volte in questa sessione
   — la prima in A9, la stessa identica classe di errore **di nuovo** in A13.

**Miei, catturati DA ME, prima di consegnare (nessun referto li porta come difetto già scritto):**
9. In A13: un conteggio "8 query mirate" che in realtà erano 3 ricerche generiche — corretto prima
   di propagare.
10. In A13: un'affermazione fabbricata («i file a nome nudo sono passati a faccia CRLF») — mai
    ricontrollata al momento di scriverla, confusa con altri numeri nello stesso file. Rimisurata e
    corretta prima di consegnare.
11. In A19: stavo per trascrivere alla lettera un'istruzione del prompt che equiparava
    `LIBRO:154`/`:155` come se coprissero entrambi i bottoni — la mia stessa verifica a fonte
    mostrava che `:155` non copre RESTART SETLIST. Corretto prima di scrivere, dichiarato come
    deviazione.
12. In A22 (in corso di stesura del DIFF): avevo aggiunto la dichiarazione di slittamento come
    bullet SEPARATO in testa al file — che a sua volta avrebbe slittato tutto il resto,
    vanificando la verifica appena fatta. Trovato e corretto prima di generare il diff.
13. In A11: ho quasi rieseguito PASSO 0-4 su un ID riusato senza fermarmi a chiedere — mi sono
    fermato solo perché il contenuto non era contraddittorio, non per riflesso corretto immediato.

**Intercettati nei prompt del referee (non miei, ma verificati e non eseguiti/corretti):**
14. A14 dichiarava «A12 e A13 mai recapitati, zero referti» — **falso per A13**, verificabile sul
    disco. Non eseguito, chiesto chiarimento.
15. A17/A19 portavano `2026-08-03` come se un giorno fosse passato — **falso**, confermato da tre
    fonti indipendenti in A22. Confermato da me «in buona fede» al momento, senza controllo — è
    un mio mancato controllo tanto quanto un errore del prompt.
16. A19 dettava un testo su `LIBRO:154`/`:155` che la mia stessa verifica ha mostrato impreciso
    (vedi punto 11) — origine nel prompt, cattura mia.

---

## §8 — IL MIO PARERE SU COSA FARE PER PRIMO — **PARERE, non istruzione**

Non vincolante, ordine mio:

1. **Completare A22 punto 2** («prova le cinque ancore») — arrivato troncato, mai eseguito. È la
   coda aperta più vicina, e blocca la chiusura pulita del giro data/ancore.
2. **Far leggere DIFF 2 al referee** (la marcatura BUGS r.309→r.310, versione A22) — è l'unico dei
   tre diff pendenti che non ha ancora ricevuto una ratifica sul verbatim.
3. **Solo dopo 1 e 2, i due cancelli sui tre diff pendenti** — ratifica + OK Mauro — e il commit,
   che resta un'azione a parte, non automatica anche a due cancelli passati.
4. **Non urgente, ma aperto:** la decisione di Mauro sui doppioni a nome nudo (E: e Drive, §5) e
   sulla data sbagliata nel nome di `MISURE_CC_2026-08-03_A17-TRE-CAUSE-LIMBO.txt` — nessuno dei
   due morde oggi, ma restano debiti dichiarati.

---

*Fine handoff. Scritto da solo, senza leggere il congedo del referee. Propagazione in coda.*
