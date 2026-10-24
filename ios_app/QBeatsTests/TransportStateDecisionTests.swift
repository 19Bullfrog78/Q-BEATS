import XCTest

// === A421 — banco dello specchio `isPlaying` = `isRunning` e della guardia del ritorno in primo piano
// (`TransportStateDecision`, banco Models), mandato par. 2.2 e ===

final class TransportStateDecisionTests: XCTestCase {

    private let bools = [false, true]
    private var causes: [CrisisCause?] { [nil] + CrisisCause.allCases.map { Optional($0) } }

    /// `isPlaying` è lo specchio di `isRunning`: vero a motore in moto (anche col Follower muto per l'uscita mancante),
    /// falso a motore fermo (anche col Direttore muto in canzone).
    func testIsPlayingMirrorsIsRunning() {
        XCTAssertTrue(TransportStateDecision.isPlaying(engineRunning: true))
        XCTAssertFalse(TransportStateDecision.isPlaying(engineRunning: false))
    }

    /// A motore in moto il ritorno in primo piano non fa niente, qualunque cosa dicano gli altri ingressi.
    func testWakeupDoesNothingWithTheEngineRunning() {
        for pending in bools {
            for silent in bools {
                for cause in causes {
                    XCTAssertFalse(TransportStateDecision.wakeupRecovers(engineRunning: true, pendingResume: pending,
                                                                        silentInSong: silent, crisisCause: cause),
                                   "pendente:\(pending) muto:\(silent) causa:\(String(describing: cause))")
                }
            }
        }
    }

    /// A motore fermo riprova solo per una crisi: la ripresa pendente, il Direttore muto in canzone, una causa viva. Fermo
    /// per uno Stop senza crisi (la causa azzerata dall'avvio di prima): niente, il click non riparte da solo.
    func testWakeupRecoversOnlyAfterACrisis() {
        XCTAssertFalse(TransportStateDecision.wakeupRecovers(engineRunning: false, pendingResume: false, silentInSong: false, crisisCause: nil))
        XCTAssertTrue(TransportStateDecision.wakeupRecovers(engineRunning: false, pendingResume: true, silentInSong: false, crisisCause: nil))
        XCTAssertTrue(TransportStateDecision.wakeupRecovers(engineRunning: false, pendingResume: false, silentInSong: true, crisisCause: nil))
        for cause in CrisisCause.allCases {
            XCTAssertTrue(TransportStateDecision.wakeupRecovers(engineRunning: false, pendingResume: false, silentInSong: false,
                                                               crisisCause: cause), "\(cause)")
        }
    }

    /// Dopo uno Stop voluto la causa resta fino all'avvio dopo e la guardia passa: è `RecoveryDecision` a dire «niente»
    /// (`wantedStopSinceCrisis`). Qui si prova che la coppia tiene.
    func testAfterAWantedStopTheGuardPassesAndTheRouteSaysNothing() {
        XCTAssertTrue(TransportStateDecision.wakeupRecovers(engineRunning: false, pendingResume: false, silentInSong: false,
                                                           crisisCause: .configuration))
        for role in [PlayerRole.direttore, .solo] {
            XCTAssertEqual(RecoveryDecision.route(trigger: .appWakeup, playerRole: role, silentInSong: false,
                                                  wantedStopSinceCrisis: true, crisisCause: .configuration, outputMissing: false),
                           .noRestart, "\(role)")
        }
    }
}
