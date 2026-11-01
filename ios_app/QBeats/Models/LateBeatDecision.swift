import Foundation

// === A421 (24/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 2: IL BATTITO IN RITARDO DOPO UNA CORREZIONE (U9) ===
// Il fatto (referto A419, §3.1.5 e §3.2.c; `core_engine/MetronomeDSP.cpp`, `setBeatPositionTimeOnly`). La correzione di fase
// (la fase di Link sul Follower e sul Direttore che segue Link; l'orologio proprio del Follower DA-SOLO) porta la posizione
// del DSP da `before` a `after`. Il DSP tiene il battito pendente «in sé»: la sua etichetta nella linea nuova è quella di
// «adesso» più la distanza fisica al pendente, arrotondata (`pendingRelIdx = round(relative + aheadBeats)`); sotto mezzo
// battito di correzione l'etichetta è la stessa, da mezzo in su salta di un intero (il «re-map»: cambia il nome, non la
// fisica). Se la correzione in avanti scavalca il pendente, il suo campione è nel passato del cursore nuovo e il DSP lo fa
// uscire al primo campione del buffer (il «fire-asap», `MetronomeDSP.cpp:351-353`): un click in ritardo dell'ampiezza
// dello scavalco. Le suddivisioni no: si rifanno dal prossimo confine di battito, in avanti (`MetronomeDSP.cpp:356-365`):
// una suddivisione scavalcata si salta, non esce in ritardo.
//
// La regola (mandato «USCITA AUDIO PASSO 2a PEZZO 2», par. 2.1 U9; decisione del referee del 23/10): il battito del
// fire-asap si conta e non si suona, solo se uscirebbe in ritardo di almeno un buffer (10,67 ms a 48 kHz, 11,6 a 44,1);
// una regola sola per Direttore e Follower, in Swift, nei due punti della correzione; niente in core_engine. Il battito
// zittito non scrive campioni e non arma la coda del click. Una correzione normale (5364 in una canzone, media 0,0009
// battiti, massima 0,0097: prova A0 del 21/10 [R]) non zittisce mai: il ritardo massimo che può dare è la correzione
// stessa, 4,8 ms a 121 BPM.
// L'origine è quella che Swift passa a `metronome_reset_for_start` (0 al Play fresco e all'ingresso del Follower; l'«uno»
// del rientro): la griglia del DSP sta all'origine più un intero. Che la posizione del DSP e quella del sequencer MIDI
// (`before`, letta in Swift) coincidano al campione è [Probabile]: si scrivono insieme a ogni avvio e a ogni correzione.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

enum LateBeatDecision {

    /// Il clamp del DSP sulla distanza al pendente (`MetronomeDSP.cpp:325-326`).
    static let maxAheadBeats: Double = 1.5

    /// Il battito pendente prima della correzione: il primo battito della griglia (origine più interi) non prima di `beat`.
    static func pendingBeat(origin: Double, beat: Double) -> Double {
        origin + (beat - origin - 1e-9).rounded(.up)
    }

    /// La distanza fisica al pendente, in battiti, col clamp del DSP.
    static func aheadBeats(origin: Double, beat: Double) -> Double {
        let ahead = pendingBeat(origin: origin, beat: beat) - beat
        return min(max(ahead, 0), maxAheadBeats)
    }

    /// Il battito pendente dopo la correzione, nella linea nuova: il pendente di prima più la parte intera arrotondata della
    /// correzione (il re-map del DSP).
    static func pendingBeatAfter(origin: Double, before: Double, after: Double) -> Double {
        pendingBeat(origin: origin, beat: before) + (after - before).rounded()
    }

    /// Di quanto il battito del fire-asap esce in ritardo, in battiti: la correzione ha scavalcato il pendente. `nil` se non
    /// lo scavalca (il pendente resta davanti, o la correzione è indietro).
    static func lateBeats(origin: Double, before: Double, after: Double) -> Double? {
        guard origin.isFinite, before.isFinite, after.isFinite else { return nil }
        let late = after - pendingBeatAfter(origin: origin, before: before, after: after)
        return late > 1e-9 ? late : nil
    }

    /// Un buffer in secondi.
    static func bufferSeconds(bufferFrames: Int, sampleRate: Double) -> Double? {
        guard bufferFrames > 0, sampleRate > 0, sampleRate.isFinite else { return nil }
        return Double(bufferFrames) / sampleRate
    }

    /// Il battito del fire-asap si zittisce: esce in ritardo di almeno un buffer.
    static func mutesLateBeat(lateBeats: Double?, bpm: Double, bufferFrames: Int, sampleRate: Double) -> Bool {
        guard let late = lateBeats, bpm > 0, bpm.isFinite,
              let buffer = bufferSeconds(bufferFrames: bufferFrames, sampleRate: sampleRate) else { return false }
        return late * 60.0 / bpm >= buffer
    }

    /// Il ritardo in millisecondi, per la riga.
    static func lateMilliseconds(lateBeats: Double?, bpm: Double) -> Double {
        guard let late = lateBeats, bpm > 0, bpm.isFinite else { return 0 }
        return late * 60_000.0 / bpm
    }

    /// Tutto insieme: la correzione da `before` ad `after` zittisce il battito di questo buffer?
    static func mutes(origin: Double, before: Double, after: Double, bpm: Double, bufferFrames: Int, sampleRate: Double) -> Bool {
        mutesLateBeat(lateBeats: lateBeats(origin: origin, before: before, after: after),
                      bpm: bpm, bufferFrames: bufferFrames, sampleRate: sampleRate)
    }
}
