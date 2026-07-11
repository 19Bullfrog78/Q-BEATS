import SwiftUI

// MARK: - MetroFAB — Design System CD, freeze "Cancello 1" (sha256 b23dfc78…) — §1.3 FROZEN
// ⚠️ RESO MAI VISTO A SCHERMO (nessun Xcode in ambiente CC). CI-verde ≠ chiuso.
//    Chiusura visiva = gate device S3, con il freeze aperto a fianco.
// Uscita esplicita al metronomo-libero (senza show). Componente condiviso Q-Live Shows + empty-state.
// Sorgente: `.metrofab .c` / `.metrofab .l` (§CSS :703-705); path icona verbatim §markup :878.
// NOTA (referee): `.metrofab{margin-top:auto; padding:0 0 30px}` (§CSS :703) = layout del
// CONTENITORE (posizione in coda alla lista/empty), NON del componente → DIFFERITO a S2/S6,
// non implementato qui.
struct MetroFAB: View {
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                circle
                Text("Metronome")
                    .font(.jbMono(.regular, size: 9))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(QStageTheme.text2)
            }
        }
        .buttonStyle(.plain)   // FIX 7 (referee): niente tint/dim di default SwiftUI (coerente con RoomSwitchBar)
    }

    // .metrofab .c: 64×64 cerchio, bg orange .14, bordo orange .5 (1.5pt), shadow nero .55 (§CSS :704).
    // FIX 6 (referee): l'ombra è sul solo cerchio (CSS box-shadow è sull'elemento `.c`, non sul
    // contenuto). Prima era sullo ZStack intero → SwiftUI proiettava anche l'ombra dell'icona,
    // che trapelava attraverso il fill al 14% come un alone offset di 6pt. L'icona ora è un
    // `.overlay` SOPRA il sottoalbero ombreggiato → nessuna ombra sull'icona.
    // ⚠️ 2° RESO NON VERIFICATO — INTENSITÀ OMBRA: in CSS box-shadow è disegnata dall'ELEMENTO
    // (opaco). In SwiftUI `.shadow()` deriva l'ombra dall'ALPHA del contenuto renderizzato, e il
    // fill è al 14% → l'ombra potrebbe risultare molto più debole del freeze (alone slavato
    // invece di ombra profonda). SOSPETTO, NON VERIFICATO: è rendering, non deducibile dal
    // codice. → GATE DEVICE S3, insieme all'hit-area. Se sul device l'ombra è slavata, si casta
    // da una shape opaca.
    private var circle: some View {
        ZStack {
            Circle()
                .fill(QStageTheme.orange.opacity(0.14))
            Circle()
                .strokeBorder(QStageTheme.orange.opacity(0.5), lineWidth: 1.5)
        }
        .frame(width: 64, height: 64)
        .shadow(color: Color.black.opacity(0.55), radius: 9, x: 0, y: 6)
        .overlay(icon)
    }

    // icona/testo orangeTint (--live-l). Fuori dal sottoalbero ombreggiato (FIX 6).
    private var icon: some View {
        ZStack {
            MetronomeBodyShape()
                // FIX 2 (referee): stroke-width SVG=1.6 in unità viewBox(24), reso a 30pt →
                // 1.6 × 30/24 = 2.0 sullo schermo (le coordinate erano già scalate).
                .stroke(QStageTheme.orangeTint, style: StrokeStyle(lineWidth: 1.6 * 30 / 24, lineCap: .round, lineJoin: .round))
            MetronomePivotShape()
                .fill(QStageTheme.orangeTint)
        }
        .frame(width: 30, height: 30)
    }
}

// Corpo + braccio, viewBox 24×24: "M9 3h6l3.2 18H5.8z" + "M12 20l3.2-11" (§markup :878)
private struct MetronomeBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale)
        }
        var path = Path()
        path.move(to: pt(9, 3))
        path.addLine(to: pt(15, 3))
        path.addLine(to: pt(18.2, 21))
        path.addLine(to: pt(5.8, 21))
        path.closeSubpath()
        path.move(to: pt(12, 20))
        path.addLine(to: pt(15.2, 9))
        return path
    }
}

// Pivot: circle cx=13.7 cy=9.5 r=1.5, viewBox 24×24 (§markup :878)
private struct MetronomePivotShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        let cx = rect.minX + 13.7 * scale
        let cy = rect.minY + 9.5 * scale
        let r = 1.5 * scale
        return Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }
}
