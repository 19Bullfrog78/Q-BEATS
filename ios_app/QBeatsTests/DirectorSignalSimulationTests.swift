import XCTest

// === A386 · FASE B2d — banco di simulazione del segnale «sento il Direttore» (banco Models) ===
// Mandato «A386 · FASE B2d», §3.a e §3.b: un banco che simula i due battiti — il Direttore che
// ripete a 1 s e il Follower che ascolta — con lo scarto dei timer e la ripetizione che cambia
// l'ora, e fa passare ogni lettura dal tipo vero (`DirectorHeardTracker.observe`).
// Tick a 24.000 per millisecondo (misura A382 §3.6), come sugli apparecchi del collaudo.
// Com'e' fatta la simulazione: la ripetizione n arriva sul Follower al tick `arrivals[n]` e
// porta l'ora `times[n]`; a ogni lettura il Follower vede l'ora dell'ultima ripetizione
// arrivata (prima di ogni arrivo: l'ora di partenza). Niente altro: nessuna rete, nessun Link.
// Due cose si possono scegliere, e sono le due meta' della correzione:
//  · ogni quanto il Follower ascolta: 1 s (prima di B2d) o `DirectorSignalCadence` (0,25 s);
//  · le ore che il Direttore scrive: due valori alternati (prima di B2d, `twoValueTimes`) o il
//    giro a quattro valori del tipo vero (`productionTimes`, da `DirectorReannounceDecision`).
//    Il giro a tre valori (`threeValueTimes`) e' una strada scartata: sta qui solo per tenere
//    scritto, con un test, perche' i valori sono quattro.
// I test «…WithOneSecondListeningAndTwoValues…» tengono fermo IL DIFETTO: con la cadenza e le
// ore di prima, lo stesso banco perde il Direttore. Sono la prova che i test di produzione
// sarebbero rossi senza la correzione. I test «…Production…» usano le costanti e il tipo che
// il motore usa davvero: se qualcuno riporta l'ascolto a 1 s o il giro a due valori, diventano
// rossi.
// Gli scarti pseudo-casuali vengono da un generatore lineare scritto qui (stesso seme, stessi
// numeri a ogni esecuzione): niente di casuale davvero.

final class DirectorSignalSimulationTests: XCTestCase {

    private let ms: UInt64 = 24_000                   // 1 ms
    private let second: UInt64 = 24_000_000           // 1,0 s
    private let threshold: UInt64 = 72_000_000        // 3,0 s, la soglia del motore
    private let base: UInt64 = 3_452_864_540_640      // un'ora d'avvio: quella del log D7

    /// La cadenza d'ascolto di produzione, in tick (0,25 s = 6.000.000).
    private var listen: UInt64 {
        UInt64((DirectorSignalCadence.listenPeriodSeconds * 24_000_000.0).rounded())
    }

    /// Il leeway del timer d'ascolto di produzione, in tick (50 ms = 1.200.000).
    private var leeway: UInt64 {
        UInt64(DirectorSignalCadence.listenLeewayMilliseconds) * ms
    }

    // MARK: - Le ore che il Direttore scrive

    /// Prima di B2d: +1 ms, −1 ms a giri alterni sull'ora catturata. Due valori.
    private func twoValueTimes(_ count: Int) -> [UInt64] {
        var times: [UInt64] = []
        var value = base
        var plus = true
        for _ in 0..<count {
            value = plus ? value + ms : value - ms
            plus = !plus
            times.append(value)
        }
        return times
    }

    /// Produzione: le ore le scrive `DirectorReannounceDecision`, ognuna sull'ora scritta dalla
    /// precedente (la cattura restituisce cio' che e' stato scritto).
    private func productionTimes(_ count: Int) -> [UInt64] {
        var times: [UInt64] = []
        var captured = base
        var cycle = DirectorReannounceDecision.Cycle.start
        for _ in 0..<count {
            let decision = DirectorReannounceDecision(role: .direttore, userLinkEnabled: true,
                                                      startStopSyncEnabled: true, linkEnabled: true,
                                                      showOpen: true, sessionPlaying: false,
                                                      capturedTime: captured, shiftTicks: ms, cycle: cycle)
            guard case .reannounce(_, let at) = decision.outcome else {
                XCTFail("attesa una ripetizione")
                return times
            }
            times.append(at)
            captured = at
            cycle = decision.nextCycle
        }
        return times
    }

    // MARK: - La simulazione

    private struct Outcome {
        /// Fronti «sento» -> «non sento».
        var losses = 0
        var firstLossAt: UInt64? = nil
        /// Il primo fronte «sento» -> «non sento» dopo il tick `after` dato alla simulazione.
        var firstLossAfter: UInt64? = nil
        var hits = 0
        var samples = 0
        /// La fila piu' lunga di letture senza colpo, dopo il primo colpo.
        var maxRun = 0
        /// Il vuoto piu' lungo fra due colpi.
        var maxGap: UInt64 = 0
        /// «Sento» alla fine.
        var heardAtTheEnd = false
    }

    /// `times[n]` = l'ora che porta la ripetizione n; `arrivals[n]` = il tick a cui arriva sul
    /// Follower (se `arrivals` e' piu' corto di `times`, le ripetizioni oltre non arrivano: il
    /// Direttore ha smesso). `sampleTimes` = i tick delle letture del Follower, in ordine.
    private func simulate(times: [UInt64], arrivals: [UInt64], sampleTimes: [UInt64],
                          after: UInt64 = 0) -> Outcome {
        var outcome = Outcome()
        var tracker = DirectorHeardTracker.start
        var previousHeard = false
        var run = 0
        var lastHit: UInt64? = nil
        let count = min(times.count, arrivals.count)
        for now in sampleTimes {
            var latest = -1
            for index in 0..<count where arrivals[index] <= now {
                latest = index
            }
            let value = latest < 0 ? base : times[latest]
            let verdict = tracker.observe(sample: DirectorHeardSample(linkEnabled: true, isPlaying: false,
                                                                      timeForIsPlaying: value),
                                          now: now, thresholdTicks: threshold,
                                          ownTimelineWriteSinceLastSample: false)
            tracker = verdict.next
            if previousHeard && !verdict.heard {
                outcome.losses += 1
                if outcome.firstLossAt == nil { outcome.firstLossAt = now }
                if outcome.firstLossAfter == nil && now > after { outcome.firstLossAfter = now }
            }
            previousHeard = verdict.heard
            if verdict.hit {
                if let last = lastHit, now - last > outcome.maxGap { outcome.maxGap = now - last }
                lastHit = now
                run = 0
                outcome.hits += 1
            } else if lastHit != nil {
                run += 1
                if run > outcome.maxRun { outcome.maxRun = run }
            }
            outcome.samples += 1
        }
        outcome.heardAtTheEnd = previousHeard
        return outcome
    }

    /// Le letture del Follower su una griglia regolare, senza scarto: `offset + k × period`
    /// fino a `duration` compreso.
    private func grid(period: UInt64, offset: UInt64, duration: UInt64) -> [UInt64] {
        var result: [UInt64] = []
        var now = offset
        while now <= duration {
            result.append(now)
            now += period
        }
        return result
    }

    /// Generatore lineare congruente a 64 bit: numeri uguali a ogni esecuzione.
    private struct Lcg {
        var state: UInt64
        /// Un intero fra 0 e `bound` compresi.
        mutating func below(_ bound: UInt64) -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return (state >> 33) % (bound + 1)
        }
    }

    // MARK: - 1. Lo schema del log D7 (collaudo dell'01/10/2026, 20:03:12 e 20:04:31)

    /// I due battiti a 1 s quasi in fase: dal quinto giro la ripetizione arriva a turno 10 ms
    /// prima e 10 ms dopo la lettura del Follower. Trenta secondi.
    private func d7Arrivals() -> [UInt64] {
        var arrivals: [UInt64] = []
        for n in 0..<32 {
            let late: UInt64 = (n >= 5 && n % 2 == 1) ? 20 * ms : 0
            let nominal: UInt64 = UInt64(n) * second
            let network: UInt64 = 5 * ms
            arrivals.append(nominal + network + late)
        }
        return arrivals
    }

    /// IL DIFETTO: ascolto a 1 s e due valori alternati. Fra due letture cadono zero ripetizioni
    /// oppure due (e l'ora torna uguale): quattro colpi all'inizio, poi nessuno. «Non sento»
    /// esce alla terza lettura senza colpo, con il Direttore che ripete ogni secondo.
    func testD7SchemaWithOneSecondListeningAndTwoValuesLosesTheDirector() {
        let outcome = simulate(times: twoValueTimes(32), arrivals: d7Arrivals(),
                               sampleTimes: grid(period: second, offset: 15 * ms, duration: 30 * second))
        XCTAssertEqual(outcome.samples, 30)
        XCTAssertEqual(outcome.hits, 4)
        XCTAssertEqual(outcome.losses, 1)
        XCTAssertEqual(outcome.firstLossAt, 7 * second + 15 * ms)
        XCTAssertFalse(outcome.heardAtTheEnd)
    }

    /// LA CORREZIONE: stessi arrivi, cadenza d'ascolto e ore di produzione. Ogni ripetizione e'
    /// un colpo; mai «non sento»; fra due colpi al piu' un secondo e un quarto.
    func testD7SchemaWithProductionListeningAndFourValuesNeverLosesTheDirector() {
        let outcome = simulate(times: productionTimes(32), arrivals: d7Arrivals(),
                               sampleTimes: grid(period: listen, offset: 15 * ms, duration: 30 * second))
        XCTAssertEqual(outcome.samples, 120)
        XCTAssertEqual(outcome.hits, 29)
        XCTAssertEqual(outcome.losses, 0)
        XCTAssertTrue(outcome.heardAtTheEnd)
        XCTAssertEqual(outcome.maxRun, 4)
        XCTAssertEqual(outcome.maxGap, second + listen)
    }

    /// Ognuna delle due meta', da sola, regge lo schema di D7: l'ascolto fitto vede ogni
    /// ripetizione; il giro a quattro valori rende un colpo anche due ripetizioni fra due letture
    /// (un colpo ogni due secondi: un secondo solo di margine sulla soglia).
    func testD7SchemaEachHalfOfTheFixAloneHolds() {
        let listeningOnly = simulate(times: twoValueTimes(32), arrivals: d7Arrivals(),
                                     sampleTimes: grid(period: listen, offset: 15 * ms, duration: 30 * second))
        XCTAssertEqual(listeningOnly.losses, 0)
        XCTAssertEqual(listeningOnly.maxGap, second + listen)

        let fourValuesOnly = simulate(times: productionTimes(32), arrivals: d7Arrivals(),
                                      sampleTimes: grid(period: second, offset: 15 * ms, duration: 30 * second))
        XCTAssertEqual(fourValuesOnly.losses, 0)
        XCTAssertEqual(fourValuesOnly.hits, 16)
        XCTAssertEqual(fourValuesOnly.maxGap, 2 * second)
    }

    /// Lo schema di D7 dentro la macchina vera, da Ready (FUORI armato sulla canzone 1): col
    /// difetto il fronte «non sento» toglie la scelta (2D-R2, «no longer ready»); con la
    /// correzione il fronte non nasce e la scelta resta.
    func testD7SchemaThroughTheRealMachineKeepsTheArmedSong() {
        let ready = FollowerSyncState.out(armed: 1)

        let defect = simulate(times: twoValueTimes(32), arrivals: d7Arrivals(),
                              sampleTimes: grid(period: second, offset: 15 * ms, duration: 30 * second))
        XCTAssertEqual(defect.losses, 1)
        let lost = FollowerSyncDecision.transition(state: ready,
                                                   event: .directorHeard(false, engineRunning: false))
        XCTAssertEqual(lost.state, .out(armed: nil))
        XCTAssertEqual(lost.outReason, .lostWhileArmed(chosen: 1))

        let fixed = simulate(times: productionTimes(32), arrivals: d7Arrivals(),
                             sampleTimes: grid(period: listen, offset: 15 * ms, duration: 30 * second))
        XCTAssertEqual(fixed.losses, 0)
        // l'unico fronte del segnale e' «sento», che non cambia stato
        let heard = FollowerSyncDecision.transition(state: ready,
                                                    event: .directorHeard(true, engineRunning: false))
        XCTAssertEqual(heard.state, ready)
        XCTAssertNil(heard.outReason)
    }

    // MARK: - 2. Una ripetizione in ritardo (log C1 del 30/09, 16:21:43: 1,751 s e poi 0,248 s)

    /// La sesta ripetizione arriva 0,82 s dopo e cade nello stesso quarto di secondo della
    /// settima; l'ottava arriva 20 ms dopo il solito.
    private func lateArrivals() -> [UInt64] {
        var arrivals: [UInt64] = []
        for n in 0..<32 {
            let nominal: UInt64 = UInt64(n) * second
            var at: UInt64 = nominal + 240 * ms
            if n == 6 { at += 820 * ms }
            if n == 8 { at += 20 * ms }
            arrivals.append(at)
        }
        return arrivals
    }

    /// Perche' l'ascolto fitto da solo non basta: con due valori alternati le due ripetizioni
    /// arrivate insieme riportano l'ora al valore di prima, e fra due colpi passano 3,25 s.
    func testALateRepetitionStillLosesTheDirectorWithTwoValuesEvenAtProductionListening() {
        let outcome = simulate(times: twoValueTimes(32), arrivals: lateArrivals(),
                               sampleTimes: grid(period: listen, offset: 0, duration: 30 * second))
        XCTAssertEqual(outcome.losses, 1)
        XCTAssertEqual(outcome.firstLossAt, 8 * second + listen)
        XCTAssertEqual(outcome.maxGap, 3 * second + listen)
    }

    /// Col giro a quattro valori le due ripetizioni arrivate insieme sono un colpo: il vuoto
    /// piu' lungo e' di due secondi, la soglia non si tocca.
    func testALateRepetitionNeverLosesTheDirectorInProduction() {
        let outcome = simulate(times: productionTimes(32), arrivals: lateArrivals(),
                               sampleTimes: grid(period: listen, offset: 0, duration: 30 * second))
        XCTAssertEqual(outcome.losses, 0)
        XCTAssertTrue(outcome.heardAtTheEnd)
        XCTAssertEqual(outcome.maxRun, 7)
        XCTAssertEqual(outcome.maxGap, 2 * second)
    }

    // MARK: - 3. Ripetizioni perse di fila: perche' il giro ha quattro valori e non tre

    /// La strada scartata: tre valori, +1 ms, −2 ms, +1 ms (T+1, T−1, T). L'ora torna uguale
    /// alla terza ripetizione, cioe' sulla soglia di 3 s.
    private func threeValueTimes(_ count: Int) -> [UInt64] {
        var times: [UInt64] = []
        var value = base
        for index in 0..<count {
            if index % 3 == 1 {
                value -= 2 * ms
            } else {
                value += ms
            }
            times.append(value)
        }
        return times
    }

    /// Arrivi regolari, ogni secondo; le ripetizioni in `lost` non arrivano mai.
    private func arrivals(losing lost: Set<Int>) -> [UInt64] {
        var arrivals: [UInt64] = []
        for n in 0..<32 {
            let nominal: UInt64 = UInt64(n) * second
            arrivals.append(lost.contains(n) ? UInt64.max : nominal + 240 * ms)
        }
        return arrivals
    }

    /// Una ripetizione persa: la successiva porta un'ora nuova, due secondi fra due colpi.
    func testOneLostRepetitionNeverLosesTheDirectorInProduction() {
        let outcome = simulate(times: productionTimes(32), arrivals: arrivals(losing: [6]),
                               sampleTimes: grid(period: listen, offset: 0, duration: 30 * second))
        XCTAssertEqual(outcome.losses, 0)
        XCTAssertEqual(outcome.maxGap, 2 * second)
    }

    /// Due ripetizioni perse di fila: la terza arriva sulla soglia e porta un'ora che non e'
    /// quella di prima. E' un colpo, e il Direttore non si perde.
    func testTwoLostRepetitionsInARowAreStillHeardWhenTheThirdArrivesInProduction() {
        let outcome = simulate(times: productionTimes(32), arrivals: arrivals(losing: [6, 7]),
                               sampleTimes: grid(period: listen, offset: 0, duration: 30 * second))
        XCTAssertEqual(outcome.losses, 0)
        XCTAssertEqual(outcome.maxGap, 3 * second)
        XCTAssertTrue(outcome.heardAtTheEnd)
    }

    /// Lo stesso caso con tre valori: la terza ripetizione riporta l'ora di tre giri prima, non
    /// conta, ed esce «non sento» con il Direttore che e' tornato. Per questo sono quattro.
    func testWithThreeValuesTwoLostRepetitionsInARowWouldLoseTheDirector() {
        let outcome = simulate(times: threeValueTimes(32), arrivals: arrivals(losing: [6, 7]),
                               sampleTimes: grid(period: listen, offset: 0, duration: 30 * second))
        XCTAssertEqual(outcome.losses, 1)
        XCTAssertEqual(outcome.firstLossAt, 8 * second + listen)
        XCTAssertEqual(outcome.maxGap, 4 * second)
    }

    /// Tre ripetizioni perse di fila sono piu' di tre secondi di silenzio: e' una perdita vera,
    /// e «non sento» esce alla soglia, come deve.
    func testThreeLostRepetitionsInARowAreATrueLoss() {
        let outcome = simulate(times: productionTimes(32), arrivals: arrivals(losing: [6, 7, 8]),
                               sampleTimes: grid(period: listen, offset: 0, duration: 30 * second))
        XCTAssertEqual(outcome.losses, 1)
        XCTAssertEqual(outcome.firstLossAt, 8 * second + listen)
        XCTAssertTrue(outcome.heardAtTheEnd)
    }

    // MARK: - 4. Tutte le fasi fra i due battiti, con lo scarto dei timer

    private struct Sweep {
        var phasesWithALoss: [Int] = []
        var worstRun = 0
        var worstGap: UInt64 = 0
    }

    /// Duecento fasi (ogni 5 ms di un secondo), due minuti l'una. Scarti pseudo-casuali: 0…50 ms
    /// sul timer del Direttore, 0…30 ms sulla rete, 0…50 ms sul timer del Follower.
    private func sweep(period: UInt64, production: Bool) -> Sweep {
        var result = Sweep()
        let duration: UInt64 = 120 * second
        let repetitions = Int(duration / second) + 2
        let sampleCount = Int(duration / period) + 2
        let times = production ? productionTimes(repetitions) : twoValueTimes(repetitions)
        for phase in stride(from: 0, to: 1000, by: 5) {
            var generator = Lcg(state: 1_000_003 + UInt64(phase))
            var directorJitter: [UInt64] = []
            for _ in 0..<repetitions { directorJitter.append(generator.below(50 * ms)) }
            var networkJitter: [UInt64] = []
            for _ in 0..<repetitions { networkJitter.append(generator.below(30 * ms)) }
            var followerJitter: [UInt64] = []
            for _ in 0..<sampleCount { followerJitter.append(generator.below(leeway)) }
            var arrivals: [UInt64] = []
            for n in 0..<repetitions {
                let nominal: UInt64 = UInt64(n) * second + UInt64(phase) * ms
                let jitter: UInt64 = directorJitter[n] + networkJitter[n]
                let network: UInt64 = 5 * ms
                arrivals.append(nominal + jitter + network)
            }
            var sampleTimes: [UInt64] = []
            for k in 0..<sampleCount {
                let now = UInt64(k) * period + followerJitter[k]
                if now > duration { break }
                sampleTimes.append(now)
            }
            let outcome = simulate(times: times, arrivals: arrivals, sampleTimes: sampleTimes)
            if outcome.losses > 0 { result.phasesWithALoss.append(phase) }
            if outcome.maxRun > result.worstRun { result.worstRun = outcome.maxRun }
            if outcome.maxGap > result.worstGap { result.worstGap = outcome.maxGap }
        }
        return result
    }

    /// IL DIFETTO dipende dalla fase: con l'ascolto a 1 s e due valori il falso «non sento»
    /// esce solo dove i due battiti sono quasi in fase (la ripetizione arriva a ridosso della
    /// lettura), e li' esce davvero.
    func testPhaseSweepWithOneSecondListeningAndTwoValuesLosesTheDirectorOnlyNearCoincidence() {
        let result = sweep(period: second, production: false)
        XCTAssertGreaterThan(result.phasesWithALoss.count, 0)
        for phase in result.phasesWithALoss {
            XCTAssertTrue(phase <= 100 || phase >= 900, "fase:\(phase) ms")
        }
    }

    /// LA CORREZIONE non dipende dalla fase: in nessuna delle duecento fasi esce un «non
    /// sento»; mai piu' di cinque letture di fila senza colpo (la soglia sono dodici), mai piu'
    /// di un secondo e mezzo fra due colpi.
    func testPhaseSweepInProductionNeverLosesTheDirectorInAnyPhase() {
        let result = sweep(period: listen, production: true)
        XCTAssertEqual(result.phasesWithALoss, [])
        XCTAssertLessThanOrEqual(result.worstRun, 5)
        XCTAssertLessThan(result.worstGap, second + second / 2)
    }

    // MARK: - 5. La perdita vera: il Direttore smette

    /// Il Direttore ripete undici volte e poi tace. Per ogni fase: i tick fra l'ultimo arrivo e
    /// «non sento».
    private func trueLossDelays(period: UInt64, production: Bool) -> [UInt64?] {
        var delays: [UInt64?] = []
        let duration: UInt64 = 20 * second
        let repetitions = Int(duration / second) + 2
        let sampleCount = Int(duration / period) + 2
        let times = production ? productionTimes(repetitions) : twoValueTimes(repetitions)
        for phase in stride(from: 0, to: 1000, by: 5) {
            var generator = Lcg(state: 7_000_021 + UInt64(phase))
            var directorJitter: [UInt64] = []
            for _ in 0..<repetitions { directorJitter.append(generator.below(50 * ms)) }
            var followerJitter: [UInt64] = []
            for _ in 0..<sampleCount { followerJitter.append(generator.below(leeway)) }
            var arrivals: [UInt64] = []
            for n in 0...10 {
                let nominal: UInt64 = UInt64(n) * second + UInt64(phase) * ms
                let network: UInt64 = 5 * ms
                arrivals.append(nominal + directorJitter[n] + network)
            }
            var sampleTimes: [UInt64] = []
            for k in 0..<sampleCount {
                let now = UInt64(k) * period + followerJitter[k]
                if now > duration { break }
                sampleTimes.append(now)
            }
            let lastArrival = arrivals[10]
            let outcome = simulate(times: times, arrivals: arrivals, sampleTimes: sampleTimes, after: lastArrival)
            delays.append(outcome.firstLossAfter.map { $0 - lastArrival })
        }
        return delays
    }

    /// La soglia non cambia e la perdita vera si vede prima: «non sento» esce fra la soglia e la
    /// soglia piu' due passi d'ascolto (3,0–3,6 s dall'ultimo arrivo), in ogni fase.
    func testATrueLossIsNoticedBetweenTheThresholdAndTwoListeningStepsLater() {
        let delays = trueLossDelays(period: listen, production: true)
        XCTAssertEqual(delays.count, 200)
        for delay in delays {
            guard let delay else {
                XCTFail("la perdita vera non e' stata vista")
                continue
            }
            XCTAssertGreaterThanOrEqual(delay, threshold)
            XCTAssertLessThanOrEqual(delay, threshold + 2 * (listen + leeway))
        }
    }

    /// Il tempo per accorgersi di una perdita vera non peggiora rispetto all'ascolto a 1 s: ne'
    /// il caso peggiore ne' la somma su tutte le fasi.
    func testATrueLossIsNotNoticedLaterThanWithOneSecondListening() {
        let production = trueLossDelays(period: listen, production: true).compactMap { $0 }
        let before = trueLossDelays(period: second, production: false).compactMap { $0 }
        XCTAssertEqual(production.count, 200)
        XCTAssertEqual(before.count, 200)
        XCTAssertLessThan(production.max() ?? 0, before.max() ?? 0)
        XCTAssertLessThan(production.reduce(0, +), before.reduce(0, +))
    }
}
