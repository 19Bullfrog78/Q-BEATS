import Foundation

// === A408 (15/10/2026) — IL RESET DEI SERVIZI AUDIO: TRE STATI, UNA RICOSTRUZIONE ===
// Il fatto (referto A407, §3.2). In rari casi iOS termina e riavvia il server dei servizi
// multimediali: prima posta la Lost (il server non c'è più), poi la Reset (il server è ripartito
// e la sessione audio ha un ID nuovo). Il motore dell'app restava agganciato alla sessione morta:
// ogni avvio dello stesso motore falliva con -50 sul nodo d'uscita, e il click ripartiva solo
// chiudendo l'app. iOS posta Lost e Reset una volta per ogni sessione del processo, comprese le
// due aptiche di UIKit: nel collaudo di A406 tre Lost e tre Reset (referto A407, §4).
//
// La regola (decisioni del referee sul referto A407, mandato A408, §0-§2):
//  · la Lost porta a «servizi persi», da qualunque stato, e nient'altro;
//  · la Reset da «servizi persi»: l'arresto che serve sul principale, poi, su audioQueue, «da
//    ricostruire». Fra la lettura e il passaggio lo stato resta «servizi persi», così nessun avvio
//    parte in mezzo. A412 (mandato «DIRETTORE-IN-CRISI-PASSO-2», §2.1): l'arresto lo decide la regola
//    delle crisi (`CrisisStopDecision`). Lo `stopSync` resta solo per il Follower, che ferma in locale
//    un motore rimasto «in moto» sul server morto, senza scrivere su Link (A360); Direttore e Solo li ha
//    già fermati la Lost, e alla Reset non esce nessuno Stop verso la band e nessuna canzone si chiude
//    (LIBRO 2026-09-17 «IL PRINCIPIO DELLA BAND»). Fino ad A411 quello stopSync, sul Direttore, mandava
//    lo Stop alla band e chiudeva la canzone (`TD-media-reset-del-direttore-ferma-la-band`); fino ad
//    A410 lo mandava anche il Solo con Link acceso. Prima di A410 qui c'era «lo Stop alla band resta
//    quello di oggi», come se fosse una scelta: non lo era (referto A408, §8.3);
//  · la Reset da «da ricostruire»: notifica ripetuta, ignorata;
//  · la Reset da «normale» (Reset senza Lost): «da ricostruire», senza stopSync;
//  · un avvio in «servizi persi»: rifiutato e non ricordato, motore fermo;
//  · un avvio in «da ricostruire»: prima la ricostruzione (motore e 8 nodi nuovi, sessione,
//    grafo), poi l'avvio. Sessione attivata → «normale». Sessione non attivata → resta «da
//    ricostruire», l'avvio finisce fermo e il Play dopo riprova;
//  · fuori da «normale» nessuna strada fa lavoro di grafo o d'avvio sul motore vecchio e
//    nessuna chiama setActive, tranne la ricostruzione (`allowsAudioWork`). Nessuna ripartenza
//    automatica: il click riparte solo da un avvio.
// La ricostruzione si fa al primo avvio, non alla notifica: più Reset prima di un Play ne
// chiedono una sola.
//
// Fonti Apple (URL e impronte nel referto A407, §1.0): Technical Q&A QA1749,
// https://developer.apple.com/library/archive/qa/qa1749/_index.html — gli oggetti audio orfani
// si eliminano e si ricreano come al primo avvio, e «applications should not go active until
// and unless prompted to do so through user action»; pagina della Reset,
// https://developer.apple.com/documentation/avfaudio/avaudiosession/mediaserviceswereresetnotification.md
// — niente ripartenza «until initiated by user action».
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

enum MediaServicesState: Equatable {
    /// «normale»: il motore è agganciato alla sessione viva; tutto come prima di A408.
    case normal
    /// «servizi persi»: fra la Lost e la Reset. Il server non c'è.
    case servicesLost
    /// «da ricostruire»: dopo la Reset, fino a una ricostruzione riuscita al primo avvio.
    case needsRebuild
}

enum MediaServicesEvent: Equatable {
    /// `AVAudioSession.mediaServicesWereLostNotification`.
    case lost
    /// `AVAudioSession.mediaServicesWereResetNotification`.
    case reset
    /// Il passaggio su audioQueue dopo lo stopSync della Reset arrivata in «servizi persi».
    case stoppedAfterReset
    /// Un avvio del motore (`AudioEngine.start(resumeAtBeat:)`).
    case start
    /// La ricostruzione è finita: la sessione si è attivata oppure no.
    case rebuilt(sessionActivated: Bool)
}

enum MediaServicesAction: Equatable {
    /// Nessuna azione oltre al cambio di stato.
    case none
    /// Reset da «servizi persi»: l'arresto che serve sul principale (da A412 lo `stopSync` del solo
    /// Follower, `CrisisStopDecision`), poi `stoppedAfterReset`.
    case stopThenMarkRebuild
    /// Reset da «normale» (senza Lost): «da ricostruire», senza stopSync.
    case markRebuild
    /// Reset da «da ricostruire»: notifica ripetuta, ignorata.
    case ignoreRepeatedReset
    /// L'avvio prosegue come oggi.
    case startAsToday
    /// Avvio rifiutato: servizi persi. Motore fermo, niente da ricordare.
    case refuseStart
    /// Prima la ricostruzione, poi l'avvio.
    case rebuildThenStart
    /// La sessione non si è attivata: l'avvio finisce fermo; il Play dopo riprova.
    case failStart
}

struct MediaServicesTransition: Equatable {
    let next: MediaServicesState
    let action: MediaServicesAction
}

enum MediaServicesResetDecision {

    /// All'avvio dell'app.
    static let initial: MediaServicesState = .normal

    static func transition(state: MediaServicesState, event: MediaServicesEvent) -> MediaServicesTransition {
        switch event {
        case .lost:
            // Da qualunque stato, anche ripetuta o durante «da ricostruire».
            return MediaServicesTransition(next: .servicesLost, action: .none)
        case .reset:
            switch state {
            case .servicesLost:
                // Resta «servizi persi» fino al passaggio dopo lo stopSync.
                return MediaServicesTransition(next: .servicesLost, action: .stopThenMarkRebuild)
            case .needsRebuild:
                return MediaServicesTransition(next: .needsRebuild, action: .ignoreRepeatedReset)
            case .normal:
                return MediaServicesTransition(next: .needsRebuild, action: .markRebuild)
            }
        case .stoppedAfterReset:
            // Il mandato: «poi, su audioQueue, lo stato passa a "da ricostruire"».
            return MediaServicesTransition(next: .needsRebuild, action: .none)
        case .start:
            switch state {
            case .normal:
                return MediaServicesTransition(next: .normal, action: .startAsToday)
            case .servicesLost:
                return MediaServicesTransition(next: .servicesLost, action: .refuseStart)
            case .needsRebuild:
                return MediaServicesTransition(next: .needsRebuild, action: .rebuildThenStart)
            }
        case .rebuilt(let sessionActivated):
            return sessionActivated
                ? MediaServicesTransition(next: .normal, action: .startAsToday)
                : MediaServicesTransition(next: .needsRebuild, action: .failStart)
        }
    }

    /// Lavoro di grafo o d'avvio sul motore (attach, connect, rebuildGraph, setupGraph, prepare,
    /// start, play) e setActive fuori dalla ricostruzione: solo in «normale».
    static func allowsAudioWork(_ state: MediaServicesState) -> Bool {
        state == .normal
    }
}
