import SwiftUI
import CoreAudioKit

struct BTMIDICentralPickerView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> CABTMIDICentralViewController {
        return CABTMIDICentralViewController()
    }

    // CABTMIDICentralViewController non accetta injection di stato post-init.
    // updateUIViewController deve restare vuoto — non aggiungere logica qui.
    func updateUIViewController(_ uiViewController: CABTMIDICentralViewController,
                                context: Context) {}
}
