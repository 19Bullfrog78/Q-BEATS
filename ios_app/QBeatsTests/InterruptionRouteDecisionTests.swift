import XCTest

// === A416 · SEGUITO 2 — banco dell'interruzione di sistema e del cambio di percorso rimandato (`InterruptionRouteDecision`,
// banco Models), mandato §2.2 ===
// La matrice del mandato: stato alzato o basso × motore fermo o in moto × frequenza uguale o diversa × modo uguale o
// diverso × ripresa pendente sì o no (32 celle), ognuna con e senza un rimandato già segnato. I due casi di confine: un
// inizio con lo stato già alzato, una fine con lo stato già basso. Gli abbassamenti (fine, sessione attivata, motore
// avviato). L'esecuzione una volta sola, alla fine che passa dalla ricostruzione o all'avvio. Le sequenze del collaudo:
// B1 con la fine, B1 senza la fine, la fine che non passa dalla ricostruzione, due chiamate, G senza interruzione.

final class InterruptionRouteDecisionTests: XCTestCase {

    private let bools = [false, true]

    private func raised(_ reason: String? = nil) -> InterruptionRouteState {
        InterruptionRouteState(systemInterruption: true, deferredReason: reason)
    }

    private func low(_ reason: String? = nil) -> InterruptionRouteState {
        InterruptionRouteState(systemInterruption: false, deferredReason: reason)
    }

    private func conditions(engine: Bool = false, rate: Bool = false, mode: Bool = false,
                            pending: Bool = false) -> InterruptionRouteDecision.RouteConditions {
        InterruptionRouteDecision.RouteConditions(engineRunning: engine, rateDiffers: rate, modeDiffers: mode,
                                                   pendingResume: pending)
    }

    private func route(_ reason: String, _ state: InterruptionRouteState,
                       _ conds: InterruptionRouteDecision.RouteConditions? = nil)
        -> (outcome: InterruptionRouteOutcome, state: InterruptionRouteState) {
        InterruptionRouteDecision.routeChange(reason: reason, conditions: conds ?? conditions(), state: state)
    }

    /// La matrice: con lo stato alzato ogni cella rimanda (niente sessione, niente motore, niente ripresa pendente) e il
    /// motivo diventa l'ultimo; con lo stato basso ogni cella fa come oggi e lo stato non cambia.
    func testMatrix() {
        var cells = 0
        for isRaised in bools {
            for engine in bools {
                for rate in bools {
                    for mode in bools {
                        for pending in bools {
                            for hadDeferred in bools {
                                let before = InterruptionRouteState(systemInterruption: isRaised,
                                                                    deferredReason: hadDeferred ? "oldDeviceUnavailable" : nil)
                                let step = route("categoryChange", before,
                                                 conditions(engine: engine, rate: rate, mode: mode, pending: pending))
                                if isRaised {
                                    XCTAssertEqual(step.outcome, .deferred)
                                    XCTAssertEqual(step.state, raised("categoryChange"))
                                } else {
                                    XCTAssertEqual(step.outcome, .asToday)
                                    XCTAssertEqual(step.state, before)
                                }
                                cells += 1
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 64)
    }

    /// Confine 1: un inizio con lo stato già alzato (una seconda chiamata prima della fine della prima) lo lascia alzato,
    /// col rimandato com'era.
    func testBeganWithStateAlreadyRaised() {
        XCTAssertEqual(InterruptionRouteDecision.state(after: .began, from: raised()), raised())
        XCTAssertEqual(InterruptionRouteDecision.state(after: .began, from: raised("categoryChange")),
                       raised("categoryChange"))
    }

    /// Confine 2: una fine con lo stato già basso lo lascia basso, col rimandato com'era.
    func testEndedWithStateAlreadyLow() {
        XCTAssertEqual(InterruptionRouteDecision.state(after: .ended, from: low()), low())
        XCTAssertEqual(InterruptionRouteDecision.state(after: .ended, from: low("categoryChange")), low("categoryChange"))
    }

    /// L'inizio alza; la fine, la sessione attivata e il motore avviato abbassano, da ogni stato. Il rimandato resta.
    func testRaiseAndLower() {
        for reason in [nil, "categoryChange"] as [String?] {
            XCTAssertEqual(InterruptionRouteDecision.state(after: .began, from: low(reason)), raised(reason))
            for event in [InterruptionRouteDecision.Event.ended, .sessionActivated, .engineStarted] {
                XCTAssertEqual(InterruptionRouteDecision.state(after: event, from: raised(reason)), low(reason))
                XCTAssertEqual(InterruptionRouteDecision.state(after: event, from: low(reason)), low(reason))
            }
        }
    }

    /// L'esecuzione: con un rimandato si esegue col suo motivo e si toglie; la seconda volta niente; senza rimandato
    /// niente. Uguale alla fine e all'avvio, con lo stato alzato o basso.
    func testDeferredRunsOnce() {
        for runner in DeferredRouteRunner.allCases {
            for isRaised in bools {
                let before = InterruptionRouteState(systemInterruption: isRaised, deferredReason: "categoryChange")
                let first = InterruptionRouteDecision.runDeferred(at: runner, state: before)
                XCTAssertEqual(first.reason, "categoryChange")
                XCTAssertEqual(first.state, InterruptionRouteState(systemInterruption: isRaised, deferredReason: nil))
                let second = InterruptionRouteDecision.runDeferred(at: runner, state: first.state)
                XCTAssertNil(second.reason)
                XCTAssertEqual(second.state, first.state)
            }
        }
    }

    /// Due cambi di percorso a stato alzato: vale il motivo dell'ultimo.
    func testLastReasonWins() {
        let first = route("oldDeviceUnavailable", raised())
        let second = route("categoryChange", first.state, conditions(rate: true, mode: true))
        XCTAssertEqual(second.outcome, .deferred)
        XCTAssertEqual(InterruptionRouteDecision.runDeferred(at: .start, state: second.state).reason, "categoryChange")
    }

    /// B1 come al collaudo del 21/10, con la fine che arriva: il percorso della chiamata e quello del ritorno si
    /// rimandano; alla fine, che passa dalla ricostruzione, il rimandato si esegue una volta; l'avvio dopo non lo rifà.
    func testB1WithTheEnd() {
        var state = InterruptionRouteDecision.state(after: .began, from: .initial)
        var step = route("categoryChange", state, conditions(rate: true))
        XCTAssertEqual(step.outcome, .deferred)
        step = route("categoryChange", step.state, conditions(rate: true))
        XCTAssertEqual(step.outcome, .deferred)
        state = InterruptionRouteDecision.state(after: .ended, from: step.state)
        XCTAssertFalse(state.systemInterruption)
        let atEnd = InterruptionRouteDecision.runDeferred(at: .interruptionEnd, state: state)
        XCTAssertEqual(atEnd.reason, "categoryChange")
        state = InterruptionRouteDecision.state(after: .sessionActivated, from: atEnd.state)
        let atStart = InterruptionRouteDecision.runDeferred(at: .start, state: state)
        XCTAssertNil(atStart.reason)
        XCTAssertEqual(InterruptionRouteDecision.state(after: .engineStarted, from: atStart.state), .initial)
    }

    /// B1 se la fine non arriva mai: lo stato resta alzato fino al primo avvio; l'avvio esegue il rimandato e, riuscito,
    /// abbassa lo stato.
    func testB1WithoutTheEnd() {
        var step = route("categoryChange", InterruptionRouteDecision.state(after: .began, from: .initial))
        step = route("categoryChange", step.state)
        XCTAssertTrue(step.state.systemInterruption)
        let atStart = InterruptionRouteDecision.runDeferred(at: .start, state: step.state)
        XCTAssertEqual(atStart.reason, "categoryChange")
        XCTAssertTrue(atStart.state.systemInterruption)
        XCTAssertEqual(InterruptionRouteDecision.state(after: .engineStarted, from: atStart.state), .initial)
    }

    /// La fine che non passa dalla ricostruzione (ripresa pendente, nessuna interruzione attiva, shouldResume falso,
    /// hardware occupato, reset dei servizi): alla fine niente; la riattivazione abbassa; l'avvio esegue.
    func testEndWithoutRebuildLeavesItToStart() {
        let step = route("categoryChange", InterruptionRouteDecision.state(after: .began, from: .initial),
                         conditions(pending: true))
        XCTAssertEqual(step.outcome, .deferred)
        var state = InterruptionRouteDecision.state(after: .ended, from: step.state)
        XCTAssertEqual(state, low("categoryChange"))
        state = InterruptionRouteDecision.state(after: .sessionActivated, from: state)
        XCTAssertEqual(InterruptionRouteDecision.runDeferred(at: .start, state: state).reason, "categoryChange")
    }

    /// Un cambio di percorso a stato basso con un rimandato in attesa: come oggi, e il rimandato lo esegue l'avvio.
    func testRouteChangeWhileLowKeepsTheDeferredForStart() {
        let step = route("newDeviceAvailable", low("categoryChange"))
        XCTAssertEqual(step.outcome, .asToday)
        XCTAssertEqual(step.state, low("categoryChange"))
        XCTAssertEqual(InterruptionRouteDecision.runDeferred(at: .start, state: step.state).reason, "categoryChange")
    }

    /// Due chiamate, la prima senza fine: un solo rimandato, eseguito una volta.
    func testTwoCalls() {
        var state = InterruptionRouteDecision.state(after: .began, from: .initial)
        state = route("categoryChange", state).state
        state = InterruptionRouteDecision.state(after: .began, from: state)
        state = route("categoryChange", state).state
        state = InterruptionRouteDecision.state(after: .ended, from: state)
        let atEnd = InterruptionRouteDecision.runDeferred(at: .interruptionEnd, state: state)
        XCTAssertEqual(atEnd.reason, "categoryChange")
        XCTAssertNil(InterruptionRouteDecision.runDeferred(at: .start, state: atEnd.state).reason)
    }

    /// G di controllo: nessuna interruzione, i cambi di percorso fanno come oggi e niente si rimanda.
    func testNoInterruptionNothingIsDeferred() {
        var state = InterruptionRouteState.initial
        for reason in ["oldDeviceUnavailable", "newDeviceAvailable"] {
            let step = route(reason, state, conditions(rate: true))
            XCTAssertEqual(step.outcome, .asToday)
            state = step.state
        }
        XCTAssertEqual(state, .initial)
        XCTAssertNil(InterruptionRouteDecision.runDeferred(at: .start, state: state).reason)
    }

    /// I nomi delle righe.
    func testNames() {
        XCTAssertEqual(InterruptionRouteOutcome.asToday.rawValue, "come-oggi")
        XCTAssertEqual(InterruptionRouteOutcome.deferred.rawValue, "rimanda")
        XCTAssertEqual(DeferredRouteRunner.interruptionEnd.rawValue, "fine-interruzione")
        XCTAssertEqual(DeferredRouteRunner.start.rawValue, "avvio")
        XCTAssertEqual(InterruptionRouteDecision.Event.allCases.map(\.rawValue),
                       ["inizio", "fine", "sessione-attivata", "motore-avviato"])
        XCTAssertEqual(InterruptionRouteState.initial, low())
    }
}
