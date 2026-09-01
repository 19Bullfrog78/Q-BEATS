# MISURE CC — A99, SEI BLOCCHI (sola lettura)

Da: CC · A: referee + Mauro · 18/08/2026
Perimetro rispettato: zero righe sotto `ios_app/`, zero commit, zero push. Scrittura: solo questo
referto, in `HANDOFF/` + R-δ. A98 mai arrivato, non eseguito, non cercato.

Marcatura: **[M]** misurato ora · **[R]** riportato, non riverificato da me · **[A]** assunzione.

---

## AGGANCIO

**[M]** A99, forma a token, due supporti: `\bA99\b` → **0** in `HANDOFF/` (repo) e **0** su E:.
Controllo positivo adiacente `\bA96\b` → **1** file su entrambi (l'ultimo ID prima di questo). Non
collide.

---

## B1 · DOVE SIAMO

**[M]** HEAD locale = HEAD remoto = **`44fea3e378414c300ffd50fcac527c683740735b`**.
Albero pulito sui tracciati: **sì** (`git status --porcelain=v1 | grep -vc '^??'` → 0).

**[M] Workflow, per nome, non «CI verde»:**

| workflow | run | esito | quando |
|---|---|---|---|
| **`iOS Signed Build`** | `32148440889` | **success** | 2026-08-18T14:27:32Z, sullo sha esatto sopra |
| **`F1 — Build Check (zero errors, zero warnings)`** | `30639169986` / `30638276963` | **failure** (entrambe) | 2026-07-31 — **nessuna run dopo** |
| `Build LinkHut Diagnostic` (terzo, minore) | `26290451025` | success | 2026-05-22 — irrilevante, non tocca l'app |

⇒ **Esiste un secondo workflow** (F1) e **non ha girato dopo il 31/07**: la sua ultima run in
assoluto è quella fallita del 31/07. «CI verde» riferito a `iOS Signed Build` non dice nulla su F1.

---

## B2 · IMPRONTE A HEAD

**[M]** Estratti con `git show 44fea3e:<path>`, mai da disco:

| file | sha256 blob | byte | righe | CR (0x0D, sui byte) |
|---|---|---:|---:|---:|
| `LIBRO_MASTRO_QBEATS.md` | `59c1fd73b431c04f6b289178999d6feb92231b171e5ce276af0ca199b4072722` | 275 470 | 518 | **0** |
| `BUGS_QBEATS.md` | `64f7df0927448915f2913e0281aeb0be3b96a0018bfd2dde7ba2a1123eb2ac06` | 299 772 | 1 067 | **0** |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | `09bf3442a372a17e66dda7d53ca512e0d1bc551e80f42d2c7a08614811d84fe5` | 56 791 | 350 | **0** |

**[M] Riga `**Versione:**`, verbatim, con numero di riga:**
- LIBRO — riga **5**: `**Versione:** 56 (18/08/2026)`
- BUGS — riga **3**: `**Versione:** 52`
- SCALETTA — riga **3**: `**Versione:** 10 (18/08/2026)  ·  **Ratificata dal referee:** 13/07/2026 (v1) · … · **A3 empty-state cancellata + ⟦S5a⟧ chiuso device + destinazione ⟦S6⟧ ribadita, 18/08** (v10)` (riga intera molto lunga, accumulante — troncata qui per leggibilità, integra nel file)

---

## B3 · SCHEDA ⟦S5b⟧, VERBATIM

**[M] Non esiste.** Sezione B («Scaletta 12 atomi») ha esattamente 12 intestazioni `###`, contate:
`⟦S0⟧` (:42) · `⟦S1⟧` (:48) · `⟦S2F⟧` (:54) · `⟦S2⟧` (:60) · `⟦S3⟧` (:66) · `⟦NODO A⟧` (:125) ·
`⟦S4⟧` (:132) · `⟦S4K⟧` (:165) · `⟦S4R⟧` (:194) · `⟦S4L⟧` (:247) · `⟦S5⟧` (:298) · `⟦S6⟧` (:313).
**Nessuna è `⟦S5b⟧`.** Controllo positivo forma identica: `⟦S5a⟧` rende **3** occorrenze nello stesso
file (righe 324, 324, 326 — tutte dentro la stessa marcatura e la sua successora).

**[M] Cosa c'è al suo posto.** `⟦S5b⟧` esiste **solo come menzione dentro la marcatura del 07/08** a
riga **324** (dentro la scheda `⟦S5⟧`, che storicamente copriva anche lo Start): «**(3) ⟦S5b⟧ —
cablaggio dello Start. È IL FRONTE.** UN solo bottone: lo Start diviso vive solo sulla card della
lista, il `.startfoot` del dettaglio resta invariato (freeze consolidato del 06/08).» — **una frase
sola**, non una scheda (niente `Scopo`/`File`/`Reversibilità`/`Cond`/`Gate` come le altre 12).

La scheda `⟦S5⟧` a riga 298 resta la sua «casa» nominale, ma la marcatura di riga 324 stessa dichiara
che **si è spezzata in tre** (S5a/S5x/S5b) e che «la riga d'ordine sopra non lo sa» — cioè nemmeno
sez.C, la sede unica dell'ordine, nomina i tre pezzi separatamente.

---

## B4 · SUPERFICIE DI SCRITTURA DEL PERCORSO DI ESECUZIONE

**[M] Tracciato l'intero meccanismo, ogni tappa, con controllo positivo per ogni zero.**

**Meccanismo di scrittura del catalogo (`QBeatsStore`)** — 10 CRUD, tutte confermate a fonte:
`addSong`/`updateSong`/`deleteSong`/`moveSongs` (`Store/QBeatsStore.swift:81,86,91,96` circa) ·
`addSetlist`/`updateSetlist`/`deleteSetlist`/`moveSetlists` (stesso file, blocco successivo) — **ogni
singola CRUD chiama `try? await save()` nella riga immediatamente successiva alla mutazione**,
verificato leggendo il file per intero.

**Ricerca, forma esatta, in ogni file del percorso di gioco** (`.save()`, `UserDefaults`,
`QBeatsStore`, i nomi dei dieci CRUD):

| file | occorrenze |
|---|---:|
| `ios_app/QBeats/UI/Live/LiveView.swift` | **0** |
| `ios_app/QBeats/UI/Live/TransportView.swift` | **0** |
| `ios_app/QBeats/UI/Live/FineSetlistView.swift` | **0** |
| `ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift` | **0** (una sola riga, `:81`, `@ObservedObject private var store = QBeatsStore.shared` — **lettura**, non scrittura) |
| `ios_app/QBeats/SetlistRunner.swift` | **0** |

Controllo positivo forma identica: `QBeatsStore.shared.` rende **8** occorrenze in tutto il progetto,
**tutte e otto in `DebugView.swift`** (le chiamate a `injectTestData`) più una in `QBeatsApp.swift:19`
(`QBeatsStore.shared.load()`, lettura all'avvio). La forma di ricerca funziona: gli zeri sopra non
sono falsi-zero.

**Unica scrittura persistente raggiungibile da dentro la Vista LIVE**: `MixerOverlayView.swift:62`
→ `audioEngine.setChannelVolume(...)` → `AudioEngine.swift:1468`
`self.appSettings.updateChannelVolumes(...)` → il `didSet` su `appSettings`
(`AudioEngine.swift:111`) chiama `appSettings.save()` → `UserDefaults.standard.set(data, forKey:
Self.udKey)` (`AppSettings.swift:37`). **Gesto dell'utente** (tocco su uno slider), non automatico
dal semplice avanzare di sezione/brano.

**Ciclo di vita — nessuna scrittura periodica o a cambio-scena.** `QBeatsApp.swift`: `load()` chiamato
**una sola volta**, in `.task` al lancio (`:19`); `.onChange(of: scenePhase)` (`:47-84`) tocca **solo**
`AudioEngine.shared.setLinkEnabled(...)`, mai il catalogo. **Zero `deinit`** in tutto il progetto
tranne uno, `AudioEngine.swift:614` (teardown del motore, non persistenza — verificato: unico
`deinit` in tutto `ios_app/`).

⇒ **Il meccanismo di gioco in sé (Start → runner → avanzamento sezione/brano → END SHOW → uscita) non
scrive MAI il catalogo.** Nessuna delle 10 CRUD è raggiungibile da quel percorso.

**Il rischio è composizionale, non meccanico, e non è nuovo.** Per collaudare ⟦S5b⟧ serve una setlist
di test, e l'unico modo di crearne una è `injectTestData` dalla porta DEBUG (§8 non esiste — stesso
reperto di A94/A96). `injectTestData` sostituisce l'intero catalogo **in memoria**; se **durante la
stessa sessione**, prima o dopo il collaudo, scatta **una qualsiasi** delle 10 CRUD (anche
un'operazione in Q-Stage non legata al test), `save()` fotografa la memoria — tainted — e la scrive
sui tre file reali. Non è un rischio che ⟦S5b⟧ introduce: è il rischio già censito in
`TD-injecttestdata-sovrascrive-dati-reali` (`BUGS_QBEATS.md`), che il collaudo eredita per forza,
dato che non esiste altra via per procurarsi una setlist.

### Verdetto secco

**Collaudo ⟦S5b⟧ dalla porta DEBUG = SICURO nel meccanismo del play in sé (zero scritture nel
percorso Start→…→uscita, verificato riga per riga), ma NON SICURO come procedura completa** —
perché richiede `injectTestData` per esistere, e quel passo, da solo, arma il rischio già noto: una
qualunque CRUD nella stessa sessione dopo l'iniezione sovrascrive il catalogo reale. Il rischio non
nasce da ⟦S5b⟧: **⟦S5b⟧ non può essere collaudato senza attraversarlo.**

---

## B5 · STATO DI RATIFICA DELL'OPZIONE Ⓐ, A HEAD

### 1. Ratificato, cancellato, o altro?

**[M] Né l'uno né l'altro secco: la riga stessa si spezza in due metà con stato diverso.**
`LIBRO_MASTRO_QBEATS.md:353` (07/08), verbatim: **il comportamento** — «RESTART SETLIST SI TOGLIE DA
END SHOW — OPZIONE Ⓐ DI CD (07/08) … **ratifica tecnica del referee** e **OK di Mauro** … due
cancelli distinti, passati entrambi» — **RATIFICATO**. Ma la stessa riga, due frasi dopo: **il
disegno visivo** — «⛔ **Il DISEGNO del piede ribilanciato NON è ratificato qui:** non è ancora
passato per un canale byte-fedele — il deliverable CD del 07/08 è agli atti per impronta nel referto
A80, non ancora letto né ratificato.» — **esplicitamente NON ratificato**.

**[M] Mai risolto dopo.** Cercato «piede» e «byte-fedele» in tutto `LIBRO_MASTRO_QBEATS.md` a HEAD:
le uniche due occorrenze sono la riga 353 stessa e la sua eco nel registro a riga 513 (changelog
`\| 55 \|`, che ripete verbatim «Il disegno del piede ribilanciato resta NON ratificato»). **Nessuna
riga successiva lo ratifica.**

⇒ **Ⓐ è ratificato nel comportamento (togliere RESTART), non nel disegno (il piede a un bottone
solo).** Chi legge «disegno Ⓐ ratificato» senza questa distinzione legge un'affermazione più forte
di quella agli atti.

### 2. Severità di `TD-mixer-copre-endshow` a HEAD

**[M] Titolo verbatim** (`BUGS_QBEATS.md:148`): «`### TD-mixer-copre-endshow` — il mixer sopravvive
a END SHOW, e col disegno Ⓐ copre l'unica uscita (🔴 OPEN ALTA / 🚨 BLOCCANTE PALCO — **PROPOSTA, non
assegnata: decide Mauro**)».

**[M] Ogni riga che lo tocca dopo il 07/08: una sola, la sua nascita.** Cercato `TD-mixer-copre-endshow`
in tutto il file: **2** occorrenze totali — il titolo (:148) e la voce di registro che lo crea,
`\| 51 \|` del 07/08 (:1062). **Zero modifiche dopo la nascita**: la severità è rimasta «PROPOSTA, non
assegnata» dal 07/08 a oggi, mai toccata.

⚠️ **Imprecisione trovata, non corretta qui (fuori perimetro):** sia il titolo sia la voce di
registro dicono «col disegno Ⓐ ratificato il 07/08» — ma per il punto B5.1 sopra, **solo il
comportamento** è ratificato, non il disegno del piede che il ticket cita come causa della
copertura. Non è una contraddizione grave (il mixer coprirebbe l'uscita comunque, con qualunque
disegno del piede), ma la formula «disegno Ⓐ ratificato» usata qui è più larga di quanto LIBRO:353
autorizzi.

### 3. Il disegno del piede Ⓐ è implementato nel codice a HEAD?

**[M] No. È ancora il piede vecchio, a due bottoni.** `ios_app/QBeats/UI/Live/FineSetlistView.swift`
a HEAD, righe **28-33**, verbatim:
```
VStack(spacing: 12) {
    Button("BACK TO SHOWS") { onBackToShows() }
        .buttonStyle(OverlayStopButtonStyle(primary: true, scaleFactor: scaleFactor))
    Button("RESTART SETLIST") { /* restart setlist — Fase successiva */ }
        .buttonStyle(OverlayStopButtonStyle(primary: false, scaleFactor: scaleFactor))
}
```
**Due bottoni**, non uno. Il commento di testata dello stesso file (righe 14-16) descrive ancora la
condizione PRE-ratifica: «RESTART SETLIST resta volutamente inerte: comportamento solo "proposto
(CD-3)"… mai ratificato» — testo **scritto prima del 07/08**, mai aggiornato, oggi impreciso: la
proposta CD-3 (rimettere RESTART da capo) è effettivamente «mai ratificata», ma la DECISIONE di
**togliere** il bottone **è** ratificata da undici giorni, e il codice non la riflette. Nessun commit
su questo file dal 06/08 (`4e4c24113b21fed53b55c2a6d38a1903e52ecd1f`), confermato in A92/A94/A95 e
riconfermato ora.

---

## B6 · IL PERCORSO «AUDIO AZZERATO E NON RIPARTE»

### 1. `LiveHost_Fase3_InterruptionHandling.md`

**[M] Trovato — solo su E:, non cercato sul web.** Percorso reale:
`E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FASE 3\LiveHost_Fase3_InterruptionHandling.md` — cartella
`FASE 3\`, **fuori** dalla struttura abituale `FILE X CLAUDE.MD\` usata per il resto del mirror.
Esiste anche una copia `.pdf` accanto.

**[M]** sha256 `c7fcdf61a2bd7a532edca0689323398150d2375c34bd34966dcb8d9071a67d56` · 3 387 byte · 110
righe.

**[M] NON tracciato in git**: `git ls-files | grep -i "InterruptionHandling"` → **0**. **NON su
Drive**: cercato in `/i/Il mio Drive/Qbeats`, zero risultati.

**[M] Citato in NESSUN canonico a HEAD**, forma esatta, con controllo positivo:

| canonico | occorrenze |
|---|---:|
| LIBRO | 0 |
| BUGS | 0 |
| BOX3 | 0 |
| BOX5 | 0 |
| SCALETTA | 0 |
| controllo positivo (`SCALETTA_ATOMI_S6_2026-07-10.md` citato in LIBRO) | **18** |

⇒ È un **artefatto normativo fuori dal controllo di versione**, stessa famiglia già censita per i
freeze CD prima del 06/08 — con l'aggravante che qui non esiste nemmeno UNA riga in un canonico che
lo nomini.

**[M] Cosa dice.** È una nota tecnica prescrittiva, non un referto: cinque regole da seguire per
implementare l'interruzione, con esempi di codice, scritta per essere data «ad AG» (nota di chiusura,
riga 105: «Note per AG (quando arriverà il momento)»). Confronto con l'implementazione reale (già
letta per intero in questo stesso mandato, sezione precedente e B6.2-B6.3):

| regola prescritta | implementata? |
|---|---|
| 1. Flag `wasPlayingBeforeInterruption` prima dell'interruzione | **Sì, in forma diversa**: `isRunning` sotto lock + `isAudioInterrupted`, non un flag identico ma lo stesso concetto |
| 2. Controllare `shouldResume` in `.ended` | **Sì** — `AudioEngine.swift:2723` |
| 3. `setActive(true)` obbligatorio nel resume | **Sì** — più volte, con retry (vedi B6.3) |
| 4. Percorso idempotente, resume ≠ reinit | **Parziale/diverso**: il codice reale chiama `rebuildGraph` a ogni `.ended` (`:2786`), non solo quando l'engine non è inizializzato come la nota prescrive — scelta probabilmente dettata dalla sincronizzazione Link/MIDI, non verificata come intenzionale in un documento a parte |
| 5. Handler su `@MainActor` | **No**: il codice reale usa una coda seriale dedicata (`audioQueue`) con `DispatchQueue.main.async` solo per i campi UI — modello diverso, non necessariamente peggiore |

⚠️ Non è mio compito in questo mandato giudicare se le divergenze siano regressioni o evoluzioni
migliori: le registro come fatto. L'implementazione reale è **più elaborata** di quanto la nota
prescriva (retry a 20 tentativi, safety-net, guardia hardware `isCallActive`/`silenceHint` — nessuno
di questi è nella nota).

### 2. Riancoraggio della catena a HEAD

**[M] Il reperto BOX3 esiste in due punti, non uno.**

- **Riga 53** (l'entry citata dal mandato) — verbatim: «**(l) REPERTO DA RIANCORARE (non ancora fatto
  operativo).** E3 dichiara [V] che uno `stop()` con `isRunning==true` supera la guardia e chiama
  `link_engine_stop` → stop propagato ai Follower … mentre l'interruzione iOS (chiamata) è
  ingegnerizzata per NON notificare Link (`AudioEngine.swift:2676-2677` @ `872dd5b`). Fonti a
  `872dd5b` (commit vecchio) → §7: **da RIANCORARE a HEAD prima di trattarlo come fatto operativo.**
  Reperto, non fatto chiuso.» — **testo invariato**, cita ancora `872dd5b`.

- **Riga 31** (entry più recente, supersede dichiarato) — verbatim, in chiusura: «Interruzione iOS
  (telefonata) INVARIATA: `AudioEngine.swift:2676-2677` non chiama `link_engine_stop` → NON propaga
  (righe identiche a HEAD, riverificate). **Il reperto (l) passa da «da riancorare» a FATTO
  OPERATIVO sorgentato.**» — ancorata a `f8276f6`, un commit più recente di `872dd5b` ma **comunque
  precedente a HEAD**.

⇒ **Il riancoraggio era già stato fatto una volta** (da `872dd5b` a `f8276f6`), con la convenzione
giusta di questo progetto — non riscrivere la riga vecchia, sovrascriverla con una nuova che la
supera. Ma **BOX3 nel suo complesso è fermo al 22/07** (reperto già censito in A92-A95), quindi anche
`f8276f6` è a sua volta un'ancora vecchia rispetto a HEAD.

**[M] Riancorato ora, a `44fea3e`:** `AudioEngine.swift:2676-2677`, verbatim, **stessi numeri di riga
di `872dd5b`**:
```
2676:                // CRITICO: NON chiamare midi_engine_stop() — il sequencer C++ continua a
2677:                // mantenere la beat position corrente. NON notificare stop a Link.
```
**[M] Confermato per ricerca**: `link_engine_stop` in tutto `AudioEngine.swift` a HEAD rende **una
sola occorrenza**, a riga **1645**, **fuori** dal ramo `.began` dell'interruzione (è nel percorso di
stop esplicito dell'utente). Zero chiamate nel blocco `.began` (righe 2661-2698).

⇒ **Il claim regge a HEAD, invariato dal commit vecchio**, con lo stesso indirizzo di riga. Il
reperto (l) di riga 53 è testo storico non aggiornato (per disciplina «si marca, non si riscrive»);
quello di riga 31 era già la marcatura corretta; questo referto lo riconferma una terza volta, a
HEAD attuale.

### 3. `mediaServicesWereResetNotification`

**[M] Gestita. Osservatore**: `AudioEngine.swift:2653-2654`. **Handler**:
`handleMediaReset`, `AudioEngine.swift:2959`.

**[M] Meccanismo intero, tracciato fino in fondo:**

```
handleMediaReset()
  → stopSync()
  → setupSession()        ← può fallire (try/catch interno)
  → setupGraph()           ← NESSUN try/catch, nessuna funzione throwing
  → applySettings(appSettings)
  → (rigenera i campioni del click)
  → se wasRunning: activateSessionAndStart(resumeAtBeat: nil, trigger: "media_reset")
```

**Se `setupSession()` fallisce** (`AudioEngine.swift:1832-1852`): il blocco `catch` (`:1849-1851`)
esegue **un solo effetto**: `DispatchQueue.main.async { self.clickStatus = "session fallita: \(error)" }`.
Nessun rilancio dell'errore, nessuna interruzione del flusso — `handleMediaReset` **prosegue
comunque** a `setupGraph()`, che non ha alcuna guardia e costruisce il grafo audio **a prescindere**
da come sia andata l'attivazione della sessione.

**Se il resume finale fallisce** (`activateSessionAndStart`, `AudioEngine.swift:1715-1810` circa):
**c'è un retry reale**, non uno solo: fino a **20 tentativi**, 500ms l'uno dall'altro (10s totali);
esauriti, imposta `pendingResume = true` e arma un **safety-net a 5s** che rilancia un altro ciclo di
tentativi (`attempt: 1`, quindi altri fino a 20). `pendingResume` viene poi ripreso anche dai
percorsi `.ended` e `handleRouteChange` (già letti in B1/A96): il sistema continua a **ritentare
indefinitamente** attraverso più canali, non si arrende in modo definitivo.

**Segnale all'utente: NESSUNO, nella UI reale.** Cercato `pendingResume`, `isAudioInterrupted`,
`clickStatus` in **ogni** file sotto `ios_app/QBeats/UI/` (l'intera UI del progetto): **zero
occorrenze**. L'unico consumo di `clickStatus` in tutto il progetto resta `ContentView.swift:23`, il
pannello dietro la porta DEBUG — già misurato in A96.

### Risposta secca

**C'è un retry** (aggressivo: 20+20 tentativi su due cicli, più i rientri da `.ended`/route-change),
**non c'è un segnale visibile nella Vista LIVE reale**, e **non c'è una resa definitiva che avvisi
l'utente**: il codice ritenta all'infinito attraverso più percorsi. Nella pratica, se il fallimento
fosse persistente (hardware realmente inutilizzabile), **il suono resterebbe silenzioso senza che il
performer veda alcuna indicazione sullo schermo** — non perché l'app si arrenda, ma perché nessuno
dei suoi tentativi produce un segno visibile fuori dal pannello DEBUG.

---

## RIEPILOGO

| blocco | esito |
|---|---|
| B1 | HEAD locale=remoto `44fea3e3…`, albero pulito. `iOS Signed Build` success. **F1 non gira dal 31/07**, fallito quell'ultima volta |
| B2 | Tre impronte a HEAD, estratte da blob, CR=0 su tutte. Versione: LIBRO `:5`, BUGS `:3`, SCALETTA `:3` |
| B3 | **`⟦S5b⟧` non ha scheda.** Esiste solo come frase dentro la marcatura di `⟦S5⟧` a `SCALETTA:324` |
| B4 | Il meccanismo di gioco **non scrive mai il catalogo** (10 CRUD, zero raggiungibili dal percorso Start→uscita) — ma il collaudo **eredita** il rischio noto di `injectTestData`, necessario in assenza di §8. Verdetto: **sicuro nel meccanismo, non sicuro come procedura** |
| B5 | Ⓐ ratificato **nel comportamento**, **non nel disegno del piede** — mai risolto dopo il 07/08. `TD-mixer-copre-endshow` invariato dalla nascita, formula «disegno Ⓐ ratificato» più larga del vero. Codice: **piede vecchio a due bottoni**, invariato |
| B6 | `LiveHost_Fase3_InterruptionHandling.md` trovato su E: (`FASE 3\`), non tracciato, non su Drive, **citato in zero canonici**. Catena BOX3 **riancorata a HEAD**, claim confermato con gli stessi numeri di riga di `872dd5b`. `mediaServicesWereResetNotification` gestita con retry aggressivo ma **zero segnale nella UI reale** |

⛔ Nessuna azione eseguita oltre la misura e questo referto, come da perimetro.

---

*A99-SEI-BLOCCHI-SOLA-LETTURA-FINE*
