import SwiftUI

/// Contenitore di Q-Stage (authoring): 3 sezioni Songs · Shows · Media.
/// È la RADICE di Q-Stage: `TabView` in cima, una pila di navigazione dentro
/// ogni linguetta (pattern canonico SwiftUI). Raggiunto per commutazione di
/// schermata dalla Home (AppRootView), NON più come push di `AppDestination`.
/// PRIMA FETTA: completa solo la tab Songs; Shows e Media sono placeholder.
/// Nav-bar nativa nascosta ovunque: si usano header custom (stile app, cfr. HomeRootView).
/// `onExit()` torna alla Home (commutazione di schermata in AppRootView).
/// Possiede DUE seam: `onExit()` → Home, `onSwitchToLive()` → Q-Live (specchio di QLiveRootView).
struct QStageRootView: View {
    let onExit: () -> Void
    /// Switch di stanza → Q-Live. Iniettata da AppRootView
    /// (`{ screen = .qLive }` ESPLICITO, non un toggle).
    /// Specchio di `QLiveRootView.onSwitchToStage`.
    let onSwitchToLive: () -> Void
    @State private var tab: Tab = .songs

    private enum Tab: Hashable { case songs, shows, media }

    var body: some View {
        TabView(selection: $tab) {
            SongListView(onExit: onExit)
                .tabItem { Label("Songs", systemImage: "music.note.list") }
                .tag(Tab.songs)

            ShowsListView(onExit: onExit, onSwitchToLive: onSwitchToLive)
                .tabItem { Label("Shows", systemImage: "rectangle.stack") }
                .tag(Tab.shows)

            QStagePlaceholderTab(title: "Media",
                                 message: "Libreria Tracks — prossima fetta.",
                                 systemImage: "waveform",
                                 onExit: onExit)
                .tabItem { Label("Media", systemImage: "waveform") }
                .tag(Tab.media)
        }
        .tint(QStageTheme.accent)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }
}
