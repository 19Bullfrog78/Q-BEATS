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

    // MARK: - A435 · la (b): il Play dopo un conto non certo (mandato A435, par. 4 e)

    private let everyState: [S] = [.inSync(songClosed: false), .inSync(songClosed: true), .alone,
                                   .out(armed: nil), .out(armed: 3)]

    /// Col segno basso (`.notAsked`) e col tempo che combacia il Play vale come sempre, da ogni stato.
    func testAPlayWithTheTempoMatchingOrNotAskedIsThePlayOfToday() {
        for state in everyState {
            for within in [false, true] {
                let today = t(state, .linkPlay(withinHalfBar: within))
                XCTAssertEqual(t(state, .linkPlay(withinHalfBar: within, tempo: .notAsked)), today,
                               "\(state) \(within)")
                XCTAssertEqual(t(state, .linkPlay(withinHalfBar: within, tempo: .matches)), today,
                               "\(state) \(within)")
            }
        }
    }

    /// IN SYNC, entro mezza battuta, il tempo non combacia: nessun avvio, si resta IN SYNC con la canzone aperta.
    /// ⚠️ CORRETTO A435 · SEGUITO 3 (16/11/2026; seguito 3 di A435, par. 2): l'azione attesa era `.none`; da qui è
    /// `.openSong`, perché la canzone si apra anche sul runner (se no lo Stop dopo non lo fa avanzare).
    func testInSyncAPlayWithTheTempoDifferingDoesNotStartAndKeepsTheSongOpen() {
        for closed in [false, true] {
            XCTAssertEqual(t(.inSync(songClosed: closed), .linkPlay(withinHalfBar: true, tempo: .differs)),
                           T(.inSync(songClosed: false), .openSong), "\(closed)")
        }
    }

    /// Poi lo Stop del Direttore (motore fermo, nessuna falsa partenza) arma la successiva; al Play dopo col tempo che
    /// combacia si parte; con un altro Play che non combacia di nuovo niente, e lo Stop arma di nuovo la successiva.
    /// ⚠️ CORRETTO A435 · SEGUITO 3 (seguito 3 di A435, par. 2): le due azioni attese del Play che non combacia erano
    /// `.none`; da qui sono `.openSong`. Il resto del caso com'era.
    func testAfterAPlayThatDidNotMatchTheStopArmsTheNextSongAndTheNextMatchingPlayStarts() {
        let refused = t(.inSync(songClosed: true), .linkPlay(withinHalfBar: true, tempo: .differs))
        XCTAssertEqual(refused.action, .openSong)
        let stopped = t(refused.state, .linkStop(falseStart: false, engineRunning: false))
        XCTAssertEqual(stopped, T(.inSync(songClosed: true), .armNext))
        XCTAssertEqual(t(stopped.state, .linkPlay(withinHalfBar: true, tempo: .matches)),
                       T(.inSync(songClosed: false), .start))
        let again = t(stopped.state, .linkPlay(withinHalfBar: true, tempo: .differs))
        XCTAssertEqual(again, T(.inSync(songClosed: false), .openSong))
        XCTAssertEqual(t(again.state, .linkStop(falseStart: false, engineRunning: false)),
                       T(.inSync(songClosed: true), .armNext))
    }

    // MARK: - A435 · SEGUITO 3: l'apertura della canzone senza avvio (seguito 3 di A435, par. 2 e 3)

    /// L'azione `.openSong` esce SOLO dal Play IN SYNC, entro mezza battuta, col tempo che non combacia: da nessun
    /// altro stato, per nessun altro confronto, e mai da un Play oltre mezza battuta. Da FUORI armato il Play che non
    /// combacia resta senza azione (lo Stop lì non tocca niente).
    func testOnlyTheInSyncPlayWithinHalfABarThatDoesNotMatchOpensTheSong() {
        for state in everyState {
            for within in [false, true] {
                for tempo in [FollowerPlayTempo.notAsked, .matches, .differs] {
                    var inSync = false
                    if case .inSync = state { inSync = true }
                    let opens = inSync && within && tempo == .differs
                    let action = t(state, .linkPlay(withinHalfBar: within, tempo: tempo)).action
                    XCTAssertEqual(action == .openSong, opens, "\(state) \(within) \(tempo)")
                }
            }
        }
        // nessun altro evento apre la canzone
        let others: [E] = [.linkStop(falseStart: false, engineRunning: false),
                           .linkStop(falseStart: true, engineRunning: false),
                           .linkStop(falseStart: false, engineRunning: true),
                           .directorHeard(false, engineRunning: false), .directorHeard(true, engineRunning: false),
                           .ownSongEnded, .musicianStop, arming(2, heard: true, playing: false), .reset]
        for state in everyState {
            for event in others {
                XCTAssertNotEqual(t(state, event).action, .openSong, "\(state) \(event)")
            }
        }
    }

    /// La falsa partenza del Direttore dopo un Play che non combacia (D7-bis: «in tutte le canzoni»): lo Stop entro
    /// la prima battuta riarma la STESSA canzone; poi di nuovo il Play che non combacia, e lo Stop dopo la prima
    /// battuta arma la successiva. Un secondo Stop non avanza un'altra volta.
    func testAfterAPlayThatDidNotMatchAFalseStartRearmsTheSameSongAndTheLaterStopArmsTheNext() {
        let refused = t(.inSync(songClosed: true), .linkPlay(withinHalfBar: true, tempo: .differs))
        let falseStart = t(refused.state, .linkStop(falseStart: true, engineRunning: false))
        XCTAssertEqual(falseStart, T(.inSync(songClosed: true), .rearmSame))
        let again = t(falseStart.state, .linkPlay(withinHalfBar: true, tempo: .differs))
        XCTAssertEqual(again, T(.inSync(songClosed: false), .openSong))
        let stopped = t(again.state, .linkStop(falseStart: false, engineRunning: false))
        XCTAssertEqual(stopped, T(.inSync(songClosed: true), .armNext))
        XCTAssertEqual(t(stopped.state, .linkStop(falseStart: false, engineRunning: false)),
                       T(.inSync(songClosed: true), .none))
    }

    /// Dopo una canzone aperta senza avvio le uscite sono quelle di sempre: il Direttore perso a motore fermo porta
    /// FUORI senza azioni sul runner (D1); il reset porta FUORI senza azioni; un armamento in IN SYNC non cambia
    /// niente; lo Stop del musicista (nessuna porta lo manda in IN SYNC) chiude la canzone come sempre.
    func testAfterTheSongIsOpenedWithoutAStartTheExitsAreTheOnesOfToday() {
        let opened = t(.inSync(songClosed: true), .linkPlay(withinHalfBar: true, tempo: .differs)).state
        XCTAssertEqual(opened, .inSync(songClosed: false))
        XCTAssertEqual(t(opened, .directorHeard(false, engineRunning: false)),
                       T(.out(armed: nil), .none, .lostWhileStopped))
        XCTAssertEqual(t(opened, .directorHeard(true, engineRunning: false)), T(opened, .none))
        XCTAssertEqual(t(opened, .reset), T(.out(armed: nil), .none, .reset))
        XCTAssertEqual(t(opened, arming(2, heard: true, playing: false)), T(opened, .none))
        XCTAssertEqual(t(opened, .musicianStop), T(.out(armed: nil), .stopAndArmNext, .musicianStop))
        // da FUORI, dopo il Direttore perso: lo Stop non tocca niente, e si rientra solo armandosi
        let out = t(opened, .directorHeard(false, engineRunning: false)).state
        XCTAssertEqual(t(out, .linkStop(falseStart: false, engineRunning: false)), T(.out(armed: nil), .none))
        XCTAssertEqual(t(out, arming(2, heard: true, playing: false)), T(.out(armed: 2), .armSong(songIdx: 2)))
        for falseStart in [false, true] {
            XCTAssertEqual(t(.out(armed: 2), .linkStop(falseStart: falseStart, engineRunning: false)),
                           T(.out(armed: 2), .none), "\(falseStart)")
        }
    }

    /// Da FUORI armato col tempo che non combacia resta armato, senza avvio; non armato resta com'è.
    func testOutArmedAPlayWithTheTempoDifferingStaysArmed() {
        XCTAssertEqual(t(.out(armed: 4), .linkPlay(withinHalfBar: true, tempo: .differs)), T(.out(armed: 4), .none))
        XCTAssertEqual(t(.out(armed: nil), .linkPlay(withinHalfBar: true, tempo: .differs)),
                       T(.out(armed: nil), .none))
        XCTAssertEqual(t(.out(armed: 4), .linkPlay(withinHalfBar: true, tempo: .matches)),
                       T(.inSync(songClosed: false), .start))
    }

    /// Il Play oltre mezza battuta va dove va oggi, qualunque sia il confronto; in DA SOLO un Play non cambia niente.
    func testALatePlayGoesWhereItGoesTodayWhateverTheTempo() {
        for tempo in [FollowerPlayTempo.notAsked, .matches, .differs] {
            XCTAssertEqual(t(.inSync(songClosed: false), .linkPlay(withinHalfBar: false, tempo: tempo)),
                           T(.out(armed: nil), .none, .playLate), "\(tempo)")
            XCTAssertEqual(t(.out(armed: 4), .linkPlay(withinHalfBar: false, tempo: tempo)),
                           T(.out(armed: nil), .none, .playLate), "\(tempo)")
            XCTAssertEqual(t(.alone, .linkPlay(withinHalfBar: true, tempo: tempo)), T(.alone, .none), "\(tempo)")
        }
    }

    /// Il motore scrive la riga «play dopo un non certo» solo quando il Play farebbe partire l'iPad.
    func testAPlayWouldStartOnlyInSyncOrArmedWithinHalfABar() {
        XCTAssertTrue(FollowerSyncDecision.playWouldStart(state: .inSync(songClosed: false), withinHalfBar: true))
        XCTAssertTrue(FollowerSyncDecision.playWouldStart(state: .inSync(songClosed: true), withinHalfBar: true))
        XCTAssertTrue(FollowerSyncDecision.playWouldStart(state: .out(armed: 2), withinHalfBar: true))
        XCTAssertFalse(FollowerSyncDecision.playWouldStart(state: .out(armed: nil), withinHalfBar: true))
        XCTAssertFalse(FollowerSyncDecision.playWouldStart(state: .alone, withinHalfBar: true))
        for state in everyState {
            XCTAssertFalse(FollowerSyncDecision.playWouldStart(state: state, withinHalfBar: false), "\(state)")
        }
    }
}
