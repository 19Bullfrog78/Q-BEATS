import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationWillTerminate(_ application: UIApplication) {
        AudioEngine.shared.disableLinkOnTerminate()
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        // LinkKit best practice: re-asserisci ABLLinkSetActive(true) al ritorno active.
        // Solo se l'utente ha Link abilitato — non forziamo lo stato.
        if AudioEngine.shared.linkEnabled {
            AudioEngine.shared.setLinkEnabled(true)
        }
    }
}
