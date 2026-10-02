import Foundation

// === A386 · FASE B2d (2D) — IL CONTO DEI VUOTI DELL'ASCOLTO: SOLO LOG, TESTATO ===
// Mandato «A386 · FASE B2d», §3.c: al collaudo si devono poter contare le letture senza colpo a
// Direttore presente. Con l'ascolto a 0,25 s (`DirectorSignalCadence`) e la ripetizione a 1 s,
// tre letture su quattro sono senza colpo per costruzione: una riga a ogni lettura senza colpo
// sarebbe rumore. Questo tipo conta e dice QUANDO scrivere, a frequenza limitata:
//  · `late`: il vuoto dall'ultimo colpo ha passato `lateAfterTicks` (un periodo e mezzo della
//    ripetizione: una ripetizione non e' arrivata quando doveva). Una riga per vuoto, non di piu';
//  · `resumed`: il colpo che chiude un vuoto «in ritardo», con quanto e' durato;
//  · `summary`: ogni `summaryEvery` letture, il riepilogo della finestra — letture, colpi, la
//    fila piu' lunga di letture senza colpo, il vuoto piu' lungo fra due colpi, i ritardi.
// A regime: fila 3 o 4, vuoto di un secondo piu' gli scarti, zero ritardi. La soglia del «non
// sento» (3 s) sono dodici letture senza colpo di fila.
// NON DECIDE NIENTE: «sento il Direttore» resta di `DirectorHeardTracker`. Qui si conta e basta.
// Prima del primo colpo non c'e' un vuoto da misurare: file e ritardi partono dal primo colpo.
// A Link spento dall'app si riparte da capo, come il tracker.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct DirectorHeardGapMeter: Equatable {

    /// Il tick dell'ultimo colpo (`nil` = nessun colpo ancora).
    let lastHitAt: UInt64?
    /// Letture senza colpo di fila dall'ultimo colpo.
    let run: Int
    /// Il vuoto in corso ha gia' passato `lateAfterTicks`: la riga `late` e' gia' uscita.
    let lateOpen: Bool
    // La finestra del riepilogo in corso.
    let samples: Int
    let hits: Int
    let heardSamples: Int
    let maxRun: Int
    let maxGapTicks: UInt64
    let lates: Int

    /// Prima di ogni lettura, e a Link spento.
    static let start = DirectorHeardGapMeter(lastHitAt: nil, run: 0, lateOpen: false,
                                             samples: 0, hits: 0, heardSamples: 0,
                                             maxRun: 0, maxGapTicks: 0, lates: 0)

    /// Una ripetizione non e' arrivata quando doveva: il vuoto, adesso, e la fila di letture.
    struct Late: Equatable {
        let gapTicks: UInt64
        let run: Int
    }

    /// Il colpo che chiude un vuoto «in ritardo»: quanto e' durato e quante letture.
    struct Resumed: Equatable {
        let gapTicks: UInt64
        let run: Int
    }

    /// Il riepilogo di una finestra di letture.
    struct Summary: Equatable {
        let samples: Int
        let hits: Int
        /// Letture della finestra con «sento il Direttore».
        let heardSamples: Int
        /// La fila piu' lunga di letture senza colpo (dopo il primo colpo).
        let maxRun: Int
        /// Il vuoto piu' lungo fra due colpi, compreso quello ancora aperto a fine finestra.
        let maxGapTicks: UInt64
        let lates: Int

        var samplesWithoutHit: Int { samples - hits }
    }

    struct Step: Equatable {
        let late: Late?
        let resumed: Resumed?
        let summary: Summary?
        /// Il tempo dall'ultimo colpo, misurato a questa lettura PRIMA di contarla (per un colpo:
        /// il vuoto che chiude). `nil` = nessun colpo ancora.
        let gapTicks: UInt64?
        /// Le letture senza colpo di fila, compresa questa (per un colpo: quelle che chiude).
        let run: Int
        let next: DirectorHeardGapMeter
    }

    /// Una lettura del battito d'ascolto: se e' stata un colpo, se adesso si sente, il tick.
    func observe(linkEnabled: Bool,
                 hit: Bool,
                 heard: Bool,
                 now: UInt64,
                 lateAfterTicks: UInt64,
                 summaryEvery: Int) -> Step {
        guard linkEnabled else {
            return Step(late: nil, resumed: nil, summary: nil, gapTicks: nil, run: 0, next: .start)
        }
        var late: Late? = nil
        var resumed: Resumed? = nil
        var hitAt = lastHitAt
        var newRun = run
        var stepRun = run
        var open = lateOpen
        var windowMaxRun = maxRun
        var windowMaxGap = maxGapTicks
        var windowLates = lates
        let gap: UInt64? = lastHitAt.flatMap { now >= $0 ? now - $0 : nil }
        if hit {
            if let closed = gap {
                if closed > windowMaxGap { windowMaxGap = closed }
                if open { resumed = Resumed(gapTicks: closed, run: run) }
            }
            hitAt = now
            newRun = 0
            open = false
        } else if let current = gap {
            newRun = run + 1
            stepRun = newRun
            if newRun > windowMaxRun { windowMaxRun = newRun }
            if current > windowMaxGap { windowMaxGap = current }
            if !open && current >= lateAfterTicks {
                open = true
                windowLates += 1
                late = Late(gapTicks: current, run: newRun)
            }
        }
        let windowSamples = samples + 1
        let windowHits = hits + (hit ? 1 : 0)
        let windowHeard = heardSamples + (heard ? 1 : 0)
        if summaryEvery > 0 && windowSamples >= summaryEvery {
            let summary = Summary(samples: windowSamples, hits: windowHits, heardSamples: windowHeard,
                                  maxRun: windowMaxRun, maxGapTicks: windowMaxGap, lates: windowLates)
            return Step(late: late, resumed: resumed, summary: summary, gapTicks: gap, run: stepRun,
                        next: DirectorHeardGapMeter(lastHitAt: hitAt, run: newRun, lateOpen: open,
                                                    samples: 0, hits: 0, heardSamples: 0,
                                                    maxRun: 0, maxGapTicks: 0, lates: 0))
        }
        return Step(late: late, resumed: resumed, summary: nil, gapTicks: gap, run: stepRun,
                    next: DirectorHeardGapMeter(lastHitAt: hitAt, run: newRun, lateOpen: open,
                                                samples: windowSamples, hits: windowHits,
                                                heardSamples: windowHeard, maxRun: windowMaxRun,
                                                maxGapTicks: windowMaxGap, lates: windowLates))
    }

    /// Un Play o uno Stop ricevuto (il richiamo avvio/stop): e' un colpo fuori dalle letture.
    /// Chiude il vuoto in corso e azzera la fila; non conta come lettura della finestra.
    func observeTransportEvent(linkEnabled: Bool, now: UInt64) -> Step {
        guard linkEnabled else {
            return Step(late: nil, resumed: nil, summary: nil, gapTicks: nil, run: 0, next: .start)
        }
        var resumed: Resumed? = nil
        var windowMaxGap = maxGapTicks
        let gap: UInt64? = lastHitAt.flatMap { now >= $0 ? now - $0 : nil }
        if let closed = gap {
            if closed > windowMaxGap { windowMaxGap = closed }
            if lateOpen { resumed = Resumed(gapTicks: closed, run: run) }
        }
        return Step(late: nil, resumed: resumed, summary: nil, gapTicks: gap, run: run,
                    next: DirectorHeardGapMeter(lastHitAt: now, run: 0, lateOpen: false,
                                                samples: samples, hits: hits, heardSamples: heardSamples,
                                                maxRun: maxRun, maxGapTicks: windowMaxGap, lates: lates))
    }
}
