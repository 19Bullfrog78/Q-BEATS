import XCTest

// === A397 · SOLO-G1-PEZZO-1-M2 — banco di Next (108) e del nome della sezione (109) (banco Models) ===
// La sezione dopo; all'ultima sezione «Next song» e la canzone dopo; all'ultima dell'ultima canzone «Next» e
// «END SHOW»; senza nome «Section N», N contato da 1 nella canzone; un nome di soli spazi conta come senza nome.

final class SoloNextDecisionTests: XCTestCase {

    func testTheSectionAfter() {
        let n = SoloNextDecision.next(nextSectionName: "Bridge", nextSectionNumber: 4, nextSongName: nil)
        XCTAssertEqual(n, SoloNext(label: "Next", value: "Bridge"))
    }

    func testTheLastSectionNamesTheNextSong() {
        let n = SoloNextDecision.next(nextSectionName: nil, nextSectionNumber: 6, nextSongName: "Mare")
        XCTAssertEqual(n, SoloNext(label: "Next song", value: "Mare"))
    }

    func testTheLastSectionOfTheLastSongSaysEndShow() {
        let n = SoloNextDecision.next(nextSectionName: nil, nextSectionNumber: 5, nextSongName: nil)
        XCTAssertEqual(n, SoloNext(label: "Next", value: "END SHOW"))
    }

    func testANextSongIsIgnoredWhileASectionRemains() {
        // Il runner scrive la canzone dopo solo all'ultima sezione; se arrivassero tutte e due, vince la sezione.
        let n = SoloNextDecision.next(nextSectionName: "Outro", nextSectionNumber: 5, nextSongName: "Mare")
        XCTAssertEqual(n, SoloNext(label: "Next", value: "Outro"))
    }

    func testAnUnnamedNextSectionIsSectionN() {
        XCTAssertEqual(SoloNextDecision.next(nextSectionName: "", nextSectionNumber: 3, nextSongName: nil),
                       SoloNext(label: "Next", value: "Section 3"))
        XCTAssertEqual(SoloNextDecision.next(nextSectionName: "   ", nextSectionNumber: 12, nextSongName: "Mare"),
                       SoloNext(label: "Next", value: "Section 12"))
    }

    func testTheWords() {
        XCTAssertEqual(SoloNextDecision.nextLabel, "Next")
        XCTAssertEqual(SoloNextDecision.nextSongLabel, "Next song")
        XCTAssertEqual(SoloNextDecision.endShow, "END SHOW")
        XCTAssertEqual(SectionNameDecision.unnamedPrefix, "Section ")
    }

    func testTheSectionNameRule() {
        XCTAssertEqual(SectionNameDecision.displayName("Verse", numberInSong: 2), "Verse")
        XCTAssertEqual(SectionNameDecision.displayName("", numberInSong: 3), "Section 3")
        XCTAssertEqual(SectionNameDecision.displayName("  \t ", numberInSong: 1), "Section 1")
        XCTAssertEqual(SectionNameDecision.displayName(" Bridge ", numberInSong: 4), " Bridge ", "il nome si scrive come è scritto")
        XCTAssertTrue(SectionNameDecision.isBlank(""))
        XCTAssertTrue(SectionNameDecision.isBlank("   "))
        XCTAssertFalse(SectionNameDecision.isBlank("A"))
    }
}
