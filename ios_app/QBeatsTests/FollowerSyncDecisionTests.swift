import XCTest

// === A386 · FASE B1 — banco della macchina del Follower (banco Models) ===
// Una riga della tabella di A-TER §2 (ratificata con R1, R2 e D7-bis) per test, con attesi
// LETTERALI: stato nuovo, azione, ragione dell'uscita. Piu' la corsa di fine canzone nei due
// ordini (un solo avanzamento), l'armamento ignorato in IN SYNC (B1-bis) e la prova per assenza
// degli ingressi «numero di peer» e «collegato». Il banco gira in CI su ogni push
// (`.github/workflows/ios_build.yml`, `xcodebuild test -scheme QBeatsTests`).

final class FollowerSyncDecisionTests: XCTestCase {

    private typealias S = FollowerSyncState
    private typealias E = FollowerSyncEvent
    private typealias T = FollowerSyncTransition

    private func t(_ state: S, _ event: E) -> T {
        FollowerSyncDecision.transition(state: state, event: event)
    }

    private func arming(_ source: FollowerArming.Source, heard: Bool, playing: Bool) -> E {
        .armed(FollowerArming(source: source, directorHeard: heard, sessionPlaying: playing))
    }

    // MARK: - Stato iniziale e reset

    func testInitialStateIsOutNotArmed() {
        XCTAssertEqual(FollowerSyncDecision.initial, .out(armed: nil))
    }

    func testResetFromEveryStateGoesOutNotArmed() {
        let states: [S] = [.inSync(songClosed: false), .inSync(songClosed: true), .alone,
                           .out(armed: nil), .out(armed: 3)]
        for state in states {
            XCTAssertEqual(t(state, .reset), T(.out(armed: nil), .none, .reset), "da \(state)")
        }
    }

    // MARK: - IN SYNC fermo

    func testInSyncStoppedPlayWithinHalfBarStarts() {
        XCTAssertEqual(t(.inSync(songClosed: false), .linkPlay(withinHalfBar: true)),
                       T(.inSync(songClosed: false), .start))
        XCTAssertEqual(t(.inSync(songClosed: true), .linkPlay(withinHalfBar: true)),
                       T(.inSync(songClosed: false), .start))
    }

    func testInSyncStoppedPlayBeyondHalfBarGoesOutPlayLate() {
        XCTAssertEqual(t(.inSync(songClosed: false), .linkPlay(withinHalfBar: false)),
                       T(.out(armed: nil), .none, .playLate))
        XCTAssertEqual(t(.inSync(songClosed: true), .linkPlay(withinHalfBar: false)),
                       T(.out(armed: nil), .none, .playLate))
    }

    func testInSyncStoppedStopArmsNextOnlyIfSongNotAlreadyClosed() {
        XCTAssertEqual(t(.inSync(songClosed: false), .linkStop(falseStart: false, engineRunning: false)),
                       T(.inSync(songClosed: true), .armNext))
        XCTAssertEqual(t(.inSync(songClosed: true), .linkStop(falseStart: false, engineRunning: false)),
                       T(.inSync(songClosed: true), .none))
    }

    func testInSyncStoppedFalseStartRearmsSameD7bis() {
        XCTAssertEqual(t(.inSync(songClosed: false), .linkStop(falseStart: true, engineRunning: false)),
                       T(.inSync(songClosed: true), .rearmSame))
        XCTAssertEqual(t(.inSync(songClosed: true), .linkStop(falseStart: true, engineRunning: false)),
                       T(.inSync(songClosed: true), .rearmSame))
    }

    func testInSyncStoppedNotHeardGoesOutD1() {
        XCTAssertEqual(t(.inSync(songClosed: false), .directorHeard(false, engineRunning: false)),
                       T(.out(armed: nil), .none, .lostWhileStopped))
        XCTAssertEqual(t(.inSync(songClosed: true), .directorHeard(false, engineRunning: false)),
                       T(.out(armed: nil), .none, .lostWhileStopped))
    }

    func testInSyncHeardIsUnchanged() {
        XCTAssertEqual(t(.inSync(songClosed: false), .directorHeard(true, engineRunning: false)),
                       T(.inSync(songClosed: false), .none))
        XCTAssertEqual(t(.inSync(songClosed: true), .directorHeard(true, engineRunning: true)),
                       T(.inSync(songClosed: true), .none))
    }

    // MARK: - IN SYNC in moto

    func testInSyncRunningStopStopsAndArmsNext() {
        XCTAssertEqual(t(.inSync(songClosed: false), .linkStop(falseStart: false, engineRunning: true)),
                       T(.inSync(songClosed: true), .stopAndArmNext))
    }

    func testInSyncRunningFalseStartStopsAndRearmsSameD7bis() {
        XCTAssertEqual(t(.inSync(songClosed: false), .linkStop(falseStart: true, engineRunning: true)),
                       T(.inSync(songClosed: true), .stopAndRearmSame))
    }

    func testInSyncRunningNotHeardGoesAlone() {
        XCTAssertEqual(t(.inSync(songClosed: false), .directorHeard(false, engineRunning: true)),
                       T(.alone, .none))
    }

    func testInSyncOwnSongEndedClosesTheSong() {
        XCTAssertEqual(t(.inSync(songClosed: false), .ownSongEnded),
                       T(.inSync(songClosed: true), .none))
    }

    func testInSyncMusicianStopStopsAndGoesOut() {
        XCTAssertEqual(t(.inSync(songClosed: false), .musicianStop),
                       T(.out(armed: nil), .stop, .musicianStop))
    }

    // MARK: - B1-bis: IN SYNC ignora l'armamento

    func testInSyncIgnoresArmingInEveryForm() {
        let sources: [FollowerArming.Source] = [.startShow, .rientra(songIdx: 2)]
        for songClosed in [false, true] {
            for source in sources {
                for heard in [false, true] {
                    for playing in [false, true] {
                        let state: S = .inSync(songClosed: songClosed)
                        XCTAssertEqual(t(state, arming(source, heard: heard, playing: playing)),
                                       T(state, .none),
                                       "songClosed:\(songClosed) source:\(source) sentito:\(heard) sessione:\(playing)")
                    }
                }
            }
        }
    }

    // MARK: - La corsa di fine canzone: un solo avanzamento nei due ordini

    func testSongEndRaceOwnEndThenDirectorStopAdvancesOnce() {
        // Il runner avanza da solo a fine canzone (fuori dalla macchina); lo Stop che segue
        // non deve chiedere un secondo avanzamento.
        let afterOwnEnd = t(.inSync(songClosed: false), .ownSongEnded)
        XCTAssertEqual(afterOwnEnd, T(.inSync(songClosed: true), .none))
        let afterStop = t(afterOwnEnd.state, .linkStop(falseStart: false, engineRunning: false))
        XCTAssertEqual(afterStop, T(.inSync(songClosed: true), .none))
    }

    func testSongEndRaceDirectorStopThenOwnEndAdvancesOnce() {
        // Lo Stop arriva prima: e' lui ad avanzare (una volta); il drain proprio, se fosse gia'
        // stato accodato, trova la canzone chiusa e non chiede altro.
        let afterStop = t(.inSync(songClosed: false), .linkStop(falseStart: false, engineRunning: true))
        XCTAssertEqual(afterStop, T(.inSync(songClosed: true), .stopAndArmNext))
        let afterOwnEnd = t(afterStop.state, .ownSongEnded)
        XCTAssertEqual(afterOwnEnd, T(.inSync(songClosed: true), .none))
        // e una ripetizione dello stesso Stop non avanza di nuovo
        let repeated = t(afterOwnEnd.state, .linkStop(falseStart: false, engineRunning: false))
        XCTAssertEqual(repeated, T(.inSync(songClosed: true), .none))
    }

    func testAfterAStartTheSongIsOpenAgain() {
        let started = t(.inSync(songClosed: true), .linkPlay(withinHalfBar: true))
        XCTAssertEqual(started.state, .inSync(songClosed: false))
    }

    // MARK: - DA SOLO

    func testAloneDirectorStoppedGoesOutAndStops() {
        XCTAssertEqual(t(.alone, .linkStop(falseStart: false, engineRunning: true)),
                       T(.out(armed: nil), .stop, .directorStoppedWhileAlone))
    }

    func testAloneDirectorFalseStartGoesOutWithSameSongReasonD7bis() {
        XCTAssertEqual(t(.alone, .linkStop(falseStart: true, engineRunning: true)),
                       T(.out(armed: nil), .stop, .directorFalseStartWhileAlone))
    }

    func testAloneStaysAloneWhenDirectorHeardAgainD2() {
        XCTAssertEqual(t(.alone, .directorHeard(true, engineRunning: true)), T(.alone, .none))
        XCTAssertEqual(t(.alone, .directorHeard(false, engineRunning: true)), T(.alone, .none))
    }

    func testAloneOwnSongEndedGoesOutD2() {
        XCTAssertEqual(t(.alone, .ownSongEnded), T(.out(armed: nil), .none, .aloneSongEnded))
    }

    func testAloneMusicianStopStopsAndGoesOut() {
        XCTAssertEqual(t(.alone, .musicianStop), T(.out(armed: nil), .stop, .musicianStop))
    }

    func testAloneIgnoresPlayAndArming() {
        XCTAssertEqual(t(.alone, .linkPlay(withinHalfBar: true)), T(.alone, .none))
        XCTAssertEqual(t(.alone, arming(.startShow, heard: true, playing: false)), T(.alone, .none))
        XCTAssertEqual(t(.alone, arming(.rientra(songIdx: 2), heard: true, playing: false)), T(.alone, .none))
    }

    // MARK: - FUORI non armato

    func testOutNotArmedIgnoresEverythingButArming() {
        let events: [E] = [.linkPlay(withinHalfBar: true), .linkPlay(withinHalfBar: false),
                           .linkStop(falseStart: false, engineRunning: false),
                           .linkStop(falseStart: true, engineRunning: false),
                           .directorHeard(true, engineRunning: false),
                           .directorHeard(false, engineRunning: false),
                           .ownSongEnded, .musicianStop]
        for event in events {
            XCTAssertEqual(t(.out(armed: nil), event), T(.out(armed: nil), .none), "\(event)")
        }
    }

    func testOutStartShowHeardAndSessionStoppedGoesInSync() {
        XCTAssertEqual(t(.out(armed: nil), arming(.startShow, heard: true, playing: false)),
                       T(.inSync(songClosed: false), .none))
    }

    func testOutRientraHeardAndSessionStoppedArms() {
        XCTAssertEqual(t(.out(armed: nil), arming(.rientra(songIdx: 4), heard: true, playing: false)),
                       T(.out(armed: 4), .none))
    }

    func testArmingRefusedWhenDirectorNotHeardR1() {
        XCTAssertEqual(t(.out(armed: nil), arming(.startShow, heard: false, playing: false)),
                       T(.out(armed: nil), .none, .armRefusedNotHeard))
        XCTAssertEqual(t(.out(armed: nil), arming(.rientra(songIdx: 4), heard: false, playing: false)),
                       T(.out(armed: nil), .none, .armRefusedNotHeard))
    }

    func testArmingRefusedWhenSessionPlayingR1() {
        XCTAssertEqual(t(.out(armed: nil), arming(.startShow, heard: true, playing: true)),
                       T(.out(armed: nil), .none, .armRefusedSessionPlaying))
        XCTAssertEqual(t(.out(armed: nil), arming(.rientra(songIdx: 4), heard: true, playing: true)),
                       T(.out(armed: nil), .none, .armRefusedSessionPlaying))
    }

    func testArmingRefusedNotHeardWinsOverSessionPlaying() {
        XCTAssertEqual(t(.out(armed: nil), arming(.startShow, heard: false, playing: true)),
                       T(.out(armed: nil), .none, .armRefusedNotHeard))
    }

    // MARK: - FUORI armato

    func testOutArmedPlayWithinHalfBarStartsAndGoesInSync() {
        XCTAssertEqual(t(.out(armed: 4), .linkPlay(withinHalfBar: true)),
                       T(.inSync(songClosed: false), .start))
    }

    func testOutArmedPlayBeyondHalfBarDisarms() {
        XCTAssertEqual(t(.out(armed: 4), .linkPlay(withinHalfBar: false)),
                       T(.out(armed: nil), .none, .playLate))
    }

    func testOutArmedDirectorStopKeepsTheArmingR2() {
        XCTAssertEqual(t(.out(armed: 4), .linkStop(falseStart: false, engineRunning: false)),
                       T(.out(armed: 4), .none))
        XCTAssertEqual(t(.out(armed: 4), .linkStop(falseStart: true, engineRunning: false)),
                       T(.out(armed: 4), .none))
    }

    func testOutArmedNotHeardDisarmsKeepingTheChoiceR2() {
        XCTAssertEqual(t(.out(armed: 4), .directorHeard(false, engineRunning: false)),
                       T(.out(armed: nil), .none, .lostWhileArmed(chosen: 4)))
    }

    func testOutArmedHeardIsUnchanged() {
        XCTAssertEqual(t(.out(armed: 4), .directorHeard(true, engineRunning: false)),
                       T(.out(armed: 4), .none))
    }

    func testOutArmedRearmsWithANewChoice() {
        XCTAssertEqual(t(.out(armed: 4), arming(.rientra(songIdx: 1), heard: true, playing: false)),
                       T(.out(armed: 1), .none))
        XCTAssertEqual(t(.out(armed: 4), arming(.rientra(songIdx: 1), heard: true, playing: true)),
                       T(.out(armed: nil), .none, .armRefusedSessionPlaying))
    }

    func testOutArmedIgnoresOwnSongEndedAndMusicianStop() {
        XCTAssertEqual(t(.out(armed: 4), .ownSongEnded), T(.out(armed: 4), .none))
        XCTAssertEqual(t(.out(armed: 4), .musicianStop), T(.out(armed: 4), .none))
    }

    // MARK: - Le tre righe della tabella del 2D

    func testDirectorStoppedWhileFollowerAloneStopsAndGoesOut() {
        XCTAssertEqual(t(.alone, .linkStop(falseStart: false, engineRunning: true)).action, .stop)
    }

    func testDirectorRunningSameSongFollowerAloneContinues() {
        XCTAssertEqual(t(.alone, .directorHeard(true, engineRunning: true)).state, .alone)
    }

    func testDirectorRunningNewSongFollowerStoppedOnVeilGoesOut() {
        XCTAssertEqual(t(.inSync(songClosed: true), .linkPlay(withinHalfBar: false)).state, .out(armed: nil))
    }

    // MARK: - Prova per assenza: gli ingressi della macchina sono questi e basta

    func testEventsCarryNoPeerCountAndNoConnectedFlag() {
        // Lo switch e' esaustivo: aggiungere un caso all'enum senza toccarlo qui non compila.
        // Sette casi, nessuno porta un numero di peer ne' un «collegato».
        let events: [E] = [.linkPlay(withinHalfBar: true),
                           .linkStop(falseStart: false, engineRunning: false),
                           .directorHeard(true, engineRunning: false),
                           .ownSongEnded, .musicianStop,
                           arming(.startShow, heard: true, playing: false),
                           .reset]
        var seen = 0
        for event in events {
            switch event {
            case .linkPlay, .linkStop, .directorHeard, .ownSongEnded, .musicianStop, .armed, .reset:
                seen += 1
            }
        }
        XCTAssertEqual(seen, 7)
    }
}
