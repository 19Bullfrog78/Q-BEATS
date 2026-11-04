import Foundation

// === A425 (04/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3a: UN'ORIGINE SOLA PER L'AVVIO DEL CLICK (P1) ===
// Il fatto (referto A423, par. 3.1 a; mandato A425, par. 2.1). La ripresa del click a un battito (`start(resumeAtBeat:)`, le
// ripartenze automatiche fuori dal coordinatore) scatta alla battuta dopo contando da `_startAbsoluteBeat`; il DSP mette il battito
// scattato nella battuta contando dalla SUA origine, il battito passato a `metronome_reset_for_start` (`setBeatPosition`,
// core_engine/MetronomeDSP.cpp:262-282). Fino ad A424 `_startAbsoluteBeat` era la proiezione del sequencer MIDI all'ora d'uscita
// prevista del primo buffer (circa 0,09 battiti dopo l'origine al Play fresco, 0,04-0,05 all'ingresso del Follower), non l'origine
// del DSP: il primo click dopo lo scatto poteva non essere l'«uno» (il 24/10, 38,5709 a 121 in 4/4 scattava a 40,094321, che il DSP
// mette sul battito 41 della sua griglia: il «due»), mentre la grafica diceva «1». Da A425 `_startAbsoluteBeat` è l'origine del DSP,
// scritta subito dopo ogni `metronome_reset_for_start`: lo scatto sta sulla griglia del DSP e il primo click dopo lo scatto è l'«uno»
// accentato. Il Direttore fuori da una canzone scrive su Link lo stesso battito scattato (`link_engine_start_at_beat`, alla ripresa):
// cambia il valore (40,0 invece di 40,094321), non è una scrittura nuova; il Solo non scrive (lucchetto A411).
// Qui l'aritmetica dello scatto, che il motore chiama, e la posizione che il DSP ne ricava (la formula di `setBeatPosition`, per il
// banco: il DSP non si tocca).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

enum ResumeSnapDecision {

    /// Il battito scattato: dall'origine, la prima battuta intera non prima del battito (`ceil` dei battiti relativi diviso i
    /// battiti per battuta), di nuovo nella numerazione del battito. È l'aritmetica dello scatto di `start()` e del battito che il
    /// Direttore scrive su Link alla ripresa.
    static func snappedBeat(beat: Double, origin: Double, beatsPerBar: Double) -> Double {
        let relativePhase = beat - origin
        let snappedRelative = ceil(relativePhase / beatsPerBar) * beatsPerBar
        return origin + snappedRelative
    }

    /// La posizione che il DSP ricava da un battito: il prossimo battito della sua griglia (l'origine più un intero, con mezzo
    /// campione di tolleranza) e il suo posto nella battuta (0 = l'«uno» accentato).
    struct DSPPosition: Equatable {
        let nextBeat: Double
        let beatInBar: Int
    }

    /// `MetronomeDSP::setBeatPosition` (core_engine/MetronomeDSP.cpp:262-282), la parte che decide il battito e la battuta:
    /// `relative = beatPosition − origine`, `ceil(relative − ε)` con ε mezzo campione in battiti, il resto della divisione per i
    /// battiti per battuta (mai negativo), il prossimo battito = origine + indice.
    static func dspPosition(beatPosition: Double, dspOrigin: Double, beatsPerBar: Int,
                            sampleRate: Double, bpm: Double) -> DSPPosition {
        let epsilon = 0.5 / sampleRate * (bpm / 60.0)
        let relative = beatPosition - dspOrigin
        let nextRelativeIdx = ceil(relative - epsilon)
        let bpb = Int64(max(beatsPerBar, 1))
        var beatInBar = Int64(nextRelativeIdx) % bpb
        if beatInBar < 0 { beatInBar += bpb }
        return DSPPosition(nextBeat: dspOrigin + nextRelativeIdx, beatInBar: Int(beatInBar))
    }
}
