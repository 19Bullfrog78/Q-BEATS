import XCTest

// === A398 · SOLO-G1-PEZZO-1-M3 — banco del cancello del mixer e delle cause del registro (banco Models) ===
// In `.standby` e in `.fineSetlist` il pannello non si apre (per costruzione, non per copertura); in tutti gli
// altri stati sì, `.overlayStop` compreso (decisione b del cancello A397). Le cause nominano ogni riga [MIXER];
// nessuna causa di riserva: «sconosciuta» quando non è nota.

final class MixerOpenDecisionTests: XCTestCase {

    private let states: [LivePlaybackState] = [
        .standby(nextSongName: "Circuz"), .countIn(countdown: 4), .playing, .stopped, .loopActive,
        .overlayStop(sectionName: "Bridge", songName: "Circuz"), .fineSetlist, .starting,
    ]

    func testThePanelDoesNotOpenWhereItCannotBeClosed() {
        XCTAssertFalse(MixerOpenDecision.canOpen(in: .standby(nextSongName: "Circuz")))
        XCTAssertFalse(MixerOpenDecision.canOpen(in: .fineSetlist))
    }

    func testThePanelOpensInEveryOtherState() {
        XCTAssertEqual(states.count, 8)
        for state in states {
            switch state {
            case .standby, .fineSetlist:
                XCTAssertFalse(MixerOpenDecision.canOpen(in: state), "stato \(state)")
            default:
                XCTAssertTrue(MixerOpenDecision.canOpen(in: state), "stato \(state)")
            }
        }
        XCTAssertTrue(MixerOpenDecision.canOpen(in: .overlayStop(sectionName: "Bridge", songName: "Circuz")),
                      "in .overlayStop resta tutto com'è (decisione b del cancello A397)")
    }

    func testTheCausesOfTheRegister() {
        XCTAssertEqual(MixerCause.key.rawValue, "tasto")
        XCTAssertEqual(MixerCause.zoneAbove.rawValue, "zona-sopra")
        XCTAssertEqual(MixerCause.panelTap.rawValue, "tocco-pannello")
        XCTAssertEqual(MixerCause.handle.rawValue, "maniglia")
        XCTAssertEqual(MixerCause.dragDown.rawValue, "trascinamento-giu")
        XCTAssertEqual(MixerCause.dragUp.rawValue, "trascinamento-su")
        XCTAssertEqual(MixerCause.mount.rawValue, "montaggio")
        XCTAssertEqual(MixerCause.standby.rawValue, "standby")
        XCTAssertEqual(MixerCause.endOfSetlist.rawValue, "fine-scaletta")
        XCTAssertEqual(MixerCause.followerOut.rawValue, "follower-fuori")
        XCTAssertEqual(MixerCause.unknown.rawValue, "sconosciuta")
        // Nessuna causa si chiama ancora «gesto-fascia».
        let all: [MixerCause] = [.key, .zoneAbove, .panelTap, .handle, .dragDown, .dragUp, .mount, .standby,
                                 .endOfSetlist, .followerOut, .unknown]
        XCTAssertEqual(all.count, 11)
        XCTAssertFalse(all.map { $0.rawValue }.contains("gesto-fascia"))
        XCTAssertEqual(Set(all.map { $0.rawValue }).count, all.count, "cause distinte")
    }
}
