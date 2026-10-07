import Foundation

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — IL PANNELLO DEL MIXER NON SI APRE DOVE NON SI PUÒ CHIUDERE ===
// Decisione del referee (mandato M3 §3.9 a): in `.standby` e in `.fineSetlist` le aperture di Direttore e Follower
// non funzionano, per costruzione e non per copertura — il trascinamento in giù nella zona del teleprompter
// (`LiveView`), la maniglia e il trascinamento in su (`TransportView`). Nel Solo il tasto Mixer sta nella console,
// che su V1, V2 e V4 non c'è. In `.overlayStop` resta tutto com'è (decisione b del cancello A397). Le chiusure di
// sempre restano, e le aperture in tutti gli altri stati. Motivo: BUGS, `TD-mixer-copre-endshow`, voce
// sull'apertura a END SHOW («servono i tre gesti disarmati esplicitamente in .fineSetlist, non lasciati alla
// stratigrafia»); in `.standby` il caso è lo stesso; BOX5 V54, decisione 9 («Il pannello si chiude da solo quando la
// console sparisce»).
// Le cause del registro (decisione g del cancello A397; M3 §3.9 b): ogni riga [MIXER] nomina la causa vera; se una
// causa non è nota si scrive «sconosciuta», nessuna causa di riserva che possa mentire.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum MixerOpenDecision {

    /// Vero se in questo stato il pannello si può aprire (con un gesto o col tasto).
    static func canOpen(in state: LivePlaybackState) -> Bool {
        switch state {
        case .standby, .fineSetlist:
            return false
        case .playing, .countIn, .stopped, .loopActive, .overlayStop, .starting:
            return true
        }
    }
}

/// Le cause con cui il registro nomina ogni apertura e chiusura del pannello.
enum MixerCause: String, Equatable {
    /// Il tasto Mixer della console del Solo.
    case key = "tasto"
    /// La zona sopra il pannello di Direttore e Follower (chiude).
    case zoneAbove = "zona-sopra"
    /// Il tocco sul fondo del pannello di Direttore e Follower (chiude).
    case panelTap = "tocco-pannello"
    /// La maniglia della fascia di Direttore e Follower (apre).
    case handle = "maniglia"
    /// Il trascinamento in giù nella zona del teleprompter (apre).
    case dragDown = "trascinamento-giu"
    /// Il trascinamento in su sulla fascia (apre).
    case dragUp = "trascinamento-su"
    /// All'ingresso nel player il pannello era aperto e si chiude (azzeramento A242).
    case mount = "montaggio"
    /// Chiusura da sé all'ingresso in `.standby`.
    case standby = "standby"
    /// Chiusura da sé all'ingresso in `.fineSetlist`.
    case endOfSetlist = "fine-scaletta"
    /// Chiusura da sé quando la fascia del Follower lascia il posto alle facce FUORI.
    case followerOut = "follower-fuori"
    /// Nessuna causa nota.
    case unknown = "sconosciuta"
}
