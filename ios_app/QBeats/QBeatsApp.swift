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
            // Bug 4 fix: refresh Link socket multicast al ritorno foreground.
            // UIApplicationDelegate.applicationDidBecomeActive non scatta in app
            // SwiftUI scene-based (verificato empiricamente con diag commit 251183d
            // — log lifecycle AppDelegate mai apparsi). ScenePhase è la fonte di
            // verità per lifecycle in Q-BEATS.
            if newPhase == .active {
                AudioEngine.shared.refreshLinkSocket()
            }
        }
    }
}
