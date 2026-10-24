import XCTest

// === A421 — banco del battito in ritardo dopo una correzione (`LateBeatDecision`, banco Models), mandato par. 2.1 U9 ===
// La griglia del DSP (origine più interi), il pendente, il re-map del DSP (`MetronomeDSP.cpp:337-339`) e il fire-asap
// (`:351-353`) riprodotti sui numeri: una correzione normale non zittisce mai (5364 correzioni in una canzone, media
// 0,0009 battiti, massima 0,0097: prova A0 del 21/10 [R]); lo scavalco avanti zittisce da un buffer in su; indietro
// niente; il quantum e l'etichetta che salta di un intero; i buchi del 24/10; le due origini (0 e l'«uno» del rientro).

final class LateBeatDecisionTests: XCTestCase {

    private let frames = 512
    private let rate48 = 48_000.0
    private let rate44 = 44_100.0

    private func late(_ origin: Double, _ before: Double, _ after: Double) -> Double? {
        LateBeatDecision.lateBeats(origin: origin, before: before, after: after)
    }

    private func mutes(_ origin: Double, _ before: Double, _ after: Double, bpm: Double, rate: Double = 48_000) -> Bool {
        LateBeatDecision.mutes(origin: origin, before: before, after: after, bpm: bpm, bufferFrames: 512, sampleRate: rate)
    }

    // MARK: - La griglia

    func testThePendingBeatOnTheGrid() {
        XCTAssertEqual(LateBeatDecision.pendingBeat(origin: 0, beat: 10.3), 11)
        XCTAssertEqual(LateBeatDecision.pendingBeat(origin: 0, beat: 11.0), 11)
        XCTAssertEqual(LateBeatDecision.pendingBeat(origin: 0.25, beat: 10.3), 11.25)
        XCTAssertEqual(LateBeatDecision.pendingBeat(origin: 0.25, beat: 10.2), 10.25)
        XCTAssertEqual(LateBeatDecision.pendingBeat(origin: 40.0943, beat: 41.5), 42.0943, accuracy: 1e-9)
        XCTAssertEqual(LateBeatDecision.aheadBeats(origin: 0, beat: 10.3), 0.7, accuracy: 1e-9)
        XCTAssertEqual(LateBeatDecision.aheadBeats(origin: 0, beat: 11.0), 0, accuracy: 1e-9)
        XCTAssertEqual(LateBeatDecision.maxAheadBeats, 1.5)
    }

    /// Il re-map: sotto mezzo battito di correzione l'etichetta del pendente è la stessa; da mezzo in su salta di un
    /// intero (cambia il nome, non la fisica).
    func testTheRemapOfThePendingBeat() {
        XCTAssertEqual(LateBeatDecision.pendingBeatAfter(origin: 0, before: 10.3, after: 10.4), 11)
        XCTAssertEqual(LateBeatDecision.pendingBeatAfter(origin: 0, before: 10.3, after: 10.9), 12)
        XCTAssertEqual(LateBeatDecision.pendingBeatAfter(origin: 0, before: 10.3, after: 12.0), 13)
        XCTAssertEqual(LateBeatDecision.pendingBeatAfter(origin: 0, before: 10.3, after: 10.0), 11)
        XCTAssertEqual(LateBeatDecision.pendingBeatAfter(origin: 0, before: 10.3, after: 9.5), 10)
    }

    // MARK: - Lo scavalco

    /// Una correzione in avanti che scavalca il pendente: il battito esce al primo campione, in ritardo dell'ampiezza
    /// dello scavalco.
    func testAForwardCorrectionThatOvertakesThePendingBeatIsLate() {
        XCTAssertEqual(late(0, 10.9, 11.2)!, 0.2, accuracy: 1e-9)
        XCTAssertEqual(late(0, 10.99, 11.005)!, 0.005, accuracy: 1e-9)
        XCTAssertEqual(late(0.25, 11.2, 11.3)!, 0.05, accuracy: 1e-9)
    }

    /// Il pendente resta davanti, o la correzione è indietro: niente.
    func testNoOvertakeNoLateBeat() {
        XCTAssertNil(late(0, 10.3, 10.4))
        XCTAssertNil(late(0, 10.9, 10.95))
        XCTAssertNil(late(0, 11.2, 11.0))
        XCTAssertNil(late(0, 10.3, 9.0))
        XCTAssertNil(late(0, 11.0, 11.0))
    }

    /// Da mezzo battito in su l'etichetta salta di un intero e il pendente resta davanti: il battito si perde, non esce in
    /// ritardo (il conto lo rimette il lavoro sul Follower). Sopra una battuta intera lo stesso.
    func testAHalfBeatOrMoreSkipsTheLabelInsteadOfFiring() {
        XCTAssertNil(late(0, 10.3, 10.85))
        XCTAssertNil(late(0, 10.9, 11.5))
        XCTAssertNil(late(0, 10.3, 12.0))
        XCTAssertNil(late(0, 10.9, 12.6))
    }

    // MARK: - La soglia di un buffer

    /// Una correzione normale non zittisce mai: la più grande misurata (0,0097 battiti) dà al più 4,8 ms a 121 BPM, sotto un
    /// buffer (10,67 ms a 48 kHz, 11,6 a 44,1). Anche nel caso peggiore, col pendente a un passo.
    func testNormalCorrectionsNeverMute() {
        for bpm in [110.5, 121.0, 160.5, 180.5] {
            for delta in [0.0001, 0.0009, 0.005, 0.0097] {
                for ahead in [0.0, 0.0001, 0.004, 0.0096] where ahead < delta {
                    let before = 11.0 - ahead
                    let after = before + delta
                    let tag = "bpm:\(bpm) delta:\(delta) davanti:\(ahead)"
                    let lateBeats = late(0, before, after)
                    XCTAssertNotNil(lateBeats, tag)
                    XCTAssertFalse(mutes(0, before, after, bpm: bpm), tag)
                    XCTAssertFalse(mutes(0, before, after, bpm: bpm, rate: rate44), tag)
                    XCTAssertLessThan(LateBeatDecision.lateMilliseconds(lateBeats: lateBeats, bpm: bpm), 10.67, tag)
                }
            }
        }
    }

    /// La soglia: un buffer. A 121 BPM un buffer a 48 kHz sono 0,0215 battiti, a 44,1 kHz 0,0234.
    func testTheOneBufferThreshold() {
        XCTAssertEqual(LateBeatDecision.bufferSeconds(bufferFrames: frames, sampleRate: rate48)!, 0.010667, accuracy: 1e-6)
        XCTAssertEqual(LateBeatDecision.bufferSeconds(bufferFrames: frames, sampleRate: rate44)!, 0.011610, accuracy: 1e-6)
        XCTAssertNil(LateBeatDecision.bufferSeconds(bufferFrames: 0, sampleRate: rate48))
        let bpm = 121.0
        let oneBuffer48 = 0.010667 * bpm / 60.0
        XCTAssertFalse(LateBeatDecision.mutesLateBeat(lateBeats: oneBuffer48 * 0.99, bpm: bpm, bufferFrames: frames, sampleRate: rate48))
        XCTAssertTrue(LateBeatDecision.mutesLateBeat(lateBeats: oneBuffer48 * 1.01, bpm: bpm, bufferFrames: frames, sampleRate: rate48))
        XCTAssertFalse(LateBeatDecision.mutesLateBeat(lateBeats: oneBuffer48 * 1.01, bpm: bpm, bufferFrames: frames, sampleRate: rate44))
        XCTAssertFalse(LateBeatDecision.mutesLateBeat(lateBeats: nil, bpm: bpm, bufferFrames: frames, sampleRate: rate48))
        XCTAssertEqual(LateBeatDecision.lateMilliseconds(lateBeats: 0.2, bpm: 120), 100, accuracy: 1e-9)
        XCTAssertEqual(LateBeatDecision.lateMilliseconds(lateBeats: nil, bpm: 120), 0)
    }

    /// Uno scavalco di 0,2 battiti a 121 BPM (99 ms): zittito; di 0,01 (5 ms): no.
    func testOvertakesAboveAndBelowABuffer() {
        XCTAssertTrue(mutes(0, 10.9, 11.2, bpm: 121))
        XCTAssertTrue(mutes(0, 10.9, 11.2, bpm: 121, rate: rate44))
        XCTAssertFalse(mutes(0, 10.995, 11.005, bpm: 121), "0,005 battiti = 2,5 ms")
        XCTAssertFalse(mutes(0, 10.98, 11.005, bpm: 121), "il ritardo e' lo scavalco, 0,005, non la correzione")
        XCTAssertTrue(mutes(0, 10.98, 11.025, bpm: 121), "0,025 battiti = 12,4 ms")
    }

    // MARK: - I buchi del 24/10

    /// I buchi misurati il 24/10, come correzioni di fase a 121 BPM, col pendente a 0,1 battiti: 108,8 ms (0,219 battiti)
    /// scavalca ed esce 59 ms in ritardo (zittito); 254,5 ms (0,513) e i tre sopra i 780 ms saltano l'etichetta: nessun
    /// battito in ritardo, il battito si perde.
    func testTheHolesOfOctober24AsCorrections() {
        let bpm = 121.0
        func delta(_ ms: Double) -> Double { ms / 1000.0 * bpm / 60.0 }
        let before = 10.9
        let small = late(0, before, before + delta(108.8))
        XCTAssertEqual(small!, delta(108.8) - 0.1, accuracy: 1e-9)
        XCTAssertEqual(LateBeatDecision.lateMilliseconds(lateBeats: small, bpm: bpm), 108.8 - 0.1 * 60_000.0 / bpm, accuracy: 1e-6)
        XCTAssertTrue(mutes(0, before, before + delta(108.8), bpm: bpm))
        for ms in [254.5, 783.7, 835.4, 906.1] {
            XCTAssertNil(late(0, before, before + delta(ms)), "\(ms)")
            XCTAssertFalse(mutes(0, before, before + delta(ms), bpm: bpm), "\(ms)")
        }
        // Col pendente a 0,3: il buco da 108,8 non lo scavalca (0,219 < 0,3).
        XCTAssertNil(late(0, 10.7, 10.7 + delta(108.8)))
    }

    /// Le due origini: 0 (il Play fresco, l'ingresso del Follower) e l'«uno» del rientro (40,0943 il 24/10 alle 14:32:44).
    func testBothOrigins() {
        XCTAssertEqual(late(0, 10.9, 11.2)!, 0.2, accuracy: 1e-9)
        let origin = 40.0943
        XCTAssertEqual(late(origin, origin + 10.9, origin + 11.2)!, 0.2, accuracy: 1e-9)
        XCTAssertNil(late(origin, origin + 10.3, origin + 10.4))
        // La griglia è dell'origine: con l'origine sbagliata (0) la stessa correzione darebbe un'altra risposta (il
        // pendente sarebbe 51, e il ritardo 0,2943).
        XCTAssertEqual(late(0, origin + 10.9, origin + 11.2)!, 0.2943, accuracy: 1e-6)
    }

    /// Valori non finiti: niente.
    func testNonFiniteInputsGiveNothing() {
        XCTAssertNil(late(.nan, 10, 11))
        XCTAssertNil(late(0, .infinity, 11))
        XCTAssertFalse(mutes(0, 10.9, 11.2, bpm: 0))
        XCTAssertFalse(LateBeatDecision.mutesLateBeat(lateBeats: 0.5, bpm: 120, bufferFrames: 512, sampleRate: 0))
    }
}
