import SwiftUI

/// Contenitore di Q-Stage (authoring): 3 sezioni Songs · Shows · Media.
/// Vive come push dal Bivio (AppRootView, AppDestination.qStage; audioEngine già iniettato).
/// PRIMA FETTA: completa solo la tab Songs; Shows e Media sono placeholder.
/// Nav-bar nativa nascosta ovunque: si usano header custom (stile app, cfr. BivioBoardView).
/// `dismiss()` torna al Bivio (pop del push esterno).
struct QStageRootView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .songs

    private enum Tab: Hashable { case songs, shows, media }

    var body: some View {
        TabView(selection: $tab) {
            SongListView(onExit: { dismiss() })
                .tabItem { Label("Songs", systemImage: "music.note.list") }
                .tag(Tab.songs)

            QStagePlaceholderTab(title: "Shows",
                                 message: "Setlist authoring — prossima fetta.",
                                 systemImage: "rectangle.stack",
                                 onExit: { dismiss() })
                .tabItem { Label("Shows", systemImage: "rectangle.stack") }
                .tag(Tab.shows)

            QStagePlaceholderTab(title: "Media",
                                 message: "Libreria Tracks — prossima fetta.",
                                 systemImage: "waveform",
                                 onExit: { dismiss() })
                .tabItem { Label("Media", systemImage: "waveform") }
                .tag(Tab.media)
        }
        .tint(QStageTheme.accent)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }
}
