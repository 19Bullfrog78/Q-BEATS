import XCTest

// === A411 · SOLO-INERTE — banco della regola d'accensione di Link (banco Models), mandato §2.2 ===
// La matrice degli ingressi: levetta × ruolo × sospeso dallo sfondo × chiusura dell'app = 24 righe, atteso
// LETTERALE per ognuna, scritto dalla regola del mandato e non ricavato dal codice. Poi: in Solo Link non è
// mai attivo (anche a levetta accesa); per Direttore e Follower la regola è quella di oggi (levetta accesa e
// non sospeso); la ragione dello spento segue l'ordine della regola; la forma nuda coincide con la struttura.

final class LinkActivationDecisionTests: XCTestCase {

    private let roles: [LinkMode] = [.standalone, .direttore, .collaborativa]
    private let bools = [false, true]

    // (levetta, ruolo, sospeso, chiusura, attivo)
    private let rows: [(Bool, LinkMode, Bool, Bool, Bool)] = [
        (false, .standalone,    false, false, false),
        (false, .standalone,    false, true,  false),
        (false, .standalone,    true,  false, false),
        (false, .standalone,    true,  true,  false),
        (false, .direttore,     false, false, false),
        (false, .direttore,     false, true,  false),
        (false, .direttore,     true,  false, false),
        (false, .direttore,     true,  true,  false),
        (false, .collaborativa, false, false, false),
        (false, .collaborativa, false, true,  false),
        (false, .collaborativa, true,  false, false),
        (false, .collaborativa, true,  true,  false),
        (true,  .standalone,    false, false, false),
        (true,  .standalone,    false, true,  false),
        (true,  .standalone,    true,  false, false),
        (true,  .standalone,    true,  true,  false),
        (true,  .direttore,     false, false, true),
        (true,  .direttore,     false, true,  false),
        (true,  .direttore,     true,  false, false),
        (true,  .direttore,     true,  true,  false),
        (true,  .collaborativa, false, false, true),
        (true,  .collaborativa, false, true,  false),
        (true,  .collaborativa, true,  false, false),
        (true,  .collaborativa, true,  true,  false),
    ]

    private func decision(_ user: Bool, _ role: LinkMode, _ suspended: Bool, _ terminating: Bool) -> LinkActivationDecision {
        LinkActivationDecision(userLinkEnabled: user, role: role,
                               backgroundSuspended: suspended, appTerminating: terminating)
    }

    func testTheTwentyFourRowsLiterally() {
        XCTAssertEqual(rows.count, 24)
        for (user, role, suspended, terminating, expected) in rows {
            let d = decision(user, role, suspended, terminating)
            XCTAssertEqual(d.active, expected,
                           "levetta:\(user) ruolo:\(role) sfondo:\(suspended) chiusura:\(terminating)")
            XCTAssertEqual(LinkActivationDecision.isActive(userLinkEnabled: user, role: role,
                                                           backgroundSuspended: suspended,
                                                           appTerminating: terminating),
                           expected,
                           "forma nuda - levetta:\(user) ruolo:\(role) sfondo:\(suspended) chiusura:\(terminating)")
        }
    }

    /// Le righe sono tutte e sole le combinazioni degli ingressi.
    func testTheRowsCoverEveryCombinationOnce() {
        var seen = Set<String>()
        for (user, role, suspended, terminating, _) in rows {
            seen.insert("\(user)-\(role)-\(suspended)-\(terminating)")
        }
        XCTAssertEqual(seen.count, 2 * 3 * 2 * 2)
    }

    /// Il cuore del mandato: in Solo il telefono resta fuori dalla rete anche con la levetta accesa.
    func testSoloRoleIsNeverActiveEvenWithTheUserSwitchOn() {
        for user in bools {
            for suspended in bools {
                for terminating in bools {
                    XCTAssertFalse(decision(user, .standalone, suspended, terminating).active,
                                   "levetta:\(user) sfondo:\(suspended) chiusura:\(terminating)")
                }
            }
        }
        let d = decision(true, .standalone, false, false)
        XCTAssertEqual(d.playerRole, .solo)
        XCTAssertEqual(d.offReason, .soloRole)
    }

    /// Direttore o Follower con la levetta spenta sono Solo (A394): Link spento, ragione «levetta-spenta».
    func testUserSwitchOffKeepsEveryRoleOffline() {
        for role in roles {
            let d = decision(false, role, false, false)
            XCTAssertFalse(d.active, "ruolo:\(role)")
            XCTAssertEqual(d.playerRole, .solo, "ruolo:\(role)")
            XCTAssertEqual(d.offReason, .userLinkOff, "ruolo:\(role)")
        }
    }

    /// Direttore e Follower: la regola di oggi (Link segue la levetta, salvo sfondo a click fermo).
    func testDirectorAndFollowerFollowTheUserSwitchAsToday() {
        for role in [LinkMode.direttore, .collaborativa] {
            for user in bools {
                for suspended in bools {
                    XCTAssertEqual(decision(user, role, suspended, false).active, user && !suspended,
                                   "ruolo:\(role) levetta:\(user) sfondo:\(suspended)")
                }
            }
        }
        XCTAssertEqual(decision(true, .direttore, false, false).playerRole, .direttore)
        XCTAssertEqual(decision(true, .collaborativa, false, false).playerRole, .follower)
    }

    /// La politica dello sfondo spegne Direttore e Follower, la chiusura dell'app spegne tutti.
    func testBackgroundAndTerminationSwitchOff() {
        XCTAssertEqual(decision(true, .direttore, true, false).offReason, .backgroundSuspended)
        XCTAssertEqual(decision(true, .collaborativa, true, false).offReason, .backgroundSuspended)
        XCTAssertEqual(decision(true, .direttore, false, true).offReason, .appTerminating)
        XCTAssertEqual(decision(true, .collaborativa, false, true).offReason, .appTerminating)
        for role in roles {
            for user in bools {
                for suspended in bools {
                    XCTAssertFalse(decision(user, role, suspended, true).active,
                                   "ruolo:\(role) levetta:\(user) sfondo:\(suspended)")
                }
            }
        }
    }

    /// La ragione dello spento segue l'ordine della regola, e c'è se e solo se Link è spento.
    func testOffReasonFollowsTheOrderOfTheRule() {
        for (user, role, suspended, terminating, expected) in rows {
            let d = decision(user, role, suspended, terminating)
            XCTAssertEqual(d.offReason == nil, expected,
                           "levetta:\(user) ruolo:\(role) sfondo:\(suspended) chiusura:\(terminating)")
            let reason: LinkActivationDecision.OffReason?
            if !user {
                reason = .userLinkOff
            } else if role == .standalone {
                reason = .soloRole
            } else if suspended {
                reason = .backgroundSuspended
            } else if terminating {
                reason = .appTerminating
            } else {
                reason = nil
            }
            XCTAssertEqual(d.offReason, reason,
                           "levetta:\(user) ruolo:\(role) sfondo:\(suspended) chiusura:\(terminating)")
        }
        XCTAssertEqual(LinkActivationDecision.OffReason.userLinkOff.rawValue, "levetta-spenta")
        XCTAssertEqual(LinkActivationDecision.OffReason.soloRole.rawValue, "ruolo-solo")
        XCTAssertEqual(LinkActivationDecision.OffReason.backgroundSuspended.rawValue, "sospeso-sfondo")
        XCTAssertEqual(LinkActivationDecision.OffReason.appTerminating.rawValue, "chiusura")
    }

    /// Attivo solo con un ruolo del player, e il ruolo del player è quello della regola di oggi.
    func testActiveImpliesARoleAndThePlayerRoleIsTodaysRule() {
        for (user, role, suspended, terminating, _) in rows {
            let d = decision(user, role, suspended, terminating)
            XCTAssertEqual(d.playerRole, PlayerRoleDecision.playerRole(role: role, userLinkEnabled: user))
            if d.active {
                XCTAssertNotEqual(d.playerRole, .solo)
                XCTAssertTrue(d.userLinkEnabled)
            }
        }
    }

    /// Il giro del collaudo: avvio con la levetta accesa (Solo, fuori rete) → Director (in rete) → sfondo a
    /// click fermo (fuori) → primo piano (in rete) → Solo (fuori) → chiusura.
    func testTheCollaudoWalk() {
        var role = LinkMode.standalone
        var suspended = false
        var terminating = false
        let user = true
        func active() -> Bool { decision(user, role, suspended, terminating).active }
        XCTAssertFalse(active(), "avvio: Solo con la levetta accesa")
        role = .direttore
        XCTAssertTrue(active(), "scelta di Director")
        suspended = true
        XCTAssertFalse(active(), "sfondo a click fermo")
        suspended = false
        XCTAssertTrue(active(), "primo piano")
        role = .standalone
        XCTAssertFalse(active(), "di nuovo Solo")
        role = .collaborativa
        XCTAssertTrue(active(), "Follower")
        terminating = true
        XCTAssertFalse(active(), "chiusura dell'app")
    }

    func testInputsAreKept() {
        let d = decision(true, .collaborativa, true, false)
        XCTAssertTrue(d.userLinkEnabled)
        XCTAssertEqual(d.role, .collaborativa)
        XCTAssertTrue(d.backgroundSuspended)
        XCTAssertFalse(d.appTerminating)
        XCTAssertEqual(d.playerRole, .follower)
        XCTAssertFalse(d.active)
    }

    // MARK: - A412 — la politica dello sfondo col Direttore muto in canzone (mandato «DIRETTORE-IN-CRISI-PASSO-2», §2.8)

    /// Le otto righe: Link in rete × click in moto × Direttore muto in canzone. Si sospende solo in rete,
    /// a click fermo, col Direttore non muto (la politica del 02/10, LIBRO 2026-10-02, più l'ingresso nuovo).
    func testTheBackgroundPolicyEightRowsLiterally() {
        // (in rete, click in moto, muto in canzone, si sospende)
        let policy: [(Bool, Bool, Bool, Bool)] = [
            (false, false, false, false),
            (false, false, true,  false),
            (false, true,  false, false),
            (false, true,  true,  false),
            (true,  false, false, true),
            (true,  false, true,  false),
            (true,  true,  false, false),
            (true,  true,  true,  false),
        ]
        for (active, playing, silent, expected) in policy {
            XCTAssertEqual(LinkActivationDecision.suspendsOnBackground(linkActive: active, clickPlaying: playing,
                                                                       directorSilentInSong: silent),
                           expected, "inRete:\(active) click:\(playing) muto:\(silent)")
        }
    }

    /// La matrice di A411 allargata: levetta × ruolo × click in moto × Direttore muto in canzone. Prima
    /// dello sfondo Link è quello della regola; al passaggio in sfondo la politica dà l'ingresso
    /// «sospeso dallo sfondo», e decide la regola (la strada resta una). In rete dopo lo sfondo resta solo
    /// chi c'era e ha il click in moto o è muto in canzone; il Solo mai.
    func testTheWidenedMatrixThroughTheBackground() {
        var cells = 0
        for user in bools {
            for role in roles {
                for playing in bools {
                    for silent in bools {
                        cells += 1
                        let before = decision(user, role, false, false).active
                        let suspended = LinkActivationDecision.suspendsOnBackground(linkActive: before, clickPlaying: playing,
                                                                                    directorSilentInSong: silent)
                        let after = decision(user, role, suspended, false).active
                        let tag = "levetta:\(user) ruolo:\(role) click:\(playing) muto:\(silent)"
                        XCTAssertEqual(after, before && (playing || silent), tag)
                        if role == .standalone { XCTAssertFalse(after, tag) }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 2 * 3 * 2 * 2)
    }

    /// Il caso del ticket `TD-link-spento-in-secondo-piano-durante-lo-show`: Director in rete, click fermo
    /// per un'interruzione, canzone in corso → in sfondo Link resta in rete. A click fermato dall'utente
    /// la politica del 02/10 è identica: in sfondo si sospende.
    func testTheDirectorSilentInSongStaysOnlineInBackground() {
        let silent = LinkActivationDecision.suspendsOnBackground(linkActive: true, clickPlaying: false, directorSilentInSong: true)
        XCTAssertFalse(silent)
        XCTAssertTrue(decision(true, .direttore, silent, false).active)
        let stopped = LinkActivationDecision.suspendsOnBackground(linkActive: true, clickPlaying: false, directorSilentInSong: false)
        XCTAssertTrue(stopped)
        XCTAssertEqual(decision(true, .direttore, stopped, false).offReason, .backgroundSuspended)
    }
}
