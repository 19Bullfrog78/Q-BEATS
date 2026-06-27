import SwiftUI

/// Q-Stage › Songs — catalogo canzoni (F2.4, prima fetta).
/// Lista → Editor Canzone. Modello INVARIATO; persistenza via QBeatsStore (async).
struct SongListView: View {
    let onExit: () -> Void
    @ObservedObject private var store = QBeatsStore.shared
    @State private var path = NavigationPath()
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                QStageTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    QStageNavBar(backTitle: "BIVIO",
                                 onBack: onExit,
                                 crumb: "Q-STAGE",
                                 trailingTitle: "+",
                                 trailingAction: addSong)
                    header
                    listOrEmpty
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let song = store.songs.first(where: { $0.id == id }) {
                    SongEditorView(song: song)
                } else {
                    notFound
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("Songs")
                .font(.custom("JetBrainsMono-Bold", size: 28))
                .foregroundColor(QStageTheme.text)
            Text("\(store.songs.count)")
                .font(.custom("JetBrainsMono-Medium", size: 14))
                .foregroundColor(QStageTheme.text3)
            Spacer()
            if !store.songs.isEmpty {
                Button(editMode == .active ? "Done" : "Reorder") {
                    withAnimation { editMode = editMode == .active ? .inactive : .active }
                }
                .font(.custom("JetBrainsMono-Medium", size: 12))
                .foregroundColor(QStageTheme.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var listOrEmpty: some View {
        if store.songs.isEmpty {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(QStageTheme.text3)
                Text("No songs yet")
                    .font(.custom("JetBrainsMono-Medium", size: 15))
                    .foregroundColor(QStageTheme.text2)
                Text("Tap + to create your first song.")
                    .font(.system(size: 13))
                    .foregroundColor(QStageTheme.text3)
            }
            Spacer()
        } else {
            List {
                ForEach(store.songs) { song in
                    NavigationLink(value: song.id) {
                        SongRow(song: song)
                    }
                    .listRowBackground(QStageTheme.surface)
                }
                .onDelete(perform: deleteSongs)
                .onMove(perform: moveSongs)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, $editMode)
        }
    }

    private var notFound: some View {
        ZStack {
            QStageTheme.bg.ignoresSafeArea()
            Text("Song not found").foregroundColor(QStageTheme.text2)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Actions (CRUD async via store; continuazione su main per path/UI)

    private func addSong() {
        let new = Song.makeDefault()
        Task { @MainActor in
            await store.addSong(new)
            path.append(new.id)
        }
    }

    private func deleteSongs(_ offsets: IndexSet) {
        let ids = offsets.map { store.songs[$0].id }
        Task { @MainActor in
            for id in ids { await store.deleteSong(id: id) }
        }
    }

    private func moveSongs(_ source: IndexSet, _ destination: Int) {
        Task { @MainActor in
            await store.moveSongs(from: source, to: destination)
        }
    }
}

private struct SongRow: View {
    let song: Song
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(song.name.isEmpty ? "Untitled" : song.name)
                    .font(.custom("JetBrainsMono-SemiBold", size: 15))
                    .foregroundColor(QStageTheme.text)
                Text(meta)
                    .font(.custom("JetBrainsMono-Medium", size: 11))
                    .foregroundColor(QStageTheme.text3)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    private var meta: String {
        let n = song.sections.count
        let base = song.backtrackFilename == nil ? "no base" : "base"
        return "\(n) \(n == 1 ? "section" : "sections") · \(base)"
    }
}
