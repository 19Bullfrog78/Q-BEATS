import XCTest

// === A425 — banco della mappa consegnata a un avvio in corso (`SongInProgressDecision`, banco Models), mandato A425, par. 2.2 ===
// Le sequenze: la mappa prima dell'avvio (il runner di Direttore e Solo), la mappa dopo (il Follower: il primo `start()` della
// sessione Link, poi la mappa e il secondo `start()` che trova il motore in moto), lo Stop in mezzo, due mappe di fila, e gli
// ordini della gara con l'attesa d'ingresso zero (seguito 3 di A421, par. 7): il fuoco dopo il blocco di `setSongMap` e il fuoco
// prima. Fino ad A424 la mappa dopo l'avvio restava non consumata: «canzone in corso» falsa per tutta la canzone, e col fuoco prima
// della mappa il segno alto fino a un avvio dopo.

final class SongInProgressDecisionTests: XCTestCase {

    private typealias D = SongInProgressDecision

    /// La mappa prima dell'avvio (Direttore e Solo dal runner): l'avvio la consuma, «canzone in corso»; un Play dopo senza mappa
    /// (il pedale dopo uno Stop) è fuori canzone.
    func testTheMapBeforeTheStart() {
        var m = D.mapDelivered(.initial)
        XCTAssertEqual(m, SongMapMark(mapForNextStart: true, songInProgress: false))
        m = D.normalStart(m)
        XCTAssertEqual(m, SongMapMark(mapForNextStart: false, songInProgress: true))
        m = D.normalStart(D.stopped(m))
        XCTAssertEqual(m, SongMapMark(mapForNextStart: false, songInProgress: false))
    }

    /// La mappa dopo l'avvio (il Follower): il primo avvio è fuori canzone; il secondo `start()` trova il motore in moto e la
    /// consuma; il fuoco dopo trova il segno basso.
    func testTheMapAfterTheStartIsConsumedByTheRunningStart() {
        var m = D.normalStart(.initial)
        XCTAssertFalse(m.songInProgress, "il primo start(), della sessione Link, senza mappa")
        m = D.mapDelivered(m)
        let second = D.runningStart(m)
        XCTAssertTrue(second.consumed)
        XCTAssertEqual(second.mark, SongMapMark(mapForNextStart: false, songInProgress: true))
        let fire = D.runningStart(second.mark)
        XCTAssertFalse(fire.consumed)
        XCTAssertEqual(fire.mark, second.mark)
    }

    /// Gli ordini della gara con l'attesa zero: il blocco del primo `start()` arma il fuoco in fondo, il principale mette in coda
    /// `setSongMap` e il secondo `start()`. In ognuno alla fine «canzone in corso» è vera e il segno basso, consumato una volta.
    func testTheOrdersOfTheZeroWaitRace() {
        // Il fuoco dopo il blocco di `setSongMap` e dopo il secondo `start()`: lo consuma il secondo `start()`.
        var a = D.mapDelivered(D.normalStart(.initial))
        let secondA = D.runningStart(a)
        a = secondA.mark
        let fireA = D.runningStart(a)
        XCTAssertTrue(secondA.consumed)
        XCTAssertFalse(fireA.consumed)
        XCTAssertEqual(fireA.mark, SongMapMark(mapForNextStart: false, songInProgress: true))
        // Il fuoco dopo il blocco di `setSongMap` e prima del secondo `start()`: lo consuma il fuoco.
        var b = D.mapDelivered(D.normalStart(.initial))
        let fireB = D.runningStart(b)
        b = fireB.mark
        let secondB = D.runningStart(b)
        XCTAssertTrue(fireB.consumed)
        XCTAssertFalse(secondB.consumed)
        XCTAssertEqual(secondB.mark, SongMapMark(mapForNextStart: false, songInProgress: true))
        // Il fuoco prima del blocco di `setSongMap`: il fuoco trova il segno basso, lo consuma il secondo `start()`.
        var c = D.normalStart(.initial)
        let fireC = D.runningStart(c)
        XCTAssertFalse(fireC.consumed, "il fuoco prima della mappa trova il segno basso")
        c = D.mapDelivered(fireC.mark)
        let secondC = D.runningStart(c)
        XCTAssertTrue(secondC.consumed)
        XCTAssertEqual(secondC.mark, SongMapMark(mapForNextStart: false, songInProgress: true))
    }

    /// Lo Stop in mezzo: dopo lo Stop il secondo `start()` trova il motore fermo ed è un avvio normale, che consuma la mappa. Una
    /// mappa e uno Stop prima dell'avvio: «canzone in corso» giù, il segno resta per l'avvio dopo.
    func testAStopInTheMiddle() {
        var m = D.stopped(D.normalStart(.initial))
        m = D.normalStart(D.mapDelivered(m))
        XCTAssertEqual(m, SongMapMark(mapForNextStart: false, songInProgress: true))
        m = D.stopped(m)
        XCTAssertEqual(m, SongMapMark(mapForNextStart: false, songInProgress: false))
        m = D.stopped(D.mapDelivered(m))
        XCTAssertEqual(m, SongMapMark(mapForNextStart: true, songInProgress: false))
    }

    /// Due mappe di fila: un segno solo, consumato una volta, dall'avvio normale o dall'avvio in corso.
    func testTwoMapsInARow() {
        var m = D.mapDelivered(D.mapDelivered(.initial))
        XCTAssertEqual(m, SongMapMark(mapForNextStart: true, songInProgress: false))
        m = D.normalStart(m)
        XCTAssertEqual(m, SongMapMark(mapForNextStart: false, songInProgress: true))
        XCTAssertFalse(D.runningStart(m).consumed, "consumata una volta sola")
        let running = D.runningStart(D.mapDelivered(D.mapDelivered(.initial)))
        XCTAssertTrue(running.consumed)
        XCTAssertFalse(D.runningStart(running.mark).consumed)
    }

    /// La tabella intera: ogni mossa da ogni stato.
    func testTheMovesTable() {
        for map in [false, true] {
            for song in [false, true] {
                let m = SongMapMark(mapForNextStart: map, songInProgress: song)
                XCTAssertEqual(D.mapDelivered(m), SongMapMark(mapForNextStart: true, songInProgress: song))
                XCTAssertEqual(D.normalStart(m), SongMapMark(mapForNextStart: false, songInProgress: map))
                let running = D.runningStart(m)
                XCTAssertEqual(running.consumed, map)
                XCTAssertEqual(running.mark, map ? SongMapMark(mapForNextStart: false, songInProgress: true) : m)
                XCTAssertEqual(D.stopped(m), SongMapMark(mapForNextStart: map, songInProgress: false))
            }
        }
    }
}
