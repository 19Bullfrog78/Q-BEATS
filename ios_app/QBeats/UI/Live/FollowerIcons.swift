import SwiftUI

// A386 · B2b (30/09/2026) — LE QUATTRO ICONE DI STATO DEL FOLLOWER, dai tracciati SVG del
// foglio CD 2D-QUATER (file 1, «icone · 4 + riserva», `.qb-ic`: viewBox 24×24, `fill:none`,
// `stroke:currentColor`, `stroke-width:2`, estremi e giunzioni arrotondati). Vettoriali: si
// disegnano con `Path` nel riquadro dato, col colore dello stato (ambra), alte 1,15 volte il
// corpo del testo accanto (`.qb-ic{width:1.15em;height:1.15em}`). La regola d'app (LIBRO
// `2026-09-26` «REGOLA D'APP: LE ICONE DI STATO»): un'icona di stato compare solo quando
// qualcosa non va o c'è da agire; quando tutto va bene c'è il pallino verde. Del Direttore si
// costruisce solo la prima scelta (con la bacchetta): la riserva (sola figura barrata) resta
// nel foglio per il collaudo — se non passa la prova dell'asta, si cambia con un mandato piccolo.
// Ogni segmento qui sotto cita il comando SVG che traduce, con le coordinate del viewBox.
struct FollowerIconShape: Shape {
    let icon: FollowerVeilDecision.Icon

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let ox = rect.minX + (rect.width - 24 * s) / 2
        let oy = rect.minY + (rect.height - 24 * s) / 2
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
        func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: ox + x * s, y: oy + y * s, width: w * s, height: h * s)
        }
        var p = Path()
        switch icon {
        case .directorBarred:
            // Il Direttore, barrato: una figura con la bacchetta (il ruolo, non una persona).
            // <circle cx="9" cy="7.5" r="3.2"/>
            p.addEllipse(in: box(9 - 3.2, 7.5 - 3.2, 6.4, 6.4))
            // <path d="M3 20.5c0-4 2.7-6.5 6-6.5s6 2.5 6 6.5M14.5 11l6-7"/> — le spalle (una
            // cubica e la sua simmetrica), poi la bacchetta.
            p.move(to: pt(3, 20.5))
            p.addCurve(to: pt(9, 14), control1: pt(3, 16.5), control2: pt(5.7, 14))
            p.addCurve(to: pt(15, 20.5), control1: pt(12.3, 14), control2: pt(15, 16.5))
            p.move(to: pt(14.5, 11))
            p.addLine(to: pt(20.5, 4))
            // <path d="M2.5 2.5l19 19"/> — la barra.
            p.move(to: pt(2.5, 2.5))
            p.addLine(to: pt(21.5, 21.5))
        case .playStopBarred:
            // Play-Stop, barrato: il simbolo del trasporto che Start Stop Sync sincronizza.
            // <path d="M3 7l7 5-7 5z"/>
            p.move(to: pt(3, 7))
            p.addLine(to: pt(10, 12))
            p.addLine(to: pt(3, 17))
            p.closeSubpath()
            // <rect x="13" y="7.5" width="8.5" height="9" rx="1"/>
            p.addRoundedRect(in: box(13, 7.5, 8.5, 9), cornerSize: CGSize(width: s, height: s))
            // <path d="M2.5 2.5l19 19"/>
            p.move(to: pt(2.5, 2.5))
            p.addLine(to: pt(21.5, 21.5))
        case .noEntry:
            // Divieto d'accesso: solo sui due rifiuti di R1.
            // <circle cx="12" cy="12" r="9.2"/>
            p.addEllipse(in: box(12 - 9.2, 12 - 9.2, 18.4, 18.4))
            // <path d="M7 12h10"/>
            p.move(to: pt(7, 12))
            p.addLine(to: pt(17, 12))
        case .toTheBarline:
            // Fino alla stanghetta: sulla fascia DA SOLO.
            // <path d="M2.5 12h13M10.5 6l6 6-6 6M20.5 4.5v15"/>
            p.move(to: pt(2.5, 12))
            p.addLine(to: pt(15.5, 12))
            p.move(to: pt(10.5, 6))
            p.addLine(to: pt(16.5, 12))
            p.addLine(to: pt(10.5, 18))
            p.move(to: pt(20.5, 4.5))
            p.addLine(to: pt(20.5, 19.5))
        }
        return p
    }
}

/// L'icona nel colore dello stato, alta `size` (= 1,15 × il corpo accanto, dal chiamante).
struct FollowerIconView: View {
    let icon: FollowerVeilDecision.Icon
    let size: CGFloat
    let color: Color

    var body: some View {
        FollowerIconShape(icon: icon)
            .stroke(color, style: StrokeStyle(lineWidth: size * QLiveStage.Follower.iconStrokeRatio,
                                              lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}
