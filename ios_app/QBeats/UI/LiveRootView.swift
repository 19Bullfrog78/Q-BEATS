import SwiftUI

struct LiveRootView: View {
    @EnvironmentObject var audioEngine: AudioEngine

    var body: some View {
        LiveView()
            .environmentObject(audioEngine)
    }
}
