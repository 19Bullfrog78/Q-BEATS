import Foundation

// === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — LE FACCE DELLE SPIE: LINK, WI-FI, MIDI ===
// Fonti: foglio c) Solo REV9, tabella «3 · Le misure per chi costruisce», riga «Riga di stato»
// («LED 10: verde #00c96e = collegato, bianco .18 = spento · problema: icona 20 + parola in
// ambra · striscia ambra solo per Link»), facce ① e ②, schermo G («Link lost»); «MIDI» al posto
// di «Bluetooth» (punto 98 del foglio Solo REV17); LIBRO riga 2026-10-04, punti 42 e 52: ambra
// solo se la cosa era collegata e si è persa durante lo show, mai collegata = grigia, cambia
// subito anche a canzone in corso.
// Ingressi: Link acceso dall'utente, i tre collegati, i tre ricordi (`ShowConnectionMemory`).
// Uscite: la faccia di ogni spia; se «Link» si mostra (solo con Link acceso dall'utente); il testo
// della striscia, solo per Link: «Link lost», oppure «Link lost · no Wi-Fi» se anche il Wi-Fi è
// visto e perso. In M1 non la legge ancora nessuna vista.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum StatusLightFace: Equatable {
    /// Verde: collegato.
    case connected
    /// Grigio: spento, o mai visto collegato in questo show.
    case off
    /// Ambra con l'icona barrata: visto collegato in questo show e ora perso.
    case lost
}

struct StatusLights: Equatable {
    /// `nil`: la spia «Link» non si mostra (Link spento dall'utente).
    let link: StatusLightFace?
    let wifi: StatusLightFace
    let midi: StatusLightFace
    /// La striscia ambra, solo per Link; `nil` = nessuna striscia.
    let strip: String?
}

enum StatusLightsDecision {

    static let linkLostStrip = "Link lost"
    static let linkLostNoWifiStrip = "Link lost · no Wi-Fi"

    /// La faccia di una spia: collegata → verde; non collegata → ambra se vista in questo show,
    /// altrimenti grigia.
    static func face(connected: Bool, seen: Bool) -> StatusLightFace {
        if connected { return .connected }
        return seen ? .lost : .off
    }

    static func lights(linkUserEnabled: Bool,
                       linkConnected: Bool,
                       wifiConnected: Bool,
                       midiConnected: Bool,
                       memory: ShowConnectionMemory) -> StatusLights {
        let wifi = face(connected: wifiConnected, seen: memory.wifiSeen)
        let midi = face(connected: midiConnected, seen: memory.midiSeen)
        guard linkUserEnabled else {
            return StatusLights(link: nil, wifi: wifi, midi: midi, strip: nil)
        }
        let link = face(connected: linkConnected, seen: memory.linkSeen)
        let strip: String?
        if link == .lost {
            strip = (wifi == .lost) ? linkLostNoWifiStrip : linkLostStrip
        } else {
            strip = nil
        }
        return StatusLights(link: link, wifi: wifi, midi: midi, strip: strip)
    }
}
