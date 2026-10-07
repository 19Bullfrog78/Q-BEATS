import XCTest

// === A398 · SOLO-G1-PEZZO-1-M3 — banco del pezzo del testo, la parte pura, con un misuratore finto (banco Models) ===
// A capo solo su spazi e dopo il trattino, mai dentro una parola, ogni riga piena prima di andare a capo; corpo fisso
// coi puntini sulla seconda riga; parola sola più larga del limite; discesa a passi di 1 da 80 a 48, un corpo per due
// righe, anche quando una parola da sola non sta; i puntini a 48; le linee di base a interlinea × corpo col modello
// CSS della mezza interlinea; le altezze dei blocchi (248 → 407 col nome su una riga a 80, 248 → 489 su due righe a
// 80, 26,25 in più con la riga A su due righe; in K due righe a 42 fanno 90,72, centrate nel riquadro di 100).
// Gli attesi sono calcolati a mano sul misuratore finto, scritto qui sotto, e pinnati per valore.

/// Misuratore finto e deterministico: ogni carattere è largo una frazione fissa del corpo (maiuscole 0,7; minuscole
/// e cifre 0,55; spazio 0,3; trattino 0,35; puntini 0,9; altro 0,5), senza crenatura; più la spaziatura dopo ogni
/// carattere, l'ultimo compreso. Metriche verticali: quelle di Inter (1984/2048, 494/2048, spazio 0).
struct FakeTextMeasurer: TextWidthMeasurer {
    func width(of text: String, fontName: String, size: Double, trackingEm: Double) -> Double {
        var em = 0.0
        for ch in text {
            if ch == " " { em += 0.3 }
            else if ch == "-" { em += 0.35 }
            else if ch == "\u{2026}" { em += 0.9 }
            else if ch.isUppercase { em += 0.7 }
            else if ch.isLetter || ch.isNumber { em += 0.55 }
            else { em += 0.5 }
        }
        return em * size + trackingEm * size * Double(text.count)
    }

    func verticalMetrics(fontName: String) -> FontVerticalMetrics {
        FontVerticalMetrics(ascentEm: 1984.0 / 2048.0, descentEm: 494.0 / 2048.0, lineGapEm: 0)
    }
}

final class TextFitterTests: XCTestCase {

    private let m = FakeTextMeasurer()

    private func spec(_ text: String, size: Double, width: Double, lineHeight: Double = 1.0, maxLines: Int = 2,
                      trackingEm: Double = 0, font: String = "Fake") -> TextFitSpec {
        TextFitSpec(styles: [TextFitStyle(fontName: font, trackingEm: trackingEm)],
                    runs: [TextRun(text: text, style: 0)],
                    lineHeightFactor: lineHeight, maxWidth: width, maxLines: maxLines, sizes: [size])
    }

    private func texts(_ f: FittedText) -> [String] { f.lines.map { $0.text } }

    // MARK: - Il misuratore finto, pinnato (così gli attesi sotto si rileggono)

    func testTheFakeMeasurerIsWhatTheExpectationsAssume() {
        XCTAssertEqual(m.width(of: "a b", fontName: "Fake", size: 10, trackingEm: 0), 14, accuracy: 1e-9)
        XCTAssertEqual(m.width(of: "Sixty-", fontName: "Fake", size: 10, trackingEm: 0), 32.5, accuracy: 1e-9)
        XCTAssertEqual(m.width(of: "Verde", fontName: "Fake", size: 80, trackingEm: -0.03), 220, accuracy: 1e-9)
    }

    // MARK: - A capo sugli spazi, ogni riga piena prima di andare a capo

    func testBreaksOnSpacesAndFillsEachLineFirst() {
        // «a b» = 14, «a b c» = 22,5 > 20: la prima riga si riempie fino a «a b», poi «c d».
        let f = TextFitter.fit(spec("a b c d", size: 10, width: 20), measurer: m)
        XCTAssertEqual(texts(f), ["a b", "c d"])
        XCTAssertEqual(f.size, 10)
        XCTAssertTrue(f.fits)
        XCTAssertFalse(f.truncated)
        XCTAssertEqual(f.lines[0].width, 14, accuracy: 1e-9)   // lo spazio dove si va a capo non conta
    }

    func testTwoWordsThatDoNotFitTogetherGoOnTwoLinesAtTheSameSize() {
        // «Verde Rame» a 80 con −0,03 em: 420 > 338; «Verde» 220 e «Rame» 178,4 stanno.
        let f = TextFitter.fit(spec("Verde Rame", size: 80, width: 338, lineHeight: 1.02, trackingEm: -0.03), measurer: m)
        XCTAssertEqual(texts(f), ["Verde", "Rame"])
        XCTAssertTrue(f.fits)
        XCTAssertEqual(f.lines[1].width, 178.4, accuracy: 1e-9)
    }

    // MARK: - Dopo un trattino già scritto, mai dentro una parola, nessun trattino aggiunto

    func testBreaksAfterAWrittenHyphenAndKeepsTheHyphen() {
        // «Sixty-Four» = 56 > 40: «Sixty-» (32,5) / «Four» (23,5).
        let f = TextFitter.fit(spec("Sixty-Four", size: 10, width: 40), measurer: m)
        XCTAssertEqual(texts(f), ["Sixty-", "Four"])
        XCTAssertTrue(f.fits)
        // Con più posto resta una riga sola.
        XCTAssertEqual(texts(TextFitter.fit(spec("Sixty-Four", size: 10, width: 60), measurer: m)), ["Sixty-Four"])
    }

    func testNeverBreaksInsideAWord() {
        // «Lontananza» = 56,5 > 30 e nessun punto d'a capo: resta una riga che sporge, e a corpo fisso si chiude coi
        // puntini: «Lon…» = 27 ≤ 30, «Lont…» = 32,5 > 30.
        let f = TextFitter.fit(spec("Lontananza", size: 10, width: 30), measurer: m)
        XCTAssertEqual(texts(f), ["Lon\u{2026}"])
        XCTAssertTrue(f.truncated)
        XCTAssertFalse(f.fits)
        XCTAssertEqual(f.lines[0].width, 27, accuracy: 1e-9)
        XCTAssertFalse(f.lines[0].text.contains("-"), "nessun trattino aggiunto")
    }

    // MARK: - Corpo fisso: i puntini chiudono la seconda riga

    func testFixedSizeKeepsTwoLinesAndClosesTheSecondWithAnEllipsis() {
        // Tre righe («a b», «c d», «e f»): si tengono le prime due, la seconda chiude con «…»: «c d…» = 23 > 20,
        // togliendo dalla fine resta «c» (lo spazio in coda non resta davanti ai puntini): «c…» = 14,5.
        let f = TextFitter.fit(spec("a b c d e f", size: 10, width: 20), measurer: m)
        XCTAssertEqual(texts(f), ["a b", "c\u{2026}"])
        XCTAssertTrue(f.truncated)
        XCTAssertTrue(f.lines[1].truncated)
        XCTAssertFalse(f.lines[0].truncated)
        XCTAssertFalse(f.fits)
        XCTAssertEqual(f.lineCount, 2)
    }

    func testAFirstLineWiderThanTheLimitIsShortenedToo() {
        // La parola sola più larga del limite sulla prima riga si accorcia e si chiude coi puntini; la seconda riga resta.
        let f = TextFitter.fit(spec("Lontananza b", size: 10, width: 30), measurer: m)
        XCTAssertEqual(texts(f), ["Lon\u{2026}", "b"])
        XCTAssertTrue(f.lines[0].truncated)
        XCTAssertFalse(f.lines[1].truncated)
    }

    func testOneLineAtMostWhenTheSpecSaysSo() {
        let f = TextFitter.fit(spec("a b c d", size: 10, width: 20, maxLines: 1), measurer: m)
        XCTAssertEqual(f.lineCount, 1)
        XCTAssertEqual(texts(f), ["a\u{2026}"])   // «a b…» = 23 > 20; «a…» = 14,5
    }

    // MARK: - La discesa da 80 a 48, un corpo per le due righe

    private func nameSpec(_ text: String) -> TextFitSpec {
        TextFitSpec(styles: [TextFitStyle(fontName: "Fake", trackingEm: -0.03)],
                    runs: [TextRun(text: text, style: 0)],
                    lineHeightFactor: 1.02, maxWidth: 338, maxLines: 2,
                    sizes: TextFitSpec.descending(from: 80, to: 48))
    }

    func testTheSizesDescendByOneFromEightyToFortyEight() {
        let sizes = TextFitSpec.descending(from: 80, to: 48)
        XCTAssertEqual(sizes.count, 33)
        XCTAssertEqual(sizes.first, 80)
        XCTAssertEqual(sizes.last, 48)
        for i in 1..<sizes.count { XCTAssertEqual(sizes[i - 1] - sizes[i], 1) }
    }

    func testAWordWiderThanTheLineMakesTheSizeDescendUntilItFits() {
        // «Lontananza»: 5,65 em − 0,3 em di spaziatura = 5,35 em; 5,35 × s ≤ 338 ⇒ s ≤ 63,18 ⇒ 63.
        let f = TextFitter.fit(nameSpec("Lontananza"), measurer: m)
        XCTAssertEqual(f.size, 63)
        XCTAssertEqual(texts(f), ["Lontananza"])
        XCTAssertTrue(f.fits)
        XCTAssertFalse(f.truncated)
        XCTAssertLessThanOrEqual(f.lines[0].width, 338)
        // A 64 non starebbe: 5,35 × 64 = 342,4.
        XCTAssertGreaterThan(m.width(of: "Lontananza", fontName: "Fake", size: 64, trackingEm: -0.03), 338)
    }

    func testOneSizeForBothLinesEvenWhenOneWordAloneDoesNotFit() {
        // «Lontananza Verde»: a 80 la prima parola da sola non sta; si scende finché tutte e due le righe stanno
        // allo stesso corpo: 63, «Lontananza» / «Verde».
        let f = TextFitter.fit(nameSpec("Lontananza Verde"), measurer: m)
        XCTAssertEqual(f.size, 63)
        XCTAssertEqual(texts(f), ["Lontananza", "Verde"])
        XCTAssertTrue(f.fits)
    }

    func testAtFortyEightWhatDoesNotFitEndsWithAnEllipsisOnTheSecondLine() {
        // Quattro parole che non stanno in due righe a nessun corpo: a 48, «Lontananza» / «lontananza…».
        let f = TextFitter.fit(nameSpec("Lontananza lontananza lontananza lontananza"), measurer: m)
        XCTAssertEqual(f.size, 48)
        XCTAssertEqual(f.lineCount, 2)
        XCTAssertEqual(texts(f), ["Lontananza", "lontananza\u{2026}"])
        XCTAssertTrue(f.truncated)
        XCTAssertFalse(f.fits)
        XCTAssertLessThanOrEqual(f.lines[1].width, 338)
    }

    func testAShortNameStaysAtEightyOnOneLine() {
        let f = TextFitter.fit(nameSpec("Circuz"), measurer: m)
        XCTAssertEqual(f.size, 80)
        XCTAssertEqual(texts(f), ["Circuz"])
        XCTAssertTrue(f.fits)
    }

    // MARK: - Pezzi con veste diversa nella stessa riga (la riga A di H)

    func testARunOfPiecesWithDifferentStylesWrapsAsOneLineAndKeepsTheStyles() {
        // «Resume from » (veste 0) + «Bridge attenzione vai piano» (veste 1), a 10 con limite 90: «Resume from Bridge
        // attenzione» = ? «Resume» 0,7+5×0,55 = 3,45; « » 0,3; «from» 2,2; « » 0,3; «Bridge» 0,7+5×0,55 = 3,45;
        // « attenzione» 0,3+10×0,55 = 5,8 ⇒ 15,5 em = 155 > 90. «Resume from Bridge» = 9,7 em = 97 > 90.
        // «Resume from» = 5,95 em = 59,5 ⇒ riga 1 «Resume from» (lo spazio in coda non conta), riga 2 «Bridge
        // attenzione» = 9,25 em = 92,5 > 90 ⇒ «Bridge» / «attenzione vai piano»… tre righe: la seconda chiude coi puntini.
        let s = TextFitSpec(styles: [TextFitStyle(fontName: "Fake", trackingEm: 0), TextFitStyle(fontName: "Fake", trackingEm: 0)],
                            runs: [TextRun(text: "Resume from ", style: 0), TextRun(text: "Bridge attenzione vai piano", style: 1)],
                            lineHeightFactor: 1.25, maxWidth: 90, maxLines: 2, sizes: [10])
        let f = TextFitter.fit(s, measurer: m)
        XCTAssertEqual(f.lineCount, 2)
        XCTAssertEqual(f.lines[0].text, "Resume from")
        XCTAssertEqual(f.lines[0].runs, [TextRun(text: "Resume from", style: 0)])
        XCTAssertTrue(f.lines[1].text.hasSuffix("\u{2026}"))
        XCTAssertEqual(f.lines[1].runs.first?.style, 1)
        // Con più posto, la sezione resta nella sua veste sulla stessa riga della frase.
        let wide = TextFitSpec(styles: s.styles, runs: s.runs, lineHeightFactor: 1.25, maxWidth: 400, maxLines: 2, sizes: [10])
        let g = TextFitter.fit(wide, measurer: m)
        XCTAssertEqual(g.lineCount, 1)
        XCTAssertEqual(g.lines[0].runs, [TextRun(text: "Resume from ", style: 0),
                                         TextRun(text: "Bridge attenzione vai piano", style: 1)])
    }

    func testTheSpaceBetweenTwoStylesIsMeasuredInTheStyleItComesFrom() {
        // Nei pezzi «Resume from » + «Bridge» lo spazio sta nel primo pezzo: nella riga torna lì, non nel secondo.
        let s = TextFitSpec(styles: [TextFitStyle(fontName: "Fake", trackingEm: 0), TextFitStyle(fontName: "Fake", trackingEm: 0)],
                            runs: [TextRun(text: "Resume from ", style: 0), TextRun(text: "Bridge", style: 1)],
                            lineHeightFactor: 1.25, maxWidth: 400, maxLines: 2, sizes: [21])
        let f = TextFitter.fit(s, measurer: m)
        XCTAssertEqual(f.lines[0].runs, [TextRun(text: "Resume from ", style: 0), TextRun(text: "Bridge", style: 1)])
    }

    // MARK: - Le linee di base: interlinea × corpo, mezza interlinea sopra e sotto

    func testBaselinesFollowTheHalfLeadingModel() {
        // A 80 con interlinea 1,02: riga alta 81,6; A = 77,5; D = 19,296875; mezza interlinea (81,6 − 96,796875)/2 =
        // −7,5984375 (negativa: l'interlinea è più stretta del carattere); linea di base 69,9015625, poi +81,6.
        let f = TextFitter.fit(nameSpec("Verde Rame"), measurer: m)
        XCTAssertEqual(f.size, 80)
        XCTAssertEqual(f.lineCount, 2)
        XCTAssertEqual(f.lineHeight, 81.6, accuracy: 1e-9)
        XCTAssertEqual(f.height, 163.2, accuracy: 1e-9)
        XCTAssertEqual(f.baselines[0], 69.9015625, accuracy: 1e-9)
        XCTAssertEqual(f.baselines[1], 69.9015625 + 81.6, accuracy: 1e-9)
    }

    func testBaselinesWithAnInterlineWiderThanTheFont() {
        // A 21 con interlinea 1,25: riga 26,25; A = 20,34375; D = 5,0654296875; mezza interlinea
        // (26,25 − 25,4091796875)/2 = 0,42041015625; linea di base 20,76416015625.
        let f = TextFitter.fit(spec("Next", size: 21, width: 338, lineHeight: 1.25), measurer: m)
        let a = 1984.0 / 2048.0 * 21
        let d = 494.0 / 2048.0 * 21
        XCTAssertEqual(f.lineCount, 1)
        XCTAssertEqual(f.baselines[0], (26.25 - (a + d)) / 2 + a, accuracy: 1e-9)
        XCTAssertEqual(f.baselines[0], 20.76416015625, accuracy: 1e-9)
        XCTAssertEqual(f.height, 26.25, accuracy: 1e-9)
    }

    func testAnEmptyTextIsZeroLinesAndZeroHeight() {
        let f = TextFitter.fit(spec("", size: 42, width: 366, lineHeight: 1.08), measurer: m)
        XCTAssertEqual(f.lineCount, 0)
        XCTAssertEqual(f.height, 0)
        XCTAssertTrue(f.fits)
        XCTAssertEqual(f.baselines, [])
    }

    func testSpacesOnlyTextIsZeroLines() {
        let f = TextFitter.fit(spec("   ", size: 42, width: 366, lineHeight: 1.08), measurer: m)
        XCTAssertEqual(f.lineCount, 0)
    }

    // MARK: - Le altezze dei blocchi del foglio

    func testTheVeilBlockHeightsOfTheSheet() {
        // 248 → 407 col nome su una riga a 80; 248 → 489 su due righe a 80; 26,25 in più con la riga A su due righe.
        let one = SoloVeilTypography.blockHeight(relationLines: 1, nameLines: 1, nameSize: 80)
        XCTAssertEqual(one, 26.25 + 14 + 81.6 + 12 + 25.2, accuracy: 1e-9)
        XCTAssertEqual(SoloVeilTypography.blockTop + one, 407, accuracy: 0.1)
        let two = SoloVeilTypography.blockHeight(relationLines: 1, nameLines: 2, nameSize: 80)
        XCTAssertEqual(SoloVeilTypography.blockTop + two, 489, accuracy: 0.4)
        XCTAssertEqual(two - one, 81.6, accuracy: 1e-9)
        let relationTwo = SoloVeilTypography.blockHeight(relationLines: 2, nameLines: 2, nameSize: 80)
        XCTAssertEqual(relationTwo - two, 26.25, accuracy: 1e-9)
        // La stessa altezza dalle tre scritte decise.
        let relation = TextFitter.fit(SoloVeilTypography.relationSpec(prefix: "Next", section: nil), measurer: m)
        let name = TextFitter.fit(nameSpec("Verde Rame"), measurer: m)
        let tempo = TextFitter.fit(SoloVeilTypography.tempoSpec("108 \u{00B7} 4/4"), measurer: m)
        XCTAssertEqual(SoloVeilTypography.blockHeight(relation: relation, name: name, tempo: tempo), two, accuracy: 1e-9)
        XCTAssertEqual(SoloVeilTypography.nameTop(relation: relation), 26.25 + 14, accuracy: 1e-9)
        XCTAssertEqual(SoloVeilTypography.tempoTop(relation: relation, name: name), 26.25 + 14 + 163.2 + 12, accuracy: 1e-9)
    }

    func testTheSectionBlockOfKIsCenteredInTheHundredBox() {
        // Due righe a 42 con interlinea 1,08 fanno 90,72, centrate nel riquadro di 100: cominciano a 4,64.
        let f = TextFitter.fit(spec("Bridge attenzione vai piano", size: 42, width: 200, lineHeight: 1.08, trackingEm: -0.035), measurer: m)
        XCTAssertEqual(f.lineCount, 2)
        XCTAssertEqual(f.height, 90.72, accuracy: 1e-9)
        XCTAssertEqual(SoloVeilTypography.sectionBlockTop(height: f.height), 4.64, accuracy: 1e-9)
        XCTAssertEqual(SoloVeilTypography.sectionBlockTop(height: 45.36), (100 - 45.36) / 2, accuracy: 1e-9)
    }

    // MARK: - Le vesti del foglio, pinnate

    func testTheSheetSpecsCarryTheSheetValues() {
        let name = SoloVeilTypography.nameSpec("Circuz")
        XCTAssertEqual(name.styles, [TextFitStyle(fontName: "Inter-Black", trackingEm: -0.03)])
        XCTAssertEqual(name.lineHeightFactor, 1.02)
        XCTAssertEqual(name.maxWidth, 338)
        XCTAssertEqual(name.maxLines, 2)
        XCTAssertEqual(name.sizes.first, 80)
        XCTAssertEqual(name.sizes.last, 48)
        let section = SoloVeilTypography.sectionSpec("Bridge")
        XCTAssertEqual(section.styles, [TextFitStyle(fontName: "Inter-ExtraBold", trackingEm: -0.035)])
        XCTAssertEqual(section.lineHeightFactor, 1.08)
        XCTAssertEqual(section.maxWidth, 366)
        XCTAssertEqual(section.sizes, [42])
        let relation = SoloVeilTypography.relationSpec(prefix: "Resume from ", section: "Bridge")
        XCTAssertEqual(relation.styles.map { $0.fontName }, ["Inter-SemiBold", "Inter-Bold"])
        XCTAssertEqual(relation.runs, [TextRun(text: "Resume from ", style: 0), TextRun(text: "Bridge", style: 1)])
        XCTAssertEqual(relation.lineHeightFactor, 1.25)
        XCTAssertEqual(relation.sizes, [21])
        XCTAssertEqual(SoloVeilTypography.relationSpec(prefix: "Next", section: nil).runs, [TextRun(text: "Next", style: 0)])
        let tempo = SoloVeilTypography.tempoSpec("121 \u{00B7} 4/4")
        XCTAssertEqual(tempo.styles, [TextFitStyle(fontName: "JetBrainsMono-Medium", trackingEm: 0)])
        XCTAssertEqual(tempo.lineHeightFactor, 1.2)
        XCTAssertEqual(tempo.maxLines, 1)
        let endShow = SoloVeilTypography.endShowSpec(width: 390)
        XCTAssertEqual(endShow.styles, [TextFitStyle(fontName: "Inter-Black", trackingEm: -0.02)])
        XCTAssertEqual(endShow.lineHeightFactor, 1.0)
        XCTAssertEqual(endShow.sizes, [44])
        XCTAssertEqual(endShow.runs, [TextRun(text: "END SHOW", style: 0)])
    }

    func testEndShowBaselineSitsAsTheRefereeMeasured() {
        // END SHOW a 44 con interlinea 1: A + D = 53,2 (1,21 em); mezza interlinea −4,6: la linea di base sta a
        // 44 − 19,296875/2 … = 38,0 dall'alto della riga, cioè la scritta «scende» di circa 4,6 rispetto al carattere
        // appoggiato a 360 (misura del referee sulle metriche di Inter-Black).
        let f = TextFitter.fit(SoloVeilTypography.endShowSpec(width: 390), measurer: m)
        XCTAssertEqual(f.lineCount, 1)
        XCTAssertEqual(f.height, 44, accuracy: 1e-9)
        let a = 1984.0 / 2048.0 * 44
        let d = 494.0 / 2048.0 * 44
        XCTAssertEqual(f.baselines[0], (44 - (a + d)) / 2 + a, accuracy: 1e-9)
        XCTAssertEqual((a + d) - 44, 9.23828125, accuracy: 1e-9)   // 2 × 4,62: la scritta scende di circa 4,6
    }
}
