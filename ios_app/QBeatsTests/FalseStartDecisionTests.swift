import XCTest

// === A386 · FASE B1 — banco della falsa partenza (banco Models) ===
// D7-bis: Stop entro la prima battuta dal Play -> falsa partenza. Battiti di sessione letterali,
// margini 4, 6 e 7 (una battuta in 4/4, 6/8, 7/8): un attimo prima del bordo dentro, al bordo
// fuori, dopo fuori, stop prima dell'avvio dentro, margine 0 mai dentro. E il conto a giro
// simmetrico (`beatDelta`, modulo 1e6): i casi del mandato di B1-bis §3 c), piu' i bordi.

final class FalseStartDecisionTests: XCTestCase {

    private func inside(stop: Double, start: Double, margin: Double) -> Bool {
        FalseStartDecision.isFalseStart(stopBeat: stop, startBeat: start, marginBeats: margin)
    }

    private let modulus = 1_000_000.0

    // MARK: - isFalseStart

    func testJustBeforeTheEdgeIsInside() {
        XCTAssertTrue(inside(stop: 103.999, start: 100.0, margin: 4.0))
        XCTAssertTrue(inside(stop: 105.999, start: 100.0, margin: 6.0))
        XCTAssertTrue(inside(stop: 106.999, start: 100.0, margin: 7.0))
    }

    func testExactlyAtTheEdgeIsOutside() {
        XCTAssertFalse(inside(stop: 104.0, start: 100.0, margin: 4.0))
        XCTAssertFalse(inside(stop: 106.0, start: 100.0, margin: 6.0))
        XCTAssertFalse(inside(stop: 107.0, start: 100.0, margin: 7.0))
    }

    func testAfterTheEdgeIsOutside() {
        XCTAssertFalse(inside(stop: 104.5, start: 100.0, margin: 4.0))
        XCTAssertFalse(inside(stop: 112.0, start: 100.0, margin: 6.0))
        XCTAssertFalse(inside(stop: 250.0, start: 100.0, margin: 7.0))
    }

    func testAtTheStartIsInside() {
        XCTAssertTrue(inside(stop: 100.0, start: 100.0, margin: 4.0))
        XCTAssertTrue(inside(stop: 100.0, start: 100.0, margin: 7.0))
    }

    func testStopBeforeTheStartIsInside() {
        XCTAssertTrue(inside(stop: 99.5, start: 100.0, margin: 4.0))
        XCTAssertTrue(inside(stop: 0.0, start: 100.0, margin: 6.0))
        XCTAssertTrue(inside(stop: -0.001, start: 0.0, margin: 7.0))
    }

    func testZeroOrNegativeMarginIsNeverInside() {
        for margin in [0.0, -4.0] {
            XCTAssertFalse(inside(stop: 100.0, start: 100.0, margin: margin))
            XCTAssertFalse(inside(stop: 99.5, start: 100.0, margin: margin))
            XCTAssertFalse(inside(stop: 103.999, start: 100.0, margin: margin))
        }
    }

    func testMarginIsOneBarOfTheFirstSection() {
        XCTAssertEqual(FalseStartDecision.marginBeats(beatsPerBar: 4), 4.0)
        XCTAssertEqual(FalseStartDecision.marginBeats(beatsPerBar: 6), 6.0)
        XCTAssertEqual(FalseStartDecision.marginBeats(beatsPerBar: 7), 7.0)
        XCTAssertEqual(FalseStartDecision.marginBeats(beatsPerBar: 0), 0.0)
    }

    // MARK: - beatDelta, il giro simmetrico (mandato B1-bis §3 c)

    func testDeltaAcrossTheZeroForward() {
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 999_999.5, stopPhase: 0.3, modulus: modulus),
                       0.8, accuracy: 1e-9)
    }

    func testDeltaAHairBeforeTheStartIsSmallAndNegativeAndInside() {
        let delta = FalseStartDecision.beatDelta(startPhase: 10.0, stopPhase: 9.999, modulus: modulus)
        XCTAssertEqual(delta, -0.001, accuracy: 1e-9)
        XCTAssertTrue(FalseStartDecision.isFalseStart(stopBeat: delta, startBeat: 0.0, marginBeats: 4.0))
    }

    func testDeltaOfEqualPhasesIsZero() {
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 3.0, stopPhase: 3.0, modulus: modulus), 0.0)
    }

    func testDeltaAcrossTheZeroBackward() {
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 0.5, stopPhase: 999_999.0, modulus: modulus),
                       -1.5, accuracy: 1e-9)
    }

    func testDeltaPlainInsideTheRange() {
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 100.0, stopPhase: 104.0, modulus: modulus), 4.0)
    }

    func testDeltaWithoutModulusIsThePlainDifference() {
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 999_999.5, stopPhase: 0.3, modulus: 0),
                       -999_999.2, accuracy: 1e-9)
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 100.0, stopPhase: 104.0, modulus: -1), 4.0)
    }

    func testDeltaRangeIsOpenOnTheLeftAndClosedOnTheRight() {
        // esattamente meta' giro: +500000 resta, -500000 diventa +500000
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 0.0, stopPhase: 500_000.0, modulus: modulus), 500_000.0)
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 500_000.0, stopPhase: 0.0, modulus: modulus), 500_000.0)
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 0.0, stopPhase: 500_000.5, modulus: modulus),
                       -499_999.5, accuracy: 1e-9)
    }

    func testDeltaBeyondOneTurnIsReduced() {
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 0.0, stopPhase: 2_500_000.0, modulus: modulus), 500_000.0)
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 0.0, stopPhase: 2_000_004.0, modulus: modulus), 4.0)
        XCTAssertEqual(FalseStartDecision.beatDelta(startPhase: 2_000_004.0, stopPhase: 0.0, modulus: modulus), -4.0)
    }

    func testDeltaThenFalseStartAcrossTheZero() {
        // avvio letto a 1e6 − 0.5 (mezzo battito prima dello zero), stop a 3.0: 3.5 battiti dopo
        let delta = FalseStartDecision.beatDelta(startPhase: 999_999.5, stopPhase: 3.0, modulus: modulus)
        XCTAssertEqual(delta, 3.5, accuracy: 1e-9)
        XCTAssertTrue(FalseStartDecision.isFalseStart(stopBeat: delta, startBeat: 0.0, marginBeats: 4.0))
        XCTAssertFalse(FalseStartDecision.isFalseStart(stopBeat: delta + 1.0, startBeat: 0.0, marginBeats: 4.0))
    }
}
