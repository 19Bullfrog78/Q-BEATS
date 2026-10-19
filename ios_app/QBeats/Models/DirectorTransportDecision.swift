import Foundation

// === A412 (18/10/2026) — DIRETTORE IN CRISI, PASSO 2: IL TASTO DELLA FASCIA DURANTE IL SILENZIO ===
// Il fatto (referto A409, §3.1, §5.6, §6.4 e §8.5; referto A410, Aperto 5). Il tasto della fascia del
// Direttore è uno solo, Play/Stop (`TransportView`), e durante il silenzio leggeva `isPlaying` senza
// osservare il motore: la scritta poteva essere vecchia, e il tocco a click muto faceva
// `runner.startCurrentSection`, cioè W1 e il ramo fresco: il Direttore ricominciava la sua sezione e
// spostava la griglia di tutti. E lo Stop voluto col motore già fermo non arrivava alla band.
//
// La regola (mandato §2.4, decisioni di Mauro del 16/10/2026 D2 e D3, LIBRO 2026-09-23 «IN MODALITÀ
// DIRETTORE, A CANZONE IN CORSO, SOLO STOP»), coi glifi e le scritte di oggi:
//  · Direttore muto in canzone, e un tocco adesso farebbe rientrare il click (il coordinatore dice
//    «rientra», nessuna interruzione in corso, servizi audio non persi): il tasto dice Play e il tocco
//    RIENTRA (D2). In pratica succede dopo un reset dei servizi audio, l'unico silenzio che finisce solo
//    con un tocco;
//  · Direttore muto in canzone e un rientro adesso non è possibile (conto non certo, interruzione in
//    corso, servizi audio persi): il tasto dice Stop e il tocco FERMA TUTTA LA BAND e chiude la
//    canzone (D3; D4 (a): a fine pezzo il batterista preme Stop);
//  · fuori dal silenzio: il tasto com'è oggi (`nil`).
// Il pedale playPause segue la stessa regola; il pedale stop è sempre Stop. L'esito si calcola sul motore
// (al battito a 1 s e a ogni cambio del silenzio) e arriva alla vista come stato della sessione
// (`LiveSession.directorSilence`), non da una lettura del motore.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Che cosa fa il tocco del tasto (e del pedale playPause) col Direttore muto in canzone.
enum DirectorTransportTap: String, Equatable {
    /// Il tasto dice Play: il tocco rientra, passando dal coordinatore.
    case rejoin = "rientra"
    /// Il tasto dice Stop: il tocco manda lo Stop a Link e chiude la canzone.
    case stopBand = "ferma-la-band"
}

/// A412 — «MUTO IN CANZONE», COME LO VEDE LA SESSIONE (mandato §2.5): la forma equivalente di un caso
/// nuovo di `LivePlaybackState`. La sessione del Direttore muto resta `.playing` (il player si vede come
/// oggi a click in moto) e porta in più questo valore, che la fascia legge per il tasto. `nil` = nessun
/// silenzio. Nessun testo e nessun colore nuovo: Play e Stop sono quelli di oggi.
struct DirectorSilence: Equatable {
    let tap: DirectorTransportTap

    /// Il tasto dice Play (glifo «▶», scritta «play»); altrimenti Stop («■», «stop»).
    var showsPlay: Bool { tap == .rejoin }
}

enum DirectorTransportDecision {

    /// Perché il tasto dice ciò che dice: per la riga di registro.
    enum Reason: String, Equatable {
        case rejoinPossible = "rientro-possibile"
        case interruptionActive = "interruzione-in-corso"
        case servicesLost = "servizi-audio-persi"
        case rejoinNotPossible = "rientro-non-possibile"
    }

    /// La regola. `nil` = fuori dal silenzio: il tasto com'è oggi.
    static func silence(playerRole: PlayerRole,
                        silentInSong: Bool,
                        rejoinPossibleNow: Bool,
                        interruptionActive: Bool,
                        servicesLost: Bool) -> DirectorSilence? {
        guard playerRole == .direttore, silentInSong else { return nil }
        if rejoinPossibleNow && !interruptionActive && !servicesLost {
            return DirectorSilence(tap: .rejoin)
        }
        return DirectorSilence(tap: .stopBand)
    }

    /// La ragione dell'esito, nell'ordine della regola. `nil` fuori dal silenzio.
    static func reason(playerRole: PlayerRole,
                       silentInSong: Bool,
                       rejoinPossibleNow: Bool,
                       interruptionActive: Bool,
                       servicesLost: Bool) -> Reason? {
        guard playerRole == .direttore, silentInSong else { return nil }
        if interruptionActive { return .interruptionActive }
        if servicesLost { return .servicesLost }
        return rejoinPossibleNow ? .rejoinPossible : .rejoinNotPossible
    }
}
