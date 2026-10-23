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

    // MARK: - A420 — la ripartenza per la frequenza, una strada sola (mandato A420, par. 2.3)

    /// Prima il percorso (il nodo d'uscita dà già la frequenza nuova a motore in moto: «fermare-e-ricostruire»), poi la
    /// configurazione, prima o dopo che la ripartenza sia finita: una ripartenza sola, tutte le copie alla frequenza nuova.
    func testRouteThenConfigurationRestartsOnce() {
        // La configurazione prima che la ripartenza finisca: trova `isRunning` basso e si ignora.
        var early = RateRig(rate: 44100)
        early.hardwareRate(48000)
        early.routeChange()
        XCTAssertEqual(early.restarts, 1)
        early.systemStopsEngine()
        early.configurationChange()
        early.completeStart()
        XCTAssertEqual(early.restarts, 1)
        XCTAssertTrue(early.allCopiesAt48k)
        XCTAssertTrue(early.stateRunning && early.engineRunning)
        // La configurazione dopo la ripartenza: trova il motore in moto e si ignora.
        var late = RateRig(rate: 44100)
        late.hardwareRate(48000)
        late.routeChange()
        late.completeStart()
        late.configurationChange()
        XCTAssertEqual(late.restarts, 1)
        XCTAssertTrue(late.allCopiesAt48k)
        XCTAssertTrue(late.stateRunning && late.engineRunning)
    }

    /// Prima la configurazione (il motore l'ha fermato il sistema), poi il percorso, prima o dopo che la ripartenza sia
    /// finita: il percorso trova la copia già uguale al nodo e non ferma niente. Una ripartenza sola.
    func testConfigurationThenRouteRestartsOnce() {
        for routeBeforeTheStart in [true, false] {
            var rig = RateRig(rate: 44100)
            rig.hardwareRate(48000)
            rig.systemStopsEngine()
            rig.configurationChange()
            XCTAssertEqual(rig.restarts, 1)
            XCTAssertTrue(rig.allCopiesAt48k)
            if routeBeforeTheStart {
                rig.routeChange()
                rig.completeStart()
            } else {
                rig.completeStart()
                rig.routeChange()
            }
            XCTAssertEqual(rig.restarts, 1, "percorso prima dell'avvio: \(routeBeforeTheStart)")
            XCTAssertTrue(rig.allCopiesAt48k)
            XCTAssertTrue(rig.stateRunning && rig.engineRunning)
        }
    }

    /// Non è «una ripartenza per evento» alla cieca: se il sistema ferma di nuovo il motore dopo la nostra ripartenza, la
    /// configurazione trova il motore fermo con `isRunning` vero, ed è un arresto vero: si riparte.
    func testASystemStopAfterOurRestartRestartsAgain() {
        var rig = RateRig(rate: 44100)
        rig.hardwareRate(48000)
        rig.routeChange()
        rig.completeStart()
        rig.systemStopsEngine()
        rig.configurationChange()
        XCTAssertEqual(rig.restarts, 2)
        rig.completeStart()
        XCTAssertTrue(rig.stateRunning && rig.engineRunning)
        XCTAssertTrue(rig.allCopiesAt48k)
    }
}

// === A420 — le due notifiche della frequenza sul motore ridotto (mandato A420, par. 2.3) ===
/// Il motore ridotto a quello che conta per le due notifiche: `isRunning`, il motore di sistema, il nodo d'uscita, la
/// sessione e le copie della frequenza. `restartForRateChange` è la funzione sola del motore (`restartForRateChangeQ`):
/// arresto sulla coda, frequenza dalla fonte unica a tutte le copie, ripartenza accodata; `completeStart` è l'avvio che la
/// completa (`activateSessionAndStart`, poi `start()`, che rilegge la frequenza). Le regole sono `SampleRateDecision` ed
/// `EngineConfigChangeDecision`, le stesse del motore.
private struct RateRig {
    var stateRunning = true
    var engineRunning = true
    var output: Double
    var session: Double
    var copy: Double
    var dsp: Double
    var click: Double
    var ioBuffer: Double
    var restarts = 0
    var pendingStart = false

    init(rate: Double) {
        output = rate
        session = rate
        copy = rate
        dsp = rate
        click = rate
        ioBuffer = rate
    }

    /// `applySampleRateQ`: le letture, la regola, e a motore fermo le copie riscritte.
    @discardableResult
    mutating func applySampleRate() -> SampleRateDecision.Outcome {
        let outcome = SampleRateDecision.outcome(SampleRateDecision.Reading(output: output,
                                                                            session: session,
                                                                            copy: copy,
                                                                            dsp: dsp,
                                                                            click: click,
                                                                            ioBuffer: ioBuffer,
                                                                            engineRunning: stateRunning))
        if outcome.rewritesCopy {
            copy = outcome.rate
        }
        if outcome.rewritesDSP {
            dsp = outcome.rate
        }
        if outcome.regeneratesClick {
            click = outcome.rate
        }
        if outcome.requestsIOBuffer {
            ioBuffer = outcome.rate
        }
        return outcome
    }

    /// Il sistema porta l'hardware a un'altra frequenza: il nodo d'uscita e la sessione la danno.
    mutating func hardwareRate(_ rate: Double) {
        output = rate
        session = rate
    }

    /// Il sistema ferma il motore (Apple: prima di mandare la notifica di configurazione).
    mutating func systemStopsEngine() {
        engineRunning = false
    }

    /// `restartForRateChangeQ`.
    mutating func restartForRateChange() {
        stateRunning = false
        engineRunning = false
        applySampleRate()
        restarts += 1
        pendingStart = true
    }

    /// Il cambio di percorso (`handleRouteChange`, senza cambio di modo).
    mutating func routeChange() {
        if applySampleRate().action == .stopAndRebuild {
            restartForRateChange()
        }
    }

    /// Il cambio di configurazione del motore corrente (`handleEngineConfigChange`).
    mutating func configurationChange() {
        let step = EngineConfigChangeDecision.outcome(senderIsCurrent: true,
                                                      stateRunning: stateRunning,
                                                      engineRunning: engineRunning,
                                                      audioWorkAllowed: true,
                                                      pendingResume: false)
        if step.restarts {
            restartForRateChange()
        }
    }

    /// L'avvio accodato dalla ripartenza: rilegge la frequenza a motore fermo, poi parte.
    mutating func completeStart() {
        guard pendingStart else { return }
        pendingStart = false
        applySampleRate()
        stateRunning = true
        engineRunning = true
    }

    var allCopiesAt48k: Bool {
        copy == 48000 && dsp == 48000 && click == 48000 && ioBuffer == 48000
    }
}
