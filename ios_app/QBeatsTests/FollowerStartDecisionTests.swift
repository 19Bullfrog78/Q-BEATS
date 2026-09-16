import XCTest

// === A361/A362 — banco della decisione d'avvio del Follower (banco Models) ===
// Cinque ingressi: ruolo × Link dell'utente × almeno un collegato × sessione che suona ×
// ripresa sì/no. Attesi LETTERALI per le otto righe del Follower (collegato × sessione ×
// ripresa): l'esito dipende SOLO dalla sessione che suona — «collegato» è un dato di log
// e il banco prova che non cambia l'esito (A362). Per chi comanda il trasporto
// (Direttore, Solo, e ruolo Follower con Link dell'utente spento) l'esito è sempre lo
// stesso, ed è la prova che il motore di chi comanda parte come oggi, ripresa compresa.
// Il banco gira in CI su ogni push (`.github/workflows/ios_build.yml`,
// `xcodebuild test -scheme QBeatsTests`).

final class FollowerStartDecisionTests: XCTestCase {

    private func decision(role: LinkMode = .collaborativa,
                          user: Bool = true,
                          connected: Bool,
                          playing: Bool,
                          resume: Bool) -> FollowerStartDecision {
        FollowerStartDecision(role: role,
                              userLinkEnabled: user,
                              anyPeerConnected: connected,
                              sessionPlaying: playing,
                              isResume: resume)
    }

    // MARK: - Le otto righe del Follower: collegato × sessione che suona × ripresa

    func testTheEightFollowerRowsLiterally() {
        // (collegato, sessione, ripresa, esito atteso) — l'esito segue la sola sessione.
        let rows: [(Bool, Bool, Bool, FollowerStartDecision.Outcome)] = [
            (false, false, false, .stayStopped),
            (false, false, true,  .stayStopped),
            (false, true,  false, .joinRunningSession),
            (false, true,  true,  .joinRunningSession),
            (true,  false, false, .stayStopped),
            (true,  false, true,  .stayStopped),
            (true,  true,  false, .joinRunningSession),
            (true,  true,  true,  .joinRunningSession),
        ]
        XCTAssertEqual(rows.count, 8)
        for (connected, playing, resume, outcome) in rows {
            let d = decision(connected: connected, playing: playing, resume: resume)
            XCTAssertTrue(d.isFollower)
            XCTAssertEqual(d.outcome, outcome, "collegato:\(connected) sessione:\(playing) ripresa:\(resume)")
            XCTAssertFalse(d.usesResumeBeat, "il Follower non usa mai il beat di ripresa")
        }
    }

    // MARK: - A362 — «collegato» non cambia l'esito: la spia può restare indietro

    func testConnectedFlagNeverChangesTheOutcome() {
        for role in [LinkMode.standalone, .direttore, .collaborativa] {
            for user in [false, true] {
                for playing in [false, true] {
                    for resume in [false, true] {
                        let seen = decision(role: role, user: user, connected: true, playing: playing, resume: resume)
                        let stale = decision(role: role, user: user, connected: false, playing: playing, resume: resume)
                        XCTAssertEqual(seen.outcome, stale.outcome, "ruolo:\(role) utente:\(user) sessione:\(playing) ripresa:\(resume)")
                        XCTAssertEqual(seen.usesResumeBeat, stale.usesResumeBeat, "ruolo:\(role) utente:\(user) sessione:\(playing) ripresa:\(resume)")
                    }
                }
            }
        }
    }

    func testFollowerJoinsARunningSessionEvenWithTheIndicatorStuckAtZero() {
        // Alla punta un Follower con la spia dei collegati a zero e la sessione che suona
        // entrava nel ramo condiviso: la decisione deve fare lo stesso.
        let d = decision(connected: false, playing: true, resume: false)
        XCTAssertEqual(d.outcome, .joinRunningSession)
        XCTAssertFalse(d.anyPeerConnected)   // il dato resta leggibile per il log
    }

    // MARK: - Chi comanda il trasporto parte come oggi, ripresa compresa

    func testWhoCommandsTheTransportKeepsTodaysStart() {
        // Direttore e Solo con Link dell'utente acceso o spento, e il ruolo Follower con
        // Link spento dall'utente: sempre `commandsTransport`, e il beat di ripresa si usa
        // esattamente quando c'è.
        let commanders: [(LinkMode, Bool)] = [
            (.standalone, false), (.standalone, true),
            (.direttore, false), (.direttore, true),
            (.collaborativa, false),
        ]
        for (role, user) in commanders {
            for connected in [false, true] {
                for playing in [false, true] {
                    for resume in [false, true] {
                        let d = decision(role: role, user: user, connected: connected, playing: playing, resume: resume)
                        XCTAssertFalse(d.isFollower, "ruolo:\(role) utente:\(user)")
                        XCTAssertEqual(d.outcome, .commandsTransport, "ruolo:\(role) utente:\(user) collegato:\(connected) sessione:\(playing) ripresa:\(resume)")
                        XCTAssertEqual(d.usesResumeBeat, resume, "ruolo:\(role) utente:\(user) ripresa:\(resume)")
                    }
                }
            }
        }
    }

    // MARK: - Il Follower entra solo in una sessione che suona

    func testFollowerJoinsOnlyARunningSession() {
        XCTAssertEqual(decision(connected: true,  playing: true,  resume: false).outcome, .joinRunningSession)
        XCTAssertEqual(decision(connected: true,  playing: false, resume: false).outcome, .stayStopped)   // il Direttore c'è ma è fermo
        XCTAssertEqual(decision(connected: false, playing: true,  resume: false).outcome, .joinRunningSession)
        XCTAssertEqual(decision(connected: false, playing: false, resume: false).outcome, .stayStopped)
    }

    // MARK: - La ripresa dopo un'interruzione: il Follower entra con join o resta fermo

    func testFollowerResumeAfterInterruptionJoinsOrStaysStopped() {
        let directorStillPlaying = decision(connected: true, playing: true, resume: true)
        XCTAssertEqual(directorStillPlaying.outcome, .joinRunningSession)
        XCTAssertFalse(directorStillPlaying.usesResumeBeat)
        let directorStoppedMeanwhile = decision(connected: true, playing: false, resume: true)
        XCTAssertEqual(directorStoppedMeanwhile.outcome, .stayStopped)
        XCTAssertFalse(directorStoppedMeanwhile.usesResumeBeat)
    }

    // MARK: - «Resta fermo» è solo del Follower

    func testStayStoppedIsOnlyForAFollower() {
        XCTAssertEqual(decision(role: .direttore,  user: true, connected: false, playing: false, resume: false).outcome, .commandsTransport)
        XCTAssertEqual(decision(role: .standalone, user: true, connected: false, playing: false, resume: false).outcome, .commandsTransport)
        XCTAssertEqual(decision(role: .collaborativa, user: true, connected: false, playing: false, resume: false).outcome, .stayStopped)
    }

    // MARK: - Gli ingressi restano leggibili (per la strumentazione)

    func testInputsAreKept() {
        let d = decision(connected: true, playing: false, resume: true)
        XCTAssertTrue(d.isFollower)
        XCTAssertTrue(d.anyPeerConnected)
        XCTAssertFalse(d.sessionPlaying)
        XCTAssertTrue(d.isResume)
    }
}
