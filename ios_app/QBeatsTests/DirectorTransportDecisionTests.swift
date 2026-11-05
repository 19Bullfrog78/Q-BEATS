import XCTest

// === A412 — banco della regola del tasto della fascia (`DirectorTransportDecision`, banco Models), mandato §2.4 ===
// La matrice: ruolo del player × muto in canzone × rientro possibile adesso × interruzione in corso ×
// servizi audio persi = 3 × 2 × 2 × 2 × 2 = 48 celle (⚠️ RISCRITTO A426: c'era «48 celle» senza data; 48 in A412, 96 da A425,
// 192 da A426, nei blocchi qui sotto), con l'atteso scritto dalla regola del mandato. Poi
// i casi del collaudo: dopo un reset dei servizi audio (il solo silenzio che finisce col tocco) il tasto
// dice Play; fra la Lost e la Reset, durante un'interruzione o col conto non certo dice Stop; fuori dal
// silenzio il tasto è quello di oggi (`nil`). E la ragione, nell'ordine della regola.
// === A425 (mandato A425, par. 2.3) — l'ingresso nuovo «la canzone finisce col conto certo» e la regola del tocco ===
// ⚠️ RISCRITTO A426, c'era «La matrice segue l'ingresso nuovo: 3 × 2 × 2 × 2 × 2 × 2 = 96 celle (erano 48). Il tasto dice Play in
// tre celle»: in A425 96 celle e Play in tre; da A426 192 celle e Play in sette (blocco A426 qui sotto). In A425: «rientra»
// col rientro possibile, con e senza la fine certa (vince il rientro), e «lascia finire» con la sola fine certa; prima la cella
// era una, perché l'esito Play era solo «rientra». I casi nuovi: la fine certa con e senza interruzione o servizi persi, il
// rientro e la fine insieme, fuori dal silenzio `nil`; i quattro casi della regola del tocco su una faccia Play (riletta sulla
// coda: decide la faccia di adesso, mai un «ferma la band»).
// === A426 (mandato A426, par. 2.2-2.3) — l'ingresso nuovo «il rientro è armato» e il ramo del tocco ===
// La matrice segue l'ingresso nuovo: 3 × 2 × 2 × 2 × 2 × 2 × 2 = 192 celle (erano 96). Il tasto dice Play in sette celle:
// «rientro in arrivo» in quattro (il rientro armato, con e senza il rientro possibile e la fine certa: vince l'armato),
// «rientra» in due (non armato, rientro possibile, con e senza la fine certa), «lascia finire» in una (non armato, la sola fine
// certa). I casi nuovi: l'armato con e senza interruzione o servizi persi, l'armato col rientro possibile e con la fine certa,
// fuori dal silenzio `nil`; il tocco su «rientro in arrivo» (riletto «rientro in arrivo», «rientra», `nil`, Stop); il ramo del
// tocco su ogni faccia (`tapRoute`). E le due debolezze del banco viste dai verificatori del referee su A425 (mandato A426,
// par. 2.2): l'attesa sempre vera della proprietà sulla matrice e il nome di un test che prometteva più di quello che prova.

final class DirectorTransportDecisionTests: XCTestCase {

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]

    // A426 — `armed` (il rientro armato) vale `false` se il test non lo dice: i test di prima di A426 provano il mondo senza un
    // rientro armato, come prima. La regola invece non ha valori di default: questi due aiuti lo passano sempre.
    private func silence(_ role: PlayerRole, silent: Bool = true, armed: Bool = false, possible: Bool = true, ends: Bool = false,
                         interrupted: Bool = false, lost: Bool = false) -> DirectorSilence? {
        DirectorTransportDecision.silence(playerRole: role, silentInSong: silent, rejoinArmedNow: armed,
                                          rejoinPossibleNow: possible,
                                          songEndsCertainNow: ends, interruptionActive: interrupted, servicesLost: lost)
    }

    private func reason(_ role: PlayerRole, silent: Bool = true, armed: Bool = false, possible: Bool = true, ends: Bool = false,
                        interrupted: Bool = false, lost: Bool = false) -> DirectorTransportDecision.Reason? {
        DirectorTransportDecision.reason(playerRole: role, silentInSong: silent, rejoinArmedNow: armed,
                                         rejoinPossibleNow: possible,
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

    /// A425 — l'atteso scritto dalla regola del mandato A425, par. 2.3, ⚠️ RISCRITTO A426, c'era «nell'ordine: interruzione o
    /// servizi persi ⇒ Stop; rientro possibile ⇒ rientra; fine certa ⇒ lascia finire; se no Stop.»: A426 — dalla regola del
    /// mandato A426, par. 2.1, nell'ordine: interruzione o servizi persi ⇒ Stop; rientro armato ⇒ rientro in arrivo; rientro
    /// possibile ⇒ rientra; fine certa ⇒ lascia finire; se no Stop.
    private func expected(_ role: PlayerRole, silent: Bool, armed: Bool, possible: Bool, ends: Bool, interrupted: Bool,
                          lost: Bool) -> DirectorTransportTap? {
        guard role == .direttore, silent else { return nil }
        if interrupted || lost { return .stopBand }
        if armed { return .rejoinComing }
        if possible { return .rejoin }
        return ends ? .letSongEnd : .stopBand
    }

    func testTheMatrix() {
        var cells = 0
        var rejoins = 0
        var letSongEnds = 0
        var rejoinComings = 0
        var plays = 0
        for role in roles {
            for silent in bools {
                for armed in bools {
                    for possible in bools {
                        for ends in bools {
                            for interrupted in bools {
                                for lost in bools {
                                    cells += 1
                                    let got = silence(role, silent: silent, armed: armed, possible: possible, ends: ends,
                                                      interrupted: interrupted, lost: lost)
                                    let tag = "ruolo:\(role) muto:\(silent) armato:\(armed) possibile:\(possible) fine:\(ends) interruzione:\(interrupted) persi:\(lost)"
                                    XCTAssertEqual(got?.tap, expected(role, silent: silent, armed: armed, possible: possible,
                                                                      ends: ends, interrupted: interrupted, lost: lost), tag)
                                    if got?.tap == .rejoin { rejoins += 1 }
                                    if got?.tap == .letSongEnd { letSongEnds += 1 }
                                    if got?.tap == .rejoinComing { rejoinComings += 1 }
                                    if got?.showsPlay == true { plays += 1 }
                                }
                            }
                        }
                    }
                }
            }
        }
        // A425 — l'ingresso nuovo raddoppia le celle (48 → 96). «Rientra» esce in due celle (il rientro possibile, con e senza la
        // fine certa: vince il rientro), «lascia finire» in una (la sola fine certa); ⚠️ RISCRITTO A426, c'era «il tasto dice Play
        // in tre.»: A426 — il rientro armato raddoppia ancora le celle (96 → 192): «rientra» e «lascia finire» restano nelle celle
        // senza l'armato (due e una), «rientro in arrivo» esce in quattro (l'armato, con e senza il rientro possibile e la fine
        // certa: vince l'armato); il tasto dice Play in sette.
        XCTAssertEqual(cells, 192)
        XCTAssertEqual(rejoins, 2, "rientra: Direttore muto, nessun rientro armato, rientro possibile, nessuna interruzione, servizi presenti")
        XCTAssertEqual(letSongEnds, 1, "lascia finire: in più nessun rientro possibile e la fine certa")
        XCTAssertEqual(rejoinComings, 4, "rientro in arrivo: Direttore muto, rientro armato, nessuna interruzione, servizi presenti")
        XCTAssertEqual(plays, 7, "il tasto dice Play nelle celle di rientra, di lascia finire e di rientro in arrivo")
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
        // A426 — il rientro armato: dopo interruzione e servizi persi, prima del rientro possibile e della fine certa.
        XCTAssertEqual(reason(.direttore, armed: true, possible: false), .rejoinArmed)
        XCTAssertEqual(reason(.direttore, armed: true, possible: true, ends: true), .rejoinArmed)
        XCTAssertEqual(reason(.direttore, armed: true, possible: true, interrupted: true), .interruptionActive)
        XCTAssertEqual(reason(.direttore, armed: true, possible: true, lost: true), .servicesLost)
        XCTAssertNil(reason(.direttore, silent: false, armed: true))
        XCTAssertNil(reason(.follower, armed: true))
        // La ragione «possibile» c'è se e solo se il tasto dice «rientra»; A425: la ragione «fine certa» se e solo se dice
        // «lascia finire»; A426: la ragione «rientro armato» se e solo se dice «rientro in arrivo».
        for role in roles {
            for silent in bools {
                for armed in bools {
                    for possible in bools {
                        for ends in bools {
                            for interrupted in bools {
                                for lost in bools {
                                    let tap = silence(role, silent: silent, armed: armed, possible: possible, ends: ends,
                                                      interrupted: interrupted, lost: lost)?.tap
                                    let why = reason(role, silent: silent, armed: armed, possible: possible, ends: ends,
                                                     interrupted: interrupted, lost: lost)
                                    XCTAssertEqual(tap == nil, why == nil)
                                    XCTAssertEqual(tap == .rejoin, why == .rejoinPossible)
                                    XCTAssertEqual(tap == .letSongEnd, why == .songEndCertain)
                                    XCTAssertEqual(tap == .rejoinComing, why == .rejoinArmed)
                                }
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
    /// riletta è Stop. ⚠️ RISCRITTO A426 (mandato A426, par. 2.2), c'era «pubblicata diventa Stop» e il nome finiva con
    /// «AndTheFaceChanges»: il banco vede solo la faccia riletta; la pubblicazione è del motore (`publishDirectorFaceQ`).
    func testATapOnAPlayFaceThatRereadsStopStopsNothingAndTheRereadFaceIsStop() {
        for reread in [silence(.direttore, possible: false, ends: false),
                       silence(.direttore, possible: true, ends: true, interrupted: true),
                       silence(.direttore, possible: true, ends: true, lost: true)] {
            let outcome = DirectorTransportDecision.playFaceTap(rereadNow: reread)
            XCTAssertEqual(outcome, .nothingStop)
            XCTAssertFalse(outcome.startsEngine)
            XCTAssertEqual(reread?.showsPlay, false, "la faccia riletta è Stop")
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
    /// ⚠️ RISCRITTO A426 (mandato A426, par. 2.2): qui c'era anche «XCTAssertNotEqual(outcome.rawValue,
    /// DirectorTransportTap.stopBand.rawValue)», un confronto fra due stringhe sempre vero (nessun esito di `playFaceTap` si chiama
    /// «ferma-la-band»): non poteva cadere, e si è tolto. La garanzia «da una faccia Play mai uno Stop» la dà il tipo:
    /// `DirectorPlayFaceTapOutcome` non ha un esito che ferma la band. Restano le prove che possono cadere: l'elenco esatto degli
    /// esiti (`testTheNames`), «solo rientra fa partire qualcosa» (in fondo qui) e, da A426, l'esito atteso per ogni faccia
    /// riletta (`expectedOutcome`).
    func testNoPlayFaceTapEverStopsTheBandAndOnlyARereadRejoinStarts() {
        var starts = 0
        for role in roles {
            for silent in bools {
                for armed in bools {
                    for possible in bools {
                        for ends in bools {
                            for interrupted in bools {
                                for lost in bools {
                                    let reread = silence(role, silent: silent, armed: armed, possible: possible, ends: ends,
                                                         interrupted: interrupted, lost: lost)
                                    let outcome = DirectorTransportDecision.playFaceTap(rereadNow: reread)
                                    XCTAssertEqual(outcome.startsEngine, reread?.tap == .rejoin)
                                    XCTAssertEqual(outcome, expectedOutcome(reread?.tap))
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
        }
        XCTAssertEqual(starts, 2)
        XCTAssertEqual(DirectorPlayFaceTapOutcome.allCases.filter { $0.startsEngine }, [.rejoin])
    }

    /// A426 — l'esito atteso per la faccia riletta, scritto dalla regola del tocco (mandato A425, par. 2.3; mandato A426, par.
    /// 2.1): `nil` ⇒ niente fuori dal silenzio; «rientra» ⇒ rientra; «lascia finire» ⇒ lascia finire; Stop ⇒ niente, nessuno
    /// stop; «rientro in arrivo» ⇒ niente, né avvio né stop.
    private func expectedOutcome(_ reread: DirectorTransportTap?) -> DirectorPlayFaceTapOutcome {
        guard let tap = reread else { return .nothingOutsideSilence }
        switch tap {
        case .rejoin: return .rejoin
        case .letSongEnd: return .letSongEnd
        case .stopBand: return .nothingStop
        case .rejoinComing: return .nothingRejoinComing
        }
    }

    func testTheNames() {
        XCTAssertEqual(DirectorTransportTap.rejoin.rawValue, "rientra")
        XCTAssertEqual(DirectorTransportTap.stopBand.rawValue, "ferma-la-band")
        XCTAssertEqual(DirectorTransportDecision.Reason.interruptionActive.rawValue, "interruzione-in-corso")
        XCTAssertEqual(DirectorTransportDecision.Reason.servicesLost.rawValue, "servizi-audio-persi")
        // A425 — i nomi delle righe del tasto e del tocco.
        XCTAssertEqual(DirectorTransportTap.letSongEnd.rawValue, "lascia-finire")
        XCTAssertEqual(DirectorTransportDecision.Reason.songEndCertain.rawValue, "fine-canzone-certa")
        // A426 — col caso nuovo l'elenco degli esiti ha cinque voci (erano quattro).
        XCTAssertEqual(DirectorPlayFaceTapOutcome.allCases.map { $0.rawValue },
                       ["rientra", "lascia-finire", "niente(stop)", "niente(fuori-dal-silenzio)", "niente(rientro-in-arrivo)"])
        // A426 — i nomi nuovi delle righe del tasto e del tocco, e l'elenco esatto delle facce.
        XCTAssertEqual(DirectorTransportTap.rejoinComing.rawValue, "rientro-in-arrivo")
        XCTAssertEqual(DirectorTransportDecision.Reason.rejoinArmed.rawValue, "rientro-armato")
        XCTAssertEqual(DirectorPlayFaceTapOutcome.nothingRejoinComing.rawValue, "niente(rientro-in-arrivo)")
        XCTAssertEqual(DirectorTransportTap.allCases.map { $0.rawValue },
                       ["rientra", "ferma-la-band", "lascia-finire", "rientro-in-arrivo"])
    }

    // MARK: - A426 — il rientro armato (mandato A426, par. 2.1)

    /// Mentre il rientro è armato e il click sta per tornare: il tasto dice Play, «rientro in arrivo» (la «B» di Mauro del 05/11).
    func testWhileTheRejoinIsArmedTheButtonSaysPlayRejoinComing() {
        let s = silence(.direttore, armed: true, possible: false)
        XCTAssertEqual(s, DirectorSilence(tap: .rejoinComing))
        XCTAssertEqual(s?.showsPlay, true, "la faccia è il Play di oggi")
        XCTAssertEqual(reason(.direttore, armed: true, possible: false), .rejoinArmed)
    }

    /// Il rientro armato con un'interruzione in corso o coi servizi audio persi: Stop (la D4 (a) del 16/10 vince su tutto).
    func testTheArmedRejoinWithAnInterruptionOrTheServicesLostStaysStop() {
        XCTAssertEqual(silence(.direttore, armed: true, interrupted: true), DirectorSilence(tap: .stopBand))
        XCTAssertEqual(silence(.direttore, armed: true, lost: true), DirectorSilence(tap: .stopBand))
        XCTAssertEqual(silence(.direttore, armed: true, interrupted: true, lost: true), DirectorSilence(tap: .stopBand))
        XCTAssertEqual(silence(.direttore, armed: true, interrupted: true)?.showsPlay, false)
        XCTAssertEqual(silence(.direttore, armed: true, possible: false, interrupted: true), DirectorSilence(tap: .stopBand))
    }

    /// Armato e possibile insieme (nel motore non succede: col rientro armato il coordinatore non si legge) e armato con la fine
    /// certa: la regola dice armato.
    func testTheArmedRejoinWinsOverPossibleAndSongEnd() {
        XCTAssertEqual(silence(.direttore, armed: true, possible: true), DirectorSilence(tap: .rejoinComing))
        XCTAssertEqual(silence(.direttore, armed: true, possible: true, ends: true), DirectorSilence(tap: .rejoinComing))
        XCTAssertEqual(silence(.direttore, armed: true, possible: false, ends: true), DirectorSilence(tap: .rejoinComing))
    }

    /// Fuori dal silenzio, e per Solo e Follower, il rientro armato non cambia niente: `nil`.
    func testOutsideTheSilenceTheArmedRejoinGivesNil() {
        XCTAssertNil(silence(.direttore, silent: false, armed: true))
        for role in [PlayerRole.solo, .follower] {
            for silent in bools {
                XCTAssertNil(silence(role, silent: silent, armed: true), "ruolo:\(role) muto:\(silent)")
            }
        }
    }

    // MARK: - A426 — il tocco su «rientro in arrivo» (mandato A426, par. 2.1 e 2.3)

    /// Il secondo tocco: faccia «rientro in arrivo» toccata, riletta «rientro in arrivo» (il rientro è ancora armato): niente, né
    /// `start()` né `stop()`. Il ramo va alla rilettura, mai a `stop()`.
    func testASecondTapWhileTheRejoinIsArmedDoesNothing() {
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .rejoinComing), .reread)
        let outcome = DirectorTransportDecision.playFaceTap(rereadNow: silence(.direttore, armed: true, possible: false))
        XCTAssertEqual(outcome, .nothingRejoinComing)
        XCTAssertFalse(outcome.startsEngine)
    }

    /// Faccia «rientro in arrivo» toccata, riletta «rientra» (il rientro annullato e di nuovo possibile): `start()`, il rientro.
    func testATapOnRejoinComingThatRereadsRejoinRejoins() {
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .rejoinComing), .reread)
        let outcome = DirectorTransportDecision.playFaceTap(rereadNow: silence(.direttore, armed: false, possible: true))
        XCTAssertEqual(outcome, .rejoin)
        XCTAssertTrue(outcome.startsEngine)
    }

    /// Faccia «rientro in arrivo» toccata, riletta `nil` (il fuoco già fatto: il silenzio è finito): niente.
    func testATapOnRejoinComingAfterTheFireDoesNothing() {
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .rejoinComing), .reread)
        let outcome = DirectorTransportDecision.playFaceTap(rereadNow: silence(.direttore, silent: false))
        XCTAssertEqual(outcome, .nothingOutsideSilence)
        XCTAssertFalse(outcome.startsEngine)
    }

    /// Faccia «rientro in arrivo» toccata, riletta Stop (un'interruzione, i servizi persi, il rientro che non è partito col conto
    /// non certo): il tocco non ferma niente.
    func testATapOnRejoinComingThatRereadsStopStopsNothing() {
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .rejoinComing), .reread)
        for reread in [silence(.direttore, armed: true, interrupted: true),
                       silence(.direttore, armed: true, lost: true),
                       silence(.direttore, armed: false, possible: false, ends: false)] {
            let outcome = DirectorTransportDecision.playFaceTap(rereadNow: reread)
            XCTAssertEqual(outcome, .nothingStop)
            XCTAssertFalse(outcome.startsEngine)
            XCTAssertEqual(reread?.tap, .stopBand)
        }
    }

    /// Il ramo del tocco su ogni faccia (`tapRoute`): la faccia Stop va a `stop()`, ogni faccia Play alla rilettura sulla coda.
    /// Una faccia Play finita per errore nel ramo dello Stop, o la faccia Stop nella rilettura, fa cadere questo test.
    func testTheTapRouteOnEveryFace() {
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .stopBand), .wantedStop)
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .rejoin), .reread)
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .letSongEnd), .reread)
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .rejoinComing), .reread)
        for face in DirectorTransportTap.allCases {
            let route = DirectorTransportDecision.tapRoute(face: face)
            XCTAssertEqual(route == .wantedStop, face == .stopBand, "faccia:\(face.rawValue)")
            XCTAssertEqual(route == .reread, DirectorSilence(tap: face).showsPlay, "faccia:\(face.rawValue): Play se e solo se rilettura")
        }
        XCTAssertEqual(DirectorTransportTap.allCases.count, 4)
        XCTAssertEqual(DirectorTapRoute.allCases.count, 2)
    }
}
