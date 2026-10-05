import XCTest

// === A394 · SOLO-G1-PEZZO-1-M1 — banco della metrica in testata (banco Models) ===
// Le cinque metriche che la testata di oggi scriveva sbagliate (6/4 come «6/8»; 5/8, 7/8, 9/8,
// 11/8 con «/4») e, come controllo, 4/4, 6/8 e 12/8, che uscivano giuste. Poi tutta la lista
// chiusa e una metrica fuori lista.

final class MeterLabelTests: XCTestCase {

    /// La funzione di oggi (`LiveView.timeSigString(for:)` a c1dec22), ricopiata qui solo per
    /// mostrare dove sbagliava: denominatore 8 per 6 e 12 battiti, 4 per tutto il resto.
    private func oldLabel(beats: UInt32) -> String {
        let denom: UInt32 = (beats == 6 || beats == 12) ? 8 : 4
        return "\(beats)/\(denom)"
    }

    func testTheFiveMetersThatWereWrong() {
        // (battiti, unità, atteso, scritta di oggi)
        let rows: [(UInt32, UInt32, String, String)] = [
            (6,  4, "6/4",  "6/8"),
            (9,  8, "9/8",  "9/4"),
            (5,  8, "5/8",  "5/4"),
            (7,  8, "7/8",  "7/4"),
            (11, 8, "11/8", "11/4"),
        ]
        XCTAssertEqual(rows.count, 5)
        for (beats, unit, expected, old) in rows {
            XCTAssertEqual(MeterLabel.text(beatsPerBar: beats, beatUnit: unit), expected)
            XCTAssertEqual(oldLabel(beats: beats), old, "la scritta di oggi per \(beats)/\(unit)")
            XCTAssertNotEqual(oldLabel(beats: beats), expected)
        }
    }

    func testTheThreeMetersThatWereRightStayRight() {
        let rows: [(UInt32, UInt32, String)] = [(4, 4, "4/4"), (6, 8, "6/8"), (12, 8, "12/8")]
        for (beats, unit, expected) in rows {
            XCTAssertEqual(MeterLabel.text(beatsPerBar: beats, beatUnit: unit), expected)
            XCTAssertEqual(oldLabel(beats: beats), expected)
        }
    }

    func testEveryMeterOfTheClosedListGetsItsOwnLabel() {
        XCTAssertEqual(TimeSignature.all.count, 12)
        for ts in TimeSignature.all {
            XCTAssertEqual(MeterLabel.text(beatsPerBar: ts.numerator, beatUnit: ts.denominator), ts.label)
        }
    }

    func testAMeterOutsideTheClosedListStillGetsALabel() {
        XCTAssertNil(TimeSignature.find(numerator: 13, denominator: 16))
        XCTAssertEqual(MeterLabel.text(beatsPerBar: 13, beatUnit: 16), "13/16")
    }

    func testTheLabelComesFromTheSectionNumbers() {
        var section = SongSection.makeDefault()
        section.beatsPerBar = 6
        section.beatUnit = 4
        XCTAssertEqual(MeterLabel.text(beatsPerBar: section.beatsPerBar, beatUnit: section.beatUnit), "6/4")
        XCTAssertEqual(MeterLabel.defaultBeatUnit, SongSection.makeDefault().beatUnit)
    }
}
