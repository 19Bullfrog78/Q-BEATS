import XCTest

// === A386 · FASE B1 — banco della ripetizione del Direttore (banco Models) ===
// In moto `{vero, T ± 1 ms}`, da fermo `{falso, Tstop ± 1 ms}` (Tstop e' l'ora dello stop letta
// da Link, non «adesso»), segno alternato solo quando si ripete; i quattro salti (non
// Direttore, Link dell'utente spento, Start Stop Sync spento, ponte spento). Il millisecondo e'
// 24.000 tick (misura A382 §3.6): qui e' un numero passato, non una costante del tipo.
// B2b (A2): il quinto salto, show chiuso — il Direttore ripete solo a show aperto.
// ⚠️ B2d: il segno alternato qui sopra non c'e' piu'. La ripetizione gira su TRE valori —
//    +1 ms, −2 ms, +1 ms sull'ora catturata: T+1, T−1, T — e avanza solo quando si ripete; dopo
//    un Play o uno Stop veri riparte dal primo passo. I test del segno sono diventati i test
//    del giro; quelli dei salti e dello show chiuso sono gli stessi, col giro al posto del segno.

final class DirectorReannounceDecisionTests: XCTestCase {

    private typealias D = DirectorReannounceDecision
    private typealias Cycle = DirectorReannounceDecision.Cycle
    private let ms: UInt64 = 24_000

    private func decide(role: LinkMode = .direttore, user: Bool = true, sss: Bool = true,
                        link: Bool = true, showOpen: Bool = true, playing: Bool, captured: UInt64,
                        cycle: Cycle) -> D {
        D(role: role, userLinkEnabled: user, startStopSyncEnabled: sss, linkEnabled: link,
          showOpen: showOpen, sessionPlaying: playing, capturedTime: captured, shiftTicks: ms, cycle: cycle)
    }

    /// `count` ripetizioni di fila, ognuna sull'ora scritta dalla precedente (la cattura
    /// restituisce cio' che e' stato scritto): le ore scritte, e il giro alla fine.
    private func chain(from start: UInt64, cycle: Cycle, playing: Bool, count: Int) -> (times: [UInt64], cycle: Cycle) {
        var times: [UInt64] = []
        var captured = start
        var current = cycle
        for _ in 0..<count {
            let d = decide(playing: playing, captured: captured, cycle: current)
            guard case .reannounce(_, let at) = d.outcome else {
                XCTFail("attesa una ripetizione")
                return (times, current)
            }
            times.append(at)
            captured = at
            current = d.nextCycle
        }
        return (times, current)
    }

    // MARK: - Il primo passo: come prima di B2d, +1 ms sull'ora catturata

    func testRunningReannouncesPlayingAtCapturedPlusOneMillisecond() {
        let d = decide(playing: true, captured: 1_000_000, cycle: .start)
        XCTAssertEqual(d.outcome, .reannounce(isPlaying: true, at: 1_024_000))
        XCTAssertEqual(d.shift, 24_000)
        XCTAssertEqual(d.step, 0)
        XCTAssertEqual(d.nextCycle, Cycle(step: 1, lastPlaying: true))
    }

    func testStoppedReannouncesStoppedAtStopTimeNotNow() {
        let d = decide(playing: false, captured: 5_000_000, cycle: .start)
        XCTAssertEqual(d.outcome, .reannounce(isPlaying: false, at: 5_024_000))
        XCTAssertEqual(d.nextCycle, Cycle(step: 1, lastPlaying: false))
    }

    // MARK: - B2d: il giro a tre valori

    func testTheThreeShiftsArePlusOneMinusTwoPlusOne() {
        XCTAssertEqual(D.signedShift(step: 0, shiftTicks: ms), 24_000)
        XCTAssertEqual(D.signedShift(step: 1, shiftTicks: ms), -48_000)
        XCTAssertEqual(D.signedShift(step: 2, shiftTicks: ms), 24_000)
        // fuori dal giro vale il passo modulo tre
        XCTAssertEqual(D.signedShift(step: 3, shiftTicks: ms), 24_000)
        XCTAssertEqual(D.signedShift(step: 4, shiftTicks: ms), -48_000)
        XCTAssertEqual(D.signedShift(step: -1, shiftTicks: ms), 24_000)
        XCTAssertEqual(Cycle.length, 3)
    }

    func testTheSecondStepSubtractsTwoMilliseconds() {
        let d = decide(playing: true, captured: 1_024_000, cycle: Cycle(step: 1, lastPlaying: true))
        XCTAssertEqual(d.outcome, .reannounce(isPlaying: true, at: 976_000))
        XCTAssertEqual(d.shift, -48_000)
        XCTAssertEqual(d.step, 1)
        XCTAssertEqual(d.nextCycle, Cycle(step: 2, lastPlaying: true))
    }

    func testTheTimeGoesRoundThreeValuesAndDoesNotDrift() {
        // se la cattura restituisce cio' che e' stato scritto: T+1 ms, T−1 ms, T, e da capo.
        let start: UInt64 = 9_000_000
        let result = chain(from: start, cycle: .start, playing: true, count: 7)
        XCTAssertEqual(result.times, [start + ms, start - ms, start,
                                      start + ms, start - ms, start,
                                      start + ms])
        XCTAssertEqual(result.cycle, Cycle(step: 1, lastPlaying: true))
    }

    /// La ragione del giro: fra due ripetizioni distanti una o due posizioni l'ora e' sempre
    /// diversa. Un Follower che fra due letture riceve due ripetizioni (o ne perde una) legge
    /// comunque un valore nuovo. Con due valori alternati, a distanza due l'ora era la stessa.
    func testTheTimeNeverComesBackWithinTwoRepetitions() {
        let result = chain(from: 9_000_000, cycle: .start, playing: false, count: 30)
        var previous: UInt64 = 9_000_000
        var beforePrevious: UInt64? = nil
        for time in result.times {
            XCTAssertNotEqual(time, previous)
            if let earlier = beforePrevious {
                XCTAssertNotEqual(time, earlier)
            }
            beforePrevious = previous
            previous = time
        }
        XCTAssertEqual(Set(result.times).count, 3)
    }

    /// L'errore sull'ora dopo un Play vero: entro 1 ms, come prima di B2d. Il giro riparte dal
    /// primo passo qualunque fosse la sua posizione da fermo.
    func testAfterARealPlayTheCycleRestartsAndStaysWithinOneMillisecond() {
        let stopTime: UInt64 = 5_000_000
        let playTime: UInt64 = 80_000_000
        for stoppedRepetitions in 1...6 {
            let stopped = chain(from: stopTime, cycle: .start, playing: false, count: stoppedRepetitions)
            // Play vero: Link porta l'ora nuova; «suona» e' cambiato rispetto all'ultima ripetizione.
            let playing = chain(from: playTime, cycle: stopped.cycle, playing: true, count: 9)
            XCTAssertEqual(Array(playing.times.prefix(3)), [playTime + ms, playTime - ms, playTime])
            for time in playing.times {
                let error = time >= playTime ? time - playTime : playTime - time
                XCTAssertLessThanOrEqual(error, ms)
            }
        }
    }

    func testAfterARealStopTheCycleRestartsToo() {
        let playing = chain(from: 80_000_000, cycle: .start, playing: true, count: 2)
        XCTAssertEqual(playing.cycle, Cycle(step: 2, lastPlaying: true))
        let d = decide(playing: false, captured: 200_000_000, cycle: playing.cycle)
        XCTAssertEqual(d.outcome, .reannounce(isPlaying: false, at: 200_024_000))
        XCTAssertEqual(d.step, 0)
        XCTAssertEqual(d.nextCycle, Cycle(step: 1, lastPlaying: false))
    }

    /// La misura dell'errore nel caso che il giro non puo' vedere: l'ora catturata cambia senza
    /// che cambi «suona» (due cambi di trasporto dentro lo stesso secondo, o Link che rimappa
    /// l'ora). Il giro continua dal passo dov'era: mai oltre 2 ms dall'ora nuova.
    func testAnUnseenChangeOfTheCapturedTimeStaysWithinTwoMilliseconds() {
        let newTime: UInt64 = 300_000_000
        var worst: UInt64 = 0
        for position in 0..<3 {
            let result = chain(from: newTime, cycle: Cycle(step: position, lastPlaying: true),
                             playing: true, count: 12)
            for time in result.times {
                let error = time >= newTime ? time - newTime : newTime - time
                if error > worst { worst = error }
            }
        }
        XCTAssertEqual(worst, 2 * ms)
    }

    func testTheSecondStepNeverGoesBelowZero() {
        let d = decide(playing: false, captured: 10, cycle: Cycle(step: 1, lastPlaying: false))
        XCTAssertEqual(d.outcome, .reannounce(isPlaying: false, at: 0))
        XCTAssertEqual(d.shift, -48_000)
    }

    // MARK: - I salti: il giro non avanza

    func testSkipsDoNotAdvanceTheCycle() {
        let cycle = Cycle(step: 2, lastPlaying: true)

        let notDirector = decide(role: .collaborativa, playing: true, captured: 1, cycle: cycle)
        XCTAssertEqual(notDirector.outcome, .skip(.notDirector))
        XCTAssertEqual(notDirector.nextCycle, cycle)
        XCTAssertEqual(notDirector.shift, 0)
        XCTAssertNil(notDirector.step)

        let solo = decide(role: .standalone, playing: true, captured: 1, cycle: cycle)
        XCTAssertEqual(solo.outcome, .skip(.notDirector))
        XCTAssertEqual(solo.nextCycle, cycle)

        let userOff = decide(user: false, playing: true, captured: 1, cycle: cycle)
        XCTAssertEqual(userOff.outcome, .skip(.userLinkOff))
        XCTAssertEqual(userOff.nextCycle, cycle)

        let sssOff = decide(sss: false, playing: true, captured: 1, cycle: cycle)
        XCTAssertEqual(sssOff.outcome, .skip(.startStopSyncOff))
        XCTAssertEqual(sssOff.nextCycle, cycle)

        let linkOff = decide(link: false, playing: true, captured: 1, cycle: cycle)
        XCTAssertEqual(linkOff.outcome, .skip(.linkUnavailable))
        XCTAssertEqual(linkOff.nextCycle, cycle)

        let showClosed = decide(showOpen: false, playing: true, captured: 1, cycle: cycle)
        XCTAssertEqual(showClosed.outcome, .skip(.showClosed))
        XCTAssertEqual(showClosed.nextCycle, cycle)
    }

    func testSkipOrderNotDirectorBeforeTheOthers() {
        let d = decide(role: .collaborativa, user: false, sss: false, link: false, showOpen: false,
                       playing: true, captured: 1, cycle: .start)
        XCTAssertEqual(d.outcome, .skip(.notDirector))
    }

    // MARK: - B2b (A2): il Direttore ripete solo a show aperto

    func testShowClosedSkipsInMotionAndStopped() {
        XCTAssertEqual(decide(showOpen: false, playing: true, captured: 1_000_000, cycle: .start).outcome,
                       .skip(.showClosed))
        XCTAssertEqual(decide(showOpen: false, playing: false, captured: 1_000_000, cycle: .start).outcome,
                       .skip(.showClosed))
    }

    func testShowClosedComesAfterTheConfigurationSkips() {
        // Una configurazione sbagliata si legge prima di uno show chiuso, che e' il caso normale.
        XCTAssertEqual(decide(user: false, showOpen: false, playing: true, captured: 1, cycle: .start).outcome,
                       .skip(.userLinkOff))
        XCTAssertEqual(decide(sss: false, showOpen: false, playing: true, captured: 1, cycle: .start).outcome,
                       .skip(.startStopSyncOff))
        XCTAssertEqual(decide(link: false, showOpen: false, playing: true, captured: 1, cycle: .start).outcome,
                       .skip(.linkUnavailable))
    }

    func testShowOpenAgainReannouncesFromTheCapturedTime() {
        let closed = decide(showOpen: false, playing: false, captured: 7_000_000, cycle: .start)
        XCTAssertEqual(closed.outcome, .skip(.showClosed))
        let open = decide(showOpen: true, playing: false, captured: 7_000_000, cycle: closed.nextCycle)
        XCTAssertEqual(open.outcome, .reannounce(isPlaying: false, at: 7_024_000))
        XCTAssertEqual(open.nextCycle, Cycle(step: 1, lastPlaying: false))
    }

    /// Uno show chiuso a meta' giro e riaperto: il giro riprende dal passo dov'era, sull'ora
    /// che la cattura restituisce (l'ultima scritta), e torna sui tre valori di prima.
    func testAShowClosedMidCycleResumesOnTheSameThreeValues() {
        let start: UInt64 = 7_000_000
        let before = chain(from: start, cycle: .start, playing: false, count: 1)
        XCTAssertEqual(before.times, [start + ms])
        let closed = decide(showOpen: false, playing: false, captured: start + ms, cycle: before.cycle)
        XCTAssertEqual(closed.nextCycle, before.cycle)
        let after = chain(from: start + ms, cycle: closed.nextCycle, playing: false, count: 3)
        XCTAssertEqual(after.times, [start - ms, start, start + ms])
    }
}
