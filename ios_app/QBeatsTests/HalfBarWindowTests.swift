import XCTest

// === A386 · FASE B1 — banco della mezza battuta (banco Models) ===
// Tempi non tondi (121.0 e 141.0 BPM, Costituzione §6), tick a 24.000.000 al secondo (misura
// A382 §3.6), attesi letterali: 4/4 a 121.0 = 0,991735537 s = 23.801.653 tick; 4/4 a 141.0 =
// 0,851063830 s = 20.425.532 tick; 6/8 a 121.0 = 1,487603306 s = 35.702.479 tick. Due lati:
// bordo dentro, bordo + 1 tick fuori, futuro entro/oltre; finestra zero mai dentro.

final class HalfBarWindowTests: XCTestCase {

    private let ticksPerSecond = 24_000_000.0

    func testHalfBarSecondsLiterally() {
        XCTAssertEqual(HalfBarWindow.halfBarSeconds(beatsPerBar: 4, bpm: 121.0), 0.991735537190, accuracy: 1e-9)
        XCTAssertEqual(HalfBarWindow.halfBarSeconds(beatsPerBar: 4, bpm: 141.0), 0.851063829787, accuracy: 1e-9)
        XCTAssertEqual(HalfBarWindow.halfBarSeconds(beatsPerBar: 6, bpm: 121.0), 1.487603305785, accuracy: 1e-9)
        XCTAssertEqual(HalfBarWindow.halfBarSeconds(beatsPerBar: 7, bpm: 141.0), 1.489361702128, accuracy: 1e-9)
    }

    func testHalfBarTicksLiterally() {
        XCTAssertEqual(HalfBarWindow.halfBarTicks(beatsPerBar: 4, bpm: 121.0, ticksPerSecond: ticksPerSecond), 23_801_653)
        XCTAssertEqual(HalfBarWindow.halfBarTicks(beatsPerBar: 4, bpm: 141.0, ticksPerSecond: ticksPerSecond), 20_425_532)
        XCTAssertEqual(HalfBarWindow.halfBarTicks(beatsPerBar: 6, bpm: 121.0, ticksPerSecond: ticksPerSecond), 35_702_479)
    }

    func testDegenerateInputsGiveZero() {
        XCTAssertEqual(HalfBarWindow.halfBarSeconds(beatsPerBar: 0, bpm: 121.0), 0)
        XCTAssertEqual(HalfBarWindow.halfBarSeconds(beatsPerBar: 4, bpm: 0), 0)
        XCTAssertEqual(HalfBarWindow.halfBarSeconds(beatsPerBar: 4, bpm: -121.0), 0)
        XCTAssertEqual(HalfBarWindow.halfBarTicks(beatsPerBar: 4, bpm: 121.0, ticksPerSecond: 0), 0)
        XCTAssertEqual(HalfBarWindow.halfBarTicks(beatsPerBar: 0, bpm: 121.0, ticksPerSecond: ticksPerSecond), 0)
    }

    func testWithinTheWindowOnBothSides() {
        let half: UInt64 = 23_801_653
        let announced: UInt64 = 1_000_000_000
        // passato
        XCTAssertTrue(HalfBarWindow.isWithin(announced: announced, now: announced + 1, halfBarTicks: half))
        XCTAssertTrue(HalfBarWindow.isWithin(announced: announced, now: announced + half, halfBarTicks: half))
        XCTAssertFalse(HalfBarWindow.isWithin(announced: announced, now: announced + half + 1, halfBarTicks: half))
        // futuro
        XCTAssertTrue(HalfBarWindow.isWithin(announced: announced, now: announced - 1, halfBarTicks: half))
        XCTAssertTrue(HalfBarWindow.isWithin(announced: announced, now: announced - half, halfBarTicks: half))
        XCTAssertFalse(HalfBarWindow.isWithin(announced: announced, now: announced - half - 1, halfBarTicks: half))
        // esattamente adesso
        XCTAssertTrue(HalfBarWindow.isWithin(announced: announced, now: announced, halfBarTicks: half))
    }

    func testAPlayAboutOneSecondLateFallsOnTheTwoSidesOfTheWindow() {
        // 1,0 s = 24.000.000 tick: fuori a 141.0 (finestra 20.425.532) e fuori anche a 121.0
        // (23.801.653); 0,99 s = 23.760.000 tick: dentro a 121.0, fuori a 141.0.
        let announced: UInt64 = 5_000_000_000
        let oneSecond: UInt64 = 24_000_000
        let almostOneSecond: UInt64 = 23_760_000   // 0,99 s
        XCTAssertFalse(HalfBarWindow.isWithin(announced: announced, now: announced + oneSecond, halfBarTicks: 20_425_532))
        XCTAssertFalse(HalfBarWindow.isWithin(announced: announced, now: announced + oneSecond, halfBarTicks: 23_801_653))
        XCTAssertTrue(HalfBarWindow.isWithin(announced: announced, now: announced + almostOneSecond, halfBarTicks: 23_801_653))
        XCTAssertFalse(HalfBarWindow.isWithin(announced: announced, now: announced + almostOneSecond, halfBarTicks: 20_425_532))
    }

    func testZeroWindowIsNeverWithin() {
        XCTAssertFalse(HalfBarWindow.isWithin(announced: 10, now: 10, halfBarTicks: 0))
        XCTAssertFalse(HalfBarWindow.isWithin(announced: 10, now: 11, halfBarTicks: 0))
    }
}
