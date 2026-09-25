import XCTest

// === A386 · FASE B1 — banco della ripetizione del Direttore (banco Models) ===
// In moto `{vero, T ± 1 ms}`, da fermo `{falso, Tstop ± 1 ms}` (Tstop e' l'ora dello stop letta
// da Link, non «adesso»), segno alternato solo quando si ripete; i quattro salti (non
// Direttore, Link dell'utente spento, Start Stop Sync spento, ponte spento). Il millisecondo e'
// 24.000 tick (misura A382 §3.6): qui e' un numero passato, non una costante del tipo.

final class DirectorReannounceDecisionTests: XCTestCase {

    private typealias D = DirectorReannounceDecision
    private let ms: UInt64 = 24_000

    private func decide(role: LinkMode = .direttore, user: Bool = true, sss: Bool = true,
                        link: Bool = true, playing: Bool, captured: UInt64,
                        sign: D.Sign) -> D {
        D(role: role, userLinkEnabled: user, startStopSyncEnabled: sss, linkEnabled: link,
          sessionPlaying: playing, capturedTime: captured, shiftTicks: ms, sign: sign)
    }

    func testRunningReannouncesPlayingAtCapturedPlusOneMillisecond() {
        let d = decide(playing: true, captured: 1_000_000, sign: .plus)
        XCTAssertEqual(d.outcome, .reannounce(isPlaying: true, at: 1_024_000))
        XCTAssertEqual(d.nextSign, .minus)
    }

    func testStoppedReannouncesStoppedAtStopTimeNotNow() {
        let d = decide(playing: false, captured: 5_000_000, sign: .plus)
        XCTAssertEqual(d.outcome, .reannounce(isPlaying: false, at: 5_024_000))
        XCTAssertEqual(d.nextSign, .minus)
    }

    func testMinusSignSubtractsOneMillisecond() {
        let d = decide(playing: true, captured: 1_024_000, sign: .minus)
        XCTAssertEqual(d.outcome, .reannounce(isPlaying: true, at: 1_000_000))
        XCTAssertEqual(d.nextSign, .plus)
    }

    func testTheTimeOscillatesAndDoesNotDrift() {
        // se la cattura restituisce cio' che e' stato scritto, dopo due ripetizioni si torna
        // al valore di partenza: +1 ms, -1 ms.
        let start: UInt64 = 9_000_000
        let first = decide(playing: true, captured: start, sign: .plus)
        guard case .reannounce(_, let t1) = first.outcome else { return XCTFail("prima") }
        let second = decide(playing: true, captured: t1, sign: first.nextSign)
        guard case .reannounce(_, let t2) = second.outcome else { return XCTFail("seconda") }
        let third = decide(playing: true, captured: t2, sign: second.nextSign)
        guard case .reannounce(_, let t3) = third.outcome else { return XCTFail("terza") }
        XCTAssertEqual(t1, start + ms)
        XCTAssertEqual(t2, start)
        XCTAssertEqual(t3, start + ms)
        XCTAssertEqual(third.nextSign, .minus)
    }

    func testMinusNeverGoesBelowZero() {
        let d = decide(playing: false, captured: 10, sign: .minus)
        XCTAssertEqual(d.outcome, .reannounce(isPlaying: false, at: 0))
    }

    func testSkipsDoNotFlipTheSign() {
        let notDirector = decide(role: .collaborativa, playing: true, captured: 1, sign: .plus)
        XCTAssertEqual(notDirector.outcome, .skip(.notDirector))
        XCTAssertEqual(notDirector.nextSign, .plus)

        let solo = decide(role: .standalone, playing: true, captured: 1, sign: .minus)
        XCTAssertEqual(solo.outcome, .skip(.notDirector))
        XCTAssertEqual(solo.nextSign, .minus)

        let userOff = decide(user: false, playing: true, captured: 1, sign: .plus)
        XCTAssertEqual(userOff.outcome, .skip(.userLinkOff))
        XCTAssertEqual(userOff.nextSign, .plus)

        let sssOff = decide(sss: false, playing: true, captured: 1, sign: .plus)
        XCTAssertEqual(sssOff.outcome, .skip(.startStopSyncOff))
        XCTAssertEqual(sssOff.nextSign, .plus)

        let linkOff = decide(link: false, playing: true, captured: 1, sign: .plus)
        XCTAssertEqual(linkOff.outcome, .skip(.linkUnavailable))
        XCTAssertEqual(linkOff.nextSign, .plus)
    }

    func testSkipOrderNotDirectorBeforeTheOthers() {
        let d = decide(role: .collaborativa, user: false, sss: false, link: false,
                       playing: true, captured: 1, sign: .plus)
        XCTAssertEqual(d.outcome, .skip(.notDirector))
    }
}
