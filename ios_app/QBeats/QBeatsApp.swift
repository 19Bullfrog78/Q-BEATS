import SwiftUI
import os

@main
struct QBeatsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var audioEngine = AudioEngine.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingImportManifest: BackupManifest? = nil
    @State private var showImportView = false

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(audioEngine)
                .task {
                    do {
                        try await QBeatsStore.shared.load()
                    } catch {
                        os_log("[QBeatsApp] QBeatsStore.load failed: %{public}@",
                               log: .default, type: .error,
                               error.localizedDescription)
                    }
                }
                .sheet(isPresented: $showImportView) {
                    if let manifest = pendingImportManifest {
                        ImportView(manifest: manifest, store: QBeatsStore.shared)
                    }
                }
                .onOpenURL { url in
                    guard url.pathExtension.lowercased() == "qbeats" else { return }
                    os_log("[QBeatsApp] onOpenURL: %{public}@", log: .default, type: .default,
                           url.lastPathComponent)
                    Task {
                        do {
                            let manifest = try await QBeatsBackupManager.parse(url)
                            pendingImportManifest = manifest
                            showImportView = true
                        } catch {
                            os_log("[QBeatsApp] parse error: %{public}@", log: .default, type: .error,
                                   error.localizedDescription)
                        }
                    }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            os_log("[Q-BEATS][LIFECYCLE] scenePhase changed: → %{public}@",
                   log: .default, type: .default,
                   String(describing: newPhase))
            // Bug 4 fix: pattern Ableton bidirezionale (vedi LinkHutApp.swift
            // in examples/LinkHut/ del repo Ableton/LinkKit) adattato alla
            // preferenza utente Q-BEATS.
            //
            // LinkHut chiama SetActive(true) unconditional al .active perché
            // Link è sempre attivo quando l'app è aperta — non c'è preferenza
            // utente. Q-BEATS invece accende Link solo con la levetta del pannello
            // E un ruolo Director o Follower (A411 · SOLO-INERTE, regola
            // `LinkActivationDecision` nel motore): riaccendere unconditional al
            // primo .active lo metterebbe in rete contro la levetta o in Solo.
            //
            // Flag linkSuspendedByBackground traccia SOLO le sospensioni
            // autorizzate da noi al .background. La politica è quella di prima; da
            // A411 non accende e non spegne Link da sé: dà alla regola l'ingresso
            // «sospeso dallo sfondo» (`setLinkBackgroundSuspended`), e la regola decide.
            // Casi:
            // - Link fuori rete (levetta spenta, o Solo) → flag mai settato →
            //   .active non tocca niente
            // - Link in rete (Director o Follower) + audio fermo → sospeso al bg,
            //   ripresa al fg (flag traccia il restore)
            // - Link in rete + audio in corso → non tocchiamo (performance
            //   in background deve continuare)
            // - User cambia Link OFF→ON manualmente in foreground → flag
            //   resta false, prossimo ciclo bg/fg gestito correttamente
            // ⚠️ A412 · DIRETTORE IN CRISI, PASSO 2 (18/10/2026) — la politica e il segno «sospeso da noi» stanno
            //    ora nel motore (`AudioEngine.sceneEnteredBackground` / `sceneBecameActive`, regola
            //    `LinkActivationDecision.suspendsOnBackground`), perché c'è un caso in più che vive su audioQueue:
            //    col Direttore muto in canzone il click è fermo ma la canzone suona per la band, e Link non si
            //    sospende (mandato §2.8; BUGS, `TD-link-spento-in-secondo-piano-durante-lo-show`). Qui si passa
            //    solo «il click suona». I casi qui sopra restano veri; il flag `linkSuspendedByBackground` di
            //    questa struttura è uscito (è `_linkBackgroundSuspendedQ` nel motore).
            switch newPhase {
            case .background:
                AudioEngine.shared.sceneEnteredBackground(clickPlaying: AudioEngine.shared.isPlaying)
            case .active:
                AudioEngine.shared.sceneBecameActive()
            default: break
            }
        }
    }
}
