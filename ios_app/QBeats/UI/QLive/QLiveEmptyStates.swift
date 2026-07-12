import SwiftUI

// MARK: - QLiveEmptyStates — S2, Design System CD
// Sorgente: freeze QLive Nav di CD, contratto vivo DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html
// @ 9994bc0 (base 09/07 + emendamenti Q7-Q16). Il freeze È IN GIT dal commit 9994bc0
// (DESIGN/QLive_Nav/): la provenienza di questo file è ora verificabile a fonte — il vecchio
// «TD: freeze non versionato, solo su mirror E:» è CHIUSO.
// Riferimenti citati per SELETTORE, mai per riga (R7, LIBRO v31 / prescrizione CD CD-02): il
// freeze cresce a ogni taglio, le citazioni a riga slittano e falliscono in silenzio.
// ⚠️ RESO MAI VISTO A SCHERMO (nessun Xcode in ambiente CC). CI-verde ≠ chiuso.
//    🔴 Gate NON uniforme, distinguere per componente (verificato a fonte, R1 12/07):
//    · componenti CONDIVISI base (layout/badge/icona Ⓔ) → ESTRATTI in
//      `UI/Components/EmptyStateKit.swift` (S2d, move puro). Il loro gate (device S3, SOLO
//      via Q13 «No shows yet» di Q-Stage) è documentato LÌ, sui rispettivi simboli.
//    · subview INTERE Ⓔ/Ⓕ/Ⓖ (con CTA/MetroFAB, gradiente amber, punto esclamativo) → Ⓔ è di
//      Q-LIVE, Ⓕ/Ⓖ del dettaglio show → gate S4/S5, dopo il Nodo A. NON a S3. QUESTE restano qui.
//    Oggi le 3 subview vivono solo nel PreviewProvider in coda: nessuna è montata in una vista
//    reale finché S3 (Q13, che usa i componenti di EmptyStateKit) / S4 non le istanziano.
// Questo file dopo S2d: SOLO le 3 subview Ⓔ/Ⓕ/Ⓖ + `GoToQStageCTA` + le icone Ⓕ/Ⓖ + Preview.
// Zero header/navbar/statusbar/startfoot/routing: quelli sono altri atomi (S1/S2F già fatti;
// startfoot "Start show" + conteggio "N unavailable" del `.dhead` sono S5, non qui).

// MARK: - Icone (path SVG verbatim dal freeze, viewBox 24×24)

// Ⓕ .eic.live (§markup): barra "M9 18V6l11-2v12" + 2 note (circle r=3, stesso
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

// Ⓖ .eic.amber (§markup): triangolo "M12 3l9 16H3z", stroke 1.7 — Shape separata
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

// Punto esclamativo dentro il triangolo: "M12 9v4.5M12 16.5v0.5", stroke 1.8 (§markup .eic.amber).
// ⚠️ Il 2° sottopath (12,16.5)→(12,17) è un segmento di 0.5pt: con .lineCap(.round) SwiftUI
// dovrebbe renderlo come un disco pieno (raggio = lineWidth/2), coerente col "punto" SVG —
// caso limite (segmento quasi degenere), non verificato a schermo. GATE: S4/S5 — vive solo
// in Ⓖ NoPlayableSongs (dettaglio show), NON a schermo al gate S3.
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

// Chevron sinistro della CTA (§markup .cta.quiet): "M14 6l-6 6 6 6", stroke 2, box 13×13.
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

// MARK: - CTA "Go to Q-Stage" (.cta.quiet) — closure non cablata (S6)

// CD-Q9 RISOLTA (11/07, CD + referee): bottone ATTIVO, non disabilitato. Omonimia
// sciolta: `.dead` ora significa SOLO stile disabilitato (opacity:var(--disabled),
// es. `.startbtn.dead`) — questa CTA non lo è. L'attivo low-emphasis si chiama
// `.cta.quiet`: stesso layout/padding/bordo di prima, testo+icona salgono da
// `--text3` a `--text2`. "closure non cablata" nel titolo sopra è SOLO lo stato di
// `onGoToQStage` (vedi REGISTRO RESI sotto) — non più una domanda sullo stile.
// ⚠️ CORREZIONE S2c: S2b aveva scritto `.cta.ghost` — nome SBAGLIATO. Verificato
// contro il freeze emendato di CD (taglio 11/07, emendamenti Q7-Q10), selettore
// `.cta.quiet`. Vocabolario ratificato da CD: `.dead` = disabilitato (opacity) ·
// `.quiet` = nav secondaria ATTIVA, neutro solido (questa CTA) · `.ghost` = CTA di
// CREAZIONE attiva, blu tratteggiato ("Create in Songs", fuori da questo freeze).
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

// MARK: - Ⓔ NO SHOWS TO PLAY (§markup Frame E, §CSS `.empty`→`.cta.quiet` + `.metrofab`)

// Empty-state della lista Shows quando non esiste alcuno show. CTA inerte + MetroFAB
// (riuso S2F, `UI/QLive/MetroFAB.swift`) come uscita al metronomo-libero.
// Cablaggio (onGoToQStage / onMetroTap) = S6, qui restano no-op di default.
// ⚠️ Il pinning "empty centrato sopra, MetroFAB in fondo con 30pt di margine" (§CSS
// .metrofab `margin-top:auto; padding:0 0 30px`) FUNZIONA solo se il container che ospiterà questa
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
                // .cta margin-top:4px (§CSS) — EXTRA rispetto al gap:15 uniforme di
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

// MARK: - Ⓕ THIS SHOW IS EMPTY (§markup Frame F)

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

// MARK: - Ⓖ NO PLAYABLE SONGS (§markup Frame G)

// Empty-state del dettaglio show quando la lista è piena ma nessuna canzone è
// suonabile (tutte orfane/cancellate dal catalogo). Nessuno startfoot/conteggio
// "0 playable · N unavailable": quello è `.dhead .mt.a` (§CSS), S5.
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
                // (§CSS .eic.amber). 150deg CSS non ha una conversione lineare esatta in
                // UnitPoint SwiftUI: .topLeading→.bottomTrailing è un'APPROSSIMAZIONE
                // dichiarata (≈135°), non un valore sourced. GATE: S4/S5 — Ⓖ è del dettaglio
                // show, NON a schermo al gate S3.
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
