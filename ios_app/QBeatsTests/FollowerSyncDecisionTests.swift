import XCTest

// === A386 · FASE B1 — banco della macchina del Follower (banco Models) ===
// Una riga della tabella di A-TER §2 (ratificata con R1, R2 e D7-bis) per test, con attesi
// LETTERALI: stato nuovo, azione, ragione dell'uscita. Piu' la corsa di fine canzone nei due
// ordini (un solo avanzamento), l'armamento ignorato in IN SYNC (B1-bis) e la prova per assenza
// degli ingressi «numero di peer» e «collegato». Il banco gira in CI su ogni push
// (`.github/workflows/ios_build.yml`, `xcodebuild test -scheme QBeatsTests`).
// B2b (mandato A386 §3.a, §3.b, §3.d): la sorgente `startShow` e' uscita (A1); l'armamento
// accettato porta l'azione `armSong(songIdx:)` e il rifiuto porta la canzone toccata; lo Stop
// del Direttore in DA SOLO, la falsa partenza in DA SOLO e lo Stop del musicista chiudono la
// canzone sul runner (`stopAndArmNext` / `stopAndRearmSame`).

final class FollowerSyncDecisionTests: XCTestCase {

    private typealias S = FollowerSyncState
    private typealias E = FollowerSyncEvent
    private typealias T = FollowerSyncTransition

    private func t(_ state: S, _ event: E) -> T {
        FollowerSyncDecision.transition(state: state, event: event)
    }

    private func arming(_ songIdx: Int, heard: Bool, playing: Bool) -> E {
        .armed(FollowerArming(source: .rientra(songIdx: songIdx), directorHeard: heard, sessionPlaying: playing))
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

    func testInSyncMusicianStopStopsClosesTheSongAndGoesOut() {
        // B2b (§3.d): non piu' il solo `stop` — la canzone fermata si chiude sul runner.
        XCTAssertEqual(t(.inSync(songClosed: false), .musicianStop),
                       T(.out(armed: nil), .stopAndArmNext, .musicianStop))
        XCTAssertEqual(t(.inSync(songClosed: true), .musicianStop),
                       T(.out(armed: nil), .stopAndArmNext, .musicianStop))
    }

    // MARK: - B1-bis / B2b (§3.b): IN SYNC ignora l'armamento — runner e misura non si toccano

    func testInSyncIgnoresArmingInEveryForm() {
        for songClosed in [false, true] {
            for songIdx in [0, 2] {
                for heard in [false, true] {
                    for playing in [false, true] {
                        let state: S = .inSync(songClosed: songClosed)
                        XCTAssertEqual(t(state, arming(songIdx, heard: heard, playing: playing)),
                                       T(state, .none),
                                       "songClosed:\(songClosed) songIdx:\(songIdx) sentito:\(heard) sessione:\(playing)")
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

    func testAloneDirectorStoppedStopsClosesTheSongAndGoesOut() {
        // B2b (§3.d): `stopAndArmNext`, ragione invariata.
        XCTAssertEqual(t(.alone, .linkStop(falseStart: false, engineRunning: true)),
                       T(.out(armed: nil), .stopAndArmNext, .directorStoppedWhileAlone))
    }

    func testAloneDirectorFalseStartStopsRearmsSameAndGoesOutD7bis() {
        // B2b (§3.d): `stopAndRearmSame`, ragione invariata.
        XCTAssertEqual(t(.alone, .linkStop(falseStart: true, engineRunning: true)),
                       T(.out(armed: nil), .stopAndRearmSame, .directorFalseStartWhileAlone))
    }

    func testAloneStaysAloneWhenDirectorHeardAgainD2() {
        XCTAssertEqual(t(.alone, .directorHeard(true, engineRunning: true)), T(.alone, .none))
        XCTAssertEqual(t(.alone, .directorHeard(false, engineRunning: true)), T(.alone, .none))
    }

    func testAloneOwnSongEndedGoesOutD2() {
        XCTAssertEqual(t(.alone, .ownSongEnded), T(.out(armed: nil), .none, .aloneSongEnded))
    }

    func testAloneMusicianStopStopsClosesTheSongAndGoesOut() {
        // B2b (§3.d): lo Stop a pressione della fascia DA SOLO.
        XCTAssertEqual(t(.alone, .musicianStop), T(.out(armed: nil), .stopAndArmNext, .musicianStop))
    }

    func testAloneIgnoresPlayAndArming() {
        XCTAssertEqual(t(.alone, .linkPlay(withinHalfBar: true)), T(.alone, .none))
        XCTAssertEqual(t(.alone, arming(2, heard: true, playing: false)), T(.alone, .none))
        XCTAssertEqual(t(.alone, arming(0, heard: false, playing: true)), T(.alone, .none))
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

    // MARK: - B2b (§3.b): i tre esiti dell'armamento — accettato, rifiutato, ignorato

    func testArmingAcceptedArmsAndAsksTheRunnerToArmTheChosenSong() {
        XCTAssertEqual(t(.out(armed: nil), arming(4, heard: true, playing: false)),
                       T(.out(armed: 4), .armSong(songIdx: 4)))
        XCTAssertEqual(t(.out(armed: nil), arming(0, heard: true, playing: false)),
                       T(.out(armed: 0), .armSong(songIdx: 0)))
    }

    func testArmingRefusedWhenDirectorNotHeardCarriesTheTappedSongR1() {
        XCTAssertEqual(t(.out(armed: nil), arming(4, heard: false, playing: false)),
                       T(.out(armed: nil), .none, .armRefusedNotHeard(chosen: 4)))
    }

    func testArmingRefusedWhenSessionPlayingCarriesTheTappedSongR1() {
        XCTAssertEqual(t(.out(armed: nil), arming(4, heard: true, playing: true)),
                       T(.out(armed: nil), .none, .armRefusedSessionPlaying(chosen: 4)))
    }

    func testArmingRefusedNotHeardWinsOverSessionPlaying() {
        XCTAssertEqual(t(.out(armed: nil), arming(4, heard: false, playing: true)),
                       T(.out(armed: nil), .none, .armRefusedNotHeard(chosen: 4)))
    }

    func testArmingRefusedAsksNothingOfTheRunner() {
        // Rifiutato: nessuna azione, il runner e la misura non si toccano.
        XCTAssertEqual(t(.out(armed: nil), arming(4, heard: false, playing: false)).action, .none)
        XCTAssertEqual(t(.out(armed: nil), arming(4, heard: true, playing: true)).action, .none)
        XCTAssertEqual(t(.out(armed: 2), arming(4, heard: false, playing: false)).action, .none)
    }

    func testArmingIgnoredInSyncAndAloneAsksNothingOfTheRunner() {
        // Un tocco arrivato mentre passa il Play del Direttore trova la macchina gia' IN SYNC:
        // ignorato — stato invariato, nessuna azione, nessuna ragione.
        XCTAssertEqual(t(.inSync(songClosed: false), arming(4, heard: true, playing: false)),
                       T(.inSync(songClosed: false), .none))
        XCTAssertEqual(t(.inSync(songClosed: true), arming(4, heard: true, playing: false)),
                       T(.inSync(songClosed: true), .none))
        XCTAssertEqual(t(.alone, arming(4, heard: true, playing: false)),
                       T(.alone, .none))
    }

    func testOnlyAnAcceptedArmingCarriesTheArmSongAction() {
        // La misura e il runner cambiano solo con `armSong`: nessun altro evento la produce.
        let events: [E] = [.linkPlay(withinHalfBar: true), .linkPlay(withinHalfBar: false),
                           .linkStop(falseStart: false, engineRunning: true),
                           .linkStop(falseStart: true, engineRunning: false),
                           .directorHeard(true, engineRunning: false),
                           .directorHeard(false, engineRunning: true),
                           .ownSongEnded, .musicianStop, .reset,
                           arming(4, heard: false, playing: false), arming(4, heard: true, playing: true)]
        let states: [S] = [.inSync(songClosed: false), .inSync(songClosed: true), .alone,
                           .out(armed: nil), .out(armed: 3)]
        for state in states {
            for event in events {
                if case .armSong = t(state, event).action {
                    XCTFail("armSong da \(state) con \(event)")
                }
            }
        }
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
        XCTAssertEqual(t(.out(armed: 4), arming(1, heard: true, playing: false)),
                       T(.out(armed: 1), .armSong(songIdx: 1)))
        XCTAssertEqual(t(.out(armed: 4), arming(1, heard: true, playing: true)),
                       T(.out(armed: nil), .none, .armRefusedSessionPlaying(chosen: 1)))
    }

    func testOutArmedIgnoresOwnSongEndedAndMusicianStop() {
        XCTAssertEqual(t(.out(armed: 4), .ownSongEnded), T(.out(armed: 4), .none))
        XCTAssertEqual(t(.out(armed: 4), .musicianStop), T(.out(armed: 4), .none))
    }

    // MARK: - Le tre righe della tabella del 2D

    func testDirectorStoppedWhileFollowerAloneStopsAndGoesOut() {
        let tr = t(.alone, .linkStop(falseStart: false, engineRunning: true))
        XCTAssertEqual(tr.action, .stopAndArmNext)
        XCTAssertEqual(tr.state, .out(armed: nil))
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
                           arming(0, heard: true, playing: false),
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

    func testTheOnlyArmingSourceIsRientra() {
        // B2b (A1): `startShow` e' uscito. Lo switch e' esaustivo su un caso solo: se una
        // sorgente rientrasse, questo test non compilerebbe.
        let source = FollowerArming.Source.rientra(songIdx: 5)
        var chosen = -1
        switch source {
        case .rientra(let songIdx):
            chosen = songIdx
        }
        XCTAssertEqual(chosen, 5)
    }
}
