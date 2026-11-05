import XCTest

// === A412 — banco della regola del tasto della fascia (`DirectorTransportDecision`, banco Models), mandato §2.4 ===
// La matrice: ruolo del player × muto in canzone × rientro possibile adesso × interruzione in corso ×
// servizi audio persi = 3 × 2 × 2 × 2 × 2 = 48 celle (⚠️ RISCRITTO A426: c'era «48 celle» senza data; ⚠️ RISCRITTO A427, c'era
// «48 in A412, 96 da A425, 192 da A426, nei blocchi qui sotto»: 48 in A412, 96 da A425, 192 da A426, 384 da A427, nei blocchi qui
// sotto), con l'atteso scritto dalla regola del mandato. Poi
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
// ⚠️ RISCRITTO A427, c'era «La matrice segue l'ingresso nuovo: 3 × 2 × 2 × 2 × 2 × 2 × 2 = 192 celle (erano 96). Il tasto dice Play
// in sette celle»: in A426 192 celle e Play in sette; da A427 384 celle e Play in ventitré (blocco A427 qui sotto). In A426:
// «rientro in arrivo» in quattro (il rientro armato, con e senza il rientro possibile e la fine certa: vince l'armato),
// «rientra» in due (non armato, rientro possibile, con e senza la fine certa), «lascia finire» in una (non armato, la sola fine
// certa). I casi nuovi: l'armato con e senza interruzione o servizi persi, l'armato col rientro possibile e con la fine certa,
// fuori dal silenzio `nil`; il tocco su «rientro in arrivo» (riletto «rientro in arrivo», «rientra», `nil`, Stop); il ramo del
// tocco su ogni faccia (`tapRoute`). E le due debolezze del banco viste dai verificatori del referee su A425 (mandato A426,
// par. 2.2): l'attesa sempre vera della proprietà sulla matrice e il nome di un test che prometteva più di quello che prova.
// === A427 (mandato A427, par. 2.2) — l'ingresso nuovo «il primo click del rientro in arrivo» e la regola pura dell'ora ===
// La matrice segue l'ingresso nuovo: 3 × 2 × 2 × 2 × 2 × 2 × 2 × 2 = 384 celle (erano 192). «Rientro in arrivo» in venti celle
// (il rientro armato in dodici, il primo click in arrivo senza l'armato in otto, col Direttore muto e non muto), «rientra» in due,
// «lascia finire» in una: il tasto dice Play in ventitré, Stop in settantatré, `nil` in duecentottantotto (Solo e Follower, e il
// Direttore né muto né col primo click in arrivo). I casi nuovi: il primo click in arrivo col Direttore non muto e muto, con e
// senza interruzione o servizi persi, col rientro possibile e con la fine certa, insieme al rientro armato; il secondo tocco fra
// il fuoco e l'«uno» (riletto «rientro in arrivo»: niente) e il tocco proprio sull'«uno» (riletto `nil`: niente); la regola pura
// dell'ora (prima, proprio all'ora, dopo, nessuna ora). E i due test di A426 che cadono solo dalla parte del ramo, col nome e il
// commento che dicono che cosa provano (note dei verificatori del referee su A426: auditor N4, B2-1 N6).

final class DirectorTransportDecisionTests: XCTestCase {

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]

    // A426 — `armed` (il rientro armato) vale `false` se il test non lo dice: i test di prima di A426 provano il mondo senza un
    // rientro armato, come prima. La regola invece non ha valori di default: questi due aiuti lo passano sempre.
    // A427 — lo stesso per `pending` (il primo click del rientro in arrivo): i test di prima di A427 provano il mondo senza.
    private func silence(_ role: PlayerRole, silent: Bool = true, armed: Bool = false, pending: Bool = false, possible: Bool = true,
                         ends: Bool = false, interrupted: Bool = false, lost: Bool = false) -> DirectorSilence? {
        DirectorTransportDecision.silence(playerRole: role, silentInSong: silent, rejoinArmedNow: armed,
                                          rejoinClickPendingNow: pending,
                                          rejoinPossibleNow: possible,
                                          songEndsCertainNow: ends, interruptionActive: interrupted, servicesLost: lost)
    }

    private func reason(_ role: PlayerRole, silent: Bool = true, armed: Bool = false, pending: Bool = false, possible: Bool = true,
                        ends: Bool = false, interrupted: Bool = false, lost: Bool = false) -> DirectorTransportDecision.Reason? {
        DirectorTransportDecision.reason(playerRole: role, silentInSong: silent, rejoinArmedNow: armed,
                                         rejoinClickPendingNow: pending,
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

    /// ⚠️ RISCRITTO A427, c'era «Fuori dal silenzio, e per il Solo e il Follower, il tasto è quello di oggi.»: fuori dal silenzio e
    /// senza il primo click del rientro in arrivo (gli aiuti, se il test non lo dice), e per il Solo e il Follower, il tasto è quello
    /// di oggi.
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
    /// A427 — dalla regola del mandato A427, par. 2.1, nell'ordine: ruolo diverso dal Direttore ⇒ `nil`; Direttore né muto né col
    /// primo click in arrivo ⇒ `nil`; interruzione o servizi persi ⇒ Stop; rientro armato ⇒ rientro in arrivo; primo click in
    /// arrivo ⇒ rientro in arrivo; rientro possibile ⇒ rientra; fine certa ⇒ lascia finire; se no Stop.
    private func expected(_ role: PlayerRole, silent: Bool, armed: Bool, pending: Bool, possible: Bool, ends: Bool,
                          interrupted: Bool, lost: Bool) -> DirectorTransportTap? {
        guard role == .direttore else { return nil }
        guard silent || pending else { return nil }
        if interrupted || lost { return .stopBand }
        if armed { return .rejoinComing }
        if pending { return .rejoinComing }
        if possible { return .rejoin }
        return ends ? .letSongEnd : .stopBand
    }

    func testTheMatrix() {
        var cells = 0
        var rejoins = 0
        var letSongEnds = 0
        var rejoinComings = 0
        var plays = 0
        var stops = 0
        var nils = 0
        for role in roles {
            for silent in bools {
                for armed in bools {
                    for pending in bools {
                        for possible in bools {
                            for ends in bools {
                                for interrupted in bools {
                                    for lost in bools {
                                        cells += 1
                                        let got = silence(role, silent: silent, armed: armed, pending: pending, possible: possible,
                                                          ends: ends, interrupted: interrupted, lost: lost)
                                        let tag = "ruolo:\(role) muto:\(silent) armato:\(armed) clickInArrivo:\(pending) possibile:\(possible) fine:\(ends) interruzione:\(interrupted) persi:\(lost)"
                                        XCTAssertEqual(got?.tap, expected(role, silent: silent, armed: armed, pending: pending,
                                                                          possible: possible, ends: ends, interrupted: interrupted,
                                                                          lost: lost), tag)
                                        if got?.tap == .rejoin { rejoins += 1 }
                                        if got?.tap == .letSongEnd { letSongEnds += 1 }
                                        if got?.tap == .rejoinComing { rejoinComings += 1 }
                                        if got?.showsPlay == true { plays += 1 }
                                        if got?.tap == .stopBand { stops += 1 }
                                        if got == nil { nils += 1 }
                                    }
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
        // certa: vince l'armato); ⚠️ RISCRITTO A427, c'era «il tasto dice Play in sette.»: in A426 il tasto diceva Play in sette.
        // A427 — il primo click in arrivo raddoppia ancora le celle (192 → 384): «rientra» e «lascia finire» restano due e una (il
        // Direttore muto, né armato né col click in arrivo); «rientro in arrivo» esce in venti: dodici col rientro armato (il
        // Direttore muto, o non muto col click in arrivo), otto col solo click in arrivo (muto e non muto), sempre senza
        // interruzione e coi servizi presenti, con e senza il rientro possibile e la fine certa; il tasto dice Play in ventitré, Stop
        // in settantatré (le settantadue celle con l'interruzione o i servizi persi, e la cella senza niente), `nil` nelle altre
        // duecentottantotto (Solo e Follower in duecentocinquantasei, il Direttore né muto né col click in arrivo in trentadue).
        XCTAssertEqual(cells, 384)
        XCTAssertEqual(rejoins, 2, "rientra: Direttore muto, nessun rientro armato né click in arrivo, rientro possibile, nessuna interruzione, servizi presenti")
        XCTAssertEqual(letSongEnds, 1, "lascia finire: in più nessun rientro possibile e la fine certa")
        XCTAssertEqual(rejoinComings, 20, "rientro in arrivo: rientro armato o primo click in arrivo, nessuna interruzione, servizi presenti")
        XCTAssertEqual(plays, 23, "il tasto dice Play nelle celle di rientra, di lascia finire e di rientro in arrivo")
        XCTAssertEqual(stops, 73, "Stop: interruzione o servizi persi, o il Direttore muto senza niente")
        XCTAssertEqual(nils, 288, "nil: Solo, Follower, e il Direttore né muto né col primo click in arrivo")
        XCTAssertEqual(plays + stops + nils, cells)
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
        // A427 — il primo click in arrivo: dopo interruzione, servizi persi e rientro armato, prima del rientro possibile e della
        // fine certa; col Direttore non muto la ragione c'è (la faccia non è `nil`).
        XCTAssertEqual(reason(.direttore, silent: false, pending: true, possible: false), .rejoinClickPending)
        XCTAssertEqual(reason(.direttore, silent: false, pending: true, possible: true, ends: true), .rejoinClickPending)
        XCTAssertEqual(reason(.direttore, silent: false, pending: true, interrupted: true), .interruptionActive)
        XCTAssertEqual(reason(.direttore, silent: false, pending: true, lost: true), .servicesLost)
        XCTAssertEqual(reason(.direttore, silent: false, armed: true, pending: true), .rejoinArmed)
        XCTAssertNil(reason(.direttore, silent: false, pending: false))
        XCTAssertNil(reason(.solo, silent: false, pending: true))
        // La ragione «possibile» c'è se e solo se il tasto dice «rientra»; A425: la ragione «fine certa» se e solo se dice
        // «lascia finire»; A426: ⚠️ RISCRITTO A427, c'era «la ragione «rientro armato» se e solo se dice «rientro in arrivo».» (e
        // il controllo `tap == .rejoinComing` ⇔ `why == .rejoinArmed`, che col primo click in arrivo cade): da A427 «rientro in
        // arrivo» se e solo se la ragione è «rientro armato» o «primo click in arrivo»; e «primo click in arrivo» solo senza
        // l'armato, che viene prima.
        for role in roles {
            for silent in bools {
                for armed in bools {
                    for pending in bools {
                        for possible in bools {
                            for ends in bools {
                                for interrupted in bools {
                                    for lost in bools {
                                        let tap = silence(role, silent: silent, armed: armed, pending: pending, possible: possible,
                                                          ends: ends, interrupted: interrupted, lost: lost)?.tap
                                        let why = reason(role, silent: silent, armed: armed, pending: pending, possible: possible,
                                                         ends: ends, interrupted: interrupted, lost: lost)
                                        XCTAssertEqual(tap == nil, why == nil)
                                        XCTAssertEqual(tap == .rejoin, why == .rejoinPossible)
                                        XCTAssertEqual(tap == .letSongEnd, why == .songEndCertain)
                                        XCTAssertEqual(tap == .rejoinComing, why == .rejoinArmed || why == .rejoinClickPending)
                                        XCTAssertEqual(why == .rejoinClickPending, tap == .rejoinComing && !armed)
                                    }
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

    /// Faccia Play toccata, il Direttore già fuori dal silenzio (⚠️ RISCRITTO A427, c'era «il rientro fatto»: il rientro fatto e il
    /// suo primo click già uscito, lo Stop di fine canzone, uno Stop voluto): niente.
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
                    for pending in bools {
                        for possible in bools {
                            for ends in bools {
                                for interrupted in bools {
                                    for lost in bools {
                                        let reread = silence(role, silent: silent, armed: armed, pending: pending,
                                                             possible: possible, ends: ends, interrupted: interrupted, lost: lost)
                                        let outcome = DirectorTransportDecision.playFaceTap(rereadNow: reread)
                                        XCTAssertEqual(outcome.startsEngine, reread?.tap == .rejoin)
                                        XCTAssertEqual(outcome, expectedOutcome(reread?.tap))
                                        if outcome.startsEngine { starts += 1 }
                                        // A427 — anche col primo click in arrivo (il Direttore non muto): dentro un'interruzione Stop.
                                        if interrupted && role == .direttore && (silent || pending) {
                                            XCTAssertEqual(reread?.showsPlay, false, "dentro un'interruzione la faccia è Stop")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // A427 — col primo click in arrivo gli avvii restano due: «rientra» esce solo senza l'armato e senza il click in arrivo.
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
        // A427 — il motivo nuovo della riga del tasto.
        XCTAssertEqual(DirectorTransportDecision.Reason.rejoinClickPending.rawValue, "primo-click-in-arrivo")
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

    /// ⚠️ RISCRITTO A427, c'era «Fuori dal silenzio, e per Solo e Follower, il rientro armato non cambia niente: `nil`.»: fuori dal
    /// silenzio senza il primo click in arrivo (gli aiuti, se il test non lo dice), e per Solo e Follower, il rientro armato non
    /// cambia niente: `nil`.
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

    /// ⚠️ RISCRITTO A427 (mandato A427, par. 2.2; note dei verificatori del referee su A426: auditor N4, B2-1 N6), c'era «Faccia
    /// «rientro in arrivo» toccata, riletta «rientra» (il rientro annullato e di nuovo possibile): `start()`, il rientro.» e il nome
    /// `testATapOnRejoinComingThatRereadsRejoinRejoins`: il test prova il ramo del tocco su «rientro in arrivo» (`tapRoute`, A426: la
    /// rilettura) e la regola della rilettura di A425 (riletta «rientra» ⇒ `start()`). La faccia riletta la scrive il test con gli
    /// aiuti: cade se cambia il ramo o la regola del tocco, non se cambia la regola della faccia.
    func testATapOnRejoinComingTakesTheRereadRouteAndARereadRejoinRejoins() {
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .rejoinComing), .reread)
        let outcome = DirectorTransportDecision.playFaceTap(rereadNow: silence(.direttore, armed: false, possible: true))
        XCTAssertEqual(outcome, .rejoin)
        XCTAssertTrue(outcome.startsEngine)
    }

    /// ⚠️ RISCRITTO A427 (mandato A427, par. 2.2; note dei verificatori del referee su A426: auditor N4, B2-1 N6), c'era «Faccia
    /// «rientro in arrivo» toccata, riletta `nil` (il fuoco già fatto: il silenzio è finito): niente.» e il nome
    /// `testATapOnRejoinComingAfterTheFireDoesNothing`: da A427 dopo il fuoco, fino al primo click, la rilettura dice ancora
    /// «rientro in arrivo» (`testASecondTapBetweenTheFireAndTheFirstClickDoesNothing`). Il test prova il ramo del tocco su
    /// «rientro in arrivo» (`tapRoute`) e la regola della rilettura di A425 (riletta `nil` ⇒ niente), con la faccia `nil` scritta
    /// dal test (fuori dal silenzio e senza il primo click in arrivo: dopo il primo click).
    func testATapOnRejoinComingTakesTheRereadRouteAndARereadOutsideTheSilenceDoesNothing() {
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

    // MARK: - A427 — il primo click del rientro in arrivo (mandato A427, par. 2.1-2.2)

    /// Dal fuoco al primo click del rientro: il Direttore non è più muto e il primo click è in arrivo; il tasto dice Play,
    /// «rientro in arrivo», col motivo «primo-click-in-arrivo» (la «B» di Mauro del 05/11: il click sta già tornando).
    func testFromTheFireToTheFirstClickTheButtonSaysPlayRejoinComing() {
        let s = silence(.direttore, silent: false, pending: true, possible: false)
        XCTAssertEqual(s, DirectorSilence(tap: .rejoinComing))
        XCTAssertEqual(s?.showsPlay, true, "la faccia è il Play di oggi")
        XCTAssertEqual(reason(.direttore, silent: false, pending: true, possible: false), .rejoinClickPending)
        // Col Direttore muto (nel motore non succede: il fuoco alza il click in arrivo e chiude il silenzio) la regola dice lo stesso.
        XCTAssertEqual(silence(.direttore, silent: true, pending: true, possible: false), DirectorSilence(tap: .rejoinComing))
        XCTAssertEqual(reason(.direttore, silent: true, pending: true, possible: false), .rejoinClickPending)
    }

    /// Il primo click in arrivo con un'interruzione in corso o coi servizi audio persi: Stop (la D4 (a) del 16/10 vince su tutto),
    /// col Direttore non muto e muto.
    func testTheClickPendingWithAnInterruptionOrTheServicesLostStaysStop() {
        for silent in bools {
            XCTAssertEqual(silence(.direttore, silent: silent, pending: true, interrupted: true), DirectorSilence(tap: .stopBand),
                           "muto:\(silent)")
            XCTAssertEqual(silence(.direttore, silent: silent, pending: true, lost: true), DirectorSilence(tap: .stopBand),
                           "muto:\(silent)")
            XCTAssertEqual(silence(.direttore, silent: silent, pending: true, interrupted: true, lost: true),
                           DirectorSilence(tap: .stopBand), "muto:\(silent)")
            XCTAssertEqual(silence(.direttore, silent: silent, pending: true, interrupted: true)?.showsPlay, false, "muto:\(silent)")
        }
    }

    /// Il primo click in arrivo vince sul rientro possibile e sulla fine certa; insieme al rientro armato (nel motore non succede:
    /// il fuoco abbassa l'armato dove alza il click in arrivo) la regola dice «rientro in arrivo», col motivo dell'armato, che
    /// viene prima.
    func testTheClickPendingWinsOverPossibleAndSongEndAndWithTheArmedRejoinSaysRejoinComing() {
        XCTAssertEqual(silence(.direttore, silent: false, pending: true, possible: true), DirectorSilence(tap: .rejoinComing))
        XCTAssertEqual(silence(.direttore, silent: false, pending: true, possible: false, ends: true),
                       DirectorSilence(tap: .rejoinComing))
        XCTAssertEqual(silence(.direttore, silent: true, pending: true, possible: true, ends: true),
                       DirectorSilence(tap: .rejoinComing))
        XCTAssertEqual(reason(.direttore, silent: true, pending: true, possible: true, ends: true), .rejoinClickPending)
        XCTAssertEqual(silence(.direttore, silent: true, armed: true, pending: true), DirectorSilence(tap: .rejoinComing))
        XCTAssertEqual(silence(.direttore, silent: false, armed: true, pending: true), DirectorSilence(tap: .rejoinComing))
        XCTAssertEqual(reason(.direttore, silent: true, armed: true, pending: true), .rejoinArmed)
        XCTAssertEqual(reason(.direttore, silent: false, armed: true, pending: true), .rejoinArmed)
    }

    /// Fuori dal Direttore il primo click in arrivo non cambia niente (`nil`); e il Direttore né muto né col primo click in arrivo
    /// (dopo il primo click) ha il tasto di oggi.
    func testOutsideTheDirectorTheClickPendingGivesNilAndAfterTheFirstClickTheButtonIsTodays() {
        for role in [PlayerRole.solo, .follower] {
            for silent in bools {
                XCTAssertNil(silence(role, silent: silent, pending: true), "ruolo:\(role) muto:\(silent)")
                XCTAssertNil(reason(role, silent: silent, pending: true), "ruolo:\(role) muto:\(silent)")
            }
        }
        XCTAssertNil(silence(.direttore, silent: false, pending: false))
        XCTAssertNil(reason(.direttore, silent: false, pending: false))
    }

    /// Il secondo tocco fra il fuoco e l'«uno»: faccia «rientro in arrivo» toccata, va alla rilettura (mai a `stop()`), riletta
    /// «rientro in arrivo» col primo click ancora in arrivo: niente, né `start()` né `stop()`.
    func testASecondTapBetweenTheFireAndTheFirstClickDoesNothing() {
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .rejoinComing), .reread)
        let reread = silence(.direttore, silent: false, pending: true, possible: false)
        XCTAssertEqual(reread?.tap, .rejoinComing)
        let outcome = DirectorTransportDecision.playFaceTap(rereadNow: reread)
        XCTAssertEqual(outcome, .nothingRejoinComing)
        XCTAssertFalse(outcome.startsEngine)
    }

    /// Il tocco proprio sull'«uno», col primo click già uscito ma prima del controllo del motore: la regola dell'ora dice «non più
    /// in arrivo», la rilettura è `nil` e il tocco non fa niente (nessuno `stop()`: il ramo è la rilettura).
    func testATapRightAtTheFirstClickRereadsOutsideAndDoesNothing() {
        let uno: UInt64 = 1_000_000
        let pending = DirectorTransportDecision.rejoinClickPending(unoOutputTicks: uno, nowTicks: uno)
        XCTAssertFalse(pending)
        let reread = silence(.direttore, silent: false, pending: pending, possible: false)
        XCTAssertNil(reread)
        XCTAssertEqual(DirectorTransportDecision.tapRoute(face: .rejoinComing), .reread)
        let outcome = DirectorTransportDecision.playFaceTap(rereadNow: reread)
        XCTAssertEqual(outcome, .nothingOutsideSilence)
        XCTAssertFalse(outcome.startsEngine)
    }

    /// La regola pura dell'ora: in arrivo prima dell'ora d'uscita dell'«uno»; proprio all'ora e dopo, uscito; nessuna ora, niente
    /// click in arrivo.
    func testTheFirstClickTimeRule() {
        let uno: UInt64 = 24_000_000
        XCTAssertTrue(DirectorTransportDecision.rejoinClickPending(unoOutputTicks: uno, nowTicks: uno - 1), "prima")
        XCTAssertTrue(DirectorTransportDecision.rejoinClickPending(unoOutputTicks: uno, nowTicks: 0), "molto prima")
        XCTAssertFalse(DirectorTransportDecision.rejoinClickPending(unoOutputTicks: uno, nowTicks: uno), "proprio all'ora")
        XCTAssertFalse(DirectorTransportDecision.rejoinClickPending(unoOutputTicks: uno, nowTicks: uno + 1), "dopo")
        XCTAssertFalse(DirectorTransportDecision.rejoinClickPending(unoOutputTicks: uno, nowTicks: UInt64.max), "molto dopo")
        XCTAssertFalse(DirectorTransportDecision.rejoinClickPending(unoOutputTicks: nil, nowTicks: 0), "nessuna ora")
        XCTAssertFalse(DirectorTransportDecision.rejoinClickPending(unoOutputTicks: nil, nowTicks: uno), "nessuna ora")
    }
}
