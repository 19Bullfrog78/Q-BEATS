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

    func testTheSectionOfKWrapsAsTheRefereeExpects() {
        // «Bridge attenzione vai piano» a 42 in 366: «Bridge attenzione» (342,5) / «vai piano».
        let f = TextFitter.fit(SoloVeilTypography.sectionSpec("Bridge attenzione vai piano"), measurer: m)
        XCTAssertEqual(texts(f), ["Bridge attenzione", "vai piano"], "larghezze: \(f.lines.map { $0.width })")
        XCTAssertFalse(f.truncated)
        XCTAssertEqual(f.size, 42)
        XCTAssertEqual(f.height, 90.72, accuracy: 1e-9)
    }

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
}
