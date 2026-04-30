import Foundation

struct AppSettings: Codable {
    var accentVolume: Double = 1.0   // [0.0, 1.0] — downbeat
    var beatVolume:   Double = 0.8   // [0.0, 1.0] — beat normale
    var subdivVolume: Double = 0.4   // [0.0, 1.0] — suddivisione
    var clickMuted:   Bool   = false // mute hard — i 3 gain interni restano invariati
}

extension AppSettings {
    private static let udKey = "com.bullfrog.qbeats.appSettings"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let s = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return s
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: AppSettings.udKey)
    }
}
