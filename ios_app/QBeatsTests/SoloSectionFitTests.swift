import XCTest

// === A401 · SOLO REV20, PUNTO 115 — banco della regola del teleprompter di K, la parte pura (banco Models) ===
// La regola (`SoloVeilTypography.sectionFit`, sopra `TextFitter`): due righe larghe 366, corpi da 68 a 53, vince il
// primo a cui il nome sta; se nemmeno a 53 sta in due righe, tre righe da 53 a 42; a 42 ciò che non sta finisce coi
// puntini, alla fine della terza riga. Qui col misuratore finto di `TextFitterTests` (`FakeTextMeasurer`: minuscole
// 0,55 em, spazio 0,3, trattino 0,35, puntini 0,9, più la spaziatura dopo ogni carattere): con −0,035 em una
// minuscola è larga 0,515 × corpo, lo spazio 0,265, il trattino 0,315, i puntini 0,865. Gli attesi sono derivati
// dalla regola con questi numeri (i conti stanno accanto a ogni caso), non assunti. Gli attesi del foglio, col
// carattere vero, stanno in `TextFitterRealFontTests`. In coda: il fit una volta per nome (`SoloSectionFitMemo`).

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

    // MARK: - Le misure del foglio, pinnate (tabella della sezione R)

    func testTheTwoStepsCarryTheSheetValues() {
        XCTAssertEqual(SoloVeilTypography.sectionMaxSize, 68)
        XCTAssertEqual(SoloVeilTypography.sectionThreeLineSize, 53)
        XCTAssertEqual(SoloVeilTypography.sectionMinSize, 42)
        XCTAssertEqual(SoloVeilTypography.sectionWidth, 366)
        XCTAssertEqual(SoloVeilTypography.sectionBoxHeight, 173)
        let two = SoloVeilTypography.sectionTwoLineSpec("Bridge")
        XCTAssertEqual(two.styles, [TextFitStyle(fontName: "Inter-ExtraBold", trackingEm: -0.035)])
        XCTAssertEqual(two.lineHeightFactor, 1.08)
        XCTAssertEqual(two.maxWidth, 366)
        XCTAssertEqual(two.maxLines, 2)
        XCTAssertEqual(two.sizes, stride(from: 68, through: 53, by: -1).map { Double($0) })
        XCTAssertEqual(two.sizes.count, 16)
        let three = SoloVeilTypography.sectionThreeLineSpec("Bridge")
        XCTAssertEqual(three.styles, two.styles)
        XCTAssertEqual(three.lineHeightFactor, 1.08)
        XCTAssertEqual(three.maxWidth, 366)
        XCTAssertEqual(three.maxLines, 3)
        XCTAssertEqual(three.sizes, stride(from: 53, through: 42, by: -1).map { Double($0) })
        XCTAssertEqual(three.sizes.count, 12)
        XCTAssertEqual(three.runs, [TextRun(text: "Bridge", style: 0)])
    }

    func testThreeLinesAtFiftyThreeAndTwoAtSixtyEightFitTheBox() {
        // Tabella, riga «Riquadro del teleprompter»: «ci stanno tre righe a 53 (3 × 1,08 × 53 = 171,7) e due a 68
        // (146,9)», nel riquadro alto 173.
        XCTAssertEqual(3 * 1.08 * 53, 171.72, accuracy: 1e-9)
        XCTAssertEqual(2 * 1.08 * 68, 146.88, accuracy: 1e-9)
        XCTAssertLessThanOrEqual(3 * 1.08 * 53, SoloVeilTypography.sectionBoxHeight)
    }

    func testWhereTheBlockSitsInTheSheet() {
        // Tabella, riga «Dove sta»: «una riga a 68: 334–407 · due righe a 68: 297–444 · tre righe a 53: 285–456»;
        // dal referee, a un decimale: 333,8–407,2 · 297,1–443,9 · 284,6–456,4. Il riquadro comincia a 284.
        let cases: [(lines: Double, size: Double, top: Double, bottom: Double)] = [
            (1, 68, 333.8, 407.2), (2, 68, 297.1, 443.9), (3, 53, 284.6, 456.4),
        ]
        for c in cases {
            let height = c.lines * 1.08 * c.size
            let top = 284 + SoloVeilTypography.sectionBlockTop(height: height)
            XCTAssertEqual(top, c.top, accuracy: 0.05, "\(c.lines) righe a \(c.size)")
            XCTAssertEqual(top + height, c.bottom, accuracy: 0.05, "\(c.lines) righe a \(c.size)")
            XCTAssertGreaterThanOrEqual(top, 284)
            XCTAssertLessThanOrEqual(top + height, 457)
        }
    }

    // MARK: - Passo 1: due righe, da 68 a 53

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

    func testTheSizeGoesDownOneByOneWhileTwoLinesAreEnough() {
        // 11 minuscole: a 65 fanno 368,225 > 366, a 64 fanno 362,56: il primo corpo a cui la parola sta.
        let f = fit("abcdefghijk abcdefghijk")
        XCTAssertEqual(f.size, 64)
        XCTAssertEqual(texts(f), ["abcdefghijk", "abcdefghijk"])
        XCTAssertEqual(f.lines[0].width, 362.56, accuracy: 1e-9)
        XCTAssertFalse(f.truncated)
        // 13 minuscole: a 55 fanno 368,225, a 54 fanno 361,53: ancora due righe, appena sopra 53.
        let g = fit("abcdefghijklm abcdefghijklm")
        XCTAssertEqual(g.size, 54)
        XCTAssertEqual(g.lineCount, 2)
        XCTAssertEqual(g.lines[0].width, 361.53, accuracy: 1e-9)
    }

    func testAWrittenHyphenIsABreakPoint() {
        // «ab-cdefghijklm»: intero a 68 non sta; dopo il trattino «cdefghijklm» (11 minuscole) sta a 64.
        let f = fit("ab-cdefghijklm")
        XCTAssertEqual(f.size, 64)
        XCTAssertEqual(texts(f), ["ab-", "cdefghijklm"])
        XCTAssertFalse(f.truncated)
    }

    // MARK: - Passo 2: se nemmeno a 53 sta in due righe, tre righe da 53 a 42

    func testWhatDoesNotFitOnTwoLinesAtFiftyThreeGoesOnThreeLinesAtFiftyThree() {
        // Tre parole di 8 minuscole: due insieme a 53 fanno 218,36 × 2 + 14,045 = 450,765 > 366, quindi tre righe a
        // ogni corpo da 68 a 53: in due righe non sta mai. In tre righe sta subito, a 53 (non a 68: il passo 2 parte da 53).
        let f = fit("abcdefgh abcdefgh abcdefgh")
        XCTAssertEqual(f.size, 53)
        XCTAssertEqual(texts(f), ["abcdefgh", "abcdefgh", "abcdefgh"])
        XCTAssertEqual(f.lines[0].width, 218.36, accuracy: 1e-9)
        XCTAssertTrue(f.fits)
        XCTAssertFalse(f.truncated)
        XCTAssertEqual(f.height, 3 * 1.08 * 53, accuracy: 1e-9)
    }

    func testAPhraseFillsThreeLinesAtFiftyThree() {
        // «aaaa bbbb cccc» a 53: 12 × 27,295 + 2 × 14,045 = 355,63 ≤ 366; con la quarta parola no.
        let f = fit("aaaa bbbb cccc dddd eeee ffff gggg hhhh")
        XCTAssertEqual(f.size, 53)
        XCTAssertEqual(texts(f), ["aaaa bbbb cccc", "dddd eeee ffff", "gggg hhhh"])
        XCTAssertEqual(f.lines[0].width, 355.63, accuracy: 1e-9)
        XCTAssertFalse(f.truncated)
    }

    func testTheSizeGoesDownOneByOneOnThreeLines() {
        // 14 minuscole: a 51 fanno 367,71 > 366, a 50 fanno 360,5. 16 minuscole: a 45 fanno 370,8, a 44 fanno 362,56.
        let f = fit("abcdefghijklmn abcdefghijklmn abcdefghijklmn")
        XCTAssertEqual(f.size, 50)
        XCTAssertEqual(f.lineCount, 3)
        XCTAssertEqual(f.lines[0].width, 360.5, accuracy: 1e-9)
        XCTAssertFalse(f.truncated)
        let g = fit("abcdefghijklmnop abcdefghijklmnop abcdefghijklmnop")
        XCTAssertEqual(g.size, 44)
        XCTAssertEqual(g.lineCount, 3)
        XCTAssertEqual(g.lines[0].width, 362.56, accuracy: 1e-9)
        XCTAssertFalse(g.truncated)
    }

    // MARK: - Il pavimento: a 42 i puntini, alla fine della terza riga

    func testAtFortyTwoWhatDoesNotFitEndsWithTheEllipsisOnTheThirdLine() {
        // Quattro parole di 16 minuscole: a 42 ognuna fa 346,08, due insieme non stanno: quattro righe. Restano le
        // prime tre; la terza si chiude coi puntini: «…» fa 36,33, con 16 lettere 382,41 > 366, con 15 fa 360,78.
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
