import Foundation

// === A421 (24/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 2: LE CUFFIE (P11) — LA CLASSE DELL'USCITA E LO STATO ===
// Il fatto (BUGS, `TD-cuffie-con-filo-sul-direttore-spostano-la-griglia`; referto A419, §2.1 e §3.1; collaudo del 24/10,
// voce 2 del messaggio di `9b8803b5`). Quando le cuffie col filo o una cassa Bluetooth si staccano o si attaccano a canzone
// in corso il render del motore si ferma per 0,1-0,9 s senza che il motore si fermi; la notizia del cambio di percorso
// arriva dentro il buco, prima che il render riparta; i buffer già in coda escono dopo, in ritardo e sull'uscita nuova, e
// sul Direttore il primo assert dopo il buco sposta la griglia di tutta la band (il 24/10 di 1,5253 battiti).
//
// Le regole (mandato del referee «USCITA AUDIO PASSO 2a PEZZO 2», par. 2.1 U2, U3, U5, U16, par. 2.2 f, par. 2.3 a e c):
//  · «esterna» è ogni porta d'uscita che non è l'altoparlante dell'apparecchio né il ricevitore (risposta 2 di Mauro del
//    23/10): cuffie col filo o Bluetooth, casse Bluetooth, USB, uscita di linea, AirPlay e le altre valgono come le cuffie;
//  · la classe la danno le uscite di prima e di adesso, ognuna col tipo (`portType`) e l'identificativo della porta (`uid`:
//    Apple, «A system-assigned unique identifier (UID) for the port.»), qualunque sia il motivo della notizia (il 24/10 alle
//    13:55:42 un attacco delle cuffie è arrivato col motivo `unknown`): TOLTA = prima c'era almeno un'esterna e adesso
//    nessuna; AGGIUNTA = adesso c'è almeno un'esterna e le esterne non sono più quelle di prima (anche un'esterna al posto
//    di un'altra, pure dello stesso tipo); NESSUNA = le esterne di prima e di adesso sono le stesse porte (anche nessuna e
//    nessuna). Che una porta tenga lo stesso identificativo fra i due percorsi è [Probabile] (Apple non lo scrive): se non
//    lo tenesse, il prezzo è un'aggiunta in più, mai un click in ritardo; `identity` lo dice al collaudo. L'identificativo
//    non si scrive mai nel registro;
//  · il silenzio subito (U3): il volume del mixer principale a 0, prima di ogni lettura della sessione, col click in moto e
//    fuori da un'interruzione di sistema — Direttore in canzone: tolta e aggiunta; Direttore fuori da una canzone: solo
//    tolta (U16); Follower: tolta e aggiunta; Solo: solo tolta (par. 2.2 f: a un'uscita che compare il Solo resta com'è
//    oggi, la cura è del pezzo 3). Ogni silenzio ha la sua strada di ritorno (`OutputReturnDecision`, o il Play);
//  · la crisi (U4, U16): Direttore in canzone, tolta e aggiunta; Direttore fuori da una canzone e Solo, solo tolta;
//    Follower mai (la sua regola delle crisi è «come oggi», e il Follower la crisi la zittisce senza fermarlo);
//  · «uscita mancante» (U5), per Direttore e Follower, con la memoria dell'ultima uscita da cui il click è uscito a volume 1:
//    si alza a una tolta col click in moto, o col click fermo per una crisi o un'interruzione (non per uno Stop, e non fra
//    una canzone e l'altra a click fermo); a ogni rientro automatico si rilegge il percorso di adesso (se l'ultima uscita
//    era esterna e adesso un'esterna non c'è, si alza; se un'esterna c'è, si abbassa); si abbassa con un'esterna presente,
//    per il Direttore anche al suo Play, allo Stop, a fine canzone e alla chiusura dello show, per il Follower col tocco
//    «altoparlante» o alla chiusura dello show (risposta 3 di Mauro del 23/10: a fine canzone resta);
//  · dentro un'interruzione di sistema la notizia aggiorna solo lo stato (la regola del referee del 21/10, BOX5): niente
//    volume, crisi, ritorno. Un cambio di ruolo, o Link spento dall'utente, abbassa tutto (par. 2.3 c).
// Il volume ha un solo padrone: lo stato `muted` qui, scritto dal motore solo su audioQueue, letto da `start()` prima di
// `engine.start()`, dal ritorno del Follower e dalla riga [SCHED] (`volume:0|1`). Gli invarianti del banco: volume a 1 ⇒
// non (Follower con l'uscita mancante); motore in moto ⇒ non (Direttore con l'uscita mancante).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Una porta d'uscita: il tipo (`AVAudioSessionPortDescription.portType.rawValue`) e l'identificativo (`uid`).
struct OutputPort: Equatable, Hashable {
    let type: String
    let uid: String
}

/// La classe di un cambio di percorso, col nome che va nelle righe [USCITA].
enum OutputRouteClass: String, Equatable, CaseIterable {
    case removed = "tolta"
    case added = "aggiunta"
    case none = "nessuna"
}

/// Le esterne di prima e di adesso hanno gli stessi identificativi? Solo per la riga (`identita:`).
enum OutputRouteIdentity: String, Equatable {
    /// Le stesse porte, con gli stessi identificativi (anche nessuna e nessuna).
    case same = "stesse"
    /// Porte diverse, o identificativi diversi.
    case different = "diverse"
}

/// Quale ritorno si arma dopo un silenzio.
enum OutputReturnKind: String, Equatable {
    /// Il Direttore: `RecoveryTrigger.outputAdded` verso il coordinatore, dopo l'assestamento o la configurazione (U6).
    case director = "direttore"
    /// Il Follower: il volume torna al primo «uno» di battuta dopo le due ore (par. 2.2 c).
    case follower = "follower"
}

/// Che cosa fa il blocco della coda del cambio di percorso, per un ruolo, dopo la classe.
struct OutputRouteStep: Equatable {
    /// U3: il volume del mixer principale a 0, adesso.
    let silences: Bool
    /// U4, U16, par. 2.2 f: la crisi da dichiarare (`crisisOutcomeQ`), o niente.
    let crisisCause: CrisisCause?
    /// U5: «uscita mancante» si alza.
    let raisesMissing: Bool
    /// Un'esterna è presente: «uscita mancante» si abbassa.
    let lowersMissing: Bool
    /// Il ritorno da armare, se il silenzio c'è stato.
    let armsReturn: OutputReturnKind?

    static let nothing = OutputRouteStep(silences: false, crisisCause: nil, raisesMissing: false,
                                         lowersMissing: false, armsReturn: nil)
}

/// Lo stato su audioQueue: «uscita zittita» (il volume del mixer principale a 0), «uscita mancante» e la memoria
/// dell'ultima uscita da cui il click è uscito a volume 1 (esterna o no; `nil` = mai uscito).
struct OutputSilenceState: Equatable {
    var muted: Bool
    var missing: Bool
    var lastOutputExternal: Bool?

    static let initial = OutputSilenceState(muted: false, missing: false, lastOutputExternal: nil)
}

/// Gli eventi che muovono lo stato. Il nome è il `da:` della riga `[USCITA] mancante:`.
enum OutputSilenceEvent: Equatable {
    /// Il volume a 0 (U3).
    case silenced
    /// Il volume a 1, dall'uscita di adesso (`start()`, il ritorno del Follower, il tocco): la memoria si aggiorna.
    case volumeRestored(externalPresent: Bool)
    /// Una tolta che alza «uscita mancante» (U5).
    case removed
    /// Un'esterna presente alla notizia (aggiunta, o nessuna con un'esterna): «uscita mancante» si abbassa.
    case externalPresent
    /// La rilettura del percorso a un rientro automatico (U5): la memoria decide.
    case recoveryRead(externalPresent: Bool)
    /// Il Play del batterista (Direttore): la scelta dell'uscita che c'è (D2).
    case directorPlay(externalPresent: Bool)
    /// Lo Stop voluto, o lo Stop di fine canzone, del Direttore.
    case directorStop
    /// La fine canzone del Follower: niente (risposta 3 di Mauro). Entra per il banco.
    case followerSongEnd
    /// Il tocco «altoparlante» del Follower (par. 2.2 g).
    case speakerTap
    /// La chiusura dello show.
    case showClosed
    /// Un cambio di ruolo, o Link spento dall'utente (par. 2.3 c).
    case roleChange
}

enum OutputRouteDecision {

    /// L'altoparlante dell'apparecchio e il ricevitore (`AVAudioSession.Port.builtInSpeaker`, `.builtInReceiver`): le due
    /// uscite che non sono «esterne».
    static let builtInSpeakerType = "Speaker"
    static let builtInReceiverType = "Receiver"

    static func isExternal(portType: String) -> Bool {
        portType != builtInSpeakerType && portType != builtInReceiverType
    }

    static func externalPorts(_ ports: [OutputPort]) -> [OutputPort] {
        ports.filter { isExternal(portType: $0.type) }
    }

    static func hasExternal(_ ports: [OutputPort]) -> Bool {
        ports.contains { isExternal(portType: $0.type) }
    }

    /// La classe dalle uscite di prima e di adesso (U2). Il motivo della notizia non entra: va solo nella riga.
    static func classify(previous: [OutputPort], current: [OutputPort]) -> (routeClass: OutputRouteClass, identity: OutputRouteIdentity) {
        let before = Set(externalPorts(previous).map { $0.uid })
        let after = Set(externalPorts(current).map { $0.uid })
        let identity: OutputRouteIdentity = (before == after) ? .same : .different
        if !before.isEmpty && after.isEmpty {
            return (.removed, identity)
        }
        if !after.isEmpty && before != after {
            return (.added, identity)
        }
        return (.none, identity)
    }

    /// Che cosa fa il blocco della coda, per ruolo (U3, U4, U5, U16, par. 2.2 f, par. 2.3 a).
    /// - `stoppedByCrisis`: il motore è fermo per una crisi o un'interruzione, non per uno Stop (la causa viva senza uno
    ///   Stop voluto dopo, o la ripresa d'interruzione in corso).
    /// - `inInterruption`: lo stato «interruzione di sistema» è alzato: solo lo stato, niente volume, crisi o ritorno.
    static func step(routeClass: OutputRouteClass,
                     playerRole: PlayerRole,
                     showOpen: Bool,
                     songInProgress: Bool,
                     engineRunning: Bool,
                     stoppedByCrisis: Bool,
                     inInterruption: Bool) -> OutputRouteStep {
        let inSong = showOpen && songInProgress
        switch routeClass {
        case .none:
            return .nothing
        case .removed:
            let raises = (playerRole != .solo) && (engineRunning || stoppedByCrisis)
            if inInterruption {
                return OutputRouteStep(silences: false, crisisCause: nil, raisesMissing: raises,
                                       lowersMissing: false, armsReturn: nil)
            }
            let crisis: CrisisCause? = (playerRole == .follower) ? nil : .outputRemoved
            return OutputRouteStep(silences: engineRunning, crisisCause: crisis, raisesMissing: raises,
                                   lowersMissing: false, armsReturn: nil)
        case .added:
            if inInterruption {
                return OutputRouteStep(silences: false, crisisCause: nil, raisesMissing: false,
                                       lowersMissing: playerRole != .solo, armsReturn: nil)
            }
            switch playerRole {
            case .solo:
                // Par. 2.2 f: come oggi, nessun silenzio e nessuna crisi (il pezzo 3).
                return .nothing
            case .follower:
                return OutputRouteStep(silences: engineRunning, crisisCause: nil, raisesMissing: false,
                                       lowersMissing: true, armsReturn: engineRunning ? .follower : nil)
            case .direttore:
                guard inSong else {
                    // U16: fuori da una canzone un'aggiunta è come oggi.
                    return OutputRouteStep(silences: false, crisisCause: nil, raisesMissing: false,
                                           lowersMissing: true, armsReturn: nil)
                }
                return OutputRouteStep(silences: engineRunning, crisisCause: .outputAdded, raisesMissing: false,
                                       lowersMissing: true, armsReturn: .director)
            }
        }
    }

    /// Lo stato dopo un evento, per un ruolo.
    static func state(after event: OutputSilenceEvent, from state: OutputSilenceState,
                      playerRole: PlayerRole) -> OutputSilenceState {
        var next = state
        switch event {
        case .silenced:
            next.muted = true
        case .volumeRestored(let externalPresent):
            next.muted = false
            next.lastOutputExternal = externalPresent
        case .removed:
            if playerRole != .solo { next.missing = true }
        case .externalPresent:
            next.missing = false
        case .recoveryRead(let externalPresent):
            if externalPresent {
                next.missing = false
            } else if next.lastOutputExternal == true {
                next.missing = true
            }
        case .directorPlay(let externalPresent):
            if playerRole == .direttore {
                next.missing = false
                next.lastOutputExternal = externalPresent
            }
        case .directorStop:
            if playerRole == .direttore { next.missing = false }
        case .followerSongEnd:
            break
        case .speakerTap:
            if playerRole == .follower {
                next.missing = false
                next.lastOutputExternal = false
            }
        case .showClosed:
            next.missing = false
            next.muted = false
            next.lastOutputExternal = nil
        case .roleChange:
            next.missing = false
            next.muted = false
        }
        return next
    }

    /// Il volume che `start()` scrive sul mixer principale prima di `engine.start()` (U3 b): 0 solo per il Follower con
    /// l'uscita mancante (il Direttore con l'uscita mancante non parte da solo, e il suo Play abbassa lo stato prima).
    static func volumeForStart(playerRole: PlayerRole, state: OutputSilenceState) -> Float {
        (playerRole == .follower && state.missing) ? 0.0 : 1.0
    }

    /// Un Direttore con l'uscita mancante non riparte da solo (U5, U16): ogni ripartenza automatica è «niente».
    static func directorAutoRestartBlocked(playerRole: PlayerRole, state: OutputSilenceState) -> Bool {
        playerRole == .direttore && state.missing
    }

    /// Gli invarianti del mandato (U3 b, par. 2.3 b), per il banco e per le righe.
    static func volumeInvariantHolds(playerRole: PlayerRole, state: OutputSilenceState) -> Bool {
        !(playerRole == .follower && state.missing && !state.muted)
    }

    static func engineInvariantHolds(playerRole: PlayerRole, engineRunning: Bool, state: OutputSilenceState) -> Bool {
        !(playerRole == .direttore && state.missing && engineRunning)
    }
}
