import Foundation

// === A386 · FASE B1 (2D) — «SENTO IL DIRETTORE»: IL SEGNALE, TESTATO ===
// Il Direttore ripete il proprio stato di trasporto ogni secondo (`DirectorReannounceDecision`,
// `{vero, T ± 1 ms}` in moto, `{falso, Tstop ± 1 ms}` da fermo): per la catena di Link letta dal
// referee (A-TER §1.2, [R]) ogni ripetizione cambia `timeForIsPlaying` nel client del Follower,
// anche senza richiamo. Un Follower che legge la coppia `(isPlaying, timeForIsPlaying)` a ogni
// battito (una cattura, nessun commit: `link_engine_read_start_stamp`) sente il Direttore
// finche' quella coppia cambia; se per una soglia non cambia, non lo sente piu'.
// La soglia (3 s proposti dal referee, provvisoria) entra in tick: la converte il chiamante.
//
// Tre regole in piu', dal mandato di fase B1:
//  · il primo campione dopo l'avvio NON e' un colpo: «sento» nasce solo da un cambio osservato
//    fra due catture;
//  · un cambio osservato nello stesso intervallo in cui QUESTO apparecchio ha scritto la propria
//    linea temporale (W2, `link_engine_set_bpm_and_beat_at_time` al confine di sezione) NON e'
//    un colpo: si riparte da quel valore (`ownTimelineWriteSinceLastSample`);
//  · un colpo falso isolato durante l'assenza ritarda il «non sento» di una soglia, non lo
//    annulla: e' la forma stessa della regola (l'ultimo colpo vero fissa l'orologio).
// Con Link spento dall'app (`enabled_` del ponte) i campi della cattura sono zero e il segnale
// riparte da capo: non si sente nessuno.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct DirectorHeardSample: Equatable {
    /// `enabled_` del ponte: a `false` i due campi sotto sono zero e non dicono niente.
    let linkEnabled: Bool
    /// `ABLLinkIsPlaying(state)`.
    let isPlaying: Bool
    /// `ABLLinkTimeForIsPlaying(state)`, tick locali.
    let timeForIsPlaying: UInt64
}

struct DirectorHeardTracker: Equatable {

    /// L'ultima cattura vista (`nil` prima della prima).
    let lastSample: DirectorHeardSample?
    /// Il tick dell'ultimo colpo vero (`nil` = nessun colpo ancora).
    let lastHitAt: UInt64?

    /// Prima di ogni cattura, e a Link spento.
    static let start = DirectorHeardTracker(lastSample: nil, lastHitAt: nil)

    struct Verdict: Equatable {
        /// Il segnale, adesso.
        let heard: Bool
        /// Questa cattura e' stata un colpo vero.
        let hit: Bool
        /// Lo stato da tenere per la prossima cattura.
        let next: DirectorHeardTracker
    }

    /// Una cattura, il tick di adesso, la soglia in tick, e se fra la cattura precedente e questa
    /// l'apparecchio ha scritto la propria linea temporale.
    func observe(sample: DirectorHeardSample,
                 now: UInt64,
                 thresholdTicks: UInt64,
                 ownTimelineWriteSinceLastSample: Bool) -> Verdict {
        guard sample.linkEnabled else {
            return Verdict(heard: false, hit: false, next: .start)
        }
        guard let previous = lastSample else {
            // Il primo campione non e' un colpo.
            return Verdict(heard: false, hit: false,
                           next: DirectorHeardTracker(lastSample: sample, lastHitAt: nil))
        }
        let changed = previous.isPlaying != sample.isPlaying
                   || previous.timeForIsPlaying != sample.timeForIsPlaying
        let hit = changed && !ownTimelineWriteSinceLastSample
        let hitAt: UInt64? = hit ? now : lastHitAt
        let heard: Bool
        if let at = hitAt, now >= at {
            heard = now - at < thresholdTicks
        } else {
            heard = false
        }
        return Verdict(heard: heard, hit: hit,
                       next: DirectorHeardTracker(lastSample: sample, lastHitAt: hitAt))
    }
}
