import XCTest

// === A397 · SOLO-G1-PEZZO-1-M2 — banco della geometria di K (banco Models) ===
// Fattore entro 0,005 da 1 sull'area utile 390 x 763; sulle quattro aree di prova del referee (375 x 647,
// 390 x 763, 430 x 839, 820 x 1136: valori di prova, non misure di apparecchi) tutti i blocchi dentro l'area
// utile e nessuna sovrapposizione; il pannello del mixer finisce sopra la console; la traduzione dal foglio
// (y − 44, fattore, cornice centrata); un'area degenere non ferma niente.

final class SoloPlayerGeometryTests: XCTestCase {

    private let areas: [(Double, Double)] = [(375, 647), (390, 763), (430, 839), (820, 1136)]

    func testTheFactorIsOneOnTheReferencePhone() {
        let g = SoloPlayerGeometry(usableWidth: 390, usableHeight: 763)
        XCTAssertEqual(g.scale, 1, accuracy: 0.005)
        XCTAssertEqual(g.frame.width, 390 * g.scale, accuracy: 0.0001)
        // Comanda l'altezza (763/766): la cornice è più stretta di 390 per tre millesimi e, centrata, parte a
        // x = (390 − 390 × 0,99608) / 2 ≈ 0,76, non a 0 (prima corsa della CI, run 37448423825: il banco chiedeva 0).
        XCTAssertEqual(g.frame.x, (390 - 390 * g.scale) / 2, accuracy: 0.0001)
        XCTAssertLessThan(g.frame.x, 1)
        XCTAssertEqual(g.frame.y, 0, accuracy: 0.0001)
    }

    func testTheFrameIsTheSheetWithoutStatusBarAndBottomInset() {
        XCTAssertEqual(SoloPlayerGeometry.frameWidth, 390)
        XCTAssertEqual(SoloPlayerGeometry.frameHeight, 766)
    }

    func testEveryBlockIsInsideTheUsableAreaOnTheFourAreas() {
        for (w, h) in areas {
            let g = SoloPlayerGeometry(usableWidth: w, usableHeight: h)
            XCTAssertTrue(g.frame.isInside(g.usableArea), "cornice fuori dall'area \(w)x\(h)")
            XCTAssertEqual(g.blocks.count, 9)
            for (i, b) in g.blocks.enumerated() {
                XCTAssertTrue(b.isInside(g.usableArea), "blocco \(i) fuori dall'area \(w)x\(h): \(b)")
                XCTAssertTrue(b.isInside(g.frame), "blocco \(i) fuori dalla cornice \(w)x\(h): \(b)")
            }
            XCTAssertTrue(g.mixerPanel.isInside(g.usableArea), "pannello fuori dall'area \(w)x\(h)")
        }
    }

    func testNoTwoBlocksOverlapOnTheFourAreas() {
        for (w, h) in areas {
            let g = SoloPlayerGeometry(usableWidth: w, usableHeight: h)
            let blocks = g.blocks
            for i in 0..<blocks.count {
                for j in (i + 1)..<blocks.count {
                    XCTAssertFalse(blocks[i].overlaps(blocks[j]), "blocchi \(i) e \(j) sovrapposti su \(w)x\(h)")
                }
            }
        }
    }

    func testTheMixerPanelEndsAboveTheConsole() {
        for (w, h) in areas {
            let g = SoloPlayerGeometry(usableWidth: w, usableHeight: h)
            XCTAssertLessThanOrEqual(g.mixerPanel.maxY, g.console.minY + 0.0001, "pannello sulla console su \(w)x\(h)")
            // Gli 8 del foglio fra il bordo in basso del pannello (622) e i quadranti (630).
            XCTAssertEqual(g.console.minY - g.mixerPanel.maxY, 8 * g.scale, accuracy: 0.0001)
            // Il pannello copre Next e la barra della canzone, non il teleprompter (punto 111).
            XCTAssertTrue(g.mixerPanel.overlaps(g.next))
            XCTAssertTrue(g.mixerPanel.overlaps(g.songBar))
            XCTAssertFalse(g.mixerPanel.overlaps(g.prompter))
            // A401 — Solo REV20, sezione R: il riquadro comincia 8 sotto la barra delle battute (276) e finisce 5
            // sopra il pannello del mixer aperto (462).
            XCTAssertEqual(g.prompter.minY - g.barMeter.maxY, 8 * g.scale, accuracy: 0.0001)
            XCTAssertEqual(g.mixerPanel.minY - g.prompter.maxY, 5 * g.scale, accuracy: 0.0001)
            XCTAssertEqual(g.mixerPanel.height, 160 * g.scale, accuracy: 0.0001)
        }
    }

    func testTheFactorIsTheSmallerRatioAndTheFrameIsCentered() {
        let tall = SoloPlayerGeometry(usableWidth: 375, usableHeight: 647)   // comanda l'altezza
        XCTAssertEqual(tall.scale, 647.0 / 766.0, accuracy: 0.0001)
        XCTAssertEqual(tall.frame.x, (375 - 390 * tall.scale) / 2, accuracy: 0.0001)
        XCTAssertEqual(tall.frame.y, 0, accuracy: 0.0001)
        let wide = SoloPlayerGeometry(usableWidth: 820, usableHeight: 1136)
        XCTAssertEqual(wide.scale, min(820.0 / 390.0, 1136.0 / 766.0), accuracy: 0.0001)
        XCTAssertEqual(wide.frame.midX, 410, accuracy: 0.0001)
        XCTAssertEqual(wide.frame.midY, 568, accuracy: 0.0001)
    }

    func testTheSheetTranslationLiterally() {
        let g = SoloPlayerGeometry(usableWidth: 390, usableHeight: 766)   // fattore esattamente 1
        XCTAssertEqual(g.scale, 1, accuracy: 0.0000001)
        XCTAssertEqual(g.header.y, 52 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.header.height, 44, accuracy: 0.0001)
        XCTAssertEqual(g.statusRow.y, 98 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.statusRow.height, 30, accuracy: 0.0001)
        XCTAssertEqual(g.beatLights.midY, 179 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.barRow.y, 226 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.barMeter.y, 264 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.barMeter.height, 12, accuracy: 0.0001)
        // A401 — Solo REV20, punto 115: riquadro del teleprompter 284-457, largo 366, alto 173 (era 346-446, alto 100).
        XCTAssertEqual(g.prompter.y, 284 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.prompter.x, 12, accuracy: 0.0001)
        XCTAssertEqual(g.prompter.width, 366, accuracy: 0.0001)
        XCTAssertEqual(g.prompter.height, 173, accuracy: 0.0001)
        XCTAssertEqual(g.prompter.maxY, 457 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.next.y, 516 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.next.height, 60, accuracy: 0.0001)
        XCTAssertEqual(g.songBar.y, 596 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.songBar.height, 10, accuracy: 0.0001)
        XCTAssertEqual(g.console.y, 630 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.console.height, 176, accuracy: 0.0001)
        XCTAssertEqual(g.console.x, 18, accuracy: 0.0001)
        XCTAssertEqual(g.console.width, 354, accuracy: 0.0001)
        XCTAssertEqual(g.mixerPanel.y, 462 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.mixerPanel.maxY, 622 - 44, accuracy: 0.0001)
        XCTAssertEqual(g.mixerPanel.width, 390, accuracy: 0.0001)
        XCTAssertEqual(g.scaled(44), 44, accuracy: 0.0001)
    }

    func testMeasuresScaleWithTheFactor() {
        let g = SoloPlayerGeometry(usableWidth: 820, usableHeight: 1136)
        XCTAssertEqual(g.scaled(24), 24 * g.scale, accuracy: 0.0001)
        XCTAssertEqual(g.console.width, 354 * g.scale, accuracy: 0.0001)
        XCTAssertEqual(g.console.x, g.frame.x + 18 * g.scale, accuracy: 0.0001)
    }

    func testADegenerateAreaDoesNotCrash() {
        let g = SoloPlayerGeometry(usableWidth: 0, usableHeight: 0)
        XCTAssertGreaterThan(g.scale, 0)
        for b in g.blocks {
            XCTAssertGreaterThanOrEqual(b.width, 0)
            XCTAssertGreaterThanOrEqual(b.height, 0)
        }
        let negative = SoloPlayerGeometry(usableWidth: -10, usableHeight: -10)
        XCTAssertGreaterThan(negative.scale, 0)
    }

    func testRectOverlapAndInside() {
        let a = SoloRect(x: 0, y: 0, width: 10, height: 10)
        let b = SoloRect(x: 10, y: 0, width: 10, height: 10)   // si toccano sul bordo: non si sovrappongono
        let c = SoloRect(x: 5, y: 5, width: 10, height: 10)
        XCTAssertFalse(a.overlaps(b))
        XCTAssertTrue(a.overlaps(c))
        XCTAssertTrue(SoloRect(x: 1, y: 1, width: 2, height: 2).isInside(a))
        XCTAssertTrue(a.isInside(a))
        XCTAssertFalse(c.isInside(a))
        XCTAssertEqual(c.midX, 10, accuracy: 0.0001)
        XCTAssertEqual(c.maxY, 15, accuracy: 0.0001)
    }
}
