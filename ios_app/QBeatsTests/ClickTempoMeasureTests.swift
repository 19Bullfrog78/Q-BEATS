import XCTest

// === A386 · FASE B2c — banco del tempo misurato sui campioni (banco Models) ===
// I numeri sono quelli del collaudo dell'01/10/2026: 48.000 campioni al secondo, buffer di 512,
// canzone 1 a 121, canzone 2 a 141, canzone 3 a 101 in 6/8.

final class ClickTempoMeasureTests: XCTestCase {

    private let sampleRate = 48_000.0

    func testOneBeatAt120IsHalfASecondOfSamples() {
        XCTAssertEqual(ClickTempoMeasure.bpm(beats: 1, samples: 24_000, sampleRate: sampleRate)!, 120.0, accuracy: 1e-9)
    }

    func testTheTemposOfTheBenchSongs() {
        // campioni per battito = 48.000 × 60 / bpm
        let twoBeatsAt121 = Int64((2.0 * sampleRate * 60.0 / 121.0).rounded())
        XCTAssertEqual(ClickTempoMeasure.bpm(beats: 2, samples: twoBeatsAt121, sampleRate: sampleRate)!, 121.0, accuracy: 0.01)
        let twoBeatsAt141 = Int64((2.0 * sampleRate * 60.0 / 141.0).rounded())
        XCTAssertEqual(ClickTempoMeasure.bpm(beats: 2, samples: twoBeatsAt141, sampleRate: sampleRate)!, 141.0, accuracy: 0.01)
        let twoBeatsAt101 = Int64((2.0 * sampleRate * 60.0 / 101.0).rounded())
        XCTAssertEqual(ClickTempoMeasure.bpm(beats: 2, samples: twoBeatsAt101, sampleRate: sampleRate)!, 101.0, accuracy: 0.01)
    }

    /// Il difetto si legge nella misura: gli stessi due battiti in meno campioni sono un tempo piu' alto.
    func testTheMeasureTellsApart121From141() {
        let at121 = ClickTempoMeasure.bpm(beats: 2, samples: 47_603, sampleRate: sampleRate)!
        let at141 = ClickTempoMeasure.bpm(beats: 2, samples: 40_851, sampleRate: sampleRate)!
        XCTAssertEqual(at121, 121.0, accuracy: 0.01)
        XCTAssertEqual(at141, 141.0, accuracy: 0.01)
        XCTAssertGreaterThan(at141 - at121, 19.9)
    }

    func testNothingToMeasure() {
        XCTAssertNil(ClickTempoMeasure.bpm(beats: 0, samples: 24_000, sampleRate: sampleRate))
        XCTAssertNil(ClickTempoMeasure.bpm(beats: -1, samples: 24_000, sampleRate: sampleRate))
        XCTAssertNil(ClickTempoMeasure.bpm(beats: 1, samples: 0, sampleRate: sampleRate))
        XCTAssertNil(ClickTempoMeasure.bpm(beats: 1, samples: -512, sampleRate: sampleRate))
        XCTAssertNil(ClickTempoMeasure.bpm(beats: 1, samples: 24_000, sampleRate: 0))
        XCTAssertNil(ClickTempoMeasure.bpm(beats: 1, samples: 24_000, sampleRate: .nan))
        XCTAssertNil(ClickTempoMeasure.bpm(beats: 1, samples: 24_000, sampleRate: .infinity))
    }

    // MARK: - La posizione di battuta

    func testBarPositionInFourFour() {
        XCTAssertEqual(ClickTempoMeasure.barPosition(sectionBeat: 1, beatsPerBar: 4),
                       ClickTempoMeasure.BarPosition(bar: 1, beatInBar: 1))
        XCTAssertEqual(ClickTempoMeasure.barPosition(sectionBeat: 4, beatsPerBar: 4),
                       ClickTempoMeasure.BarPosition(bar: 1, beatInBar: 4))
        XCTAssertEqual(ClickTempoMeasure.barPosition(sectionBeat: 5, beatsPerBar: 4),
                       ClickTempoMeasure.BarPosition(bar: 2, beatInBar: 1))
        // l'ultimo battito della canzone 1 del collaudo: 112 battiti = 28 battute da 4
        XCTAssertEqual(ClickTempoMeasure.barPosition(sectionBeat: 112, beatsPerBar: 4),
                       ClickTempoMeasure.BarPosition(bar: 28, beatInBar: 4))
    }

    func testBarPositionInSixEight() {
        XCTAssertEqual(ClickTempoMeasure.barPosition(sectionBeat: 6, beatsPerBar: 6),
                       ClickTempoMeasure.BarPosition(bar: 1, beatInBar: 6))
        XCTAssertEqual(ClickTempoMeasure.barPosition(sectionBeat: 7, beatsPerBar: 6),
                       ClickTempoMeasure.BarPosition(bar: 2, beatInBar: 1))
    }

    func testNoBarPositionWhenTheSectionDoesNotCount() {
        XCTAssertNil(ClickTempoMeasure.barPosition(sectionBeat: 0, beatsPerBar: 4))
        XCTAssertNil(ClickTempoMeasure.barPosition(sectionBeat: -3, beatsPerBar: 4))
        XCTAssertNil(ClickTempoMeasure.barPosition(sectionBeat: 5, beatsPerBar: 0))
    }
}
