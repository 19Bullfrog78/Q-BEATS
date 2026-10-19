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
//  · E la politica dello sfondo non l'ha sospeso (sfondo a click fermo; da A412 col Direttore muto in canzone
//    non si sospende, e la valuta il motore: blocco «A412» qui sotto),
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
    /// Sospeso dalla politica dello sfondo (`suspendsOnBackground`, qui sotto; da A412 la valuta il motore,
    /// `AudioEngine.sceneEnteredBackground`: prima `QBeatsApp` con `setLinkBackgroundSuspended`, uscita).
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

    // === A412 (18/10/2026) — LA POLITICA DELLO SFONDO, CON IL DIRETTORE MUTO IN CANZONE ===
    // Il fatto (BUGS, `TD-link-spento-in-secondo-piano-durante-lo-show`, con la marcatura del 05/10; referto
    // A409, §5.2 e §8.11). La politica del 02/10 (LIBRO, riga 2026-10-02 «L'APP IN SFONDO RESTA COM'È»): al
    // passaggio in sfondo, con Link in rete e il click fermo, Link si sospende; al ritorno in primo piano si
    // riprende. Ma col Direttore muto in canzone il click è fermo e la canzone suona per la band: sospendere
    // Link toglieva il Direttore dalla sessione. Decisione del referee del 05/10 (mandato A396, §2.3 [R]) e
    // mandato «DIRETTORE-IN-CRISI-PASSO-2», §2.8: col Direttore muto in canzone in sfondo Link non si
    // sospende. Per tutto il resto la politica è identica, e si valuta solo ai passaggi di sfondo e primo
    // piano. Il suo esito è l'ingresso `backgroundSuspended` della regola qui sopra: la strada resta una sola
    // (`AudioEngine.applyLinkActivationQ`). Niente `beginBackgroundTask` (scelta T9): se iOS sospende l'app,
    // Link e la ripetizione si fermano lo stesso.

    /// Al passaggio in sfondo Link si sospende? In rete, click fermo, e il Direttore non è muto in canzone.
    static func suspendsOnBackground(linkActive: Bool, clickPlaying: Bool, directorSilentInSong: Bool) -> Bool {
        linkActive && !clickPlaying && !directorSilentInSong
    }
}
