import XCTest

// === A386 · FASE B1 — banco della proposta di RIENTRA (banco Models) ===
// Cinque regole (A-TER §7 + R2 + D7-bis), scaletta di tre canzoni (indici 0, 1, 2), attesi
// letterali: la canzone proposta e se la proposta e' affidabile.

final class RientraProposalTests: XCTestCase {

    private func p(_ reason: FollowerOutReason?, standby: Bool, current: Int, count: Int = 3) -> RientraProposal {
        RientraProposal.propose(reason: reason, sessionIsStandby: standby,
                                currentSongIdx: current, songCount: count)
    }

    func testPlayLateProposesTheNextSong() {
        XCTAssertEqual(p(.playLate, standby: false, current: 0), RientraProposal(songIdx: 1, reliable: true))
        XCTAssertEqual(p(.playLate, standby: true, current: 1), RientraProposal(songIdx: 2, reliable: true))
    }

    func testPlayLateOnTheLastSongProposesNothing() {
        XCTAssertEqual(p(.playLate, standby: false, current: 2), RientraProposal(songIdx: nil, reliable: true))
    }

    func testLostWhileArmedProposesTheChosenSongR2() {
        XCTAssertEqual(p(.lostWhileArmed(chosen: 0), standby: true, current: 0),
                       RientraProposal(songIdx: 0, reliable: true))
        XCTAssertEqual(p(.lostWhileArmed(chosen: 2), standby: false, current: 1),
                       RientraProposal(songIdx: 2, reliable: true))
        XCTAssertEqual(p(.lostWhileArmed(chosen: 7), standby: true, current: 1),
                       RientraProposal(songIdx: nil, reliable: true))
    }

    func testDirectorFalseStartWhileAloneProposesTheSameSongD7bis() {
        XCTAssertEqual(p(.directorFalseStartWhileAlone, standby: false, current: 1),
                       RientraProposal(songIdx: 1, reliable: true))
        XCTAssertEqual(p(.directorFalseStartWhileAlone, standby: false, current: 2),
                       RientraProposal(songIdx: 2, reliable: true))
    }

    func testStandbyOnAnUnstartedSongProposesThatSong() {
        XCTAssertEqual(p(.lostWhileStopped, standby: true, current: 1), RientraProposal(songIdx: 1, reliable: true))
        XCTAssertEqual(p(.aloneSongEnded, standby: true, current: 2), RientraProposal(songIdx: 2, reliable: true))
    }

    func testOtherwiseProposesTheNextSong() {
        XCTAssertEqual(p(.lostWhileStopped, standby: false, current: 0), RientraProposal(songIdx: 1, reliable: true))
        XCTAssertEqual(p(.directorStoppedWhileAlone, standby: false, current: 1), RientraProposal(songIdx: 2, reliable: true))
        XCTAssertEqual(p(.musicianStop, standby: false, current: 0), RientraProposal(songIdx: 1, reliable: true))
    }

    func testOtherwiseOnTheLastSongProposesNothing() {
        XCTAssertEqual(p(.directorStoppedWhileAlone, standby: false, current: 2), RientraProposal(songIdx: nil, reliable: true))
        XCTAssertEqual(p(.musicianStop, standby: false, current: 2), RientraProposal(songIdx: nil, reliable: true))
    }

    func testArmingRefusedIsNotReliable() {
        XCTAssertEqual(p(.armRefusedSessionPlaying, standby: false, current: 0), RientraProposal(songIdx: 1, reliable: false))
        XCTAssertEqual(p(.armRefusedNotHeard, standby: true, current: 1), RientraProposal(songIdx: 1, reliable: false))
        XCTAssertEqual(p(.armRefusedSessionPlaying, standby: false, current: 2), RientraProposal(songIdx: nil, reliable: false))
    }

    func testResetOrNoReasonProposesNothing() {
        XCTAssertEqual(p(.reset, standby: true, current: 0), RientraProposal(songIdx: nil, reliable: true))
        XCTAssertEqual(p(nil, standby: true, current: 0), RientraProposal(songIdx: nil, reliable: true))
    }

    func testEmptyCatalogOrInvalidIndexProposesNothing() {
        XCTAssertEqual(p(.playLate, standby: false, current: 0, count: 0), RientraProposal(songIdx: nil, reliable: true))
        XCTAssertEqual(p(.lostWhileStopped, standby: true, current: 5, count: 3), RientraProposal(songIdx: nil, reliable: true))
        XCTAssertEqual(p(.lostWhileStopped, standby: true, current: -1, count: 3), RientraProposal(songIdx: nil, reliable: true))
        XCTAssertEqual(p(.armRefusedNotHeard, standby: true, current: 0, count: 0), RientraProposal(songIdx: nil, reliable: false))
    }
}
