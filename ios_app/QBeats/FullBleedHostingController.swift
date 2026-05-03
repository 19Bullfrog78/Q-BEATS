import SwiftUI
import UIKit

final class FullBleedHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.055, green: 0.055, blue: 0.063, alpha: 1)
        additionalSafeAreaInsets = UIEdgeInsets(top: -1000, left: 0, bottom: -1000, right: 0)
    }
}
