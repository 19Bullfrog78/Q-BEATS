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
// Ratifiche: LIBRO `2026-09-11` «CRITERIO GENERALE DEL PERIMETRO DEL FOLLOWER».
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum FollowerLinkWriteDecision {

    /// W1 — all'avvio orchestrato di una sezione il tempo si scrive anche su Link?
    static func writesTempoAtOrchestratedStart(role: LinkMode, userLinkEnabled: Bool) -> Bool {
        !FollowerDecision.isFollower(role: role, userLinkEnabled: userLinkEnabled)
    }

    /// W4 — all'ingresso in una sessione condivisa si scrive «si suona» su Link?
    static func writesIsPlayingAtJoin(role: LinkMode, userLinkEnabled: Bool) -> Bool {
        !FollowerDecision.isFollower(role: role, userLinkEnabled: userLinkEnabled)
    }
}
