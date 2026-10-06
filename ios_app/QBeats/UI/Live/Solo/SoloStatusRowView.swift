import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LA RIGA DI STATO: LINK, WI-FI, MIDI, LA STRISCIA, IL LAMPO ===
// Foglio (REV9, tabella delle misure, riga «Riga di stato»; REV18, punti 112 e 113 e facce g/h): 98-128, sempre
// presente, Inter 600 17 `--w66`; voci con pallino 10 e parola, 8 fra pallino e parola, 18 fra le voci; «Link» a
// sinistra solo a Link acceso dall'utente, Wi-Fi e MIDI a destra (`.sp{margin-left:auto}`). Facce
// (`StatusLightsDecision`, M1): verde `--lk` = collegato; pallino `--w18` = spento o mai visto; perso = icona
// barrata 20 (`.ic.s`) e parola, ambra `--amb`. Punto 112 con la decisione b) del LIBRO (2026-10-05): la striscia
// «Link lost» (`.ll`: ambra, testo `--bg` 700, raggio 15 a destra, dal bordo sinistro dello schermo a 18 prima di
// Wi-Fi, margine interno 18, icona `i-lo` 20) prende il posto di «Link»; Wi-Fi e MIDI restano a destra con le
// loro facce. Punto 113: la spia MIDI persa è la presa barrata `i-mo`. Punto 98 e schermo g (`.fl`): il lampo del
// pedale è lo spegnimento breve del pallino verde (circa 120 ms), quando il pedale fa fare davvero qualcosa
// (`MIDILampDecision`, dal segnale `midiActionLampSubject` di M1); su una spia grigia o persa non si vede.
// La riga occupa la larghezza intera della cornice (la striscia parte dal bordo): `sidePadding` è il 18 del foglio.
struct SoloStatusRowView: View {
    let lights: StatusLights
    let midiLampOff: Bool
    let scale: Double
    let sidePadding: CGFloat

    var body: some View {
        let font = Font.custom("Inter-SemiBold", size: CGFloat(QLiveSolo.Status.fontSize * scale))
        let gap = CGFloat(QLiveSolo.Status.gap * scale)
        HStack(spacing: gap) {
            if let strip = lights.strip {
                stripView(strip, font: font)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if let link = lights.link {
                    light(name: "Link", face: link, lostIcon: .linkLost, font: font, lampOff: false)
                        .padding(.leading, sidePadding)
                }
                Spacer(minLength: 0)
            }
            light(name: "Wi-Fi", face: lights.wifi, lostIcon: .wifiLost, font: font, lampOff: false)
            light(name: "MIDI", face: lights.midi, lostIcon: .midiLost, font: font, lampOff: midiLampOff)
                .padding(.trailing, sidePadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Una voce: pallino (verde, grigio, o spento per il lampo) oppure icona barrata ambra, e la parola.
    private func light(name: String, face: StatusLightFace, lostIcon: SoloIcon, font: Font, lampOff: Bool) -> some View {
        let led = CGFloat(QLiveSolo.Status.led * scale)
        let icon = CGFloat(QLiveSolo.Status.icon * scale)
        let off = QLiveSolo.whiteAlpha(QLiveSolo.Status.ledOffOpacity)
        return HStack(spacing: CGFloat(QLiveSolo.Status.ledGap * scale)) {
            switch face {
            case .connected:
                Circle().fill(lampOff ? off : QLiveSolo.link).frame(width: led, height: led)
            case .off:
                Circle().fill(off).frame(width: led, height: led)
            case .lost:
                SoloIconView(icon: lostIcon, size: icon, color: QLiveSolo.amber)
            }
            Text(name)
                .font(font)
                .foregroundColor(face == .lost ? QLiveSolo.amber : QLiveSolo.whiteAlpha(QLiveSolo.Status.opacity))
                .lineLimit(1)
        }
    }

    /// La striscia «Link lost» (`.ll`): ambra, testo `--bg` in Inter 700 17, icona `i-lo` 20, dal bordo sinistro,
    /// arrotondata a destra (raggio 15), 18 di margine interno.
    private func stripView(_ text: String, font: Font) -> some View {
        let icon = CGFloat(QLiveSolo.Status.icon * scale)
        return HStack(spacing: CGFloat(QLiveSolo.Status.ledGap * scale)) {
            SoloIconView(icon: .linkLost, size: icon, color: QLiveSolo.background)
            Text(text)
                .font(.custom("Inter-Bold", size: CGFloat(QLiveSolo.Status.fontSize * scale)))
                .foregroundColor(QLiveSolo.background)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.leading, CGFloat(QLiveSolo.Status.stripPadding * scale))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RightRoundedRect(radius: CGFloat(QLiveSolo.Status.stripRadius * scale)).fill(QLiveSolo.amber))
    }
}

/// Un rettangolo arrotondato solo a destra (`border-radius:0 15px 15px 0`).
struct RightRoundedRect: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(radius, rect.height / 2, rect.width)
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
