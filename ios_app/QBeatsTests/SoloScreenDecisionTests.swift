import XCTest

// === A398 · SOLO-G1-PEZZO-1-M3 — banco della regola degli schermi del Solo (banco Models) ===
// Per ogni caso di `LivePlaybackState` e per indice 0 e > 0: lo schermo, le parole («Next», «Resume from » con la
// sezione o «Section N», «Tap to start»), il tocco (V1/V2: la canzone; H: niente), il tasto (H: Play dalla
// sezione); tempo e metrica con BPM non intero (180,5 e 9/8 → «181 · 9/8», Costituzione §6); il titolo della
// testata (lo show sui veli e su V4, la canzone in K; vuoto su V4 per Direttore e Follower).
// ⚠️ A401 · Solo REV20 — punto 117: su V4 il nome dello show sta in testata per i tre ruoli («vuoto su V4 per
// Direttore e Follower» qui sopra è storia); la riga di stato resta del solo Solo. Punto 116: una canzone senza nome
// è «Song N» sui veli, su H e nel titolo di K, N = il posto nello show.

final class SoloScreenDecisionTests: XCTestCase {

    private let states: [LivePlaybackState] = [
        .standby(nextSongName: "Circuz"), .countIn(countdown: 4), .playing, .stopped, .loopActive,
        .overlayStop(sectionName: "Bridge", songName: "Circuz"), .fineSetlist, .starting,
    ]

    private func screen(_ state: LivePlaybackState, sectionIndex: Int = 0, sectionName: String? = "Verse",
                        currentSongName: String? = "Circuz", showName: String? = "Milano Assago",
                        songNameInMotion: String = "Circuz", songNumber: Int = 1, displayWritten: Bool = true,
                        bpm: Double? = 121, beats: UInt32? = 4,
                        unit: UInt32? = 4) -> SoloScreen {
        SoloScreenDecision.screen(state: state, sectionIndex: sectionIndex, sectionName: sectionName,
                                  currentSongName: currentSongName, showName: showName,
                                  songNameInMotion: songNameInMotion, songNumber: songNumber,
                                  displayWritten: displayWritten, sectionBPM: bpm,
                                  sectionBeatsPerBar: beats, sectionBeatUnit: unit)
    }

    func testTheStatesOfThePlayerAreEight() {
        XCTAssertEqual(states.count, 8)
    }

    // MARK: - Stato → schermo, per indice 0 e > 0

    func testEveryStateHasItsScreenForIndexZeroAndAbove() {
        let expected: [(LivePlaybackState, SoloScreenKind, SoloScreenKind)] = [
            (.standby(nextSongName: "Circuz"), .veil, .resume),
            (.countIn(countdown: 4), .playing, .playing),
            (.playing, .playing, .playing),
            (.stopped, .resume, .resume),
            (.loopActive, .playing, .playing),
            (.overlayStop(sectionName: "Bridge", songName: "Circuz"), .overlayStop, .overlayStop),
            (.fineSetlist, .endShow, .endShow),
            (.starting, .playing, .playing),
        ]
        XCTAssertEqual(expected.count, states.count)
        for (state, atZero, above) in expected {
            XCTAssertEqual(screen(state, sectionIndex: 0).kind, atZero, "stato \(state), indice 0")
            XCTAssertEqual(screen(state, sectionIndex: 3).kind, above, "stato \(state), indice 3")
        }
    }

    // MARK: - V1/V2

    func testTheVeilSaysNextTheSongTheTempoAndTapToStart() {
        let s = screen(.standby(nextSongName: "Verde Rame"), sectionIndex: 0, bpm: 108, beats: 4, unit: 4)
        XCTAssertEqual(s.kind, .veil)
        XCTAssertEqual(s.relationPrefix, "Next")
        XCTAssertNil(s.relationSection)
        XCTAssertEqual(s.relationLine, "Next")
        XCTAssertEqual(s.songName, "Verde Rame")
        XCTAssertEqual(s.tempoLine, "108 \u{00B7} 4/4")
        XCTAssertEqual(s.gestureLine, "Tap to start")
        XCTAssertEqual(s.tap, .startSong)
        XCTAssertFalse(s.consoleVisible)
        XCTAssertFalse(s.playStartsSection)
        XCTAssertEqual(s.headerTitle, "Milano Assago")
        XCTAssertTrue(s.statusRow)
        XCTAssertNotEqual(s.relationLine, "Next:", "«Next» senza i due punti")
    }

    // MARK: - H senza la fila

    func testAfterTheStopItIsResumeFromTheSectionWithThePlay() {
        let s = screen(.stopped, sectionIndex: 3, sectionName: "Bridge", currentSongName: "Circuz")
        XCTAssertEqual(s.kind, .resume)
        XCTAssertEqual(s.relationPrefix, "Resume from ")
        XCTAssertEqual(s.relationSection, "Bridge")
        XCTAssertEqual(s.relationLine, "Resume from Bridge")
        XCTAssertEqual(s.songName, "Circuz", "la canzone che il Play fa ripartire: `runner.currentSong`")
        XCTAssertEqual(s.tempoLine, "121 \u{00B7} 4/4")
        XCTAssertNil(s.gestureLine, "niente «Tap to start» dopo lo Stop (punto 87)")
        XCTAssertEqual(s.tap, .none)
        XCTAssertTrue(s.consoleVisible)
        XCTAssertTrue(s.playStartsSection)
        XCTAssertEqual(s.headerTitle, "Milano Assago")
    }

    func testTheReturnWithAKeptSectionIsResumeWithTheStandbyName() {
        // `.standby` con indice > 0: il nome dal caso `.standby(nextSongName:)`, come in V1.
        let s = screen(.standby(nextSongName: "Mare"), sectionIndex: 2, sectionName: "Chorus", currentSongName: "Altro")
        XCTAssertEqual(s.kind, .resume)
        XCTAssertEqual(s.songName, "Mare")
        XCTAssertEqual(s.relationLine, "Resume from Chorus")
        XCTAssertEqual(s.tap, .none)
        XCTAssertTrue(s.playStartsSection)
    }

    func testAStoppedSectionWithoutANameIsSectionN() {
        // Punto 109: senza nome, o con soli spazi, «Section N», N = indice + 1.
        XCTAssertEqual(screen(.stopped, sectionIndex: 2, sectionName: "").relationLine, "Resume from Section 3")
        XCTAssertEqual(screen(.stopped, sectionIndex: 0, sectionName: "   ").relationLine, "Resume from Section 1")
        XCTAssertEqual(screen(.standby(nextSongName: "Mare"), sectionIndex: 4, sectionName: nil).relationLine,
                       "Resume from Section 5")
    }

    func testAStopWithoutASongNameLeavesTheNameEmpty() {
        let s = screen(.stopped, sectionIndex: 1, currentSongName: nil)
        XCTAssertEqual(s.kind, .resume)
        XCTAssertEqual(s.songName, "")
    }

    // MARK: - V4

    func testTheEndOfTheSetlistIsEndShowWithTheShowInTheHeader() {
        let s = screen(.fineSetlist)
        XCTAssertEqual(s.kind, .endShow)
        XCTAssertEqual(s.headerTitle, "Milano Assago")
        XCTAssertTrue(s.statusRow)
        XCTAssertFalse(s.consoleVisible)
        XCTAssertEqual(s.tap, .none)
        XCTAssertNil(s.gestureLine)
    }

    func testEndShowHeaderForTheThreeRoles() {
        // A401 — Solo REV20, punto 117: al centro della testata di V4 il nome dello show, per i tre ruoli (fino ad
        // A400 vuoto per Direttore e Follower). La riga di stato resta del solo Solo (decisione 5).
        let roles: [PlayerRole] = [.solo, .direttore, .follower]
        XCTAssertEqual(roles.count, 3)
        for role in roles {
            XCTAssertEqual(SoloScreenDecision.endShowHeaderTitle(role: role, showName: "Milano Assago"), "Milano Assago",
                           "ruolo \(role.rawValue)")
            // Come sui veli: uno show senza nome, o di soli spazi, lascia il centro vuoto; il nome com'è scritto.
            XCTAssertEqual(SoloScreenDecision.endShowHeaderTitle(role: role, showName: nil), "", "ruolo \(role.rawValue)")
            XCTAssertEqual(SoloScreenDecision.endShowHeaderTitle(role: role, showName: "   "), "", "ruolo \(role.rawValue)")
            XCTAssertEqual(SoloScreenDecision.endShowHeaderTitle(role: role, showName: " Milano "), " Milano ",
                           "ruolo \(role.rawValue)")
        }
        XCTAssertTrue(SoloScreenDecision.endShowStatusRow(role: .solo))
        XCTAssertFalse(SoloScreenDecision.endShowStatusRow(role: .direttore))
        XCTAssertFalse(SoloScreenDecision.endShowStatusRow(role: .follower))
        XCTAssertEqual(SoloVeilTypography.endShowWord, "END SHOW")
        XCTAssertEqual(SoloScreenDecision.backToShows, "Back to Shows")
    }

    // MARK: - A401 · Solo REV20, punto 116: una canzone senza nome è «Song N»

    func testAnUnnamedSongOnTheVeilIsSongN() {
        // V1/V2: il nome viene dal caso `.standby(nextSongName:)`, il numero dal posto della canzone del runner.
        let v = screen(.standby(nextSongName: ""), sectionIndex: 0, songNumber: 2)
        XCTAssertEqual(v.kind, .veil)
        XCTAssertEqual(v.songName, "Song 2")
        XCTAssertEqual(screen(.standby(nextSongName: "   "), sectionIndex: 0, songNumber: 7).songName, "Song 7")
        XCTAssertEqual(screen(.standby(nextSongName: "Mare"), sectionIndex: 0, songNumber: 2).songName, "Mare")
        // La lineetta di una canzone che non si risolve (`SetlistRunner.armNextSong`) resta com'è.
        XCTAssertEqual(screen(.standby(nextSongName: "\u{2014}"), sectionIndex: 0, songNumber: 2).songName, "\u{2014}")
    }

    func testAnUnnamedSongOnTheResumeScreenIsSongN() {
        // H dopo lo Stop: il nome è `runner.currentSong?.name`.
        let stopped = screen(.stopped, sectionIndex: 2, currentSongName: "", songNumber: 2)
        XCTAssertEqual(stopped.kind, .resume)
        XCTAssertEqual(stopped.songName, "Song 2")
        XCTAssertEqual(screen(.stopped, sectionIndex: 0, currentSongName: "  ", songNumber: 4).songName, "Song 4")
        XCTAssertEqual(screen(.stopped, sectionIndex: 2, currentSongName: "Circuz", songNumber: 2).songName, "Circuz")
        // Una canzone che non si risolve non è una canzone senza nome: il nome resta vuoto (A398 §9, caso 3).
        XCTAssertEqual(screen(.stopped, sectionIndex: 2, currentSongName: nil, songNumber: 2).songName, "")
        // H al rientro con la sezione conservata: il nome dal caso `.standby`, come in V1.
        let kept = screen(.standby(nextSongName: ""), sectionIndex: 3, currentSongName: "Altro", songNumber: 5)
        XCTAssertEqual(kept.kind, .resume)
        XCTAssertEqual(kept.songName, "Song 5")
    }

    func testAnUnnamedSongInMotionIsSongNInTheHeader() {
        for state in [LivePlaybackState.playing, .countIn(countdown: 4), .starting, .loopActive,
                      .overlayStop(sectionName: "Bridge", songName: "")] {
            XCTAssertEqual(screen(state, songNameInMotion: "", songNumber: 2, displayWritten: true).headerTitle, "Song 2",
                           "stato \(state)")
            XCTAssertEqual(screen(state, songNameInMotion: "Circuz", songNumber: 2, displayWritten: true).headerTitle,
                           "Circuz", "stato \(state)")
            // Display non ancora scritto: il titolo resta vuoto, niente «Song N» di passaggio.
            XCTAssertEqual(screen(state, songNameInMotion: "", songNumber: 2, displayWritten: false).headerTitle, "",
                           "stato \(state)")
        }
    }

    func testTheShowNameIsNeverReplacedBySongN() {
        // Sui veli, su H e su V4 la testata dice lo show: «Song N» riguarda il nome della canzone, non la testata.
        XCTAssertEqual(screen(.standby(nextSongName: ""), sectionIndex: 0, songNumber: 2).headerTitle, "Milano Assago")
        XCTAssertEqual(screen(.stopped, sectionIndex: 1, currentSongName: "", songNumber: 2).headerTitle, "Milano Assago")
        XCTAssertEqual(screen(.fineSetlist, songNumber: 2).headerTitle, "Milano Assago")
        XCTAssertEqual(screen(.fineSetlist, songNumber: 2).songName, "")
    }

    // MARK: - K e il pannello superato

    func testInMotionTheHeaderSaysTheSong() {
        for state in [LivePlaybackState.playing, .countIn(countdown: 4), .starting, .loopActive] {
            let s = screen(state, songNameInMotion: "Circuz")
            XCTAssertEqual(s.kind, .playing, "stato \(state)")
            XCTAssertEqual(s.headerTitle, "Circuz", "stato \(state)")
            XCTAssertTrue(s.consoleVisible)
            XCTAssertEqual(s.tap, .none)
        }
        let o = screen(.overlayStop(sectionName: "Bridge", songName: "Circuz"))
        XCTAssertEqual(o.kind, .overlayStop)
        XCTAssertEqual(o.headerTitle, "Circuz")
    }

    // MARK: - Tempo e metrica

    func testTheTempoLineRoundsTheBPMLikeKAndWritesTheMeter() {
        XCTAssertEqual(SoloScreenDecision.tempoLine(bpm: 180.5, beatsPerBar: 9, beatUnit: 8), "181 \u{00B7} 9/8")
        XCTAssertEqual(SoloScreenDecision.tempoLine(bpm: 121, beatsPerBar: 4, beatUnit: 4), "121 \u{00B7} 4/4")
        XCTAssertEqual(SoloScreenDecision.tempoLine(bpm: 160.5, beatsPerBar: 5, beatUnit: 8), "161 \u{00B7} 5/8")
        XCTAssertEqual(SoloScreenDecision.tempoLine(bpm: 110.5, beatsPerBar: 6, beatUnit: 4), "111 \u{00B7} 6/4")
        XCTAssertEqual(SoloScreenDecision.tempoLine(bpm: 84, beatsPerBar: 3, beatUnit: 4), "84 \u{00B7} 3/4")
        XCTAssertEqual(SoloScreenDecision.tempoLine(bpm: nil, beatsPerBar: 4, beatUnit: 4), "")
        XCTAssertEqual(SoloScreenDecision.tempoLine(bpm: 120, beatsPerBar: nil, beatUnit: 4), "")
        XCTAssertEqual(SoloScreenDecision.tempoLine(bpm: 120, beatsPerBar: 4, beatUnit: nil), "")
        XCTAssertEqual(SoloScreenDecision.tempoLine(bpm: Double.nan, beatsPerBar: 4, beatUnit: 4), "")
        XCTAssertEqual(screen(.standby(nextSongName: "Circuz"), bpm: 180.5, beats: 9, unit: 8).tempoLine, "181 \u{00B7} 9/8")
        XCTAssertEqual(screen(.standby(nextSongName: "Circuz"), bpm: nil, beats: nil, unit: nil).tempoLine, "")
    }

    // MARK: - Il nome dello show in testata

    func testAMissingOrBlankShowNameLeavesTheHeaderEmpty() {
        XCTAssertEqual(screen(.standby(nextSongName: "Circuz"), showName: nil).headerTitle, "")
        XCTAssertEqual(screen(.standby(nextSongName: "Circuz"), showName: "   ").headerTitle, "")
        XCTAssertEqual(screen(.stopped, sectionIndex: 1, showName: "").headerTitle, "")
        XCTAssertEqual(screen(.fineSetlist, showName: nil).headerTitle, "")
        XCTAssertEqual(screen(.standby(nextSongName: "Circuz"), showName: " Milano ").headerTitle, " Milano ", "come è scritto")
    }

    func testTheWords() {
        XCTAssertEqual(SoloScreenDecision.nextWord, "Next")
        XCTAssertEqual(SoloScreenDecision.resumePrefix, "Resume from ")
        XCTAssertEqual(SoloScreenDecision.tapToStart, "Tap to start")
        XCTAssertEqual(SoloScreenDecision.tempoSeparator, " \u{00B7} ")
    }
}
