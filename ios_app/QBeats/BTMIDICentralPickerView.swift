import SwiftUI
import CoreAudioKit
import os.log
import CoreBluetooth

struct BTMIDICentralPickerView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> CABTMIDICentralViewController {
        // Log minimo richiesto per Build #66 FINAL
        os_log("🔵 BT Picker: Apertura richiesta - Authorization status: %d", CBManager.authorization.rawValue)
        
        let picker = CABTMIDICentralViewController()
        
        os_log("🔵 BT Picker: CABTMIDICentralViewController presentato")
        
        return picker
    }

    // CABTMIDICentralViewController non accetta injection di stato post-init.
    // updateUIViewController deve restare vuoto — non aggiungere logica qui.
    func updateUIViewController(_ uiViewController: CABTMIDICentralViewController,
                                context: Context) {}
}
