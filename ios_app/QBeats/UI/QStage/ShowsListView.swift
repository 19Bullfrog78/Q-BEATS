import SwiftUI
import os

// MARK: - ShowsListView — Q-Stage › Shows (frame ①) + sort sheet · S3
//
// Contratto vivo (freeze CD): DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0. Riferimenti per
// SELETTORE (R7, LIBRO v31): il freeze cresce, le righe slittano. Rimpiazza il placeholder Shows
// in QStageRootView. Ospita RoomSwitchBar (S1) ed EmptyStateKit (S2d) — entrambi a pt FISSI, quindi
// QUESTA vista usa pt FISSI (coerente col contenuto). Debito nav-root scaleFactor ereditato e
// ACCETTATO (BOX3 V94 §13 / LIBRO v33 sez.2, cross-team CD): non risolto qui, non aggravato.
// ⚠️ RESO MAI VISTO A SCHERMO (nessun Xcode in ambiente CC). «CI-verde ≠ chiuso».
//
// 🔴 PRIMO GATE DEVICE DI TUTTO §6. Chiude 3 dei 6 resi VISIVI (1 hit-area · 3 inner-shadow .eic ·
//    5 lineSpacing empty-state). Sonda del gate = os_log iniettato in RoomSwitchBar.onSwitch
//    (soluzione B, referee): la sonda vive nel CHIAMANTE (qui). ⚠️ STORIA: il 1° gate
//    (2026-07-14) è FALLITO sui tocchi [2]/[3] — hit-area inerte; RoomSwitchBar è stato
//    ristrutturato su mandato Mauro (bug FUNZIONALE del componente, non rottura del freeze
//    estetico; resa visiva invariata). Il RI-gate ripete TUTTI e 4 i tocchi da capo.
//    GATE DEVICE — 4 TOCCHI (Mauro, col dito):
//      [1] CENTRO di Q-LIVE            → il log DEVE apparire (sanity: se non appare nemmeno qui,
//          il problema è il log/Button, non l'hit-area)
//      [2] 8-10pt SOPRA il bordo Q-LIVE → il log DEVE apparire (espansione alta funziona)
//      [3] 8-10pt SOTTO il bordo Q-LIVE → il log DEVE apparire (espansione bassa funziona)
//      [4] BORDO DESTRO di Q-STAGE (pill attiva) → il log NON deve apparire (nessuna
//          sovrapposizione col sibling; RoomSwitchBar `pill()`: `if !isOn` non chiama onSwitch
//          su Q-Stage)
//    Testare Q-Live è sufficiente/rappresentativo: `.contentShape(Rectangle())` (RoomSwitchBar
//    `pill()`, DENTRO la label del Button — GATE-FIX 2026-07-14) ridefinisce l'area interattiva
//    indipendentemente dal contenuto della pill.
//    ⚠️ NOTA GATE (per Mauro, così non segnala un falso reso): la tab-bar in fondo NON assomiglia al
//       freeze — usa SF Symbols nativi (systemImage:"rectangle.stack"), NON i glifi SVG del design.
//       È NOTO, PRE-ESISTENTE (TabView di QStageRootView), NON è un reso di S3. Non segnalarlo.
//
// DECISIONI (ratificate referee/Mauro 13/07):
//  · SEARCH = FUNZIONALE ma LOCALE (@State qui). Q15 condivide SOLO l'ORDINE (nello store); la search
//    no — Q-Live ha la SUA search (SCALETTA:130). Il sort si applica al risultato GIÀ FILTRATO.
//  · CARD senza chevron, NON interattive: l'editing show è §8 (differito) → una freccia verso una
//    navigazione inesistente sarebbe una falsa promessa (CD-Q7 «niente bottoni morti» + CD-Q14). La
//    variante SENZA chevron è nel freeze (frame sort-sheet, .showrow senza <svg>).
//  · Trappola dei due glifi: MUTA a S3 (tab-bar nativa, mai costruito l'h10). Uso NoShowsIconShape (h9)
//    solo per il badge empty-state Q13.
//  · «+» create show OMESSO (CD-Q7): §8 differito, nessun path di scrittura cablato.
//
// ⚠️ 9° PUNTO (fuori contratto, default CC — flag per ratifica): se la search non trova nulla ma degli
//    show ESISTONO, il freeze non specifica lo stato (Q13 è per 0 show TOTALI). Default: hint minimale
//    «No shows match your search.», non un empty-state pieno.

private let showsLogger = Logger(subsystem: "com.bullfrog.qbeats", category: "ShowsListView")

struct ShowsListView: View {
    let onExit: () -> Void
    /// Switch di stanza verso Q-Live: closure DISTINTA da onExit (RoomSwitchBar.onSwitch).
    /// Iniettata da AppRootView attraverso QStageRootView (`screen` resta private, E2).
    let onSwitchToLive: () -> Void
    @ObservedObject private var store = QBeatsStore.shared

    // ⚠️ LOCALE (Q15: solo l'ordine è condiviso; la search NO). Vive qui, non nello store.
    @State private var searchText = ""
    @State private var showSortSheet = false

    // Lista visibile = filtrata (search locale) POI ordinata (stato condiviso nello store).
    private var visibleShows: [Setlist] {
        let filtered = searchText.isEmpty
            ? store.setlists
            : store.setlists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        return store.sortedSetlists(filtered)
    }

    // .sortbtn.active (§CSS): ambra quando l'ordine ≠ default (Name A–Z Ascending).
    private var isSortNonDefault: Bool {
        store.showsSortKey != .name || !store.showsSortAscending
    }

    // NIENTE NavigationStack: S3 non ha destinazioni di navigazione (card non tappabili, editing = §8
    // differito). La Home è gestita da RoomSwitchBar.onHome→onExit (commutazione schermata in AppRootView),
    // non da push. La tab-bar/safe-area vengono dal TabView di QStageRootView. Nessun layer di nav inutile.
    var body: some View {
        ZStack {
            QStageTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                RoomSwitchBar(
                    active: .qStage,
                    onHome: onExit,
                    variant: .full,
                    onSwitch: {
                        showsLogger.notice("[NAV] Q-Stage → Q-Live (RoomSwitchBar)")
                        onSwitchToLive()
                    }
                )

                scrhead

                if !store.setlists.isEmpty {
                    searchRow
                }

                content
            }

            if showSortSheet {
                sortSheetOverlay
            }
        }
    }

    // MARK: - Header (.scrhead §CSS)

    private var scrhead: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Shows")
                .font(.custom("Inter-ExtraBold", size: 29))
                .tracking(-0.6)
                .foregroundColor(.white)
            Spacer(minLength: 0)
            Text(showCountLabel)
                .font(.jbMono(.regular, size: 11))
                .tracking(0.4)
                .foregroundColor(QStageTheme.text2)
        }
        .padding(.top, 8)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    // .cnt (§CSS) = conteggio TOTALE degli show (non del filtrato). Plurale Q12.
    private var showCountLabel: String {
        let n = store.setlists.count
        return n == 1 ? "1 show" : "\(n) shows"
    }

    // MARK: - Search row (.searchrow / .search / .sortbtn §CSS) — omessa nell'empty (punto 5)

    private var searchRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 9) {
                SearchIconShape()
                    .stroke(QStageTheme.text3,
                            style: StrokeStyle(lineWidth: 1.8 * 15 / 24, lineCap: .round, lineJoin: .round))
                    .frame(width: 15, height: 15)
                // Placeholder colorato --text3 (SwiftUI non stila il placeholder nativo): ZStack esplicito.
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("Search shows")
                            .font(.jbMono(.regular, size: 12))
                            .tracking(0.3)
                            .foregroundColor(QStageTheme.text3)
                    }
                    TextField("", text: $searchText)
                        .font(.jbMono(.regular, size: 12))
                        .foregroundColor(QStageTheme.text)
                        .tint(QStageTheme.blue)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(QStageTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(QStageTheme.line, lineWidth: 1)
            )

            Button {
                withAnimation(.easeOut(duration: 0.22)) { showSortSheet = true }
            } label: {
                SortButtonIconShape()
                    .stroke(isSortNonDefault ? QStageTheme.amber : QStageTheme.text2,
                            style: StrokeStyle(lineWidth: 1.6 * 18 / 24, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 18)
                    .frame(width: 40, height: 40)
                    .background(isSortNonDefault ? QStageTheme.amber.opacity(0.12) : QStageTheme.surface,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isSortNonDefault ? QStageTheme.amber.opacity(0.4) : QStageTheme.line,
                                          lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 12)
    }

    // MARK: - Corpo (lista / empty Q13 / no-match)

    @ViewBuilder
    private var content: some View {
        if store.setlists.isEmpty {
            emptyStateQ13
        } else if visibleShows.isEmpty {
            noMatchHint
        } else {
            showList
        }
    }

    private var showList: some View {
        ScrollView {
            // .list (§CSS): padding 0 16, gap 11.
            LazyVStack(spacing: 11) {
                ForEach(visibleShows) { show in
                    showCard(show)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)   // .list padding verticale 0 (§CSS); il bottom è inset di scroll
        }
    }

    // .showrow (§CSS): radius 15, padding 15/16, bg surface, bordo line, inset-top 1px .04.
    // NIENTE chevron / NIENTE tap (falsa-promessa: editing show = §8 differito).
    private func showCard(_ show: Setlist) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                // ⚠️ 10° PUNTO (copy CC, DA RATIFICARE DA CD): «Untitled show» = fallback per name vuoto.
                // Verificato a source: la CREAZIONE (§8, differita) dà sempre «New Show» e non c'è editor
                // di rename → per creazione NON può essere vuoto. MA l'IMPORT/restore
                // (QBeatsStore.addSetlist ← QBeatsBackupManager:233) NON valida il nome → un archivio
                // importato può portarne uno vuoto. Tenuto perché raggiungibile; la copy è dominio CD.
                Text(show.name.isEmpty ? "Untitled show" : show.name)
                    .font(.custom("Inter-SemiBold", size: 16))
                    .tracking(-0.2)
                    .foregroundColor(.white)
                Text(showMeta(show))
                    .font(.jbMono(.regular, size: 10.5))
                    .tracking(0.3)
                    .foregroundColor(QStageTheme.text2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(QStageTheme.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(QStageTheme.line, lineWidth: 1)
        )
        .overlay(
            // box-shadow:inset 0 1px 0 rgba(255,255,255,0.04) (§CSS .showrow) — riga 1px SOLO in cima,
            // stessa tecnica mask-su-strip-2pt di RoomSwitchBar FIX 3 / EmptyIconBadge.
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
                .mask(VStack(spacing: 0) { Rectangle().frame(height: 2); Spacer(minLength: 0) })
        )
    }

    // .mt (§CSS): «N songs» + « · M min» SOLO se la durata stimata dà minuti > 0 (a 0 sparisce anche il ·).
    private func showMeta(_ show: Setlist) -> String {
        let s = show.songIDs.count
        let songs = "\(s) \(s == 1 ? "song" : "songs")"
        let minutes = Int((store.estimatedDuration(for: show) / 60).rounded())
        guard minutes > 0 else { return songs }
        return "\(songs) · \(minutes) min"   // · = MIDDLE DOT U+00B7 (verbatim dal freeze)
    }

    // Empty-state Q13 (0 show TOTALI). RIUSA EmptyStateKit (badge .eic.dim h9); NESSUNA CTA.
    private var emptyStateQ13: some View {
        EmptyStateLayout(
            icon: EmptyIconBadge(strokeColor: Color.white.opacity(0.10)) {
                Color.white.opacity(0.03)
            } content: {
                NoShowsIconShape()
                    .stroke(QStageTheme.text3,
                            style: StrokeStyle(lineWidth: 1.7 * 34 / 24, lineCap: .round, lineJoin: .round))
                    .frame(width: 34, height: 34)
            },
            title: "No shows yet",
            description: "Shows line up your songs for a gig, in the order you'll play them."
        ) {
            EmptyView()
        }
    }

    // 9° punto (default CC, flag ratifica): show esistono ma la search non matcha nulla.
    private var noMatchHint: some View {
        VStack {
            Spacer()
            Text("No shows match your search.")
                .font(.jbMono(.regular, size: 11))
                .tracking(0.2)
                .foregroundColor(QStageTheme.text3)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sort sheet (Q11) — overlay custom (gradiente inline, non native .sheet)

    private var sortSheetOverlay: some View {
        ZStack(alignment: .bottom) {
            // .shdim (§CSS): rgba(4,6,16,0.6), tap fuori = chiudi.
            Color(red: 4 / 255, green: 6 / 255, blue: 16 / 255).opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.easeOut(duration: 0.22)) { showSortSheet = false } }

            sortSheet
                .transition(.move(edge: .bottom))
        }
    }

    private var sortSheet: some View {
        VStack(spacing: 0) {
            // .grab (§CSS): 38×4, radius 3, white .18, 15 sotto.
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 38, height: 4)
                .padding(.bottom, 15)

            // .sh-h (§CSS): solo il titolo (Q15: sottotitolo rimosso).
            HStack {
                Text("Sort shows")
                    .font(.custom("Inter-ExtraBold", size: 18))
                    .tracking(-0.3)
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)

            sortOptionRow(key: .name, name: "Name (A–Z)", detail: "Alphabetical · default")
            sortOptionRow(key: .date, name: "Concert date", detail: "Chronological")

            // .dirseg (§CSS)
            HStack(spacing: 4) {
                dirSegOption("Ascending", ascending: true)
                dirSegOption("Descending", ascending: false)
            }
            .padding(4)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(QStageTheme.line2, lineWidth: 1)
            )
            .padding(.top, 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(
            // GRADIENTE INLINE verbatim dal freeze (.sortsheet, @9994bc0) — NON un token DS (uso singolo).
            LinearGradient(colors: [Color(hex: "#171d3c"), Color(hex: "#0f1329")],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(TopRoundedRectangle(radius: 22))   // border-radius: 22 22 0 0
        .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: -18)   // box-shadow:0 -18px 40px (§CSS .sortsheet)
        .overlay(
            // border-top:1px var(--line2) (§CSS): solo bordo superiore.
            TopRoundedRectangle(radius: 22)
                .stroke(QStageTheme.line2, lineWidth: 1)
                .mask(VStack(spacing: 0) { Rectangle().frame(height: 2); Spacer(minLength: 0) })
        )
        .ignoresSafeArea(edges: .bottom)
    }

    // .opt-row (§CSS): icona + label(n/d) + check. .sel → bg ambra .07, radius 12, icona/check ambra.
    private func sortOptionRow(key: ShowsSortKey, name: String, detail: String) -> some View {
        let selected = store.showsSortKey == key
        return Button {
            store.showsSortKey = key
        } label: {
            HStack(spacing: 12) {
                sortIcon(for: key, selected: selected)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)      // – = EN DASH U+2013
                        .font(.custom("Inter-SemiBold", size: 15.5))
                        .tracking(-0.2)
                        .foregroundColor(.white)
                    Text(detail)    // · = MIDDLE DOT U+00B7
                        .font(.jbMono(.regular, size: 9.5))
                        .tracking(0.2)
                        .foregroundColor(QStageTheme.text2)
                }
                Spacer(minLength: 0)
                // .chk (§CSS): 22×22, cerchio; .sel → riempito ambra + spunta scura.
                ZStack {
                    Circle()
                        .fill(selected ? QStageTheme.amber : Color.clear)
                    Circle()
                        .strokeBorder(selected ? QStageTheme.amber : Color.white.opacity(0.2), lineWidth: 2)
                    if selected {
                        CheckmarkShape()
                            .stroke(Color(hex: "#11131a"),
                                    style: StrokeStyle(lineWidth: 3 * 12 / 24, lineCap: .round, lineJoin: .round))
                            .frame(width: 12, height: 12)
                    }
                }
                .frame(width: 22, height: 22)
            }
            .padding(.horizontal, 6)
            .frame(minHeight: 52)
            .background(selected ? QStageTheme.amber.opacity(0.07) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .bottom) {
                // .opt-row border-bottom 1px .05 (§CSS): assente su .sel e su :last-child (Concert date).
                if !selected && key == .name {
                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // .opt-row .oi (§CSS): text2, ambra quando .sel.
    @ViewBuilder
    private func sortIcon(for key: ShowsSortKey, selected: Bool) -> some View {
        let color = selected ? QStageTheme.amber : QStageTheme.text2
        switch key {
        case .name:
            SortAlphaIconShape()
                .stroke(color, style: StrokeStyle(lineWidth: 1.7 * 18 / 24, lineCap: .round, lineJoin: .round))
                .frame(width: 18, height: 18)
        case .date:
            // rect stroke 1.7 + linee interne stroke 1.6 (§markup) — due Shape per i due stroke-width.
            ZStack {
                CalendarFrameShape()
                    .stroke(color, style: StrokeStyle(lineWidth: 1.7 * 18 / 24, lineCap: .round, lineJoin: .round))
                CalendarLinesShape()
                    .stroke(color, style: StrokeStyle(lineWidth: 1.6 * 18 / 24, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 18, height: 18)
        }
    }

    // .dirseg .o (§CSS): text3; .o.on → white, bg blu .24, bordo blu .5.
    private func dirSegOption(_ label: String, ascending: Bool) -> some View {
        let on = store.showsSortAscending == ascending
        return Button {
            store.showsSortAscending = ascending
        } label: {
            Text(label)
                .font(.jbMono(.bold, size: 10))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundColor(on ? .white : QStageTheme.text3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(on ? QStageTheme.blue.opacity(0.24) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(on ? QStageTheme.blue.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Shapes (path SVG verbatim dal freeze, viewBox 24×24) — pattern RoomSwitchBar/EmptyStateKit

// .search magnifier (§markup): circle cx11 cy11 r7 + line M16.5 16.5 L21 21, stroke 1.8.
private struct SearchIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.addEllipse(in: CGRect(x: rect.minX + 4 * s, y: rect.minY + 4 * s, width: 14 * s, height: 14 * s)) // cx11 cy11 r7
        p.move(to: pt(16.5, 16.5)); p.addLine(to: pt(21, 21))
        return p
    }
}

// .sortbtn icon (§markup): M7 4v16 M7 20l-3-3 M7 4l3 3  M17 20V4 M17 4l3 3 M17 4l-3 3, stroke 1.6.
private struct SortButtonIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.move(to: pt(7, 4));  p.addLine(to: pt(7, 20))    // M7 4v16
        p.move(to: pt(7, 20)); p.addLine(to: pt(4, 17))    // l-3 -3
        p.move(to: pt(7, 4));  p.addLine(to: pt(10, 7))     // l3 3
        p.move(to: pt(17, 20)); p.addLine(to: pt(17, 4))   // M17 20V4
        p.move(to: pt(17, 4));  p.addLine(to: pt(20, 7))    // l3 3
        p.move(to: pt(17, 4));  p.addLine(to: pt(14, 7))    // l-3 3
        return p
    }
}

// Sort-sheet .oi «Name» (§markup): M4 7h9 M4 12h6 M4 17h4  M16 5v13 M16 18l3-3 M16 18l-3-3, stroke 1.7.
private struct SortAlphaIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.move(to: pt(4, 7));   p.addLine(to: pt(13, 7))    // M4 7h9
        p.move(to: pt(4, 12));  p.addLine(to: pt(10, 12))   // M4 12h6
        p.move(to: pt(4, 17));  p.addLine(to: pt(8, 17))    // M4 17h4
        p.move(to: pt(16, 5));  p.addLine(to: pt(16, 18))   // M16 5v13
        p.move(to: pt(16, 18)); p.addLine(to: pt(19, 15))   // l3 -3
        p.move(to: pt(16, 18)); p.addLine(to: pt(13, 15))   // l-3 -3
        return p
    }
}

// Sort-sheet .oi «Concert date» (§markup): rect x4 y5 w16 h16 rx3 (stroke 1.7) + linee M4 9h16 M8 3v4
// M16 3v4 (stroke 1.6). Due Shape distinte perché il freeze usa due stroke-width diversi.
private struct CalendarFrameShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        p.addRoundedRect(in: CGRect(x: rect.minX + 4 * s, y: rect.minY + 5 * s, width: 16 * s, height: 16 * s),
                         cornerSize: CGSize(width: 3 * s, height: 3 * s))
        return p
    }
}

private struct CalendarLinesShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.move(to: pt(4, 9));  p.addLine(to: pt(20, 9))     // M4 9h16
        p.move(to: pt(8, 3));  p.addLine(to: pt(8, 7))      // M8 3v4
        p.move(to: pt(16, 3)); p.addLine(to: pt(16, 7))     // M16 3v4
        return p
    }
}

// .chk spunta (§markup): M5 12l5 5 9-11, stroke 3 (colore #11131a scuro su ambra).
private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.move(to: pt(5, 12)); p.addLine(to: pt(10, 17)); p.addLine(to: pt(19, 6))
        return p
    }
}

// Rettangolo con SOLO i due angoli superiori arrotondati (.sortsheet border-radius: 22 22 0 0).
// iOS 16-safe (UnevenRoundedRectangle evitato per compatibilità).
private struct TopRoundedRectangle: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        p.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
