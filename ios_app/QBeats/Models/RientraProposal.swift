import Foundation

// === A386 · FASE B1 (2D) — RIENTRA: LA CANZONE PROPOSTA, TESTATA ===
// RIENTRA apre sempre la scaletta intera (D4): il musicista sceglie qualsiasi canzone, anche
// gia' suonata. Questa regola dice solo quale canzone PROPORRE preselezionata, per quanto il
// Follower ne sa (decisione del referee, A-TER §2 e §7, con R2 e D7-bis dal mandato di fase B1):
//  1. FUORI per un Play arrivato oltre mezza battuta sul velo della canzone N: la band sta
//     suonando N -> si propone N+1, se esiste;
//  2. FUORI da armato perche' il Direttore non si sente piu' (R2): la canzone che il musicista
//     aveva scelto;
//  3. FUORI da DA SOLO per una falsa partenza del Direttore (D7-bis, Stop entro la prima
//     battuta dal Play): la STESSA canzone;
//  4. altrimenti, se il runner e' in `.standby` su una canzone mai partita (tipico dopo D1 e a
//     fine DA SOLO): quella (`currentSongIdx`);
//  5. altrimenti la successiva a quella in cui si trova; se non esiste, nessuna proposta.
// Armato a sessione in moto, o senza sentire il Direttore: la proposta non e' affidabile
// (limite v1, dichiarato, non corretto). Dopo un `reset` non c'e' show: nessuna proposta.
// «Runner in `.standby` su una canzone mai partita» = la sessione e' `.standby`: la partenza la
// cancella (`.starting`/`.playing`), quindi `.standby` vuol dire armata e mai partita.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct RientraProposal: Equatable {

    /// La canzone da preselezionare sul velo, `nil` = scaletta aperta senza preselezione.
    let songIdx: Int?
    /// Falso quando il Follower non puo' sapere dove sta la band (limite v1).
    let reliable: Bool

    static let none = RientraProposal(songIdx: nil, reliable: true)

    static func propose(reason: FollowerOutReason?,
                        sessionIsStandby: Bool,
                        currentSongIdx: Int,
                        songCount: Int) -> RientraProposal {
        let reliable: Bool
        switch reason {
        case .armRefusedSessionPlaying?, .armRefusedNotHeard?:
            reliable = false
        default:
            reliable = true
        }
        guard songCount > 0, currentSongIdx >= 0, currentSongIdx < songCount else {
            return RientraProposal(songIdx: nil, reliable: reliable)
        }
        func next(after idx: Int) -> Int? {
            idx + 1 < songCount ? idx + 1 : nil
        }
        let idx: Int?
        switch reason {
        case nil, .reset?:
            idx = nil
        case .playLate?:
            idx = next(after: currentSongIdx)
        case .lostWhileArmed(let chosen)?:
            idx = (chosen >= 0 && chosen < songCount) ? chosen : nil
        case .directorFalseStartWhileAlone?:
            idx = currentSongIdx
        default:
            idx = sessionIsStandby ? currentSongIdx : next(after: currentSongIdx)
        }
        return RientraProposal(songIdx: idx, reliable: reliable)
    }
}
