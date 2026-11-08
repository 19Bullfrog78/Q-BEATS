import XCTest

// === A394 · SOLO-G1-PEZZO-1-M1 — banco del lampo del pedale (banco Models) ===
// Ogni azione per Solo, Direttore e Follower, a trasporto fermo e in moto, attesi letterali; i
// cinque comandi muti mai; sul Follower solo il muto; Stop Backtrack mai con la base ferma.
// ⚠️ RISCRITTO A429 (08/11/2026), c'era «a trasporto fermo e in moto»: per Play/Pause e Stop l'ingresso non e' piu' il
// trasporto in moto ma il lampo della regola del pedale (`transportPressed`, da `PedalPressDecision`); le altre azioni
// come prima. Gli attesi cambiano solo per Play/Pause (prima sempre) e Stop (prima col trasporto in moto).

final class MIDILampDecisionTests: XCTestCase {

    private let commanders: [PlayerRole] = [.solo, .direttore]

    private func fires(_ action: MIDIAction, _ role: PlayerRole, pressed: Bool, backtrack: Bool = false) -> Bool {
        MIDILampDecision.fires(action: action, role: role, transportPressed: pressed, backtrackPlaying: backtrack)
    }

    func testEveryActionForSoloAndDirectorLiterally() {
        // (azione, atteso col pedale che non ha premuto, atteso col pedale che ha premuto) — base ferma
        // A429 — Play/Pause e Stop: (false, true), dalla regola del pedale; prima (true, true) e (false, true) col moto.
        let rows: [(MIDIAction, Bool, Bool)] = [
            (.playPause,       false, true),
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
            for (action, notPressed, pressed) in rows {
                XCTAssertEqual(fires(action, role, pressed: false), notPressed, "\(action.rawValue) \(role) non premuto")
                XCTAssertEqual(fires(action, role, pressed: true), pressed, "\(action.rawValue) \(role) premuto")
            }
        }
    }

    func testFollowerOnlyTheMute() {
        for action in MIDIAction.allCases {
            for pressed in [false, true] {
                for backtrack in [false, true] {
                    XCTAssertEqual(fires(action, .follower, pressed: pressed, backtrack: backtrack),
                                   action == .muteClickToggle,
                                   "\(action.rawValue) premuto:\(pressed) base:\(backtrack)")
                }
            }
        }
    }

    func testTheFiveSilentCommandsNeverFire() {
        XCTAssertEqual(MIDILampDecision.silentActions.count, 5)
        for action in MIDILampDecision.silentActions {
            for role in [PlayerRole.solo, .direttore, .follower] {
                for pressed in [false, true] {
                    XCTAssertFalse(fires(action, role, pressed: pressed, backtrack: true),
                                   "\(action.rawValue) \(role) premuto:\(pressed)")
                }
            }
        }
    }

    func testStopBacktrackOnlyWhileTheBacktrackPlays() {
        for role in commanders {
            for pressed in [false, true] {
                XCTAssertFalse(fires(.stopBacktrack, role, pressed: pressed, backtrack: false))
                XCTAssertTrue(fires(.stopBacktrack, role, pressed: pressed, backtrack: true))
            }
        }
    }

    /// ⚠️ A429 — era `testStopFiresOnlyWhileTheTransportMoves` («Stop solo col trasporto in moto»): da A429 Play/Pause e
    /// Stop lampeggiano se e solo se la regola del pedale ha premuto un comando (mandato A429, par. 2.5).
    func testTransportFiresOnlyWhenThePedalPressed() {
        for role in commanders {
            for action in [MIDIAction.playPause, .stop] {
                XCTAssertFalse(fires(action, role, pressed: false), "\(action.rawValue) \(role)")
                XCTAssertTrue(fires(action, role, pressed: true), "\(action.rawValue) \(role)")
            }
        }
    }

    func testMuteFiresForEveryRoleInEveryState() {
        for role in [PlayerRole.solo, .direttore, .follower] {
            for pressed in [false, true] {
                XCTAssertTrue(fires(.muteClickToggle, role, pressed: pressed))
            }
        }
    }
}
