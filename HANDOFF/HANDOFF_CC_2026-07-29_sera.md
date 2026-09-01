================================================================================
HANDOFF CC — 2026-07-29 sera — chiusura sessione (S4K device-chiuso + DARK-DECL)
================================================================================
Scritto da CC a chiusura sessione, per la PROSSIMA sessione CC. Indipendente
dall'handoff del referee per esplicita richiesta di Mauro: non l'ho letto, non
l'ho cercato, non ho allineato nulla di quanto segue a un'aspettativa su cosa
lui possa aver scritto. Se questo documento e quello del referee divergono, la
divergenza è essa stessa un dato: uno dei due ricorda male, meglio scoperto ora
che fra tre sessioni.

**[V]** = misurato da me, in questo turno, ora, con un comando che ne mostra
l'output qui sotto o poco sopra nella stessa sessione di lavoro.
**[R]** = riferito (da un prompt, da mia memoria di turni precedenti in questa
stessa chat, o da terzi) — non rimisurato in questo turno. Un [R] non è un
errore: è onestà su cosa non ho ri-toccato adesso.

**Notazione dei numeri**, stessa convenzione della sessione: `byte(disco)` vs
`byte(blob)`; `righe(terminatori, wc -l)`; `CR` sempre con `tr -cd '\r' | wc -c`,
mai `grep -c` (sottoconta sui multi-CR-per-riga). Ogni zero riportato qui porta
il proprio controllo positivo nella stessa forma di comando.

================================================================================
(a) STATO DEL REPO A FONTE — tutto [V], misurato in questo turno
================================================================================

**HEAD = origin/master = `6c7352a19b0dc6edadca8c14d34939ca30711369`**
(confermato con `git fetch origin master` prima del confronto, non un
`rev-parse` locale dato per buono).

`git status --porcelain -uno`: **vuoto** (nessun file tracciato modificato).
Controllo positivo, stessa forma: `git status --porcelain` nudo → **59 righe**,
tutte `??` untracked. Il comando funziona; lo zero di `-uno` è un'assenza vera.

**Untracked in `HANDOFF/`: 57** (delle 59 totali; le altre 2 sono
`QBEATS_A5C_PIANO_2026-07-04.md` e `QBEATS_ATOMC_PIANO_2026-07-06.md`, in root).

**Canonici tracciati, sha256 + impronte, misurati ora:**

| file | sha256(disco) | byte(disco) | righe(term) | CR(disco) | versione dichiarata |
|---|---|---|---|---|---|
| `LIBRO_MASTRO_QBEATS.md` | `734c0158…4355817` | 163167 | 455 | **455** | 43 (28/07/2026) |
| `BUGS_QBEATS.md` | `74fc8057…f9ea0773` | 208814 | 911 | **911** | 44 |
| `BOX3_QBEATS.md` | `c728bacc…d29fb3c` | 89457 | 803 | **0** | V99 — 2026-07-22 |
| `BOX5_QBEATS.md` | `cf425ff0…184ff5b` | 57158 | 596 | **0** | V28 — 28/07/2026 |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | `700d7caa…5549c0e14` | 35661 | 333 | **0** | 3 (28/07/2026) |

Controllo positivo per i CR=0 (BOX3/BOX5/SCALETTA, facce uniche LF): la stessa
forma di comando rende 455 e 911 su LIBRO/BUGS nella stessa tabella — il
comando conta i CR, dove rende 0 è perché non ci sono. **Nessuno di questi
cinque file è stato toccato in questa sessione** — le impronte sopra sono
identiche a quelle già agli atti dal 28/07 (SCALETTA, BOX5, BOX3) o dal 28/07
sera (LIBRO v43): oggi non ho scritto in nessun canonico.

**I tre file toccati oggi, impronte a fine sessione:**

| file | sha256(disco) | righe |
|---|---|---|
| `ios_app/QBeats/UI/QLive/QLiveKit.swift` | `e963c7c2…c62ad89` | 17 |
| `ios_app/QBeats/UI/QLive/QLiveShowsView.swift` | `82a9d505…913d18a3eb916f` | 396 |
| `ios_app/project.yml` | `5c583446…f827dd3d` | 160 |

================================================================================
(b) COSA È ENTRATO IN MASTER OGGI — tutto [V]
================================================================================

Confermato con `git log --since --until` sull'intera giornata 2026-07-29:
**esattamente due commit, entrambi di questa sessione, nessun terzo attore.**

| # | ora | sha40 | subject | file | CI |
|---|---|---|---|---|---|
| 1 | 15:35:32 | `b9f4e5f0c806a40938136cd8bb076f590c5e851d` | `S4K: congedo tastiera Q-Live (contratto Q20) - barra propria via safeAreaInset` | `QLiveKit.swift`, `QLiveShowsView.swift` | run `30456740570`, **success** (letto verbatim `gh run view`, non da exit code) |
| 2 | 16:59:23 | `6c7352a19b0dc6edadca8c14d34939ca30711369` | `DARK-DECL: UIUserInterfaceStyle=Dark - la UI di sistema segue l'app, non il device` | `project.yml` | run `30463659772`, **success** (idem) |

Entrambi: autore = committer = Mauro Martintoni `<di_tutto@icloud.com>`, **zero
trailer Co-Authored-By** (verificato con `%b` vuoto su entrambi i commit).

**S4K — chiuso, ma con una faccia che resta [R] per me per costruzione:** il
gate CI è verde, misurato da me. Il gate DEVICE (Mauro, iPad+iPhone, 29/07) non
è qualcosa che io possa misurare — non ho un device. Lo riporto perché Mauro
lo ha dichiarato in chat, ma resta **[R]**, non [V]: nessuna riga di questo
handoff certifica il device al posto di Mauro.

**DARK-DECL — l'unico dei due atomi verificato fino al prodotto reale, non solo
al commit.** Ho scaricato l'artifact `QBeats-IPA` della run `30463659772`
(`gh run download`, cartella scratchpad fuori dal repo), estratto
`Payload/QBeats.app/Info.plist` (binary plist reale) e letto con `plistlib`:
```
UIUserInterfaceStyle = 'Dark'
```
Ri-letto ORA, in questo turno, dallo stesso file già estratto (path Windows
nativo per `python3.exe`, non il path stile Git-Bash — vedi trappola in (g)):
stesso risultato, `'Dark'`, confermato una seconda volta. Il gate DEVICE del
colore reale su schermo resta di Mauro, non mio.

================================================================================
(c) COSA HO MISURATO OGGI CHE NON È IN NESSUN CANONICO
================================================================================

Tutto quanto segue esiste **solo in questa chat** (e nei due prompt di
censimento/verifica che l'hanno prodotto) — **zero righe di questo materiale
sono incise in BOX3/BOX5/BUGS/LIBRO.** Elenco senza deciderne io la
destinazione (non è compito mio, e oggi non devo "sistemare" nulla):

1. **Entitlement multicast + `get-task-allow`**: entrambi dichiarati
   incondizionatamente (tutte le config) sia in `QBeats.entitlements` che in
   `project.yml:74-84`. Nessuna divergenza fra i due file sulle stesse 2 chiavi
   (il "debito post-TD#44" citato in un prompt di oggi non risulta più aperto
   su questo confronto puntuale).
2. **La CI produce SOLO build development-signed**: `ios_build.yml` compila
   `-configuration Debug`, esporta con `ExportOptions.plist` → `method:
   development`, firma con `"Apple Development: Mauro Martintoni (AZ8V772X7R)"`,
   profilo `QBeats_Dev_Profile`. **Nessuna pipeline di distribuzione App Store
   esiste oggi in questo repo.**
3. **LinkKit**: vendor a 4.0 dal commit `42424ef` (05/05/2026). Tre commenti
   nel codice dicono ancora il contrario: `AudioEngine.swift:447`,
   `AudioEngine.swift:457` («LinkKit 3.2.2»), `LinkEngine.mm:55` («LinkKit
   3.x»). Nessun marcatore di versione indipendente trovato dentro l'SDK
   stesso (né nell'`Info.plist` dello xcframework né negli header).
4. **Il pannello Ableton Link NON è un one-time al primo enable**: è un
   `Button("Ableton Link")` sempre presente in `SettingsView.swift:23-25`, che
   ripresenta il pannello reale (`ABLLinkSettingsViewController`, via
   `ABLLinkSettingsSheetView` / `UIViewControllerRepresentable`) a ogni tap.
   Zero flag "prima volta" in tutto il progetto (cercato esplicitamente).
5. **Versione/build number NON vivono in `project.yml`**: vivono nel file
   fisico `QBeats/Info.plist` (`CFBundleVersion=142`, `CFBundleShortVersionString=1.0`
   — **ma vedi punto 6, questi due numeri non contano per il prodotto reale**).
   **Team ID e metodo di export NON vivono in `project.yml`**: vivono in
   `ios_build.yml` (`DEVELOPMENT_TEAM=X42CX3ZP3T`, `method: development`).
6. **`project.yml` comanda il plist del prodotto, non il file fisico —
   confermato con ground truth, non inferenza.** Ho scaricato l'artifact di
   ieri (run `30456740570`) e oggi (run `30463659772`), estratto
   `Payload/QBeats.app/Info.plist` reale in entrambi i casi: le chiavi
   dichiarate SOLO in `project.yml→info.properties` (`UIRequiresFullScreen`,
   `CFBundleDocumentTypes`, `NSBluetoothAlwaysUsageDescription`, +4 altre)
   sono TUTTE presenti nel prodotto; e **`CFBundleVersion` nel prodotto reale è
   `'1'`, non `142`** — il 142 del file fisico non ha mai contato per nessuna
   build che sia mai uscita da questa CI.
7. **Zero crash reporting / telemetria** in tutto il progetto (Crashlytics,
   Sentry, Bugsnag, MetricKit, `NSSetUncaughtExceptionHandler`: cercati,
   assenti). Solo `os_log`, utile solo con device fisico + iMazing.

================================================================================
(d) COSA NON HO VERIFICATO — dichiarato in chiaro
================================================================================

- **[R]** Non ho letto il PDF delle linee guida UI di Ableton Link (non l'ho
  cercato, non mi è stato passato): non so se il pattern «bottone permanente +
  sheet» sia conforme. Ho solo misurato COME è costruito oggi (punto c.4), non
  se sia a norma.
- **[R]** Non ho verificato se l'entitlement multicast sia mai stato
  richiesto/approvato da Apple sul **profilo di distribuzione** (solo
  development è misurato, punto c.2). "Ce l'abbiamo già" (TD#44) riguarda per
  quanto ne so il lato development — resta un gate non misurato da me sul lato
  Store.
- **[R]** Non ho un modo di confermare "LinkKit 4.0" in modo indipendente dal
  messaggio di commit + un commento di intestazione file (punto c.3). Nessun
  marcatore embedded trovato.
- **Il MECCANISMO interno di XcodeGen (merge vs rigenerazione totale) resta
  non verificato da me** — ho verificato il RISULTATO (project.yml comanda,
  punto c.6) confrontando input/output su due run reali, non il codice sorgente
  di XcodeGen né la sua documentazione fino in fondo su questo caso preciso.
- **[R]** Non ho controllato se la versione di `xcodegen` installata da
  `brew install xcodegen` (non pinnata nel workflow) sia la stessa fra le run
  di ieri e quella di oggi. Se Homebrew ha aggiornato la formula nel frattempo,
  il confronto A1/A2/A3 fra le due run porta comunque una variabile non
  controllata che non ho isolato.
- **Il gate DEVICE, per entrambi gli atomi di oggi** (S4K sulla UX reale,
  DARK-DECL sul colore reale visto su schermo) non è mio da dichiarare e non
  l'ho misurato: lo fa Mauro.
- Non ho cercato se esistano asset/color-set con varianti chiare che
  diventerebbero un problema (o si risolverebbero da sole) con
  `UIUserInterfaceStyle: Dark` — il censimento di ieri (punto 2.3 del
  censimento colore) diceva zero `.colorset` nel progetto, quindi il rischio
  è probabilmente basso, ma non l'ho ri-controllato oggi in questa luce
  specifica.

================================================================================
(e) DOVE HO SBAGLIATO IO, E COME ME NE SONO ACCORTO
================================================================================

1. **Ieri ho declassato una memoria corretta a "probabilmente superata".** La
   memoria diceva "CFBundleVersion bloccato a 1"; il file fisico
   `Info.plist` mostrava 142, e ho scritto che la memoria sembrava superata.
   Era il contrario: la ground truth di oggi (sezione c.6) mostra che il
   prodotto reale porta `CFBundleVersion='1'` — la memoria aveva ragione, io
   mi ero fermato al livello sbagliato (il file fisico, che non conta). Me ne
   sono accorto SOLO perché il referee ha imposto la verifica sull'artefatto
   reale come condizione per scrivere qualunque cosa (Passo A di oggi); non
   l'ho scoperto per iniziativa propria prima che fosse richiesto.
2. **Ho scritto, nel primo tentativo di S4K, un `HStack{Spacer();Button}`
   dentro `ToolbarItemGroup(placement:.keyboard)`** — pattern che riproduce
   quasi esattamente un bug Apple documentato e mai risolto (thread 736040):
   con ogni probabilità la barra sarebbe apparsa vuota su device. Non l'ho
   scoperto da solo: il referee ha chiesto la verifica sui forum sviluppatori
   Apple prima che quel codice arrivasse a un secondo cancello, e la ricerca
   l'ho fatta perché richiesta esplicitamente, non perché avessi già un
   sospetto mio.
3. **Ho ripetuto, nell'introduzione al censimento commerciale, la
   caratterizzazione "pannello Ableton mostrato una volta sola al primo
   enable"** così come mi era stata data, prima di misurarla. L'ho corretta
   nella stessa risposta una volta arrivato al punto 3 del censimento (era
   falsa: è un bottone permanente) — quindi l'errore non si è propagato oltre
   questa chat, ma il pattern («ripetere un'affermazione datami prima di
   misurarla») è lo stesso che questo progetto marca da mesi come rischioso.

================================================================================
(f) DOVE HO CORRETTO IL REFEREE, O DOVE PENSO SI SBAGLI ANCORA
================================================================================

**Correzioni fatte oggi, con misura a supporto:**
- Il thread Apple 709227, citato come motivo generale per cui serve un
  `NavigationStack`, descrive nel dettaglio un bug **specifico alla
  presentazione `.sheet()`** — e `QLiveShowsView` non è mai presentata con
  `.sheet()` (arriva da uno switch manuale su enum in `AppRootView`). L'ho
  segnalato come caveat, non come smentita: la fragilità generale dell'API
  restava comunque un argomento valido, ed è la strada poi scelta
  (`safeAreaInset`).
- La caratterizzazione "una volta al primo enable" del pannello Ableton (sopra,
  e.3).
- La mia stessa lettura di ieri su `CFBundleVersion` (sopra, e.1) — non è una
  correzione al referee, è un'auto-correzione innescata dalla sua richiesta di
  misura.

**Dove penso — PARERE, non misura — che possa restare un punto scoperto:**
la frase "l'entitlement multicast ce l'abbiamo già, TD#44 ve l'ha fatto perdere
e riconquistare" mescola, a mio parere, due cose diverse: il fatto che il
profilo **development** ce l'abbia (misurato, vero) e il fatto — non misurato
da me, e per quanto io sappia non misurato nemmeno dal referee — che sia mai
stato richiesto per un **profilo di distribuzione**. Non ho visto, in questa
sessione, una misura che chiuda questo punto in un senso o nell'altro. Lo
marco come mio sospetto aperto, non come fatto stabilito.

================================================================================
(g) TRAPPOLE TECNICHE PER IL PROSSIMO CC
================================================================================

- **`python3.exe` nativo Windows non capisce i path stile Git-Bash
  (`/c/Users/...`).** `ls`/bash li traducono (binari MSYS), un eseguibile
  Windows nativo no: `FileNotFoundError` anche se il file esiste ed `ls` lo
  vede. Serve un path Windows (`C:\Users\...` o `C:/Users/...`) quando si
  invoca Python da Bash su file con path assoluti POSIX-style. Scoperta oggi,
  costata un giro.
- **`ToolbarItemGroup(placement:.keyboard)` con `Spacer()` dentro l'`HStack` →
  toolbar vuota.** Bug Apple noto (thread forum 736040), MAI risolto fino a
  iOS 18 per quanto documentato. Vale per qualunque uso futuro di quel
  placement in questo progetto, non solo per Q-Live.
- **`.ignoresSafeArea(.keyboard, edges:.bottom)` NON annulla un inset aggiunto
  da `.safeAreaInset(edge:.bottom)`.** Sono due `SafeAreaRegions` distinte
  (`.container` vs `.keyboard`, da documentazione Apple). Chi tocca ancora
  quell'area di `QLiveShowsView.swift` deve saperlo prima di stupirsi di un
  riflusso di layout.
- **Il file fisico `ios_app/QBeats/Info.plist` NON è la fonte di verità per il
  prodotto costruito.** `xcodegen generate` gira a ogni CI run (il
  `.xcodeproj` non è nemmeno tracciato in git) e — confermato con ground
  truth, non supposizione — `project.yml→info.properties` comanda. Chi edita
  a mano il file fisico (il team l'ha fatto in passato, commit `2b379e4`) sta
  scrivendo in un posto che la prossima generazione ignora silenziosamente.
  **Ogni futura chiave Info.plist va in `project.yml`.**
- **La CI produce solo IPA development-signed.** Nessuno confonda "CI verde,
  IPA scaricabile" con "pronto per lo Store": manca l'intera categoria
  (certificato/profilo Distribution, `get-task-allow:false`, verifica
  dell'entitlement multicast sul profilo Distribution).
- **`get-task-allow: true` è incondizionato**, in entrambi i file che lo
  dichiarano. Se un giorno qualcuno prova a costruire in Release/Distribution
  da questo stesso `project.yml` senza toccare quella riga, rischia un rifiuto
  Apple per quel motivo specifico — non l'ho verificato di persona (nessuna
  build Distribution è mai stata tentata, per quanto misurato), lo segnalo
  come rischio dichiarato, non come fatto osservato.

================================================================================
(h) COSA RESTA PRONTO, COSA RESTA BLOCCATO — E DA CHI
================================================================================

- **Non affermo che ⟦S4R⟧ sia "pronto da iniziare"**: l'ordine
  ⟦S4K⟧→⟦S4R⟧→⟦S4L⟧ è inciso (fonte: SCALETTA v3, non ri-letta per intero in
  questa sessione oltre la scheda S4K — **[R]** per il resto della scheda).
  Non ho visto, in questa sessione, un prompt che apra esplicitamente ⟦S4R⟧:
  chi riprende verifica a fonte prima di assumere che sia lo step successivo
  scontato.
- **Blocco reale, misurato oggi, non ancora in coda a nessuno che io sappia:**
  la verifica dell'entitlement multicast sul profilo di **distribuzione**
  (sezione f) — Mauro l'ha segnalata come "da fare presto, non dopo il §6".
  Nessuna misura mia che sia stata avviata.
- **Decisioni non mie da prendere, segnalate ma non chiuse:** la
  riclassificazione di severità di TD#17 in ottica commerciale (proposta di
  Mauro/CD, non mia); l'allineamento del PDF guida-UI Ableton contro il
  facade pattern esistente; la stesura di un canonico per il censimento
  commerciale (sezione c) — nessuno di questi tre è compito mio deciderlo o
  avviarlo, e non ho misura che sia già stato assegnato a qualcuno stasera.
- **[R], da questa mattina, non ri-misurato oggi:** i due mirror LIBRO fermi a
  v41 su E: — cancellazione autorizzata da Mauro ma, per quanto risulta
  dall'handoff letto in apertura di questa sessione, mai eseguita. Chi
  riprende verifica a fonte se il file esiste ancora prima di assumere lo
  stato dell'handoff di ieri sera.

================================================================================
FINE HANDOFF.
================================================================================
