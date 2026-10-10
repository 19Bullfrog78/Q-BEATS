import XCTest

// === A397 · SOLO-G1-PEZZO-1-M2 — banco di Next (108) e del nome della sezione (109) (banco Models) ===
// La sezione dopo; all'ultima sezione «Next song» e la canzone dopo; all'ultima dell'ultima canzone «Next» e
// «END SHOW»; senza nome «Section N», N contato da 1 nella canzone; un nome di soli spazi conta come senza nome.
// A401 · Solo REV20, punto 116 — una canzone senza nome, o di soli spazi, è «Song N», N = il posto nello show, da 1
// (`SongNameDecision`): dopo «Next song» e nel titolo di K, dove vale solo a display scritto.

final class SoloNextDecisionTests: XCTestCase {

    // MARK: - A401 · punto 116: «Song N»

    func testTheSongNameRule() {
        XCTAssertEqual(SongNameDecision.unnamedPrefix, "Song ")
        XCTAssertEqual(SongNameDecision.displayName("Circuz", numberInShow: 1), "Circuz")
        XCTAssertEqual(SongNameDecision.displayName("", numberInShow: 2), "Song 2")
        XCTAssertEqual(SongNameDecision.displayName("   ", numberInShow: 3), "Song 3")
        XCTAssertEqual(SongNameDecision.displayName(" \t\n", numberInShow: 12), "Song 12")
        XCTAssertEqual(SongNameDecision.displayName(" Mare ", numberInShow: 4), " Mare ", "il nome si scrive come è scritto")
        XCTAssertEqual(SongNameDecision.displayName("\u{2014}", numberInShow: 5), "\u{2014}",
                       "la lineetta che il runner scrive per una canzone che non si risolve non è un nome vuoto")
    }

    func testTheNumberIsThePlaceInTheShow() {
        // Il numero è del posto: la stessa canzone senza nome, in un altro posto, cambia numero.
        for place in 1...9 {
            XCTAssertEqual(SongNameDecision.displayName("", numberInShow: place), "Song \(place)")
        }
    }

    func testAnUnnamedNextSongIsSongN() {
        // All'ultima sezione il runner scrive la canzone dopo: senza nome è una stringa vuota, non `nil`.
        XCTAssertEqual(SoloNextDecision.next(nextSectionName: nil, nextSectionNumber: 7, nextSongName: "", nextSongNumber: 2),
                       SoloNext(label: "Next song", value: "Song 2"))
        XCTAssertEqual(SoloNextDecision.next(nextSectionName: nil, nextSectionNumber: 2, nextSongName: "  ", nextSongNumber: 5),
                       SoloNext(label: "Next song", value: "Song 5"))
        // Con un nome il numero non entra; senza canzone dopo resta «END SHOW».
        XCTAssertEqual(SoloNextDecision.next(nextSectionName: nil, nextSectionNumber: 2, nextSongName: "Mare", nextSongNumber: 5),
                       SoloNext(label: "Next song", value: "Mare"))
        XCTAssertEqual(SoloNextDecision.next(nextSectionName: nil, nextSectionNumber: 2, nextSongName: nil, nextSongNumber: 5),
                       SoloNext(label: "Next", value: "END SHOW"))
        // Finché resta una sezione vince la sezione, anche se la canzone dopo è senza nome.
        XCTAssertEqual(SoloNextDecision.next(nextSectionName: "Outro", nextSectionNumber: 3, nextSongName: "", nextSongNumber: 2),
                       SoloNext(label: "Next", value: "Outro"))
    }

    func testTheTitleOfKIsSongNOnlyOnceTheDisplayIsWritten() {
        // A display scritto: il nome, oppure «Song N». Prima (il runner non ha ancora scritto la canzone) il nome in
        // sessione è vuoto perché non è scritto: resta vuoto, niente «Song N» di passaggio.
        XCTAssertEqual(SongNameDecision.titleInMotion("Circuz", numberInShow: 1, displayWritten: true), "Circuz")
        XCTAssertEqual(SongNameDecision.titleInMotion("", numberInShow: 2, displayWritten: true), "Song 2")
        XCTAssertEqual(SongNameDecision.titleInMotion("  ", numberInShow: 2, displayWritten: true), "Song 2")
        XCTAssertEqual(SongNameDecision.titleInMotion("", numberInShow: 2, displayWritten: false), "")
        XCTAssertEqual(SongNameDecision.titleInMotion("Circuz", numberInShow: 1, displayWritten: false), "Circuz")
    }


    func testTheSectionAfter() {
        let n = SoloNextDecision.next(nextSectionName: "Bridge", nextSectionNumber: 4, nextSongName: nil, nextSongNumber: 2)
        XCTAssertEqual(n, SoloNext(label: "Next", value: "Bridge"))
    }

    func testTheLastSectionNamesTheNextSong() {
        let n = SoloNextDecision.next(nextSectionName: nil, nextSectionNumber: 6, nextSongName: "Mare", nextSongNumber: 2)
        XCTAssertEqual(n, SoloNext(label: "Next song", value: "Mare"))
    }

    func testTheLastSectionOfTheLastSongSaysEndShow() {
        let n = SoloNextDecision.next(nextSectionName: nil, nextSectionNumber: 5, nextSongName: nil, nextSongNumber: 2)
        XCTAssertEqual(n, SoloNext(label: "Next", value: "END SHOW"))
    }

    func testANextSongIsIgnoredWhileASectionRemains() {
        // Il runner scrive la canzone dopo solo all'ultima sezione; se arrivassero tutte e due, vince la sezione.
        let n = SoloNextDecision.next(nextSectionName: "Outro", nextSectionNumber: 5, nextSongName: "Mare", nextSongNumber: 2)
        XCTAssertEqual(n, SoloNext(label: "Next", value: "Outro"))
    }

    func testAnUnnamedNextSectionIsSectionN() {
        XCTAssertEqual(SoloNextDecision.next(nextSectionName: "", nextSectionNumber: 3, nextSongName: nil, nextSongNumber: 2),
                       SoloNext(label: "Next", value: "Section 3"))
        XCTAssertEqual(SoloNextDecision.next(nextSectionName: "   ", nextSectionNumber: 12, nextSongName: "Mare", nextSongNumber: 2),
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
