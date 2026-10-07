import XCTest

// === A355 — banco della decisione del velo (banco Models) ===
// Attesi LETTERALI: ogni caso pinna le stringhe e la forma per contenuto, mai
// ricalcolando la regola. Le soglie del gigante (12 · 13 · 25 · 26) sono quelle
// di BOX5 «SCALA DI PALCO» e del foglio CD 11/09 LA-TABELLA-FINALE §③.
// B2b (A386): sul Follower il velo non scrive mai «Resume from» (2D-D6, foglio 2D-QUATER L1);
// le due righe della lastra ⑧ («No device connected» · «nothing will start from here») sono
// uscite: lo slot E del Follower lo decide `FollowerVeilDecision`.
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
        XCTAssertEqual(d.gestureLine, "Tap to start")   // A398: era «Tap anywhere»
        XCTAssertEqual(d.songName, "Circuz")
    }

    // MARK: - Sezione > 0 con nome: ripresa

    func testSectionAboveZeroWithNameIsResumeFromName() {
        let d = decision(sectionIdx: 3, sectionName: "Bridge")
        XCTAssertTrue(d.hasResumePoint)
        XCTAssertEqual(d.relationLine, "Resume from Bridge")
        XCTAssertEqual(d.gestureLine, "Tap to start")   // A398: era «Tap anywhere»
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

    // MARK: - Follower: il gesto non è suo, e il velo dice sempre «Next:» (B2b)

    func testFollowerWithResumePointStillSaysNextAndDirector() {
        // B2b: sul Follower si entra solo a inizio canzone (2D-D6): mai «Resume from».
        let d = decision(sectionIdx: 3, sectionName: "Bridge", isFollower: true)
        XCTAssertTrue(d.hasResumePoint)          // il dato resta (lo leggono la strumentazione e chi comanda)
        XCTAssertTrue(d.isFollower)
        XCTAssertEqual(d.relationLine, "Next:")
        XCTAssertEqual(d.gestureLine, "The director starts")
    }

    func testFollowerWithoutResumePointSaysNextAndDirector() {
        let d = decision(sectionIdx: 0, isFollower: true)
        XCTAssertFalse(d.hasResumePoint)
        XCTAssertTrue(d.isFollower)
        XCTAssertEqual(d.relationLine, "Next:")
        XCTAssertEqual(d.gestureLine, "The director starts")
    }

    func testWhoCommandsTheTransportStillGetsResumeFrom() {
        // Il velo del Direttore non si tocca (mandato B2b §3.f).
        let d = decision(sectionIdx: 2, sectionName: "Chorus", isFollower: false)
        XCTAssertEqual(d.relationLine, "Resume from Chorus")
        XCTAssertEqual(d.gestureLine, "Tap to start")   // A398: era «Tap anywhere»
    }

    // MARK: - A398: le parole del gesto e la riga di tempo e metrica

    func testTheGestureWordsAreTapToStartAndTheDirectorStarts() {
        // Chi comanda il trasporto: «Tap to start» (BOX5 V54, decisione 5; SYNC REV8 `.qb-hi.tp`); il Follower:
        // «The director starts», com'era. «Tap anywhere» non si scrive più da nessuna parte.
        XCTAssertEqual(StandbyOverlayDecision.tapGesture, "Tap to start")
        XCTAssertEqual(StandbyOverlayDecision.directorGesture, "The director starts")
        XCTAssertEqual(decision(sectionIdx: 0).gestureLine, "Tap to start")
        XCTAssertEqual(decision(sectionIdx: 0, isFollower: true).gestureLine, "The director starts")
        XCTAssertNotEqual(StandbyOverlayDecision.tapGesture, "Tap anywhere")
        // «Next:» coi due punti resta per Direttore e Follower.
        XCTAssertEqual(StandbyOverlayDecision.nextLine, "Next:")
    }

    func testTheTempoLineIsCarriedAsGivenAndEmptyMeansNone() {
        let withTempo = StandbyOverlayDecision(currentSectionIdx: 0, currentSectionName: "Verse", songName: "Circuz",
                                               isFollower: false, tempoLine: "121 \u{00B7} 4/4")
        XCTAssertEqual(withTempo.tempoLine, "121 \u{00B7} 4/4")
        let follower = StandbyOverlayDecision(currentSectionIdx: 0, currentSectionName: "Verse", songName: "Marea",
                                              isFollower: true, tempoLine: "96 \u{00B7} 3/4")
        XCTAssertEqual(follower.tempoLine, "96 \u{00B7} 3/4")
        XCTAssertNil(decision(sectionIdx: 0).tempoLine)                    // non passata
        XCTAssertNil(StandbyOverlayDecision(currentSectionIdx: 0, currentSectionName: "Verse", songName: "Circuz",
                                            isFollower: false, tempoLine: "").tempoLine)   // vuota = nessuna riga
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
