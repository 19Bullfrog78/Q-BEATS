import XCTest

// === A401 · SOLO REV20, PUNTO 115 — banco della regola del teleprompter di K, la parte pura (banco Models) ===
// ⚠️ A403 (11/10/2026) — SOLO REV22, PUNTI 115 E 119: RISCRITTO SULLA REGOLA B. Le prove della regola A (due righe da
//    68 a 53, poi tre righe da 53 a 42, nel riquadro alto 173) sono uscite con lei.
// La regola (`SoloVeilTypography.sectionFit`, sopra `TextFitter`): righe larghe 366, fino a tre, corpi da 68 a 42 a
// scendere di 1, vince il primo a cui il nome sta; a 42 ciò che non sta finisce coi puntini, alla fine della terza
// riga. Un passo solo. Qui col misuratore finto di `TextFitterTests` (`FakeTextMeasurer`: minuscole 0,55 em, spazio
// 0,3, trattino 0,35, puntini 0,9, più la spaziatura dopo ogni carattere): con −0,035 em una minuscola è larga
// 0,515 × corpo, lo spazio 0,265, il trattino 0,315, i puntini 0,865. Gli attesi sono derivati dalla regola con questi
// numeri (i conti stanno accanto a ogni caso), non assunti. Gli attesi del foglio, col carattere vero, stanno in
// `TextFitterRealFontTests`. In coda: il fit una volta per nome (`SoloSectionFitMemo`).

/// Un misuratore che conta le misure: per provare che il fit di un nome già visto non si ricalcola.
final class CountingTextMeasurer: TextWidthMeasurer {
    private let inner = FakeTextMeasurer()
    private(set) var widthCalls = 0

    func width(of text: String, fontName: String, size: Double, trackingEm: Double) -> Double {
        widthCalls += 1
        return inner.width(of: text, fontName: fontName, size: size, trackingEm: trackingEm)
    }

    func verticalMetrics(fontName: String) -> FontVerticalMetrics {
        inner.verticalMetrics(fontName: fontName)
    }
}

final class SoloSectionFitTests: XCTestCase {

    private let m = FakeTextMeasurer()

    private func fit(_ name: String) -> FittedText { SoloVeilTypography.sectionFit(name, measurer: m) }
    private func texts(_ f: FittedText) -> [String] { f.lines.map { $0.text } }

    // MARK: - Le misure del foglio, pinnate (Solo REV22: tabella della sezione R, sezione S)

    func testTheRuleCarriesTheSheetValues() {
        XCTAssertEqual(SoloVeilTypography.sectionMaxSize, 68)
        XCTAssertEqual(SoloVeilTypography.sectionMinSize, 42)
        XCTAssertEqual(SoloVeilTypography.sectionWidth, 366)
        XCTAssertEqual(SoloVeilTypography.sectionBoxHeight, 224)
        XCTAssertEqual(SoloVeilTypography.sectionMaxLines, 3)
        let spec = SoloVeilTypography.sectionSpec("Bridge")
        XCTAssertEqual(spec.styles, [TextFitStyle(fontName: "Inter-ExtraBold", trackingEm: -0.035)])
        XCTAssertEqual(spec.lineHeightFactor, 1.08)
        XCTAssertEqual(spec.maxWidth, 366)
        XCTAssertEqual(spec.maxLines, 3)
        // Un passo solo: da 68 a 42, 27 corpi.
        XCTAssertEqual(spec.sizes, stride(from: 68, through: 42, by: -1).map { Double($0) })
        XCTAssertEqual(spec.sizes.count, 27)
        XCTAssertEqual(spec.runs, [TextRun(text: "Bridge", style: 0)])
    }

    func testThreeLinesFitTheBoxUpToSixtyNine() {
        // Tabella della sezione R, riga «Riquadro del teleprompter»: «ci stanno tre righe fino a 69: a 68 sono alte
        // 220,3», nel riquadro alto 224.
        XCTAssertEqual(3 * 1.08 * 68, 220.32, accuracy: 1e-9)
        XCTAssertLessThanOrEqual(3 * 1.08 * 68, SoloVeilTypography.sectionBoxHeight)
        XCTAssertLessThanOrEqual(3 * 1.08 * 69, SoloVeilTypography.sectionBoxHeight)   // 223,56
        XCTAssertGreaterThan(3 * 1.08 * 70, SoloVeilTypography.sectionBoxHeight)       // 226,8
    }

    func testWhereTheBlockSitsInTheSheet() {
        // Sezione S, tavola dei casi, cella per cella: «una riga a 68», «359–433 · alto 73,4»; «due righe a 68»,
        // «323–469 · alto 146,9»; «tre righe a 68», «286–506 · alto 220,3 · 10 sopra Next»; «tre righe a 57»,
        // «304–488 · alto 184,7»; «tre righe a 42, coi puntini», «328–464 · alto 136,1»; le righe «centrate a 396».
        // Il riquadro va da 284 a 508.
        let cases: [(lines: Double, size: Double, top: Double, bottom: Double, height: Double)] = [
            (1, 68, 359, 433, 73.4), (2, 68, 323, 469, 146.9), (3, 68, 286, 506, 220.3),
            (3, 57, 304, 488, 184.7), (3, 42, 328, 464, 136.1),
        ]
        for c in cases {
            let height = c.lines * 1.08 * c.size
            let top = 284 + SoloVeilTypography.sectionBlockTop(height: height)
            XCTAssertEqual(height, c.height, accuracy: 0.05, "\(c.lines) righe a \(c.size)")
            XCTAssertEqual(top.rounded(), c.top, "\(c.lines) righe a \(c.size)")
            XCTAssertEqual((top + height).rounded(), c.bottom, "\(c.lines) righe a \(c.size)")
            XCTAssertEqual(top + height / 2, 396, accuracy: 1e-9, "il blocco sta al centro, a 396")
            XCTAssertGreaterThanOrEqual(top, 284)
            XCTAssertLessThanOrEqual(top + height, 508)
        }
    }

    func testOneLineIsNeverUnderTheOpenMixer() {
        // Tavola della sezione S: «una riga a 68 … niente coperto: il blocco finisce 29 sopra il pannello»; didascalia
        // di R14: «Una riga, a qualunque corpo fino a 68, non è mai coperta». Il pannello aperto comincia a 462.
        for size in stride(from: 42.0, through: 68.0, by: 1.0) {
            let height = 1.08 * size
            let bottom = 284 + SoloVeilTypography.sectionBlockTop(height: height) + height
            XCTAssertLessThan(bottom, 462, "una riga a \(size)")
        }
        let bottomAtSixtyEight = 284 + SoloVeilTypography.sectionBlockTop(height: 1.08 * 68) + 1.08 * 68
        XCTAssertEqual((462 - bottomAtSixtyEight).rounded(), 29)
        // Due righe a 68 finiscono a 469, tre a 506: sotto 462 le copre il pannello.
        XCTAssertGreaterThan(284 + SoloVeilTypography.sectionBlockTop(height: 2 * 1.08 * 68) + 2 * 1.08 * 68, 462)
    }

    // MARK: - Fino a tre righe, da 68

    func testAShortNameStaysAtSixtyEightOnOneLine() {
        // 10 minuscole a 68: 10 × 0,515 × 68 = 350,2 ≤ 366.
        let f = fit("abcdefghij")
        XCTAssertEqual(f.size, 68)
        XCTAssertEqual(texts(f), ["abcdefghij"])
        XCTAssertEqual(f.lines[0].width, 350.2, accuracy: 1e-9)
        XCTAssertTrue(f.fits)
        XCTAssertFalse(f.truncated)
        XCTAssertEqual(f.height, 1.08 * 68, accuracy: 1e-9)
    }

    func testTwoWordsGoOnTwoLinesAtSixtyEight() {
        // Le due parole insieme a 68: 700,4 + 18,02 > 366; ognuna 350,2: due righe a 68.
        let f = fit("abcdefghij abcdefghij")
        XCTAssertEqual(f.size, 68)
        XCTAssertEqual(texts(f), ["abcdefghij", "abcdefghij"])
        XCTAssertFalse(f.truncated)
    }

    func testThreeWordsGoOnThreeLinesAtSixtyEight() {
        // Tre parole di 8 minuscole: a 68 ognuna fa 8 × 0,515 × 68 = 280,16 ≤ 366; due insieme 560,32 + 18,02 = 578,34
        // > 366. Tre righe, e a 68 ci stanno: la regola prova subito fino a tre righe (sezione S: «le righe sono
        // quelle che servono a quel corpo: una, due o tre»).
        let f = fit("abcdefgh abcdefgh abcdefgh")
        XCTAssertEqual(f.size, 68)
        XCTAssertEqual(texts(f), ["abcdefgh", "abcdefgh", "abcdefgh"])
        XCTAssertEqual(f.lines[0].width, 280.16, accuracy: 1e-9)
        XCTAssertTrue(f.fits)
        XCTAssertFalse(f.truncated)
        XCTAssertEqual(f.height, 3 * 1.08 * 68, accuracy: 1e-9)
    }

    // MARK: - Il corpo scende di 1: una parola più larga di 366, oppure più di tre righe

    func testTheSizeGoesDownOneByOneWhenAWordIsWiderThanTheBox() {
        // 11 minuscole: a 65 fanno 368,225 > 366, a 64 fanno 362,56: il primo corpo a cui la parola sta. Con due
        // parole due righe, con tre parole tre righe, allo stesso corpo.
        let f = fit("abcdefghijk abcdefghijk")
        XCTAssertEqual(f.size, 64)
        XCTAssertEqual(texts(f), ["abcdefghijk", "abcdefghijk"])
        XCTAssertEqual(f.lines[0].width, 362.56, accuracy: 1e-9)
        XCTAssertFalse(f.truncated)
        let g = fit("abcdefghijk abcdefghijk abcdefghijk")
        XCTAssertEqual(g.size, 64)
        XCTAssertEqual(g.lineCount, 3)
        XCTAssertFalse(g.truncated)
        // 13 minuscole: a 55 fanno 368,225, a 54 fanno 361,53.
        let h = fit("abcdefghijklm abcdefghijklm abcdefghijklm")
        XCTAssertEqual(h.size, 54)
        XCTAssertEqual(h.lineCount, 3)
        XCTAssertEqual(h.lines[0].width, 361.53, accuracy: 1e-9)
    }

    func testTheSizeGoesDownOneByOneWhenThreeLinesAreNotEnough() {
        // Quattro parole di 6 minuscole: una è larga 3,09 × corpo, due insieme 6,445 × corpo. Da 68 a 57 due insieme
        // non stanno (a 57: 367,365 > 366): quattro righe, una più di tre. A 56 stanno (360,92): due righe.
        let f = fit("abcdef abcdef abcdef abcdef")
        XCTAssertEqual(f.size, 56)
        XCTAssertEqual(texts(f), ["abcdef abcdef", "abcdef abcdef"])
        XCTAssertEqual(f.lines[0].width, 360.92, accuracy: 1e-9)
        XCTAssertTrue(f.fits)
        // Otto parole di 4 minuscole: tre insieme sono larghe 6,71 × corpo: a 55 fanno 369,05 > 366, a 54 fanno 362,34.
        // Da 68 a 55 ne stanno due per riga: quattro righe. A 54 tre per riga: tre righe.
        let g = fit("aaaa bbbb cccc dddd eeee ffff gggg hhhh")
        XCTAssertEqual(g.size, 54)
        XCTAssertEqual(texts(g), ["aaaa bbbb cccc", "dddd eeee ffff", "gggg hhhh"])
        XCTAssertEqual(g.lines[0].width, 362.34, accuracy: 1e-9)
        XCTAssertFalse(g.truncated)
    }

    func testAWrittenHyphenIsABreakPoint() {
        // «ab-cdefghijklm»: intero a 68 non sta; dopo il trattino «cdefghijklm» (11 minuscole) sta a 64.
        let f = fit("ab-cdefghijklm")
        XCTAssertEqual(f.size, 64)
        XCTAssertEqual(texts(f), ["ab-", "cdefghijklm"])
        XCTAssertFalse(f.truncated)
    }

    // MARK: - Il pavimento: a 42 i puntini, alla fine della terza riga

    func testAtFortyTwoWhatDoesNotFitEndsWithTheEllipsisOnTheThirdLine() {
        // Quattro parole, tre di 16 minuscole e una di 4: una parola di 16 sta da 44 in giù (a 45: 370,8; a 44: 362,56),
        // ma con la quarta parola le righe sono quattro a 44, a 43 e a 42. A 42 restano le prime tre; la terza si
        // chiude coi puntini: «…» fa 36,33, con 16 lettere 382,41 > 366, con 15 fa 360,78.
        let f = fit("abcdefghijklmnop abcdefghijklmnop abcdefghijklmnop abcd")
        XCTAssertEqual(f.size, 42)
        XCTAssertEqual(texts(f), ["abcdefghijklmnop", "abcdefghijklmnop", "abcdefghijklmno\u{2026}"])
        XCTAssertEqual(f.lines.map { $0.truncated }, [false, false, true], "i puntini stanno solo alla fine della terza riga")
        XCTAssertEqual(f.lines[2].width, 360.78, accuracy: 1e-9)
        XCTAssertTrue(f.truncated)
        XCTAssertFalse(f.fits)
        XCTAssertEqual(f.height, 3 * 1.08 * 42, accuracy: 1e-9)
    }

    func testAWordWiderThanTheBoxEvenAtFortyTwoIsCutWithTheEllipsis() {
        // Una parola sola di 26 minuscole: a 42 fa 562,38 > 366. Una riga, chiusa coi puntini come fa `TextFitter`.
        let f = fit("abcdefghijklmnopqrstuvwxyz")
        XCTAssertEqual(f.size, 42)
        XCTAssertEqual(texts(f), ["abcdefghijklmno\u{2026}"])
        XCTAssertTrue(f.truncated)
    }

    func testAnEmptyNameHasNoLines() {
        let f = fit("")
        XCTAssertEqual(f.lineCount, 0)
        XCTAssertFalse(f.truncated)
        XCTAssertEqual(f.height, 0, accuracy: 1e-9)
    }

    // MARK: - La B contro la A del 10/10

    /// La regola A del 10/10 (Solo REV20), rifatta qui solo per il confronto: due righe da 68 a 53; se non sta, tre
    /// righe da 53 a 42.
    private func oldRuleSize(_ name: String) -> Double {
        func spec(_ lines: Int, _ from: Int, _ to: Int) -> TextFitSpec {
            TextFitSpec(styles: [TextFitStyle(fontName: SoloFonts.interExtraBold, trackingEm: -0.035)],
                        runs: [TextRun(text: name, style: 0)],
                        lineHeightFactor: 1.08, maxWidth: 366, maxLines: lines,
                        sizes: TextFitSpec.descending(from: from, to: to))
        }
        let twoLines = TextFitter.fit(spec(2, 68, 53), measurer: m)
        if twoLines.fits { return twoLines.size }
        return TextFitter.fit(spec(3, 53, 42), measurer: m).size
    }

    func testTheBodyIsNeverSmallerThanWithTheRuleOfTheTenth() {
        // Sezione S: «Il corpo della B non è mai più piccolo di quello della A.»
        let names = ["abcdefghij", "abcdefghij abcdefghij", "abcdefgh abcdefgh abcdefgh", "abcde abcde abcde",
                     "abcdefghijk abcdefghijk", "abcdef abcdef abcdef abcdef", "aaaa bbbb cccc dddd eeee ffff gggg hhhh",
                     "abcdefghijklm abcdefghijklm abcdefghijklm", "abcdefghijklmnop abcdefghijklmnop abcdefghijklmnop abcd",
                     "ab-cdefghijklm", "abcdefghijklmnopqrstuvwxyz"]
        for name in names {
            XCTAssertGreaterThanOrEqual(fit(name).size, oldRuleSize(name), name)
        }
        // Sezione S, dove la B cambia: «le frasi che con la A stanno in due righe a un corpo fra 53 e 67». Tre parole di
        // 5 minuscole: due insieme sono larghe 5,415 × corpo: a 68 fanno 368,22 > 366, a 67 fanno 362,805. Con la A: 67
        // in due righe. Con la B: 68 in tre righe.
        XCTAssertEqual(oldRuleSize("abcde abcde abcde"), 67)
        let twoToThree = fit("abcde abcde abcde")
        XCTAssertEqual(twoToThree.size, 68)
        XCTAssertEqual(texts(twoToThree), ["abcde", "abcde", "abcde"])
        // «sia quelle che con la A vanno in tre righe a 53 o meno»: tre parole di 8 minuscole, con la A 53, con la B 68.
        XCTAssertEqual(oldRuleSize("abcdefgh abcdefgh abcdefgh"), 53)
        XCTAssertEqual(fit("abcdefgh abcdefgh abcdefgh").size, 68)
        // «Restano uguali i nomi che con la A sono a 68, in una o due righe».
        XCTAssertEqual(oldRuleSize("abcdefghij abcdefghij"), 68)
        XCTAssertEqual(fit("abcdefghij abcdefghij").size, 68)
    }

    // MARK: - Il fit una volta per nome

    func testTheMemoComputesEachNameOnce() {
        let counting = CountingTextMeasurer()
        let memo = SoloSectionFitMemo()
        let first = memo.fit("abcdefgh abcdefgh abcdefgh", measurer: counting)
        let afterFirst = counting.widthCalls
        XCTAssertGreaterThan(afterFirst, 0)
        XCTAssertEqual(first, fit("abcdefgh abcdefgh abcdefgh"), "il memo rende il fit della regola")
        // Lo stesso nome, cento volte: nessuna misura in più.
        for _ in 0..<100 {
            XCTAssertEqual(memo.fit("abcdefgh abcdefgh abcdefgh", measurer: counting), first)
        }
        XCTAssertEqual(counting.widthCalls, afterFirst)
        // Un nome nuovo si misura; tornando al primo, niente.
        let second = memo.fit("abcdefghij", measurer: counting)
        let afterSecond = counting.widthCalls
        XCTAssertGreaterThan(afterSecond, afterFirst)
        XCTAssertEqual(second.size, 68)
        XCTAssertEqual(memo.fit("abcdefgh abcdefgh abcdefgh", measurer: counting), first)
        XCTAssertEqual(memo.fit("abcdefghij", measurer: counting), second)
        XCTAssertEqual(counting.widthCalls, afterSecond)
    }
}
