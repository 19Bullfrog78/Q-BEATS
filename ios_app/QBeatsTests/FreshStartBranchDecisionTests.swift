import XCTest

// === RIENTRO-P1 — banco del ramo dell'avvio fresco (banco Models) ===
// Cinque ingressi: il Follower entra sì/no × ruolo × Link dell'app acceso/spento × almeno
// un collegato × sessione che suona. Tre cose da provare:
//  1. a Link ACCESO la tabella è quella di sempre, riga per riga (attesi LETTERALI);
//  2. a Link SPENTO si va SEMPRE nel ramo standalone, qualunque cosa dica il contatore dei
//     collegati — è la riga nuova, nata dal giro G7 del collaudo del 17/09/2026;
//  3. il Follower deciso in testa a `start` entra comunque, qualunque siano gli altri ingressi.
// Il banco gira in CI su ogni push (`.github/workflows/ios_build.yml`,
// `xcodebuild test -scheme QBeatsTests`).

final class FreshStartBranchDecisionTests: XCTestCase {

    private let roles: [LinkMode] = [.standalone, .direttore, .collaborativa]

    private func decision(followerJoins: Bool = false,
                          role: LinkMode,
                          link: Bool,
                          connected: Bool,
                          playing: Bool) -> FreshStartBranchDecision {
        FreshStartBranchDecision(followerJoins: followerJoins,
                                 role: role,
                                 linkEnabled: link,
                                 anyPeerConnected: connected,
                                 sessionPlaying: playing)
    }

    // MARK: - 1 · Link acceso: la tabella di sempre, parola per parola

    func testLinkOnKeepsTheOldTableLiterally() {
        // (ruolo, collegato, sessione, esito atteso)
        let rows: [(LinkMode, Bool, Bool, FreshStartBranchDecision.Outcome)] = [
            (.standalone,    false, false, .standaloneOrDirector),
            (.standalone,    false, true,  .sharedJoin),
            (.standalone,    true,  false, .sharedJoin),
            (.standalone,    true,  true,  .sharedJoin),
            (.collaborativa, false, false, .standaloneOrDirector),
            (.collaborativa, false, true,  .sharedJoin),
            (.collaborativa, true,  false, .sharedJoin),
            (.collaborativa, true,  true,  .sharedJoin),
            (.direttore,     false, false, .standaloneOrDirector),
            (.direttore,     false, true,  .standaloneOrDirector),
            (.direttore,     true,  false, .standaloneOrDirector),
            (.direttore,     true,  true,  .standaloneOrDirector),
        ]
        for (role, connected, playing, expected) in rows {
            let d = decision(role: role, link: true, connected: connected, playing: playing)
            XCTAssertEqual(d.outcome, expected,
                           "Link acceso - ruolo:\(role) collegato:\(connected) sessione:\(playing)")
            XCTAssertFalse(d.linkOffOverridesStalePeers,
                           "a Link acceso la riga nuova non decide mai")
        }
    }

    // MARK: - 2 · Link spento: sempre standalone

    func testLinkOffAlwaysGoesStandalone() {
        for role in roles {
            for connected in [false, true] {
                for playing in [false, true] {
                    let d = decision(role: role, link: false, connected: connected, playing: playing)
                    XCTAssertEqual(d.outcome, .standaloneOrDirector,
                                   "Link spento - ruolo:\(role) collegato:\(connected) sessione:\(playing)")
                }
            }
        }
    }

    /// Il giro G7 del collaudo, alla lettera: ruolo Follower, Link spento dal pannello, il
    /// contatore dei collegati rimasto a 1, sessione ferma. Prima: ramo condiviso.
    func testG7StalePeerCounterWithLinkOffLiterally() {
        let d = decision(role: .collaborativa, link: false, connected: true, playing: false)
        XCTAssertEqual(d.outcome, .standaloneOrDirector)
        XCTAssertTrue(d.linkOffOverridesStalePeers)
    }

    /// La riga nuova «decide» solo dove la tabella di sempre avrebbe scelto il ramo
    /// condiviso: dove avrebbe scelto comunque lo standalone, il segnale per il log resta giù.
    func testOverrideFlagOnlyWhereTheOldTableWouldHaveShared() {
        // (ruolo, collegato, sessione, atteso linkOffOverridesStalePeers)
        let rows: [(LinkMode, Bool, Bool, Bool)] = [
            (.standalone,    false, false, false),
            (.standalone,    true,  false, true),
            (.standalone,    false, true,  true),
            (.standalone,    true,  true,  true),
            (.collaborativa, false, false, false),
            (.collaborativa, true,  false, true),
            (.direttore,     false, false, false),
            (.direttore,     true,  true,  false),
        ]
        for (role, connected, playing, expected) in rows {
            let d = decision(role: role, link: false, connected: connected, playing: playing)
            XCTAssertEqual(d.linkOffOverridesStalePeers, expected,
                           "Link spento - ruolo:\(role) collegato:\(connected) sessione:\(playing)")
        }
    }

    // MARK: - 3 · Il Follower che entra vince su tutto

    func testFollowerJoinWinsOverEveryOtherInput() {
        for role in roles {
            for link in [false, true] {
                for connected in [false, true] {
                    for playing in [false, true] {
                        let d = decision(followerJoins: true, role: role, link: link,
                                         connected: connected, playing: playing)
                        XCTAssertEqual(d.outcome, .followerJoin,
                                       "ruolo:\(role) link:\(link) collegato:\(connected) sessione:\(playing)")
                        XCTAssertFalse(d.linkOffOverridesStalePeers)
                    }
                }
            }
        }
    }
}
