import XCTest

// === A355 — banco della decisione del velo (banco Models) ===
// Attesi LETTERALI: ogni caso pinna le stringhe e la forma per contenuto, mai
// ricalcolando la regola. Le soglie del gigante (12 · 13 · 25 · 26) sono quelle
// di BOX5 «SCALA DI PALCO» e del foglio CD 11/09 LA-TABELLA-FINALE §③.
// Il banco gira in CI su ogni push (`.github/workflows/ios_build.yml`,
// `xcodebuild test -scheme QBeatsTests`).

final class StandbyOverlayDecisionTests: XCTestCase {

    // Fabbrica SENZA logica: default espliciti, ogni test dichiara ciò che cambia.
    private func decision(sectionIdx: Int,
                          sectionName: String = "Bridge",
                          songName: String = "Circuz",
                          isFollower: Bool = false) -> StandbyOverlayDecision {
        StandbyOverlayDecision(currentSectionIdx: sectionIdx,
                               currentSectionName: sectionName,
                               songName: songName,
                               isFollower: isFollower)
    }

    // MARK: - Sezione 0: partenza

    func testSectionZeroIsStartWithNextLine() {
        let d = decision(sectionIdx: 0)
        XCTAssertFalse(d.hasResumePoint)
        XCTAssertEqual(d.relationLine, "Next:")
        XCTAssertEqual(d.gestureLine, "Tap anywhere")
        XCTAssertEqual(d.songName, "Circuz")
    }

    // MARK: - Sezione > 0 con nome: ripresa

    func testSectionAboveZeroWithNameIsResumeFromName() {
        let d = decision(sectionIdx: 3, sectionName: "Bridge")
        XCTAssertTrue(d.hasResumePoint)
        XCTAssertEqual(d.relationLine, "Resume from Bridge")
        XCTAssertEqual(d.gestureLine, "Tap anywhere")
    }

    // MARK: - Garanzia contro la bugia: nome vuoto o di soli spazi

    func testSectionAboveZeroWithEmptyNameKeepsResumeButSaysNext() {
        let d = decision(sectionIdx: 3, sectionName: "")
        XCTAssertTrue(d.hasResumePoint)          // il tocco riparte dalla sezione
        XCTAssertTrue(d.sectionNameIsBlank)
        XCTAssertEqual(d.relationLine, "Next:")  // il velo non scrive «Resume from —»
    }

    func testSectionAboveZeroWithBlankNameKeepsResumeButSaysNext() {
        let d = decision(sectionIdx: 3, sectionName: "   ")
        XCTAssertTrue(d.hasResumePoint)
        XCTAssertTrue(d.sectionNameIsBlank)
        XCTAssertEqual(d.relationLine, "Next:")
    }

    func testSectionNameWithSurroundingSpacesIsNotBlank() {
        let d = decision(sectionIdx: 3, sectionName: " Bridge ")
        XCTAssertFalse(d.sectionNameIsBlank)
        XCTAssertEqual(d.relationLine, "Resume from Bridge")  // spazi ai bordi tolti, nome intatto
    }

    // MARK: - Follower: il gesto non è suo, con e senza punto di ripresa

    func testFollowerWithResumePointNamesSectionAndDirector() {
        let d = decision(sectionIdx: 3, sectionName: "Bridge", isFollower: true)
        XCTAssertTrue(d.hasResumePoint)
        XCTAssertTrue(d.isFollower)
        XCTAssertEqual(d.relationLine, "Resume from Bridge")
        XCTAssertEqual(d.gestureLine, "The director starts")
    }

    func testFollowerWithoutResumePointSaysNextAndDirector() {
        let d = decision(sectionIdx: 0, isFollower: true)
        XCTAssertFalse(d.hasResumePoint)
        XCTAssertTrue(d.isFollower)
        XCTAssertEqual(d.relationLine, "Next:")
        XCTAssertEqual(d.gestureLine, "The director starts")
    }

    // MARK: - Regola del gigante: 12 · 13 · 25 · 26 caratteri

    func testTwelveCharactersIsOneLine() {
        let name = String(repeating: "a", count: 12)
        XCTAssertEqual(name.count, 12)
        XCTAssertEqual(decision(sectionIdx: 0, songName: name).nameForm, .oneLine)
    }

    func testThirteenCharactersIsTwoLines() {
        let name = String(repeating: "a", count: 13)
        XCTAssertEqual(name.count, 13)
        XCTAssertEqual(decision(sectionIdx: 0, songName: name).nameForm, .twoLines)
    }

    func testTwentyFiveCharactersIsTwoLines() {
        let name = String(repeating: "a", count: 25)
        XCTAssertEqual(name.count, 25)
        XCTAssertEqual(decision(sectionIdx: 0, songName: name).nameForm, .twoLines)
    }

    func testTwentySixCharactersIsTwoLinesWithEllipsis() {
        let name = String(repeating: "a", count: 26)
        XCTAssertEqual(name.count, 26)
        XCTAssertEqual(decision(sectionIdx: 0, songName: name).nameForm, .twoLinesEllipsis)
    }

    func testGiantRuleCountsCharactersNotBytes() {
        // 12 caratteri accentati = 24 byte UTF-8: la soglia è in caratteri. Lo scalare
        // è scritto esplicito (U+00E8, precomposto): se un editor salvasse la lettera
        // scomposta i byte diventerebbero 36 e il test fallirebbe col codice giusto.
        let name = String(repeating: "\u{00E8}", count: 12)
        XCTAssertEqual(name.count, 12)
        XCTAssertEqual(name.utf8.count, 24)
        XCTAssertEqual(decision(sectionIdx: 0, songName: name).nameForm, .oneLine)
    }

    // MARK: - Il nome si scrive come è scritto

    func testSongNameIsKeptAsWritten() {
        let d = decision(sectionIdx: 0, songName: "Circuz")
        XCTAssertEqual(d.songName, "Circuz")   // niente maiuscolo forzato: lo decide la vista, non il dato
    }
}
