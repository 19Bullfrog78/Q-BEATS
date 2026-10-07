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
        /// di B→C») × k = 34,01 → 34.
        /// B2b: lo stesso posto lo prende lo slot E del foglio 2D-QUATER (L1, `.qb-sg.ok.g2`,
        /// `--g2:34px`): la distanza coincide. B2b-BIS: `gapStatusLines` (fra le due righe
        /// della lastra ⑧) e `statusAmber` (l'ambra della riga 1) sono usciti con le righe:
        /// zero lettori (misura del referee a `272dc1f`). La marcatura in BOX5 (A360) va al
        /// giro dei canonici.
        static let gapGestureToStatus: CGFloat = (26 * k).rounded()
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

// MARK: - SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — I TOKEN DEL GIRO 1 DEL PLAYER DEL SOLO, IN UN POSTO SOLO
// Dalla Solo REV18 (`DESIGN/QLive_Nav/2026-10-05_QLive-Player_G1-SOLO-REV18_390x844_1.html`: `:root` e i selettori
// citati accanto a ogni valore; le misure di K in moto sono quelle della REV9, che la REV18 richiama). Corpi,
// diametri, spessori e distanze sono in punti sulla cornice 390 x 766 del foglio: le viste del Solo li moltiplicano
// per il fattore di `SoloPlayerGeometry` (decisione D4 del referee, 06/10/2026), MAI per `max(1, scaleFactor)`: per
// il player del Solo quella legge provvisoria è sostituita dalla cornice. Le spaziature dei caratteri sono in em
// (`letter-spacing` del foglio): la vista le moltiplica per il corpo già scalato. Il posto resta uno: un token si
// aggiunge qui quando una vista lo usa.
enum QLiveSolo {
    // I colori del foglio (`:root`).
    static let background = Color(hex: "#110f0e")      // --bg: il fondo, anche fuori dalla cornice
    static let surface = Color(hex: "#1f1b18")         // --sf: tonde e quadranti
    static let white = Color(hex: "#f5efe6")           // --w: il bianco caldo pieno
    /// Il bianco caldo con la sua opacità: `--w86` .86 · `--w72` .72 · `--w66` .66 · `--w18` .18 · `--w12` .12 · `--w07` .07.
    static func whiteAlpha(_ opacity: Double) -> Color { Color(hex: "#f5efe6").opacity(opacity) }
    static let orange = Color(hex: "#ff8a5c")          // --orl: la freccia della stanza
    static let accent = Color(hex: "#28cd41")          // --acc: l'accento del battito e il Play
    static let link = Color(hex: "#00c96e")            // --lk: il collegato
    static let red = Color(hex: "#ff3b30")             // --red: lo Stop
    static let amber = Color(hex: "#f5b820")           // --amb: il muto acceso, le spie perse, la striscia
    static let mixerPanel = Color(hex: "#16161a")      // .mxp: il pannello di oggi (QLiveTheme.surf)
    /// Le icone dei fogli: viewBox 24, tratto 2,2 (`.ic{stroke-width:2.2}`), estremi e giunzioni arrotondati.
    static let iconStroke: Double = 2.2
    static let iconViewBox: Double = 24

    /// Testata (`.p-hd{height:60px;gap:10px;padding:0 14px}`, `.p-rk` tonda 44 su `--sf` col filo chiaro in alto
    /// `inset 0 1px 0 rgba(255,255,255,.055)`, `.p-hn{font:700 24px Inter;letter-spacing:-.01em;color:var(--w86)}`);
    /// icona 24: freccia `--orl`, altoparlante `--w86`, muto acceso `--amb` (`.p-rk.mu`, punto 110).
    enum Header {
        static let round: Double = 44
        static let sidePadding: Double = 14
        static let gap: Double = 10
        static let icon: Double = 24
        static let titleSize: Double = 24
        static let titleTrackingEm: Double = -0.01
        static let titleOpacity: Double = 0.86
        static let iconOpacity: Double = 0.86
        static let roundHighlight: Double = 0.055
    }
    /// Riga di stato (`.p-rl{height:30px;gap:18px;font:600 17px Inter;color:var(--w66)}`, `.p-rl span{gap:8px}`,
    /// `.p-rl i` pallino 10 `--lk`, `.o` = `--w18`; problema: `.ic.s` 20 e parola `--amb`; striscia `.ll`: `--amb`,
    /// testo `--bg` 700, `border-radius:0 15px 15px 0`, margine interno 18). Il lampo del pedale (`.fl`, punto 98):
    /// spento per il 6 % di un giro di 2 s, cioè 120 ms.
    enum Status {
        static let fontSize: Double = 17
        static let opacity: Double = 0.66
        static let gap: Double = 18
        static let ledGap: Double = 8
        static let led: Double = 10
        static let ledOffOpacity: Double = 0.18
        static let icon: Double = 20
        static let stripRadius: Double = 15
        static let stripPadding: Double = 18
        static let lampOffSeconds: Double = 0.12
    }
    /// Le spie (`.lp i{background:var(--w07);box-shadow:inset 0 0 0 1.5px rgba(245,239,230,.1)}`; accesa `.a` =
    /// `--acc`, `.n` = `--w`). Ø e spazio: `BeatLightsLayout` (Models/).
    enum Lights {
        static let offFill: Double = 0.07
        static let offRing: Double = 1.5
        static let offRingOpacity: Double = 0.10
    }
    /// Battuta e tempo (`.p-bc b{font:700 26px/1 JetBrains Mono;letter-spacing:-.02em}`, `.p-bc b span{font:600 17px
    /// Inter;color:var(--w66);margin:0 7px}`).
    enum BarRow {
        static let numberSize: Double = 26
        static let numberTrackingEm: Double = -0.02
        static let wordSize: Double = 17
        static let wordOpacity: Double = 0.66
        static let wordGap: Double = 7
    }
    /// La barra delle battute (`.bm i{background:var(--w12)}`, `.d` = `rgba(245,239,230,.42)`, `.c` = `--w`).
    /// Spazio, segmento e raggio: `SoloBarMeterLayout` (Models/).
    enum BarMeter {
        static let doneOpacity: Double = 0.42
        static let otherOpacity: Double = 0.12
    }
    /// Il teleprompter (`.p-se b{font:800 42px/1.08 Inter;letter-spacing:-.035em}`, bianco pieno, centrato).
    enum Prompter {
        static let fontName = "Inter-ExtraBold"
        static let fontSize: Double = 42
        static let lineHeight: Double = 1.08
        static let trackingEm: Double = -0.035
    }
    /// Next (`.p-nx{height:60px;border-radius:16px;box-shadow:inset 0 0 0 1.5px var(--w12);gap:12px;padding:0 16px}`,
    /// `.p-nx span{font:600 19px Inter;color:var(--w66)}`, `.p-nx b{font:700 28px Inter;letter-spacing:-.015em;
    /// color:var(--w86)}`).
    enum Next {
        static let radius: Double = 16
        static let padding: Double = 16
        static let border: Double = 1.5
        static let borderOpacity: Double = 0.12
        static let gap: Double = 12
        static let labelSize: Double = 19
        static let labelOpacity: Double = 0.66
        static let valueSize: Double = 28
        static let valueTrackingEm: Double = -0.015
        static let valueOpacity: Double = 0.86
    }
    /// La barra della canzone (`.p-sp{height:10px;gap:4px}`, `.p-sp i{border-radius:5px;background:var(--w12)}`,
    /// `.d` = `rgba(245,239,230,.34)`, `u` = `rgba(245,239,230,.62)`).
    enum SongBar {
        static let gap: Double = 4
        static let radius: Double = 5
        static let doneOpacity: Double = 0.34
        static let progressOpacity: Double = 0.62
        static let otherOpacity: Double = 0.12
    }
    /// La console B (`.kB{gap:8px}` griglia 2 x 2 su 354 x 176: quadranti 173 x 84; `.q{background:var(--sf);
    /// border-radius:20px;gap:7px;font:700 17px Inter;color:var(--w72);box-shadow:inset 0 1px 0
    /// rgba(255,255,255,.055)}`, `.q.l{padding-right:64px}`, `.q.r{padding-left:64px}`, `.q.dead`/`.q.off{opacity:.4}`,
    /// `.q.on{background:rgba(245,239,230,.14);box-shadow:inset 0 0 0 1.5px rgba(245,239,230,.5);color:var(--w)}`;
    /// `.kst` Ø 128, `box-shadow:0 0 0 8px var(--bg),inset 0 0 0 2px rgba(255,59,48,.7)`, fondo rosso .16 su `--bg`,
    /// `.kst i` quadrato 42 raggio 8 `--red`; `.kst.pl` fondo verde .14, bordo 2 `--acc`, `svg` 46 tratto 2,4
    /// `margin-left:6px`).
    enum Console {
        static let gap: Double = 8
        static let radius: Double = 20
        static let labelSize: Double = 17
        static let labelOpacity: Double = 0.72
        static let icon: Double = 24
        static let iconLabelGap: Double = 7
        static let centerClearance: Double = 64
        static let offOpacity: Double = 0.4
        static let selectedFillOpacity: Double = 0.14
        static let selectedBorder: Double = 1.5
        static let selectedBorderOpacity: Double = 0.5
        static let highlight: Double = 0.055
        static let centerDiameter: Double = 128
        static let centerRing: Double = 8
        static let centerBorder: Double = 2
        static let stopFillOpacity: Double = 0.16
        static let stopBorderOpacity: Double = 0.7
        static let stopSquare: Double = 42
        static let stopSquareRadius: Double = 8
        static let playFillOpacity: Double = 0.14
        static let playTriangle: Double = 46
        static let playStroke: Double = 2.4
        static let playOffset: Double = 6
    }

    // SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — i veli V1, V2 e H, «Tap to start» e V4. Corpi, interlinee, spaziature e
    // distanze delle scritte stanno in `SoloVeilTypography` (Models/, col banco del pezzo del testo); qui i colori, il
    // respiro e le misure delle parti che non sono scritte.
    /// Il blocco del velo (`.p-va` e `.p-vt` in `--w66`; `.p-va b` e `.p-vn` bianco pieno) e il respiro del nome
    /// (`@keyframes pu{0%,100%{opacity:1}50%{opacity:.45}}`, `animation:pu 2.2s ease-in-out infinite`): ciclo intero
    /// 2,2 s, da 1 a .45 e ritorno, ease-in-out per ogni metà. `QLiveStage.Veil.pulsePeriod` non cambia: lo usano il
    /// velo di Direttore e Follower e la riga armata del Follower.
    enum Veil {
        static let relationOpacity: Double = 0.66
        static let tempoOpacity: Double = 0.66
        static let pulsePeriod: Double = 2.2
        static var pulseHalfPeriod: Double { pulsePeriod / 2 }
        static let pulseOpacityLow: Double = 0.45
    }
    /// «Tap to start» (`.p-tap{gap:10px;font:600 21px/1.2 Inter;color:var(--w86)}`, `.p-tap svg{width:44px;height:44px;
    /// stroke-width:1.7}`): la mano 44 col tratto 1,7, 10 fra mano e scritta, bianco .86.
    enum Tap {
        static let hand: Double = 44
        static let handStroke: Double = 1.7
        static let gap: Double = 10
        static let opacity: Double = 0.86
    }
    /// V4: «Back to Shows» (`.p-bs{height:64px;border-radius:20px;box-shadow:inset 0 0 0 2px rgba(245,239,230,.42);
    /// gap:10px;font:700 19px Inter;color:var(--w86)}`, la freccia in `.ic` 24).
    enum EndShow {
        static let buttonRadius: Double = 20
        static let buttonBorder: Double = 2
        static let buttonBorderOpacity: Double = 0.42
        static let buttonIcon: Double = 24
        static let buttonGap: Double = 10
        static let buttonFontSize: Double = 19
        static let buttonOpacity: Double = 0.86
    }
}
