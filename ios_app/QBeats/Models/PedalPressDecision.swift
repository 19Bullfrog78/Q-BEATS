import Foundation

// === A429 (08/11/2026) — IL PEDALE COME LO SCHERMO (TD-pedale-midi-play-senza-runner) ===
// Il pedale non ha una strada sua: preme il comando che lo schermo mostra adesso, con la stessa funzione del tocco
// (regola di Mauro del 19/10, domanda 3: «Il pedale fa sempre esattamente quello che fa il tasto sullo schermo, in
// tutti i ruoli. → sì»). Restano le due cose gia' decise: il ramo del Direttore muto (A425-A427) e lo Stop che ferma
// in ogni momento (la «B» di Mauro del 05/11, estesa a ogni schermo il 07/11). Mandato A429, par. 2.0, con il seguito 1
// (08/11), par. 2.1-2.5. L'ordine, che il banco segue:
//  (1) Follower: com'e' oggi (passa solo il muto, e non passa di qui);
//  (2) Direttore muto in canzone: com'e' oggi (Play/Pause → il tasto del silenzio, Stop → `handleStop`);
//  (3) click in moto → Stop. Per il Play/Pause «in moto» e' `isPlaying`; per lo Stop e' `isPlaying`, oppure il segno
//      «partenza chiesta» alzato, oppure il motore `.playing` o `.countIn` (seguito 1, par. 2.2);
//  (4) Stop a click fermo → niente;
//  (5) Play/Pause con una partenza o un arresto in corso → niente, su ogni schermo: il segno alzato, oppure il motore
//      `.playing`/`.countIn` con `isPlaying` falso (seguito 1, par. 2.1);
//  (6) lo schermo di adesso: ⚠️ RISCRITTO A429 · SEGUITO 2, c'era «il comando di partenza che mostra, o niente (mandato,
//      punti 5-8; seguito 1, par. 2.4).»: il comando che mostra, o niente (mandato, punti 5-8; seguito 1, par. 2.4): un
//      comando di partenza, oppure BACK TO SHOWS sulla fine scaletta di Direttore e Solo (seguito 2, la «A» di Mauro
//      dell'08/11, 11:00).
// Cosa mostra lo schermo entra come esito delle regole che gia' lo disegnano (`StandbyOverlayDecision`,
// `SoloScreenDecision`, `SoloConsoleDecision`, lo stato della sessione, il bivio, il piede del dettaglio): qui non c'e'
// una regola nuova dello schermo. Il lampo esce dalla stessa decisione (mandato, par. 2.5): fuori dal silenzio c'e' se e
// solo se il pedale ha premuto un comando; nel silenzio com'e' oggi (Play/Pause sempre, Stop col motore in moto).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// I due comandi del trasporto del pedale che passano da questa regola.
enum PedalTransportAction: String, Equatable, CaseIterable {
    case playPause
    case stop

    /// L'azione del MIDI Learn, se e' una delle due; `nil` per tutte le altre.
    init?(midi: MIDIAction) {
        switch midi {
        case .playPause: self = .playPause
        case .stop: self = .stop
        default: return nil
        }
    }
}

/// Che cosa copre il comando di partenza dello schermo, cosi' che il dito non lo raggiunge.
enum PedalCover: String, Equatable, CaseIterable {
    /// Il bivio «SHOW STOPPED» sopra il player fermo (`QLiveBivioView`).
    case bivio
    /// Il pannello del mixer di Direttore e Follower, sopra la fascia e alla sua altezza.
    case mixer
    /// Il foglio dell'import di un file `.qbeats`, sopra tutta l'app.
    case importSheet = "foglio-import"
}

/// Il piede dei dettagli dello show.
enum PedalDetailFoot: Equatable {
    /// La terza faccia col RESUME (`showsResume`).
    case resume
    /// Lo `startfoot`: START SHOW (faccia 1) o BACK TO SHOW (faccia 2, e faccia 3 senza RESUME), acceso o spento.
    case startFoot(enabled: Bool)
}

/// Cosa mostra adesso la schermata che ha la porta del pedale aperta.
enum PedalScreen: Equatable {
    /// Nessuna porta aperta: la lista degli show, lo show chiuso, la Home con le sue porte, Q-Stage, il debug.
    case noDoor
    /// Il comando di partenza c'e' ma e' coperto.
    case covered(PedalCover)
    /// Il player di Direttore e Follower: lo stato della sessione e, in `.standby`, il velo (`StandbyOverlayDecision`).
    case director(state: LivePlaybackState, veil: StandbyOverlayDecision?)
    /// Il player del Solo: lo schermo (`SoloScreenDecision`) e le facce della console (`SoloConsoleDecision`).
    case solo(screen: SoloScreen, faces: SoloConsoleFaces)
    /// I dettagli dello show, col loro piede.
    case detail(PedalDetailFoot)
}

/// Il comando che il pedale preme.
enum PedalCommand: Equatable {
    /// Col Direttore muto in canzone: il tasto del silenzio (`directorTransportTapped`, origine «pedale»).
    case directorSilenceTap
    /// Col Direttore muto in canzone: `handleStop` (che sul Direttore chiama `stop()`).
    case handleStopInSilence
    /// Lo Stop: `stop()`, la stessa chiamata della fascia e della console.
    case stop
    /// Il velo del Direttore con «Tap to start»: `veilTapped` col velo di adesso.
    case directorVeil(StandbyOverlayDecision)
    /// I veli V1/V2 del Solo: `soloVeilTapped` con lo schermo di adesso.
    case soloVeil(SoloScreen)
    /// Il tasto centrale della console del Solo a Play: `consoleKeyTouched(.center)` con le facce di adesso.
    case consoleCenter(SoloConsoleFaces)
    /// La fascia del Direttore accesa: il tocco della fascia.
    case directorStrip
    /// Il RESUME dei dettagli.
    case resume
    /// START SHOW o BACK TO SHOW dei dettagli.
    case startShow
    /// A429 · seguito 2 — BACK TO SHOWS della fine scaletta (V4, `EndShowView`), di Direttore e Solo: chiude lo show e
    /// torna alla lista degli show, con la funzione del tasto (la «A» di Mauro dell'08/11, 11:00).
    case backToShows
}

/// L'esito della regola: il comando premuto (`nil` = niente), il motivo per il registro, il lampo.
struct PedalPress: Equatable {
    let command: PedalCommand?
    let reason: String
    let lamp: Bool
}

enum PedalPressDecision {

    /// L'origine che il pedale passa alle funzioni del tocco.
    static let pedalOrigin = "pedale"

    /// «In moto» per l'azione (seguito 1, par. 2.1 (3) e par. 2.2).
    static func inMotion(action: PedalTransportAction, isPlaying: Bool, startRequested: Bool, engineMoving: Bool) -> Bool {
        switch action {
        case .playPause:
            return isPlaying
        case .stop:
            return isPlaying || startRequested || engineMoving
        }
    }

    /// La regola. Ingressi letti all'atto del pedale, sul principale:
    /// - `role`: `PlayerRoleDecision`;
    /// - `directorSilent`: il Direttore e' muto in canzone (`AudioEngine.directorSilence` non `nil`);
    /// - `isPlaying`: lo specchio del motore;
    /// - `startRequested`: il segno «partenza chiesta» del motore e' alzato (seguito 1, par. 2.1);
    /// - `engineMoving`: lo stato del motore e' `.playing` o `.countIn` (`AudioEngine.transportInMotion`);
    /// - `screen`: cosa mostra adesso la schermata con la porta aperta.
    static func decide(role: PlayerRole,
                       directorSilent: Bool,
                       action: PedalTransportAction,
                       isPlaying: Bool,
                       startRequested: Bool,
                       engineMoving: Bool,
                       screen: PedalScreen) -> PedalPress {
        // (1) Follower.
        if role == .follower {
            return PedalPress(command: nil, reason: "follower", lamp: false)
        }
        // (2) Direttore muto in canzone: com'e' oggi, lampo compreso.
        if directorSilent {
            switch action {
            case .playPause:
                return PedalPress(command: .directorSilenceTap, reason: "silenzio", lamp: true)
            case .stop:
                return PedalPress(command: .handleStopInSilence, reason: "silenzio", lamp: engineMoving)
            }
        }
        // (3) Click in moto → Stop.
        if inMotion(action: action, isPlaying: isPlaying, startRequested: startRequested, engineMoving: engineMoving) {
            return PedalPress(command: .stop, reason: "in-moto", lamp: true)
        }
        // (4) Stop a click fermo → niente.
        if action == .stop {
            return PedalPress(command: nil, reason: "fermo", lamp: false)
        }
        // (5) Play/Pause con una partenza o un arresto in corso → niente.
        if startRequested || engineMoving {
            return PedalPress(command: nil, reason: "partenza-o-arresto-in-corso", lamp: false)
        }
        // (6) Lo schermo di adesso.
        return pressed(screenCommand(screen))
    }

    /// ⚠️ RISCRITTO A429 · SEGUITO 2, c'era «Il comando di partenza che lo schermo mostra a click fermo, oppure niente col
    /// motivo.»: il comando che lo schermo mostra a click fermo (di partenza, oppure BACK TO SHOWS sulla fine scaletta),
    /// oppure niente col motivo.
    static func screenCommand(_ screen: PedalScreen) -> (command: PedalCommand?, reason: String) {
        switch screen {
        case .noDoor:
            return (nil, "nessuna-porta")
        case .covered(let cover):
            return (nil, "coperto-" + cover.rawValue)
        case .director(let state, let veil):
            switch state {
            case .standby:
                guard let veil, !veil.isFollower else { return (nil, "nessun-comando") }
                return (.directorVeil(veil), "velo")
            case .fineSetlist:
                return (.backToShows, "fine-scaletta")
            case .overlayStop:
                return (nil, "pannello-ux3")
            case .countIn, .playing, .stopped, .loopActive, .starting:
                return (.directorStrip, "fascia")
            }
        case .solo(let soloScreen, let faces):
            switch soloScreen.kind {
            case .overlayStop:
                return (nil, "pannello-ux3")
            case .endShow:
                return (.backToShows, "fine-scaletta")
            case .veil, .resume, .playing:
                if soloScreen.tap == .startSong {
                    return (.soloVeil(soloScreen), "velo")
                }
                if soloScreen.consoleVisible && faces.center == .play {
                    return (.consoleCenter(faces), "console")
                }
                return (nil, "nessun-comando")
            }
        case .detail(let foot):
            switch foot {
            case .resume:
                return (.resume, "resume")
            case .startFoot(let enabled):
                if enabled {
                    return (.startShow, "start-show")
                }
                return (nil, "tasto-spento")
            }
        }
    }

    private static func pressed(_ choice: (command: PedalCommand?, reason: String)) -> PedalPress {
        PedalPress(command: choice.command, reason: choice.reason, lamp: choice.command != nil)
    }

    // MARK: - Le parole del registro (senza accenti)

    /// Il campo `schermo:` della riga [PEDALE].
    static func screenName(_ screen: PedalScreen) -> String {
        switch screen {
        case .noDoor:
            return "nessuna-porta"
        case .covered(let cover):
            return "coperto-" + cover.rawValue
        case .director(let state, _):
            switch state {
            case .standby: return "direttore-velo"
            case .fineSetlist: return "direttore-fine-scaletta"
            case .overlayStop: return "direttore-ux3"
            case .countIn, .playing, .stopped, .loopActive, .starting: return "direttore-fascia"
            }
        case .solo(let soloScreen, _):
            switch soloScreen.kind {
            case .veil: return "solo-V"
            case .resume: return "solo-H"
            case .playing: return "solo-K"
            case .endShow: return "solo-V4"
            case .overlayStop: return "solo-ux3"
            }
        case .detail(let foot):
            switch foot {
            case .resume: return "dettaglio-resume"
            case .startFoot(let enabled): return enabled ? "dettaglio-start-acceso" : "dettaglio-start-spento"
            }
        }
    }

    /// Il campo `preme:` della riga [PEDALE].
    static func commandName(_ command: PedalCommand?) -> String {
        guard let command else { return "niente" }
        switch command {
        case .directorSilenceTap: return "tasto-del-silenzio"
        case .handleStopInSilence: return "handleStop"
        case .stop: return "stop"
        case .directorVeil: return "velo"
        case .soloVeil: return "velo-solo"
        case .consoleCenter: return "console-play"
        case .directorStrip: return "fascia"
        case .resume: return "resume"
        case .startShow: return "start-show"
        case .backToShows: return "back-to-shows"
        }
    }

    /// Il pezzo che le righe dei tocchi aggiungono quando le chiama il pedale: vuoto per il tocco, cosi' le righe del
    /// tocco escono come oggi (seguito 1, divieti: per il tocco cambiano solo le righe [PARTENZA]).
    static func originSuffix(_ origin: String) -> String {
        origin == pedalOrigin ? " origine:" + origin : ""
    }
}
