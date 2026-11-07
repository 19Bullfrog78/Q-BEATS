import XCTest

// === A425 — banco dello scatto della ripresa e dell'origine (`ResumeSnapDecision`, banco Models), mandato A425, par. 2.1 ===
// Il battito del 24/10 (registro dell'iPhone delle 14:37:21, righe 1975-1976 [R: referto A423, par. 2.1]): 38,5709 a 121 in 4/4.
// Con l'origine di prima (0,094321, la proiezione del sequencer) lo scatto dà 40,094321, e il DSP, la cui origine è 0, lo mette sul
// battito 41: il «due». Con l'origine del DSP (P1) lo scatto dà 40,0, l'«uno». Il valore che il Direttore fuori da una canzone
// scrive su Link alla ripresa è lo stesso battito scattato: 40,094321 prima, 40,0 dopo. Poi 3/4 e 6/8 (sei battiti per battuta,
// `TimeSignature`), un battito proprio sul confine, e la proprietà «il battito scritto meno l'origine del DSP è un multiplo dei
// battiti per battuta».

final class ResumeSnapDecisionTests: XCTestCase {

    private let rate = 48_000.0

    /// Il 24/10 con P1: l'origine 0 (quella del DSP), 38,5709 a 121 in 4/4 ⇒ 40,0, l'«uno» accentato.
    func testTheBeatOfTheTwentyFourthWithTheDSPOriginSnapsToTheOne() {
        let snapped = ResumeSnapDecision.snappedBeat(beat: 38.5709, origin: 0, beatsPerBar: 4)
        XCTAssertEqual(snapped, 40.0, accuracy: 1e-9)
        let dsp = ResumeSnapDecision.dspPosition(beatPosition: snapped, dspOrigin: 0, beatsPerBar: 4, sampleRate: rate, bpm: 121)
        XCTAssertEqual(dsp.beatInBar, 0, "l'«uno»")
        XCTAssertEqual(dsp.nextBeat, 40.0, accuracy: 1e-9, "il primo click è il battito scattato")
    }

    /// Il 24/10 come fino ad A424: l'origine 0,094321 (la proiezione del sequencer) e il DSP con l'origine 0 ⇒ 40,094321, che il DSP
    /// mette sul battito 41, il «due».
    func testTheBeatOfTheTwentyFourthWithTheSequencerOriginLandsOnTheTwo() {
        let snapped = ResumeSnapDecision.snappedBeat(beat: 38.5709, origin: 0.094321, beatsPerBar: 4)
        XCTAssertEqual(snapped, 40.094321, accuracy: 1e-9)
        let dsp = ResumeSnapDecision.dspPosition(beatPosition: snapped, dspOrigin: 0, beatsPerBar: 4, sampleRate: rate, bpm: 121)
        XCTAssertEqual(dsp.beatInBar, 1, "il «due»")
        XCTAssertEqual(dsp.nextBeat, 41.0, accuracy: 1e-9)
    }

    /// 3/4 e 6/8: lo scatto alla battuta dopo, sull'«uno» del DSP; con l'origine di prima fuori dall'«uno».
    func testThreeFourAndSixEight() {
        let three = ResumeSnapDecision.snappedBeat(beat: 38.5709, origin: 0, beatsPerBar: 3)
        XCTAssertEqual(three, 39.0, accuracy: 1e-9, "13 battute")
        XCTAssertEqual(ResumeSnapDecision.dspPosition(beatPosition: three, dspOrigin: 0, beatsPerBar: 3,
                                                      sampleRate: rate, bpm: 121).beatInBar, 0)
        let six = ResumeSnapDecision.snappedBeat(beat: 38.5709, origin: 0, beatsPerBar: 6)
        XCTAssertEqual(six, 42.0, accuracy: 1e-9, "7 battute")
        XCTAssertEqual(ResumeSnapDecision.dspPosition(beatPosition: six, dspOrigin: 0, beatsPerBar: 6,
                                                      sampleRate: rate, bpm: 101).beatInBar, 0)
        let threeBefore = ResumeSnapDecision.snappedBeat(beat: 38.5709, origin: 0.094321, beatsPerBar: 3)
        XCTAssertEqual(ResumeSnapDecision.dspPosition(beatPosition: threeBefore, dspOrigin: 0, beatsPerBar: 3,
                                                      sampleRate: rate, bpm: 121).beatInBar, 1)
        let sixBefore = ResumeSnapDecision.snappedBeat(beat: 38.5709, origin: 0.094321, beatsPerBar: 6)
        XCTAssertEqual(ResumeSnapDecision.dspPosition(beatPosition: sixBefore, dspOrigin: 0, beatsPerBar: 6,
                                                      sampleRate: rate, bpm: 101).beatInBar, 1)
    }

    /// Un battito proprio sul confine resta lì, ed è l'«uno»; mezzo campione di tolleranza nel DSP; appena dopo il confine, la
    /// battuta dopo.
    func testABeatExactlyOnTheBoundaryStaysThere() {
        XCTAssertEqual(ResumeSnapDecision.snappedBeat(beat: 40.0, origin: 0, beatsPerBar: 4), 40.0, accuracy: 1e-12)
        let dsp = ResumeSnapDecision.dspPosition(beatPosition: 40.0, dspOrigin: 0, beatsPerBar: 4, sampleRate: rate, bpm: 121)
        XCTAssertEqual(dsp.beatInBar, 0)
        XCTAssertEqual(dsp.nextBeat, 40.0, accuracy: 1e-12)
        let underHalfSample = 0.4 / rate * (121.0 / 60.0)
        XCTAssertEqual(ResumeSnapDecision.dspPosition(beatPosition: 40.0 + underHalfSample, dspOrigin: 0, beatsPerBar: 4,
                                                      sampleRate: rate, bpm: 121).nextBeat, 40.0, accuracy: 1e-12)
        XCTAssertEqual(ResumeSnapDecision.snappedBeat(beat: 40.001, origin: 0, beatsPerBar: 4), 44.0, accuracy: 1e-12)
    }

    /// La proprietà: dall'origine del DSP il battito scritto meno l'origine è un multiplo dei battiti per battuta, non prima del
    /// battito e meno di una battuta dopo; il DSP lo mette sull'«uno». Per ogni metro, origine e battito.
    func testTheSnappedBeatMinusTheDSPOriginIsAWholeNumberOfBars() {
        var cases = 0
        for bpb in [2, 3, 4, 5, 6, 7, 9, 12] {
            for origin in [0.0, 12.0, 37.25, 1003.5] {
                for k in 0..<50 {
                    let beat = origin + Double(k) * 0.731 + 0.013
                    let snapped = ResumeSnapDecision.snappedBeat(beat: beat, origin: origin, beatsPerBar: Double(bpb))
                    let bars = (snapped - origin) / Double(bpb)
                    let tag = "metro:\(bpb) origine:\(origin) battito:\(beat)"
                    XCTAssertEqual(bars, bars.rounded(), accuracy: 1e-9, tag)
                    XCTAssertGreaterThanOrEqual(snapped, beat - 1e-9, tag)
                    XCTAssertLessThan(snapped - beat, Double(bpb) + 1e-9, tag)
                    let dsp = ResumeSnapDecision.dspPosition(beatPosition: snapped, dspOrigin: origin, beatsPerBar: bpb,
                                                             sampleRate: rate, bpm: 121)
                    XCTAssertEqual(dsp.beatInBar, 0, tag)
                    cases += 1
                }
            }
        }
        XCTAssertEqual(cases, 8 * 4 * 50)
    }

    /// Il valore che il Direttore fuori da una canzone scrive su Link alla ripresa (`link_engine_start_at_beat`) è il battito
    /// scattato: 40,0 con P1, sulla griglia del DSP, al posto di 40,094321. Non è una scrittura nuova: cambia il valore.
    func testTheValueWrittenToLinkAtTheResumeIsOnTheDSPGrid() {
        let written = ResumeSnapDecision.snappedBeat(beat: 38.5709, origin: 0, beatsPerBar: 4)
        let before = ResumeSnapDecision.snappedBeat(beat: 38.5709, origin: 0.094321, beatsPerBar: 4)
        XCTAssertEqual(written, 40.0, accuracy: 1e-9)
        XCTAssertEqual(before, 40.094321, accuracy: 1e-9)
        XCTAssertEqual(written.truncatingRemainder(dividingBy: 4), 0, accuracy: 1e-9, "un «uno» intero")
        XCTAssertNotEqual(before.truncatingRemainder(dividingBy: 4), 0, "prima fuori dalla griglia del DSP")
    }
}
