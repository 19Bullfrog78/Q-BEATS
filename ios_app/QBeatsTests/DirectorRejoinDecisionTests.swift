import XCTest

// === A410 — banco della decisione del rientro del Direttore (`DirectorRejoinDecision`, banco Models) ===
// Mandato A410, §3: la matrice del referto A409 §8.4 (ruolo × show × àncora × ponte × suona ×
// stesso avvio × righelli × esito del conteggio × finestra); «non certo» non dà mai un ingresso né
// uno Stop; il Solo e il Follower mai nel coordinatore. Più i casi del bersaglio scritti per esteso:
// margine, finestra del cambio di sezione (anche a battute corte), canzone che finisce prima,
// canzone già finita, ciclo; la regola dell'àncora; il giudice «stesso avvio».
// La canzone è «Test Song A» di L1.b (`DebugView.loadTestDataL1b`): Intro 100 4/4 × 12, Verse 120
// 4/4 × 3, Bridge 140 3/4 × 2. L'àncora è al battito 40 dell'Intro (battuta 11, battito 1), sul
// battito di Link 1000, a 100 s. La finestra è quella del motore: 100 buffer da 512 a 48 kHz.
// Gli attesi sono scritti dai numeri della canzone, non ricavati dal tipo.

final class DirectorRejoinDecisionTests: XCTestCase {

    private typealias Decision = DirectorRejoinDecision

    private let tps = 24_000_000.0
    private let anchorTicks: UInt64 = 100 * 24_000_000
    /// 100 buffer da 512 campioni a 48 kHz: 1,0666… s.
    private let window = 100.0 * 512.0 / 48_000.0

    private let songA = SongMap(sections: [
        SongMapSection(beatsPerBar: 4, repetitions: 12, bpm: 100),
        SongMapSection(beatsPerBar: 4, repetitions: 3, bpm: 120),
        SongMapSection(beatsPerBar: 3, repetitions: 2, bpm: 140),
    ])

    private var clockA: ShowClock {
        ShowClock(map: songA, anchor: ShowClockAnchor(section: 0, beatInSection: 40, linkBeat: 1000, ticks: anchorTicks))
    }

    /// Due battute di 4/4 e poi un ciclo; àncora al battito 4, sul battito di Link 0.
    private var clockWithCycle: ShowClock {
        let map = SongMap(sections: [
            SongMapSection(beatsPerBar: 4, repetitions: 2, bpm: 100),
            SongMapSection(beatsPerBar: 4, repetitions: -1, bpm: 100),
        ])
        return ShowClock(map: map, anchor: ShowClockAnchor(section: 0, beatInSection: 4, linkBeat: 0, ticks: anchorTicks))
    }

    private func ticks(afterAnchor seconds: Double) -> UInt64 {
        anchorTicks + UInt64((seconds * tps).rounded())
    }

    private func situation(role: LinkMode = .direttore,
                           userLink: Bool = true,
                           show: Bool = true,
                           link: Bool = true,
                           playing: Bool = true,
                           same: Bool = true,
                           nowLinkBeat: Double,
                           afterAnchor seconds: Double,
                           tempo: Double = 100,
                           margin: Double = 0.150,
                           window: Double? = nil) -> Decision.Situation {
        Decision.Situation(role: role, userLinkEnabled: userLink, showOpen: show,
                           linkEnabled: link, sessionPlaying: playing, sameStart: same,
                           nowLinkBeat: nowLinkBeat, nowTicks: ticks(afterAnchor: seconds),
                           ticksPerSecond: tps, sessionTempo: tempo,
                           marginSeconds: margin, windowSeconds: window ?? self.window)
    }

    // MARK: - Il bersaglio, scritto per esteso

    /// Battuta 11, battito 2,5 dell'Intro (1,5 battiti dopo l'àncora, 0,9 s). Margine 150 ms a 100 =
    /// 0,25 battiti: il primo «uno» da Link 1001,75 in poi è il battito 44 = battuta 12, Link 1004,
    /// a 26,4 s dall'inizio dell'Intro (fuori dalla finestra).
    func testRejoinInsideTheIntro() {
        let plan = Decision.plan(clock: clockA, situation: situation(nowLinkBeat: 1001.5, afterAnchor: 0.9))
        XCTAssertEqual(plan.outcome, .rejoin(section: 0, bar: 12, linkBeat: 1004))
        XCTAssertEqual(plan.windowShifts, 0)
        XCTAssertEqual(plan.reading?.certain, true)
    }

    /// Battuta 12, battito 3,5 dell'Intro (6,5 battiti dopo, 3,9 s). Il primo «uno» utile è l'inizio
    /// del Verse (Link 1008): cade nella finestra del cambio di sezione, si entra alla battuta dopo,
    /// Verse battuta 2 (Link 1012, a 2,0 s dall'inizio del Verse). Senza finestra: Verse battuta 1.
    func testTheSectionChangeWindowMovesTheTargetOneBar() {
        let withWindow = Decision.plan(clock: clockA, situation: situation(nowLinkBeat: 1006.5, afterAnchor: 3.9))
        XCTAssertEqual(withWindow.outcome, .rejoin(section: 1, bar: 2, linkBeat: 1012))
        XCTAssertEqual(withWindow.windowShifts, 1)
        let noWindow = Decision.plan(clock: clockA, situation: situation(nowLinkBeat: 1006.5, afterAnchor: 3.9, window: 0))
        XCTAssertEqual(noWindow.outcome, .rejoin(section: 1, bar: 1, linkBeat: 1008))
        XCTAssertEqual(noWindow.windowShifts, 0)
    }

    /// Battute corte: 2/4 a 200 (0,6 s a battuta). L'«uno» d'ingresso del 2/4 e quello della sua
    /// battuta 2 (0,6 s) stanno nella finestra; la battuta 3 (1,2 s) no: due spostamenti.
    func testShortBarsMoveTheTargetMoreThanOnce() {
        let map = SongMap(sections: [
            SongMapSection(beatsPerBar: 4, repetitions: 2, bpm: 100),
            SongMapSection(beatsPerBar: 2, repetitions: 8, bpm: 200),
        ])
        let clock = ShowClock(map: map, anchor: ShowClockAnchor(section: 0, beatInSection: 4, linkBeat: 0, ticks: anchorTicks))
        let plan = Decision.plan(clock: clock, situation: situation(nowLinkBeat: 3.5, afterAnchor: 2.1))
        XCTAssertEqual(plan.outcome, .rejoin(section: 1, bar: 3, linkBeat: 8))
        XCTAssertEqual(plan.windowShifts, 2)
    }

    /// Battuta 11, battito 4,9 (3,9 battiti dopo, 2,34 s): l'«uno» della battuta 12 è a 0,1 battiti
    /// (60 ms), dentro il margine di 150 ms: si salta all'inizio del Verse, e la finestra porta alla
    /// battuta 2 del Verse. Senza margine si entra alla battuta 12.
    func testTheMarginSkipsADownbeatTooClose() {
        let withMargin = Decision.plan(clock: clockA, situation: situation(nowLinkBeat: 1003.9, afterAnchor: 2.34))
        XCTAssertEqual(withMargin.outcome, .rejoin(section: 1, bar: 2, linkBeat: 1012))
        let noMargin = Decision.plan(clock: clockA, situation: situation(nowLinkBeat: 1003.9, afterAnchor: 2.34, margin: 0))
        XCTAssertEqual(noMargin.outcome, .rejoin(section: 0, bar: 12, linkBeat: 1004))
    }

    /// Un tempo di sessione non valido: il margine si conta col tempo della mappa (100 nell'Intro).
    func testAnInvalidSessionTempoUsesTheMapTempo() {
        for tempo in [0.0, -1.0, Double.nan] {
            let plan = Decision.plan(clock: clockA, situation: situation(nowLinkBeat: 1001.5, afterAnchor: 0.9, tempo: tempo))
            XCTAssertEqual(plan.outcome, .rejoin(section: 0, bar: 12, linkBeat: 1004), "tempo:\(tempo)")
        }
    }

    /// Bridge battuta 2, battito 2,5 (24,5 battiti dopo): margine 150 ms a 140 = 0,35 battiti, e
    /// nessun «uno» prima della fine (Link 1026): la canzone finisce prima. Già oltre la fine: finita.
    func testTheSongEnds() {
        let before = Decision.plan(clock: clockA,
                                   situation: situation(nowLinkBeat: 1024.5,
                                                        afterAnchor: 4.8 + 6.0 + 4.5 * 60.0 / 140.0,
                                                        tempo: 140))
        XCTAssertEqual(before.outcome, .songEnded(endLinkBeat: 1026, alreadyOver: false))
        let over = Decision.plan(clock: clockA,
                                 situation: situation(nowLinkBeat: 1030,
                                                      afterAnchor: 4.8 + 6.0 + 6.0 * 60.0 / 140.0 + 4.0 * 60.0 / 140.0,
                                                      tempo: 140))
        XCTAssertEqual(over.outcome, .songEnded(endLinkBeat: 1026, alreadyOver: true))
    }

    /// I righelli in disaccordo: «non certo», mai un ingresso e mai la fine (D4 = (a)).
    func testRulersDisagreeIsUncertain() {
        let inside = Decision.plan(clock: clockA, situation: situation(nowLinkBeat: 1001.5, afterAnchor: 3.0))
        XCTAssertEqual(inside.outcome, .uncertain(.rulersDisagree))
        XCTAssertEqual(inside.reading?.gapBeats ?? 0, -3.5, accuracy: 1e-6)
        let atEnd = Decision.plan(clock: clockA, situation: situation(nowLinkBeat: 1030, afterAnchor: 10, tempo: 140))
        XCTAssertEqual(atEnd.outcome, .uncertain(.rulersDisagree))
    }

    func testCycleIsUncertain() {
        let plan = Decision.plan(clock: clockWithCycle, situation: situation(nowLinkBeat: 5, afterAnchor: 3.0))
        XCTAssertEqual(plan.outcome, .uncertain(.clock(.cycle)))
        let anchoredInCycle = ShowClock(map: clockWithCycle.map,
                                        anchor: ShowClockAnchor(section: 1, beatInSection: 0, linkBeat: 0, ticks: anchorTicks))
        XCTAssertEqual(Decision.plan(clock: anchoredInCycle, situation: situation(nowLinkBeat: 1, afterAnchor: 0.6)).outcome,
                       .uncertain(.clock(.cycle)))
    }

    /// Una finestra che non si chiude mai (enorme) su una canzone lunga: oltre 1024 spostamenti il
    /// bersaglio non si trova.
    func testAWindowThatNeverClearsGivesNoTarget() {
        let long = SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 4000, bpm: 100)])
        let clock = ShowClock(map: long, anchor: ShowClockAnchor(section: 0, beatInSection: 0, linkBeat: 0, ticks: anchorTicks))
        let plan = Decision.plan(clock: clock, situation: situation(nowLinkBeat: 0.5, afterAnchor: 0.3, window: 1e9))
        XCTAssertEqual(plan.outcome, .uncertain(.noTarget))
        XCTAssertEqual(plan.windowShifts, Decision.maxWindowShifts + 1)
    }

    // MARK: - La precedenza, caso per caso

    func testSessionStoppedElsewhere() {
        let plan = Decision.plan(clock: clockA, situation: situation(playing: false, nowLinkBeat: 1001.5, afterAnchor: 0.9))
        XCTAssertEqual(plan.outcome, .sessionStoppedElsewhere)
        XCTAssertNil(plan.reading)
    }

    func testStartChangedIsUncertain() {
        XCTAssertEqual(Decision.plan(clock: clockA, situation: situation(same: false, nowLinkBeat: 1001.5, afterAnchor: 0.9)).outcome,
                       .uncertain(.startChanged))
    }

    func testLinkOffIsUncertain() {
        XCTAssertEqual(Decision.plan(clock: clockA, situation: situation(link: false, nowLinkBeat: 1001.5, afterAnchor: 0.9)).outcome,
                       .uncertain(.linkOff))
    }

    func testNoAnchorAndShowClosedAreNotCoordinated() {
        XCTAssertEqual(Decision.plan(clock: nil, situation: situation(nowLinkBeat: 1001.5, afterAnchor: 0.9)).outcome,
                       .notCoordinated(.noAnchor))
        XCTAssertEqual(Decision.plan(clock: clockA, situation: situation(show: false, nowLinkBeat: 1001.5, afterAnchor: 0.9)).outcome,
                       .notCoordinated(.showClosed))
    }

    /// Il Solo e il Follower mai nel coordinatore; il ruolo Direttore con Link spento dall'utente
    /// è un Solo (la regola di `DirectorSongCloseDecision.closesSongOnStop`).
    func testSoloAndFollowerNeverEnterTheCoordinator() {
        let cases: [(LinkMode, Bool)] = [(.standalone, false), (.standalone, true),
                                         (.collaborativa, false), (.collaborativa, true),
                                         (.direttore, false)]
        for (role, userLink) in cases {
            let plan = Decision.plan(clock: clockA,
                                     situation: situation(role: role, userLink: userLink, nowLinkBeat: 1001.5, afterAnchor: 0.9))
            XCTAssertEqual(plan.outcome, .notCoordinated(.notDirector), "ruolo:\(role) linkUtente:\(userLink)")
            XCTAssertNil(plan.reading)
        }
    }

    // MARK: - La matrice del referto A409 §8.4

    private enum Count: CaseIterable {
        case inSongCertain, inSongDisagree, endedCertain, endedDisagree, cycle
    }

    /// Il conteggio di ogni colonna: l'orologio e adesso (battito di Link, secondi dall'àncora, tempo).
    private func count(_ kind: Count) -> (clock: ShowClock, linkBeat: Double, seconds: Double, tempo: Double) {
        switch kind {
        case .inSongCertain:  return (clockA, 1006.5, 3.9, 100)
        case .inSongDisagree: return (clockA, 1001.5, 3.0, 100)
        case .endedCertain:   return (clockA, 1030, 4.8 + 6.0 + 10.0 * 60.0 / 140.0, 140)
        case .endedDisagree:  return (clockA, 1030, 10, 140)
        case .cycle:          return (clockWithCycle, 5, 3.0, 100)
        }
    }

    /// L'atteso di una cella, dalla precedenza della regola (mandato A410 §2.5; referto A409 §8.4):
    /// fuori dal coordinatore → ponte spento → sessione ferma → avvio cambiato → conto (non so,
    /// righelli) → fine → bersaglio.
    private func expected(role: LinkMode, userLink: Bool, show: Bool, anchored: Bool, link: Bool,
                          playing: Bool, same: Bool, kind: Count, windowOn: Bool) -> Decision.Outcome {
        guard role == .direttore && userLink else { return .notCoordinated(.notDirector) }
        guard show else { return .notCoordinated(.showClosed) }
        guard anchored else { return .notCoordinated(.noAnchor) }
        guard link else { return .uncertain(.linkOff) }
        guard playing else { return .sessionStoppedElsewhere }
        guard same else { return .uncertain(.startChanged) }
        switch kind {
        case .inSongCertain:
            return windowOn ? .rejoin(section: 1, bar: 2, linkBeat: 1012) : .rejoin(section: 1, bar: 1, linkBeat: 1008)
        case .inSongDisagree, .endedDisagree:
            return .uncertain(.rulersDisagree)
        case .endedCertain:
            return .songEnded(endLinkBeat: 1026, alreadyOver: true)
        case .cycle:
            return .uncertain(.clock(.cycle))
        }
    }

    func testTheMatrix() {
        var cells = 0
        for role in [LinkMode.standalone, .collaborativa, .direttore] {
            for userLink in [false, true] {
                for show in [false, true] {
                    for anchored in [false, true] {
                        for link in [false, true] {
                            for playing in [false, true] {
                                for same in [false, true] {
                                    for kind in Count.allCases {
                                        for windowOn in [false, true] {
                                            cells += 1
                                            let c = count(kind)
                                            let s = situation(role: role, userLink: userLink, show: show,
                                                              link: link, playing: playing, same: same,
                                                              nowLinkBeat: c.linkBeat, afterAnchor: c.seconds,
                                                              tempo: c.tempo, window: windowOn ? window : 0)
                                            let plan = Decision.plan(clock: anchored ? c.clock : nil, situation: s)
                                            let want = expected(role: role, userLink: userLink, show: show,
                                                                anchored: anchored, link: link, playing: playing,
                                                                same: same, kind: kind, windowOn: windowOn)
                                            let tag = "ruolo:\(role) linkUtente:\(userLink) show:\(show) ancora:\(anchored) link:\(link) suona:\(playing) stessoAvvio:\(same) conto:\(kind) finestra:\(windowOn)"
                                            XCTAssertEqual(plan.outcome, want, tag)
                                            // «Non certo» non dà mai un ingresso né uno Stop.
                                            if case .uncertain = plan.outcome {
                                                XCTAssertFalse(plan.outcome.wouldStartEngine, tag)
                                                XCTAssertFalse(plan.outcome.wouldSendStop, tag)
                                            }
                                            // Righelli non in accordo: mai un ingresso, mai la fine.
                                            if let reading = plan.reading, !reading.certain {
                                                XCTAssertFalse(plan.outcome.wouldStartEngine, tag)
                                                XCTAssertFalse(plan.outcome.wouldSendStop, tag)
                                            }
                                            // Il Solo e il Follower mai nel coordinatore.
                                            if !(role == .direttore && userLink) {
                                                XCTAssertEqual(plan.outcome, .notCoordinated(.notDirector), tag)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 3 * 2 * 2 * 2 * 2 * 2 * 2 * 5 * 2)
    }

    // MARK: - Che cosa farebbe ogni esito

    func testOnlyRejoinStartsAndOnlySongEndedStops() {
        let outcomes: [Decision.Outcome] = [
            .notCoordinated(.notDirector), .notCoordinated(.showClosed), .notCoordinated(.noAnchor),
            .rejoin(section: 0, bar: 1, linkBeat: 0),
            .songEnded(endLinkBeat: 0, alreadyOver: true), .songEnded(endLinkBeat: 0, alreadyOver: false),
            .uncertain(.linkOff), .uncertain(.startChanged), .uncertain(.clock(.cycle)),
            .uncertain(.rulersDisagree), .uncertain(.noTarget),
            .sessionStoppedElsewhere,
        ]
        for outcome in outcomes {
            switch outcome {
            case .rejoin:
                XCTAssertTrue(outcome.wouldStartEngine)
                XCTAssertFalse(outcome.wouldSendStop)
            case .songEnded:
                XCTAssertFalse(outcome.wouldStartEngine)
                XCTAssertTrue(outcome.wouldSendStop)
            default:
                XCTAssertFalse(outcome.wouldStartEngine, "\(outcome)")
                XCTAssertFalse(outcome.wouldSendStop, "\(outcome)")
            }
        }
    }

    // MARK: - La regola dell'àncora

    /// L'àncora si prende solo col Direttore (ruolo Direttore e Link acceso dall'utente), a show
    /// aperto, col motore in moto e la mappa della canzone: una combinazione su 48.
    func testTheAnchorRule() {
        var taken = 0
        var cells = 0
        for role in [LinkMode.standalone, .collaborativa, .direttore] {
            for userLink in [false, true] {
                for show in [false, true] {
                    for running in [false, true] {
                        for map in [false, true] {
                            cells += 1
                            let takes = Decision.takesAnchor(role: role, userLinkEnabled: userLink, showOpen: show,
                                                             engineRunning: running, hasSongMap: map)
                            if takes { taken += 1 }
                            XCTAssertEqual(takes, role == .direttore && userLink && show && running && map,
                                           "ruolo:\(role) linkUtente:\(userLink) show:\(show) motore:\(running) mappa:\(map)")
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 48)
        XCTAssertEqual(taken, 1)
    }

    // MARK: - Il giudice «stesso avvio»

    func testSameStartInBeats() {
        XCTAssertTrue(Decision.sameStart(anchorStartBeat: 3369.038608, nowStartBeat: 3369.038608))
        XCTAssertTrue(Decision.sameStart(anchorStartBeat: 100, nowStartBeat: 100.125))
        XCTAssertTrue(Decision.sameStart(anchorStartBeat: 100, nowStartBeat: 99.875))
        XCTAssertFalse(Decision.sameStart(anchorStartBeat: 100, nowStartBeat: 100.126))
        XCTAssertFalse(Decision.sameStart(anchorStartBeat: 100, nowStartBeat: 99.874))
        XCTAssertFalse(Decision.sameStart(anchorStartBeat: 100, nowStartBeat: 101))
        XCTAssertFalse(Decision.sameStart(anchorStartBeat: .nan, nowStartBeat: 100))
        XCTAssertFalse(Decision.sameStart(anchorStartBeat: 100, nowStartBeat: .infinity))
        XCTAssertFalse(Decision.sameStart(anchorStartBeat: 100, nowStartBeat: 100, toleranceBeats: -1))
        XCTAssertTrue(Decision.sameStart(anchorStartBeat: 100, nowStartBeat: 100.4, toleranceBeats: 0.5))
        XCTAssertEqual(Decision.sameStartToleranceBeats, 0.125)
    }
}
