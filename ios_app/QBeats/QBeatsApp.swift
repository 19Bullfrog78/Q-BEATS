import SwiftUI

@main
struct QBeatsApp: App {
    init() {
        // Test di comunicazione col Core C++
        let handle = metronome_create(48000.0, 120.0)
        if handle != nil {
            print("🟢 Q-BEATS: Motore C++ collegato con successo. BPM Iniziale: 120")
            metronome_setBPM(handle, 140.0)
            print("🟢 Q-BEATS: BPM aggiornato a 140 tramite C-Interface.")
            metronome_destroy(handle)
        } else {
            print("🔴 Q-BEATS: ERRORE CRITICO - Impossibile creare l'handle C++")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
