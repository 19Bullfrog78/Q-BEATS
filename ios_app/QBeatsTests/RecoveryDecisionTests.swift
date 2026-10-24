import XCTest

// === A412 — banco della regola delle ripartenze automatiche (`RecoveryDecision`, banco Models), mandato §2.6 ===
// La matrice: innesco × ruolo del player × muto in canzone × Stop voluto dopo la crisi × causa della crisi
// (le sei, più «nessuna») = 9 × 3 × 2 × 2 × 7 = 756 celle, con l'atteso scritto dalla regola del mandato.
// Poi: l'esito non dipende dall'innesco; il Follower è sempre com'è; dopo uno Stop voluto niente; il
// Direttore muto in canzone va al coordinatore; il Solo dopo un'interruzione (Lost e reset compresi) non
// riparte da solo, dopo configurazione e modo sì. E la fine dell'interruzione senza `shouldResume`, che
// rialza la ripresa pendente solo con un'interruzione attiva e nessuno Stop voluto.
// ⚠️ A421 (24/10/2026): gli inneschi sono dodici (`outputAdded`, `renderGap`, `engineStoppedBySystem`), le
// cause nove, e c'è l'ingresso «uscita mancante» (mandato A421, par. 2.1 U4, U5, U6, U7, par. 2.2 a): la
// matrice senza l'uscita mancante è 12 × 3 × 2 × 2 × 10 = 1440 celle, con l'uscita mancante altre 1440. Il
// Direttore con l'uscita mancante ⇒ niente, per ogni innesco; il Solo dopo «uscita-tolta» ⇒ niente.

final class RecoveryDecisionTests: XCTestCase {

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]
    private var causes: [CrisisCause?] { [nil] + CrisisCause.allCases.map { Optional($0) } }

    private func route(_ trigger: RecoveryTrigger = .interruptionEnded, _ role: PlayerRole, silent: Bool = false,
                       wanted: Bool = false, cause: CrisisCause? = .interruption) -> RecoveryRoute {
        RecoveryDecision.route(trigger: trigger, playerRole: role, silentInSong: silent,
                               wantedStopSinceCrisis: wanted, crisisCause: cause)
    }

    /// Il Direttore muto in canzone: il coordinatore, da ogni innesco (fine interruzione, ripresa
    /// pendente, reti di sicurezza, configurazione, frequenza, modo, risveglio).
    func testSilentDirectorGoesToTheCoordinatorFromEveryTrigger() {
        for trigger in RecoveryTrigger.allCases {
            for cause in causes {
                XCTAssertEqual(route(trigger, .direttore, silent: true, cause: cause), .coordinator,
                               "innesco:\(trigger) causa:\(String(describing: cause))")
            }
        }
    }

    /// Uno Stop voluto dopo la crisi: niente, per il Direttore e per il Solo.
    func testAWantedStopMeansNoRestart() {
        for role in [PlayerRole.direttore, .solo] {
            for silent in bools {
                for cause in causes {
                    XCTAssertEqual(route(.pendingRecovery, role, silent: silent, wanted: true, cause: cause), RecoveryRoute.noRestart,
                                   "ruolo:\(role) muto:\(silent) causa:\(String(describing: cause))")
                }
            }
        }
    }

    /// Il Solo dopo un'interruzione, una Lost o un reset non riparte da solo (ripresa pendente
    /// compresa); dopo configurazione e modo, e senza crisi, riparte come oggi. A421: dopo «uscita-tolta»
    /// niente (le cuffie staccate: riparte col Play); dopo «uscita-aggiunta» e «buco-del-render» come oggi.
    func testSoloDoesNotRestartAfterAnAudioSessionCrisis() {
        for trigger in RecoveryTrigger.allCases {
            for cause in [CrisisCause.interruption, .servicesLost, .resetWithoutLost, .resetAfterLost, .outputRemoved] {
                XCTAssertEqual(route(trigger, .solo, cause: cause), RecoveryRoute.noRestart, "innesco:\(trigger) causa:\(cause)")
            }
            XCTAssertEqual(route(trigger, .solo, cause: .configuration), .startAsToday, "innesco:\(trigger)")
            XCTAssertEqual(route(trigger, .solo, cause: .mode), .startAsToday, "innesco:\(trigger)")
            XCTAssertEqual(route(trigger, .solo, cause: .outputAdded), .startAsToday, "innesco:\(trigger)")
            XCTAssertEqual(route(trigger, .solo, cause: .renderGap), .startAsToday, "innesco:\(trigger)")
            XCTAssertEqual(route(trigger, .solo, cause: nil), .startAsToday, "innesco:\(trigger)")
        }
    }

    // MARK: - A421 — l'uscita mancante (U5) e i motivi del «niente»

    /// Il Direttore con l'uscita mancante (muto in canzone, o fermo fuori da una canzone): niente, per ogni innesco e ogni
    /// causa, anche la ripresa pendente che recupera il gestore del percorso; il motivo è «uscita-mancante» (uno Stop
    /// voluto viene prima, col suo motivo).
    func testTheDirectorWithTheOutputMissingDoesNotRestartFromAnyTrigger() {
        for trigger in RecoveryTrigger.allCases {
            for silent in bools {
                for cause in causes {
                    let tag = "innesco:\(trigger) muto:\(silent) causa:\(String(describing: cause))"
                    XCTAssertEqual(RecoveryDecision.route(trigger: trigger, playerRole: .direttore, silentInSong: silent,
                                                          wantedStopSinceCrisis: false, crisisCause: cause, outputMissing: true),
                                   .noRestart, tag)
                    XCTAssertEqual(RecoveryDecision.noRestartReason(trigger: trigger, playerRole: .direttore, silentInSong: silent,
                                                                    wantedStopSinceCrisis: false, crisisCause: cause, outputMissing: true),
                                   .outputMissing, tag)
                    XCTAssertEqual(RecoveryDecision.noRestartReason(trigger: trigger, playerRole: .direttore, silentInSong: silent,
                                                                    wantedStopSinceCrisis: true, crisisCause: cause, outputMissing: true),
                                   .wantedStop, tag)
                }
            }
        }
    }

    /// Il Follower e il Solo non hanno «uscita mancante» nella regola: con l'ingresso vero l'esito è quello di sempre.
    func testFollowerAndSoloIgnoreTheOutputMissing() {
        for trigger in RecoveryTrigger.allCases {
            for cause in causes {
                for wanted in bools {
                    for silent in bools {
                        for role in [PlayerRole.follower, .solo] {
                            let with = RecoveryDecision.route(trigger: trigger, playerRole: role, silentInSong: silent,
                                                              wantedStopSinceCrisis: wanted, crisisCause: cause, outputMissing: true)
                            let without = RecoveryDecision.route(trigger: trigger, playerRole: role, silentInSong: silent,
                                                                 wantedStopSinceCrisis: wanted, crisisCause: cause, outputMissing: false)
                            XCTAssertEqual(with, without, "ruolo:\(role) innesco:\(trigger) causa:\(String(describing: cause))")
                        }
                    }
                }
            }
        }
    }

    /// I motivi del «niente», nell'ordine della regola; `nil` quando si riparte.
    func testNoRestartReasons() {
        XCTAssertEqual(RecoveryDecision.noRestartReason(trigger: .appWakeup, playerRole: .solo, silentInSong: false,
                                                        wantedStopSinceCrisis: false, crisisCause: .outputRemoved, outputMissing: false),
                       .soloAfterCrisis)
        XCTAssertEqual(RecoveryDecision.noRestartReason(trigger: .appWakeup, playerRole: .solo, silentInSong: false,
                                                        wantedStopSinceCrisis: true, crisisCause: .outputRemoved, outputMissing: false),
                       .wantedStop)
        XCTAssertNil(RecoveryDecision.noRestartReason(trigger: .appWakeup, playerRole: .direttore, silentInSong: true,
                                                      wantedStopSinceCrisis: false, crisisCause: .outputAdded, outputMissing: false))
        XCTAssertNil(RecoveryDecision.noRestartReason(trigger: .appWakeup, playerRole: .follower, silentInSong: false,
                                                      wantedStopSinceCrisis: true, crisisCause: nil, outputMissing: true))
        XCTAssertEqual(NoRestartReason.wantedStop.rawValue, "stop-voluto")
        XCTAssertEqual(NoRestartReason.outputMissing.rawValue, "uscita-mancante")
        XCTAssertEqual(NoRestartReason.soloAfterCrisis.rawValue, "solo-dopo-la-crisi")
    }

    /// Il Direttore muto in canzone senza l'uscita mancante: il coordinatore, anche coi tre inneschi nuovi.
    func testTheNewTriggersGoToTheCoordinatorForTheSilentDirector() {
        for trigger in [RecoveryTrigger.outputAdded, .renderGap, .engineStoppedBySystem] {
            XCTAssertEqual(route(trigger, .direttore, silent: true, cause: .outputAdded), .coordinator, "\(trigger)")
            XCTAssertEqual(route(trigger, .direttore, silent: true, cause: .renderGap), .coordinator, "\(trigger)")
            XCTAssertEqual(route(trigger, .follower, cause: .outputAdded), .startAsToday, "\(trigger)")
        }
    }

    /// Il Follower: come oggi, sempre (il suo rientro esatto è dei passi 2B e 2C).
    func testFollowerIsAlwaysAsToday() {
        for trigger in RecoveryTrigger.allCases {
            for silent in bools {
                for wanted in bools {
                    for cause in causes {
                        XCTAssertEqual(route(trigger, .follower, silent: silent, wanted: wanted, cause: cause), .startAsToday,
                                       "innesco:\(trigger) muto:\(silent) stop:\(wanted) causa:\(String(describing: cause))")
                    }
                }
            }
        }
    }

    /// Il Direttore che non è muto in canzone (senza show, senza canzone): come oggi.
    func testDirectorNotSilentIsAsToday() {
        for cause in causes {
            XCTAssertEqual(route(.engineConfigChange, .direttore, silent: false, cause: cause), .startAsToday,
                           "causa:\(String(describing: cause))")
        }
    }

    // MARK: - La matrice

    private func expected(_ role: PlayerRole, silent: Bool, wanted: Bool, cause: CrisisCause?) -> RecoveryRoute {
        if role == .follower { return .startAsToday }
        if wanted { return .noRestart }
        if role == .direttore && silent { return .coordinator }
        if role == .solo {
            switch cause {
            case .interruption?, .servicesLost?, .resetWithoutLost?, .resetAfterLost?, .outputRemoved?:
                // A421: anche «uscita-tolta» ferma il Solo.
                return .noRestart
            default:
                break
            }
        }
        return .startAsToday
    }

    func testTheMatrixAndThatTheTriggerDoesNotDecide() {
        var cells = 0
        for role in roles {
            for silent in bools {
                for wanted in bools {
                    for cause in causes {
                        let want = expected(role, silent: silent, wanted: wanted, cause: cause)
                        for trigger in RecoveryTrigger.allCases {
                            cells += 1
                            XCTAssertEqual(route(trigger, role, silent: silent, wanted: wanted, cause: cause), want,
                                           "innesco:\(trigger) ruolo:\(role) muto:\(silent) stop:\(wanted) causa:\(String(describing: cause))")
                        }
                    }
                }
            }
        }
        // A421: dodici inneschi e nove cause (più «nessuna»).
        XCTAssertEqual(cells, 12 * 3 * 2 * 2 * 10)
    }

    /// A421 — la stessa matrice con l'uscita mancante: cambia solo il Direttore, che non riparte da solo (uno Stop voluto
    /// viene prima e dice la stessa cosa).
    func testTheMatrixWithTheOutputMissing() {
        var cells = 0
        for role in roles {
            for silent in bools {
                for wanted in bools {
                    for cause in causes {
                        var want = expected(role, silent: silent, wanted: wanted, cause: cause)
                        if role == .direttore { want = .noRestart }
                        for trigger in RecoveryTrigger.allCases {
                            cells += 1
                            XCTAssertEqual(RecoveryDecision.route(trigger: trigger, playerRole: role, silentInSong: silent,
                                                                  wantedStopSinceCrisis: wanted, crisisCause: cause, outputMissing: true),
                                           want,
                                           "innesco:\(trigger) ruolo:\(role) muto:\(silent) stop:\(wanted) causa:\(String(describing: cause))")
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 12 * 3 * 2 * 2 * 10)
    }

    // MARK: - La fine dell'interruzione senza shouldResume

    func testEndedWithoutShouldResumeRaisesThePendingResumeOnlyInsideAnInterruption() {
        XCTAssertTrue(RecoveryDecision.raisesPendingOnEndedWithoutResume(interruptionActive: true, wantedStopSinceCrisis: false))
        XCTAssertFalse(RecoveryDecision.raisesPendingOnEndedWithoutResume(interruptionActive: false, wantedStopSinceCrisis: false),
                       "nessuna interruzione attiva")
        XCTAssertFalse(RecoveryDecision.raisesPendingOnEndedWithoutResume(interruptionActive: true, wantedStopSinceCrisis: true),
                       "uno Stop voluto")
        XCTAssertFalse(RecoveryDecision.raisesPendingOnEndedWithoutResume(interruptionActive: false, wantedStopSinceCrisis: true))
    }

    /// I nomi degli inneschi sono quelli che il motore scrive già nelle righe [RESUME].
    func testTheTriggerNames() {
        // A421: i tre inneschi nuovi in coda.
        XCTAssertEqual(RecoveryTrigger.allCases.map { $0.rawValue },
                       ["interruption_ended", "pending_recovery", "safety_net_noresume", "safety_net",
                        "engine_config_change", "sample_rate_change", "mode_change",
                        "wakeup_pending_recovery", "app_wakeup",
                        "uscita_aggiunta", "buco_del_render", "motore_fermo_dal_sistema"])
        XCTAssertEqual(RecoveryRoute.coordinator.rawValue, "coordinatore")
        XCTAssertEqual(RecoveryRoute.startAsToday.rawValue, "avvio-come-oggi")
        XCTAssertEqual(RecoveryRoute.noRestart.rawValue, "niente")
    }
}
