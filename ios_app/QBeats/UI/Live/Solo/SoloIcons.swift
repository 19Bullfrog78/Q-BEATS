import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LE ICONE DEI FOGLI DEL SOLO, COME `Path` ===
// Dai simboli SVG in testa alla Solo REV18 (`<symbol id="i-…" viewBox="0 0 24 24">`; `.ic{fill:none;
// stroke:currentColor;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round}`), sul modello di
// `FollowerIconShape` (B2b): ogni segmento cita il comando SVG che traduce, con le coordinate del viewBox.
// Gli archi SVG (`a r r 0 0 1 dx dy`: raggio e punto d'arrivo, verso orario) sono scritti col loro centro,
// calcolato dal raggio e dalla corda: in SwiftUI `addArc(… clockwise: false)` percorre l'angolo crescente,
// che sullo schermo (y verso il basso) è il verso orario dell'SVG (`sweep-flag` 1).
// Le icone: freccia (`i-bk`), altoparlante (`i-sp`), altoparlante barrato del muto acceso (`i-sm`, punto
// 110), Mixer (`i-mx`), List mode (`i-ls`), Kill (`i-kl`), Play (`i-pl`), Link perso (`i-lo`), Wi-Fi perso
// (`i-wo`), MIDI perso (`i-mo`, punto 113: la presa MIDI, un cerchio con cinque piedini e la tacca, barrata).
// SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — due icone in più: la mano di «Tap to start» (`i-tp`, tratto 1,7 su 24:
// lo dà il chiamante) e la freccia di «Back to Shows» (`M19 12H5M11 6l-6 6 6 6`, in `.ic`, tratto 2,2). I centri
// degli archi di `i-tp` sono calcolati dalla formula degli archi SVG (F.6.5) col raggio e la corda.
enum SoloIcon: Equatable {
    case back, speaker, speakerMuted, mixer, listMode, kill, play, linkLost, wifiLost, midiLost, tapHand, backArrow
}

/// I tratti (contorno) di un'icona.
struct SoloIconShape: Shape {
    let icon: SoloIcon

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let ox = rect.minX + (rect.width - 24 * s) / 2
        let oy = rect.minY + (rect.height - 24 * s) / 2
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
        func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: ox + x * s, y: oy + y * s, width: w * s, height: h * s)
        }
        // Un arco dal punto all'angolo `from` al punto all'angolo `to` (gradi; crescenti = orario sullo schermo).
        func arc(_ p: inout Path, cx: CGFloat, cy: CGFloat, r: CGFloat, from: Double, to: Double) {
            p.addArc(center: pt(cx, cy), radius: r * s,
                     startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false)
        }
        var p = Path()
        switch icon {
        case .back:
            // <path d="M15 5l-7 7 7 7"/>
            p.move(to: pt(15, 5))
            p.addLine(to: pt(8, 12))
            p.addLine(to: pt(15, 19))
        case .speaker, .speakerMuted:
            // <path d="M4 9.5v5h3.5L12 18V6L7.5 9.5z"/> — il corpo dell'altoparlante
            p.move(to: pt(4, 9.5))
            p.addLine(to: pt(4, 14.5))
            p.addLine(to: pt(7.5, 14.5))
            p.addLine(to: pt(12, 18))
            p.addLine(to: pt(12, 6))
            p.addLine(to: pt(7.5, 9.5))
            p.closeSubpath()
            if icon == .speaker {
                // <path d="M15.5 9a4 4 0 010 6M18 6.5a7.5 7.5 0 010 11"/> — le due onde, centri (15.5,12) e (18,12)
                p.move(to: pt(15.5, 9))
                arc(&p, cx: 15.5, cy: 12, r: 4, from: -90, to: 90)
                p.move(to: pt(18, 6.5))
                arc(&p, cx: 18, cy: 12, r: 7.5, from: -90, to: 90)
            } else {
                // <path d="M3 3l18 18"/> — la barra
                p.move(to: pt(3, 3))
                p.addLine(to: pt(21, 21))
            }
        case .mixer:
            // <path d="M6 3.5v6M6 14v6.5M12 3.5v1.5M12 9.5v11M18 3.5v8M18 16v4.5"/> — le tre aste
            p.move(to: pt(6, 3.5)); p.addLine(to: pt(6, 9.5))
            p.move(to: pt(6, 14)); p.addLine(to: pt(6, 20.5))
            p.move(to: pt(12, 3.5)); p.addLine(to: pt(12, 5))
            p.move(to: pt(12, 9.5)); p.addLine(to: pt(12, 20.5))
            p.move(to: pt(18, 3.5)); p.addLine(to: pt(18, 11.5))
            p.move(to: pt(18, 16)); p.addLine(to: pt(18, 20.5))
            // <circle cx="6" cy="11.8" r="2.3"/><circle cx="12" cy="7.2" r="2.3"/><circle cx="18" cy="13.8" r="2.3"/>
            p.addEllipse(in: box(6 - 2.3, 11.8 - 2.3, 4.6, 4.6))
            p.addEllipse(in: box(12 - 2.3, 7.2 - 2.3, 4.6, 4.6))
            p.addEllipse(in: box(18 - 2.3, 13.8 - 2.3, 4.6, 4.6))
        case .listMode:
            // <path d="M9.5 6H20M9.5 12H20M9.5 18H20M4.5 6h.01M4.5 12h.01M4.5 18h.01"/> — tre righe e tre punti
            for y: CGFloat in [6, 12, 18] {
                p.move(to: pt(9.5, y)); p.addLine(to: pt(20, y))
                p.move(to: pt(4.5, y)); p.addLine(to: pt(4.51, y))
            }
        case .kill:
            // <path d="M4 10v4M8 7v10M12 4v16M16 8v8M20 10.5v3"/> — le cinque barre
            p.move(to: pt(4, 10)); p.addLine(to: pt(4, 14))
            p.move(to: pt(8, 7)); p.addLine(to: pt(8, 17))
            p.move(to: pt(12, 4)); p.addLine(to: pt(12, 20))
            p.move(to: pt(16, 8)); p.addLine(to: pt(16, 16))
            p.move(to: pt(20, 10.5)); p.addLine(to: pt(20, 13.5))
        case .play:
            // <path d="M6 3.5L21 12 6 20.5z"/> — il triangolo (il tratto lo dà il chiamante: 2,4 su 24)
            p.move(to: pt(6, 3.5))
            p.addLine(to: pt(21, 12))
            p.addLine(to: pt(6, 20.5))
            p.closeSubpath()
        case .linkLost:
            // <path d="M9 17H7A5 5 0 017 7h1M15 7h2a5 5 0 014 8M8 12h3M3 3l18 18"/>
            // la maglia sinistra: da (7,17) a (7,7), raggio 5, centro (7,12), per il lato sinistro
            p.move(to: pt(9, 17)); p.addLine(to: pt(7, 17))
            arc(&p, cx: 7, cy: 12, r: 5, from: 90, to: 270)
            p.addLine(to: pt(8, 7))
            // la maglia destra: da (17,7) a (21,15), raggio 5, centro (17,12), per il lato destro
            p.move(to: pt(15, 7)); p.addLine(to: pt(17, 7))
            arc(&p, cx: 17, cy: 12, r: 5, from: -90, to: 36.87)
            // il tratto in mezzo e la barra
            p.move(to: pt(8, 12)); p.addLine(to: pt(11, 12))
            p.move(to: pt(3, 3)); p.addLine(to: pt(21, 21))
        case .wifiLost:
            // <path d="M12 19.5h.01M8.6 15.8a5 5 0 016.8 0M5.2 12.4a10 10 0 0113.6 0M2 9a14.5 14.5 0 0120 0M3 3l18 18"/>
            // il punto, i tre archi (centri calcolati: (12,19.47), (12,19.73), (12,19.5)) e la barra
            p.move(to: pt(12, 19.5)); p.addLine(to: pt(12.01, 19.5))
            p.move(to: pt(8.6, 15.8))
            arc(&p, cx: 12, cy: 19.466, r: 5, from: -132.84, to: -47.16)
            p.move(to: pt(5.2, 12.4))
            arc(&p, cx: 12, cy: 19.732, r: 10, from: -132.84, to: -47.16)
            p.move(to: pt(2, 9))
            arc(&p, cx: 12, cy: 19.5, r: 14.5, from: -133.6, to: -46.4)
            p.move(to: pt(3, 3)); p.addLine(to: pt(21, 21))
        case .midiLost:
            // <circle cx="12" cy="12" r="9"/><path d="M12 3v2.6M3 3l18 18"/> — il cerchio, la tacca, la barra;
            // i cinque piedini pieni stanno in `SoloIconFillShape`.
            p.addEllipse(in: box(3, 3, 18, 18))
            p.move(to: pt(12, 3)); p.addLine(to: pt(12, 5.6))
            p.move(to: pt(3, 3)); p.addLine(to: pt(21, 21))
        case .backArrow:
            // <path d="M19 12H5M11 6l-6 6 6 6"/> — l'asta e la punta
            p.move(to: pt(19, 12)); p.addLine(to: pt(5, 12))
            p.move(to: pt(11, 6)); p.addLine(to: pt(5, 12)); p.addLine(to: pt(11, 18))
        case .tapHand:
            // i-tp — le due onde del tocco: <path d="M6.6 6.2a4.2 4.2 0 0 1 8.4 0"/> centro (10.8, 6.2);
            // <path d="M8.6 6.6a2.2 2.2 0 0 1 4.4 0"/> centro (10.8, 6.6)
            p.move(to: pt(6.6, 6.2))
            arc(&p, cx: 10.8, cy: 6.2, r: 4.2, from: 180, to: 360)
            p.move(to: pt(8.6, 6.6))
            arc(&p, cx: 10.8, cy: 6.6, r: 2.2, from: 180, to: 360)
            // l'indice: <path d="M9.6 14V7.4a1.2 1.2 0 0 1 2.4 0V12"/> centro (10.8, 7.4)
            p.move(to: pt(9.6, 14)); p.addLine(to: pt(9.6, 7.4))
            arc(&p, cx: 10.8, cy: 7.4, r: 1.2, from: 180, to: 360)
            p.addLine(to: pt(12, 12))
            // il medio: <path d="M12 11.2a1.2 1.2 0 0 1 2.4 0V12.4"/> centro (13.2, 11.2)
            p.move(to: pt(12, 11.2))
            arc(&p, cx: 13.2, cy: 11.2, r: 1.2, from: 180, to: 360)
            p.addLine(to: pt(14.4, 12.4))
            // l'anulare: <path d="M14.4 11.8a1.2 1.2 0 0 1 2.4 0v.8"/> centro (15.6, 11.8)
            p.move(to: pt(14.4, 11.8))
            arc(&p, cx: 15.6, cy: 11.8, r: 1.2, from: 180, to: 360)
            p.addLine(to: pt(16.8, 12.6))
            // il mignolo, il palmo, il polso e il pollice:
            // <path d="M16.8 12.4a1.2 1.2 0 0 1 2.4 0v3.4a5.6 5.6 0 0 1-5.6 5.6h-1.2a5.2 5.2 0 0 1-4.1-2l-2.6-3.3a1.25 1.25 0 0 1 1.9-1.6l2 2.1"/>
            // centri: (18, 12.4) r 1.2; (13.6, 15.8) r 5.6 da 0° a 90°; (12.3988, 16.2) r 5.2 da 89.987° a 142.02°;
            // (6.7411, 15.4082) r 1.25 da 146.395° a 313.403°
            p.move(to: pt(16.8, 12.4))
            arc(&p, cx: 18, cy: 12.4, r: 1.2, from: 180, to: 360)
            p.addLine(to: pt(19.2, 15.8))
            arc(&p, cx: 13.6, cy: 15.8, r: 5.6, from: 0, to: 90)
            p.addLine(to: pt(12.4, 21.4))
            arc(&p, cx: 12.3988, cy: 16.2, r: 5.2, from: 89.987, to: 142.02)
            p.addLine(to: pt(5.7, 16.1))
            arc(&p, cx: 6.7411, cy: 15.4082, r: 1.25, from: 146.395, to: 313.403)
            p.addLine(to: pt(9.6, 16.6))
        }
        return p
    }
}

/// Le parti piene di un'icona (`fill="currentColor" stroke="none"`): solo i cinque piedini della presa MIDI.
struct SoloIconFillShape: Shape {
    let icon: SoloIcon

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard icon == .midiLost else { return p }
        let s = min(rect.width, rect.height) / 24
        let ox = rect.minX + (rect.width - 24 * s) / 2
        let oy = rect.minY + (rect.height - 24 * s) / 2
        // <circle cx="7" cy="12" r="1.25"/> <circle cx="8.46" cy="15.54" r="1.25"/> <circle cx="12" cy="17" r="1.25"/>
        // <circle cx="15.54" cy="15.54" r="1.25"/> <circle cx="17" cy="12" r="1.25"/>
        let pins: [(CGFloat, CGFloat)] = [(7, 12), (8.46, 15.54), (12, 17), (15.54, 15.54), (17, 12)]
        for (cx, cy) in pins {
            p.addEllipse(in: CGRect(x: ox + (cx - 1.25) * s, y: oy + (cy - 1.25) * s, width: 2.5 * s, height: 2.5 * s))
        }
        return p
    }
}

/// L'icona nel colore dato, alta `size`; il tratto è 2,2 su 24 della misura (`.ic`), salvo dove il foglio dice
/// altro (il Play: 2,4 su 24).
struct SoloIconView: View {
    let icon: SoloIcon
    let size: CGFloat
    let color: Color
    var strokeWidth: CGFloat? = nil

    var body: some View {
        let lineWidth = strokeWidth ?? size * CGFloat(QLiveSolo.iconStroke / QLiveSolo.iconViewBox)
        ZStack {
            SoloIconShape(icon: icon)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            SoloIconFillShape(icon: icon)
                .fill(color)
        }
        .frame(width: size, height: size)
    }
}
