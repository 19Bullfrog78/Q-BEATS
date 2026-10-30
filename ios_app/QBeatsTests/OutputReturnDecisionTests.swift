import XCTest

// === A421 — banco dei ritorni dopo il silenzio e della rete del motore fermo (`OutputReturnDecision`, banco Models), mandato
// par. 2.2 a-d e g, par. 2.1 U3 c e U6 ===
// Un orologio finto a 24 MHz. Le due ore del Follower coi tempi veri del 24/10 (il render ripartito 681 e 684 ms dopo la
// notizia) e con la premessa del referto A419 (30-36 ms); il primo «uno» di Link e quello della linea propria; l'ora in
// cui rimettere il volume per il buffer dell'«uno» (U3 c); le attese del Direttore; la riga della rete.
// A421 · SEGUITO 1 (par. 2): il tocco con la regola della notizia (`testTheTapDeadline` è uscito col `tapDeadlineTicks`); la
// guardia del primo campione a volume 1, anche con la lettura di riserva; la battuta dopo, con Link e DA-SOLO; la rilettura
// dell'«uno»; il segno «uno non calcolabile».

final class OutputReturnDecisionTests: XCTestCase {

    private let tps = 24_000_000.0
    private let buffer = 512.0 / 48_000.0
    private let latency = 0.0233

    private func t(_ seconds: Double) -> UInt64 {
        UInt64((seconds * tps).rounded())
    }

    private func s(_ ticks: UInt64) -> Double {
        Double(ticks) / tps
    }

    // MARK: - Le costanti

    func testTheConstants() {
        XCTAssertEqual(OutputReturnDecision.directorSettleSeconds, 0.100)
        XCTAssertEqual(OutputReturnDecision.configurationReserveSeconds, 2.0)
        XCTAssertEqual(OutputReturnDecision.followerMinimumSeconds, 0.3)
        XCTAssertEqual(OutputReturnDecision.clickTailSeconds, 0.040)
        XCTAssertEqual(OutputReturnDecision.queuedAheadBuffers, 2)
        XCTAssertEqual(OutputReturnDecision.stoppedEngineNetSeconds, 2.0)
        XCTAssertEqual(OutputReturnDecision.stoppedEngineLineEvery, 10)
        XCTAssertEqual(DirectorReturnWait.settle.rawValue, "assestamento")
        XCTAssertEqual(DirectorReturnWait.configuration.rawValue, "configurazione")
    }

    // MARK: - Il Direttore (U6, par. 2.2 b)

    func testTheDirectorWaitsTheConfigurationOnlyIfTheSessionRateDiffers() {
        XCTAssertEqual(OutputReturnDecision.directorWait(sessionRateDiffersFromCopy: true), .configuration)
        XCTAssertEqual(OutputReturnDecision.directorWait(sessionRateDiffersFromCopy: false), .settle)
        XCTAssertEqual(OutputReturnDecision.directorWaitSeconds(.settle), 0.100)
        XCTAssertEqual(OutputReturnDecision.directorWaitSeconds(.configuration), 2.0)
    }

    // MARK: - Il Follower (par. 2.2 c)

    /// La fine d'uscita del buffer che la chiamata produce: due davanti più il nostro.
    func testTheProgrammedEnd() {
        let next = t(100.0)
        let end = OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: next, queuedAhead: 2, bufferTicks: t(buffer))
        XCTAssertEqual(s(end), 100.0 + 3 * buffer, accuracy: 1e-6)
        XCTAssertEqual(OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: next, queuedAhead: 0, bufferTicks: t(buffer)),
                       next + t(buffer))
        XCTAssertEqual(OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: UInt64.max - 1, queuedAhead: 2,
                                                                     bufferTicks: t(buffer)), UInt64.max)
    }

    /// Le cuffie col filo del 24/10: il render riparte 681 ms dopo la notizia. La seconda ora vince: i buffer già
    /// programmati escono fino a 0,747 s dopo la notizia, più i 40 ms del click.
    func testTheDeadlineWhenTheRenderRestarts681msLater() {
        let notice = 100.0
        let firstCall = notice + 0.681
        let nextOutput = t(firstCall + buffer + latency)
        let end = OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: nextOutput, queuedAhead: 2, bufferTicks: t(buffer))
        let deadline = OutputReturnDecision.followerDeadlineTicks(noticeTicks: t(notice), programmedEndOutputTicks: end, ticksPerSecond: tps)
        let expected = firstCall + buffer + latency + 3 * buffer + 0.040
        XCTAssertEqual(s(deadline), expected, accuracy: 1e-6)
        XCTAssertGreaterThan(s(deadline), notice + 0.3)
    }

    /// La premessa del referto A419: il buco finito 36 ms dopo la notizia. Qui vince l'ora della notizia: 0,3 s.
    func testTheDeadlineWhenTheRenderRestarts36msLater() {
        let notice = 100.0
        let nextOutput = t(notice + 0.036 + buffer + latency)
        let end = OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: nextOutput, queuedAhead: 2, bufferTicks: t(buffer))
        let deadline = OutputReturnDecision.followerDeadlineTicks(noticeTicks: t(notice), programmedEndOutputTicks: end, ticksPerSecond: tps)
        XCTAssertEqual(s(deadline), notice + 0.3, accuracy: 1e-6)
    }

    // MARK: - A421 · SEGUITO 1 (par. 2): la regola sola, il primo campione a volume 1, la battuta dopo, il segno

    private func programmedEnd(firstCallAt: Double) -> UInt64 {
        OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: t(firstCallAt + buffer + latency),
                                                      queuedAhead: OutputReturnDecision.queuedAheadBuffers, bufferTicks: t(buffer))
    }

    private func step(out: Double, uno: UInt64?, deadline: UInt64, first: UInt64) -> FollowerReturnStep {
        OutputReturnDecision.followerReturnStep(bufferOutputTicks: t(out), bufferTicks: t(buffer), unoTicks: uno,
                                                deadlineTicks: deadline, firstSampleTicks: first)
    }

    /// Par. 2.1: il tocco ha le due ore della notizia, con l'ora del tocco. Dentro il buco del 24/10 (la prima chiamata 681 ms
    /// dopo il tocco) vince la fine dei buffer programmati più la coda del click: la sola ora «0,3 s dopo il tocco» era già
    /// passata e i due buffer di prima del buco sarebbero usciti a volume 1. Senza buco vince l'ora del tocco.
    func testTheTapUsesTheNoticeRule() {
        let tap = 50.0
        let firstCall = tap + 0.681
        let deadline = OutputReturnDecision.followerDeadlineTicks(noticeTicks: t(tap), programmedEndOutputTicks: programmedEnd(firstCallAt: firstCall),
                                                                  ticksPerSecond: tps)
        XCTAssertEqual(s(deadline), firstCall + buffer + latency + 3 * buffer + 0.040, accuracy: 1e-6)
        XCTAssertGreaterThan(s(deadline), tap + 0.3)
        let noHole = OutputReturnDecision.followerDeadlineTicks(noticeTicks: t(tap), programmedEndOutputTicks: programmedEnd(firstCallAt: tap + 0.011),
                                                                ticksPerSecond: tps)
        XCTAssertEqual(s(noHole), tap + 0.3, accuracy: 1e-6)
    }

    /// Par. 2.2: il primo campione che può uscire a volume 1, nel caso peggiore: un CICLO D'USCITA (`bufferDurationTicks`, non
    /// il buffer da 512 campioni) prima del prossimo buffer da rendere; con la lettura di riserva un ciclo in più; si ferma a
    /// zero. La guardia: alla scadenza o dopo. Con un ciclo di 21,33 ms il primo campione è 21,33 ms prima, non 10,67.
    func testTheFirstSampleAtVolumeOne() {
        let next = t(100.0)
        let longCycle = 1024.0 / 48_000.0
        XCTAssertEqual(s(OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: next, cycleTicks: t(longCycle), fallbackRead: false)),
                       100.0 - longCycle, accuracy: 1e-6)
        XCTAssertEqual(s(OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: next, cycleTicks: t(longCycle), fallbackRead: true)),
                       100.0 - 2 * longCycle, accuracy: 1e-6)
        XCTAssertEqual(s(OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: next, cycleTicks: t(buffer), fallbackRead: false)),
                       100.0 - buffer, accuracy: 1e-6)
        XCTAssertEqual(s(OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: next, cycleTicks: t(buffer), fallbackRead: true)),
                       100.0 - 2 * buffer, accuracy: 1e-6)
        XCTAssertEqual(OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: t(0.005), cycleTicks: t(buffer), fallbackRead: false), 0)
        XCTAssertEqual(OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: 10, cycleTicks: UInt64.max, fallbackRead: true), 0)
        XCTAssertTrue(OutputReturnDecision.volumeMayReturn(firstSampleTicks: t(100.3), deadlineTicks: t(100.3)))
        XCTAssertTrue(OutputReturnDecision.volumeMayReturn(firstSampleTicks: t(100.31), deadlineTicks: t(100.3)))
        XCTAssertFalse(OutputReturnDecision.volumeMayReturn(firstSampleTicks: t(100.29), deadlineTicks: t(100.3)))
    }

    /// Par. 2.2: la chiamata col ritorno armato e un «uno». Il buffer non lo porta: si aspetta. Lo porta e il primo campione è
    /// alla scadenza o dopo: il volume torna. Lo porta e il primo campione è prima: la battuta dopo, con lo scarto. Con la
    /// lettura di riserva (un ciclo in più) lo stesso «uno» può passare da «torna» a «battuta dopo».
    func testTheFirstSampleGuardMovesTheReturnToTheNextBar() {
        let deadline = t(100.3)
        let uno = t(100.5)
        XCTAssertEqual(step(out: 100.4, uno: uno, deadline: deadline, first: t(100.2)), .wait)
        XCTAssertEqual(step(out: 100.49, uno: uno, deadline: deadline, first: t(100.45)), .restore)
        XCTAssertEqual(step(out: 100.49, uno: uno, deadline: deadline, first: deadline), .restore)
        XCTAssertEqual(step(out: 100.49, uno: uno, deadline: deadline, first: t(100.25)), .nextBar(earlyTicks: t(0.05)))
        let nextOut = t(100.32)
        let hardware = OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: nextOut, cycleTicks: t(buffer), fallbackRead: false)
        let fallback = OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: nextOut, cycleTicks: t(buffer), fallbackRead: true)
        XCTAssertEqual(step(out: 100.49, uno: uno, deadline: deadline, first: hardware), .restore)
        XCTAssertEqual(step(out: 100.49, uno: uno, deadline: deadline, first: fallback), .nextBar(earlyTicks: deadline - fallback))
    }

    /// Par. 2.2: senza un «uno» calcolabile il volume torna alla prima chiamata col primo campione alla scadenza o dopo.
    func testWithoutAComputableUnoTheReturnWaitsForTheDeadline() {
        let deadline = t(100.3)
        XCTAssertEqual(step(out: 100.0, uno: nil, deadline: deadline, first: t(100.1)), .wait)
        XCTAssertEqual(step(out: 100.0, uno: nil, deadline: deadline, first: t(100.29)), .wait)
        XCTAssertEqual(step(out: 100.0, uno: nil, deadline: deadline, first: t(100.3)), .restore)
        XCTAssertEqual(step(out: 100.0, uno: nil, deadline: deadline, first: t(100.4)), .restore)
    }

    /// Par. 2.2: l'«uno» della battuta dopo è lo stesso battito più una battuta, sullo stesso orologio (Link: il quantum;
    /// DA-SOLO: i battiti della battuta); non si ricalcola dalla scadenza, che darebbe lo stesso «uno».
    func testTheNextBarUno() {
        // A421 · SEGUITO 2 (E.9): la battuta dopo usa il quantum con cui l'«uno» è stato scelto.
        let link = FollowerReturnUno(beat: 48, clock: .link, beatsPerBar: 4)
        XCTAssertEqual(OutputReturnDecision.nextBarUno(link), FollowerReturnUno(beat: 52, clock: .link, beatsPerBar: 4))
        let own = FollowerReturnUno(beat: 13.5, clock: .own, beatsPerBar: 3)
        XCTAssertEqual(OutputReturnDecision.nextBarUno(own), FollowerReturnUno(beat: 16.5, clock: .own, beatsPerBar: 3))
        XCTAssertNil(OutputReturnDecision.nextBarUno(FollowerReturnUno(beat: 48, clock: .link, beatsPerBar: 0)))
        XCTAssertNil(OutputReturnDecision.nextBarUno(FollowerReturnUno(beat: .nan, clock: .link, beatsPerBar: 4)))
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 47.2, quantum: 4), 48, "il ricalcolo dalla scadenza darebbe lo stesso uno")
    }

    /// Par. 2.2: la rilettura dell'«uno» a ogni chiamata: l'orologio cambiato riarma; l'ora non rileggibile riarma; se no l'ora
    /// riletta. DA-SOLO un cambio di tempo tiene il battito e sposta l'ora (la linea propria col tempo nuovo).
    /// A421 · SEGUITO 2 (E.9): anche il metro cambiato riarma, prima di rileggere l'ora.
    func testTheUnoRefresh() {
        let uno = FollowerReturnUno(beat: 48, clock: .link, beatsPerBar: 4)
        XCTAssertEqual(OutputReturnDecision.refreshUno(saved: uno, clockNow: .own, beatsPerBarNow: 4, rereadTicks: t(101.0)),
                       .rearm(reason: "orologio-cambiato"))
        XCTAssertEqual(OutputReturnDecision.refreshUno(saved: uno, clockNow: .link, beatsPerBarNow: 3, rereadTicks: t(101.0)),
                       .rearm(reason: "metro-cambiato"))
        XCTAssertEqual(OutputReturnDecision.refreshUno(saved: uno, clockNow: .own, beatsPerBarNow: 3, rereadTicks: t(101.0)),
                       .rearm(reason: "orologio-cambiato"), "l'orologio prima del metro")
        XCTAssertEqual(OutputReturnDecision.refreshUno(saved: uno, clockNow: .link, beatsPerBarNow: 4, rereadTicks: nil),
                       .rearm(reason: "uno-non-rileggibile"))
        XCTAssertEqual(OutputReturnDecision.refreshUno(saved: uno, clockNow: .link, beatsPerBarNow: 4, rereadTicks: t(101.0)), .ticks(t(101.0)))
        XCTAssertEqual(OutputReturnDecision.unoClock(followsLink: true), .link)
        XCTAssertEqual(OutputReturnDecision.unoClock(followsLink: false), .own)
        XCTAssertEqual(FollowerReturnClock.link.rawValue, "link")
        XCTAssertEqual(FollowerReturnClock.own.rawValue, "proprio")
        let slow = OwnClockTimeline(anchorTicks: t(100.0), anchorBeat: 44, bpm: 120)
        let fast = OwnClockTimeline(anchorTicks: t(100.0), anchorBeat: 44, bpm: 160)
        XCTAssertEqual(s(OutputReturnDecision.ownTicks(atBeat: 48, timeline: slow, ticksPerSecond: tps)!), 102.0, accuracy: 1e-6)
        XCTAssertEqual(s(OutputReturnDecision.ownTicks(atBeat: 48, timeline: fast, ticksPerSecond: tps)!), 101.5, accuracy: 1e-6)
    }

    /// Il primo «uno» di battuta di Link non prima del battito: il multiplo del quantum; un battito su una battuta è quella.
    func testTheNextBarBeat() {
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 10.3, quantum: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 12.0, quantum: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 12.0000001, quantum: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 12.001, quantum: 4), 16)
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: 0.5, quantum: 3), 3)
        XCTAssertEqual(OutputReturnDecision.nextBarBeat(atOrAfter: -0.5, quantum: 4), 0)
        XCTAssertNil(OutputReturnDecision.nextBarBeat(atOrAfter: 10, quantum: 0))
        XCTAssertNil(OutputReturnDecision.nextBarBeat(atOrAfter: .nan, quantum: 4))
    }

    /// DA-SOLO: l'«uno» a battute dall'ultimo «uno» uscito; mai quello già uscito.
    func testTheNextOwnUno() {
        XCTAssertEqual(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 10.3, lastUnoBeat: 8, beatsPerBar: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 8.0, lastUnoBeat: 8, beatsPerBar: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 12.0, lastUnoBeat: 8, beatsPerBar: 4), 12)
        XCTAssertEqual(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 12.5, lastUnoBeat: 8, beatsPerBar: 4), 16)
        XCTAssertEqual(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 20.9, lastUnoBeat: 8, beatsPerBar: 3), 23)
        XCTAssertNil(OutputReturnDecision.nextOwnUnoBeat(atOrAfter: 10, lastUnoBeat: 8, beatsPerBar: 0))
    }

    /// L'ora di un battito sulla linea propria: l'inversa di `OwnClockTimeline.beat(atTicks:)`.
    func testOwnTicksAtBeatInvertsTheTimeline() {
        let timeline = OwnClockTimeline(anchorTicks: t(100.0), anchorBeat: 8, bpm: 120)
        let twelve = OutputReturnDecision.ownTicks(atBeat: 12, timeline: timeline, ticksPerSecond: tps)
        XCTAssertEqual(s(twelve!), 102.0, accuracy: 1e-6)
        XCTAssertEqual(timeline.beat(atTicks: twelve!, ticksPerSecond: tps), 12, accuracy: 1e-9)
        let before = OutputReturnDecision.ownTicks(atBeat: 7, timeline: timeline, ticksPerSecond: tps)
        XCTAssertEqual(s(before!), 99.5, accuracy: 1e-6)
        XCTAssertNil(OutputReturnDecision.ownTicks(atBeat: 12, timeline: OwnClockTimeline(anchorTicks: 0, anchorBeat: 0, bpm: 0),
                                                   ticksPerSecond: tps))
    }

    /// Il buffer che porta l'«uno»: la sua fine d'uscita è oltre l'«uno».
    func testTheBufferThatReachesTheUno() {
        let uno = t(100.5)
        XCTAssertFalse(OutputReturnDecision.bufferReachesUno(bufferOutputTicks: t(100.47), bufferTicks: t(buffer), unoTicks: uno))
        XCTAssertTrue(OutputReturnDecision.bufferReachesUno(bufferOutputTicks: t(100.49), bufferTicks: t(buffer), unoTicks: uno))
        XCTAssertTrue(OutputReturnDecision.bufferReachesUno(bufferOutputTicks: t(100.6), bufferTicks: t(buffer), unoTicks: uno))
        XCTAssertTrue(OutputReturnDecision.bufferReachesUno(bufferOutputTicks: UInt64.max, bufferTicks: 1, unoTicks: uno))
    }

    /// `ticks(_:plusSeconds:)`: avanti, indietro (si ferma a zero), ai bordi.
    func testTicksPlusSeconds() {
        XCTAssertEqual(OutputReturnDecision.ticks(t(100), plusSeconds: 0.5, ticksPerSecond: tps), t(100.5))
        XCTAssertEqual(OutputReturnDecision.ticks(t(100), plusSeconds: -0.5, ticksPerSecond: tps), t(99.5))
        XCTAssertEqual(OutputReturnDecision.ticks(t(1), plusSeconds: -5, ticksPerSecond: tps), 0)
        XCTAssertEqual(OutputReturnDecision.ticks(UInt64.max - 10, plusSeconds: 1, ticksPerSecond: tps), UInt64.max)
        XCTAssertEqual(OutputReturnDecision.ticks(t(100), plusSeconds: 1, ticksPerSecond: 0), t(100))
    }

    // MARK: - La rete del motore fermo (par. 2.2 a)

    func testTheStoppedEngineLineFirstThenEveryTen() {
        let written = (0...35).filter { OutputReturnDecision.writesStoppedEngineLine(callbacks: $0) }
        XCTAssertEqual(written, [1, 11, 21, 31])
    }

    // MARK: - A421 · SEGUITO 2 (par. 4.4, 5.1, 5.2, 5.5): il ritorno dopo il buco, la scadenza riletta, la finestra, il limite

    /// Par. 4.4: la fine dei buffer programmati alla chiamata dell'armo, riletta adesso e mai in discesa. Senza buchi dopo l'armo la
    /// rilettura dà la stessa ora (la fine di adesso meno i buffer programmati dall'armo); con un buco di 50 ms dopo l'armo il
    /// prossimo buffer da rendere è 50 ms più tardi e la fine sale di 50 ms; una lettura che darebbe meno non scende.
    func testTheProgrammedEndIsRereadAndNeverDecreases() {
        let armCall = 100.0
        let endAtArm = programmedEnd(firstCallAt: armCall)
        // Tre chiamate dopo, senza buchi: il prossimo buffer da rendere è tre buffer più tardi.
        let same = OutputReturnDecision.rereadProgrammedEndTicks(previous: endAtArm, nextBufferOutputTicks: t(armCall + 3 * buffer + buffer + latency),
                                                                  queuedAhead: 2, bufferTicks: t(buffer), buffersSinceArm: 3)
        XCTAssertEqual(s(same), s(endAtArm), accuracy: 1e-6)
        // Un buco di 50 ms fra la chiamata dell'armo e la terza dopo: la fine sale di 50 ms.
        let moved = OutputReturnDecision.rereadProgrammedEndTicks(previous: endAtArm,
                                                                   nextBufferOutputTicks: t(armCall + 3 * buffer + 0.050 + buffer + latency),
                                                                   queuedAhead: 2, bufferTicks: t(buffer), buffersSinceArm: 3)
        XCTAssertEqual(s(moved), s(endAtArm) + 0.050, accuracy: 1e-6)
        // Una lettura che darebbe meno (un richiamo in anticipo, la lettura di riserva): non scende.
        let lower = OutputReturnDecision.rereadProgrammedEndTicks(previous: moved, nextBufferOutputTicks: t(armCall + 3 * buffer + latency),
                                                                   queuedAhead: 2, bufferTicks: t(buffer), buffersSinceArm: 3)
        XCTAssertEqual(lower, moved)
        // Ai bordi: più buffer dall'armo di quanti ne copra la lettura (zero), e un conto negativo (zero buffer).
        XCTAssertEqual(OutputReturnDecision.rereadProgrammedEndTicks(previous: 0, nextBufferOutputTicks: t(0.001), queuedAhead: 2,
                                                                      bufferTicks: t(buffer), buffersSinceArm: 1000), 0)
        XCTAssertEqual(OutputReturnDecision.rereadProgrammedEndTicks(previous: 0, nextBufferOutputTicks: t(100), queuedAhead: 2,
                                                                      bufferTicks: t(buffer), buffersSinceArm: -5),
                       OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: t(100), queuedAhead: 2, bufferTicks: t(buffer)))
        // La scadenza del ritorno dopo il buco: la fine più la coda del click.
        XCTAssertEqual(s(OutputReturnDecision.gapReturnDeadlineTicks(programmedEndOutputTicks: endAtArm, ticksPerSecond: tps)),
                       s(endAtArm) + 0.040, accuracy: 1e-6)
    }

    /// Par. 4.4: la chiamata col ritorno dopo il buco: il volume torna al primo campione alla scadenza o dopo, senza l'«uno»; mai in
    /// una chiamata che salta la correzione; con l'esterna sparita si aspetta.
    func testTheGapReturnStep() {
        let deadline = t(100.3)
        XCTAssertEqual(OutputReturnDecision.gapReturnStep(firstSampleTicks: t(100.29), deadlineTicks: deadline, skipsCorrection: false,
                                                          externalVanished: false), .wait)
        XCTAssertEqual(OutputReturnDecision.gapReturnStep(firstSampleTicks: deadline, deadlineTicks: deadline, skipsCorrection: false,
                                                          externalVanished: false), .restore)
        XCTAssertEqual(OutputReturnDecision.gapReturnStep(firstSampleTicks: t(100.4), deadlineTicks: deadline, skipsCorrection: false,
                                                          externalVanished: false), .restore)
        XCTAssertEqual(OutputReturnDecision.gapReturnStep(firstSampleTicks: t(100.4), deadlineTicks: deadline, skipsCorrection: true,
                                                          externalVanished: false), .wait, "la finestra sync skip")
        XCTAssertEqual(OutputReturnDecision.gapReturnStep(firstSampleTicks: t(100.4), deadlineTicks: deadline, skipsCorrection: false,
                                                          externalVanished: true), .externalVanished)
        XCTAssertEqual(OutputReturnDecision.gapReturnStep(firstSampleTicks: t(100.2), deadlineTicks: deadline, skipsCorrection: false,
                                                          externalVanished: true), .wait, "prima della scadenza non si legge l'uscita")
    }

    /// Par. 5.1 (F1): in una chiamata che salta la correzione il ritorno del Follower non rimette il volume: con l'«uno» raggiunto la
    /// battuta dopo (`nextBarInWindow`), senza «uno» si aspetta anche dopo la scadenza.
    func testTheWindowBlocksTheFollowerReturn() {
        let deadline = t(100.3)
        let uno = t(100.5)
        XCTAssertEqual(OutputReturnDecision.followerReturnStep(bufferOutputTicks: t(100.49), bufferTicks: t(buffer), unoTicks: uno,
                                                               deadlineTicks: deadline, firstSampleTicks: t(100.45), skipsCorrection: true),
                       .nextBarInWindow)
        XCTAssertEqual(OutputReturnDecision.followerReturnStep(bufferOutputTicks: t(100.4), bufferTicks: t(buffer), unoTicks: uno,
                                                               deadlineTicks: deadline, firstSampleTicks: t(100.45), skipsCorrection: true),
                       .wait, "il buffer non porta l'uno")
        XCTAssertEqual(OutputReturnDecision.followerReturnStep(bufferOutputTicks: t(100.49), bufferTicks: t(buffer), unoTicks: nil,
                                                               deadlineTicks: deadline, firstSampleTicks: t(100.45), skipsCorrection: true),
                       .wait, "senza uno si aspetta")
        XCTAssertEqual(OutputReturnDecision.followerReturnStep(bufferOutputTicks: t(100.49), bufferTicks: t(buffer), unoTicks: uno,
                                                               deadlineTicks: deadline, firstSampleTicks: t(100.45), skipsCorrection: false),
                       .restore, "senza la finestra, come prima")
    }

    /// Par. 5.1 (F1): la prima correzione dopo la finestra sposta di almeno un buffer, a meno di un intero di battiti. A 121 BPM un
    /// buffer è 0,0215 battiti: 0,03 sposta, 0,01 no; a un cambio di metro il battito cambia solo nome (4,01: la distanza
    /// dall'intero è 0,01: no); 3,97 è 0,03 dall'intero: sì.
    func testTheFirstCorrectionAfterTheWindow() {
        let bpm = 121.0
        XCTAssertTrue(OutputReturnDecision.correctionMovesAtLeastABuffer(beforeBeat: 10.0, afterBeat: 10.03, bpm: bpm, bufferSeconds: buffer))
        XCTAssertFalse(OutputReturnDecision.correctionMovesAtLeastABuffer(beforeBeat: 10.0, afterBeat: 10.01, bpm: bpm, bufferSeconds: buffer))
        XCTAssertFalse(OutputReturnDecision.correctionMovesAtLeastABuffer(beforeBeat: 10.0, afterBeat: 14.01, bpm: bpm, bufferSeconds: buffer),
                       "un cambio di metro: il battito cambia solo nome")
        XCTAssertTrue(OutputReturnDecision.correctionMovesAtLeastABuffer(beforeBeat: 10.0, afterBeat: 13.97, bpm: bpm, bufferSeconds: buffer))
        XCTAssertTrue(OutputReturnDecision.correctionMovesAtLeastABuffer(beforeBeat: 10.0, afterBeat: 9.97, bpm: bpm, bufferSeconds: buffer),
                      "anche all'indietro")
        XCTAssertFalse(OutputReturnDecision.correctionMovesAtLeastABuffer(beforeBeat: 10.0, afterBeat: 10.0, bpm: bpm, bufferSeconds: buffer))
        XCTAssertFalse(OutputReturnDecision.correctionMovesAtLeastABuffer(beforeBeat: .nan, afterBeat: 10.0, bpm: bpm, bufferSeconds: buffer))
        XCTAssertFalse(OutputReturnDecision.correctionMovesAtLeastABuffer(beforeBeat: 10.0, afterBeat: 10.5, bpm: 0, bufferSeconds: buffer))
        // Il 29/10: la prima correzione dopo il buco di 70 ms, 0,1883 battiti: sposta.
        XCTAssertTrue(OutputReturnDecision.correctionMovesAtLeastABuffer(beforeBeat: 54.1435, afterBeat: 54.3318, bpm: bpm, bufferSeconds: buffer))
    }

    /// Par. 5.2 (E.1): il limite di una battuta dopo la scadenza senza un «uno» calcolabile.
    func testTheNoUnoLimit() {
        let deadline = t(100.3)
        let bar = t(4 * 60.0 / 121.0)
        XCTAssertFalse(OutputReturnDecision.noUnoLimitReached(nowTicks: t(100.3), deadlineTicks: deadline, barTicks: bar))
        XCTAssertFalse(OutputReturnDecision.noUnoLimitReached(nowTicks: deadline + bar - 1, deadlineTicks: deadline, barTicks: bar))
        XCTAssertTrue(OutputReturnDecision.noUnoLimitReached(nowTicks: deadline + bar, deadlineTicks: deadline, barTicks: bar))
        XCTAssertFalse(OutputReturnDecision.noUnoLimitReached(nowTicks: UInt64.max, deadlineTicks: UInt64.max - 1, barTicks: 10))
    }

    func testTheGapReturnNames() {
        XCTAssertEqual(GapReturnStep.wait, .wait)
        XCTAssertNotEqual(GapReturnStep.restore, GapReturnStep.externalVanished)
        XCTAssertNotEqual(FollowerReturnStep.nextBarInWindow, FollowerReturnStep.wait)
    }
}
