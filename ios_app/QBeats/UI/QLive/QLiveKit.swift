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
// ⚠️ MARCATURA A360 (16/09/2026) — STAGE-SECONDARY è entrato (`Secondary`, sotto): lo usa
//    la riga 2 dello slot E del velo (lastra ⑧). Gli altri tre restano fuori, per la
//    stessa ragione di prima. I token del velo li usa ora anche la fascia del Follower
//    (`TransportView`, riga-regola in STAGE-CAPS): il posto resta uno.
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
    /// STAGE-SECONDARY — sottoriga ambra, etichette di tasto in minuscolo, note.
    /// 1,00 × 17 = 17 · JetBrains Mono 500-700 · spaziatura 0,3 · bianco 0,60 (BOX5, tabella
    /// P = 17). A360: la riga 2 dello slot E del velo (lastra ⑧ `.vlink .c`: peso 500,
    /// minuscolo come è scritta). Il peso 500 è `JetBrainsMono-Medium`, già registrato
    /// (`Font+JBMono.swift`, `project.yml`).
    enum Secondary {
        static let size: CGFloat = 17
        static let weight: Font.Weight = .medium
        static let tracking: CGFloat = 0.3
        static let opacity: Double = 0.60
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
        /// A360 — slot E della lastra ⑧ (`.vlink`): C→E `margin-top:26px` («lo stesso respiro
        /// di B→C») × k = 34,01 → 34; fra le due righe `gap:5px` × k = 6,54 → 7.
        static let gapGestureToStatus: CGFloat = (26 * k).rounded()
        static let gapStatusLines: CGFloat = (5 * k).rounded()
        /// A360 — l'ambra della riga 1 dello slot E (`.vlink .s`, `#f5b820`): già in uso
        /// (`LiveHeaderView` muto, `TransportView` lampo di KILL BASE). Nessun colore nuovo:
        /// solo un nome per un valore che c'era.
        static let statusAmber = Color(hex: "#f5b820")
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
