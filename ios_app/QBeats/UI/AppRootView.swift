import SwiftUI
import os

struct AppRootView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true
    @State private var screen: Screen = .bivio

    /// Routing top-level del Bivio: commutazione di schermata (NON push).
    /// Q-Live resta una modale UIKit presentata a parte (cfr. BivioBoardView),
    /// fuori da questo enum — riconciliazione top-level = Nodo A (a verbale).
    private enum Screen { case bivio, qStage }

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                switch screen {
                case .bivio:
                    BivioBoardView(onOpenQStage: { screen = .qStage })
                case .qStage:
                    QStageRootView(onExit: { screen = .bivio })
                        .environmentObject(audioEngine)
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onChange(of: scenePhase) { newPhase in
            UIApplication.shared.isIdleTimerDisabled = (newPhase == .active)
        }
    }
}
