import XCTest

// === A386 · FASE B2c — banco della linea del tempo propria (banco Models) ===
// 24.000.000 tick al secondo (misura A382 §3.6 su questa famiglia di apparecchi: e' una misura,
// il tipo riceve i tick al secondo dal chiamante). Buffer di 512 campioni a 48 kHz.

final class OwnClockTimelineTests: XCTestCase {

    private let tps = 24_000_000.0
    private let second: UInt64 = 24_000_000
    /// Un buffer di 512 campioni a 48 kHz, in tick: 256.000.
    private let buffer: UInt64 = 256_000

    func testAtTheAnchorTheBeatIsTheAnchorBeat() {
        let line = OwnClockTimeline(anchorTicks: 100 * second, anchorBeat: 5365.955, bpm: 121.0)
        XCTAssertEqual(line.beat(atTicks: 100 * second, ticksPerSecond: tps), 5365.955, accuracy: 1e-9)
    }

    func testOneSecondAt120IsTwoBeats() {
        let line = OwnClockTimeline(anchorTicks: 10 * second, anchorBeat: 8.0, bpm: 120.0)
        XCTAssertEqual(line.beat(atTicks: 11 * second, ticksPerSecond: tps), 10.0, accuracy: 1e-9)
    }

    /// Il tempo della linea e' quello della propria canzone: a 121 un minuto sono 121 battiti,
    /// qualunque cosa dica la sessione.
    func testOneMinuteAt121Is121Beats() {
        let line = OwnClockTimeline(anchorTicks: 0, anchorBeat: 0.0, bpm: 121.0)
        XCTAssertEqual(line.beat(atTicks: 60 * second, ticksPerSecond: tps), 121.0, accuracy: 1e-6)
    }

    func testOneBufferAt121() {
        let line = OwnClockTimeline(anchorTicks: 5 * second, anchorBeat: 40.0, bpm: 121.0)
        // 512 / 48000 s × 121 / 60 battiti
        let expected = 40.0 + 512.0 / 48_000.0 * 121.0 / 60.0
        XCTAssertEqual(line.beat(atTicks: 5 * second + buffer, ticksPerSecond: tps), expected, accuracy: 1e-9)
    }

    func testATimeBeforeTheAnchorGivesAnEarlierBeat() {
        let line = OwnClockTimeline(anchorTicks: 10 * second, anchorBeat: 8.0, bpm: 120.0)
        XCTAssertEqual(line.beat(atTicks: 9 * second, ticksPerSecond: tps), 6.0, accuracy: 1e-9)
    }

    /// La linea e' fatta di ore: dopo trenta secondi di motore fermo (una telefonata) la griglia
    /// e' dove sarebbe se il click non si fosse mai interrotto.
    func testTheLineGoesThroughAnInterruption() {
        let line = OwnClockTimeline(anchorTicks: 100 * second, anchorBeat: 16.0, bpm: 120.0)
        XCTAssertEqual(line.beat(atTicks: 130 * second, ticksPerSecond: tps), 76.0, accuracy: 1e-9)
    }

    func testInvalidTicksPerSecondOrTempoGiveTheAnchorBeat() {
        let line = OwnClockTimeline(anchorTicks: 10 * second, anchorBeat: 8.0, bpm: 120.0)
        XCTAssertEqual(line.beat(atTicks: 11 * second, ticksPerSecond: 0), 8.0)
        XCTAssertEqual(line.beat(atTicks: 11 * second, ticksPerSecond: .nan), 8.0)
        XCTAssertEqual(line.beat(atTicks: 11 * second, ticksPerSecond: .infinity), 8.0)
        let noTempo = OwnClockTimeline(anchorTicks: 10 * second, anchorBeat: 8.0, bpm: 0.0)
        XCTAssertEqual(noTempo.beat(atTicks: 11 * second, ticksPerSecond: tps), 8.0)
        let nanTempo = OwnClockTimeline(anchorTicks: 10 * second, anchorBeat: 8.0, bpm: .nan)
        XCTAssertEqual(nanTempo.beat(atTicks: 11 * second, ticksPerSecond: tps), 8.0)
    }

    // MARK: - Il ritardo del motore sulla linea

    /// A regime: cento buffer, ognuno consegnato in orario. La posizione del motore, che avanza
    /// di un buffer per volta, coincide con la linea: nessun ritardo.
    func testOnTimeBuffersHaveNoLag() {
        let line = OwnClockTimeline(anchorTicks: 50 * second, anchorBeat: 200.0, bpm: 121.0)
        let beatsPerBuffer = 512.0 / 48_000.0 * 121.0 / 60.0
        let ownBeat = line.beat(atTicks: 50 * second + 100 * buffer, ticksPerSecond: tps)
        let localBeat = 200.0 + 100.0 * beatsPerBuffer
        XCTAssertEqual(OwnClockTimeline.lagMilliseconds(ownBeat: ownBeat, localBeat: localBeat, bpm: 121.0),
                       0.0, accuracy: 1e-6)
    }

    /// Il caso del collaudo: i buffer restano indietro di 124 ms sul tempo reale (il gradino piu'
    /// grande del log del difetto). La linea dice dove dovrebbe essere il click: 124 ms piu' avanti.
    func testAStallOf124MillisecondsIsALagOf124Milliseconds() {
        let line = OwnClockTimeline(anchorTicks: 50 * second, anchorBeat: 200.0, bpm: 121.0)
        let beatsPerBuffer = 512.0 / 48_000.0 * 121.0 / 60.0
        let stall: UInt64 = 2_976_000        // 124 ms in tick
        let ownBeat = line.beat(atTicks: 50 * second + 100 * buffer + stall, ticksPerSecond: tps)
        let localBeat = 200.0 + 100.0 * beatsPerBuffer
        XCTAssertEqual(OwnClockTimeline.lagMilliseconds(ownBeat: ownBeat, localBeat: localBeat, bpm: 121.0),
                       124.0, accuracy: 1e-6)
    }

    func testLagIsNegativeWhenTheEngineIsAhead() {
        XCTAssertEqual(OwnClockTimeline.lagMilliseconds(ownBeat: 10.0, localBeat: 10.5, bpm: 120.0),
                       -250.0, accuracy: 1e-9)
    }

    func testLagWithAnInvalidTempoIsZero() {
        XCTAssertEqual(OwnClockTimeline.lagMilliseconds(ownBeat: 10.0, localBeat: 9.0, bpm: 0.0), 0.0)
        XCTAssertEqual(OwnClockTimeline.lagMilliseconds(ownBeat: 10.0, localBeat: 9.0, bpm: .nan), 0.0)
    }

    /// Il difetto, in numeri: la linea propria a 121 e una linea a 141 partite dallo stesso punto
    /// si separano di venti battiti al minuto. Il click di DA SOLO sta sulla prima.
    func testTheOwnLineDoesNotFollowADifferentTempo() {
        let own = OwnClockTimeline(anchorTicks: 0, anchorBeat: 73.0, bpm: 121.0)
        let session = OwnClockTimeline(anchorTicks: 0, anchorBeat: 73.0, bpm: 141.0)
        let after = 16 * second
        XCTAssertEqual(own.beat(atTicks: after, ticksPerSecond: tps), 73.0 + 121.0 * 16.0 / 60.0, accuracy: 1e-9)
        XCTAssertEqual(session.beat(atTicks: after, ticksPerSecond: tps) - own.beat(atTicks: after, ticksPerSecond: tps),
                       20.0 * 16.0 / 60.0, accuracy: 1e-9)
    }
}
