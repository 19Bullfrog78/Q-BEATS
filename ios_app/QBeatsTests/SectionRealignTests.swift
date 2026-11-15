import XCTest

// === A432, parte 2a — banco del messaggio del riallineo di sezione (`SectionRealign`, banco Models) ===
// Seguito «PARTE 2a» del mandato A432, par. 2.2; referto A424, par. 3.3 b, passo 4: l'identità che la vista usa
// già, `sectionStartTick = tick − sectionBeat + 1`. Lo stesso caso gira sul modello Python delle regole (fuori dal
// deposito), dove il test cade se si toglie la riga della regola.

final class SectionRealignTests: XCTestCase {

    func testTheSectionStartTickOfARealign() {
        XCTAssertEqual(SectionRealign(sectionIdx: 2, nextTick: 101, sectionBeat: 1).sectionStartTick, 101)
        XCTAssertEqual(SectionRealign(sectionIdx: 2, nextTick: 101, sectionBeat: 5).sectionStartTick, 97)
        XCTAssertEqual(SectionRealign(sectionIdx: 0, nextTick: 8, sectionBeat: 8).sectionStartTick, 1)
    }
}
