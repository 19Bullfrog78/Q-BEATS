import Foundation

struct AppSettings: Codable {
    var accentVolume: Double = 1.0   // [0.0, 1.0] — downbeat
    var beatVolume:   Double = 0.8   // [0.0, 1.0] — beat normale
    var subdivVolume: Double = 0.4   // [0.0, 1.0] — suddivisione
    var clickMuted:   Bool   = false // mute hard — i 3 gain interni restano invariati
}
