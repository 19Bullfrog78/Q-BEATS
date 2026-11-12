import XCTest

// === A432, parte 2b — banco dell'«uno» del ritorno del Follower dal conto (`FollowerBandUno`, banco Models) ===
// Mandato A432, seguito «PARTE 2b», par. 2.4 (mandato v5, par. 2.2 voce i e par. 2.3): il banco di `FollowerReturnUno`
// con l'orologio `.band`, col caso di A424, Aperto par. A.14 (l'«uno» dopo un cambio di metro).
// La canzone di A.14: 4/4 per due battute (8 battiti), poi 3/4 per otto battute (24 battiti), a 120. L'àncora
// all'inizio, battito della sessione 600 (un multiplo di 12: le battute di Link col quanto 4 e col quanto 3 partono
// tutte e due da lì). Gli «uno» della canzone: 600, 604, poi 608, 611, 614, … 629; la fine a 632. Le battute di Link
// col quanto 3 (la regola di prima) sono 609, 612, 615: un battito dopo.
// 24.000.000 tick al secondo, l'ora dell'àncora a 100 s, come `FollowerBandCountTests`.
// Gli stessi casi, con gli stessi nomi e gli stessi numeri, girano sul modello Python delle regole (fuori dal
// deposito), dove ogni test cade se si toglie la regola che prova (la tabella nel referto).
// Mai `!` sugli optional: i test lanciano (`XCTUnwrap`).

final class FollowerBandUnoTests: XCTestCase {

    private struct NotTheExpectedCase: Error {}

    private let tps = 24_000_000.0
    private let t0: UInt64 = 100 * 24_000_000

    private func ticks(_ seconds: Double) -> UInt64 {
        t0 + UInt64((seconds * tps).rounded())
    }

    private func song(_ sections: [(Int, Int, Double)]) -> SongMap {
        SongMap(sections: sections.map { SongMapSection(beatsPerBar: $0.0, repetitions: $0.1, bpm: $0.2) })
    }

    private func count(_ map: SongMap, section: Int = 0, beat: Int = 0, link: Double = 600.0) -> FollowerBandCount {
        FollowerBandCount(map: map, anchor: ShowClockAnchor(section: section, beatInSection: beat,
                                                            linkBeat: link, ticks: t0))
    }

    private var a14: SongMap { song([(4, 2, 120.0), (3, 8, 120.0)]) }

    private func band(_ beat: Double, _ beatsPerBar: Int) -> FollowerReturnUno {
        FollowerReturnUno(beat: beat, clock: .band, beatsPerBar: beatsPerBar)
    }

    func testTheUnoIsTheNextDownbeatOfTheSong() {
        let c = count(a14)
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 601.5), band(604, 4))
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 604.0), band(604, 4),
                       "un battito su un inizio di battuta è quella battuta")
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 600.0), band(600, 4), "il battito dell'àncora")
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 604.000001), band(608, 3),
                       "appena dopo: la battuta dopo, che è già nel 3/4")
    }

    /// A424, Aperto A.14: nel 3/4 gli «uno» della canzone sono 608, 611, 614; le battute di Link col quanto 3 (la
    /// regola di prima: `nextBarBeat`) sono 609, 612, 615, un battito dopo.
    func testTheUnoAfterAMeterChangeIsNotTheLinkBar() throws {
        let c = count(a14)
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 612.4), band(614, 3))
        let old = try XCTUnwrap(OutputReturnDecision.nextBarBeat(atOrAfter: 612.4, quantum: 3))
        XCTAssertEqual(old, 615, "la battuta di Link col quanto 3")
        XCTAssertEqual((old - 608).truncatingRemainder(dividingBy: 3), 1,
                       "che è il secondo battito di una battuta della canzone")
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 608.0), band(608, 3), "il primo «uno» del 3/4")
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 608.2), band(611, 3))
    }

    /// Dall'ultima battuta del 4/4 l'«uno» è il primo del 3/4, e porta i 3 battiti per battuta della sua sezione.
    func testTheUnoBeforeTheBoundaryCarriesTheMeterOfTheSectionItFallsIn() {
        let c = count(a14)
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 605.2), band(608, 3))
        // 3/4 poi 4/4: 9 battiti e poi battute da 4.
        let d = count(song([(3, 3, 120.0), (4, 4, 120.0)]))
        XCTAssertEqual(FollowerBandUno.next(count: d, atOrAfterLinkBeat: 606.5), band(609, 4))
        XCTAssertEqual(FollowerBandUno.next(count: d, atOrAfterLinkBeat: 609.5), band(613, 4))
    }

    /// La battuta dopo non è «il battito più una battuta»: al confine il metro cambia.
    func testTheNextBarWalksTheMapAcrossTheBoundary() throws {
        let d = count(song([(3, 3, 120.0), (4, 4, 120.0)]))
        let u = try XCTUnwrap(FollowerBandUno.next(count: d, atOrAfterLinkBeat: 605.5))
        XCTAssertEqual(u, band(606, 3))
        let u2 = try XCTUnwrap(FollowerBandUno.nextBar(count: d, after: u))
        XCTAssertEqual(u2, band(609, 4), "la battuta dopo è la prima del 4/4")
        XCTAssertEqual(FollowerBandUno.nextBar(count: d, after: u2), band(613, 4),
                       "e quella dopo è quattro battiti più in là, non tre")
        let c = count(a14)
        XCTAssertEqual(FollowerBandUno.nextBar(count: c, after: band(604, 4)), band(608, 3))
        XCTAssertEqual(FollowerBandUno.nextBar(count: c, after: band(608, 3)), band(611, 3))
        XCTAssertNil(FollowerBandUno.nextBar(count: c, after: FollowerReturnUno(beat: 604, clock: .link, beatsPerBar: 4)),
                     "solo per un «uno» del conto")
        XCTAssertNil(FollowerBandUno.nextBar(count: c, after: band(.nan, 4)))
    }

    func testTheSongEndingFirstGivesNoUno() {
        let c = count(a14)
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 629.0), band(629, 3), "l'ultima battuta")
        XCTAssertNil(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 629.5),
                     "dopo l'ultimo inizio di battuta la canzone finisce prima")
        XCTAssertNil(FollowerBandUno.nextBar(count: c, after: band(629, 3)))
        XCTAssertNil(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 640.0), "oltre la fine")
        XCTAssertNil(FollowerBandUno.next(count: c, atOrAfterLinkBeat: .nan))
    }

    func testAClosedCountGivesNoUno() throws {
        var c = count(a14)
        XCTAssertTrue(FollowerBandUno.isCertain(c))
        // Una lettura a 2 s dall'àncora (4 battiti a 120) col battito della sessione 3 battiti avanti: fuori dallo stato.
        let reading = c.read(pendingLinkBeat: 607.0, pendingTicks: ticks(2.0), ticksPerSecond: tps, lastCounted: nil)
        XCTAssertFalse(reading.certain)
        XCTAssertEqual(reading.reason, .jumpOutsideRenumbering)
        XCTAssertFalse(FollowerBandUno.isCertain(c))
        XCTAssertNil(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 612.4))
        XCTAssertNil(FollowerBandUno.next(count: c, atOrAfterTicks: ticks(6.2), ticksPerSecond: tps))
        XCTAssertFalse(FollowerBandUno.confirms(count: c, uno: band(614, 3)))
        XCTAssertNil(FollowerBandUno.mapTicks(count: c, uno: band(614, 3), ticksPerSecond: tps))
        XCTAssertFalse(FollowerBandUno.isCertain(nil))
        // Un conto nato chiuso (il seme non certo), senza àncora: 2/4 a 120, l'ingresso mezzo secondo dopo il Play
        // (un battito, mezza battuta).
        let entry = FollowerBandCount.seed(FollowerBandSeedInput(map: song([(2, 8, 120.0)]), playCallbackTicks: t0,
                                                                 entryTicks: ticks(0.5), entryLinkBeat: 600.0,
                                                                 ticksPerSecond: tps))
        guard case .noCount(let bornClosed) = entry else { throw NotTheExpectedCase() }
        XCTAssertEqual(bornClosed.closed, .seedOffBar)
        XCTAssertNil(bornClosed.anchor)
        XCTAssertFalse(FollowerBandUno.isCertain(bornClosed))
        XCTAssertNil(FollowerBandUno.next(count: bornClosed, atOrAfterLinkBeat: 601.5))
    }

    func testABeatBeforeTheAnchorSectionOrInACycleGivesNoUno() {
        let c = count(a14, section: 1, beat: 0, link: 608.0)
        XCTAssertNil(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 607.0), "prima della sezione dell'àncora")
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterLinkBeat: 608.0), band(608, 3))
        let cycle = count(song([(4, 2, 120.0), (4, 0, 120.0)]))
        XCTAssertEqual(FollowerBandUno.next(count: cycle, atOrAfterLinkBeat: 603.0), band(604, 4))
        XCTAssertNil(FollowerBandUno.next(count: cycle, atOrAfterLinkBeat: 604.5),
                     "la battuta dopo sarebbe l'inizio di un ciclo")
        XCTAssertNil(FollowerBandUno.next(count: cycle, atOrAfterLinkBeat: 609.0), "dentro il ciclo")
    }

    func testTheSavedUnoIsConfirmedOnlyWhileItIsADownbeatOfTheCount() {
        let c = count(a14)
        XCTAssertTrue(FollowerBandUno.confirms(count: c, uno: band(614, 3)))
        XCTAssertFalse(FollowerBandUno.confirms(count: c, uno: band(615, 3)), "non è un inizio di battuta")
        XCTAssertFalse(FollowerBandUno.confirms(count: c, uno: band(614, 4)),
                       "i battiti per battuta non sono quelli della sua sezione")
        XCTAssertFalse(FollowerBandUno.confirms(count: c, uno: FollowerReturnUno(beat: 614, clock: .link, beatsPerBar: 3)))
        XCTAssertFalse(FollowerBandUno.confirms(count: nil, uno: band(614, 3)))
        // L'àncora ha preso un salto di −1 (una rinumerazione riconosciuta): gli «uno» sono 607, 610, 613.
        let moved = count(a14, link: 599.0)
        XCTAssertFalse(FollowerBandUno.confirms(count: moved, uno: band(614, 3)))
        XCTAssertTrue(FollowerBandUno.confirms(count: moved, uno: band(613, 3)))
        // Un salto di una battuta intera (−3): 614 è ancora un inizio di battuta (quello dopo): resta, e la guardia del
        // primo campione a volume 1 decide se è troppo presto.
        let byOneBar = count(a14, link: 597.0)
        XCTAssertTrue(FollowerBandUno.confirms(count: byOneBar, uno: band(614, 3)))
    }

    /// DA-SOLO: il posto alla scadenza dal righello dei secondi. 6,2 s a 120 = 12,4 battiti dall'àncora.
    func testOnItsOwnTheUnoComesFromTheSecondsRuler() {
        let c = count(a14)
        XCTAssertEqual(FollowerBandUno.next(count: c, atOrAfterTicks: ticks(6.2), ticksPerSecond: tps), band(614, 3))
        XCTAssertEqual(FollowerBandUno.mapTicks(count: c, uno: band(614, 3), ticksPerSecond: tps), ticks(7.0),
                       "14 battiti a 120")
        // Coi tempi diversi: 8 battiti a 120 (4 s) e poi il 3/4 a 90: a 6,2 s la band è a 8 + 3,3 = 11,3 battiti.
        let d = count(song([(4, 2, 120.0), (3, 8, 90.0)]))
        XCTAssertEqual(FollowerBandUno.next(count: d, atOrAfterTicks: ticks(6.2), ticksPerSecond: tps), band(614, 3))
        XCTAssertEqual(FollowerBandUno.mapTicks(count: d, uno: band(614, 3), ticksPerSecond: tps), ticks(8.0),
                       "4 s e poi 6 battiti a 90")
        XCTAssertNil(FollowerBandUno.next(count: d, atOrAfterTicks: ticks(4.0 + 24 * 60.0 / 90.0 + 1.0), ticksPerSecond: tps),
                     "oltre la fine")
        XCTAssertNil(FollowerBandUno.mapTicks(count: d, uno: FollowerReturnUno(beat: 615, clock: .link, beatsPerBar: 3),
                                              ticksPerSecond: tps))
    }

    /// La linea propria: battito 50 all'ora dell'àncora, a 90; l'ultimo «uno» uscito a 50,25 (i click cadono su
    /// 50,25 + n). L'ora della mappa dell'«uno» (8 s dopo l'àncora) è il battito 62 della linea: l'«uno» è il click più
    /// vicino, 62,25.
    func testOnItsOwnTheUnoIsCarriedOnTheOwnLine() {
        let timeline = OwnClockTimeline(anchorTicks: t0, anchorBeat: 50.0, bpm: 90.0)
        XCTAssertEqual(FollowerBandUno.ownBeat(mapTicks: ticks(8.0), timeline: timeline, lastUnoBeat: 50.25, ticksPerSecond: tps), 62.25)
        XCTAssertEqual(FollowerBandUno.ownBeat(mapTicks: ticks(8.0), timeline: timeline, lastUnoBeat: 50.0, ticksPerSecond: tps), 62.0)
        XCTAssertEqual(FollowerBandUno.ownBeat(mapTicks: ticks(8.0), timeline: timeline, lastUnoBeat: 49.6, ticksPerSecond: tps), 61.6,
                       "il più vicino può essere prima")
        XCTAssertNil(FollowerBandUno.ownBeat(mapTicks: ticks(8.0), timeline: timeline, lastUnoBeat: .nan, ticksPerSecond: tps))
        XCTAssertNil(FollowerBandUno.ownBeat(mapTicks: ticks(8.0), timeline: OwnClockTimeline(anchorTicks: t0, anchorBeat: 50.0, bpm: 0.0),
                                             lastUnoBeat: 50.25, ticksPerSecond: tps))
        XCTAssertNil(FollowerBandUno.ownBeat(mapTicks: ticks(8.0), timeline: timeline, lastUnoBeat: 50.25, ticksPerSecond: 0.0))
    }

    /// Le tre righe nuove di `OutputReturnDecision` per l'orologio `.band`.
    func testTheBandClockInTheReturnRules() {
        // L'orologio di adesso: un «uno» del conto resta del conto finché il conto è certo, IN SYNC o DA-SOLO.
        XCTAssertEqual(OutputReturnDecision.unoClockNow(saved: .band, followsLink: true, bandCountCertain: true), .band)
        XCTAssertEqual(OutputReturnDecision.unoClockNow(saved: .band, followsLink: false, bandCountCertain: true), .band)
        XCTAssertEqual(OutputReturnDecision.unoClockNow(saved: .band, followsLink: true, bandCountCertain: false), .link,
                       "col conto chiuso: l'orologio di sempre")
        XCTAssertEqual(OutputReturnDecision.unoClockNow(saved: .band, followsLink: false, bandCountCertain: false), .own)
        XCTAssertEqual(OutputReturnDecision.unoClockNow(saved: .link, followsLink: true, bandCountCertain: true), .link,
                       "un «uno» di Link non diventa del conto")
        XCTAssertEqual(OutputReturnDecision.unoClockNow(saved: .own, followsLink: false, bandCountCertain: true), .own)
        XCTAssertEqual(OutputReturnDecision.unoClockNow(saved: .link, followsLink: false, bandCountCertain: true), .own)
        let uno = band(608, 3)
        // Il metro del motore (4, prima del confine) non è quello dell'«uno» (3, la sua sezione): non riarma.
        XCTAssertEqual(OutputReturnDecision.refreshUno(saved: uno, clockNow: .band, beatsPerBarNow: 4, rereadTicks: 5000), .ticks(5000))
        XCTAssertEqual(OutputReturnDecision.refreshUno(saved: uno, clockNow: .link, beatsPerBarNow: 3, rereadTicks: 5000),
                       .rearm(reason: "orologio-cambiato"), "il conto chiuso")
        XCTAssertEqual(OutputReturnDecision.refreshUno(saved: uno, clockNow: .band, beatsPerBarNow: 3, rereadTicks: nil),
                       .rearm(reason: "uno-non-rileggibile"))
        // Per gli «uno» di sempre il metro vale come prima.
        XCTAssertEqual(OutputReturnDecision.refreshUno(saved: FollowerReturnUno(beat: 48, clock: .link, beatsPerBar: 4),
                                                       clockNow: .link, beatsPerBarNow: 3, rereadTicks: 5000),
                       .rearm(reason: "metro-cambiato"))
        // La battuta dopo di un «uno» del conto non è «più una battuta».
        XCTAssertNil(OutputReturnDecision.nextBarUno(uno))
        XCTAssertEqual(OutputReturnDecision.nextBarUno(FollowerReturnUno(beat: 48, clock: .link, beatsPerBar: 4)),
                       FollowerReturnUno(beat: 52, clock: .link, beatsPerBar: 4))
        XCTAssertEqual(FollowerReturnClock.band.rawValue, "band")
    }
}
