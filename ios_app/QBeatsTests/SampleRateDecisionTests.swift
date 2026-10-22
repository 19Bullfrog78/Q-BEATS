import XCTest

// === A416 — banco della frequenza da una fonte sola (`SampleRateDecision`, banco Models), mandato §2.1 ===
// I casi del mandato: 48000 → 44100 e ritorno, 32000 (la chiamata), 0 Hz, valori uguali, e il caso dell'iPad del
// 19/10 alle 10:51 (la sessione a 44100 vecchia, l'uscita già a 48000: si sceglie 48000). Poi il motore in moto (niente
// si scrive, si ferma e si ricostruisce), il primo giro all'avvio dell'app (i campioni del click mai fatti) e la
// matrice: uscita × sessione × copia × DSP × click × durata del buffer × motore, con l'atteso scritto qui dalla regola
// del mandato (non ricavato dal tipo).

final class SampleRateDecisionTests: XCTestCase {

    private func reading(output: Double, session: Double, copy: Double, dsp: Double,
                         click: Double, io: Double, running: Bool = false) -> SampleRateDecision.Reading {
        SampleRateDecision.Reading(output: output, session: session, copy: copy, dsp: dsp,
                                   click: click, ioBuffer: io, engineRunning: running)
    }

    private func allAt(_ hz: Double, output: Double, session: Double? = nil,
                       running: Bool = false) -> SampleRateDecision.Outcome {
        SampleRateDecision.outcome(reading(output: output, session: session ?? output, copy: hz, dsp: hz,
                                           click: hz, io: hz, running: running))
    }

    // MARK: - La fonte

    /// Il nodo d'uscita vince sulla sessione: è il formato dell'hardware.
    func testTheOutputNodeIsTheSource() {
        let o = SampleRateDecision.outcome(reading(output: 48000, session: 44100, copy: 44100, dsp: 44100,
                                                   click: 44100, io: 44100))
        XCTAssertEqual(o.rate, 48000)
        XCTAssertEqual(o.source, .output)
        XCTAssertEqual(o.action, .apply)
        XCTAssertTrue(o.rewritesCopy)
        XCTAssertTrue(o.rewritesDSP)
        XCTAssertTrue(o.regeneratesClick)
        XCTAssertTrue(o.requestsIOBuffer)
        XCTAssertTrue(o.reconnectsGraph)
    }

    /// L'iPad del 19/10, 10:51: dalle 08:21 la copia del motore e i nodi erano a 44100, il DSP e i campioni del click a
    /// 48000 (mai riscritti), la sessione ancora a 44100 (vecchia) mentre l'uscita andava già a 48000. Si sceglie 48000:
    /// si riscrive la copia (e si ricollegano i nodi); DSP, click e durata del buffer sono già lì.
    func testTheIPadCaseOf19OctoberAt1051() {
        let o = SampleRateDecision.outcome(reading(output: 48000, session: 44100, copy: 44100, dsp: 48000,
                                                   click: 48000, io: 48000))
        XCTAssertEqual(o.rate, 48000)
        XCTAssertEqual(o.source, .output)
        XCTAssertEqual(o.action, .apply)
        XCTAssertTrue(o.rewritesCopy)
        XCTAssertFalse(o.rewritesDSP)
        XCTAssertFalse(o.regeneratesClick)
        XCTAssertFalse(o.requestsIOBuffer)
        XCTAssertTrue(o.reconnectsGraph)
    }

    /// Il nodo d'uscita a zero (uscita non abilitata, o un momento in cui non lo sa): la sessione.
    func testZeroOutputFallsBackToTheSession() {
        let o = SampleRateDecision.outcome(reading(output: 0, session: 44100, copy: 48000, dsp: 48000,
                                                   click: 48000, io: 48000))
        XCTAssertEqual(o.rate, 44100)
        XCTAssertEqual(o.source, .session)
        XCTAssertEqual(o.action, .apply)
        XCTAssertTrue(o.rewritesCopy)
    }

    /// Zero anche la sessione: la copia resta com'è, e niente cambia.
    func testBothZeroKeepTheCopy() {
        let o = SampleRateDecision.outcome(reading(output: 0, session: 0, copy: 48000, dsp: 48000,
                                                   click: 48000, io: 48000))
        XCTAssertEqual(o.rate, 48000)
        XCTAssertEqual(o.source, SampleRateSource.noSource)
        XCTAssertEqual(o.action, .unchanged)
        XCTAssertFalse(o.rewritesCopy || o.rewritesDSP || o.regeneratesClick || o.requestsIOBuffer)
    }

    /// Zero tutte e due e un DSP diverso dalla copia (non succede: li scrive la stessa funzione): il DSP va alla copia.
    func testBothZeroBringTheOtherCopiesToTheCopy() {
        let o = SampleRateDecision.outcome(reading(output: 0, session: 0, copy: 48000, dsp: 44100,
                                                   click: 48000, io: 48000))
        XCTAssertEqual(o.rate, 48000)
        XCTAssertEqual(o.action, .apply)
        XCTAssertFalse(o.rewritesCopy)
        XCTAssertTrue(o.rewritesDSP)
        XCTAssertFalse(o.reconnectsGraph)
    }

    /// Valori che non si possono usare: mai una frequenza a zero (il DSP dividerebbe per zero).
    func testNeverZeroAndNeverNotFinite() {
        XCTAssertEqual(SampleRateDecision.outcome(reading(output: 0, session: 0, copy: 0, dsp: 0, click: 0, io: 0)).rate,
                       48000)
        XCTAssertEqual(SampleRateDecision.outcome(reading(output: .nan, session: 44100, copy: 48000, dsp: 48000,
                                                          click: 48000, io: 48000)).source, .session)
        XCTAssertEqual(SampleRateDecision.outcome(reading(output: .infinity, session: -1, copy: 48000, dsp: 48000,
                                                          click: 48000, io: 48000)).source, SampleRateSource.noSource)
        XCTAssertFalse(SampleRateDecision.isUsable(0))
        XCTAssertFalse(SampleRateDecision.isUsable(-48000))
        XCTAssertFalse(SampleRateDecision.isUsable(.nan))
        XCTAssertTrue(SampleRateDecision.isUsable(8000))
    }

    // MARK: - I cambi del mandato

    /// 48000 → 44100 e ritorno, a motore fermo: ogni volta tutte le copie insieme.
    func testFrom48000To44100AndBack() {
        let down = allAt(48000, output: 44100)
        XCTAssertEqual(down.rate, 44100)
        XCTAssertEqual(down.action, .apply)
        XCTAssertTrue(down.rewritesCopy && down.rewritesDSP && down.regeneratesClick && down.requestsIOBuffer)
        let back = allAt(44100, output: 48000)
        XCTAssertEqual(back.rate, 48000)
        XCTAssertEqual(back.action, .apply)
        XCTAssertTrue(back.rewritesCopy && back.rewritesDSP && back.regeneratesClick && back.requestsIOBuffer)
    }

    /// La chiamata: 32000 durante, 48000 dopo (il 19/10 alle 11:55, A415 §4.10).
    func testThe32000CallAndBack() {
        let during = allAt(48000, output: 32000)
        XCTAssertEqual(during.rate, 32000)
        XCTAssertEqual(during.action, .apply)
        XCTAssertTrue(during.reconnectsGraph)
        let after = allAt(32000, output: 48000)
        XCTAssertEqual(after.rate, 48000)
        XCTAssertEqual(after.action, .apply)
        XCTAssertTrue(after.rewritesDSP)
    }

    /// Valori uguali: niente.
    func testEqualValuesDoNothing() {
        for hz in [32000.0, 44100, 48000] {
            for running in [false, true] {
                let o = allAt(hz, output: hz, running: running)
                XCTAssertEqual(o.action, .unchanged, "hz:\(hz) motore:\(running)")
                XCTAssertFalse(o.rewritesCopy || o.rewritesDSP || o.regeneratesClick || o.requestsIOBuffer)
                XCTAssertFalse(o.reconnectsGraph)
            }
        }
    }

    /// Meno di mezzo hertz è la stessa frequenza: nessuna ricostruzione per un arrotondamento.
    func testUnderHalfAHertzIsTheSameRate() {
        XCTAssertEqual(allAt(48000, output: 48000.3).action, .unchanged)
        XCTAssertEqual(allAt(48000, output: 47999.6).action, .unchanged)
        XCTAssertEqual(allAt(48000, output: 48000.5).action, .apply)
        XCTAssertTrue(SampleRateDecision.same(44100, 44100.49))
        XCTAssertFalse(SampleRateDecision.same(44100, 44100.5))
    }

    // MARK: - Il motore in moto

    /// A motore in moto con la frequenza diversa niente si scrive: si ferma e si ricostruisce.
    func testRunningEngineWithADifferentRateStopsAndRebuilds() {
        let o = allAt(48000, output: 44100, running: true)
        XCTAssertEqual(o.rate, 44100)
        XCTAssertEqual(o.action, .stopAndRebuild)
        XCTAssertFalse(o.rewritesCopy || o.rewritesDSP || o.regeneratesClick || o.requestsIOBuffer)
        XCTAssertFalse(o.reconnectsGraph)
    }

    /// A motore in moto basta una copia fuori posto (il DSP, i campioni del click) per fermare e ricostruire.
    func testRunningEngineWithOneCopyOutOfPlace() {
        let dsp = SampleRateDecision.outcome(reading(output: 48000, session: 48000, copy: 48000, dsp: 44100,
                                                     click: 48000, io: 48000, running: true))
        XCTAssertEqual(dsp.action, .stopAndRebuild)
        let click = SampleRateDecision.outcome(reading(output: 48000, session: 48000, copy: 48000, dsp: 48000,
                                                       click: 44100, io: 48000, running: true))
        XCTAssertEqual(click.action, .stopAndRebuild)
    }

    /// A motore in moto la durata del buffer da sola non ferma niente: si chiede alla prossima chiamata a motore fermo.
    func testRunningEngineDefersTheIOBuffer() {
        let running = SampleRateDecision.outcome(reading(output: 48000, session: 48000, copy: 48000, dsp: 48000,
                                                         click: 48000, io: 44100, running: true))
        XCTAssertEqual(running.action, .unchanged)
        XCTAssertFalse(running.requestsIOBuffer)
        let stopped = SampleRateDecision.outcome(reading(output: 48000, session: 48000, copy: 48000, dsp: 48000,
                                                         click: 48000, io: 44100, running: false))
        XCTAssertEqual(stopped.action, .apply)
        XCTAssertTrue(stopped.requestsIOBuffer)
        XCTAssertFalse(stopped.reconnectsGraph)
    }

    // MARK: - L'avvio dell'app

    /// Il primo giro: la copia e il DSP nascono a 48000, la durata del buffer l'ha già chiesta `setupSession` per
    /// 48000, i campioni del click non ci sono: si fanno, e basta.
    func testFirstCallAtBootMakesTheClickSamples() {
        let o = SampleRateDecision.outcome(reading(output: 48000, session: 48000, copy: 48000, dsp: 48000,
                                                   click: 0, io: 48000))
        XCTAssertEqual(o.action, .apply)
        XCTAssertTrue(o.regeneratesClick)
        XCTAssertFalse(o.rewritesCopy || o.rewritesDSP || o.requestsIOBuffer)
    }

    /// Lo stesso con l'uscita a 44100 all'avvio: tutte le copie a 44100, e la durata del buffer richiesta.
    func testFirstCallAtBootWithTheOutputAt44100() {
        let o = SampleRateDecision.outcome(reading(output: 44100, session: 44100, copy: 48000, dsp: 48000,
                                                   click: 0, io: 48000))
        XCTAssertEqual(o.rate, 44100)
        XCTAssertTrue(o.rewritesCopy && o.rewritesDSP && o.regeneratesClick && o.requestsIOBuffer)
    }

    // MARK: - La durata del buffer

    func testTheIOBufferDurationIs512SamplesOfTheChosenRate() {
        XCTAssertEqual(SampleRateDecision.ioBufferDuration(rate: 48000)!, 512.0 / 48000.0, accuracy: 1e-12)
        XCTAssertEqual(SampleRateDecision.ioBufferDuration(rate: 44100)!, 512.0 / 44100.0, accuracy: 1e-12)
        XCTAssertEqual(SampleRateDecision.ioBufferDuration(rate: 32000)!, 0.016, accuracy: 1e-12)
        XCTAssertNil(SampleRateDecision.ioBufferDuration(rate: 0))
        XCTAssertEqual(SampleRateDecision.preferredSampleRate, 48000)
        XCTAssertEqual(SampleRateDecision.bufferFrames, 512)
    }

    // MARK: - La matrice

    /// L'atteso di una cella, dalla regola del mandato §2.1.
    private func expected(_ r: SampleRateDecision.Reading) -> (rate: Double, source: SampleRateSource,
                                                               action: SampleRateAction, copy: Bool, dsp: Bool,
                                                               click: Bool, io: Bool) {
        var rate = r.copy
        var source = SampleRateSource.noSource
        if r.output > 0 {
            rate = r.output
            source = .output
        } else if r.session > 0 {
            rate = r.session
            source = .session
        }
        let copy = rate != r.copy
        let dsp = rate != r.dsp
        let click = rate != r.click
        let io = rate != r.ioBuffer
        if r.engineRunning {
            return (rate, source, (copy || dsp || click) ? .stopAndRebuild : .unchanged, false, false, false, false)
        }
        let any = copy || dsp || click || io
        return (rate, source, any ? .apply : .unchanged, copy, dsp, click, io)
    }

    func testTheMatrix() {
        var cells = 0
        for output in [0.0, 32000, 44100, 48000] {
            for session in [0.0, 44100, 48000] {
                for copy in [44100.0, 48000] {
                    for dsp in [44100.0, 48000] {
                        for click in [0.0, 44100, 48000] {
                            for io in [0.0, 44100, 48000] {
                                for running in [false, true] {
                                    cells += 1
                                    let r = reading(output: output, session: session, copy: copy, dsp: dsp,
                                                    click: click, io: io, running: running)
                                    let got = SampleRateDecision.outcome(r)
                                    let want = expected(r)
                                    let tag = "uscita:\(output) sessione:\(session) copia:\(copy) dsp:\(dsp) click:\(click) io:\(io) motore:\(running)"
                                    XCTAssertEqual(got.rate, want.rate, tag)
                                    XCTAssertEqual(got.source, want.source, tag)
                                    XCTAssertEqual(got.action, want.action, tag)
                                    XCTAssertEqual(got.rewritesCopy, want.copy, tag)
                                    XCTAssertEqual(got.rewritesDSP, want.dsp, tag)
                                    XCTAssertEqual(got.regeneratesClick, want.click, tag)
                                    XCTAssertEqual(got.requestsIOBuffer, want.io, tag)
                                    // La frequenza scelta si può sempre usare.
                                    XCTAssertTrue(SampleRateDecision.isUsable(got.rate), tag)
                                    // A motore in moto niente si scrive.
                                    if running {
                                        XCTAssertFalse(got.rewritesCopy || got.rewritesDSP || got.regeneratesClick
                                                       || got.requestsIOBuffer, tag)
                                    }
                                    // Il grafo si ricollega solo quando cambia la copia del motore.
                                    XCTAssertEqual(got.reconnectsGraph, got.rewritesCopy, tag)
                                    // «aggiornata» vuol dire che qualcosa si scrive, e viceversa.
                                    XCTAssertEqual(got.action == .apply,
                                                   got.rewritesCopy || got.rewritesDSP || got.regeneratesClick
                                                   || got.requestsIOBuffer, tag)
                                }
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 4 * 3 * 2 * 2 * 3 * 3 * 2)
    }

    // MARK: - I nomi nelle righe

    func testTheNamesInTheLines() {
        XCTAssertEqual(SampleRateSource.output.rawValue, "uscita")
        XCTAssertEqual(SampleRateSource.session.rawValue, "sessione")
        XCTAssertEqual(SampleRateSource.noSource.rawValue, "nessuna")
        XCTAssertEqual(SampleRateAction.unchanged.rawValue, "invariata")
        XCTAssertEqual(SampleRateAction.apply.rawValue, "aggiornata")
        XCTAssertEqual(SampleRateAction.stopAndRebuild.rawValue, "fermare-e-ricostruire")
    }
}
