import XCTest

// === A421 · SEGUITO 3 (31/10/2026) — banco della memoria della crisi del Solo (`CrisisMemoryDecision`, banco Models), mandato par. 2 ===
// La matrice: ruolo × causa × motore in moto × show × canzone × già muto = 3 × 9 × 2 × 2 × 2 × 2 = 432 celle, con l'atteso scritto
// qui dalla regola del mandato (par. 2.2) e non ricavato dal tipo: per il Solo a motore fermo con una causa che non lo ferma la
// memoria resta («invariati»); con l'esito «niente» non si tocca («niente», come oggi); in ogni altro caso si riscrive («riscrive»,
// come oggi). Poi le tre sequenze del par. 2.1 sulle regole pure (la coppia dopo il passo, m4 e `RecoveryDecision` coi valori
// giusti), com'era e da qui, e la catena viva senza Stop (par. 2.4).

final class CrisisMemoryDecisionTests: XCTestCase {

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]

    private func step(_ role: PlayerRole, _ cause: CrisisCause, running: Bool, show: Bool = true, song: Bool = true,
                      silent: Bool = false) -> CrisisMemoryStep {
        let outcome = CrisisStopDecision.outcome(playerRole: role, cause: cause, showOpen: show, songInProgress: song,
                                                 engineRunning: running, silentInSong: silent)
        return CrisisMemoryDecision.step(playerRole: role, cause: cause, engineRunning: running, outcome: outcome)
    }

    private func soloAtBegin(_ memory: (cause: CrisisCause?, wantedStopSinceCrisis: Bool)) -> InterruptionActivationDecision.SoloInterruptionBeginStep {
        InterruptionActivationDecision.soloAtInterruptionBegin(playerRole: .solo, engineRunning: false, pendingResume: false,
                                                               wantedStopSinceCrisis: memory.wantedStopSinceCrisis,
                                                               crisisCause: memory.cause)
    }

    // MARK: - La matrice

    /// L'atteso dalla regola del mandato: «niente» non tocca la memoria; il Solo a motore fermo con una causa che non lo ferma la
    /// tiene; tutto il resto come oggi.
    func testTheMatrix() {
        var cells = 0
        var kept = 0
        for role in roles {
            for cause in CrisisCause.allCases {
                for running in bools {
                    for show in bools {
                        for song in bools {
                            for silent in bools {
                                cells += 1
                                let outcome = CrisisStopDecision.outcome(playerRole: role, cause: cause, showOpen: show, songInProgress: song,
                                                                         engineRunning: running, silentInSong: silent)
                                let got = CrisisMemoryDecision.step(playerRole: role, cause: cause, engineRunning: running, outcome: outcome)
                                let expected: CrisisMemoryStep
                                if outcome == .nothing {
                                    expected = .nothing
                                } else if role == .solo && !running && !cause.stopsSolo {
                                    expected = .keep
                                } else {
                                    expected = .rewrite
                                }
                                XCTAssertEqual(got, expected, "ruolo:\(role) causa:\(cause) motore:\(running) show:\(show) canzone:\(song) muto:\(silent)")
                                if got == .keep { kept += 1 }
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 3 * 9 * 2 * 2 * 2 * 2)
        // «Invariati» solo per il Solo a motore fermo con le quattro cause che non lo fermano, qualunque show, canzone, muto.
        XCTAssertEqual(kept, 4 * 2 * 2 * 2)
    }

    // MARK: - Il Solo

    /// A motore fermo: le quattro cause che non lo fermano (configurazione, modo, «uscita-aggiunta», «buco-del-render») tengono la
    /// memoria; le cinque che lo fermano danno «niente» (non c'era niente da fermare: come oggi). Col motore in moto, come oggi.
    func testTheSoloAtEngineStoppedKeepsItsMemoryForTheCausesThatDoNotStopIt() {
        for cause in [CrisisCause.configuration, .mode, .outputAdded, .renderGap] {
            XCTAssertFalse(cause.stopsSolo)
            XCTAssertEqual(step(.solo, cause, running: false), .keep, "\(cause)")
            XCTAssertEqual(step(.solo, cause, running: true), .rewrite, "\(cause): col motore in moto come oggi")
        }
        for cause in [CrisisCause.interruption, .servicesLost, .resetWithoutLost, .resetAfterLost, .outputRemoved] {
            XCTAssertTrue(cause.stopsSolo)
            XCTAssertEqual(step(.solo, cause, running: false), .nothing, "\(cause): niente da fermare, la memoria non si tocca come oggi")
            XCTAssertEqual(step(.solo, cause, running: true), .rewrite, "\(cause): fermo come allo Stop della console, la causa si ricorda")
        }
    }

    /// Direttore e Follower: come oggi, qualunque causa e stato: riscrive dove l'esito non è «niente».
    func testTheOtherRolesAreAsToday() {
        for role in [PlayerRole.direttore, .follower] {
            for cause in CrisisCause.allCases {
                for running in bools {
                    for silent in bools {
                        let outcome = CrisisStopDecision.outcome(playerRole: role, cause: cause, showOpen: true, songInProgress: true,
                                                                 engineRunning: running, silentInSong: silent)
                        let got = CrisisMemoryDecision.step(playerRole: role, cause: cause, engineRunning: running, outcome: outcome)
                        XCTAssertEqual(got, outcome == .nothing ? .nothing : .rewrite, "ruolo:\(role) causa:\(cause) motore:\(running) muto:\(silent)")
                        XCTAssertNotEqual(got, .keep, "«invariati» è solo del Solo")
                    }
                }
            }
        }
    }

    // MARK: - La memoria dopo il passo

    /// Con «invariati» e «niente» la coppia non cambia; con «riscrive» la causa di `rememberedCause` (appiccicosa per il Solo) e lo
    /// Stop voluto a falso.
    func testTheMemoryAfterTheStep() {
        for previous in [nil, CrisisCause.configuration, .interruption, .outputRemoved] {
            for wanted in bools {
                for cause in CrisisCause.allCases {
                    for stepKept in [CrisisMemoryStep.keep, .nothing] {
                        let after = CrisisMemoryDecision.memoryAfter(step: stepKept, previousCause: previous, wantedStopSinceCrisis: wanted,
                                                                     cause: cause, playerRole: .solo)
                        XCTAssertEqual(after.cause, previous, "\(stepKept) \(String(describing: previous)) \(cause)")
                        XCTAssertEqual(after.wantedStopSinceCrisis, wanted, "\(stepKept) \(String(describing: previous)) \(cause)")
                    }
                    for role in roles {
                        let after = CrisisMemoryDecision.memoryAfter(step: .rewrite, previousCause: previous, wantedStopSinceCrisis: wanted,
                                                                     cause: cause, playerRole: role)
                        XCTAssertEqual(after.cause, CrisisStopDecision.rememberedCause(previous: previous, new: cause, playerRole: role),
                                       "\(role) \(String(describing: previous)) \(cause)")
                        XCTAssertFalse(after.wantedStopSinceCrisis)
                    }
                }
            }
        }
    }

    // MARK: - Le tre sequenze del par. 2.1 sulle regole pure

    /// (a) Il Solo fermo con lo Stop della console («Resume from»: causa nulla, Stop voluto), un cambio di modo a motore fermo, un
    /// inizio d'interruzione: da qui la memoria resta e m4 non ferma («niente Stop, era gia' fermo»); com'era, la causa diventava
    /// «modo» e lo Stop voluto falso, m4 vedeva «ripartenza in corso» e il Solo si fermava una seconda volta.
    func testSequenceAOnResumeFromAModeChangeAndACall() {
        let modeStep = step(.solo, .mode, running: false)
        XCTAssertEqual(modeStep, .keep)
        let kept = CrisisMemoryDecision.memoryAfter(step: modeStep, previousCause: nil, wantedStopSinceCrisis: true, cause: .mode, playerRole: .solo)
        XCTAssertNil(kept.cause)
        XCTAssertTrue(kept.wantedStopSinceCrisis)
        XCTAssertEqual(soloAtBegin(kept), .closeChainAndRemember(stop: false), "niente secondo Stop: lo schermo resta su Resume from")
        let today = CrisisMemoryDecision.memoryAfter(step: .rewrite, previousCause: nil, wantedStopSinceCrisis: true, cause: .mode, playerRole: .solo)
        XCTAssertEqual(today.cause, .mode)
        XCTAssertFalse(today.wantedStopSinceCrisis)
        XCTAssertEqual(soloAtBegin(today), .closeChainAndRemember(stop: true), "com'era: il secondo Stop")
        // Dopo l'inizio, con la memoria tenuta, nessuna ripartenza fino al Play, per ogni innesco.
        for trigger in RecoveryTrigger.allCases {
            XCTAssertEqual(RecoveryDecision.route(trigger: trigger, playerRole: .solo, silentInSong: false,
                                                  wantedStopSinceCrisis: kept.wantedStopSinceCrisis, crisisCause: kept.cause), .noRestart, "\(trigger)")
        }
    }

    /// (b) Il Solo mai partito (causa nulla, nessuno Stop voluto), un cambio di modo, un inizio d'interruzione: da qui niente Stop e
    /// niente riga di Stop («mai suonato»); com'era, la causa diventava «modo» e il Solo si fermava senza essere mai partito.
    func testSequenceBNeverStartedAModeChangeAndACall() {
        let kept = CrisisMemoryDecision.memoryAfter(step: step(.solo, .mode, running: false), previousCause: nil, wantedStopSinceCrisis: false,
                                                    cause: .mode, playerRole: .solo)
        XCTAssertNil(kept.cause)
        XCTAssertFalse(kept.wantedStopSinceCrisis)
        XCTAssertEqual(soloAtBegin(kept), .closeChainAndRemember(stop: false), "mai suonato: niente Stop")
        let today = CrisisMemoryDecision.memoryAfter(step: .rewrite, previousCause: nil, wantedStopSinceCrisis: false, cause: .mode, playerRole: .solo)
        XCTAssertEqual(soloAtBegin(today), .closeChainAndRemember(stop: true), "com'era: lo Stop falso")
        // Le altre tre cause che non fermano il Solo fanno lo stesso.
        for cause in [CrisisCause.configuration, .outputAdded, .renderGap] {
            let after = CrisisMemoryDecision.memoryAfter(step: step(.solo, cause, running: false), previousCause: nil, wantedStopSinceCrisis: false,
                                                         cause: cause, playerRole: .solo)
            XCTAssertNil(after.cause, "\(cause)")
            XCTAssertEqual(soloAtBegin(after), .closeChainAndRemember(stop: false), "\(cause)")
        }
    }

    /// (c) La catena di ripartenza in volo: la crisi «configurazione» col motore in moto (riscrive), lo Stop della console (lo Stop
    /// voluto alzato), poi un cambio di modo a motore fermo: da qui la memoria resta e il tentativo dopo dà «niente»; com'era, lo
    /// Stop voluto tornava falso, la causa «modo», e il tentativo passava («avvio-come-oggi»): il Solo fermato dall'utente ripartiva.
    func testSequenceCTheChainInFlightTheStopAndAModeChange() {
        let configuration = CrisisMemoryDecision.memoryAfter(step: step(.solo, .configuration, running: true), previousCause: nil,
                                                             wantedStopSinceCrisis: false, cause: .configuration, playerRole: .solo)
        XCTAssertEqual(configuration.cause, .configuration)
        XCTAssertFalse(configuration.wantedStopSinceCrisis)
        // Lo Stop della console alza lo Stop voluto (`stopSync(.wanted)`), senza toccare la causa.
        let stopped = (cause: configuration.cause, wantedStopSinceCrisis: true)
        for trigger in RecoveryTrigger.allCases {
            XCTAssertEqual(RecoveryDecision.route(trigger: trigger, playerRole: .solo, silentInSong: false,
                                                  wantedStopSinceCrisis: stopped.wantedStopSinceCrisis, crisisCause: stopped.cause), .noRestart,
                           "\(trigger): dopo lo Stop il tentativo dopo si ferma")
        }
        let kept = CrisisMemoryDecision.memoryAfter(step: step(.solo, .mode, running: false), previousCause: stopped.cause,
                                                    wantedStopSinceCrisis: stopped.wantedStopSinceCrisis, cause: .mode, playerRole: .solo)
        XCTAssertEqual(kept.cause, .configuration)
        XCTAssertTrue(kept.wantedStopSinceCrisis)
        for trigger in RecoveryTrigger.allCases {
            XCTAssertEqual(RecoveryDecision.route(trigger: trigger, playerRole: .solo, silentInSong: false,
                                                  wantedStopSinceCrisis: kept.wantedStopSinceCrisis, crisisCause: kept.cause), .noRestart,
                           "\(trigger): il Solo fermato dall'utente non riparte")
        }
        let today = CrisisMemoryDecision.memoryAfter(step: .rewrite, previousCause: stopped.cause, wantedStopSinceCrisis: true,
                                                     cause: .mode, playerRole: .solo)
        XCTAssertEqual(today.cause, .mode)
        XCTAssertFalse(today.wantedStopSinceCrisis)
        XCTAssertEqual(RecoveryDecision.route(trigger: .engineConfigChange, playerRole: .solo, silentInSong: false,
                                              wantedStopSinceCrisis: today.wantedStopSinceCrisis, crisisCause: today.cause), .startAsToday,
                       "com'era: il tentativo dopo passava")
    }

    /// La catena viva senza Stop (par. 2.4): la crisi «configurazione» col motore in moto, un cambio di modo a motore fermo fra due
    /// tentativi: riparte come oggi; la causa ricordata resta «configurazione» (oggi diventava «modo»: stesso esito).
    func testTheLiveChainWithoutAStopRestartsAndKeepsTheCause() {
        let configuration = CrisisMemoryDecision.memoryAfter(step: step(.solo, .configuration, running: true), previousCause: nil,
                                                             wantedStopSinceCrisis: false, cause: .configuration, playerRole: .solo)
        let kept = CrisisMemoryDecision.memoryAfter(step: step(.solo, .mode, running: false), previousCause: configuration.cause,
                                                    wantedStopSinceCrisis: configuration.wantedStopSinceCrisis, cause: .mode, playerRole: .solo)
        XCTAssertEqual(kept.cause, .configuration, "la causa resta «configurazione»")
        XCTAssertFalse(kept.wantedStopSinceCrisis)
        let today = CrisisMemoryDecision.memoryAfter(step: .rewrite, previousCause: configuration.cause, wantedStopSinceCrisis: false,
                                                     cause: .mode, playerRole: .solo)
        XCTAssertEqual(today.cause, .mode)
        for trigger in RecoveryTrigger.allCases {
            XCTAssertEqual(RecoveryDecision.route(trigger: trigger, playerRole: .solo, silentInSong: false,
                                                  wantedStopSinceCrisis: kept.wantedStopSinceCrisis, crisisCause: kept.cause), .startAsToday, "\(trigger)")
            XCTAssertEqual(RecoveryDecision.route(trigger: trigger, playerRole: .solo, silentInSong: false,
                                                  wantedStopSinceCrisis: today.wantedStopSinceCrisis, crisisCause: today.cause), .startAsToday,
                           "\(trigger): stesso esito di oggi")
        }
        // m4 a motore fermo con la catena viva: «ripartenza in corso» con tutte e due le memorie.
        XCTAssertEqual(soloAtBegin(kept), .closeChainAndRemember(stop: true))
        XCTAssertEqual(soloAtBegin(today), .closeChainAndRemember(stop: true))
    }

    /// Il Solo in moto con un cambio di modo, e una causa che ferma il Solo a motore fermo: come oggi.
    func testTheSoloInMotionAndAStoppingCauseAtEngineStoppedAreAsToday() {
        let inMotion = CrisisMemoryDecision.memoryAfter(step: step(.solo, .mode, running: true), previousCause: nil, wantedStopSinceCrisis: true,
                                                        cause: .mode, playerRole: .solo)
        XCTAssertEqual(inMotion.cause, .mode)
        XCTAssertFalse(inMotion.wantedStopSinceCrisis)
        for cause in [CrisisCause.interruption, .servicesLost, .resetWithoutLost, .resetAfterLost, .outputRemoved] {
            let stopping = step(.solo, cause, running: false)
            XCTAssertEqual(stopping, .nothing, "\(cause)")
            let after = CrisisMemoryDecision.memoryAfter(step: stopping, previousCause: .configuration, wantedStopSinceCrisis: true,
                                                         cause: cause, playerRole: .solo)
            XCTAssertEqual(after.cause, .configuration, "\(cause): niente da fermare, la memoria come oggi")
            XCTAssertTrue(after.wantedStopSinceCrisis, "\(cause)")
        }
    }

    func testTheNamesInTheLines() {
        XCTAssertEqual(CrisisMemoryStep.rewrite.rawValue, "riscrive")
        XCTAssertEqual(CrisisMemoryStep.keep.rawValue, "invariati")
        XCTAssertEqual(CrisisMemoryStep.nothing.rawValue, "niente")
        XCTAssertEqual(CrisisMemoryStep.allCases.count, 3)
    }
}
