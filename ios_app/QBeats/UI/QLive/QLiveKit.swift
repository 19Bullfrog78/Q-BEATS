import SwiftUI

// MARK: - Token strutturali Q-Live — Design System CD (§3, freeze "Cancello 1" b23dfc78)
// Q-LIVE = ambiente "sul palco" → neutro antracite #0e0e10 (resta inline nelle viste Live).
// I 3 token qui erano marcati [DS] nel freeze ma ASSENTI dal codice → promossi (§3, "Zero-hex-fuori-DS").
// Namespace SEPARATO da QStageTheme (kit di Q-Stage; QStageKit.swift:4-5 riserva #0e0e10 alla sola Q-Live).
// NB: gli swatch colore-TAG restano fuori dal DS (R1-pending) finché R1 non ratifica la palette — NON qui.
enum QLiveTheme {
    static let surf   = Color(hex: "#16161a")    // superficie card/pill Q-Live · --qlive-surf
    static let bd     = Color.white.opacity(0.06)// bordo strutturale Q-Live    · --qlive-bd
    static let pick   = Color(hex: "#1a1614")    // evidenza last-opened (cosmetica) · --qlive-pick
    // Q20 (congedo tastiera, 2026-07-26_QLive-Shows-Keyboard-Dismiss__Q20-RIEMISSIONE.html):
    // token propri di Q-Live, MAI QStageTheme.orangeTint — stanze separate, coincidenza di
    // valore permessa e attesa (LIBRO riga 2026-07-27, clausola 1 della palette).
    static let accent = Color(hex: "#ff8a5c")    // Q20 r.32 --live-l · uso r.104 .kbdone (Done)
    static let kbbar  = Color(hex: "#1c1c20")    // Q20 r.103 .kbtoolbar background
}

// MARK: - Scala di palco — P = 17, solo iPhone (BOX5 «SCALA DI PALCO», ratificata Mauro 11/09/2026, incisa A348)
// A355 — QUI VIVONO I TOKEN CHE IL VELO USA, E SOLO QUELLI, coi nomi che portano in
// BOX5: un posto solo. ⛔ Non è la scala intera: un token si aggiunge qui quando una
// vista lo usa (STAGE-SECONDARY, STAGE-BODY, STAGE-DATA, STAGE-TITLE non ci sono
// perché il velo non li usa). Grandezze in punti su base 390, pavimento P = 17.
// Fra apparecchi vale `dimensione = max(pavimento, base × scaleFactor)` (BOX5, riga
// «Fra device»): `scaled(_:_:)` qui sotto. Sull'iPad è la stessa legge provvisoria del
// resto della Vista LIVE — l'iPad si fa a parte (LIBRO, riga 2026-09-11 «L'iPAD SI FA
// A PARTE, DOPO L'iPHONE»).
enum QLiveStage {
    /// STAGE-CAPS — occhielli, gesto del velo, chrome della testata.
    /// 1,25 × 17 = 21,25 → 21 · JetBrains Mono 600 · spaziatura 1,5 · maiuscole · bianco 0,60.
    enum Caps {
        static let size: CGFloat = 21
        static let weight: Font.Weight = .semibold
        static let tracking: CGFloat = 1.5
        static let opacity: Double = 0.60
    }
    /// STAGE-HERO — nome di sezione in play, nome canzone sul velo.
    /// 4,00 × 17 = 68 · Inter 900 (`Inter-Black`) · spaziatura −1,6 · bianco pieno.
    enum Hero {
        static let size: CGFloat = 68
        static let fontName = "Inter-Black"
        static let tracking: CGFloat = -1.6
    }
    /// STAGE-NEXT — la sezione che viene dopo, pavimento del gigante.
    /// 2,60 × 17 = 44,2 → 44. Il velo ne usa solo la grandezza: è il pavimento sotto
    /// cui il nome non scende (regola del gigante, BOX5).
    enum Next {
        static let size: CGFloat = 44
    }
    /// Il velo: distanze e margine della lastra ① (foglio CD 11/09
    /// IL-FOLLOWER-NON-TOCCA-IL-TRASPORTO, `.vnm` margin-top 11 · `.vhint` margin-top 26),
    /// riportate al pavimento 17 con k = 17/13 = 1,308 (BOX5, «Le distanze crescono col
    /// pavimento»); margine 26 di LA-TABELLA-FINALE §③ (larghezza utile 390 − 2×26 = 338).
    enum Veil {
        static let k: CGFloat = 17.0 / 13.0
        /// A→B: 11 × k = 14,39 → 14.
        static let gapRelationToName: CGFloat = (11 * k).rounded()
        /// B→C: 26 × k = 34,01 → 34.
        static let gapNameToGesture: CGFloat = (26 * k).rounded()
        static let horizontalMargin: CGFloat = 26
        /// Pulsazione del nome, invariata (BOX5 «Overlay Standby»).
        static let pulsePeriod: Double = 2.2
        static let pulseOpacityLow: Double = 0.45
        static let pulseOpacityHigh: Double = 1.0
    }

    /// `dimensione = max(pavimento, base × scaleFactor)` = token × max(1, scaleFactor).
    static func scaled(_ token: CGFloat, _ scaleFactor: CGFloat) -> CGFloat {
        token * max(1, scaleFactor)
    }
}
