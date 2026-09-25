import Foundation

// === A386 · FASE B1 (2D) — LA MACCHINA DEL FOLLOWER: TRE STATI, UN SOLO POSTO, TESTATO ===
// Regola pura: niente motore, niente Link, niente schermo, niente orologio. Ingressi e uscite
// espliciti; chi la chiama (fase B2) legge il mondo e traduce l'esito in azioni.
//
// Gli stati (decisioni di Mauro 23-24/09/2026, referto A-TER §2 ratificato dal referee):
//  · IN SYNC — segue Play e Stop del Direttore. `songClosed` dice se la canzone corrente del
//    runner e' gia' chiusa (armata la successiva, o riarmata la stessa): un secondo Stop non
//    avanza — e' la corsa di fine canzone, in tutti e due gli ordini.
//  · DA SOLO — il Direttore non si sente piu' a canzone in corso: si finisce la canzone sulla
//    propria copia (D2, versione brutale); si esce solo FUORI. Unica eccezione: il Direttore
//    torna e si sente FERMO -> ci si ferma -> FUORI.
//  · FUORI — zitti; se ne esce solo con RIENTRA (D1, D4). `armed` e' la canzone armata.
//
// Le regole incise qui, con la decisione da cui vengono:
//  D1  IN SYNC fermo sul velo che smette di sentire il Direttore -> FUORI subito.
//  D2  DA SOLO resta DA SOLO fino a fine canzone anche se il Direttore torna in moto.
//  D6  Ingresso solo a inizio canzone, entro mezza battuta (`HalfBarWindow`): un Play oltre
//      mezza battuta porta FUORI.
//  D7-bis (Mauro, 24/09/2026) Uno Stop del Direttore ENTRO LA PRIMA BATTUTA DAL PLAY non
//      chiude la canzone, in tutte le canzoni («falsa partenza»): Direttore e Follower tornano
//      sul velo della STESSA canzone. Oltre la prima battuta vale D6: lo Stop chiude. Lo dice
//      il chiamante con `falseStart` (`FalseStartDecision`, in battiti di sessione).
//  R1  Ci si arma (START SHOW o RIENTRA) solo se «sento il Direttore» E la sessione e' ferma;
//      altrimenti FUORI non armato, con la ragione per il velo.
//  R2  FUORI armato che smette di sentire il Direttore -> FUORI non armato (la proposta resta
//      la canzone scelta); FUORI armato + Stop del Direttore -> resta armato.
//  Q11 «in moto» = isRunning || isAudioInterrupted: e' un ingresso (`engineRunning`), lo
//      calcola il chiamante.
//
// L'armamento (`armed`) vale SOLO da FUORI: IN SYNC e DA SOLO lo ignorano (stato invariato,
// nessuna azione; il chiamante logga). Un armamento accettato in IN SYNC riporterebbe
// `songClosed` a falso — allo Stop successivo il Follower avanzerebbe una canzone di troppo —
// o, se in quell'istante il Direttore non si sente, lo porterebbe FUORI senza motivo (B1-bis,
// correzione del referee). Un nuovo show passa sempre da `reset` (END SHOW) e poi da FUORI.
// `linkPlay` arriva alla macchina SOLO a motore fermo: a motore in moto il richiamo di Link e'
// gia' ignorato a monte (AudioEngine, guardia `!engine.isPlaying` nel richiamo avvio/stop).
// Nessun ingresso «numero di peer» ne' «collegato»: il collegato di LinkKit resta per schermo
// e log; il segnale della macchina e' «sento il Direttore» (`DirectorHeardTracker`).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum FollowerSyncState: Equatable {
    /// Segue Play e Stop del Direttore. `songClosed`: la canzone corrente e' gia' chiusa.
    case inSync(songClosed: Bool)
    /// Il Direttore non si sente piu' a canzone in corso: finisce la canzone sulla propria copia.
    case alone
    /// Zitto. `armed` = indice della canzone armata da RIENTRA, `nil` = non armato.
    case out(armed: Int?)
}

/// Come ci si arma: START SHOW (la scaletta parte dalla prima canzone) o RIENTRA (una
/// canzone scelta, anche gia' suonata — D4). `directorHeard` e `sessionPlaying` sono letti
/// dal chiamante nell'istante dell'armamento (R1).
struct FollowerArming: Equatable {
    enum Source: Equatable {
        case startShow
        case rientra(songIdx: Int)
    }
    let source: Source
    let directorHeard: Bool
    let sessionPlaying: Bool
}

enum FollowerSyncEvent: Equatable {
    /// Richiamo avvio di Link, a motore fermo. `withinHalfBar`: `HalfBarWindow`.
    case linkPlay(withinHalfBar: Bool)
    /// Richiamo stop di Link. `falseStart`: `FalseStartDecision` sui battiti di sessione (D7-bis).
    case linkStop(falseStart: Bool, engineRunning: Bool)
    /// Il fronte del segnale «sento il Direttore» (`DirectorHeardTracker`), col motore.
    case directorHeard(Bool, engineRunning: Bool)
    /// La propria canzone e' finita (il runner ha gia' armato la successiva da solo).
    case ownSongEnded
    /// Lo Stop del musicista (la striscia DA SOLO; le porte che chiudono lo show mandano `reset`).
    case musicianStop
    /// START SHOW o RIENTRA. Vale solo da FUORI.
    case armed(FollowerArming)
    /// Link spento dall'utente, cambio di ruolo, END SHOW, uscita dalla stanza.
    case reset
}

/// Cosa deve fare il chiamante. Un'azione sola per transizione.
enum FollowerSyncAction: Equatable {
    case none
    /// `engine.start()` + `linkStartedSubject` (il ramo di oggi del richiamo avvio).
    case start
    /// `engine.stop()`.
    case stop
    /// `engine.stop()` + `runner.armNextSong` (idempotente sul runner).
    case stopAndArmNext
    /// `runner.armNextSong` a motore gia' fermo.
    case armNext
    /// D7-bis: `engine.stop()` + `runner.armSong(currentSongIdx)`.
    case stopAndRearmSame
    /// D7-bis a motore fermo: `runner.armSong(currentSongIdx)`.
    case rearmSame
}

/// Perche' si e' andati FUORI (o perche' un armamento e' stato rifiutato): il velo lo legge,
/// e `RientraProposal` ci calcola la canzone da proporre.
enum FollowerOutReason: Equatable {
    /// Play arrivato oltre mezza battuta: la band sta suonando la canzone sul velo.
    case playLate
    /// D1: fermo sul velo, il Direttore non si sente piu'.
    case lostWhileStopped
    /// R2: armato da RIENTRA, il Direttore non si sente piu'. La proposta resta la scelta.
    case lostWhileArmed(chosen: Int)
    /// D2: DA SOLO fino a fine canzone, poi FUORI.
    case aloneSongEnded
    /// D2, eccezione: il Direttore torna e si sente fermo.
    case directorStoppedWhileAlone
    /// D7-bis in DA SOLO: lo Stop del Direttore e' una falsa partenza -> la stessa canzone.
    case directorFalseStartWhileAlone
    /// Lo Stop del musicista.
    case musicianStop
    /// R1: armamento rifiutato, il Direttore non si sente.
    case armRefusedNotHeard
    /// R1: armamento rifiutato, la sessione e' in moto (limite v1: proposta non affidabile).
    case armRefusedSessionPlaying
    /// `reset`: nessuno show.
    case reset
}

struct FollowerSyncTransition: Equatable {
    let state: FollowerSyncState
    let action: FollowerSyncAction
    /// Valorizzata SOLO quando si entra (o si resta) FUORI per una ragione nuova.
    let outReason: FollowerOutReason?

    init(_ state: FollowerSyncState, _ action: FollowerSyncAction, _ outReason: FollowerOutReason? = nil) {
        self.state = state
        self.action = action
        self.outReason = outReason
    }
}

enum FollowerSyncDecision {

    /// Prima di ogni show, e dopo ogni `reset`: FUORI, non armato.
    static let initial: FollowerSyncState = .out(armed: nil)

    static func transition(state: FollowerSyncState, event: FollowerSyncEvent) -> FollowerSyncTransition {
        if case .reset = event {
            return FollowerSyncTransition(.out(armed: nil), .none, .reset)
        }
        switch state {
        case .inSync(let songClosed):
            return inSync(songClosed: songClosed, event: event)
        case .alone:
            return alone(event: event)
        case .out(let armed):
            return out(armed: armed, event: event)
        }
    }

    // MARK: - IN SYNC

    private static func inSync(songClosed: Bool, event: FollowerSyncEvent) -> FollowerSyncTransition {
        let unchanged = FollowerSyncTransition(.inSync(songClosed: songClosed), .none)
        switch event {
        case .linkPlay(let withinHalfBar):
            // D6: si parte solo entro mezza battuta; oltre, la band sta gia' suonando.
            if withinHalfBar {
                return FollowerSyncTransition(.inSync(songClosed: false), .start)
            }
            return FollowerSyncTransition(.out(armed: nil), .none, .playLate)

        case .linkStop(let falseStart, let engineRunning):
            if falseStart {
                // D7-bis: falsa partenza, Direttore e Follower tornano sul velo della STESSA canzone.
                return FollowerSyncTransition(.inSync(songClosed: true),
                                              engineRunning ? .stopAndRearmSame : .rearmSame)
            }
            if engineRunning {
                return FollowerSyncTransition(.inSync(songClosed: true), .stopAndArmNext)
            }
            // Fermo: se la canzone e' gia' chiusa (fine canzone propria, o Stop gia' visto) non si
            // avanza una seconda volta; se non lo e' (armati sul velo, mai partiti), la band ha
            // chiuso una canzone che qui non e' partita.
            return FollowerSyncTransition(.inSync(songClosed: true), songClosed ? .none : .armNext)

        case .directorHeard(let heard, let engineRunning):
            if heard { return unchanged }
            if engineRunning {
                return FollowerSyncTransition(.alone, .none)
            }
            // D1
            return FollowerSyncTransition(.out(armed: nil), .none, .lostWhileStopped)

        case .ownSongEnded:
            // Il runner ha gia' armato la successiva: la canzone e' chiusa.
            return FollowerSyncTransition(.inSync(songClosed: true), .none)

        case .musicianStop:
            // In IN SYNC non c'e' un tasto Stop (le porte che chiudono lo show mandano `reset`):
            // se una porta futura lo manda, si ferma e si esce.
            return FollowerSyncTransition(.out(armed: nil), .stop, .musicianStop)

        case .armed:
            // Gia' IN SYNC: un armamento (il player che si ricarica e rimanda START SHOW, o un
            // RIENTRA arrivato fuori tempo) non cambia niente. Il chiamante logga.
            return unchanged

        case .reset:
            return FollowerSyncTransition(.out(armed: nil), .none, .reset)
        }
    }

    // MARK: - DA SOLO

    private static func alone(event: FollowerSyncEvent) -> FollowerSyncTransition {
        let unchanged = FollowerSyncTransition(.alone, .none)
        switch event {
        case .linkStop(let falseStart, _):
            // D2, eccezione: il Direttore torna e si sente fermo. D7-bis: se lo Stop e' una falsa
            // partenza, la proposta di RIENTRA sara' la stessa canzone.
            return FollowerSyncTransition(.out(armed: nil), .stop,
                                          falseStart ? .directorFalseStartWhileAlone
                                                     : .directorStoppedWhileAlone)
        case .directorHeard:
            // D2, brutale: sentito o no, in moto o no, si finisce la canzone.
            return unchanged
        case .ownSongEnded:
            return FollowerSyncTransition(.out(armed: nil), .none, .aloneSongEnded)
        case .musicianStop:
            return FollowerSyncTransition(.out(armed: nil), .stop, .musicianStop)
        case .linkPlay, .armed:
            // La copia di Link dice gia' «suona»: un Play non puo' arrivare; in moto non ci si
            // arma. Il chiamante logga l'anomalia.
            return unchanged
        case .reset:
            return FollowerSyncTransition(.out(armed: nil), .none, .reset)
        }
    }

    // MARK: - FUORI

    private static func out(armed: Int?, event: FollowerSyncEvent) -> FollowerSyncTransition {
        let unchanged = FollowerSyncTransition(.out(armed: armed), .none)
        switch event {
        case .armed(let arming):
            return arm(arming)

        case .linkPlay(let withinHalfBar):
            guard let chosen = armed else { return unchanged }
            if withinHalfBar {
                return FollowerSyncTransition(.inSync(songClosed: false), .start)
            }
            _ = chosen
            return FollowerSyncTransition(.out(armed: nil), .none, .playLate)

        case .linkStop:
            // R2: FUORI armato + Stop del Direttore -> resta armato (il chiamante logga).
            return unchanged

        case .directorHeard(let heard, _):
            if heard { return unchanged }
            guard let chosen = armed else { return unchanged }
            // R2: come D1, ma la proposta resta la canzone scelta.
            return FollowerSyncTransition(.out(armed: nil), .none, .lostWhileArmed(chosen: chosen))

        case .ownSongEnded, .musicianStop:
            return unchanged

        case .reset:
            return FollowerSyncTransition(.out(armed: nil), .none, .reset)
        }
    }

    // MARK: - R1: l'armamento (solo da FUORI)

    private static func arm(_ arming: FollowerArming) -> FollowerSyncTransition {
        guard arming.directorHeard else {
            return FollowerSyncTransition(.out(armed: nil), .none, .armRefusedNotHeard)
        }
        guard !arming.sessionPlaying else {
            return FollowerSyncTransition(.out(armed: nil), .none, .armRefusedSessionPlaying)
        }
        switch arming.source {
        case .startShow:
            return FollowerSyncTransition(.inSync(songClosed: false), .none)
        case .rientra(let songIdx):
            return FollowerSyncTransition(.out(armed: songIdx), .none)
        }
    }
}
