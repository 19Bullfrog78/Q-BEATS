import Foundation

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
