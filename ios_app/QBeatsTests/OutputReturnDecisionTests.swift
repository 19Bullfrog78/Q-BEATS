import XCTest

// === A421 — banco dei ritorni dopo il silenzio e della rete del motore fermo (`OutputReturnDecision`, banco Models), mandato
// par. 2.2 a-d e g, par. 2.1 U3 c e U6 ===
// Un orologio finto a 24 MHz. Le due ore del Follower coi tempi veri del 24/10 (il render ripartito 681 e 684 ms dopo la
// notizia) e con la premessa del referto A419 (30-36 ms); il primo «uno» di Link e quello della linea propria; l'ora in
// cui rimettere il volume per il buffer dell'«uno» (U3 c); le attese del Direttore; la riga della rete.

final class OutputReturnDecisionTests: XCTestCase {

    private let tps = 24_000_000.0
    private let buffer = 512.0 / 48_000.0
    private let latency = 0.0233

    private func t(_ seconds: Double) -> UInt64 {
        UInt64((seconds * tps).rounded())
    }

    private func s(_ ticks: UInt64) -> Double {
        Double(ticks) / tps
    }

    // MARK: - Le costanti

    func testTheConstants() {
        XCTAssertEqual(OutputReturnDecision.directorSettleSeconds, 0.100)
        XCTAssertEqual(OutputReturnDecision.configurationReserveSeconds, 2.0)
        XCTAssertEqual(OutputReturnDecision.followerMinimumSeconds, 0.3)
        XCTAssertEqual(OutputReturnDecision.clickTailSeconds, 0.040)
        XCTAssertEqual(OutputReturnDecision.queuedAheadBuffers, 2)
        XCTAssertEqual(OutputReturnDecision.stoppedEngineNetSeconds, 2.0)
        XCTAssertEqual(OutputReturnDecision.stoppedEngineLineEvery, 10)
        XCTAssertEqual(DirectorReturnWait.settle.rawValue, "assestamento")
        XCTAssertEqual(DirectorReturnWait.configuration.rawValue, "configurazione")
    }

    // MARK: - Il Direttore (U6, par. 2.2 b)

    func testTheDirectorWaitsTheConfigurationOnlyIfTheSessionRateDiffers() {
        XCTAssertEqual(OutputReturnDecision.directorWait(sessionRateDiffersFromCopy: true), .configuration)
        XCTAssertEqual(OutputReturnDecision.directorWait(sessionRateDiffersFromCopy: false), .settle)
        XCTAssertEqual(OutputReturnDecision.directorWaitSeconds(.settle), 0.100)
        XCTAssertEqual(OutputReturnDecision.directorWaitSeconds(.configuration), 2.0)
    }

    // MARK: - Il Follower (par. 2.2 c)

    /// La fine d'uscita del buffer che la chiamata produce: due davanti più il nostro.
    func testTheProgrammedEnd() {
        let next = t(100.0)
        let end = OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: next, queuedAhead: 2, bufferTicks: t(buffer))
        XCTAssertEqual(s(end), 100.0 + 3 * buffer, accuracy: 1e-6)
        XCTAssertEqual(OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: next, queuedAhead: 0, bufferTicks: t(buffer)),
                       next + t(buffer))
        XCTAssertEqual(OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: UInt64.max - 1, queuedAhead: 2,
                                                                     bufferTicks: t(buffer)), UInt64.max)
    }

    /// Le cuffie col filo del 24/10: il render riparte 681 ms dopo la notizia. La seconda ora vince: i buffer già
    /// programmati escono fino a 0,747 s dopo la notizia, più i 40 ms del click.
    func testTheDeadlineWhenTheRenderRestarts681msLater() {
        let notice = 100.0
        let firstCall = notice + 0.681
        let nextOutput = t(firstCall + buffer + latency)
        let end = OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: nextOutput, queuedAhead: 2, bufferTicks: t(buffer))
        let deadline = OutputReturnDecision.followerDeadlineTicks(noticeTicks: t(notice), programmedEndOutputTicks: end, ticksPerSecond: tps)
        let expected = firstCall + buffer + latency + 3 * buffer + 0.040
        XCTAssertEqual(s(deadline), expected, accuracy: 1e-6)
        XCTAssertGreaterThan(s(deadline), notice + 0.3)
    }

    /// La premessa del referto A419: il buco finito 36 ms dopo la notizia. Qui vince l'ora della notizia: 0,3 s.
    func testTheDeadlineWhenTheRenderRestarts36msLater() {
        let notice = 100.0
        let nextOutput = t(notice + 0.036 + buffer + latency)
        let end = OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: nextOutput, queuedAhead: 2, bufferTicks: t(buffer))
        let deadline = OutputReturnDecision.followerDeadlineTicks(noticeTicks: t(notice), programmedEndOutputTicks: end, ticksPerSecond: tps)
        XCTAssertEqual(s(deadline), notice + 0.3, accuracy: 1e-6)
    }

    /// Il tocco «altoparlante»: la sola ora «0,3 s dopo il tocco».
    func testTheTapDeadline() {
        XCTAssertEqual(s(OutputReturnDecision.tapDeadlineTicks(tapTicks: t(50.0), ticksPerSecond: tps)), 50.3, accuracy: 1e-6)
    }

    /// Il primo «uno» di battuta di Link non prima del battito: il multiplo del quantum; un battito su una battuta è quella.
    func testTheNextBarBeat() {
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 10.3, quantum: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 12.0, quantum: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 12.0000001, quantum: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 12.001, quantum: 4), 16)
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 0.5, quantum: 3), 3)
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: -0.5, quantum: 4), 0)
        XCTAssertNil(OutputReturnDecision.nextBarBeat(atOrAfter: 10, quantum: 0))
        XCTAssertNil(OutputReturnDecision.nextBarBeat(atOrAfter: .nan, quantum: 4))
    }

    /// DA-SOLO: l'«uno» a battute dall'ultimo «uno» uscito; mai quello già uscito.
    func testTheNextOwnUno() {
        XCTAssertEqual(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 10.3, lastUnoBeat: 8, beatsPerBar: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 8.0, lastUnoBeat: 8, beatsPerBar: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 12.0, lastUnoBeat: 8, beatsPerBar: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 12.5, lastUnoBeat: 8, beatsPerBar: 4), 16)
        XCTAssertEqual(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 20.9, lastUnoBeat: 8, beatsPerBar: 3), 23)
        XCTAssertNil(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 10, lastUnoBeat: 8, beatsPerBar: 0))
    }

    /// L'ora di un battito sulla linea propria: l'inversa di `OwnClockTimeline.beat(atTicks:)`.
    func testOwnTicksAtBeatInvertsTheTimeline() {
        let timeline = OwnClockTimeline(anchorTicks: t(100.0), anchorBeat: 8, bpm: 120)
        let twelve = OutputReturnDecision.ownTicks(atBeat: 12, timeline: timeline, ticksPerSecond: tps)
        XCTAssertEqual(s(twelve!), 102.0, accuracy: 1e-6)
        XCTAssertEqual(timeline.beat(atTicks: twelve!, ticksPerSecond: tps), 12, accuracy: 1e-9)
        let before = OutputReturnDecision.ownTicks(atBeat: 7, timeline: timeline, ticksPerSecond: tps)
        XCTAssertEqual(s(before!), 99.5, accuracy: 1e-6)
        XCTAssertNil(OutputReturnDecision.ownTicks(atBeat: 12, timeline: OwnClockTimeline(anchorTicks: 0, anchorBeat: 0, bpm: 0),
                                                   ticksPerSecond: tps))
    }

    /// Il buffer che porta l'«uno»: la sua fine d'uscita è oltre l'«uno».
    func testTheBufferThatReachesTheUno() {
        let uno = t(100.5)
        XCTAssertFalse(OutputReturnDecision.bufferReachesUno(bufferOutputTicks: t(100.47), bufferTicks: t(buffer), unoTicks: uno))
        XCTAssertTrue(OutputReturnDecision.bufferReachesUno(bufferOutputTicks: t(100.49), bufferTicks: t(buffer), unoTicks: uno))
        XCTAssertTrue(OutputReturnDecision.bufferReachesUno(bufferOutputTicks: t(100.6), bufferTicks: t(buffer), unoTicks: uno))
        XCTAssertTrue(OutputReturnDecision.bufferReachesUno(bufferOutputTicks: UInt64.max, bufferTicks: 1, unoTicks: uno))
    }

    /// `ticks(_:plusSeconds:)`: avanti, indietro (si ferma a zero), ai bordi.
    func testTicksPlusSeconds() {
        XCTAssertEqual(OutputReturnDecision.ticks(t(100), plusSeconds: 0.5, ticksPerSecond: tps), t(100.5))
        XCTAssertEqual(OutputReturnDecision.ticks(t(100), plusSeconds: -0.5, ticksPerSecond: tps), t(99.5))
        XCTAssertEqual(OutputReturnDecision.ticks(t(1), plusSeconds: -5, ticksPerSecond: tps), 0)
        XCTAssertEqual(OutputReturnDecision.ticks(UInt64.max - 10, plusSeconds: 1, ticksPerSecond: tps), UInt64.max)
        XCTAssertEqual(OutputReturnDecision.ticks(t(100), plusSeconds: 1, ticksPerSecond: 0), t(100))
    }

    // MARK: - La rete del motore fermo (par. 2.2 a)

    func testTheStoppedEngineLineFirstThenEveryTen() {
        let written = (0...35).filter { OutputReturnDecision.writesStoppedEngineLine(callbacks: $0) }
        XCTAssertEqual(written, [1, 11, 21, 31])
    }
}
