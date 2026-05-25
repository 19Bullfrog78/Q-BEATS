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
        AudioEngine.shared.refreshLinkSocket()
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
