import Foundation

// === A386 · FASE B2c (2D) — IL TEMPO DEL CLICK, MISURATO SUI CAMPIONI ===
// In DA SOLO la correzione di fase non gira piu', e con lei spariscono le righe
// «[LINK] Phase sync» da cui al collaudo dell'01/10/2026 si e' ricavato il tempo del click.
// La riga al secondo di DA SOLO (`AudioEngine`, etichetta `[Q-BEATS][2D][DA-SOLO]`) porta al
// loro posto un tempo MISURATO, non creduto: il motore segna per ogni battito il campione del
// flusso d'uscita su cui cade (buffer consegnati al player, uno dietro l'altro), e fra due
// righe il tempo e' `battiti × campioni al secondo × 60 / campioni`. E' il tempo che esce
// dall'altoparlante, qualunque cosa creda il motore.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum ClickTempoMeasure {

    /// Battiti al minuto fra due battiti del click. `nil` se non c'e' niente da misurare
    /// (nessun battito nuovo, campioni non crescenti, frequenza di campionamento non valida).
    static func bpm(beats: Int, samples: Int64, sampleRate: Double) -> Double? {
        guard beats > 0, samples > 0, sampleRate > 0, sampleRate.isFinite else { return nil }
        return Double(beats) * sampleRate * 60.0 / Double(samples)
    }

    struct BarPosition: Equatable {
        /// Battuta dentro la sezione, da 1.
        let bar: Int
        /// Battito dentro la battuta, da 1.
        let beatInBar: Int
    }

    /// La posizione di battuta dell'ultimo battito suonato nella sezione. `sectionBeat` e' il
    /// contatore di sezione del motore (1 = primo battito). `nil` se la sezione non conta
    /// (contatore a zero: sezione appena cambiata, o sezione in loop) o la misura e' zero.
    static func barPosition(sectionBeat: Int, beatsPerBar: UInt32) -> BarPosition? {
        guard sectionBeat > 0, beatsPerBar > 0 else { return nil }
        let bpb = Int(beatsPerBar)
        return BarPosition(bar: (sectionBeat - 1) / bpb + 1,
                           beatInBar: (sectionBeat - 1) % bpb + 1)
    }
}
