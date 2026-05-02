import SwiftUI
import os
import UIKit

struct BackupView: View {
    @ObservedObject var store: QBeatsStore

    @State private var includeSettings = true
    @State private var selectedSongIDs: Set<UUID> = []
    @State private var allSongsSelected = true
    @State private var selectedSetlistIDs: Set<UUID> = []
    @State private var includeAudio = false
    @State private var isExporting = false
    @State private var exportedURL: URL? = nil
    @State private var exportError: String? = nil
    @State private var showShareSheet = false

    private var estimatedAudioSize: Int64 {
        guard includeAudio else { return 0 }
        let selected = store.songs.filter { selectedSongIDs.contains($0.id) }
        return QBeatsBackupManager.estimatedAudioSize(for: selected)
    }

    private var canExport: Bool {
        !selectedSongIDs.isEmpty || !selectedSetlistIDs.isEmpty || includeSettings
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Impostazioni") {
                    Toggle("Impostazioni app", isOn: $includeSettings)
                }

                Section("Canzoni") {
                    Toggle("Tutte", isOn: $allSongsSelected)
                        .onChange(of: allSongsSelected) { val in
                            selectedSongIDs = val ? Set(store.songs.map(\.id)) : []
                        }
                    ForEach(store.songs) { song in
                        CheckRow(
                            label: song.name,
                            isSelected: selectedSongIDs.contains(song.id)
                        ) {
                            if selectedSongIDs.contains(song.id) {
                                selectedSongIDs.remove(song.id)
                                allSongsSelected = false
                            } else {
                                selectedSongIDs.insert(song.id)
                                if selectedSongIDs.count == store.songs.count {
                                    allSongsSelected = true
                                }
                            }
                        }
                    }
                }

                Section("Setlist") {
                    ForEach(store.setlists) { setlist in
                        CheckRow(
                            label: setlist.name,
                            isSelected: selectedSetlistIDs.contains(setlist.id)
                        ) {
                            if selectedSetlistIDs.contains(setlist.id) {
                                selectedSetlistIDs.remove(setlist.id)
                            } else {
                                selectedSetlistIDs.insert(setlist.id)
                            }
                        }
                    }
                    if store.setlists.isEmpty {
                        Text("Nessuna setlist").foregroundColor(.secondary).font(.caption)
                    }
                }

                Section {
                    Toggle("Includi audio", isOn: $includeAudio)
                    if includeAudio, estimatedAudioSize > 0 {
                        HStack {
                            Text("Dimensione stimata")
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: estimatedAudioSize, countStyle: .file))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let err = exportError {
                    Section {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Esporta backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: doExport) {
                        if isExporting {
                            ProgressView()
                        } else {
                            Text("Esporta")
                        }
                    }
                    .disabled(isExporting || !canExport)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ActivitySheet(items: [url])
                }
            }
            .onAppear {
                selectedSongIDs = Set(store.songs.map(\.id))
                selectedSetlistIDs = Set(store.setlists.map(\.id))
            }
        }
    }

    private func doExport() {
        isExporting = true
        exportError = nil
        let settings: AppSettings? = includeSettings ? AppSettings.load() : nil
        let songs = store.songs.filter { selectedSongIDs.contains($0.id) }
        let setlists = store.setlists.filter { selectedSetlistIDs.contains($0.id) }
        Task {
            do {
                let url = try await QBeatsBackupManager.export(
                    settings: settings,
                    songs: songs,
                    setlists: setlists,
                    includeAudio: includeAudio,
                    store: store
                )
                exportedURL = url
                showShareSheet = true
                os_log("[BackupView] Export completato: %{public}@", log: .default, type: .default,
                       url.lastPathComponent)
            } catch {
                exportError = error.localizedDescription
                os_log("[BackupView] Export error: %{public}@", log: .default, type: .error,
                       error.localizedDescription)
            }
            isExporting = false
        }
    }
}

// MARK: - Shared helpers

struct CheckRow: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
            Text(label)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
