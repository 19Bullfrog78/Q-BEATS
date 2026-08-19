import Foundation
import Combine
import os

/// Layer 3 orchestrator per navigazione multi-section setlist (L1.b).
///
/// Lo SLOT che lo ospita vive in `QLiveSession`, posseduta da `QLiveRootView`
/// come `@StateObject` (⟦S4R⟧): il runner nasce allo Start (⟦S5⟧) con la
/// setlist scelta e vive quanto la stanza Q-Live — vita = durata performance.
/// AudioEngine ignora il setlist: SetlistRunner è il callsite di
/// `loadSection(onEnd:)` e decide tra i 3 rami end-of-section:
///   - `avanza`      — sezione successiva nella stessa canzone
///   - `standby`     — fine canzone, prossima canzone esiste
///   - `fineSetlist` — fine ultima sezione di ultima canzone della setlist
///
/// La closure end-of-section è costruita UNA VOLTA in
/// `prepareAndStartCurrentSection` e riusata identica in ogni `loadSection`
/// successivo (autopropagante). Cattura `[weak self, weak audioEngine,
/// weak session]` e legge `currentSongIdx`/`currentSectionIdx` al momento
/// dell'esecuzione, non della costruzione.
///
/// Specifica vincolante: BOX5 V22 "Fade scatta SOLO a fine vera".
/// Memoria correlata: `project_qbeats_l1b_fade_rule.md`.
@MainActor
final class SetlistRunner: ObservableObject {

    // MARK: - Stato interno

    private let catalog: [Song]
    @Published private(set) var currentSongIdx: Int = 0
    @Published private(set) var currentSectionIdx: Int = 0

    // Costruita lazy al primo `prepareAndStartCurrentSection`. Riusata
    // identica per tutta la vita del runner (autopropagante).
    private var sectionEndedClosure: (() -> Void)?

    // MARK: - Display update segnale (TD #41 fix, 17/05/2026)

    /// Subscription al `beatTickSubject` di AudioEngine. Subscribed UNA VOLTA
    /// in `prepareAndStartCurrentSection` (guard `beatTickSubscribed`), vive
    /// per la durata del runner. Sink: se `pendingDisplayUpdate == true`,
    /// chiama `updateSessionDisplay` e azzera il flag.
    private var cancellables = Set<AnyCancellable>()

    /// Guard esplicito per la sottoscrizione lazy. NON usare
    /// `cancellables.isEmpty` come guard: è fragile se altre subscription
    /// venissero aggiunte/rimosse in seguito.
    private var beatTickSubscribed = false

    /// True quando il ramo `avanza` ha incrementato `currentSectionIdx` ma
    /// il display non è ancora stato aggiornato. Il subscriber a
    /// `beatTickSubject` applica `updateSessionDisplay` al primo tick
    /// post-transition (= primo beat nuova sezione audio Strada A).
    /// Reset esplicito ai entry points (`startSetlist`, `startCurrentSong`)
    /// per evitare update spurio al replay dopo Stop manuale durante
    /// transizione SEAMLESS (TD #41 lifecycle).
    @Published private(set) var pendingDisplayUpdate: Bool = false

    // MARK: - Init

    init(setlist: Setlist, store: QBeatsStore) {
        let resolved = store.resolve(setlist)
        self.catalog = resolved.songs
        os_log("[Q-BEATS][L1.b] SetlistRunner init — songs:%d missing:%d",
               log: .default, type: .default,
               resolved.songs.count, resolved.missingIDs.count)
    }

    // MARK: - Derivati

    var currentSong: Song? {
        guard currentSongIdx >= 0, currentSongIdx < catalog.count else { return nil }
        return catalog[currentSongIdx]
    }

    var currentSection: SongSection? {
        guard let song = currentSong,
              currentSectionIdx >= 0,
              currentSectionIdx < song.sections.count else { return nil }
        return song.sections[currentSectionIdx]
    }

    var nextSection: SongSection? {
        guard let song = currentSong else { return nil }
        let nextIdx = currentSectionIdx + 1
        guard nextIdx < song.sections.count else { return nil }
        return song.sections[nextIdx]
    }

    var nextSong: Song? {
        let nextIdx = currentSongIdx + 1
        guard nextIdx < catalog.count else { return nil }
        return catalog[nextIdx]
    }

    var isLastSectionInSong: Bool {
        guard let song = currentSong else { return true }
        return currentSectionIdx + 1 >= song.sections.count
    }

    var isLastSongInSetlist: Bool {
        return currentSongIdx + 1 >= catalog.count
    }

    // MARK: - Entry points pubblici

    /// Primo Play della setlist — resetta indici a 0 e carica la prima sezione.
    /// Chiamato dal pulsante Play del transport quando da `.stopped`.
    func startSetlist(audioEngine: AudioEngine, session: LiveSession) {
        // Reset esplicito pendingDisplayUpdate: se l'utente ha fatto Stop
        // durante una transizione SEAMLESS (flag true) e ora replay, evita
        // updateSessionDisplay spurio al primo tick post-replay (TD #41).
        pendingDisplayUpdate = false
        currentSongIdx = 0
        currentSectionIdx = 0
        os_log("[Q-BEATS][L1.b] startSetlist — reset a songIdx:0 sectionIdx:0",
               log: .default, type: .default)
        prepareAndStartCurrentSection(audioEngine: audioEngine, session: session)
    }

    /// Avvio canzone corrente dopo standby — presuppone `currentSongIdx`
    /// già avanzato dal ramo standby della closure end-of-section.
    /// Chiamato dal tap su `StandbyOverlayView`.
    func startCurrentSong(audioEngine: AudioEngine, session: LiveSession) {
        // Reset esplicito coerente con startSetlist (TD #41 lifecycle).
        pendingDisplayUpdate = false
        currentSectionIdx = 0
        os_log("[Q-BEATS][L1.b] startCurrentSong — songIdx:%d sectionIdx:0",
               log: .default, type: .default, currentSongIdx)
        prepareAndStartCurrentSection(audioEngine: audioEngine, session: session)
    }

    // MARK: - Core orchestration

    /// Setup audio engine per la sezione corrente, aggiorna session, parte audio.
    /// Ordine ratificato delle chiamate ad AudioEngine:
    ///   1. setBeatsPerBar  2. setAccentPattern  3. loadSection  4. setBPM  5. start
    /// loadSection PRIMA di setBPM: registra la nuova sezione e la closure
    /// (race-safe rispetto al drain della sezione precedente).
    private func prepareAndStartCurrentSection(audioEngine: AudioEngine,
                                                session: LiveSession) {
        guard let section = currentSection else {
            // Stato degenerato: setlist vuota o currentSongIdx fuori range.
            // Trattato come fineSetlist immediato.
            os_log("[Q-BEATS][L1.b] prepareAndStartCurrentSection — currentSection nil → fineSetlist",
                   log: .default, type: .default)
            audioEngine.sectionEndedSubject.send()
            session.playbackState = .fineSetlist
            return
        }

        // TD #41 fix v2 (17/05/2026) — Lazy subscribe a `session.$beatActive`
        // filter ==1, UNA VOLTA per la vita del runner. Sink applica
        // `updateSessionDisplay` al primo beat di una battuta SE
        // `pendingDisplayUpdate == true`.
        //
        // Motivazione cambio v1 → v2: il sink originale su `beatTickSubject`
        // con `.receive(on: DispatchQueue.main)` soffriva di race FIFO main
        // queue. L'operator `.receive(on:)` faceva sì che il sink ricevesse
        // il tick_ULTIMO sezione precedente DOPO la closure step (i) avesse
        // settato `pendingDisplayUpdate = true` → updateSessionDisplay
        // applicato all'ULTIMO beat sezione precedente anziché al PRIMO beat
        // nuova sezione (TD #41 ROSSO sul device 17/05 test L1.b: testo
        // teleprompter + macrobar cambiavano al 4° beat sez prec).
        //
        // `session.beatActive` è invece settato da LiveView handler
        // `beatTickSubject` DOPO aver applicato i mirror pending e resettato
        // `sectionStartTick`. Al tick_PRIMO nuova sezione, beatActive=1
        // (= ((1-1) % bpb) + 1). Filter ==1 garantisce sink solo al primo
        // beat di battuta.
        //
        // `.receive(on:)` rimosso: `LiveSession` è @MainActor e
        // `session.beatActive` è scritto solo dal main (LiveView handler),
        // quindi il sink scatta sincrono sul main thread senza scheduler
        // intermedio. Codice più pulito e zero ambiguità di timing.
        //
        // Guard esplicito `beatTickSubscribed` (NON `cancellables.isEmpty`).
        if !beatTickSubscribed {
            session.$beatActive
                .filter { $0 == 1 }
                .sink { [weak self, weak session] _ in
                    guard let self,
                          let session,
                          self.pendingDisplayUpdate else { return }
                    self.updateSessionDisplay(session: session)
                    self.pendingDisplayUpdate = false
                }
                .store(in: &cancellables)
            beatTickSubscribed = true
        }

        // Lazy build closure end-of-section (autopropagante, costruita una
        // sola volta per la vita del runner).
        if sectionEndedClosure == nil {
            sectionEndedClosure = makeSectionEndedClosure(audioEngine: audioEngine, session: session)
        }
        guard let closure = sectionEndedClosure else { return }

        // 1-4: ordine ratificato setup audio.
        audioEngine.setBeatsPerBar(section.beatsPerBar)
        audioEngine.setAccentPattern(section.accentPattern)
        // W1 (wiring subdivision/swing → Live): il valore authoring della
        // sezione (SectionEditorView) finalmente arriva al DSP anche a Play
        // — prima lo consumava solo DebugView. Setter secco RT-safe (hop su
        // audioQueue in AudioEngine.setSubdivision): qui l'audio è fermo o
        // in setup, nessuna finestra seamless in corso.
        audioEngine.setSubdivision(multiplier: section.subdivisionMultiplier,
                                   swingRatio: section.swingRatio)
        audioEngine.loadSection(beatsPerBar: section.beatsPerBar,
                                repetitions: section.repetitions,
                                onEnd: closure)
        audioEngine.setBPM(section.bpm)

        // Strada A — Seed del meccanismo seamless: pre-load sezione N+1
        // SOLO se esiste nella stessa canzone. Se nextSection == nil
        // (canzone con una sola sezione, o ultima sezione della canzone),
        // il primo cambio passa per drain + standby (corretto).
        if let n1 = self.nextSection {
            audioEngine.preloadNextSection(bpm: n1.bpm,
                                           beatsPerBar: n1.beatsPerBar,
                                           accentPattern: n1.accentPattern,
                                           subdivisionMultiplier: n1.subdivisionMultiplier,
                                           swingRatio: n1.swingRatio,
                                           repetitions: n1.repetitions,
                                           onEnd: closure)
        }

        // 5: display LiveSession (siamo già su main, @Published direct).
        updateSessionDisplay(session: session)

        // 6: parte la catena audio.
        // L1.b v1: niente count-in tra canzoni. Da aggiungere in iterazione successiva.
        audioEngine.start()
    }

    /// Aggiorna i campi `@Published` di LiveSession per il display Vista LIVE.
    /// Chiamato all'inizio sezione (start*, ramo avanza).
    private func updateSessionDisplay(session: LiveSession) {
        guard let song = currentSong, let section = currentSection else { return }
        session.currentSongName    = song.name
        session.currentSectionName = section.name
        session.nextSectionName    = nextSection?.name
        session.nextSongName       = isLastSectionInSong ? nextSong?.name : nil
        session.macroBarCurrent    = currentSectionIdx + 1
        session.macroBarTotal      = song.sections.count
    }

    // MARK: - Problema A fix (27/05/2026) — Display init pre-Play device locale
    //
    // NB nomenclatura: NON confondere con "Bug 1" del RECAP 24/05 (Follower no
    // update quando Director fa Play cross-device — Problema B, fuori scope).
    // Questo è Problema A: display vuoto pre-Play su singolo device.

    /// Popola il display LiveSession con la prima sezione della setlist
    /// caricata, SENZA avviare l'audio. Chiamato dall'`onAppear` di LiveView
    /// per evitare che la videata appaia "vuota" (nome canzone/sezione/next
    /// blank) al primo ingresso prima del tap Play.
    ///
    /// ⚠️ MARCATURA ⟦S5b⟧ — LE TRE RIGHE QUI SOTTO SONO SCADUTE: si marcano, non si
    /// riscrivono. Da ⟦S5b⟧ l'ingresso in uno show NON è più `.stopped`, è ARMA +
    /// STANDBY sulla prima canzone — `BOX5_QBEATS.md:331` (QL-SHOWS-07).
    /// L'obiezione storica non si applica: TD #28 tolse lo standby d'ingresso
    /// (`Models/LiveSession.swift:30-34`) perché mostrava un EM-DASH, cioè uno
    /// standby SENZA NOME VERO, con nessuna setlist caricata. Con un runner
    /// armato il nome c'è, ed è quello della canzone che partirà al tocco.
    ///
    /// Coerente con TD #28 (17/05/2026): stato iniziale Vista LIVE è `.stopped`,
    /// nessun overlay standby — la videata deve mostrare i dati della setlist
    /// caricata già in stato `.stopped`.
    ///
    /// Sicuro chiamarlo più volte: idempotente quando il runner è in stato
    /// iniziale (currentSongIdx=0, currentSectionIdx=0). NON tocca AudioEngine,
    /// NON modifica `pendingDisplayUpdate` né `sectionEndedClosure`.
    ///
    /// In aggiunta a `updateSessionDisplay` (che popola solo nomi + macrobar),
    /// setta anche `currentBPM` e `totalBarsInSection` dalla prima sezione
    /// del catalogo runner — così il display pre-Play è coerente con la
    /// setlist caricata, non con i default LiveSession (120 BPM, 4 battute).
    func primeDisplay(session: LiveSession) {
        guard let section = currentSection else { return }
        updateSessionDisplay(session: session)
        session.currentBPM         = section.bpm
        session.totalBarsInSection = Int(section.repetitions)
        // ⟦S5b⟧ `Cond (b)` — ARMAMENTO D'INGRESSO. Il player si monta FERMO e ARMATO:
        // titolo della prima canzone che pulsa sopra il player oscurato
        // (`LiveView.swift:129` opacità 0,10 · `:132-138` overlay + tap-ovunque ·
        // `StandbyOverlayView.swift:18-24` e `:31-35`). Il click NON parte qui: parte al
        // tocco successivo, che va a `startCurrentSong` e suona QUESTA canzone, perché
        // `currentSongIdx` è ancora 0.
        //
        // IL NOME GIUSTO È `currentSong`, NON `nextSong`. `.standby(nextSongName:)`
        // significa «la canzone che partirà al prossimo tap»: nel ramo standby fra due
        // canzoni quel nome è letto DOPO `currentSongIdx += 1` (:343-345), quindi è
        // sempre la corrente-dopo-l'avanzamento. All'ingresso, con indice 0, è la PRIMA.
        // Usare `nextSong` qui darebbe la SECONDA canzone.
        //
        // ⛔ `Cond (c)` — LISTA DI PERMESSI, NON DI DIVIETI (correzione del referee).
        //    Si arma SOLO da `.stopped`. `primeDisplay` gira a OGNI `onAppear`, non solo
        //    al primo (unico chiamante: `LiveView.swift:231`), e `LivePlaybackState` ha
        //    OTTO casi (`Models/LivePlaybackState.swift:3-19`): .standby .countIn
        //    .playing .stopped .loopActive .overlayStop .fineSetlist .waitingForDirector.
        //    Un divieto scritto al contrario («arma a meno che stia suonando») ne
        //    coprirebbe uno e calpesterebbe gli altri: rimetterebbe l'overlay sopra
        //    END SHOW, sopra la pausa a metà sezione e sopra l'attesa del Direttore.
        //    L'elenco dei permessi ha un solo membro, e così resta corretto anche se
        //    domani se ne aggiunge un nono.
        if case .stopped = session.playbackState, let song = currentSong {
            session.playbackState = .standby(nextSongName: song.name)
        }
    }

    // MARK: - Closure end-of-section (autopropagante)

    /// Closure passata a `loadSection(onEnd:)`. Eseguita su main thread
    /// (drain dispatch usa `DispatchQueue.main.async`). Legge indici al
    /// momento dell'esecuzione: ad ogni transizione trova `currentSongIdx`
    /// e `currentSectionIdx` aggiornati dal ramo precedente. Pubblica per
    /// testabilità.
    func makeSectionEndedClosure(audioEngine: AudioEngine,
                                  session: LiveSession) -> () -> Void {
        return { [weak self, weak audioEngine, weak session] in
            guard let self, let audioEngine, let session else { return }
            os_log("[Q-BEATS][DRAIN] endClosure executing",
                   log: .default, type: .default)

            if !self.isLastSectionInSong {
                // === RAMO AVANZA — Strada A (seamless) ===
                // Lo swap audio (BPM/BPB/accent/totalBeats) è già avvenuto
                // nel beat callback di AudioEngine (ramo SEAMLESS). Qui:
                //   1. avanza currentSectionIdx
                //   2. aggiorna session display
                //   3. pre-load sezione N+2 SE esiste nella stessa canzone
                // NESSUNA chiamata a setBeatsPerBar/setAccentPattern/
                // loadSection/scheduleBPMChange/kickScheduling — tutto
                // gestito dallo swap nel beat callback.
                self.currentSectionIdx += 1
                guard let closure = self.sectionEndedClosure else {
                    os_log("[Q-BEATS][L1.b] avanza — closure nil, abort",
                           log: .default, type: .error)
                    return
                }
                os_log("[Q-BEATS][L1.b] avanza (seamless) — songIdx:%d sectionIdx:%d",
                       log: .default, type: .default,
                       self.currentSongIdx, self.currentSectionIdx)
                // ATOM C — il setter-post-confine di W1 è stato RIMOSSO: la
                // subdivision della sezione entrante ora viaggia col preload
                // (preloadNextSection) e si arma al downbeat nel ramo
                // SEAMLESS di AudioEngine via metronome_schedule_subdivision,
                // sample-accurate come bpm/bpb/accent. Qui non serve altro.
                // TD #41 fix: rinvia updateSessionDisplay al primo beat tick
                // della nuova sezione. Senza rinvio, il display si aggiornava
                // all'ULTIMO beat sezione precedente (dispatch step (i) di
                // AudioEngine.scheduleNextBuffer ramo SEAMLESS su main),
                // mostrando il testo della sezione successiva 1 beat prima
                // del cambio audio. Il subscriber a `beatTickSubject` in
                // `prepareAndStartCurrentSection` chiamerà
                // `updateSessionDisplay` al primo tick post-transition.
                self.pendingDisplayUpdate = true
                // Pre-load sezione N+2 SOLO se esiste nella stessa canzone.
                // Se nextSection == nil dopo l'avanzamento: l'attuale è
                // l'ultima della canzone — il prossimo cambio passerà per
                // drain + standby (passaggio inter-canzone), il prossimo
                // swap vedrà _pendingNext* == nil → ramo DRAIN.
                if let n2 = self.nextSection {
                    audioEngine.preloadNextSection(bpm: n2.bpm,
                                                   beatsPerBar: n2.beatsPerBar,
                                                   accentPattern: n2.accentPattern,
                                                   subdivisionMultiplier: n2.subdivisionMultiplier,
                                                   swingRatio: n2.swingRatio,
                                                   repetitions: n2.repetitions,
                                                   onEnd: closure)
                }
                // NESSUN sectionEndedSubject.send() — transizione intermedia.

            } else if !self.isLastSongInSetlist {
                // === RAMO STANDBY ===
                self.currentSongIdx += 1
                self.currentSectionIdx = 0
                let nextSongName = self.currentSong?.name ?? "—"
                os_log("[Q-BEATS][L1.b] standby — nextSong:%{public}@",
                       log: .default, type: .default, nextSongName)
                session.playbackState = .standby(nextSongName: nextSongName)
                session.beatActive = 0
                // L1.b Fix 7 — Azzera i campi display per non far apparire i
                // dati della canzone precedente in secondo piano sotto lo
                // standby overlay (la canzone successiva NON è ancora caricata,
                // arriva al tap su StandbyOverlay → runner.startCurrentSong).
                session.currentSongName = ""
                session.currentSectionName = ""
                session.nextSectionName = nil
                session.nextSongName = nil
                session.macroBarCurrent = 0
                session.macroBarTotal = 1
                // NESSUN sectionEndedSubject.send() — fine canzone non è fine performance.
                // NESSUN loadSection/setBPM — il prossimo setup arriva al tap
                // StandbyOverlay tramite runner.startCurrentSong(...).
                // Stop pulisce stato audio (isRunning=false) — necessario perché
                // audioEngine.start() ha guard `!isRunning` (AudioEngine.swift:503).
                // Senza questo, startCurrentSong sarebbe no-op silenzioso e la
                // canzone successiva non partirebbe mai.
                // NB: audioEngine.stop() dispatcha playbackState=.stopped su main,
                // che senza il fix in LiveView.onReceive(audioEngine.$playbackState)
                // sovrascriverebbe il .standby appena impostato.
                audioEngine.stop()

            } else {
                // === RAMO FINESETLIST ===
                os_log("[Q-BEATS][L1.b] fineSetlist — performance terminata",
                       log: .default, type: .default)
                audioEngine.sectionEndedSubject.send()   // PRIMA del cambio stato
                session.playbackState = .fineSetlist
                audioEngine.stop()
            }
        }
    }
}
