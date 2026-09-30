import XCTest

// === A386 · FASE B1 — banco della proposta di RIENTRA (banco Models) ===
// B2b: la tabella del foglio CD 2D-QUATER (file 1 §0-bis) — una riga per test, con attesi
// letterali: la canzone proposta e la sua FORMA (normale · ipotesi · scelta tua · nessuna).
// Scaletta di tre canzoni (indici 0, 1, 2). Piu' la prova che dopo un rifiuto la canzone
// toccata vince anche su una proposta normale.

final class RientraProposalTests: XCTestCase {

    private func p(_ reason: FollowerOutReason?, current: Int, count: Int = 3, afterLast: Bool = false) -> RientraProposal {
        RientraProposal.propose(reason: reason, currentSongIdx: current, songCount: count,
                                afterLastSong: afterLast)
    }

    // MARK: - normale («suggested», bordo pieno)

    func testPlayLateProposesTheNextSongNormal() {
        XCTAssertEqual(p(.playLate, current: 0), RientraProposal(songIdx: 1, form: .normal))
        XCTAssertEqual(p(.playLate, current: 1), RientraProposal(songIdx: 2, form: .normal))
    }

    func testPlayLateOnTheLastSongProposesNothing() {
        XCTAssertEqual(p(.playLate, current: 2), .none)
    }

    func testAloneSongEndedProposesTheCurrentSongNormal() {
        // Il runner ha gia' armato la successiva a fine canzone propria: e' la corrente.
        XCTAssertEqual(p(.aloneSongEnded, current: 1), RientraProposal(songIdx: 1, form: .normal))
    }

    func testDirectorStoppedWhileAloneProposesTheCurrentSongNormal() {
        // B2b: `stopAndArmNext` — il runner ha gia' armato la successiva: e' la corrente.
        XCTAssertEqual(p(.directorStoppedWhileAlone, current: 2), RientraProposal(songIdx: 2, form: .normal))
    }

    func testDirectorFalseStartWhileAloneProposesTheSameSongNormalD7bis() {
        // `stopAndRearmSame` — il runner ha riarmato la stessa: e' la corrente.
        XCTAssertEqual(p(.directorFalseStartWhileAlone, current: 1), RientraProposal(songIdx: 1, form: .normal))
    }

    func testMusicianStopProposesTheCurrentSongNormal() {
        XCTAssertEqual(p(.musicianStop, current: 1), RientraProposal(songIdx: 1, form: .normal))
    }

    func testOpeningTheShowProposesTheFirstSongNormal() {
        // La lista d'ingresso (A1): ragione nulla all'avvio, `reset` dopo un END SHOW.
        XCTAssertEqual(p(nil, current: 0), RientraProposal(songIdx: 0, form: .normal))
        XCTAssertEqual(p(.reset, current: 0), RientraProposal(songIdx: 0, form: .normal))
        XCTAssertEqual(p(.reset, current: 2), RientraProposal(songIdx: 0, form: .normal))
    }

    // MARK: - ipotesi («a guess — check the band», tratteggio): SOLO dopo lostWhileStopped

    func testLostWhileStoppedProposesTheVeilSongAsAGuess() {
        XCTAssertEqual(p(.lostWhileStopped, current: 1), RientraProposal(songIdx: 1, form: .guess))
        XCTAssertEqual(p(.lostWhileStopped, current: 0), RientraProposal(songIdx: 0, form: .guess))
    }

    func testNoOtherReasonIsAGuess() {
        let reasons: [FollowerOutReason?] = [nil, .reset, .playLate, .aloneSongEnded, .directorStoppedWhileAlone,
                                             .directorFalseStartWhileAlone, .musicianStop,
                                             .lostWhileArmed(chosen: 1), .armRefusedNotHeard(chosen: 1),
                                             .armRefusedSessionPlaying(chosen: 1)]
        for reason in reasons {
            XCTAssertNotEqual(p(reason, current: 1).form, .guess, "\(String(describing: reason))")
        }
    }

    // MARK: - scelta tua («your pick», bordo pieno)

    func testRefusedNotHeardProposesTheTappedSongAsYourPick() {
        XCTAssertEqual(p(.armRefusedNotHeard(chosen: 2), current: 0), RientraProposal(songIdx: 2, form: .yourPick))
    }

    func testRefusedSessionPlayingProposesTheTappedSongAsYourPick() {
        XCTAssertEqual(p(.armRefusedSessionPlaying(chosen: 0), current: 1), RientraProposal(songIdx: 0, form: .yourPick))
    }

    func testLostWhileArmedProposesTheChosenSongAsYourPickR2() {
        XCTAssertEqual(p(.lostWhileArmed(chosen: 0), current: 0), RientraProposal(songIdx: 0, form: .yourPick))
        XCTAssertEqual(p(.lostWhileArmed(chosen: 2), current: 1), RientraProposal(songIdx: 2, form: .yourPick))
    }

    func testAfterARefusalTheTappedSongWinsOverANormalProposal() {
        // L6-ⓐ: la proposta dell'app era la 9 (successiva alla corrente 8); il musicista ha toccato
        // la 10 ⇒ la proposta e' la 10, «your pick» (punti 5 · 24 del foglio).
        let names = 12
        let normal = p(.aloneSongEnded, current: 9, count: names)
        XCTAssertEqual(normal, RientraProposal(songIdx: 9, form: .normal))
        let tapped = p(.armRefusedNotHeard(chosen: 10), current: 9, count: names)
        XCTAssertEqual(tapped, RientraProposal(songIdx: 10, form: .yourPick))
        let tappedPlaying = p(.armRefusedSessionPlaying(chosen: 10), current: 9, count: names)
        XCTAssertEqual(tappedPlaying, RientraProposal(songIdx: 10, form: .yourPick))
    }

    func testYourPickOutOfCatalogProposesNothing() {
        XCTAssertEqual(p(.lostWhileArmed(chosen: 7), current: 1), .none)
        XCTAssertEqual(p(.armRefusedNotHeard(chosen: -1), current: 1), .none)
    }

    // MARK: - nessuna: dopo l'ultima canzone, qualunque sia la ragione

    func testAfterTheLastSongNothingIsProposedWhateverTheReason() {
        let reasons: [FollowerOutReason?] = [nil, .reset, .playLate, .lostWhileStopped, .aloneSongEnded,
                                             .directorStoppedWhileAlone, .directorFalseStartWhileAlone,
                                             .musicianStop, .lostWhileArmed(chosen: 1),
                                             .armRefusedNotHeard(chosen: 1), .armRefusedSessionPlaying(chosen: 1)]
        for reason in reasons {
            XCTAssertEqual(p(reason, current: 2, afterLast: true), .none, "\(String(describing: reason))")
        }
    }

    func testEmptyCatalogOrInvalidIndexProposesNothing() {
        XCTAssertEqual(p(.playLate, current: 0, count: 0), .none)
        XCTAssertEqual(p(.lostWhileStopped, current: 5, count: 3), .none)
        XCTAssertEqual(p(.lostWhileStopped, current: -1, count: 3), .none)
        XCTAssertEqual(p(nil, current: 0, count: 0), .none)
    }

    func testNoneHasNoSongAndTheNoneForm() {
        XCTAssertNil(RientraProposal.none.songIdx)
        XCTAssertEqual(RientraProposal.none.form, .none)
    }
}
