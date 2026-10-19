import Foundation
import Combine

/// Sorgente di verità per la Vista LIVE.
/// Alimentata da AudioEngine + QBeatsStore.
/// Tutti i @Published assegnati su main thread.
@MainActor
final class LiveSession: ObservableObject {

    // MARK: - Canzone corrente
    @Published var currentSongName: String = ""
    @Published var currentBPM: Double = 120
    @Published var currentTimeSig: String = "4/4"
    @Published var currentSectionName: String = ""
    @Published var nextSectionName: String? = nil
    @Published var nextSongName: String? = nil

    // MARK: - Posizione
    @Published var currentBar: Int = 1
    @Published var totalBarsInSection: Int = 4
    @Published var macroBarCurrent: Int = 0
    @Published var macroBarTotal: Int = 1

    // MARK: - Metronomo slot
    /// Array: "accent" | "beat" | "subdiv" — lunghezza = beatsPerBar
    @Published var accentPattern: [String] = ["accent", "beat", "beat", "beat"]
    @Published var beatActive: Int = 0      // 1-based, 0 = nessuno

    // MARK: - Stato
    // Default `.stopped`: all'avvio Vista LIVE niente em-dash centrale.
    // L'overlay `.standby` viene mostrato SOLO quando il SetlistRunner
    // imposta esplicitamente lo state tra una canzone e l'altra (vedi
    // SetlistRunner.swift ramo standby). Cambiato da `.standby(nextSongName: "—")`
    // il 17/05/2026 — TD #28, Step 2 roadmap pre-CD.
    @Published var playbackState: LivePlaybackState = .stopped
    // A412 (18/10/2026) — IL DIRETTORE MUTO IN CANZONE, COME STATO DELLA SESSIONE (mandato
    // «DIRETTORE-IN-CRISI-PASSO-2», §2.5): la forma equivalente di un caso nuovo di `LivePlaybackState`.
    // Il Direttore muto resta `.playing` (il player si vede come oggi a click in moto); qui c'è in più
    // l'esito del tasto della fascia (`DirectorTransportDecision`: Play = rientra, Stop = ferma la band).
    // `nil` = nessun silenzio. Lo scrive solo la stanza (`QLiveSession`), dallo specchio del motore.
    @Published var directorSilence: DirectorSilence? = nil
    @Published var isBacktrackLocked: Bool = false

    // MARK: - Mixer
    @Published var showMixer: Bool = false
    @Published var isProMode: Bool = false
}
