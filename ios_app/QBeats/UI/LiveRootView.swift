import SwiftUI

struct LiveRootView: View {
    /// Nodo A — seam d'uscita fornito dal presenter (AppRootView via
    /// QLiveRootView: `{ screen = .home }`). Firma STABILE: cambia il
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
