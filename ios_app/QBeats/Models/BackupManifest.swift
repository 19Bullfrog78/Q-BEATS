import Foundation

// === B7-A5c-1 — Modelli del backup .qbeats (MOVE da QBeatsBackupManager) ===
// Struct spostati in Models/ BYTE-IDENTICI (piano A5c v2, rimedio B1): il
// banco QBeatsTests compila solo QBeats/Models → solo qui le fixture
// retro-compat del manifest possono girare in CI. Unico delta rispetto al
// pre-move: il campo `backtracks` (A5c). La logica resta nel manager.
struct BackupManifest: Codable, Sendable {
    var version: Int = 1
    var exportedAt: Date
    var hasSettings: Bool
    var songs: [BackupSongEntry]
    var setlists: [BackupSetlistEntry]

    // A5c — metadati mappa per-backtrack. OPTIONAL con `= nil`, load-bearing:
    // (a) decodeIfPresent → nil sui manifest VECCHI (chiave assente): un
    //     campo required farebbe fallire il restore di OGNI .qbeats pre-A5c;
    // (b) `= nil` preserva la costruzione memberwise esistente nel manager.
    var backtracks: [BacktrackFile]? = nil

    // Runtime only — path to the extracted temp dir set by parse(), not serialized.
    var extractedDir: URL? = nil

    // Lista di ESCLUSIONE: `extractedDir` è runtime-only e resta FUORI dalla
    // serializzazione (un path temp device-specifico non deve entrare nel
    // .qbeats portabile). `backtracks` invece SÌ: viaggia nel manifest.
    enum CodingKeys: String, CodingKey {
        case version, exportedAt, hasSettings, songs, setlists, backtracks
    }
}

struct BackupSongEntry: Codable, Sendable {
    var song: Song
    var audioFilename: String?
}

struct BackupSetlistEntry: Codable, Sendable {
    var setlist: Setlist
}
