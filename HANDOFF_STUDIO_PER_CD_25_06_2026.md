# HANDOFF STUDIO PER CD — 25/06/2026
### Documento di lavoro — da Mauro a Claude Design (CD)
### Fonte: audit del codice a master `0d626de` (§7 FONTE-O-NIENTE) + LIBRO_MASTRO v19 + BOX5 V24

> **Come leggere questo documento.** È l'unica fonte di verità che CD riceve: CD non ha accesso al codice. Ogni vincolo del modello è accompagnato dalla riga di codice **verbatim** tra parentesi, per riferimento. Il documento dice *cosa esiste sotto* e *cosa va progettato* — **non** come deve essere fatto. Wireframe, flussi e scelte estetiche sono lavoro di CD.

> **NB (post-25/06/2026):** "Studio" in questo brief = il container **authoring**, ora rinominato **Q-Stage** (identificatore tecnico `QStageRootView`). Il nuovo container **Q-Studio** (pratica/esercitazione, non ancora costruito) è una cosa **separata**. Mappa nomi canonica: LIBRO_MASTRO v21 sez. 1.

---

## SEZIONE 1 — COS'È STUDIO E PERCHÉ SERVE

Q-BEATS ha due metà:
- **Q-LIVE** (la "coda"): la modalità da palco. È **costruita e funziona** — metronomo, teleprompter, backtrack, sync Link, transport. Validata su device.
- **STUDIO / Q-STAGE** (la "testa"): è dove l'utente **crea le canzoni e costruisce le scalette**. Oggi è un **guscio vuoto**: una schermata nera con scritto "Q-STAGE — in costruzione" (verbatim `QStageRootView.swift:9` → `Text("Q-STAGE — in costruzione")`).

**Il problema da risolvere:**
- Tutto quello che va in Q-LIVE deve passare per Studio.
- Oggi **non c'è modo per l'utente di creare, modificare o scegliere niente**. La scaletta che finisce in Live arriva da un *fallback di sviluppo*: il motore prende "la prima scaletta che trova, o una vuota" (verbatim `LiveRootView.swift:7-9` → `SetlistRunner(setlist: QBeatsStore.shared.setlists.first ?? Setlist.makeDefault(), store: .shared)`).
- I dati di test oggi vengono **iniettati** solo in DEBUG (verbatim `QBeatsStore.swift:120` → `func injectTestData(...)` dentro `#if DEBUG`). Non è un flusso utente.

**In una frase:** Studio è il pezzo che trasforma Q-BEATS da prototipo funzionante (un motore che sa suonare) ad app completa (un'app dove l'utente prepara i propri show e poi li suona).

**Buona notizia per il design:** il *motore dati* sotto Studio **esiste già ed è solido** (modello, salvataggio, operazioni, import/export — vedi §2 e §3). Studio è "da zero" **solo sullo strato delle schermate**. CD progetta interfacce sopra fondamenta che già reggono.

---

## SEZIONE 2 — IL MODELLO DATI (cosa esiste sotto)

Tre entità: **Song** (canzone), **SongSection** (sezione di una canzone), **Setlist** (scaletta/show). Tutte sono strutture salvabili (`Codable`) e con identità univoca (`Identifiable`).

### CANZONE (`Song`) — file `Models/Song.swift`
Rappresenta una canzone del catalogo.

- **Identità interna** — un codice univoco generato dal sistema, non visibile né modificabile dall'utente *(codice: `var id: UUID`)*.
- **Nome** — il titolo della canzone (es. "Intro", "Pezzo Forte") *(codice: `var name: String`)* — **editabile**.
- **Sezioni** — la lista **ordinata** delle parti della canzone (intro, strofa, ritornello…). Una canzone **ha N sezioni** *(codice: `var sections: [SongSection]`)* — **editabile** (si aggiungono/tolgono/riordinano sezioni).
- **Count-in** — quante battute di conteggio prima di partire: `0` = nessuno, `1` = una battuta, `2` = due battute *(codice: `var countIn: Int  // 0=nessuno, 1=1 battuta, 2=2 battute`)* — **editabile**.
- **Base audio** — il **nome del file** audio associato, se c'è (opzionale). Non è il file: è il suo nome; il file vive nella cartella `Backtracks/` del dispositivo *(codice: `var backtrackFilename: String?`)* — **editabile** (associare/togliere una base).

> Una canzone "di default" nasce con nome **"New Song"**, una sola sezione, count-in 1, nessuna base *(codice: `Song.makeDefault()` → `name: "New Song"`)*.

### SEZIONE DI UNA CANZONE (`SongSection`) — file `Models/SongSection.swift`
Rappresenta una parte di una canzone (es. Intro, Chorus). È **l'unità che porta i parametri musicali**.

- **Identità interna** *(codice: `var id: UUID`)* — interna, non utente.
- **Nome** — il nome della sezione (es. "Intro", "Chorus") *(codice: `var name: String`)* — **editabile**.
- **BPM** — il tempo della sezione (battiti al minuto) *(codice: `var bpm: Double`)* — **editabile**.
- **Battute per misura** — quanti beat ci sono in una misura (es. 4 per un 4/4, 3 per un 3/4) *(codice: `var beatsPerBar: UInt32`)* — **editabile**.
- **Unità di battito** — il denominatore della metrica (il "4" di 4/4) *(codice: `var beatUnit: UInt32`)* — **editabile** (default 4).
- **Ripetizioni** — quante volte si ripete la sezione. **Attenzione al valore speciale: `-1` = loop infinito** *(codice: `var repetitions: Int  // -1 = loop infinito (sentinel, non genericamente < 0)`)* — **editabile**.
- **Note** — testo libero della sezione *(codice: `var notes: String`)* — **editabile**.
- **Pattern accenti** — quali beat sono accentati. È una lista di numeri, **uno per beat**. Significato di ciascun numero: `2` = accento, `1` = beat normale, `0` = sottosuddivisione/silenzioso *(codice: `var accentPattern: [UInt8]`; mappatura ratificata in BOX5 V24: `2→"accent"`, `1→"beat"`, `0→"subdiv"`)* — **editabile**.
- **Moltiplicatore di suddivisione** — quante sottosuddivisioni per beat (audio-only, **nessun impatto visivo** — BOX5 V24) *(codice: `var subdivisionMultiplier: UInt8`)* — **editabile**.
- **Swing** — il rapporto di swing *(codice: `var swingRatio: Double`)* — **editabile**.

> Sezione di default: nome "Sezione", 120 BPM, 4/4, 1 ripetizione, accenti `[1,0,0,0]` *(codice: `SongSection.makeDefault()`)*.

> ⚠️ **PUNTO CRITICO PER CD — il modello NON valida la coerenza accenti↔battute.**
> Quando una sezione viene letta dal file, il numero di battute e il pattern di accenti sono letti **in modo indipendente**, senza alcun controllo che combacino *(codice `SongSection.swift:40-52`: il decoder legge `beatsPerBar` e `accentPattern` come campi separati, nessun `guard` che leghi `accentPattern.count` a `beatsPerBar`)*. Oggi è quindi possibile avere una sezione **con 4 battute e 3 accenti** — un dato incoerente che il sistema accetta in silenzio.
> **Conseguenza per il design:** l'editor della sezione deve **impedire a livello di interfaccia** di salvare una sezione dove il numero di accenti non corrisponde alle battute. Il numero di "caselle accento" deve seguire automaticamente il valore "battute per misura". CD deve prevedere questo comportamento nell'editor.

### SCALETTA / SHOW (`Setlist`) — file `Models/Setlist.swift`
Rappresenta una scaletta (uno show: l'ordine delle canzoni di una serata).

- **Identità interna** *(codice: `var id: UUID`)* — interna, non utente.
- **Nome** — il nome dello show (es. "Milano 2026") *(codice: `var name: String`)* — **editabile**.
- **Data** — la data dello show *(codice: `var date: Date`)* — **editabile**.
- **Canzoni** — la lista **ordinata** delle canzoni della serata, **referenziate per identità (ID), non per copia** *(codice: `var songIDs: [UUID]  // ordine della serata — referenze al catalogo`)* — **editabile** (si scelgono e si riordinano).

> **Relazione fondamentale:** una scaletta **non contiene** le canzoni, le **punta** tramite il loro ID. Le canzoni vivono nel catalogo (la libreria canzoni); la scaletta è un elenco ordinato di puntatori. Conseguenza pratica: se una canzone viene cancellata dal catalogo, la scaletta che la puntava ha un "buco" (vedi §8, decisione D14).
> Show di default: nome **"New Show"**, data odierna, **zero canzoni** *(codice: `Setlist.makeDefault()` → `songIDs: []`)*.

---

## SEZIONE 3 — OPERAZIONI DISPONIBILI (cosa sa già fare il sistema)

Tutte queste operazioni **esistono già** nel sistema di salvataggio (`Store/QBeatsStore.swift`). Ognuna salva automaticamente su disco. **CD non deve progettarle — deve progettare le schermate che le richiamano.** Il nome del metodo è solo un riferimento per chi scrive il codice (CC).

### CANZONI (catalogo)
- **Crea canzone** — aggiunge una nuova canzone al catalogo e salva *(`addSong`)*.
- **Modifica canzone** — aggiorna una canzone esistente e salva *(`updateSong`)*.
- **Cancella canzone** — rimuove una canzone e salva *(`deleteSong`)*.
- **Riordina canzoni** — cambia l'ordine nel catalogo e salva *(`moveSongs`)*.

### SCALETTE / SHOWS
- **Crea scaletta** — aggiunge un nuovo show e salva *(`addSetlist`)*.
- **Modifica scaletta** — aggiorna uno show esistente e salva *(`updateSetlist`)*.
- **Cancella scaletta** — rimuove uno show e salva *(`deleteSetlist`)*.
- **Riordina scalette** — cambia l'ordine della libreria show e salva *(`moveSetlists`)*.

### SUPPORTO
- **Risolvi scaletta** — data una scaletta, restituisce le canzoni reali trovate **e l'elenco di quelle mancanti** (puntate ma non più nel catalogo) *(`resolve` → ritorna `(songs, missingIDs)`)*. È il meccanismo che oggi rileva le canzoni mancanti.
- **Durata stimata** — calcola la durata totale di una scaletta *(`estimatedDuration`)*.
- **Carica / Salva tutto** — legge e scrive il catalogo su disco in modo affidabile e atomico *(`load` / `save`)*.

### IMPORT / EXPORT (già funzionante — `QBeatsBackupManager.swift` + `ImportView.swift`)
- **Esporta** — crea un **archivio `.qbeats` (un file ZIP)** che contiene: impostazioni + canzoni + scalette + (opzionale) i file audio delle basi *(`export` → produce un file `QBeats_<data>.qbeats`)*.
- **Importa** — apre un archivio `.qbeats`, mostra **cosa contiene**, e lascia scegliere **quali** canzoni/scalette/audio importare; gestisce i **doppioni** (se un ID esiste già, importa con nuovo nome "(importato <data>)") *(`parse` + `importSelected`; UI completa in `ImportView.swift`)*.

> **Nota per CD:** oggi l'import è un **backup/restore dell'intera libreria** (tutto in un archivio), non "importa una singola scaletta condivisa da un altro musicista". È però la stessa macchina (ZIP + indice + audio) e già funziona. Dove collocare import/export nella navigazione di Studio è una **domanda di design aperta** (vedi §11).

> ⚠️ **ATTENZIONE — due cose diverse si chiamano "manifest / manifesto". NON confonderle:**
> - Il **"manifest" dell'import/export** (quello qui sopra) è l'**indice di un backup**: versione, data, elenco dei contenuti dell'archivio `.qbeats`. **Esiste già** nel codice (`BackupManifest`). Non contiene alcun hash del contenuto.
> - Il **"manifesto" della validazione** (§8, decisione D4) è **un'altra cosa, ancora tutta da costruire**: è **per-scaletta** e porta l'**impronta/hash del contenuto** che serve a dire "questa scaletta è integra / è quella approvata".
> **Non sono lo stesso oggetto e non condividono codice.** Quando in §8 si legge "manifesto", non è il manifest del backup.

---

## SEZIONE 4 — IL FLUSSO DELL'APP (da Studio a Live)

Il percorso che l'utente segue, dalla creazione alla performance:

```
1. CREA CANZONE in Studio
   → definisci le sezioni (nome, BPM, battute, accenti, ripetizioni, swing…)
   → associa una base audio (opzionale)
   → salva

2. COSTRUISCI SCALETTA (SHOW) in Studio
   → scegli le canzoni dal catalogo
   → ordinale nell'ordine della serata
   → dai un nome allo show
   → salva

3. SELEZIONA SCALETTA per il Live   ← F2.3, il PONTE (oggi NON esiste)
   → scegli quale scaletta suonare
   → la scaletta selezionata va nel motore Q-LIVE

4. VAI IN LIVE (Q-LIVE)
   → suona
```

> **Il passo 3 è il punto in cui testa e coda dell'app si congiungono.** Oggi è un **DEV FALLBACK**: il motore prende automaticamente la prima scaletta o una vuota (verbatim `LiveRootView.swift:7-9`). Non c'è scelta utente. F2.3 è la schermata che **ritira questo fallback**. Finché F2.3 non esiste, non c'è modo per l'utente di decidere cosa suonare.

---

## SEZIONE 5 — LE SCHERMATE DA PROGETTARE

Cinque schermate, tutte già nel backlog di BOX5 V24. Per ciascuna: cosa fa, quali dati mostra, quali azioni offre (mappate alle operazioni di §3), vincoli noti, domande aperte. **CD progetta layout/flusso/estetica — qui ci sono solo gli ingredienti.**

### F2.4 — Libreria Canzoni *(priorità 🔴)*
- **Cosa fa:** mostra l'elenco di tutte le canzoni del catalogo; da qui si gestiscono.
- **Dati mostrati:** per ogni canzone, almeno il **nome** (`Song.name`); utili anche numero di sezioni (`Song.sections.count`) e presenza base audio (`Song.backtrackFilename != nil`).
- **Azioni:** Crea (`addSong`), Modifica/apri editor (`updateSong`), Cancella (`deleteSong`), Riordina (`moveSongs`).
- **Vincoli noti:** —
- **Domande aperte:** vedi §11.

### F2.5 — Editor Canzone *(priorità 🔴)*
- **Cosa fa:** la schermata dove si definisce una canzone e **tutte le sue sezioni**.
- **Dati mostrati:** nome canzone, count-in, base audio associata; e **per ogni sezione** tutti i parametri di §2 (nome, BPM, battute per misura, unità, ripetizioni, note, pattern accenti, suddivisione, swing).
- **Azioni:** modifica i campi della canzone; **aggiungi / modifica / riordina / cancella sezioni**; **associa una base audio** (rimanda alla Libreria Backtrack — vedi F2.6); salva (`updateSong`).
- **Vincoli noti (OBBLIGATORI):**
  - Il numero di **caselle accento deve seguire automaticamente le "battute per misura"**: non si può salvare una sezione con accenti ≠ battute (vedi §2, punto critico). Valori accento ammessi: accento / beat / suddivisione (2/1/0).
  - **Ripetizioni = loop infinito** è un valore speciale (`-1`): l'interfaccia deve permettere di esprimere "∞" in modo chiaro, distinto da un numero.
- **Domande aperte:** come si aggiungono le sezioni (pulsante "+" o flusso guidato)? — vedi §11.

### F2.6 — Libreria Backtrack *(priorità 🟡)*
- **Cosa fa:** gestione dei file audio (le basi).
- **Dati mostrati:** elenco dei file audio disponibili (vivono nella cartella `Backtracks/` del dispositivo); a quali canzoni sono associati.
- **Azioni:** **importa** un file audio, **cancella** un file, **associa** un file a una canzone (collega `Song.backtrackFilename`).
- **Vincoli noti:** una canzone referenzia la base **per nome di file** (`backtrackFilename: String?`), non per copia. Streaming **vietato** dal motore (le basi sono file locali, BOX5 V24).
- **Domande aperte:** è una schermata separata o è integrata nell'Editor Canzone come "selettore audio"? — vedi §11.

### F2.7 — Gestione Setlist / Libreria Shows *(priorità 🔴)*
- **Cosa fa:** mostra l'elenco di tutte le scalette (show); da qui si gestiscono, e si modifica la lista canzoni di ciascuna.
- **Dati mostrati:** per ogni show: **nome** (`Setlist.name`), **data** (`Setlist.date`), numero/ordine canzoni (`Setlist.songIDs`). Dentro lo show: l'elenco ordinato delle canzoni (risolte dal catalogo via `resolve`), **con eventuali mancanti evidenziate**.
- **Azioni:** Crea (`addSetlist`), Modifica (`updateSetlist`), Cancella (`deleteSetlist`), Riordina shows (`moveSetlists`); **scegli/ordina/togli le canzoni** dentro lo show (modifica `Setlist.songIDs`).
- **Vincoli noti:**
  - **Due scalette non possono avere lo stesso nome** (regola anti-confusione — vedi §8 D9/D10). Il vincolo si verifica **al salvataggio**: se il nome collide, l'utente deve cambiarlo; altrimenti salva.
  - Stato visivo **rosso/verde** della scaletta (vedi §8 — requisito di validazione).
- **Domande aperte:** vedi §11.

### F2.3 — Selezione Setlist (il PONTE Studio→Live) *(priorità 🔴)*
- **Cosa fa:** si sceglie quale scaletta portare in Q-LIVE. **Ritira il DEV FALLBACK.**
- **Dati mostrati:** elenco scalette selezionabili (nome, data); **stato rosso/verde** (solo le verdi possono andare in Live — vedi §8).
- **Azioni:** seleziona una scaletta → entra in Q-LIVE con quella scaletta.
- **Vincoli noti:** **una scaletta rossa NON può entrare in Live** (§8 D2). Esiste già il nome ratificato **"Select Setlist"** per il picker (LIBRO_MASTRO sez. 1).
- **Domande aperte:** è una schermata a sé o è integrata nella transizione Studio→Live? — vedi §11.

> **Promemoria backlog (BOX5 V24):** "Schermate CD mancanti (bloccano CC): Selezione Setlist · Lista Canzoni · Editor Canzone · Lista/Editor Setlist · Libreria Backtrack". Sono esattamente queste cinque.

---

## SEZIONE 6 — NOMI E CONVENZIONI GIÀ RATIFICATE (non reinventare)

Tutte verificate in `LIBRO_MASTRO_QBEATS.md`. **CD deve usare questi nomi.**

| Nome / regola | Dove ratificato | Stato |
|---|---|---|
| **STUDIO → Q-STAGE** | 19/05 sera, commit `63831de` (LIBRO riga 190) | attiva — **in attesa test su device** |
| **LIVE → Q-LIVE** | 19/05 sera, commit `63831de` | attiva — in attesa test su device |
| **Setlist → Shows** | 19/05 sera, commit `63831de` | attiva — in attesa test su device |
| **Canzoni → Songs** | 19/05 sera, commit `63831de` | attiva — in attesa test su device |
| **Default name "New Show" / "New Song"** | commit `63831de` (LIBRO riga 191) | attiva (confermato nel codice `makeDefault()`) |
| **UI tutta in inglese** (anche Settings/MIDI futuri) | 21/05 R-CD5-10 (LIBRO riga 208); rename Swift completato in `cf3f0b5` | attiva |
| **KILL TRACK** (rinomina di KILL BASE) | 21/05 Q5=B / R-CD5-07 (LIBRO righe 130, 206) | attiva |
| **END SHOW** (era FINE SHOW) | 21/05 R-CD5-10 (LIBRO riga 140) | attiva |
| **BACK TO SHOWS** (era TORNA AGLI SHOWS) | 21/05 R-CD5-10 (LIBRO riga 139) | attiva |
| **NEXT** (era PROSSIMA) | 21/05 Q11=A (LIBRO riga 222) | attiva |
| **EMERGENCY** (era EMERGENZA) | 21/05 Q12=A (LIBRO riga 142) | attiva |
| **START LOCAL** + **CANCEL** (in WAITING FOR DIRECTOR) | 27/05 CD-Q2=B (LIBRO riga 143) | attiva |
| **Select Setlist** (picker scaletta per il Live) | LIBRO sez. 1 (riga 102) | attiva |

> ⚠️ **Incongruenza doc segnalata (non è una decisione, è un refuso da sapere):** alcuni documenti/codice più vecchi mostrano ancora **"KILL BASE"** (es. BOX5 V24 sezione Transport). Il nome **ratificato e attivo è KILL TRACK**. Vale la ratifica, non il refuso.

---

## SEZIONE 7 — DECISIONI DI DESIGN GIÀ PRESE CHE TOCCANO STUDIO

| Decisione | Dove | Cosa implica per il design |
|---|---|---|
| **Modalità collaborativa: default Standalone + opt-in ruoli manuali** (CD-7, 12/06) | LIBRO_MASTRO v19 (ridisegno modalità collaborativa) | Studio/Settings devono presentare i ruoli (Direttore/Follower) come **scelta opzionale**, non imposta. Default = Standalone. |
| **Count-in sempre al Resume** dopo STOP a metà song (Q3=A, 21/05) | LIBRO riga 151, 209 | Riguarda Q-LIVE; rilevante perché il **count-in è una proprietà della canzone** (§2 `countIn`) che Studio fa impostare. |
| **`.stoppedMidSong` come stato distinto** da `.stopped` (Q4=A, 21/05) | LIBRO righe 154, 212 | Riguarda Q-LIVE (gli stati di esecuzione); informativo per CD sulla coerenza degli stati. |
| **Default modalità Link = `.collaborativa`** (non `.direttore`), commit `cb92faa` (24/05) | BOX5 V24 (invariante Link) | La modalità è una **impostazione**, non una scelta per-scaletta. Studio non deve duplicarla a livello di show. |

---

## SEZIONE 8 — LE 15 DECISIONI SULLA VALIDAZIONE (requisiti per il "Salva")

Queste sono le **15 decisioni ratificate** nella sessione validazione setlist (25/06). **L'implementazione del codice è IN STANDBY**, ma le decisioni sono **vincolanti come requisiti**: il design delle schermate di Studio deve già prevederle (soprattutto lo **stato visivo rosso/verde** della scaletta e il comportamento del **Salva**).

1. Si costruisce prima la validazione all'import (prima linea), poi il gate al Play (seconda linea / rete di sicurezza).
2. Separazione **ARCHIVIARE** (una scaletta rotta può entrare in archivio, segnata **rossa**) vs **ARMARE PER IL LIVE** (solo **verde**). Principio fondante: *"tutto quello che entra in Live dev'essere plug and play."*
3. Per verificare l'integrità di un file audio si usa un'**impronta digitale del contenuto** (hash), non il peso in KB. Il peso si tiene come informazione, non come giudice.
4. **Due livelli di verifica:** il **manifesto** viaggia *dentro* la scaletta ("la scatola contiene quello che dice l'etichetta"); lo **scontrino** resta su QB nel proprio archivio locale ("è lo stesso prodotto che avevi approvato"). Il manifesto viaggia col file, lo scontrino no. *(⚠️ Questo "manifesto" — con hash, da costruire — NON è il "manifest" del backup/restore di §3, che è solo l'indice di un archivio `.qbeats` già esistente. Due oggetti diversi, stesso nome.)*
5. **Migrazione del pregresso:** le scalette che esistono già non hanno manifesto. Alla prima apertura post-funzione, QB lo genera dal contenuto attuale. "Manifesto mancante" = uno dei motivi di rosso.
6. Quando la scaletta del Follower è **incompleta** e il Direttore preme Play, il Follower **si rifiuta di partire e avvisa**. Non parte con un avviso — si ferma. (Opzione A.)
7. Il **confronto Follower↔Direttore** ("scaletta diversa ma integra") è **fuori scope**: richiede un canale di rete proprietario (Soluzione C, futuro). Il manifesto risolve "rotta", non "sbagliata".
8. Si **progetta su carta prima** di scrivere codice. Si implementa **a pezzi**.
9. **Due scalette non possono avere lo stesso nome** (regola anti-confusione). Ma l'identità vera è l'impronta (hash), non il nome.
10. **Rename alla riparazione: NON forzato.** È il vincolo "nome unico al salvataggio" — se collide rinomini, altrimenti salvi e basta.
11. La **fondazione è LOCALE**, senza rete. Il protocollo tra device è a valle e trasmette solo l'impronta (poche cifre).
12. **Tre momenti di verifica:** all'import, alla modifica, all'**armamento per il Live**. Il terzo intercetta danni esterni a QB (storage guasto, sync interrotta, file corrotto da solo).
13. **Scaletta senza manifesto** (vecchie, import esterno, manifesto danneggiato): "manifesto mancante" = rosso → l'utente conferma → QB genera il manifesto → verde.
14. Una scaletta **verde diventa rossa in automatico** quando il contenuto cambia (l'impronta cambia, lo scontrino non torna più). *"Una scaletta modificata è una scaletta nuova."* Non serve un meccanismo separato: lo fa l'impronta.
15. Il **protocollo futuro tra device** farà **entrambe le cose**: confronto E trasferimento. Confronto prima (più piccolo), trasferimento dopo. La fondazione locale serve a entrambi.

> **Cosa significa per il design di CD (concreto):**
> - Ogni scaletta ha uno **stato visivo rosso/verde**; **solo le verdi** possono andare in Live (schermata F2.3 e F2.7).
> - Il **Salva** di una canzone/scaletta è il momento in cui nasce il manifesto e si verifica il nome unico. Il design del "Salva" deve riflettere questo (es. avviso se il nome collide).
> - Una scaletta rossa va **mostrata in archivio** ma **bloccata dal Live**, con un modo per l'utente di "ripararla" e farla tornare verde.
> - CD progetta **il visivo** dello stato (icona? fascia? colore di sfondo? bollino?) — **non** il meccanismo dell'hash sotto.

---

## SEZIONE 9 — COSA CD NON DEVE PREOCCUPARSI DI

- **Il motore audio** (Layer 1/2 — DSP, click, Link, MIDI): esiste, funziona, validato. CD non lo tocca. Regola di progetto: *qualsiasi problema visivo si risolve solo in Layer 3, mai nel motore* (BOX5 V24).
- **Il thread real-time:** non esiste in Studio. Studio è tutto interfaccia (Layer 3).
- **Il protocollo tra device** (Soluzione C / confronto-trasferimento): futuro, non impatta il design di Studio adesso.
- **I bug parcheggiati** (indicatore LED Direttore, rallentamento Control Center): cosmetici/sospesi, non impattano Studio.
- **Il salvataggio su disco** (lo Store): esiste e funziona (JSON + iCloud, atomico). CD progetta la UI sopra.
- **Come funziona l'hash/impronta internamente:** CD progetta il **visivo** (rosso/verde, riparazione), non il meccanismo.

---

## SEZIONE 10 — TOKEN VISIVI E PATTERN UI ESISTENTI (coerenza con Q-LIVE)

Da rispettare per coerenza con la parte Live già costruita. Verificati su `BOX5_V24` + codice.

**Identità / vincoli di base:**
- **Portrait obbligato su tutti i device** (iPhone + iPad universal). Landscape rimandato a v2 *(BOX5 V24; Info.plist: unica orientation `UIInterfaceOrientationPortrait`)*.
- iOS minimo 16.0; iCloud container `iCloud.com.bullfrog.qbeats`.

**Font:**
- **JetBrains Mono** — il font principale, pesi Bold / SemiBold / Medium / Regular *(codice `Font+JBMono.swift`: `JetBrainsMono-Bold/-SemiBold/-Medium/-Regular`)*. Usato per nomi, BPM, contatori, label.
- **Inter** — per i testi grandi: **Inter-Black** (teleprompter giant text, overlay standby) e **Inter ExtraBold** (zona NEXT) *(BOX5 V24, righe 166, 181, 221)*.
- Font di sistema SwiftUI per alcune label minori.

**Palette (hex verificati nel codice + BOX5 V24):**
- **Sfondo profondo:** `#0e0e10` (usato come background ovunque: Splash, Studio, Bivio, Live).
- **Superficie / pannelli:** `#16161a` (token "Surface" — pannello mixer, capsule, card del Bivio).
- **Accento metronomo / verde "acceso":** `#28cd41` (BOX5 V24 riga 144) e `#00c96e` (indicatori LiveHeader).
- **Ambra / mute / Direttore:** `#f5b820`.
- **Blu (badge ruolo):** `#2a6bd6`.
- **Arancio (accento Bivio):** `#d43f00`.
- **Rosso (stop / kill):** `#ff3b30`.
- Beat bianco 85%, suddivisione bianco 20%, off bianco 8% (BOX5 V24).
> Lo stato **rosso/verde** delle scalette (§8) dovrà scegliere tra questi rossi/verdi esistenti o un loro derivato — decisione di CD (§11).

**Scaling responsive (pattern obbligatorio):**
- Tutto si scala con un fattore `scaleFactor = larghezza_schermo / 390` (baseline **390pt** = iPhone 13 portrait, misurata empiricamente) *(codice `LiveView.swift:82`: `let scaleFactor: CGFloat = geo.size.width / 390`; BOX5 V24)*. Su iPad il fattore cresce (~1.9 iPad mini, ~2.6 iPad Pro 12.9").
- Le dimensioni font si esprimono come **`pt_originale * scaleFactor`** (la pt di design resta visibile).
- **Spacing < 20pt e dimensioni di tocco (hit-target)** restano in **pt assoluti** (non scalati).
- **API VIETATE per lo scaling:** `@ScaledMetric`, `UIFont.preferredFont`, `Font.preferredFont`, `@Environment(\.sizeCategory)` — sono legate al Dynamic Type accessibility, non alla dimensione del device *(BOX5 V24)*.

---

## SEZIONE 11 — DOMANDE APERTE PER CD

Servono risposte di CD **prima** che CC possa implementare:

1. **Stato rosso/verde di una scaletta — come appare?** Icona, fascia laterale, colore di sfondo, bollino? Dove sta nelle liste (F2.3, F2.7)? Come si comunica "rossa = riparabile, non entra in Live"?
2. **F2.3 (Selezione Setlist):** è una schermata a sé stante oppure è integrata nella transizione Studio→Live (es. parte del bivio / di un menu)?
3. **Editor Canzone (F2.5):** le sezioni si aggiungono con un "+" semplice o con un flusso guidato? Come si presenta l'editor dei **pattern accenti** (le caselle che devono seguire le battute)? Come si esprime "ripetizioni = ∞"?
4. **Libreria Backtrack (F2.6):** schermata separata o integrata nell'Editor Canzone come selettore audio? (entrambe le strade sono supportate dal modello).
5. **Import/Export:** dove vive nella navigazione di Studio (è oggi un backup/restore dell'intera libreria)?
6. **Flusso di "riparazione" di una scaletta rossa** (§8): che aspetto ha il percorso rosso→verde (apri, verifica, eventualmente rinomina se il nome collide, salva)?
7. **Navigazione generale di Studio:** come si articolano le 5 schermate (libreria canzoni, editor canzone, libreria backtrack, libreria show, selezione)? Una tab bar, un menu, un bivio? (Esistono già `BivioBoardView` per il bivio STUDIO/LIVE e `SplashView` come ingresso — CD valuta se riusarli.)

---

### NOTE DI VERIFICA (per il referee)
- Tutto il modello dati, lo Store e l'import sono stati letti **verbatim** a master `0d626de`.
- Due incongruenze doc-vs-realtà segnalate dentro: (a) il nome ratificato è **KILL TRACK**, alcuni doc mostrano ancora "KILL BASE"; (b) BOX5 V24 elenca un file `Models/Section.swift`, ma il file reale è **`SongSection.swift`** (nome usato in questo documento).
- `Q-STAGE`, `Q-LIVE`, `Shows`, `Songs` sono ratificati ma **ancora in attesa di test su device** (LIBRO riga 190) — CD può usarli, ma sappia che non sono ancora "confermati a video".

*Documento di lavoro — non committato su git. Mauro lo porta a CD e al referee.*
