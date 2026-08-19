import SwiftUI

// MARK: - QLiveShowDetailView — Q-Live › Show Detail (frame ③, read-only) · ⟦S5a⟧
//
// Contratto vivo (freeze CD): DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0 — Frame 3
// "Show detail / read-only" (§1.2), Frame F "Empty show detail" (§1.5), Frame G "Show
// all-orphan" (§1.5). Riferimenti per SELETTORE (R7, LIBRO v31): il freeze cresce, le righe
// slittano.
// ⚠️ RESO MAI VISTO A SCHERMO (nessun Xcode in ambiente CC). «CI-verde ≠ chiuso».
//
// REGOLA DI COSTRUZIONE DI QUESTO ATOMO (rilavorazione A53): se un pezzo esiste già costruito
// e ratificato in questa stanza, SI RIUSA; costruirlo a mano è l'eccezione, e va dichiarata.
//   · `.seg-mini` della navbar → `RoomSwitchBar(variant: .segMini)`, come prescrive la scheda
//     dell'atomo (`HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:300`). Usato, MAI modificato.
//   · Ⓕ show vuoto → `ThisShowIsEmptyState` · Ⓖ tutto-orfano → `NoPlayableSongsEmptyState`
//     (`QLiveEmptyStates.swift`), finora vive solo nel loro PreviewProvider: questo atomo le
//     aggancia per la prima volta a una vista reale. Usate, MAI modificate.
//
// ⛔ ECCEZIONE DICHIARATA — il badge `.ro` è RICOSTRUITO qui, non riusato, e NON per scelta:
//    l'implementazione corretta esiste (`QLiveShowsView.swift:154-172` `roBadge`) ma è una
//    `private var` DENTRO quella struct, e la sua icona (`LockIconShape`, `:353`) è una
//    `private struct` file-scope: nessuna delle due è raggiungibile da un altro file, e
//    renderle internal è fuori dal perimetro autorizzato di questo atomo. Il rimedio durevole
//    è l'ESTRAZIONE in `UI/Components/`, esattamente come fu fatto in S2d per
//    `EmptyStateKit.swift` (stesso identico problema: «duplicarli avrebbe creato due copie
//    destinate a divergere → estratti qui, neutri», `EmptyStateKit.swift:6-8`). Serve un file
//    nuovo in `UI/Components/` = decisione del referee, non di questo atomo. Fino ad allora
//    queste ~20 righe sono una SECONDA COPIA della stessa specifica: se cambia il freeze,
//    cambiano in due posti.
//
// ⚠️ `.songlist` SCORRE (`overflow-y:auto`), NON `overflow:hidden` come il CSS del freeze:
// `LIBRO_MASTRO_QBEATS.md:342` (ratificato 01/08, tre settimane dopo il freeze) VINCE —
// `Setlist.songIDs` è `[UUID]` senza vincolo di cardinalità per costruzione, nessuna altezza
// fissa basta mai. Padding e gap del freeze restano invece in vigore (16pt / 2pt): LIBRO:342
// deroga al SOLO `overflow`.
//
// ⚠️ Caso misto (alcune canzoni orfane, alcune no): SKIP silenzioso delle orfane
// (`resolve(_:).missingIDs`), NESSUN conteggio a schermo — il conteggio «N unavailable» vive
// SOLO nel caso tutto-orfano (`metaText`), dove distingue «show vuoto» da «show con tutte le
// canzoni cancellate», due stati altrimenti identici a schermo. Il badge del misto resta in
// Q-Stage. Semantica di N = RISOLTO (decisione referee D3, A53): questa vista e la lista
// (`QLiveShowsView.showMeta`) contano entrambe i risolti.
//
// ⚠️ Tag-rail «R1-pending SOLO LAYOUT»: nessun modello dati tag esiste oggi (stesso stato di
// `isPick` in QLiveShowsView). Lo spazio del rail è riservato (`.crail`, larghezza fissa) ma
// reso SEMPRE trasparente — niente evidenza finta. Il chip `.stag` non ha equivalente onesto
// senza un modello: OMESSO, dichiarato qui.
// ⚠️ `.warn` / `.songrow.warned` (badge «⚠ FILE MISSING») OMESSI: DIFFERITI per mandato
// (scheda ⟦S5⟧, «OPEN … DIFFERITO»). Dichiarati qui perché il freeze del frame ③ li porta.
// ⚠️ `.viewtoggle` (Q-Live view / List view) OMESSO: precedente ratificato Q7
// (`LIBRO_MASTRO_QBEATS.md:272`) — zero canonici prescrivono il comportamento di «List view»,
// e due pillole di cui una accesa sono un interruttore, non un'etichetta. Rientra con l'atomo
// che lo definisce.
//
// ⛔ START INERTE — closure vuota. Eccezione consapevole e dichiarata al divieto CD-Q7 sui
// bottoni morti (LIBRO v31), a vita brevissima: il cablaggio verso `SetlistRunner` è ⟦S5b⟧ —
// stessa forma con cui ⟦S4R⟧ ha lasciato lo slot di `QLiveSession` senza mutatore APPOSTA
// (`QLiveSession.swift:12-15`). Lo stato VISIVO abilitato/disabilitato (token DS opacity 0.4)
// è invece cablato oggi, gattato sul RISOLTO-non-vuoto, non sul numero di righe.
//
// ⚠️ `scaleFactor` (D2) — APPLICATO, ma la copertura è PARZIALE PER COSTRUZIONE e va saputo.
// Applicato dove la regola arriva: `BOX5_QBEATS.md:68` scala «font/spacing ≥ 20pt», e in questo
// file l'unico valore ≥20 è il titolo `.dhead .nm` (29pt — A129, era 23pt). Tutto il resto è
// < 20pt e resta assoluto per `BOX5:458`, che esenta anche i 56pt dello Start (hit-target).
// ⛔ COSA NON PUÒ SEGUIRE, e non per mia scelta: i due componenti che questo atomo ha l'ordine
// di USARE-e-NON-MODIFICARE non ricevono `scaleFactor` perché non lo espongono —
// `RoomSwitchBar` (font 10,5pt — A129, era 9pt — tutti < 20: nessun effetto pratico) e soprattutto
// `EmptyStateLayout`, il cui titolo è `Inter-ExtraBold 20pt` (`EmptyStateKit.swift:47`), cioè
// ESATTAMENTE sulla soglia: nelle due empty-state Ⓕ/Ⓖ quel titolo NON scala. Darglielo
// significherebbe modificarli, che è vietato qui.
// ⚠️ Misura di contesto, non alibi: l'intera stanza Q-Live ha oggi ZERO `scaleFactor`
// (QLiveShowsView, QLiveEmptyStates, QLiveKit, MetroFAB, QLiveRootView, RoomSwitchBar,
// EmptyStateKit: 0 occorrenze ciascuno), mentre la Vista LIVE lo usa ovunque (LiveView 14,
// LiveHeaderView 10, FineSetlistView 4). Questo file è quindi il PRIMO della stanza a
// rispettare `BOX5:68`, e la lista fratello (`QLiveShowsView`) resta indietro: debito
// PRE-ESISTENTE, non introdotto qui, da aprire in BUGS al prossimo giro doc.
struct QLiveShowDetailView: View {
    let setlist: Setlist
    let onBack: () -> Void
    /// ⟦S5b⟧ — Start. Il runner si costruisce QUI: questa vista possiede già i due
    /// soli ingredienti che servono, `setlist` (:78) e `store` (:81), e
    /// `SetlistRunner.init(setlist:store:)` non chiede altro
    /// (`SetlistRunner.swift:61`). Il presentatore lo installa nello slot di
    /// stanza e naviga, nella stessa closure sincrona — ⟦S5b⟧ `Cond (a)`.
    ///
    /// ⚠️ DIVERGENZA DALLA LETTERA DELLA SCHEDA, DICHIARATA E NON RISOLTA DA ME.
    /// La scheda scrive «closure `() -> Void` … nella forma di `onBack`», e nello
    /// stesso elenco prescrive che il runner nasca IN QUESTO FILE, citandone le
    /// righe :78 e :81. Le due prescrizioni stanno insieme solo se la closure
    /// TRASPORTA il runner: una `() -> Void` obbligherebbe a costruirlo nella
    /// root, contro la riga che lo assegna qui. Forma adottata:
    /// `(SetlistRunner) -> Void`. Rilievo #1 del referto A125 — se il referee
    /// vuole la lettera, il cambio è meccanico e sta in un solo giro.
    let onStart: (SetlistRunner) -> Void

    @ObservedObject private var store = QBeatsStore.shared

    var body: some View {
        // `scaleFactor` — pattern ratificato `BOX5_QBEATS.md:47`, identico a `LiveView.swift:87`:
        // calcolato nel `GeometryReader` e PASSATO come parametro, mai catturato implicitamente.
        GeometryReader { geo in
            let scaleFactor: CGFloat = geo.size.width / 390
            // `resolve(_:)` calcolata UNA VOLTA per passata di render e passata ai sotto-blocchi:
            // è una scansione lineare su `songIDs`, non un valore cached.
            let resolved = store.resolve(setlist)
            VStack(spacing: 0) {
                navbar
                dhead(resolved, scaleFactor: scaleFactor)
                content(resolved)
                startfoot(resolved)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "#0e0e10").ignoresSafeArea())
    }

    // MARK: - Navbar (§CSS `.navbar`: height 50, padding 0 14)

    private var navbar: some View {
        HStack {
            backButton
            Spacer()
            // Componente prescritto dalla scheda dell'atomo: `.segMini[active:.qLive]` INERTE.
            // `onHome` non è usato dalla variante `.segMini` (il suo `body` rende il solo
            // `segment`, RoomSwitchBar.swift:65-66) ma è un parametro non-opzionale: passata
            // una closure vuota. `onSwitch` resta al suo default no-op ⇒ INERTE come richiesto.
            RoomSwitchBar(active: .qLive, onHome: {}, variant: .segMini)
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
    }

    // Back «Shows» — unica uscita dalla schermata. Hit-area ≥44pt (vincolo globale): il
    // padding verticale sta DENTRO la label del Button, così il GESTO lo copre — lezione del
    // gate device S3 fallito su `RoomSwitchBar` (`RoomSwitchBar.swift:152-164`: un
    // `.contentShape` fuori dal Button appartiene a una vista senza gesto e resta inerte).
    // Il chrome visivo non cambia: il padding aggiunto è trasparente. Navbar 50pt ⇒ i 44
    // ci stanno senza sfondare.
    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: 5) {
                BackChevronShape()
                    .stroke(QLiveTheme.accent,
                            style: StrokeStyle(lineWidth: 2 * 16 / 24, lineCap: .round, lineJoin: .round))
                    .frame(width: 16, height: 16)
                Text("Shows")
                    .font(.jbMono(.semibold, size: 12))
                    .tracking(0.4)
                    .foregroundColor(QLiveTheme.accent)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dhead (§CSS `.dhead` padding 6/18/10 · `.dhrow` gap 10 · `.mt` / `.mt.a`)

    private func dhead(_ resolved: (songs: [Song], missingIDs: [UUID]), scaleFactor: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 10) {
                // A129 — 23→29pt, ratificato nel freeze 06/08 (rev3-NORMATIVA, pannello ③,
                // tabella `.dhead .nm`): «pari a `.scrhead h1`: è un titolo di schermata come gli
                // altri». Non era una gerarchia voluta: era una taratura difensiva contro l'a-capo,
                // pagata in leggibilità sul dato più costoso da sbagliare della schermata — quale
                // show sto per far partire.
                // `.dhead .nm`: Inter 800 29pt, tracking −0.6 — CSS rev3 riga 153, verbatim:
                // `font-size:29px;font-weight:800;letter-spacing:-0.6px`. Il vecchio valore (23pt,
                // tracking −0.5, §CSS :248) veniva dal freeze SUPERATO 07/11: quella citazione è
                // oggi la colonna «Era» della stessa tabella, non più la fonte corrente.
                // 29 ≥ 20 ⇒ scala (`BOX5_QBEATS.md:68`), come già il 23. Resta l'UNICO valore di
                // questo file che la regola raggiunge: tutti gli altri font/spacing sono < 20pt e
                // restano assoluti (`BOX5:458`), e i 56pt dello Start sono hit-target, esenti per
                // la stessa riga.
                // ⛔ MAX 2 RIGHE, POI TRONCAMENTO IN CODA (freeze rev3 :153, `-webkit-line-clamp:2`):
                // `.lineLimit(1)` da solo avrebbe reso PEGGIORE il taglio dei nomi lunghi a 29pt —
                // servivano ENTRAMBE le cose. `.truncationMode(.tail)` esplicito per coerenza con
                // l'idioma già in uso nel corpus (`LiveHeaderView.swift:53-54`): `.tail` è comunque
                // il default SwiftUI, l'esplicito qui dichiara l'intento invece di ereditarlo.
                Text(setlist.name.isEmpty ? "Untitled show" : setlist.name)
                    .font(.custom("Inter-ExtraBold", size: 29 * scaleFactor))
                    .tracking(-0.6)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                readOnlyBadge
            }
            if let text = metaText(resolved) {
                Text(text)
                    .font(.jbMono(.regular, size: 11))
                    .tracking(0.3)
                    .foregroundColor(resolved.songs.isEmpty ? QStageTheme.amber : QStageTheme.text2)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // `.ro` (§CSS :192, verbatim): gap 5 · JetBrains Mono 700 9.5 · tracking 1 · UPPERCASE ·
    // colore --live-l · bg rgba(212,63,0,0.12) · bordo 1px rgba(212,63,0,0.32) · padding 4/8 ·
    // radius 7. ⛔ SECONDA COPIA della stessa specifica — vedi l'eccezione dichiarata in testa
    // al file: l'originale (`QLiveShowsView.swift:154-172`) è `private` e non raggiungibile.
    private var readOnlyBadge: some View {
        HStack(spacing: 5) {
            LockShape()
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

    // `.mt` (show con risolti) / `.mt.a` (tutto-orfano). Assente per setlist genuinamente
    // vuota: §markup Frame F porta un `.dhead` col solo `.dhrow`, nessuna riga meta.
    // D3 (A53): N = canzoni RISOLTE, non `songIDs` grezzi.
    private func metaText(_ resolved: (songs: [Song], missingIDs: [UUID])) -> String? {
        guard !setlist.songIDs.isEmpty else { return nil }
        if resolved.songs.isEmpty {
            return "0 playable · \(resolved.missingIDs.count) unavailable"
        }
        let count = resolved.songs.count
        let songs = "\(count) \(count == 1 ? "song" : "songs")"
        let minutes = Int((store.estimatedDuration(for: setlist) / 60).rounded())
        guard minutes > 0 else { return songs }
        return "\(songs) · \(minutes) min"   // · = MIDDLE DOT U+00B7 (verbatim dal freeze)
    }

    // MARK: - Corpo — songlist scorrevole, o una delle due empty-state già costruite.

    @ViewBuilder
    private func content(_ resolved: (songs: [Song], missingIDs: [UUID])) -> some View {
        if setlist.songIDs.isEmpty {
            ThisShowIsEmptyState()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if resolved.songs.isEmpty {
            NoPlayableSongsEmptyState()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            songList(resolved.songs)
        }
    }

    // `.songlist` (§CSS :252): padding 2px 16px 0, gap 2. `overflow` derogato da LIBRO:342
    // (scorre); padding e gap NO.
    private func songList(_ songs: [Song]) -> some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                    songRow(index: index + 1, song: song)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // `.songrow` (§CSS :253-259): gap 12, padding 12/6, border-bottom 1px white .05.
    // `.crail` → SEMPRE trasparente (vedi nota di testa). `.nm` è `flex:1` nel freeze: qui
    // `.frame(maxWidth:.infinity, alignment:.leading)`, NON uno `Spacer`, così il divario col
    // blocco `.met` resta esattamente il gap 12 anche quando il nome tronca.
    private func songRow(index: Int, song: Song) -> some View {
        let section = song.sections.first
        return HStack(spacing: 12) {
            Color.clear
                .frame(width: 4)
            Text("\(index)")
                .font(.jbMono(.bold, size: 12))
                .foregroundColor(QLiveTheme.accent)
                .frame(width: 18, alignment: .trailing)
            // `.songrow .nm` (§CSS :257): 16pt, weight 600, tracking −0.2, white .9 — e
            // font-family ereditata da `body{font-family:'Inter'}` (:129), che `.nm` non
            // sovrascrive mentre i suoi fratelli `.idx`/`.met`/`.stag`/`.warn` dichiarano
            // tutti mono esplicitamente. ⇒ Inter-SemiBold 16, identico al fratello
            // `QLiveShowsView.swift:288`. ⛔ NON `Font.system` (= SF Pro, vietato da
            // `DESIGN_SYSTEM_QBEATS.md:107`) e NON la regola `BOX5_QBEATS.md:162`
            // (JetBrains Mono 700 28pt), che vale per il nome-brano del TELEPROMPTER della
            // Vista LIVE, non per una riga di lista.
            Text(song.name)
                .font(.custom("Inter-SemiBold", size: 16))
                .tracking(-0.2)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let section {
                Text("\(Int(section.bpm.rounded())) · \(section.beatsPerBar)/\(section.beatUnit)")
                    .font(.jbMono(.regular, size: 12))
                    .tracking(0.3)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
        }
    }

    // MARK: - Startfoot (§CSS `.startfoot` :265 · `.startbtn` :270-273) — sempre in fondo,
    // presente in TUTTI e tre gli stati (Frame 3/F/G lo portano tutti).

    private func startfoot(_ resolved: (songs: [Song], missingIDs: [UUID])) -> some View {
        let isEnabled = !resolved.songs.isEmpty
        return Button {
            // ⟦S5b⟧ — ARMA, NON SUONA. Qui non si tocca l'audio: si costruisce il runner
            // con la setlist SCELTA e lo si consegna al presentatore.
            // ⛔ NON si chiama `startSetlist`: farebbe partire il click al PRIMO tocco,
            //    contro `BOX5_QBEATS.md:331` (QL-SHOWS-07 — «l'ingresso in uno show è
            //    SEMPRE arma + standby, qualunque sia il flag standby della prima
            //    canzone») e `BOX5_QBEATS.md:354` (§3 — «il click parte al secondo tap,
            //    schermo ovunque, o via MIDI»). Il secondo tap è già cablato e non si
            //    tocca: `LiveView.swift:134-137`.
            onStart(SetlistRunner(setlist: setlist, store: store))
        } label: {
            HStack(spacing: 10) {
                PlayGlyphShape()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                Text("START SHOW")
                    .font(.jbMono(.bold, size: 15))
                    .tracking(2.5)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                isEnabled
                    ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "#e8571c"), Color(hex: "#c8360a")],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color.white.opacity(0.05)),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(isEnabled ? Color.clear : QStageTheme.line, lineWidth: 1)
            )
            // `.startbtn.live` (§CSS :271) porta anche `box-shadow:0 6px 20px rgba(212,63,0,0.4)`
            // (glow) e `inset 0 1px 0 rgba(255,180,140,0.3)` (highlight in cima). Il glow è reso
            // con `.shadow`; l'inset-highlight con la tecnica mask-su-strip-2pt già in uso in
            // `RoomSwitchBar.swift:182-204` e `QLiveShowsView.swift:305-309`.
            // ⚠️ APPROSSIMAZIONE DICHIARATA: il freeze è `linear-gradient(150deg, …)`; 150°
            // CSS non ha conversione lineare esatta in `UnitPoint` SwiftUI —
            // `.topLeading → .bottomTrailing` (≈135°) è la stessa approssimazione già
            // dichiarata e in uso in `QLiveEmptyStates.swift:210-217`. Non è un valore sourced.
            .shadow(color: isEnabled ? QStageTheme.orange.opacity(0.4) : .clear, radius: 10, x: 0, y: 6)
            .overlay(
                Group {
                    if isEnabled {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .strokeBorder(Color(hex: "#ffb48c").opacity(0.3), lineWidth: 1)
                            .mask(VStack(spacing: 0) { Rectangle().frame(height: 2); Spacer(minLength: 0) })
                    }
                }
            )
            .opacity(isEnabled ? 1.0 : 0.4)   // token DS --disabled: 0.4
        }
        .buttonStyle(.plain)
        // ⟦S5b⟧ `Cond (d)` — IL TOCCO SI CHIUDE su show vuoto o tutto-orfano. Fino a
        // qui `isEnabled` pilotava SOLO l'aspetto — ombra (:323), bordo (:326-331),
        // opacità (:333) — e il bottone SEMBRAVA spento restando tappabile: `.disabled(`
        // rendeva 0 occorrenze in questo file, mentre il corpus lo usa in 6 file. Senza
        // questa riga un tocco su una scaletta orfana costruisce un runner a catalogo
        // VUOTO, `primeDisplay` esce al primo `guard` (`SetlistRunner.swift:272`) e il
        // player si monta BIANCO.
        // ⚠️ DA GUARDARE AL GATE DEVICE, e non ho modo di vederlo io: `.disabled` agisce
        //    anche sull'ambiente. Se lo stile `.plain` applicasse un proprio smorzamento
        //    allo stato disabilitato, lo Start spento risulterebbe più scuro dello 0,4
        //    prescritto (:333). Confronto: Frame F/G del freeze,
        //    `DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html`.
        .disabled(!isEnabled)
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 20)
        // §CSS `.startfoot` :265 — `linear-gradient(to top, var(--qlive-bg) 66%,
        // rgba(14,14,16,0))`. NON è decorazione: con `.songlist` che scorre (LIBRO:342) è ciò
        // che fa SFUMARE le righe sotto il footer; senza, le canzoni spuntano di netto da sotto
        // lo Start. CSS `to top` = asse dal basso verso l'alto ⇒ `.bottom → .top`; opaco da 0%
        // a 66%, poi dissolvenza ad alpha 0.
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#0e0e10"), location: 0.0),
                    .init(color: Color(hex: "#0e0e10"), location: 0.66),
                    .init(color: Color(hex: "#0e0e10").opacity(0), location: 1.0)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }
}

// MARK: - Glifi (path SVG verbatim dal freeze, viewBox 24×24)
// Pattern ratificato dal referee (`RoomSwitchBar.swift:71-73`): glifo del contratto = `Shape`
// col path verbatim, NON SF Symbol — un glifo diverso da CD, e senza dimensione fissa, si
// scalerebbe col Dynamic Type. Stroke-width in unità viewBox(24), reso a Npt ⇒ `w * N / 24`.

// `.back` chevron (§markup :439): "M15 5l-7 7 7 7", stroke 2, reso 16×16.
private struct BackChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(15, 5))
        path.addLine(to: pt(8, 12))
        path.addLine(to: pt(15, 19))
        return path
    }
}

// Lucchetto `.ro` (§markup :443): rect x5 y11 w14 h9 rx2 + arco "M8 11V8a4 4 0 018 0v3",
// stroke 1.9, reso 11×11. ⛔ Duplicato di `QLiveShowsView.swift:353` `LockIconShape`
// (`private`, non raggiungibile) — vedi l'eccezione dichiarata in testa al file.
private struct LockShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.minX + 5 * scale, y: rect.minY + 11 * scale,
                                       width: 14 * scale, height: 9 * scale),
                            cornerSize: CGSize(width: 2 * scale, height: 2 * scale))
        // Arco della staffa: da (8,11) sale a y=8, semicerchio r=4 fino a (16,8), poi giù a (16,11).
        path.move(to: pt(8, 11))
        path.addLine(to: pt(8, 8))
        path.addArc(center: pt(12, 8), radius: 4 * scale,
                    startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: pt(16, 11))
        return path
    }
}

// `.startbtn` play (§markup :458): "M7 5l12 7-12 7z", riempito, reso 16×16.
private struct PlayGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale) }
        var path = Path()
        path.move(to: pt(7, 5))
        path.addLine(to: pt(19, 12))
        path.addLine(to: pt(7, 19))
        path.closeSubpath()
        return path
    }
}
