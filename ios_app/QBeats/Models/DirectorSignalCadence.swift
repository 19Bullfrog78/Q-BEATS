import Foundation

// === A386 · FASE B2d (2D) — OGNI QUANTO IL FOLLOWER ASCOLTA IL DIRETTORE, TESTATO ===
// Il Direttore ripete il proprio stato ogni 1,0 s (`DirectorReannounceDecision`, il battito di
// trasporto). Fino a B2c il Follower lo ascoltava nello stesso battito a 1 s: due orologi alla
// stessa cadenza. Quando le due cadenze cadono quasi in fase — la ripetizione arriva a ridosso
// della lettura del Follower — lo scarto dei timer (leeway 50 ms) decide a ogni giro se la
// ripetizione cade prima o dopo la lettura: fra due letture ne cadono zero, una o due. Zero non
// e' un cambio; due, con l'ora che alternava fra due valori, nemmeno. Tre letture di fila cosi'
// e il Follower diceva «non sento» a Direttore presente (collaudo dell'01/10/2026, log
// `A386_D7_iPad.txt`, 20:03:12 e 20:04:31; in Ready perdeva la scelta, R2).
// La cura ha due meta', e questa e' la prima: IL FOLLOWER ASCOLTA PIU' FITTO DELLA RIPETIZIONE.
// A 0,25 s (piu' il leeway: 0,30 s al massimo fra due letture) ogni ripetizione che arriva e'
// vista da sola, qualunque sia la fase fra i due apparecchi; fra due colpi passa un secondo
// piu' gli scarti, e la soglia di 3 s resta lontana due secondi. La seconda meta' e' il giro a
// tre valori della ripetizione (`DirectorReannounceDecision`, B2d): due ripetizioni fra due
// letture — una arrivata in ritardo insieme alla successiva — restano un cambio.
// La soglia NON cambia (3,0 s, nel motore). La perdita vera si vede prima: l'ultimo colpo e'
// letto entro 0,30 s dall'arrivo (prima: entro un secondo), e «non sento» esce alla prima
// lettura oltre la soglia (prima: fino a un secondo dopo).
// Il quarto di secondo e' la cadenza del campionatore del timbro (RIENTRO-P2A, stesso periodo e
// stesso leeway): nei log del collaudo A386 ha visto a una a una tutte le ripetizioni.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum DirectorSignalCadence {

    /// Ogni quanto il Follower legge la coppia (suona, ora d'avvio): secondi.
    static let listenPeriodSeconds: Double = 0.25

    /// Il leeway del timer d'ascolto: millisecondi.
    static let listenLeewayMilliseconds: Int = 50

    /// Oltre questo tempo dall'ultimo colpo una ripetizione e' «in ritardo»: un periodo e mezzo
    /// della ripetizione. Solo per le righe di log (`DirectorHeardGapMeter`): non decide niente.
    static let lateAfterSeconds: Double = 1.5

    /// Ogni quante letture esce la riga di riepilogo dell'ascolto: 40 letture = 10 s.
    static let summaryEverySamples: Int = 40
}
