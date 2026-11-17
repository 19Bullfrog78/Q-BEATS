import XCTest

// === A435 — banco della regola del tempo che combacia al Play dopo un conto non certo (banco Models) ===
// Mandato A435, par. 4 e, e il banco della parte 2: 120,9999 contro 121 combacia; 120,5 contro 124,5 no; i bordi del
// decimo; un tempo che non si sa non combacia; l'ingresso per la macchina del Follower.

final class BandTempoMatchDecisionTests: XCTestCase {

    private func matches(_ session: Double, _ song: Double?) -> Bool {
        BandTempoMatchDecision.matches(sessionBpm: session, songFirstBpm: song)
    }

    /// Il richiamo dell'01/11 portava 120,9999 per 121.
    func testTheCallbackOfTheFirstOfNovemberMatches() {
        XCTAssertTrue(matches(120.9999, 121.0))
        XCTAssertTrue(matches(121.0, 121.0))
    }

    func testAnotherSongDoesNotMatch() {
        XCTAssertFalse(matches(120.5, 124.5))
        XCTAssertFalse(matches(124.5, 120.5))
        XCTAssertFalse(matches(141.5, 131.5))
        XCTAssertFalse(matches(91.5, 121.5))
    }

    /// I bordi del decimo: un decimo esatto combacia (col margine della virgola mobile), un decimillesimo in più no.
    func testTheEdgesOfTheTenth() {
        XCTAssertEqual(BandTempoMatchDecision.toleranceBpm, 0.1)
        XCTAssertTrue(matches(121.1, 121.0))
        XCTAssertTrue(matches(120.9, 121.0))
        XCTAssertTrue(matches(101.4, 101.5))
        XCTAssertTrue(matches(101.6, 101.5))
        XCTAssertTrue(matches(121.0999, 121.0))
        // 60,1 − 60 in virgola mobile fa 0,10000000000000142: senza il margine del confronto non combacerebbe
        XCTAssertTrue(matches(60.1, 60.0))
        XCTAssertFalse(matches(121.1001, 121.0))
        XCTAssertFalse(matches(120.8999, 121.0))
        XCTAssertFalse(matches(121.2, 121.0))
    }

    /// Un tempo che non si sa, o non valido, non combacia: non si può dire che la canzone è la stessa.
    func testAnUnknownOrInvalidTempoDoesNotMatch() {
        XCTAssertFalse(matches(121.0, nil))
        XCTAssertFalse(matches(121.0, 0.0))
        XCTAssertFalse(matches(121.0, -121.0))
        XCTAssertFalse(matches(121.0, .nan))
        XCTAssertFalse(matches(121.0, .infinity))
        XCTAssertFalse(matches(0.0, 0.0))
        XCTAssertFalse(matches(.nan, 121.0))
        XCTAssertFalse(matches(.infinity, .infinity))
    }

    /// L'ingresso per la macchina: col segno basso il confronto non si fa, qualunque tempo.
    func testTheCheckForTheMachine() {
        XCTAssertEqual(BandTempoMatchDecision.check(uncertainSilence: false, sessionBpm: 124.5, songFirstBpm: 120.5),
                       .notAsked)
        XCTAssertEqual(BandTempoMatchDecision.check(uncertainSilence: false, sessionBpm: 0.0, songFirstBpm: nil),
                       .notAsked)
        XCTAssertEqual(BandTempoMatchDecision.check(uncertainSilence: true, sessionBpm: 120.9999, songFirstBpm: 121.0),
                       .matches)
        XCTAssertEqual(BandTempoMatchDecision.check(uncertainSilence: true, sessionBpm: 124.5, songFirstBpm: 120.5),
                       .differs)
        XCTAssertEqual(BandTempoMatchDecision.check(uncertainSilence: true, sessionBpm: 121.0, songFirstBpm: nil),
                       .differs)
    }

    /// La scaletta di prova del collaudo («COLLAUDO 3C-2 D» e «F»): la prima sezione di ogni canzone, Direttore
    /// contro Follower. Solo la 2 («2 Other tempo») non combacia.
    /// ⚠️ CORRETTO A435 · SEGUITO 3 (16/11/2026; seguito 3 di A435, par. 4): la 2 e la 3 della scaletta di prova si sono
    /// scambiate (`DebugView.loadTestDataCollaudo3C2`); qui c'era «Solo la 3 («3 Other tempo») non combacia», con le
    /// righe (2, 101.5, 101.5, true) e (3, 141.5, 131.5, false).
    func testTheFirstSectionsOfTheTestSetlist() {
        // (canzone, tempo del Direttore, tempo del Follower, combacia)
        let rows: [(Int, Double, Double, Bool)] = [
            (1, 121.5, 121.5, true),
            (2, 141.5, 131.5, false),
            (3, 101.5, 101.5, true),
            (4, 121.5, 121.5, true),
            (5, 161.5, 161.5, true),
            (6, 161.5, 161.5, true),
            (7, 180.5, 180.5, true),
        ]
        XCTAssertEqual(rows.count, 7)
        for (song, director, follower, expected) in rows {
            XCTAssertEqual(matches(director, follower), expected, "canzone \(song)")
        }
    }
}
