import Foundation

// === A411 · SOLO-INERTE (18/10/2026) — IL LUCCHETTO DEL MOTORE E LE FACCE DEL SOLO ===
// Fonti: LIBRO, riga 2026-07-01 «Standalone = INERTE / ingaggio Link consapevole (role-gated)»; Mauro, chat
// del referee del 17/10/2026, riportato nel mandato: «SOLO vuol dire collegamento OFF. Nessun contatto con
// l'esterno tramite Peer o LINK.»; mandato del referee «SOLO-INERTE · EMISSIONE 2», §2.4 e §2.5.
//
// §2.4 — IL LUCCHETTO. Link in Solo è spento (`LinkActivationDecision`), ma il motore non si fida
// dell'accensione: anche con Link attivo per qualunque ragione, nel Solo fa ciò che fa il Solo a Link spento,
// già costruito e collaudato (`FreshStartBranchDecision`, ramo standalone; A364 P1 c). Sulle strade del
// motore che toccano Link:
//  · entra: niente tempo adottato dal richiamo del tempo, niente Play né Stop dal richiamo avvio/stop,
//    niente correzione di fase a ogni buffer (né assert del Direttore né `sync_phase`);
//  · esce: niente avvio («suona»), niente tempo (all'avvio di sezione, `setBPM`, al confine di sezione),
//    niente Stop, niente probe che committa;
//  · si legge: l'avvio fresco e la ripresa dopo un'interruzione vedono Link spento.
// «Solo» è il ruolo del player (`PlayerRoleDecision` `.solo`): il ruolo Solo, e anche Direttore o Follower
// con la levetta spenta (A394). DA SOLO è uno stato del Follower, non il Solo: non c'entra.
// Una regola sola (`isInert`), letta dal motore su ogni strada col nome della strada (`passes`).
//
// §2.5 — LE FACCE. In Solo ogni schermo mostra ciò che mostra a Link spento: la spia «Link» e la striscia
// «Link lost» no (il Solo passa alla regola della spia la levetta spenta), il badge del ruolo no. Unica
// eccezione voluta: il menu Mode (con le righe Peers e BPM) segue la levetta, non lo specchio
// dell'accensione, altrimenti in Solo sparirebbe e non si potrebbe più scegliere Director.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum SoloInertDecision {

    /// Le strade del motore che toccano Link (mandato §2.4), col nome che va nella riga di registro.
    enum Path: String, CaseIterable {
        /// Entra — il richiamo del tempo di Link (`link_engine_set_tempo_callback`).
        case sessionTempo = "tempo-dalla-sessione"
        /// Entra — il richiamo avvio/stop di Link (`link_engine_set_start_stop_callback`).
        case sessionTransport = "avvio-stop-dalla-sessione"
        /// Entra — la correzione di fase a ogni buffer (assert del Direttore, `link_engine_sync_phase`).
        case phaseCorrection = "correzione-di-fase"
        /// Esce — «suona» (`link_engine_start_at_beat_zero`, `link_engine_start_at_beat`).
        case startWrite = "avvio-verso-link"
        /// Esce — il tempo (`link_engine_set_bpm`: avvio di sezione, `setBPM`, tap tempo).
        case tempoWrite = "tempo-verso-link"
        /// Esce — il tempo al confine di sezione (W2, `link_engine_set_bpm_and_beat_at_time`).
        case boundaryTempoWrite = "tempo-al-confine-verso-link"
        /// Esce — lo Stop (`link_engine_stop` in `stopSync`).
        case stopWrite = "stop-verso-link"
        /// Esce — il probe che cattura e committa (`link_engine_probe_session`, testa di `start()`).
        case sessionProbe = "probe-con-commit"
        /// Si legge — l'interruttore del ponte (avvio fresco, ripresa dopo un'interruzione).
        case linkSwitchRead = "interruttore-del-ponte"
    }

    /// Il lucchetto: `true` = il motore tratta Link come spento.
    static func isInert(role: LinkMode, userLinkEnabled: Bool) -> Bool {
        PlayerRoleDecision.playerRole(role: role, userLinkEnabled: userLinkEnabled) == .solo
    }

    /// Il lucchetto letto su una strada: `true` = il motore passa da Link come oggi (Direttore, Follower);
    /// `false` = nel Solo la strada è chiusa. La stessa regola per ogni strada: il nome serve al registro.
    static func passes(_ path: Path, role: LinkMode, userLinkEnabled: Bool) -> Bool {
        !isInert(role: role, userLinkEnabled: userLinkEnabled)
    }

    /// L'interruttore di Link come lo legge il motore (`FreshStartBranchDecision`, ripresa dopo
    /// un'interruzione): quello del ponte (`link_engine_is_enabled`), spento nel Solo.
    static func engineSeesLinkOn(role: LinkMode, userLinkEnabled: Bool, linkActive: Bool) -> Bool {
        linkActive && passes(.linkSwitchRead, role: role, userLinkEnabled: userLinkEnabled)
    }

    /// §2.5 — l'ingresso «Link acceso dall'utente» di `StatusLightsDecision.lights`: nel Solo spento, così
    /// la riga di stato del player non mostra né la spia «Link» né la striscia «Link lost».
    static func statusLightsUserLinkEnabled(role: LinkMode, userLinkEnabled: Bool) -> Bool {
        userLinkEnabled && !isInert(role: role, userLinkEnabled: userLinkEnabled)
    }

    /// §2.5 — il badge del ruolo (`LiveView.linkRoleBadge`): Link in rete E un ruolo. Per Direttore e
    /// Follower è lo specchio `linkEnabled` di sempre; nel Solo mai.
    static func roleBadgeVisible(role: LinkMode, userLinkEnabled: Bool, linkActive: Bool) -> Bool {
        linkActive && !isInert(role: role, userLinkEnabled: userLinkEnabled)
    }

    /// §2.5 — il menu Mode e le righe Peers e BPM dello stesso blocco (`SettingsView`): la levetta.
    /// Lo specchio dell'accensione entra per essere ignorato: in Solo è spento anche a levetta accesa.
    static func modeMenuVisible(userLinkEnabled: Bool, appLinkEnabled: Bool) -> Bool {
        userLinkEnabled
    }
}

/// §2.7 — la riga del lucchetto quando scarta qualcosa che arriva da Link, a frequenza limitata se il
/// richiamo si ripete: il primo scarto si scrive subito, poi al più una riga ogni `intervalTicks`, col
/// numero degli scarti dall'ultima riga scritta (lui compreso). Una per strada, nel motore su audioQueue.
struct SoloInertDiscardLog: Equatable {
    /// Gli scarti non ancora scritti in una riga.
    private(set) var unreported: Int
    /// L'ora (mach ticks) dell'ultima riga scritta; `nil` = mai.
    private(set) var lastWrittenTicks: UInt64?

    static let start = SoloInertDiscardLog(unreported: 0, lastWrittenTicks: nil)

    /// Uno scarto all'ora `now`: rende quanti scarti scrivere adesso, o `nil` se la riga aspetta.
    /// Un'ora che torna indietro conta come intervallo passato.
    mutating func noteDiscard(now: UInt64, intervalTicks: UInt64) -> Int? {
        unreported += 1
        if let last = lastWrittenTicks, now >= last, now - last < intervalTicks {
            return nil
        }
        let count = unreported
        unreported = 0
        lastWrittenTicks = now
        return count
    }
}
