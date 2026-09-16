import XCTest

// === A360 — banco della regola del Follower (banco Models) ===
// Quattro ingressi: ruolo × Link dell'utente × interruttore dell'app × almeno un
// collegato. Attesi LETTERALI, riga per riga, per le dodici combinazioni che contano
// (ruolo × utente × collegato); l'interruttore dell'app si prova a parte, ed è la
// prova che NON conta: andare in background e tornare non cambia il ruolo.
// Il banco gira in CI su ogni push (`.github/workflows/ios_build.yml`,
// `xcodebuild test -scheme QBeatsTests`).

final class FollowerDecisionTests: XCTestCase {

    private func decision(role: LinkMode,
                          user: Bool,
                          app: Bool = true,
                          connected: Bool = true) -> FollowerDecision {
        FollowerDecision(role: role,
                         userLinkEnabled: user,
                         appLinkEnabled: app,
                         anyPeerConnected: connected)
    }

    // MARK: - Le dodici righe: ruolo × Link dell'utente × collegato → (Follower, nessuno collegato)

    func testTheTwelveRowsLiterally() {
        // (ruolo, utente, collegato, atteso isFollower, atteso nobodyConnected)
        let rows: [(LinkMode, Bool, Bool, Bool, Bool)] = [
            (.standalone,    false, false, false, false),
            (.standalone,    false, true,  false, false),
            (.standalone,    true,  false, false, false),
            (.standalone,    true,  true,  false, false),
            (.direttore,     false, false, false, false),
            (.direttore,     false, true,  false, false),
            (.direttore,     true,  false, false, false),
            (.direttore,     true,  true,  false, false),
            (.collaborativa, false, false, false, false),
            (.collaborativa, false, true,  false, false),
            (.collaborativa, true,  false, true,  true),
            (.collaborativa, true,  true,  true,  false),
        ]
        XCTAssertEqual(rows.count, 12)
        for (role, user, connected, follower, nobody) in rows {
            let d = decision(role: role, user: user, connected: connected)
            XCTAssertEqual(d.isFollower, follower, "ruolo:\(role) utente:\(user) collegato:\(connected)")
            XCTAssertEqual(d.nobodyConnected, nobody, "ruolo:\(role) utente:\(user) collegato:\(connected)")
        }
    }

    // MARK: - L'interruttore dell'app non conta: background e ritorno

    func testAppSwitchNeverChangesTheDecision() {
        for role in [LinkMode.standalone, .direttore, .collaborativa] {
            for user in [false, true] {
                for connected in [false, true] {
                    let on  = decision(role: role, user: user, app: true,  connected: connected)
                    let off = decision(role: role, user: user, app: false, connected: connected)
                    XCTAssertEqual(on.isFollower, off.isFollower, "ruolo:\(role) utente:\(user) collegato:\(connected)")
                    XCTAssertEqual(on.nobodyConnected, off.nobodyConnected, "ruolo:\(role) utente:\(user) collegato:\(connected)")
                }
            }
        }
    }

    func testFollowerStaysFollowerWhileTheAppHasLinkOffInBackground() {
        // Sul palco: ruolo Follower, Link acceso dal pannello, l'app in background a click
        // fermo spegne il SUO interruttore. Al ritorno il velo deve dire ancora
        // «The director starts», non «Tap anywhere».
        let inBackground = decision(role: .collaborativa, user: true, app: false, connected: false)
        XCTAssertTrue(inBackground.isFollower)
        XCTAssertTrue(inBackground.nobodyConnected)
    }

    // MARK: - Link spento dall'utente = Solo, qualunque sia il ruolo scelto

    func testUserLinkOffIsSoloEvenWithFollowerRole() {
        let d = decision(role: .collaborativa, user: false, app: true, connected: true)
        XCTAssertFalse(d.isFollower)
        XCTAssertFalse(d.nobodyConnected)
    }

    // MARK: - «Nessuno collegato» è solo del Follower

    func testNobodyConnectedOnlyForAFollower() {
        XCTAssertFalse(decision(role: .direttore,  user: true, connected: false).nobodyConnected)
        XCTAssertFalse(decision(role: .standalone, user: true, connected: false).nobodyConnected)
        XCTAssertTrue(decision(role: .collaborativa, user: true, connected: false).nobodyConnected)
        XCTAssertFalse(decision(role: .collaborativa, user: true, connected: true).nobodyConnected)
    }

    // MARK: - La regola nuda coincide con l'istanza

    func testStaticRuleMatchesTheInstance() {
        for role in [LinkMode.standalone, .direttore, .collaborativa] {
            for user in [false, true] {
                let nuda = FollowerDecision.isFollower(role: role, userLinkEnabled: user)
                let piena = decision(role: role, user: user).isFollower
                XCTAssertEqual(nuda, piena, "ruolo:\(role) utente:\(user)")
            }
        }
        XCTAssertTrue(FollowerDecision.isFollower(role: .collaborativa, userLinkEnabled: true))
        XCTAssertFalse(FollowerDecision.isFollower(role: .collaborativa, userLinkEnabled: false))
        XCTAssertFalse(FollowerDecision.isFollower(role: .direttore, userLinkEnabled: true))
    }

    // MARK: - Gli ingressi restano leggibili (per la strumentazione)

    func testInputsAreKept() {
        let d = decision(role: .collaborativa, user: true, app: false, connected: true)
        XCTAssertEqual(d.role, .collaborativa)
        XCTAssertTrue(d.userLinkEnabled)
        XCTAssertFalse(d.appLinkEnabled)
        XCTAssertTrue(d.anyPeerConnected)
    }
}
