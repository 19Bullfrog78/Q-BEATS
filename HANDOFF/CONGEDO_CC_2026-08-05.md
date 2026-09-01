# CONGEDO CC — 2026-08-05

**Deposito, NON ratifica. Verificare, non ereditare.**

Scritto in chiusura di giornata, indipendente dal congedo del referee: i due documenti devono
essere misure separate, non una copia l'uno dell'altro. Orologio di scrittura:
**2026-08-05T13:09:04Z** (`date -u`), fuso locale +02:00 — **stavolta la data del nome e quella
di scrittura coincidono**, a differenza del 04/08.

Convenzione: **[V]** = misurato da me oggi. **[R]** = riferito da altri, non verificabile da me.

---

## 1. Stato a fine giornata

**HEAD e remoto** [V], misurati a fonte, non dall'output dei comandi che li hanno prodotti:
```
master locale : 25056b66eda40ad76d91a886ace442b7064ca900
master remoto : 25056b66eda40ad76d91a886ace442b7064ca900   (git ls-remote)
albero        : 63c793a8d0ec122cdfc9657992c309568f83821e
```
Partenza di giornata: `5183758d8b80b0d1f975fb0e6074d146cec3e3ae`. **Un solo commit prodotto
oggi**, ed è ⟦S5a⟧.

**CI** [V]: due run verdi sullo **stesso albero** `63c793a8…` — `31004966940`
(`workflow_dispatch` sul ramo temporaneo) e `31009171778` (`push` su master), entrambe
`conclusion: success`, 15/15 step, zero errori Swift, zero warning nuovi.

**Working tree** [V]: `git status --porcelain -- ios_app/` → vuoto. Nessun ramo
`ci-fiammifero/*` né locale né remoto.

---

## 2. Cosa è stato fatto: ⟦S5a⟧, dall'inizio alla fine

Un solo atomo, in otto giri (A47→A55): ricognizione → Fase 1 → diff → rettifica → rilievi →
rilavorazione → precommit → commit.

`QLiveShowDetailView.swift` NUOVO (409 righe) + due file toccati al minimo
(`QLiveRootView.swift` per il raggiungimento, `QLiveShowsView.swift` per il tap-riga e il
conteggio). +447/−5.

**Il diff è stato ratificato dal referee sui BYTE** (sha256 `85f47246…b670126a`), non su un
riassunto, ed è legato allo sha che la CI ha compilato — legame dimostrato attraverso
cherry-pick **e** amend, con l'albero invariato a ogni passaggio.

⛔ **⟦S5a⟧ è CI-VERDE e NON VALIDATO SU DEVICE.** Mai visto a schermo: nessun Xcode in ambiente
CC. La chiusura è il gate device di Mauro e **non è stato fatto**. «CI-verde ≠ chiuso.»

---

## 3. I CINQUE TICKET DA APRIRE — nessuno aperto oggi, tutti misurati

1. **`QBeatsStore.resolve(_:)` senza indice + `logger.warning` DENTRO il ciclo.** [V]
   `resolve` è O(S × C): per ogni id di `songIDs` fa `songs.first(where:)` su un Array
   (`QBeatsStore.swift:17` `var songs: [Song]`, `:152-164`), nessun dizionario. **Zero** forme
   cached o indicizzate nel file (controllo positivo: `func ` → 22 hit).
   ⚠️ **`showMeta` risolve DUE volte per riga** (`QLiveShowsView.swift:337` mia + `:339` via
   `estimatedDuration`, che a `QBeatsStore.swift:167` risolve di nuovo). Prima di D3 era una.
   ⚠️ E `:160` scrive un `logger.warning` per ogni id orfano, **dentro il render path**: uno
   show con K orfani costa K×2 log per riga per passata, in continuo durante lo scroll. È la
   stessa famiglia di difetto per cui la scheda ⟦S5⟧ vieta il badge FILE MISSING per-riga.
   ⚠️ Dimensioni reali **non misurabili** da qui (dati su device, `resolveBaseURL()` →
   iCloud/Documents). `test_data/songs.json` ha 2 canzoni ma è una fixture. La misura stabilisce
   la FORMA del costo, non la grandezza.

2. **`roBadge` e `LockIconShape` duplicati perché `private`.** [V]
   L'implementazione corretta del badge `.ro` esiste (`QLiveShowsView.swift:154-172`) ma è una
   `private var` dentro la struct, e la sua icona una `private struct` file-scope: irraggiungibili
   da un altro file. ⟦S5a⟧ ne porta una **seconda copia** della stessa specifica. Rimedio
   durevole = estrazione in `UI/Components/`, precedente esatto **S2d/`EmptyStateKit.swift`**
   («duplicarli avrebbe creato due copie destinate a divergere → estratti qui, neutri»,
   `EmptyStateKit.swift:6-8`). Se cambia il freeze, oggi cambiano due posti.

3. **`scaleFactor` assente in 7 file su 7 della stanza Q-Live.** [V]
   Misurato: QLiveShowsView, QLiveEmptyStates, QLiveKit, MetroFAB, QLiveRootView, RoomSwitchBar,
   EmptyStateKit → **0 occorrenze ciascuno**. La Vista LIVE invece lo usa ovunque (LiveView 14,
   LiveHeaderView 10, FineSetlistView 4), e `BOX5:47` descrive il pattern come proprio dei
   «sub-View della Vista LIVE».
   ⟦S5a⟧ è **il primo file della stanza** a rispettare `BOX5:68` (titolo 23pt scalato).
   ⚠️ Copertura parziale PER COSTRUZIONE: `EmptyStateLayout` ha il titolo a **20pt esatti**
   (`EmptyStateKit.swift:47`), sulla soglia, e non può riceverlo senza modificare un file che
   ⟦S5a⟧ ha il divieto di toccare ⇒ nelle empty-state Ⓕ/Ⓖ quel titolo non scala. Debito
   PRE-ESISTENTE per il resto della stanza, non introdotto qui.

4. **I due debiti `AudioEngine.swift`, da A51.** [V]
   (a) **Commenti contraddittori**: `:287` dichiara `_onSectionEnd` «single-shot: consumata
   (settata nil) sull'ultimo beat», ma il censimento delle sue 3 assegnazioni (`:1148`, `:1152`,
   `:2536`) mostra che **non viene mai azzerata sull'ultimo beat** — e `:2612-2615` afferma
   l'opposto («RESTANO registrati»). Il codice segue il secondo. Il single-shot per azzeramento
   esiste, ma su `_pendingEndClosure` (`:2219`).
   (b) 🚨 **Il più serio**: `:2617-2618` afferma un comportamento del lato **C++**
   («`metronome_processBuffer` skippato → beatCount=0 → hook non scatta») — un'affermazione su un
   meccanismo esterno, incisa in un commento e **mai passata da §7**. L'ho lasciata NON
   VERIFICATA: verificarla richiede aprire il C++, e inferirla dal nome sarebbe esattamente il
   difetto dominante di questo progetto.

5. **Drive non byte-fedele — riguarda la TERZA destinazione di R-δ.** [R+V]
   Il referee ha scaricato A43 da Drive e pesato **25 888 B contro 25 891**, impronta diversa,
   testo integro e righe combacianti. ⇒ Nessuna ratifica passa più da Drive; per un verbatim che
   deve reggere una ratifica serve un canale che regga la prova dei byte, e **quale sia non è
   deciso**. Oggi né io né il referee possiamo verificare quella destinazione. Già in memoria
   persistente, ma **la memoria di sessione non è un canonico**: va in BUGS.

---

## 4. Anomalie di processo di oggi — servono a chi leggerà lo storico degli ID

- **A53 è stato emesso in TRE versioni.** La Fase A l'ho eseguita sotto la **prima** (poi
  stoppata da Mauro, su un comando di sola verifica, non su una scrittura); **D2** (`scaleFactor`)
  è arrivato con la **seconda**; la **Fase B** (build autorizzata) con la **terza**. Il file NON
  è un ibrido di due stesure: è una riscrittura continua contro una Fase A che le tre versioni
  dichiarano identica. ⚠️ **L'impronta pre-riscrittura non esiste** — nessun prompt ne aveva
  ordinato la cattura, e non l'ho inventata. La provenienza resta ricostruibile da
  `MISURE_CC_2026-08-05_A50-S5A-DIFF-CORRETTO.txt`.
- **A54 è arrivato TRONCATO nel passaggio**: M2 e la sezione CONSEGNA sono andati persi in
  transito. Ho consegnato M1, dichiarato che M2 non era arrivato e **non ho indovinato** né la
  misura né il nome del file. Il referee ha poi inviato la metà mancante, stesso ID.
- **A52 emesso e mai inviato** (ritiro di R4).
- ⚠️ **`RoomSwitchBar.swift` sta in `UI/Components/`, non in `UI/QLive/`** come dice l'elenco
  «file autorizzati» di A53. Nessuna conseguenza pratica (il file è unico e l'ho trovato), ma
  l'indirizzo va corretto alla prossima riemissione del mandato.

---

## 5. I miei errori di oggi, per esteso

**Il più grande, e non l'ho trovato io.** In A48/A49 ho tradotto il freeze CSS in SwiftUI nuovo
**mentre metà dei componenti erano già costruiti e ratificati nella stanza accanto**. Il referee
ha bocciato con 5 rilievi; una revisione avversariale indipendente (4 lenti, ogni finding passata
a un verificatore istruito a refutarla) ne ha trovati **24, di cui 17 sopravvissuti** — 1
bloccante, 8 seri. Aggravante: `SCALETTA:300` prescrive **testualmente** `RoomSwitchBar
.segMini`, ed **è una riga che avevo letto e citato io stesso in A47 e in A48**. Non è una svista
di lettura: è una svista di applicazione.

**La difesa sbagliata, ritirata.** In A49 avevo giustificato gli SF Symbol col precedente
`LiveHeaderView`. Regge per la Vista LIVE, **non** per questa stanza, dove il precedente è
opposto e più recente (`RoomSwitchBar.swift:71-73`, glifo = `Shape` col path verbatim). Ritirata.

**Un errore mio corretto prima che uscisse.** Nella prima stesura `resolve()` veniva richiamata
quattro volte per render; l'ho vista rileggendo il file e sistemata **prima** che entrasse nel
diff consegnato.

**Tre volte mi sono fermata, e tutte e tre erano giuste** (ratificate dal referee): il contratto
inesistente in A47 (path costruito per analogia, mai verificato — quattro ricerche indipendenti
lo hanno escluso); l'impossibilità di compilare senza push in A51 (`workflow_dispatch` su master
avrebbe compilato codice **senza** il mio atomo: un verde sarebbe stato un'assicurazione falsa);
il messaggio di commit falso in A55 (il cherry-pick preserva il messaggio, e quel testo diceva
«NON un commit di lavoro / da NON mergiare» proprio mentre stava per diventare storia pubblica
di master).

---

## 6. Trappole di misura di oggi — la forma che morde e quella che mente

- **Nome di font.** MENTE: verificare che il `.ttf` esista e sia in `UIAppFonts`. Quello elenca
  **nomi di FILE**; `Font.custom` vuole il **nome PostScript**, e se divergono iOS ripiega in
  silenzio su SF Pro senza che il compilatore dica nulla. MORDE: leggere la tabella `name`
  (nameID 6) DENTRO il TTF. Misurato: family = `Inter SemiBold` (spazio), PostScript =
  `Inter-SemiBold` (trattino) — il codice usa la forma giusta.
- **`Info.plist` vs `project.yml`.** MENTE: misurare su `QBeats/Info.plist`, che XcodeGen
  **genera** (`project.yml:15-16`). MORDE: `project.yml`, la fonte. Misurare il prodotto è
  misurare la propria eco.
- **`git branch -d` che rifiuta dopo un cherry-pick.** MENTE: forzare con `-D` perché «tanto è
  stato mergiato». Lo sha è diverso e git non sa che sono equivalenti. MORDE: dimostrare
  l'equivalenza degli **alberi** (`^{tree}` identici + `git diff` vuoto) e solo dopo forzare.
- **Esito di una CI.** MENTE: il solo exit code di `gh run watch`. MORDE: due forme indipendenti
  — exit-status **e** `gh run view --json conclusion`.
- **Warning "nuovi".** MENTE: contare i warning della propria run. MORDE: confrontarli con la
  run baseline su master. I 2 `will never be executed` erano a `:298`/`:302` a master e a
  `:306`/`:310` da me — delta +8, esattamente le righe che il mio commento aggiunge sopra.
- **Console `cp1252`.** Ripresa dal 04/08: stampare `δ`/`≥` da Python su questa macchina lancia
  `UnicodeEncodeError`. `sys.stdout.reconfigure(encoding="utf-8", errors="replace")`.
- **Parser di un formato che non hai letto.** Ho scritto due volte un parser sul journal di un
  workflow assumendo lo schema, e ha reso **zero** entrambe le volte. Lo zero non era un fatto,
  era il mio filtro: la struttura reale aveva `key`/`agentId`, non `label`. Guardare la forma
  prima di filtrare.

---

## 7. Se fossi la prossima chat, farei per primo questo

1. **Il gate device di ⟦S5a⟧.** È l'unica cosa che trasforma «CI-verde» in «chiuso», ed è di
   Mauro. Tutto il resto è secondario finché quello non è fatto.
2. **🚨 `TD-fineshow-bottoni-morti`** (`BUGS_QBEATS.md:319`) resta in §1.2 «non bloccanti palco»
   **mentre è bloccante palco**. Segnalato il 04/08, riportato in ogni handoff da allora, **mai
   lavorato**. Oggi la giornata è finita tutta in ⟦S5a⟧.
3. **I cinque ticket della §3**, in un giro doc unico. Il più urgente nel merito è il (4b): un
   commento che asserisce il comportamento del C++ senza essere mai passato da §7.
4. **⟦S5b⟧** — lo Start vero. ⚠️ Ricordare le misure di A46: `.fineSetlist` non ha una serratura
   ma **tre** (closure vuote in `FineSetlistView`, la guardia `LiveView.swift:231-233` che
   esclude `.fineSetlist` dal solo percorso che scrive `.stopped`, e `LiveView` che non si
   smonta e quindi non riveste il display).

⚠️ Non rifarei le verifiche già chiuse oggi (identità albero, font PostScript, censimenti
`resolve`): sono misurate, e rimisurarle senza un motivo nuovo è overhead.

---

# ADDENDUM — QB-2026-08-05-A57 · scritto alle 2026-08-05T18:23:51Z

⚠️ **Il testo sopra NON è stato riscritto.** Era chiuso alle 13:09Z con impronta
`2f4457c4d17692fb0415bc15ab65e4b71df84ec0c94d1d90b3da16d565af06f1` (12 353 B); questo addendum è
aggiunto **in coda** cinque ore dopo, quando Mauro aveva già provato ⟦S5a⟧ sul telefono. Le
conclusioni qui sotto sono mie: il referee mi ha passato i fatti grezzi, non i giudizi, e dove
la mia lettura diverge dalla sua l'ho scritta invece di allinearmi.

Convenzione invariata: **[V]** = misurato da me · **[R]** = riferito, non verificabile da me.

---

## A. Cosa cambia il collaudo device (F1)

**Sei controlli su iPhone 13: 3 OK · 1 parziale · 2 NON PRODUCIBILI.** [R, collaudo Mauro]

⇒ **La riga del mio congedo «CI-VERDE e NON VALIDATO SU DEVICE» è superata, ma NON diventa
«chiuso device».** Lo stato esatto oggi è: **parzialmente validato, con un tetto strutturale**.
Non è pignoleria — cambia cosa si può dichiarare a chi legge dopo.

Ciò che è provato sul telefono: navigazione andata/ritorno, badge Read-only col lucchetto giusto,
e — questo mi interessa in particolare — **il conteggio lista = conteggio dettaglio** (controllo 6),
che è la verifica diretta della decisione D3. Quella parte regge sul device, non solo in teoria.

Ciò che NON è provato, e il perché conta:
- **controllo 3 (Start ancorato durante lo scroll) → PARZIALE.** L'unica setlist disponibile ha
  una canzone: la lista non scorre, lo schermo rimbalza. ⇒ **Il gradiente `.startfoot` che ho
  aggiunto in A51 (rilievo R3 del referee) NON è stato visto fare il suo lavoro.** Serviva
  esattamente a sfumare le righe sotto il footer *mentre la lista scorre*: senza scroll reale,
  la ragione per cui esiste non è stata esercitata. Da rifare con 10+ canzoni.
- **controlli 4 e 5 → NON PRODUCIBILI.** E qui la mia lettura è netta: **non è «rimandato», è
  strutturalmente impossibile oggi.** Senza §8 (creazione show in Q-Stage) non esiste modo di
  fabbricare uno show con orfani né uno show vuoto.

⚠️ **La conseguenza che il mio congedo non poteva vedere, e che considero il rilievo più
scomodo di questo addendum:** i controlli 4 e 5 sono precisamente i due che eserciterebbero
**tutto ciò che ⟦S5a⟧ ha di nuovo e non banale** —
`ThisShowIsEmptyState` e `NoPlayableSongsEmptyState` (che questo atomo ha agganciato per la
**prima volta** a una vista reale, dopo essere vissute solo in un `PreviewProvider` da S2), il
ramo `metaText` «0 playable · N unavailable», e il caso peggiore della mia misura M2 (scroll con
orfani, `resolve` che scandisce l'intero catalogo per ogni id mancante e scrive un log per
ciascuno, due volte per riga).
⇒ **Quei percorsi sono stati spediti su master senza che nessuno li abbia mai visti** — né a
schermo né in CI, perché la CI compila e non esegue. Nel congedo sopra ho contato il riuso delle
due empty-state fra le cose fatte bene: **lo confermo come scelta, ma va qualificato** — sono
codice riusato correttamente e *mai osservato vivo*. Non è un difetto di ⟦S5a⟧: è un buco di
osservabilità che §8 chiuderebbe e che nessun atomo di UI può chiudere da solo.

---

## B. «Font e pulsanti piccoli» (F2) — non è mia, ed è dimostrabile

Mauro: «nella nuova videata font, pulsanti ecc. sono piccoli. Devono essere uguali alle altre
videate, es. SHOWS o SONG», e dichiara di averlo già segnalato altre volte. [R]

**Ho misurato, e il rilievo è fondato nel merito ma il bersaglio non è l'implementazione.** [V]

| elemento | dettaglio (⟦S5a⟧) | lista Shows | fonte |
|---|---|---|---|
| titolo schermata | **23pt** (`QLiveShowDetailView.swift:152`) | **29pt** (`QLiveShowsView.swift:141`) | freeze `:248` = 23px · freeze `:190` = 29px |
| segmento stanza | **9pt**, padding 5/9 (`.segMini`) | **10.5pt**, padding 7/12 (`.full`) | freeze `:245` · freeze `:182` |

⇒ **Le due schermate sono diverse PER CONTRATTO, e la mia implementazione riproduce il freeze
esattamente.** Il dettaglio è più piccolo della lista perché CD l'ha disegnato più piccolo.

⚠️ **E `scaleFactor` non c'entra nulla**, contro l'ipotesi più naturale: su iPhone 13
`scaleFactor` = 390/390 = **1,0 esatto**, quindi `23 * scaleFactor` = 23. Il lavoro che ho fatto
in A53 sul punto D2 **non cambia un pixel su quel telefono** — vale solo su iPad.

⇒ **La mia lettura: F2 è un ticket per CD, non per CC, ed è di famiglia DIVERSA dal ticket 3 del
congedo.** Sono due assi che non vanno confusi:
- **ticket 3 (mio, §3)** = `scaleFactor` assente in 7 file su 7 della stanza → riguarda **iPad**,
  è una regola BOX5, è dominio CC;
- **F2 (nuovo)** = dimensioni assolute del frame ③ vs frame ② → riguarda **iPhone**, è una scelta
  di disegno incisa nel freeze, è dominio CD.
Applicare la regola dell'uno all'altro non risolverebbe niente e romperebbe il freeze.
⚠️ Che Mauro dica di averlo già segnalato più volte mi fa sospettare che il rilievo sia stato
finora instradato come difetto di implementazione — cioè al destinatario sbagliato. **Instradare
≠ tracciare**: va aperto come domanda a CD sul freeze, altrimenti tornerà una quarta volta.

---

## C. Il documento CD sulle tre vie (F3) — e cosa fa al footer che ho costruito

Il documento `2026-08-02_QLive-Shows-Start-ViewChoice__3-vie_STANDALONE.html` non l'ho letto:
è su Drive, e Drive è dichiarato non byte-fedele. Ragiono sui verbatim che mi hai passato. **[R]**

**Sul merito della decisione presa in A50, la confermo: l'omissione di `.viewtoggle` era ed è
corretta.** La misura sui canonici era esatta (zero occorrenze di «List view» in LIBRO v53,
BUGS v50, SCALETTA v7, BOX3 V99, BOX5 V28), e il documento CD **dichiara di sé «non è un
contratto»**: cablare due pillole su un documento che si autoesclude dal regime dei contratti
sarebbe stato peggio che ometterle.

⚠️ **Ma il documento cambia radicalmente COSA andrà costruito, e in una direzione che né io né
il referee avevamo previsto.** Il verbatim decisivo è **«Scelta = avvio. Tocchi "List view" e
parte in List view: non c'è un secondo Start da premere.»**
⇒ Le due pillole **non sono un controllo sopra lo Start: sono lo Start.** Il footer che ho
costruito — pillole omesse, un solo bottone START SHOW ancorato — non è «il footer a cui
aggiungere il toggle dopo». È una forma **alternativa e incompatibile** con quella che il
documento descrive, dove «Tap sul corpo grande = parte sempre in Auto view» e il conteggio è
«Auto view = 1 tocco · List view = 2 tocchi».
⇒ **⟦S5b⟧ non erediterà il mio `.startfoot` estendendolo: dovrà rifarlo.** Meglio saperlo adesso
che a diff consegnato.

Due cose collegate che ho verificato io sui canonici [V]:
- `LIBRO:109` definisce «Vista LISTA | Schermata alternativa Q-Live (lista canzoni — Fase 4)» —
  quindi l'oggetto esiste già nel vocabolario ratificato;
- `LIBRO:157` registra come **attivo** il bottone EMERGENCY della pulsantiera CD-4, che «fa
  switch da Vista Q-Live a Vista LISTA», ratificato 21/05.
⇒ Coerente col verbatim «lo switch Auto ↔ List a play iniziato è già ratificato»: sono **due
meccanismi distinti** — la scelta *prima* dell'avvio (il documento nuovo, non contrattuale) e lo
switch *durante* il play (`LIBRO:157`, ratificato). Non vanno confusi.
⚠️ E i nomi cambiano: «Q-Live view» → **«Auto view»**. Le etichette del freeze `2026-07-11` sono
superate su questo punto. Se qualcuno cabla le pillole leggendo il freeze, scrive il nome vecchio.

---

## D. Una canzone con più sezioni (F4) — il punto su cui do il giudizio più netto

**La correzione di Mauro è giusta, e l'affermazione del referee era falsa — ma solo in due terzi.
Lo dico preciso perché la parte che resta vera è quella che conta.** [V, misurato oggi]

La closure di fine-sezione ha **tre rami**, e ciascuno ha una condizione d'ingresso diversa
(`SetlistRunner.swift`):
```
292	            if !self.isLastSectionInSong {          → ramo AVANZA
341	            } else if !self.isLastSongInSetlist {    → ramo STANDBY
372	            } else {                                 → ramo FINESETLIST
```
Con **una canzone di N≥2 sezioni**, come sono fatte le canzoni di debug:
- ✅ **AVANZA è esercitato N−1 volte.** È il ramo seamless — swap di BPM e di beats-per-bar al
  downbeat. I cambi 4/4→3/4 e 100→200 BPM che Mauro descrive **sono esattamente questo ramo.**
- ❌ **STANDBY non è raggiungibile**: serve la canzone N+1. Confermato dal canonico —
  `LIBRO:165`: «`.standby` | Overlay tra canzoni (transizione standard tra song N e song N+1)».
- ✅ **FINESETLIST è raggiungibile**: è l'`else` finale, cioè ultima sezione dell'ultima canzone —
  e con una sola canzone, la sua ultima sezione **è** quella condizione.

⇒ **Con i dati di debug esistenti si collauda la maggior parte di ⟦S5b⟧**, non «niente»: tutta la
catena di transizione seamless, che è la parte tecnicamente più rischiosa. Resta fuori solo lo
standby.

⚠️ **E qui arrivo alla conseguenza che considero la più importante di tutto questo addendum.**
Ho riverificato oggi, a HEAD `25056b66…`, le tre serrature di `.fineSetlist` che avevo misurato
in A46 — **sono tutte e tre ancora in piedi** [V]:
1. `FineSetlistView.swift:19` e `:21` — «BACK TO SHOWS» e «RESTART SETLIST» sono **ancora closure
   vuote**, verbatim invariate;
2. `LiveView.swift:231-233` — la guardia `case .standby, .fineSetlist: return` esclude tuttora
   `.fineSetlist` dall'**unico** percorso che scrive `.stopped`;
3. `LiveView` non si smonta quando compare `FineSetlistView` (è un ramo dello stesso `ZStack`),
   quindi `.onAppear`/`primeDisplay` non rifirano.

⇒ **Il gate device di ⟦S5b⟧, eseguito sui dati che esistono oggi, finisce dentro `.fineSetlist`
e lì si pianta.** Una canzone → si arriva alla fine → schermata END SHOW → due bottoni che non
fanno nulla → nessun percorso di uscita, né a UI né di stato.
⇒ **`TD-fineshow-bottoni-morti` non è un ticket parallelo a ⟦S5b⟧: è il capolinea del suo
percorso felice, sull'unico dato disponibile.** Nel congedo sopra l'ho segnalato come «il più
grave nel merito, mai lavorato»; **con F4 diventa qualcosa di più preciso: è un prerequisito di
⟦S5b⟧, non un debito che gli corre accanto.** Un collaudo device di ⟦S5b⟧ che arrivi in fondo
alla setlist non può concludersi pulito finché quei due bottoni sono vuoti.

**La mia raccomandazione esplicita:** cablare almeno «BACK TO SHOWS» **prima o dentro** ⟦S5b⟧.
È un'uscita, non una feature: senza, il gate di ⟦S5b⟧ o si ferma prima della fine — e allora non
prova il ramo `fineSetlist` — oppure finisce con l'app inchiodata e il tester che chiude a forza.
⚠️ Non decido io se sia ⟦S5b⟧ o un atomo a sé: dico che l'ordine «⟦S5b⟧ e poi il fineshow» è
quello che costa un giro di collaudo buttato.

---

## E. Cosa questo addendum corregge del testo sopra

1. **§1 e §7, «CI-VERDE e NON VALIDATO SU DEVICE»** → **superato**: ora è *parzialmente validato
   su device* (3 OK, 1 parziale, 2 non producibili). Non è chiuso, e la formula giusta non è più
   «device-pending» ma «parzialmente validato con tetto strutturale».
2. **§7 punto 1, «il gate device è la prima cosa»** → **eseguito**, in parte. Quel che resta non
   è «fare il gate» ma **produrre i dati** che i controlli 3, 4 e 5 richiedono — e per 4 e 5
   serve §8, cioè non è alla portata di un atomo di UI.
3. **§2, il riuso delle due empty-state contato fra le cose fatte bene** → **confermato come
   scelta, qualificato come esito**: quei due percorsi sono su master e non li ha visti nessuno.
4. **§7 punto 4, le tre serrature come «cosa da ricordare per ⟦S5b⟧»** → **rafforzato**: da
   promemoria a **prerequisito**, per il ragionamento in §D.
5. **§3 ticket 3 (`scaleFactor`)** → **invariato ma da non confondere** con F2, che è un asse
   diverso e un destinatario diverso (CD, non CC) — vedi §B.

**Nessuno dei cinque ticket del §3 è stato aperto**, e nessuno è stato smentito dai fatti di
questo addendum. Se ne aggiungono **due**:
6. **F2 — dimensioni del frame ③ vs frame ② (dominio CD).** Domanda a CD: il dettaglio deve
   restare più piccolo della lista, come il freeze prescrive, o il freeze va emendato?
7. **F3 — «Scelta = avvio» ridisegna il footer di ⟦S5b⟧.** Il documento CD non è un contratto:
   va portato a contratto prima che qualcuno cabli, e i nomi nuovi («Auto view») superano quelli
   del freeze `2026-07-11`.

⚠️ **Su F5 non ho nulla da aggiungere e non fingo di averlo:** «l'app suona solo quando sarà
finita» è una decisione di Mauro sul quando provare con la band. Non tocca nessuna misura mia.

---

## F. La card di Shows con «···», START SHOW e VIEW (F6) — cosa fa al gesto che ho cablato

⚠️ **Aggiunto alle 18:4x Z, stesso ID A57.** Il freeze citato,
`2026-07-24_QLive-Shows-Card-Azione-Overflow-FREEZE.html`, **non l'ho letto**: [V] non è nel repo
— `DESIGN/QLive_Nav/` si ferma al `2026-07-18` — ed esiste in **una sola copia**, su E: in
`FILE X CLAUDE.MD/DA_CD_PER_CC/24_07_2026/`. Ragiono sui verbatim passati dal referee. **[R]**

⚠️ **E questo è già di per sé un reperto:** è un freeze **normativo** fuori dal controllo di
versione, cioè la **seconda istanza** del difetto che `LIBRO_MASTRO_QBEATS.md:324` ha già
dichiarato per il contratto Q20 («ARTEFATTI NORMATIVI FUORI DAL CONTROLLO DI VERSIONE — buco
dichiarato, non regime»). Là si era detto «altri freeze SONO nel repo e tracciati… È un buco».
Ne è comparso un altro, e nessuno lo sta contando.

### F.1 — Cosa ho cablato davvero, misurato

`QLiveShowsView.swift:319`, ultimo modificatore della catena di `showCard`: [V]
```
304	        .padding(.horizontal, 16)
305	        .padding(.vertical, 15)
306	        .background(… RoundedRectangle(cornerRadius: 15 …))
308	        .overlay( … bordo … )
312	        .overlay( … inset-highlight … )
319	        .onTapGesture { onSelectShow(show) }
```
⇒ Il gesto è **sull'intera card**, dopo padding e sfondo: copre tutto il rettangolo, **angolo in
alto a destra compreso** — cioè esattamente dove andrà «···». Oggi non collide con nulla, perché
dentro `showCard` **non c'è nessun `Button`** [V]: gli unici del file (`:117`, `:208`, `:228`)
sono il campo di ricerca e la sua «x». Nessun `contentShape` sulla card.

### F.2 — La collisione SEMANTICA: il mio gesto è il percorso che il freeze vuole declassare

Verbatim del freeze: «sul palco l'azione più frequente è "parti", e oggi costa **DUE tap** (apri
il dettaglio → parti). Un'azione primaria sulla card la porta a **UNO**.»

⇒ Il gesto che ho cablato **È** quel percorso a due tap, e l'ho reso l'affordance dell'intera
superficie della card. Non è sbagliato oggi — ⟦S5a⟧ doveva raggiungere il dettaglio e non
esisteva altro — ma **non è la base su cui costruire**: il freeze esiste per demolire quel
percorso come azione primaria.
⚠️ E c'è una ridondanza che arriva insieme: «vedi dettaglio» diventa **una voce del menu «···»**.
Il dettaglio avrà quindi due strade — tap sul corpo e voce di menu — e questo va deciso da CD,
non ereditato per inerzia dal mio gesto.

⇒ **La mia lettura: `.onTapGesture` di ⟦S5a⟧ è PROVVISORIO e va RI-DECISO, non esteso.** Chi
costruirà l'atomo della card non deve chiedersi «come faccio convivere «···» col tap esistente»,
ma «il corpo della card, ora che c'è START, cosa deve fare?».

### F.3 — La collisione TECNICA, ed è quella che questo progetto ha già pagato una volta

Il freeze prescrive: «"···" **tap-area 44×44**: separa "vado" da "gestisco"». Il glifo «···» è
piccolo; una tap-area 44×44 significa **espandere** l'area sensibile oltre il disegno.

⚠️ Espandere l'hit-area di un figlio **dentro** un genitore che ha a sua volta un gesto su tutta
la superficie è **precisamente la configurazione che ha fatto fallire il gate device S3** di
`RoomSwitchBar`, il 14/07: tocchi 8-10pt oltre il bordo della pill **mai loggati**, espansione
inerte, bersaglio reale 34pt invece di 54. La causa è incisa in
`RoomSwitchBar.swift:152-164` [V] — «il `.contentShape` esteso apparteneva al wrapper, una vista
SENZA gesto; il gesto del Button copriva solo la label» — e la ristrutturazione che l'ha risolto
mette l'espansione **dentro la label del Button**, mai su un wrapper.
Nota di linguaggio, per non spaventare a vuoto: SwiftUI dà priorità al gesto del **figlio** su
quello dell'antenato, quindi in teoria i `Button` di «···» e START vincerebbero sul mio
`.onTapGesture`. **Ma «in teoria» è esattamente ciò che è stato smentito sul device a luglio**, e
la lezione agli atti dice che la struttura dell'hit-test si prova, non si ragiona.

⇒ **Raccomandazione operativa:** quando la card riceve i controlli, **togliere il
`.onTapGesture` sull'intera card** e rendere esplicita l'intenzione — o il corpo diventa un
`Button` suo (con `contentShape` sulla sua label), o il gesto si restringe al blocco di testo.
E il gate device non può essere «apro uno show»: serve la **stessa forma a più tocchi** già usata
per `RoomSwitchBar` — su «···», 8-10pt **fuori** da «···», su START, **fra** START e «···», e sul
corpo — perché è nelle zone di confine che il difetto si manifesta, non al centro dei bersagli.

### F.4 — Due conseguenze che nessuno ha ancora nominato

**(i) Tre affordance sulla stessa card.** Oggi la card porta un **chevron** a destra
(`RowChevronShape`, `:299-302`), che nel markup del frame ② significa «push al dettaglio». Con
«···», START SHOW e VIEW, quella card avrebbe **quattro** segnali di azione insieme, di cui uno
(il chevron) indica una destinazione che nel frattempo è diventata una voce di menu. Non lo
decido io: lo segnalo come domanda a CD, perché è il genere di cosa che si scopre a diff fatto.

**(ii) START sulla card accorcia la strada al vicolo cieco.** Da §D di questo addendum: con i
dati di debug il ramo `fineSetlist` è raggiungibile, e lì i due bottoni sono vuoti — l'app resta
inchiodata. Un START a **un tap dalla lista** rende quel fondo cieco raggiungibile ancora più in
fretta, e da una schermata in più. **Non è un argomento contro la card-azione**: è un argomento
in più perché `TD-fineshow-bottoni-morti` venga chiuso **prima**, non dopo.

### F.5 — Cosa NON so

Non ho letto il freeze `2026-07-24`, quindi **non so**: che aspetto abbia «VIEW» sulla card né
che rapporto abbia con le «Auto view / List view» del documento di F3 (potrebbero essere la
stessa materia o due cose diverse — sospetto la stessa, ma è un sospetto e lo dichiaro tale);
se il chevron sopravviva; se «START SHOW» sulla card debba avviare in Auto view o aprire la
scelta a tre vie. Sono tutte domande a CD, e nessuna è deducibile dal codice.

⇒ **Ottavo ticket** (dopo i cinque del §3 e i due dell'addendum): il freeze `2026-07-24` è
normativo e vive in copia unica fuori dal repo — seconda istanza del buco già dichiarato in
`LIBRO:324`. Da portare sotto controllo di versione **prima** che qualcuno ci cabli sopra, o si
cablerà su un documento che nessuno può ancorare.
