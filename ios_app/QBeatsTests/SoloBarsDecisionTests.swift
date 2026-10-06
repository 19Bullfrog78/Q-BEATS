import XCTest

// === A397 · SOLO-G1-PEZZO-1-M2 — banco delle due barre (banco Models) ===
// Barra delle battute: spazi 6, 3, 1,5 ai confini 16, 17, 32, 33, 64; segmento 16,5 a 16 battute, circa 8,2 a
// 32, circa 4 a 64 (il registro di controllo in fondo alla REV18); raggio mai oltre metà del segmento; fatte,
// in corso, le altre, con le regole di stato di `MicroSegBarView`. Barra della canzone: l'esempio dei fogli
// (sezioni da 8, 16, 16, 8, 8; avanzamento 6,25 % a battuta 1 di 16 e 62,5 % a 5 di 8); sezione infinita e
// sezione da 0 battute senza fermarsi (D6).

final class SoloBarsDecisionTests: XCTestCase {

    // MARK: - La barra delle battute

    func testTheGapsAtTheBoundaries() {
        XCTAssertEqual(SoloBarMeterLayout.gap(forBars: 1), 6)
        XCTAssertEqual(SoloBarMeterLayout.gap(forBars: 16), 6)
        XCTAssertEqual(SoloBarMeterLayout.gap(forBars: 17), 3)
        XCTAssertEqual(SoloBarMeterLayout.gap(forBars: 32), 3)
        XCTAssertEqual(SoloBarMeterLayout.gap(forBars: 33), 1.5)
        XCTAssertEqual(SoloBarMeterLayout.gap(forBars: 64), 1.5)
    }

    func testTheSegmentWidthsOfTheSheet() {
        XCTAssertEqual(SoloBarMeterLayout(totalBars: 16).segmentWidth, 16.5, accuracy: 0.0001)
        XCTAssertEqual(SoloBarMeterLayout(totalBars: 32).segmentWidth, 8.2, accuracy: 0.05)
        XCTAssertEqual(SoloBarMeterLayout(totalBars: 64).segmentWidth, 4, accuracy: 0.1)
        XCTAssertEqual(SoloBarMeterLayout(totalBars: 8).segmentWidth, 39, accuracy: 0.0001)
        XCTAssertEqual(SoloBarMeterLayout(totalBars: 64).cornerRadius, 2, accuracy: 0.05)
    }

    func testTheRadiusNeverExceedsHalfTheSegmentAndTheRowIs354() {
        for n in 1...64 {
            let l = SoloBarMeterLayout(totalBars: n)
            XCTAssertEqual(l.count, n)
            XCTAssertLessThanOrEqual(l.cornerRadius, l.segmentWidth / 2 + 0.0001, "battute \(n)")
            XCTAssertLessThanOrEqual(l.cornerRadius, 6 + 0.0001, "battute \(n)")
            XCTAssertEqual(Double(n) * l.segmentWidth + Double(n - 1) * l.gap, 354, accuracy: 0.0001, "battute \(n)")
        }
    }

    func testTheStatesDoneCurrentOther() {
        let s = SoloBarMeterLayout.states(count: 8, currentBar: 5, lit: true)
        XCTAssertEqual(s, [.done, .done, .done, .done, .current, .other, .other, .other])
        XCTAssertEqual(SoloBarMeterLayout.states(count: 8, currentBar: 1, lit: true).first, .current)
        XCTAssertEqual(SoloBarMeterLayout.states(count: 8, currentBar: 8, lit: true).last, .current)
    }

    func testOffInStandbyAndWithoutTheAnchor() {
        // Spenta (`.standby`, oppure né `.playing` né `sectionHold`): tutti «le altre».
        XCTAssertEqual(SoloBarMeterLayout.states(count: 4, currentBar: 2, lit: false), [.other, .other, .other, .other])
        // Battuta 0 = ancora non conquistata (trattini): niente fatto, niente in corso.
        XCTAssertEqual(SoloBarMeterLayout.states(count: 4, currentBar: 0, lit: true), [.other, .other, .other, .other])
        // Oltre l'ultima: tutte fatte, nessuna in corso.
        XCTAssertEqual(SoloBarMeterLayout.states(count: 3, currentBar: 7, lit: true), [.done, .done, .done])
        XCTAssertEqual(SoloBarMeterLayout.states(count: 0, currentBar: 1, lit: true), [])
    }

    func testInfiniteAndZeroBarsDrawOneSegment() {
        XCTAssertEqual(SoloBarMeterLayout(totalBars: -1).count, 1)
        XCTAssertEqual(SoloBarMeterLayout(totalBars: 0).count, 1)
        XCTAssertEqual(SoloBarMeterLayout(totalBars: -1).segmentWidth, 354, accuracy: 0.0001)
        XCTAssertEqual(SoloBarMeterLayout(totalBars: -1).cornerRadius, 6, accuracy: 0.0001)
    }

    func testBeyondSixtyFourBarsStaysTotal() {
        for n in [65, 100, 200, 400, 1000] {
            let l = SoloBarMeterLayout(totalBars: n)
            XCTAssertGreaterThan(l.segmentWidth, 0, "battute \(n)")
            XCTAssertGreaterThanOrEqual(l.gap, 0, "battute \(n)")
            XCTAssertLessThanOrEqual(Double(n) * l.segmentWidth + Double(n - 1) * l.gap, 354 + 0.0001, "battute \(n)")
            XCTAssertLessThanOrEqual(l.cornerRadius, l.segmentWidth / 2 + 0.0001, "battute \(n)")
        }
    }

    // MARK: - La barra della canzone

    private let sheetSong = [8, 16, 16, 8, 8]

    func testTheSheetExampleAtBarOneOfSixteen() {
        // Schermo K della REV18: terza sezione in corso, battuta 1 di 16 → 6,25 %.
        let l = SoloSongBarLayout(barsPerSection: sheetSong, currentSectionIndex: 2, currentBar: 1, totalBarsInSection: 16)
        XCTAssertEqual(l.blocks.map { $0.state }, [.done, .done, .current, .other, .other])
        XCTAssertEqual(l.blocks[2].progress, 0.0625, accuracy: 0.0001)
        XCTAssertEqual(l.blocks[0].progress, 0)
        XCTAssertEqual(l.blocks.map { $0.weight }, [8, 16, 16, 8, 8])
    }

    func testTheREV9ExampleAtBarFiveOfEight() {
        // Schermo E della REV9: quarta sezione in corso, battuta 5 di 8 → 62,5 %.
        let l = SoloSongBarLayout(barsPerSection: sheetSong, currentSectionIndex: 3, currentBar: 5, totalBarsInSection: 8)
        XCTAssertEqual(l.blocks.map { $0.state }, [.done, .done, .done, .current, .other])
        XCTAssertEqual(l.blocks[3].progress, 0.625, accuracy: 0.0001)
    }

    func testTheWidthsAreProportionalToTheBars() {
        let l = SoloSongBarLayout(barsPerSection: sheetSong, currentSectionIndex: 0, currentBar: 1, totalBarsInSection: 8)
        let w = l.widths()
        // 354 meno quattro spazi da 4 = 338, diviso in 56 parti.
        XCTAssertEqual(w.reduce(0, +), 338, accuracy: 0.0001)
        XCTAssertEqual(w[0], 338.0 * 8 / 56, accuracy: 0.0001)
        XCTAssertEqual(w[1], 338.0 * 16 / 56, accuracy: 0.0001)
        XCTAssertEqual(w[1], 2 * w[0], accuracy: 0.0001)
    }

    func testInfiniteAndZeroSectionsDoNotStop() {
        let l = SoloSongBarLayout(barsPerSection: [8, -1, 0, 8], currentSectionIndex: 1, currentBar: 3, totalBarsInSection: -1)
        XCTAssertEqual(l.blocks.map { $0.weight }, [8, 1, 1, 8])
        XCTAssertEqual(l.blocks[1].state, .current)
        XCTAssertEqual(l.blocks[1].progress, 0, "sezione infinita: avanzamento 0")
        let widths = l.widths()
        XCTAssertEqual(widths.count, 4)
        XCTAssertEqual(widths.reduce(0, +), 354 - 3 * 4, accuracy: 0.0001)
        let zero = SoloSongBarLayout(barsPerSection: [4], currentSectionIndex: 0, currentBar: 2, totalBarsInSection: 0)
        XCTAssertEqual(zero.blocks[0].progress, 0, "sezione da 0 battute: avanzamento 0")
    }

    func testProgressIsClampedAndTheLastBlockIsCurrentOnTheLastSection() {
        let over = SoloSongBarLayout(barsPerSection: [4, 4], currentSectionIndex: 1, currentBar: 9, totalBarsInSection: 4)
        XCTAssertEqual(over.blocks[1].progress, 1, accuracy: 0.0001)
        XCTAssertEqual(over.blocks.map { $0.state }, [.done, .current])
        let before = SoloSongBarLayout(barsPerSection: [4, 4], currentSectionIndex: 0, currentBar: 0, totalBarsInSection: 4)
        XCTAssertEqual(before.blocks[0].progress, 0, accuracy: 0.0001)
    }

    func testNoSectionsNoCrash() {
        let empty = SoloSongBarLayout(barsPerSection: [], currentSectionIndex: 0, currentBar: 1, totalBarsInSection: 4)
        XCTAssertTrue(empty.blocks.isEmpty)
        XCTAssertTrue(empty.widths().isEmpty)
        let beyond = SoloSongBarLayout(barsPerSection: [4, 4], currentSectionIndex: 5, currentBar: 1, totalBarsInSection: 4)
        XCTAssertEqual(beyond.blocks.map { $0.state }, [.done, .done])
    }
}
