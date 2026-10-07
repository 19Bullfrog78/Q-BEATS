import XCTest

// === A398 · SOLO-G1-PEZZO-1-M3 — banco delle posizioni nuove: i blocchi dei veli, «Tap to start», V4 (banco Models) ===
// Dentro l'area utile e senza sovrapposizioni sulle quattro aree di prova di A397 (375 × 647, 390 × 763, 430 × 839,
// 820 × 1136), col blocco più alto (riga A su due righe, nome su due righe a 80): in H sopra la console, in V1/V2
// sopra «Tap to start». La zona del tocco di V1/V2 sotto la riga di stato fino al fondo, larga quanto l'area utile.

final class SoloVeilGeometryTests: XCTestCase {

    private let areas: [(Double, Double)] = [(375, 647), (390, 763), (430, 839), (820, 1136)]

    /// Il blocco più alto che il foglio ammette: riga A su due righe, nome su due righe a 80.
    private var tallestBlock: Double {
        SoloVeilTypography.blockHeight(relationLines: 2, nameLines: 2, nameSize: 80)
    }

    func testTheSheetPositionsAtFactorOne() {
        let g = SoloPlayerGeometry(usableWidth: 390, usableHeight: 766)
        XCTAssertEqual(g.scale, 1, accuracy: 1e-9)
        let block = g.veilBlock(height: 159.05)
        XCTAssertEqual(block.x, 26, accuracy: 1e-9)
        XCTAssertEqual(block.y, 248 - 44, accuracy: 1e-9)
        XCTAssertEqual(block.width, 338, accuracy: 1e-9)
        XCTAssertEqual(block.maxY, 407.05 - 44, accuracy: 1e-9)
        XCTAssertEqual(g.tapToStart.y, 618 - 44, accuracy: 1e-9)
        XCTAssertEqual(g.tapToStart.height, 44, accuracy: 1e-9)
        XCTAssertEqual(g.tapToStart.width, 390, accuracy: 1e-9)
        XCTAssertEqual(g.endShowLine.y, 360 - 44, accuracy: 1e-9)
        XCTAssertEqual(g.endShowLine.height, 44, accuracy: 1e-9)
        XCTAssertEqual(g.backToShows.x, 45, accuracy: 1e-9)
        XCTAssertEqual(g.backToShows.width, 300, accuracy: 1e-9)
        XCTAssertEqual(g.backToShows.y, 730 - 44, accuracy: 1e-9)
        XCTAssertEqual(g.backToShows.maxY, 794 - 44, accuracy: 1e-9)   // dal basso 50 sullo schermo 844
        XCTAssertEqual(g.backToShows.height, 64, accuracy: 1e-9)
    }

    func testTheTallestBlockEndsAboveTapToStartAndAboveTheConsole() {
        XCTAssertEqual(tallestBlock, 2 * 26.25 + 14 + 2 * 81.6 + 12 + 25.2, accuracy: 1e-9)
        for (w, h) in areas {
            let g = SoloPlayerGeometry(usableWidth: w, usableHeight: h)
            let block = g.veilBlock(height: tallestBlock)
            XCTAssertTrue(block.isInside(g.usableArea), "blocco fuori dall'area \(w)x\(h)")
            XCTAssertTrue(block.isInside(g.frame), "blocco fuori dalla cornice \(w)x\(h)")
            XCTAssertFalse(block.overlaps(g.tapToStart), "blocco su «Tap to start» \(w)x\(h)")
            XCTAssertLessThan(block.maxY, g.tapToStart.minY, "V1/V2: il blocco finisce sopra «Tap to start» \(w)x\(h)")
            XCTAssertFalse(block.overlaps(g.console), "blocco sulla console \(w)x\(h)")
            XCTAssertLessThan(block.maxY, g.console.minY, "H: il blocco finisce sopra la console \(w)x\(h)")
            XCTAssertFalse(block.overlaps(g.statusRow), "blocco sulla riga di stato \(w)x\(h)")
            XCTAssertFalse(block.overlaps(g.header), "blocco sulla testata \(w)x\(h)")
            // Caso D6 dichiarato: col blocco più alto il pannello del mixer (462-622) ne copre la parte bassa.
            XCTAssertTrue(block.overlaps(g.mixerPanel), "il pannello copre la parte bassa del blocco più alto \(w)x\(h)")
        }
    }

    func testTheOneLineBlockEndsAtFourHundredAndSevenAndTheTwoLineOneAtFourHundredAndEightyNine() {
        let g = SoloPlayerGeometry(usableWidth: 390, usableHeight: 766)
        let one = g.veilBlock(height: SoloVeilTypography.blockHeight(relationLines: 1, nameLines: 1, nameSize: 80))
        XCTAssertEqual(one.maxY + 44, 407, accuracy: 0.1)
        let two = g.veilBlock(height: SoloVeilTypography.blockHeight(relationLines: 1, nameLines: 2, nameSize: 80))
        XCTAssertEqual(two.maxY + 44, 489, accuracy: 0.4)
        // Col nome su una riga a 80 il pannello del mixer (da 462) non tocca il blocco; con due righe sì (D6).
        XCTAssertFalse(one.overlaps(g.mixerPanel))
        XCTAssertTrue(two.overlaps(g.mixerPanel))
    }

    func testTapToStartAndV4AreInsideTheFrameAndApart() {
        for (w, h) in areas {
            let g = SoloPlayerGeometry(usableWidth: w, usableHeight: h)
            for (name, r) in [("Tap to start", g.tapToStart), ("END SHOW", g.endShowLine), ("Back to Shows", g.backToShows)] {
                XCTAssertTrue(r.isInside(g.usableArea), "\(name) fuori dall'area \(w)x\(h)")
                XCTAssertTrue(r.isInside(g.frame), "\(name) fuori dalla cornice \(w)x\(h)")
            }
            XCTAssertFalse(g.endShowLine.overlaps(g.backToShows), "\(w)x\(h)")
            XCTAssertFalse(g.endShowLine.overlaps(g.statusRow), "\(w)x\(h)")
            XCTAssertFalse(g.endShowLine.overlaps(g.header), "\(w)x\(h)")
            XCTAssertFalse(g.tapToStart.overlaps(g.statusRow), "\(w)x\(h)")
            XCTAssertLessThan(g.endShowLine.maxY, g.backToShows.minY, "\(w)x\(h)")
            XCTAssertEqual(g.endShowLine.width, g.frame.width, accuracy: 1e-9)
            XCTAssertEqual(g.tapToStart.width, g.frame.width, accuracy: 1e-9)
        }
    }

    func testTheVeilTapZoneIsBelowTheStatusRowDownToTheBottomAndAsWideAsTheUsableArea() {
        for (w, h) in areas {
            let g = SoloPlayerGeometry(usableWidth: w, usableHeight: h)
            let z = g.veilTapZone
            XCTAssertEqual(z.x, 0, accuracy: 1e-9)
            XCTAssertEqual(z.width, w, accuracy: 1e-9)
            XCTAssertEqual(z.minY, g.statusRow.maxY, accuracy: 1e-9)
            XCTAssertEqual(z.maxY, h, accuracy: 1e-9)
            XCTAssertFalse(z.overlaps(g.header), "testata fuori dalla zona del tocco \(w)x\(h)")
            XCTAssertFalse(z.overlaps(g.statusRow), "riga di stato fuori dalla zona del tocco \(w)x\(h)")
            XCTAssertTrue(g.tapToStart.isInside(z), "«Tap to start» dentro la zona \(w)x\(h)")
            XCTAssertTrue(g.veilBlock(height: tallestBlock).isInside(z), "il blocco dentro la zona \(w)x\(h)")
            // H: la zona senza tocco finisce alla console.
            let dead = g.resumeDeadZone
            XCTAssertEqual(dead.minY, g.statusRow.maxY, accuracy: 1e-9)
            XCTAssertEqual(dead.maxY, g.console.minY, accuracy: 1e-9)
            XCTAssertEqual(dead.width, w, accuracy: 1e-9)
            XCTAssertFalse(dead.overlaps(g.console))
        }
    }

    func testADegenerateAreaDoesNotCrash() {
        let g = SoloPlayerGeometry(usableWidth: 0, usableHeight: -5)
        XCTAssertGreaterThanOrEqual(g.veilTapZone.height, 0)
        XCTAssertGreaterThanOrEqual(g.resumeDeadZone.height, 0)
        XCTAssertGreaterThanOrEqual(g.veilBlock(height: -10).height, 0)
        XCTAssertGreaterThan(g.scale, 0)
    }
}
