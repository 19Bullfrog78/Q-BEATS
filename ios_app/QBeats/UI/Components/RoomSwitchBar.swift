import SwiftUI

// MARK: - RoomSwitchBar — Design System CD, freeze "Cancello 1" (sha256 b23dfc78…) — §1.4 FROZEN
// ⚠️ RESO MAI VISTO A SCHERMO (nessun Xcode in ambiente CC). CI-verde ≠ chiuso.
//    Chiusura visiva = gate device S3, con il freeze aperto a fianco.
// Componente presentazionale INERTE: highlight pilotato da `active` (no @State), zero logica di switch/navigazione.
// «+» create show è §8 DIFFERITO — FUORI PERIMETRO qui: nessun addmini/showsPlus/onAdd in questo atomo.
// Sorgente: `.roombar.center`/`.homebtn`/`.roomseg` (variant .full) e `.navbar .seg-mini` (variant .segMini).
// FIX 5 (referee, dichiarazione): il freeze ha DUE layout `.full` (spec CD verbatim §markup :937):
// Q-Stage›Shows = home sx · seg centrato · «+» a dx (§markup :834-837, `.roombar` piatta).
// Q-Live›Shows  = home sx · seg centrato · NESSUN «+» (§markup :864-866, `.roombar.center`).
// Qui è implementato SOLO il secondo (`.roombar.center`) e chiamato `.full` — senza il «+»
// (§8 differito) il layout Q-Stage non è nemmeno costruibile in questo atomo. Decisione presa
// da CC in questa sede: l'header Q-Stage con «+» resta un'apertura per CD, non ancora deciso
// come si presenti nel frattempo — segnalato a Mauro/referee per LIBRO, non scritto qui.
struct RoomSwitchBar: View {
    enum Room {
        case qStage, qLive
    }

    enum Variant {
        case full      // header pieno: home (fissato a sx) · seg centrato sull'intera barra — = layout Q-Live
        case segMini   // navbar detail: solo seg compatto, nessun home
    }

    let active: Room
    let onHome: () -> Void
    var variant: Variant = .full
    var onSwitch: () -> Void = {}

    var body: some View {
        switch variant {
        case .full:
            // .roombar.center: seg centrato sull'INTERA barra, home in `position:absolute;left:14px` (§CSS :668)
            // → ZStack (non HStack+Spacer): il centraggio del segment non dipende dalla presenza dell'home.
            ZStack {
                segment
                HStack {
                    homeButton
                    Spacer()
                }
            }
            // FIX 8 (referee): dichiarare la larghezza piena, NON ereditarla dallo Spacer +
            // inferenza sul genitore (S3/S4 non ancora scritti; senza un genitore che proponga
            // la larghezza piena, lo ZStack collasserebbe alla larghezza intrinseca e il
            // "seg centrato sull'intera barra" salterebbe).
            // ORDINE dei modificatori (SwiftUI wrappa dall'interno all'esterno, `.padding`
            // DEVE restare l'ULTIMO/esterno): `.frame(maxWidth:.infinity)` fa reclamare al
            // contenuto (W−28) proposti dal padding; `.padding(.horizontal,14)` riaggiunge 14
            // per lato → barra a larghezza piena W, contenuto inset 14/lato (= §CSS :665
            // `padding:0 14px`, border-box), home ancorato al bordo interno sx (HStack riempie
            // W−28, Spacer spinge), seg centrato dallo ZStack. Invertendo (padding interno,
            // frame esterno) il contenuto galleggerebbe centrato con 14 di minimo ma senza
            // ancoraggio a 14 → home NON al bordo. `.frame(height:54)` è asse indipendente.
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .padding(.horizontal, 14)
        case .segMini:
            segment
        }
    }

    // .homebtn: 34×34, radius 10, bg white .05, bordo white .09 (§CSS :667).
    // FIX 1 (referee): icona = path SVG verbatim (§markup :835), NON SF Symbol "house" —
    // glifo diverso da CD e senza dimensione fissa si sarebbe scalato col Dynamic Type
    // dentro il box fisso 34×34. Stroke-width SVG=1.7 in unità viewBox(24), reso a 18pt →
    // 1.7 × 18/24 = 1.275 sullo schermo (NON 1.7).
    private var homeButton: some View {
        Button(action: onHome) {
            HomeShape()
                .stroke(QStageTheme.text2, style: StrokeStyle(lineWidth: 1.7 * 18 / 24, lineCap: .round, lineJoin: .round))
                .frame(width: 18, height: 18)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // .roomseg / .navbar .seg-mini: container bg white .05, bordo white .10 (§CSS :670, :710)
    private var segment: some View {
        let containerPadding: CGFloat = variant == .full ? 4 : 3
        let containerRadius: CGFloat = variant == .full ? 12 : 10
        return HStack(spacing: 3) {
            pill(.qStage, label: "Q-Stage")
            pill(.qLive, label: "Q-Live")
        }
        .padding(containerPadding)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: containerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: containerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    // .roomseg .opt(.stage-on/.live-on) e .navbar .seg-mini .o(.live-on) (§CSS :672-674, :711-712)
    private func pill(_ room: Room, label: String) -> some View {
        let isOn = room == active
        let tint: Color = room == .qStage ? QStageTheme.blue : QStageTheme.orange
        let fontSize: CGFloat = variant == .full ? 10.5 : 9
        let hPad: CGFloat = variant == .full ? 12 : 9
        let vPad: CGFloat = variant == .full ? 7 : 5
        let radius: CGFloat = variant == .full ? 9 : 8
        let minHeight: CGFloat = variant == .full ? 34 : 30
        // FIX 4-bis (referee): hit-area 54pt su tutta l'altezza barra (§CSS :669, commento CD
        // verbatim), chrome visibile resta 34/30. Scoping: solo `.full` ha la claim sourced
        // (la nota :669 sta subito sopra `.roomseg`, la variante piena; `.navbar .seg-mini`
        // non ha un commento equivalente — 30pt, sotto i 44pt HIG: APERTO PER CD, non deciso
        // qui). Il primo tentativo (`.contentShape(Rectangle().inset(by: -N))`) insettava
        // TUTTI E 4 I LATI: le due pill (3pt di gap) finivano con hit-area sovrapposte di 17pt,
        // e nella sovrapposizione vince il sibling successivo → toccando il bordo destro di
        // "Q-Stage" si attivava "Q-Live". Bug funzionale, trovato dal referee. Fix: espandere
        // SOLO in verticale con l'idioma pad→contentShape→pad-negativo (la larghezza non è
        // mai toccata, zero sovrapposizione orizzontale).
        // ⚠️ hit-area NON VERIFICATA: il container ha `.clipShape`; se SwiftUI clippa anche
        // l'hit-test ereditato dall'antenato, l'espansione è INERTE e il bersaglio resta
        // 34pt (< 44 HIG) senza alcun segnale — compila, gira, sembra a posto. → GATE DEVICE
        // S3: toccare 8pt SOPRA il bordo visibile della pill deve commutare. Se non commuta,
        // il fix è una foglia di fico e va ristrutturato. Non deducibile dal codice: è runtime.
        let hitExpansion: CGFloat = variant == .full ? (54 - minHeight) / 2 : 0

        return Button(action: { if !isOn { onSwitch() } }) {
            Text(label)
                .font(.jbMono(.bold, size: fontSize))
                .tracking(variant == .full ? 1 : 0.8)
                .textCase(.uppercase)
                .foregroundColor(isOn ? .white : QStageTheme.text3)
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
                .frame(minHeight: minHeight)
                .background(isOn ? tint.opacity(0.24) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(isOn ? tint.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                .overlay(
                    // FIX 3 (referee): CSS `inset 0 1px 0 rgba(255,255,255,.06)` = riga 1px
                    // SOLO sul bordo SUPERIORE interno (offset-y 1px, blur 0), NON un anello
                    // sui 4 lati. SwiftUI non ha inner-shadow nativo: si traccia il bordo
                    // completo e si maschera a una fascia di 2pt in cima (il centro del
                    // tratto 1pt cade lì; la maschera esclude lati/basso). Solo variant .full
                    // attivo (assente su .seg-mini nel freeze, §CSS :673-674 vs :712).
                    // Rifinitura (referee): .strokeBorder invece di .stroke — il CSS globale è
                    // box-sizing:border-box (§CSS :618), bordo/inset stanno DENTRO; .stroke è
                    // centrato sul bordo e sborda 0.5pt fuori.
                    Group {
                        if variant == .full && isOn {
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                                .mask(
                                    VStack(spacing: 0) {
                                        Rectangle().frame(height: 2)
                                        Spacer(minLength: 0)
                                    }
                                )
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .padding(.vertical, hitExpansion)      // layout cresce a 54 (solo .full; 0 su .segMini)
        .contentShape(Rectangle())             // hit 54 in ALTEZZA, larghezza invariata
        .padding(.vertical, -hitExpansion)     // annulla → layout torna 34, container 42
    }
}

// Icona home, viewBox 24×24: roofline "M4 11l8-6 8 6" + pareti "M6 10v9h12v-9" (§markup :835)
private struct HomeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale)
        }
        var path = Path()
        path.move(to: pt(4, 11))
        path.addLine(to: pt(12, 5))
        path.addLine(to: pt(20, 11))
        path.move(to: pt(6, 10))
        path.addLine(to: pt(6, 19))
        path.addLine(to: pt(18, 19))
        path.addLine(to: pt(18, 10))
        return path
    }
}
