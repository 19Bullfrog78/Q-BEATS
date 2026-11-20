import XCTest

// === A437 — banco della ripresa del Solo sulla canzone (`SoloResumeDecision`, banco Models) ===
// Mandato A437, par. 3 (commit 1) e seguito 1, voce 6; referto A424, par. 2.1 a-g, 3.1 b «Banco».
// Le canzoni sono quelle della scaletta di prova «COLLAUDO 3B» (mandato, par. 4 f): «1 Two sections» (4/4 a 121,5 per
// 16 battute, poi 4/4 a 91,5 per 16), «3 Short» (4/4 a 131,5 per 4), «5 Odd meter» (7/8 a 161,5 per 8, poi 4/4 a
// 121,5 per 8); più una canzone piatta a 120 per i bordi del margine e una con un ciclo in mezzo.
// 24.000.000 tick al secondo; l'ora dell'àncora di tutti i casi è 100 s. Gli attesi sono numeri scritti per esteso,
// rifatti a parte col modello Python del mandato (non ricavati dal tipo).

final class SoloResumeDecisionTests: XCTestCase {

    private let tps = 24_000_000.0
    private let anchorTicks: UInt64 = 2_400_000_000

    private let twoSections = SongMap(sections: [
        SongMapSection(beatsPerBar: 4, repetitions: 16, bpm: 121.5),
        SongMapSection(beatsPerBar: 4, repetitions: 16, bpm: 91.5),
    ])
    private let short = SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 4, bpm: 131.5)])
    private let oddMeter = SongMap(sections: [
        SongMapSection(beatsPerBar: 7, repetitions: 8, bpm: 161.5),
        SongMapSection(beatsPerBar: 4, repetitions: 8, bpm: 121.5),
    ])
    private let withCycle = SongMap(sections: [
        SongMapSection(beatsPerBar: 4, repetitions: 2, bpm: 120),
        SongMapSection(beatsPerBar: 4, repetitions: 0, bpm: 120),
        SongMapSection(beatsPerBar: 4, repetitions: 2, bpm: 120),
    ])
    private let flat = SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 8, bpm: 120)])

    private func ticks(afterAnchor seconds: Double) -> UInt64 {
        anchorTicks + UInt64((seconds * tps).rounded())
    }

    private func clock(_ map: SongMap, section: Int, beat: Int) -> ShowClock {
        ShowClock(map: map, anchor: ShowClockAnchor(section: section, beatInSection: beat, linkBeat: 0, ticks: anchorTicks))
    }

    private func plan(_ clock: ShowClock?, after seconds: Double, margin: Double = 0.150) -> SoloResumePlan {
        SoloResumeDecision.plan(clock: clock, nowTicks: ticks(afterAnchor: seconds), ticksPerSecond: tps, marginSeconds: margin)
    }

    private func aim(_ section: Int, _ bar: Int, _ beat: Int, _ target: UInt64, _ uno: Double) -> SoloResumePlan {
        .resume(SoloResumeAim(section: section, bar: bar, beatInSection: beat, targetTicks: target, unoBeat: uno))
    }

    // MARK: - Il Solo «in moto per il player» (P35)

    func testInMotionForThePlayerIsTheEngineOrThePause() {
        XCTAssertFalse(SoloResumeDecision.inMotionForPlayer(engineRunning: false, resumePending: false))
        XCTAssertTrue(SoloResumeDecision.inMotionForPlayer(engineRunning: true, resumePending: false))
        XCTAssertTrue(SoloResumeDecision.inMotionForPlayer(engineRunning: false, resumePending: true), "la pausa della ripresa")
        XCTAssertTrue(SoloResumeDecision.inMotionForPlayer(engineRunning: true, resumePending: true))
    }

    // MARK: - L'àncora

    private func take(role: PlayerRole = .solo, show: Bool = true, song: Bool = true, stopping: Bool = false,
                      running: Bool = true, drain: Bool = false, alive: Bool = false, map: Bool = true,
                      counted: Bool = true, cycle: Bool = false) -> SoloAnchorTake {
        SoloResumeDecision.anchorTake(playerRole: role, showOpen: show, songInProgress: song,
                                      stoppingCauseRemembered: stopping, engineRunning: running, drainOpen: drain,
                                      anchorAlive: alive, mapValid: map, countedBeatOut: counted, beatInCycle: cycle)
    }

    /// Con una causa che ferma il Solo già ricordata (la tolta e il cambio di modo nello stesso blocco: una scheda USB
    /// staccata) il Solo si sta fermando come la console: l'àncora non si prende e una viva non fa aspettare la ripresa,
    /// col motore in moto, fermo, o col drenaggio aperto.
    func testWithAStoppingCauseRememberedTheResumeDoesNotBegin() {
        XCTAssertEqual(take(stopping: true), .notTaken(.stoppingCause))
        XCTAssertEqual(take(stopping: true, alive: true), .notTaken(.stoppingCause), "nella pausa: lo stacco e poi il modo")
        XCTAssertEqual(take(stopping: true, running: false, alive: true), .notTaken(.stoppingCause))
        XCTAssertEqual(take(stopping: true, drain: true), .notTaken(.stoppingCause))
        XCTAssertEqual(take(song: false, stopping: true), .notTaken(.noSong), "ruolo, show e canzone vengono prima")
        XCTAssertFalse(SoloAnchorTake.notTaken(.stoppingCause).resumeWaits)
        XCTAssertEqual(SoloAnchorRefusal.stoppingCause.rawValue, "il-solo-si-ferma-come-la-console")
    }

    /// Solo, show aperto, canzone in corso, motore in moto, mappa valida, un battito contato già uscito, fuori da un
    /// ciclo: presa. Ogni condizione che manca dà il suo motivo.
    func testTheAnchorIsTakenOnlyWithEveryConditionAndEachMissingOneHasItsReason() {
        XCTAssertEqual(take(), .taken)
        XCTAssertEqual(take(role: .direttore), .notTaken(.notSolo))
        XCTAssertEqual(take(role: .follower), .notTaken(.notSolo))
        XCTAssertEqual(take(show: false), .notTaken(.showClosed))
        XCTAssertEqual(take(song: false), .notTaken(.noSong))
        XCTAssertEqual(take(running: false), .notTaken(.engineStopped))
        XCTAssertEqual(take(map: false), .notTaken(.noMap))
        XCTAssertEqual(take(counted: false), .notTaken(.noCountedBeat), "il click fermato subito dopo il Play")
        XCTAssertEqual(take(cycle: true), .notTaken(.cycle))
    }

    /// L'ordine dei motivi quando ne mancano più d'una: ruolo, show, canzone, motore, mappa, battito, ciclo.
    func testTheOrderOfTheRefusals() {
        XCTAssertEqual(take(role: .direttore, show: false, song: false, running: false), .notTaken(.notSolo))
        XCTAssertEqual(take(show: false, song: false, running: false), .notTaken(.showClosed))
        XCTAssertEqual(take(song: false, running: false, map: false), .notTaken(.noSong))
        XCTAssertEqual(take(running: false, map: false, counted: false), .notTaken(.engineStopped))
        XCTAssertEqual(take(map: false, counted: false, cycle: true), .notTaken(.noMap))
        XCTAssertEqual(take(counted: false, cycle: true), .notTaken(.noCountedBeat))
    }

    /// Un'àncora già viva resta quella: nella pausa (motore fermo), nella scorta e dopo il fuoco (motore in moto).
    func testAnAnchorAlreadyAliveStays() {
        XCTAssertEqual(take(running: false, alive: true), .alreadyAlive, "una crisi nuova nella pausa")
        XCTAssertEqual(take(running: true, alive: true), .alreadyAlive, "una crisi nuova nella scorta o dopo il fuoco")
        XCTAssertEqual(take(running: false, alive: true, map: false, counted: false), .alreadyAlive,
                       "nella pausa i battiti contati sono azzerati: l'ancora viva basta")
        XCTAssertTrue(SoloAnchorTake.alreadyAlive.resumeWaits)
        XCTAssertTrue(SoloAnchorTake.taken.resumeWaits)
    }

    /// Seguito 1, voce 6 — col drenaggio aperto l'àncora non si prende, anche se un'àncora è ancora viva (tenuta dalla
    /// ripresa): il controllo del drenaggio viene prima di «già viva», e la canzone finisce come finita suonando.
    func testTheOpenDrainComesBeforeTheAnchorAlreadyAlive() {
        XCTAssertEqual(take(drain: true), .drainDelivered)
        XCTAssertEqual(take(drain: true, alive: true), .drainDelivered, "ancora viva tenuta dalla ripresa e drenaggio aperto")
        XCTAssertEqual(take(drain: true, alive: true, map: false, counted: false, cycle: true), .drainDelivered)
        XCTAssertFalse(SoloAnchorTake.drainDelivered.resumeWaits)
        XCTAssertFalse(SoloAnchorTake.notTaken(.noCountedBeat).resumeWaits)
        // A motore fermo il drenaggio non è aperto (l'ha chiuso l'arresto): se il valore arrivasse alto non conta.
        XCTAssertEqual(take(running: false, drain: true, alive: true), .alreadyAlive)
        XCTAssertEqual(take(running: false, drain: true), .notTaken(.engineStopped))
        // Il ruolo, lo show e la canzone vengono prima anche del drenaggio.
        XCTAssertEqual(take(song: false, drain: true, alive: true), .notTaken(.noSong))
    }

    // MARK: - Δ

    // MARK: - Δ, la regola nuova (A437 · SEGUITO 5, par. 2.1-2.3)
    //
    // I tick sono quelli del telefono, 24.000.000 al secondo. Il buffer del lettore (512 campioni) a 48 kHz vale 256.000
    // tick nel conto esatto e 255.999 nella conversione del motore, che tronca; a 44,1 kHz 278.639. Le misure del
    // telefono (referto A437, par. 45-46): l'ora dell'ultimo render sta circa 22,9 ms dopo adesso (a), e ψ, il posto
    // dell'inizio del rendering del buffer di confronto dentro il ciclo, fra 0,19 e 10,56 ms.

    /// I secondi in tick come li conta il motore (`secondsToMachTicks`, con la base dei tempi del telefono, 125/3): i
    /// nanosecondi troncati, poi per 3 diviso 125.
    private func machTicks(_ seconds: Double) -> UInt64 { UInt64(seconds * 1_000_000_000.0) * 3 / 125 }

    private func gate(wanted: Int = 3, inMemory: Bool = true, cycle: UInt64 = 256_000, rate: Double = 48_000,
                      ticksPerSecond: Double = 24_000_000, frames: Int = 512) -> SoloDeltaDiscard? {
        SoloResumeDecision.deltaReadingGate(wantedIndex: wanted, wantedInChainMemory: inMemory, cycleTicks: cycle,
                                            sampleRate: rate, ticksPerSecond: ticksPerSecond, bufferFrames: frames)
    }

    /// Di base: adesso 10.000.000, l'ultimo render 2,05 cicli dopo (524.800 tick), il ciclo e il buffer 256.000 tick,
    /// la latenza 12,6 ms (302.400), la convenzione 10.000.000: Δ = 10.524.800 − 128.000 + 302.400 − 10.000.000 = 699.200.
    private func reading(render: Bool = true, last: UInt64 = 10_524_800, now: UInt64 = 10_000_000, cycle: UInt64 = 256_000,
                         latency: UInt64 = 302_400, convention: UInt64 = 10_000_000, buffer: UInt64 = 256_000,
                         queued: Int = 2) -> SoloDeltaReadingOutcome {
        SoloResumeDecision.deltaReading(renderTimeValid: render, lastRenderTicks: last, nowTicks: now, cycleTicks: cycle,
                                        latencyTicks: latency, conventionTicks: convention, bufferTicks: buffer,
                                        queuedAheadBuffers: queued)
    }

    /// Il primo passo, prima della lettura di `lastRenderTime`: «avvio», poi «catena», poi «ciclo», un motivo solo.
    func testTheGateBeforeTheReadDiscardsTheStartupBuffersThenTheChainThenTheCycle() {
        XCTAssertEqual(SoloResumeDecision.chainStartBuffers, 3, "tre buffer a ogni catena: due in coda più uno")
        XCTAssertNil(gate(), "il buffer 3, il primo prodotto da un richiamo: si legge")
        // «avvio»: le tre chiamate della partenza (nessun richiamo: 0) e i richiami 1 e 2.
        XCTAssertEqual(gate(wanted: 0), .startup)
        XCTAssertEqual(gate(wanted: 1), .startup)
        XCTAssertEqual(gate(wanted: 2), .startup)
        XCTAssertNil(gate(wanted: 3))
        XCTAssertNil(gate(wanted: 400))
        XCTAssertEqual(gate(wanted: -1), .startup, "un indice che non esiste non si legge")
        // «catena»: il buffer di confronto non è nella memoria della catena corrente.
        XCTAssertEqual(gate(inMemory: false), .chain)
        // «ciclo»: il ciclo d'I/O più lungo del buffer del lettore (1024 campioni contro 512).
        XCTAssertEqual(gate(cycle: 512_000), .cycle)
        XCTAssertNil(gate(cycle: 128_000), "un ciclo di 256 campioni: la regola si applica")
        // L'ordine: il primo che cade.
        XCTAssertEqual(gate(wanted: 2, inMemory: false, cycle: 512_000), .startup)
        XCTAssertEqual(gate(wanted: 3, inMemory: false, cycle: 512_000), .chain)
        XCTAssertEqual(gate(wanted: 3, inMemory: true, cycle: 512_000), .cycle)
    }

    /// Il confronto del ciclo col buffer si fa in campioni interi, con la metà verso l'alto, non in tick: ai bordi.
    func testTheCycleIsComparedWithTheBufferInWholeFramesNotInTicks() {
        func longer(_ cycle: UInt64, rate: Double = 48_000, tps: Double = 24_000_000, frames: Int = 512) -> Bool {
            SoloResumeDecision.cycleLongerThanBuffer(cycleTicks: cycle, sampleRate: rate, ticksPerSecond: tps,
                                                     bufferFrames: frames)
        }
        // Sul telefono il buffer del lettore vale 255.999 tick (la conversione tronca), non i 256.000 del conto esatto.
        XCTAssertEqual(machTicks(512.0 / 48_000.0), 255_999)
        // 512 campioni: non «ciclo», nel conto esatto e in quello del telefono (511,998 campioni: 512).
        XCTAssertFalse(longer(256_000))
        XCTAssertFalse(longer(255_999))
        // 512,0001 campioni: in tick 256.000 contro i 255.999 del buffer (in tick sembrerebbe più lungo); in campioni 512.
        XCTAssertEqual(machTicks(512.0001 / 48_000.0), 256_000)
        XCTAssertGreaterThan(machTicks(512.0001 / 48_000.0), machTicks(512.0 / 48_000.0), "in tick il ciclo sembra piu' lungo")
        XCTAssertFalse(longer(machTicks(512.0001 / 48_000.0)), "in campioni interi non lo e'")
        // 512,5 campioni esatti (256.250 tick): la metà va verso l'alto, 513: «ciclo». Un tick sotto (512,498): 512.
        XCTAssertTrue(longer(256_250))
        XCTAssertFalse(longer(256_249))
        XCTAssertEqual(machTicks(512.5 / 48_000.0), 256_249, "la conversione del motore tronca: 512,5 campioni arrivano come 512,498")
        // 512,6 e 513 campioni: «ciclo».
        XCTAssertEqual(machTicks(512.6 / 48_000.0), 256_299)
        XCTAssertTrue(longer(machTicks(512.6 / 48_000.0)))
        XCTAssertEqual(machTicks(513.0 / 48_000.0), 256_500)
        XCTAssertTrue(longer(machTicks(513.0 / 48_000.0)))
        // 44,1 kHz: 512 campioni (278.639 tick) no; 1024 sì; 256 no.
        XCTAssertEqual(machTicks(512.0 / 44_100.0), 278_639)
        XCTAssertFalse(longer(278_639, rate: 44_100))
        XCTAssertTrue(longer(557_278, rate: 44_100))
        XCTAssertFalse(longer(139_319, rate: 44_100))
        // Senza un valore la conversione non si fa: «ciclo» (nessuna divisione per zero, nessun intero da un infinito).
        XCTAssertTrue(longer(0), "il ciclo a zero, prima del primo avvio")
        XCTAssertTrue(longer(256_000, rate: 0))
        XCTAssertTrue(longer(256_000, tps: 0))
        XCTAssertTrue(longer(256_000, rate: .infinity))
        XCTAssertTrue(longer(256_000, rate: .nan))
        XCTAssertTrue(longer(256_000, tps: .infinity))
        XCTAssertTrue(longer(256_000, tps: 1e-300), "un numero di campioni non finito")
    }

    /// Il secondo passo: una lettura vale col render avanti di al più tre cicli e Δ dentro i limiti. Sono le condizioni
    /// della prova di prima («le quattro condizioni» di A424 par. 2.1 g, tolta con la regola vecchia), riscritte con la
    /// regola nuova: il render nel futuro è la lettura valida, il render indietro quella scartata.
    func testAReadingIsValidOnlyWithTheRenderAheadWithinThreeCyclesAndDeltaInsideTheLimits() {
        // Il render nel futuro di 2,05 cicli: la lettura vale, e Δ = (L − ciclo/2 + latenza) − la convenzione.
        XCTAssertEqual(reading(), .valid(deltaTicks: 699_200), "un render nel futuro: la lettura valida")
        // «render»: l'ora dell'ultimo render non valida.
        XCTAssertEqual(reading(render: false), .discarded(.render, deltaTicks: nil))
        // «indietro»: L prima di adesso, anche di un tick e di un millisecondo (il render fermo o in ritardo).
        XCTAssertEqual(reading(last: 9_999_999), .discarded(.behind, deltaTicks: nil), "un tick")
        XCTAssertEqual(reading(last: 9_976_000), .discarded(.behind, deltaTicks: nil), "un millisecondo")
        XCTAssertEqual(reading(last: 5_000_000), .discarded(.behind, deltaTicks: nil), "il render fermo da tempo")
        XCTAssertEqual(reading(last: 10_000_000), .valid(deltaTicks: 174_400), "L uguale ad adesso: non e' indietro")
        // «avanti»: il tetto di tre cicli, ai bordi.
        XCTAssertEqual(reading(last: 10_768_000), .valid(deltaTicks: 942_400), "tre cicli esatti")
        XCTAssertEqual(reading(last: 10_768_001), .discarded(.ahead, deltaTicks: nil), "un tick oltre i tre cicli")
        XCTAssertEqual(SoloResumeDecision.deltaRenderAheadCycles, 3)
        // «limiti»: -1 ciclo <= Δ <= (buffer in coda + 2) x un buffer, ai bordi; con «limiti» torna la Δ calcolata.
        XCTAssertEqual(reading(convention: 10_955_200), .valid(deltaTicks: -256_000))
        XCTAssertEqual(reading(convention: 10_955_201), .discarded(.limits, deltaTicks: -256_001))
        XCTAssertEqual(reading(convention: 9_675_200), .valid(deltaTicks: 1_024_000), "quattro buffer con due in coda")
        XCTAssertEqual(reading(convention: 9_675_199), .discarded(.limits, deltaTicks: 1_024_001))
        XCTAssertEqual(reading(convention: 10_699_200), .valid(deltaTicks: 0))
        XCTAssertEqual(reading(queued: -1), .discarded(.limits, deltaTicks: 699_200))
        XCTAssertEqual(OutputReturnDecision.queuedAheadBuffers, 2)
        // Senza la latenza la Δ cambia della latenza: la regola la somma.
        XCTAssertEqual(reading(latency: 0), .valid(deltaTicks: 396_800))
        // Il mezzo ciclo è quello del ciclo d'I/O, non del buffer: col ciclo di 256 campioni Δ cambia di un quarto di buffer.
        XCTAssertEqual(reading(last: 10_262_400, cycle: 128_000), .valid(deltaTicks: 500_800))
        // L'ordine, un motivo solo: «render» prima di «indietro», «indietro» e «avanti» prima dei «limiti».
        XCTAssertEqual(reading(render: false, last: 9_999_999, convention: 0), .discarded(.render, deltaTicks: nil))
        XCTAssertEqual(reading(last: 9_999_999, convention: 0), .discarded(.behind, deltaTicks: nil))
        XCTAssertEqual(reading(last: 10_768_001, convention: 0), .discarded(.ahead, deltaTicks: nil))
    }

    /// Il conto di Δ coi numeri del telefono. Queste prove dicono che l'aritmetica della regola torna DATI i due fatti
    /// misurati (F1: al richiamo L = l'inizio del rendering del buffer di confronto + ψ; F2: L − adesso = a): non
    /// provano i fatti (nota C1 del verificatore del seguito 4). La prova dei fatti è il WAV del collaudo C6.
    func testDeltaWithTheNumbersOfThePhoneIsTwoBuffersPlusTheAdvanceMinusOneCycleAndAHalf() {
        // Il richiamo n (n da 3): il buffer n comincia il rendering a r(n) = n × B; L = r(n) + ψ; adesso = L − a. La
        // convenzione del buffer n è scritta due richiami prima: adesso(n − 2) + latenza + ciclo. L'uscita vera è
        // r(n) + latenza: Δ vero = 2B − ciclo + a − ψ, e la regola dà 2B + a − 3 × ciclo / 2: l'errore è ψ − ciclo / 2.
        func at(buffer: Int64, cycle: Int64, ahead: Int64, phase: Int64, latency: Int64 = 302_400, n: Int64 = 40)
            -> (outcome: SoloDeltaReadingOutcome, read: Int64, error: Int64) {
            let origin: Int64 = 1_000_000_000
            let lastRender = origin + n * buffer + phase
            let now = lastRender - ahead
            let nowTwoCallbacksBefore = origin + (n - 2) * buffer + phase - ahead
            let convention = nowTwoCallbacksBefore + latency + cycle
            let trueDelta = origin + n * buffer + latency - convention
            let read = 2 * buffer + ahead - cycle - cycle / 2
            let outcome = SoloResumeDecision.deltaReading(renderTimeValid: true, lastRenderTicks: UInt64(lastRender),
                                                          nowTicks: UInt64(now), cycleTicks: UInt64(cycle),
                                                          latencyTicks: UInt64(latency), conventionTicks: UInt64(convention),
                                                          bufferTicks: UInt64(buffer), queuedAheadBuffers: 2)
            return (outcome, read, read - trueDelta)
        }
        let ahead: Int64 = 549_600            // a = 22,9 ms
        let phases: [Int64] = [4_560, 127_920, 253_440]   // ψ = 0,19 · 5,33 · 10,56 ms
        // 48 kHz, il ciclo uguale al buffer: Δ letta = a + B/2 = 677.600 tick (28,23 ms), l'errore entro ± mezzo ciclo.
        for phase in phases {
            let got = at(buffer: 256_000, cycle: 256_000, ahead: ahead, phase: phase)
            XCTAssertEqual(got.read, 677_600)
            XCTAssertEqual(got.outcome, .valid(deltaTicks: 677_600), "48 kHz psi:\(phase)")
            XCTAssertEqual(got.error, phase - 128_000, "l'errore e' psi meno mezzo ciclo")
            XCTAssertLessThanOrEqual(abs(got.error), 128_000, "48 kHz psi:\(phase)")
        }
        // Coi 255.999 tick del telefono (ciclo e buffer): un tick e mezzo di differenza, niente di più.
        XCTAssertEqual(at(buffer: 255_999, cycle: 255_999, ahead: ahead, phase: 127_920).outcome, .valid(deltaTicks: 677_600))
        // 44,1 kHz (la cassa Bluetooth), il ciclo uguale al buffer, 278.639 tick: 2B + a − 3 × ciclo / 2 = 688.920 (28,7 ms).
        for phase in phases {
            let got = at(buffer: 278_639, cycle: 278_639, ahead: ahead, phase: phase)
            XCTAssertEqual(got.read, 688_920)
            XCTAssertEqual(got.outcome, .valid(deltaTicks: 688_920), "44,1 kHz psi:\(phase)")
            XCTAssertEqual(got.error, phase - 139_319)
            XCTAssertLessThanOrEqual(abs(got.error), 139_320, "44,1 kHz psi:\(phase)")
        }
        // Il ciclo di 256 campioni col buffer di 512 [Ipotesi del referee: F1 è misurato solo col ciclo uguale al buffer].
        // (i) F1 com'è, a = due cicli (10,67 ms), ψ = 0,2 · 2,67 · 5,2 ms: Δ letta = 576.000 (24 ms), l'errore entro ± mezzo ciclo.
        for phase: Int64 in [4_800, 64_080, 124_800] {
            let got = at(buffer: 256_000, cycle: 128_000, ahead: 256_000, phase: phase)
            XCTAssertEqual(got.outcome, .valid(deltaTicks: 576_000), "256 campioni (i) psi:\(phase)")
            XCTAssertEqual(got.error, phase - 64_000)
            XCTAssertLessThanOrEqual(abs(got.error), 64_000, "256 campioni (i) psi:\(phase)")
        }
        // (ii) F1 spostato di un ciclo, ψ in (ciclo, 2 cicli]: la lettura vale lo stesso, e l'errore va da + mezzo ciclo a
        // + un ciclo e mezzo (da +2,67 a +8,00 ms: l'àncora, e il click, più tardi del vero).
        XCTAssertEqual(at(buffer: 256_000, cycle: 128_000, ahead: 256_000, phase: 128_001).error, 64_001)
        XCTAssertEqual(at(buffer: 256_000, cycle: 128_000, ahead: 256_000, phase: 128_001).outcome, .valid(deltaTicks: 576_000))
        XCTAssertEqual(at(buffer: 256_000, cycle: 128_000, ahead: 256_000, phase: 256_000).error, 192_000)
        XCTAssertEqual(at(buffer: 256_000, cycle: 128_000, ahead: 256_000, phase: 256_000).outcome, .valid(deltaTicks: 576_000))
        // (iii) a che resta 22,9 ms invece di due cicli: oltre il tetto (3 × 5,33 = 16 ms), «avanti», e vale la riserva.
        XCTAssertEqual(at(buffer: 256_000, cycle: 128_000, ahead: ahead, phase: 64_080).outcome, .discarded(.ahead, deltaTicks: nil))
        // (iv) F1 spostato all'indietro, ψ in (−ciclo, 0]: l'errore va da − mezzo ciclo a − un ciclo e mezzo (fino a 8 ms in anticipo).
        XCTAssertEqual(at(buffer: 256_000, cycle: 128_000, ahead: 256_000, phase: 0).error, -64_000)
        XCTAssertEqual(at(buffer: 256_000, cycle: 128_000, ahead: 256_000, phase: -127_999).error, -191_999)
        // La regola rende la stessa Δ qualunque sia ψ (la fase sta tutta nell'errore): le asserzioni su `read` ed `error` qui
        // sopra sono il conto della prova, quelle su `outcome` sono la regola (nota N1 del verificatore V2).
        XCTAssertEqual(at(buffer: 256_000, cycle: 128_000, ahead: 256_000, phase: 0).outcome, .valid(deltaTicks: 576_000))
        XCTAssertEqual(at(buffer: 256_000, cycle: 128_000, ahead: 256_000, phase: -127_999).outcome, .valid(deltaTicks: 576_000))
        // Il ciclo di 1024 campioni: la lettura non arriva a `lastRenderTime`, si scarta col motivo «ciclo».
        XCTAssertEqual(gate(cycle: 512_000), .cycle)
        XCTAssertEqual(gate(cycle: 557_278, rate: 44_100), .cycle)
    }

    /// L'àncora somma Δ solo a un battito di regime (par. 2.3): se no Δ = 0 e la lettura è «avvio», che vince su
    /// «hardware» e su «riserva», con le letture della catena scritte come sono.
    func testTheAnchorAddsDeltaOnlyToABeatOnTheRegimeConvention() {
        XCTAssertEqual(SoloResumeDecision.noDeltaEpoch, -1)
        // Il segno del battito: l'epoca se il suo buffer è prodotto da un richiamo della catena (indice da tre in su).
        XCTAssertEqual(SoloResumeDecision.beatDeltaEpoch(bufferChainIndex: 0, epoch: 7), SoloResumeDecision.noDeltaEpoch)
        XCTAssertEqual(SoloResumeDecision.beatDeltaEpoch(bufferChainIndex: 2, epoch: 7), SoloResumeDecision.noDeltaEpoch)
        XCTAssertEqual(SoloResumeDecision.beatDeltaEpoch(bufferChainIndex: 3, epoch: 7), 7)
        XCTAssertEqual(SoloResumeDecision.beatDeltaEpoch(bufferChainIndex: 46, epoch: 7), 7)
        // Di regime solo col segno dell'epoca di adesso: un battito di prima di un azzeramento non lo è.
        XCTAssertTrue(SoloResumeDecision.beatOnRegimeConvention(beatEpoch: 7, currentEpoch: 7))
        XCTAssertFalse(SoloResumeDecision.beatOnRegimeConvention(beatEpoch: 7, currentEpoch: 8), "prima dell'azzeramento")
        XCTAssertFalse(SoloResumeDecision.beatOnRegimeConvention(beatEpoch: SoloResumeDecision.noDeltaEpoch, currentEpoch: 7))
        XCTAssertFalse(SoloResumeDecision.beatOnRegimeConvention(beatEpoch: SoloResumeDecision.noDeltaEpoch,
                                                                 currentEpoch: SoloResumeDecision.noDeltaEpoch))
        // «Δ o 0».
        let hardware = SoloDelta(ticks: 677_600, readings: 8, fromHardware: true, newestReadTicks: 99)
        XCTAssertEqual(SoloResumeDecision.anchorDelta(fromReadings: hardware, beatOnRegimeConvention: true), hardware)
        let startup = SoloResumeDecision.anchorDelta(fromReadings: hardware, beatOnRegimeConvention: false)
        XCTAssertEqual(startup, SoloDelta(ticks: 0, readings: 8, fromHardware: false, newestReadTicks: 99, beatOffRegime: true))
        XCTAssertEqual(startup.sourceName, "avvio")
        XCTAssertFalse(startup.fromHardware)
        XCTAssertEqual(SoloResumeDecision.anchorTicks(conventionTicks: 1_000, delta: startup), 1_000, "l'ora della convenzione com'e'")
        let reserve = SoloResumeDecision.delta(readings: readings([5, 7]))
        XCTAssertEqual(SoloResumeDecision.anchorDelta(fromReadings: reserve, beatOnRegimeConvention: true).sourceName, "riserva")
        let reserveAtStartup = SoloResumeDecision.anchorDelta(fromReadings: reserve, beatOnRegimeConvention: false)
        XCTAssertEqual(reserveAtStartup.sourceName, "avvio", "avvio vince anche sulla riserva")
        XCTAssertEqual(reserveAtStartup.readings, 2)
        XCTAssertEqual(hardware.sourceName, "hardware")
        XCTAssertFalse(hardware.beatOffRegime, "il valore di base: chi costruisce coi quattro campi di prima non cambia")
    }

    /// I contatori della riga `letture di delta`: un motivo per chiamata, le chiamate sono le valide più le scartate, e
    /// i due «ultimi» sono della chiamata più recente che ha letto un'ora valida.
    func testTheTallyCountsOneReasonPerCallAndKeepsTheLastReadValues() {
        var tally = SoloDeltaTally()
        XCTAssertEqual(tally.lastRenderMinusNowText(ticksPerSecond: 24_000_000), "-")
        XCTAssertEqual(tally.lastDeltaText(ticksPerSecond: 24_000_000), "-")
        for _ in 0..<5 { tally.noteBeforeRead(.startup) }
        XCTAssertEqual(tally.calls, 5)
        XCTAssertEqual(tally.startup, 5)
        XCTAssertEqual(tally.lastRenderMinusNowText(ticksPerSecond: 24_000_000), "-", "nessuna chiamata ha ancora letto")
        tally.noteAfterRead(.valid(deltaTicks: 677_600), renderTimeValid: true, lastRenderTicks: 10_549_600, nowTicks: 10_000_000)
        XCTAssertEqual(tally.valid, 1)
        XCTAssertEqual(tally.lastRenderMinusNowText(ticksPerSecond: 24_000_000), "22.9")
        XCTAssertEqual(tally.lastDeltaText(ticksPerSecond: 24_000_000), "28.2")
        // «indietro»: l'ora letta è valida, Δ non si calcola.
        tally.noteAfterRead(.discarded(.behind, deltaTicks: nil), renderTimeValid: true, lastRenderTicks: 9_976_000, nowTicks: 10_000_000)
        XCTAssertEqual(tally.behind, 1)
        XCTAssertEqual(tally.lastRenderMinusNowText(ticksPerSecond: 24_000_000), "-1.0")
        XCTAssertEqual(tally.lastDeltaText(ticksPerSecond: 24_000_000), "-")
        // «limiti»: Δ si calcola e la riga la scrive.
        tally.noteAfterRead(.discarded(.limits, deltaTicks: 1_100_000), renderTimeValid: true, lastRenderTicks: 10_549_600, nowTicks: 10_000_000)
        XCTAssertEqual(tally.limits, 1)
        XCTAssertEqual(tally.lastDeltaText(ticksPerSecond: 24_000_000), "45.8")
        // «render»: l'ora non valida non tocca i due «ultimi».
        tally.noteAfterRead(.discarded(.render, deltaTicks: nil), renderTimeValid: false, lastRenderTicks: 0, nowTicks: 10_000_000)
        XCTAssertEqual(tally.render, 1)
        XCTAssertEqual(tally.lastRenderMinusNowText(ticksPerSecond: 24_000_000), "22.9")
        XCTAssertEqual(tally.lastDeltaText(ticksPerSecond: 24_000_000), "45.8")
        tally.noteAfterRead(.discarded(.ahead, deltaTicks: nil), renderTimeValid: true, lastRenderTicks: 10_800_000, nowTicks: 10_000_000)
        tally.noteBeforeRead(.chain)
        tally.noteBeforeRead(.cycle)
        XCTAssertEqual(tally.ahead, 1)
        XCTAssertEqual(tally.chain, 1)
        XCTAssertEqual(tally.cycle, 1)
        XCTAssertEqual(tally.lastRenderMinusNowText(ticksPerSecond: 24_000_000), "33.3", "le chiamate fermate prima della lettura non la toccano")
        XCTAssertEqual(tally.lastDeltaText(ticksPerSecond: 24_000_000), "-")
        XCTAssertEqual(tally.calls, 12)
        XCTAssertEqual(tally.discarded, 11)
        XCTAssertEqual(tally.calls, tally.valid + tally.discarded, "chiamate = valide + scartate")
        XCTAssertEqual(tally.lastDeltaText(ticksPerSecond: 0), "-", "senza i tick al secondo niente numero")
        XCTAssertEqual(SoloDeltaTally(), SoloDeltaTally(), "una catena nuova riparte da zero")
        XCTAssertEqual(SoloDeltaDiscard.allCases.map { $0.rawValue },
                       ["avvio", "render", "catena", "indietro", "avanti", "ciclo", "limiti"], "l'ordine della riga")
    }

    /// Le letture si azzerano a catena viva solo se latenza o ciclo cambiano davvero (par. 3 g).
    func testTheReadingsAreResetOnlyWhenLatencyOrCycleReallyChange() {
        func reason(_ latencyBefore: UInt64, _ latencyNow: UInt64, _ cycleBefore: UInt64, _ cycleNow: UInt64) -> String? {
            SoloResumeDecision.deltaResetReason(latencyBeforeTicks: latencyBefore, latencyNowTicks: latencyNow,
                                                cycleBeforeTicks: cycleBefore, cycleNowTicks: cycleNow)
        }
        XCTAssertNil(reason(302_400, 302_400, 256_000, 256_000), "gli stessi valori riscritti: le letture restano")
        XCTAssertEqual(reason(302_400, 64_800, 256_000, 256_000), "latenza")
        XCTAssertEqual(reason(302_400, 302_400, 256_000, 128_000), "ciclo")
        XCTAssertEqual(reason(302_400, 64_800, 256_000, 278_639), "latenza+ciclo")
        XCTAssertEqual(reason(302_400, 302_401, 256_000, 256_000), "latenza", "anche un tick")
    }

    private func readings(_ deltas: [Int64]) -> [SoloDeltaReading] {
        deltas.enumerated().map { SoloDeltaReading(deltaTicks: $0.element, readTicks: UInt64($0.offset + 1)) }
    }

    /// Con meno di tre letture Δ = 0 e la lettura è «riserva»; da tre in su la mediana, «hardware».
    func testDeltaIsTheMedianWithAtLeastThreeReadingsOtherwiseTheReserve() {
        XCTAssertEqual(SoloResumeDecision.deltaMinimumReadings, 3)
        XCTAssertEqual(SoloResumeDecision.deltaMemory, 8)
        XCTAssertEqual(SoloResumeDecision.delta(readings: []),
                       SoloDelta(ticks: 0, readings: 0, fromHardware: false, newestReadTicks: nil))
        XCTAssertEqual(SoloResumeDecision.delta(readings: readings([5, 7])),
                       SoloDelta(ticks: 0, readings: 2, fromHardware: false, newestReadTicks: 2))
        XCTAssertEqual(SoloResumeDecision.delta(readings: readings([5, 7, 6])),
                       SoloDelta(ticks: 6, readings: 3, fromHardware: true, newestReadTicks: 3))
        XCTAssertEqual(SoloResumeDecision.delta(readings: readings([9, 5, 7, 6])),
                       SoloDelta(ticks: 6, readings: 4, fromHardware: true, newestReadTicks: 4), "pari: la media delle due di mezzo")
        XCTAssertEqual(SoloResumeDecision.delta(readings: readings([-30, -10, -20])).ticks, -20)
        XCTAssertEqual(SoloResumeDecision.delta(readings: readings([-3, -2, 4, 9])).ticks, 1)
        XCTAssertEqual(SoloResumeDecision.delta(readings: readings([-3, -2, -4, -9])).ticks, -3, "la divisione tronca verso zero")
        XCTAssertEqual(SoloResumeDecision.delta(readings: []).sourceName, "riserva")
        XCTAssertEqual(SoloResumeDecision.delta(readings: readings([1, 2, 3])).sourceName, "hardware")
    }

    /// Solo le ultime otto: tre letture vecchie e lontane non spostano la mediana; e una lettura lontana fra otto non la
    /// sposta (la mediana, non la media).
    func testDeltaUsesOnlyTheLastEightAndIsNotMovedByAnOutlier() {
        let old: [Int64] = [1000, 1000, 1000]
        let recent: [Int64] = [10, 10, 10, 10, 10, 10, 10, 10]
        let got = SoloResumeDecision.delta(readings: readings(old + recent))
        XCTAssertEqual(got.ticks, 10)
        XCTAssertEqual(got.readings, 8)
        XCTAssertEqual(got.newestReadTicks, 11)
        XCTAssertEqual(SoloResumeDecision.delta(readings: readings([10, 11, 12, 9000, 10, 11, 12, 11])).ticks, 11)
    }

    func testTheTrueTimeOfTheAnchorIsTheConventionPlusDelta() {
        func delta(_ ticks: Int64) -> SoloDelta { SoloDelta(ticks: ticks, readings: 3, fromHardware: true, newestReadTicks: 1) }
        XCTAssertEqual(SoloResumeDecision.anchorTicks(conventionTicks: 1_000, delta: delta(250)), 1_250)
        XCTAssertEqual(SoloResumeDecision.anchorTicks(conventionTicks: 1_000, delta: delta(-250)), 750)
        XCTAssertEqual(SoloResumeDecision.anchorTicks(conventionTicks: 1_000, delta: delta(0)), 1_000)
        XCTAssertEqual(SoloResumeDecision.anchorTicks(conventionTicks: 100, delta: delta(-250)), 0, "si ferma a zero")
        XCTAssertEqual(SoloResumeDecision.anchorTicks(conventionTicks: UInt64.max - 10, delta: delta(250)), UInt64.max)
    }

    // MARK: - Il conto: il primo «uno» non prima di adesso più il margine

    /// A metà sezione. Àncora al battito 9 della prima sezione (battuta 3, battito 2); 0,9 s dopo, col margine di 150 ms,
    /// il primo «uno» utile è il battito 12 (battuta 4): tre battiti a 121,5 dopo l'àncora, 1,481481... s = 35.555.555 tick.
    func testInTheMiddleOfASectionTheTargetIsTheNextBar() {
        XCTAssertEqual(plan(clock(twoSections, section: 0, beat: 9), after: 0.9), aim(0, 4, 12, 2_435_555_555, 12))
    }

    /// Vicino alla fine di una sezione: il primo «uno» utile è l'inizio della sezione dopo (il battito 64 della canzone).
    func testNearTheEndOfASectionTheTargetIsTheFirstBarOfTheNextOne() {
        XCTAssertEqual(plan(clock(twoSections, section: 0, beat: 61), after: 0.5), aim(1, 1, 0, 2_435_555_555, 64))
    }

    /// A cavallo del confine e del cambio di tempo (121,5 -> 91,5): due battiti a 121,5 fino al confine, poi quattro a
    /// 91,5: 0,987654... + 2,622950... s = 86.654.523 tick. Il bersaglio è la seconda battuta del Chorus, battito 68.
    func testAcrossTheBoundaryTheTimeWalksTheTwoTempos() {
        XCTAssertEqual(plan(clock(twoSections, section: 0, beat: 62), after: 2.0), aim(1, 2, 4, 2_486_654_523, 68))
    }

    /// Il cambio di metro (7/8 -> 4/4, «5 Odd meter»): dall'ultima battuta dell'Intro al primo «uno» del Main, e oltre.
    func testAcrossAMeterChange() {
        XCTAssertEqual(plan(clock(oddMeter, section: 0, beat: 50), after: 0.4), aim(1, 1, 0, 2_453_498_452, 56))
        XCTAssertEqual(plan(clock(oddMeter, section: 0, beat: 54), after: 0.9), aim(1, 2, 4, 2_465_240_224, 60))
    }

    /// Canzone finita: nell'ultima battuta non c'è più un «uno» utile, e a canzone già finita nemmeno.
    func testTheSongEndsBeforeTheFirstUsefulBar() {
        XCTAssertEqual(plan(clock(short, section: 0, beat: 13), after: 0.3), .songEnded, "l'ultima battuta di «3 Short»")
        XCTAssertEqual(plan(clock(twoSections, section: 1, beat: 60), after: 0.2), .songEnded, "l'ultima battuta dell'ultima sezione")
        XCTAssertEqual(plan(clock(short, section: 0, beat: 10), after: 10.0), .songEnded, "gia' finita")
        // La penultima battuta ha ancora il suo «uno»: la quarta.
        XCTAssertEqual(plan(clock(short, section: 0, beat: 10), after: 0.1), aim(0, 4, 12, 2_421_901_140, 12))
    }

    /// Non certo: àncora assente, mappa non valida, àncora fuori mappa, un ciclo (sull'àncora, come bersaglio, sul cammino),
    /// tick al secondo non validi.
    func testUncertainWithoutAnAnchorWithACycleOrWithInvalidValues() {
        XCTAssertEqual(plan(nil, after: 0.9), .uncertain(.noAnchor))
        XCTAssertEqual(plan(clock(SongMap(sections: []), section: 0, beat: 0), after: 0.9), .uncertain(.clock(.invalidMap)))
        XCTAssertEqual(plan(clock(twoSections, section: 0, beat: 64), after: 0.9), .uncertain(.clock(.invalidAnchor)))
        XCTAssertEqual(plan(clock(withCycle, section: 1, beat: 0), after: 0.2), .uncertain(.clock(.cycle)), "l'ancora in un ciclo")
        XCTAssertEqual(plan(clock(withCycle, section: 0, beat: 6), after: 0.2), .uncertain(.clock(.cycle)), "il bersaglio in un ciclo")
        XCTAssertEqual(plan(clock(withCycle, section: 0, beat: 6), after: 30.0), .uncertain(.clock(.cycle)), "un ciclo sul cammino")
        XCTAssertEqual(SoloResumeDecision.plan(clock: clock(twoSections, section: 0, beat: 9), nowTicks: ticks(afterAnchor: 0.9),
                                               ticksPerSecond: 0, marginSeconds: 0.150), .uncertain(.clock(.invalidInput)))
        XCTAssertEqual(SoloResumeDecision.plan(clock: clock(twoSections, section: 0, beat: 9), nowTicks: ticks(afterAnchor: 0.9),
                                               ticksPerSecond: tps, marginSeconds: .nan), .uncertain(.clock(.invalidInput)))
    }

    /// Il margine al bordo, a 120 (una battuta ogni 2 s): con adesso a 1,85 s e 150 ms il primo «uno» utile cade
    /// esattamente a 2,0 s e vale (battuta 2); due tick dopo si va alla battuta 3; col margine della cassa Bluetooth
    /// (249,6 ms, A421 seguito 2) la battuta 2 non è più raggiungibile e il bersaglio è la 3.
    func testTheMarginAtTheEdgeWith150AndWith249Point6Milliseconds() {
        let c = clock(flat, section: 0, beat: 0)
        XCTAssertEqual(plan(c, after: 1.85), aim(0, 2, 4, 2_448_000_000, 4))
        XCTAssertEqual(SoloResumeDecision.plan(clock: c, nowTicks: ticks(afterAnchor: 1.85) + 2, ticksPerSecond: tps,
                                               marginSeconds: 0.150), aim(0, 3, 8, 2_496_000_000, 8))
        XCTAssertEqual(plan(c, after: 1.85, margin: 0.2496), aim(0, 3, 8, 2_496_000_000, 8))
        // Un margine negativo vale zero: il bersaglio non va mai prima di adesso.
        XCTAssertEqual(plan(c, after: 1.85, margin: -1.0), aim(0, 2, 4, 2_448_000_000, 4))
    }

    /// Il bersaglio è sempre un «uno» di battuta della canzone, con l'ora non prima di adesso più il margine, e l'«uno»
    /// per il DSP è almeno 1: per ogni istante di «1 Two sections» a passi di 0,37 s.
    func testTheTargetIsAlwaysADownbeatNotBeforeNowPlusTheMargin() {
        let c = clock(twoSections, section: 0, beat: 0)
        var resumes = 0
        var ended = 0
        var step = 0
        while step < 220 {
            let seconds = Double(step) * 0.37
            let now = ticks(afterAnchor: seconds)
            let earliest = now + UInt64((0.150 * tps).rounded())
            switch SoloResumeDecision.plan(clock: c, nowTicks: now, ticksPerSecond: tps, marginSeconds: 0.150) {
            case .resume(let aim):
                resumes += 1
                XCTAssertEqual(aim.beatInSection % 4, 0, "t:\(seconds)")
                XCTAssertEqual(aim.bar, aim.beatInSection / 4 + 1, "t:\(seconds)")
                XCTAssertGreaterThanOrEqual(aim.targetTicks + 2, earliest, "t:\(seconds)")
                XCTAssertLessThan(aim.targetTicks, earliest + UInt64((4.0 * 60.0 / 91.5 * tps).rounded()) + 2, "al piu' una battuta dopo - t:\(seconds)")
                XCTAssertGreaterThanOrEqual(aim.unoBeat, 1, "t:\(seconds)")
                XCTAssertEqual(aim.unoBeat, Double(aim.section * 64 + aim.beatInSection), "t:\(seconds)")
            case .songEnded:
                ended += 1
                // La canzone dura 31,60... + 41,96... = 73,57 s: l'ultimo «uno» utile è a 70,94 s.
                XCTAssertGreaterThan(seconds + 0.150, 70.9, "t:\(seconds)")
            case .uncertain(let why):
                XCTFail("non certo \(why) a t:\(seconds)")
            }
            step += 1
        }
        XCTAssertGreaterThan(resumes, 180)
        XCTAssertGreaterThan(ended, 20)
    }

    /// Il conto rifatto dopo un fuoco in ritardo: il bersaglio nuovo è sempre dopo quello mancato, anche se adesso più il
    /// margine cade ancora prima di lui (il fuoco scattato in orario ma col lettore lento).
    func testTheRecountAfterALateFireNeverGivesTheSameTarget() {
        let c = clock(twoSections, section: 0, beat: 9)
        // Il bersaglio di prima: il battito 12, a 35.555.555 tick dall'àncora. Adesso più il margine cade prima di lui.
        XCTAssertEqual(plan(c, after: 0.9), aim(0, 4, 12, 2_435_555_555, 12))
        XCTAssertEqual(SoloResumeDecision.plan(clock: c, nowTicks: ticks(afterAnchor: 0.9), ticksPerSecond: tps,
                                               marginSeconds: 0.150, notBeforeTicks: 2_435_555_555),
                       aim(0, 4, 12, 2_435_555_555, 12), "non prima di lui: lui vale ancora")
        XCTAssertEqual(SoloResumeDecision.plan(clock: c, nowTicks: ticks(afterAnchor: 0.9), ticksPerSecond: tps,
                                               marginSeconds: 0.150, notBeforeTicks: 2_435_555_556),
                       aim(0, 5, 16, 2_482_962_962, 16), "un tick dopo il bersaglio mancato: la battuta dopo")
        // Se adesso più il margine è già oltre, decide lui.
        XCTAssertEqual(SoloResumeDecision.plan(clock: c, nowTicks: ticks(afterAnchor: 5.0), ticksPerSecond: tps,
                                               marginSeconds: 0.150, notBeforeTicks: 2_435_555_556),
                       plan(c, after: 5.0))
    }

    /// Adesso può cadere poco prima dell'ora vera dell'àncora (Δ in avanti): il conto torna indietro nella sezione.
    func testNowJustBeforeTheAnchorStillCounts() {
        let c = clock(twoSections, section: 0, beat: 9)
        let now = anchorTicks - 240_000
        XCTAssertEqual(SoloResumeDecision.plan(clock: c, nowTicks: now, ticksPerSecond: tps, marginSeconds: 0.150),
                       aim(0, 4, 12, 2_435_555_555, 12))
    }

    /// Il conto usa la mappa col tempo dell'àncora: se la sezione correva a 126 invece di 121,5 (un tap tempo), i tre
    /// battiti fino al bersaglio durano 1,428571... s = 34.285.714 tick.
    func testTheCountRunsAtTheTempoOfTheAnchor() {
        let map = twoSections.replacingTempo(ofSection: 0, with: 126)
        XCTAssertEqual(plan(clock(map, section: 0, beat: 9), after: 0.9), aim(0, 4, 12, 2_434_285_714, 12))
    }

    // MARK: - Il tempo d'arrivo, il fuoco in ritardo

    func testTheArrivalTempo() {
        // Nella sezione dell'àncora: il tempo del motore di adesso (uguale a quello dell'àncora, o cambiato da un tap).
        XCTAssertEqual(SoloResumeDecision.arrivalTempo(targetSection: 0, anchorSection: 0, anchorTempo: 121.5,
                                                       engineTempoNow: 121.5, mapTempo: 121.5), 121.5)
        XCTAssertEqual(SoloResumeDecision.arrivalTempo(targetSection: 0, anchorSection: 0, anchorTempo: 121.5,
                                                       engineTempoNow: 126, mapTempo: 121.5), 126, "un tap tempo nella pausa")
        XCTAssertEqual(SoloResumeDecision.arrivalTempo(targetSection: 0, anchorSection: 0, anchorTempo: 126,
                                                       engineTempoNow: .nan, mapTempo: 121.5), 126, "senza un tempo valido resta quello dell'ancora")
        XCTAssertEqual(SoloResumeDecision.arrivalTempo(targetSection: 0, anchorSection: 0, anchorTempo: 126,
                                                       engineTempoNow: 0, mapTempo: 121.5), 126)
        // Nelle altre sezioni: il tempo della mappa.
        XCTAssertEqual(SoloResumeDecision.arrivalTempo(targetSection: 1, anchorSection: 0, anchorTempo: 126,
                                                       engineTempoNow: 126, mapTempo: 91.5), 91.5)
    }

    /// Mai un click in ritardo: il fuoco in ritardo rifà il conto consumando un salto; col segno «lettore lento» senza
    /// consumarlo; senza salti il Solo si ferma.
    func testTheLateFireRecountsWithTheSkipsThenGivesUp() {
        XCTAssertEqual(DirectorRejoinDecision.maxLateSkips, 4)
        XCTAssertEqual(SoloResumeDecision.lateStep(slowPlayer: false, lateSkipsLeft: 4), .recount(skipsLeft: 3, trigger: "ritardo"))
        XCTAssertEqual(SoloResumeDecision.lateStep(slowPlayer: false, lateSkipsLeft: 1), .recount(skipsLeft: 0, trigger: "ritardo"))
        XCTAssertEqual(SoloResumeDecision.lateStep(slowPlayer: false, lateSkipsLeft: 0), .giveUp)
        XCTAssertEqual(SoloResumeDecision.lateStep(slowPlayer: true, lateSkipsLeft: 4), .recount(skipsLeft: 4, trigger: "lettore-lento"))
        XCTAssertEqual(SoloResumeDecision.lateStep(slowPlayer: true, lateSkipsLeft: 0), .recount(skipsLeft: 0, trigger: "lettore-lento"))
    }

    // MARK: - Il ritorno e la guardia del fuoco

    private func ret(running: Bool = false, interruption: Bool = false, services: Bool = true, role: PlayerRole = .solo,
                     pending: Bool = true, anchor: Bool = true, sameSong: Bool = true, vanished: Bool = false) -> SoloReturnStep {
        SoloResumeDecision.returnStep(engineRunning: running, systemInterruption: interruption, servicesNormal: services,
                                      playerRole: role, pending: pending, anchorAlive: anchor, sameSong: sameSong,
                                      externalVanished: vanished)
    }

    func testTheReturnFiresOnlyWithTheGuardAndTheOutputStillThere() {
        XCTAssertEqual(ret(), .fire)
        XCTAssertEqual(ret(running: true), .notFired(.engineRunning))
        XCTAssertEqual(ret(interruption: true), .notFired(.interruption))
        XCTAssertEqual(ret(services: false), .notFired(.services))
        XCTAssertEqual(ret(role: .direttore), .notFired(.notSolo))
        XCTAssertEqual(ret(pending: false), .notFired(.notPending))
        XCTAssertEqual(ret(anchor: false), .notFired(.noAnchor))
        XCTAssertEqual(ret(sameSong: false), .notFired(.otherSong))
        // P32 — l'uscita sparita (la memoria dice esterna e adesso un'esterna non c'e'): come la tolta.
        XCTAssertEqual(ret(vanished: true), .asRemoved)
        // La guardia viene prima dell'uscita sparita.
        XCTAssertEqual(ret(interruption: true, vanished: true), .notFired(.interruption))
        XCTAssertEqual(ret(pending: false, vanished: true), .notFired(.notPending))
        // L'ordine dei motivi.
        XCTAssertEqual(ret(running: true, interruption: true, services: false), .notFired(.engineRunning))
        XCTAssertEqual(ret(interruption: true, services: false, role: .follower), .notFired(.interruption))
        XCTAssertEqual(ret(services: false, role: .follower, pending: false), .notFired(.services))
        XCTAssertEqual(ret(role: .follower, pending: false, anchor: false), .notFired(.notSolo))
        XCTAssertEqual(ret(pending: false, anchor: false, sameSong: false), .notFired(.notPending))
        XCTAssertEqual(ret(anchor: false, sameSong: false), .notFired(.noAnchor))
    }

    private func fire(role: PlayerRole = .solo, interruption: Bool = false, services: Bool = true, anchor: Bool = true,
                      sameSong: Bool = true, section: Bool = true, handles: Bool = true) -> SoloFireRefusal? {
        SoloResumeDecision.fireRefusal(playerRole: role, systemInterruption: interruption, servicesNormal: services,
                                       anchorAlive: anchor, sameSong: sameSong, sectionInMap: section, handlesPresent: handles)
    }

    func testTheFireEntersOnlyWithItsGuard() {
        XCTAssertNil(fire())
        XCTAssertEqual(fire(role: .direttore), .notSolo)
        XCTAssertEqual(fire(interruption: true), .interruption, "il fuoco fra i due passaggi sulla coda di un'interruzione")
        XCTAssertEqual(fire(services: false), .services)
        XCTAssertEqual(fire(anchor: false), .noAnchor)
        XCTAssertEqual(fire(sameSong: false), .otherSong)
        XCTAssertEqual(fire(section: false), .sectionOutOfMap)
        XCTAssertEqual(fire(handles: false), .handlesMissing)
        XCTAssertEqual(fire(role: .follower, interruption: true), .notSolo)
        XCTAssertEqual(fire(interruption: true, services: false), .interruption)
        XCTAssertEqual(fire(services: false, anchor: false), .services)
        XCTAssertEqual(fire(anchor: false, sameSong: false), .noAnchor)
        XCTAssertEqual(fire(sameSong: false, section: false), .otherSong)
        XCTAssertEqual(fire(section: false, handles: false), .sectionOutOfMap)
    }

    // MARK: - La vita della ripresa

    /// La tabella intera, stato × evento, scritta per esteso (A424 par. 2.1 b: una riga per evento).
    func testTheLifecycleTable() {
        // Le colonne: da nessuna, in attesa, armata, tenuta.
        let table: [(SoloResumeEvent, [SoloResumeState])] = [
            (.crisisWaits, [.waiting, .waiting, .waiting, .waiting]),
            (.crisisNotTaken, [.idle, .idle, .idle, .idle]),
            (.crisisDrainDelivered, [.idle, .idle, .idle, .idle]),
            (.engineStartedForResume, [.idle, .armed, .armed, .held]),
            (.fired, [.idle, .waiting, .held, .held]),
            (.firstCountedBeatOut, [.idle, .waiting, .armed, .idle]),
            (.stop, [.idle, .idle, .idle, .idle]),
            (.manualPlay, [.idle, .idle, .idle, .idle]),
            (.showClosed, [.idle, .idle, .idle, .idle]),
            (.roleOrLinkChange, [.idle, .idle, .idle, .idle]),
            (.outputRemoved, [.idle, .idle, .idle, .idle]),
            (.interruption, [.idle, .idle, .idle, .idle]),
            (.servicesLostOrReset, [.idle, .idle, .idle, .idle]),
            (.uncertain, [.idle, .idle, .idle, .idle]),
            (.songEnded, [.idle, .idle, .idle, .idle]),
            (.otherSong, [.idle, .idle, .idle, .idle]),
        ]
        let states: [SoloResumeState] = [.idle, .waiting, .armed, .held]
        XCTAssertEqual(table.count, SoloResumeEvent.allCases.count)
        XCTAssertEqual(Set(table.map { $0.0 }), Set(SoloResumeEvent.allCases))
        XCTAssertEqual(states, SoloResumeState.allCases)
        for (event, expected) in table {
            for (index, state) in states.enumerated() {
                XCTAssertEqual(SoloResumeDecision.lifecycle(state, event), expected[index], "stato:\(state) evento:\(event)")
            }
        }
    }

    /// La vita intera di una ripresa riuscita, e il segno pubblicato: vero da quando la ripresa aspetta a quando il
    /// fuoco riesce; l'àncora resta tenuta fino al primo battito contato uscito.
    func testTheLifeOfAResumeAndThePublishedSign() {
        var state = SoloResumeState.idle
        XCTAssertFalse(SoloResumeDecision.pending(state))
        XCTAssertFalse(SoloResumeDecision.anchorAlive(state))
        state = SoloResumeDecision.lifecycle(state, .crisisWaits)
        XCTAssertEqual(state, .waiting)
        XCTAssertTrue(SoloResumeDecision.pending(state))
        XCTAssertTrue(SoloResumeDecision.anchorAlive(state))
        XCTAssertFalse(SoloResumeDecision.heldByResume(state))
        state = SoloResumeDecision.lifecycle(state, .engineStartedForResume)
        XCTAssertEqual(state, .armed)
        XCTAssertTrue(SoloResumeDecision.pending(state), "nella scorta il segno e' ancora alto")
        state = SoloResumeDecision.lifecycle(state, .fired)
        XCTAssertEqual(state, .held)
        XCTAssertFalse(SoloResumeDecision.pending(state), "al fuoco riuscito il segno scende")
        XCTAssertTrue(SoloResumeDecision.anchorAlive(state))
        XCTAssertTrue(SoloResumeDecision.heldByResume(state))
        // Una crisi nuova prima del primo battito contato: l'àncora tenuta torna in attesa.
        XCTAssertEqual(SoloResumeDecision.lifecycle(state, .crisisWaits), .waiting)
        state = SoloResumeDecision.lifecycle(state, .firstCountedBeatOut)
        XCTAssertEqual(state, .idle)
        XCTAssertFalse(SoloResumeDecision.anchorAlive(state))
    }

    /// Lo stato dai tre valori che il motore tiene; le combinazioni che non esistono non hanno uno stato.
    func testTheStateFromTheThreeValuesOfTheEngine() {
        XCTAssertEqual(SoloResumeDecision.state(anchorAlive: false, pending: false, heldByResume: false, engineRunning: false), .idle)
        XCTAssertEqual(SoloResumeDecision.state(anchorAlive: false, pending: false, heldByResume: false, engineRunning: true), .idle)
        XCTAssertEqual(SoloResumeDecision.state(anchorAlive: true, pending: true, heldByResume: false, engineRunning: false), .waiting)
        XCTAssertEqual(SoloResumeDecision.state(anchorAlive: true, pending: true, heldByResume: false, engineRunning: true), .armed)
        XCTAssertEqual(SoloResumeDecision.state(anchorAlive: true, pending: false, heldByResume: true, engineRunning: true), .held)
        XCTAssertNil(SoloResumeDecision.state(anchorAlive: false, pending: true, heldByResume: false, engineRunning: false),
                     "in attesa senza ancora")
        XCTAssertNil(SoloResumeDecision.state(anchorAlive: true, pending: true, heldByResume: true, engineRunning: true),
                     "tenuta e in attesa insieme")
        XCTAssertNil(SoloResumeDecision.state(anchorAlive: true, pending: false, heldByResume: false, engineRunning: true),
                     "un'ancora viva che non aspetta e non e' tenuta")
        XCTAssertNil(SoloResumeDecision.state(anchorAlive: false, pending: false, heldByResume: true, engineRunning: true))
        for state in SoloResumeState.allCases {
            let back = SoloResumeDecision.state(anchorAlive: SoloResumeDecision.anchorAlive(state),
                                                pending: SoloResumeDecision.pending(state),
                                                heldByResume: SoloResumeDecision.heldByResume(state),
                                                engineRunning: state == .armed || state == .held)
            XCTAssertEqual(back, state)
        }
    }

    // MARK: - I nomi nelle righe

    func testTheNamesInTheLines() {
        XCTAssertEqual(SoloAnchorRefusal.noCountedBeat.rawValue, "nessun-battito-contato-gia-uscito")
        XCTAssertEqual(SoloAnchorRefusal.cycle.rawValue, "ciclo")
        XCTAssertEqual(SoloAnchorRefusal.allCases.count, 8)
        XCTAssertEqual(SoloReturnRefusal.allCases.count, 7)
        XCTAssertEqual(SoloFireRefusal.allCases.count, 7)
        XCTAssertEqual(SoloFireRefusal.interruption.rawValue, "interruzione")
        XCTAssertEqual(SoloResumeState.waiting.rawValue, "in-attesa")
        XCTAssertEqual(SoloResumeState.allCases.map { $0.rawValue }, ["nessuna", "in-attesa", "armata", "tenuta"])
        XCTAssertEqual(SoloResumeEvent.allCases.count, 16)
        XCTAssertEqual(Set(SoloResumeEvent.allCases.map { $0.rawValue }).count, 16)
    }
}
