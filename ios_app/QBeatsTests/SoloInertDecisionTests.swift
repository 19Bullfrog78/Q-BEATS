import XCTest

// === A411 · SOLO-INERTE — banco del lucchetto del motore e delle facce del Solo (banco Models) ===
// §2.4: il lucchetto, ruolo × levetta, atteso LETTERALE; poi, su ogni strada, «Solo con Link acceso» uguale
// a «Solo con Link spento». Il modello di «Link spento» è quello del ponte di oggi, scritto qui nel banco:
// a Link spento le scritture escono senza scrivere (guardia `enabled_`) e i richiami non arrivano; quindi
// su una strada il motore usa Link solo se Link è acceso E il lucchetto la lascia passare. Per Direttore e
// Follower il lucchetto non tocca niente. Poi la composizione vera con l'avvio fresco
// (`FreshStartBranchDecision`): nel Solo, Link acceso o spento, sempre il ramo standalone.
// §2.5: le facce — spia «Link» e striscia, badge, menu Mode — righe letterali.
// §2.7: la riga del lucchetto a frequenza limitata.

final class SoloInertDecisionTests: XCTestCase {

    private let roles: [LinkMode] = [.standalone, .direttore, .collaborativa]
    private let bools = [false, true]

    // MARK: - §2.4 · Il lucchetto

    // (ruolo, levetta, inerte)
    private let lockRows: [(LinkMode, Bool, Bool)] = [
        (.standalone,    false, true),
        (.standalone,    true,  true),
        (.direttore,     false, true),
        (.direttore,     true,  false),
        (.collaborativa, false, true),
        (.collaborativa, true,  false),
    ]

    func testTheSixLockRowsLiterally() {
        XCTAssertEqual(lockRows.count, 6)
        for (role, user, inert) in lockRows {
            XCTAssertEqual(SoloInertDecision.isInert(role: role, userLinkEnabled: user), inert,
                           "ruolo:\(role) levetta:\(user)")
        }
    }

    /// «Solo» è il ruolo del player della regola di oggi (A394), niente di più e niente di meno.
    func testInertIsExactlyThePlayerRoleSolo() {
        for role in roles {
            for user in bools {
                XCTAssertEqual(SoloInertDecision.isInert(role: role, userLinkEnabled: user),
                               PlayerRoleDecision.playerRole(role: role, userLinkEnabled: user) == .solo,
                               "ruolo:\(role) levetta:\(user)")
            }
        }
    }

    /// Una regola sola: ogni strada legge lo stesso lucchetto.
    func testEveryPathReadsTheSameLock() {
        XCTAssertEqual(SoloInertDecision.Path.allCases.count, 9)
        for path in SoloInertDecision.Path.allCases {
            for role in roles {
                for user in bools {
                    XCTAssertEqual(SoloInertDecision.passes(path, role: role, userLinkEnabled: user),
                                   !SoloInertDecision.isInert(role: role, userLinkEnabled: user),
                                   "strada:\(path.rawValue) ruolo:\(role) levetta:\(user)")
                }
            }
        }
    }

    /// Il modello del ponte di oggi: su una strada il motore usa Link se Link è acceso e il lucchetto passa.
    private func engineUsesLink(_ path: SoloInertDecision.Path, role: LinkMode, user: Bool, linkActive: Bool) -> Bool {
        linkActive && SoloInertDecision.passes(path, role: role, userLinkEnabled: user)
    }

    /// Il banco del mandato: su ogni strada, «Solo con Link acceso» uguale a «Solo con Link spento».
    func testOnEveryPathSoloWithLinkOnEqualsSoloWithLinkOff() {
        for path in SoloInertDecision.Path.allCases {
            for (role, user, inert) in lockRows where inert {
                let on = engineUsesLink(path, role: role, user: user, linkActive: true)
                let off = engineUsesLink(path, role: role, user: user, linkActive: false)
                XCTAssertEqual(on, off, "strada:\(path.rawValue) ruolo:\(role) levetta:\(user)")
                XCTAssertFalse(on, "strada:\(path.rawValue) ruolo:\(role) levetta:\(user)")
            }
        }
    }

    /// Direttore e Follower: il lucchetto non tocca niente, Link acceso passa su ogni strada come oggi.
    func testDirectorAndFollowerPassEveryPathAsToday() {
        for path in SoloInertDecision.Path.allCases {
            for role in [LinkMode.direttore, .collaborativa] {
                XCTAssertTrue(SoloInertDecision.passes(path, role: role, userLinkEnabled: true),
                              "strada:\(path.rawValue) ruolo:\(role)")
                XCTAssertTrue(engineUsesLink(path, role: role, user: true, linkActive: true),
                              "strada:\(path.rawValue) ruolo:\(role)")
                XCTAssertFalse(engineUsesLink(path, role: role, user: true, linkActive: false),
                               "strada:\(path.rawValue) ruolo:\(role) - a ponte spento, come oggi")
            }
        }
    }

    /// L'interruttore come lo legge il motore: quello del ponte, spento nel Solo.
    func testEngineSeesLinkOnRows() {
        for role in roles {
            for user in bools {
                for active in bools {
                    let inert = SoloInertDecision.isInert(role: role, userLinkEnabled: user)
                    XCTAssertEqual(SoloInertDecision.engineSeesLinkOn(role: role, userLinkEnabled: user, linkActive: active),
                                   active && !inert,
                                   "ruolo:\(role) levetta:\(user) ponte:\(active)")
                }
            }
        }
        XCTAssertFalse(SoloInertDecision.engineSeesLinkOn(role: .standalone, userLinkEnabled: true, linkActive: true))
        XCTAssertTrue(SoloInertDecision.engineSeesLinkOn(role: .direttore, userLinkEnabled: true, linkActive: true))
        XCTAssertFalse(SoloInertDecision.engineSeesLinkOn(role: .direttore, userLinkEnabled: true, linkActive: false))
    }

    /// La composizione vera con l'avvio fresco (A364 P1 c): nel Solo, Link acceso o spento, qualunque cosa
    /// dicano i peer e la sessione, il ramo è lo standalone — quello del Solo a Link spento.
    func testFreshStartOfTheSoloIsTheStandaloneBranchWithLinkOnOrOff() {
        for (role, user, inert) in lockRows where inert {
            for peers in bools {
                for playing in bools {
                    let branchOn = FreshStartBranchDecision(
                        followerJoins: false, role: role,
                        linkEnabled: SoloInertDecision.engineSeesLinkOn(role: role, userLinkEnabled: user, linkActive: true),
                        anyPeerConnected: peers, sessionPlaying: playing)
                    let branchOff = FreshStartBranchDecision(
                        followerJoins: false, role: role,
                        linkEnabled: SoloInertDecision.engineSeesLinkOn(role: role, userLinkEnabled: user, linkActive: false),
                        anyPeerConnected: peers, sessionPlaying: playing)
                    XCTAssertEqual(branchOn, branchOff, "ruolo:\(role) levetta:\(user) peer:\(peers) sessione:\(playing)")
                    XCTAssertEqual(branchOn.outcome, .standaloneOrDirector,
                                   "ruolo:\(role) levetta:\(user) peer:\(peers) sessione:\(playing)")
                }
            }
        }
    }

    /// Per Direttore e Follower l'interruttore che arriva all'avvio fresco è quello del ponte, come oggi.
    func testFreshStartOfDirectorAndFollowerIsUnchanged() {
        for role in [LinkMode.direttore, .collaborativa] {
            for active in bools {
                for peers in bools {
                    for playing in bools {
                        let today = FreshStartBranchDecision(followerJoins: false, role: role, linkEnabled: active,
                                                             anyPeerConnected: peers, sessionPlaying: playing)
                        let now = FreshStartBranchDecision(
                            followerJoins: false, role: role,
                            linkEnabled: SoloInertDecision.engineSeesLinkOn(role: role, userLinkEnabled: true, linkActive: active),
                            anyPeerConnected: peers, sessionPlaying: playing)
                        XCTAssertEqual(now, today, "ruolo:\(role) ponte:\(active) peer:\(peers) sessione:\(playing)")
                    }
                }
            }
        }
    }

    /// I nomi delle strade, come escono nella riga di registro.
    func testPathNamesForTheLog() {
        let names = SoloInertDecision.Path.allCases.map { $0.rawValue }
        XCTAssertEqual(names, ["tempo-dalla-sessione", "avvio-stop-dalla-sessione", "correzione-di-fase",
                               "avvio-verso-link", "tempo-verso-link", "tempo-al-confine-verso-link",
                               "stop-verso-link", "probe-con-commit", "interruttore-del-ponte"])
        XCTAssertEqual(Set(names).count, names.count)
    }

    // MARK: - §2.5 · Le facce

    // (ruolo, levetta, ingresso della spia)
    private let lightRows: [(LinkMode, Bool, Bool)] = [
        (.standalone,    false, false),
        (.standalone,    true,  false),
        (.direttore,     false, false),
        (.direttore,     true,  true),
        (.collaborativa, false, false),
        (.collaborativa, true,  true),
    ]

    func testStatusLightsInputRowsLiterally() {
        for (role, user, expected) in lightRows {
            XCTAssertEqual(SoloInertDecision.statusLightsUserLinkEnabled(role: role, userLinkEnabled: user), expected,
                           "ruolo:\(role) levetta:\(user)")
        }
    }

    /// Nel Solo la riga di stato è quella di Link spento: niente spia «Link», niente striscia, anche con Link
    /// visto e perso nello show; Wi-Fi e MIDI uguali a Link spento.
    func testSoloStatusRowEqualsTheLinkOffRow() {
        let memories: [ShowConnectionMemory] = [
            .none,
            ShowConnectionMemory(linkSeen: true, wifiSeen: true, midiSeen: true),
            ShowConnectionMemory(linkSeen: true, wifiSeen: false, midiSeen: false),
        ]
        for memory in memories {
            for linkConnected in bools {
                for wifi in bools {
                    for midi in bools {
                        let solo = StatusLightsDecision.lights(
                            linkUserEnabled: SoloInertDecision.statusLightsUserLinkEnabled(role: .standalone, userLinkEnabled: true),
                            linkConnected: linkConnected, wifiConnected: wifi, midiConnected: midi, memory: memory)
                        let linkOff = StatusLightsDecision.lights(
                            linkUserEnabled: false,
                            linkConnected: linkConnected, wifiConnected: wifi, midiConnected: midi, memory: memory)
                        XCTAssertEqual(solo, linkOff, "collegato:\(linkConnected) wifi:\(wifi) midi:\(midi) ricordo:\(memory)")
                        XCTAssertNil(solo.link)
                        XCTAssertNil(solo.strip)
                    }
                }
            }
        }
    }

    /// Direttore e Follower passano la levetta com'è: la regola della spia resta quella di oggi.
    func testDirectorAndFollowerPassTheUserSwitchToTheLights() {
        for role in [LinkMode.direttore, .collaborativa] {
            for user in bools {
                XCTAssertEqual(SoloInertDecision.statusLightsUserLinkEnabled(role: role, userLinkEnabled: user), user,
                               "ruolo:\(role) levetta:\(user)")
            }
        }
        let lost = StatusLightsDecision.lights(
            linkUserEnabled: SoloInertDecision.statusLightsUserLinkEnabled(role: .direttore, userLinkEnabled: true),
            linkConnected: false, wifiConnected: true, midiConnected: false,
            memory: ShowConnectionMemory(linkSeen: true, wifiSeen: true, midiSeen: false))
        XCTAssertEqual(lost.link, .lost)
        XCTAssertEqual(lost.strip, StatusLightsDecision.linkLostStrip)
    }

    // (ruolo, levetta, Link in rete, badge)
    private let badgeRows: [(LinkMode, Bool, Bool, Bool)] = [
        (.standalone,    false, false, false),
        (.standalone,    false, true,  false),
        (.standalone,    true,  false, false),
        (.standalone,    true,  true,  false),
        (.direttore,     false, false, false),
        (.direttore,     false, true,  false),
        (.direttore,     true,  false, false),
        (.direttore,     true,  true,  true),
        (.collaborativa, false, false, false),
        (.collaborativa, false, true,  false),
        (.collaborativa, true,  false, false),
        (.collaborativa, true,  true,  true),
    ]

    func testRoleBadgeRowsLiterally() {
        XCTAssertEqual(badgeRows.count, 12)
        for (role, user, active, expected) in badgeRows {
            XCTAssertEqual(SoloInertDecision.roleBadgeVisible(role: role, userLinkEnabled: user, linkActive: active), expected,
                           "ruolo:\(role) levetta:\(user) rete:\(active)")
        }
    }

    /// Per Direttore e Follower il badge è lo specchio `linkEnabled` di sempre.
    func testRoleBadgeOfDirectorAndFollowerIsTheMirrorAsToday() {
        for role in [LinkMode.direttore, .collaborativa] {
            for active in bools {
                XCTAssertEqual(SoloInertDecision.roleBadgeVisible(role: role, userLinkEnabled: true, linkActive: active), active,
                               "ruolo:\(role) rete:\(active)")
            }
        }
    }

    // (levetta, specchio dell'accensione, menu)
    private let menuRows: [(Bool, Bool, Bool)] = [
        (false, false, false),
        (false, true,  false),
        (true,  false, true),
        (true,  true,  true),
    ]

    func testModeMenuRowsLiterally() {
        for (user, app, expected) in menuRows {
            XCTAssertEqual(SoloInertDecision.modeMenuVisible(userLinkEnabled: user, appLinkEnabled: app), expected,
                           "levetta:\(user) specchio:\(app)")
        }
    }

    /// L'eccezione voluta del §2.5: in Solo a levetta accesa l'accensione è spenta (regola del §2.2), e il
    /// menu c'è lo stesso — con la condizione di prima (lo specchio) sarebbe sparito e Director non si
    /// potrebbe più scegliere.
    func testModeMenuStaysInSoloWithTheUserSwitchOn() {
        let appSwitch = LinkActivationDecision(userLinkEnabled: true, role: .standalone,
                                               backgroundSuspended: false, appTerminating: false).active
        XCTAssertFalse(appSwitch)
        XCTAssertTrue(SoloInertDecision.modeMenuVisible(userLinkEnabled: true, appLinkEnabled: appSwitch))
        for role in [LinkMode.direttore, .collaborativa] {
            let active = LinkActivationDecision(userLinkEnabled: true, role: role,
                                                backgroundSuspended: false, appTerminating: false).active
            XCTAssertEqual(SoloInertDecision.modeMenuVisible(userLinkEnabled: true, appLinkEnabled: active), active,
                           "ruolo:\(role) - in primo piano come oggi")
        }
    }

    // MARK: - §2.7 · La riga del lucchetto a frequenza limitata

    func testFirstDiscardIsWrittenAtOnce() {
        var log = SoloInertDiscardLog.start
        XCTAssertEqual(log.noteDiscard(now: 1_000, intervalTicks: 100), 1)
        XCTAssertEqual(log.unreported, 0)
        XCTAssertEqual(log.lastWrittenTicks, 1_000)
    }

    func testRepeatedDiscardsAreCountedAndWrittenOncePerInterval() {
        var log = SoloInertDiscardLog.start
        XCTAssertEqual(log.noteDiscard(now: 1_000, intervalTicks: 100), 1)
        XCTAssertNil(log.noteDiscard(now: 1_010, intervalTicks: 100))
        XCTAssertNil(log.noteDiscard(now: 1_050, intervalTicks: 100))
        XCTAssertNil(log.noteDiscard(now: 1_099, intervalTicks: 100))
        XCTAssertEqual(log.unreported, 3)
        XCTAssertEqual(log.noteDiscard(now: 1_100, intervalTicks: 100), 4)
        XCTAssertEqual(log.unreported, 0)
        XCTAssertEqual(log.lastWrittenTicks, 1_100)
        XCTAssertNil(log.noteDiscard(now: 1_150, intervalTicks: 100))
        XCTAssertEqual(log.noteDiscard(now: 5_000, intervalTicks: 100), 2)
    }

    func testAClockThatGoesBackCountsAsElapsed() {
        var log = SoloInertDiscardLog.start
        XCTAssertEqual(log.noteDiscard(now: 1_000, intervalTicks: 100), 1)
        XCTAssertEqual(log.noteDiscard(now: 900, intervalTicks: 100), 1)
        XCTAssertEqual(log.lastWrittenTicks, 900)
    }

    /// Cento scarti in fila, uno ogni 10 tick, intervallo 100: righe ai tick 0, 100, 200, ...; ogni riga
    /// porta i 10 scarti dall'ultima (la prima 1), e nessuno scarto si perde.
    func testABurstLosesNoDiscard() {
        var log = SoloInertDiscardLog.start
        var written: [Int] = []
        for i in 0..<100 {
            if let n = log.noteDiscard(now: UInt64(i * 10), intervalTicks: 100) {
                written.append(n)
            }
        }
        XCTAssertEqual(written.first, 1)
        XCTAssertEqual(written.count, 10)
        XCTAssertTrue(written.dropFirst().allSatisfy({ $0 == 10 }))
        XCTAssertEqual(written.reduce(0, +) + log.unreported, 100)
    }
}
