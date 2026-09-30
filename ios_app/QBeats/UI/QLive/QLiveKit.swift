import SwiftUI

// MARK: - Token strutturali Q-Live — Design System CD (§3, freeze "Cancello 1" b23dfc78)
// Q-LIVE = ambiente "sul palco" → neutro antracite #0e0e10 (resta inline nelle viste Live).
// I 3 token qui erano marcati [DS] nel freeze ma ASSENTI dal codice → promossi (§3, "Zero-hex-fuori-DS").
// Namespace SEPARATO da QStageTheme (kit di Q-Stage; QStageKit.swift:4-5 riserva #0e0e10 alla sola Q-Live).
// NB: gli swatch colore-TAG restano fuori dal DS (R1-pending) finché R1 non ratifica la palette — NON qui.
enum QLiveTheme {
    static let surf   = Color(hex: "#16161a")    // superficie card/pill Q-Live · --qlive-surf
    static let bd     = Color.white.opacity(0.06)// bordo strutturale Q-Live    · --qlive-bd
    static let pick   = Color(hex: "#1a1614")    // evidenza last-opened (cosmetica) · --qlive-pick
    // Q20 (congedo tastiera, 2026-07-26_QLive-Shows-Keyboard-Dismiss__Q20-RIEMISSIONE.html):
    // token propri di Q-Live, MAI QStageTheme.orangeTint — stanze separate, coincidenza di
    // valore permessa e attesa (LIBRO riga 2026-07-27, clausola 1 della palette).
    static let accent = Color(hex: "#ff8a5c")    // Q20 r.32 --live-l · uso r.104 .kbdone (Done)
    static let kbbar  = Color(hex: "#1c1c20")    // Q20 r.103 .kbtoolbar background
}

// MARK: - Scala di palco — P = 17, solo iPhone (BOX5 «SCALA DI PALCO», ratificata Mauro 11/09/2026, incisa A348)
// A355 — QUI VIVONO I TOKEN CHE IL VELO USA, E SOLO QUELLI, coi nomi che portano in
// BOX5: un posto solo. ⛔ Non è la scala intera: un token si aggiunge qui quando una
// vista lo usa (STAGE-SECONDARY, STAGE-BODY, STAGE-DATA, STAGE-TITLE non ci sono
// perché il velo non li usa). Grandezze in punti su base 390, pavimento P = 17.
// ⚠️ MARCATURA A360 (16/09/2026) — STAGE-SECONDARY è entrato (`Secondary`, sotto): lo usa
//    la riga 2 dello slot E del velo (lastra ⑧). Gli altri tre restano fuori, per la
//    stessa ragione di prima. I token del velo li usa ora anche la fascia del Follower
//    (`TransportView`, riga-regola in STAGE-CAPS): il posto resta uno.
// ⚠️ MARCATURA A386 · B2b (30/09/2026) — STAGE-BODY (`Body`) e STAGE-DATA (`Data`) sono entrati
//    col velo del Follower (foglio CD 2D-QUATER: la riga sotto la parola in testa, i nomi e i
//    numeri della scaletta), e con loro la parola in testa (`Word`, la grandezza di STAGE-NEXT
//    in Inter 900) e i numeri propri del Follower (`Follower`: colori, distanze, righe, fascia
//    DA SOLO, Stop a pressione). Il posto resta uno. STAGE-TITLE resta fuori.
// Fra apparecchi vale `dimensione = max(pavimento, base × scaleFactor)` (BOX5, riga
// «Fra device»): `scaled(_:_:)` qui sotto. Sull'iPad è la stessa legge provvisoria del
// resto della Vista LIVE — l'iPad si fa a parte (LIBRO, riga 2026-09-11 «L'iPAD SI FA
// A PARTE, DOPO L'iPHONE»).
enum QLiveStage {
    /// STAGE-CAPS — occhielli, gesto del velo, chrome della testata.
    /// 1,25 × 17 = 21,25 → 21 · JetBrains Mono 600 · spaziatura 1,5 · maiuscole · bianco 0,60.
    enum Caps {
        static let size: CGFloat = 21
        static let weight: Font.Weight = .semibold
        static let tracking: CGFloat = 1.5
        static let opacity: Double = 0.60
    }
    /// STAGE-HERO — nome di sezione in play, nome canzone sul velo.
    /// 4,00 × 17 = 68 · Inter 900 (`Inter-Black`) · spaziatura −1,6 · bianco pieno.
    enum Hero {
        static let size: CGFloat = 68
        static let fontName = "Inter-Black"
        static let tracking: CGFloat = -1.6
    }
    /// STAGE-NEXT — la sezione che viene dopo, pavimento del gigante.
    /// 2,60 × 17 = 44,2 → 44. Il velo ne usa solo la grandezza: è il pavimento sotto
    /// cui il nome non scende (regola del gigante, BOX5).
    enum Next {
        static let size: CGFloat = 44
    }
    /// STAGE-SECONDARY — sottoriga ambra, etichette di tasto in minuscolo, note.
    /// 1,00 × 17 = 17 · JetBrains Mono 500-700 · spaziatura 0,3 · bianco 0,60 (BOX5, tabella
    /// P = 17). A360: la riga 2 dello slot E del velo (lastra ⑧ `.vlink .c`: peso 500,
    /// minuscolo come è scritta). Il peso 500 è `JetBrainsMono-Medium`, già registrato
    /// (`Font+JBMono.swift`, `project.yml`).
    enum Secondary {
        static let size: CGFloat = 17
        static let weight: Font.Weight = .medium
        static let tracking: CGFloat = 0.3
        static let opacity: Double = 0.60
    }
    /// STAGE-BODY — B2b: la riga sotto la parola in testa e i nomi nella scaletta del Follower
    /// (foglio 2D-QUATER `.qb-or`, `.qb-r b`: `font:600 21px/1.25 Inter`, `letter-spacing:-.005em`
    /// = −0,105 a 21). 1,25 × 17 = 21,25 → 21 · Inter 600 (`Inter-SemiBold`) · spaziatura −0,1 ·
    /// bianco 0,82 (`--t82`).
    enum Body {
        static let size: CGFloat = 21
        static let fontName = "Inter-SemiBold"
        static let tracking: CGFloat = -0.1
        static let opacity: Double = 0.82
    }
    /// STAGE-DATA — B2b: il numero della riga nella scaletta (`.qb-r>i`: `font:500 21px`
    /// JetBrains Mono, `--dt:21px`, bianco 0,60, largo `1.6em`, allineato a destra).
    enum Data {
        static let size: CGFloat = 21
        static let weight: Font.Weight = .medium
        static let opacity: Double = 0.60
    }
    /// La parola in testa del velo del Follower — B2b (`.qb-ow`: `font:900 var(--nx)/1 Inter`,
    /// `--nx:44px`, `letter-spacing:-.0273em` = −1,2 a 44): la grandezza di STAGE-NEXT in
    /// Inter 900. Ambra («Out») o bianco («Join», «Ready», `.qb-ow.w`).
    enum Word {
        static let size: CGFloat = 44
        static let fontName = "Inter-Black"
        static let tracking: CGFloat = -1.2
    }
    /// Il velo: distanze e margine della lastra ① (foglio CD 11/09
    /// IL-FOLLOWER-NON-TOCCA-IL-TRASPORTO, `.vnm` margin-top 11 · `.vhint` margin-top 26),
    /// riportate al pavimento 17 con k = 17/13 = 1,308 (BOX5, «Le distanze crescono col
    /// pavimento»); margine 26 di LA-TABELLA-FINALE §③ (larghezza utile 390 − 2×26 = 338).
    enum Veil {
        static let k: CGFloat = 17.0 / 13.0
        /// A→B: 11 × k = 14,39 → 14.
        static let gapRelationToName: CGFloat = (11 * k).rounded()
        /// B→C: 26 × k = 34,01 → 34.
        static let gapNameToGesture: CGFloat = (26 * k).rounded()
        /// A360 — slot E della lastra ⑧ (`.vlink`): C→E `margin-top:26px` («lo stesso respiro
        /// di B→C») × k = 34,01 → 34; fra le due righe `gap:5px` × k = 6,54 → 7.
        /// B2b: lo stesso posto lo prende lo slot E del foglio 2D-QUATER (L1, `.qb-sg.ok.g2`,
        /// `--g2:34px`): la distanza coincide.
        static let gapGestureToStatus: CGFloat = (26 * k).rounded()
        static let gapStatusLines: CGFloat = (5 * k).rounded()
        /// A360 — l'ambra della riga 1 dello slot E (`.vlink .s`, `#f5b820`): già in uso
        /// (`LiveHeaderView` muto, `TransportView` lampo di KILL BASE). Nessun colore nuovo:
        /// solo un nome per un valore che c'era.
        static let statusAmber = Color(hex: "#f5b820")
        static let horizontalMargin: CGFloat = 26
        /// Pulsazione del nome, invariata (BOX5 «Overlay Standby»).
        static let pulsePeriod: Double = 2.2
        static let pulseOpacityLow: Double = 0.45
        static let pulseOpacityHigh: Double = 1.0
    }
    /// B2b — IL FOLLOWER CHE PERDE IL DIRETTORE: i numeri del foglio CD 2D-QUATER (26/09/2026,
    /// `DESIGN/QLive_Nav/2026-09-26_QLive-Player_2D-QUATER-FOLLOWER-FUORI-RIENTRA_390x844_1.html`
    /// e `_2.html`), citati per selettore CSS. Corpi con `scaled(_:_:)`; distanze e margini in
    /// punti; colori dai `:root` del foglio. Nessun numero nuovo fuori dal foglio, tranne dove
    /// il foglio non dice (dichiarato nel referto B2b: il tratteggio della proposta-ipotesi).
    enum Follower {
        // Colori (`:root`): `--amber`, `--amb2`, `--linkg`, `--red-l`, `--t82`.
        static let amber = Color(hex: "#f5b820")
        static let amberLight = Color(hex: "#ffd35a")
        static let linkGreen = Color(hex: "#00c96e")
        static let stopRed = Color(hex: "#ff8a80")
        /// `.qb-st` bordo `rgba(255,59,48,.75)`; riempimento `::before` `rgba(255,59,48,.35)`.
        static let stopBorder = Color(red: 1.0, green: 59.0 / 255.0, blue: 48.0 / 255.0).opacity(0.75)
        static let stopFill = Color(red: 1.0, green: 59.0 / 255.0, blue: 48.0 / 255.0).opacity(0.35)
        // La testa del velo FUORI (`.qb-ob{padding:20px var(--m) 0}`, `--m:22px`).
        static let headTop: CGFloat = 20
        static let sideMargin: CGFloat = 22
        /// `.qb-or{margin-top:10px}` · `.qb-or{gap:.45em}` · `.qb-or .qb-ic{margin-top:.08em}`.
        static let bodyTop: CGFloat = 10
        static let bodyIconGapEm: CGFloat = 0.45
        static let bodyIconTopEm: CGFloat = 0.08
        /// `.qb-ob .qb-sg{margin-top:14px}` · `.qb-sg em{margin-top:7px}` · `.qb-sg p{gap:.5em}` ·
        /// `.qb-sg p i{width:.5em;height:.5em}` (il pallino) · `.qb-sg.lis p i{border:2px}`.
        static let slotTop: CGFloat = 14
        static let slotDetailTop: CGFloat = 7
        static let slotGapEm: CGFloat = 0.5
        static let slotDotEm: CGFloat = 0.5
        static let slotDotRing: CGFloat = 2
        /// `.qb-ic{width:1.15em;height:1.15em;stroke-width:2}` su viewBox 24: il tratto è 2/24
        /// dell'altezza. Le icone sono alte 1,15 volte il corpo del testo accanto.
        static let iconEm: CGFloat = 1.15
        static let iconStrokeRatio: CGFloat = 2.0 / 24.0
        // L'intestazione della scaletta (`.qb-lh{margin:22px var(--m) 0;padding-bottom:10px;
        // border-bottom:1px solid rgba(255,255,255,.13)}`).
        static let listHeaderTop: CGFloat = 22
        static let listHeaderBottom: CGFloat = 10
        static let listHeaderRule = Color.white.opacity(0.13)
        // Le righe (`.qb-r{height:var(--rw);gap:14px;padding:0 var(--m);border-bottom:1px solid
        // rgba(255,255,255,.06)}`, `--rw:64px`; `.qb-r>i{width:1.6em}`; `.qb-r em{margin-top:5px}`).
        static let rowHeight: CGFloat = 64
        static let rowGap: CGFloat = 14
        static let rowRule = Color.white.opacity(0.06)
        static let rowNumberWidthEm: CGFloat = 1.6
        static let rowLineTop: CGFloat = 5
        // La riga evidenziata (`.qb-r.pr{min-height:calc(var(--rw) + 24px);margin:6px 10px;
        // padding:10px calc(var(--m) - 12px);border:2px solid var(--amber);border-radius:14px;
        // background:rgba(245,184,32,.1)}`; `.un{border-style:dashed;background:rgba(245,184,32,.05)}`;
        // `.ar{border-color:rgba(255,255,255,.82);background:rgba(255,255,255,.08)}`).
        static let proposedMinHeight: CGFloat = 88
        static let proposedMarginV: CGFloat = 6
        static let proposedMarginH: CGFloat = 10
        static let proposedPaddingV: CGFloat = 10
        static let proposedPaddingH: CGFloat = 10
        static let proposedBorder: CGFloat = 2
        static let proposedRadius: CGFloat = 14
        static let proposedFill = Color(hex: "#f5b820").opacity(0.10)
        static let guessFill = Color(hex: "#f5b820").opacity(0.05)
        /// Il tratteggio di `.un` (`border-style:dashed`): il foglio non fissa la lunghezza del
        /// tratto (la decide il browser). Scelta dichiarata: 6 pieno, 4 vuoto.
        static let guessDash: [CGFloat] = [6, 4]
        static let armedBorder = Color.white.opacity(0.82)
        static let armedFill = Color.white.opacity(0.08)
        // La fascia DA SOLO (`.qb-fa.so{background:rgba(245,184,32,.08);border-top:2px solid
        // rgba(245,184,32,.55)}`; `.qb-fa{gap:12px;padding:0 18px 24px}`; `.qb-fm em{margin-top:4px}`).
        static let stripFill = Color(hex: "#f5b820").opacity(0.08)
        static let stripTopRule = Color(hex: "#f5b820").opacity(0.55)
        static let stripTopRuleWidth: CGFloat = 2
        static let stripSide: CGFloat = 18
        static let stripBottom: CGFloat = 24
        static let stripGap: CGFloat = 12
        static let stripLineTop: CGFloat = 4
        // Lo Stop a pressione e la cella di EMERG (`.qb-fb{gap:12px}`; `.qb-st{height:var(--bh);
        // border-radius:15px;border:2px;gap:11px}`; `.qb-st i{width:.8em;height:.8em;border-radius:2px}`;
        // `--bh:64px`; `.qb-em{width:var(--eb)}`, `--eb:98px`).
        static let stopHeight: CGFloat = 64
        static let stopRadius: CGFloat = 15
        static let stopBorderWidth: CGFloat = 2
        static let stopSquareEm: CGFloat = 0.8
        static let stopSquareRadius: CGFloat = 2
        static let stopGap: CGFloat = 11
        static let emergWidth: CGFloat = 98
        /// Lo Stop a pressione: 0,6 s (foglio L3, punto 2, approvato da Mauro il 25/09/2026).
        /// UNA costante, in UN posto: si fissa al collaudo.
        static let holdToStopSeconds: Double = 0.6
        /// Il riempimento si svuota se si rilascia prima: il tempo dello svuotamento.
        static let releaseEmptySeconds: Double = 0.15
    }

    /// `dimensione = max(pavimento, base × scaleFactor)` = token × max(1, scaleFactor).
    static func scaled(_ token: CGFloat, _ scaleFactor: CGFloat) -> CGFloat {
        token * max(1, scaleFactor)
    }
}
