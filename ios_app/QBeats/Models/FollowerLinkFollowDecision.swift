import Foundation

// === A386 · FASE B2c (2D) — IL FOLLOWER SEGUE LINK? UNA DECISIONE SOLA, TESTATA ===
// Collaudo dell'01/10/2026 (log `A386_BUG_TEMPO_iPad.txt`): il Follower suona DA SOLO la
// canzone 1 a 121, la rete torna col Direttore gia' sulla canzone 2 a 141, e il click del
// Follower passa a 141 con la macchina ancora DA SOLO; la sua canzone finisce in anticipo.
// Decisione del referee (mandato «A386 · FASE B2c», §2, da 2D-D2 «DA SOLO: il Follower finisce
// la sua canzone»): in DA SOLO il click non segue ne' il tempo ne' la fase di Link. Suona la
// sua canzone, ai tempi delle sue sezioni, col suo orologio, fino alla fine. Vale anche per un
// apparecchio su Link che non e' il Direttore (caso E4): non puo' imporre il suo tempo a un
// Follower da solo.
//
// Le strade da cui tempo e fase della sessione entrano nel motore mentre suona sono due
// (mappa nel referto B2c): il richiamo del tempo di Link (adotta il tempo della sessione) e la
// correzione di fase a ogni buffer (riporta la posizione sulla linea del tempo di Link: e'
// lei, buffer per buffer, che fa andare il click al tempo della sessione). Tutte e due girano
// su audioQueue e leggono QUESTA decisione dalla copia della macchina che vive li'.
//
// La regola:
//  · chi non e' Follower (Direttore, Solo, ruolo Follower con Link spento dall'utente): `true`
//    — le strade restano quelle di oggi, questa decisione non le tocca;
//  · Follower IN SYNC: `true` — segue tempo e fase di Link, come oggi;
//  · Follower DA SOLO: `false`;
//  · Follower FUORI: `true`, cioe' come oggi. A motore fermo conta solo il richiamo del tempo,
//    che continua ad adottare il tempo della sessione (non si sente niente; al Play la macchina
//    passa a IN SYNC PRIMA dell'avvio del motore, quindi l'ingresso gira sempre in IN SYNC);
//  · `ownClockUntilStop`: la macchina esce da DA SOLO sempre verso FUORI, e quando esce con uno
//    stop (Stop del Direttore, Stop del musicista) il motore si ferma qualche millisecondo
//    DOPO, da main. In quella coda lo stato dice gia' FUORI ma il motore gira ancora: senza
//    questo ingresso la correzione di fase ripartirebbe per uno o due buffer e sposterebbe il
//    click proprio mentre si ferma. Si alza entrando in DA SOLO; lo abbassano il motore, a ogni
//    arresto e a ogni avvio, e il `reset` della macchina (Link spento dall'utente, cambio di
//    ruolo, END SHOW, uscita dalla stanza: da li' in poi o il motore e' fermo, o l'apparecchio
//    non e' piu' Follower, e se lo ridiventa a motore in moto deve seguire Link come oggi). Lo
//    stato da solo non distingue «FUORI fermo» da «FUORI che si sta fermando dopo DA SOLO»: per
//    questo e' un ingresso.
// Nessun ingresso «collegato» ne' «numero di peer»: la decisione legge la macchina e basta.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum FollowerLinkFollowDecision {

    /// Tempo e fase della sessione Link entrano nel motore?
    static func followsLink(role: LinkMode,
                            userLinkEnabled: Bool,
                            state: FollowerSyncState,
                            ownClockUntilStop: Bool) -> Bool {
        guard FollowerDecision.isFollower(role: role, userLinkEnabled: userLinkEnabled) else {
            return true
        }
        if ownClockUntilStop { return false }
        switch state {
        case .inSync:
            return true
        case .alone:
            return false
        case .out:
            return true
        }
    }

    /// L'orologio proprio dopo una transizione della macchina: `event` e' l'evento appena
    /// applicato, `state` lo stato in cui ha portato. Un `reset` lo abbassa; entrare (o restare)
    /// in DA SOLO lo alza; per ogni altro caso resta com'era (lo abbassa il motore, quando si
    /// ferma o riparte).
    static func ownClockUntilStop(after event: FollowerSyncEvent,
                                  state: FollowerSyncState,
                                  previous: Bool) -> Bool {
        if case .reset = event { return false }
        if case .alone = state { return true }
        return previous
    }

    /// Alla soglia di DA SOLO: il tempo da ridare al motore perche' suoni «ai tempi delle sue
    /// sezioni». Serve solo se il tempo in corso era stato adottato dalla sessione DOPO l'ultimo
    /// tempo dato dalla propria canzone (`adoptedFromLink`); se un cambio di sezione e' gia'
    /// armato, il tempo proprio arriva da solo al prossimo battere e non si tocca niente.
    /// `nil` = niente da ridare.
    static func tempoToRestore(sectionTempo: Double,
                               adoptedFromLink: Double?,
                               sectionChangePending: Bool) -> Double? {
        guard adoptedFromLink != nil, !sectionChangePending else { return nil }
        guard sectionTempo > 0, sectionTempo.isFinite else { return nil }
        return sectionTempo
    }
}
