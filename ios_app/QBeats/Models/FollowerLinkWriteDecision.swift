import Foundation

// === RIENTRO-P1 (17/09/2026) — DUE SCRITTURE CHE DAL FOLLOWER NON ESCONO PIU' ===
// A360 ha tolto al Follower lo stop verso Link, A361/A362 l'avvio. Verificando il collaudo
// del 17/09/2026 (referto A364, §3.f e §4.2) ne sono emerse altre due, mai tracciate:
//
//  · W1 — il TEMPO scritto su Link a ogni avvio orchestrato: `SetlistRunner`
//    (`prepareAndStartCurrentSection`) chiama `AudioEngine.setBPM`, che fa
//    `link_engine_set_bpm`. Sul Follower succede a ogni Play del Direttore e a ogni
//    rientro: se il Follower è nella sezione sbagliata scrive nella sessione il tempo
//    sbagliato. All'ingresso il Follower PRENDE il tempo della sessione, non lo dà.
//  · W4 — «SI SUONA» scritto su Link a ogni ingresso: `link_engine_join_running_session`
//    fa `ABLLinkSetIsPlaying(state, true, futureHostTime)`. Il Follower entra solo in una
//    sessione che suona già (A361): il valore non cambia, ma l'ORA dello stato
//    avvio/stop sì, ed è l'ora che i passi successivi useranno per sapere se il
//    Direttore è ripartito. È una scrittura di trasporto che esce dal Follower.
//
// La regola è la stessa di `FollowerDecision` (ruolo `.collaborativa` E Link acceso
// dall'utente): il Follower non scrive; Direttore, Solo e ruolo Follower con Link spento
// dall'utente scrivono come oggi, e il banco lo prova riga per riga.
//
// ⚠️ FUORI DA QUI, di proposito: il tempo che il Follower scrive al CONFINE DI SEZIONE
//    (`link_engine_set_bpm_and_beat_at_time` dal beat callback di `scheduleNextBuffer`)
//    resta com'è — è la decisione 9.1 del referto A364, in mano a Mauro. E il tempo
//    scritto dal metronomo di Q-Studio (`ContentView`) non è un avvio orchestrato.
// ⚠️ MARCATURA A386 · B2c-BIS (01/10/2026) — W2 È ENTRATA QUI, PER LA SOLA PARTE DI «DA SOLO».
//    Decisione di Mauro dell'01/10/2026 («SI SI VA BENISSIMO», sulla proposta del referee):
//    «iPad da solo: non scrive niente in Link. iPad in sync: tutto come hai deciso il 18/09
//    (al cambio di sezione continua a scrivere il suo tempo, se il Direttore tace)». La
//    decisione 9.1 (LIBRO, riga `2026-09-18`) resta com'è e si restringe a IN SYNC. Le righe
//    qui sopra restano come storia: si marcano, non si riscrivono.
//    Perché: in DA SOLO il click ha l'orologio proprio (`OwnClockTimeline`), quindi W2 non gli
//    serve; e a rete tornata W2 scrive nella sessione della band, dove i Follower in sync lo
//    adottano per un istante (referto B2c §11.1).
//    La fonte è la STESSA delle due strade d'ingresso: W2 scrive se e solo se il Follower
//    segue Link (`FollowerLinkFollowDecision.followsLink`) — IN SYNC sì, DA SOLO no, la coda
//    prima dell'arresto no, FUORI come oggi; chi non è Follower come oggi. Una regola sola per
//    «Link entra» e «il tempo esce»: non possono divergere.
//    L'interruttore solo DEBUG di A366 («Follower: tempo al confine (W2)») resta com'è e si
//    combina: sul Follower W2 scrive solo se lo permettono tutti e due. Fuori da DEBUG
//    l'interruttore non esiste e il chiamante passa `true`.
// Ratifiche: LIBRO `2026-09-11` «CRITERIO GENERALE DEL PERIMETRO DEL FOLLOWER».
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum FollowerLinkWriteDecision {

    /// L'esito di W2 a un confine di sezione, con la ragione del salto per la riga di log.
    enum BoundaryTempoWrite: Equatable {
        /// Il tempo della sezione nuova si scrive su Link, come oggi.
        case writes
        /// B2c-BIS: il Follower è sul proprio orologio (DA SOLO, o la coda prima dell'arresto).
        case skippedOwnClock
        /// A366: interruttore solo DEBUG spento, su un Follower che altrimenti scriverebbe.
        case skippedDebugSwitch
    }

    /// W2 — al proprio confine di sezione il tempo della sezione nuova si scrive su Link?
    /// `state` e `ownClockUntilStop` sono le copie della macchina su audioQueue, le stesse che
    /// leggono le due strade d'ingresso. `debugSwitchOn`: l'interruttore solo DEBUG di A366
    /// (`true` dove non esiste). Chi non è Follower scrive sempre, qualunque cosa dicano gli
    /// altri ingressi. Sul Follower l'orologio proprio viene prima dell'interruttore: se W2 si
    /// salta per tutti e due i motivi, la ragione è `skippedOwnClock`.
    static func boundaryTempoWrite(role: LinkMode,
                                   userLinkEnabled: Bool,
                                   state: FollowerSyncState,
                                   ownClockUntilStop: Bool,
                                   debugSwitchOn: Bool) -> BoundaryTempoWrite {
        guard FollowerDecision.isFollower(role: role, userLinkEnabled: userLinkEnabled) else {
            return .writes
        }
        guard FollowerLinkFollowDecision.followsLink(role: role,
                                                     userLinkEnabled: userLinkEnabled,
                                                     state: state,
                                                     ownClockUntilStop: ownClockUntilStop) else {
            return .skippedOwnClock
        }
        return debugSwitchOn ? .writes : .skippedDebugSwitch
    }

    /// W1 — all'avvio orchestrato di una sezione il tempo si scrive anche su Link?
    static func writesTempoAtOrchestratedStart(role: LinkMode, userLinkEnabled: Bool) -> Bool {
        !FollowerDecision.isFollower(role: role, userLinkEnabled: userLinkEnabled)
    }

    /// W4 — all'ingresso in una sessione condivisa si scrive «si suona» su Link?
    static func writesIsPlayingAtJoin(role: LinkMode, userLinkEnabled: Bool) -> Bool {
        !FollowerDecision.isFollower(role: role, userLinkEnabled: userLinkEnabled)
    }
}
