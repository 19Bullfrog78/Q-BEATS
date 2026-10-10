import XCTest

// === A400 — banco del richiamo avvio/stop di Link (banco Models) ===
// Sei ingressi: «suona» del richiamo × ruolo × Link acceso dall'utente × il segno del
// proprio avvio × `isPlaying` del motore × il lucchetto del doppio invio. Cose da provare:
//  1. l'eco propria (richiamo «suona» col segno alzato, apparecchio né Direttore né
//     Follower) si consuma e non avvia niente — i tre test `testOwnEcho…`: sono quelli che
//     cadono con la regola di oggi (eco propria → avvia) e passano con la cura;
//  2. gli avvii e gli stop degli altri passano come prima: avvio a segno basso e motore
//     fermo → avvia; stop a motore in moto → ferma, qualunque sia il segno; lo stop non è
//     mai un eco;
//  3. Direttore → ignora; Follower → alla sua macchina; lucchetto alzato → niente;
//  4. il passo di main è il blocco di sempre, riga per riga (attesi LETTERALI), e la
//     regola intera è i due passi in fila.
// Il banco gira in CI (`.github/workflows/ios_build.yml`, `xcodebuild test -scheme QBeatsTests`).

final class LinkTransportCallbackDecisionTests: XCTestCase {

    /// Chi non è Direttore né Follower: il Solo, e il ruolo Follower con Link spento dall'utente.
    private let others: [(LinkMode, Bool)] = [(.standalone, true), (.standalone, false),
                                              (.collaborativa, false)]
    private let bools = [false, true]

    private func action(isPlaying: Bool,
                        role: LinkMode = .standalone,
                        userLink: Bool = true,
                        sign: Bool,
                        engine: Bool,
                        lock: Bool = false) -> LinkTransportCallbackDecision.Action {
        LinkTransportCallbackDecision(isPlaying: isPlaying,
                                      role: role,
                                      userLinkEnabled: userLink,
                                      ownStartPending: sign,
                                      engineIsPlaying: engine,
                                      startEmitInFlight: lock).action
    }

    // MARK: - 1 · L'eco propria (cadono con la regola di oggi, passano con la cura)

    /// Il caso misurato (A399 §5.1, 18 avvii su 25): Solo, Link acceso, il richiamo «suona»
    /// arriva col segno alzato e il motore ancora «fermo» su main. Oggi: avvia.
    func testOwnEchoOfTheSoloIsConsumedAndDoesNotStart() {
        XCTAssertEqual(action(isPlaying: true, sign: true, engine: false), .consumeOwnEcho)
    }

    /// Il segno non legge `isPlaying` del motore né il lucchetto: col segno alzato un
    /// richiamo «suona» è l'eco propria comunque stiano gli altri due.
    func testOwnEchoIsConsumedWhateverTheEngineAndTheLockSay() {
        for (role, userLink) in others {
            for engine in bools {
                for lock in bools {
                    XCTAssertEqual(action(isPlaying: true, role: role, userLink: userLink,
                                          sign: true, engine: engine, lock: lock),
                                   .consumeOwnEcho,
                                   "ruolo:\(role) linkUtente:\(userLink) motore:\(engine) lucchetto:\(lock)")
                }
            }
        }
    }

    /// Il passo di coda da solo: «suona» + segno alzato → si consuma lì, non arriva a main.
    func testOwnEchoQueueStepConsumesOnTheQueue() {
        XCTAssertEqual(LinkTransportCallbackDecision.queueStep(isPlaying: true, ownStartPending: true),
                       .consumeOwnEcho)
    }

    // MARK: - 2 · Gli avvii e gli stop degli altri passano come prima

    func testOthersStartWithTheSignDownStartsTheEngine() {
        for (role, userLink) in others {
            XCTAssertEqual(action(isPlaying: true, role: role, userLink: userLink,
                                  sign: false, engine: false),
                           .start, "ruolo:\(role) linkUtente:\(userLink)")
        }
    }

    func testStopWithTheEngineRunningStopsWhateverTheSign() {
        for (role, userLink) in others {
            for sign in bools {
                for lock in bools {
                    XCTAssertEqual(action(isPlaying: false, role: role, userLink: userLink,
                                          sign: sign, engine: true, lock: lock),
                                   .stop,
                                   "ruolo:\(role) linkUtente:\(userLink) segno:\(sign) lucchetto:\(lock)")
                }
            }
        }
    }

    /// Lo stop di un altro non è un eco: il segno alzato non lo consuma, nemmeno nel passo di coda.
    func testStopWithTheSignRaisedIsNotAnEcho() {
        XCTAssertEqual(action(isPlaying: false, sign: true, engine: true), .stop)
        XCTAssertEqual(LinkTransportCallbackDecision.queueStep(isPlaying: false, ownStartPending: true),
                       .forwardToMain)
    }

    func testQueueStepForwardsWhenTheSignIsDown() {
        XCTAssertEqual(LinkTransportCallbackDecision.queueStep(isPlaying: true, ownStartPending: false),
                       .forwardToMain)
        XCTAssertEqual(LinkTransportCallbackDecision.queueStep(isPlaying: false, ownStartPending: false),
                       .forwardToMain)
    }

    func testStartWithTheEngineAlreadyPlayingDoesNothing() {
        XCTAssertEqual(action(isPlaying: true, sign: false, engine: true), .none)
        XCTAssertEqual(action(isPlaying: true, sign: false, engine: true, lock: true), .none)
    }

    func testStopWithTheEngineStoppedDoesNothing() {
        for sign in bools {
            for lock in bools {
                XCTAssertEqual(action(isPlaying: false, sign: sign, engine: false, lock: lock), .none,
                               "segno:\(sign) lucchetto:\(lock)")
            }
        }
    }

    // MARK: - 3 · Direttore, Follower, lucchetto

    func testDirectorIgnoresEverything() {
        for isPlaying in bools {
            for userLink in bools {
                for sign in bools {
                    for engine in bools {
                        for lock in bools {
                            XCTAssertEqual(action(isPlaying: isPlaying, role: .direttore,
                                                  userLink: userLink, sign: sign,
                                                  engine: engine, lock: lock),
                                           .directorIgnores)
                        }
                    }
                }
            }
        }
    }

    func testFollowerGoesToItsMachine() {
        for isPlaying in bools {
            for sign in bools {
                for engine in bools {
                    for lock in bools {
                        XCTAssertEqual(action(isPlaying: isPlaying, role: .collaborativa,
                                              userLink: true, sign: sign,
                                              engine: engine, lock: lock),
                                       .followerMachine)
                    }
                }
            }
        }
    }

    /// Il lucchetto del doppio invio alzato inghiotte l'avvio di un altro (semantica di sempre).
    func testLockRaisedSwallowsTheOthersStart() {
        for (role, userLink) in others {
            XCTAssertEqual(action(isPlaying: true, role: role, userLink: userLink,
                                  sign: false, engine: false, lock: true),
                           .none, "ruolo:\(role) linkUtente:\(userLink)")
        }
    }

    // MARK: - 4 · Il passo di main è il blocco di sempre; la regola è i due passi in fila

    func testMainStepIsTheOldBlockLiterally() {
        // (suona, motore, lucchetto, atteso)
        let rows: [(Bool, Bool, Bool, LinkTransportCallbackDecision.MainStep)] = [
            (true,  false, false, .start),
            (true,  false, true,  .none),
            (true,  true,  false, .none),
            (true,  true,  true,  .none),
            (false, true,  false, .stop),
            (false, true,  true,  .stop),
            (false, false, false, .none),
            (false, false, true,  .none),
        ]
        for (isPlaying, engine, lock, expected) in rows {
            XCTAssertEqual(LinkTransportCallbackDecision.mainStep(isPlaying: isPlaying,
                                                                  engineIsPlaying: engine,
                                                                  startEmitInFlight: lock),
                           expected, "suona:\(isPlaying) motore:\(engine) lucchetto:\(lock)")
        }
    }

    func testTheWholeRuleIsTheTwoStepsInARow() {
        for (role, userLink) in others {
            for isPlaying in bools {
                for sign in bools {
                    for engine in bools {
                        for lock in bools {
                            let expected: LinkTransportCallbackDecision.Action
                            if LinkTransportCallbackDecision.queueStep(isPlaying: isPlaying,
                                                                       ownStartPending: sign) == .consumeOwnEcho {
                                expected = .consumeOwnEcho
                            } else {
                                switch LinkTransportCallbackDecision.mainStep(isPlaying: isPlaying,
                                                                              engineIsPlaying: engine,
                                                                              startEmitInFlight: lock) {
                                case .start: expected = .start
                                case .stop: expected = .stop
                                case .none: expected = .none
                                }
                            }
                            XCTAssertEqual(action(isPlaying: isPlaying, role: role, userLink: userLink,
                                                  sign: sign, engine: engine, lock: lock),
                                           expected,
                                           "ruolo:\(role) suona:\(isPlaying) segno:\(sign) motore:\(engine) lucchetto:\(lock)")
                        }
                    }
                }
            }
        }
    }
}
