import XCTest

// === A386 · FASE B2d — banco del conto dei vuoti dell'ascolto (banco Models) ===
// Il tipo conta e dice quando scrivere una riga di log; non decide niente. Tick a 24.000 per
// millisecondo: un quarto di secondo (la cadenza dell'ascolto) = 6.000.000 tick; «in ritardo»
// oltre 1,5 s = 36.000.000 tick; riepilogo ogni 40 letture. Attesi letterali.

final class DirectorHeardGapMeterTests: XCTestCase {

    private typealias Meter = DirectorHeardGapMeter
    private let quarter: UInt64 = 6_000_000           // 0,25 s
    private let second: UInt64 = 24_000_000           // 1,0 s
    private let lateAfter: UInt64 = 36_000_000        // 1,5 s

    /// Una fila di letture a un quarto di secondo l'una, a partire da `start`: `hits` dice per
    /// ogni lettura se e' un colpo. Rende i passi, nell'ordine.
    private func feed(_ meter: Meter, from start: UInt64, hits: [Bool], heard: Bool = true,
                      summaryEvery: Int = 40) -> [Meter.Step] {
        var steps: [Meter.Step] = []
        var current = meter
        for (index, hit) in hits.enumerated() {
            let step = current.observe(linkEnabled: true, hit: hit, heard: heard,
                                       now: start + UInt64(index) * quarter,
                                       lateAfterTicks: lateAfter, summaryEvery: summaryEvery)
            steps.append(step)
            current = step.next
        }
        return steps
    }

    func testBeforeTheFirstHitThereIsNoGapAndNoRun() {
        let steps = feed(.start, from: 0, hits: [false, false, false, false, false, false, false, false])
        for step in steps {
            XCTAssertNil(step.late)
            XCTAssertNil(step.resumed)
            XCTAssertNil(step.summary)
        }
        XCTAssertEqual(steps.last?.next.run, 0)
        XCTAssertNil(steps.last?.next.lastHitAt)
        XCTAssertEqual(steps.last?.next.samples, 8)
    }

    /// A regime: un colpo ogni quattro letture. Fila 3, vuoto di un secondo, nessun ritardo.
    func testSteadyStateOneHitEveryFourSamples() {
        var pattern: [Bool] = []
        for index in 0..<40 { pattern.append(index % 4 == 0) }
        let steps = feed(.start, from: 0, hits: pattern)
        XCTAssertTrue(steps.allSatisfy { $0.late == nil && $0.resumed == nil })
        let summary = steps.last?.summary
        XCTAssertEqual(summary, Meter.Summary(samples: 40, hits: 10, heardSamples: 40,
                                              maxRun: 3, maxGapTicks: second, lates: 0))
        XCTAssertEqual(summary?.samplesWithoutHit, 30)
    }

    /// Ogni passo porta il vuoto e la fila di quella lettura: e' cio' che la riga del cambio di
    /// stato scrive («da quanto non arrivava un colpo»).
    func testEachStepReportsTheGapAndTheRunOfThatSample() {
        let steps = feed(.start, from: 0, hits: [false, true, false, false, true])
        XCTAssertNil(steps[0].gapTicks)
        XCTAssertEqual(steps[0].run, 0)
        // il primo colpo non chiude nessun vuoto
        XCTAssertNil(steps[1].gapTicks)
        XCTAssertEqual(steps[1].run, 0)
        XCTAssertEqual(steps[2].gapTicks, quarter)
        XCTAssertEqual(steps[2].run, 1)
        XCTAssertEqual(steps[3].gapTicks, 2 * quarter)
        XCTAssertEqual(steps[3].run, 2)
        // il secondo colpo chiude un vuoto di tre quarti di secondo e una fila di due
        XCTAssertEqual(steps[4].gapTicks, 3 * quarter)
        XCTAssertEqual(steps[4].run, 2)
    }

    func testTheSummaryResetsTheWindowButNotTheOpenGap() {
        var pattern: [Bool] = []
        for index in 0..<40 { pattern.append(index % 4 == 0) }
        let steps = feed(.start, from: 0, hits: pattern)
        let after = steps.last!.next
        XCTAssertEqual(after.samples, 0)
        XCTAssertEqual(after.hits, 0)
        XCTAssertEqual(after.maxRun, 0)
        XCTAssertEqual(after.maxGapTicks, 0)
        XCTAssertEqual(after.lates, 0)
        // l'ultimo colpo era alla lettura 36: tre letture senza colpo sono ancora aperte
        XCTAssertEqual(after.run, 3)
        XCTAssertEqual(after.lastHitAt, 36 * quarter)
    }

    /// Una ripetizione saltata: fra due colpi passano due secondi. La riga «in ritardo» esce
    /// una volta sola, alla prima lettura a 1,5 s dall'ultimo colpo; il colpo dopo la chiude.
    func testALateRepetitionWritesOneLateLineAndOneResumedLine() {
        // colpo, 7 letture senza, colpo
        let steps = feed(.start, from: 0, hits: [true, false, false, false, false, false, false, false, true])
        let lates = steps.compactMap { $0.late }
        XCTAssertEqual(lates, [Meter.Late(gapTicks: 6 * quarter, run: 6)])
        XCTAssertNotNil(steps[6].late)
        XCTAssertNil(steps[7].late)
        XCTAssertEqual(steps[8].resumed, Meter.Resumed(gapTicks: 8 * quarter, run: 7))
        XCTAssertEqual(steps[8].next.run, 0)
        XCTAssertFalse(steps[8].next.lateOpen)
        XCTAssertEqual(steps[8].next.maxGapTicks, 2 * second)
        XCTAssertEqual(steps[8].next.maxRun, 7)
        XCTAssertEqual(steps[8].next.lates, 1)
    }

    /// La perdita vera: una riga «in ritardo» a 1,5 s e poi silenzio, non una riga a lettura.
    func testATrueLossWritesTheLateLineOnceAndNothingAfter() {
        var pattern: [Bool] = [true]
        for _ in 0..<60 { pattern.append(false) }
        let steps = feed(.start, from: 0, hits: pattern, summaryEvery: 0)
        XCTAssertEqual(steps.compactMap { $0.late }.count, 1)
        XCTAssertTrue(steps.allSatisfy { $0.resumed == nil })
        XCTAssertEqual(steps.last?.next.run, 60)
        XCTAssertEqual(steps.last?.next.maxGapTicks, 60 * quarter)
        // dodici letture senza colpo sono i 3 s della soglia
        XCTAssertEqual(steps[12].next.run, 12)
        XCTAssertEqual(steps[12].next.maxGapTicks, 3 * second)
    }

    func testTheOpenGapEntersTheSummaryEvenWithoutAClosingHit() {
        var pattern: [Bool] = [true]
        for _ in 0..<39 { pattern.append(false) }
        let steps = feed(.start, from: 0, hits: pattern, heard: false)
        XCTAssertEqual(steps.last?.summary, Meter.Summary(samples: 40, hits: 1, heardSamples: 0,
                                                          maxRun: 39, maxGapTicks: 39 * quarter, lates: 1))
    }

    func testHeardSamplesAreCountedPerWindow() {
        var current = Meter.start
        var last: Meter.Step? = nil
        for index in 0..<40 {
            let step = current.observe(linkEnabled: true, hit: index % 4 == 0, heard: index < 25,
                                       now: UInt64(index) * quarter,
                                       lateAfterTicks: lateAfter, summaryEvery: 40)
            current = step.next
            last = step
        }
        XCTAssertEqual(last?.summary?.heardSamples, 25)
    }

    /// Un Play o uno Stop ricevuto chiude il vuoto in corso senza contare come lettura.
    func testATransportEventClosesTheGapAndIsNotASample() {
        let steps = feed(.start, from: 0, hits: [true, false, false, false, false, false, false])
        let open = steps.last!.next
        XCTAssertTrue(open.lateOpen)
        let event = open.observeTransportEvent(linkEnabled: true, now: 7 * quarter)
        XCTAssertEqual(event.resumed, Meter.Resumed(gapTicks: 7 * quarter, run: 6))
        XCTAssertNil(event.late)
        XCTAssertNil(event.summary)
        XCTAssertEqual(event.next.run, 0)
        XCTAssertFalse(event.next.lateOpen)
        XCTAssertEqual(event.next.lastHitAt, 7 * quarter)
        XCTAssertEqual(event.next.samples, open.samples)
        XCTAssertEqual(event.next.hits, open.hits)
    }

    func testATransportEventWithoutAnOpenLateGapWritesNothing() {
        let steps = feed(.start, from: 0, hits: [true, false])
        let event = steps.last!.next.observeTransportEvent(linkEnabled: true, now: 2 * quarter)
        XCTAssertNil(event.resumed)
        XCTAssertEqual(event.next.lastHitAt, 2 * quarter)
        XCTAssertEqual(event.next.maxGapTicks, 2 * quarter)
    }

    func testLinkOffStartsOver() {
        let steps = feed(.start, from: 0, hits: [true, false, false, false, false, false, false])
        let off = steps.last!.next.observe(linkEnabled: false, hit: false, heard: false, now: 8 * quarter,
                                           lateAfterTicks: lateAfter, summaryEvery: 40)
        XCTAssertEqual(off.next, .start)
        XCTAssertNil(off.late)
        XCTAssertNil(off.summary)
        let offEvent = steps.last!.next.observeTransportEvent(linkEnabled: false, now: 8 * quarter)
        XCTAssertEqual(offEvent.next, .start)
        XCTAssertNil(offEvent.resumed)
    }
}
