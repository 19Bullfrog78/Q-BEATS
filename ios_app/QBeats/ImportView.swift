import SwiftUI
import os

struct ImportView: View {
    let manifest: BackupManifest
    @ObservedObject var store: QBeatsStore
    @Environment(\.dismiss) private var dismiss

    @State private var importSettings: Bool
    @State private var selectedSongIDs: Set<UUID>
    @State private var selectedSetlistIDs: Set<UUID>
    @State private var includeAudio: Bool
    @State private var isImporting = false
    @State private var importResult: ImportResult? = nil
    @State private var importError: String? = nil

    init(manifest: BackupManifest, store: QBeatsStore) {
        self.manifest = manifest
        self.store = store
        _importSettings = State(initialValue: manifest.hasSettings)
        _selectedSongIDs = State(initialValue: Set(manifest.songs.map(\.song.id)))
        _selectedSetlistIDs = State(initialValue: Set(manifest.setlists.map(\.setlist.id)))
        _includeAudio = State(initialValue: manifest.songs.contains { $0.audioFilename != nil })
    }

    private var canImport: Bool {
        !selectedSongIDs.isEmpty || !selectedSetlistIDs.isEmpty || importSettings
    }

    var body: some View {
        NavigationStack {
            if let result = importResult {
                resultView(result)
            } else {
                Form {
                    SwiftUI.Section {
                        HStack {
                            Text("Exported on")
                            Spacer()
                            Text(manifest.exportedAt, style: .date).foregroundColor(.secondary)
                        }
                    }

                    if manifest.hasSettings {
                        SwiftUI.Section("Settings") {
                            Toggle("App settings", isOn: $importSettings)
                        }
                    }

                    SwiftUI.Section("Songs (\(manifest.songs.count))") {
                        if manifest.songs.isEmpty {
                            Text("No songs in backup").foregroundColor(.secondary).font(.caption)
                        } else {
                            ForEach(manifest.songs, id: \.song.id) { entry in
                                HStack {
                                    Image(systemName: selectedSongIDs.contains(entry.song.id)
                                          ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedSongIDs.contains(entry.song.id)
                                                         ? .accentColor : .secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.song.name)
                                        if entry.audioFilename != nil {
                                            Text("Include audio").font(.caption2).foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedSongIDs.contains(entry.song.id) {
                                        selectedSongIDs.remove(entry.song.id)
                                    } else {
                                        selectedSongIDs.insert(entry.song.id)
                                    }
                                }
                            }
                        }
                    }

                    SwiftUI.Section("Shows (\(manifest.setlists.count))") {
                        if manifest.setlists.isEmpty {
                            Text("No shows in backup").foregroundColor(.secondary).font(.caption)
                        } else {
                            ForEach(manifest.setlists, id: \.setlist.id) { entry in
                                CheckRow(
                                    label: entry.setlist.name,
                                    isSelected: selectedSetlistIDs.contains(entry.setlist.id)
                                ) {
                                    if selectedSetlistIDs.contains(entry.setlist.id) {
                                        selectedSetlistIDs.remove(entry.setlist.id)
                                    } else {
                                        selectedSetlistIDs.insert(entry.setlist.id)
                                    }
                                }
                            }
                        }
                    }

                    if manifest.songs.contains(where: { $0.audioFilename != nil }) {
                        SwiftUI.Section {
                            Toggle("Include audio", isOn: $includeAudio)
                        }
                    }

                    if let err = importError {
                        SwiftUI.Section {
                            Text(err).foregroundColor(.red).font(.caption)
                        }
                    }
                }
                .navigationTitle("Import backup")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: doImport) {
                            if isImporting {
                                ProgressView()
                            } else {
                                Text("Import")
                            }
                        }
                        .disabled(isImporting || !canImport)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func resultView(_ result: ImportResult) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            Text("Import complete")
                .font(.headline)
            List {
                if result.settingsImported {
                    Label("Settings imported", systemImage: "gearshape.fill")
                }
                Label(
                    "\(result.songsImported) song\(result.songsImported == 1 ? "" : "s") imported",
                    systemImage: "music.note"
                )
                if result.songsDuplicated > 0 {
                    Label(
                        "\(result.songsDuplicated) duplicate\(result.songsDuplicated == 1 ? "" : "s") (renamed)",
                        systemImage: "doc.on.doc"
                    )
                    .foregroundColor(.orange)
                }
                if result.setlistsImported > 0 {
                    Label(
                        "\(result.setlistsImported) show\(result.setlistsImported == 1 ? "" : "s") imported",
                        systemImage: "list.bullet"
                    )
                }
                if result.audioFilesImported > 0 {
                    Label(
                        "\(result.audioFilesImported) audio file\(result.audioFilesImported == 1 ? "" : "s") imported",
                        systemImage: "waveform"
                    )
                }
            }
            .frame(maxHeight: 200)
            Button("Close") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func doImport() {
        isImporting = true
        importError = nil
        Task {
            do {
                let result = try await QBeatsBackupManager.importSelected(
                    manifest: manifest,
                    importSettings: importSettings,
                    songIDs: selectedSongIDs,
                    setlistIDs: selectedSetlistIDs,
                    includeAudio: includeAudio,
                    store: store
                )
                importResult = result
                os_log("[ImportView] Importazione completata: %d songs, %d setlists",
                       log: .default, type: .default, result.songsImported, result.setlistsImported)
            } catch {
                importError = error.localizedDescription
                os_log("[ImportView] Import error: %{public}@", log: .default, type: .error,
                       error.localizedDescription)
            }
            isImporting = false
        }
    }
}
