import XCTest

// === A394 · SOLO-G1-PEZZO-1-M1 — banco del lampo del pedale (banco Models) ===
// Ogni azione per Solo, Direttore e Follower, a trasporto fermo e in moto, attesi letterali; i
// cinque comandi muti mai; sul Follower solo il muto; Stop Backtrack mai con la base ferma.

final class MIDILampDecisionTests: XCTestCase {

    private let commanders: [PlayerRole] = [.solo, .direttore]

    private func fires(_ action: MIDIAction, _ role: PlayerRole, moving: Bool, backtrack: Bool = false) -> Bool {
        MIDILampDecision.fires(action: action, role: role, transportInMotion: moving, backtrackPlaying: backtrack)
    }

    func testEveryActionForSoloAndDirectorLiterally() {
        // (azione, atteso a fermo, atteso in moto) — base ferma
        let rows: [(MIDIAction, Bool, Bool)] = [
            (.playPause,       true,  true),
            (.stop,            false, true),
            (.muteClickToggle, true,  true),
            (.stopBacktrack,   false, false),
            (.tapTempo,        true,  true),
            (.nextSection,     false, false),
            (.prevSection,     false, false),
            (.nextSong,        false, false),
            (.startSong,       false, false),
            (.loopToggle,      false, false),
        ]
        XCTAssertEqual(rows.count, MIDIAction.allCases.count, "ogni azione del MIDI Learn ha la sua riga")
        for role in commanders {
            for (action, stopped, moving) in rows {
                XCTAssertEqual(fires(action, role, moving: false), stopped, "\(action.rawValue) \(role) fermo")
                XCTAssertEqual(fires(action, role, moving: true), moving, "\(action.rawValue) \(role) in moto")
            }
        }
    }

    func testFollowerOnlyTheMute() {
        for action in MIDIAction.allCases {
            for moving in [false, true] {
                for backtrack in [false, true] {
                    XCTAssertEqual(fires(action, .follower, moving: moving, backtrack: backtrack),
                                   action == .muteClickToggle,
                                   "\(action.rawValue) moto:\(moving) base:\(backtrack)")
                }
            }
        }
    }

    func testTheFiveSilentCommandsNeverFire() {
        XCTAssertEqual(MIDILampDecision.silentActions.count, 5)
        for action in MIDILampDecision.silentActions {
            for role in [PlayerRole.solo, .direttore, .follower] {
                for moving in [false, true] {
                    XCTAssertFalse(fires(action, role, moving: moving, backtrack: true),
                                   "\(action.rawValue) \(role) moto:\(moving)")
                }
            }
        }
    }

    func testStopBacktrackOnlyWhileTheBacktrackPlays() {
        for role in commanders {
            for moving in [false, true] {
                XCTAssertFalse(fires(.stopBacktrack, role, moving: moving, backtrack: false))
                XCTAssertTrue(fires(.stopBacktrack, role, moving: moving, backtrack: true))
            }
        }
    }

    func testStopFiresOnlyWhileTheTransportMoves() {
        for role in commanders {
            XCTAssertFalse(fires(.stop, role, moving: false))
            XCTAssertTrue(fires(.stop, role, moving: true))
        }
    }

    func testMuteFiresForEveryRoleInEveryState() {
        for role in [PlayerRole.solo, .direttore, .follower] {
            for moving in [false, true] {
                XCTAssertTrue(fires(.muteClickToggle, role, moving: moving))
            }
        }
    }
}
