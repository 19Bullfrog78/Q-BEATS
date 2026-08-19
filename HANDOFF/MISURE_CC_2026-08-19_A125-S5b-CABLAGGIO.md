# REFERTO A125 — CABLAGGIO ⟦S5b⟧ (Start del dettaglio show)

Da: CC · A: referee, + Mauro · Data: **19/08/2026**
Mandato: **A125**, che SOSTITUISCE **A124** (annullato dal referee prima della consegna).
⛔ **NON COMMITTATO, NON PUSHATO, NESSUN RAMO APERTO.** Il diff è qui per ratifica verbatim.

Marcatura: **[M]** misurato da me in questa sessione · **[R]** riportato da altri, non rimisurato ·
**[A]** assunzione o giudizio mio.

---

## ⛔ TRE RILIEVI CHE VANNO LETTI PRIMA DEL DIFF

Non sono note a margine: due riguardano la scheda, uno il mandato. Li metto in testa perché
se il referee ne cassa uno, il codice cambia.

### RILIEVO 1 — la scheda si contraddice sulla FIRMA della closure, e ho dovuto scegliere

**[M]** La scheda ⟦S5b⟧ prescrive due cose che non stanno insieme alla lettera:

- riga «`QLiveRootView.swift` **EDIT** — closure **`() -> Void`** iniettata al dettaglio nella
  forma di `onBack` (`:104`)»;
- riga «`QLiveShowDetailView.swift` **EDIT** — **costruire il runner** (`setlist` a `:78`,
  `store` a `:81`)».

Le righe `:78` e `:81` sono **nel file del DETTAGLIO** — verificate: `:78` è
`let setlist: Setlist`, `:81` è `@ObservedObject private var store = QBeatsStore.shared`.
Se il runner nasce lì, la closure **deve trasportarlo**: una `() -> Void` non può, e
obbligherebbe a costruirlo nella root, contro la riga che lo assegna al dettaglio.

⇒ **Forma adottata: `(SetlistRunner) -> Void`.** Ho letto `() -> Void` come descrizione della
FORMA D'INIEZIONE (una closure passata al sito `:104`, come `onBack`), non della firma.
⚠️ **Questa è una mia scelta e la dichiaro come tale.** Avevo già alzato lo stesso rilievo in
A124; il mandato A125 elenca quattro correzioni e questa non è fra esse, quindi non so se il
referee l'abbia vista o l'abbia respinta in silenzio. **Se vuole la lettera, il cambio è
meccanico** — il runner si costruisce nella root con `QBeatsStore.shared` — e sta in un giro solo.

### RILIEVO 2 — la correzione (1) dice «sette stati». Sono OTTO, e la citazione punta all'enum sbagliato

**[M]** Il mandato scrive: «*La macchina ha SETTE stati: .stopped .standby .playing .countIn
.overlayStop .fineSetlist .waitingForDirector (LiveView.swift:243-282)*».

Due misure, entrambe verificate al blob a `fe2091a`:

1. `LivePlaybackState` — l'enum che la guardia legge davvero — ha **OTTO** casi.
   Manca dall'elenco **`.loopActive`**.
   Fonte: `ios_app/QBeats/Models/LivePlaybackState.swift:3-19`.
2. La citazione `LiveView.swift:243-282` **non contiene sette casi ma QUATTRO**, e sono di un
   **altro enum**: è lo `switch` sullo stato del **MOTORE**, `AudioEngine.PlaybackState`
   (`ios_app/QBeats/AudioEngine.swift:24-29`): `.stopped .countIn .playing .pausedAwaitingChoice`.

⚠️ **La REGOLA non ne soffre — anzi ne esce rafforzata.** Una lista di permessi con un solo
membro (`.stopped`) resta corretta con otto stati come con sette, e resterà corretta con nove.
È esattamente l'argomento del referee, e `.loopActive` è la prova che una lista di divieti
avrebbe mancato anche quello. **Ho implementato la regola, non il conteggio.**

### RILIEVO 3 — la correzione (4) chiede di scegliere fra due righe, ma me ne è arrivata UNA

**[M]** Il mandato dice: «*[QUINTO FILE] — TIENI UNA SOLA DELLE DUE RIGHE, CANCELLA L'ALTRA:*»
e poi elenca **solo il ramo «SÌ»**. Il ramo «NO» non c'è nel testo che ho ricevuto.

⇒ **[A] Ho eseguito il ramo trasmesso**, perché è completo, coerente e a rischio nullo:
`LiveView.swift` è EDIT di **soli commenti**, zero righe di comportamento — verificato da
controprova (CP-8). ⚠️ **Se il ramo mancante diceva «NO, LiveView non si tocca», il rimedio è
togliere un solo file dal diff e nient'altro cambia.**

**[A] Come compongo questo con la scheda,** che dice «⛔ Così `LiveView.swift` NON si tocca»:
quel divieto protegge il **comportamento** (che `LiveSession` resti privata e che nessun
cablaggio passi di lì). Un commento non è comportamento. Le due prescrizioni convivono, e
il diff lo dimostra: `LiveView.swift` porta 25 righe aggiunte e 4 tolte, **tutte commento**.

---

## PASSO ZERO — CHE COSA HA LASCIATO A124

### 0.1 · HEAD

**[M]** `git rev-parse HEAD` → **`fe2091a8434f801316ea59c15bb54b006150a3bd`**.
Coincide con l'atteso. Non mi sono fermato.

### 0.2 · `git status --porcelain=v1` — verbatim

Al momento della misura, PRIMA di qualunque intervento, le righe non-untracked erano queste
quattro, e nessun'altra:

```text
 M ios_app/QBeats/SetlistRunner.swift
 M ios_app/QBeats/UI/QLive/QLiveRootView.swift
 M ios_app/QBeats/UI/QLive/QLiveSession.swift
 M ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift
```

⚠️ **Le righe `??` sono 238 e NON le riporto qui una per una**, per non seppellire il referto:
sono il contenuto storico di `HANDOFF/` e `ARCHIVIO.MD/`, invariato. Il conteggio è
`non-untracked: 4` · `untracked: 238`. **Se il referee vuole le 238 righe, le produco.**

### 0.3 · Artefatti col nome `A124`

**[M]** Criterio = **NOME DI FILE**, su due supporti.

| sonda | repo `HANDOFF/` | E: `HANDOFF/` |
|---|---:|---:|
| `ls \| grep -c A124` | **0** | **0** |

⛔ **CONTROLLO POSITIVO IN FORMA DIVERSA DALLA SONDA:** la sonda legge il **nome**; il controllo
legge il **contenuto** (`grep -rlE '\bA121\b'`), meccanismo indipendente. Rende **4** su repo e
**4** su E: per `A121`, ID notoriamente usato ⇒ **il controllo sa distinguere presenza da
assenza senza usare la sonda**. Per `A124` il contenuto rende **1 e 1**: è **il congedo A123**,
che lo nominava come prossimo libero. Una **menzione**, non un artefatto.

⇒ **A124 non aveva prodotto alcun artefatto.** Il punto 0.5 del mandato non aveva bersaglio
al momento della misura.

### 0.4 · Salvataggio del lavoro parziale, poi ripristino

**(a) SALVATO PRIMA DI TOCCARE.** Convenzione letta alla fonte, non inventata: i sei file più
recenti di `HANDOFF/` (giro del 18/08) hanno forma **`DIFF_<AAAA-MM-GG>_<ID>-<BERSAGLIO>.txt`**
— es. `DIFF_2026-08-18_A122-SCALETTA-S5b.txt`. Faccia **LF** (`CR=0`), come impone
`.gitattributes` (`HANDOFF/** -text`). Nome scelto:

```text
HANDOFF/DIFF_2026-08-19_A124-S5b-PARZIALE-ANNULLATO.txt
```

| | valore |
|---|---|
| byte | **14 434** |
| righe | **238** |
| CR | **0** (uniforme LF, come gli altri `DIFF_*.txt`) |
| sha256 | `45e0597951302522f0de3f938091ee7cac0efa3312c04392587e7f777e38f289` |
| file contenuti | **4** (`diff --git` contati) |

**[M] Punto 0.5 applicato a questo stesso file**, che *è* un artefatto A124: porta **in testa
una riga sola** che lo dichiara annullato, sostituito da A125, con la data. Nessuno lo leggerà
come autorità.

**[M] Propagato su E: esplicitamente** — la propagazione non è automatica:
`cmp` → **identici byte-a-byte**, stesso sha256 su entrambi i supporti.

**(b) RIPRISTINO, solo DOPO aver verificato che il salvataggio esiste ed è leggibile**
(prime 6 e ultime 3 righe rilette, 4 intestazioni `diff --git` contate).
`git checkout --` sui quattro file. Esito:

- `git status --porcelain=v1 | grep -v '^??'` → **vuoto**, non-untracked = **0**;
- **controprova del ripristino su un secondo asse**, perché «status pulito» da solo non prova
  che il contenuto sia quello giusto: sha256 del **disco** contro sha256 del **blob convertito
  a CRLF** (il blob è LF, il disco è CRLF per `core.autocrlf=true`).

| file | disco | blob→CRLF | |
|---|---|---|---|
| `SetlistRunner.swift` | `b72332eae2ba77df` | `b72332eae2ba77df` | = |
| `QLiveRootView.swift` | `3d6dc9f0c6629b6c` | `3d6dc9f0c6629b6c` | = |
| `QLiveSession.swift` | `c1c15c59d10808f3` | `c1c15c59d10808f3` | = |
| `QLiveShowDetailView.swift` | `b7daf070082fdf1b` | `b7daf070082fdf1b` | = |

⇒ **Ripristino verificato.** Il salvataggio è ancora al suo posto (14 434 byte).

### 0.6 · Registrazione per il congedo

**A124 = BRUCIATO — ESEGUITO PARZIALMENTE.** Terza categoria, distinta da «mai eseguito» e da
«eseguito». Ha prodotto **un solo artefatto**, il diff annullato qui sopra.
⛔ **Non riusare l'ID, in nessun caso.**

---

## PASSO 1 — COLLISIONE `A125`

**[M]** Criterio = **NOME DI FILE**.

| sonda | repo | E: |
|---|---:|---:|
| `ls HANDOFF/ \| grep -c A125` | **0** | **0** |

⛔ **Controllo positivo, meccanismo DIVERSO dalla sonda** (nome → contenuto): `A122`, ID
notoriamente usato, rende **4** su repo e **3** su E:.
⚠️ L'asimmetria 4/3 **non è un difetto e non è nuova**: il quarto colpo nel repo è la SCALETTA
stessa, che porta «(A122)» in sezione C ed è **stale su E:** — già spiegato nel congedo A123.
Il controllo, comunque, distingue usato da libero.

⇒ **`A125` LIBERO.** Procedo.

---

## PASSO 2 — ANCORA DELLA SCHEDA

**[M]** Estratta dal **blob**, mai da disco: `git show HEAD:HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`.

| | misurato da me | ancora del referee (GitHub raw) | |
|---|---|---|---|
| sha256 | `d1d8b396cb7eefbe2e979fc9f3ae0a7695ca5031947b035213aeccf1a68f361a` | idem | ✅ |
| byte | `66467` | `66 467` | ✅ |
| righe | `457` | `457` | ✅ |

⇒ **Coincide su tutti e tre, per due canali indipendenti** (il tuo GitHub raw, il mio blob
locale). Non mi sono fermato.

---

## PUNTO 9 — `LiveSession.swift`: PERCORSO REALE E RIGHE VERBATIM

**[M] Percorso**, dall'albero git a HEAD:

```text
ios_app/QBeats/Models/LiveSession.swift
```

```text
https://raw.githubusercontent.com/19Bullfrog78/Q-BEATS/fe2091a8434f801316ea59c15bb54b006150a3bd/ios_app/QBeats/Models/LiveSession.swift
```

**Righe 29-36 verbatim dal blob** (29 e 35-36 come contorno; 30-34 sono le citate):

```swift
    // MARK: - Stato
    // Default `.stopped`: all'avvio Vista LIVE niente em-dash centrale.
    // L'overlay `.standby` viene mostrato SOLO quando il SetlistRunner
    // imposta esplicitamente lo state tra una canzone e l'altra (vedi
    // SetlistRunner.swift ramo standby). Cambiato da `.standby(nextSongName: "—")`
    // il 17/05/2026 — TD #28, Step 2 roadmap pre-CD.
    @Published var playbackState: LivePlaybackState = .stopped
    @Published var isBacktrackLocked: Bool = false
```

**[A] Perché dodici tentativi sono andati a vuoto — c'è un OMONIMO**, ed è la trappola più
economica di questo corpus. Nella cartella `UI/QLive/` esiste `QLiveSession.swift`, un file
**diverso** con un nome quasi uguale. I due:

| file | percorso | che cos'è |
|---|---|---|
| `LiveSession.swift` | `ios_app/QBeats/**Models**/` | sorgente di verità del display della Vista LIVE |
| `QLiveSession.swift` | `ios_app/QBeats/**UI/QLive**/` | contenitore-sessione della stanza, possiede lo slot del runner |

⚠️ **Il primo sta in `Models/`, non in `UI/`**: è lì che una ricerca «per vicinanza alla Vista
LIVE» non arriva.

⛔ **E QUESTO CAMBIA LA CITAZIONE DELLA SCHEDA.** La scheda ⟦S5b⟧, in `Cond (b)`, scrive
«`LiveSession.swift:30-34`» **senza cartella**. Il numero di riga è giusto, il contenuto è
quello atteso — ma il puntatore è **ambiguo fra due file esistenti**. Proposta di incisione
in fondo a questo referto.

---

## IL DIFF — VERBATIM E COMPLETO

Depositato anche come file a sé, con la convenzione vigente:

```text
HANDOFF/DIFF_2026-08-19_A125-S5b-CABLAGGIO.txt
```

| | valore |
|---|---|
| byte | **16 588** |
| righe | **257** |
| CR | **0** (LF, come tutti i `DIFF_*.txt`) |
| sha256 | `00628d781472c537dff20df5f09d70f4aced2e5b55b9c76a7e9f25909010d3ba` |

Righe per file (`git diff --numstat`):

| file | + | − |
|---|---:|---:|
| `SetlistRunner.swift` | 34 | 0 |
| `LiveView.swift` | 25 | 4 |
| `QLiveRootView.swift` | 35 | 1 |
| `QLiveSession.swift` | 28 | 1 |
| `QLiveShowDetailView.swift` | 37 | 3 |
| **totale** | **159** | **9** |

⚠️ **Il rapporto commento/codice è deliberato e va detto:** le righe di **comportamento** nuove
sono **nove** — il mutatore (2), la costruzione+consegna del runner (1), la guardia d'armamento
(3), `.disabled(!isEnabled)` (1), e l'apertura/chiusura del sito di costruzione del dettaglio (2).
Tutto il resto è **perché**: è ciò che impedisce a una pulizia futura di disfare l'atomo senza
accorgersene — vedi il commento (2) su `LiveView.swift:250`, che è esattamente quel caso.

```diff
diff --git a/ios_app/QBeats/SetlistRunner.swift b/ios_app/QBeats/SetlistRunner.swift
index 1e60d7d..cce8654 100644
--- a/ios_app/QBeats/SetlistRunner.swift
+++ b/ios_app/QBeats/SetlistRunner.swift
@@ -256,6 +256,14 @@ final class SetlistRunner: ObservableObject {
     /// per evitare che la videata appaia "vuota" (nome canzone/sezione/next
     /// blank) al primo ingresso prima del tap Play.
     ///
+    /// ⚠️ MARCATURA ⟦S5b⟧ — LE TRE RIGHE QUI SOTTO SONO SCADUTE: si marcano, non si
+    /// riscrivono. Da ⟦S5b⟧ l'ingresso in uno show NON è più `.stopped`, è ARMA +
+    /// STANDBY sulla prima canzone — `BOX5_QBEATS.md:331` (QL-SHOWS-07).
+    /// L'obiezione storica non si applica: TD #28 tolse lo standby d'ingresso
+    /// (`Models/LiveSession.swift:30-34`) perché mostrava un EM-DASH, cioè uno
+    /// standby SENZA NOME VERO, con nessuna setlist caricata. Con un runner
+    /// armato il nome c'è, ed è quello della canzone che partirà al tocco.
+    ///
     /// Coerente con TD #28 (17/05/2026): stato iniziale Vista LIVE è `.stopped`,
     /// nessun overlay standby — la videata deve mostrare i dati della setlist
     /// caricata già in stato `.stopped`.
@@ -273,6 +281,32 @@ final class SetlistRunner: ObservableObject {
         updateSessionDisplay(session: session)
         session.currentBPM         = section.bpm
         session.totalBarsInSection = Int(section.repetitions)
+        // ⟦S5b⟧ `Cond (b)` — ARMAMENTO D'INGRESSO. Il player si monta FERMO e ARMATO:
+        // titolo della prima canzone che pulsa sopra il player oscurato
+        // (`LiveView.swift:129` opacità 0,10 · `:132-138` overlay + tap-ovunque ·
+        // `StandbyOverlayView.swift:18-24` e `:31-35`). Il click NON parte qui: parte al
+        // tocco successivo, che va a `startCurrentSong` e suona QUESTA canzone, perché
+        // `currentSongIdx` è ancora 0.
+        //
+        // IL NOME GIUSTO È `currentSong`, NON `nextSong`. `.standby(nextSongName:)`
+        // significa «la canzone che partirà al prossimo tap»: nel ramo standby fra due
+        // canzoni quel nome è letto DOPO `currentSongIdx += 1` (:343-345), quindi è
+        // sempre la corrente-dopo-l'avanzamento. All'ingresso, con indice 0, è la PRIMA.
+        // Usare `nextSong` qui darebbe la SECONDA canzone.
+        //
+        // ⛔ `Cond (c)` — LISTA DI PERMESSI, NON DI DIVIETI (correzione del referee).
+        //    Si arma SOLO da `.stopped`. `primeDisplay` gira a OGNI `onAppear`, non solo
+        //    al primo (unico chiamante: `LiveView.swift:231`), e `LivePlaybackState` ha
+        //    OTTO casi (`Models/LivePlaybackState.swift:3-19`): .standby .countIn
+        //    .playing .stopped .loopActive .overlayStop .fineSetlist .waitingForDirector.
+        //    Un divieto scritto al contrario («arma a meno che stia suonando») ne
+        //    coprirebbe uno e calpesterebbe gli altri: rimetterebbe l'overlay sopra
+        //    END SHOW, sopra la pausa a metà sezione e sopra l'attesa del Direttore.
+        //    L'elenco dei permessi ha un solo membro, e così resta corretto anche se
+        //    domani se ne aggiunge un nono.
+        if case .stopped = session.playbackState, let song = currentSong {
+            session.playbackState = .standby(nextSongName: song.name)
+        }
     }
 
     // MARK: - Closure end-of-section (autopropagante)
diff --git a/ios_app/QBeats/UI/Live/LiveView.swift b/ios_app/QBeats/UI/Live/LiveView.swift
index 8e907ed..750d6ce 100644
--- a/ios_app/QBeats/UI/Live/LiveView.swift
+++ b/ios_app/QBeats/UI/Live/LiveView.swift
@@ -226,6 +226,14 @@ struct LiveView: View {
             //
             // NB nomenclatura: questo NON è il "Bug 1" del RECAP 24/05 (Follower
             // no update cross-device — Problema B). Questo è Problema A locale.
+            // ⚠️ CORRETTO DA ⟦S5b⟧ — le due righe qui sotto NON valgono più come
+            // scritte. Da ⟦S5b⟧ `primeDisplay` non lascia più la videata in
+            // `.stopped`: se e SOLO se lo stato è `.stopped`, la porta in
+            // `.standby(nextSongName:)` sulla PRIMA canzone — arma + standby
+            // d'ingresso, `BOX5_QBEATS.md:331` (QL-SHOWS-07). Il click non parte:
+            // parte al tocco sull'overlay, :134-137. Resta vero il resto: la
+            // videata mostra i dati della setlist caricata già prima del Play.
+            // (Storia, da leggere come tale:)
             // Coerente con TD #28 (17/05/2026): stato iniziale `.stopped`, no
             // overlay standby, videata deve mostrare dati setlist caricata.
             runner.primeDisplay(session: session)
@@ -242,10 +250,23 @@ struct LiveView: View {
         .onReceive(audioEngine.$playbackState) { state in
             switch state {
             case .stopped:
-                // L1.b: il runner gestisce .standby e .fineSetlist impostando
-                // session.playbackState PRIMA di chiamare audioEngine.stop().
-                // Lo stop() dispatcha .stopped su main qualche ms dopo —
-                // NON sovrascrivere stati già impostati dal runner.
+                // ⛔ QUESTA GUARDIA HA DUE MOTIVI, NON UNO. Chi ne togliesse uno solo
+                //    romperebbe l'altro in silenzio: non è codice difensivo ridondante.
+                //
+                //  (1) L1.b, motivo storico: il runner gestisce .standby e .fineSetlist
+                //      impostando session.playbackState PRIMA di chiamare
+                //      audioEngine.stop(). Lo stop() dispatcha .stopped su main qualche
+                //      ms dopo — NON sovrascrivere stati già impostati dal runner.
+                //
+                //  (2) ⟦S5b⟧ — È CIÒ CHE TIENE IN PIEDI L'ARMAMENTO D'INGRESSO. All'apparire
+                //      del player il motore è fermo, e `@Published` consegna il valore
+                //      CORRENTE a chi si sottoscrive: questo `.onReceive` riceve `.stopped`
+                //      anche senza alcun cambio di stato. Senza il `case .standby` qui
+                //      sotto, quel `.stopped` scriverebbe sopra lo standby appena armato
+                //      da `primeDisplay` (:231) e l'overlay non comparirebbe mai — lo
+                //      Start sembrerebbe non fare nulla.
+                //      ⚠️ Una pulizia futura che togliesse `.standby` da questa lista
+                //      romperebbe ⟦S5b⟧ senza toccarne una riga.
                 switch session.playbackState {
                 case .standby, .fineSetlist:
                     return
diff --git a/ios_app/QBeats/UI/QLive/QLiveRootView.swift b/ios_app/QBeats/UI/QLive/QLiveRootView.swift
index 6f5561f..ef9effa 100644
--- a/ios_app/QBeats/UI/QLive/QLiveRootView.swift
+++ b/ios_app/QBeats/UI/QLive/QLiveRootView.swift
@@ -101,7 +101,28 @@ struct QLiveRootView: View {
             // difensivo — non dovrebbe accadere (unico chiamante di navigate(.detail) è
             // onSelectShow sopra, che valorizza selectedSetlist nello stesso gesto).
             if let show = selectedSetlist {
-                QLiveShowDetailView(setlist: show, onBack: { navigate(to: .shows) })
+                QLiveShowDetailView(
+                    setlist: show,
+                    onBack: { navigate(to: .shows) },
+                    // ⟦S5b⟧ `Cond (a)` — L'INVARIANTE È LA SINCRONIA, NON L'ORDINE
+                    // (correzione del referee). Le due righe qui sotto stanno nella
+                    // STESSA closure e senza alcuna attesa in mezzo: niente `Task`,
+                    // niente `async`, niente `asyncAfter`. SwiftUI non ridisegna fra
+                    // due assegnazioni sincrone, quindi il ramo `.metronome` non può
+                    // mai montarsi con `runner == nil` e il ramo `else` non si vede.
+                    // ⚠️ Basta infilare un'attesa fra le due per perdere la garanzia:
+                    //    lì il ramo `else` diventa visibile per un frame. L'ordine
+                    //    prescritto dalla scheda è rispettato — costa nulla — ma non
+                    //    è lui a proteggere.
+                    // ⛔ NESSUNO stop audio qui e nessun avvio: `navigate` resta muto
+                    //    sul transport (decisione CD 18/07, :78-85). Questo è un
+                    //    INGRESSO — arma e basta. Il click parte al secondo tap
+                    //    (`LiveView.swift:134-137`).
+                    onStart: { runner in
+                        roomSession.install(runner)
+                        navigate(to: .metronome)
+                    }
+                )
             } else {
                 EmptyView()
             }
@@ -170,6 +191,19 @@ struct QLiveRootView: View {
                 // Oggi la pagina resta comunque IRRAGGIUNGIBILE: nessuno chiama
                 // `navigate(to: .metronome)`. L'unico chiamante dell'imbuto è
                 // il back del player qui sopra, e porta a `.shows`.
+                //
+                // ⚠️ MARCATURA ⟦S5b⟧ — LE DUE FRASI QUI SOPRA SONO SCADUTE. Si marcano,
+                //    non si riscrivono: sono la storia di come ci si è arrivati.
+                //    (1) «⟦S5⟧ NON parte senza questo empty-state» — superata dalla
+                //        CANCELLAZIONE dell'atomo A3 empty-state
+                //        (`LIBRO_MASTRO_QBEATS.md:355`). Nessun disegno CD serve: qui il
+                //        ramo `else` resta una GUARDIA DIFENSIVA, come il gemello a
+                //        :105-107 nello stesso `switch`. ⟦S5b⟧ è partita senza.
+                //    (2) «nessuno chiama `navigate(to: .metronome)`» — falsa da ⟦S5b⟧:
+                //        lo chiama `onStart` qui sopra. ⇒ il ramo resta irraggiungibile,
+                //        ma per una RAGIONE DIVERSA: non più «nessuno naviga qui», bensì
+                //        «chi naviga qui ha già installato il runner, nella stessa
+                //        closure sincrona».
                 EmptyView()
             }
         }
diff --git a/ios_app/QBeats/UI/QLive/QLiveSession.swift b/ios_app/QBeats/UI/QLive/QLiveSession.swift
index dfc4d29..f61a9d7 100644
--- a/ios_app/QBeats/UI/QLive/QLiveSession.swift
+++ b/ios_app/QBeats/UI/QLive/QLiveSession.swift
@@ -31,6 +31,33 @@ import Combine
 final class QLiveSession: ObservableObject {
 
     /// Slot del runner. `nil` = nessuna scaletta in esecuzione.
-    /// `private(set)` e senza mutatore: in ⟦S4R⟧ non è riempibile da nessuno.
+    /// `private(set)`: da ⟦S5b⟧ si riempie SOLO da `install(_:)` qui sotto.
     @Published private(set) var runner: SetlistRunner? = nil
+
+    /// ⟦S5b⟧ — MUTATORE DELLO SLOT: la porta che ⟦S4R⟧ aveva lasciato mancante
+    /// APPOSTA (:12-15). È il solo punto in cui il runner entra nella stanza.
+    ///
+    /// ⛔ SOSTITUISCE SEMPRE, ANCHE A SLOT PIENO — ed è una scelta, non una
+    /// distrazione. Un `if runner == nil` qui riuserebbe il runner del PRIMO show
+    /// quando la band ne apre un SECONDO nella stessa serata: partirebbe la
+    /// scaletta sbagliata. L'assegnazione secca è l'unica forma che non sa
+    /// sbagliare. Il vecchio runner perde qui il suo ultimo riferimento forte.
+    ///
+    /// ⛔ INSTALLA E BASTA: non avvia l'audio, non arma nulla, non tocca
+    /// AudioEngine. Contratto `BOX5_QBEATS.md:331` (QL-SHOWS-07) e
+    /// `BOX5_QBEATS.md:354` (§3): l'ingresso in uno show è SEMPRE arma + standby,
+    /// il click parte al SECONDO tap. L'armamento vive in
+    /// `SetlistRunner.primeDisplay(session:)`, che gira nell'`onAppear` del player.
+    ///
+    /// ⚠️ L'INVARIANTE DEL CHIAMANTE È LA SINCRONIA, non l'ordine (⟦S5b⟧ `Cond (a)`,
+    /// come corretta dal referee): questa chiamata e la `navigate(to: .metronome)`
+    /// che la segue devono stare nella STESSA closure e SENZA alcuna attesa in
+    /// mezzo — niente `Task`, niente `async`, niente `asyncAfter`. SwiftUI non
+    /// ridisegna fra due assegnazioni sincrone, quindi il ramo `else` del gate
+    /// `if let runner` non può apparire. Basta un'attesa a spezzare la garanzia:
+    /// lì il ramo `else` diventa visibile. L'ordine si rispetta comunque — costa
+    /// nulla — ma non è lui a proteggere.
+    func install(_ newRunner: SetlistRunner) {
+        runner = newRunner
+    }
 }
diff --git a/ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift b/ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift
index 505fbcc..1d58215 100644
--- a/ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift
+++ b/ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift
@@ -77,6 +77,21 @@ import SwiftUI
 struct QLiveShowDetailView: View {
     let setlist: Setlist
     let onBack: () -> Void
+    /// ⟦S5b⟧ — Start. Il runner si costruisce QUI: questa vista possiede già i due
+    /// soli ingredienti che servono, `setlist` (:78) e `store` (:81), e
+    /// `SetlistRunner.init(setlist:store:)` non chiede altro
+    /// (`SetlistRunner.swift:61`). Il presentatore lo installa nello slot di
+    /// stanza e naviga, nella stessa closure sincrona — ⟦S5b⟧ `Cond (a)`.
+    ///
+    /// ⚠️ DIVERGENZA DALLA LETTERA DELLA SCHEDA, DICHIARATA E NON RISOLTA DA ME.
+    /// La scheda scrive «closure `() -> Void` … nella forma di `onBack`», e nello
+    /// stesso elenco prescrive che il runner nasca IN QUESTO FILE, citandone le
+    /// righe :78 e :81. Le due prescrizioni stanno insieme solo se la closure
+    /// TRASPORTA il runner: una `() -> Void` obbligherebbe a costruirlo nella
+    /// root, contro la riga che lo assegna qui. Forma adottata:
+    /// `(SetlistRunner) -> Void`. Rilievo #1 del referto A125 — se il referee
+    /// vuole la lettera, il cambio è meccanico e sta in un solo giro.
+    let onStart: (SetlistRunner) -> Void
 
     @ObservedObject private var store = QBeatsStore.shared
 
@@ -287,9 +302,15 @@ struct QLiveShowDetailView: View {
     private func startfoot(_ resolved: (songs: [Song], missingIDs: [UUID])) -> some View {
         let isEnabled = !resolved.songs.isEmpty
         return Button {
-            // ⟦S5b⟧ cablerà qui l'avvio reale (SetlistRunner.startSetlist). Vuota apposta:
-            // eccezione dichiarata al divieto CD-Q7 sui bottoni morti (LIBRO v31), stessa
-            // forma dello slot senza mutatore di QLiveSession (⟦S4R⟧).
+            // ⟦S5b⟧ — ARMA, NON SUONA. Qui non si tocca l'audio: si costruisce il runner
+            // con la setlist SCELTA e lo si consegna al presentatore.
+            // ⛔ NON si chiama `startSetlist`: farebbe partire il click al PRIMO tocco,
+            //    contro `BOX5_QBEATS.md:331` (QL-SHOWS-07 — «l'ingresso in uno show è
+            //    SEMPRE arma + standby, qualunque sia il flag standby della prima
+            //    canzone») e `BOX5_QBEATS.md:354` (§3 — «il click parte al secondo tap,
+            //    schermo ovunque, o via MIDI»). Il secondo tap è già cablato e non si
+            //    tocca: `LiveView.swift:134-137`.
+            onStart(SetlistRunner(setlist: setlist, store: store))
         } label: {
             HStack(spacing: 10) {
                 PlayGlyphShape()
@@ -333,6 +354,19 @@ struct QLiveShowDetailView: View {
             .opacity(isEnabled ? 1.0 : 0.4)   // token DS --disabled: 0.4
         }
         .buttonStyle(.plain)
+        // ⟦S5b⟧ `Cond (d)` — IL TOCCO SI CHIUDE su show vuoto o tutto-orfano. Fino a
+        // qui `isEnabled` pilotava SOLO l'aspetto — ombra (:323), bordo (:326-331),
+        // opacità (:333) — e il bottone SEMBRAVA spento restando tappabile: `.disabled(`
+        // rendeva 0 occorrenze in questo file, mentre il corpus lo usa in 6 file. Senza
+        // questa riga un tocco su una scaletta orfana costruisce un runner a catalogo
+        // VUOTO, `primeDisplay` esce al primo `guard` (`SetlistRunner.swift:272`) e il
+        // player si monta BIANCO.
+        // ⚠️ DA GUARDARE AL GATE DEVICE, e non ho modo di vederlo io: `.disabled` agisce
+        //    anche sull'ambiente. Se lo stile `.plain` applicasse un proprio smorzamento
+        //    allo stato disabilitato, lo Start spento risulterebbe più scuro dello 0,4
+        //    prescritto (:333). Confronto: Frame F/G del freeze,
+        //    `DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html`.
+        .disabled(!isEnabled)
         .padding(.horizontal, 18)
         .padding(.top, 14)
         .padding(.bottom, 20)
```

---

## LE QUATTRO CORREZIONI — COME LE HO RISOLTE, CON LA RIGA CHE LE REALIZZA

### (1) `Cond (c)` — LISTA DI PERMESSI, NON DI DIVIETI

**Riga che la realizza** — `ios_app/QBeats/SetlistRunner.swift`, dentro `primeDisplay`:

```swift
        if case .stopped = session.playbackState, let song = currentSong {
            session.playbackState = .standby(nextSongName: song.name)
        }
```

Il permesso ha **un solo membro**: `.stopped`. Tutto il resto — `.standby` `.playing`
`.countIn` `.loopActive` `.overlayStop` `.fineSetlist` `.waitingForDirector` — non arma, e
non perché sia elencato, ma perché **non è nella lista**. È la proprietà che volevi: resta
corretta anche quando l'enum cresce.

⛔ **Conseguenza che dichiaro perché non sia una sorpresa: NON ho aggiunto alcun flag
`hasStartedPlayback`.** In A124 ne avevo messo uno; la lista di permessi lo rende superfluo,
e un secondo stato che dice quasi la stessa cosa è debito, non robustezza.

⚠️ **Il caso residuo, dichiarato:** dopo uno **stop manuale a metà show** la sessione torna
`.stopped`; se il player si ri-presentasse in quel momento, `primeDisplay` **riarmerebbe**.
**[M] Oggi non è raggiungibile:** `primeDisplay` ha un solo chiamante (`LiveView.swift:231`,
dentro l'`onAppear`), e non esiste navigazione che nasconda e rimostri il player restando in
`.metronome` — il mixer è un overlay nella stessa vista, e il back porta a `.shows`,
distruggendo `LiveView`. **Non l'ho coperto perché coprirlo oggi significherebbe aggiungere
lo stato che ho appena tolto.** Se domani nasce una vista che copre il player, va rivisto lì.

### (2) `Cond (a)` — L'INVARIANTE È LA SINCRONIA, NON L'ORDINE

**Righe che la realizzano** — `ios_app/QBeats/UI/QLive/QLiveRootView.swift`:

```swift
                    onStart: { runner in
                        roomSession.install(runner)
                        navigate(to: .metronome)
                    }
```

Stessa closure, due assegnazioni **sincrone**, **zero attese**: nessun `Task`, nessun `async`,
nessun `await`, nessun `asyncAfter`, nessun `DispatchQueue`. L'ordine della scheda è comunque
rispettato — costa nulla — ma la controprova **CP-2b** verifica la sincronia come invariante
separata, e fallisce se qualcuno infila un `Task` fra le due righe **anche lasciando l'ordine
giusto**. È la differenza fra le due formulazioni, resa misurabile.

Il perché è inciso in due punti: al sito d'uso (`QLiveRootView`) e sul mutatore
(`QLiveSession.install(_:)`), così chi arriva da una delle due porte lo trova.

### (3) IL MUTATORE SOSTITUISCE SEMPRE

**Forma scelta** — `ios_app/QBeats/UI/QLive/QLiveSession.swift`:

```swift
    func install(_ newRunner: SetlistRunner) {
        runner = newRunner
    }
```

**Assegnazione secca. Nessun `if`, nessun `guard`, nessuna condizione.** Dichiarato nel
commento il motivo: un `if runner == nil` riuserebbe il runner del PRIMO show quando la band
ne apre un SECONDO nella stessa serata, e partirebbe la scaletta sbagliata.
La controprova **CP-4** rifiuta qualunque `if`/`guard` dentro quel corpo.

⚠️ **Nome scelto: `install(_:)`**, e non `startShow` o simili. Deliberato: questo metodo **non
avvia niente**, e un nome che promettesse un avvio sarebbe esattamente la confusione
(arma ≠ suona) che l'atomo esiste per tenere separata.

### (4) `LiveView.swift` — QUINTO FILE, SOLI COMMENTI

Due incisioni, zero righe di comportamento (verificato da **CP-8**):

- **`:226-233`** — corretta la frase «stato iniziale `.stopped`, no overlay standby», che dopo
  ⟦S5b⟧ è falsa. La riga vecchia resta sotto, marcata come storia.
- **`:250-269`** — la guardia `case .standby, .fineSetlist: return` ora dichiara **due** motivi.
  ⛔ **Questo è il punto che mi hai chiesto di scrivere, ed è quello che vale di più
  nell'intero diff.** Lo riporto perché il referee lo veda senza cercarlo:

> All'apparire del player il motore è fermo, e `@Published` consegna il valore **corrente** a
> chi si sottoscrive: quell'`.onReceive` riceve `.stopped` **anche senza alcun cambio di
> stato**. Senza il `case .standby` in quella lista, quel `.stopped` scriverebbe sopra lo
> standby appena armato da `primeDisplay` (`:231`), **l'overlay non comparirebbe mai e lo
> Start sembrerebbe non fare nulla**.

**[M] Ho verificato che oggi la guardia regge**, e come: al primo giro `session.playbackState`
vale ancora `.stopped`, quindi il ramo cade su `default: break` e riassegna `.stopped` — una
scrittura inerte; **poi** l'`onAppear` arma. Da quel momento ogni successivo `.stopped` del
motore trova `.standby` e **ritorna**. ⇒ **L'ordine fra `onReceive` e `onAppear` non conta**,
e questo è il motivo per cui l'atomo non dipende da un dettaglio di scheduling SwiftUI.
⚠️ **Ma dipende da quella riga**, ed è per questo che ora è scritto lì.

---

## FACCIA DEI CINQUE FILE — PRIMA E DOPO

CR contati sui **byte** (`tr -cd '\r' | wc -c`), **mai** con `grep`.
Regola: `CRLF` e `LF-sole` devono essere **uno zero e un numero**, mai due numeri.

| file | PRIMA | DOPO | |
|---|---|---|---|
| `QLiveSession.swift` | CRLF 36 · LF-sole **0** | CRLF 63 · LF-sole **0** | uniforme |
| `QLiveShowDetailView.swift` | CRLF 409 · LF-sole **0** | CRLF 443 · LF-sole **0** | uniforme |
| `QLiveRootView.swift` | CRLF 177 · LF-sole **0** | CRLF 211 · LF-sole **0** | uniforme |
| `SetlistRunner.swift` | CRLF 382 · LF-sole **0** | CRLF 416 · LF-sole **0** | uniforme |
| `LiveView.swift` | CRLF 466 · LF-sole **0** | CRLF 487 · LF-sole **0** | uniforme |

⚠️ **Nota sul metodo, perché il «prima» non si poteva leggere da disco:** i file erano già
modificati quando ho misurato. La colonna PRIMA è il **blob a HEAD convertito a CRLF**, cioè
la faccia che il disco *aveva* — non il blob nudo, che è LF. La conversione è quella che fa
git stesso: `.gitattributes` non copre `ios_app/`, `core.autocrlf=true`, quindi **blob LF →
disco CRLF**. È anche il motivo per cui `SCALETTA` e i `DIFF_*.txt` sono LF e questi no:
`HANDOFF/** -text`.

**Strumento usato:** editing in Python su file aperti con `newline=''`, sostituzioni su testo
con `\r\n` espliciti, riscrittura senza traduzione — e ogni sostituzione **asserita esattamente
una volta** (se un'ancora fosse comparsa 0 o 2 volte, lo script si sarebbe fermato).

---

## CONTROPROVE — QUATTORDICI, OGNUNA CON LA SUA DIMOSTRAZIONE DI FALLIBILITÀ

Metodo: ogni controllo viene **prima** applicato a un caso **noto-cattivo** ricostruito in
memoria. Se non fallisce lì, si dichiara **inutile** e non si porta.

| # | cosa verifica | caso noto-cattivo | ha saputo fallire? | esito sul reale |
|---|---|---|---|---|
| **CP-1** ×5 | faccia uniforme | file misto CRLF+LF | ✅ `MISTO: CRLF=2 LF-sole=1` | **PASSA** ×5 |
| **CP-2a** | `install` precede `navigate` | closure a ordine invertito | ✅ `ORDINE INVERTITO` | **PASSA** |
| **CP-2b** | zero attese nella closure | closure con `Task { }` in mezzo | ✅ `ATTESA nella closure: Task` | **PASSA** |
| **CP-3a** | guardia a permessi | forma a **divieto** (`!hasStartedPlayback`) | ✅ `SENZA lista di permessi` | **PASSA** |
| **CP-3b** | guardia presente | armamento **senza** guardia | ✅ `SENZA lista di permessi` | **PASSA** |
| **CP-4** | mutatore sostituisce sempre | `guard runner == nil else { return }` | ✅ `ha una condizione` | **PASSA** |
| **CP-5bis** | arma con `currentSong` | armamento da `nextSong` | ✅ `armerebbe la SECONDA` | **PASSA** |
| **CP-6** | arma, non suona | azione che chiama `startSetlist` | ✅ `AVVIA AUDIO: startSetlist, audioEngine` | **PASSA** |
| **CP-7** | tocco chiuso su show vuoto | **il file a HEAD**, che ne aveva 0 | ✅ `.disabled( assente` | **PASSA** |
| **CP-8** | `LiveView` = soli commenti | lo stesso diff + 1 riga di codice | ✅ `1 riga NON commento` | **PASSA** |

⛔ **UNA CONTROPROVA È STATA DICHIARATA INUTILE E RIFATTA. Lo scrivo perché è il reperto di
metodo del giro.**

La prima **CP-5** verificava che la riga d'armamento contenesse `song.name`. Applicata al caso
noto-cattivo — armamento da `nextSong` invece che da `currentSong` — **NON è fallita**: nei due
casi la resa è identica, `song.name` c'è in entrambi. Guardava **il risultato**, che è uguale,
invece della **sorgente del legame**, che è ciò che cambia.

**CP-5bis** guarda `let song = currentSong` contro `let song = nextSong`, sulle sole righe
eseguibili (i commenti non fanno testo). Applicata allo stesso caso cattivo **fallisce**:
`il legame nasce da nextSong -> armerebbe la SECONDA canzone`. Sul file reale passa, e riporta
la riga misurata:

```swift
if case .stopped = session.playbackState, let song = currentSong {
```

⇒ **[A] La regola generale, che vale oltre questo atomo:** una controprova che guarda l'OUTPUT
di due percorsi che producono lo stesso output non può distinguerli. Va puntata sul punto in
cui i percorsi **divergono**, non su quello in cui riconvergono.

**Controlli aggiuntivi, non portati come cancelli** perché troppo grezzi per esserlo, ma
riportati: bilancio graffe `{`/`}` pari su tutti e cinque i file (2/2, 49/49, 16/16, 39/39,
61/61). **Non è una prova di sintassi**, è un indizio che non ho lasciato un blocco aperto.

---

## ⛔ LIMITI DICHIARATI — QUELLO CHE NON HO POTUTO VERIFICARE

**Non li aggiro e non li attenuo. Sono cinque.**

1. ⛔ **NON SO SE IL CODICE COMPILA.** Non ho Mac, non ho Xcode, e la CI (`iOS Signed Build`)
   gira **solo dopo un commit** — che questo mandato vieta. ⇒ **Il diff che stai leggendo non
   è mai passato da un compilatore.** È la lacuna più grande del referto e nessuna controprova
   qui dentro la copre: le mie sono verifiche **testuali**, non semantiche.
   ⚠️ Il punto più esposto è il **sito di costruzione del dettaglio**: aggiungendo `onStart`
   cambia la firma dell'init sintetizzato di `QLiveShowDetailView`. **[M] Ho verificato che il
   sito di costruzione è UNO SOLO** (`QLiveRootView.swift:104`, `git grep` sull'intero
   `ios_app/`) e **che non esistono `PreviewProvider` né `#Preview` in quel file** — le due
   cose che romperebbero la build in silenzio. Ma «ho contato i chiamanti» non è «compila».

2. ⚠️ **CONCORRENZA — precedente in-repo, non verifica mia.** `SetlistRunner` e `QLiveSession`
   sono `@MainActor`, e li costruisco/chiamo da closure di `Button` e da `onStart`. **[M] Il
   corpus fa già esattamente questo su percorsi esercitati a ogni show**: `LiveView.swift:135-137`
   chiama `runner.startCurrentSong` da un `onTapGesture`, e `QLiveRootView.swift:95-98` muta
   `@State` da una closure iniettata. ⇒ **[A] Mi aspetto che compili per simmetria.** Non è una
   prova: è un'inferenza da un precedente, e la dichiaro come tale (§7).

3. ⛔ **NON HO VISTO NIENTE A SCHERMO.** Due punti vanno guardati sul device, e li ho incisi nel
   codice perché non si perdano:
   - **`.disabled(!isEnabled)` sullo Start** — è la prima occorrenza di `.disabled` in quel
     file. Se `PlainButtonStyle` applicasse un proprio smorzamento allo stato disabilitato, lo
     Start spento risulterebbe **più scuro dello 0,4 prescritto** dal freeze (`:333`). Non ho
     fonte su quel comportamento di SwiftUI e **non ne invento una**: va confrontato con i
     Frame F/G del freeze.
   - **l'overlay d'ingresso** — che compaia, col nome della **prima** canzone, **che pulsi**, e
     che **non suoni nulla**. È il Passo (1) del gate della scheda, e distingue «armato» da
     «fermo».

4. ⚠️ **NON HO RIVERIFICATO TUTTE E VENTICINQUE LE CITAZIONI DELLA SCHEDA.** Ho verificato al
   sorgente **quelle su cui poggia il codice che ho scritto** — `:78` `:81` `:288` `:289-293`
   `:323` `:326-331` `:333` del dettaglio · `:61` `:271-276` `:343-345` del runner · `:11`
   `:129` `:132-138` `:161` `:231` `:242-282` di `LiveView` · `:18-24` `:31-35` di
   `StandbyOverlayView` · `:44` `:88` `:104` `:105-107` di `QLiveRootView` · `:30-35` di
   `Models/LiveSession` · `BOX5:331` e `BOX5:354` — **e reggono tutte**. Le restanti (in
   particolare i puntatori `BOX5:324` `:333` `:362` `:401` `:404` e `LIBRO:166`, che stanno
   nella sezione **OPEN**, fuori porta) **non le ho rimisurate in questo mandato**.

5. ⚠️ **IL SECONDO SHOW DELLA SERATA NON È COLLAUDABILE DA ME.** Il mutatore che sostituisce
   sempre è la mia risposta alla correzione (3), ed è corretto per costruzione; ma il difetto
   noto «secondo show con l'audio ancora acceso» è di ⟦S6F⟧ e **resta aperto**. Il gate device
   di ⟦S5b⟧ non lo copre, e **non deve sembrare che lo copra**.

---

## PROPOSTE DI INCISIONE — SOLO PROPOSTE, NON HO TOCCATO NULLA

Perimetro rispettato: **zero modifiche ai canonici, zero voci di registro.** Le lascio qui per
il giro doc in coda.

1. **`SCALETTA` — la firma della closure in ⟦S5b⟧.** La scheda dice `() -> Void` e nello stesso
   elenco assegna la costruzione del runner al dettaglio. Delle due, una. Proposta: correggere
   in **`(SetlistRunner) -> Void`**, o spostare esplicitamente la costruzione nella root.
   *(Rilievo 1.)*

2. **`SCALETTA` — il puntatore `LiveSession.swift:30-34` in `Cond (b)` è ambiguo.** Esistono due
   file con nome quasi identico; quello giusto è **`Models/LiveSession.swift`**. Proposta:
   qualificare la cartella. *(È il motivo dei dodici tentativi a vuoto del referee.)*

3. **`BUGS` — nuovo ticket, 🟡 proposta BASSA: `TD-start-disabled-aspetto-non-visto`.** Lo
   Start disabilitato ora porta `.disabled()` oltre all'opacità 0,4: se `.plain` smorza per
   conto suo, l'aspetto diverge dal freeze. Da chiudere al primo gate device, non prima.

4. **`SCALETTA` o `BUGS` — registrare il reperto di metodo di CP-5:** *una controprova che
   guarda l'output di due percorsi che producono lo stesso output non può distinguerli; va
   puntata dove i percorsi divergono.* È il seguito naturale della controprova d'ordine di
   A121/A122 ed è costata un giro a scoprirla.

5. **Congedo — `A124` = BRUCIATO, ESEGUITO PARZIALMENTE.** Terza categoria. Unico artefatto:
   `HANDOFF/DIFF_2026-08-19_A124-S5b-PARZIALE-ANNULLATO.txt`, già marcato annullato in testa.

---

## STATO DI CONSEGNA

| | |
|---|---|
| commit | ⛔ **NESSUNO** |
| push | ⛔ **NESSUNO** |
| rami aperti | ⛔ **NESSUNO** |
| HEAD | `fe2091a8434f801316ea59c15bb54b006150a3bd`, invariato |
| albero | 5 file modificati sotto `ios_app/`, nessun canonico toccato |
| cancello 1 — CI verde | ⏸️ **non valutabile**: la CI gira dopo il commit |
| cancello 2 — diff visto dal referee | ⏸️ **questo referto** |
| gate device | ⏸️ **da fare**, dopo il commit, con i quattro passi della scheda |

⇒ **I due cancelli restano distinti.** Questo mandato non li collassa: consegno il diff, la
ratifica è tua, l'autorizzazione al commit è di Mauro e viene a parte.

---

*A125-FINE*
