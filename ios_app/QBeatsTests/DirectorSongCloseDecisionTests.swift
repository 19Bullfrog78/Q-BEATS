import XCTest

// === A386 · FASE B1 — banco della chiusura della canzone del Direttore (banco Models) ===
// D3 (ogni Stop a canzone in corso chiude la canzone, in Direttore), D7-bis (falsa partenza ->
// riarma la stessa), D4 (RIENTRA su qualsiasi indice, anche gia' suonato). Scaletta di tre
// canzoni (0, 1, 2), attesi letterali.

final class DirectorSongCloseDecisionTests: XCTestCase {

    private func onStop(role: LinkMode = .direttore, user: Bool = true,
                        inProgress: Bool = true, falseStart: Bool = false,
                        current: Int, count: Int = 3) -> DirectorSongCloseDecision.StopOutcome {
        DirectorSongCloseDecision.onStop(role: role, userLinkEnabled: user,
                                         songInProgress: inProgress, falseStart: falseStart,
                                         currentSongIdx: current, songCount: count)
    }

    // (ruolo, Link dell'utente, chiude allo Stop)
    private let roleRows: [(LinkMode, Bool, Bool)] = [
        (.standalone,    false, false),
        (.standalone,    true,  false),
        (.direttore,     false, false),
        (.direttore,     true,  true),
        (.collaborativa, false, false),
        (.collaborativa, true,  false),
    ]

    func testClosesSongOnStopTheSixRowsLiterally() {
        for (role, user, expected) in roleRows {
            XCTAssertEqual(DirectorSongCloseDecision.closesSongOnStop(role: role, userLinkEnabled: user),
                           expected, "ruolo:\(role) linkUtente:\(user)")
        }
    }

    func testDirectorStopMidSongClosesAndArmsTheNext() {
        XCTAssertEqual(onStop(current: 0), .closeAndArmNext(songIdx: 1))
        XCTAssertEqual(onStop(current: 1), .closeAndArmNext(songIdx: 2))
    }

    func testDirectorStopOnTheLastSongFinishesTheSetlist() {
        XCTAssertEqual(onStop(current: 2), .closeAndFinishSetlist)
    }

    func testDirectorFalseStartRearmsTheSameSongD7bis() {
        XCTAssertEqual(onStop(falseStart: true, current: 0), .rearmSame(songIdx: 0))
        XCTAssertEqual(onStop(falseStart: true, current: 2), .rearmSame(songIdx: 2))
    }

    func testStopWithNoSongInProgressDoesNothing() {
        XCTAssertEqual(onStop(inProgress: false, current: 0), .none)
        XCTAssertEqual(onStop(inProgress: false, falseStart: true, current: 0), .none)
    }

    func testSoloAndLinkOffDoNothing() {
        for (role, user, closes) in roleRows where !closes {
            XCTAssertEqual(onStop(role: role, user: user, current: 0), .none, "ruolo:\(role) linkUtente:\(user)")
            XCTAssertEqual(onStop(role: role, user: user, falseStart: true, current: 0), .none)
        }
    }

    func testInvalidIndicesDoNothing() {
        XCTAssertEqual(onStop(current: 3), .none)
        XCTAssertEqual(onStop(current: -1), .none)
        XCTAssertEqual(onStop(current: 0, count: 0), .none)
    }

    func testArmSongAcceptsAnyIndexOfTheCatalogEvenAlreadyPlayedD4() {
        XCTAssertEqual(DirectorSongCloseDecision.armSong(index: 0, songCount: 3), .arm(songIdx: 0))
        XCTAssertEqual(DirectorSongCloseDecision.armSong(index: 1, songCount: 3), .arm(songIdx: 1))
        XCTAssertEqual(DirectorSongCloseDecision.armSong(index: 2, songCount: 3), .arm(songIdx: 2))
    }

    func testArmSongRefusesOutOfRangeAndEmptyCatalog() {
        XCTAssertEqual(DirectorSongCloseDecision.armSong(index: 3, songCount: 3), .refuse)
        XCTAssertEqual(DirectorSongCloseDecision.armSong(index: -1, songCount: 3), .refuse)
        XCTAssertEqual(DirectorSongCloseDecision.armSong(index: 0, songCount: 0), .refuse)
    }
}
