import XCTest

// === A412 — banco della regola delle ripartenze automatiche (`RecoveryDecision`, banco Models), mandato §2.6 ===
// La matrice: innesco × ruolo del player × muto in canzone × Stop voluto dopo la crisi × causa della crisi
// (le sei, più «nessuna») = 9 × 3 × 2 × 2 × 7 = 756 celle, con l'atteso scritto dalla regola del mandato.
// Poi: l'esito non dipende dall'innesco; il Follower è sempre com'è; dopo uno Stop voluto niente; il
// Direttore muto in canzone va al coordinatore; il Solo dopo un'interruzione (Lost e reset compresi) non
// riparte da solo, dopo configurazione e modo sì. E la fine dell'interruzione senza `shouldResume`, che
// rialza la ripresa pendente solo con un'interruzione attiva e nessuno Stop voluto.

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
    /// compresa); dopo configurazione e modo, e senza crisi, riparte come oggi.
    func testSoloDoesNotRestartAfterAnAudioSessionCrisis() {
        for trigger in RecoveryTrigger.allCases {
            for cause in [CrisisCause.interruption, .servicesLost, .resetWithoutLost, .resetAfterLost] {
                XCTAssertEqual(route(trigger, .solo, cause: cause), RecoveryRoute.noRestart, "innesco:\(trigger) causa:\(cause)")
            }
            XCTAssertEqual(route(trigger, .solo, cause: .configuration), .startAsToday, "innesco:\(trigger)")
            XCTAssertEqual(route(trigger, .solo, cause: .mode), .startAsToday, "innesco:\(trigger)")
            XCTAssertEqual(route(trigger, .solo, cause: nil), .startAsToday, "innesco:\(trigger)")
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
            case .interruption?, .servicesLost?, .resetWithoutLost?, .resetAfterLost?:
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
        XCTAssertEqual(cells, 9 * 3 * 2 * 2 * 7)
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
        XCTAssertEqual(RecoveryTrigger.allCases.map { $0.rawValue },
                       ["interruption_ended", "pending_recovery", "safety_net_noresume", "safety_net",
                        "engine_config_change", "sample_rate_change", "mode_change",
                        "wakeup_pending_recovery", "app_wakeup"])
        XCTAssertEqual(RecoveryRoute.coordinator.rawValue, "coordinatore")
        XCTAssertEqual(RecoveryRoute.startAsToday.rawValue, "avvio-come-oggi")
        XCTAssertEqual(RecoveryRoute.noRestart.rawValue, "niente")
    }
}
