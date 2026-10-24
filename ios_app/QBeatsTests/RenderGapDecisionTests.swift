import XCTest

// === A421 — banco della crisi da misuratore (`RenderGapDecision`, banco Models), mandato par. 2.1 U7 e U8 ===
// I 19 buchi del referto A419 (par. 3.2.b) e i cinque del 24/10 (906,1 · 835,4 · 783,7 · 254,5 · 108,8 ms), col ruolo che
// avevano; la soglia a 75 ms; il Direttore che segue già Link; fuori da una canzone; Follower e Solo solo riga; la matrice.

final class RenderGapDecisionTests: XCTestCase {

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]

    private func outcome(_ holeMs: Double, _ role: PlayerRole, show: Bool = true, song: Bool = true, running: Bool = true,
                         follows: Bool = false, silent: Bool = false) -> RenderGapOutcome {
        RenderGapDecision.outcome(holeSeconds: holeMs / 1000.0, playerRole: role, showOpen: show, songInProgress: song,
                                  engineRunning: running, followsLink: follows, silentInSong: silent)
    }

    func testTheThreshold() {
        XCTAssertEqual(RenderGapMeter.crisisThresholdSeconds, 0.075)
        XCTAssertEqual(RenderGapMeter.thresholdBuffers, 3, "la soglia della riga resta a tre buffer")
        XCTAssertEqual(outcome(74.9, .direttore), .followLink)
        XCTAssertEqual(outcome(75.0, .direttore), .crisis)
        XCTAssertEqual(outcome(75.1, .direttore), .crisis)
    }

    /// I 19 buchi del referto A419, par. 3.2.b, col ruolo del registro.
    func testTheNineteenHolesOfA419() {
        // Solo: R1 121,5 (tolta), R5 218,7 (aggiunta) e 108,0 (tolta): solo riga (la crisi del Solo arriva dalla notizia).
        for ms in [121.5, 218.7, 108.0] {
            XCTAssertEqual(outcome(ms, .solo), .lineOnly, "\(ms)")
        }
        // Direttore in canzone: R2 155,2 e 187,5; R4 circa 791 e 803 (19/10): crisi.
        for ms in [155.2, 187.5, 791.0, 803.0] {
            XCTAssertEqual(outcome(ms, .direttore), .crisis, "\(ms)")
        }
        // Follower senza notizia: R7 32,6 · 42,0; R6 34,3 · 33,7 · 41,1; R8 36,5 · 48,8 · 32,8 · 34,3 · 45,7 · 32,9 · 32,2: solo riga.
        for ms in [32.6, 42.0, 34.3, 33.7, 41.1, 36.5, 48.8, 32.8, 34.3, 45.7, 32.9, 32.2] {
            XCTAssertEqual(outcome(ms, .follower), .lineOnly, "\(ms)")
        }
    }

    /// I cinque buchi del 24/10: 906,1 sul Direttore (la cassa Bluetooth: crisi, è il caso dell'assert di 1,5253 battiti);
    /// 835,4 e 783,7 nel Solo (le cuffie col filo), 254,5 e 108,8 nel Solo (la cassa): solo riga.
    func testTheFiveHolesOfOctober24() {
        XCTAssertEqual(outcome(906.1, .direttore), .crisis)
        for ms in [835.4, 783.7, 254.5, 108.8] {
            XCTAssertEqual(outcome(ms, .solo), .lineOnly, "\(ms)")
        }
        // Gli stessi buchi sul Direttore in canzone sarebbero crisi tutti e cinque.
        for ms in [906.1, 835.4, 783.7, 254.5, 108.8] {
            XCTAssertEqual(outcome(ms, .direttore), .crisis, "\(ms)")
        }
    }

    /// Il Direttore che segue già Link (T4) con un buco da 75 ms in su va in crisi come gli altri (U7); sotto resta «segue
    /// Link».
    func testTheDirectorThatFollowsLinkStillGoesIntoCrisis() {
        XCTAssertEqual(outcome(906.1, .direttore, follows: true), .crisis)
        XCTAssertEqual(outcome(75.0, .direttore, follows: true), .crisis)
        XCTAssertEqual(outcome(48.8, .direttore, follows: true), .followLink)
    }

    /// Il Direttore muto in canzone col motore in moto (l'attesa del rientro): la stessa regola.
    func testTheSilentDirectorWithTheEngineRunning() {
        XCTAssertEqual(outcome(100.0, .direttore, silent: true), .crisis)
        XCTAssertEqual(outcome(40.0, .direttore, silent: true), .followLink)
    }

    /// Sotto la soglia col Direttore in canzone: segue Link (U8, la (iii) del referto A419).
    func testBelowTheThresholdTheDirectorFollowsLink() {
        for ms in [32.2, 48.8, 60.0, 74.99] {
            XCTAssertEqual(outcome(ms, .direttore), .followLink, "\(ms)")
        }
        XCTAssertEqual(RenderGapDecision.followLinkTrigger(showOpen: true, songInProgress: true), "buco-piccolo")
    }

    /// Fuori da una canzone (show chiuso, o click senza canzone): per ogni buco sopra la soglia della riga segue Link, mai
    /// una crisi (lì U7 non c'è).
    func testOutOfASongEveryHoleMakesTheDirectorFollowLink() {
        for (show, song) in [(false, false), (true, false), (false, true)] {
            for ms in [32.2, 75.0, 906.1] {
                XCTAssertEqual(outcome(ms, .direttore, show: show, song: song), .followLink, "show:\(show) canzone:\(song) \(ms)")
            }
            XCTAssertEqual(RenderGapDecision.followLinkTrigger(showOpen: show, songInProgress: song), "buco-fuori-canzone")
        }
    }

    /// Follower e Solo: solo riga, qualunque buco e qualunque stato.
    func testFollowerAndSoloAreLineOnly() {
        for role in [PlayerRole.follower, .solo] {
            for ms in [32.2, 75.0, 906.1, 5000.0] {
                for show in bools {
                    for song in bools {
                        for follows in bools {
                            XCTAssertEqual(outcome(ms, role, show: show, song: song, follows: follows), .lineOnly,
                                           "ruolo:\(role) \(ms) show:\(show) canzone:\(song)")
                        }
                    }
                }
            }
        }
    }

    /// A motore fermo niente (il misuratore non gira: entra per la matrice).
    func testEngineStoppedIsLineOnly() {
        XCTAssertEqual(outcome(906.1, .direttore, running: false), .lineOnly)
    }

    // MARK: - La matrice

    private func expected(_ holeMs: Double, _ role: PlayerRole, show: Bool, song: Bool, running: Bool) -> RenderGapOutcome {
        guard role == .direttore, running else { return .lineOnly }
        guard show && song else { return .followLink }
        return holeMs >= 75.0 ? .crisis : .followLink
    }

    func testTheMatrix() {
        var cells = 0
        for ms in [32.2, 74.9, 75.0, 906.1] {
            for role in roles {
                for show in bools {
                    for song in bools {
                        for running in bools {
                            for follows in bools {
                                for silent in bools {
                                    cells += 1
                                    let got = outcome(ms, role, show: show, song: song, running: running, follows: follows, silent: silent)
                                    let tag = "\(ms) ruolo:\(role) show:\(show) canzone:\(song) motore:\(running) segue:\(follows) muto:\(silent)"
                                    XCTAssertEqual(got, expected(ms, role, show: show, song: song, running: running), tag)
                                    // La crisi solo per il Direttore a show aperto con la canzone in corso e il motore in moto.
                                    if got == .crisis { XCTAssertTrue(role == .direttore && show && song && running, tag) }
                                }
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 4 * 3 * 2 * 2 * 2 * 2 * 2)
    }

    func testTheNamesInTheLines() {
        XCTAssertEqual(RenderGapOutcome.lineOnly.rawValue, "solo-riga")
        XCTAssertEqual(RenderGapOutcome.followLink.rawValue, "segue-link")
        XCTAssertEqual(RenderGapOutcome.crisis.rawValue, "crisi")
        XCTAssertEqual(RenderGapOutcome.allCases.count, 3)
    }
}
