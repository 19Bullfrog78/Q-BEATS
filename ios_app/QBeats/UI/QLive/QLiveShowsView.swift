import SwiftUI

// MARK: - QLiveShowsView — Q-Live › Shows (frame ②, read-only) · S4a
//
// Contratto vivo (freeze CD): DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0, frame
// "Shows / Q-Live (read-only) [FROZEN]" + frame "No shows to play / Q-Live [FROZEN]".
// Riferimenti per SELETTORE (R7, LIBRO v31): il freeze cresce, le righe slittano.
// ⚠️ RESO MAI VISTO A SCHERMO (nessun Xcode in ambiente CC). «CI-verde ≠ chiuso».
//
// S4a = nato DEAD CODE (ratifica referee 18/07, specchio N1a): file NUOVO, allora non
// referenziato. Da S4b il flip della root è ESEGUITO: questa vista è la root di
// QLiveRootView, referenziata e a schermo. 🔴 Chiusura visiva = gate device S4b.
//
// DECISIONI (ratificate, con fonte):
//  · READ-ONLY: nessuna scrittura su QBeatsStore. Il badge .ro «Read-only» sostituisce
//    il conteggio .cnt di Q-Stage (§markup frame ②: scrhead ha .ro, NON .cnt).
//  · SORT EREDITATO da Q-Stage in sola lettura (Q15): NESSUN .sortbtn qui; l'ordine è
//    riletto da `store.sortedSetlists` (stato condiviso). La SEARCH invece è LOCALE
//    (@State qui), come in ShowsListView (Q15: solo l'ordine è condiviso).
//  · «+» create show OMESSO (CD-Q7, LIBRO v31): §8 differito, nessun bottone morto.
//  · RIGHE INERTI con chevron (§markup frame ②: .showrow CON <svg> chevron — a
//    differenza di Q-Stage/S3 che le ha senza): il tap-riga arriva a S5 (push detail).
//    Finestra S4b→S5 con chevron inerte = ratificata (referee: «device gate S4 conferma
//    no-crash su tap-riga nella finestra pre-S5», SCALETTA ⟦S4⟧).
//  · MetroFAB in coda SOLO PIAZZATO (S2F riusato; dest = S6 stub, SCALETTA ⟦S4⟧/⟦S6⟧).
//    Vincolo REGISTRO RESI sul no-op silenzioso: documentato in QLiveEmptyStates (CTA).
//  · NESSUNO stop audio agganciato alla navigazione (decisione CD 18/07: navigazione e
//    transport sono cose separate; lo stop è SOLO esplicito). Questa vista non tocca
//    AudioEngine in alcun modo.
//
// ⚠️ DEFAULT CC — FLAG PER RATIFICA (dichiarati anche in PIANO_S4b_REV_2026-07-18):
//  · .pick (last-opened, §CSS .qlive .showrow.pick): COSMETICO e ancora SENZA MODELLO —
//    nessun dato "ultimo aperto" esiste (verificato a fonte, grep store/modelli). Il ramo
//    di stile è implementato ma `isPick` resta false per OGNI riga: niente evidenza finta.
//  · Caret della search: il freeze non specifica il colore del cursore; specchio di
//    ShowsListView (accento stanza): qui orange Q-Live. Cosmetico.
//  · Search senza risultati (show esistenti, zero match): il freeze non copre lo stato;
//    specchio del 9° punto di ShowsListView («No shows match your search.»).
struct QLiveShowsView: View {
    /// Seam d'uscita verso Home (Cond A): a S4b sarà l'`onExit` di QLiveRootView.
    let onExit: () -> Void
    /// Switch di stanza verso Q-Stage: closure DISTINTA da onExit (RoomSwitchBar.onSwitch).
    /// A S4b sarà iniettata da AppRootView (`screen` resta private, E2).
    let onSwitchToStage: () -> Void

    @ObservedObject private var store = QBeatsStore.shared

    // LOCALE (Q15: solo l'ordine è condiviso; la search NO). Specchio ShowsListView.
    @State private var searchText = ""
    // Q20 (congedo tastiera): stato di focus del campo — pilota «Done», tap-fuori, Return.
    @FocusState private var searchFieldFocused: Bool

    // Lista visibile = filtrata (search locale) POI ordinata (ordine condiviso, sola lettura).
    private var visibleShows: [Setlist] {
        let filtered = searchText.isEmpty
            ? store.setlists
            : store.setlists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        return store.sortedSetlists(filtered)
    }

    var body: some View {
        ZStack {
            // --qlive-bg #0e0e10: resta inline nelle viste Q-Live (QLiveKit, nota di testa).
            Color(hex: "#0e0e10")
                .ignoresSafeArea()
                // Q20 §2, gesto perdonante: tap fuori dal campo congeda (non il canonico).
                .onTapGesture { searchFieldFocused = false }

            VStack(spacing: 0) {
                RoomSwitchBar(
                    active: .qLive,
                    onHome: onExit,
                    variant: .full,
                    onSwitch: onSwitchToStage
                )

                scrhead

                if !store.setlists.isEmpty {
                    searchRow
                }

                content
                    // Q20 §4/§6: spostato qui, non più su tutto il `body` — `.keyboard`
                    // è una SafeAreaRegions distinta da `.container` (Apple, doc
                    // SafeAreaRegions: case separati). Occlude MetroFAB/lista sotto la
                    // tastiera; NON cancella l'inset della barra sotto (§7 qui sotto),
                    // che contribuisce alla regione `.container`, non a `.keyboard`.
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        // Q20 §1: barra propria — non più `ToolbarItemGroup(.keyboard)`, scartato dal
        // referee (bug riprodotti su forum sviluppatori Apple, thread 709227 e 736040;
        // e comunque uno slot dentro una barra dipinta dal SISTEMA, non da noi).
        // `safeAreaInset` compone con la safe-area automatica da tastiera: mostrata
        // solo a fuoco, si posiziona sopra di essa senza calcoli manuali.
        .safeAreaInset(edge: .bottom) {
            if searchFieldFocused {
                keyboardDoneBar
            }
        }
    }

    // Q20 §1: gesto canonico — «Done» su barra propria pinnata sopra la tastiera,
    // sempre visibile, ≥44pt, arancio = accento Q-Live, unica azione della barra.
    private var keyboardDoneBar: some View {
        HStack {
            Spacer()
            Button {
                searchFieldFocused = false
            } label: {
                Text("Done")
                    .font(.jbMono(.bold, size: 15))
                    .tracking(0.4)
                    .foregroundColor(QLiveTheme.accent)
            }
            .frame(minWidth: 56, minHeight: 44, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        // .kbtoolbar (§CSS Q20): bg #1c1c20 + hairline superiore .13.
        .background(QLiveTheme.kbbar)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.13)).frame(height: 1)
        }
    }

    // MARK: - Header (.scrhead §CSS) — h1 + badge .ro (NON .cnt: Q-Live è read-only)

    private var scrhead: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Shows")
                .font(.custom("Inter-ExtraBold", size: 29))
                .tracking(-0.6)
                .foregroundColor(.white)
            Spacer(minLength: 0)
            roBadge
        }
        .padding(.top, 8)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    // .ro (§CSS): lucchetto 11×11 + «Read-only» JetBrains Mono 9.5/700, ls 1, UPPERCASE,
    // colore --live-l, bg live .12, bordo live .32, padding 4/8, radius 7, gap 5.
    private var roBadge: some View {
        HStack(spacing: 5) {
            LockIconShape()
                .stroke(QStageTheme.orangeTint,
                        style: StrokeStyle(lineWidth: 1.9 * 11 / 24, lineCap: .round, lineJoin: .round))
                .frame(width: 11, height: 11)
            Text("Read-only")
                .font(.jbMono(.bold, size: 9.5))
                .tracking(1)
                .textCase(.uppercase)
        }
        .foregroundColor(QStageTheme.orangeTint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(QStageTheme.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(QStageTheme.orange.opacity(0.32), lineWidth: 1)
        )
    }

    // MARK: - Search row (.searchrow / .search §CSS) — SENZA .sortbtn (Q15); omessa nell'empty

    private var searchRow: some View {
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
                    // ⚠️ default CC (flag in testa): caret = accento stanza, specchio ShowsListView.
                    .tint(QStageTheme.orange)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($searchFieldFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        // Q20 §6: Return = «Search» conferma il filtro E congeda, query conservata.
                        searchFieldFocused = false
                    }
            }
            // Q20 §5: a svuotare è SOLO la «×» — azione esplicita e separata, riporta la lista
            // completa. Non tocca il focus: il congedo resta un evento distinto.
            if !searchText.isEmpty {
                xclearButton
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        // .qlive .search (§CSS): bg --qlive-surf, bordo --qlive-bd.
        .background(QLiveTheme.surf, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(QLiveTheme.bd, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 12)
    }

    // .xclear (§CSS Q20): cerchio 20×20, bg white .22, icona 9×9 colore --qlive-bg (#0e0e10).
    // Posizionato a fine HStack: il TextField davanti si espande da sé (margin-left:auto).
    private var xclearButton: some View {
        Button {
            searchText = ""
        } label: {
            XClearIconShape()
                .stroke(Color(hex: "#0e0e10"),
                        style: StrokeStyle(lineWidth: 2 * 9 / 12, lineCap: .round))
                .frame(width: 9, height: 9)
        }
        .frame(width: 20, height: 20)
        .background(Color.white.opacity(0.22), in: Circle())
    }

    // MARK: - Corpo (lista / empty Ⓔ / no-match) + MetroFAB in coda (.metrofab margin-top:auto)

    @ViewBuilder
    private var content: some View {
        if store.setlists.isEmpty {
            // Frame Ⓔ (FROZEN): include già CTA «Go to Q-Stage» + MetroFAB in coda (S2).
            // EmptyStateLayout si espande da sé (maxHeight .infinity) → MetroFAB resta in fondo.
            NoShowsToPlayEmptyState(onGoToQStage: onSwitchToStage)
        } else {
            if visibleShows.isEmpty {
                noMatchHint
            } else {
                showList
            }
            // .metrofab (§CSS): margin-top:auto (qui: dopo lo scroll greedy), padding-bottom 30.
            MetroFAB()
                .padding(.bottom, 30)
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
            .padding(.bottom, 16)   // inset di scroll (come ShowsListView)
        }
        // Q20 §2, gesto perdonante: swipe giù interattivo. iOS 16.0+ confermato a fonte
        // (Apple Developer Documentation, scrolldismisseskeyboard(_:).json → introduced 16.0),
        // combacia col minimo del progetto: nessun margine, ma nessuna specifica cade.
        .scrollDismissesKeyboard(.interactively)
    }

    // .showrow (§CSS): radius 15, padding 15/16, bg --qlive-surf, bordo --qlive-bd,
    // inset-top 1px .04; variante .pick: bg --qlive-pick, bordo live .45. Chevron A DESTRA
    // (§markup frame ②) — riga INERTE fino a S5 (nessun Button/tap qui).
    private func showCard(_ show: Setlist) -> some View {
        // ⚠️ default CC (flag in testa): nessun modello last-opened → pick MAI attivo per ora.
        let isPick = false
        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                // «Untitled show» = fallback per name vuoto (specchio ShowsListView, 10° punto:
                // raggiungibile via import/restore che non valida il nome).
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
            // Chevron §markup frame ②: viewBox 8×14, stroke 1.8, reso a 8×14 pt (scala 1:1).
            // Colore: pick = live-l @ .85 · plain = white .3 (§markup, due varianti verbatim).
            RowChevronShape()
                .stroke(isPick ? QStageTheme.orangeTint.opacity(0.85) : Color.white.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                .frame(width: 8, height: 14)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(isPick ? QLiveTheme.pick : QLiveTheme.surf,
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(isPick ? QStageTheme.orange.opacity(0.45) : QLiveTheme.bd, lineWidth: 1)
        )
        .overlay(
            // box-shadow:inset 0 1px 0 rgba(255,255,255,0.04) (§CSS .showrow) — riga 1px SOLO
            // in cima, tecnica mask-su-strip-2pt (ShowsListView / RoomSwitchBar FIX 3).
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
                .mask(VStack(spacing: 0) { Rectangle().frame(height: 2); Spacer(minLength: 0) })
        )
    }

    // .mt (§CSS): «N songs» + « · M min» SOLO se la durata stimata dà minuti > 0
    // (§markup frame ②: la terza riga «Prove giovedì» è «5 songs» SENZA « · »).
    private func showMeta(_ show: Setlist) -> String {
        let s = show.songIDs.count
        let songs = "\(s) \(s == 1 ? "song" : "songs")"
        let minutes = Int((store.estimatedDuration(for: show) / 60).rounded())
        guard minutes > 0 else { return songs }
        return "\(songs) · \(minutes) min"   // · = MIDDLE DOT U+00B7 (verbatim dal freeze)
    }

    // 9° punto ShowsListView (default CC, specchiato — flag in testa): show esistenti,
    // search senza match. Il MetroFAB resta visibile (è l'uscita costante della stanza).
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
}

// MARK: - Icon Shapes (path SVG verbatim dal freeze) — pattern ShowsListView/EmptyStateKit

// .ro lucchetto (§markup): rect x5 y11 w14 h9 rx2 + arco M8 11V8a4 4 0 018 0v3, stroke
// unico 1.9, viewBox 24×24. Arco: semicerchio superiore centro (12,8) r4 — in coordinate
// SwiftUI (y verso il basso) 180°→360° con clockwise:false passa dall'alto (270°).
private struct LockIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.addRoundedRect(in: CGRect(x: rect.minX + 5 * s, y: rect.minY + 11 * s, width: 14 * s, height: 9 * s),
                         cornerSize: CGSize(width: 2 * s, height: 2 * s))
        p.move(to: pt(8, 11))
        p.addLine(to: pt(8, 8))
        p.addArc(center: pt(12, 8), radius: 4 * s,
                 startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        p.addLine(to: pt(16, 11))
        return p
    }
}

// .search magnifier (§markup): circle cx11 cy11 r7 + line M16.5 16.5 L21 21, stroke 1.8.
// (Copia privata: la gemella in ShowsListView è `private` di quel file — pattern per-file.)
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

// Chevron riga (§markup frame ②): viewBox 0 0 8 14, path M1 1l6 6-6 6 — scala su base 8.
private struct RowChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 8
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.move(to: pt(1, 1))
        p.addLine(to: pt(7, 7))
        p.addLine(to: pt(1, 13))
        return p
    }
}

// .xclear icona (§markup Q20): viewBox 0 0 12 12, due segmenti a X, path M2 2l8 8M10 2l-8 8.
private struct XClearIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 12
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var p = Path()
        p.move(to: pt(2, 2)); p.addLine(to: pt(10, 10))
        p.move(to: pt(10, 2)); p.addLine(to: pt(2, 10))
        return p
    }
}
