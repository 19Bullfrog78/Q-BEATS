import Foundation

// === A416 (21/10/2026) — USCITA AUDIO, PASSO 1: IL BUCO DEL RENDER, MISURATO DA audioQueue (SOLO REGISTRO) ===
// Il fatto (referto A415, §3.1-§3.6; P11). Al cambio di percorso (le cuffie col filo che si staccano o si attaccano) il
// rendering del motore si ferma per circa 0,8 s senza che il motore si fermi: i completamenti dei buffer non arrivano e
// `scheduleNextBuffer` non gira; alla ripresa i richiami arretrati arrivano a raffica (19/10: tre in un millisecondo).
// Il motore non lo vede: la sua posizione avanza coi campioni programmati, l'orologio no.
// La misura (mandato del referee «USCITA-AUDIO-PASSO-1», §2.3; referto A415 §3.6, punto 2): a ogni chiamata di
// `scheduleNextBuffer`, prima del blocco della fase, lo scarto fra l'orologio e i campioni programmati
//     scarto = (adesso − ora di riferimento) − (campioni programmati da allora) / frequenza dei nodi.
// In regime lo scarto resta vicino a un livello, la base: oscilla di un ciclo d'uscita (e di circa un buffer col dente
// di sega di nodi e uscita a frequenze diverse, A415 §4.5). In un buco sale della durata del buco e resta su; la raffica
// dopo lo fa solo scendere. Un buco è uno scarto oltre la base di più di tre buffer (soglia provvisoria, scelta 2 del
// referee: i tre buffer che il motore tiene in coda; P11 ne valeva 77). Ogni buco si conta una volta: dopo un buco la
// base si riprende dalla chiamata dopo (e la raffica la porta al livello nuovo).
// Le regole:
//  · il riferimento si prende alla quarta chiamata dopo un avvio, una ripartenza, un cambio di frequenza o la ripresa
//    della catena dopo una fine di sezione (le prime tre sono la scorta dei tre buffer, consegnati insieme: al rientro
//    del Direttore il primo esce a un'ora chiesta, più tardi). Al riferimento lo scarto vale zero;
//  · la base è il pavimento dello scarto: scende con lui, e sale al più di un millisecondo per secondo. Così segue la
//    deriva lenta fra l'orologio dell'apparecchio e quello dell'hardware (decine di parti per milione) e non un buco,
//    che arriva tutto in una chiamata;
//  · un evento (cambio di percorso, cambio di configurazione) è «vicino» a un buco se è arrivato fra un secondo prima
//    dell'inizio stimato del buco (adesso − buco) e adesso.
// In questo passo nessuna azione: una riga di registro e basta (l'assert del Direttore e la correzione del Follower
// restano come sono; la cura è del passo 2). Aritmetica su numeri che il motore ha già, su audioQueue: niente nel
// thread di rendering.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct RenderGapMeter: Equatable {

    /// La soglia, in buffer sopra la base (provvisoria: la fissa il referee dopo il collaudo).
    static let thresholdBuffers: Double = 3
    /// Le chiamate prima del riferimento: la scorta dei tre buffer di ogni avvio.
    static let warmupCalls: Int = 3
    /// Quanto può salire la base, in secondi per secondo d'orologio.
    static let baseRisePerSecond: Double = 0.001
    /// Quanto prima dell'inizio stimato del buco un evento conta ancora come «vicino».
    static let eventWindowBeforeSeconds: Double = 1.0

    /// Un buco: la durata stimata (scarto meno base), lo scarto e la base, l'ora stimata d'inizio, i buffer consegnati.
    struct Gap: Equatable {
        let holeSeconds: Double
        let gapSeconds: Double
        let baseSeconds: Double
        let startTicks: UInt64
        let bufferCount: Int
    }

    enum Outcome: Equatable {
        /// Prima del riferimento (la scorta).
        case warmup
        /// In regime: lo scarto e la base.
        case regular(gapSeconds: Double, baseSeconds: Double)
        /// Un buco, contato una volta.
        case gap(Gap)
    }

    let bufferFrames: Int
    let ticksPerSecond: Double
    private(set) var sampleRate: Double
    private(set) var warmupLeft: Int
    private(set) var referenceTicks: UInt64? = nil
    private(set) var referenceBufferCount: Int = 0
    private(set) var baseSeconds: Double? = nil
    private(set) var lastTicks: UInt64 = 0
    /// I buchi contati dall'ultimo riferimento preso dopo un avvio (per il banco e per le righe).
    private(set) var gapsCounted: Int = 0

    init(bufferFrames: Int, sampleRate: Double, ticksPerSecond: Double) {
        self.bufferFrames = bufferFrames
        self.ticksPerSecond = ticksPerSecond
        self.sampleRate = sampleRate
        self.warmupLeft = RenderGapMeter.warmupCalls
    }

    /// La catena dei buffer riparte (avvio, ripartenza, ripresa dopo una fine di sezione) o la frequenza è cambiata: il
    /// riferimento si riprende dopo la scorta.
    mutating func restart(sampleRate: Double) {
        self.sampleRate = sampleRate
        warmupLeft = RenderGapMeter.warmupCalls
        referenceTicks = nil
        referenceBufferCount = 0
        baseSeconds = nil
        lastTicks = 0
        gapsCounted = 0
    }

    /// Una chiamata di `scheduleNextBuffer`. `bufferCount`: i buffer già consegnati in questo avvio (0 = il primo, e il
    /// riferimento si riprende); `sampleRate`: la frequenza dei nodi (se cambia, il riferimento si riprende).
    mutating func observe(nowTicks: UInt64, bufferCount: Int, sampleRate: Double) -> Outcome {
        if bufferCount == 0 || !SampleRateDecision.same(sampleRate, self.sampleRate) {
            restart(sampleRate: sampleRate)
        }
        if warmupLeft > 0 {
            warmupLeft -= 1
            return .warmup
        }
        guard ticksPerSecond > 0, SampleRateDecision.isUsable(self.sampleRate), bufferFrames > 0 else { return .warmup }
        guard let reference = referenceTicks else {
            referenceTicks = nowTicks
            referenceBufferCount = bufferCount
            baseSeconds = 0
            lastTicks = nowTicks
            return .regular(gapSeconds: 0, baseSeconds: 0)
        }
        let elapsed = signedSeconds(from: reference, to: nowTicks)
        let scheduled = Double(bufferCount - referenceBufferCount) * Double(bufferFrames) / self.sampleRate
        let gap = elapsed - scheduled
        let sinceLast = max(signedSeconds(from: lastTicks, to: nowTicks), 0)
        lastTicks = nowTicks
        guard let base = baseSeconds else {
            // La chiamata dopo un buco: la base si riprende da qui.
            baseSeconds = gap
            return .regular(gapSeconds: gap, baseSeconds: gap)
        }
        let threshold = RenderGapMeter.thresholdBuffers * Double(bufferFrames) / self.sampleRate
        if gap > base + threshold {
            let hole = gap - base
            gapsCounted += 1
            baseSeconds = nil
            let holeTicks = UInt64(max(hole, 0) * ticksPerSecond)
            let start = nowTicks > holeTicks ? nowTicks - holeTicks : 0
            return .gap(Gap(holeSeconds: hole, gapSeconds: gap, baseSeconds: base, startTicks: start,
                            bufferCount: bufferCount))
        }
        let newBase = min(gap, base + RenderGapMeter.baseRisePerSecond * sinceLast)
        baseSeconds = newBase
        return .regular(gapSeconds: gap, baseSeconds: newBase)
    }

    /// Un evento arrivato a `eventTicks` è «vicino» al buco cominciato a `holeStartTicks` e visto a `nowTicks`.
    static func isNear(eventTicks: UInt64, holeStartTicks: UInt64, nowTicks: UInt64, ticksPerSecond: Double) -> Bool {
        guard ticksPerSecond > 0 else { return false }
        let windowTicks = UInt64(eventWindowBeforeSeconds * ticksPerSecond)
        let from = holeStartTicks > windowTicks ? holeStartTicks - windowTicks : 0
        return eventTicks >= from && eventTicks <= nowTicks
    }

    private func signedSeconds(from start: UInt64, to end: UInt64) -> Double {
        end >= start ? Double(end - start) / ticksPerSecond : -Double(start - end) / ticksPerSecond
    }
}
