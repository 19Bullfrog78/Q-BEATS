import SwiftUI

// MARK: - EmptyStateKit — blocchi base condivisi per gli empty-state, Design System CD
// Estratti da QLiveEmptyStates.swift in S2d: `EmptyStateLayout`, `EmptyIconBadge` e
// `NoShowsIconShape` sono usati sia dalle subview Q-Live (Ⓔ/Ⓕ/Ⓖ) sia dall'empty-state Q13
// «No shows yet» di Q-STAGE. Riusarli dal file "QLive" avrebbe fatto dipendere Q-Stage da
// QLive; duplicarli avrebbe creato due copie destinate a divergere → estratti qui, neutri.
// Move puro (S2d): zero cambi di comportamento, solo `private`→`internal`.
// Sorgente: freeze QLive Nav di CD, contratto vivo
// DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0. R7 (LIBRO v31): riferimenti per
// SELETTORE, nessuno sha inciso, nessun riferimento a riga verso il freeze.
// ⚠️ RESO MAI VISTO A SCHERMO (nessun Xcode in ambiente CC). CI-verde ≠ chiuso.
//    GATE di questi componenti condivisi = device S3, ma SOLO via Q13 «No shows yet» di
//    Q-Stage (l'unica schermata che li monta a S3, dopo questa estrazione S2d). I gate
//    per-simbolo restano sui rispettivi commenti sotto.
// ⚠️ Debito PRE-ESISTENTE (mini-TD 🔵, fuori perimetro S2d): `EmptyStateLayout` usa
//    `QStageTheme.text3` (via QStageKit) → un componente in `UI/Components/` dipende da un
//    tema di stanza. Compila (stesso modulo), ma è un odore. Non risolto qui — vedi BUGS.
//
// Layout condiviso `.empty` (§CSS): flex:1, column, center, gap 15,
// padding 24px 34px, text-align:center → VStack(spacing:15) espanso a riempire lo
// spazio verticale disponibile nel genitore, contenuto centrato.

// MARK: - Layout comune (icona + titolo + descrizione + extra opzionale)

struct EmptyStateLayout<Icon: View, Extra: View>: View {
    let icon: Icon
    let title: String
    let description: String
    @ViewBuilder let extra: () -> Extra

    var body: some View {
        VStack(spacing: 15) {
            icon
            // .et (§CSS): Inter 800/ExtraBold 20px, colore #fff, letter-spacing -0.4px
            // → .tracking(-0.4) (px→pt 1:1, esatta — nessuna conversione, il freeze è già in pt).
            // line-height:1.15 → 23.0pt target: NESSUN .lineSpacing applicato, DICHIARATO non
            // dimenticato — misurato a fonte (tabella hhea di Inter-ExtraBold.ttf: ascender=1984
            // descender=-494 lineGap=0 unitsPerEm=2048 → fattore naturale 1.21 → 24.2pt @ 20px)
            // il leading NATURALE del font è già > del target CSS: non c'è spazio da aggiungere,
            // e SwiftUI non ha un modo pulito per sottrarre sotto il naturale. Registro resi: da
            // confermare a schermo (gate S3 via Q13, dopo S2d) se CoreText usa hhea o OS/2 typo
            // metrics — possono differire leggermente, non verificabile senza rendering reale.
            // Stesso pattern "Inter-ExtraBold" già in uso (HomeRootView.swift:165,
            // QStageKit.swift:92) — nessun terzo approccio introdotto.
            Text(title)
                .font(.custom("Inter-ExtraBold", size: 20))
                .tracking(-0.4)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            // .ed (§CSS): JetBrains Mono regular 11px, --text3, max-width 255,
            // letter-spacing 0.2px → .tracking(0.2) (px→pt 1:1, esatta).
            // line-height:1.6 → 17.6pt target: lineSpacing = target − naturale. Naturale
            // misurato a fonte (tabella hhea di JetBrainsMono-Regular.ttf: ascender=1020
            // descender=-300 lineGap=0 unitsPerEm=1000 → fattore 1.32 → 14.52pt @ 11px).
            // lineSpacing = 17.6 − 14.52 = 3.08 — APPROSSIMAZIONE dichiarata (CoreText può
            // derivare il leading nativo da OS/2 invece che hhea; il valore è calcolato da
            // metrici reali, non inventato, ma non garantito pixel-esatto). Registro resi:
            // conferma a schermo, gate S3 via Q13, dopo S2d.
            Text(description)
                .font(.jbMono(.regular, size: 11))
                .tracking(0.2)
                .lineSpacing(3.08)
                .foregroundColor(QStageTheme.text3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 255)
            extra()
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Badge icona (.eic): 78×78, radius 22, inset highlight in cima

struct EmptyIconBadge<Background: View, Content: View>: View {
    let strokeColor: Color
    @ViewBuilder let background: () -> Background
    @ViewBuilder let content: () -> Content

    var body: some View {
        background()
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .frame(width: 78, height: 78)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1.5)
            )
            .overlay(
                // box-shadow:inset 0 1px 0 rgba(255,255,255,.05) (§CSS .eic) = riga 1px
                // SOLO sul bordo superiore interno. Stessa tecnica mask-su-strip-2pt già
                // usata in RoomSwitchBar.swift (FIX 3) per lo stesso tipo di inner-shadow —
                // NON ancora verificata a schermo nemmeno lì (reso aperto pre-esistente).
                // GATE: S3 via Q13 (il badge .eic.dim di «No shows yet», Q-Stage, usa
                // EmptyIconBadge), dopo S2d — è un componente CONDIVISO, arriva a schermo a S3.
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                    .mask(VStack(spacing: 0) { Rectangle().frame(height: 2); Spacer(minLength: 0) })
            )
            .overlay(content())
    }
}

// MARK: - Icona Ⓔ .eic.dim (path SVG verbatim dal freeze, viewBox 24×24)

// Ⓔ .eic.dim (§markup): 3 linee orizzontali "M4 6h16M4 12h16M4 18h9", stroke 1.7.
// ⚠️ NON riusare per l'icona tab-bar «Shows» di Q13 (Q-Stage): glifo QUASI identico ma
// DIVERSO — path "…M4 18h10" (h10, non h9) e stroke 1.8 (non 1.7), verificato nel freeze.
// Chi la riusasse sbaglierebbe di 1 unità e nessuno se ne accorgerebbe (compila, gira,
// sembra giusto). Due Shape distinte per un motivo: quando S3 costruirà la tab-bar, glifo a sé.
struct NoShowsIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(4, 6));  path.addLine(to: pt(20, 6))
        path.move(to: pt(4, 12)); path.addLine(to: pt(20, 12))
        path.move(to: pt(4, 18)); path.addLine(to: pt(13, 18))
        return path
    }
}
