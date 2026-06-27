import SwiftUI

/// Q-Stage › Songs — catalogo canzoni (F2.4).
/// Passata grafica CD (27/06): palette BLU NOTTE, font Inter (titolo + nome brano) +
/// JetBrains Mono (tutto il resto). Misure dal mock v2 a baseline 390
/// (scaleFactor = geo.size.width / 390, pattern Vista Live · LiveView.swift:82).
///
/// FUORI SCOPE: NESSUN badge sync (IN/DA SYNC = stato di validazione setlist, non stile).
/// RINVIATO: glifo ⚙ Settings nell'header (la schermata Settings è un fronte a parte) → trailing vuoto.
/// DIPENDENZA: i font Inter-*.ttf devono stare in QBeats/Fonts/ (registrati in project.yml/Info.plist);
/// finché non ci sono, titolo/nome ripiegano sul font di sistema.
struct SongListView: View {
    let onExit: () -> Void
    @ObservedObject private var store = QBeatsStore.shared
    @State private var path = NavigationPath()
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geo in
                let sf = geo.size.width / 390      // scaleFactor (pattern Vista Live)
                ZStack {
                    QStageTheme.bg.ignoresSafeArea()
                    VStack(spacing: 0) {
                        QStageNavBar(backTitle: "BIVIO", onBack: onExit, crumb: "Q-STAGE", sf: sf)
                        titleBlock(sf)
                        listOrEmpty(sf)
                    }
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

    // Titolo "Songs" (Inter ExtraBold) + sottotitolo + (Reorder) + FAB "+".
    private func titleBlock(_ sf: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 10 * sf) {
            VStack(alignment: .leading, spacing: 3 * sf) {
                Text("Songs")
                    .font(.custom("Inter-ExtraBold", size: 30 * sf))
                    .tracking(-0.6 * sf)
                    .foregroundColor(QStageTheme.text)
                Text(catalogSubtitle)
                    .font(.jbMono(.medium, size: 12 * sf))
                    .tracking(0.5 * sf)
                    .foregroundColor(QStageTheme.text2)
            }
            Spacer(minLength: 0)
            if !store.songs.isEmpty {
                Button(editMode == .active ? "Done" : "Reorder") {
                    withAnimation { editMode = editMode == .active ? .inactive : .active }
                }
                .font(.jbMono(.medium, size: 12 * sf))
                .foregroundColor(QStageTheme.accent)
            }
            fab(sf)
        }
        .padding(.horizontal, 16 * sf)
        .padding(.top, 8 * sf)
        .padding(.bottom, 12 * sf)
    }

    private var catalogSubtitle: String {
        let n = store.songs.count
        return "\(n) \(n == 1 ? "song" : "songs") in catalog"
    }

    // FAB "+" ambra: gradiente + glow, glifo scuro (mock CD).
    private func fab(_ sf: CGFloat) -> some View {
        Button(action: addSong) {
            Image(systemName: "plus")
                .font(.system(size: 22 * sf, weight: .semibold))
                .foregroundColor(QStageTheme.ink)
                .frame(width: 44 * sf, height: 44 * sf)
                .background(
                    LinearGradient(colors: [Color(hex: "#ffd35a"), QStageTheme.amber],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14 * sf, style: .continuous))
                .shadow(color: QStageTheme.amber.opacity(0.25), radius: 9 * sf, x: 0, y: 6 * sf)
        }
    }

    @ViewBuilder
    private func listOrEmpty(_ sf: CGFloat) -> some View {
        if store.songs.isEmpty {
            Spacer()
            VStack(spacing: 10 * sf) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 40 * sf, weight: .light))
                    .foregroundColor(Color.white.opacity(0.18))
                Text("No songs yet")
                    .font(.custom("Inter-SemiBold", size: 17 * sf))
                    .foregroundColor(Color.white.opacity(0.70))
                Text("Tap + to create your first song.")
                    .font(.jbMono(.regular, size: 11 * sf))
                    .foregroundColor(QStageTheme.text3)
            }
            Spacer()
        } else {
            List {
                ForEach(store.songs) { song in
                    Button {
                        guard editMode != .active else { return }
                        path.append(song.id)
                    } label: {
                        SongCard(song: song, sf: sf)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5.5 * sf, leading: 16 * sf,
                                              bottom: 5.5 * sf, trailing: 16 * sf))
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

// Card brano (mock CD): superficie #141832, bordo --line, radius 16.
// Nome = Inter SemiBold; meta = JetBrains Mono. NESSUN badge sync.
private struct SongCard: View {
    let song: Song
    let sf: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4 * sf) {
                Text(song.name.isEmpty ? "Untitled" : song.name)
                    .font(.custom("Inter-SemiBold", size: 17 * sf))
                    .tracking(-0.2 * sf)
                    .foregroundColor(QStageTheme.text)
                Text(meta)
                    .font(.jbMono(.medium, size: 11 * sf))
                    .tracking(0.3 * sf)
                    .foregroundColor(QStageTheme.text2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16 * sf)
        .padding(.vertical, 14 * sf)
        .background(QStageTheme.surface, in: RoundedRectangle(cornerRadius: 16 * sf, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16 * sf, style: .continuous)
                .strokeBorder(QStageTheme.line, lineWidth: 1)
        )
    }

    // Display-only, derivato dai campi esistenti del modello. Zero logica di stato.
    private var meta: String {
        let n = song.sections.count
        let sec = "\(n) \(n == 1 ? "section" : "sections")"
        guard !song.sections.isEmpty else { return sec }
        let bpms = song.sections.map { Int($0.bpm.rounded()) }
        let lo = bpms.min()!, hi = bpms.max()!
        let bpm = (lo == hi) ? "\(lo) BPM" : "\(lo)–\(hi) BPM"
        let metros = Set(song.sections.map { "\($0.beatsPerBar)/\($0.beatUnit)" })
        let first = song.sections[0]
        let metro = (metros.count == 1) ? metros.first! : "\(first.beatsPerBar)/\(first.beatUnit)"
        return "\(sec) · \(bpm) · \(metro)"
    }
}
