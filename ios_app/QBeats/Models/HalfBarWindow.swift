import Foundation

// === A386 · FASE B1 (2D) — LA MEZZA BATTUTA: DENTRO O FUORI, TESTATO ===
// D6 (23/09/2026): il Follower entra solo a inizio canzone, col Play del Direttore, e solo se
// il Play gli arriva ENTRO MEZZA BATTUTA dalla partenza annunciata. Perche' mezza battuta: il
// seme d'ingresso (`armSharedJoin`) arrotonda alla battuta un'attesa di al piu' una battuta —
// e' giusto entro mezza battuta, oltre entra una battuta indietro (A-BIS §1.a, confermato).
// Q9 (ratifica 24/09): DUE lati, `|adesso − partenza| <= mezza battuta` — una partenza letta
// nel futuro oltre mezza battuta il seme la leggerebbe come battuta 1 col Direttore alla 0.
// Q10 (ratifica 24/09): la misura (battiti per battuta) e' quella della CANZONE ARMATA, non
// quella che il motore porta al momento del richiamo (che e' ancora la sezione precedente);
// il tempo e' quello della sessione, letto dalla stessa cattura della partenza.
// I tick per secondo li da' il chiamante da `mach_timebase_info` (A382 §3.6 ne ha misurati
// 24.000 per millisecondo su questa famiglia di apparecchi: e' una misura, non una costante).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum HalfBarWindow {

    /// Mezza battuta in secondi: `beatsPerBar / 2 × 60 / bpm`. Zero se un ingresso non regge.
    static func halfBarSeconds(beatsPerBar: UInt32, bpm: Double) -> Double {
        guard beatsPerBar > 0, bpm > 0, bpm.isFinite else { return 0 }
        return Double(beatsPerBar) / 2.0 * 60.0 / bpm
    }

    /// Mezza battuta in tick dell'orologio, arrotondata al tick.
    static func halfBarTicks(beatsPerBar: UInt32, bpm: Double, ticksPerSecond: Double) -> UInt64 {
        guard ticksPerSecond > 0, ticksPerSecond.isFinite else { return 0 }
        let seconds = halfBarSeconds(beatsPerBar: beatsPerBar, bpm: bpm)
        guard seconds > 0 else { return 0 }
        return UInt64((seconds * ticksPerSecond).rounded())
    }

    /// Due lati: `|now − announced| <= halfBarTicks`. Con finestra zero, mai dentro.
    static func isWithin(announced: UInt64, now: UInt64, halfBarTicks: UInt64) -> Bool {
        guard halfBarTicks > 0 else { return false }
        let distance = now >= announced ? now - announced : announced - now
        return distance <= halfBarTicks
    }
}
