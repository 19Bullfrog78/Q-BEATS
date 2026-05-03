import SwiftUI
import os

enum AppDestination: Hashable {
    case studio
}

struct AppRootView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var appNav: AppNavigationState
    @State private var showSplash = true
    @State private var path = NavigationPath()

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
                NavigationStack(path: $path) {
                    BivioBoardView(path: $path)
                        .navigationDestination(for: AppDestination.self) { destination in
                            switch destination {
                            case .studio:
                                StudioRootView()
                                    .environmentObject(audioEngine)
                            }
                        }
                }
            }

            if appNav.showLive {
                LiveRootView()
                    .environmentObject(audioEngine)
                    .ignoresSafeArea(.all)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea(.all)
        .onChange(of: appNav.showLive) { isShowing in
            if !isShowing { audioEngine.stop() }
        }
    }
}
