import XCTest

// === A403 · SOLO REV22, PUNTO 118 — banco della regola del nome in testata, la parte pura (banco Models) ===
// La regola (`SoloHeaderTitle.fit`, sopra `TextFitter`): una riga larga 254, corpi da 24 a 17 a scendere di 1, vince il
// primo a cui il titolo sta; a 17 ciò che non sta finisce coi puntini, alla fine. Qui col misuratore finto di
// `TextFitterTests` (`FakeTextMeasurer`: minuscole e cifre 0,55 em, spazio 0,3, puntini 0,9, più la spaziatura dopo
// ogni carattere): con −0,01 em una minuscola è larga 0,54 × corpo, lo spazio 0,29, i puntini 0,89. Gli attesi sono
// derivati dalla regola con questi numeri (i conti stanno accanto a ogni caso), non assunti. Gli attesi del foglio e
// del referee, col carattere vero, stanno in `TextFitterRealFontTests`. In coda: il fit una volta per titolo
// (`SoloHeaderTitleMemo`).
// ⚠️ A403 · SEGUITO 1 (11/10/2026) — a 17 il titolo che non sta si taglia al carattere, come nel foglio (CSS
//    `text-overflow:ellipsis` su `.p-hn`), non più dopo l'ultima parola intera: `SoloHeaderTitle.cutAtTheCharacter`.
//    La prova che fissava il taglio alla parola (`testAtSeventeenTheWordsThatDoNotFitGoAwayAndTheEllipsisClosesTheLine`)
//    è riscritta al carattere, col nome nuovo `testAtSeventeenATitleOfSeveralWordsIsCutAtTheCharacter`.

final class SoloHeaderTitleTests: XCTestCase {

    private let m = FakeTextMeasurer()

    private func fit(_ title: String) -> FittedText { SoloHeaderTitle.fit(title, measurer: m) }
    private func texts(_ f: FittedText) -> [String] { f.lines.map { $0.text } }

    // MARK: - Le misure del foglio, pinnate (Solo REV22: punto 118, sezione N, `.p-hn`)

    func testTheRuleCarriesTheSheetValues() {
        XCTAssertEqual(SoloHeaderTitle.maxSize, 24)
        XCTAssertEqual(SoloHeaderTitle.minSize, 17)
        XCTAssertEqual(SoloHeaderTitle.lineHeight, 1.2)
        XCTAssertEqual(SoloHeaderTitle.trackingEm, -0.01)
        XCTAssertEqual(SoloHeaderTitle.maxLines, 1)
        let spec = SoloHeaderTitle.spec("Circuz")
        XCTAssertEqual(spec.styles, [TextFitStyle(fontName: "Inter-Bold", trackingEm: -0.01)])
        XCTAssertEqual(spec.lineHeightFactor, 1.2)
        XCTAssertEqual(spec.maxWidth, 254)
        XCTAssertEqual(spec.maxLines, 1)
        // Da 24 a 17 a scendere di 1: otto corpi.
        XCTAssertEqual(spec.sizes, stride(from: 24, through: 17, by: -1).map { Double($0) })
        XCTAssertEqual(spec.sizes.count, 8)
        XCTAssertEqual(spec.runs, [TextRun(text: "Circuz", style: 0)])
    }

    func testTheWidthComesFromTheGeometryOfTheHeader() {
        // Punto 118: «La casella al centro della testata, larga 254 fra le due tonde». La testata (`.p-hd{gap:10px;
        // padding:0 14px}`, tonde `.p-rk` 44) è larga 390 − 2 × 14 = 362: 362 − 2 × 44 − 2 × 10 = 254.
        XCTAssertEqual(SoloHeaderTitle.sidePadding, 14)
        XCTAssertEqual(SoloHeaderTitle.roundDiameter, 44)
        XCTAssertEqual(SoloHeaderTitle.gap, 10)
        XCTAssertEqual(SoloHeaderTitle.width, 254)
        let g = SoloPlayerGeometry(usableWidth: 390, usableHeight: 766)   // fattore esattamente 1
        XCTAssertEqual(g.header.x, SoloHeaderTitle.sidePadding, accuracy: 0.0001)
        XCTAssertEqual(g.header.width, 362, accuracy: 0.0001)
        XCTAssertEqual(g.header.width - 2 * SoloHeaderTitle.roundDiameter - 2 * SoloHeaderTitle.gap,
                       SoloHeaderTitle.width, accuracy: 0.0001)
        // La tonda è alta quanto la testata della geometria (52–96).
        XCTAssertEqual(g.header.height, SoloHeaderTitle.roundDiameter, accuracy: 0.0001)
    }

    // MARK: - Da 24 a 17, su una riga

    func testAShortTitleStaysAtTwentyFour() {
        // 10 minuscole a 24: 10 × 0,54 × 24 = 129,6 ≤ 254. La riga è alta 1,2 × 24 = 28,8.
        let f = fit("abcdefghij")
        XCTAssertEqual(f.size, 24)
        XCTAssertEqual(texts(f), ["abcdefghij"])
        XCTAssertEqual(f.lines[0].width, 129.6, accuracy: 1e-9)
        XCTAssertTrue(f.fits)
        XCTAssertFalse(f.truncated)
        XCTAssertEqual(f.height, 28.8, accuracy: 1e-9)
    }

    func testTheSizeGoesDownOneByOne() {
        // 20 minuscole: a 24 fanno 259,2 > 254, a 23 fanno 248,4: il primo corpo a cui il titolo sta.
        let f = fit("abcdefghijklmnopqrst")
        XCTAssertEqual(f.size, 23)
        XCTAssertEqual(texts(f), ["abcdefghijklmnopqrst"])
        XCTAssertEqual(f.lines[0].width, 248.4, accuracy: 1e-9)
        XCTAssertTrue(f.fits)
        // Due parole di 10 minuscole: larghe (10,8 + 0,29) × corpo = 11,09 × corpo: a 24 fanno 266,16, a 23 fanno
        // 255,07, a 22 fanno 243,98. Il titolo resta su una riga: non va a capo, scende.
        let g = fit("abcdefghij abcdefghij")
        XCTAssertEqual(g.size, 22)
        XCTAssertEqual(texts(g), ["abcdefghij abcdefghij"])
        XCTAssertEqual(g.lines[0].width, 243.98, accuracy: 1e-9)
        XCTAssertTrue(g.fits)
        XCTAssertFalse(g.truncated)
        XCTAssertEqual(g.height, 1.2 * 22, accuracy: 1e-9)
    }

    func testAtSeventeenATitleThatFitsIsWrittenWhole() {
        // 27 minuscole: a 18 fanno 262,44 > 254, a 17 fanno 247,86: il pavimento, senza puntini.
        let f = fit("abcdefghijklmnopqrstuvwxyza")
        XCTAssertEqual(f.size, 17)
        XCTAssertEqual(texts(f), ["abcdefghijklmnopqrstuvwxyza"])
        XCTAssertEqual(f.lines[0].width, 247.86, accuracy: 1e-9)
        XCTAssertTrue(f.fits)
        XCTAssertFalse(f.truncated)
    }

    // MARK: - Il pavimento: a 17 i puntini, alla fine

    func testAtSeventeenAWordThatDoesNotFitIsCutWithTheEllipsisAtTheEnd() {
        // 30 minuscole in una parola: a 17 fanno 275,4 > 254. I puntini sono larghi 0,89 × 17 = 15,13: con 27 lettere
        // 247,86 + 15,13 = 262,99 > 254, con 26 lettere 238,68 + 15,13 = 253,81.
        let f = fit("abcdefghijklmnopqrstuvwxyzabcd")
        XCTAssertEqual(f.size, 17)
        XCTAssertEqual(texts(f), ["abcdefghijklmnopqrstuvwxyz\u{2026}"])
        XCTAssertEqual(f.lines[0].width, 253.81, accuracy: 1e-9)
        XCTAssertTrue(f.truncated)
        XCTAssertFalse(f.fits)
        XCTAssertEqual(f.height, 1.2 * 17, accuracy: 1e-9)
    }

    func testAtSeventeenATitleOfSeveralWordsIsCutAtTheCharacter() {
        // Tre parole di 10 minuscole: a 17 tutte e tre fanno (16,2 + 0,58) × 17 = 285,26 > 254. A 17 una minuscola è
        // larga 9,18, lo spazio 4,93, i puntini 15,13. Il titolo intero si accorcia dalla fine, un carattere alla
        // volta: due parole e i due spazi fanno 183,6 + 9,86 = 193,46; con 5 lettere della terza 193,46 + 45,9 +
        // 15,13 = 254,49 > 254, con 4 lettere 193,46 + 36,72 + 15,13 = 245,31. Della terza parola restano quattro
        // lettere: il taglio è al carattere, non alla parola (alla parola la riga era «abcdefghij abcdefghij…», 203,66).
        let f = fit("abcdefghij abcdefghij abcdefghij")
        XCTAssertEqual(f.size, 17)
        XCTAssertEqual(texts(f), ["abcdefghij abcdefghij abcd\u{2026}"])
        XCTAssertEqual(f.lines[0].width, 245.31, accuracy: 1e-9)
        XCTAssertTrue(f.truncated)
        XCTAssertTrue(f.lines[0].truncated)
        XCTAssertFalse(f.fits)
        XCTAssertEqual(f.lineCount, 1)
        XCTAssertEqual(f.height, 1.2 * 17, accuracy: 1e-9)
        // Una riga sola, con la linea di base del modello CSS: mezza interlinea più l'ascendente del carattere.
        XCTAssertEqual(f.baselines, TextFitter.baselines(count: 1, size: 17, lineHeight: 1.2 * 17,
                                                         metrics: m.verticalMetrics(fontName: "Inter-Bold")))
        XCTAssertEqual(f.styles, [TextFitStyle(fontName: "Inter-Bold", trackingEm: -0.01)])
    }

    func testTheSpacesAtTheCutDoNotStayBeforeTheEllipsis() {
        // «abcdefghij abcdefghij abcd efghij»: 30 lettere e 3 spazi, a 17 fanno 275,4 + 14,79 = 290,19 > 254. Fino a
        // «…abcd e» la riga coi puntini non sta (229,5 + 14,79 + 15,13 = 259,42); tolta la «e» resta «…abcd » con lo
        // spazio in coda, che non resta davanti ai puntini: «…abcd…», 220,32 + 9,86 + 15,13 = 245,31.
        let f = fit("abcdefghij abcdefghij abcd efghij")
        XCTAssertEqual(f.size, 17)
        XCTAssertEqual(texts(f), ["abcdefghij abcdefghij abcd\u{2026}"])
        XCTAssertEqual(f.lines[0].width, 245.31, accuracy: 1e-9)
        XCTAssertTrue(f.truncated)
        // Gli spazi in testa e quelli doppi fra le parole non si scrivono, nemmeno nella riga tagliata: è la riga che
        // `TextFitter` scriverebbe (`tokenize` e `fragments`).
        let g = fit("  abcdefghij   abcdefghij abcdefghij")
        XCTAssertEqual(texts(g), ["abcdefghij abcdefghij abcd\u{2026}"])
        XCTAssertEqual(g.lines[0].width, 245.31, accuracy: 1e-9)
    }

    func testTheCutNeverLeavesOutAPieceThatWouldFit() {
        // Per ogni titolo: i puntini solo a 17, solo in coda, e solo se il titolo intero a 17 non sta; la riga
        // tagliata è l'inizio del titolo intero, senza spazio davanti ai puntini, e col pezzo che viene subito dopo
        // (il prossimo carattere che non è uno spazio, con gli spazi che lo precedono) non starebbe più nei 254.
        // I titoli: parole di minuscole, cifre e trattini, lunghezze da un generatore fisso (niente caso).
        var seed: UInt64 = 403
        func next(_ n: Int) -> Int {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Int((seed >> 33) % UInt64(n))
        }
        let alphabet: [Character] = Array("abcdefghijklmnopqrstuvwxyz0123456789-")
        var titles: [String] = ["abcdefghij abcdefghij abcdefghij", "abcdefghijklmnopqrstuvwxyzabcd", "a b c d e f g h i j k l m n o p q r s t u v w x y z",
                      "ab-cdefghijklmnopqrstuvwxyz abcdefghijklmnop", "abcdefghij abcdefghij abcd efghij"]
        for _ in 0..<200 {
            let wordCount = 1 + next(7)
            var words: [String] = []
            for _ in 0..<wordCount {
                let length = 1 + next(14)
                var word = ""
                for _ in 0..<length { word.append(alphabet[next(alphabet.count)]) }
                words.append(word)
            }
            titles.append(words.joined(separator: " "))
        }
        var cut = 0
        for title in titles {
            let f = fit(title)
            let rule = SoloHeaderTitle.spec(title)
            let whole = TextFitter.fragments(TextFitter.tokenize(rule.runs)).map { $0.text }.joined()
            let wholeAtFloor = m.width(of: whole, fontName: "Inter-Bold", size: 17, trackingEm: -0.01)
            XCTAssertEqual(f.lineCount, 1, title)
            XCTAssertLessThanOrEqual(f.lines[0].width, 254 + 1e-9, title)
            XCTAssertEqual(f.truncated, wholeAtFloor > 254 + 1e-9, title)
            guard f.truncated else {
                XCTAssertEqual(f.lines[0].text, whole, title)
                XCTAssertTrue(f.fits, title)
                continue
            }
            cut += 1
            XCTAssertEqual(f.size, 17, title)
            XCTAssertFalse(f.fits, title)
            let shown = f.lines[0].text
            XCTAssertTrue(shown.hasSuffix("\u{2026}"), title)
            let body = String(shown.dropLast())
            XCTAssertFalse(body.contains("\u{2026}"), title)
            XCTAssertFalse(body.hasSuffix(" "), title)
            XCTAssertFalse(body.isEmpty, title)
            XCTAssertTrue(whole.hasPrefix(body), title)
            XCTAssertLessThan(body.count, whole.count, title)
            // Il pezzo dopo: gli spazi che seguono e il primo carattere che non è uno spazio.
            var rest = Array(whole.dropFirst(body.count))
            var piece = ""
            while let ch = rest.first {
                piece.append(ch)
                rest.removeFirst()
                if ch != " " { break }
            }
            let longer = m.width(of: body + piece + "\u{2026}", fontName: "Inter-Bold", size: 17, trackingEm: -0.01)
            XCTAssertGreaterThan(longer, 254 + 1e-9, "\(title): «\(body + piece)…» starebbe (\(longer))")
        }
        XCTAssertGreaterThan(cut, 20, "il generatore deve dare titoli che si tagliano")
        XCTAssertLessThan(cut, titles.count - 20, "e titoli che stanno")
    }

    func testATitleIsAlwaysOneLineInsideTheBox() {
        // Punto 118: «su una riga»; sezione N: «Due righe, no.»
        let titles = ["a", "abcdefghij", "abcdefghij abcdefghij", "abcdefghij abcdefghij abcdefghij",
                      "abcdefghijklmnopqrstuvwxyzabcd", "ab-cdefghijklmnopqrstuvwxyz abcdefghijklmnop", "a b c d e f g h i j k l m n o p q r s t u v w x y z"]
        for title in titles {
            let f = fit(title)
            XCTAssertEqual(f.lineCount, 1, title)
            XCTAssertLessThanOrEqual(f.lines[0].width, 254 + 1e-9, title)
            XCTAssertGreaterThanOrEqual(f.size, 17, title)
            XCTAssertLessThanOrEqual(f.size, 24, title)
            XCTAssertEqual(f.height, 1.2 * f.size, accuracy: 1e-9, title)
        }
    }

    func testAnEmptyTitleHasNoLine() {
        for title in ["", "   "] {
            let f = fit(title)
            XCTAssertEqual(f.lineCount, 0)
            XCTAssertFalse(f.truncated)
            XCTAssertEqual(f.height, 0, accuracy: 1e-9)
        }
    }

    // MARK: - Il fit una volta per titolo

    func testTheMemoComputesEachTitleOnce() {
        let counting = CountingTextMeasurer()
        let memo = SoloHeaderTitleMemo()
        let first = memo.fit("abcdefghij abcdefghij abcdefghij", measurer: counting)
        let afterFirst = counting.widthCalls
        XCTAssertGreaterThan(afterFirst, 0)
        XCTAssertEqual(first, fit("abcdefghij abcdefghij abcdefghij"), "il memo rende il fit della regola")
        // Lo stesso titolo, cento volte (K si rivaluta a ogni battito): nessuna misura in più.
        for _ in 0..<100 {
            XCTAssertEqual(memo.fit("abcdefghij abcdefghij abcdefghij", measurer: counting), first)
        }
        XCTAssertEqual(counting.widthCalls, afterFirst)
        // Un titolo nuovo si misura; tornando al primo, niente.
        let second = memo.fit("abcdefghij", measurer: counting)
        let afterSecond = counting.widthCalls
        XCTAssertGreaterThan(afterSecond, afterFirst)
        XCTAssertEqual(second.size, 24)
        XCTAssertEqual(memo.fit("abcdefghij abcdefghij abcdefghij", measurer: counting), first)
        XCTAssertEqual(memo.fit("abcdefghij", measurer: counting), second)
        XCTAssertEqual(counting.widthCalls, afterSecond)
    }
}
