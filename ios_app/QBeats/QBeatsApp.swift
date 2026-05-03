import SwiftUI
import os

@main
struct QBeatsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var audioEngine = AudioEngine.shared
    @State private var pendingImportManifest: BackupManifest? = nil
    @State private var showImportView = false

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(audioEngine)
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
    }
}
