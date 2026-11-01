import XCTest

// === A412 — banco della regola delle crisi (`CrisisStopDecision`, banco Models), mandato §2.1 e §2.7 ===
// La matrice: ruolo del player × causa × show aperto × canzone in corso × motore in moto × già muto in
// canzone = 3 × 6 × 2 × 2 × 2 × 2 = 288 celle, con l'atteso scritto qui dalla regola del mandato (e non
// ricavato dal tipo). Poi i casi per esteso: il Direttore in canzone tace a ogni causa; senza show o
// senza canzone si ferma in locale; già muto resta muto; il Solo alle crisi della sessione audio si
// ferma come allo Stop della console e a configurazione e modo è com'è; il Follower è sempre com'è; il
// ruolo Direttore con la levetta spenta è un Solo. E il cuore del mandato: nessuna crisi manda Stop a
// Link, per nessun ruolo.
// ⚠️ A421 (24/10/2026): le cause sono nove (mandato A421, par. 2.1 U4: «uscita-tolta», «uscita-aggiunta»,
// «buco-del-render»), la matrice 3 × 9 × 2 × 2 × 2 × 2 = 432 celle. Il Solo si ferma come allo Stop della
// console alle cause che lo fermano (`stopsSolo`: le quattro della sessione audio e «uscita-tolta»); a
// «uscita-aggiunta» e «buco-del-render» è com'è, come a configurazione e modo. La causa ricordata per le
// ripartenze è appiccicosa per il Solo (`rememberedCause`).

final class CrisisStopDecisionTests: XCTestCase {

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]

    private func outcome(_ role: PlayerRole, _ cause: CrisisCause, show: Bool = true, song: Bool = true,
                         running: Bool = true, silent: Bool = false) -> CrisisStopOutcome {
        CrisisStopDecision.outcome(playerRole: role, cause: cause, showOpen: show,
                                   songInProgress: song, engineRunning: running, silentInSong: silent)
    }

    // MARK: - Il Direttore

    /// A show aperto con la canzone in corso e il click in moto: muto in canzone, a ogni causa (Siri,
    /// sveglia, timer, chiamata, Lost, i due reset, configurazione, modo).
    func testDirectorInSongGoesSilentForEveryCause() {
        for cause in CrisisCause.allCases {
            XCTAssertEqual(outcome(.direttore, cause), .silentInSong, "causa:\(cause)")
        }
    }

    /// Senza show o senza canzone in corso: arresto locale, nessuno Stop verso Link.
    func testDirectorWithoutShowOrSongStopsLocally() {
        for cause in CrisisCause.allCases {
            XCTAssertEqual(outcome(.direttore, cause, show: false), .localStop, "senza show - causa:\(cause)")
            XCTAssertEqual(outcome(.direttore, cause, song: false), .localStop, "senza canzone - causa:\(cause)")
            XCTAssertEqual(outcome(.direttore, cause, show: false, song: false), .localStop, "né show né canzone - causa:\(cause)")
        }
    }

    /// Già muto in canzone (una crisi nuova durante il silenzio, a motore fermo): resta muto, qualunque
    /// cosa dicano gli altri ingressi.
    func testDirectorAlreadySilentStaysSilent() {
        for cause in CrisisCause.allCases {
            for show in bools {
                for song in bools {
                    for running in bools {
                        XCTAssertEqual(outcome(.direttore, cause, show: show, song: song, running: running, silent: true),
                                       .silentInSong, "causa:\(cause) show:\(show) canzone:\(song) motore:\(running)")
                    }
                }
            }
        }
    }

    /// Motore fermo e nessun silenzio in corso: niente da fermare.
    func testDirectorNotRunningAndNotSilentDoesNothing() {
        for cause in CrisisCause.allCases {
            XCTAssertEqual(outcome(.direttore, cause, running: false), .nothing, "causa:\(cause)")
        }
    }

    // MARK: - Il Solo

    /// Alle crisi della sessione audio (interruzione, Lost, i due reset), col click in moto: come lo Stop
    /// della sua console. A motore fermo niente (alla Reset dopo la Lost l'ha già fermato la Lost).
    func testSoloStopsAsItsConsoleOnAudioSessionCrises() {
        for cause in [CrisisCause.interruption, .servicesLost, .resetWithoutLost, .resetAfterLost] {
            XCTAssertEqual(outcome(.solo, cause), .soloStopAsConsole, "causa:\(cause)")
            XCTAssertEqual(outcome(.solo, cause, show: false, song: false), .soloStopAsConsole, "senza show - causa:\(cause)")
            XCTAssertEqual(outcome(.solo, cause, running: false), .nothing, "motore fermo - causa:\(cause)")
        }
    }

    /// Configurazione e modo nel Solo: com'è oggi (ripartono da sole, non sono interruzioni). A421: anche
    /// «uscita-aggiunta» (par. 2.2 f: la cura è del pezzo 3) e «buco-del-render» (il Solo non ha una band).
    func testSoloAsTodayOnConfigurationAndMode() {
        for cause in [CrisisCause.configuration, .mode, .outputAdded, .renderGap] {
            for running in bools {
                XCTAssertEqual(outcome(.solo, cause, running: running), .asToday, "causa:\(cause) motore:\(running)")
            }
        }
    }

    /// A421 — «uscita-tolta» nel Solo: come lo Stop della console col click in moto (le cuffie staccate: il Solo si ferma e
    /// riparte col Play, decisione di Mauro del 20/10); a motore fermo niente.
    func testSoloStopsAsItsConsoleOnOutputRemoved() {
        XCTAssertEqual(outcome(.solo, .outputRemoved), .soloStopAsConsole)
        XCTAssertEqual(outcome(.solo, .outputRemoved, show: false, song: false), .soloStopAsConsole)
        XCTAssertEqual(outcome(.solo, .outputRemoved, running: false), .nothing)
        XCTAssertTrue(CrisisCause.outputRemoved.stopsSolo)
        XCTAssertFalse(CrisisCause.outputRemoved.isAudioSessionCrisis)
    }

    /// A421 — la causa ricordata (`rememberedCause`): per il Solo una causa che lo ferma resta finché non riparte col Play;
    /// una crisi dopo che non lo ferma (configurazione, modo, un'uscita che compare, un buco) non la cancella. Per il
    /// Direttore e il Follower, e per il Solo senza una causa che lo ferma, la causa è la nuova.
    func testRememberedCauseIsStickyForTheSolo() {
        for sticky in CrisisCause.allCases where sticky.stopsSolo {
            for later in CrisisCause.allCases where !later.stopsSolo {
                XCTAssertEqual(CrisisStopDecision.rememberedCause(previous: sticky, new: later, playerRole: .solo), sticky,
                               "prima:\(sticky) dopo:\(later)")
                XCTAssertEqual(CrisisStopDecision.rememberedCause(previous: sticky, new: later, playerRole: .direttore), later,
                               "prima:\(sticky) dopo:\(later)")
                XCTAssertEqual(CrisisStopDecision.rememberedCause(previous: sticky, new: later, playerRole: .follower), later,
                               "prima:\(sticky) dopo:\(later)")
            }
            // Una causa che ferma dopo una che ferma: la nuova.
            XCTAssertEqual(CrisisStopDecision.rememberedCause(previous: sticky, new: .interruption, playerRole: .solo), .interruption)
        }
        XCTAssertEqual(CrisisStopDecision.rememberedCause(previous: .configuration, new: .mode, playerRole: .solo), .mode)
        XCTAssertEqual(CrisisStopDecision.rememberedCause(previous: nil, new: .mode, playerRole: .solo), .mode)
        XCTAssertEqual(CrisisStopDecision.rememberedCause(previous: .mode, new: .outputRemoved, playerRole: .solo), .outputRemoved)
    }

    /// Il ruolo Direttore con la levetta spenta è un Solo (`PlayerRoleDecision`).
    func testDirectorRoleWithTheUserSwitchOffIsSolo() {
        let role = PlayerRoleDecision.playerRole(role: .direttore, userLinkEnabled: false)
        XCTAssertEqual(role, .solo)
        XCTAssertEqual(outcome(role, .interruption), .soloStopAsConsole)
        XCTAssertEqual(outcome(role, .configuration), .asToday)
    }

    // MARK: - Il Follower

    /// Il Follower non cambia: com'è oggi a ogni causa e in ogni stato.
    func testFollowerIsAlwaysAsToday() {
        for cause in CrisisCause.allCases {
            for show in bools {
                for song in bools {
                    for running in bools {
                        for silent in bools {
                            XCTAssertEqual(outcome(.follower, cause, show: show, song: song, running: running, silent: silent),
                                           .asToday, "causa:\(cause) show:\(show) canzone:\(song) motore:\(running) muto:\(silent)")
                        }
                    }
                }
            }
        }
    }

    // MARK: - La matrice

    /// L'atteso di una cella, dalla regola del mandato §2.1 e §2.7.
    private func expected(_ role: PlayerRole, _ cause: CrisisCause, show: Bool, song: Bool,
                          running: Bool, silent: Bool) -> CrisisStopOutcome {
        switch role {
        case .follower:
            return .asToday
        case .solo:
            // A421: le cause che fermano il Solo sono le quattro della sessione audio e «uscita-tolta».
            if !cause.stopsSolo { return .asToday }
            return running ? .soloStopAsConsole : .nothing
        case .direttore:
            if silent { return .silentInSong }
            if !running { return .nothing }
            if show && song { return .silentInSong }
            return .localStop
        }
    }

    func testTheMatrix() {
        var cells = 0
        for role in roles {
            for cause in CrisisCause.allCases {
                for show in bools {
                    for song in bools {
                        for running in bools {
                            for silent in bools {
                                cells += 1
                                let got = outcome(role, cause, show: show, song: song, running: running, silent: silent)
                                let tag = "ruolo:\(role) causa:\(cause) show:\(show) canzone:\(song) motore:\(running) muto:\(silent)"
                                XCTAssertEqual(got, expected(role, cause, show: show, song: song, running: running, silent: silent), tag)
                                // Nessuna crisi manda Stop a Link, per nessun ruolo (mandato §2.1).
                                XCTAssertFalse(got.sendsStopToLink, tag)
                                // Solo il Direttore diventa muto in canzone.
                                if got == .silentInSong { XCTAssertEqual(role, .direttore, tag) }
                                // Solo il Solo si ferma come allo Stop della console.
                                if got == .soloStopAsConsole { XCTAssertEqual(role, .solo, tag) }
                            }
                        }
                    }
                }
            }
        }
        // A421: nove cause.
        XCTAssertEqual(cells, 3 * 9 * 2 * 2 * 2 * 2)
    }

    // MARK: - Nessuno Stop a Link; le cause

    func testNoCrisisSendsStopToLink() {
        XCTAssertFalse(CrisisStopDecision.sendsStopToLink)
        for o in [CrisisStopOutcome.silentInSong, .localStop, .soloStopAsConsole, .asToday, .nothing] {
            XCTAssertFalse(o.sendsStopToLink, "\(o)")
        }
    }

    func testTheCauses() {
        // A421: nove cause (le sei di A412 più le tre dell'uscita audio).
        XCTAssertEqual(CrisisCause.allCases.count, 9)
        XCTAssertTrue(CrisisCause.interruption.isAudioSessionCrisis)
        XCTAssertTrue(CrisisCause.servicesLost.isAudioSessionCrisis)
        XCTAssertTrue(CrisisCause.resetWithoutLost.isAudioSessionCrisis)
        XCTAssertTrue(CrisisCause.resetAfterLost.isAudioSessionCrisis)
        XCTAssertFalse(CrisisCause.configuration.isAudioSessionCrisis)
        XCTAssertFalse(CrisisCause.mode.isAudioSessionCrisis)
        XCTAssertFalse(CrisisCause.outputRemoved.isAudioSessionCrisis)
        XCTAssertFalse(CrisisCause.outputAdded.isAudioSessionCrisis)
        XCTAssertFalse(CrisisCause.renderGap.isAudioSessionCrisis)
        // `stopsSolo`: le quattro della sessione audio e «uscita-tolta», nessun'altra.
        for cause in CrisisCause.allCases {
            XCTAssertEqual(cause.stopsSolo, cause.isAudioSessionCrisis || cause == .outputRemoved, "\(cause)")
        }
        XCTAssertEqual(CrisisCause.allCases.filter { $0.stopsSolo }.count, 5)
        XCTAssertEqual(CrisisCause.interruption.rawValue, "interruzione")
        XCTAssertEqual(CrisisCause.servicesLost.rawValue, "servizi-persi")
        XCTAssertEqual(CrisisCause.resetWithoutLost.rawValue, "reset-senza-lost")
        XCTAssertEqual(CrisisCause.resetAfterLost.rawValue, "reset-dopo-la-lost")
        XCTAssertEqual(CrisisCause.configuration.rawValue, "configurazione")
        XCTAssertEqual(CrisisCause.mode.rawValue, "modo")
        XCTAssertEqual(CrisisCause.outputRemoved.rawValue, "uscita-tolta")
        XCTAssertEqual(CrisisCause.outputAdded.rawValue, "uscita-aggiunta")
        XCTAssertEqual(CrisisCause.renderGap.rawValue, "buco-del-render")
        XCTAssertEqual(CrisisStopOutcome.silentInSong.rawValue, "muto-in-canzone")
        XCTAssertEqual(CrisisStopOutcome.soloStopAsConsole.rawValue, "come-lo-stop-della-console")
    }
}
