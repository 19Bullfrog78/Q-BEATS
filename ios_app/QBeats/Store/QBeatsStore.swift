import Foundation
import os

private let logger = Logger(subsystem: "com.bullfrog.qbeats", category: "QBeatsStore")
private let iCloudContainerID = "iCloud.com.bullfrog.qbeats"

@MainActor
final class QBeatsStore: ObservableObject {
    static let shared = QBeatsStore()

    @Published private(set) var songs: [Song] = []
    @Published private(set) var setlists: [Setlist] = []

    private init() {}

    // MARK: - Load / Save

    func load() async throws {
        let (loadedSongs, loadedSetlists) = try await Task.detached(priority: .utility) {
            let base = QBeatsStore.resolveBaseURL()
            try QBeatsStore.ensureDirectory(base)
            let songs: [Song] = try QBeatsStore.coordinatedRead(
                at: base.appendingPathComponent("songs.json"), default: []
            )
            let setlists: [Setlist] = try QBeatsStore.coordinatedRead(
                at: base.appendingPathComponent("setlists.json"), default: []
            )
            return (songs, setlists)
        }.value
        songs = loadedSongs
        setlists = loadedSetlists
        logger.info("load — songs: \(self.songs.count), setlists: \(self.setlists.count)")
    }

    func save() async throws {
        let songsSnapshot = songs
        let setlistsSnapshot = setlists
        try await Task.detached(priority: .utility) { [songsSnapshot, setlistsSnapshot] in
            let base = QBeatsStore.resolveBaseURL()
            try QBeatsStore.ensureDirectory(base)
            try QBeatsStore.coordinatedWrite(songsSnapshot, to: base.appendingPathComponent("songs.json"))
            try QBeatsStore.coordinatedWrite(setlistsSnapshot, to: base.appendingPathComponent("setlists.json"))
        }.value
        logger.info("save — songs: \(self.songs.count), setlists: \(self.setlists.count)")
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

    // MARK: - Private

    nonisolated private static func resolveBaseURL() -> URL {
        if let container = FileManager.default.url(forUbiquityContainerIdentifier: iCloudContainerID) {
            return container.appendingPathComponent("Documents", isDirectory: true)
        }
        logger.warning("iCloud container unavailable — using local Documents")
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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
