import XCTest

// === A420 — banco della catena dei buffer (`BufferChainGeneration`, banco Models), mandato A420 par. 2.2 e risposta del
// referee par. 1 ===
// Il lettore del click e la coda del motore ridotti a quello che conta per la catena (`ChainRig`): i buffer programmati e
// non ancora richiamati, ognuno con la sua generazione; `isRunning`; il drenaggio di fine sezione; la generazione corrente,
// gli scarti e le loro righe. Le aperture stanno dove le mette il motore: `startMotor` (accanto a `isRunning = true` in
// `start()`), `startChain` (prima dei tre buffer di ogni catena: ripresa, standalone/Direttore, fuoco dell'ingresso, fuoco
// del rientro, `kickScheduling`). `stop` è lo stop del lettore sulla coda: toglie i buffer, e i loro richiami il banco li
// consegna quando vuole (subito, o in ritardo dopo un avvio). `opensAtMotorStart` falso è il disegno del mandato prima
// della risposta del referee (le sole catene): il banco vede la finestra del referto A420, §1.

/// Un buffer nel lettore: la generazione con cui è stato programmato, e se è il buffer ancorato del rientro.
private struct RigBuffer: Equatable {
    let generation: Int
    let anchored: Bool
}

/// Il lettore del click e la coda del motore, per la catena.
private struct ChainRig {
    var opensAtMotorStart = true
    /// Fine dell'ultima sezione: il primo richiamo che arriva a motore in moto non programma niente e chiude il drenaggio.
    var drainPending = false
    private(set) var running = false
    private(set) var chainStarted = false
    private(set) var current = BufferChainGeneration.initial
    private(set) var discarded = 0
    private(set) var discardLines = 0
    private(set) var anchoredLines = 0
    /// I buffer programmati a motore in moto prima della prima catena dell'avvio: devono restare zero.
    private(set) var scheduledBeforeChain = 0
    /// I buffer nel lettore, dal più vecchio.
    private(set) var queued: [RigBuffer] = []

    /// `start()`: il motore parte e `isRunning` diventa vero.
    mutating func startMotor() {
        precondition(!running)
        running = true
        chainStarted = false
        if opensAtMotorStart {
            current = BufferChainGeneration.opened(after: current)
        }
    }

    /// Una catena che comincia: una generazione nuova, poi tre buffer.
    mutating func startChain(anchoredFirst: Bool = false) {
        precondition(running)
        current = BufferChainGeneration.opened(after: current)
        chainStarted = true
        scheduleNext(anchored: anchoredFirst)
        scheduleNext(anchored: false)
        scheduleNext(anchored: false)
    }

    /// `scheduleNextBuffer`: prima la guardia di `isRunning`, poi il drenaggio.
    mutating func scheduleNext(anchored: Bool = false) {
        guard running else { return }
        if drainPending {
            drainPending = false
            return
        }
        if !chainStarted {
            scheduledBeforeChain += 1
        }
        queued.append(RigBuffer(generation: current, anchored: anchored))
    }

    /// Lo stop del lettore sulla coda (`stopSync` abbassa anche il drenaggio): toglie tutti i buffer e rende quelli tolti,
    /// i cui richiami arrivano dopo.
    mutating func stop() -> [RigBuffer] {
        precondition(running)
        running = false
        drainPending = false
        let removed = queued
        queued = []
        return removed
    }

    /// A421 — le chiusure di fine sezione consegnate dagli arresti delle crisi (mandato A421, par. 2.2 j).
    private(set) var drainDeliveries = 0

    /// A421 — l'arresto di una crisi sulla coda (la Lost, il reset, l'inizio di un'interruzione, il modo, la frequenza, le
    /// cuffie, il buco del render, il rientro che non parte): come lo stop, ma un drenaggio aperto si consegna una volta
    /// (la canzone era finita mentre suonava) e si chiude. Uno Stop voluto (`stop`) lo chiude senza consegnarlo.
    mutating func crisisStop() -> [RigBuffer] {
        precondition(running)
        if drainPending {
            drainDeliveries += 1
        }
        return stop()
    }

    /// Il richiamo sulla coda (`bufferCallbackQ`).
    mutating func callback(_ buffer: RigBuffer) {
        guard BufferChainGeneration.accepts(callbackGeneration: buffer.generation, current: current) else {
            discarded += 1
            if BufferChainGeneration.writesDiscardLine(discarded: discarded) {
                discardLines += 1
            }
            return
        }
        if buffer.anchored {
            anchoredLines += 1
        }
        scheduleNext()
    }

    /// Il lettore consuma il buffer più vecchio e il suo richiamo arriva subito, `times` volte.
    mutating func cycle(_ times: Int = 1) {
        for _ in 0..<times {
            guard !queued.isEmpty else { return }
            let buffer = queued.removeFirst()
            callback(buffer)
        }
    }

    /// I buffer in coda della generazione corrente.
    var liveQueued: Int {
        queued.filter { $0.generation == current }.count
    }
}

final class BufferChainGenerationTests: XCTestCase {

    // MARK: - Le regole

    func testInitialAndOpened() {
        XCTAssertEqual(BufferChainGeneration.initial, 0)
        XCTAssertEqual(BufferChainGeneration.opened(after: 0), 1)
        XCTAssertEqual(BufferChainGeneration.opened(after: 41), 42)
        // Una generazione nuova non è mai uguale a quella di prima, neanche al bordo dell'intero.
        XCTAssertNotEqual(BufferChainGeneration.opened(after: Int.max), Int.max)
    }

    func testOnlyTheCurrentGenerationIsAccepted() {
        XCTAssertTrue(BufferChainGeneration.accepts(callbackGeneration: 7, current: 7))
        XCTAssertFalse(BufferChainGeneration.accepts(callbackGeneration: 6, current: 7))
        XCTAssertFalse(BufferChainGeneration.accepts(callbackGeneration: 8, current: 7))
    }

    /// «La prima volta, poi una ogni dieci» (mandato A420, par. 2.2; scelta 3 del referto A420).
    func testTheDiscardLineFirstThenEveryTen() {
        let written = (0...35).filter { BufferChainGeneration.writesDiscardLine(discarded: $0) }
        XCTAssertEqual(written, [1, 11, 21, 31])
        XCTAssertEqual(BufferChainGeneration.discardLineEvery, 10)
    }

    // MARK: - La catena

    /// Il richiamo della stessa catena, accettato: la catena resta di tre buffer, nessuno scarto.
    func testTheSameChainIsAccepted() {
        var rig = ChainRig()
        rig.startMotor()
        rig.startChain()
        rig.cycle(50)
        XCTAssertEqual(rig.queued.count, 3)
        XCTAssertEqual(rig.liveQueued, 3)
        XCTAssertEqual(rig.discarded, 0)
    }

    /// Il richiamo dopo un avvio nuovo, scartato: uno Stop e un Play vicinissimi, coi richiami dello stop consegnati dopo
    /// l'avvio (ripresa o ramo standalone/Direttore). Senza la generazione la catena diventerebbe di sei buffer.
    func testACallbackAfterAFreshStartIsDiscarded() {
        var rig = ChainRig()
        rig.startMotor()
        rig.startChain()
        rig.cycle(5)
        let removed = rig.stop()
        XCTAssertEqual(removed.count, 3)
        rig.startMotor()
        rig.startChain()
        for buffer in removed {
            rig.callback(buffer)
        }
        XCTAssertEqual(rig.discarded, 3)
        XCTAssertEqual(rig.discardLines, 1)
        XCTAssertEqual(rig.queued.count, 3)
        rig.cycle(30)
        XCTAssertEqual(rig.queued.count, 3)
        XCTAssertEqual(rig.liveQueued, 3)
    }

    /// I richiami dello stop consegnati prima dell'avvio dopo (l'arresto sulla coda, mandato A420 par. 2.1): passano la
    /// generazione ma trovano `isRunning` falso e non programmano niente; nessuno scarto.
    func testCallbacksOfTheStopBeforeTheNextStartDoNothing() {
        var rig = ChainRig()
        rig.startMotor()
        rig.startChain()
        rig.cycle(4)
        let removed = rig.stop()
        for buffer in removed {
            rig.callback(buffer)
        }
        XCTAssertEqual(rig.discarded, 0)
        XCTAssertTrue(rig.queued.isEmpty)
        rig.startMotor()
        rig.startChain()
        XCTAssertEqual(rig.queued.count, 3)
        XCTAssertEqual(rig.liveQueued, 3)
    }

    /// Avvii ripetuti (la prova 2a.10: cinque Play e Stop entro 1,5 s): i richiami di ogni stop arrivano dopo l'avvio
    /// seguente. La catena resta di tre buffer, gli scarti si contano tutti, e le righe sono al primo e all'undicesimo.
    func testRepeatedStarts() {
        var rig = ChainRig()
        var late: [RigBuffer] = []
        for _ in 0..<5 {
            rig.startMotor()
            rig.startChain()
            for buffer in late {
                rig.callback(buffer)
            }
            XCTAssertEqual(rig.queued.count, 3)
            rig.cycle(2)
            late = rig.stop()
        }
        rig.startMotor()
        rig.startChain()
        for buffer in late {
            rig.callback(buffer)
        }
        XCTAssertEqual(rig.discarded, 15)
        XCTAssertEqual(rig.discardLines, 2)
        XCTAssertEqual(rig.queued.count, 3)
        XCTAssertEqual(rig.liveQueued, 3)
    }

    /// La finestra dell'ingresso del Follower (referto A420, §1; risposta del referee, par. 1): il motore parte e la catena
    /// comincia al fuoco. Un richiamo della catena di prima arrivato nell'attesa si scarta, e prima del fuoco non parte
    /// niente.
    func testAFollowerJoinWaitDiscardsTheOldChain() {
        var rig = ChainRig()
        rig.startMotor()
        rig.startChain()
        rig.cycle(6)
        let removed = rig.stop()
        rig.startMotor()
        for buffer in removed {
            rig.callback(buffer)
        }
        XCTAssertEqual(rig.discarded, 3)
        XCTAssertEqual(rig.scheduledBeforeChain, 0)
        XCTAssertTrue(rig.queued.isEmpty)
        rig.startChain()
        XCTAssertEqual(rig.queued.count, 3)
        rig.cycle(20)
        XCTAssertEqual(rig.queued.count, 3)
        XCTAssertEqual(rig.liveQueued, 3)
    }

    /// Lo stesso col disegno di prima della risposta del referee (le sole catene): il richiamo vecchio nell'attesa passa e
    /// fa partire una catena prima del fuoco, che vive fino al fuoco; al fuoco la sua continuazione si scarta, ma il suo
    /// buffer è già in coda davanti ai tre nuovi. È la finestra del referto A420, §1: il banco la vede.
    func testWithoutTheMotorStartGenerationTheJoinWaitLeaks() {
        var rig = ChainRig()
        rig.opensAtMotorStart = false
        rig.startMotor()
        rig.startChain()
        rig.cycle(6)
        let removed = rig.stop()
        rig.startMotor()
        rig.callback(removed[0])
        XCTAssertEqual(rig.discarded, 0)
        XCTAssertEqual(rig.scheduledBeforeChain, 1)
        XCTAssertEqual(rig.queued.count, 1)
        rig.cycle(5)
        XCTAssertEqual(rig.scheduledBeforeChain, 6)
        rig.startChain()
        XCTAssertEqual(rig.queued.count, 4)
        XCTAssertEqual(rig.liveQueued, 3)
        rig.cycle(1)
        XCTAssertEqual(rig.discarded, 1)
        XCTAssertEqual(rig.queued.count, 3)
    }

    /// La finestra del rientro del Direttore: il motore parte muto e la catena comincia al fuoco, col primo buffer ancorato.
    /// Il richiamo vecchio nell'attesa si scarta; il buffer ancorato scrive la sua riga al consumo, e la catena va avanti.
    func testADirectorRejoinWaitDiscardsTheOldChain() {
        var rig = ChainRig()
        rig.startMotor()
        rig.startChain()
        rig.cycle(9)
        let removed = rig.stop()
        rig.startMotor()
        for buffer in removed {
            rig.callback(buffer)
        }
        XCTAssertEqual(rig.discarded, 3)
        XCTAssertEqual(rig.scheduledBeforeChain, 0)
        rig.startChain(anchoredFirst: true)
        XCTAssertTrue(rig.queued[0].anchored)
        rig.cycle(1)
        XCTAssertEqual(rig.anchoredLines, 1)
        XCTAssertEqual(rig.queued.count, 3)
        XCTAssertFalse(rig.queued.contains { $0.anchored })
    }

    /// Il primo buffer ancorato di un rientro che si ferma prima di uscire: dopo l'avvio seguente il suo richiamo si
    /// scarta tutto, riga del consumo compresa (scelta 4 del referto A420).
    func testTheAnchoredBufferOfAnEndedRejoinIsDiscardedWhole() {
        var rig = ChainRig()
        rig.startMotor()
        rig.startChain(anchoredFirst: true)
        let removed = rig.stop()
        rig.startMotor()
        rig.startChain()
        for buffer in removed {
            rig.callback(buffer)
        }
        XCTAssertEqual(rig.discarded, 3)
        XCTAssertEqual(rig.anchoredLines, 0)
        XCTAssertEqual(rig.queued.count, 3)
    }

    /// La fine di sezione col drenaggio e più richiami in volo (Aperto 3 del referto A420): il richiamo che entra nel
    /// drenaggio non programma, gli altri continuano, e la catena va avanti con due buffer. Con `kickScheduling` (oggi
    /// senza chiamanti) i tre nuovi sono una catena nuova, e i due vecchi si scartano al loro consumo: tre buffer, non
    /// cinque.
    func testTheDrainWithCallbacksInFlightAndKickScheduling() {
        var rig = ChainRig()
        rig.startMotor()
        rig.startChain()
        rig.cycle(7)
        rig.drainPending = true
        rig.cycle(1)
        XCTAssertEqual(rig.queued.count, 2)
        rig.cycle(10)
        XCTAssertEqual(rig.queued.count, 2)
        XCTAssertEqual(rig.discarded, 0)
        rig.startChain()
        XCTAssertEqual(rig.queued.count, 5)
        XCTAssertEqual(rig.liveQueued, 3)
        rig.cycle(2)
        XCTAssertEqual(rig.discarded, 2)
        XCTAssertEqual(rig.queued.count, 3)
        rig.cycle(10)
        XCTAssertEqual(rig.queued.count, 3)
        XCTAssertEqual(rig.liveQueued, 3)
    }

    /// A421 — un arresto di crisi che trova il drenaggio aperto consegna la chiusura di fine sezione una volta e lo chiude;
    /// uno Stop voluto lo chiude senza consegnarla; e l'avvio dopo non trova un drenaggio vecchio (mandato A421, par. 2.2 j;
    /// referto A420, Aperto 9).
    func testACrisisStopDeliversTheDrainOnceAndAWantedStopDoesNot() {
        var crisis = ChainRig()
        crisis.startMotor()
        crisis.startChain()
        crisis.cycle(7)
        crisis.drainPending = true
        let removed = crisis.crisisStop()
        XCTAssertEqual(crisis.drainDeliveries, 1)
        XCTAssertFalse(crisis.drainPending)
        XCTAssertEqual(removed.count, 3)
        // Il drenaggio già entrato prima della crisi: niente da consegnare.
        var entered = ChainRig()
        entered.startMotor()
        entered.startChain()
        entered.cycle(7)
        entered.drainPending = true
        entered.cycle(1)
        _ = entered.crisisStop()
        XCTAssertEqual(entered.drainDeliveries, 0)
        // Lo Stop voluto: chiude senza consegnare.
        var wanted = ChainRig()
        wanted.startMotor()
        wanted.startChain()
        wanted.drainPending = true
        _ = wanted.stop()
        XCTAssertEqual(wanted.drainDeliveries, 0)
        XCTAssertFalse(wanted.drainPending)
        // Nessun avvio dopo una crisi trova un drenaggio vecchio: i tre buffer nuovi si programmano tutti.
        crisis.startMotor()
        crisis.startChain()
        XCTAssertEqual(crisis.queued.count, 3)
        XCTAssertEqual(crisis.liveQueued, 3)
        crisis.cycle(10)
        XCTAssertEqual(crisis.queued.count, 3)
    }

    /// Le due salite nello stesso blocco (ripresa e ramo standalone/Direttore): con la sola salita della catena o con tutte
    /// e due, gli stessi buffer e gli stessi scarti.
    func testTwoOpeningsInTheSameBlockChangeNothing() {
        func run(_ opensAtMotorStart: Bool) -> [Int] {
            var rig = ChainRig()
            rig.opensAtMotorStart = opensAtMotorStart
            rig.startMotor()
            rig.startChain()
            rig.cycle(3)
            let removed = rig.stop()
            rig.startMotor()
            rig.startChain()
            for buffer in removed {
                rig.callback(buffer)
            }
            rig.cycle(5)
            return [rig.queued.count, rig.liveQueued, rig.discarded, rig.discardLines, rig.scheduledBeforeChain]
        }
        XCTAssertEqual(run(false), run(true))
        XCTAssertEqual(run(true), [3, 3, 3, 1, 0])
    }

    // MARK: - Tutte le sequenze brevi

    /// Gli eventi del banco esaustivo.
    private enum Event: CaseIterable {
        /// `start()` con la sua catena nello stesso blocco (ripresa, standalone/Direttore).
        case freshStart
        /// `start()` dell'ingresso o del rientro: il motore parte, la catena al fuoco.
        case waitStart
        /// Il fuoco dell'ingresso o del rientro.
        case fire
        /// Lo stop sulla coda: i richiami dei buffer tolti vanno fra quelli in ritardo.
        case stop
        /// Il lettore consuma un buffer e il suo richiamo arriva subito.
        case cycle
        /// Arriva il più vecchio dei richiami in ritardo.
        case late
        /// Fine dell'ultima sezione: il prossimo richiamo entra nel drenaggio (una volta per avvio).
        case drain
    }

    /// Il banco esaustivo: il rig, i richiami in ritardo, il fuoco atteso, il drenaggio dell'avvio.
    private struct Explorer {
        var rig = ChainRig()
        var late: [RigBuffer] = []
        var firePending = false
        var drained = false

        func allowed(_ event: Event) -> Bool {
            switch event {
            case .freshStart, .waitStart:
                return !rig.running
            case .fire:
                return rig.running && firePending
            case .stop:
                return rig.running
            case .cycle:
                return !rig.queued.isEmpty
            case .late:
                return !late.isEmpty
            case .drain:
                return rig.running && rig.chainStarted && !drained
            }
        }

        mutating func apply(_ event: Event) {
            switch event {
            case .freshStart:
                rig.startMotor()
                rig.startChain()
                drained = false
            case .waitStart:
                rig.startMotor()
                firePending = true
                drained = false
            case .fire:
                rig.startChain()
                firePending = false
            case .stop:
                late.append(contentsOf: rig.stop())
                firePending = false
            case .cycle:
                rig.cycle(1)
            case .late:
                rig.callback(late.removeFirst())
            case .drain:
                rig.drainPending = true
                drained = true
            }
        }

        /// Gli invarianti dopo un evento: nessun buffer prima della catena; in coda solo buffer della generazione corrente;
        /// a motore fermo, o in attesa del fuoco, coda vuota; a catena viva tre buffer, due dopo il drenaggio; un richiamo
        /// in ritardo non programma niente.
        func holds(after event: Event, queuedBefore: Int) -> Bool {
            if rig.scheduledBeforeChain != 0 {
                return false
            }
            if !rig.queued.allSatisfy({ $0.generation == rig.current }) {
                return false
            }
            if !rig.running || !rig.chainStarted {
                if !rig.queued.isEmpty {
                    return false
                }
            } else {
                let expected = (drained && !rig.drainPending) ? 2 : 3
                if rig.queued.count != expected {
                    return false
                }
            }
            if event == .late && rig.queued.count != queuedBefore {
                return false
            }
            return true
        }
    }

    private struct Tally: Equatable {
        var sequences = 0
        var violating = 0
        var discarded = 0
    }

    private func explore(_ explorer: Explorer, depth: Int, violated: Bool, tally: inout Tally) {
        if depth == 0 {
            tally.sequences += 1
            tally.violating += violated ? 1 : 0
            tally.discarded += explorer.rig.discarded
            return
        }
        for event in Event.allCases where explorer.allowed(event) {
            var next = explorer
            let queuedBefore = next.rig.queued.count
            next.apply(event)
            let ok = next.holds(after: event, queuedBefore: queuedBefore)
            explore(next, depth: depth - 1, violated: violated || !ok, tally: &tally)
        }
    }

    /// Tutte le sequenze di dieci eventi, dall'app appena aperta: con la generazione anche all'avvio del motore nessuna
    /// rompe un invariante, e gli scarti ci sono (la guardia lavora). Col disegno di prima della risposta del referee una
    /// parte le rompe: è la finestra. I conti vengono dal modello Python del referto A420 (stesse regole, stessi eventi);
    /// senza la risposta le sequenze sono di più, perché la catena abusiva rende possibili giri del lettore in più.
    func testAllShortSequences() {
        var withAnswer = Tally()
        explore(Explorer(), depth: 10, violated: false, tally: &withAnswer)
        var before = Explorer()
        before.rig.opensAtMotorStart = false
        var withoutAnswer = Tally()
        explore(before, depth: 10, violated: false, tally: &withoutAnswer)

        XCTAssertEqual(withAnswer.violating, 0)
        XCTAssertGreaterThan(withAnswer.discarded, 0)
        XCTAssertGreaterThan(withoutAnswer.violating, 0)
        XCTAssertEqual(withAnswer, Tally(sequences: 37713, violating: 0, discarded: 53497))
        XCTAssertEqual(withoutAnswer, Tally(sequences: 41141, violating: 8285, discarded: 47872))
    }
}
