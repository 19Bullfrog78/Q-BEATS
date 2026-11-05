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
//    corso, servizi audio persi): ⚠️ RISCRITTO A426, c'era «il tasto dice Stop e il tocco FERMA TUTTA LA BAND e chiude la
//    canzone»: il tasto dice Stop e il tocco FERMA TUTTA LA BAND e chiude la canzone (D3; D4 (a): a fine pezzo il batterista
//    preme Stop), salvo nell'ultimo tratto col conto certo («lascia finire», A425) e col rientro armato («rientro in arrivo»,
//    A426), dove il tasto dice Play e il tocco non ferma la band;
//  · fuori dal silenzio: il tasto com'è oggi (`nil`).
// Il pedale playPause segue la stessa regola; il pedale stop è sempre Stop. L'esito si calcola sul motore
// (al battito a 1 s e a ogni cambio del silenzio) e arriva alla vista come stato della sessione
// (`LiveSession.directorSilence`), non da una lettura del motore.
// === A425 (04/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3a: IL TASTO NELL'ULTIMO TRATTO DELLA CANZONE E LA REGOLA DEL TOCCO ===
// La «B» di Mauro del 01/11 (LIBRO, riga 2026-11-01 «L'OK ALLO SQUASH DI A421; COL DIRETTORE MUTO IN CANZONE E IL CONTO CERTO,
// NELL'ULTIMO TRATTO DELLA CANZONE IL TASTO RESTA PLAY E NON FERMA LA BAND (LA «B»)…»; referto A423, par. 3.4; decisione del
// referee su P13; mandato A425, par. 2.3):
//  · un esito nuovo, «lascia finire»: col Direttore muto in canzone, nessun rientro possibile adesso e il coordinatore che dice
//    «canzone finita» (esce solo col conto certo), il tasto dice Play come oggi e il tocco non ferma la band: la canzone finisce
//    da sola con lo Stop di fine canzone. ⚠️ RISCRITTO A426, c'era «L'ordine: fuori dal silenzio `nil`; interruzione in corso o
//    servizi persi ⇒ Stop (la D4 (a) del 16/10 vince su tutto); rientro possibile ⇒ rientra; fine certa ⇒ lascia finire; se no
//    Stop»: da A426 dopo l'interruzione e i servizi persi, prima del rientro possibile, viene il rientro armato (blocco A426);
//  · la regola del tocco: un tocco su una faccia Play (⚠️ RISCRITTO A426, c'era «rientra o lascia finire»: rientra, lascia finire
//    o rientro in arrivo) si rilegge sulla coda del motore con gli ingressi
//    di adesso (`playFaceTap`): rientra solo se adesso il rientro è possibile, se no niente. Da una faccia Play non nasce mai un
//    «ferma la band»: lo Stop alla band esce solo dalla faccia Stop. Così una faccia «rientra» vecchia non passa più da `start()`
//    quando il rientro non è possibile, e un tocco su «lascia finire» quando il rientro è tornato possibile rientra al primo tocco.
// Nessuna parola e nessuna grafica nuova: la faccia è il Play di oggi (`showsPlay`).
// === A426 (05/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3a, SEGUITO 1: IL TASTO DURANTE L'ATTESA DEL RIENTRO ===
// La «B» di Mauro del 05/11 (mandato A426, par. 1-2): mentre il rientro è armato e il click sta per tornare (fino a circa una
// battuta: il bersaglio è l'«uno» della battuta dopo il margine), il tasto resta Play e un secondo tocco non fa niente; il
// pedale Stop ferma la band in ogni momento. Fino ad A425 col rientro armato la regola cadeva in Stop: un secondo tocco del
// tasto o del pedale playPause fermava tutta la band (collaudo di 3a del 05/11).
//  · un esito nuovo, «rientro in arrivo» (Play), dall'ingresso nuovo `rejoinArmedNow`. L'ordine: fuori dal silenzio `nil`;
//    interruzione in corso o servizi persi ⇒ Stop (la D4 (a) del 16/10 vince su tutto); rientro armato ⇒ rientro in arrivo;
//    rientro possibile ⇒ rientra; fine certa ⇒ lascia finire; se no Stop;
//  · il ramo del tocco è una regola pura (`tapRoute`): una faccia Play (rientra, lascia finire, rientro in arrivo) va alla
//    rilettura sulla coda, la faccia Stop a `stop()`. Riletta «rientro in arrivo», il tocco non fa niente (né `start()` né
//    `stop()`); riletta un'altra faccia, decide quella, come in A425.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Che cosa fa il tocco del tasto (e del pedale playPause) col Direttore muto in canzone.
enum DirectorTransportTap: String, Equatable, CaseIterable {
    /// Il tasto dice Play: il tocco rientra, passando dal coordinatore. A425: se, riletto sulla coda, il rientro è ancora
    /// possibile (`DirectorTransportDecision.playFaceTap`).
    case rejoin = "rientra"
    /// Il tasto dice Stop: il tocco manda lo Stop a Link e chiude la canzone.
    case stopBand = "ferma-la-band"
    /// A425 — il tasto dice Play nell'ultimo tratto della canzone col conto certo: il tocco non ferma la band e non avvia niente
    /// (né sessione, né motore, né Link); la canzone finisce da sola con lo Stop di fine canzone.
    case letSongEnd = "lascia-finire"
    /// A426 — il tasto dice Play mentre il rientro è armato e il click sta per tornare: il tocco non avvia niente e non ferma la
    /// band (né `start()` né `stop()`). Al fuoco, al fuoco che non parte, a un riarmo e a un'interruzione la faccia si ricalcola:
    /// dopo l'attesa lo Stop torna dove c'era.
    case rejoinComing = "rientro-in-arrivo"
}

/// A412 — «MUTO IN CANZONE», COME LO VEDE LA SESSIONE (mandato §2.5): la forma equivalente di un caso
/// nuovo di `LivePlaybackState`. La sessione del Direttore muto resta `.playing` (il player si vede come
/// oggi a click in moto) e porta in più questo valore, che la fascia legge per il tasto. `nil` = nessun
/// silenzio. Nessun testo e nessun colore nuovo: Play e Stop sono quelli di oggi.
struct DirectorSilence: Equatable {
    let tap: DirectorTransportTap

    /// Il tasto dice Play (glifo «▶», scritta «play»); altrimenti Stop («■», «stop»). A425: Play anche per «lascia finire».
    /// A426: e per «rientro in arrivo».
    var showsPlay: Bool { tap == .rejoin || tap == .letSongEnd || tap == .rejoinComing }
}

/// A425 — l'esito di un tocco su una faccia Play (⚠️ RISCRITTO A426, c'era «rientra o lascia finire»: rientra, lascia finire o
/// rientro in arrivo), riletto sulla coda del motore.
enum DirectorPlayFaceTapOutcome: String, Equatable, CaseIterable {
    /// Adesso il rientro è possibile: `start()`, il rientro dal coordinatore.
    case rejoin = "rientra"
    /// Adesso è l'ultimo tratto col conto certo: niente (né sessione, né motore, né Link); la faccia si ripubblica.
    case letSongEnd = "lascia-finire"
    /// Adesso la faccia è Stop (il conto non è più certo, un'interruzione, i servizi persi): il tocco non ferma niente e la
    /// faccia si ripubblica Stop.
    case nothingStop = "niente(stop)"
    /// Adesso il Direttore non è più nel silenzio (il rientro già fatto, lo Stop di fine canzone, uno Stop voluto, fra il tocco e
    /// la coda): niente, né `start()` né `stop()`.
    case nothingOutsideSilence = "niente(fuori-dal-silenzio)"
    /// A426 — adesso il rientro è armato e il click sta per tornare: niente, né `start()` né `stop()`; la faccia si ripubblica.
    case nothingRejoinComing = "niente(rientro-in-arrivo)"

    /// Solo «rientra» fa partire qualcosa (`start()`); nessun esito ferma la band.
    var startsEngine: Bool { self == .rejoin }
}

/// A426 — dove va il tocco del tasto (e del pedale playPause) col Direttore muto in canzone, dalla faccia toccata
/// (`DirectorTransportDecision.tapRoute`).
enum DirectorTapRoute: Equatable, CaseIterable {
    /// Una faccia Play: la faccia si rilegge sulla coda del motore e decide la faccia riletta (`playFaceTap`).
    case reread
    /// La faccia Stop: `stop()`, lo Stop voluto (ferma la band e chiude la canzone).
    case wantedStop
}

enum DirectorTransportDecision {

    /// Perché il tasto dice ciò che dice: per la riga di registro.
    enum Reason: String, Equatable {
        case rejoinPossible = "rientro-possibile"
        case interruptionActive = "interruzione-in-corso"
        case servicesLost = "servizi-audio-persi"
        case rejoinNotPossible = "rientro-non-possibile"
        /// A425 — nessun rientro possibile e la canzone finisce col conto certo: il tasto dice Play, «lascia finire».
        case songEndCertain = "fine-canzone-certa"
        /// A426 — il rientro è armato e il click sta per tornare: il tasto dice Play, «rientro in arrivo».
        case rejoinArmed = "rientro-armato"
    }

    /// La regola. `nil` = fuori dal silenzio: il tasto com'è oggi.
    /// A425 — `songEndsCertainNow`: il coordinatore, letto adesso, dice «canzone finita» (solo col conto certo); senza valore di
    /// default, ogni chiamante lo dice. ⚠️ RISCRITTO A426, c'era «L'ordine: interruzione o servizi persi ⇒ Stop; rientro possibile
    /// ⇒ rientra; fine certa ⇒ lascia finire; se no Stop.»: l'ordine di adesso è nella riga A426 qui sotto.
    /// A426 — `rejoinArmedNow`: il rientro è armato e non ancora suonato (il click sta per tornare); senza valore di default, ogni
    /// chiamante lo dice. L'ordine: interruzione o servizi persi ⇒ Stop; rientro armato ⇒ rientro in arrivo; rientro possibile ⇒
    /// rientra; fine certa ⇒ lascia finire; se no Stop.
    static func silence(playerRole: PlayerRole,
                        silentInSong: Bool,
                        rejoinArmedNow: Bool,
                        rejoinPossibleNow: Bool,
                        songEndsCertainNow: Bool,
                        interruptionActive: Bool,
                        servicesLost: Bool) -> DirectorSilence? {
        guard playerRole == .direttore, silentInSong else { return nil }
        if interruptionActive || servicesLost {
            return DirectorSilence(tap: .stopBand)
        }
        // A426 — il rientro armato: il click sta per tornare, il tasto resta Play e il tocco non fa niente.
        if rejoinArmedNow {
            return DirectorSilence(tap: .rejoinComing)
        }
        if rejoinPossibleNow {
            return DirectorSilence(tap: .rejoin)
        }
        if songEndsCertainNow {
            return DirectorSilence(tap: .letSongEnd)
        }
        return DirectorSilence(tap: .stopBand)
    }

    /// La ragione dell'esito, nell'ordine della regola. `nil` fuori dal silenzio.
    static func reason(playerRole: PlayerRole,
                       silentInSong: Bool,
                       rejoinArmedNow: Bool,
                       rejoinPossibleNow: Bool,
                       songEndsCertainNow: Bool,
                       interruptionActive: Bool,
                       servicesLost: Bool) -> Reason? {
        guard playerRole == .direttore, silentInSong else { return nil }
        if interruptionActive { return .interruptionActive }
        if servicesLost { return .servicesLost }
        if rejoinArmedNow { return .rejoinArmed }
        if rejoinPossibleNow { return .rejoinPossible }
        return songEndsCertainNow ? .songEndCertain : .rejoinNotPossible
    }

    /// A425 — LA REGOLA DEL TOCCO su una faccia Play (⚠️ RISCRITTO A426, c'era «rientra o lascia finire»: rientra, lascia finire o
    /// rientro in arrivo), sulla coda del motore: decide la faccia riletta
    /// adesso (`silence(…)` con gli ingressi di adesso), non quella toccata. Rientra solo se adesso dice «rientra»; da una faccia
    /// Play non nasce mai un «ferma la band». A426: riletta «rientro in arrivo», niente.
    static func playFaceTap(rereadNow: DirectorSilence?) -> DirectorPlayFaceTapOutcome {
        guard let now = rereadNow else { return .nothingOutsideSilence }
        switch now.tap {
        case .rejoin: return .rejoin
        case .letSongEnd: return .letSongEnd
        case .stopBand: return .nothingStop
        case .rejoinComing: return .nothingRejoinComing
        }
    }

    /// A426 — IL RAMO DEL TOCCO dalla faccia toccata, prima della coda (`directorTransportTapped`): la faccia Stop va a `stop()`,
    /// lo Stop voluto (ferma la band e chiude la canzone, anche dentro un'interruzione, dove la faccia è Stop); ogni faccia Play
    /// (rientra, lascia finire, rientro in arrivo) va alla rilettura sulla coda (`playFaceTap`). Una faccia nuova che finisse per
    /// errore nel ramo dello Stop fa cadere il banco.
    static func tapRoute(face: DirectorTransportTap) -> DirectorTapRoute {
        switch face {
        case .stopBand: return .wantedStop
        case .rejoin, .letSongEnd, .rejoinComing: return .reread
        }
    }
}
