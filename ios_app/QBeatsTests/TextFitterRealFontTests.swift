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

    // MARK: - A401 · Solo REV20, punto 115: il teleprompter di K
    // Gli attesi sono del foglio (`DESIGN/QLive_Nav/2026-10-10_QLive-Player_G1-SOLO-REV20_390x844_1.html`, sezione R:
    // schermi R2-R11 e tabella) e del referee (mandato A401 §4.1 e: misura del 10/10 con `Inter-ExtraBold.ttf`).
    // Se un atteso non torna il banco cade e si riporta la misura: non si aggiusta l'atteso.

    private func section(_ name: String) -> FittedText {
        SoloVeilTypography.sectionFit(name, measurer: m)
    }

    /// Dove sta il blocco, in coordinate del foglio: il riquadro va da 284 a 457.
    private func blockSpan(_ f: FittedText) -> (top: Double, bottom: Double) {
        let top = 284 + SoloVeilTypography.sectionBlockTop(height: f.height)
        return (top, top + f.height)
    }

    private func describe(_ f: FittedText) -> String {
        "corpo \(f.size), righe \(f.lines.map { "\($0.text) (\($0.width))" })"
    }

    func testTheShortSectionNamesAreSixtyEightOnOneLine() {
        // R2 «Verse»: 68, una riga; riga d delle misure: «Section 3» 68 in una riga. Tabella, «Dove sta»: una riga a
        // 68 da 334 a 407 (333,8–407,2).
        for name in ["Verse", "Section 3"] {
            let f = section(name)
            XCTAssertEqual(f.size, 68, "\(name): \(describe(f))")
            XCTAssertEqual(texts(f), [name])
            XCTAssertFalse(f.truncated)
            let span = blockSpan(f)
            XCTAssertEqual(span.top, 333.8, accuracy: 0.05)
            XCTAssertEqual(span.bottom, 407.2, accuracy: 0.05)
        }
    }

    func testPreChorusIsSixtyEightOnTwoLinesAfterTheHyphen() {
        // R3: «Pre-» / «Chorus», a capo dopo il trattino già scritto; in una riga a 68 servirebbero 366,67 su 366.
        let f = section("Pre-Chorus")
        XCTAssertEqual(f.size, 68, describe(f))
        XCTAssertEqual(texts(f), ["Pre-", "Chorus"])
        XCTAssertFalse(f.truncated)
        let span = blockSpan(f)
        XCTAssertEqual(span.top, 297.1, accuracy: 0.05)
        XCTAssertEqual(span.bottom, 443.9, accuracy: 0.05)
    }

    func testStaccoVeloceAndBridgeVaiPianoAreSixtyEightOnTwoLines() {
        // R5 e R7: due righe a 68, da 297 a 444 (297,1–443,9).
        for name in ["Stacco veloce", "Bridge vai piano"] {
            let f = section(name)
            XCTAssertEqual(f.size, 68, "\(name): \(describe(f))")
            XCTAssertEqual(f.lineCount, 2, "\(name): \(describe(f))")
            XCTAssertFalse(f.truncated)
            let span = blockSpan(f)
            XCTAssertEqual(span.top, 297.1, accuracy: 0.05)
            XCTAssertEqual(span.bottom, 443.9, accuracy: 0.05)
        }
    }

    func testThePhrasesAreFiftyThreeOnThreeLines() {
        // R4 (e R11, col Mixer aperto) «Bridge attenzione vai piano» e R9 «comincia il canto four three two one»:
        // in due righe dovrebbero scendere sotto 53, quindi tre righe a 53, da 285 a 456 (284,6–456,4), dentro il
        // riquadro 284–457.
        for name in ["Bridge attenzione vai piano", "comincia il canto four three two one"] {
            let f = section(name)
            XCTAssertEqual(f.size, 53, "\(name): \(describe(f))")
            XCTAssertEqual(f.lineCount, 3, "\(name): \(describe(f))")
            XCTAssertFalse(f.truncated)
            XCTAssertTrue(f.lines.allSatisfy { $0.width <= 366 }, describe(f))
            let span = blockSpan(f)
            XCTAssertEqual(span.top, 284.6, accuracy: 0.05)
            XCTAssertEqual(span.bottom, 456.4, accuracy: 0.05)
            XCTAssertGreaterThanOrEqual(span.top, 284)
            XCTAssertLessThanOrEqual(span.bottom, 457)
        }
    }

    func testTheLongNameOfRevThreeIsFortyFourOnThreeLines() {
        // R6: «Nella REV19 arrivava a 42 coi puntini; in tre righe sta tutto.»
        let f = section("Bridge attenzione vai piano poi stop secco sul quattro")
        XCTAssertEqual(f.size, 44, describe(f))
        XCTAssertEqual(f.lineCount, 3, describe(f))
        XCTAssertFalse(f.truncated)
    }

    func testANameThatDoesNotFitAtFortyTwoEndsWithTheEllipsisOnTheThirdLine() {
        // R10: 51 caratteri; a 42 servirebbero quattro righe («entra la voce / piano, quattro / battute poi /
        // ritornello»): la terza si chiude coi puntini di `TextFitter`, «battute poi…», come nel foglio.
        let f = section("entra la voce piano, quattro battute poi ritornello")
        XCTAssertEqual(f.size, 42, describe(f))
        XCTAssertEqual(f.lineCount, 3, describe(f))
        XCTAssertTrue(f.truncated)
        XCTAssertEqual(f.lines[2].text, "battute poi\u{2026}", describe(f))
        XCTAssertEqual(f.lines.map { $0.truncated }, [false, false, true])
        XCTAssertTrue(f.lines.allSatisfy { $0.width <= 366 }, describe(f))
    }

    func testFiftyTwoCharactersStillFitAtFortyTwoOnThreeLines() {
        // Didascalia di R10: questo nome, di 52 caratteri, «sta ancora a 42 in tre righe».
        let f = section("entra la voce, quattro battute poi ritornello e stop")
        XCTAssertEqual(f.size, 42, describe(f))
        XCTAssertEqual(f.lineCount, 3, describe(f))
        XCTAssertFalse(f.truncated)
    }

    func testTheThreeWidthsWithinOnePointOfTheLimit() {
        // Tre casi a meno di un punto da 366 (misura del referee: 366,67 · 366,93 · 366,66): decidono il corpo o
        // l'a capo dei nomi qui sopra. La larghezza di CoreText si stampa nel log della CI, per il referto.
        let cases: [(text: String, size: Double, referee: Double)] = [
            ("Pre-Chorus", 68, 366.67), ("Bridge attenzione", 45, 366.93), ("quattro battute poi", 43, 366.66),
        ]
        for c in cases {
            let w = m.width(of: c.text, fontName: SoloFonts.interExtraBold, size: c.size, trackingEm: -0.035)
            let below = m.width(of: c.text, fontName: SoloFonts.interExtraBold, size: c.size - 1, trackingEm: -0.035)
            print("[A401][CORETEXT] «\(c.text)» a \(Int(c.size)) = \(String(format: "%.4f", w)); a \(Int(c.size) - 1) = \(String(format: "%.4f", below))")
            XCTAssertGreaterThan(w, 366, "«\(c.text)» a \(c.size): \(w)")
            XCTAssertLessThan(w, 367, "«\(c.text)» a \(c.size): \(w)")
            XCTAssertEqual(w, c.referee, accuracy: 0.05, "«\(c.text)» a \(c.size): \(w)")
            XCTAssertLessThanOrEqual(below, 366, "«\(c.text)» a \(c.size - 1): \(below)")
        }
    }
}
