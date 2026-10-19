import XCTest

// === A412 · SEGUITO 2 — banco della numerazione della sessione nel conto e nel rientro del Direttore ===
// Mandato «A412 · SEGUITO 2», par. 3.5. Il collaudo di A412 delle 16:24 (righe copiate nel mandato, par. 1): Siri
// 0,95 s dopo il Play di Test Song B, il cambio 90 → 110 nell'attesa del rientro. Fra le due letture all'ora
// dell'avvio (18.590 e 19.047) il battito a quantum 1 passa da 3,415800 a 2,415800, quello a quantum 1e6 resta
// 1917,415800, quello a quantum 0 (la linea propria) passa da 2,924537 a 2,915067: la numerazione dell'apparecchio
// salta di un battito intero con la sessione ferma, e A412 ha rifiutato il rientro («avvio cambiato», «mappa e ponte
// in disaccordo»). Qui gli stessi numeri nei tipi puri: nella numerazione a quantum 1 si rifà il rifiuto; nella
// numerazione della sessione stesso avvio, stessa posizione e lo stesso bersaglio. Il caso delle 16:06 (passo 3,
// registro QBeats_registro_iPhone_2026-10-18_16-06-55.txt) resta com'era; un riavvio vero e uno spostamento vero di
// un battito della sessione si rifiutano come oggi.
// Test Song B: 3 battute 4/4 a 90, poi 12 battute 4/4 a 110. Le ore sono tick mach a 24 MHz. Alle 16:24 la distanza
// fra le due numerazioni è −1914 prima del salto e −1915 dopo; alle 16:06 è −282. Gli istanti senza ora nel registro
// sono ricostruiti dalle righe: la decisione da oraMappa meno daAdesso; la riga al secondo delle 19.547 dal righello
// dei secondi (11,0452 + 0,9722 battiti dall'àncora); il battito di Link alla decisione dal righello dei secondi più
// lo scarto scritto nella riga.

final class DirectorRejoinSessionNumberingTests: XCTestCase {

    private typealias Decision = DirectorRejoinDecision

    private let tps = 24_000_000.0
    /// 100 buffer da 512 campioni a 48 kHz: 1,0666… s.
    private let window = 100.0 * 512.0 / 48_000.0

    private let songB = SongMap(sections: [
        SongMapSection(beatsPerBar: 4, repetitions: 3, bpm: 90),
        SongMapSection(beatsPerBar: 4, repetitions: 12, bpm: 110),
    ])

    // 16:24 — l'àncora: sezione 0, battito 1 (indice 1/12), battitoLinkQ1 3,034936, ora 5922959314512.
    private let anchorTicks1624: UInt64 = 5_922_959_314_512
    private var clockQ1At1624: ShowClock {
        ShowClock(map: songB, anchor: ShowClockAnchor(section: 0, beatInSection: 1, linkBeat: 3, ticks: anchorTicks1624))
    }
    private var clockSessionAt1624: ShowClock {
        ShowClock(map: songB, anchor: ShowClockAnchor(section: 0, beatInSection: 1, linkBeat: 1917, ticks: anchorTicks1624))
    }

    // 16:06 — l'àncora: sezione 0, battito 10 (indice 10/12), battitoLinkQ1 8,036075, ora 5908281168772.
    private let anchorTicks1606: UInt64 = 5_908_281_168_772
    private var clockQ1At1606: ShowClock {
        ShowClock(map: songB, anchor: ShowClockAnchor(section: 0, beatInSection: 10, linkBeat: 8, ticks: anchorTicks1606))
    }
    private var clockSessionAt1606: ShowClock {
        ShowClock(map: songB, anchor: ShowClockAnchor(section: 0, beatInSection: 10, linkBeat: 290, ticks: anchorTicks1606))
    }

    /// La decisione delle 16:24:17.297: oraMappa 5923187678148 meno daAdesso 3876,2 ms.
    private let decisionTicks1624: UInt64 = 5_923_094_649_348
    /// La riga al secondo delle 16:24:19.547, dopo la W2 dell'iPad e il salto.
    private let secondTicks1624: UInt64 = 5_923_148_633_203
    /// La decisione delle 16:06:20.048: oraMappa 5908470259681 meno daAdesso 2191,1 ms.
    private let decisionTicks1606: UInt64 = 5_908_417_673_281

    private func situation(same: Bool, nowLinkBeat: Double, nowTicks: UInt64, tempo: Double,
                           playing: Bool = true) -> Decision.Situation {
        Decision.Situation(role: .direttore, userLinkEnabled: true, showOpen: true,
                           linkEnabled: true, sessionPlaying: playing, sameStart: same,
                           nowLinkBeat: nowLinkBeat, nowTicks: nowTicks,
                           ticksPerSecond: tps, sessionTempo: tempo,
                           marginSeconds: 0.150, windowSeconds: window)
    }

    // MARK: - Le due numerazioni

    /// Il quantum della numerazione della sessione è quello del 2D e del timbro dell'avvio.
    func testTheSessionQuantum() {
        XCTAssertEqual(Decision.sessionQuantum, 1.0e6)
    }

    /// Le letture all'ora dell'avvio delle 16:24 (mandato, par. 3.5): la distanza fra le due numerazioni passa da
    /// −1914 a −1915, il battito della sessione resta lo stesso.
    func testTheDeviceOffsetJumpsByOneWhileTheSessionBeatStays() {
        XCTAssertEqual(Decision.deviceOffset(beatQuantumOne: 3.415800, beatSession: 1917.415800), -1914)
        XCTAssertEqual(Decision.deviceOffset(beatQuantumOne: 2.415800, beatSession: 1917.415800), -1915)
        XCTAssertEqual(Decision.deviceOffset(beatQuantumOne: -1.875093, beatSession: 280.124907), -282)
    }

    /// Valori non finiti: nessuna distanza.
    func testTheDeviceOffsetOfInvalidReadings() {
        XCTAssertNil(Decision.deviceOffset(beatQuantumOne: .nan, beatSession: 1917))
        XCTAssertNil(Decision.deviceOffset(beatQuantumOne: 3, beatSession: .infinity))
    }

    // MARK: - 16:24, stesso avvio

    /// A quantum 1 le due letture dell'avvio sono un altro avvio (il rifiuto di A412); nella sessione lo stesso.
    func testSameStartAcrossTheRenumbering() {
        XCTAssertFalse(Decision.sameStart(anchorStartBeat: 3.415800, nowStartBeat: 2.415800))
        XCTAssertTrue(Decision.sameStart(anchorStartBeat: 1917.415800, nowStartBeat: 1917.415800))
        // L'avvio all'àncora (16:24:11.823) e alla riga al secondo delle 19.547, con la ripetizione del Direttore.
        XCTAssertFalse(Decision.sameStart(anchorStartBeat: 3.417300, nowStartBeat: 2.417633))
        XCTAssertTrue(Decision.sameStart(anchorStartBeat: 1917.417300, nowStartBeat: 1917.417633))
    }

    // MARK: - 16:24, la posizione

    /// La riga al secondo delle 19.547: a quantum 1 battiti 1.1.1, secondi 1.1.2, scarto −0,9722, non certo (come
    /// il registro); nella sessione battiti 1.1.2 come i secondi, scarto +0,0278, certo.
    func testThePositionAfterTheTempoChange() throws {
        let q1 = clockQ1At1624.read(nowLinkBeat: 14.0452, nowTicks: secondTicks1624, ticksPerSecond: tps)
        XCTAssertEqual(try XCTUnwrap(q1.gapBeats), -0.9722, accuracy: 2e-4)
        XCTAssertFalse(q1.certain)
        guard case .inSong(1, 1, 1, _) = q1.outcome else {
            return XCTFail("a quantum 1: \(q1.outcome)")
        }
        let session = clockSessionAt1624.read(nowLinkBeat: 1929.0452, nowTicks: secondTicks1624, ticksPerSecond: tps)
        XCTAssertEqual(try XCTUnwrap(session.gapBeats), 0.0278, accuracy: 2e-4)
        XCTAssertTrue(session.certain)
        guard case .inSong(1, 1, 2, _) = session.outcome else {
            return XCTFail("nella sessione: \(session.outcome)")
        }
        guard case .inSong(1, let x) = session.bySeconds.place else {
            return XCTFail("righello dei secondi: \(session.bySeconds.place)")
        }
        XCTAssertEqual(x, 1.0174, accuracy: 2e-4)
    }

    // MARK: - 16:24, il bersaglio

    /// La decisione delle 17.297 (prima del salto): rientra alla battuta 2 della sezione a 110, una battuta di
    /// finestra; nella sessione il battito è 1932, a quantum 1 era 18.
    func testTheDecisionTarget() {
        let session = Decision.coordinate(clock: clockSessionAt1624,
                                          situation: situation(same: true, nowLinkBeat: 1925.4933,
                                                               nowTicks: decisionTicks1624, tempo: 90))
        XCTAssertEqual(session.outcome, .rejoin(section: 1, bar: 2, linkBeat: 1932))
        XCTAssertEqual(session.windowShifts, 1)
        let q1 = Decision.coordinate(clock: clockQ1At1624,
                                     situation: situation(same: true, nowLinkBeat: 11.4933,
                                                          nowTicks: decisionTicks1624, tempo: 90))
        XCTAssertEqual(q1.outcome, .rejoin(section: 1, bar: 2, linkBeat: 18))
        XCTAssertEqual(q1.windowShifts, 1)
    }

    /// Dopo il salto (19.547): nella sessione lo stesso bersaglio della decisione; a quantum 1 «avvio cambiato»,
    /// e anche a stesso avvio i righelli in disaccordo.
    func testTheSameTargetAfterTheRenumbering() {
        let session = Decision.coordinate(clock: clockSessionAt1624,
                                          situation: situation(same: true, nowLinkBeat: 1929.0452,
                                                               nowTicks: secondTicks1624, tempo: 110))
        XCTAssertEqual(session.outcome, .rejoin(section: 1, bar: 2, linkBeat: 1932))
        let q1 = Decision.coordinate(clock: clockQ1At1624,
                                     situation: situation(same: false, nowLinkBeat: 14.0452,
                                                          nowTicks: secondTicks1624, tempo: 110))
        XCTAssertEqual(q1.outcome, .uncertain(.startChanged))
        let q1Forced = Decision.coordinate(clock: clockQ1At1624,
                                           situation: situation(same: true, nowLinkBeat: 14.0452,
                                                                nowTicks: secondTicks1624, tempo: 110))
        XCTAssertEqual(q1Forced.outcome, .uncertain(.rulersDisagree))
    }

    /// L'armamento delle 21.080: l'ora della mappa del bersaglio è la stessa nelle due numerazioni; il ponte a
    /// quantum 1 (registrato, battito 18 dopo il salto) dista −530,3 ms, −0,9722 battiti: disaccordo. Il ponte della
    /// sessione (battito 1932: un battito a 110 prima) dista +15,2 ms, +0,0278: accordo.
    func testTheArmingCheckInTheTwoNumberings() throws {
        let mapTicks = try XCTUnwrap(clockSessionAt1624.ticks(section: 1, beatInSection: 4, ticksPerSecond: tps))
        XCTAssertEqual(mapTicks, 5_923_187_678_148)
        XCTAssertEqual(clockQ1At1624.ticks(section: 1, beatInSection: 4, ticksPerSecond: tps), mapTicks)
        let old = Decision.armingCheck(mapTicks: mapTicks, bridgeTicks: 5_923_200_404_616, sectionBPM: 110,
                                       ticksPerSecond: tps)
        XCTAssertEqual(try XCTUnwrap(old.gapSeconds) * 1000, -530.3, accuracy: 0.05)
        XCTAssertEqual(try XCTUnwrap(old.gapBeats), -0.9722, accuracy: 1e-4)
        XCTAssertFalse(old.agree)
        let new = Decision.armingCheck(mapTicks: mapTicks, bridgeTicks: 5_923_187_313_707, sectionBPM: 110,
                                       ticksPerSecond: tps)
        XCTAssertEqual(try XCTUnwrap(new.gapSeconds) * 1000, 15.18, accuracy: 0.05)
        XCTAssertEqual(try XCTUnwrap(new.gapBeats), 0.0278, accuracy: 1e-4)
        XCTAssertTrue(new.agree)
    }

    // MARK: - 16:06, com'era

    /// Il passo 3 (cambio durante Siri, nessun salto: la distanza resta −282): la stessa decisione nelle due
    /// numerazioni, battuta 4 della sezione a 110, senza finestra, lo stesso scarto.
    func testThe1606CaseStaysAsItWas() throws {
        XCTAssertTrue(Decision.sameStart(anchorStartBeat: -1.875761, nowStartBeat: -1.876927))
        XCTAssertTrue(Decision.sameStart(anchorStartBeat: 280.124239, nowStartBeat: 280.123073))
        let q1 = Decision.coordinate(clock: clockQ1At1606,
                                     situation: situation(same: true, nowLinkBeat: 18.0122,
                                                          nowTicks: decisionTicks1606, tempo: 110))
        let session = Decision.coordinate(clock: clockSessionAt1606,
                                          situation: situation(same: true, nowLinkBeat: 300.0122,
                                                               nowTicks: decisionTicks1606, tempo: 110))
        XCTAssertEqual(q1.outcome, .rejoin(section: 1, bar: 4, linkBeat: 22))
        XCTAssertEqual(session.outcome, .rejoin(section: 1, bar: 4, linkBeat: 304))
        XCTAssertEqual(q1.windowShifts, 0)
        XCTAssertEqual(session.windowShifts, 0)
        let gapQ1 = try XCTUnwrap(q1.reading?.gapBeats)
        let gapSession = try XCTUnwrap(session.reading?.gapBeats)
        XCTAssertEqual(gapQ1, 0.0292, accuracy: 2e-4)
        XCTAssertEqual(gapSession, gapQ1, accuracy: 1e-9)
        XCTAssertEqual(clockSessionAt1606.ticks(section: 1, beatInSection: 12, ticksPerSecond: tps), 5_908_470_259_681)
    }

    // MARK: - I cambi veri

    /// Un riavvio vero della sessione (un altro avvio): non è lo stesso avvio, il rientro non è certo.
    func testARealRestartIsRefused() {
        XCTAssertFalse(Decision.sameStart(anchorStartBeat: 1917.4173, nowStartBeat: 1950.0))
        let plan = Decision.coordinate(clock: clockSessionAt1624,
                                       situation: situation(same: false, nowLinkBeat: 1929.0452,
                                                            nowTicks: secondTicks1624, tempo: 110))
        XCTAssertEqual(plan.outcome, .uncertain(.startChanged))
    }

    /// Uno spostamento vero di un battito della sessione: l'avvio non è più lo stesso, e il righello dei battiti si
    /// stacca da quello dei secondi. Da 1/8 di battito in su il conto non è certo; sotto, sì.
    func testARealShiftOfTheSessionIsRefused() {
        XCTAssertFalse(Decision.sameStart(anchorStartBeat: 1917.4173, nowStartBeat: 1918.4173))
        let shifted = Decision.coordinate(clock: clockSessionAt1624,
                                          situation: situation(same: true, nowLinkBeat: 1930.0452,
                                                               nowTicks: secondTicks1624, tempo: 110))
        XCTAssertEqual(shifted.outcome, .uncertain(.rulersDisagree))
        let eighth = clockSessionAt1624.read(nowLinkBeat: 1929.1702, nowTicks: secondTicks1624, ticksPerSecond: tps)
        XCTAssertFalse(eighth.certain)
        let small = clockSessionAt1624.read(nowLinkBeat: 1929.0952, nowTicks: secondTicks1624, ticksPerSecond: tps)
        XCTAssertTrue(small.certain)
    }

    /// La sessione ferma resta ferma da altri (T6), come oggi.
    func testTheStoppedSessionIsAsToday() {
        let plan = Decision.coordinate(clock: clockSessionAt1624,
                                       situation: situation(same: true, nowLinkBeat: 1929.0452,
                                                            nowTicks: secondTicks1624, tempo: 110, playing: false))
        XCTAssertEqual(plan.outcome, .sessionStoppedElsewhere)
    }
}
