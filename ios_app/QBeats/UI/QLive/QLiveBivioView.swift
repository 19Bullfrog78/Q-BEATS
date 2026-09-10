import SwiftUI

// MARK: - QLiveBivioView — il BIVIO A TRE VIE del player fermo · ⟦A343⟧ (10/09/2026)
//
// Contratto: frame ① del foglio CD 30/08 — `DESIGN/QLive_Nav/2026-08-30_QLive-Player_IL-VELO-
// DICE-DA-DOVE__END-SHOW-sullo-scaffale-e-sei-decisioni-incise__390x844.html @
// 5ca0c5fd53f51cb32370fb2386ebc20c077c07a3` («01 — bivio a tre vie con END SHOW separato dallo
// scaffale full-bleed», :199-224; MISURE :341-355). Le citazioni `:N` qui sotto sono righe di
// quel foglio. Ratifica: LIBRO:383 (30/08, «dopo STOP la freccia apre il bivio a tre vie»).
//
// Questa vista e' MUTA: riceve stringhe gia' risolte e tre closure; non legge il motore ne' il
// runner — li legge la stanza, all'atto di agire (`QLiveRootView.leavePlayer()`), che e' anche
// l'unica a montarla, come overlay della pagina `.metronome`: il player fermo resta sotto.
// Ogni stringa e' nella forma in cui si RENDE (`.popk` e `.vrow` portano
// `text-transform:uppercase`, :79 e :116); ogni misura porta il suo selettore.
// ⚠️ La X sta in alto a DESTRA: `.popx{right:-12px;top:-12px}` (:78) e MISURE :345 «angolo
//    alto-destro». Il mandato A343 diceva «a sinistra»: vince il foglio (referto A343 §5a).
// ⚠️ Glifi: `EndShowGlyphShape` e `LinkWarnTriangleShape` esistono nel dettaglio ma sono
//    `private` (`QLiveShowDetailView.swift:792`, `:819`) e il dettaglio non si tocca (mandato):
//    copiati qui, stessa convenzione di `addArc` collaudata su device. Duplicato dichiarato.
// ⚠️ `line-height:1.1` di `.popnm` (:80) NON e' attuabile: SwiftUI aggiunge interlinea, non la
//    comprime — stessa ragione della 1.12 del dettaglio (A334). Si lascia l'interlinea naturale.
struct QLiveBivioView: View {
    /// `.popnm` (:80) — il nome della canzone, com'e'. Vuoto = riga nascosta.
    let songName: String
    /// `.popmt` (:81) — «sezione · BPM · tempo», gia' composta dalla stanza. Vuota = riga nascosta.
    let meta: String
    /// `.vrow.end em` (:122, :124) — la sottoriga ambra; `nil` = riga assente, END SHOW a 56.
    let endShowSubline: String?
    let onClose: () -> Void
    let onShowDetails: () -> Void
    let onEndShow: () -> Void

    var body: some View {
        GeometryReader { geo in
            // Lo header del player resta SCOPERTO: nel frame ① `.scrim` e `.pop` stanno dentro
            // `.pbody` (:74-77), SOTTO `.plhead` (:63). L'altezza dello header e' la STESSA
            // espressione di `LiveView.swift:155` (`geo.size.height * 0.08`): non un token nuovo.
            let headerH = geo.size.height * 0.08
            ZStack(alignment: .top) {
                // `.scrim` (:76): rgba(0,0,0,0.70), inset 0 nel corpo. MISURE :346: «Tap sullo
                // scrim = come la X, e CONSUMA il tap» — senza, chiudere il bivio farebbe
                // partire il metronomo davanti alla band (R1). Il gesto e' sullo scrim, che
                // copre il transport: il tocco non arriva sotto.
                Color.black.opacity(0.70)
                    .padding(.top, headerH)
                    .ignoresSafeArea(edges: .bottom)
                    .contentShape(Rectangle())
                    .onTapGesture { onClose() }
                panel
                    .padding(.horizontal, 18)          // `.pop` left/right 18 (:77, MISURE :344)
                    .padding(.top, headerH + 132)      // `.pop` top 132, dal corpo (:77, MISURE :344)
            }
        }
    }

    // MARK: - Pannello `.pop` (:77) — radius 22 · padding 20/17/17 · --qlive-surf · bordo 1px .13 · ombra 0 22 54 .62

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // `.popk` (:79): mono 9 · 800 · tracking 2.4 · --text2 (.55, :27) · UPPERCASE.
            // ⚠️ 800 → `.bold` (700): `Font+JBMono.swift:4-13` non registra ExtraBold e manda
            //    ogni altro peso su Regular; stessa approssimazione del dettaglio per i suoi 800.
            Text("SHOW STOPPED")
                .font(.jbMono(.bold, size: 9))
                .tracking(2.4)
                .foregroundColor(Color.white.opacity(0.55))
            // `.popnm` (:80): Inter 26 · 800 · tracking −0.5 · bianco · margin-top 7.
            // Font: l'idioma del titolo del dettaglio (`QLiveShowDetailView.swift:358`).
            if !songName.isEmpty {
                Text(songName)
                    .font(.custom("Inter-ExtraBold", size: 26))
                    .tracking(-0.5)
                    .foregroundColor(.white)
                    .padding(.top, 7)
            }
            // `.popmt` (:81): mono 11 · --text2r (.60, :27) · tracking 0.3 · margin-top 6.
            if !meta.isEmpty {
                Text(meta)
                    .font(.jbMono(.regular, size: 11))
                    .tracking(0.3)
                    .foregroundColor(Color.white.opacity(0.60))
                    .padding(.top, 6)
            }
            // `.popact` (:82): margin-top 17 · colonna · gap 9.
            VStack(spacing: 9) {
                showDetailsRow
                shelf
                endShowRow
            }
            .padding(.top, 17)
        }
        .padding(EdgeInsets(top: 20, leading: 17, bottom: 17, trailing: 17))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(QLiveTheme.surf, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.13), lineWidth: 1)
        )
        // `box-shadow: 0 22px 54px rgba(0,0,0,0.62)` → radius 54/2, y 22: l'idioma di
        // `QLiveShowDetailView.swift:703` (0 6px 20px → radius 10, y 6).
        .shadow(color: Color.black.opacity(0.62), radius: 27, x: 0, y: 22)
        // Un tocco a vuoto sul pannello non deve raggiungere lo scrim (che chiude).
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture {}
        // `.popx` (:78): 44×44 a cavallo dell'angolo alto-DESTRO, right −12 / top −12.
        .overlay(alignment: .topTrailing) {
            closeButton.offset(x: 12, y: -12)
        }
    }

    // MARK: - X `.popx` (:78) — 44×44 · radius 50% · #1e1e23 · bordo 1px .18 · ombra 0 4 14 .5 · icona :213 13×13

    private var closeButton: some View {
        Button(action: onClose) {
            ZStack {
                Circle().fill(Color(hex: "#1e1e23"))
                Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                // icona (:213): viewBox 14, «M1 1l12 12M13 1L1 13», tratto 1.7 round,
                // rgba(255,255,255,0.82), resa 13×13.
                BivioCloseXShape()
                    .stroke(Color.white.opacity(0.82),
                            style: StrokeStyle(lineWidth: 1.7 * 13 / 14, lineCap: .round))
                    .frame(width: 13, height: 13)
            }
            .frame(width: 44, height: 44)
            .shadow(color: Color.black.opacity(0.5), radius: 7, x: 0, y: 4)
            // Hit-area: il GESTO copre i 44 — il `.contentShape` sta DENTRO la label del Button
            // (lezione del gate device S3, `RoomSwitchBar.swift:152-164`).
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - SHOW DETAILS `.vrow.ret` (:116, :118) — 56 · radius 15 · gap 11 · padding 0/16 · mono 13.5 700 ls 2.2 UPPERCASE · gradiente 150° #e8571c→#c8360a · bianco · glow 0 6 20 rgba(212,63,0,.4) · inset 0 1 0 rgba(255,180,140,.3)

    private var showDetailsRow: some View {
        Button(action: onShowDetails) {
            HStack(spacing: 11) {
                // icona (:218): viewBox 24, «M4 6h16M4 12h16M4 18h10», tratto 2.2 round,
                // currentColor (= bianco), resa 16×16.
                BivioListGlyphShape()
                    .stroke(Color.white,
                            style: StrokeStyle(lineWidth: 2.2 * 16 / 24, lineCap: .round))
                    .frame(width: 16, height: 16)
                Text("SHOW DETAILS")
                    .font(.jbMono(.bold, size: 13.5))
                    .tracking(2.2)
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            // Gradiente, glow e inset-highlight: la STESSA resa del tasto grande del dettaglio
            // (`QLiveShowDetailView.swift:684-711`); l'approssimazione 150° → topLeading/
            // bottomTrailing e' quella gia' dichiarata li' (`:699-702`). `QStageTheme.orange`
            // e' `#d43f00` = rgba(212,63,0), il colore del glow.
            .background(
                LinearGradient(colors: [Color(hex: "#e8571c"), Color(hex: "#c8360a")],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .shadow(color: QStageTheme.orange.opacity(0.4), radius: 10, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(Color(hex: "#ffb48c").opacity(0.3), lineWidth: 1)
                    .mask(VStack(spacing: 0) { Rectangle().frame(height: 2); Spacer(minLength: 0) })
            )
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - MENSOLA `.gsep.shelf` (:125, :127) — 1px · rgba(255,255,255,0.13) · margin 11 −17

    /// Esce dal padding 17 del pannello e tocca i due bordi. Salto 41 = gap 9 + margin 11 +
    /// linea 1 + margin 11 + gap 9 (MISURE :348). Nessun token nuovo: 0.13 e' il bordo del
    /// pannello (annotazione :225).
    private var shelf: some View {
        Rectangle()
            .fill(Color.white.opacity(0.13))
            .frame(height: 1)
            .padding(.horizontal, -17)
            .padding(.vertical, 11)
    }

    // MARK: - END SHOW `.vrow.end` (:116, :119) — 64 con sottoriga, 56 senza (MISURE :350) · outline · bordo 1px rgba(255,59,48,.52) · testo #ff8a80 · sottoriga `.vrow.end em` (:122, :124) mono 10 600 ls 1.1 #ffd35a gap 5

    /// La stessa resa della voce END SHOW del dettaglio (`QLiveShowDetailView.swift:580-626`),
    /// che e' il freeze 27/08 `.vrow.end` verbatim: qui il selettore e' lo stesso.
    private var endShowRow: some View {
        Button(action: onEndShow) {
            HStack(spacing: 11) {
                // icona (:220): viewBox 24, porta con freccia in uscita, tratto 2, resa 15×15.
                BivioEndShowGlyphShape()
                    .stroke(Color(hex: "#ff8a80"),
                            style: StrokeStyle(lineWidth: 2 * 15 / 24, lineCap: .round, lineJoin: .round))
                    .frame(width: 15, height: 15)
                VStack(alignment: .leading, spacing: 3) {
                    Text("END SHOW")
                        .font(.jbMono(.bold, size: 13.5))
                        .tracking(2.2)
                        .foregroundColor(Color(hex: "#ff8a80"))
                    if let endShowSubline {
                        HStack(spacing: 5) {
                            // triangolo (:220): viewBox 12×11, tratto 1.4, reso 11×10.
                            BivioWarnTriangleShape()
                                .stroke(Color(hex: "#ffd35a"),
                                        style: StrokeStyle(lineWidth: 1.4 * 11 / 12, lineCap: .round, lineJoin: .round))
                                .frame(width: 11, height: 10)
                            Text(endShowSubline)
                                .font(.jbMono(.semibold, size: 10))
                                .tracking(1.1)
                                .foregroundColor(Color(hex: "#ffd35a"))
                                .lineLimit(2)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: endShowSubline == nil ? 56 : 64)
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(Color(hex: "#ff3b30").opacity(0.52), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glifi del frame ① — path SVG copiati dal foglio, convenzione `pt(x,y)` dei fratelli del dettaglio

// `.popx svg` (:213): viewBox 14, «M1 1l12 12M13 1L1 13».
private struct BivioCloseXShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 14
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(1, 1))
        path.addLine(to: pt(13, 13))
        path.move(to: pt(13, 1))
        path.addLine(to: pt(1, 13))
        return path
    }
}

// `.vrow.ret svg` (:218): viewBox 24, «M4 6h16M4 12h16M4 18h10».
private struct BivioListGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(4, 6));  path.addLine(to: pt(20, 6))
        path.move(to: pt(4, 12)); path.addLine(to: pt(20, 12))
        path.move(to: pt(4, 18)); path.addLine(to: pt(14, 18))
        return path
    }
}

// `.vrow.end svg` (:220): viewBox 24, «M15 4h3a2 2 0 012 2v12a2 2 0 01-2 2h-3» + «M10 8l-4 4 4 4M6 12h9».
// Copia di `QLiveShowDetailView.swift:792-814` (`EndShowGlyphShape`, `private` li'): i due
// raccordi r2 con `addArc`, `clockwise: false`, angoli crescenti nello spazio y-in-giu' —
// la convenzione collaudata su device.
private struct BivioEndShowGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(15, 4))
        path.addLine(to: pt(18, 4))
        path.addArc(center: pt(18, 6), radius: 2 * scale,
                    startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: pt(20, 18))
        path.addArc(center: pt(18, 18), radius: 2 * scale,
                    startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: pt(15, 20))
        path.move(to: pt(10, 8))
        path.addLine(to: pt(6, 12))
        path.addLine(to: pt(10, 16))
        path.move(to: pt(6, 12))
        path.addLine(to: pt(15, 12))
        return path
    }
}

// `.vrow.end em svg` (:220): viewBox 12×11, «M6 1l5 9H1z» + «M6 4.4v2». Copia di
// `QLiveShowDetailView.swift:819-832` (`LinkWarnTriangleShape`, `private` li'). ⚠️ La scala e'
// sul viewBox 12, non 24 come i fratelli.
private struct BivioWarnTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 12
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(6, 1))
        path.addLine(to: pt(11, 10))
        path.addLine(to: pt(1, 10))
        path.closeSubpath()
        path.move(to: pt(6, 4.4))
        path.addLine(to: pt(6, 6.4))
        return path
    }
}
