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
}
