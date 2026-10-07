import Foundation

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LE FACCE DELLA CONSOLE B E L'AZIONE DEI TASTI ===
// Fonti: Solo REV18, punti 84 e 88 (decisi: a canzone in corso restano accesi solo Mixer e Stop; Kill e List
// mode spenti nella veste del quadrante vuoto, il tocco non fa niente), schermo f1 (a pannello aperto il tasto
// Mixer ha la veste del tasto selezionato); LIBRO v89, riga 2026-10-05 «RATIFICA DELLA SOLO REV18», decisione
// e) (Mauro: «B», «DOMANDA LIST MODE: B»): Kill acceso quando la base arriverà nel player e solo mentre suona;
// List mode spento finché non ha una funzione.
// Decisione D5 del referee (mandato M2): faccia e azione del tasto centrale escono dallo stesso dato — dice
// Stop esattamente quando il tocco ferma. L'ingresso è quello dell'azione di oggi (`TransportView`, fascia di
// chi comanda: `if audioEngine.isPlaying { stop() } else { startCurrentSection }`), cioè `AudioEngine.isPlaying`.
// Oggi la scritta guardava anche il conto (`isCountIn ? "stop" : …`): nella finestra `.countIn` con `isPlaying`
// falso (fra `resumeFromCurrentSection`, che scrive `.countIn`, e lo `start()` che alza `isPlaying`) la scritta
// diceva Stop mentre il tocco avrebbe avviato. Qui la regola segue l'azione: in quella finestra dice Play.
// Lo stato del player (`LivePlaybackState`) NON entra: il banco lo prova stato per stato.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum SoloConsoleCenter: Equatable {
    /// Quadrato rosso: il tocco ferma (`audioEngine.stop()`).
    case stop
    /// Triangolo verde: il tocco avvia (`runner.startCurrentSection(audioEngine:session:)`).
    case play
}

/// I quattro tasti e il tasto centrale: cosa può toccare chi guarda la console.
enum SoloConsoleKey: Equatable {
    case center, mixer, kill, listMode
}

/// Cosa fa il tocco su un tasto. `none`: il tocco non fa niente (Kill spento e List mode, nel Giro 1).
enum SoloConsoleAction: Equatable {
    case stop, start, toggleMixer, killBacktrack, none
}

struct SoloConsoleFaces: Equatable {
    /// Il tasto centrale: Stop in moto, Play da fermo (stesso dato dell'azione, D5).
    let center: SoloConsoleCenter
    /// Il Mixer è sempre acceso (punto 84: «il Mixer sì», anche a canzone ferma).
    let mixerOn: Bool
    /// A pannello aperto il tasto Mixer prende la veste del tasto selezionato (REV18, schermo f1).
    let mixerSelected: Bool
    /// Kill: acceso solo in moto e con la base che suona (decisione e) del 05/10). Nel Giro 1 la base nel player
    /// non parte: l'ingresso arriva falso, col motivo nel commento del chiamante (come il lampo di M1).
    let killOn: Bool
    /// List mode: spento finché non ha una funzione (Mauro: «DOMANDA LIST MODE: B»).
    let listModeOn: Bool
}

enum SoloConsoleDecision {

    /// `transportRunning` = `AudioEngine.isPlaying`, l'ingresso dell'azione del tasto centrale.
    static func faces(transportRunning: Bool, backtrackPlaying: Bool, mixerOpen: Bool) -> SoloConsoleFaces {
        SoloConsoleFaces(center: transportRunning ? .stop : .play,
                         mixerOn: true,
                         mixerSelected: mixerOpen,
                         killOn: transportRunning && backtrackPlaying,
                         listModeOn: false)
    }

    /// L'azione del tocco su un tasto, dalle facce disegnate: il tasto centrale fa ciò che dice (D5); il Mixer
    /// apre o chiude il pannello; Kill e List mode spenti non fanno niente (Kill acceso: `stopBacktrack`, che
    /// nel Giro 1 non si raggiunge perché la base nel player non suona).
    static func action(for key: SoloConsoleKey, faces: SoloConsoleFaces) -> SoloConsoleAction {
        switch key {
        case .center:
            return faces.center == .stop ? .stop : .start
        case .mixer:
            return .toggleMixer
        case .kill:
            return faces.killOn ? .killBacktrack : .none
        case .listMode:
            // SOLO-G1-PEZZO-1-M3 · A398 — pulizia (decisione g del cancello A397): List mode non fa niente, acceso o
            //    spento, finché non ha una funzione; il condizionale inerte è uscito, il comportamento è lo stesso.
            return .none
        }
    }
}
