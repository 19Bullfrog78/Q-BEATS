import Foundation

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — LE VOCI DEL SELETTORE «MODE» ===
// Tre voci: «Solo» (`.standalone`, il default), «Director», «Follower»; l'ordine è una decisione del referee (il
// default per primo; mandato M3 §3.8). Motivo: BUGS, `TD-mode-picker-senza-solo` («chi sceglie Follower una volta
// resta con un ruolo che non sa togliersi»; gravità ratificata da Mauro il 22/08, da chiudere prima della v1); serve
// anche al collaudo di M3. Il banco cade se un ruolo di `LinkMode` resta senza voce.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct LinkModeMenuEntry: Equatable {
    let mode: LinkMode
    let title: String
}

enum LinkModeMenu {
    static let entries: [LinkModeMenuEntry] = [
        LinkModeMenuEntry(mode: .standalone, title: "Solo"),
        LinkModeMenuEntry(mode: .direttore, title: "Director"),
        LinkModeMenuEntry(mode: .collaborativa, title: "Follower"),
    ]

    /// Il titolo di un ruolo.
    static func title(for mode: LinkMode) -> String {
        entries.first { $0.mode == mode }?.title ?? mode.rawValue
    }
}
