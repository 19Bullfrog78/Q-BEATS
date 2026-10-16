import XCTest

// === A408 — banco del reset dei servizi audio (banco Models) ===
// Un caso per ogni riga della tabella degli stati (mandato A408, §1-§3): Lost, Reset, il
// passaggio dopo lo stopSync, l'avvio e la fine della ricostruzione, da ognuno dei tre stati,
// con gli attesi LETTERALI. Poi le sequenze che il mandato nomina: Lost ripetute; tre Reset di
// fila (il collaudo di A406: tre Lost, tre Reset, una ricostruzione sola); Reset senza Lost;
// Lost durante «da ricostruire»; setActive fallito. Il banco gira in CI su ogni push
// (`.github/workflows/ios_build.yml`, `xcodebuild test -scheme QBeatsTests`).

final class MediaServicesResetDecisionTests: XCTestCase {

    private func step(_ state: MediaServicesState, _ event: MediaServicesEvent) -> MediaServicesTransition {
        MediaServicesResetDecision.transition(state: state, event: event)
    }

    /// Applica gli eventi in fila dallo stato dato; rende le azioni e lo stato finale.
    private func run(from state: MediaServicesState,
                     _ events: [MediaServicesEvent]) -> (actions: [MediaServicesAction], last: MediaServicesState) {
        var s = state
        var actions: [MediaServicesAction] = []
        for e in events {
            let t = step(s, e)
            actions.append(t.action)
            s = t.next
        }
        return (actions, s)
    }

    // MARK: - La tabella, riga per riga

    func testEveryRowOfTheTableLiterally() {
        // (stato, evento, stato dopo, azione)
        let rows: [(MediaServicesState, MediaServicesEvent, MediaServicesState, MediaServicesAction)] = [
            // Lost: da qualunque stato a «servizi persi», nient'altro.
            (.normal,       .lost,  .servicesLost, .none),
            (.servicesLost, .lost,  .servicesLost, .none),
            (.needsRebuild, .lost,  .servicesLost, .none),
            // Reset.
            (.normal,       .reset, .needsRebuild, .markRebuild),
            (.servicesLost, .reset, .servicesLost, .stopThenMarkRebuild),
            (.needsRebuild, .reset, .needsRebuild, .ignoreRepeatedReset),
            // Il passaggio dopo lo stopSync: «da ricostruire».
            (.normal,       .stoppedAfterReset, .needsRebuild, .none),
            (.servicesLost, .stoppedAfterReset, .needsRebuild, .none),
            (.needsRebuild, .stoppedAfterReset, .needsRebuild, .none),
            // L'avvio.
            (.normal,       .start, .normal,       .startAsToday),
            (.servicesLost, .start, .servicesLost, .refuseStart),
            (.needsRebuild, .start, .needsRebuild, .rebuildThenStart),
            // La fine della ricostruzione.
            (.normal,       .rebuilt(sessionActivated: true),  .normal,       .startAsToday),
            (.servicesLost, .rebuilt(sessionActivated: true),  .normal,       .startAsToday),
            (.needsRebuild, .rebuilt(sessionActivated: true),  .normal,       .startAsToday),
            (.normal,       .rebuilt(sessionActivated: false), .needsRebuild, .failStart),
            (.servicesLost, .rebuilt(sessionActivated: false), .needsRebuild, .failStart),
            (.needsRebuild, .rebuilt(sessionActivated: false), .needsRebuild, .failStart),
        ]
        XCTAssertEqual(rows.count, 18)
        for (state, event, next, action) in rows {
            let t = step(state, event)
            XCTAssertEqual(t.next, next, "stato:\(state) evento:\(event)")
            XCTAssertEqual(t.action, action, "stato:\(state) evento:\(event)")
        }
    }

    func testTheAppStartsNormal() {
        XCTAssertEqual(MediaServicesResetDecision.initial, .normal)
        XCTAssertEqual(step(MediaServicesResetDecision.initial, .start).action, .startAsToday)
    }

    // MARK: - Fuori da «normale» niente lavoro di grafo, niente setActive, niente ripartenza

    func testAudioWorkIsAllowedOnlyInNormal() {
        XCTAssertTrue(MediaServicesResetDecision.allowsAudioWork(.normal))
        XCTAssertFalse(MediaServicesResetDecision.allowsAudioWork(.servicesLost))
        XCTAssertFalse(MediaServicesResetDecision.allowsAudioWork(.needsRebuild))
    }

    // MARK: - Le sequenze del mandato

    func testRepeatedLostStayServicesLost() {
        let r = run(from: .normal, [.lost, .lost, .lost])
        XCTAssertEqual(r.actions, [.none, .none, .none])
        XCTAssertEqual(r.last, .servicesLost)
    }

    func testThreeResetsInARowAskOneRebuild() {
        // Il collaudo di A406 (referto A407, §3.2): tre Lost, tre Reset, poi il Play. La prima
        // Reset ferma e porta a «da ricostruire»; le altre due sono ignorate; il Play ricostruisce
        // una volta sola, e il Play dopo parte come oggi.
        var r = run(from: .normal, [.lost, .lost, .lost, .reset])
        XCTAssertEqual(r.actions, [.none, .none, .none, .stopThenMarkRebuild])
        XCTAssertEqual(r.last, .servicesLost, "fra la lettura e il passaggio resta «servizi persi»")
        r = run(from: r.last, [.stoppedAfterReset, .reset, .reset])
        XCTAssertEqual(r.actions, [.none, .ignoreRepeatedReset, .ignoreRepeatedReset])
        XCTAssertEqual(r.last, .needsRebuild)
        r = run(from: r.last, [.start, .rebuilt(sessionActivated: true), .start])
        XCTAssertEqual(r.actions, [.rebuildThenStart, .startAsToday, .startAsToday])
        XCTAssertEqual(r.last, .normal)
    }

    func testResetWithoutLostMarksRebuildWithoutStop() {
        let r = run(from: .normal, [.reset])
        XCTAssertEqual(r.actions, [.markRebuild], "niente stopSync")
        XCTAssertEqual(r.last, .needsRebuild)
        let play = run(from: r.last, [.start, .rebuilt(sessionActivated: true)])
        XCTAssertEqual(play.actions, [.rebuildThenStart, .startAsToday])
        XCTAssertEqual(play.last, .normal)
    }

    func testLostDuringNeedsRebuildStartsANewWindow() {
        // Dopo la Reset, prima del Play, il server muore di nuovo: si torna a «servizi persi», il
        // Play è rifiutato, e la Reset nuova ferma e riporta a «da ricostruire».
        let r = run(from: .needsRebuild, [.lost, .start, .reset, .stoppedAfterReset, .start])
        XCTAssertEqual(r.actions, [.none, .refuseStart, .stopThenMarkRebuild, .none, .rebuildThenStart])
        XCTAssertEqual(r.last, .needsRebuild)
    }

    func testSessionNotActivatedKeepsNeedsRebuildAndTheNextPlayRetries() {
        let r = run(from: .needsRebuild, [.start, .rebuilt(sessionActivated: false),
                                          .start, .rebuilt(sessionActivated: true)])
        XCTAssertEqual(r.actions, [.rebuildThenStart, .failStart, .rebuildThenStart, .startAsToday])
        XCTAssertEqual(r.last, .normal)
    }

    func testAStartRefusedWhileServicesAreLostIsNotRemembered() {
        // Il Play nella finestra è rifiutato e non lascia niente: dopo la Reset nessuna azione
        // d'avvio, finché non arriva un avvio nuovo.
        let r = run(from: .normal, [.lost, .start, .start, .reset, .stoppedAfterReset])
        XCTAssertEqual(r.actions, [.none, .refuseStart, .refuseStart, .stopThenMarkRebuild, .none])
        XCTAssertEqual(r.last, .needsRebuild)
        XCTAssertFalse(r.actions.contains(.startAsToday))
        XCTAssertFalse(r.actions.contains(.rebuildThenStart))
    }

    func testOnlyAStartRebuilds() {
        // Nessuna notifica ricostruisce né avvia: la ricostruzione esce solo da un avvio.
        for state in [MediaServicesState.normal, .servicesLost, .needsRebuild] {
            for event in [MediaServicesEvent.lost, .reset, .stoppedAfterReset] {
                let a = step(state, event).action
                XCTAssertNotEqual(a, .rebuildThenStart, "stato:\(state) evento:\(event)")
                XCTAssertNotEqual(a, .startAsToday, "stato:\(state) evento:\(event)")
            }
        }
    }
}
