import SwiftUI

// MARK: - Token strutturali Q-Live — Design System CD (§3, freeze "Cancello 1" b23dfc78)
// Q-LIVE = ambiente "sul palco" → neutro antracite #0e0e10 (resta inline nelle viste Live).
// I 3 token qui erano marcati [DS] nel freeze ma ASSENTI dal codice → promossi (§3, "Zero-hex-fuori-DS").
// Namespace SEPARATO da QStageTheme (kit di Q-Stage; QStageKit.swift:4-5 riserva #0e0e10 alla sola Q-Live).
// NB: gli swatch colore-TAG restano fuori dal DS (R1-pending) finché R1 non ratifica la palette — NON qui.
enum QLiveTheme {
    static let surf = Color(hex: "#16161a")      // superficie card/pill Q-Live · --qlive-surf
    static let bd   = Color.white.opacity(0.06)  // bordo strutturale Q-Live    · --qlive-bd
    static let pick = Color(hex: "#1a1614")      // evidenza last-opened (cosmetica) · --qlive-pick
}
