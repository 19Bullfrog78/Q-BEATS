import Foundation

// === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — CHI È SOLO, CHI DIRETTORE, CHI FOLLOWER ===
// Nel codice «Solo» non era una regola: il Solo era ciò che resta (referto A393 §3). Le regole
// pure di ruolo sono due e NON si riscrivono qui, si compongono:
//  · Follower  = `FollowerDecision.isFollower(role:userLinkEnabled:)` (ruolo `.collaborativa`
//    E Link acceso dall'utente — A360);
//  · Direttore = `DirectorSongCloseDecision.closesSongOnStop(role:userLinkEnabled:)` (ruolo
//    `.direttore` E Link acceso dall'utente — A386 B1);
//  · Solo      = tutto il resto.
// Decisione del referee (05/10/2026): è Solo anche il ruolo Direttore con Link spento dall'utente
// e il ruolo Follower con Link spento dall'utente (A393 §3.2, casi 3 e 4). L'interruttore che
// l'app muove in sfondo (`link_engine_set_enabled`, specchio `linkEnabled`) NON conta: entra
// qui, come in `FollowerDecision`, solo perché il banco provi che non conta.
// In M1 non la legge ancora nessuna vista: la legge il lampo del pedale (`MIDILampDecision`,
// da `AudioEngine.executeMIDIAction`) e, dai mandati M2/M3, la composizione del player.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum PlayerRole: String, Equatable {
    case solo, direttore, follower
}

struct PlayerRoleDecision: Equatable {
    /// Il ruolo scelto nelle impostazioni (`AppSettings.linkMode`, specchio `currentLinkMode`).
    let role: LinkMode
    /// Link acceso dall'utente nel pannello Link (`ABLLinkIsEnabled`, specchio `linkUserEnabled`).
    let userLinkEnabled: Bool
    /// L'interruttore dell'app (specchio `linkEnabled`): entra per essere ignorato.
    let appLinkEnabled: Bool
    /// L'esito.
    let playerRole: PlayerRole

    init(role: LinkMode, userLinkEnabled: Bool, appLinkEnabled: Bool) {
        self.role = role
        self.userLinkEnabled = userLinkEnabled
        self.appLinkEnabled = appLinkEnabled
        self.playerRole = Self.playerRole(role: role, userLinkEnabled: userLinkEnabled)
    }

    /// La regola nuda, composta dalle due di oggi: prima il Follower, poi il Direttore, poi Solo.
    /// Le due condizioni sono esclusive per costruzione (ruoli diversi): l'ordine non cambia l'esito.
    static func playerRole(role: LinkMode, userLinkEnabled: Bool) -> PlayerRole {
        if FollowerDecision.isFollower(role: role, userLinkEnabled: userLinkEnabled) {
            return .follower
        }
        if DirectorSongCloseDecision.closesSongOnStop(role: role, userLinkEnabled: userLinkEnabled) {
            return .direttore
        }
        return .solo
    }
}
