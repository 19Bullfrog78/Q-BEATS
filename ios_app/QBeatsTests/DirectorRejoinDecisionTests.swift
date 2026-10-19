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

    // MARK: - A412 — il coordinatore che agisce (mandato «DIRETTORE-IN-CRISI-PASSO-2», §2.2 e §2.3)

    /// Il Direttore muto in canzone senza àncora (A410: «ancora non presa») è non certo: resta muto,
    /// nessun ingresso e nessuno Stop. Show chiuso, Solo e Follower restano fuori dal coordinatore.
    func testCoordinateWithoutAnAnchorIsUncertain() {
        let plan = Decision.coordinate(clock: nil, situation: situation(nowLinkBeat: 1001.5, afterAnchor: 0.9))
        XCTAssertEqual(plan.outcome, .uncertain(.noAnchor))
        XCTAssertNil(plan.reading)
        XCTAssertFalse(plan.outcome.wouldStartEngine)
        XCTAssertFalse(plan.outcome.wouldSendStop)
        XCTAssertEqual(Decision.coordinate(clock: nil, situation: situation(show: false, nowLinkBeat: 1001.5, afterAnchor: 0.9)).outcome,
                       .notCoordinated(.showClosed))
        XCTAssertEqual(Decision.coordinate(clock: nil, situation: situation(role: .standalone, nowLinkBeat: 1001.5, afterAnchor: 0.9)).outcome,
                       .notCoordinated(.notDirector))
        XCTAssertEqual(Decision.coordinate(clock: nil, situation: situation(role: .direttore, userLink: false, nowLinkBeat: 1001.5, afterAnchor: 0.9)).outcome,
                       .notCoordinated(.notDirector))
    }

    /// Con l'àncora il coordinatore è la decisione di A410, per ogni conteggio e ogni ingresso.
    func testCoordinateWithAnAnchorIsThePlan() {
        var cells = 0
        for kind in Count.allCases {
            for link in [false, true] {
                for playing in [false, true] {
                    for same in [false, true] {
                        for windowOn in [false, true] {
                            cells += 1
                            let c = count(kind)
                            let s = situation(link: link, playing: playing, same: same,
                                              nowLinkBeat: c.linkBeat, afterAnchor: c.seconds,
                                              tempo: c.tempo, window: windowOn ? window : 0)
                            XCTAssertEqual(Decision.coordinate(clock: c.clock, situation: s), Decision.plan(clock: c.clock, situation: s),
                                           "conto:\(kind) link:\(link) suona:\(playing) stessoAvvio:\(same) finestra:\(windowOn)")
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 5 * 2 * 2 * 2 * 2)
    }

    /// La prova P4 del collaudo A410: decisione nell'Intro a 100, bersaglio Verse battuta 2 a 120. L'ora del
    /// ponte alla decisione (tempo costante 100: Link 1012 è 12 battiti × 0,6 s = 7,2 s dopo l'àncora) sta
    /// 0,40 s dopo quella della mappa (8 battiti a 100 = 4,8 s, più 4 a 120 = 2,0 s: 6,8 s): −0,8 battiti a
    /// 120, il controllo non passa. All'armamento, passato il confine, il ponte vede il 120 (Link 1008 a
    /// 4,8 s, 1012 a 6,8 s): scarto zero, il controllo passa.
    func testTheBridgeAtTheDecisionIgnoresTheTempoChangeAndTheArmingCatchesIt() {
        let map = clockA.ticks(section: 1, beatInSection: 4, ticksPerSecond: tps)
        XCTAssertEqual(Double(map ?? 0), Double(anchorTicks) + 6.8 * tps, accuracy: 1.0)
        let atDecision = Decision.armingCheck(mapTicks: map, bridgeTicks: anchorTicks + 172_800_000,
                                              sectionBPM: 120, ticksPerSecond: tps)
        XCTAssertEqual(atDecision.gapSeconds ?? 0, -0.4, accuracy: 1e-6)
        XCTAssertEqual(atDecision.gapBeats ?? 0, -0.8, accuracy: 1e-6)
        XCTAssertFalse(atDecision.agree)
        let atArming = Decision.armingCheck(mapTicks: map, bridgeTicks: anchorTicks + 163_200_000,
                                            sectionBPM: 120, ticksPerSecond: tps)
        XCTAssertEqual(atArming.gapSeconds ?? 99, 0, accuracy: 1e-6)
        XCTAssertTrue(atArming.agree)
    }

    /// Il controllo all'armamento: 1/8 di battito al tempo della sezione d'arrivo, compreso; oltre no. Senza
    /// l'ora del ponte (0, ponte spento) o della mappa, o con valori non validi, non passa.
    func testTheArmingCheckTolerance() {
        let map: UInt64 = anchorTicks + 163_200_000
        // 0,05 s a 120 = 0,1 battiti: passa, nei due versi.
        XCTAssertTrue(Decision.armingCheck(mapTicks: map, bridgeTicks: map + 1_200_000, sectionBPM: 120, ticksPerSecond: tps).agree)
        XCTAssertTrue(Decision.armingCheck(mapTicks: map, bridgeTicks: map - 1_200_000, sectionBPM: 120, ticksPerSecond: tps).agree)
        // 0,0625 s a 120 = 0,125 battiti: il bordo, passa.
        let edge = Decision.armingCheck(mapTicks: map, bridgeTicks: map + 1_500_000, sectionBPM: 120, ticksPerSecond: tps)
        XCTAssertEqual(edge.gapBeats ?? 0, -0.125, accuracy: 1e-12)
        XCTAssertTrue(edge.agree)
        // 0,07 s a 120 = 0,14 battiti: non passa, nei due versi.
        XCTAssertFalse(Decision.armingCheck(mapTicks: map, bridgeTicks: map + 1_680_000, sectionBPM: 120, ticksPerSecond: tps).agree)
        XCTAssertFalse(Decision.armingCheck(mapTicks: map, bridgeTicks: map - 1_680_000, sectionBPM: 120, ticksPerSecond: tps).agree)
        // Lo stesso scarto in secondi pesa di più a un tempo più veloce: 0,05 s a 160 = 0,1333 battiti.
        XCTAssertFalse(Decision.armingCheck(mapTicks: map, bridgeTicks: map + 1_200_000, sectionBPM: 160, ticksPerSecond: tps).agree)
        // Mancanze e valori non validi.
        let noBridge = Decision.armingCheck(mapTicks: map, bridgeTicks: 0, sectionBPM: 120, ticksPerSecond: tps)
        XCTAssertNil(noBridge.gapSeconds)
        XCTAssertFalse(noBridge.agree)
        XCTAssertFalse(Decision.armingCheck(mapTicks: nil, bridgeTicks: map, sectionBPM: 120, ticksPerSecond: tps).agree)
        let badTempo = Decision.armingCheck(mapTicks: map, bridgeTicks: map, sectionBPM: 0, ticksPerSecond: tps)
        XCTAssertEqual(badTempo.gapSeconds, 0)
        XCTAssertNil(badTempo.gapBeats)
        XCTAssertFalse(badTempo.agree)
        XCTAssertFalse(Decision.armingCheck(mapTicks: map, bridgeTicks: map, sectionBPM: 120, ticksPerSecond: 0).agree)
    }

    /// Il primo buffer comincia all'ora d'uscita del bersaglio meno la latenza d'uscita; l'armamento sta un
    /// margine prima del bersaglio (qui 125 ms, esatti in tick); il blocco è in ritardo se adesso più
    /// l'anticipo minimo supera l'ora chiesta.
    func testTheFirstBufferTheArmingAndTheLateness() {
        let target: UInt64 = anchorTicks + 163_200_000
        XCTAssertEqual(Decision.firstBufferRenderTicks(targetOutputTicks: target, outputLatencyTicks: 240_000), target - 240_000)
        XCTAssertEqual(Decision.firstBufferRenderTicks(targetOutputTicks: 100, outputLatencyTicks: 240_000), 0)
        XCTAssertEqual(Decision.armingTicks(targetOutputTicks: target, marginSeconds: 0.125, ticksPerSecond: tps), target - 3_000_000)
        XCTAssertEqual(Decision.armingTicks(targetOutputTicks: target, marginSeconds: -1, ticksPerSecond: tps), target)
        let render = target - 240_000
        let lead: UInt64 = 720_000   // 30 ms
        XCTAssertFalse(Decision.isLate(nowTicks: render - lead, renderTicks: render, minLeadTicks: lead), "esatto: in tempo")
        XCTAssertTrue(Decision.isLate(nowTicks: render - lead + 1, renderTicks: render, minLeadTicks: lead))
        XCTAssertFalse(Decision.isLate(nowTicks: render - 3_600_000, renderTicks: render, minLeadTicks: lead), "150 ms prima")
        XCTAssertTrue(Decision.isLate(nowTicks: render + 1, renderTicks: render, minLeadTicks: 0), "dopo l'ora chiesta")
        XCTAssertTrue(Decision.isLate(nowTicks: UInt64.max - 10, renderTicks: UInt64.max, minLeadTicks: lead), "trabocca: in ritardo")
        XCTAssertEqual(Decision.minLeadSeconds, 0.030)
        XCTAssertEqual(Decision.maxLateSkips, 4)
    }

    /// LO STOP DI FINE CANZONE (D1): mai prima della fine. Test Song A dall'àncora: la mappa dà la fine a
    /// 13,371428… s (8 battiti a 100, 12 a 120, 6 a 140). Si prende la più tarda fra mappa e ponte, più 1/8
    /// di battito all'ultimo tempo (a 140: 53,57 ms).
    func testTheSongEndStopIsNeverBeforeTheEnd() {
        guard let mapEnd = clockA.endTicks(ticksPerSecond: tps) else { return XCTFail("fine della mappa") }
        XCTAssertEqual(Double(mapEnd), Double(anchorTicks) + (4.8 + 6.0 + 6.0 * 60.0 / 140.0) * tps, accuracy: 1.0)
        let margin = 0.125 * 60.0 / 140.0 * tps
        let later = Decision.songEndStopTicks(mapEndTicks: mapEnd, bridgeEndTicks: mapEnd + 240_000,
                                              lastSectionBPM: 140, ticksPerSecond: tps)
        XCTAssertEqual(Double(later ?? 0), Double(mapEnd + 240_000) + margin, accuracy: 1.0, "conta il ponte, 10 ms dopo")
        let earlier = Decision.songEndStopTicks(mapEndTicks: mapEnd, bridgeEndTicks: mapEnd - 240_000,
                                                lastSectionBPM: 140, ticksPerSecond: tps)
        XCTAssertEqual(Double(earlier ?? 0), Double(mapEnd) + margin, accuracy: 1.0, "conta la mappa, il ponte 10 ms prima")
        for delta in stride(from: -2_400_000, through: 2_400_000, by: 240_000) {
            let bridge = UInt64(Int64(mapEnd) + Int64(delta))
            let stop = Decision.songEndStopTicks(mapEndTicks: mapEnd, bridgeEndTicks: bridge,
                                                 lastSectionBPM: 140, ticksPerSecond: tps)
            XCTAssertNotNil(stop, "scarto:\(delta)")
            XCTAssertGreaterThan(stop ?? 0, max(mapEnd, bridge), "mai prima della più tarda - scarto:\(delta)")
        }
        XCTAssertNil(Decision.songEndStopTicks(mapEndTicks: nil, bridgeEndTicks: mapEnd, lastSectionBPM: 140, ticksPerSecond: tps))
        XCTAssertNil(Decision.songEndStopTicks(mapEndTicks: mapEnd, bridgeEndTicks: 0, lastSectionBPM: 140, ticksPerSecond: tps))
        XCTAssertNil(Decision.songEndStopTicks(mapEndTicks: mapEnd, bridgeEndTicks: mapEnd, lastSectionBPM: 0, ticksPerSecond: tps))
        XCTAssertNil(Decision.songEndStopTicks(mapEndTicks: mapEnd, bridgeEndTicks: mapEnd, lastSectionBPM: 140, ticksPerSecond: .nan))
        XCTAssertNil(Decision.songEndStopTicks(mapEndTicks: mapEnd, bridgeEndTicks: mapEnd, lastSectionBPM: 140,
                                               ticksPerSecond: tps, marginBeats: -0.1))
    }

    /// Le ragioni nuove del «non certo» si distinguono, e nessuna entra né ferma.
    func testTheNewUncertainReasons() {
        let all: [Decision.Uncertain] = [.linkOff, .startChanged, .clock(.cycle), .rulersDisagree, .noTarget,
                                         .noAnchor, .mapBridgeDisagree, .lateTooManyTimes]
        for (i, a) in all.enumerated() {
            for (j, b) in all.enumerated() {
                XCTAssertEqual(a == b, i == j, "\(a) \(b)")
            }
        }
        for why in [Decision.Uncertain.noAnchor, .mapBridgeDisagree, .lateTooManyTimes] {
            XCTAssertFalse(Decision.Outcome.uncertain(why).wouldStartEngine, "\(why)")
            XCTAssertFalse(Decision.Outcome.uncertain(why).wouldSendStop, "\(why)")
        }
    }
}
