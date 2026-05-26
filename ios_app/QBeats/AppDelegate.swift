import UIKit
import os

class AppDelegate: NSObject, UIApplicationDelegate {

    func applicationWillTerminate(_ application: UIApplication) {
        os_log("[Q-BEATS][LIFECYCLE] applicationWillTerminate",
               log: .default, type: .default)
        AudioEngine.shared.disableLinkOnTerminate()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        os_log("[Q-BEATS][LIFECYCLE] applicationDidBecomeActive",
               log: .default, type: .default)
        // NOTE: refreshLinkSocket() RIMOSSO — questo callback non scatta
        // in app SwiftUI scene-based (verificato commit 251183d). Fix Bug 4
        // vive in QBeatsApp.swift via .onChange(of: scenePhase) — pattern
        // bidirezionale .background/.active.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        os_log("[Q-BEATS][LIFECYCLE] applicationWillEnterForeground",
               log: .default, type: .default)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        os_log("[Q-BEATS][LIFECYCLE] applicationDidEnterBackground",
               log: .default, type: .default)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        os_log("[Q-BEATS][LIFECYCLE] applicationWillResignActive",
               log: .default, type: .default)
    }
}
