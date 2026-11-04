import XCTest

// === A412 — banco della regola del tasto della fascia (`DirectorTransportDecision`, banco Models), mandato §2.4 ===
// La matrice: ruolo del player × muto in canzone × rientro possibile adesso × interruzione in corso ×
// servizi audio persi = 3 × 2 × 2 × 2 × 2 = 48 celle, con l'atteso scritto dalla regola del mandato. Poi
// i casi del collaudo: dopo un reset dei servizi audio (il solo silenzio che finisce col tocco) il tasto
// dice Play; fra la Lost e la Reset, durante un'interruzione o col conto non certo dice Stop; fuori dal
// silenzio il tasto è quello di oggi (`nil`). E la ragione, nell'ordine della regola.
// === A425 (mandato A425, par. 2.3) — l'ingresso nuovo «la canzone finisce col conto certo» e la regola del tocco ===
// La matrice segue l'ingresso nuovo: 3 × 2 × 2 × 2 × 2 × 2 = 96 celle (erano 48). Il tasto dice Play in tre celle: «rientra»
// col rientro possibile, con e senza la fine certa (vince il rientro), e «lascia finire» con la sola fine certa; prima la cella
// era una, perché l'esito Play era solo «rientra». I casi nuovi: la fine certa con e senza interruzione o servizi persi, il
// rientro e la fine insieme, fuori dal silenzio `nil`; i quattro casi della regola del tocco su una faccia Play (riletta sulla
// coda: decide la faccia di adesso, mai un «ferma la band»).

final class DirectorTransportDecisionTests: XCTestCase {

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]

    private func silence(_ role: PlayerRole, silent: Bool = true, possible: Bool = true, ends: Bool = false,
                         interrupted: Bool = false, lost: Bool = false) -> DirectorSilence? {
        DirectorTransportDecision.silence(playerRole: role, silentInSong: silent, rejoinPossibleNow: possible,
                                          songEndsCertainNow: ends, interruptionActive: interrupted, servicesLost: lost)
    }

    private func reason(_ role: PlayerRole, silent: Bool = true, possible: Bool = true, ends: Bool = false,
                        interrupted: Bool = false, lost: Bool = false) -> DirectorTransportDecision.Reason? {
        DirectorTransportDecision.reason(playerRole: role, silentInSong: silent, rejoinPossibleNow: possible,
                                         songEndsCertainNow: ends, interruptionActive: interrupted, servicesLost: lost)
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

    /// A425 — l'atteso scritto dalla regola del mandato A425, par. 2.3, nell'ordine: interruzione o servizi persi ⇒ Stop; rientro
    /// possibile ⇒ rientra; fine certa ⇒ lascia finire; se no Stop.
    private func expected(_ role: PlayerRole, silent: Bool, possible: Bool, ends: Bool, interrupted: Bool, lost: Bool) -> DirectorTransportTap? {
        guard role == .direttore, silent else { return nil }
        if interrupted || lost { return .stopBand }
        if possible { return .rejoin }
        return ends ? .letSongEnd : .stopBand
    }

    func testTheMatrix() {
        var cells = 0
        var rejoins = 0
        var letSongEnds = 0
        var plays = 0
        for role in roles {
            for silent in bools {
                for possible in bools {
                    for ends in bools {
                        for interrupted in bools {
                            for lost in bools {
                                cells += 1
                                let got = silence(role, silent: silent, possible: possible, ends: ends,
                                                  interrupted: interrupted, lost: lost)
                                let tag = "ruolo:\(role) muto:\(silent) possibile:\(possible) fine:\(ends) interruzione:\(interrupted) persi:\(lost)"
                                XCTAssertEqual(got?.tap, expected(role, silent: silent, possible: possible, ends: ends,
                                                                  interrupted: interrupted, lost: lost), tag)
                                if got?.tap == .rejoin { rejoins += 1 }
                                if got?.tap == .letSongEnd { letSongEnds += 1 }
                                if got?.showsPlay == true { plays += 1 }
                            }
                        }
                    }
                }
            }
        }
        // A425 — l'ingresso nuovo raddoppia le celle (48 → 96). «Rientra» esce in due celle (il rientro possibile, con e senza la
        // fine certa: vince il rientro), «lascia finire» in una (la sola fine certa); il tasto dice Play in tre.
        XCTAssertEqual(cells, 96)
        XCTAssertEqual(rejoins, 2, "rientra: Direttore muto, rientro possibile, nessuna interruzione, servizi presenti")
        XCTAssertEqual(letSongEnds, 1, "lascia finire: in più nessun rientro possibile e la fine certa")
        XCTAssertEqual(plays, 3, "il tasto dice Play nelle celle di rientra e di lascia finire")
    }

    // MARK: - La ragione

    func testTheReasonFollowsTheOrderOfTheRule() {
        XCTAssertEqual(reason(.direttore, possible: true), .rejoinPossible)
        XCTAssertEqual(reason(.direttore, possible: false), .rejoinNotPossible)
        XCTAssertEqual(reason(.direttore, possible: true, interrupted: true, lost: true), .interruptionActive)
        XCTAssertEqual(reason(.direttore, possible: true, lost: true), .servicesLost)
        XCTAssertNil(reason(.direttore, silent: false, possible: true))
        XCTAssertNil(reason(.solo, possible: true))
        // A425 — la fine certa: dopo interruzione, servizi persi e rientro possibile.
        XCTAssertEqual(reason(.direttore, possible: false, ends: true), .songEndCertain)
        XCTAssertEqual(reason(.direttore, possible: true, ends: true), .rejoinPossible)
        XCTAssertEqual(reason(.direttore, possible: false, ends: true, interrupted: true), .interruptionActive)
        XCTAssertEqual(reason(.direttore, possible: false, ends: true, lost: true), .servicesLost)
        // La ragione «possibile» c'è se e solo se il tasto dice «rientra»; A425: la ragione «fine certa» se e solo se dice
        // «lascia finire».
        for role in roles {
            for silent in bools {
                for possible in bools {
                    for ends in bools {
                        for interrupted in bools {
                            for lost in bools {
                                let tap = silence(role, silent: silent, possible: possible, ends: ends,
                                                  interrupted: interrupted, lost: lost)?.tap
                                let why = reason(role, silent: silent, possible: possible, ends: ends,
                                                 interrupted: interrupted, lost: lost)
                                XCTAssertEqual(tap == nil, why == nil)
                                XCTAssertEqual(tap == .rejoin, why == .rejoinPossible)
                                XCTAssertEqual(tap == .letSongEnd, why == .songEndCertain)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - A425 — la fine certa (mandato A425, par. 2.3)

    /// Nell'ultimo tratto della canzone, col Direttore muto, nessun rientro possibile e la fine certa: il tasto dice Play e il
    /// tocco lascia finire la canzone (la «B» di Mauro del 01/11).
    func testInTheLastStretchWithTheCountCertainTheButtonSaysPlayAndLetsTheSongEnd() {
        let s = silence(.direttore, possible: false, ends: true)
        XCTAssertEqual(s, DirectorSilence(tap: .letSongEnd))
        XCTAssertEqual(s?.showsPlay, true, "la faccia è il Play di oggi")
        XCTAssertEqual(reason(.direttore, possible: false, ends: true), .songEndCertain)
    }

    /// La fine certa con un'interruzione in corso o coi servizi audio persi: il tasto resta Stop e il tocco ferma la band come
    /// oggi (la D4 (a), BOX5 «la regola del referee del 21/10»).
    func testTheSongEndWithAnInterruptionOrTheServicesLostStaysStop() {
        XCTAssertEqual(silence(.direttore, possible: false, ends: true, interrupted: true), DirectorSilence(tap: .stopBand))
        XCTAssertEqual(silence(.direttore, possible: false, ends: true, lost: true), DirectorSilence(tap: .stopBand))
        XCTAssertEqual(silence(.direttore, possible: false, ends: true, interrupted: true, lost: true), DirectorSilence(tap: .stopBand))
        XCTAssertEqual(silence(.direttore, possible: false, ends: true, interrupted: true)?.showsPlay, false)
        // Col conto non certo il coordinatore non dice «canzone finita»: senza la fine certa resta Stop (la D4 (a)).
        XCTAssertEqual(silence(.direttore, possible: false, ends: false), DirectorSilence(tap: .stopBand))
    }

    /// Il rientro possibile e la fine certa insieme: vince il rientro.
    func testRejoinAndSongEndTogetherTheRejoinWins() {
        XCTAssertEqual(silence(.direttore, possible: true, ends: true), DirectorSilence(tap: .rejoin))
    }

    /// Fuori dal silenzio, e per Solo e Follower, la fine certa non cambia niente: `nil`.
    func testOutsideTheSilenceTheSongEndGivesNil() {
        XCTAssertNil(silence(.direttore, silent: false, possible: false, ends: true))
        for role in [PlayerRole.solo, .follower] {
            for silent in bools {
                XCTAssertNil(silence(role, silent: silent, possible: false, ends: true), "ruolo:\(role) muto:\(silent)")
            }
        }
    }

    // MARK: - A425 — la regola del tocco su una faccia Play

    /// Faccia «rientra» toccata, riletta «lascia finire» (il rientro non è più possibile): nessun `start()`.
    func testATapOnAStaleRejoinFaceThatRereadsLetSongEndStartsNothing() {
        let outcome = DirectorTransportDecision.playFaceTap(rereadNow: silence(.direttore, possible: false, ends: true))
        XCTAssertEqual(outcome, .letSongEnd)
        XCTAssertFalse(outcome.startsEngine)
    }

    /// Faccia «lascia finire» toccata, riletta «rientra» (il rientro è tornato possibile): `start()`, al primo tocco.
    func testATapOnLetSongEndThatRereadsRejoinRejoinsAtTheFirstTap() {
        let outcome = DirectorTransportDecision.playFaceTap(rereadNow: silence(.direttore, possible: true, ends: true))
        XCTAssertEqual(outcome, .rejoin)
        XCTAssertTrue(outcome.startsEngine)
    }

    /// Faccia Play toccata, riletta Stop (il conto non più certo, un'interruzione, i servizi persi): niente, e la faccia
    /// pubblicata diventa Stop.
    func testATapOnAPlayFaceThatRereadsStopStopsNothingAndTheFaceChanges() {
        for reread in [silence(.direttore, possible: false, ends: false),
                       silence(.direttore, possible: true, ends: true, interrupted: true),
                       silence(.direttore, possible: true, ends: true, lost: true)] {
            let outcome = DirectorTransportDecision.playFaceTap(rereadNow: reread)
            XCTAssertEqual(outcome, .nothingStop)
            XCTAssertFalse(outcome.startsEngine)
            XCTAssertEqual(reread?.showsPlay, false, "la faccia che si ripubblica è Stop")
        }
    }

    /// Faccia Play toccata, il Direttore già fuori dal silenzio (il rientro fatto, lo Stop di fine canzone, uno Stop voluto): niente.
    func testATapOnAPlayFaceWithTheDirectorAlreadyOutOfTheSilenceDoesNothing() {
        let outcome = DirectorTransportDecision.playFaceTap(rereadNow: silence(.direttore, silent: false))
        XCTAssertEqual(outcome, .nothingOutsideSilence)
        XCTAssertFalse(outcome.startsEngine)
    }

    /// La regola su tutta la matrice: il tocco su una faccia Play fa partire qualcosa se e solo se la faccia riletta dice
    /// «rientra», e nessun esito ferma la band. Dentro un'interruzione la faccia è Stop: il tocco va a `stop()` come oggi.
    func testNoPlayFaceTapEverStopsTheBandAndOnlyARereadRejoinStarts() {
        var starts = 0
        for role in roles {
            for silent in bools {
                for possible in bools {
                    for ends in bools {
                        for interrupted in bools {
                            for lost in bools {
                                let reread = silence(role, silent: silent, possible: possible, ends: ends,
                                                     interrupted: interrupted, lost: lost)
                                let outcome = DirectorTransportDecision.playFaceTap(rereadNow: reread)
                                XCTAssertEqual(outcome.startsEngine, reread?.tap == .rejoin)
                                XCTAssertNotEqual(outcome.rawValue, DirectorTransportTap.stopBand.rawValue)
                                if outcome.startsEngine { starts += 1 }
                                if interrupted && role == .direttore && silent {
                                    XCTAssertEqual(reread?.showsPlay, false, "dentro un'interruzione la faccia è Stop")
                                }
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(starts, 2)
        XCTAssertEqual(DirectorPlayFaceTapOutcome.allCases.filter { $0.startsEngine }, [.rejoin])
    }

    func testTheNames() {
        XCTAssertEqual(DirectorTransportTap.rejoin.rawValue, "rientra")
        XCTAssertEqual(DirectorTransportTap.stopBand.rawValue, "ferma-la-band")
        XCTAssertEqual(DirectorTransportDecision.Reason.interruptionActive.rawValue, "interruzione-in-corso")
        XCTAssertEqual(DirectorTransportDecision.Reason.servicesLost.rawValue, "servizi-audio-persi")
        // A425 — i nomi delle righe del tasto e del tocco.
        XCTAssertEqual(DirectorTransportTap.letSongEnd.rawValue, "lascia-finire")
        XCTAssertEqual(DirectorTransportDecision.Reason.songEndCertain.rawValue, "fine-canzone-certa")
        XCTAssertEqual(DirectorPlayFaceTapOutcome.allCases.map { $0.rawValue },
                       ["rientra", "lascia-finire", "niente(stop)", "niente(fuori-dal-silenzio)"])
    }
}
