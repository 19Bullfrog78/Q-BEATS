import XCTest

// === A421 · SEGUITO 1 — banco della regola «con l'interruzione di sistema in corso nessuna ripartenza automatica tocca sessione
// o motore» (`InterruptionActivationDecision`, banco Models), mandato par. 3.2-3.5 ===
// La tabella del par. 3.4: stato alto e basso; ogni innesco di `RecoveryTrigger`, col segno dell'eccezione e il contatore degli
// inizi; Direttore muto in canzone, Direttore fuori da una canzone, Follower, Solo; il tentativo 0 e i successivi;
// `isAudioInterrupted` vero e falso; lo Stop voluto dopo la crisi vero e falso; i tre punti. Poi la catena del ritorno in
// primo piano passo per passo, la regola del par. 3.5 e il Solo all'inizio di un'interruzione.

final class InterruptionActivationDecisionTests: XCTestCase {

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]
    private let points = InterruptionActivationPoint.allCases
    private let foreground: [RecoveryTrigger] = [.appWakeup, .wakeupPendingRecovery]

    private func mark(_ token: Int, _ begins: Int) -> InterruptionActivationException {
        InterruptionActivationException(chainToken: token, beginsCount: begins)
    }

    private func allows(_ point: InterruptionActivationPoint, high: Bool, mark: InterruptionActivationException?,
                        token: Int, begins: Int, role: PlayerRole, silent: Bool) -> Bool {
        InterruptionActivationDecision.allowsActivation(point: point, systemInterruption: high, mark: mark, chainToken: token,
                                                        beginsCount: begins, playerRole: role, silentInSong: silent)
    }

    // MARK: - Il segno dell'eccezione (par. 3.2)

    /// Il segno si prende solo al tentativo 0 di `app_wakeup` o `wakeup_pending_recovery`, con lo stato già alto, il ruolo
    /// Direttore e il Direttore muto in canzone; porta il contatore della catena e quello degli inizi. Per ogni altra
    /// combinazione (innesco, tentativo, stato, ruolo, silenzio) niente.
    func testTheMarkOnlyForTheForegroundReturnOfTheSilentDirectorWithTheStateHigh() {
        var cells = 0
        var marks = 0
        for trigger in RecoveryTrigger.allCases {
            for attempt in [0, 1, 7, 20] {
                for high in bools {
                    for role in roles {
                        for silent in bools {
                            cells += 1
                            let got = InterruptionActivationDecision.exceptionMark(trigger: trigger, attempt: attempt,
                                                                                   systemInterruption: high, playerRole: role,
                                                                                   silentInSong: silent, chainToken: 7, beginsCount: 3)
                            let expected = attempt == 0 && foreground.contains(trigger) && high && role == .direttore && silent
                            XCTAssertEqual(got != nil, expected, "\(trigger) \(attempt) \(high) \(role) \(silent)")
                            if let got {
                                marks += 1
                                XCTAssertEqual(got, mark(7, 3))
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 12 * 4 * 2 * 3 * 2)
        XCTAssertEqual(marks, 2, "due inneschi, una cella ciascuno")
        XCTAssertTrue(InterruptionActivationDecision.isForegroundReturn(.appWakeup))
        XCTAssertTrue(InterruptionActivationDecision.isForegroundReturn(.wakeupPendingRecovery))
        for trigger in RecoveryTrigger.allCases where !foreground.contains(trigger) {
            XCTAssertFalse(InterruptionActivationDecision.isForegroundReturn(trigger), "\(trigger)")
        }
    }

    // MARK: - La regola (par. 3.2, 3.3)

    /// Con lo stato «interruzione di sistema» basso la ripartenza tocca sessione e motore, a ogni punto, con o senza segno, per
    /// ogni ruolo.
    func testWithTheStateLowTheRuleAlwaysAllows() {
        for point in points {
            for mark in [nil, mark(7, 3)] as [InterruptionActivationException?] {
                for role in roles {
                    for silent in bools {
                        for token in [7, 8] {
                            for begins in [3, 4] {
                                XCTAssertTrue(allows(point, high: false, mark: mark, token: token, begins: begins, role: role, silent: silent),
                                              "\(point) \(String(describing: mark)) \(role) \(silent) \(token) \(begins)")
                            }
                        }
                    }
                }
            }
        }
    }

    /// Con lo stato alto solo l'eccezione passa, ai punti «ingresso» e «setActive»: il segno di questa catena (lo stesso
    /// contatore della catena), il contatore degli inizi non cambiato, e adesso il Direttore muto in canzone. Cambia una cosa
    /// sola — il segno assente, un'altra catena, un inizio nuovo, il ruolo, il silenzio finito — e la regola dice no. Al
    /// punto «start» mai.
    func testWithTheStateHighOnlyTheExceptionPasses() {
        let exception = mark(7, 3)
        for point in [InterruptionActivationPoint.entry, .setActive] {
            XCTAssertTrue(allows(point, high: true, mark: exception, token: 7, begins: 3, role: .direttore, silent: true), "\(point)")
            XCTAssertFalse(allows(point, high: true, mark: nil, token: 7, begins: 3, role: .direttore, silent: true), "\(point) senza segno")
            XCTAssertFalse(allows(point, high: true, mark: exception, token: 8, begins: 3, role: .direttore, silent: true), "\(point) altra catena")
            XCTAssertFalse(allows(point, high: true, mark: exception, token: 7, begins: 4, role: .direttore, silent: true), "\(point) inizio nuovo")
            XCTAssertFalse(allows(point, high: true, mark: exception, token: 7, begins: 3, role: .direttore, silent: false), "\(point) fuori canzone")
            XCTAssertFalse(allows(point, high: true, mark: exception, token: 7, begins: 3, role: .follower, silent: true), "\(point) Follower")
            XCTAssertFalse(allows(point, high: true, mark: exception, token: 7, begins: 3, role: .solo, silent: true), "\(point) Solo")
        }
        for mark in [nil, exception] as [InterruptionActivationException?] {
            for role in roles {
                for silent in bools {
                    XCTAssertFalse(allows(.start, high: true, mark: mark, token: 7, begins: 3, role: role, silent: silent),
                                   "start \(String(describing: mark)) \(role) \(silent)")
                }
            }
        }
        // La tabella intera: stato alto × punto × segno × catena × inizi × ruolo × silenzio.
        var cells = 0
        for point in points {
            for mark in [nil, exception] as [InterruptionActivationException?] {
                for token in [7, 8] {
                    for begins in [3, 4] {
                        for role in roles {
                            for silent in bools {
                                cells += 1
                                let expected = point != .start && mark != nil && token == 7 && begins == 3
                                    && role == .direttore && silent
                                XCTAssertEqual(allows(point, high: true, mark: mark, token: token, begins: begins, role: role, silent: silent),
                                               expected, "\(point) \(String(describing: mark)) \(token) \(begins) \(role) \(silent)")
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 3 * 2 * 2 * 2 * 3 * 2)
        XCTAssertEqual(InterruptionActivationPoint.entry.rawValue, "ingresso")
        XCTAssertEqual(InterruptionActivationPoint.setActive.rawValue, "setActive")
        XCTAssertEqual(InterruptionActivationPoint.start.rawValue, "start")
    }

    /// L'innesco e il tentativo non entrano nella regola: contano solo per il segno. Una catena con il segno passa a ogni
    /// tentativo e con la rete a 5 s (`safety_net`, che porta lo stesso contatore della catena).
    func testTheRuleDoesNotDependOnTheTriggerOrTheAttempt() {
        let exception = mark(7, 3)
        for trigger in RecoveryTrigger.allCases {
            for attempt in [0, 1, 20] {
                _ = trigger
                _ = attempt
                XCTAssertTrue(allows(.entry, high: true, mark: exception, token: 7, begins: 3, role: .direttore, silent: true))
                XCTAssertFalse(allows(.entry, high: true, mark: nil, token: 7, begins: 3, role: .direttore, silent: true))
            }
        }
    }

    // MARK: - Con la regola che dice no (par. 3.3)

    /// Il Solo: fermo come allo Stop della console (mai la ripresa pendente), salvo dopo uno Stop voluto, quando è già fermo.
    /// Gli altri: con `isAudioInterrupted` vero niente; se no la ripresa pendente, salvo uno Stop voluto dopo la crisi.
    func testTheRefusal() {
        for interrupted in bools {
            XCTAssertEqual(InterruptionActivationDecision.refusal(playerRole: .solo, isAudioInterrupted: interrupted, wantedStopSinceCrisis: false), .soloStop)
            XCTAssertEqual(InterruptionActivationDecision.refusal(playerRole: .solo, isAudioInterrupted: interrupted, wantedStopSinceCrisis: true), .nothing)
        }
        for role in [PlayerRole.direttore, .follower] {
            for wanted in bools {
                XCTAssertEqual(InterruptionActivationDecision.refusal(playerRole: role, isAudioInterrupted: true, wantedStopSinceCrisis: wanted), .nothing, "\(role) \(wanted)")
            }
            XCTAssertEqual(InterruptionActivationDecision.refusal(playerRole: role, isAudioInterrupted: false, wantedStopSinceCrisis: false), .raisePending, "\(role)")
            XCTAssertEqual(InterruptionActivationDecision.refusal(playerRole: role, isAudioInterrupted: false, wantedStopSinceCrisis: true), .nothing, "\(role)")
        }
        XCTAssertEqual(InterruptionActivationRefusal.nothing.rawValue, "niente")
        XCTAssertEqual(InterruptionActivationRefusal.raisePending.rawValue, "ripresa-pendente")
        XCTAssertEqual(InterruptionActivationRefusal.soloStop.rawValue, "solo-fermo")
    }

    // MARK: - La catena del ritorno in primo piano, passo per passo (par. 3.2)

    /// La catena partita con lo stato già alto: il segno al tentativo 0, l'eccezione ai venti tentativi e alla rete a 5 s; un
    /// inizio nuovo la toglie; una catena nuova dopo (un altro ritorno in primo piano) ha il suo segno e passa; la catena
    /// partita con lo stato basso non ha il segno e a un inizio che comincia durante i suoi tentativi non passa.
    func testTheForegroundChain() {
        var begins = 3
        let mark0 = InterruptionActivationDecision.exceptionMark(trigger: .appWakeup, attempt: 0, systemInterruption: true,
                                                                  playerRole: .direttore, silentInSong: true, chainToken: 7, beginsCount: begins)
        XCTAssertEqual(mark0, mark(7, 3))
        for attempt in 0...20 {
            _ = attempt
            XCTAssertTrue(allows(.entry, high: true, mark: mark0, token: 7, begins: begins, role: .direttore, silent: true))
            XCTAssertTrue(allows(.setActive, high: true, mark: mark0, token: 7, begins: begins, role: .direttore, silent: true))
        }
        XCTAssertTrue(allows(.entry, high: true, mark: mark0, token: 7, begins: begins, role: .direttore, silent: true), "la rete a 5 s, stesso contatore")
        begins += 1
        XCTAssertFalse(allows(.entry, high: true, mark: mark0, token: 7, begins: begins, role: .direttore, silent: true), "un inizio nuovo")
        let mark1 = InterruptionActivationDecision.exceptionMark(trigger: .wakeupPendingRecovery, attempt: 0, systemInterruption: true,
                                                                  playerRole: .direttore, silentInSong: true, chainToken: 8, beginsCount: begins)
        XCTAssertEqual(mark1, mark(8, 4))
        XCTAssertTrue(allows(.setActive, high: true, mark: mark1, token: 8, begins: begins, role: .direttore, silent: true), "la catena nuova passa")
        XCTAssertFalse(allows(.setActive, high: true, mark: mark1, token: 7, begins: begins, role: .direttore, silent: true), "la vecchia no")
        let low = InterruptionActivationDecision.exceptionMark(trigger: .appWakeup, attempt: 0, systemInterruption: false,
                                                               playerRole: .direttore, silentInSong: true, chainToken: 9, beginsCount: begins)
        XCTAssertNil(low, "partita con lo stato basso: nessun segno")
        XCTAssertFalse(allows(.entry, high: true, mark: low, token: 9, begins: begins + 1, role: .direttore, silent: true))
    }

    // MARK: - Par. 3.5 e il Solo all'inizio (par. 3.3)

    /// Un avvio riuscito: lo sgombero con la riga se la ripresa pendente o l'interruzione era alzata; se no solo il contatore.
    func testAStartClearsThePendingResumeWithTheLineOnlyIfSomethingWasUp() {
        XCTAssertFalse(InterruptionActivationDecision.startClearsPendingWithLine(pendingResume: false, isAudioInterrupted: false))
        XCTAssertTrue(InterruptionActivationDecision.startClearsPendingWithLine(pendingResume: true, isAudioInterrupted: false))
        XCTAssertTrue(InterruptionActivationDecision.startClearsPendingWithLine(pendingResume: false, isAudioInterrupted: true))
        XCTAssertTrue(InterruptionActivationDecision.startClearsPendingWithLine(pendingResume: true, isAudioInterrupted: true))
    }

    /// All'inizio di un'interruzione il Solo con la ripresa pendente la perde e si ferma come allo Stop della console; gli altri
    /// ruoli, e il Solo senza ripresa pendente, seguono la regola delle crisi.
    func testTheSoloLosesThePendingResumeAtTheBegin() {
        XCTAssertTrue(InterruptionActivationDecision.soloLosesPendingAtBegin(playerRole: .solo, pendingResume: true))
        XCTAssertFalse(InterruptionActivationDecision.soloLosesPendingAtBegin(playerRole: .solo, pendingResume: false))
        for role in [PlayerRole.direttore, .follower] {
            for pending in bools {
                XCTAssertFalse(InterruptionActivationDecision.soloLosesPendingAtBegin(playerRole: role, pendingResume: pending), "\(role)")
            }
        }
        // La causa ricordata del Solo a quel punto: «interruzione», che lo tiene fermo fino al Play (`RecoveryDecision`).
        let cause = CrisisStopDecision.rememberedCause(previous: .configuration, new: .interruption, playerRole: .solo)
        XCTAssertEqual(cause, .interruption)
        for trigger in RecoveryTrigger.allCases {
            XCTAssertEqual(RecoveryDecision.route(trigger: trigger, playerRole: .solo, silentInSong: false, wantedStopSinceCrisis: false,
                                                  crisisCause: cause), .noRestart, "\(trigger)")
        }
    }
}
