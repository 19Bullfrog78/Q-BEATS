import Foundation

// === A360 (16/09/2026) — LA REGOLA DEL FOLLOWER: UN SOLO POSTO, TESTATO ===
// Fino a oggi sei viste decidevano da sole se l'apparecchio è Follower, tutte con
// `audioEngine.currentLinkMode == .collaborativa` (BOX5 «Chi comanda il trasporto»,
// V48), e nessuna guardava l'interruttore di Link. Da qui esce UNA regola sola:
//
//     Follower  =  ruolo `.collaborativa`  E  Link acceso DALL'UTENTE.
//
// I due interruttori di Link sono due cose diverse (mappa A360, §1):
//  · quello dell'UTENTE è `ABLLinkIsEnabled` (ABLLink.h: «only controllable by the
//    user via the Link settings dialog») — lo muove solo chi apre il pannello Link;
//  · quello dell'APP è `link_engine_set_enabled` (`ABLLinkSetActive`), che l'app
//    spegne da sola in background a click fermo e riaccende al ritorno (`QBeatsApp`).
// Andare in background e tornare NON cambia il ruolo: per questo il secondo
// interruttore entra qui SOLO per essere ignorato — `appLinkEnabled` è un ingresso
// della regola perché il banco possa provare che non conta, non perché conti.
// Con Link spento dall'utente l'apparecchio si comporta da Solo in tutto (velo
// «Tap anywhere», tocco che fa partire, fascia intera): chi ha scelto Follower una
// volta può sempre suonare da solo spegnendo Link dal pannello.
//
// `nobodyConnected` è il caso della lastra ⑧ (foglio CD 11/09
// IL-FOLLOWER-NON-TOCCA-IL-TRASPORTO): Follower con Link acceso e nessun apparecchio
// collegato. L'app sa solo «almeno uno, sì o no» (BOX5 «LIMITI DELLA LIBRERIA LINK» ①):
// il velo nomina la conseguenza, mai chi manca.
//
// Ratifiche: LIBRO `2026-09-09/11` «IL TRASPORTO È DEL DIRETTORE» · `2026-09-10` «NIENTE
// START LOCAL» · `2026-09-11` «CRITERIO GENERALE DEL PERIMETRO DEL FOLLOWER». Questa regola
// supera la riga BOX5 «Chi comanda il trasporto» (V48), che leggeva il solo ruolo.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct FollowerDecision: Equatable {

    /// Il ruolo scelto nelle impostazioni (`AppSettings.linkMode`, mirror `currentLinkMode`).
    let role: LinkMode
    /// Link acceso dall'utente nel pannello Link (`ABLLinkIsEnabled`).
    let userLinkEnabled: Bool
    /// L'interruttore dell'app (`link_engine_set_enabled`): entra per essere ignorato.
    let appLinkEnabled: Bool
    /// Almeno un apparecchio collegato (`linkIsConnected`).
    let anyPeerConnected: Bool

    /// L'apparecchio è Follower: non manda STOP a Link, non ha PLAY/STOP/KILL BASE,
    /// il tocco sul velo non fa niente, il pedale non avvia né ferma né sposta lo show.
    let isFollower: Bool
    /// Follower con Link acceso e nessuno collegato: il velo aggiunge le due righe
    /// della lastra ⑧ («No device connected» · «nothing will start from here»).
    let nobodyConnected: Bool

    init(role: LinkMode, userLinkEnabled: Bool, appLinkEnabled: Bool, anyPeerConnected: Bool) {
        self.role = role
        self.userLinkEnabled = userLinkEnabled
        self.appLinkEnabled = appLinkEnabled
        self.anyPeerConnected = anyPeerConnected
        let follower = Self.isFollower(role: role, userLinkEnabled: userLinkEnabled)
        self.isFollower = follower
        self.nobodyConnected = follower && !anyPeerConnected
    }

    /// La regola nuda, per chi non ha il collegamento sotto mano (lo stop del motore,
    /// su audioQueue, legge le sue due copie e nient'altro).
    static func isFollower(role: LinkMode, userLinkEnabled: Bool) -> Bool {
        role == .collaborativa && userLinkEnabled
    }
}
