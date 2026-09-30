import Foundation

// === A386 · FASE B1 (2D) — RIENTRA: LA CANZONE PROPOSTA, TESTATA ===
// RIENTRA apre sempre la scaletta intera (D4): il musicista sceglie qualsiasi canzone, anche
// gia' suonata. Questa regola dice solo quale canzone PROPORRE preselezionata, e in quale FORMA,
// per quanto il Follower ne sa.
//
// ⚠️ B2b (29-30/09/2026) — LE TRE FORME, foglio CD 2D-QUATER file 1 §0-bis, cablate 1:1 (mandato
// A386 B2b §3.e). `reliable` e' uscito: al suo posto la forma. La tabella, ragione -> canzone:
//  · normale («suggested», bordo pieno):
//      playLate -> la successiva a quella sul velo (la band la sta suonando);
//      aloneSongEnded, directorStoppedWhileAlone, musicianStop -> la successiva: il runner
//      l'ha gia' armata (fine canzone propria; B2b, `stopAndArmNext`), quindi e' la corrente;
//      directorFalseStartWhileAlone -> la STESSA (riarmata dal runner: la corrente);
//      apertura dello show (ragione nulla o `reset`, la lista d'ingresso di A1) -> la 1.
//  · ipotesi («a guess — check the band», tratteggio): SOLO dopo lostWhileStopped -> la canzone
//    del velo (la corrente). L'app sa che il Direttore puo' aver chiuso e riaperto (A2) o la
//    band essere andata avanti; il musicista no.
//  · scelta tua («your pick», bordo pieno): dopo i due rifiuti (armRefusedNotHeard,
//    armRefusedSessionPlaying) la canzone toccata, portata dalla ragione (B2b) — vince anche su
//    una proposta normale; dopo lostWhileArmed la scelta (R2).
//  · nessuna: dopo l'ultima canzone, qualunque sia la ragione (`afterLastSong`: la sessione e'
//    `.fineSetlist`, il runner ha chiuso la scaletta) — anche lostWhileStopped a fine concerto
//    (L5). E fuori catalogo.
// «La corrente» e' `currentSongIdx` del runner DOPO l'azione della macchina sul runner: la
// stanza ricalcola la proposta a ogni transizione e dopo ogni azione sul runner.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct RientraProposal: Equatable {

    /// La forma della riga evidenziata nella scaletta (foglio §0-bis).
    enum Form: Equatable {
        /// «suggested» — bordo pieno ambra.
        case normal
        /// «a guess — check the band» — tratteggio ambra.
        case guess
        /// «your pick» — bordo pieno ambra: la canzone che il musicista ha toccato o scelto.
        case yourPick
        /// Nessuna riga evidenziata, lista in cima.
        case none
    }

    /// La canzone da preselezionare sul velo, `nil` = scaletta aperta senza preselezione.
    let songIdx: Int?
    let form: Form

    static let none = RientraProposal(songIdx: nil, form: .none)

    static func propose(reason: FollowerOutReason?,
                        currentSongIdx: Int,
                        songCount: Int,
                        afterLastSong: Bool) -> RientraProposal {
        guard songCount > 0, currentSongIdx >= 0, currentSongIdx < songCount else { return .none }
        if afterLastSong { return .none }
        func valid(_ idx: Int) -> Int? {
            (idx >= 0 && idx < songCount) ? idx : nil
        }
        func normal(_ idx: Int?) -> RientraProposal {
            guard let idx = idx else { return .none }
            return RientraProposal(songIdx: idx, form: .normal)
        }
        switch reason {
        case nil, .reset?:
            // La lista d'ingresso (A1): la 1, normale (punto 21 del foglio).
            return normal(valid(0))
        case .playLate?:
            return normal(valid(currentSongIdx + 1))
        case .aloneSongEnded?, .directorStoppedWhileAlone?, .musicianStop?, .directorFalseStartWhileAlone?:
            return normal(currentSongIdx)
        case .lostWhileStopped?:
            return RientraProposal(songIdx: currentSongIdx, form: .guess)
        case .lostWhileArmed(let chosen)?, .armRefusedNotHeard(let chosen)?, .armRefusedSessionPlaying(let chosen)?:
            guard let idx = valid(chosen) else { return .none }
            return RientraProposal(songIdx: idx, form: .yourPick)
        }
    }
}
