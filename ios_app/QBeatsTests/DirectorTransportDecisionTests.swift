import XCTest

// === A412 — banco della regola del tasto della fascia (`DirectorTransportDecision`, banco Models), mandato §2.4 ===
// La matrice: ruolo del player × muto in canzone × rientro possibile adesso × interruzione in corso ×
// servizi audio persi = 3 × 2 × 2 × 2 × 2 = 48 celle, con l'atteso scritto dalla regola del mandato. Poi
// i casi del collaudo: dopo un reset dei servizi audio (il solo silenzio che finisce col tocco) il tasto
// dice Play; fra la Lost e la Reset, durante un'interruzione o col conto non certo dice Stop; fuori dal
// silenzio il tasto è quello di oggi (`nil`). E la ragione, nell'ordine della regola.

final class DirectorTransportDecisionTests: XCTestCase {

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]

    private func silence(_ role: PlayerRole, silent: Bool = true, possible: Bool = true,
                         interrupted: Bool = false, lost: Bool = false) -> DirectorSilence? {
        DirectorTransportDecision.silence(playerRole: role, silentInSong: silent, rejoinPossibleNow: possible,
                                          interruptionActive: interrupted, servicesLost: lost)
    }

    /// Dopo un reset dei servizi audio: muto in canzone, nessuna interruzione, servizi tornati, il
    /// coordinatore dice «rientra». Il tasto dice Play e il tocco rientra (D2).
    func testAfterAResetTheButtonSaysPlayAndRejoins() {
        let s = silence(.direttore)
        XCTAssertEqual(s, DirectorSilence(tap: .rejoin))
        XCTAssertEqual(s?.showsPlay, true)
    }

    /// Fra la Lost e la Reset (servizi persi), durante un'interruzione, o col conto non certo: il tasto
    /// dice Stop e il tocco ferma tutta la band (D3; D4 (a)).
    func testWhenRejoinIsNotPossibleTheButtonSaysStop() {
        XCTAssertEqual(silence(.direttore, lost: true), DirectorSilence(tap: .stopBand))
        XCTAssertEqual(silence(.direttore, interrupted: true), DirectorSilence(tap: .stopBand))
        XCTAssertEqual(silence(.direttore, possible: false), DirectorSilence(tap: .stopBand))
        XCTAssertEqual(silence(.direttore, possible: false)?.showsPlay, false)
    }

    /// Fuori dal silenzio, e per il Solo e il Follower, il tasto è quello di oggi.
    func testOutsideTheSilenceTheButtonIsTodays() {
        XCTAssertNil(silence(.direttore, silent: false))
        for role in [PlayerRole.solo, .follower] {
            for silent in bools {
                XCTAssertNil(silence(role, silent: silent), "ruolo:\(role) muto:\(silent)")
            }
        }
    }

    // MARK: - La matrice

    private func expected(_ role: PlayerRole, silent: Bool, possible: Bool, interrupted: Bool, lost: Bool) -> DirectorTransportTap? {
        guard role == .direttore, silent else { return nil }
        return (possible && !interrupted && !lost) ? .rejoin : .stopBand
    }

    func testTheMatrix() {
        var cells = 0
        var plays = 0
        for role in roles {
            for silent in bools {
                for possible in bools {
                    for interrupted in bools {
                        for lost in bools {
                            cells += 1
                            let got = silence(role, silent: silent, possible: possible, interrupted: interrupted, lost: lost)
                            let tag = "ruolo:\(role) muto:\(silent) possibile:\(possible) interruzione:\(interrupted) persi:\(lost)"
                            XCTAssertEqual(got?.tap, expected(role, silent: silent, possible: possible,
                                                              interrupted: interrupted, lost: lost), tag)
                            if got?.tap == .rejoin { plays += 1 }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 48)
        XCTAssertEqual(plays, 1, "il tasto dice Play in una sola combinazione")
    }

    // MARK: - La ragione

    func testTheReasonFollowsTheOrderOfTheRule() {
        typealias D = DirectorTransportDecision
        XCTAssertEqual(D.reason(playerRole: .direttore, silentInSong: true, rejoinPossibleNow: true,
                                interruptionActive: false, servicesLost: false), .rejoinPossible)
        XCTAssertEqual(D.reason(playerRole: .direttore, silentInSong: true, rejoinPossibleNow: false,
                                interruptionActive: false, servicesLost: false), .rejoinNotPossible)
        XCTAssertEqual(D.reason(playerRole: .direttore, silentInSong: true, rejoinPossibleNow: true,
                                interruptionActive: true, servicesLost: true), .interruptionActive)
        XCTAssertEqual(D.reason(playerRole: .direttore, silentInSong: true, rejoinPossibleNow: true,
                                interruptionActive: false, servicesLost: true), .servicesLost)
        XCTAssertNil(D.reason(playerRole: .direttore, silentInSong: false, rejoinPossibleNow: true,
                              interruptionActive: false, servicesLost: false))
        XCTAssertNil(D.reason(playerRole: .solo, silentInSong: true, rejoinPossibleNow: true,
                              interruptionActive: false, servicesLost: false))
        // La ragione «possibile» c'è se e solo se il tasto dice Play.
        for role in roles {
            for silent in bools {
                for possible in bools {
                    for interrupted in bools {
                        for lost in bools {
                            let tap = D.silence(playerRole: role, silentInSong: silent, rejoinPossibleNow: possible,
                                                interruptionActive: interrupted, servicesLost: lost)?.tap
                            let reason = D.reason(playerRole: role, silentInSong: silent, rejoinPossibleNow: possible,
                                                  interruptionActive: interrupted, servicesLost: lost)
                            XCTAssertEqual(tap == nil, reason == nil)
                            XCTAssertEqual(tap == .rejoin, reason == .rejoinPossible)
                        }
                    }
                }
            }
        }
    }

    func testTheNames() {
        XCTAssertEqual(DirectorTransportTap.rejoin.rawValue, "rientra")
        XCTAssertEqual(DirectorTransportTap.stopBand.rawValue, "ferma-la-band")
        XCTAssertEqual(DirectorTransportDecision.Reason.interruptionActive.rawValue, "interruzione-in-corso")
        XCTAssertEqual(DirectorTransportDecision.Reason.servicesLost.rawValue, "servizi-audio-persi")
    }
}
