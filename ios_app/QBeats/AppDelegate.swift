import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach {
                    $0.backgroundColor = UIColor(red: 0.055, green: 0.055, blue: 0.063, alpha: 1)
                }
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AudioEngine.shared.disableLinkOnTerminate()
    }
}
