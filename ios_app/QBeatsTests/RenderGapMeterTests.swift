import XCTest

// === A416 — banco del misuratore del buco del render (`RenderGapMeter`, banco Models), mandato §2.3 ===
// Un orologio finto a 24 MHz (quello degli iPhone) e le chiamate di `scheduleNextBuffer` come arrivano: tre insieme
// all'avvio (la scorta), poi una a ogni buffer consumato. I casi del mandato: il regime, la raffica dei richiami
// arretrati (19/10: tre in un millisecondo), un buco di 77 buffer come P11 del 19/10 (contato una volta), i nodi a 44100
// con l'uscita a 48000 (il dente di sega, A415 §4.5). In più: le soglie, la deriva lenta dell'orologio, la ripresa della
// catena dopo una fine di sezione, il primo buffer del rientro a un'ora chiesta, gli eventi «vicini».

final class RenderGapMeterTests: XCTestCase {

    private let tps = 24_000_000.0

    private func t(_ seconds: Double) -> UInt64 {
        UInt64((seconds * tps).rounded())
    }

    private func bufferSeconds(_ rate: Double) -> Double {
        512.0 / rate
    }

    /// Un misuratore e la sua posizione nella prova.
    private struct Run {
        var meter: RenderGapMeter
        var bufferCount: Int
        var now: Double
        let rate: Double
        var gaps: [RenderGapMeter.Gap] = []

        mutating func call(at seconds: Double, ticks: UInt64) -> RenderGapMeter.Outcome {
            now = seconds
            let count = bufferCount
            let nodeRate = rate
            let outcome = meter.observe(nowTicks: ticks, bufferCount: count, sampleRate: nodeRate)
            bufferCount += 1
            if case .gap(let gap) = outcome { gaps.append(gap) }
            return outcome
        }
    }

    /// L'avvio: la scorta di tre buffer all'istante `start`, poi il primo completamento dopo `firstCompletion`.
    private func started(at start: Double = 100.0, firstCompletion: Double = 0.005, rate: Double = 48_000) -> Run {
        var run = Run(meter: RenderGapMeter(bufferFrames: 512, sampleRate: rate, ticksPerSecond: tps),
                      bufferCount: 0, now: start, rate: rate)
        for _ in 0..<3 {
            XCTAssertEqual(run.call(at: start, ticks: t(start)), .warmup)
        }
        let first = start + firstCompletion
        XCTAssertEqual(run.call(at: first, ticks: t(first)), .regular(gapSeconds: 0, baseSeconds: 0))
        return run
    }

    /// `n` chiamate in regime, una ogni `step` secondi (di norma un buffer).
    private func regime(_ run: inout Run, calls n: Int, step: Double? = nil) {
        let s = step ?? bufferSeconds(run.rate)
        for _ in 0..<n {
            let next = run.now + s
            _ = run.call(at: next, ticks: t(next))
        }
    }

    // MARK: - Avvio e regime

    /// Le prime tre chiamate sono la scorta; alla quarta si prende il riferimento, con lo scarto a zero.
    func testWarmupThenReferenceAtTheFourthCall() {
        let run = started()
        XCTAssertEqual(run.meter.referenceBufferCount, 3)
        XCTAssertEqual(run.meter.referenceTicks, t(100.005))
        XCTAssertEqual(run.meter.baseSeconds, 0)
        XCTAssertEqual(RenderGapMeter.warmupCalls, 3)
    }

    /// Il regime, dieci secondi a 48 kHz: nessun buco, la base resta a zero.
    func testSteadyRegimeHasNoGap() {
        var run = started()
        regime(&run, calls: 1000)
        XCTAssertTrue(run.gaps.isEmpty)
        XCTAssertEqual(run.meter.gapsCounted, 0)
        XCTAssertEqual(run.meter.baseSeconds!, 0, accuracy: 1e-6)
    }

    /// Un richiamo in ritardo di due buffer e poi la raffica (tre in un millisecondo): sotto la soglia, niente.
    func testALateCallbackAndItsBurstAreAbsorbed() {
        var run = started()
        regime(&run, calls: 100)
        let late = run.now + bufferSeconds(48_000) * 3
        _ = run.call(at: late, ticks: t(late))
        _ = run.call(at: late + 0.0005, ticks: t(late + 0.0005))
        _ = run.call(at: late + 0.001, ticks: t(late + 0.001))
        regime(&run, calls: 200)
        XCTAssertTrue(run.gaps.isEmpty)
    }

    // MARK: - Il buco di P11

    /// P11 del 19/10: il render fermo per 77 buffer (0,821 s), poi la raffica dei richiami arretrati, poi il regime.
    /// Un buco solo, della sua durata; la base riprende al livello nuovo e il regime dopo non conta niente.
    func testTheP11HoleOf77BuffersIsCountedOnce() {
        var run = started()
        regime(&run, calls: 100)
        let buffer = bufferSeconds(48_000)
        let hole = 77 * buffer
        let lastRegular = run.now
        let resumed = lastRegular + buffer + hole
        let outcome = run.call(at: resumed, ticks: t(resumed))
        guard case .gap(let gap) = outcome else {
            return XCTFail("atteso un buco, avuto \(outcome)")
        }
        XCTAssertEqual(gap.holeSeconds, hole, accuracy: 0.001)
        XCTAssertEqual(gap.gapSeconds, hole, accuracy: 0.001)
        XCTAssertEqual(gap.baseSeconds, 0, accuracy: 0.001)
        XCTAssertEqual(gap.bufferCount, 104)
        XCTAssertEqual(Double(gap.startTicks) / tps, lastRegular + buffer, accuracy: 0.001)
        // La raffica: tre in un millisecondo.
        _ = run.call(at: resumed + 0.0005, ticks: t(resumed + 0.0005))
        _ = run.call(at: resumed + 0.001, ticks: t(resumed + 0.001))
        regime(&run, calls: 500)
        XCTAssertEqual(run.gaps.count, 1)
        XCTAssertEqual(run.meter.gapsCounted, 1)
        // La base nuova è il livello dopo il buco e la raffica.
        XCTAssertEqual(run.meter.baseSeconds!, hole - 2 * buffer + 0.001, accuracy: 0.0005)
    }

    /// Due buchi lontani: due righe.
    func testTwoHolesAreTwoGaps() {
        var run = started()
        regime(&run, calls: 100)
        for _ in 0..<2 {
            let resumed = run.now + bufferSeconds(48_000) + 0.5
            _ = run.call(at: resumed, ticks: t(resumed))
            regime(&run, calls: 300)
        }
        XCTAssertEqual(run.gaps.count, 2)
        XCTAssertEqual(run.gaps[0].holeSeconds, 0.5, accuracy: 0.001)
        XCTAssertEqual(run.gaps[1].holeSeconds, 0.5, accuracy: 0.001)
    }

    /// La soglia: tre buffer sopra la base. Due buffer e mezzo di ritardo no, tre e mezzo sì.
    func testTheThreshold() {
        XCTAssertEqual(RenderGapMeter.thresholdBuffers, 3)
        var below = started()
        regime(&below, calls: 50)
        let b = bufferSeconds(48_000)
        let lateBelow = below.now + b + 2.5 * b
        _ = below.call(at: lateBelow, ticks: t(lateBelow))
        XCTAssertTrue(below.gaps.isEmpty)
        var above = started()
        regime(&above, calls: 50)
        let lateAbove = above.now + b + 3.5 * b
        _ = above.call(at: lateAbove, ticks: t(lateAbove))
        XCTAssertEqual(above.gaps.count, 1)
        XCTAssertEqual(above.gaps[0].holeSeconds, 3.5 * b, accuracy: 0.0001)
    }

    // MARK: - Nodi e uscita a frequenze diverse

    /// I nodi a 44100 e l'uscita a 48000 (l'iPad del 19/10 dalle 10:51): a ogni ciclo d'uscita (512 campioni a 48 kHz)
    /// il mixer prende 470,4 campioni dal lettore, e un buffer da 512 finisce quasi a ogni ciclo, saltandone uno ogni
    /// undici circa. Il dente di sega resta sotto la soglia: un minuto senza buchi.
    func testNodesAt44100WithTheOutputAt48000() {
        let rate = 44_100.0
        var run = started(firstCompletion: 0, rate: rate)
        let cycle = 512.0 / 48_000.0
        let pulledPerCycle = 512.0 * rate / 48_000.0
        var pulled = 0.0
        var completed = 0
        let start = run.now
        var maxAboveBase = 0.0
        for i in 1...5625 {   // un minuto di cicli d'uscita
            pulled += pulledPerCycle
            let done = Int(pulled / 512.0)
            while completed < done {
                completed += 1
                let now = start + Double(i) * cycle
                let outcome = run.call(at: now, ticks: t(now))
                if case .regular(let gap, let base) = outcome {
                    maxAboveBase = max(maxAboveBase, gap - base)
                }
            }
        }
        XCTAssertTrue(run.gaps.isEmpty)
        XCTAssertGreaterThan(maxAboveBase, 0.005)
        XCTAssertLessThan(maxAboveBase, 0.012)
    }

    // MARK: - La deriva lenta

    /// L'orologio dell'hardware più lento di 100 parti per milione per venti minuti: la base segue, nessun buco.
    func testASlowClockDriftDoesNotMakeFalseHoles() {
        var run = started()
        regime(&run, calls: 112_500, step: bufferSeconds(48_000) * (1 + 100e-6))
        XCTAssertTrue(run.gaps.isEmpty)
    }

    /// E più veloce: la base scende con lui.
    func testAFastClockDriftDoesNotMakeFalseHoles() {
        var run = started()
        regime(&run, calls: 112_500, step: bufferSeconds(48_000) * (1 - 100e-6))
        XCTAssertTrue(run.gaps.isEmpty)
    }

    /// Un buco dopo venti minuti di deriva si vede ancora.
    func testAHoleAfterADriftIsStillSeen() {
        var run = started()
        let step = bufferSeconds(48_000) * (1 + 100e-6)
        regime(&run, calls: 112_500, step: step)
        let resumed = run.now + step + 0.2
        _ = run.call(at: resumed, ticks: t(resumed))
        XCTAssertEqual(run.gaps.count, 1)
        XCTAssertEqual(run.gaps[0].holeSeconds, 0.2, accuracy: 0.001)
    }

    // MARK: - Le ripartenze della catena

    /// Un avvio (il primo buffer, `bufferCount` zero) riprende il riferimento, anche in mezzo a un regime.
    func testAStartRestartsTheReference() {
        var run = started()
        regime(&run, calls: 100)
        run.bufferCount = 0
        let restart = run.now + 3.0
        XCTAssertEqual(run.call(at: restart, ticks: t(restart)), .warmup)
        XCTAssertEqual(run.call(at: restart, ticks: t(restart)), .warmup)
        XCTAssertEqual(run.call(at: restart, ticks: t(restart)), .warmup)
        XCTAssertEqual(run.call(at: restart + 0.004, ticks: t(restart + 0.004)), .regular(gapSeconds: 0, baseSeconds: 0))
        regime(&run, calls: 100)
        XCTAssertTrue(run.gaps.isEmpty)
    }

    /// Una frequenza diversa riprende il riferimento.
    func testASampleRateChangeRestartsTheReference() {
        var run = started()
        regime(&run, calls: 10)
        let next = run.now + bufferSeconds(48_000)
        let count = run.bufferCount
        let outcome = run.meter.observe(nowTicks: t(next), bufferCount: count, sampleRate: 44_100)
        XCTAssertEqual(outcome, .warmup)
        XCTAssertEqual(run.meter.sampleRate, 44_100)
        XCTAssertNil(run.meter.referenceTicks)
    }

    /// A421 — il drenaggio di fine sezione senza la ripartenza del misuratore (mandato A421, par. 2.2 i; referto A420,
    /// Aperto 3): il richiamo che entra nel drenaggio non programma niente e il misuratore non lo vede; gli altri due
    /// buffer in volo continuano la catena con un anello in meno, al passo di sempre. Lo scarto sale di un buffer e resta
    /// lì, sotto la soglia di tre: nessun buco finto, per tutta la coda della canzone, e il misuratore resta sveglio.
    func testTheDrainWithoutARestartIsNotAHole() {
        var run = started()
        regime(&run, calls: 100)
        // Il richiamo del drenaggio: arriva al passo di un buffer ma non chiama il misuratore e non conta un buffer.
        run.now += bufferSeconds(48_000)
        // I due in volo e la catena dopo: una chiamata a ogni buffer, con un buffer in meno programmato.
        regime(&run, calls: 2000)
        XCTAssertTrue(run.gaps.isEmpty)
        XCTAssertEqual(run.meter.gapsCounted, 0)
        // Lo scarto è di un buffer sopra la base di prima, e la base lo riassorbe (un millisecondo al secondo).
        let nextTime = run.now + bufferSeconds(48_000)
        guard case .regular(let gap, let base) = run.call(at: nextTime, ticks: t(nextTime)) else {
            return XCTFail("atteso il regime")
        }
        XCTAssertEqual(gap, bufferSeconds(48_000), accuracy: 0.0005)
        XCTAssertLessThan(gap - base, RenderGapMeter.thresholdBuffers * bufferSeconds(48_000))
    }

    /// Con la ripartenza del misuratore al drenaggio (com'era fino ad A420, `restart`): il riferimento si rifà sulla
    /// catena che continua, e nemmeno così c'è un buco. ⚠️ A421: la ripartenza al drenaggio è uscita dal motore
    /// (`kickScheduling` non ha chiamanti, e la catena non si ferma); `restart` resta per gli avvii e la frequenza.
    func testTheChainAfterASectionEndIsNotAHole() {
        var run = started()
        regime(&run, calls: 100)
        run.meter.restart(sampleRate: 48_000)
        let kick = run.now + 2.0
        for _ in 0..<3 {
            XCTAssertEqual(run.call(at: kick, ticks: t(kick)), .warmup)
        }
        _ = run.call(at: kick + 0.006, ticks: t(kick + 0.006))
        regime(&run, calls: 200)
        XCTAssertTrue(run.gaps.isEmpty)
    }

    /// Il rientro del Direttore: i tre buffer al fuoco, il primo all'ora chiesta 150 ms dopo. Il riferimento al primo
    /// completamento non vede un buco.
    func testTheRejoinWithTheFirstBufferAtARequestedTime() {
        var run = started(firstCompletion: 0.150)
        regime(&run, calls: 300)
        XCTAssertTrue(run.gaps.isEmpty)
    }

    // MARK: - Gli eventi vicini

    func testEventsNearAHole() {
        let start = t(200.0)
        let now = t(200.8)
        XCTAssertTrue(RenderGapMeter.isNear(eventTicks: t(199.5), holeStartTicks: start, nowTicks: now, ticksPerSecond: tps))
        XCTAssertTrue(RenderGapMeter.isNear(eventTicks: t(200.1), holeStartTicks: start, nowTicks: now, ticksPerSecond: tps))
        XCTAssertTrue(RenderGapMeter.isNear(eventTicks: now, holeStartTicks: start, nowTicks: now, ticksPerSecond: tps))
        XCTAssertFalse(RenderGapMeter.isNear(eventTicks: t(198.5), holeStartTicks: start, nowTicks: now, ticksPerSecond: tps))
        XCTAssertFalse(RenderGapMeter.isNear(eventTicks: t(200.801), holeStartTicks: start, nowTicks: now, ticksPerSecond: tps))
        XCTAssertFalse(RenderGapMeter.isNear(eventTicks: t(199.5), holeStartTicks: start, nowTicks: now, ticksPerSecond: 0))
        XCTAssertEqual(RenderGapMeter.eventWindowBeforeSeconds, 1.0)
    }

    /// L'inizio stimato di un buco è adesso meno il buco, anche a ridosso dell'inizio dell'orologio.
    func testTheStartOfAHoleIsNowMinusTheHole() {
        var run = started(at: 0.0, firstCompletion: 0.0)
        let resumed = bufferSeconds(48_000) + 0.3
        _ = run.call(at: resumed, ticks: t(resumed))
        XCTAssertEqual(run.gaps.count, 1)
        XCTAssertEqual(Double(run.gaps[0].startTicks) / tps, resumed - run.gaps[0].holeSeconds, accuracy: 0.0001)
    }
}
