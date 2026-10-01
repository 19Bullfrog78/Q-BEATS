import Foundation

// === A386 · FASE B2c (2D) — LA LINEA DEL TEMPO PROPRIA DEL FOLLOWER DA SOLO ===
// In IN SYNC la correzione di fase fa due lavori insieme (misurato sui log del collaudo
// dell'01/10/2026, referto B2c §1.4):
//  1. tiene il click sulla linea del tempo di Link — tempo e fase della sessione;
//  2. tiene il click sull'ORA dell'apparecchio. I buffer audio a tratti arrivano in ritardo sul
//     tempo reale (nel log `A386_BUG_TEMPO_iPad.txt`, mentre si apre il Centro di Controllo per
//     il Wi-Fi: 267 ms accumulati in venti secondi di DA SOLO); la correzione, che a ogni buffer
//     riporta la posizione sul battito previsto per l'ora d'uscita, li riassorbe. A regime lo
//     scarto resta entro una decina di millisecondi e torna a zero (log A1 e C3).
// In DA SOLO il primo lavoro si deve fermare (decisione del referee: il click non segue ne' il
// tempo ne' la fase di Link). Il secondo no: senza, ogni ritardo resterebbe addosso al click
// fino a fine canzone, e il Follower suonerebbe in ritardo sulla band che continua.
//
// Questa e' la linea che prende il posto di Link in DA SOLO: un'ancora (ora, battito) e un
// tempo. Nessuna rete, nessun altro apparecchio: solo l'orologio dell'apparecchio e il tempo
// della propria sezione. Il motore la ancora al primo buffer del tratto sul proprio orologio —
// alla posizione in cui IN SYNC l'ha lasciato, senza salto — e a ogni buffer riporta la
// posizione sul battito che la linea da' per l'ora d'uscita: la stessa meccanica di IN SYNC,
// con questa linea al posto di quella di Link. A un cambio di tempo della propria canzone la
// linea si butta e si ri-ancora al primo buffer utile.
// La linea e' fatta solo di ore: attraversa un'interruzione (il motore fermo per una
// telefonata) senza perdere la griglia.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct OwnClockTimeline: Equatable {

    /// L'ora dell'ancora, in tick dell'orologio dell'apparecchio.
    let anchorTicks: UInt64
    /// Il battito all'ora dell'ancora.
    let anchorBeat: Double
    /// Il tempo della linea, battiti al minuto.
    let bpm: Double

    /// Il battito all'ora `ticks`. Un'ora prima dell'ancora rende un battito precedente.
    /// Con i tick al secondo o il tempo non validi rende il battito dell'ancora.
    func beat(atTicks ticks: UInt64, ticksPerSecond: Double) -> Double {
        guard ticksPerSecond > 0, ticksPerSecond.isFinite, bpm > 0, bpm.isFinite else {
            return anchorBeat
        }
        let elapsedTicks: Double
        if ticks >= anchorTicks {
            elapsedTicks = Double(ticks - anchorTicks)
        } else {
            elapsedTicks = -Double(anchorTicks - ticks)
        }
        return anchorBeat + elapsedTicks / ticksPerSecond * bpm / 60.0
    }

    /// Di quanto la posizione del motore e' indietro rispetto alla linea, in millisecondi
    /// (positivo = il motore e' in ritardo sull'ora). Solo per il log. Zero con un tempo non valido.
    static func lagMilliseconds(ownBeat: Double, localBeat: Double, bpm: Double) -> Double {
        guard bpm > 0, bpm.isFinite else { return 0 }
        return (ownBeat - localBeat) * 60_000.0 / bpm
    }
}
