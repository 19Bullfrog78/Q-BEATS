import XCTest

// === RIENTRO-P1 — banco delle due scritture tolte al Follower (banco Models) ===
// Due ingressi: ruolo × Link acceso dall'utente. Attesi LETTERALI per le sei righe, per
// W1 (il tempo scritto su Link all'avvio orchestrato) e per W4 («si suona» scritto su Link
// all'ingresso). Una riga sola dice «non scrive»: il Follower (ruolo `.collaborativa` E
// Link acceso dall'utente). Le altre cinque sono la prova che Direttore, Solo e ruolo
// Follower con Link spento dall'utente scrivono come prima.
// Il banco gira in CI su ogni push (`.github/workflows/ios_build.yml`,
// `xcodebuild test -scheme QBeatsTests`).

final class FollowerLinkWriteDecisionTests: XCTestCase {

    // (ruolo, Link dell'utente, atteso «scrive»)
    private let rows: [(LinkMode, Bool, Bool)] = [
        (.standalone,    false, true),
        (.standalone,    true,  true),
        (.direttore,     false, true),
        (.direttore,     true,  true),
        (.collaborativa, false, true),
        (.collaborativa, true,  false),
    ]

    func testTempoAtOrchestratedStartTheSixRowsLiterally() {
        for (role, user, expected) in rows {
            XCTAssertEqual(
                FollowerLinkWriteDecision.writesTempoAtOrchestratedStart(role: role, userLinkEnabled: user),
                expected,
                "W1 - ruolo:\(role) linkUtente:\(user)")
        }
    }

    func testIsPlayingAtJoinTheSixRowsLiterally() {
        for (role, user, expected) in rows {
            XCTAssertEqual(
                FollowerLinkWriteDecision.writesIsPlayingAtJoin(role: role, userLinkEnabled: user),
                expected,
                "W4 - ruolo:\(role) linkUtente:\(user)")
        }
    }

    /// Le due scritture seguono la STESSA regola di `FollowerDecision`: chi è Follower non
    /// scrive, chi non lo è scrive. Se un giorno la regola del Follower cambia, questo
    /// banco dice subito se le due scritture l'hanno seguita.
    func testBothWritesFollowTheFollowerRule() {
        for (role, user, _) in rows {
            let isFollower = FollowerDecision.isFollower(role: role, userLinkEnabled: user)
            XCTAssertEqual(
                FollowerLinkWriteDecision.writesTempoAtOrchestratedStart(role: role, userLinkEnabled: user),
                !isFollower)
            XCTAssertEqual(
                FollowerLinkWriteDecision.writesIsPlayingAtJoin(role: role, userLinkEnabled: user),
                !isFollower)
        }
    }

    // MARK: - A386 · B2c-BIS: W2, il tempo scritto su Link al proprio confine di sezione
    // Decisione di Mauro dell'01/10/2026: da solo il Follower non scrive niente in Link; in sync
    // resta la decisione 9.1 (scrive). Attesi LETTERALI, stato per stato. L'interruttore solo
    // DEBUG di A366 si combina: sul Follower W2 scrive solo se lo permettono tutti e due.

    private typealias W2 = FollowerLinkWriteDecision.BoundaryTempoWrite

    private let states: [FollowerSyncState] = [
        .inSync(songClosed: false),
        .inSync(songClosed: true),
        .alone,
        .out(armed: nil),
        .out(armed: 3),
    ]

    private func w2(_ role: LinkMode, _ user: Bool, _ state: FollowerSyncState,
                    ownClock: Bool = false, debugSwitch: Bool = true) -> W2 {
        FollowerLinkWriteDecision.boundaryTempoWrite(role: role, userLinkEnabled: user, state: state,
                                                     ownClockUntilStop: ownClock, debugSwitchOn: debugSwitch)
    }

    func testW2FollowerInSyncWritesAsToday() {
        XCTAssertEqual(w2(.collaborativa, true, .inSync(songClosed: false)), .writes)
        XCTAssertEqual(w2(.collaborativa, true, .inSync(songClosed: true)), .writes)
    }

    func testW2FollowerAloneDoesNotWrite() {
        XCTAssertEqual(w2(.collaborativa, true, .alone), .skippedOwnClock)
        XCTAssertEqual(w2(.collaborativa, true, .alone, ownClock: true), .skippedOwnClock)
    }

    /// La coda fra l'uscita da DA SOLO e l'arresto del motore: lo stato dice gia' FUORI, il
    /// motore gira ancora sul proprio orologio. Un confine di sezione li' non scrive.
    func testW2FollowerInTheTailBeforeTheStopDoesNotWrite() {
        XCTAssertEqual(w2(.collaborativa, true, .out(armed: nil), ownClock: true), .skippedOwnClock)
        XCTAssertEqual(w2(.collaborativa, true, .out(armed: 3), ownClock: true), .skippedOwnClock)
    }

    func testW2FollowerOutWithoutOwnClockWritesAsToday() {
        XCTAssertEqual(w2(.collaborativa, true, .out(armed: nil)), .writes)
        XCTAssertEqual(w2(.collaborativa, true, .out(armed: 3)), .writes)
    }

    func testW2WhoIsNotAFollowerAlwaysWrites() {
        let notFollowers: [(LinkMode, Bool)] = [
            (.standalone, false), (.standalone, true),
            (.direttore, false), (.direttore, true),
            (.collaborativa, false),
        ]
        for (role, user) in notFollowers {
            for state in states {
                for ownClock in [false, true] {
                    for debugSwitch in [false, true] {
                        XCTAssertEqual(w2(role, user, state, ownClock: ownClock, debugSwitch: debugSwitch), .writes,
                                       "ruolo:\(role) linkUtente:\(user) stato:\(state) orologioProprio:\(ownClock) interruttore:\(debugSwitch)")
                    }
                }
            }
        }
    }

    /// L'interruttore solo DEBUG di A366 funziona come prima: spento, salta W2 sul Follower che
    /// altrimenti scriverebbe (IN SYNC e FUORI).
    func testW2DebugSwitchOffSkipsOnTheFollowerThatWouldWrite() {
        XCTAssertEqual(w2(.collaborativa, true, .inSync(songClosed: false), debugSwitch: false), .skippedDebugSwitch)
        XCTAssertEqual(w2(.collaborativa, true, .inSync(songClosed: true), debugSwitch: false), .skippedDebugSwitch)
        XCTAssertEqual(w2(.collaborativa, true, .out(armed: nil), debugSwitch: false), .skippedDebugSwitch)
        XCTAssertEqual(w2(.collaborativa, true, .out(armed: 3), debugSwitch: false), .skippedDebugSwitch)
    }

    /// I due si combinano: W2 scrive solo se lo permettono tutti e due. Quando la saltano tutti
    /// e due, la ragione e' l'orologio proprio (la regola di prodotto viene prima dello strumento).
    func testW2OwnClockAndDebugSwitchCombine() {
        XCTAssertEqual(w2(.collaborativa, true, .alone, debugSwitch: false), .skippedOwnClock)
        XCTAssertEqual(w2(.collaborativa, true, .out(armed: nil), ownClock: true, debugSwitch: false), .skippedOwnClock)
        for state in states {
            for ownClock in [false, true] {
                XCTAssertNotEqual(w2(.collaborativa, true, state, ownClock: ownClock, debugSwitch: false), .writes,
                                  "stato:\(state) orologioProprio:\(ownClock)")
            }
        }
    }

    /// Una regola sola per «Link entra» e «il tempo esce»: a interruttore acceso W2 scrive se e
    /// solo se il Follower segue Link (`FollowerLinkFollowDecision`), per ogni ruolo e stato.
    func testW2WritesExactlyWhenTheDeviceFollowsLink() {
        for role in [LinkMode.standalone, .direttore, .collaborativa] {
            for user in [false, true] {
                for state in states {
                    for ownClock in [false, true] {
                        let follows = FollowerLinkFollowDecision.followsLink(role: role, userLinkEnabled: user,
                                                                             state: state, ownClockUntilStop: ownClock)
                        XCTAssertEqual(w2(role, user, state, ownClock: ownClock) == .writes, follows,
                                       "ruolo:\(role) linkUtente:\(user) stato:\(state) orologioProprio:\(ownClock)")
                    }
                }
            }
        }
    }

    /// Sulla macchina vera: IN SYNC scrive; perso il Direttore a canzone in corso, DA SOLO non
    /// scrive, e non scrive nemmeno dopo che il Direttore torna a sentirsi; allo Stop del
    /// Direttore la coda non scrive; a motore fermo l'orologio proprio si abbassa e FUORI torna
    /// come oggi.
    func testW2ThroughTheRealMachine() {
        var state: FollowerSyncState = .inSync(songClosed: false)
        var ownClock = false
        func step(_ event: FollowerSyncEvent) {
            state = FollowerSyncDecision.transition(state: state, event: event).state
            ownClock = FollowerLinkFollowDecision.ownClockUntilStop(after: event, state: state, previous: ownClock)
        }
        XCTAssertEqual(w2(.collaborativa, true, state, ownClock: ownClock), .writes)
        step(.directorHeard(false, engineRunning: true))
        XCTAssertEqual(state, .alone)
        XCTAssertEqual(w2(.collaborativa, true, state, ownClock: ownClock), .skippedOwnClock)
        step(.directorHeard(true, engineRunning: true))
        XCTAssertEqual(w2(.collaborativa, true, state, ownClock: ownClock), .skippedOwnClock)
        step(.linkStop(falseStart: false, engineRunning: true))
        XCTAssertEqual(state, .out(armed: nil))
        XCTAssertEqual(w2(.collaborativa, true, state, ownClock: ownClock), .skippedOwnClock)
        ownClock = false    // il motore si e' fermato
        XCTAssertEqual(w2(.collaborativa, true, state, ownClock: ownClock), .writes)
    }
}
