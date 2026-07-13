import Foundation
import os

private let logger = Logger(subsystem: "com.bullfrog.qbeats", category: "QBeatsStore")
private let iCloudContainerID = "iCloud.com.bullfrog.qbeats"

/// Chiave di ordinamento della lista Shows (S3). Stato di presentazione condiviso Q-Stage/Q-Live.
enum ShowsSortKey: Equatable {
    case name   // Name (A–Z)
    case date   // Concert date
}

@MainActor
final class QBeatsStore: ObservableObject {
    static let shared = QBeatsStore()

    @Published private(set) var songs: [Song] = []
    @Published private(set) var setlists: [Setlist] = []
    @Published private(set) var backtracks: [BacktrackFile] = []   // A5c-1: terzo catalogo

    // MARK: - Shows sort (S3, Q15/Q16) — stato di PRESENTAZIONE volatile, NON persistito
    // Vive QUI (singleton .shared) perché Q15 IMPONE che Q-Live (S4) erediti l'ORDINE in sola
    // lettura. ASSENTE da save()/load() → zero disco (Q16); si resetta al riavvio. Debito
    // architetturale lieve, DICHIARATO e ACCETTATO (BOX3 V92 §4). ⚠️ SOLO l'ordine è condiviso
    // (Q15): la SEARCH è LOCALE alle viste (Q-Live ha la sua «search no-sort», SCALETTA:130) →
    // NON sta qui, sta in @State di ShowsListView.
    @Published var showsSortKey: ShowsSortKey = .name
    @Published var showsSortAscending: Bool = true

    private init() {}

    // MARK: - Load / Save

    func load() async throws {
        let (loadedSongs, loadedSetlists, loadedBacktracks) = try await Task.detached(priority: .utility) {
            let base = QBeatsStore.resolveBaseURL()
            try QBeatsStore.ensureDirectory(base)
            let songs: [Song] = try QBeatsStore.coordinatedRead(
                at: base.appendingPathComponent("songs.json"), default: []
            )
            let setlists: [Setlist] = try QBeatsStore.coordinatedRead(
                at: base.appendingPathComponent("setlists.json"), default: []
            )
            // A5c-1 — terzo catalogo, lettura ISOLATA e NON-FATALE (piano v2,
            // rimedio m3): un errore I/O sul SOLO backtracks.json non deve MAI
            // abortire il load di songs/setlists — un load abortito lascia
            // songs=[] in RAM e il primo save() renderebbe il vuoto permanente
            // (wipe). Catalogo NUOVO: il default [] non perde nulla.
            var backtracks: [BacktrackFile] = []
            do {
                backtracks = try QBeatsStore.coordinatedRead(
                    at: base.appendingPathComponent("backtracks.json"), default: []
                )
            } catch {
                logger.error("load — backtracks.json read error (non-fatal): \(error)")
            }
            return (songs, setlists, backtracks)
        }.value
        songs = loadedSongs
        setlists = loadedSetlists
        backtracks = loadedBacktracks
        logger.info("load — songs: \(self.songs.count), setlists: \(self.setlists.count), backtracks: \(self.backtracks.count)")
    }

    func save() async throws {
        let songsSnapshot = songs
        let setlistsSnapshot = setlists
        let backtracksSnapshot = backtracks
        try await Task.detached(priority: .utility) { [songsSnapshot, setlistsSnapshot, backtracksSnapshot] in
            let base = QBeatsStore.resolveBaseURL()
            try QBeatsStore.ensureDirectory(base)
            try QBeatsStore.coordinatedWrite(songsSnapshot, to: base.appendingPathComponent("songs.json"))
            try QBeatsStore.coordinatedWrite(setlistsSnapshot, to: base.appendingPathComponent("setlists.json"))
            try QBeatsStore.coordinatedWrite(backtracksSnapshot, to: base.appendingPathComponent("backtracks.json"))
        }.value
        logger.info("save — songs: \(self.songs.count), setlists: \(self.setlists.count), backtracks: \(self.backtracks.count)")
    }

    // MARK: - Songs CRUD

    func addSong(_ song: Song) async {
        songs.append(song)
        try? await save()
    }

    func updateSong(_ song: Song) async {
        guard let idx = songs.firstIndex(where: { $0.id == song.id }) else { return }
        songs[idx] = song
        try? await save()
    }

    func deleteSong(id: UUID) async {
        songs.removeAll { $0.id == id }
        try? await save()
    }

    func moveSongs(from source: IndexSet, to destination: Int) async {
        songs.move(fromOffsets: source, toOffset: destination)
        try? await save()
    }

    // MARK: - Setlists CRUD

    func addSetlist(_ setlist: Setlist) async {
        setlists.append(setlist)
        try? await save()
    }

    func updateSetlist(_ setlist: Setlist) async {
        guard let idx = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }
        setlists[idx] = setlist
        try? await save()
    }

    func deleteSetlist(id: UUID) async {
        setlists.removeAll { $0.id == id }
        try? await save()
    }

    func moveSetlists(from source: IndexSet, to destination: Int) async {
        setlists.move(fromOffsets: source, toOffset: destination)
        try? await save()
    }

    // MARK: - Backtracks CRUD (A5c-1)

    // Path di SCRITTURA del futuro analyzer: upsert secco per filename.
    // ⚠️ Il restore (A5c-2) non upserta MAI l'entry in arrivo as-is: passa
    // dal merge NON-distruttivo (BacktrackFile.merged) e upserta solo il
    // VINCITORE, quando differisce dall'esistente — così un entry in arrivo
    // non può clobberare un'analisi locale più nuova, per costruzione.
    func upsertBacktrack(_ backtrack: BacktrackFile) async {
        if let idx = backtracks.firstIndex(where: { $0.filename == backtrack.filename }) {
            backtracks[idx] = backtrack
        } else {
            backtracks.append(backtrack)
        }
        try? await save()
    }

    func deleteBacktrack(filename: String) async {
        backtracks.removeAll { $0.filename == filename }
        try? await save()
    }

    func backtrack(for filename: String) -> BacktrackFile? {
        backtracks.first { $0.filename == filename }
    }

    // MARK: - Resolution

    func resolve(_ setlist: Setlist) -> (songs: [Song], missingIDs: [UUID]) {
        var resolved: [Song] = []
        var missing: [UUID] = []
        for id in setlist.songIDs {
            if let song = songs.first(where: { $0.id == id }) {
                resolved.append(song)
            } else {
                missing.append(id)
                logger.warning("resolve — songID \(id.uuidString) not found in catalog")
            }
        }
        return (resolved, missing)
    }

    func estimatedDuration(for setlist: Setlist) -> Double {
        resolve(setlist).songs.reduce(0.0) { $0 + $1.estimatedDurationSeconds }
    }

    // MARK: - Shows sort (applicazione ordine)

    /// Setlist ordinate secondo lo stato sort corrente. La leggono sia Q-Stage (S3) sia Q-Live
    /// (S4, sola lettura — Q15). Ordinamento su copia: zero mutazione di `setlists`, zero disco.
    var sortedSetlists: [Setlist] {
        sortedSetlists(setlists)
    }

    /// Applica l'ordine corrente a un sottoinsieme arbitrario (es. la lista già filtrata dalla
    /// search LOCALE della vista). Ordinamento stabile; nome case-insensitive.
    func sortedSetlists(_ input: [Setlist]) -> [Setlist] {
        let ascending: [Setlist]
        switch showsSortKey {
        case .name:
            ascending = input.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .date:
            ascending = input.sorted { $0.date < $1.date }
        }
        return showsSortAscending ? ascending : ascending.reversed()
    }

    // MARK: - Test data injection (DEBUG only)

    #if DEBUG
    /// Inietta dati di test direttamente in RAM, bypassa coordinated read/write.
    /// Usato da DebugView per popolare lo store senza dipendere da iCloud
    /// container o file su disco. Nessuna persistenza — i dati spariscono al
    /// kill dell'app. Pensato per validazione L1.b su device.
    func injectTestData(songs: [Song], setlists: [Setlist]) {
        self.songs = songs
        self.setlists = setlists
        logger.info("injectTestData — songs: \(self.songs.count), setlists: \(self.setlists.count)")
    }
    #endif

    // MARK: - Private

    nonisolated private static func resolveBaseURL() -> URL {
        if let container = FileManager.default.url(forUbiquityContainerIdentifier: iCloudContainerID) {
            return container.appendingPathComponent("Documents", isDirectory: true)
        }
        logger.warning("iCloud container unavailable — using local Documents")
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // Single source of truth for backtrack audio file location.
    // Used by QBeatsBackupManager and future Layer 3 song player.
    nonisolated static func backtrackBaseURL() -> URL {
        resolveBaseURL().appendingPathComponent("Backtracks", isDirectory: true)
    }

    nonisolated private static func ensureDirectory(_ url: URL) throws {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    nonisolated private static func coordinatedRead<T: Decodable>(at url: URL, default defaultValue: T) throws -> T {
        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.info("coordinatedRead — \(url.lastPathComponent) not found, using default")
            return defaultValue
        }
        var result = defaultValue
        var coordinatorError: NSError?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinatorError) { readURL in
            do {
                let data = try Data(contentsOf: readURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                result = try decoder.decode(T.self, from: data)
                logger.info("coordinatedRead — \(url.lastPathComponent) OK")
            } catch {
                logger.error("coordinatedRead — decode error for \(url.lastPathComponent): \(error)")
            }
        }
        if let error = coordinatorError {
            logger.error("coordinatedRead — coordinator error: \(error)")
            throw error
        }
        return result
    }

    nonisolated private static func coordinatedWrite<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        var coordinatorError: NSError?
        var writeError: Error?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordinatorError) { writeURL in
            do {
                let tempURL = writeURL.deletingLastPathComponent()
                    .appendingPathComponent(".\(UUID().uuidString).tmp")
                try data.write(to: tempURL)
                try FileManager.default.replaceItem(
                    at: writeURL, withItemAt: tempURL,
                    backupItemName: nil, options: [], resultingItemURL: nil
                )
                logger.info("coordinatedWrite — \(url.lastPathComponent) OK")
            } catch {
                writeError = error
            }
        }
        if let error = coordinatorError {
            logger.error("coordinatedWrite — coordinator error: \(error)")
            throw error
        }
        if let error = writeError {
            logger.error("coordinatedWrite — write error for \(url.lastPathComponent): \(error)")
            throw error
        }
    }
}
