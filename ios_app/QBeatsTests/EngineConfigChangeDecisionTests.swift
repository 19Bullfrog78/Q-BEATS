import XCTest

// === A416 — banco del cambio di configurazione del motore (`EngineConfigChangeDecision`, banco Models), mandato §2.2 ===
// La regola di stato al posto dei 20 s e della guardia «SR mismatch»: motore fermo con `isRunning` vero ⇒ si riparte
// sempre; una seconda notifica per lo stesso arresto trova `isRunning` basso e si ignora (nessuna ripartenza doppia).
// La matrice: motore corrente × `isRunning` × motore che gira × lavoro audio permesso × ripresa pendente = 2^5 celle,
// con l'atteso scritto qui. Nessun ingresso è un tempo: la regola non ha orologio.

final class EngineConfigChangeDecisionTests: XCTestCase {

    private let bools = [false, true]

    private func outcome(current: Bool = true, state: Bool = true, engine: Bool = false,
                         allowed: Bool = true, pending: Bool = false) -> EngineConfigChangeOutcome {
        EngineConfigChangeDecision.outcome(senderIsCurrent: current, stateRunning: state, engineRunning: engine,
                                           audioWorkAllowed: allowed, pendingResume: pending)
    }

    /// Motore fermo dal sistema con `isRunning` vero: si riparte.
    func testStoppedWithIsRunningTrueRestarts() {
        XCTAssertEqual(outcome(), .restart)
        XCTAssertTrue(outcome().restarts)
    }

    /// Lo stesso con una ripresa pendente: la ripresa pendente, dalla stessa strada (prima l'arresto esplicito).
    func testPendingResumeIsRecoveredTheSameWay() {
        XCTAssertEqual(outcome(pending: true), .recoverPending)
        XCTAssertTrue(outcome(pending: true).restarts)
    }

    /// Subito dopo una ripresa d'interruzione (fino ad A415 nei 20 s si saltava, e il click restava muto): si riparte lo
    /// stesso. La regola non ha un ingresso di tempo: gli stessi stati danno la stessa risposta a ogni istante.
    func testRightAfterAResumeItRestartsAnyway() {
        for _ in 0..<3 {
            XCTAssertEqual(outcome(), .restart)
        }
    }

    /// Fino ad A415 una frequenza della sessione diversa dalla copia faceva saltare («SR mismatch … skip»): la
    /// frequenza non entra più nella regola. La ricostruzione la prende dalla fonte unica (`SampleRateDecision`).
    func testTheSampleRateIsNotAnInput() {
        XCTAssertEqual(outcome(), .restart)
        XCTAssertEqual(outcome(pending: true), .recoverPending)
    }

    /// Non fermo con `isRunning` vero: niente da far ripartire.
    func testIgnoredUnlessStoppedWithIsRunningTrue() {
        XCTAssertEqual(outcome(state: false, engine: false), .ignored)
        XCTAssertEqual(outcome(state: false, engine: true), .ignored)
        XCTAssertEqual(outcome(state: true, engine: true), .ignored)
        XCTAssertEqual(outcome(state: false, engine: false, pending: true), .ignored)
    }

    /// Un motore che non è quello corrente si ignora prima di tutto (A408).
    func testNotCurrentEngineComesFirst() {
        for state in bools {
            for engine in bools {
                for allowed in bools {
                    for pending in bools {
                        XCTAssertEqual(outcome(current: false, state: state, engine: engine, allowed: allowed,
                                               pending: pending), .notCurrentEngine)
                    }
                }
            }
        }
    }

    /// Fuori da «normale» (reset dei servizi audio) niente lavoro sul motore vecchio, dopo la guardia di stato (com'era).
    func testMediaResetAfterTheStateGuard() {
        XCTAssertEqual(outcome(allowed: false), .mediaReset)
        XCTAssertEqual(outcome(allowed: false, pending: true), .mediaReset)
        XCTAssertEqual(outcome(state: false, allowed: false), .ignored)
        XCTAssertFalse(EngineConfigChangeOutcome.mediaReset.restarts)
    }

    /// Nessuna ripartenza doppia: chi riparte abbassa `isRunning` prima, e la notifica dopo, per lo stesso arresto, si
    /// ignora. Su tutte le celle.
    func testNoDoubleRestart() {
        for current in bools {
            for state in bools {
                for engine in bools {
                    for allowed in bools {
                        for pending in bools {
                            let first = outcome(current: current, state: state, engine: engine, allowed: allowed,
                                                pending: pending)
                            guard first.restarts else { continue }
                            let stateAfter = EngineConfigChangeDecision.stateRunningAfter(first, stateRunning: state)
                            XCTAssertFalse(stateAfter)
                            let second = outcome(current: current, state: stateAfter, engine: engine, allowed: allowed,
                                                 pending: pending)
                            XCTAssertEqual(second, .ignored, "corrente:\(current) motore:\(engine) permesso:\(allowed) pendente:\(pending)")
                        }
                    }
                }
            }
        }
        XCTAssertTrue(EngineConfigChangeDecision.stateRunningAfter(.ignored, stateRunning: true))
        XCTAssertFalse(EngineConfigChangeDecision.stateRunningAfter(.ignored, stateRunning: false))
    }

    // MARK: - La matrice

    private func expected(current: Bool, state: Bool, engine: Bool, allowed: Bool,
                          pending: Bool) -> EngineConfigChangeOutcome {
        if !current { return .notCurrentEngine }
        if !(state && !engine) { return .ignored }
        if !allowed { return .mediaReset }
        return pending ? .recoverPending : .restart
    }

    func testTheMatrix() {
        var cells = 0
        var restarts = 0
        for current in bools {
            for state in bools {
                for engine in bools {
                    for allowed in bools {
                        for pending in bools {
                            cells += 1
                            let got = outcome(current: current, state: state, engine: engine, allowed: allowed,
                                              pending: pending)
                            let tag = "corrente:\(current) isRunning:\(state) motoreGira:\(engine) permesso:\(allowed) pendente:\(pending)"
                            XCTAssertEqual(got, expected(current: current, state: state, engine: engine,
                                                         allowed: allowed, pending: pending), tag)
                            // Si riparte solo col motore fermo e `isRunning` vero: mai a motore che gira.
                            if got.restarts {
                                restarts += 1
                                XCTAssertTrue(current && state && !engine && allowed, tag)
                            }
                            // Motore fermo con `isRunning` vero, corrente e in «normale»: si riparte sempre.
                            if current && state && !engine && allowed {
                                XCTAssertTrue(got.restarts, tag)
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 32)
        XCTAssertEqual(restarts, 2)
    }

    func testTheNamesInTheLines() {
        XCTAssertEqual(EngineConfigChangeOutcome.allCases.count, 5)
        XCTAssertEqual(EngineConfigChangeOutcome.notCurrentEngine.rawValue, "motore-non-corrente")
        XCTAssertEqual(EngineConfigChangeOutcome.ignored.rawValue, "ignorato")
        XCTAssertEqual(EngineConfigChangeOutcome.mediaReset.rawValue, "reset-dei-servizi")
        XCTAssertEqual(EngineConfigChangeOutcome.recoverPending.rawValue, "ripresa-pendente")
        XCTAssertEqual(EngineConfigChangeOutcome.restart.rawValue, "ripartenza")
    }
}
