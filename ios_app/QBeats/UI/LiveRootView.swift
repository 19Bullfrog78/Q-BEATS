import SwiftUI

struct LiveRootView: View {
    /// Nodo A N0 — seam d'uscita fornito dal presenter (oggi
    /// HomeRootView.presentLive → dismiss della modale; da N1b AppRootView
    /// → { screen = .home }). Firma STABILE per N1a/N1b: cambia il
    /// chiamante, non LiveRootView.
    let onExit: () -> Void

    @EnvironmentObject var audioEngine: AudioEngine

    // L1.b DEV FALLBACK — sostituire con selezione setlist (F2.3)
    @StateObject private var runner = SetlistRunner(
        setlist: QBeatsStore.shared.setlists.first ?? Setlist.makeDefault(),
        store: .shared
    )

    var body: some View {
        LiveView(onExit: onExit)
            .environmentObject(audioEngine)
            .environmentObject(runner)
    }
}
