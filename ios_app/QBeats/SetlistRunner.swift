import Foundation
import Combine
import os

/// Layer 3 orchestrator per navigazione multi-section setlist (L1.b).
///
/// Vive in `LiveRootView` come `@StateObject` — vita = durata performance.
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

        // TD #41 fix — Lazy subscribe a `beatTickSubject`, UNA VOLTA per la
        // vita del runner. Sink applica `updateSessionDisplay` al primo tick
        // post-transition se `pendingDisplayUpdate == true`. Guard esplicito
        // `beatTickSubscribed` (NON `cancellables.isEmpty`).
        if !beatTickSubscribed {
            audioEngine.beatTickSubject
                .receive(on: DispatchQueue.main)
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
