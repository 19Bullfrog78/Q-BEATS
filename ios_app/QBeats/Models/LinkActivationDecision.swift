import Foundation

// === A411 · SOLO-INERTE (18/10/2026) — LINK IN RETE SOLO CON UN RUOLO: UNA REGOLA SOLA ===
// Fonti: LIBRO, riga 2026-07-01 «Standalone = INERTE / ingaggio Link consapevole (role-gated)»: in
// Standalone il Link non è ingaggiato, anche con apparecchi raggiungibili in rete; l'aggancio solo alla
// scelta cosciente di Direttore o Follower. Mandato del referee «SOLO-INERTE · EMISSIONE 2», §2.2.
// ABLLink.h (LinkKit 4.0): da attivo l'apparecchio si annuncia sulla rete locale e apre le connessioni
// con gli altri, ed è attivo appena nato (:56-62); la levetta del pannello la muove solo l'utente (:64-69).
//
// La regola: Link è attivo (`ABLLinkSetActive(true)`) se e solo se
//  · la levetta del pannello è accesa (`ABLLinkIsEnabled`, specchio `linkUserEnabled`),
//  · E il ruolo del player è Direttore o Follower (`PlayerRoleDecision.playerRole` diverso da `.solo`),
//  · E la politica dello sfondo non l'ha sospeso (`QBeatsApp`, sfondo a click fermo: invariata),
//  · E l'app non si sta chiudendo (`disableLinkOnTerminate`).
// La quarta condizione è la mano «chiusura dell'app» del §2.2 detta come ingresso: senza, quella mano non
// avrebbe niente da cambiare e non passerebbe dalla regola.
// L'esito lo applica una funzione sola del motore (`AudioEngine.applyLinkActivationQ`, su audioQueue), che
// scrive anche lo specchio `linkEnabled`. Tutte le mani cambiano un ingresso e passano da lì: avvio, levetta
// del pannello, cambio di ruolo, sfondo e primo piano, chiusura del pannello, toggle del Debug, chiusura
// dell'app. La levetta Q-BEATS non la cambia e non ci prova (ABLLink.h:64-69).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct LinkActivationDecision: Equatable {

    /// La prima condizione che tiene Link spento, nell'ordine della regola: la dice la riga di registro.
    enum OffReason: String, Equatable {
        case userLinkOff = "levetta-spenta"
        case soloRole = "ruolo-solo"
        case backgroundSuspended = "sospeso-sfondo"
        case appTerminating = "chiusura"
    }

    /// La levetta del pannello (`ABLLinkIsEnabled`, specchio `linkUserEnabled`).
    let userLinkEnabled: Bool
    /// Il ruolo scelto nel menu Mode (`currentLinkMode`, copia di coda `_linkMode`).
    let role: LinkMode
    /// Sospeso dalla politica dello sfondo (`QBeatsApp`, `setLinkBackgroundSuspended`).
    let backgroundSuspended: Bool
    /// L'app si sta chiudendo (`disableLinkOnTerminate`).
    let appTerminating: Bool
    /// Il ruolo del player, dalla regola di oggi (A394).
    let playerRole: PlayerRole
    /// L'esito: Link in rete.
    let active: Bool
    /// `nil` quando `active`.
    let offReason: OffReason?

    init(userLinkEnabled: Bool, role: LinkMode, backgroundSuspended: Bool, appTerminating: Bool) {
        self.userLinkEnabled = userLinkEnabled
        self.role = role
        self.backgroundSuspended = backgroundSuspended
        self.appTerminating = appTerminating
        let playerRole = PlayerRoleDecision.playerRole(role: role, userLinkEnabled: userLinkEnabled)
        self.playerRole = playerRole
        if !userLinkEnabled {
            self.offReason = .userLinkOff
        } else if playerRole == .solo {
            self.offReason = .soloRole
        } else if backgroundSuspended {
            self.offReason = .backgroundSuspended
        } else if appTerminating {
            self.offReason = .appTerminating
        } else {
            self.offReason = nil
        }
        self.active = self.offReason == nil
    }

    /// La regola nuda.
    static func isActive(userLinkEnabled: Bool, role: LinkMode,
                         backgroundSuspended: Bool, appTerminating: Bool) -> Bool {
        userLinkEnabled
            && PlayerRoleDecision.playerRole(role: role, userLinkEnabled: userLinkEnabled) != .solo
            && !backgroundSuspended
            && !appTerminating
    }
}
