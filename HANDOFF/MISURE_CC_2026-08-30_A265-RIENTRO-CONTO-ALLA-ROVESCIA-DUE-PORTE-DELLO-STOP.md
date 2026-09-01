# MISURE CC — A265 — RIENTRO, CONTO ALLA ROVESCIA, DUE PORTE DELLO STOP — 30/08/2026

**⏱ Orologio:** domenica 30/08/2026, **13:56:42 locale (UTC+2)**, misurato da `date` di sistema.

**HEAD di misura:** `b1b4c1fd0864b1713eec7cda5a4d142fac431339` (branch `master` = `origin/master`, 0 ahead/behind, 0 modificati/staged).

⛔ **Nessuna modifica sotto `ios_app/`. Nessun commit.** Mandato di sola lettura, rispettato.

---

## ID — esito delle sonde (richiesto in prima riga dal mandato)

`A264` **annullato per collisione**, misurata da questa chat e ratificata dal referee (occupato da `CONGEDO_CC_2026-08-30_A264-IN-AUTONOMIA.md` + `SEGNAPOSTO_A264_2026-08-30_CC.md`, entrambe le gambe, nome e contenuto).

`A265` scelto come successore. Verifica, binari esclusi (`grep -rlI`):
- nome file: C: 0 · E: 0
- contenuto: C: 2 · E: 2 + rumore in log TD17 (spot-verificato: match reale `FA265`/`A2654`, frammento UUID WiFi `corewifi`/QoS, stesso pattern del falso positivo sui font già documentato in `CLAUDE.md`) — i due hit reali sono **citazioni** di A265 come esempio di trappola grep-su-binari (`CONGEDO_CC_2026-08-30_A264-IN-AUTONOMIA.md` §e.1, `MISURE_CC_2026-08-30_A266-PERCHE-LE-REGOLE-NON-TENGONO.md` §0), non un uso dell'ID.
- `git log --all --grep="A265"`: 0.
- Positivo `A240` (committato): `git log` → 3 hit (`b1b4c1f`… no, i tre commit reali: `eca1ae6`, `e13b192`, `d0225ef`). Positivo di forma disco `A263`/`A266`: entrambi visti su nome e contenuto, entrambe le gambe.
- Convergenza indipendente: `MISURE_CC_2026-08-30_A266-PERCHE-LE-REGOLE-NON-TENGONO.md` §0 aveva già misurato — **[R]** per questa chat — «A265 rende 4 senza -I e 0 con — erano font .ttf e un .pdb. A265 era libero» alle 11:33 di oggi.

`A265` libero, confermato. **Prenotato** con segnaposto su due gambe (`SEGNAPOSTO_A265_2026-08-30_CC.md`, `cmp` exit 0), ri-misurata la solitudine dopo la scrittura: un solo file per gamba.

---

## BLOCCO 0 — cosa contengono i due file che il referee non vede

**0.1**

`HANDOFF/CONGEDO_CC_2026-08-30_A264-IN-AUTONOMIA.md` — congedo a struttura (a)-(g) scritto sotto il mandato `A264-CONGEDO-CC-IN-AUTONOMIA`. Contenuto: (a) tre azioni — rimisura di `CONGEDO_CC_2026-08-30_A262.md`, esecuzione completa del mandato `A263-CONTO-DEI-TOCCHI-E-PORTE-DELLA-LISTA`, e questo stesso congedo; (b) cinque misure nuove — doppia occorrenza della contraddizione BUGS, rapporto congedi tracciati/totali, i conti di A263, il censimento delle cinque porte di scrittura di `QBeatsStore.setlists`, la scoperta della sessione concorrente; (c) sei lacune dichiarate; (d) due errori auto-corretti (impronta auto-invalidante, catena `&&` interrotta in silenzio); (e) tre trappole (falso positivo binari su A265 — la stessa che ho appena riverificato indipendentemente sopra — contraddizione ④/⑥ di un disegno rev2, etichetta di frame che nomina uno stato e ne disegna un altro); (f) nulla da riportare contro il referee; (g) quattro voci aperte.

Chi l'ha ordinato: il mandato `A264-CONGEDO-CC-IN-AUTONOMIA` (autonomo — non ho il testo verbatim del prompt originale che l'ha aperto, solo il suo prodotto finale; non lo invento).

`HANDOFF/SEGNAPOSTO_A264_2026-08-30_CC.md` — segnaposto di 11 righe: CC ha prenotato l'ID `A264` prima di scrivere il congedo sopra, dopo aver letto la lezione di `MISURE_CC_2026-08-30_A266-PERCHE-LE-REGOLE-NON-TENGONO.md` (altra sessione). Dichiara la sonda a quattro gambe eseguita prima della prenotazione (tutte 0, positivo su A263 vedente) e il motivo (rischio di collisione fra sessioni concorrenti, già accaduto oggi su A263). Non è un mandato a sé: è un atto preparatorio interno all'esecuzione di A264.

**0.2 — LA DOMANDA CHE CONTA: NO.**

Nessuno dei due file tocca in alcuna parte i Blocchi 1/2/3. Il congedo A264 parla di: conteggio tocchi attraverso stati/destinazioni di navigazione della lista setlist (materia di `A263`, non citata qui verbatim perché fuori dal perimetro di 0.1), bookkeeping di processo, collisione ID, tre trappole di misura non correlate al player. Il segnaposto è puro bookkeeping di prenotazione. **Zero citazioni** di `onAppear`, `primeDisplay`, `startCurrentSong`, indice di sezione, conto alla rovescia, `handleStop`, `audioEngine.stop()`, o azioni MIDI. Procedo senza aver rifatto lavoro già fatto stamattina — non ce n'era da riusare.

---

## BLOCCO 1 — IL RIENTRO

### 1.1 — `LiveView.onAppear` (verbatim, `UI/Live/LiveView.swift:303-429`)

```swift
.onAppear {
    // Sincronizzazione iniziale mirror UI con stato corrente AudioEngine.
    // Necessario quando l'utente entra in Vista LIVE dopo aver modificato
    // BPB/AccentPattern in altre schermate (es. ContentView Q-Beats Studio).
    // Senza questo, i mirror restano sui valori @State init (4, [2,1,1,1])
    // fino al primo beat tick.
    displayBpb = audioEngine.beatsPerBar
    displayAccentPattern = audioEngine.currentAccentPattern
    // [... commenti storici A/S5b/A242 invariati, vedi file a fonte ...]
    session.showMixer = false
    session.currentBar = 0
    session.beatActive = 0
    runner.primeDisplay(session: session)
    if let section = runner.currentSection {
        displayBpb = section.beatsPerBar
        displayAccentPattern = section.accentPattern
        session.currentTimeSig = timeSigString(for: section.beatsPerBar)
    }
    audioEngine.snapshotSectionPosition { sectionBeat, sectionTotal, tick in
        guard !barAnchorValid, sectionTotal > 0, audioEngine.isPlaying else { return }
        sectionStartTick = tick - sectionBeat + 1
        barAnchorValid = true
        guard sectionBeat > 0 else { return }
        let bpb = max(1, Int(displayBpb))
        session.beatActive = ((sectionBeat - 1) % bpb) + 1
        session.currentBar = ((sectionBeat - 1) / bpb) + 1
    }
}
```

⚠️ Ho abbreviato SOLO i blocchi di commento storico (righe 311-327, 331-337, 339-349, 366-417) marcati esplicitamente `[...]` sopra — nessuna riga di CODICE è stata tagliata; il codice eseguibile è integrale. I commenti tagliati sono citabili a fonte (`LiveView.swift`, stesse righe) se servono.

**Il ramo che converte «fermo» in «pronto a partire»** (chiesto da 1.1): non è dentro `onAppear` — `onAppear` chiama `runner.primeDisplay(session:)` (riga 350), ed è **dentro `primeDisplay`** che vive la conversione. Vedi 1.2/primeDisplay sotto — `SetlistRunner.swift:361-363`.

### 1.2 — `SetlistRunner.startCurrentSong` (verbatim, `SetlistRunner.swift:139-146`)

```swift
func startCurrentSong(audioEngine: AudioEngine, session: LiveSession) {
    // Reset esplicito coerente con startSetlist (TD #41 lifecycle).
    pendingDisplayUpdate = false
    currentSectionIdx = 0
    os_log("[Q-BEATS][L1.b] startCurrentSong — songIdx:%d sectionIdx:0",
           log: .default, type: .default, currentSongIdx)
    prepareAndStartCurrentSection(audioEngine: audioEngine, session: session)
}
```

Conserva `currentSongIdx` (non lo tocca), **azzera** `currentSectionIdx` (riga 142). Non salva nulla: legge lo stato che il runner già ha.

Per completezza del meccanismo (non chiesto in 1.2 ma necessario a rispondere 1.3): `primeDisplay` (`SetlistRunner.swift:333-364`), il ramo che converte `.stopped` in `.standby`:

```swift
func primeDisplay(session: LiveSession) {
    guard let section = currentSection else { return }
    updateSessionDisplay(session: session)
    session.currentBPM         = section.bpm
    session.totalBarsInSection = Int(section.repetitions)
    if case .stopped = session.playbackState, let song = currentSong {
        session.playbackState = .standby(nextSongName: song.name)
    }
}
```

### 1.3 — LA DOMANDA CENTRALE: l'indice di sezione viene salvato? Sopravvive all'uscita?

**Sì, ma non come "salvataggio all'evento STOP": è un campo persistente che STOP non tocca.**

`@Published private(set) var currentSectionIdx: Int = 0` — `SetlistRunner.swift:31`. Chi scrive: `startSetlist` lo azzera (`:120`), `startCurrentSong` lo azzera (`:142`), `startCurrentSection` lo **conserva** (nessuna scrittura, `:166-185`), il ramo "avanza" della closure end-of-section lo incrementa (`self.currentSectionIdx += 1`, `:390`), il ramo "standby" lo azzera (`:432`).

⚠️ **MARCATURA A267 (30/08, stesso giorno)** — «nessuna scrittura» qui sopra è **FALSO**: alle `:179-180`, dentro la guardia fallback A240 (`if currentSection == nil`), `startCurrentSection` azzera ENTRAMBI gli indici. Nel percorso normale la guardia non scatta (catalogo = copia immutabile risolta all'init, indici provenienti da uno stato valido), ma la scrittura ESISTE e il censimento sopra la ometteva. Smentita del referee nel mandato A267, confermata a fonte da CC. La riga sopra resta come scritta. **Nessuno di questi scrittori è raggiunto da STOP** — n é da `AudioEngine.stop()` né da `handleStop()`: entrambi vivono in `AudioEngine`, che non ha alcun riferimento a `SetlistRunner` (la dipendenza va nell'altro verso: è `SetlistRunner` a ricevere `audioEngine` come parametro). STOP non salva l'indice perché non lo tocca affatto — resta dov'era.

**L'oggetto sopravvive all'uscita dal player.** Dal commento di testa del file (`SetlistRunner.swift:5-9`, verbatim):

```
/// Lo SLOT che lo ospita vive in `QLiveSession`, posseduta da `QLiveRootView`
/// come `@StateObject` (⟦S4R⟧): il runner nasce allo Start (⟦S5⟧) con la
/// setlist scelta e vive quanto la stanza Q-Live — vita = durata performance.
```

Confermato dai punti di accesso: `LiveView.swift:6` e `TransportView.swift:6` dichiarano `@EnvironmentObject var runner: SetlistRunner` — **osservano**, non possiedono. Il possesso è `QLiveSession.swift:44`: `@Published private(set) var runner: SetlistRunner? = nil`, popolato da `QLiveRootView.swift:245` (`roomSession.install(SetlistRunner(setlist: show, …))`). `LiveView` (il player) può scomparire e ricomparire dalla gerarchia SwiftUI senza che `QLiveSession` venga deallocata: l'indice non muore con la schermata.

**Dove muore davvero**: `QLiveSession.endShow(audioEngine:)`, `QLiveSession.swift:209-213`, verbatim:

```swift
func endShow(audioEngine: AudioEngine) {
    audioEngine.stop()
    runner = nil
    liveSession.playbackState = .stopped
}
```

Solo qui `runner` (e con esso `currentSectionIdx`) viene distrutto — è un'azione esplicita di fine-show, non una conseguenza di navigazione o di STOP.

### 1.4 — Cosa muore e cosa sopravvive all'uscita dal player

| oggetto | vive in | sopravvive all'uscita dal player? | muore quando |
|---|---|---|---|
| `SetlistRunner.currentSongIdx` / `currentSectionIdx` | `SetlistRunner` (`:30-31`), posseduto da `QLiveSession` | ✅ sì | `endShow()`, `QLiveSession.swift:211` (`runner = nil`) |
| `AudioEngine._sectionBeatCounter` (posizione BEAT dentro la sezione — diverso da sopra: è "a che beat", non "quale sezione") | `AudioEngine` (privato, letto via `snapshotSectionPosition`, `:1206-1214`) | ⛔ no — azzerato ad OGNI stop | `stopSync()`, `AudioEngine.swift:1712` (`self._sectionBeatCounter = 0`), commento a riga 1707-1711: resta registrato solo il TOTALE (`_sectionTotalBeats`), il contatore si azzera sempre |
| `QLiveSession.liveSession` / mixer, bar corrente, beatActive (display) | `LiveSession`, posseduta dalla sessione | display: azzerati a ogni `onAppear` (`:338, :348-349`, per costruzione, non perché "muoiono" — sono resettati e ricalcolati) | — |
| `AudioEngine.playbackState` (proprietà separata da `session.playbackState`, vedi Blocco 3) | `AudioEngine` | non applicabile al player: vive quanto l'engine (singleton per la sessione app) | — |

⚠️ **Sono DUE nozioni distinte di "sezione", stesso nome comune ma oggetti diversi**: QUALE sezione (`SetlistRunner.currentSectionIdx`, sopravvive) e A CHE BEAT dentro la sezione (`AudioEngine._sectionBeatCounter`, azzerato a ogni stop). Confondere le due porterebbe a concludere erroneamente che "la sezione si perde" — la sezione (indice) NON si perde; la posizione-beat dentro di essa sì, sempre, per STOP.

---

## BLOCCO 2 — IL CONTO ALLA ROVESCIA

### 2.1 — Sweep dichiarato

Termini cercati: `countIn` / `count-in` / `countdown` (case-insensitive dove indicato), su tutto `ios_app/`. File con almeno un match su `[Cc]ountIn|count-in|countdown`: **15** (elenco: `LiveView.swift`, `AudioEngine.swift`, `BarCounterView.swift`, `LivePlaybackState.swift`, `TransportView.swift`, `SetlistRunner.swift`, `DebugView.swift`, `QBeatsBackupManager.swift`, `Song.swift`, `SongEditorView.swift`, `TeleprompterCapsuleView.swift`, `PreviewData.swift`, 3 file di test). Controllo positivo: la stessa sonda su un termine sorella noto letto a runtime (`beatsPerBar`) rende decine di hit reali nello stesso file (`LiveView.swift`) — la sonda non è cieca, il basso numero su `countdown` (2 hit soli, sotto) è un dato reale, non un difetto di ricerca.

Punti reali (non-test, non-Codable-passthrough) dove il conto alla rovescia è innescato, calcolato o mostrato:

- **Innesco stato**: `AudioEngine.resumeFromCurrentSection()`, `AudioEngine.swift:1303-1310` — imposta `playbackState = .countIn` (riga 1307) poi chiama `startCountIn(for: currentSection)` (riga 1309).
- **"Calcolo"**: `AudioEngine.startCountIn(for:)`, `AudioEngine.swift:1616-1619`, verbatim:
  ```swift
  // L3 stub — sostituito da Layer 3 quando disponibile.
  private func startCountIn(for section: String?) {
      start()
  }
  ```
  È uno **stub L3 vuoto**: non calcola nulla, non introduce alcun ritardo — chiama `start()` immediatamente. Il parametro `section` non viene letto.
- **Traduzione in stato UI + comparsa del numero**: `LiveView.swift`, dentro `.onReceive(audioEngine.$playbackState)`, ramo `case .countIn:` — `LiveView.swift:482-483`, verbatim:
  ```swift
  case .countIn:
      session.playbackState = .countIn(countdown: 4)
  ```
- **Definizione del caso**: `Models/LivePlaybackState.swift:5` — `case countIn(countdown: Int)`.
- **Display**: `TeleprompterCapsuleView.swift:17` (`case .countIn(let n):`, legge il numero per mostrarlo) e `BarCounterView.swift:15` (`case .countIn, .standby:`, ramo di modalità, non legge il numero).

⛔ **Nessun timer, nessuna sottrazione, nessun `Timer.scheduled`, nessuna occorrenza di `countdown -` in tutto `ios_app/`** (sonda dedicata: `countdown` case-insensitive rende **esattamente 2** hit in tutto l'albero — la definizione del caso e questa unica riga che lo costruisce). **Non esiste un meccanismo che faccia scendere 4→3→2→1**: il valore è scritto una volta e mai più letto per essere decrementato.

### 2.2 — Da dove esce il «4»?

**Costante letterale, `LiveView.swift:483`**, dentro il ramo `.countIn` dell'`onReceive(audioEngine.$playbackState)`. Non deriva da `Song.countIn` (vedi 2.3), non da un calcolo su BPM/battute, non da alcun parametro della sezione. **Non viene corretta più avanti nella catena**: è il valore terminale — nessun altro punto del codice scrive un valore diverso in `.countIn(countdown:)`, e nessun consumatore lo modifica, solo lo legge per il display (`TeleprompterCapsuleView.swift:17`).

### 2.3 — L'impostazione utente nell'editor: dove finisce, chi la legge

**Scrittura**: `SongEditorView.swift:34` — `Picker(selection: $draft.countIn) { … }`. Il campo è `Song.countIn: Int` (`Models/Song.swift:21`), commento a fonte: `// 0=nessuno, 1=1 battuta, 2=2 battute`. Persistito via Codable (`Song.swift:40` init, `:60` decode).

**Lettura — sweep dedicato**: `grep -rn '\.countIn\b'` su tutto `ios_app/` rende **13 righe**. Elenco completo per categoria:
- 3× nei test (`SongRetroCompatDecodingTests.swift:50,83`, `SongCodableRoundTripTests.swift:55`) — round-trip Codable, non lettura a runtime.
- 3× in `Song.swift` (`:40,60` — definizione/decode) — non lettura, è lo stesso campo che si definisce.
- 1× `QBeatsBackupManager.swift:217` — `countIn: song.countIn` dentro la costruzione di un record di backup/export: **copia il valore, non lo consuma per il comportamento**.
- 1× `SongEditorView.swift:34` — la scrittura (Picker).
- 5× riferimenti a `.countIn` come **CASO DI UN ENUM DIVERSO** (`LivePlaybackState.countIn`, materia del §2.1 sopra: `AudioEngine.swift:1095,1290,1307`, `SetlistRunner.swift:354` commento, `TransportView.swift:13`) — stesso testo, oggetto **diverso** (stato di riproduzione, non il campo `Song.countIn`).

**CONTROLLO POSITIVO — la sonda non è cieca**: lo stesso pattern di ricerca su un campo sorella dello stesso `Song`/`SongSection` che **è** letto a runtime, `beatsPerBar`, rende consumo reale in `LiveView.swift:356` (`displayBpb = section.beatsPerBar`, dentro `onAppear`) e altrove nel motore. La sonda su `countIn` trova zero consumatori runtime con la stessa metodologia che su `beatsPerBar` ne trova.

⇒ **`Song.countIn` — l'impostazione che l'utente sceglie nell'editor — non viene letta da NESSUN punto del percorso di riproduzione.** Non alimenta `startCountIn` (che non legge il suo parametro `section` nemmeno per il nome, figuriamoci un `Int` che non gli viene nemmeno passato), non alimenta il `4` di `LiveView.swift:483`. È scritta, persistita, copiata in backup — e ignorata a runtime.

### 2.4 — Al rientro, la metrica della sezione (beats-per-bar)

`displayBpb = section.beatsPerBar` — **`LiveView.swift:356`**, dentro `onAppear`, dentro `if let section = runner.currentSection { … }` (righe 355-365). **Raggiungibile: SÌ.** `runner.currentSection` è il computed property di `SetlistRunner` (`:77-82`) che risolve da `currentSongIdx`/`currentSectionIdx` — gli stessi indici che, per 1.3-1.4, sopravvivono all'uscita dal player. Al rientro (nuovo `onAppear`), se il runner esiste ancora (show non terminato), `currentSection` risolve alla sezione vera e `displayBpb` si aggiorna correttamente da essa — non dal motore (il commento a riga 351-354 lo dichiara esplicitamente: la sezione della posizione è "verità" di display, sovrascrive il mirror da `audioEngine`).

---

## BLOCCO 3 — LE DUE PORTE DELLO STOP

### 3.1 — `AudioEngine.handleStop()` (verbatim, integrale, `AudioEngine.swift:1279-1301`)

```swift
func handleStop() {
    switch playbackState {
    case .playing:
        stopSync()
        let sectionName = currentSection ?? ""
        let songName = currentSong ?? ""
        os_log("[Q-BEATS][UX-3] handleStop: playing → pausedAwaitingChoice section:%{public}@ song:%{public}@",
               log: .default, type: .default, sectionName, songName)
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .pausedAwaitingChoice(sectionName: sectionName, songName: songName)
        }
    case .countIn:
        stopSync()
        resetToSongStart()
        os_log("[Q-BEATS][UX-3] handleStop: countIn → stopped",
               log: .default, type: .default)
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .stopped
        }
    default:
        break
    }
}
```

⚠️ `currentSection`/`currentSong` qui sono **campi propri di `AudioEngine`** (`String?`, dichiarati `AudioEngine.swift:196` e adiacenze) — **omonimi** dei computed property di `SetlistRunner` con lo stesso nome ma tipo `SongSection?`/`Song?` (Blocco 1). Sono due cose diverse: l'`AudioEngine` non vede il runner.

### 3.2 — Chiamanti di `handleStop()` — sweep dichiarato

`grep -rn 'handleStop()'` su tutto `ios_app/`: **3 righe**, di cui una è la definizione (`AudioEngine.swift:1279`) e una un commento (`:1095`, cita `handleStop()` a scopo di riferimento, non lo chiama). **Chiamanti reali: 2, esatti**:
1. `AudioEngine.swift:1667`, dentro `executeMIDIAction(_:)`, ramo `case .stop:` (vedi 3.4).
2. `DebugView.swift:187` — `audioEngine.handleStop()`, un pulsante di debug.

**Nessun chiamante nel percorso UI principale** (`TransportView`, `LiveView`, `OverlayStopView`): quella strada usa `audioEngine.stop()` direttamente.

### 3.3 — `audioEngine.stop()` (verbatim, integrale, `AudioEngine.swift:1088-1103`)

```swift
func stop() {
    stopSync()
#if QB_DIAG_SPY
    // SPIA passiva: flush finale del ring L1 (audio già fermo da stopSync → no race).
    if let h = metronomeHandle { metronome_flush_diag(h) }
#endif
    // P1+P3 fix: allinea playbackState all'isPlaying su ogni percorso di stop.
    // Pattern già usato in handleStop() (.countIn/.playing) e restartFromBeginning().
    // Senza questo dispatch, lo stop manuale lasciava playbackState=.playing
    // mentre isPlaying=false → desincronizzazione UI (segmento bloccato bianco,
    // TransportView label/glyph fuori sync — TransportView re-render solo su
    // session.playbackState, non su audioEngine.isPlaying).
    DispatchQueue.main.async { [weak self] in
        self?.playbackState = .stopped
    }
}
```

**Il chiamante del pulsante del transport** — `TransportView.swift:52-53`, dentro il tap-handler del bottone play/stop:

```swift
if audioEngine.isPlaying {
    audioEngine.stop()
} else if audioEngine.currentLinkMode == .collaborativa {
    // ...
```

Nessuno `switch` sullo stato precedente: `stop()` porta SEMPRE a `.stopped`, incondizionatamente, qualunque fosse `playbackState` prima.

### 3.4 — Esecutore azioni MIDI, ramo `case .stop` (verbatim, integrale, `AudioEngine.swift:1662-1678`)

```swift
private func executeMIDIAction(_ action: MIDIAction) {
    switch action {
    case .playPause:
        if isPlaying { stop() } else { start() }
    case .stop:
        handleStop()
    case .muteClickToggle:
        appSettings.clickMuted.toggle()
    case .stopBacktrack:
        stopBacktrack()
    case .tapTempo:
        tapTempo()
    case .nextSection, .prevSection, .nextSong, .startSong, .loopToggle:
        os_log("[Q-BEATS][MIDI ACTION] %{public}@ — richiede Layer 3",
               log: .default, type: .default, action.rawValue)
    }
}
```

Nota: `.playPause` (azione MIDI diversa da `.stop`) chiama `stop()`, NON `handleStop()`. Solo l'azione MIDI `.stop` passa da `handleStop()`.

### 3.5 — LA DOMANDA: cosa fa `handleStop()` che la strada del pulsante NON fa (oltre a montare il pannello)?

**Non solo monta un pannello: cambia lo STATO DI DESTINAZIONE stesso, e questo attiva una UI a due scelte che `stop()` non raggiunge mai.**

Meccanismo intero, tracciato:

1. Da `.playing`: `handleStop()` → `.pausedAwaitingChoice(sectionName:songName:)` (cattura nomi). `stop()` → sempre `.stopped`, direttamente, nessuna cattura di nomi. **Sono due stati finali diversi**, non lo stesso stato raggiunto con un passo in più.
2. `.pausedAwaitingChoice` (stato di `AudioEngine`) viene tradotto da `LiveView.swift:490-491` in `session.playbackState = .overlayStop(sectionName:songName:)` (stato di `LiveSession` — un ALTRO enum, altro nome ancora), che monta **`OverlayStopView`** (`LiveView.swift:197` + file `OverlayStopView.swift`): due bottoni, **"Riprendi da {sezione}"** → `audioEngine.resumeFromCurrentSection()` e **"Dall'inizio · {canzone}"** → `audioEngine.restartCurrentSong()`. Se il pedale/MIDI STOP atterrasse su `stop()`, questa schermata **non comparirebbe mai**: si andrebbe dritti a `.stopped`, saltando la scelta resume/restart.
3. Dal `.countIn`: `handleStop()` chiama anche `resetToSongStart()` (`AudioEngine.swift:1621-1622`) — **anche questo uno stub L3 vuoto**, verbatim: `private func resetToSongStart() {}`. `stop()` non la chiama mai, in nessun ramo.
4. `default: break` — per QUALSIASI altro stato (`.stopped`, `.standby`, `.loopActive`, `.fineSetlist`, `.waitingForDirector`, e persino `.pausedAwaitingChoice` stesso), `handleStop()` **non fa nulla**. `stop()` invece agisce SEMPRE, incondizionatamente, forzando `.stopped` anche da stati come `.standby` — dove oggi non viene mai chiamato da quella strada, ma lo sarebbe se i due percorsi fossero unificati sulla strada di `stop()`.

⚠️ **Nota sul ramo count-in, come richiesto — è dove una risposta affrettata farebbe danno**: seguendo la catena fino in fondo (Blocco 2), il "count-in" che `handleStop()` interrompe (`resetToSongStart()`) e quello che lo start-side innesca (`startCountIn`) sono **entrambi stub L3 vuoti**. Non è solo che `handleStop()` fa "qualcosa in più" nel ramo count-in: quel "qualcosa in più" oggi **non fa nulla** — quindi, per il ramo count-in specificamente, far atterrare il pedale su `stop()` invece che su `handleStop()` non perderebbe funzionalità reale (`resetToSongStart` è vuoto), ma **cambierebbe comunque lo stato finale pubblicato** (`stop()` non gestisce `.countIn` come caso a parte: lo tratterebbe come "qualunque altro stato", risultato comunque `.stopped` per via del path generico — stesso stato di arrivo, percorso diverso, nessun log `[UX-3]` emesso).

**🔴 Trovato per side-effect, non chiesto esplicitamente ma appartiene allo stesso meccanismo (3.5) — il bottone "Dall'inizio" di `OverlayStopView` è anch'esso rotto oggi, indipendentemente da quale STOP lo raggiunge:** `restartCurrentSong()` (`AudioEngine.swift:1322`) → `restartFromBeginning()` (`:1312-1319`) → `resetToSongStart()` (stub vuoto, `:1622`) + `playbackState = .stopped`. **Nessuna chiamata tocca `SetlistRunner.currentSongIdx`/`currentSectionIdx`** (`AudioEngine` non ha riferimento al runner — Blocco 1.3). Premere "Dall'inizio · {canzone}" oggi non riporta l'indice della canzone/sezione all'inizio: lascia il runner esattamente dov'era. Un successivo Play (che per A240 CONSERVA canzone e sezione, `SetlistRunner.swift:166-185`) riprenderebbe dallo stesso punto di prima — non "dall'inizio" come il testo del bottone promette. Verificabile a schermo (comportamento, non solo codice) — non l'ho fatto: mandato di sola lettura, zero device/build.

---

## Percorsi e impronte

*(l'impronta di questo file vive nel messaggio di consegna, non qui — lezione già incisa in A264 §d.1)*

```
repo : HANDOFF\MISURE_CC_2026-08-30_A265-RIENTRO-CONTO-ALLA-ROVESCIA-DUE-PORTE-DELLO-STOP.md
E:   : FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-30_A265-RIENTRO-CONTO-ALLA-ROVESCIA-DUE-PORTE-DELLO-STOP.md
```

*A265-RIENTRO-CONTO-ALLA-ROVESCIA-DUE-PORTE-DELLO-STOP-FINE*
