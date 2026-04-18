import SwiftUI
import UIKit

struct LinkSettingsUIView: UIViewControllerRepresentable {
    let presenter: LinkSettingsPresenter

    func makeUIViewController(context: Context) -> UIViewController {
        return presenter.makeSettingsViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Nothing to update
    }
}
