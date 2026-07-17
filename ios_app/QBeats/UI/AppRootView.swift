import SwiftUI
import os

struct AppRootView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true
    @State private var screen: Screen = .home
    /// Nodo A N1a — valore precedente di `screen` per il handler `.onChange`
    /// (iOS 16 dà solo il valore NUOVO). Serve a sapere DA DOVE si viene, così
    /// il handler può fermare l'audio quando la transizione LASCIA `.qLive`.
    @State private var previousScreen: Screen = .home

    /// Routing top-level della Home: commutazione di schermata (NON push).
    /// Nodo A N1a: `.qLive` aggiunto all'enum come DEAD CODE — la porta Q-Live
    /// resta su `presentLive()` (modale UIKit) fino a N1b, quindi il path
    /// `.qLive` è irraggiungibile finché nessuno setta `screen = .qLive`.
    private enum Screen { case home, qStage, qLive }

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
                case .home:
                    HomeRootView(onOpenQStage: { screen = .qStage },
                                 onOpenQLive: { screen = .qLive })
                case .qStage:
                    QStageRootView(onExit: { screen = .home })
                        .environmentObject(audioEngine)
                case .qLive:
                    // Nodo A N1a — arm DEAD CODE (specchio di `.qStage`). QLiveRootView
                    // possiede il seam onExit e lo inoltra a LiveRootView; la closure
                    // `{ screen = .home }` vive SOLO qui (E2, `Screen` private enum).
                    QLiveRootView(onExit: { screen = .home })
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
        // Nodo A N1a — stop-audio CANONICO su transizione + DND all'ingresso Q-Live.
        // Al PUNTO-DI-MUTAZIONE dell'enum, DETERMINISTICO — NON `.onDisappear`
        // (non-deterministico su view riusata/cachata). iOS 16: `onChange` dà solo
        // il valore NUOVO → `previousScreen` fornisce il precedente.
        // INERTE in N1a (`.qLive` irraggiungibile, nessuna transizione lo tocca);
        // si attiva da N1b; copre lo step-3 RoomSwitchBar automaticamente.
        // La `triggerDNDReminderIfNeeded()` qui è la copia PRE-PIAZZATA: coesiste
        // con quella viva in `HomeRootView.presentLive()` finché N1b non rimuove
        // `presentLive()` (una viva, una inerte — voluto).
        .onChange(of: screen) { newScreen in
            if newScreen == .qLive {
                audioEngine.triggerDNDReminderIfNeeded()
            } else if previousScreen == .qLive {
                audioEngine.stop()
            }
            previousScreen = newScreen
        }
    }
}
