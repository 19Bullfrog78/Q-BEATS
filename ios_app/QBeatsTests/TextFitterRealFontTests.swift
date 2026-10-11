import XCTest
import CoreText

// === A398 · SOLO-G1-PEZZO-1-M3 — banco del pezzo del testo coi caratteri veri (CoreText sui .ttf in bundle) ===
// I caratteri stanno fra le risorse del bersaglio QBeatsTests (`ios_app/project.yml`) e si registrano nel processo
// con `CTFontManagerRegisterFontsForURL`. Il misuratore è quello dell'app (`CoreTextWidthMeasurer`): la
// convenzione (avanzamenti con la crenatura + spaziatura dopo ogni carattere, l'ultimo compreso; limite esatto) è
// quella del mandato M3 §3.6, verificata sui quattro valori del registro della REV18 e sulle attese del referee.
// Il banco cade se un carattere non si risolve (CoreText darebbe un altro carattere senza dirlo).

final class TextFitterRealFontTests: XCTestCase {

    private static let fontFiles = ["Inter-Black", "Inter-ExtraBold", "Inter-Bold", "Inter-SemiBold", "JetBrainsMono-Medium"]

    private static let registered: [String] = {
        let bundle = Bundle(for: TextFitterRealFontTests.self)
        var done: [String] = []
        for name in fontFiles {
            guard let url = bundle.url(forResource: name, withExtension: "ttf") else { continue }
            // L'esito della registrazione non decide niente qui (un carattere già registrato rende falso): decide
            // `resolves(_:)` del misuratore, nel primo banco sotto.
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            done.append(name)
        }
        return done
    }()

    private let m = CoreTextWidthMeasurer()

    override func setUp() {
        super.setUp()
        _ = Self.registered
    }

    private func texts(_ f: FittedText) -> [String] { f.lines.map { $0.text } }

    // MARK: - I caratteri sono quelli chiesti

    func testTheFiveFontsResolveToThemselves() {
        XCTAssertEqual(Set(Self.registered), Set(Self.fontFiles), "caratteri non trovati fra le risorse del banco")
        for name in SoloFonts.all {
            XCTAssertTrue(m.resolves(name), "CoreText non dà \(name)")
        }
        XCTAssertFalse(m.resolves("Carattere-Che-Non-Esiste"))
    }

    func testTheVerticalMetricsAreReadFromTheFont() {
        // Inter: ascendente 1984, discendente 494, spazio 0, su 2048 (hhea = OS/2 typo). JetBrains Mono: 1020, 300 su 1000.
        let inter = m.verticalMetrics(fontName: SoloFonts.interExtraBold)
        XCTAssertEqual(inter.ascentEm, 1984.0 / 2048.0, accuracy: 0.0005)
        XCTAssertEqual(inter.descentEm, 494.0 / 2048.0, accuracy: 0.0005)
        XCTAssertEqual(inter.contentHeightEm * 42, 50.82, accuracy: 0.05)   // due righe a 42: 101,6 col carattere, 90,72 col foglio
        let mono = m.verticalMetrics(fontName: SoloFonts.jetBrainsMonoMedium)
        XCTAssertEqual(mono.ascentEm, 1.02, accuracy: 0.0005)
        XCTAssertEqual(mono.descentEm, 0.30, accuracy: 0.0005)
    }

    // MARK: - I quattro valori del registro della REV18 (norma)

    func testVerdeRameIsEightyOnTwoLines() {
        let f = TextFitter.fit(SoloVeilTypography.nameSpec("Verde Rame"), measurer: m)
        XCTAssertEqual(f.size, 80, "larghezze: \(f.lines.map { $0.width })")
        XCTAssertEqual(texts(f), ["Verde", "Rame"])
        XCTAssertFalse(f.truncated)
    }

    func testLontananzaIsSixtyOnOneLine() {
        // Con la spaziatura dopo l'ultimo carattere «Lontananza» a 60 misura 337,37 ≤ 338 (senza, 339,17: scenderebbe a 59).
        let f = TextFitter.fit(SoloVeilTypography.nameSpec("Lontananza"), measurer: m)
        XCTAssertEqual(f.size, 60, "larghezze: \(f.lines.map { $0.width })")
        XCTAssertEqual(texts(f), ["Lontananza"])
        XCTAssertEqual(f.lines[0].width, 337.37, accuracy: 0.25)
        XCTAssertGreaterThan(m.width(of: "Lontananza", fontName: SoloFonts.interBlack, size: 61, trackingEm: -0.03), 338)
    }

    func testIlCieloInUnaStanzaIsSixtyFourOnTwoLines() {
        let f = TextFitter.fit(SoloVeilTypography.nameSpec("Il cielo in una stanza"), measurer: m)
        XCTAssertEqual(f.size, 64, "larghezze: \(f.lines.map { $0.width })")
        XCTAssertEqual(texts(f), ["Il cielo in", "una stanza"])
        XCTAssertFalse(f.truncated)
    }

    func testTheLongestNameIsFortyEightWithAnEllipsis() {
        let f = TextFitter.fit(SoloVeilTypography.nameSpec("La canzone lunghissima che non finisce mai"), measurer: m)
        XCTAssertEqual(f.size, 48, "larghezze: \(f.lines.map { $0.width })")
        XCTAssertEqual(texts(f), ["La canzone", "lunghissima\u{2026}"])
        XCTAssertTrue(f.truncated)
        XCTAssertLessThanOrEqual(f.lines[1].width, 338)
    }

    func testCircuzIsEightyOnOneLine() {
        let f = TextFitter.fit(SoloVeilTypography.nameSpec("Circuz"), measurer: m)
        XCTAssertEqual(f.size, 80)
        XCTAssertEqual(texts(f), ["Circuz"])
    }

    // MARK: - Le attese del referee (mandato M3 §3.6)

    // ⚠️ A401 (10/10/2026) — qui stava `testTheSectionOfKWrapsAsTheRefereeExpects`: «Bridge attenzione vai piano» a 42
    //    fisso su due righe (punto 51). Con la Solo REV20 (punto 115) quel nome esce a 53 su tre righe: il banco della
    //    sezione di K è in fondo a questo file («A401 · Solo REV20, punto 115»).
    // ⚠️ A403 (11/10/2026) — con la Solo REV22 quel nome esce a 68 su tre righe (regola B, punto 119): in fondo al file
    //    il banco è «A403 · Solo REV22, punti 115 e 119», e dopo di lui quello del nome in testata (punto 118).

    func testTheRelationLineOfHWrapsAsTheRefereeExpects() {
        // «Resume from Bridge attenzione vai piano» a 21 in 338: «Resume from Bridge attenzione» / «vai piano».
        let f = TextFitter.fit(SoloVeilTypography.relationSpec(prefix: "Resume from ", section: "Bridge attenzione vai piano"),
                               measurer: m)
        XCTAssertEqual(texts(f), ["Resume from Bridge attenzione", "vai piano"], "larghezze: \(f.lines.map { $0.width })")
        XCTAssertEqual(f.lines[0].runs, [TextRun(text: "Resume from ", style: 0), TextRun(text: "Bridge attenzione", style: 1)])
        XCTAssertEqual(f.lines[1].runs, [TextRun(text: "vai piano", style: 1)])
        XCTAssertFalse(f.truncated)
    }

    func testTwoBravoSixtyFourBarsBreaksAfterTheHyphenAtFiftyOne() {
        // Decisione del referee sul trattino: «2 Bravo Sixty-» / «Four Bars» a 51 (336,3 ≤ 338); senza quell'a capo
        // scenderebbe a 48 coi puntini.
        let f = TextFitter.fit(SoloVeilTypography.nameSpec("2 Bravo Sixty-Four Bars"), measurer: m)
        XCTAssertEqual(f.size, 51, "larghezze: \(f.lines.map { $0.width })")
        XCTAssertEqual(texts(f), ["2 Bravo Sixty-", "Four Bars"])
        XCTAssertFalse(f.truncated)
    }

    // MARK: - Controllo indipendente sugli altri nomi della scaletta COLLAUDO SOLO G1 (misure del referee, non norma)

    func testTheOtherNamesOfTheTestSetlistAsTheRefereeMeasured() {
        let alfa = TextFitter.fit(SoloVeilTypography.nameSpec("1 Alfa 7/8"), measurer: m)
        XCTAssertEqual(alfa.size, 80, "1 Alfa 7/8 larghezze: \(alfa.lines.map { $0.width })")
        XCTAssertEqual(alfa.lineCount, 2)
        let charlie = TextFitter.fit(SoloVeilTypography.nameSpec("3 Charlie 12/8"), measurer: m)
        XCTAssertEqual(charlie.size, 79, "3 Charlie 12/8 larghezze: \(charlie.lines.map { $0.width })")   // «3 Charlie» a 80 misura 339,14: caso al limite
        XCTAssertEqual(charlie.lineCount, 2)
        let delta = TextFitter.fit(SoloVeilTypography.nameSpec("4 Delta 11/8"), measurer: m)
        XCTAssertEqual(delta.size, 80, "4 Delta 11/8 larghezze: \(delta.lines.map { $0.width })")
        XCTAssertEqual(delta.lineCount, 2)
        let echo = TextFitter.fit(SoloVeilTypography.nameSpec("5 Echo"), measurer: m)
        XCTAssertEqual(echo.size, 80, "5 Echo larghezze: \(echo.lines.map { $0.width })")
        XCTAssertEqual(echo.lineCount, 1)
    }

    func testNotturnoIsSeventyEightBecauseTheLimitIsExact() {
        // «Notturno» a 79 misura 339,01 > 338: nell'app 78 (lo script del foglio tollera 1 px: lì 79). Voluto.
        XCTAssertGreaterThan(m.width(of: "Notturno", fontName: SoloFonts.interBlack, size: 79, trackingEm: -0.03), 338)
        let f = TextFitter.fit(SoloVeilTypography.nameSpec("Notturno"), measurer: m)
        XCTAssertEqual(f.size, 78, "larghezze: \(f.lines.map { $0.width })")
        XCTAssertEqual(f.lineCount, 1)
    }

    // MARK: - A403 · Solo REV22, punti 115 e 119: il teleprompter di K con la regola B
    // ⚠️ Qui stava il banco «A401 · Solo REV20, punto 115» (la regola A: due righe da 68 a 53, poi tre righe da 53 a
    //    42, nel riquadro 284–457). Con la Solo REV22 la regola è la B e il riquadro va da 284 a 508: gli attesi della
    //    A sono usciti con lei.
    // Gli attesi sono del foglio (`DESIGN/QLive_Nav/2026-10-11_QLive-Player_G1-SOLO-REV22_390x844_1.html`, sezione S, tavola
    // dei casi; sezione R, schermi e tabella) e del referee (mandato A403 §4.2 d: misura dell'11/10 con
    // `Inter-ExtraBold.ttf` dell'app, HarfBuzz sul file del repo, in punti del foglio). Se un atteso non torna il banco
    // cade e si riporta la misura: non si aggiusta l'atteso.

    private func section(_ name: String) -> FittedText {
        SoloVeilTypography.sectionFit(name, measurer: m)
    }

    /// Dove sta il blocco, in coordinate del foglio: il riquadro va da 284 a 508, il centro è a 396.
    private func blockSpan(_ f: FittedText) -> (top: Double, bottom: Double) {
        let top = 284 + SoloVeilTypography.sectionBlockTop(height: f.height)
        return (top, top + f.height)
    }

    /// Le righe di base, in coordinate del foglio.
    private func sheetBaselines(_ f: FittedText) -> [Double] {
        let top = blockSpan(f).top
        return f.baselines.map { top + $0 }
    }

    private func describe(_ f: FittedText) -> String {
        "corpo \(f.size), righe \(f.lines.map { "\($0.text) (\($0.width))" })"
    }

    /// Blocco e righe di base contro gli attesi del referee, dati a un decimale: ± 0,05 sul blocco (è solo aritmetica:
    /// righe × 1,08 × corpo, al centro di 284–508) e ± 0,06 sulle righe di base, che dipendono anche dalle metriche del
    /// carattere. E contro la tavola della sezione S, che dà gli stessi numeri arrotondati all'intero.
    private func assertBlock(_ f: FittedText, top: Double, bottom: Double, baselines: [Double], sheet: [Double],
                             _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let span = blockSpan(f)
        XCTAssertEqual(span.top, top, accuracy: 0.05, "\(name): \(describe(f))", file: file, line: line)
        XCTAssertEqual(span.bottom, bottom, accuracy: 0.05, "\(name): \(describe(f))", file: file, line: line)
        XCTAssertEqual((span.top + span.bottom) / 2, 396, accuracy: 1e-6, "\(name): il blocco sta al centro", file: file, line: line)
        XCTAssertGreaterThanOrEqual(span.top, 284, name, file: file, line: line)
        XCTAssertLessThanOrEqual(span.bottom, 508, name, file: file, line: line)
        let bases = sheetBaselines(f)
        XCTAssertEqual(bases.count, baselines.count, "\(name): \(bases)", file: file, line: line)
        for (got, want) in zip(bases, baselines) {
            XCTAssertEqual(got, want, accuracy: 0.06, "\(name): righe di base \(bases)", file: file, line: line)
        }
        XCTAssertEqual(bases.map { $0.rounded() }, sheet, "\(name): la tavola della sezione S", file: file, line: line)
    }

    func testTheShortSectionNamesAreSixtyEightOnOneLine() {
        // R2 «Verse» e R12 «Section 6»: 68, una riga. Tavola della sezione S: «una riga a 68 · 359–433 · alto 73,4»,
        // riga di base 421.
        for name in ["Verse", "Section 6"] {
            let f = section(name)
            XCTAssertEqual(f.size, 68, "\(name): \(describe(f))")
            XCTAssertEqual(texts(f), [name])
            XCTAssertFalse(f.truncated)
            assertBlock(f, top: 359.3, bottom: 432.7, baselines: [420.7], sheet: [421], name)
            XCTAssertEqual(blockSpan(f).top.rounded(), 359)
            XCTAssertEqual(blockSpan(f).bottom.rounded(), 433)
            // «il blocco finisce 29 sopra il pannello» (462).
            XCTAssertEqual((462 - blockSpan(f).bottom).rounded(), 29)
        }
    }

    func testPreChorusIsSixtyEightOnTwoLinesAfterTheHyphen() {
        // R3: «Pre-» / «Chorus», a capo dopo il trattino già scritto; in una riga a 68 servirebbero 366,67 su 366.
        // Tavola S: «due righe a 68 · 323–469», righe di base 384 e 457.
        let f = section("Pre-Chorus")
        XCTAssertEqual(f.size, 68, describe(f))
        XCTAssertEqual(texts(f), ["Pre-", "Chorus"])
        XCTAssertFalse(f.truncated)
        assertBlock(f, top: 322.6, bottom: 469.4, baselines: [384.0, 457.5], sheet: [384, 457], "Pre-Chorus")
    }

    func testStaccoVeloceAndBridgeVaiPianoAreSixtyEightOnTwoLines() {
        // R5 e R7: due righe a 68, da 323 a 469.
        let expected: [(name: String, lines: [String])] = [
            ("Stacco veloce", ["Stacco", "veloce"]), ("Bridge vai piano", ["Bridge vai", "piano"]),
        ]
        for e in expected {
            let f = section(e.name)
            XCTAssertEqual(f.size, 68, "\(e.name): \(describe(f))")
            XCTAssertEqual(texts(f), e.lines, "\(e.name): \(describe(f))")
            XCTAssertFalse(f.truncated)
            assertBlock(f, top: 322.6, bottom: 469.4, baselines: [384.0, 457.5], sheet: [384, 457], e.name)
        }
    }

    func testBridgeAttenzioneVaiPianoIsSixtyEightOnThreeLines() {
        // R4 e, col Mixer aperto, R11: con la B «Bridge / attenzione / vai piano» a 68, da 286 a 506 (con la A era 53).
        // Tavola S: «tre righe a 68 · 286–506 · alto 220,3 · 10 sopra Next», righe di base 347, 421 e 494; col Mixer
        // aperto «la terza ha la base 32 sotto il bordo».
        let f = section("Bridge attenzione vai piano")
        XCTAssertEqual(f.size, 68, describe(f))
        XCTAssertEqual(texts(f), ["Bridge", "attenzione", "vai piano"], describe(f))
        XCTAssertFalse(f.truncated)
        XCTAssertTrue(f.lines.allSatisfy { $0.width <= 366 }, describe(f))
        assertBlock(f, top: 285.8, bottom: 506.2, baselines: [347.3, 420.7, 494.2], sheet: [347, 421, 494],
                    "Bridge attenzione vai piano")
        XCTAssertEqual((516 - blockSpan(f).bottom).rounded(), 10)
        XCTAssertEqual((sheetBaselines(f)[2] - 462).rounded(), 32)
    }

    func testCominciaIlCantoIsFiftySevenOnThreeLines() {
        // R9 e, col Mixer aperto, R13: 57, da 304 a 488. La ferma «three two one»: a 58 sarebbe larga 366,9 su 366.
        // Tavola S: «tre righe a 57 · 304–488 · alto 184,7», righe di base 355, 417 e 478; col Mixer aperto «la terza
        // ha la base 16 sotto il bordo».
        let f = section("comincia il canto four three two one")
        XCTAssertEqual(f.size, 57, describe(f))
        XCTAssertEqual(texts(f), ["comincia il", "canto four", "three two one"], describe(f))
        XCTAssertFalse(f.truncated)
        XCTAssertTrue(f.lines.allSatisfy { $0.width <= 366 }, describe(f))
        assertBlock(f, top: 303.7, bottom: 488.3, baselines: [355.2, 416.7, 478.3], sheet: [355, 417, 478],
                    "comincia il canto four three two one")
        XCTAssertEqual((sheetBaselines(f)[2] - 462).rounded(), 16)
    }

    func testTheLongNameOfRevThreeIsFortyFourOnThreeLines() {
        // R6, 54 caratteri: 44, tre righe, senza puntini.
        let f = section("Bridge attenzione vai piano poi stop secco sul quattro")
        XCTAssertEqual(f.size, 44, describe(f))
        XCTAssertEqual(texts(f), ["Bridge attenzione", "vai piano poi stop", "secco sul quattro"], describe(f))
        XCTAssertFalse(f.truncated)
        XCTAssertTrue(f.lines.allSatisfy { $0.width <= 366 }, describe(f))
    }

    func testANameThatDoesNotFitAtFortyTwoEndsWithTheEllipsisOnTheThirdLine() {
        // R10 e, col Mixer aperto, R15: 51 caratteri; a 42 servirebbero quattro righe: la terza si chiude coi puntini
        // di `TextFitter`, «battute poi…». Tavola S: «tre righe a 42, coi puntini · 328–464 · alto 136,1», righe di
        // base 366, 411 e 457; col Mixer aperto «la terza ha la base 5 sopra il bordo».
        let f = section("entra la voce piano, quattro battute poi ritornello")
        XCTAssertEqual(f.size, 42, describe(f))
        XCTAssertEqual(texts(f), ["entra la voce", "piano, quattro", "battute poi\u{2026}"], describe(f))
        XCTAssertTrue(f.truncated)
        XCTAssertEqual(f.lines.map { $0.truncated }, [false, false, true])
        XCTAssertTrue(f.lines.allSatisfy { $0.width <= 366 }, describe(f))
        assertBlock(f, top: 328.0, bottom: 464.0, baselines: [365.9, 411.3, 456.6], sheet: [366, 411, 457],
                    "entra la voce piano, quattro battute poi ritornello")
        XCTAssertEqual((462 - sheetBaselines(f)[2]).rounded(), 5)
    }

    func testFiftyTwoCharactersStillFitAtFortyTwoOnThreeLines() {
        // Didascalia di R10: questo nome, di 52 caratteri, «sta ancora a 42 in tre righe».
        let f = section("entra la voce, quattro battute poi ritornello e stop")
        XCTAssertEqual(f.size, 42, describe(f))
        XCTAssertEqual(texts(f), ["entra la voce,", "quattro battute poi", "ritornello e stop"], describe(f))
        XCTAssertFalse(f.truncated)
        XCTAssertTrue(f.lines.allSatisfy { $0.width <= 366 }, describe(f))
    }

    func testTheFourWidthsWithinOnePointOfTheLimit() {
        // Quattro casi a meno di un punto da 366 (misura del referee: 366,89 · 366,67 · 366,93 · 366,66): decidono il
        // corpo o l'a capo dei nomi qui sopra. La larghezza di CoreText si stampa nel log della CI, per il referto.
        let cases: [(text: String, size: Double, referee: Double)] = [
            ("three two one", 58, 366.89), ("Pre-Chorus", 68, 366.67), ("Bridge attenzione", 45, 366.93),
            ("quattro battute poi", 43, 366.66),
        ]
        for c in cases {
            let w = m.width(of: c.text, fontName: SoloFonts.interExtraBold, size: c.size, trackingEm: -0.035)
            let below = m.width(of: c.text, fontName: SoloFonts.interExtraBold, size: c.size - 1, trackingEm: -0.035)
            print("[A403][CORETEXT] sezione «\(c.text)» a \(Int(c.size)) = \(String(format: "%.4f", w)); a \(Int(c.size) - 1) = \(String(format: "%.4f", below))")
            XCTAssertGreaterThan(w, 366, "«\(c.text)» a \(c.size): \(w)")
            XCTAssertLessThan(w, 367, "«\(c.text)» a \(c.size): \(w)")
            XCTAssertEqual(w, c.referee, accuracy: 0.05, "«\(c.text)» a \(c.size): \(w)")
            XCTAssertLessThanOrEqual(below, 366, "«\(c.text)» a \(c.size - 1): \(below)")
        }
    }

    // MARK: - A403 · Solo REV22, punto 118: il nome lungo in testata
    // La regola: `SoloHeaderTitle.fit`, sopra `TextFitter`: Inter 700, spaziatura −0,01 em, una riga larga 254, da 24 a
    // 17 a scendere di 1; a 17 i puntini, alla fine. Gli attesi sono del foglio (sezione N: N1–N6) e del referee
    // (mandato A403 §4.3 e: misura dell'11/10 con `Inter-Bold.ttf` dell'app, HarfBuzz sul file del repo). Se un atteso
    // non torna il banco cade e si riporta la misura: non si aggiusta l'atteso.

    private func headerTitle(_ title: String) -> FittedText {
        SoloHeaderTitle.fit(title, measurer: m)
    }

    func testTheTitlesThatFitAreWrittenWhole() {
        // N1 e N5 «COLLAUDO SOLO REV20»: 21, intero (a 24, nella REV20 costruita, «COLLAUDO SOLO R…»); N2 «Milano Assago
        // 20/04/2026»: 19; i nomi corti restano a 24.
        let cases: [(title: String, size: Double)] = [
            ("COLLAUDO SOLO REV20", 21), ("COLLAUDO SOLO REV22", 21), ("Milano Assago", 24), ("Il cielo in una stanza", 24),
            ("Milano Assago 20/04/2026", 19), ("Festa della Musica Assago", 19),
        ]
        for c in cases {
            let f = headerTitle(c.title)
            XCTAssertEqual(f.size, c.size, "\(c.title): \(describe(f))")
            XCTAssertEqual(texts(f), [c.title], "\(c.title): \(describe(f))")
            XCTAssertFalse(f.truncated, c.title)
            XCTAssertTrue(f.fits, c.title)
            XCTAssertLessThanOrEqual(f.lines[0].width, 254, "\(c.title): \(describe(f))")
            XCTAssertEqual(f.height, 1.2 * c.size, accuracy: 1e-9, "una riga alta 1,2 × corpo")
        }
    }

    func testTheTitlesThatDoNotFitAtSeventeenEndWithTheEllipsis() {
        // N3, N4 e N6: a 17, coi puntini alla fine (Mauro, 11/10: «alla fine»).
        let cases: [(title: String, shown: String)] = [
            ("La canzone lunghissima che non finisce mai", "La canzone lunghissima che\u{2026}"),
            ("Estate in Piazza \u{B7} Bergamo Alta 2026", "Estate in Piazza \u{B7} Bergamo Al\u{2026}"),
            ("Teatro Comunale di Vicenza 21/04/2026", "Teatro Comunale di Vicenza\u{2026}"),
        ]
        for c in cases {
            let f = headerTitle(c.title)
            XCTAssertEqual(f.size, 17, "\(c.title): \(describe(f))")
            XCTAssertEqual(texts(f), [c.shown], "\(c.title): \(describe(f))")
            XCTAssertTrue(f.truncated, c.title)
            XCTAssertFalse(f.fits, c.title)
            XCTAssertLessThanOrEqual(f.lines[0].width, 254, "\(c.title): \(describe(f))")
            XCTAssertEqual(f.height, 1.2 * 17, accuracy: 1e-9)
        }
    }

    func testTheTwoTitleWidthsThatDecideTheSize() {
        // «COLLAUDO SOLO REV20» a 22 = 262,33: non sta, scende a 21. «Festa della Musica Assago» a 20 = 254,39: meno di
        // mezzo punto oltre il limite di 254 (lo script del foglio, che tollera 1 px, lo terrebbe a 20; l'app, col
        // limite esatto, lo porta a 19). La larghezza di CoreText si stampa nel log della CI, per il referto.
        let cases: [(text: String, size: Double, referee: Double)] = [
            ("COLLAUDO SOLO REV20", 22, 262.33), ("Festa della Musica Assago", 20, 254.39),
        ]
        for c in cases {
            let w = m.width(of: c.text, fontName: SoloFonts.interBold, size: c.size, trackingEm: -0.01)
            let below = m.width(of: c.text, fontName: SoloFonts.interBold, size: c.size - 1, trackingEm: -0.01)
            print("[A403][CORETEXT] testata «\(c.text)» a \(Int(c.size)) = \(String(format: "%.4f", w)); a \(Int(c.size) - 1) = \(String(format: "%.4f", below))")
            XCTAssertGreaterThan(w, 254, "«\(c.text)» a \(c.size): \(w)")
            XCTAssertEqual(w, c.referee, accuracy: 0.05, "«\(c.text)» a \(c.size): \(w)")
            XCTAssertLessThanOrEqual(below, 254, "«\(c.text)» a \(c.size - 1): \(below)")
        }
    }
}
