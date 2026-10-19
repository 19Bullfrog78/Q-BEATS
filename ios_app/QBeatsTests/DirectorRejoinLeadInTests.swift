import XCTest

// === A412 · SEGUITO 2 (2/2) — banco della scorta muta del rientro (`DirectorRejoinDecision.leadIn` e sorelle) ===
// Mandato «A412 · SEGUITO 2 (2/2)», par. 3. I due fuochi del 18/10/2026 (registri QBeats_registro_iPhone_2026-10-18_
// 15-53-56.txt e _16-06-55.txt): P1 a 100 BPM, prima correzione −0,0440 battiti; passo 3 a 110 BPM, −0,0568. Le ore
// sono tick mach a 24 MHz; un buffer è 512 campioni a 48 kHz (256000 tick, 10,667 ms); la latenza d'uscita dei due
// fuochi è 302499 tick (12,604 ms). I bordi del par. 2.2 a): mappa e ponte a ±1/8 di battito (il seme è il battito di
// Link all'ora della mappa, quindi l'«uno» li porta già dentro), il primo buffer a inizio e a fine ciclo d'uscita (la
// prima correzione fra la più grande all'indietro, −43,67 ms, e la più grande in avanti, un buffer d'I/O), il tempo più
// lento e il più veloce del campo dell'app (20 e 400 BPM, `SectionEditorView.bpmRange`).

final class DirectorRejoinLeadInTests: XCTestCase {

    private typealias Decision = DirectorRejoinDecision

    private let tps = 24_000_000.0
    private let sampleRate = 48_000.0
    private let frames = 512
    private let buffer = 512.0 / 48_000.0
    private let latency: UInt64 = 302_499

    private func plan(target: UInt64, uno: Double, bpm: Double, io: Double? = nil) -> Decision.LeadIn? {
        Decision.leadIn(targetOutputTicks: target, outputLatencyTicks: latency, unoBeat: uno, bpm: bpm,
                        bufferFrames: frames, sampleRate: sampleRate, ioBufferSeconds: io ?? buffer,
                        ticksPerSecond: tps)
    }

    private func bufferBeats(_ bpm: Double) -> Double { buffer * bpm / 60.0 }

    // MARK: - Quanti buffer

    /// I tre buffer senza correzione, più ⌊I/O ÷ buffer⌋ + 1: l'«uno» davanti alla prima correzione di più di un
    /// buffer d'I/O. L'I/O di 512 campioni arrotondato in tick (255999) conta come 512.
    func testHowManyBuffers() {
        XCTAssertEqual(Decision.uncorrectedFireBuffers, 3)
        XCTAssertEqual(Decision.leadInBuffers(bufferSeconds: buffer, ioBufferSeconds: buffer), 5)
        XCTAssertEqual(Decision.leadInBuffers(bufferSeconds: buffer, ioBufferSeconds: 255_999.0 / tps), 5)
        XCTAssertEqual(Decision.leadInBuffers(bufferSeconds: buffer, ioBufferSeconds: 256.0 / 48_000.0), 4)
        XCTAssertEqual(Decision.leadInBuffers(bufferSeconds: buffer, ioBufferSeconds: 1024.0 / 48_000.0), 6)
        XCTAssertEqual(Decision.leadInBuffers(bufferSeconds: buffer, ioBufferSeconds: 2048.0 / 48_000.0), 8)
        XCTAssertEqual(Decision.leadInBuffers(bufferSeconds: buffer, ioBufferSeconds: 0), 4)
        XCTAssertNil(Decision.leadInBuffers(bufferSeconds: 0, ioBufferSeconds: buffer))
        XCTAssertNil(Decision.leadInBuffers(bufferSeconds: buffer, ioBufferSeconds: .nan))
    }

    // MARK: - I due fuochi del 18/10

    /// P1, 100 BPM: cinque buffer muti; il primo esce 1280000 tick (53,3 ms) prima dell'«uno» e si chiede al lettore
    /// una latenza prima; il seme è l'«uno» meno 0,0889 battiti. Con la prima correzione registrata (−0,0440) l'«uno»
    /// resta davanti al buffer corretto: due buffer più 0,044.
    func testTheFireOfP1() throws {
        let p = try XCTUnwrap(plan(target: 5_889_171_281_099, uno: 28.0393, bpm: 100))
        XCTAssertEqual(p.buffers, 5)
        XCTAssertEqual(p.firstBufferOutputTicks, 5_889_171_281_099 - 1_280_000)
        XCTAssertEqual(p.firstBufferRenderTicks, 5_889_171_281_099 - 1_280_000 - latency)
        XCTAssertEqual(p.beats, 0.0888889, accuracy: 1e-6)
        XCTAssertEqual(p.seedBeat, 28.0393 - 0.0888889, accuracy: 1e-6)
        XCTAssertEqual(p.unoBeat, 28.0393)
        let ahead = Decision.unoAheadAfterFirstCorrection(p, bufferBeats: bufferBeats(100), correctionBeats: -0.0440)
        XCTAssertEqual(ahead, 2 * bufferBeats(100) + 0.0440, accuracy: 1e-9)
        XCTAssertGreaterThan(ahead, 0)
    }

    /// Passo 3, 110 BPM: cinque buffer, seme l'«uno» meno 0,0978; con −0,0568 l'«uno» resta davanti.
    func testTheFireOfStep3() throws {
        let p = try XCTUnwrap(plan(target: 5_908_470_259_681, uno: 24.0292, bpm: 110))
        XCTAssertEqual(p.buffers, 5)
        XCTAssertEqual(p.firstBufferOutputTicks, 5_908_470_259_681 - 1_280_000)
        XCTAssertEqual(p.beats, 0.0977778, accuracy: 1e-6)
        XCTAssertEqual(p.seedBeat, 24.0292 - 0.0977778, accuracy: 1e-6)
        let ahead = Decision.unoAheadAfterFirstCorrection(p, bufferBeats: bufferBeats(110), correctionBeats: -0.0568)
        XCTAssertEqual(ahead, 2 * bufferBeats(110) + 0.0568, accuracy: 1e-9)
    }

    /// Il controllo «in ritardo» sull'ora del primo buffer muto, coi fuochi veri: 47,31 ms (P1) e 56,33 ms (passo
    /// 3) d'anticipo, sopra i 30 ms. Fuori dal margine (il fuoco 30 ms dopo il primo buffer) è in ritardo.
    func testTheFirstSilentBufferIsNotLate() throws {
        let minLead = UInt64(Decision.minLeadSeconds * tps)
        let p1 = try XCTUnwrap(plan(target: 5_889_171_281_099, uno: 28.0393, bpm: 100))
        XCTAssertFalse(Decision.isLate(nowTicks: 5_889_168_563_109, renderTicks: p1.firstBufferRenderTicks,
                                       minLeadTicks: minLead))
        XCTAssertEqual(Double(p1.firstBufferRenderTicks - 5_889_168_563_109) / tps * 1000, 47.31, accuracy: 0.01)
        let p3 = try XCTUnwrap(plan(target: 5_908_470_259_681, uno: 24.0292, bpm: 110))
        XCTAssertFalse(Decision.isLate(nowTicks: 5_908_467_325_183, renderTicks: p3.firstBufferRenderTicks,
                                       minLeadTicks: minLead))
        XCTAssertEqual(Double(p3.firstBufferRenderTicks - 5_908_467_325_183) / tps * 1000, 56.33, accuracy: 0.01)
        XCTAssertTrue(Decision.isLate(nowTicks: p3.firstBufferRenderTicks - minLead + 1,
                                      renderTicks: p3.firstBufferRenderTicks, minLeadTicks: minLead))
    }

    /// Il margine di 150 ms basta a ogni tempo: la scorta è in buffer, non in battiti. Fra l'armamento in orario e il
    /// primo buffer muto restano 150 − 53,33 − 12,60 = 84,06 ms; col ritardo del fuoco misurato (36,75 ms) 47,31.
    func testTheMarginHoldsAtEveryTempo() throws {
        for bpm in [20.0, 90.0, 110.0, 400.0] {
            let target: UInt64 = 1_000 * 24_000_000
            let p = try XCTUnwrap(plan(target: target, uno: 100, bpm: bpm))
            let armAt = Decision.armingTicks(targetOutputTicks: target, marginSeconds: 0.150, ticksPerSecond: tps)
            XCTAssertEqual(Double(p.firstBufferRenderTicks - armAt) / tps * 1000, 84.06, accuracy: 0.01, "\(bpm)")
            XCTAssertFalse(Decision.isLate(nowTicks: armAt + UInt64(0.03675 * tps), renderTicks: p.firstBufferRenderTicks,
                                           minLeadTicks: UInt64(Decision.minLeadSeconds * tps)), "\(bpm)")
        }
    }

    // MARK: - I bordi del par. 2.2 a)

    /// La prima correzione fra la più grande all'indietro (−43,67 ms) e la più grande in avanti (un buffer d'I/O,
    /// 10,667 ms), al tempo più lento e al più veloce: l'«uno» resta sempre davanti al buffer corretto (mai
    /// scavalcato), e la correzione resta sotto mezzo battito (il DSP non cambia etichetta al battito pendente).
    func testTheUnoStaysAheadOverTheWholeField() throws {
        for bpm in [20.0, 60.0, 100.0, 110.0, 240.0, 400.0] {
            let p = try XCTUnwrap(plan(target: 1_000 * 24_000_000, uno: 100, bpm: bpm))
            for correctionMs in [10.667, 0.0, -11.09, -22.0, -26.4, -31.0, -33.01, -43.67] {
                let correctionBeats = correctionMs / 1000.0 * bpm / 60.0
                let ahead = Decision.unoAheadAfterFirstCorrection(p, bufferBeats: bufferBeats(bpm),
                                                                  correctionBeats: correctionBeats)
                XCTAssertGreaterThan(ahead, 0, "\(bpm) BPM, correzione \(correctionMs) ms")
                XCTAssertLessThan(abs(correctionBeats), 0.5, "\(bpm) BPM, correzione \(correctionMs) ms")
            }
        }
    }

    /// Mappa e ponte a +1/8 e a −1/8 di battito: il seme è il battito di Link all'ora della mappa, quindi l'«uno» del
    /// piano li porta già dentro (24,125 o 23,875), e la scorta è la stessa: il seme è l'«uno» meno gli stessi
    /// battiti, e la correzione prima del click resta quella della sola convenzione.
    func testMapAndBridgeAtPlusAndMinusOneEighth() throws {
        for uno in [24.125, 23.875] {
            let p = try XCTUnwrap(plan(target: 5_908_470_259_681, uno: uno, bpm: 110))
            XCTAssertEqual(p.buffers, 5)
            XCTAssertEqual(p.seedBeat, uno - 0.0977778, accuracy: 1e-6)
            let ahead = Decision.unoAheadAfterFirstCorrection(p, bufferBeats: bufferBeats(110),
                                                              correctionBeats: buffer * 110 / 60)
            XCTAssertEqual(ahead, bufferBeats(110), accuracy: 1e-9)
        }
    }

    /// Il tempo più lento e il più veloce: la scorta in battiti (0,0178 a 20 BPM, 0,3556 a 400) resta sotto mezzo
    /// battito. Con un I/O di 2048 campioni a 400 BPM non ci starebbe (8 buffer, 0,569): niente scorta, si entra come
    /// prima. Un seme che andrebbe sotto zero: niente scorta.
    func testTheSlowestAndFastestTempo() throws {
        let slow = try XCTUnwrap(plan(target: 1_000 * 24_000_000, uno: 100, bpm: 20))
        XCTAssertEqual(slow.beats, 0.0177778, accuracy: 1e-6)
        let fast = try XCTUnwrap(plan(target: 1_000 * 24_000_000, uno: 100, bpm: 400))
        XCTAssertEqual(fast.beats, 0.3555556, accuracy: 1e-6)
        XCTAssertLessThan(fast.beats, 0.5)
        XCTAssertNil(plan(target: 1_000 * 24_000_000, uno: 100, bpm: 400, io: 2048.0 / 48_000.0))
        XCTAssertNil(plan(target: 1_000 * 24_000_000, uno: 0.05, bpm: 110))
        XCTAssertNil(Decision.leadIn(targetOutputTicks: 1_000, outputLatencyTicks: latency, unoBeat: 24, bpm: 110,
                                     bufferFrames: frames, sampleRate: sampleRate, ioBufferSeconds: buffer,
                                     ticksPerSecond: tps))
    }

    // MARK: - La correzione e il MIDI nella scorta

    /// Nella scorta la correzione gira una volta sola: la prima.
    func testOnlyTheFirstCorrectionDuringTheLeadIn() {
        XCTAssertTrue(Decision.leadInAllowsCorrection(correctionsSoFar: 0))
        XCTAssertFalse(Decision.leadInAllowsCorrection(correctionsSoFar: 1))
        XCTAssertFalse(Decision.leadInAllowsCorrection(correctionsSoFar: 2))
    }

    /// Il MIDI tace finché l'«uno» non cade nel buffer: con l'«uno» a 24 e un buffer di 0,0196 battiti (110 BPM),
    /// tace il buffer che comincia a 23,9 e quello che finisce proprio su 24; suona quello che comincia a 23,99.
    func testTheMIDIWaitsForTheUnoBuffer() {
        let b = bufferBeats(110)
        XCTAssertTrue(Decision.leadInHoldsMIDI(bufferStartBeat: 23.9, bufferBeats: b, unoBeat: 24))
        XCTAssertTrue(Decision.leadInHoldsMIDI(bufferStartBeat: 24 - b, bufferBeats: b, unoBeat: 24))
        XCTAssertFalse(Decision.leadInHoldsMIDI(bufferStartBeat: 23.99, bufferBeats: b, unoBeat: 24))
        XCTAssertFalse(Decision.leadInHoldsMIDI(bufferStartBeat: 24.01, bufferBeats: b, unoBeat: 24))
        XCTAssertFalse(Decision.leadInHoldsMIDI(bufferStartBeat: .nan, bufferBeats: b, unoBeat: 24))
    }
}
