import XCTest

// === A421 — banco dello specchio `isPlaying` = `isRunning` e della guardia del ritorno in primo piano
// (`TransportStateDecision`, banco Models), mandato par. 2.2 e ===
// ⚠️ RISCRITTO A421 dopo la verifica del diff: la guardia non guarda più la causa di crisi viva. Il Direttore fuori da una
// canzone fermato da una tolta (U16) non riparte al risveglio quando l'uscita torna; il Solo dopo una crisi aspetta il Play;
// il Follower fermato da un'interruzione lo riprende la fine dell'interruzione, non un risveglio durante la chiamata.

final class TransportStateDecisionTests: XCTestCase {

    private let bools = [false, true]

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
                XCTAssertFalse(TransportStateDecision.wakeupRecovers(engineRunning: true, pendingResume: pending,
                                                                    silentInSong: silent),
                               "pendente:\(pending) muto:\(silent)")
            }
        }
    }

    /// A motore fermo riprova solo per le due strade che ci contavano: la ripresa pendente e il Direttore muto in canzone
    /// (D5). Fermo per uno Stop, o per una crisi che aspetta il Play: niente.
    func testWakeupRecoversOnlyForAPendingResumeOrTheSilentDirector() {
        XCTAssertFalse(TransportStateDecision.wakeupRecovers(engineRunning: false, pendingResume: false, silentInSong: false))
        XCTAssertTrue(TransportStateDecision.wakeupRecovers(engineRunning: false, pendingResume: true, silentInSong: false))
        XCTAssertTrue(TransportStateDecision.wakeupRecovers(engineRunning: false, pendingResume: false, silentInSong: true))
        XCTAssertTrue(TransportStateDecision.wakeupRecovers(engineRunning: false, pendingResume: true, silentInSong: true))
    }

    /// U16 dopo la verifica del diff: il Direttore fuori da una canzone fermato da una tolta ha la causa viva e, con l'uscita
    /// tornata, `RecoveryDecision` direbbe «come oggi» a un risveglio: è la guardia che lo ferma, perché non guarda la causa.
    /// Lo stesso per il Follower fermato da un'interruzione con uno Stop voluto in mezzo («come oggi» prima dello Stop voluto).
    func testALiveCrisisCauseAloneNeverRecovers() {
        XCTAssertEqual(RecoveryDecision.route(trigger: .appWakeup, playerRole: .direttore, silentInSong: false,
                                              wantedStopSinceCrisis: false, crisisCause: .outputRemoved, outputMissing: false),
                       .startAsToday, "la regola sola ripartirebbe: la guardia deve fermare prima")
        XCTAssertEqual(RecoveryDecision.route(trigger: .appWakeup, playerRole: .follower, silentInSong: false,
                                              wantedStopSinceCrisis: true, crisisCause: .interruption, outputMissing: false),
                       .startAsToday, "il Follower: «come oggi» viene prima dello Stop voluto")
        XCTAssertFalse(TransportStateDecision.wakeupRecovers(engineRunning: false, pendingResume: false, silentInSong: false),
                       "senza ripresa pendente e senza il Direttore muto il risveglio non prova niente, con qualunque causa viva")
    }
}
