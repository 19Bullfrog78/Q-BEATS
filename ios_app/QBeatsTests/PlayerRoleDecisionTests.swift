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

    // MARK: - A437 · PARTE 2 (seguito 2 di A437, §2 voce 2): il ruolo effettivo cambia

    /// Il ruolo effettivo cambia se il ruolo del player di prima e quello di dopo sono diversi: tutte le coppie (ruolo scelto,
    /// levetta) prima e dopo, contro la regola del ruolo.
    func testTheEffectiveRoleChangesWhenThePlayerRoleBeforeAndAfterDiffer() {
        let roles: [LinkMode] = [.standalone, .direttore, .collaborativa]
        for before in roles {
            for linkBefore in [false, true] {
                for after in roles {
                    for linkAfter in [false, true] {
                        let was = PlayerRoleDecision.playerRole(role: before, userLinkEnabled: linkBefore)
                        let now = PlayerRoleDecision.playerRole(role: after, userLinkEnabled: linkAfter)
                        XCTAssertEqual(PlayerRoleDecision.effectiveRoleChanges(roleBefore: before, userLinkEnabledBefore: linkBefore,
                                                                               roleAfter: after, userLinkEnabledAfter: linkAfter),
                                       was != now, "prima:\(before)/\(linkBefore) dopo:\(after)/\(linkAfter)")
                    }
                }
            }
        }
    }

    /// I casi del motore, a parole. Il cambio del ruolo scelto a levetta accesa cambia il ruolo effettivo; a levetta spenta no
    /// (da Solo a Solo). La levetta spenta: col ruolo scelto Direttore o Follower sì, col ruolo scelto Solo no. La levetta
    /// accesa: lo stesso al contrario.
    func testTheEffectiveRoleInTheThreeRoadsOfTheEngine() {
        // `applySettings`: il ruolo scelto prima e quello nuovo, con la levetta di adesso.
        XCTAssertTrue(PlayerRoleDecision.effectiveRoleChanges(roleBefore: .collaborativa, userLinkEnabledBefore: true,
                                                              roleAfter: .direttore, userLinkEnabledAfter: true), "da Follower a Direttore")
        XCTAssertTrue(PlayerRoleDecision.effectiveRoleChanges(roleBefore: .standalone, userLinkEnabledBefore: true,
                                                              roleAfter: .direttore, userLinkEnabledAfter: true), "da Solo a Direttore")
        XCTAssertFalse(PlayerRoleDecision.effectiveRoleChanges(roleBefore: .standalone, userLinkEnabledBefore: false,
                                                               roleAfter: .direttore, userLinkEnabledAfter: false),
                       "a levetta spenta il ruolo scelto cambia ma il player resta Solo")
        XCTAssertFalse(PlayerRoleDecision.effectiveRoleChanges(roleBefore: .direttore, userLinkEnabledBefore: false,
                                                               roleAfter: .collaborativa, userLinkEnabledAfter: false),
                       "da Solo a Solo")
        // La levetta spenta: il ruolo scelto, accesa prima e spenta dopo.
        XCTAssertTrue(PlayerRoleDecision.effectiveRoleChanges(roleBefore: .direttore, userLinkEnabledBefore: true,
                                                              roleAfter: .direttore, userLinkEnabledAfter: false))
        XCTAssertTrue(PlayerRoleDecision.effectiveRoleChanges(roleBefore: .collaborativa, userLinkEnabledBefore: true,
                                                              roleAfter: .collaborativa, userLinkEnabledAfter: false))
        XCTAssertFalse(PlayerRoleDecision.effectiveRoleChanges(roleBefore: .standalone, userLinkEnabledBefore: true,
                                                               roleAfter: .standalone, userLinkEnabledAfter: false))
        // La levetta accesa: spenta prima e accesa dopo.
        XCTAssertTrue(PlayerRoleDecision.effectiveRoleChanges(roleBefore: .direttore, userLinkEnabledBefore: false,
                                                              roleAfter: .direttore, userLinkEnabledAfter: true), "da Solo a Direttore")
        XCTAssertFalse(PlayerRoleDecision.effectiveRoleChanges(roleBefore: .standalone, userLinkEnabledBefore: false,
                                                               roleAfter: .standalone, userLinkEnabledAfter: true))
        // Niente cambia: niente.
        XCTAssertFalse(PlayerRoleDecision.effectiveRoleChanges(roleBefore: .direttore, userLinkEnabledBefore: true,
                                                               roleAfter: .direttore, userLinkEnabledAfter: true))
    }
}
