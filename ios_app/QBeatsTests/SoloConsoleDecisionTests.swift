import XCTest

// === A397 · SOLO-G1-PEZZO-1-M2 — banco della console B (banco Models) ===
// Per ogni stato del player: tasto centrale, Kill, List mode, Mixer; faccia e azione del tasto centrale dallo
// stesso ingresso (D5); Kill acceso solo in moto con la base che suona (provato anche con la base che suona, che
// oggi nel player non arriva); List mode mai; Mixer sempre, selezionato a pannello aperto; Kill e List mode spenti
// non fanno niente.

final class SoloConsoleDecisionTests: XCTestCase {

    private let states: [LivePlaybackState] = [
        .standby(nextSongName: "Circuz"), .countIn(countdown: 4), .playing, .stopped, .loopActive,
        .overlayStop(sectionName: "Bridge", songName: "Circuz"), .fineSetlist, .starting,
    ]

    func testTheStatesOfThePlayerAreEight() {
        XCTAssertEqual(states.count, 8)
    }

    func testTheCenterSaysStopExactlyWhenTheTouchStops() {
        for running in [false, true] {
            let f = SoloConsoleDecision.faces(transportRunning: running, backtrackPlaying: false, mixerOpen: false)
            XCTAssertEqual(f.center, running ? .stop : .play)
            let a = SoloConsoleDecision.action(for: .center, faces: f)
            XCTAssertEqual(a, running ? .stop : .start)
            XCTAssertEqual(f.center == .stop, a == .stop, "faccia e azione dallo stesso dato (D5)")
        }
    }

    func testThePlayerStateDoesNotEnterTheConsole() {
        // La regola prende l'ingresso dell'azione (`isPlaying`), non lo stato del player: per ognuno degli otto
        // stati la console è la stessa funzione di `transportRunning`. (Nella finestra `.countIn` con `isPlaying`
        // falso la scritta di oggi diceva Stop mentre il tocco avrebbe avviato: qui dice Play, come l'azione.)
        for state in states {
            for running in [false, true] {
                let f = SoloConsoleDecision.faces(transportRunning: running, backtrackPlaying: false, mixerOpen: false)
                XCTAssertEqual(f.center, running ? .stop : .play, "stato \(state) in-moto:\(running)")
                XCTAssertTrue(f.mixerOn, "stato \(state)")
                XCTAssertFalse(f.mixerSelected, "stato \(state)")
                XCTAssertFalse(f.killOn, "stato \(state): la base nel player non suona")
                XCTAssertFalse(f.listModeOn, "stato \(state)")
            }
        }
    }

    func testTheMixerIsAlwaysOnAndSelectedWhenThePanelIsOpen() {
        for running in [false, true] {
            XCTAssertTrue(SoloConsoleDecision.faces(transportRunning: running, backtrackPlaying: false, mixerOpen: false).mixerOn)
            XCTAssertFalse(SoloConsoleDecision.faces(transportRunning: running, backtrackPlaying: false, mixerOpen: false).mixerSelected)
            XCTAssertTrue(SoloConsoleDecision.faces(transportRunning: running, backtrackPlaying: false, mixerOpen: true).mixerSelected)
        }
    }

    func testKillIsOnOnlyInMotionWithTheBacktrackPlaying() {
        XCTAssertFalse(SoloConsoleDecision.faces(transportRunning: false, backtrackPlaying: false, mixerOpen: false).killOn)
        XCTAssertFalse(SoloConsoleDecision.faces(transportRunning: false, backtrackPlaying: true, mixerOpen: false).killOn)
        XCTAssertFalse(SoloConsoleDecision.faces(transportRunning: true, backtrackPlaying: false, mixerOpen: false).killOn)
        XCTAssertTrue(SoloConsoleDecision.faces(transportRunning: true, backtrackPlaying: true, mixerOpen: false).killOn)
    }

    func testListModeIsNeverOn() {
        for running in [false, true] {
            for backtrack in [false, true] {
                for mixer in [false, true] {
                    XCTAssertFalse(SoloConsoleDecision.faces(transportRunning: running, backtrackPlaying: backtrack, mixerOpen: mixer).listModeOn)
                }
            }
        }
    }

    func testTheActionsOfTheKeys() {
        let off = SoloConsoleDecision.faces(transportRunning: true, backtrackPlaying: false, mixerOpen: false)
        XCTAssertEqual(SoloConsoleDecision.action(for: .mixer, faces: off), .toggleMixer)
        XCTAssertEqual(SoloConsoleDecision.action(for: .kill, faces: off), .none, "Kill spento: nessuna azione")
        XCTAssertEqual(SoloConsoleDecision.action(for: .listMode, faces: off), .none, "List mode: nessuna azione")
        let on = SoloConsoleDecision.faces(transportRunning: true, backtrackPlaying: true, mixerOpen: true)
        XCTAssertEqual(SoloConsoleDecision.action(for: .kill, faces: on), .killBacktrack)
        XCTAssertEqual(SoloConsoleDecision.action(for: .mixer, faces: on), .toggleMixer)
        XCTAssertEqual(SoloConsoleDecision.action(for: .listMode, faces: on), .none)
        XCTAssertEqual(SoloConsoleDecision.action(for: .center, faces: on), .stop)
    }
}
