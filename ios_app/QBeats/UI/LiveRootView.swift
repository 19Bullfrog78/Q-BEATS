import SwiftUI

struct LiveRootView: View {
    @EnvironmentObject var audioEngine: AudioEngine

    // L1.b DEV FALLBACK — sostituire con selezione setlist (F2.3)
    @StateObject private var runner = SetlistRunner(
        setlist: QBeatsStore.shared.setlists.first ?? Setlist.makeDefault(),
        store: .shared
    )

    var body: some View {
        LiveView()
            .environmentObject(audioEngine)
            .environmentObject(runner)
    }
}
