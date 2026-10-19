import XCTest

// === A412 · SEGUITO 1 — banco della regola del richiamo del tempo del Direttore (`DirectorTempoRebroadcastDecision`,
// banco Models), mandato «A412 · SEGUITO 1», §2.1-§2.2 e §3 ===
// La matrice: ruolo del player × motore in moto × muto in canzone × segue Link × tempo del richiamo uguale o diverso
// = 3 × 2 × 2 × 2 × 2 = 48 celle, con l'atteso scritto qui dalla regola del mandato (e non ricavato dal tipo). Poi i
// casi per esteso: il caso del collaudo (Direttore, motore in moto, muto in canzone, richiamo 110, `_audioBPM` 90) non
// ribatte; il caso di oggi a click in moto senza crisi ribatte, come prima; il resto del Direttore com'era (motore
// fermo, stesso tempo, «segue Link»); Solo e Follower mai.

final class DirectorTempoRebroadcastDecisionTests: XCTestCase {

    private typealias Decision = DirectorTempoRebroadcastDecision

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]

    private func outcome(_ role: PlayerRole, running: Bool = true, silent: Bool = false, follows: Bool = false,
                         callback: Double = 110, own: Double = 90) -> Decision.Outcome {
        Decision.outcome(playerRole: role, engineRunning: running, silentInSong: silent, followsLink: follows,
                         callbackTempo: callback, ownTempo: own)
    }

    // MARK: - Il collaudo e il caso di oggi

    /// Il caso del collaudo di A412 (P2-bis, 18/10/2026): l'iPhone Direttore aspetta il rientro col motore acceso e
    /// muto; l'iPad scrive 110 al cambio di sezione; il motore dell'iPhone è ancora a 90. Non ribatte.
    func testTheCollaudoCaseDoesNotRebroadcast() {
        let result = outcome(.direttore, running: true, silent: true, follows: false, callback: 110, own: 90)
        XCTAssertEqual(result, .hold(.silentInSong))
        XCTAssertFalse(result.rebroadcasts)
    }

    /// Il caso di oggi a click in moto senza crisi: il Direttore ribatte il proprio tempo, come prima.
    func testTodayAtClickInMotionWithoutCrisisRebroadcasts() {
        let result = outcome(.direttore, running: true, silent: false, follows: false, callback: 110, own: 90)
        XCTAssertEqual(result, .rebroadcast)
        XCTAssertTrue(result.rebroadcasts)
    }

    // MARK: - Il resto del Direttore, com'era

    /// Il richiamo porta lo stesso tempo del Direttore: niente rimpallo (il controllo `bpm != _audioBPM` di sempre).
    func testTheSameTempoIsNeverRebroadcast() {
        XCTAssertEqual(outcome(.direttore, callback: 90, own: 90), .hold(.sameTempo))
        XCTAssertEqual(outcome(.direttore, callback: 120.5, own: 120.5), .hold(.sameTempo))
    }

    /// Motore fermo senza crisi (il Direttore fermo dopo uno Stop): non ribatte e non combatte la sessione (com'era).
    func testTheStoppedDirectorDoesNotRebroadcast() {
        XCTAssertEqual(outcome(.direttore, running: false), .hold(.engineStopped))
    }

    /// Dopo un rientro, fino all'avvio dopo (T4): segue Link e non ribatte (com'era da A412).
    func testTheDirectorFollowingLinkDoesNotRebroadcast() {
        XCTAssertEqual(outcome(.direttore, running: true, follows: true), .hold(.followsLink))
        XCTAssertEqual(outcome(.direttore, running: false, follows: true), .hold(.followsLink))
    }

    /// Muto in canzone col motore fermo (il silenzio prima del rientro) e durante l'attesa del rientro (motore acceso):
    /// non ribatte mai, qualunque tempo porti il richiamo.
    func testTheSilentDirectorNeverRebroadcasts() {
        for running in bools {
            for follows in bools {
                for (callback, own) in [(110.0, 90.0), (90.0, 90.0), (140.0, 120.0)] {
                    XCTAssertEqual(outcome(.direttore, running: running, silent: true, follows: follows,
                                           callback: callback, own: own),
                                   .hold(.silentInSong),
                                   "motore:\(running) segue:\(follows) richiamo:\(callback) proprio:\(own)")
                }
            }
        }
    }

    // MARK: - Solo e Follower

    /// Chi non è Direttore non ribatte mai: il suo ramo del richiamo è un altro (Solo: il lucchetto di A411;
    /// Follower: l'adozione di oggi).
    func testSoloAndFollowerNeverRebroadcast() {
        for role in [PlayerRole.solo, .follower] {
            for running in bools {
                for silent in bools {
                    for follows in bools {
                        XCTAssertEqual(outcome(role, running: running, silent: silent, follows: follows),
                                       .hold(.notDirector),
                                       "ruolo:\(role) motore:\(running) muto:\(silent) segue:\(follows)")
                    }
                }
            }
        }
    }

    // MARK: - La matrice

    /// 48 celle. Atteso scritto dalla regola del mandato: ribatte se e solo se Direttore, motore in moto, non muto in
    /// canzone, non «segue Link», tempo diverso; altrimenti il primo motivo nell'ordine non-direttore, muto in canzone,
    /// segue Link, motore fermo, stesso tempo.
    func testTheMatrix() {
        var cells = 0
        var rebroadcasts = 0
        for role in roles {
            for running in bools {
                for silent in bools {
                    for follows in bools {
                        for differ in bools {
                            let own = 90.0
                            let callback = differ ? 110.0 : 90.0
                            let expected: Decision.Outcome
                            if role != .direttore {
                                expected = .hold(.notDirector)
                            } else if silent {
                                expected = .hold(.silentInSong)
                            } else if follows {
                                expected = .hold(.followsLink)
                            } else if !running {
                                expected = .hold(.engineStopped)
                            } else if !differ {
                                expected = .hold(.sameTempo)
                            } else {
                                expected = .rebroadcast
                            }
                            let result = outcome(role, running: running, silent: silent, follows: follows,
                                                 callback: callback, own: own)
                            XCTAssertEqual(result, expected,
                                           "ruolo:\(role) motore:\(running) muto:\(silent) segue:\(follows) diverso:\(differ)")
                            cells += 1
                            if result.rebroadcasts { rebroadcasts += 1 }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 48)
        XCTAssertEqual(rebroadcasts, 1, "una sola cella ribatte: Direttore in moto, non muto, non «segue Link», tempo diverso")
    }

    // MARK: - Le parole

    /// I nomi dei motivi, come vanno nelle righe di registro (senza accenti).
    func testTheHoldNames() {
        XCTAssertEqual(Decision.Hold.allCases.map { $0.rawValue },
                       ["non-direttore", "muto-in-canzone", "segue-link", "motore-fermo", "stesso-tempo"])
    }
}
