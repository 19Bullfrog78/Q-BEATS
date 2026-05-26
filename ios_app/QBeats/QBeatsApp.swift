import SwiftUI
import os

@main
struct QBeatsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var audioEngine = AudioEngine.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var linkSuspendedByBackground = false
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
            // utente. Q-BEATS invece ha toggle utente per disabilitare Link
            // (persisted): se chiamassimo setLinkEnabled(true) unconditional
            // riaccenderemmo Link contro la volontà dell'utente al primo
            // .active (vedi log cold launch con persistedEnabled:0).
            //
            // Flag linkSuspendedByBackground traccia SOLO le sospensioni
            // autorizzate da noi al .background. Casi:
            // - User Link OFF → flag mai settato → .active non tocca niente
            // - User Link ON + audio fermo → SetActive(false) al bg, ripristino
            //   al fg (flag traccia il restore)
            // - User Link ON + audio in corso → non tocchiamo (performance
            //   in background deve continuare)
            // - User cambia Link OFF→ON manualmente in foreground → flag
            //   resta false, prossimo ciclo bg/fg gestito correttamente
            switch newPhase {
            case .background:
                if AudioEngine.shared.linkEnabled && !AudioEngine.shared.isPlaying {
                    linkSuspendedByBackground = true
                    AudioEngine.shared.setLinkEnabled(false)
                }
            case .active:
                if linkSuspendedByBackground {
                    linkSuspendedByBackground = false
                    AudioEngine.shared.setLinkEnabled(true)
                }
            default: break
            }
        }
    }
}
