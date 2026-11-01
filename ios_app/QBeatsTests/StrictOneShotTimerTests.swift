import XCTest

// === A412 · SEGUITO 3 (18/10/2026) — IL BANCO DEL TIMER ALL'ORA CHIESTA (`StrictOneShotTimer`) ===
// Mandato del referee «A412 · SEGUITO 3», par. 4: il pezzo del timer, senza misurarne la precisione (in CI non si
// misura). Scatta una volta; annullato prima, non scatta; un armamento nuovo annulla il vecchio; un armamento fatto
// dentro lo scatto del precedente scatta e non lascia armato il vecchio; dopo lo scatto e dopo l'annullo il timer non
// tiene niente, ne' la sorgente ne' il lavoro (par. 3.2 c). In piu': un work item annullato non parte anche se il timer
// scatta (la rete di oggi), e un timer lasciato dal suo padrone non scatta.
// Che anche il sistema lasci il work item non dipende dal timer: dopo l'annullo lo lascia entro 2 s (test 3); dopo lo
// scatto, sul simulatore della CI, e' rimasto vivo oltre 2 s anche col timer vuoto (CI #777 e #778). Per questo il
// test 6 lo scrive nel registro della CI e non ne fa una condizione.
// Attese corte (20-50 ms) e tempi d'attesa del test larghi: 5 s per uno scatto atteso, 0,5 s per uno che non deve
// arrivare (dieci volte l'attesa), 2 s per vedere il lavoro rilasciato. Il timer si arma, si annulla e si legge solo
// sulla sua coda (`queue.sync`); i lavori scrivono in `Record`, letto anche lui sulla coda.
final class StrictOneShotTimerTests: XCTestCase {

    private final class Record {
        var armedWhenTheFirstWorkStarts = true
        var armedAfterRearming = false
    }

    private var queue: DispatchQueue!
    private var timer: StrictOneShotTimer!

    override func setUp() {
        super.setUp()
        queue = DispatchQueue(label: "com.bullfrog.qbeats.tests.strict-one-shot-timer", qos: .userInteractive)
        timer = StrictOneShotTimer(queue: queue)
    }

    override func tearDown() {
        let timer = self.timer
        queue.sync { timer?.cancel() }
        self.timer = nil
        queue = nil
        super.tearDown()
    }

    private func isArmed() -> Bool {
        let timer = self.timer!
        return queue.sync { () -> Bool in timer.isArmed }
    }

    /// Aspetta che `condition` diventi vera, fino a `timeout` secondi, con un giro della coda del timer a ogni prova.
    private func eventually(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline { return false }
            queue.sync {}
            Thread.sleep(forTimeInterval: 0.01)
        }
        return true
    }

    func testTheDeclaredLeewayIsOneMillisecond() {
        XCTAssertEqual(StrictOneShotTimer.leewayMilliseconds, 1)
    }

    func testItFiresOnce() {
        let fired = expectation(description: "scatta")
        fired.expectedFulfillmentCount = 1
        fired.assertForOverFulfill = true
        let timer = self.timer!
        let armed = queue.sync { () -> Bool in
            timer.arm(afterSeconds: 0.02, work: DispatchWorkItem { fired.fulfill() })
            return timer.isArmed
        }
        XCTAssertTrue(armed)
        wait(for: [fired], timeout: 5.0)
        // Un secondo scatto cadrebbe in questa attesa larga, e `assertForOverFulfill` farebbe fallire il test.
        let settle = expectation(description: "attesa larga dopo lo scatto")
        queue.asyncAfter(deadline: .now() + 0.3) { settle.fulfill() }
        wait(for: [settle], timeout: 5.0)
        XCTAssertFalse(isArmed())
    }

    func testCancelledBeforeItDoesNotFire() {
        let fired = expectation(description: "annullato: non deve scattare")
        fired.isInverted = true
        let timer = self.timer!
        weak var weakWork: DispatchWorkItem?
        do {
            let work = DispatchWorkItem { fired.fulfill() }
            weakWork = work
            let afterCancel = queue.sync { () -> (Bool, Bool) in
                timer.arm(afterSeconds: 0.05, work: work)
                timer.cancel()
                return (timer.isArmed, timer.holdsWork)
            }
            XCTAssertFalse(afterCancel.0)
            XCTAssertFalse(afterCancel.1)
        }
        wait(for: [fired], timeout: 0.5)
        // Dopo l'annullo il lavoro non resta vivo.
        XCTAssertTrue(eventually(timeout: 2.0) { weakWork == nil })
    }

    func testANewArmingCancelsTheOldOne() {
        let old = expectation(description: "il vecchio non deve scattare")
        old.isInverted = true
        let new = expectation(description: "il nuovo scatta")
        let timer = self.timer!
        queue.sync {
            timer.arm(afterSeconds: 0.05, work: DispatchWorkItem { old.fulfill() })
            timer.arm(afterSeconds: 0.1, work: DispatchWorkItem { new.fulfill() })
        }
        wait(for: [new], timeout: 5.0)
        wait(for: [old], timeout: 0.5)
        XCTAssertFalse(isArmed())
    }

    func testAnArmingInsideTheFireFiresAndLeavesNothingOfTheOldOne() {
        let first = expectation(description: "il primo scatta")
        first.assertForOverFulfill = true
        let second = expectation(description: "il secondo, armato dentro lo scatto del primo, scatta")
        second.assertForOverFulfill = true
        let timer = self.timer!
        let record = Record()
        let secondWork = DispatchWorkItem { second.fulfill() }
        let firstWork = DispatchWorkItem {
            // Sulla coda del timer, dentro lo scatto del primo (come il fuoco in ritardo che riarma il rientro).
            record.armedWhenTheFirstWorkStarts = timer.isArmed
            timer.arm(afterSeconds: 0.02, work: secondWork)
            record.armedAfterRearming = timer.isArmed
            first.fulfill()
        }
        queue.sync { timer.arm(afterSeconds: 0.02, work: firstWork) }
        wait(for: [first, second], timeout: 5.0, enforceOrder: true)
        let settle = expectation(description: "attesa larga dopo il secondo scatto")
        queue.asyncAfter(deadline: .now() + 0.3) { settle.fulfill() }
        wait(for: [settle], timeout: 5.0)
        let seen = queue.sync { () -> (Bool, Bool) in
            (record.armedWhenTheFirstWorkStarts, record.armedAfterRearming)
        }
        // Allo scatto il primo si e' rilasciato prima del suo lavoro; il secondo era l'unico armato.
        XCTAssertFalse(seen.0)
        XCTAssertTrue(seen.1)
        XCTAssertFalse(isArmed())
    }

    func testAfterTheFireTheTimerHoldsNothing() {
        let fired = expectation(description: "scatta")
        let timer = self.timer!
        weak var weakWork: DispatchWorkItem?
        do {
            let work = DispatchWorkItem { fired.fulfill() }
            weakWork = work
            queue.sync { timer.arm(afterSeconds: 0.02, work: work) }
        }
        wait(for: [fired], timeout: 5.0)
        // Il lavoro lo tiene solo il timer, che lo consegna allo scatto e poi non tiene piu' niente.
        let afterFire = queue.sync { () -> (Bool, Bool) in (timer.isArmed, timer.holdsWork) }
        XCTAssertFalse(afterFire.0)
        XCTAssertFalse(afterFire.1)
        // Il sistema: solo nel registro della CI (vedi la testa del file).
        let released = eventually(timeout: 2.0) { weakWork == nil }
        print("[Q-BEATS][TEST] A412-SEGUITO-3 lavoro lasciato dal sistema entro 2 s dallo scatto: \(released)")
    }

    func testACancelledWorkItemDoesNotRunWhenTheTimerFires() {
        let fired = expectation(description: "work item annullato: non deve partire")
        fired.isInverted = true
        let timer = self.timer!
        let work = DispatchWorkItem { fired.fulfill() }
        queue.sync {
            timer.arm(afterSeconds: 0.02, work: work)
            work.cancel()
        }
        wait(for: [fired], timeout: 0.5)
        // Il timer e' scattato (e si e' rilasciato) senza eseguire il lavoro annullato.
        XCTAssertFalse(isArmed())
    }

    func testATimerLeftByItsOwnerDoesNotFire() {
        let fired = expectation(description: "timer lasciato: non deve scattare")
        fired.isInverted = true
        var owned: StrictOneShotTimer? = StrictOneShotTimer(queue: queue)
        let work = DispatchWorkItem { fired.fulfill() }
        queue.sync { [owned] in
            owned?.arm(afterSeconds: 0.05, work: work)
        }
        // L'ultimo riferimento se ne va qui: `deinit` annulla la sorgente.
        owned = nil
        XCTAssertNil(owned)
        wait(for: [fired], timeout: 0.5)
    }

    // MARK: - A421 · SEGUITO 2 (par. 4.2): il timer che si riarma senza rifarsi (`StrictRearmableTimer`, il guardiano)

    func testTheRearmableTimerFiresOnceAndCanBeArmedAgain() {
        let first = expectation(description: "il primo scatto")
        first.assertForOverFulfill = true
        let second = expectation(description: "il secondo scatto, dopo un armamento nuovo")
        second.assertForOverFulfill = true
        let timer = StrictRearmableTimer(queue: queue)
        XCTAssertEqual(StrictRearmableTimer.leewayMilliseconds, 1)
        let armed = queue.sync { () -> Bool in
            timer.arm(afterSeconds: 0.02) { first.fulfill() }
            return timer.isArmed
        }
        XCTAssertTrue(armed)
        wait(for: [first], timeout: 5.0)
        XCTAssertFalse(queue.sync { timer.isArmed })
        queue.sync { timer.arm(afterSeconds: 0.02) { second.fulfill() } }
        wait(for: [second], timeout: 5.0)
        let settle = expectation(description: "attesa larga")
        queue.asyncAfter(deadline: .now() + 0.3) { settle.fulfill() }
        wait(for: [settle], timeout: 5.0)
        XCTAssertFalse(queue.sync { timer.isArmed })
    }

    /// Un armamento nuovo sostituisce il vecchio (una sorgente sola, ri-programmata); l'annullo ferma il lavoro.
    func testTheRearmableTimerReplacesAndCancels() {
        let old = expectation(description: "il vecchio non deve scattare")
        old.isInverted = true
        let new = expectation(description: "il nuovo scatta")
        let timer = StrictRearmableTimer(queue: queue)
        queue.sync {
            timer.arm(afterSeconds: 0.05) { old.fulfill() }
            timer.arm(afterSeconds: 0.1) { new.fulfill() }
        }
        wait(for: [new], timeout: 5.0)
        wait(for: [old], timeout: 0.5)
        let cancelled = expectation(description: "annullato: non deve scattare")
        cancelled.isInverted = true
        let armedThenCancelled = queue.sync { () -> (Bool, Bool) in
            timer.arm(afterSeconds: 0.05) { cancelled.fulfill() }
            let before = timer.isArmed
            timer.cancel()
            return (before, timer.isArmed)
        }
        XCTAssertTrue(armedThenCancelled.0)
        XCTAssertFalse(armedThenCancelled.1)
        wait(for: [cancelled], timeout: 0.5)
        // Dopo l'annullo si arma di nuovo e scatta.
        let again = expectation(description: "dopo l'annullo scatta")
        queue.sync { timer.arm(afterSeconds: 0.02) { again.fulfill() } }
        wait(for: [again], timeout: 5.0)
    }

    /// Cento armamenti di fila, come il guardiano a ogni buffer: scatta solo l'ultimo.
    func testTheRearmableTimerWithAHundredRearmsFiresOnlyTheLast() {
        let last = expectation(description: "solo l'ultimo scatta")
        last.assertForOverFulfill = true
        let timer = StrictRearmableTimer(queue: queue)
        var fired: [Int] = []
        queue.sync {
            for i in 0..<100 {
                timer.arm(afterSeconds: 0.03) {
                    fired.append(i)
                    if i == 99 { last.fulfill() }
                }
            }
        }
        wait(for: [last], timeout: 5.0)
        let settle = expectation(description: "attesa larga")
        queue.asyncAfter(deadline: .now() + 0.3) { settle.fulfill() }
        wait(for: [settle], timeout: 5.0)
        XCTAssertEqual(queue.sync { fired }, [99])
    }

    /// Un armamento fatto dentro lo scatto resta l'unico armato e scatta.
    func testTheRearmableTimerArmedInsideTheFire() {
        let first = expectation(description: "il primo")
        let second = expectation(description: "il secondo, armato dentro lo scatto del primo")
        let timer = StrictRearmableTimer(queue: queue)
        let record = Record()
        queue.sync {
            timer.arm(afterSeconds: 0.02) {
                record.armedWhenTheFirstWorkStarts = timer.isArmed
                timer.arm(afterSeconds: 0.02) { second.fulfill() }
                record.armedAfterRearming = timer.isArmed
                first.fulfill()
            }
        }
        wait(for: [first, second], timeout: 5.0, enforceOrder: true)
        let seen = queue.sync { () -> (Bool, Bool) in (record.armedWhenTheFirstWorkStarts, record.armedAfterRearming) }
        XCTAssertFalse(seen.0, "allo scatto il lavoro si consegna prima di eseguirlo")
        XCTAssertTrue(seen.1)
    }

    func testTheRearmableTimerLeftByItsOwnerDoesNotFire() {
        let fired = expectation(description: "timer lasciato: non deve scattare")
        fired.isInverted = true
        var owned: StrictRearmableTimer? = StrictRearmableTimer(queue: queue)
        queue.sync { [owned] in
            owned?.arm(afterSeconds: 0.05) { fired.fulfill() }
        }
        owned = nil
        XCTAssertNil(owned)
        wait(for: [fired], timeout: 0.5)
    }
}
