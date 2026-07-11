import SwiftUI

// MARK: - QLiveEmptyStates — S2, Design System CD
// Sorgente UNICA: FREEZE_QLIVE_NAV_DECODED_2026-07-11.txt
// (sha256 438fcaf3ba73fb1dc379368b29474ec9fd1ac171d50839efe763d140f9b568a4).
// ⚠️ RESO MAI VISTO A SCHERMO (nessun Xcode in ambiente CC). CI-verde ≠ chiuso.
//    Chiusura visiva = gate device S3, con il freeze aperto a fianco.
// 3 subview riusabili — SOLO il blocco `.empty` (§CSS :741-750). Zero header/navbar/
// statusbar/startfoot/routing: quelli sono altri atomi (S1/S2F già fatti; startfoot
// "Start show" + conteggio "N unavailable" del `.dhead` sono S5, non qui).
//
// Layout condiviso `.empty` (§CSS :742): flex:1, column, center, gap 15,
// padding 24px 34px, text-align:center → VStack(spacing:15) espanso a riempire lo
// spazio verticale disponibile nel genitore, contenuto centrato.

// MARK: - Layout comune (icona + titolo + descrizione + extra opzionale)

private struct EmptyStateLayout<Icon: View, Extra: View>: View {
    let icon: Icon
    let title: String
    let description: String
    @ViewBuilder let extra: () -> Extra

    var body: some View {
        VStack(spacing: 15) {
            icon
            // .et (§CSS :747): Inter 800/ExtraBold 20px, colore #fff, letter-spacing -0.4px
            // → .tracking(-0.4) (px→pt 1:1, esatta — nessuna conversione, il freeze è già in pt).
            // line-height:1.15 → 23.0pt target: NESSUN .lineSpacing applicato, DICHIARATO non
            // dimenticato — misurato a fonte (tabella hhea di Inter-ExtraBold.ttf: ascender=1984
            // descender=-494 lineGap=0 unitsPerEm=2048 → fattore naturale 1.21 → 24.2pt @ 20px)
            // il leading NATURALE del font è già > del target CSS: non c'è spazio da aggiungere,
            // e SwiftUI non ha un modo pulito per sottrarre sotto il naturale. Registro resi: da
            // confermare a schermo (gate S3) se CoreText usa hhea o OS/2 typo metrics — possono
            // differire leggermente, non verificabile senza rendering reale.
            // Stesso pattern "Inter-ExtraBold" già in uso (HomeRootView.swift:165,
            // QStageKit.swift:92) — nessun terzo approccio introdotto.
            Text(title)
                .font(.custom("Inter-ExtraBold", size: 20))
                .tracking(-0.4)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            // .ed (§CSS :748): JetBrains Mono regular 11px, --text3, max-width 255,
            // letter-spacing 0.2px → .tracking(0.2) (px→pt 1:1, esatta).
            // line-height:1.6 → 17.6pt target: lineSpacing = target − naturale. Naturale
            // misurato a fonte (tabella hhea di JetBrainsMono-Regular.ttf: ascender=1020
            // descender=-300 lineGap=0 unitsPerEm=1000 → fattore 1.32 → 14.52pt @ 11px).
            // lineSpacing = 17.6 − 14.52 = 3.08 — APPROSSIMAZIONE dichiarata (CoreText può
            // derivare il leading nativo da OS/2 invece che hhea; il valore è calcolato da
            // metrici reali, non inventato, ma non garantito pixel-esatto). Registro resi:
            // conferma a schermo, gate S3.
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

// MARK: - Badge icona (.eic, §CSS :743): 78×78, radius 22, inset highlight in cima

private struct EmptyIconBadge<Background: View, Content: View>: View {
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
                // box-shadow:inset 0 1px 0 rgba(255,255,255,.05) (§CSS :743) = riga 1px
                // SOLO sul bordo superiore interno. Stessa tecnica mask-su-strip-2pt già
                // usata in RoomSwitchBar.swift (FIX 3) per lo stesso tipo di inner-shadow —
                // NON ancora verificata a schermo nemmeno lì (reso aperto pre-esistente).
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                    .mask(VStack(spacing: 0) { Rectangle().frame(height: 2); Spacer(minLength: 0) })
            )
            .overlay(content())
    }
}

// MARK: - Icone (path SVG verbatim dal freeze, viewBox 24×24)

// Ⓔ .eic.dim (§markup :960): 3 linee orizzontali "M4 6h16M4 12h16M4 18h9", stroke 1.7.
private struct NoShowsIconShape: Shape {
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

// Ⓕ .eic.live (§markup :983): barra "M9 18V6l11-2v12" + 2 note (circle r=3, stesso
// stroke-width della barra → un solo Shape/stroke, come MetronomeBodyShape in MetroFAB).
private struct ShowEmptyIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(9, 18))
        path.addLine(to: pt(9, 6))
        path.addLine(to: pt(20, 4))
        path.addLine(to: pt(20, 16))
        // circle cx=6 cy=18 r=3
        path.addEllipse(in: CGRect(x: rect.minX + 3 * scale, y: rect.minY + 15 * scale, width: 6 * scale, height: 6 * scale))
        // circle cx=17 cy=16 r=3
        path.addEllipse(in: CGRect(x: rect.minX + 14 * scale, y: rect.minY + 13 * scale, width: 6 * scale, height: 6 * scale))
        return path
    }
}

// Ⓖ .eic.amber (§markup :1007): triangolo "M12 3l9 16H3z", stroke 1.7 — Shape separata
// dal punto esclamativo perché ha stroke-width DIVERSO (1.7 vs 1.8, vedi sotto).
private struct WarningTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(12, 3))
        path.addLine(to: pt(21, 19))
        path.addLine(to: pt(3, 19))
        path.closeSubpath()
        return path
    }
}

// Punto esclamativo dentro il triangolo: "M12 9v4.5M12 16.5v0.5", stroke 1.8 (§markup :1007).
// ⚠️ Il 2° sottopath (12,16.5)→(12,17) è un segmento di 0.5pt: con .lineCap(.round) SwiftUI
// dovrebbe renderlo come un disco pieno (raggio = lineWidth/2), coerente col "punto" SVG —
// caso limite (segmento quasi degenere), non verificato a schermo.
private struct WarningMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(12, 9));   path.addLine(to: pt(12, 13.5))
        path.move(to: pt(12, 16.5)); path.addLine(to: pt(12, 17))
        return path
    }
}

// Chevron sinistro della CTA (§markup :963): "M14 6l-6 6 6 6", stroke 2, box 13×13.
private struct ChevronLeftShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(14, 6))
        path.addLine(to: pt(8, 12))
        path.addLine(to: pt(14, 18))
        return path
    }
}

// MARK: - CTA "Go to Q-Stage" (.cta.ghost, §CSS :749-750) — closure non cablata (S6)

// CD-Q9 RISOLTA (11/07, CD + referee): bottone ATTIVO, non disabilitato. Omonimia
// sciolta: `.dead` ora significa SOLO stile disabilitato (opacity:var(--disabled),
// es. `.startbtn.dead`) — questa CTA non lo è. L'attivo low-emphasis si chiama
// `.cta.ghost`: stesso layout/padding/bordo di prima, testo+icona salgono da
// `--text3` a `--text2`. "closure non cablata" nel titolo sopra è SOLO lo stato di
// `onGoToQStage` (vedi REGISTRO RESI sotto) — non più una domanda sullo stile.
// ⚠️ REGISTRO RESI — VINCOLO ESPLICITO PER S6: `onGoToQStage` è `() -> Void = {}`, un
// no-op silenzioso. Se S4/S6 dimenticano di cablarlo, il risultato è un bottone che si
// preme (hit-area 44pt reale, feedback visivo del tap) e NON fa nulla — il compilatore
// non segnala nulla, perché il default è una closure sintatticamente valida. Non
// deducibile da qui: nessun test automatico distingue "cablato apposta a no-op" da
// "dimenticato". Va verificato a schermo/integrazione quando S6 collega il routing.
private struct GoToQStageCTA: View {
    var onGoToQStage: () -> Void = {}

    var body: some View {
        Button(action: onGoToQStage) {
            HStack(spacing: 8) {
                ChevronLeftShape()
                    .stroke(QStageTheme.text2, style: StrokeStyle(lineWidth: 2 * 13 / 24, lineCap: .round, lineJoin: .round))
                    .frame(width: 13, height: 13)
                Text("Go to Q-Stage")
                    .font(.jbMono(.bold, size: 12))
                    .tracking(0.8)
            }
            .foregroundColor(QStageTheme.text2)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(QStageTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ⓔ NO SHOWS TO PLAY (§markup :959-969, §CSS :742-750, :703-705)

// Empty-state della lista Shows quando non esiste alcuno show. CTA inerte + MetroFAB
// (riuso S2F, `UI/QLive/MetroFAB.swift`) come uscita al metronomo-libero.
// Cablaggio (onGoToQStage / onMetroTap) = S6, qui restano no-op di default.
// ⚠️ Il pinning "empty centrato sopra, MetroFAB in fondo con 30pt di margine" (§CSS :703
// `margin-top:auto; padding:0 0 30px`) FUNZIONA solo se il container che ospiterà questa
// view ha un'altezza esplicita/espansa (`.frame(maxHeight:.infinity)`), non deducibile
// da qui: è un vincolo per l'integrazione futura (routing = fuori scope in questo atomo).
struct NoShowsToPlayEmptyState: View {
    var onGoToQStage: () -> Void = {}
    var onMetroTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            EmptyStateLayout(
                icon: EmptyIconBadge(strokeColor: Color.white.opacity(0.10)) {
                    Color.white.opacity(0.03)
                } content: {
                    NoShowsIconShape()
                        .stroke(QStageTheme.text3, style: StrokeStyle(lineWidth: 1.7 * 34 / 24, lineCap: .round, lineJoin: .round))
                        .frame(width: 34, height: 34)
                },
                title: "No shows to play",
                description: "No shows built yet — create one in Q-Stage. Or just start the metronome below: no show needed."
            ) {
                // .cta margin-top:4px (§CSS :749) — EXTRA rispetto al gap:15 uniforme di
                // EmptyStateLayout (`:25`). Applicato al CALL SITE, non dentro il Button:
                // dentro falserebbe il padding interno (12→16) e il min-height 44.
                GoToQStageCTA(onGoToQStage: onGoToQStage)
                    .padding(.top, 4)
            }

            MetroFAB(onTap: onMetroTap)
                .padding(.bottom, 30)
        }
    }
}

// MARK: - Ⓕ THIS SHOW IS EMPTY (§markup :982-986)

// Empty-state del dettaglio show quando lo show non ha canzoni. Nessun CTA, nessuno
// startfoot: il bottone "Start show" disabled è S5 (fuori da questo atomo).
struct ThisShowIsEmptyState: View {
    var body: some View {
        EmptyStateLayout(
            icon: EmptyIconBadge(strokeColor: QStageTheme.orange.opacity(0.4)) {
                QStageTheme.orange.opacity(0.12)
            } content: {
                ShowEmptyIconShape()
                    .stroke(QStageTheme.orangeTint, style: StrokeStyle(lineWidth: 1.6 * 32 / 24, lineCap: .round, lineJoin: .round))
                    .frame(width: 32, height: 32)
            },
            title: "This show is empty",
            description: "No songs in this show. Add songs to it in Q-Stage before the gig."
        ) {
            EmptyView()
        }
    }
}

// MARK: - Ⓖ NO PLAYABLE SONGS (§markup :1006-1010)

// Empty-state del dettaglio show quando la lista è piena ma nessuna canzone è
// suonabile (tutte orfane/cancellate dal catalogo). Nessuno startfoot/conteggio
// "0 playable · N unavailable": quello è `.dhead .mt.a` (§CSS :716-717), S5.
// CD-Q10 RISOLTA (11/07, CD + referee): copy N-agnostica, niente ramo singolare/
// plurale (l'app non è localizzata) — supera il problema di pluralizzazione che la
// versione precedente (interpolazione di `unavailableCount`, ora rimosso) lasciava
// aperto per N=1. "tracks" rimosso dal testo (ambiguo vs Media/file audio). Il
// conteggio resta solo in `.dhead .mt.a` (S5), non qui.
struct NoPlayableSongsEmptyState: View {
    var body: some View {
        EmptyStateLayout(
            icon: EmptyIconBadge(strokeColor: QStageTheme.amber.opacity(0.3)) {
                // linear-gradient(150deg, rgba(245,184,32,.14), rgba(245,184,32,.04))
                // (§CSS :746). 150deg CSS non ha una conversione lineare esatta in
                // UnitPoint SwiftUI: .topLeading→.bottomTrailing è un'APPROSSIMAZIONE
                // dichiarata (≈135°), non un valore sourced.
                LinearGradient(
                    colors: [QStageTheme.amber.opacity(0.14), QStageTheme.amber.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            } content: {
                ZStack {
                    WarningTriangleShape()
                        .stroke(QStageTheme.amber, style: StrokeStyle(lineWidth: 1.7 * 34 / 24, lineCap: .round, lineJoin: .round))
                    WarningMarkShape()
                        .stroke(QStageTheme.amber, style: StrokeStyle(lineWidth: 1.8 * 34 / 24, lineCap: .round, lineJoin: .round))
                }
                .frame(width: 34, height: 34)
            },
            title: "No playable songs",
            description: "Every song in this show was deleted from the catalog. Restore them or rebuild the show in Q-Stage."
        ) {
            EmptyView()
        }
    }
}

// MARK: - Preview (iOS 16: PreviewProvider, niente macro #Preview)

struct QLiveEmptyStates_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NoShowsToPlayEmptyState()
                .previewDisplayName("E · No shows to play")
            ThisShowIsEmptyState()
                .previewDisplayName("F · This show is empty")
            NoPlayableSongsEmptyState()
                .previewDisplayName("G · No playable songs")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#0e0e10").ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}
