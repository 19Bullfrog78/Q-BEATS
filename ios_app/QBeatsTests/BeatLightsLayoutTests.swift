import XCTest

// === A397 · SOLO-G1-PEZZO-1-M2 — banco delle spie del battito (banco Models) ===
// La tavola del punto 106 riga per riga; la fila mai più larga di 354 per ogni numero di battiti da 1 a 16 (D6);
// le larghezze che il verificatore della REV18 ha misurato (7 → 354, 9 → 352, 11 → 346, 12 → 354); 2 verde, 1 e
// 0 bianco; le forme minime per 1, 8, 10 e oltre 12.

final class BeatLightsLayoutTests: XCTestCase {

    // (battiti, Ø, spazio) — tavola a) della sezione C della REV18
    private let table: [(Int, Double, Double)] = [
        (2, 46, 22), (3, 46, 22), (4, 46, 22),
        (5, 46, 12), (6, 46, 12),
        (7, 42, 10),
        (9, 32, 8),
        (11, 26, 6),
        (12, 24, 6),
    ]

    func testTheTableRowByRow() {
        XCTAssertEqual(table.count, 9)
        for (n, d, g) in table {
            let l = BeatLightsLayout(beats: n)
            XCTAssertEqual(l.beats, n)
            XCTAssertEqual(l.diameter, d, accuracy: 0.0001, "battiti \(n)")
            XCTAssertEqual(l.gap, g, accuracy: 0.0001, "battiti \(n)")
        }
    }

    func testTheRowIsNeverWiderThanTheBarMeter() {
        for n in 1...16 {
            let l = BeatLightsLayout(beats: n)
            XCTAssertLessThanOrEqual(l.rowWidth, BeatLightsLayout.rowWidth + 0.0001, "battiti \(n): \(l.rowWidth)")
            XCTAssertGreaterThan(l.diameter, 0, "battiti \(n)")
            XCTAssertGreaterThanOrEqual(l.gap, 0, "battiti \(n)")
        }
    }

    func testTheWidthsTheSheetVerifierMeasured() {
        XCTAssertEqual(BeatLightsLayout(beats: 7).rowWidth, 354, accuracy: 0.0001)
        XCTAssertEqual(BeatLightsLayout(beats: 9).rowWidth, 352, accuracy: 0.0001)
        XCTAssertEqual(BeatLightsLayout(beats: 11).rowWidth, 346, accuracy: 0.0001)
        XCTAssertEqual(BeatLightsLayout(beats: 12).rowWidth, 354, accuracy: 0.0001)
        XCTAssertEqual(BeatLightsLayout(beats: 4).rowWidth, 4 * 46 + 3 * 22, accuracy: 0.0001)
        XCTAssertEqual(BeatLightsLayout(beats: 6).rowWidth, 6 * 46 + 5 * 12, accuracy: 0.0001)
    }

    func testTheFaces() {
        XCTAssertEqual(BeatLightsLayout.face(patternValue: 2), .accent)
        XCTAssertEqual(BeatLightsLayout.face(patternValue: 1), .beat)
        XCTAssertEqual(BeatLightsLayout.face(patternValue: 0), .beat)
        XCTAssertEqual(BeatLightsLayout.face(patternValue: 3), .beat, "un valore fuori dal contratto non è un accento")
    }

    func testTheMinimalFormsTheSheetDoesNotDraw() {
        // 1 battito: una spia Ø 46.
        let one = BeatLightsLayout(beats: 1)
        XCTAssertEqual(one.beats, 1)
        XCTAssertEqual(one.diameter, 46, accuracy: 0.0001)
        XCTAssertEqual(one.rowWidth, 46, accuracy: 0.0001)
        // 8 e 10: la misura del primo numero disegnato più grande.
        let eight = BeatLightsLayout(beats: 8)
        XCTAssertEqual(eight.diameter, 32, accuracy: 0.0001)
        XCTAssertEqual(eight.gap, 8, accuracy: 0.0001)
        let ten = BeatLightsLayout(beats: 10)
        XCTAssertEqual(ten.diameter, 26, accuracy: 0.0001)
        XCTAssertEqual(ten.gap, 6, accuracy: 0.0001)
        // Oltre 12: spazio 6 e la spia che ci sta, mai oltre 24; la fila resta 354.
        let sixteen = BeatLightsLayout(beats: 16)
        XCTAssertEqual(sixteen.gap, 6, accuracy: 0.0001)
        XCTAssertEqual(sixteen.diameter, 16.5, accuracy: 0.0001)
        XCTAssertEqual(sixteen.rowWidth, 354, accuracy: 0.0001)
        let thirteen = BeatLightsLayout(beats: 13)
        XCTAssertLessThanOrEqual(thirteen.diameter, 24)
        XCTAssertEqual(thirteen.rowWidth, 354, accuracy: 0.0001)
        // Molto oltre: spazio e spia alla pari, mai negativi, mai oltre 354.
        let many = BeatLightsLayout(beats: 100)
        XCTAssertGreaterThan(many.diameter, 0)
        XCTAssertLessThanOrEqual(many.rowWidth, 354 + 0.0001)
        // Zero o negativo: come un battito.
        XCTAssertEqual(BeatLightsLayout(beats: 0).beats, 1)
        XCTAssertEqual(BeatLightsLayout(beats: -3).beats, 1)
    }
}
