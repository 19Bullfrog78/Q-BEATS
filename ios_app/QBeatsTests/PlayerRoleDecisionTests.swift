import XCTest

// === A394 · SOLO-G1-PEZZO-1-M1 — banco della regola del ruolo del player (banco Models) ===
// I tre ruoli con Link dell'utente acceso e spento, attesi letterali; l'interruttore dell'app non
// conta; la regola composta coincide con le due regole di oggi (Follower, Direttore).

final class PlayerRoleDecisionTests: XCTestCase {

    // (ruolo, Link dell'utente, atteso)
    private let rows: [(LinkMode, Bool, PlayerRole)] = [
        (.standalone,    false, .solo),
        (.standalone,    true,  .solo),
        (.direttore,     false, .solo),
        (.direttore,     true,  .direttore),
        (.collaborativa, false, .solo),
        (.collaborativa, true,  .follower),
    ]

    func testTheSixRowsLiterally() {
        XCTAssertEqual(rows.count, 6)
        for (role, user, expected) in rows {
            XCTAssertEqual(PlayerRoleDecision.playerRole(role: role, userLinkEnabled: user), expected,
                           "ruolo:\(role) linkUtente:\(user)")
        }
    }

    func testUserLinkOffIsSoloForEveryRole() {
        for role in [LinkMode.standalone, .direttore, .collaborativa] {
            XCTAssertEqual(PlayerRoleDecision.playerRole(role: role, userLinkEnabled: false), .solo, "ruolo:\(role)")
        }
    }

    func testAppSwitchNeverChangesTheRole() {
        for (role, user, expected) in rows {
            let on  = PlayerRoleDecision(role: role, userLinkEnabled: user, appLinkEnabled: true)
            let off = PlayerRoleDecision(role: role, userLinkEnabled: user, appLinkEnabled: false)
            XCTAssertEqual(on.playerRole, expected, "ruolo:\(role) linkUtente:\(user) app acceso")
            XCTAssertEqual(off.playerRole, expected, "ruolo:\(role) linkUtente:\(user) app spento")
        }
    }

    func testFollowerInBackgroundWithAppLinkOffStaysFollower() {
        // Sfondo a click fermo: l'app spegne il SUO interruttore, l'utente ha Link acceso.
        let d = PlayerRoleDecision(role: .collaborativa, userLinkEnabled: true, appLinkEnabled: false)
        XCTAssertEqual(d.playerRole, .follower)
    }

    func testDirectorInBackgroundWithAppLinkOffStaysDirector() {
        let d = PlayerRoleDecision(role: .direttore, userLinkEnabled: true, appLinkEnabled: false)
        XCTAssertEqual(d.playerRole, .direttore)
    }

    func testComposedRuleMatchesTheTwoRulesOfToday() {
        for role in [LinkMode.standalone, .direttore, .collaborativa] {
            for user in [false, true] {
                let r = PlayerRoleDecision.playerRole(role: role, userLinkEnabled: user)
                XCTAssertEqual(r == .follower,
                               FollowerDecision.isFollower(role: role, userLinkEnabled: user),
                               "ruolo:\(role) linkUtente:\(user)")
                XCTAssertEqual(r == .direttore,
                               DirectorSongCloseDecision.closesSongOnStop(role: role, userLinkEnabled: user),
                               "ruolo:\(role) linkUtente:\(user)")
            }
        }
    }

    func testInputsAreKept() {
        let d = PlayerRoleDecision(role: .direttore, userLinkEnabled: true, appLinkEnabled: false)
        XCTAssertEqual(d.role, .direttore)
        XCTAssertTrue(d.userLinkEnabled)
        XCTAssertFalse(d.appLinkEnabled)
        XCTAssertEqual(d.playerRole, .direttore)
    }
}
