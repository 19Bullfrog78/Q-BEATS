import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationWillTerminate(_ application: UIApplication) {
        AudioEngine.shared.disableLinkOnTerminate()
    }
}
