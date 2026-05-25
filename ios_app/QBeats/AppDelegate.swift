import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationWillTerminate(_ application: UIApplication) {
        AudioEngine.shared.disableLinkOnTerminate()
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        // LinkKit: ABLLinkSetActive(true) è no-op se già true (vedi commit 9a2e529).
        // iOS sospende il socket multicast UDP in background → al ritorno foreground
        // serve un toggle false→true a livello C++ per riallocarlo.
        // refreshLinkSocket() è idempotente — se Link non è abilitato, è no-op.
        AudioEngine.shared.refreshLinkSocket()
    }
}
