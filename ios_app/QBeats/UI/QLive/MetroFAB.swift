import SwiftUI

// MARK: - MetroFAB — Design System CD, freeze QLive Nav — §1.3 FROZEN
// Contratto vivo: DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0 (contiene le regole
// .metrofab). Scritto in origine contro il predecessore "standalone" (09/07) — file DISTINTO
// dalla "base", NON lo stesso documento, ma con le stesse regole CSS verificate byte-per-byte
// in FREEZE-GIT. R7 (LIBRO v31): nessuno sha inciso; si cita path @ commit, git verifica.
// ⚠️ RESO MAI VISTO A SCHERMO (nessun Xcode in ambiente CC). CI-verde ≠ chiuso.
//    🔴 Chiusura visiva = gate device S4, NON S3. Questo componente è istanziato SOLO dentro
//    NoShowsToPlayEmptyState (Frame Ⓔ = Q-Live), e Q-Live non esiste finché il Nodo A non è
//    sciolto (S4). L'unico empty-state che S3 monta è Q13 «No shows yet» di Q-Stage, che per
//    decisione CD (LIBRO v31, Q13) NON ha CTA né MetroFAB. Al gate S3 il MetroFAB NON è a
//    schermo: chi lo cerca lì per verificarlo non lo trova. (Reso ombra sotto: stesso gate S4.)
// Uscita esplicita al metronomo-libero (senza show). Componente condiviso Q-Live Shows + empty-state.
// Sorgente: `.metrofab .c` / `.metrofab .l` (§CSS .metrofab); path icona verbatim §markup .metrofab.
// NOTA (referee): `.metrofab{margin-top:auto; padding:0 0 30px}` (§CSS .metrofab) = layout del
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

    // .metrofab .c: 64×64 cerchio, bg orange .14, bordo orange .5 (1.5pt), shadow nero .55 (§CSS .metrofab .c).
    // FIX 6 (referee): l'ombra è sul solo cerchio (CSS box-shadow è sull'elemento `.c`, non sul
    // contenuto). Prima era sullo ZStack intero → SwiftUI proiettava anche l'ombra dell'icona,
    // che trapelava attraverso il fill al 14% come un alone offset di 6pt. L'icona ora è un
    // `.overlay` SOPRA il sottoalbero ombreggiato → nessuna ombra sull'icona.
    // ⚠️ 2° RESO NON VERIFICATO — INTENSITÀ OMBRA: in CSS box-shadow è disegnata dall'ELEMENTO
    // (opaco). In SwiftUI `.shadow()` deriva l'ombra dall'ALPHA del contenuto renderizzato, e il
    // fill è al 14% → l'ombra potrebbe risultare molto più debole del freeze (alone slavato
    // invece di ombra profonda). SOSPETTO, NON VERIFICATO: è rendering, non deducibile dal
    // codice. → GATE DEVICE S4 (NON S3): il MetroFAB appare a schermo solo quando Q-Live monta
    // Frame Ⓔ, dopo il Nodo A — vedi la nota di gate in testa al file. Se sul device l'ombra è
    // slavata, si casta da una shape opaca.
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

// Corpo + braccio, viewBox 24×24: "M9 3h6l3.2 18H5.8z" + "M12 20l3.2-11" (§markup .metrofab)
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

// Pivot: circle cx=13.7 cy=9.5 r=1.5, viewBox 24×24 (§markup .metrofab)
private struct MetronomePivotShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        let cx = rect.minX + 13.7 * scale
        let cy = rect.minY + 9.5 * scale
        let r = 1.5 * scale
        return Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }
}
