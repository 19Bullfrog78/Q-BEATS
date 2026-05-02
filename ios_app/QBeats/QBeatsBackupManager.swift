import Foundation
import ZIPFoundation
import os

// MARK: - Models

struct BackupManifest: Codable, Sendable {
    var version: Int = 1
    var exportedAt: Date
    var hasSettings: Bool
    var songs: [BackupSongEntry]
    var setlists: [BackupSetlistEntry]

    // Runtime only — path to the extracted temp dir set by parse(), not serialized.
    var extractedDir: URL? = nil

    enum CodingKeys: String, CodingKey {
        case version, exportedAt, hasSettings, songs, setlists
    }
}

struct BackupSongEntry: Codable, Sendable {
    var song: Song
    var audioFilename: String?
}

struct BackupSetlistEntry: Codable, Sendable {
    var setlist: Setlist
}

struct ImportResult: Sendable {
    var settingsImported: Bool
    var songsImported: Int
    var songsDuplicated: Int
    var setlistsImported: Int
    var audioFilesImported: Int
}

enum BackupError: LocalizedError {
    case invalidArchive

    var errorDescription: String? {
        "Archivio .qbeats non valido o corrotto."
    }
}

// MARK: - Manager

enum QBeatsBackupManager {

    private static let logger = Logger(subsystem: "com.bullfrog.qbeats", category: "BackupManager")

    // MARK: Export

    static func export(
        settings: AppSettings?,
        songs: [Song],
        setlists: [Setlist],
        includeAudio: Bool,
        store: QBeatsStore
    ) async throws -> URL {
        _ = store
        return try await Task.detached(priority: .utility) {
            let fm = FileManager.default
            let tempBase = fm.temporaryDirectory
                .appendingPathComponent("qbeats_export_\(UUID().uuidString)", isDirectory: true)
            try fm.createDirectory(at: tempBase, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: tempBase) }

            // settings.json
            if let s = settings {
                try makeEncoder().encode(s)
                    .write(to: tempBase.appendingPathComponent("settings.json"))
                logger.info("export — settings.json written")
            }

            // songs/
            let songsDir = tempBase.appendingPathComponent("songs", isDirectory: true)
            try fm.createDirectory(at: songsDir, withIntermediateDirectories: true)
            for song in songs {
                try makeEncoder().encode(song)
                    .write(to: songsDir.appendingPathComponent("\(song.id.uuidString).json"))
            }
            logger.info("export — \(songs.count) song(s) written")

            // setlists/
            let setlistsDir = tempBase.appendingPathComponent("setlists", isDirectory: true)
            try fm.createDirectory(at: setlistsDir, withIntermediateDirectories: true)
            for setlist in setlists {
                try makeEncoder().encode(setlist)
                    .write(to: setlistsDir.appendingPathComponent("\(setlist.id.uuidString).json"))
            }
            logger.info("export — \(setlists.count) setlist(s) written")

            // backtracks/ (optional)
            var entries: [BackupSongEntry]
            if includeAudio {
                let btDir = tempBase.appendingPathComponent("backtracks", isDirectory: true)
                try fm.createDirectory(at: btDir, withIntermediateDirectories: true)
                let sourceBase = resolveBacktracksURL()
                entries = []
                for song in songs {
                    guard let filename = song.backtrackFilename else {
                        entries.append(BackupSongEntry(song: song, audioFilename: nil)); continue
                    }
                    let srcFile = sourceBase.appendingPathComponent(filename)
                    guard fm.fileExists(atPath: srcFile.path) else {
                        logger.warning("export — audio not found: \(filename)")
                        entries.append(BackupSongEntry(song: song, audioFilename: nil)); continue
                    }
                    var coordError: NSError?
                    var copyError: Error?
                    let coordinator = NSFileCoordinator()
                    coordinator.coordinate(readingItemAt: srcFile, options: .withoutChanges, error: &coordError) { readURL in
                        do {
                            try fm.copyItem(at: readURL, to: btDir.appendingPathComponent(filename))
                        } catch { copyError = error }
                    }
                    if let e = coordError ?? copyError {
                        logger.error("export — copy audio error \(filename): \(e)")
                        entries.append(BackupSongEntry(song: song, audioFilename: nil)); continue
                    }
                    entries.append(BackupSongEntry(song: song, audioFilename: filename))
                    logger.info("export — audio copied: \(filename)")
                }
            } else {
                entries = songs.map { BackupSongEntry(song: $0, audioFilename: nil) }
            }

            // manifest.json
            let manifest = BackupManifest(
                exportedAt: Date(),
                hasSettings: settings != nil,
                songs: entries,
                setlists: setlists.map { BackupSetlistEntry(setlist: $0) }
            )
            try makeEncoder().encode(manifest)
                .write(to: tempBase.appendingPathComponent("manifest.json"))
            logger.info("export — manifest.json written")

            // ZIP → .qbeats
            let outputURL = fm.temporaryDirectory
                .appendingPathComponent("QBeats_\(formattedDate()).qbeats")
            if fm.fileExists(atPath: outputURL.path) {
                try fm.removeItem(at: outputURL)
            }
            try fm.zipItem(at: tempBase, to: outputURL, shouldKeepParent: false)
            logger.info("export — archive created: \(outputURL.lastPathComponent)")
            return outputURL
        }.value
    }

    // MARK: Parse

    static func parse(_ url: URL) async throws -> BackupManifest {
        return try await Task.detached(priority: .utility) {
            let fm = FileManager.default
            let extractDir = fm.temporaryDirectory
                .appendingPathComponent("qbeats_import_\(UUID().uuidString)", isDirectory: true)
            try fm.createDirectory(at: extractDir, withIntermediateDirectories: true)

            do {
                try fm.unzipItem(at: url, to: extractDir)
            } catch {
                try? fm.removeItem(at: extractDir)
                throw error
            }
            logger.info("parse — extracted to \(extractDir.lastPathComponent)")

            let manifestURL = extractDir.appendingPathComponent("manifest.json")
            guard fm.fileExists(atPath: manifestURL.path) else {
                try? fm.removeItem(at: extractDir)
                throw BackupError.invalidArchive
            }

            let data = try Data(contentsOf: manifestURL)
            var manifest = try makeDecoder().decode(BackupManifest.self, from: data)
            manifest.extractedDir = extractDir
            logger.info("parse — manifest OK: \(manifest.songs.count) songs, \(manifest.setlists.count) setlists")
            return manifest
        }.value
    }

    // MARK: Import Selected

    static func importSelected(
        manifest: BackupManifest,
        importSettings: Bool,
        songIDs: Set<UUID>,
        setlistIDs: Set<UUID>,
        includeAudio: Bool,
        store: QBeatsStore
    ) async throws -> ImportResult {

        let extractDir = manifest.extractedDir

        // Settings
        var settingsImported = false
        if importSettings, manifest.hasSettings, let dir = extractDir {
            let settingsURL = dir.appendingPathComponent("settings.json")
            if let data = try? Data(contentsOf: settingsURL),
               let loaded = try? makeDecoder().decode(AppSettings.self, from: data) {
                await MainActor.run { loaded.save() }
                settingsImported = true
                logger.info("importSelected — settings imported")
            }
        }

        // Songs
        let existingIDs: Set<UUID> = await MainActor.run { Set(store.songs.map(\.id)) }
        let dateTag = formattedDate()
        var songsToAdd: [Song] = []
        var songsDuplicated = 0

        let selectedEntries = manifest.songs.filter { songIDs.contains($0.song.id) }
        for entry in selectedEntries {
            var song = entry.song
            if existingIDs.contains(song.id) {
                song = Song(
                    id: UUID(),
                    name: "\(song.name) (importato \(dateTag))",
                    sections: song.sections,
                    countIn: song.countIn,
                    backtrackFilename: song.backtrackFilename
                )
                songsDuplicated += 1
            }
            songsToAdd.append(song)
        }
        for song in songsToAdd { await store.addSong(song) }
        logger.info("importSelected — \(songsToAdd.count) songs (\(songsDuplicated) duplicated)")

        // Setlists
        let selectedSetlists = manifest.setlists.filter { setlistIDs.contains($0.setlist.id) }
        for entry in selectedSetlists { await store.addSetlist(entry.setlist) }
        logger.info("importSelected — \(selectedSetlists.count) setlists")

        // Audio
        var audioFilesImported = 0
        if includeAudio, let dir = extractDir {
            audioFilesImported = await Task.detached(priority: .utility) {
                let btSrc = dir.appendingPathComponent("backtracks", isDirectory: true)
                let btDst = resolveBacktracksURL()
                try? FileManager.default.createDirectory(at: btDst, withIntermediateDirectories: true)
                var count = 0
                for entry in selectedEntries {
                    guard let filename = entry.audioFilename else { continue }
                    let src = btSrc.appendingPathComponent(filename)
                    let dst = btDst.appendingPathComponent(filename)
                    guard FileManager.default.fileExists(atPath: src.path) else { continue }
                    do {
                        if FileManager.default.fileExists(atPath: dst.path) {
                            try FileManager.default.removeItem(at: dst)
                        }
                        try FileManager.default.copyItem(at: src, to: dst)
                        count += 1
                        logger.info("importSelected — audio copied: \(filename)")
                    } catch {
                        logger.error("importSelected — audio copy error \(filename): \(error)")
                    }
                }
                return count
            }.value
        }

        // Cleanup
        if let dir = extractDir {
            try? FileManager.default.removeItem(at: dir)
            logger.info("importSelected — temp dir cleaned")
        }

        return ImportResult(
            settingsImported: settingsImported,
            songsImported: songsToAdd.count,
            songsDuplicated: songsDuplicated,
            setlistsImported: selectedSetlists.count,
            audioFilesImported: audioFilesImported
        )
    }

    // MARK: - Utilities

    static func estimatedAudioSize(for songs: [Song]) -> Int64 {
        let base = resolveBacktracksURL()
        return songs.compactMap(\.backtrackFilename).reduce(0) { total, filename in
            let size = (try? FileManager.default
                .attributesOfItem(atPath: base.appendingPathComponent(filename).path)[.size] as? Int64) ?? 0
            return total + size
        }
    }

    // MARK: - Private

    private static func resolveBacktracksURL() -> URL {
        QBeatsStore.backtrackBaseURL()
    }

    private static func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    private static func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private static func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
