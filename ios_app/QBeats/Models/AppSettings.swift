import Foundation

// A360 (16/09/2026) — `enum LinkMode` è TRASLOCATO in `Models/LinkMode.swift`, tale e
// quale: lo legge la regola del Follower (`FollowerDecision`, Models/) e il banco
// `QBeatsTests` compila solo `QBeats/Models`. Qui non cambia niente: stesso modulo.
// A411 · SOLO-INERTE (18/10/2026) — anche questo file è TRASLOCATO in `Models/` (prima era
// `QBeats/AppSettings.swift`), per la stessa ragione: il banco deve leggere i salvataggi.
// IL RUOLO NON SI SALVA PIÙ. A ogni apertura l'app è in Solo (LIBRO, riga 2026-07-01: «parte
// SEMPRE Standalone, ruolo scelto a mano a ogni avvio, nessuno stato memorizzato»; mandato
// SOLO-INERTE §2.1). `linkMode` resta un campo — lo scrive il menu Mode, lo legge `applySettings` —
// ma esce dalle chiavi del salvataggio (`CodingKeys` qui sotto): non si scrive, e da un salvataggio
// di prima, che lo porta, non si legge (la chiave in più si ignora). Volumi e resto come prima.

struct AppSettings: Codable {
    var accentVolume: Double = 1.0   // [0.0, 1.0] — downbeat
    var beatVolume:   Double = 0.8   // [0.0, 1.0] — beat normale
    var subdivVolume: Double = 0.4   // [0.0, 1.0] — suddivisione
    var clickMuted:   Bool   = false // mute hard — i 3 gain interni restano invariati
    var ch1Volume:    Float  = 1.0
    var ch2Volume:    Float  = 1.0
    var ch3Volume:    Float  = 0.0
    var ch4Volume:    Float  = 0.0
    var showDNDReminder: Bool = true
    var linkMode:     LinkMode = .standalone

    // A411 — le chiavi del salvataggio: tutti i campi tranne `linkMode`.
    private enum CodingKeys: String, CodingKey {
        case accentVolume, beatVolume, subdivVolume, clickMuted
        case ch1Volume, ch2Volume, ch3Volume, ch4Volume
        case showDNDReminder
    }
}

extension AppSettings {
    private static let udKey = "com.bullfrog.qbeats.appSettings"

    /// A411 — il ruolo scritto in un salvataggio di prima (fino ad A410 il ruolo si salvava), letto solo
    /// per la riga di registro all'avvio. `nil` = nessun ruolo nel salvataggio, o salvataggio illeggibile.
    static func savedRole(in data: Data) -> String? {
        struct SavedRole: Decodable { let linkMode: String? }
        return (try? JSONDecoder().decode(SavedRole.self, from: data))?.linkMode
    }

    /// A411 — come `savedRole(in:)`, dal salvataggio dell'app; `nil` anche se non c'è un salvataggio.
    static func savedRoleInDefaults() -> String? {
        guard let data = UserDefaults.standard.data(forKey: udKey) else { return nil }
        return savedRole(in: data)
    }

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let s = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return s
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.udKey)
    }

    mutating func updateChannelVolumes(ch1: Float, ch2: Float, ch3: Float, ch4: Float) {
        ch1Volume = ch1
        ch2Volume = ch2
        ch3Volume = ch3
        ch4Volume = ch4
        save()
    }
}
