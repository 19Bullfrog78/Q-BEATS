import XCTest

// === A432, parte 2a — banco del precarico col numero della sezione (`SectionPreloadDecision`, banco Models) ===
// Seguito «PARTE 2a» del mandato A432, par. 2.2; referto A431, par. 2.3: in ordine, dopo un riallineo in avanti e
// all'indietro, senza mappa, l'avvio da una sezione qualunque. Gli stessi casi girano sul modello Python delle
// regole (fuori dal deposito), dove ogni test cade se si toglie la riga della regola che prova.

final class SectionPreloadDecisionTests: XCTestCase {

    private func accepts(_ preload: Int, _ engine: Int) -> Bool {
        SectionPreloadDecision.accepts(preloadSection: preload, engineSection: engine)
    }

    /// Il runner precarica sempre la sezione dopo quella che il motore conta: 0 → 1 → 2 → 3.
    func testAPreloadInOrderPasses() {
        XCTAssertTrue(accepts(1, 0))
        XCTAssertTrue(accepts(2, 1))
        XCTAssertTrue(accepts(3, 2))
    }

    /// Il motore è già in 3 (un riallineo in avanti): il precarico vecchio per la 2 non passa; quello del
    /// riallineo, la 4, sì.
    func testAStalePreloadAfterARealignForwardIsDiscarded() {
        XCTAssertFalse(accepts(2, 3))
        XCTAssertTrue(accepts(4, 3))
    }

    /// Il motore è tornato in 1 (un riallineo all'indietro): il precarico per la 3 non passa; la sezione stessa
    /// non è «la sezione dopo».
    func testAStalePreloadAfterARealignBackwardIsDiscarded() {
        XCTAssertFalse(accepts(3, 1))
        XCTAssertTrue(accepts(2, 1))
        XCTAssertFalse(accepts(1, 1))
    }

    /// Senza mappa il motore non conta le sezioni (indice negativo): passa tutto, com'è oggi.
    func testWithoutAMapEveryPreloadPasses() {
        XCTAssertTrue(accepts(0, -1))
        XCTAssertTrue(accepts(5, -1))
    }

    func testTheStartFromAnySection() {
        for start in [0, 2, 7] {
            XCTAssertTrue(accepts(start + 1, start))
            XCTAssertFalse(accepts(start + 2, start))
        }
    }
}
