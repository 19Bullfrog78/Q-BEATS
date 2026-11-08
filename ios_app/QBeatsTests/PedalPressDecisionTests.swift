import XCTest

// === A429 (08/11/2026) — banco della regola del pedale (`PedalPressDecision`, banco Models) ===
// Mandato A429, par. 2.6, col seguito 1, par. 2.8: la matrice ruolo × silenzio × azione × in moto × segno «partenza
// chiesta» × motore in moto × schermo (3 × 2 × 2 × 2 × 2 × 2 × 25 = 2400 casi), coi conti letterali; i punti del 2.0
// uno per uno, nell'ordine del seguito 1, par. 2.1; per ogni schermo del Solo il comando premuto coincide con quello che
// la regola dello schermo mette a schermo (`tap`, `consoleVisible`); i dettagli; il lampo; le parole del registro.
// Gli attesi sono scritti dal problema; il modello Python della regola (⚠️ RISCRITTO A429 · SEGUITO 2, c'era «(referto
// A429 · seguito 1)»: referti A429 · seguito 1 e seguito 2) li ha confermati e ha
// provato che ogni test cade se si toglie la riga della regola che prova. BPM non interi (141.0).
// A429 · seguito 2: sulla fine scaletta di Direttore e Solo il Play/Pause a click fermo preme BACK TO SHOWS (la «A» di
// Mauro dell'08/11, 11:00); gli attesi della fine scaletta qui sotto lo seguono.

final class PedalPressDecisionTests: XCTestCase {

    // MARK: - Gli schermi della matrice (25)

    private static func soloScreen(_ state: LivePlaybackState, section: Int = 0) -> SoloScreen {
        SoloScreenDecision.screen(state: state,
                                  sectionIndex: section,
                                  sectionName: "Verse",
                                  currentSongName: "Charly",
                                  showName: "Show",
                                  songNameInMotion: "Charly",
                                  songNumber: 3,
                                  displayWritten: true,
                                  sectionBPM: 141.0,
                                  sectionBeatsPerBar: 6,
                                  sectionBeatUnit: 8)
    }

    private static let restFaces = SoloConsoleDecision.faces(transportRunning: false, backtrackPlaying: false, mixerOpen: false)
    private static let runningFaces = SoloConsoleDecision.faces(transportRunning: true, backtrackPlaying: false, mixerOpen: false)

    private static func directorVeil(section: Int, follower: Bool = false) -> StandbyOverlayDecision {
        StandbyOverlayDecision(currentSectionIdx: section,
                               currentSectionName: "Verse",
                               songName: "3 Charly 6/8",
                               isFollower: follower,
                               tempoLine: "141 · 6/8")
    }

    private static let standby: LivePlaybackState = .standby(nextSongName: "3 Charly 6/8")
    private static let overlayStop: LivePlaybackState = .overlayStop(sectionName: "Verse", songName: "Charly")

    private static let screens: [PedalScreen] = [
        .noDoor,                                                                       // 1
        .covered(.bivio),                                                              // 2
        .covered(.mixer),                                                              // 3
        .covered(.importSheet),                                                        // 4
        .director(state: standby, veil: directorVeil(section: 0)),                     // 5
        .director(state: standby, veil: directorVeil(section: 2)),                     // 6
        .director(state: .stopped, veil: nil),                                         // 7
        .director(state: .starting, veil: nil),                                        // 8
        .director(state: .countIn(countdown: 4), veil: nil),                           // 9
        .director(state: .playing, veil: nil),                                         // 10
        .director(state: .loopActive, veil: nil),                                      // 11
        .director(state: .fineSetlist, veil: nil),                                     // 12
        .director(state: overlayStop, veil: nil),                                      // 13
        .solo(screen: soloScreen(standby), faces: restFaces),                          // 14 V
        .solo(screen: soloScreen(standby, section: 2), faces: restFaces),              // 15 H
        .solo(screen: soloScreen(.stopped, section: 2), faces: restFaces),             // 16 H
        .solo(screen: soloScreen(.playing), faces: restFaces),                         // 17 K
        .solo(screen: soloScreen(.starting), faces: restFaces),                        // 18 K
        .solo(screen: soloScreen(.countIn(countdown: 4)), faces: restFaces),           // 19 K
        .solo(screen: soloScreen(.fineSetlist), faces: restFaces),                     // 20 V4
        .solo(screen: soloScreen(overlayStop), faces: restFaces),                      // 21 UX-3
        .solo(screen: soloScreen(.playing), faces: runningFaces),                      // 22 K a Stop
        .detail(.resume),                                                              // 23
        .detail(.startFoot(enabled: true)),                                            // 24
        .detail(.startFoot(enabled: false)),                                           // 25
    ]

    private static let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private static let bools = [false, true]

    private struct Case {
        let role: PlayerRole
        let silent: Bool
        let action: PedalTransportAction
        let playing: Bool
        let requested: Bool
        let moving: Bool
        let screenIndex: Int
        var screen: PedalScreen { PedalPressDecisionTests.screens[screenIndex] }
        var label: String {
            "\(role) silenzio:\(silent) \(action) isPlaying:\(playing) segno:\(requested) motore:\(moving) schermo:\(screenIndex + 1)"
        }
    }

    private static var matrix: [Case] {
        var all: [Case] = []
        for role in roles {
            for silent in bools {
                for action in PedalTransportAction.allCases {
                    for playing in bools {
                        for requested in bools {
                            for moving in bools {
                                for index in screens.indices {
                                    all.append(Case(role: role, silent: silent, action: action, playing: playing,
                                                    requested: requested, moving: moving, screenIndex: index))
                                }
                            }
                        }
                    }
                }
            }
        }
        return all
    }

    private func decide(_ c: Case) -> PedalPress {
        PedalPressDecision.decide(role: c.role, directorSilent: c.silent, action: c.action, isPlaying: c.playing,
                                  startRequested: c.requested, engineMoving: c.moving, screen: c.screen)
    }

    private func decide(_ role: PlayerRole, _ action: PedalTransportAction, playing: Bool = false,
                        requested: Bool = false, moving: Bool = false, screen: PedalScreen) -> PedalPress {
        PedalPressDecision.decide(role: role, directorSilent: false, action: action, isPlaying: playing,
                                  startRequested: requested, engineMoving: moving, screen: screen)
    }

    private func name(_ press: PedalPress) -> String { PedalPressDecision.commandName(press.command) }

    // MARK: - Lo schermo della matrice e' quello che le regole dello schermo disegnano

    func testTheSoloScreensOfTheMatrixAreWhatTheScreenRuleDraws() {
        let kinds: [SoloScreenKind] = [.veil, .resume, .resume, .playing, .playing, .playing, .endShow, .overlayStop, .playing]
        for (offset, index) in (13...21).enumerated() {
            guard case .solo(let screen, _) = Self.screens[index] else { return XCTFail("schermo \(index + 1)") }
            XCTAssertEqual(screen.kind, kinds[offset], "schermo \(index + 1)")
        }
        XCTAssertEqual(Self.restFaces.center, .play)
        XCTAssertEqual(Self.runningFaces.center, .stop)
        XCTAssertFalse(Self.directorVeil(section: 0).hasResumePoint)
        XCTAssertTrue(Self.directorVeil(section: 2).hasResumePoint)
        XCTAssertEqual(Self.matrix.count, 2400)
    }

    // MARK: - (1) Follower

    func testPoint1TheFollowerNeverPresses() {
        for c in Self.matrix where c.role == .follower {
            let p = decide(c)
            XCTAssertNil(p.command, c.label)
            XCTAssertEqual(p.reason, "follower", c.label)
            XCTAssertFalse(p.lamp, c.label)
        }
    }

    // MARK: - (2) Direttore muto in canzone: com'e' oggi

    func testPoint2TheDirectorSilenceIsAsToday() {
        for c in Self.matrix where c.role != .follower && c.silent {
            let p = decide(c)
            XCTAssertEqual(p.reason, "silenzio", c.label)
            switch c.action {
            case .playPause:
                XCTAssertEqual(p.command, .directorSilenceTap, c.label)
                XCTAssertTrue(p.lamp, c.label)
            case .stop:
                XCTAssertEqual(p.command, .handleStopInSilence, c.label)
                XCTAssertEqual(p.lamp, c.moving, c.label)
            }
        }
    }

    // MARK: - (3) Click in moto → Stop

    func testPoint3PlayPauseWithTheClickPlayingStops() {
        for c in Self.matrix where c.role != .follower && !c.silent && c.action == .playPause && c.playing {
            let p = decide(c)
            XCTAssertEqual(p.command, .stop, c.label)
            XCTAssertEqual(p.reason, "in-moto", c.label)
            XCTAssertTrue(p.lamp, c.label)
        }
    }

    /// Seguito 1, par. 2.2: per lo Stop «in moto» e' `isPlaying`, oppure il segno alzato, oppure il motore in moto.
    func testPoint3TheStopIsInMotionWithTheClickTheMarkOrTheEngine() {
        let literal: [(Bool, Bool, Bool)] = [(true, false, false), (false, true, false), (false, false, true)]
        for (playing, requested, moving) in literal {
            for (role, index) in [(PlayerRole.direttore, 4), (.solo, 13)] {
                let p = decide(role, .stop, playing: playing, requested: requested, moving: moving, screen: Self.screens[index])
                XCTAssertEqual(p.command, .stop, "\(role) isPlaying:\(playing) segno:\(requested) motore:\(moving)")
                XCTAssertEqual(p.reason, "in-moto")
                XCTAssertTrue(p.lamp)
            }
        }
        for c in Self.matrix where c.role != .follower && !c.silent && c.action == .stop && (c.playing || c.requested || c.moving) {
            XCTAssertEqual(decide(c).command, .stop, c.label)
        }
    }

    // MARK: - (4) Stop a click fermo → niente

    func testPoint4TheStopAtRestDoesNothingOnEveryScreen() {
        for c in Self.matrix where c.role != .follower && !c.silent && c.action == .stop && !(c.playing || c.requested || c.moving) {
            let p = decide(c)
            XCTAssertNil(p.command, c.label)
            XCTAssertEqual(p.reason, "fermo", c.label)
            XCTAssertFalse(p.lamp, c.label)
        }
    }

    // MARK: - (5) Play/Pause con una partenza o un arresto in corso → niente

    func testPoint5PlayPauseWithAStartOrAStopInProgressDoesNothing() {
        for c in Self.matrix where c.role != .follower && !c.silent && c.action == .playPause && !c.playing && (c.requested || c.moving) {
            let p = decide(c)
            XCTAssertNil(p.command, c.label)
            XCTAssertEqual(p.reason, "partenza-o-arresto-in-corso", c.label)
            XCTAssertFalse(p.lamp, c.label)
        }
        // Il segno da solo (F1-F5) e il motore da solo (F6, F7), sul velo del Direttore e su V1 del Solo.
        for (requested, moving) in [(true, false), (false, true)] {
            for (role, index) in [(PlayerRole.direttore, 4), (.solo, 13)] {
                let p = decide(role, .playPause, requested: requested, moving: moving, screen: Self.screens[index])
                XCTAssertNil(p.command, "\(role) segno:\(requested) motore:\(moving)")
                XCTAssertEqual(p.reason, "partenza-o-arresto-in-corso")
            }
        }
    }

    /// Seguito 1, par. 2.1: col segno alzato e `isPlaying` gia' vero vale il (3): il Play/Pause ferma, come il dito.
    func testTheMarkUpWithTheClickAlreadyPlayingStops() {
        for screen in Self.screens {
            let p = decide(.direttore, .playPause, playing: true, requested: true, screen: screen)
            XCTAssertEqual(p.command, .stop)
            XCTAssertEqual(p.reason, "in-moto")
        }
    }

    // MARK: - (6) Lo schermo di adesso, a click fermo e senza partenza in corso (punti 5-8 e 7-bis)

    func testTheScreenCommandsAtRestOneByOne() {
        let expected: [(String, String)] = [
            ("niente", "nessuna-porta"), ("niente", "coperto-bivio"), ("niente", "coperto-mixer"),
            ("niente", "coperto-foglio-import"),
            ("velo", "velo"), ("velo", "velo"),
            ("fascia", "fascia"), ("fascia", "fascia"), ("fascia", "fascia"), ("fascia", "fascia"), ("fascia", "fascia"),
            ("back-to-shows", "fine-scaletta"), ("niente", "pannello-ux3"),
            ("velo-solo", "velo"), ("console-play", "console"), ("console-play", "console"),
            ("console-play", "console"), ("console-play", "console"), ("console-play", "console"),
            ("back-to-shows", "fine-scaletta"), ("niente", "pannello-ux3"), ("niente", "nessun-comando"),
            ("resume", "resume"), ("start-show", "start-show"), ("niente", "tasto-spento"),
        ]
        XCTAssertEqual(expected.count, Self.screens.count)
        for (index, screen) in Self.screens.enumerated() {
            let role: PlayerRole
            if case .solo = screen { role = .solo } else { role = .direttore }
            let p = decide(role, .playPause, screen: screen)
            XCTAssertEqual(name(p), expected[index].0, "schermo \(index + 1)")
            XCTAssertEqual(p.reason, expected[index].1, "schermo \(index + 1)")
            XCTAssertEqual(p.lamp, expected[index].0 != "niente", "schermo \(index + 1)")
        }
    }

    /// Il comando porta lo schermo letto adesso: il velo, lo schermo del Solo, le facce.
    func testTheCommandCarriesTheScreenItWasReadFrom() {
        XCTAssertEqual(decide(.direttore, .playPause, screen: Self.screens[5]).command,
                       .directorVeil(Self.directorVeil(section: 2)))
        XCTAssertEqual(decide(.solo, .playPause, screen: Self.screens[13]).command,
                       .soloVeil(Self.soloScreen(Self.standby)))
        XCTAssertEqual(decide(.solo, .playPause, screen: Self.screens[15]).command,
                       .consoleCenter(Self.restFaces))
    }

    func testAVeilWithoutACommandDoesNothing() {
        for veil in [Self.directorVeil(section: 0, follower: true), nil] {
            let choice = PedalPressDecision.screenCommand(.director(state: Self.standby, veil: veil))
            XCTAssertNil(choice.command)
            XCTAssertEqual(choice.reason, "nessun-comando")
        }
    }

    /// ⚠️ RISCRITTO A429 · SEGUITO 2, c'era «Mandato A429, par. 2.6: per ogni schermo del Solo il comando premuto coincide
    /// con quello che la regola dello schermo mette a schermo — il tocco del velo (`tap`) o la console (`consoleVisible`),
    /// salvo il pannello UX-3 che la copre e la fine scaletta.»: mandato A429, par. 2.6: per ogni schermo del Solo il
    /// comando premuto coincide con quello che la regola dello schermo mette a schermo — il tocco del velo (`tap`) o la
    /// console (`consoleVisible`), salvo il pannello UX-3 che la copre (niente); sulla fine scaletta (V4, `.endShow`) il
    /// tasto BACK TO SHOWS (seguito 2).
    func testEverySoloScreenPressesWhatTheScreenRuleShows() {
        let states: [LivePlaybackState] = [Self.standby, .stopped, .starting, .countIn(countdown: 4), .playing, .loopActive,
                                           .fineSetlist, Self.overlayStop]
        for state in states {
            for section in [0, 2] {
                let screen = Self.soloScreen(state, section: section)
                let p = decide(.solo, .playPause, screen: .solo(screen: screen, faces: Self.restFaces))
                let expected: String
                if screen.tap == .startSong {
                    expected = "velo-solo"
                } else if screen.kind == .endShow {
                    expected = "back-to-shows"
                } else if screen.kind == .overlayStop {
                    expected = "niente"
                } else if screen.consoleVisible {
                    expected = "console-play"
                } else {
                    expected = "niente"
                }
                XCTAssertEqual(name(p), expected, "\(state) sezione:\(section)")
            }
        }
    }

    // MARK: - La fine scaletta: BACK TO SHOWS (A429 · seguito 2, la «A» di Mauro dell'08/11, 11:00)

    /// Sulla fine scaletta del Direttore (schermo 12) e del Solo (V4, schermo 20), a click fermo, il Play/Pause preme BACK
    /// TO SHOWS, col lampo. Resta il resto: lo Stop a click fermo niente, il Follower niente, a click in moto lo Stop, con
    /// una partenza in corso niente, il pannello UX-3 niente.
    func testTheEndOfTheSetlistPressesBackToShows() {
        for (role, index, ux3) in [(PlayerRole.direttore, 11, 12), (.solo, 19, 20)] {
            let screen = Self.screens[index]
            let label = "\(role) schermo \(index + 1)"
            let p = decide(role, .playPause, screen: screen)
            XCTAssertEqual(p.command, .backToShows, label)
            XCTAssertEqual(p.reason, "fine-scaletta", label)
            XCTAssertTrue(p.lamp, label)
            XCTAssertEqual(name(p), "back-to-shows", label)
            XCTAssertEqual(PedalPressDecision.screenCommand(screen).command, .backToShows, label)
            let stop = decide(role, .stop, screen: screen)
            XCTAssertNil(stop.command, label)
            XCTAssertEqual(stop.reason, "fermo", label)
            XCTAssertFalse(stop.lamp, label)
            let follower = decide(.follower, .playPause, screen: screen)
            XCTAssertNil(follower.command, label)
            XCTAssertEqual(follower.reason, "follower", label)
            XCTAssertEqual(decide(role, .playPause, playing: true, screen: screen).command, .stop, label)
            XCTAssertNil(decide(role, .playPause, requested: true, screen: screen).command, label)
            XCTAssertNil(decide(role, .playPause, screen: Self.screens[ux3]).command, "\(role) UX-3")
        }
    }

    // MARK: - Il lampo (mandato A429, par. 2.5; seguito 1, par. 2.2)

    func testOutsideTheSilenceTheLampIsThePress() {
        for c in Self.matrix where !c.silent {
            let p = decide(c)
            XCTAssertEqual(p.lamp, p.command != nil, c.label)
        }
    }

    // MARK: - I conti della matrice

    func testTheMatrixCounts() {
        var counts: [String: Int] = [:]
        for c in Self.matrix {
            let p = decide(c)
            let lamp: String = p.lamp ? "1" : "0"
            let key: String = name(p) + "|" + p.reason + "|" + lamp
            counts[key, default: 0] += 1
        }
        let expected: [String: Int] = [
            "back-to-shows|fine-scaletta|1": 4,
            "console-play|console|1": 10,
            "fascia|fascia|1": 10,
            "handleStop|silenzio|0": 200,
            "handleStop|silenzio|1": 200,
            "niente|coperto-bivio|0": 2,
            "niente|coperto-foglio-import|0": 2,
            "niente|coperto-mixer|0": 2,
            "niente|fermo|0": 50,
            "niente|follower|0": 800,
            "niente|nessun-comando|0": 2,
            "niente|nessuna-porta|0": 2,
            "niente|pannello-ux3|0": 4,
            "niente|partenza-o-arresto-in-corso|0": 150,
            "niente|tasto-spento|0": 2,
            "resume|resume|1": 2,
            "start-show|start-show|1": 2,
            "stop|in-moto|1": 550,
            "tasto-del-silenzio|silenzio|1": 400,
            "velo-solo|velo|1": 2,
            "velo|velo|1": 4,
        ]
        XCTAssertEqual(counts, expected)
        XCTAssertEqual(counts.values.reduce(0, +), 2400)
    }

    // MARK: - «In moto», le azioni, le parole del registro

    func testInMotionDefinition() {
        for playing in Self.bools {
            for requested in Self.bools {
                for moving in Self.bools {
                    XCTAssertEqual(PedalPressDecision.inMotion(action: .playPause, isPlaying: playing,
                                                               startRequested: requested, engineMoving: moving), playing)
                    XCTAssertEqual(PedalPressDecision.inMotion(action: .stop, isPlaying: playing,
                                                               startRequested: requested, engineMoving: moving),
                                   playing || requested || moving)
                }
            }
        }
    }

    func testOnlyPlayPauseAndStopPassFromTheRule() {
        for action in MIDIAction.allCases {
            let transport = PedalTransportAction(midi: action)
            switch action {
            case .playPause: XCTAssertEqual(transport, .playPause)
            case .stop: XCTAssertEqual(transport, .stop)
            default: XCTAssertNil(transport, action.rawValue)
            }
        }
    }

    func testTheRegisterWords() {
        let names = Self.screens.map { PedalPressDecision.screenName($0) }
        XCTAssertEqual(names, [
            "nessuna-porta", "coperto-bivio", "coperto-mixer", "coperto-foglio-import",
            "direttore-velo", "direttore-velo", "direttore-fascia", "direttore-fascia", "direttore-fascia",
            "direttore-fascia", "direttore-fascia", "direttore-fine-scaletta", "direttore-ux3",
            "solo-V", "solo-H", "solo-H", "solo-K", "solo-K", "solo-K", "solo-V4", "solo-ux3", "solo-K",
            "dettaglio-resume", "dettaglio-start-acceso", "dettaglio-start-spento",
        ])
        XCTAssertEqual(PedalPressDecision.commandName(nil), "niente")
        XCTAssertEqual(PedalPressDecision.commandName(.directorSilenceTap), "tasto-del-silenzio")
        XCTAssertEqual(PedalPressDecision.commandName(.handleStopInSilence), "handleStop")
        XCTAssertEqual(PedalPressDecision.commandName(.stop), "stop")
        XCTAssertEqual(PedalPressDecision.commandName(.directorStrip), "fascia")
        XCTAssertEqual(PedalPressDecision.commandName(.resume), "resume")
        XCTAssertEqual(PedalPressDecision.commandName(.startShow), "start-show")
        XCTAssertEqual(PedalPressDecision.commandName(.backToShows), "back-to-shows")
        XCTAssertEqual(PedalPressDecision.pedalOrigin, "pedale")
        XCTAssertEqual(PedalPressDecision.originSuffix("pedale"), " origine:pedale")
        for touch in ["velo", "console", "resume", "start-show", "fascia"] {
            XCTAssertEqual(PedalPressDecision.originSuffix(touch), "", touch)
        }
    }
}
