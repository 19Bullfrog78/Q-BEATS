import XCTest

// === A386 · FASE B2b — banco del velo del Follower (banco Models) ===
// Una lastra del foglio CD 2D-QUATER (26/09/2026) per test, con attesi LETTERALI: la parola in
// testa, la riga sotto, l'intestazione, lo slot E con le sue righe e la sua icona, la riga
// evidenziata della scaletta con la sua forma. Lastre: L1 · L2-② · L2-③ · L2-④ · L3 · L4 · L5 ·
// L6-ⓐ · L6-ⓑ · L7 · L7→R2 · L8 dopo. Poi la precedenza delle cinque facce dello slot E, la
// regola d'ingresso (Join at / Rejoin at) e la faccia senza show. Il banco gira in CI su ogni
// push (`.github/workflows/ios_build.yml`, `xcodebuild test -scheme QBeatsTests`).

final class FollowerVeilDecisionTests: XCTestCase {

    private typealias D = FollowerVeilDecision

    /// La scaletta del foglio: «Milano Assago», 24 canzoni (indici 0-23).
    private let names: [String] = ["Intro Tape", "Circuz", "Roxanne", "Nebbia Bassa", "Aria Ferma",
                                   "Kerosene and the Tide", "Verde Rame", "Luna Park", "Marea",
                                   "Ferro e Sale", "Polvere", "Settembre", "Radio Notte", "Asfalto",
                                   "Song 15", "Song 16", "Song 17", "Song 18", "Song 19", "Song 20",
                                   "Song 21", "Song 22", "Song 23", "Song 24"]

    // Fabbrica SENZA logica: default espliciti, ogni test dichiara cio' che cambia.
    private func decide(state: FollowerSyncState,
                        reason: FollowerOutReason? = nil,
                        showOpen: Bool = true,
                        heard: Bool = true,
                        searching: Bool = false,
                        sss: Bool = true,
                        bandPlaying: Bool = false,
                        proposal: RientraProposal = .none) -> D {
        D(state: state, reason: reason, showOpen: showOpen, directorHeard: heard,
          searching: searching, startStopSyncEnabled: sss, linkSessionPlaying: bandPlaying,
          proposal: proposal, songNames: names)
    }

    // MARK: - L1 · IN SYNC, fermo: il velo di sempre, slot E solo «Director signal OK»

    func testL1InSyncStoppedShowsOnlySignalOK() {
        let d = decide(state: .inSync(songClosed: true))
        XCTAssertEqual(d.face, .inSync)
        XCTAssertNil(d.headWord)
        XCTAssertNil(d.bodyLine)
        XCTAssertNil(d.headingLine)
        XCTAssertEqual(d.slotE, .signalOK)
        XCTAssertEqual(d.slotELine, "Director signal OK")
        XCTAssertEqual(d.slotEDetailLines, [])
        XCTAssertNil(d.slotEIcon)
        XCTAssertFalse(d.slotEIsAmber)
        XCTAssertNil(d.highlightedRow)
    }

    func testL1InSyncSlotEIsSignalOKEvenWhenNotHeardOrBandPlaying() {
        // Se il Direttore non si sente si va FUORI (D1): sul velo L1 compare solo l'OK.
        XCTAssertEqual(decide(state: .inSync(songClosed: false), heard: false).slotE, .signalOK)
        XCTAssertEqual(decide(state: .inSync(songClosed: true), bandPlaying: true).slotE, .signalOK)
        XCTAssertEqual(decide(state: .inSync(songClosed: true), searching: true).slotE, .signalOK)
    }

    // MARK: - L2-② · Join, apertura normale, sente

    func testL2JoinNormalOpeningHeard() {
        let d = decide(state: .out(armed: nil), reason: nil,
                       proposal: RientraProposal(songIdx: 0, form: .normal))
        XCTAssertEqual(d.face, .join)
        XCTAssertEqual(d.headWord, "Join")
        XCTAssertFalse(d.headWordIsAmber)
        XCTAssertEqual(d.bodyLine, "Pick the song the band starts from.")
        XCTAssertNil(d.bodyIcon)
        XCTAssertEqual(d.heading, .joinAt)
        XCTAssertEqual(d.headingLine, "Join at")
        XCTAssertEqual(d.songsLine, "24 songs")
        XCTAssertEqual(d.slotE, .signalOK)
        XCTAssertEqual(d.highlightedRow, 0)
        XCTAssertEqual(d.rowStyle, .proposalNormal)
        XCTAssertEqual(d.rowLine, "suggested")
        XCTAssertEqual(d.scrollTargetRow, 0)
    }

    func testL2JoinAfterEndShowResetIsStillJoin() {
        let d = decide(state: .out(armed: nil), reason: .reset,
                       proposal: RientraProposal(songIdx: 0, form: .normal))
        XCTAssertEqual(d.face, .join)
        XCTAssertEqual(d.headingLine, "Join at")
    }

    // MARK: - L2-③ · Join, aperto prima del Direttore (A2): non si sente

    func testL2JoinOpenedBeforeTheDirectorShowsNoSignalWithControlLines() {
        let d = decide(state: .out(armed: nil), reason: nil, heard: false,
                       proposal: RientraProposal(songIdx: 0, form: .normal))
        XCTAssertEqual(d.face, .join)
        XCTAssertEqual(d.headWord, "Join")
        XCTAssertFalse(d.headWordIsAmber)          // aspettare il Direttore e' normale
        XCTAssertEqual(d.slotE, .noSignal)
        XCTAssertEqual(d.slotELine, "No director signal")
        XCTAssertEqual(d.slotEDetailLines, ["director: show open \u{00B7} Link \u{00B7} Start Stop Sync",
                                            "network: Wi-Fi on both \u{00B7} router"])
        XCTAssertEqual(d.slotEIcon, .directorBarred)
        XCTAssertTrue(d.slotEIsAmber)
        XCTAssertEqual(d.highlightedRow, 0)
        XCTAssertEqual(d.rowLine, "suggested")
    }

    // MARK: - L2-④ · Ready dalla lista d'ingresso: sceglie la 7, l'intestazione resta «Join at»

    func testL2ReadyFromJoinKeepsJoinAtAndPulsesTheArmedRow() {
        let d = decide(state: .out(armed: 6), reason: nil)
        XCTAssertEqual(d.face, .ready)
        XCTAssertEqual(d.headWord, "Ready")
        XCTAssertFalse(d.headWordIsAmber)
        XCTAssertEqual(d.bodyLine, "Verde Rame starts at the director's Play.")
        XCTAssertNil(d.bodyIcon)
        XCTAssertEqual(d.heading, .joinAt)
        XCTAssertEqual(d.headingLine, "Join at")
        XCTAssertEqual(d.slotE, .signalOK)
        XCTAssertEqual(d.highlightedRow, 6)
        XCTAssertEqual(d.rowStyle, .armed)
        XCTAssertEqual(d.rowLine, "tap another song to change")
        XCTAssertEqual(d.scrollTargetRow, 5)
    }

    // MARK: - L3 · DA SOLO in moto: la fascia, niente slot E

    func testL3AloneIsTheAmberStripWithNoSlotE() {
        let d = decide(state: .alone, heard: false)
        XCTAssertEqual(d.face, .alone)
        XCTAssertNil(d.headWord)
        XCTAssertNil(d.slotE)
        XCTAssertNil(d.slotELine)
        XCTAssertNil(d.headingLine)
        XCTAssertNil(d.highlightedRow)
        XCTAssertEqual(D.onYourOwnLine, "On your own")
        XCTAssertEqual(D.clickStopsLine, "click stops at the song's end")
        XCTAssertEqual(D.holdToStopLine, "hold to stop")
    }

    // MARK: - L4 · FUORI, «Director signal lost.», proposta = ipotesi (tratteggio)

    func testL4OutSignalLostProposesAGuess() {
        let d = decide(state: .out(armed: nil), reason: .lostWhileStopped,
                       proposal: RientraProposal(songIdx: 8, form: .guess))
        XCTAssertEqual(d.face, .out)
        XCTAssertEqual(d.headWord, "Out")
        XCTAssertTrue(d.headWordIsAmber)
        XCTAssertEqual(d.bodyLine, "Director signal lost.")
        XCTAssertNil(d.bodyIcon)
        XCTAssertEqual(d.heading, .rejoinAt)
        XCTAssertEqual(d.headingLine, "Rejoin at")
        XCTAssertEqual(d.songsLine, "24 songs")
        XCTAssertEqual(d.slotE, .signalOK)
        XCTAssertEqual(d.highlightedRow, 8)
        XCTAssertEqual(d.rowStyle, .proposalGuess)
        XCTAssertEqual(d.rowLine, "a guess \u{2014} check the band")
        XCTAssertEqual(d.scrollTargetRow, 7)
    }

    // MARK: - L5 · fine concerto: il Direttore chiude lo show (A2), nessuna proposta, lista in cima

    func testL5EndOfConcertNoSignalNoProposalListAtTop() {
        let d = decide(state: .out(armed: nil), reason: .lostWhileStopped, heard: false,
                       proposal: .none)
        XCTAssertEqual(d.face, .out)
        XCTAssertEqual(d.bodyLine, "Director signal lost.")
        XCTAssertEqual(d.headingLine, "Rejoin at")
        XCTAssertEqual(d.slotE, .noSignal)
        XCTAssertEqual(d.slotEIcon, .directorBarred)
        XCTAssertNil(d.highlightedRow)
        XCTAssertNil(d.rowStyle)
        XCTAssertNil(d.rowLine)
        XCTAssertNil(d.scrollTargetRow)
    }

    // MARK: - L6-ⓐ · rifiuto R1, non sente: divieto, la canzone toccata resta («your pick»)

    func testL6aRefusedNotHeardKeepsTheTappedSongWithNoEntryIcon() {
        let d = decide(state: .out(armed: nil), reason: .armRefusedNotHeard(chosen: 9), heard: false,
                       proposal: RientraProposal(songIdx: 9, form: .yourPick))
        XCTAssertEqual(d.face, .out)
        XCTAssertEqual(d.bodyLine, "Couldn't join: no director signal.")
        XCTAssertEqual(d.bodyIcon, .noEntry)
        XCTAssertEqual(d.slotE, .noSignal)
        XCTAssertEqual(d.highlightedRow, 9)
        XCTAssertEqual(d.rowStyle, .proposalNormal)   // bordo pieno, come R2
        XCTAssertEqual(d.rowLine, "your pick")
        XCTAssertEqual(d.scrollTargetRow, 8)
    }

    // MARK: - L6-ⓑ · rifiuto R1, band in moto: segnale OK + «band playing», la 9 resta

    func testL6bRefusedBandPlayingShowsTheAmberWaitLine() {
        let d = decide(state: .out(armed: nil), reason: .armRefusedSessionPlaying(chosen: 8),
                       bandPlaying: true, proposal: RientraProposal(songIdx: 8, form: .yourPick))
        XCTAssertEqual(d.face, .out)
        XCTAssertEqual(d.bodyLine, "Couldn't join: band playing.")
        XCTAssertEqual(d.bodyIcon, .noEntry)
        XCTAssertEqual(d.slotE, .signalOKBandPlaying)
        XCTAssertEqual(d.slotELine, "Director signal OK")
        XCTAssertEqual(d.slotEDetailLines, ["band playing \u{2014} wait for the stop"])
        XCTAssertNil(d.slotEIcon)
        XCTAssertFalse(d.slotEIsAmber)
        XCTAssertTrue(d.slotEDetailIsAmber)
        XCTAssertEqual(d.highlightedRow, 8)
        XCTAssertEqual(d.rowLine, "your pick")
    }

    // MARK: - L7 · FUORI armato da RIENTRA: Ready, «Rejoin at», la 9 pulsa

    func testL7ReadyFromRientraKeepsRejoinAt() {
        // Un armamento riuscito tiene la ragione precedente (`followerApply`): qui era FUORI per
        // «Director signal lost.», quindi l'intestazione resta «Rejoin at».
        let d = decide(state: .out(armed: 8), reason: .lostWhileStopped)
        XCTAssertEqual(d.face, .ready)
        XCTAssertEqual(d.headWord, "Ready")
        XCTAssertFalse(d.headWordIsAmber)
        XCTAssertEqual(d.bodyLine, "Marea starts at the director's Play.")
        XCTAssertEqual(d.heading, .rejoinAt)
        XCTAssertEqual(d.headingLine, "Rejoin at")
        XCTAssertEqual(d.slotE, .signalOK)
        XCTAssertEqual(d.highlightedRow, 8)
        XCTAssertEqual(d.rowStyle, .armed)
        XCTAssertEqual(d.rowLine, "tap another song to change")
    }

    // MARK: - L7 → R2 · armamento perso: Out, «no longer ready», la stessa canzone «your pick»

    func testR2LostWhileArmedKeepsTheChoiceAsYourPick() {
        let d = decide(state: .out(armed: nil), reason: .lostWhileArmed(chosen: 8), heard: false,
                       proposal: RientraProposal(songIdx: 8, form: .yourPick))
        XCTAssertEqual(d.face, .out)
        XCTAssertEqual(d.headWord, "Out")
        XCTAssertTrue(d.headWordIsAmber)
        XCTAssertEqual(d.bodyLine, "Director signal lost \u{2014} no longer ready.")
        XCTAssertNil(d.bodyIcon)
        XCTAssertEqual(d.slotE, .noSignal)
        XCTAssertEqual(d.highlightedRow, 8)
        XCTAssertEqual(d.rowStyle, .proposalNormal)
        XCTAssertEqual(d.rowLine, "your pick")
    }

    // MARK: - L8 dopo · fine canzone da solo, la band ha gia' attaccato

    func testL8AfterAloneSongEndedWithBandPlaying() {
        let d = decide(state: .out(armed: nil), reason: .aloneSongEnded, bandPlaying: true,
                       proposal: RientraProposal(songIdx: 8, form: .normal))
        XCTAssertEqual(d.face, .out)
        XCTAssertEqual(d.bodyLine, "Song finished on your own.")
        XCTAssertEqual(d.slotE, .signalOKBandPlaying)
        XCTAssertEqual(d.slotEDetailLines, ["band playing \u{2014} wait for the stop"])
        XCTAssertEqual(d.highlightedRow, 8)
        XCTAssertEqual(d.rowStyle, .proposalNormal)
        XCTAssertEqual(d.rowLine, "suggested")
    }

    // MARK: - Le altre righe della ragione, letterali

    func testTheOtherReasonLinesAreTheSheetsLines() {
        XCTAssertEqual(decide(state: .out(armed: nil), reason: .playLate).bodyLine,
                       "Play came late: the band started without you.")
        XCTAssertEqual(decide(state: .out(armed: nil), reason: .directorStoppedWhileAlone).bodyLine,
                       "Director stopped while you played alone.")
        // Punto 27 (chiuso dal referee): la falsa partenza da solo porta la stessa riga.
        XCTAssertEqual(decide(state: .out(armed: nil), reason: .directorFalseStartWhileAlone).bodyLine,
                       "Director stopped while you played alone.")
        XCTAssertEqual(decide(state: .out(armed: nil), reason: .musicianStop).bodyLine,
                       "You stopped the click.")
        for reason: FollowerOutReason in [.playLate, .directorStoppedWhileAlone,
                                          .directorFalseStartWhileAlone, .musicianStop,
                                          .lostWhileStopped, .aloneSongEnded, .lostWhileArmed(chosen: 1)] {
            XCTAssertNil(decide(state: .out(armed: nil), reason: reason).bodyIcon, "\(reason)")
        }
    }

    // MARK: - Slot E: le cinque facce e la loro precedenza

    func testSlotEStartStopSyncOffTakesThePlaceOfNoSignal() {
        let d = decide(state: .out(armed: nil), reason: .lostWhileStopped, heard: false,
                       searching: true, sss: false, bandPlaying: true)
        XCTAssertEqual(d.slotE, .startStopSyncOff)
        XCTAssertEqual(d.slotELine, "Start Stop Sync off")
        XCTAssertEqual(d.slotEDetailLines, ["on this device \u{00B7} Settings \u{203A} Ableton Link"])
        XCTAssertEqual(d.slotEIcon, .playStopBarred)
        XCTAssertTrue(d.slotEIsAmber)
        XCTAssertFalse(d.slotEDetailIsAmber)
    }

    func testSlotESearchingBeatsNoSignal() {
        let d = decide(state: .out(armed: nil), reason: nil, heard: false, searching: true)
        XCTAssertEqual(d.slotE, .searching)
        XCTAssertEqual(d.slotELine, "Searching\u{2026}")
        XCTAssertEqual(d.slotEDetailLines, [])
        XCTAssertNil(d.slotEIcon)
        XCTAssertFalse(d.slotEIsAmber)
    }

    func testSlotEBandPlayingNeedsTheSignalOK() {
        XCTAssertEqual(decide(state: .out(armed: nil), reason: .playLate, heard: true, bandPlaying: true).slotE,
                       .signalOKBandPlaying)
        XCTAssertEqual(decide(state: .out(armed: nil), reason: .playLate, heard: false, bandPlaying: true).slotE,
                       .noSignal)
    }

    func testSlotEOnReadyFollowsTheSameRule() {
        XCTAssertEqual(decide(state: .out(armed: 3), heard: true).slotE, .signalOK)
        XCTAssertEqual(decide(state: .out(armed: 3), heard: false).slotE, .noSignal)
        XCTAssertEqual(decide(state: .out(armed: 3), sss: false).slotE, .startStopSyncOff)
    }

    // MARK: - La regola d'ingresso: Join at / Rejoin at

    func testEntryReasonIsNilOrReset() {
        XCTAssertTrue(D.isEntry(reason: nil))
        XCTAssertTrue(D.isEntry(reason: .reset))
        XCTAssertFalse(D.isEntry(reason: .lostWhileStopped))
        XCTAssertFalse(D.isEntry(reason: .armRefusedNotHeard(chosen: 0)))
        XCTAssertFalse(D.isEntry(reason: .lostWhileArmed(chosen: 0)))
    }

    func testReadyKeepsTheHeadingOfWhereItCameFrom() {
        XCTAssertEqual(decide(state: .out(armed: 2), reason: nil).headingLine, "Join at")
        XCTAssertEqual(decide(state: .out(armed: 2), reason: .reset).headingLine, "Join at")
        XCTAssertEqual(decide(state: .out(armed: 2), reason: .playLate).headingLine, "Rejoin at")
        XCTAssertEqual(decide(state: .out(armed: 2), reason: .armRefusedNotHeard(chosen: 2)).headingLine, "Rejoin at")
    }

    // MARK: - Senza show aperto non c'e' faccia

    func testNoShowOpenMeansNoFace() {
        for state: FollowerSyncState in [.out(armed: nil), .out(armed: 1), .inSync(songClosed: true), .alone] {
            let d = decide(state: state, showOpen: false)
            XCTAssertEqual(d.face, .noShow, "\(state)")
            XCTAssertNil(d.headWord)
            XCTAssertNil(d.slotE)
            XCTAssertNil(d.highlightedRow)
        }
    }

    // MARK: - La scaletta e le righe: numero, fuori catalogo, forma «none»

    func testSongsLineCountsTheSetlist() {
        let d = D(state: .out(armed: nil), reason: nil, showOpen: true, directorHeard: true,
                  searching: false, startStopSyncEnabled: true, linkSessionPlaying: false,
                  proposal: RientraProposal(songIdx: 0, form: .normal), songNames: ["A", "B", "C", "D", "E"])
        XCTAssertEqual(d.songsLine, "5 songs")
        XCTAssertEqual(d.highlightedRow, 0)
    }

    func testProposalOutOfCatalogHighlightsNothing() {
        let d = decide(state: .out(armed: nil), reason: .playLate,
                       proposal: RientraProposal(songIdx: 40, form: .normal))
        XCTAssertNil(d.highlightedRow)
        XCTAssertNil(d.rowLine)
        XCTAssertNil(d.scrollTargetRow)
    }

    func testReadyOnAnIndexOutOfCatalogStillSaysReadyWithAnEmptyName() {
        let d = decide(state: .out(armed: 40), reason: nil)
        XCTAssertEqual(d.face, .ready)
        XCTAssertEqual(d.bodyLine, " starts at the director's Play.")
        XCTAssertEqual(d.highlightedRow, 40)
    }

    // MARK: - Le parole, carattere per carattere (mandato §3.j)

    func testTheWordsAreTheSheetsWords() {
        XCTAssertEqual(D.joinWord, "Join")
        XCTAssertEqual(D.outWord, "Out")
        XCTAssertEqual(D.readyWord, "Ready")
        XCTAssertEqual(D.joinAtHeading, "Join at")
        XCTAssertEqual(D.rejoinAtHeading, "Rejoin at")
        XCTAssertEqual(D.pickLine, "Pick the song the band starts from.")
        XCTAssertEqual(D.readyLine(songName: "Marea"), "Marea starts at the director's Play.")
        XCTAssertEqual(D.changeLine, "tap another song to change")
        XCTAssertEqual(D.suggestedLine, "suggested")
        XCTAssertEqual(D.guessLine, "a guess — check the band")
        XCTAssertEqual(D.yourPickLine, "your pick")
        XCTAssertEqual(D.songsLine(count: 24), "24 songs")
        XCTAssertEqual(D.signalOKLine, "Director signal OK")
        XCTAssertEqual(D.searchingLine, "Searching…")
        XCTAssertEqual(D.noSignalLine, "No director signal")
        XCTAssertEqual(D.noSignalDirectorLine, "director: show open · Link · Start Stop Sync")
        XCTAssertEqual(D.noSignalNetworkLine, "network: Wi-Fi on both · router")
        XCTAssertEqual(D.bandPlayingLine, "band playing — wait for the stop")
        XCTAssertEqual(D.startStopSyncOffLine, "Start Stop Sync off")
        XCTAssertEqual(D.startStopSyncOffDetailLine, "on this device · Settings › Ableton Link")
        XCTAssertEqual(D.reasonLostWhileStopped, "Director signal lost.")
        XCTAssertEqual(D.reasonPlayLate, "Play came late: the band started without you.")
        XCTAssertEqual(D.reasonAloneSongEnded, "Song finished on your own.")
        XCTAssertEqual(D.reasonDirectorStoppedWhileAlone, "Director stopped while you played alone.")
        XCTAssertEqual(D.reasonMusicianStop, "You stopped the click.")
        XCTAssertEqual(D.reasonRefusedNotHeard, "Couldn't join: no director signal.")
        XCTAssertEqual(D.reasonRefusedSessionPlaying, "Couldn't join: band playing.")
        XCTAssertEqual(D.reasonLostWhileArmed, "Director signal lost — no longer ready.")
        // I caratteri non ASCII sono quelli del sorgente HTML: U+2014, U+2026, U+00B7, U+203A.
        XCTAssertEqual(D.guessLine.unicodeScalars.filter { $0.value > 127 }.map { $0.value }, [0x2014])
        XCTAssertEqual(D.searchingLine.unicodeScalars.filter { $0.value > 127 }.map { $0.value }, [0x2026])
        XCTAssertEqual(D.startStopSyncOffDetailLine.unicodeScalars.filter { $0.value > 127 }.map { $0.value }, [0x00B7, 0x203A])
    }
}
