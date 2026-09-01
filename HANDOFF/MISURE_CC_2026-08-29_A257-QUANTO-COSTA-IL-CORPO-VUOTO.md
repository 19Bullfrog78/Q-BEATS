# MISURE CC — A257 — QUANTO COSTA IL CORPO VUOTO — 29/08/2026

Da: CC · A: referee + Mauro + CD

**ID ESEGUITO: A257.** ⚠️ **A256 non mi è mai arrivato in nessuna forma** — e l'ho misurato invece di dichiararlo: `A256` rende 17 hit su C: e 40 su E:, **tutti falsi positivi da «SHA256»** (verificati leggendo il contesto, non contandoli). Zero tracce dell'atomo.

**⏱ Orologio, verificato prima di procedere:** sab 29/08/2026 **20:59 locale (UTC+2)** · 18:59 UTC.

**Aggancio confermato:** il mio ultimo referto è A255 (§10 di `MISURE_CC_2026-08-29_A253-USCITA-DAL-DETTAGLIO.md`), che chiudeva l'atomo 1a con `9c3616e`.

Marcatura: **[M]** misurato da me a fonte in questo turno · **[A]** giudizio mio. ⛔ Mai mescolati in una frase.

⛔ **NESSUNA MODIFICA SOTTO `ios_app/`.** Nessun commit, nessun push, nessuno staging. `HEAD` invariato a `9c3616ee8555a1d35d07e6c98892ec5a0306df3a`, working tree pulito. Questo giro non ripara niente.

---

## §0 — CANCELLO ID — QUATTRO GAMBE, UN POSITIVO CHE VEDE SU CIASCUNA

**[M]** `A257`: nome git 0 · nome C: 0 · contenuto git 0 · contenuto C: 0 · nome E: 0 · contenuto E: 0 · `git log --all --grep` 0.

**Positivo dichiarato quale-per-quale — `A253`, che vede su TUTTE E QUATTRO:**

| gamba | positivo | rende |
|---|---|---|
| nome (C: · E:) | `A253` | **3 · 3** |
| contenuto (C: · E:) | `A253` | **9 · 4** |
| `git log --all --grep` | `A253` | **1** (`9c3616e`) |

⇒ Un solo positivo copre le quattro gambe **perché il commit di A255 lo ha reso visibile anche nella storia** — cosa che in A254 non era vera per nessuno degli ID citati. Il difetto di A254 non si ripete.

---

## §1 — LA PREMESSA DEL MANDATO — aperta e verificata, non creduta

**[M] Il §D del rev3 di CD (28/08) dice esattamente quello che il mandato riporta.** Verbatim dal foglio:

> «`Resume from ⟨sezione⟩` chiama una funzione che **scarta il nome che riceve** e fa ripartire e basta; `Dall'inizio ⟨canzone⟩` finisce in un **corpo vuoto**. **Entrambi i bottoni dell'overlay sono morti**, uno dei due rumorosamente.»

> «L'overlay può uscire con `Restart song` **da solo**, se il corpo vuoto viene riempito.»

**Premessa CONFERMATA.** ⚠️ **Con una precisazione che cambia il conto**: §2.

---

## §2 — LE DUE FUNZIONI, TROVATE PER SIMBOLO — corpi verbatim

**Bottone 1 — «Riprendi da ⟨sezione⟩»** (`OverlayStopView.swift:16-17`):

```swift
// AudioEngine.swift:1303
func resumeFromCurrentSection() {
    os_log("[Q-BEATS][UX-3] resumeFromCurrentSection → countIn",
           log: .default, type: .default)
    DispatchQueue.main.async { [weak self] in
        self?.playbackState = .countIn
    }
    startCountIn(for: currentSection)
}

// AudioEngine.swift:1617 — riceve la sezione e non la usa
private func startCountIn(for section: String?) {
    start()
}
```

**Bottone 2 — «Dall'inizio · ⟨canzone⟩»** (`OverlayStopView.swift:21-22`):

```swift
// AudioEngine.swift:1321 — SECONDO stub, etichetta diversa
// Stub — implementazione in Fase Backtrack
func restartCurrentSong() { restartFromBeginning() }

// AudioEngine.swift:1312
func restartFromBeginning() {
    resetToSongStart()
    os_log("[Q-BEATS][UX-3] restartFromBeginning → stopped",
           log: .default, type: .default)
    DispatchQueue.main.async { [weak self] in
        self?.playbackState = .stopped
    }
}

// AudioEngine.swift:1622 — L3 stub — sostituito da Layer 3 quando disponibile.
private func resetToSongStart() {}
```

### ⚠️ DUE CORREZIONI ALLA DESCRIZIONE DI CD — la sostanza regge, il conto no

**[M] (a) La catena del bottone 2 ha DUE indirezioni e DUE stub, non uno.** Passa da `restartCurrentSong()` — che è **un secondo stub, con un'etichetta diversa** («Fase Backtrack», non «Layer 3») — prima di arrivare al corpo vuoto. Chi cerca «il corpo vuoto» partendo dal bottone trova prima quello, che *sembra* un cablaggio innocuo.

**[M] (b) 🚨 IL BOTTONE 2 NON È MUTO: MENTE, ed è la scoperta più importante di questo giro.** `restartFromBeginning()` **non è vuota** — scrive `playbackState = .stopped` sul motore. `LiveView` sincronizza quello stato sulla sessione (`.onReceive(audioEngine.$playbackState)`), e **`.overlayStop` NON è fra i casi protetti dalla guardia** di `LiveView.swift:461-466` (che copre solo `.standby` e `.fineSetlist`).

⇒ **Premendo «Dall'inizio · ⟨canzone⟩» l'overlay SI CHIUDE.** L'utente riceve il segnale visivo del successo — la schermata risponde, sparisce — e **non è tornato all'inizio di niente**. CD lo classifica come «morto, silenzioso» in opposizione all'altro «rumoroso»: **[A] la classificazione va rovesciata.** Un bottone che non fa nulla e non dà segno si scopre premendolo due volte; **un bottone che chiude il pannello dice «fatto» e mente.** Sul palco è la categoria peggiore, ed è la stessa che il §D esiste per vietare.

---

## §3 — «L3 STUB — SOSTITUITO DA LAYER 3 QUANDO DISPONIBILE» — l'etichetta è SCADUTA

**[M] Fonte trovata, in radice, `BOX5_QBEATS.md:118-120` verbatim:**

```
LAYER 3 — Swift / SwiftUI + ObjC++ Bridge                      🔄 IN CORSO
LAYER 2 — CoreMIDI C-API + Sequencer PPQN-960 + Ableton Link   ✅ CHIUSO
LAYER 1 — Core Audio C-API + C++ DSP Engine                    ✅ CHIUSO
```

**[M]** `BOX5:95` — «**Claude Code (CC)** — implementazione Swift/SwiftUI **Layer 3**». **[M]** `BOX5:123` — «qualsiasi problema visivo si risolve ESCLUSIVAMENTE in Layer 3». **[M]** `BOX5:562`, invariante **L1.a**: «AudioEngine **NON deve avere hardcoded** la decisione di "cosa fare a fine sezione". Il caller (**Layer 3**) passa una closure…».

⇒ **RISPOSTA AL PUNTO 3: non aspetta né un pezzo né un layer intero. Aspetta un CABLAGGIO.**

**[A] Layer 3 è disponibile da sempre: è lo strato in cui lavoriamo ogni giorno**, ed è `SetlistRunner` + le viste. L'etichetta si legge come una dipendenza da lavoro futuro e **non lo è**: quel corpo è vuoto **per contratto architetturale** — il motore non deve decidere cosa significa «inizio canzone», perché la posizione nella scaletta non gli appartiene. È la stessa regola di L1.a, applicata a un altro verbo.

⚠️ **[A] L'etichetta è quindi attivamente fuorviante**, e lo è in modo costoso: fa sembrare bloccato da altri un lavoro che è nostro e disponibile. Segnalata, **non corretta** — è codice sotto `ios_app/`, fuori perimetro.

---

## §4 — LA COSA CHE CAMBIA IL PREZZO: LA FUNZIONE GIUSTA ESISTE GIÀ, E NON È NEL MOTORE

**[M] `SetlistRunner.startCurrentSong(audioEngine:session:)` (`SetlistRunner.swift:139`) FA GIÀ ESATTAMENTE «riparti dall'inizio della canzone corrente»:**

```swift
func startCurrentSong(audioEngine: AudioEngine, session: LiveSession) {
    pendingDisplayUpdate = false
    currentSectionIdx = 0
    os_log("[Q-BEATS][L1.b] startCurrentSong — songIdx:%d sectionIdx:0", ...)
    prepareAndStartCurrentSection(audioEngine: audioEngine, session: session)
}
```

Conserva la canzone, azzera la sezione, e delega alla catena completa. **[M] Non è codice nuovo né sperimentale: è la funzione del velo standby, ed è passata dal collaudo device di Mauro** (28/08, ramo A240 di `TD-stop-perde-il-punto`, verde).

⇒ **[A] Riempire `resetToSongStart()` sarebbe costruire una seconda volta, a Layer 1, una cosa che a Layer 3 esiste, funziona ed è collaudata.** Il mandato chiede il prezzo di «riempire il corpo vuoto»: la misura dice che **quella non è la strada**, ed è per questo che il prezzo di §6(a) è basso.

---

## §5 — LA CATENA DI STATI, TRACCIATA FINO IN FONDO — e dove mi fermo

**[M]** Cosa dev'essere riportato indietro perché la promessa sia mantenuta, e chi già lo copre (`prepareAndStartCurrentSection`, `SetlistRunner.swift:194`):

| stato | dove vive | chi lo riporta indietro oggi |
|---|---|---|
| indice di sezione | `SetlistRunner.currentSectionIdx` | `startCurrentSong` → `= 0` |
| indice di canzone | `SetlistRunner.currentSongIdx` | **conservato** di proposito |
| contatore di ripetizioni | `AudioEngine._sectionBeatCounter` · `_sectionTotalBeats` | `loadSection` → **entrambi azzerati/ricalcolati** |
| closure di fine sezione | `AudioEngine._onSectionEnd` | `loadSection` la ri-registra |
| metrica (bpb, accenti, suddivisione, BPM) | `AudioEngine` | `setBeatsPerBar` · `setAccentPattern` · `setSubdivision` · `setBPM` |
| seed seamless N+1 | `AudioEngine` | `preloadNextSection` |
| i campi display | `LiveSession` | `updateSessionDisplay` |
| posizione della battuta nel motore | DSP | `start()` → ramo direttore/standalone: `metronome_reset_for_start(h, 0.0)` |

**🚨 [M] IL PUNTO CHE NON È UN DETTAGLIO — CON LINK ACCESO DA DIRETTORE, QUESTO BOTTONE È UN EVENTO DI BANDA.** `start()`, ramo direttore/standalone (`AudioEngine.swift:996-1001`), esegue `metronome_reset_for_start(h, 0.0)` e poi **`link_engine_start_at_beat_zero(lh, hostNow)`**: azzera la timeline Link condivisa. ⇒ **«Dall'inizio canzone» premuto dal Direttore fa ripartire da zero anche tutti i Follower collegati.** Non è un comando locale, e nessuna etichetta a schermo lo dice oggi.

**[M] MIDI:** cercato stato di posizione da riportare indietro — **non trovato**. `handleMIDIInput` è ricezione di comandi, non posizione. Le azioni `.nextSection`/`.prevSection`/`.nextSong`/`.startSong`/`.loopToggle` cadono su un ramo che logga «richiede Layer 3» (`AudioEngine.swift:1674`) e su corpi vuoti (`:1323-1325`), già coperti dal ticket `TD-transport-tre-pulsanti-su-funzioni-vuote`. **Nessun lavoro MIDI in questa catena.**

**[M] Il corpo vuoto morde in DUE posti, non uno.** Oltre al bottone, `handleStop()` ramo `.countIn` (`AudioEngine.swift:1292`) chiama `resetToSongStart()`: **anche lo stop durante il conto alla rovescia non riporta indietro niente.** Non è nel perimetro del mandato ed è la stessa riga.

### ⛔ DOVE MI FERMO — dichiarato

- **Non ho misurato il ramo Follower** (`.collaborativa` → `armSharedJoin`, `AudioEngine.swift:1017`): cosa faccia questo bottone premuto da un Follower **non l'ho tracciato**.
- **Non ho misurato cosa vede la band** al netto della latenza di ri-aggancio: dico che l'evento parte, **non** come atterra sui peer.
- **Zero device.** Tutto letto nel codice a `9c3616e`.

---

## §6 — IL PREZZO

**(a) «Riempire il corpo vuoto» — [A] non si riempie: si cabla, e il costo è basso.**
Il lavoro è **una riga di chiamata** — `runner.startCurrentSong(audioEngine:session:)` al posto di `audioEngine.restartCurrentSong()` — più **il passaggio del runner all'overlay**, che oggi riceve solo `audioEngine` (`OverlayStopView.swift:6`; il runner è già lì, `LiveView` lo tiene come `@EnvironmentObject`, `:6`). **Tutto Layer 3, zero tocchi a Layer 1 e 2, interamente reversibile.** ⚠️ **Ma non è a costo zero di decisione**: con Link da Direttore diventa un evento di banda (§5), e **quella è una scelta di prodotto, non un cablaggio** — va posta a Mauro prima, non scoperta sul palco.

**(b) La casa — [M] l'overlay ESISTE come vista, ma NON è raggiungibile dal prodotto.**
`OverlayStopView.swift` esiste (53 righe, ratificata in `BOX5:373`). Ma la catena d'ingresso è: `.overlayStop` ha **un solo scrittore** (`LiveView.swift:491`), alimentato da `.pausedAwaitingChoice`, che ha **un solo scrittore vero** (`AudioEngine.swift:1288`, dentro `handleStop()`). E **`handleStop()` ha due soli chiamanti: `DebugView.swift:187` e l'esecutore di azioni MIDI (`AudioEngine.swift:1667`).**
🚨 **Il pulsante STOP del transport NON lo chiama**: chiama `audioEngine.stop()` (controllo positivo a fonte, `TransportView.swift:53`).
⇒ **Risposta al punto 4: sì, la vista esiste; no, non ha una porta.** Oggi è raggiungibile su device **solo** perché la build di palco è Debug e `DebugView` viene compilata (`TD-build-palco-in-configurazione-debug`) — cioè **per un difetto**, e per una strada che si chiude al passaggio a Release.

**🚨 (b-bis) E COSTRUIRGLI LA PORTA RIAPRE UNA DECISIONE CHIUSA IL 28/08 — è il rilievo che cambia l'ordine dei lavori.**
Dare una porta all'overlay significa far chiamare `handleStop()` allo STOP del transport. Ma **[M]** quel gesto ha **già** un comportamento ratificato da Mauro e **collaudato verde su device il 28/08**: STOP → `.stopped`, e il Play successivo chiama `startCurrentSection`, che **conserva canzone e sezione** (opzione B, cartello A240 in `SetlistRunner.swift:148-166`, marcatura in `TransportView.swift:40-45`). Oggi il ciclo STOP→Play **fa già** «riparti da dov'eri».
⇒ **[A] Mettere l'overlay a due vie su STOP metterebbe una domanda davanti a un gesto che oggi risponde già, e nel modo che Mauro ha scelto.** Non è additivo: è la riapertura di `TD-stop-perde-il-punto`, chiuso ieri. **Non è un lavoro di cablaggio: è una decisione di Mauro, e va posta come tale.**

**(c) `Resume from ⟨sezione⟩` — non stimato, come da mandato. ⚠️ Ma la catena di (a) LA TOCCA, e il mandato chiedeva di dirlo.**
I due bottoni vivono **nella stessa vista**, che riceve **un solo oggetto** (`audioEngine`). Passarle il runner per il bottone 2 mette il bottone 1 **a una riga di distanza**: da lì `runner.startCurrentSection(...)` onorerebbe la sezione, che è esattamente la condizione posta dal §D per sbloccare `Resume`.
⇒ **[A] Il lavoro strutturale dei due bottoni è UNO SOLO e non è separabile.** Ciò che resta separato è la **decisione** di CD sul blocco, non il codice. **Questo cambia l'ordine**: fatto (a), sbloccare `Resume` non costa una seconda apertura del cantiere — costa la parola di CD.

---

## §7 — ⛔ COSA NON HO MISURATO — dichiarato, non riempito per deduzione

- ⛔ **Nessun collaudo su device, e nessuna build.** Tutto è lettura di codice a `9c3616e`. In particolare **la chiusura dell'overlay al tap sul bottone 2 (§2b) è dedotta dalla catena degli stati, NON osservata**: è la mia affermazione più forte di questo referto ed è la meno provata. **Va vista su device prima di essere citata come fatto.**
- ⛔ **Ramo Follower non tracciato** (§5).
- ⛔ **Non ho misurato se `startCountIn`/`resetToSongStart` abbiano altri chiamanti oltre a quelli citati** al di fuori di `AudioEngine.swift`: sono `private`, ma non ho enumerato l'intero file.
- ⛔ **Non ho aperto BOX3** (dichiara da sé di essere fermo al 22/07) né cercato lì l'origine storica dell'etichetta «L3 stub»: la fonte del **significato** di Layer 3 l'ho trovata in BOX5, la fonte della **frase** no. Se esiste, non l'ho cercata.
- ⛔ **Non ho verificato se esista un ticket BUGS per `resetToSongStart`**: ho cercato il simbolo nei tre canonici di radice e **non compare in BUGS** — ma non ho fatto una spazzata per effetto sui ticket che potrebbero descriverlo con altre parole.

---

## §8 — I DUE PERCORSI E LE IMPRONTE

```
REFERTO repo: HANDOFF\MISURE_CC_2026-08-29_A257-QUANTO-COSTA-IL-CORPO-VUOTO.md
        E:  : FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-29_A257-QUANTO-COSTA-IL-CORPO-VUOTO.md
        (impronta nel messaggio di consegna: il file non può contenere il proprio hash)
```

⛔ Nessun file sotto `ios_app/` toccato. `HEAD` = `9c3616e`, invariato.

*A257-QUANTO-COSTA-IL-CORPO-VUOTO-FINE*
