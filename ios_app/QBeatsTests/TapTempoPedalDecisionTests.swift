import XCTest

// === A435 — banco della regola del tap tempo del pedale a canzone in corso (banco Models) ===
// I sei casi del mandato A435, par. 2.2, attesi letterali: Direttore in canzone, Direttore muto in canzone, Direttore
// fermo, Solo in canzone, Solo fermo, Follower. Poi la tabella intera (ruolo × canzone × silenzio) e l'ingresso della
// spia.

final class TapTempoPedalDecisionTests: XCTestCase {

    private func decide(_ role: PlayerRole, inSong: Bool, silent: Bool = false) -> TapTempoPedalOutcome {
        TapTempoPedalDecision.decide(role: role, songInProgress: inSong, directorSilent: silent)
    }

    func testTheDirectorInASongIsIgnored() {
        XCTAssertEqual(decide(.direttore, inSong: true), .ignoredSongInProgress)
    }

    /// Il Direttore muto in canzone è in canzone.
    func testTheSilentDirectorInASongIsIgnored() {
        XCTAssertEqual(decide(.direttore, inSong: true, silent: true), .ignoredSongInProgress)
    }

    /// A click fermo come oggi, anche muto sul velo con la sessione ferma.
    func testTheStoppedDirectorTaps() {
        XCTAssertEqual(decide(.direttore, inSong: false), .taps)
        XCTAssertEqual(decide(.direttore, inSong: false, silent: true), .taps)
    }

    func testTheSoloInASongTapsAsToday() {
        XCTAssertEqual(decide(.solo, inSong: true), .taps)
    }

    func testTheStoppedSoloTapsAsToday() {
        XCTAssertEqual(decide(.solo, inSong: false), .taps)
    }

    func testTheFollowerIsIgnoredAsToday() {
        XCTAssertEqual(decide(.follower, inSong: true), .ignoredFollower)
        XCTAssertEqual(decide(.follower, inSong: false), .ignoredFollower)
    }

    /// La tabella intera, dodici righe: (ruolo, canzone in corso, silenzio, atteso).
    func testTheWholeTableLiterally() {
        let rows: [(PlayerRole, Bool, Bool, TapTempoPedalOutcome)] = [
            (.direttore, true,  false, .ignoredSongInProgress),
            (.direttore, true,  true,  .ignoredSongInProgress),
            (.direttore, false, false, .taps),
            (.direttore, false, true,  .taps),
            (.solo,      true,  false, .taps),
            (.solo,      true,  true,  .taps),
            (.solo,      false, false, .taps),
            (.solo,      false, true,  .taps),
            (.follower,  true,  false, .ignoredFollower),
            (.follower,  true,  true,  .ignoredFollower),
            (.follower,  false, false, .ignoredFollower),
            (.follower,  false, true,  .ignoredFollower),
        ]
        XCTAssertEqual(rows.count, 12)
        for (role, inSong, silent, expected) in rows {
            XCTAssertEqual(decide(role, inSong: inSong, silent: silent), expected,
                           "\(role) canzone:\(inSong) silenzio:\(silent)")
        }
    }

    /// Solo col Direttore la regola legge «canzone in corso»: per Solo e Follower l'esito è lo stesso con vero e con
    /// falso, quindi il motore può non leggerla (e passare falso) senza cambiare niente.
    func testOnlyTheDirectorReadsTheSongInProgress() {
        XCTAssertTrue(TapTempoPedalDecision.readsSongInProgress(role: .direttore))
        XCTAssertFalse(TapTempoPedalDecision.readsSongInProgress(role: .solo))
        XCTAssertFalse(TapTempoPedalDecision.readsSongInProgress(role: .follower))
        for role in [PlayerRole.solo, .follower] {
            for silent in [false, true] {
                XCTAssertEqual(decide(role, inSong: true, silent: silent), decide(role, inSong: false, silent: silent),
                               "\(role) silenzio:\(silent)")
            }
        }
        XCTAssertNotEqual(decide(.direttore, inSong: true), decide(.direttore, inSong: false))
    }

    /// L'ingresso della spia: il tap agisce solo quando l'esito è «agisce».
    func testTheTapActsOnlyWhenItTaps() {
        XCTAssertTrue(TapTempoPedalDecision.acts(.taps))
        XCTAssertFalse(TapTempoPedalDecision.acts(.ignoredSongInProgress))
        XCTAssertFalse(TapTempoPedalDecision.acts(.ignoredFollower))
    }
}
