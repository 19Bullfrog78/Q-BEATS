import SwiftUI

// MARK: - RoomSwitchBar — Design System CD, freeze QLive Nav — §1.4 FROZEN
// Contratto vivo: DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0 (contiene le regole
// .roombar/.homebtn/.roomseg/.metrofab). Questo componente fu scritto in origine contro il
// predecessore "standalone" (09/07) — file DISTINTO dalla "base", NON lo stesso documento,
// che però condivide quelle stesse regole CSS, verificate identiche byte-per-byte in FREEZE-GIT.
// R7 (LIBRO v31): nessuno sha inciso nei commenti; si cita path @ commit, git verifica.
// ⚠️ GATE DEVICE S3 — ESITO 2026-07-14 (Mauro, device reale): [1] centro Q-Live PASS ·
//    [2]/[3] tocchi 8-10pt oltre il bordo pill FAIL (espansione hit-area INERTE a runtime,
//    bersaglio reale 34pt) · [4] bordo dx pill attiva PASS (nessun log, corretto).
//    → hit-test RISTRUTTURATO in questa revisione (vedi segment/pill). CI-verde ≠ chiuso:
//    il RI-gate device ripete TUTTI e 4 i tocchi da capo, non solo [2]/[3].
// Componente presentazionale INERTE: highlight pilotato da `active` (no @State), zero logica di switch/navigazione.
// «+» create show è §8 DIFFERITO — FUORI PERIMETRO qui: nessun addmini/showsPlus/onAdd in questo atomo.
// Sorgente: `.roombar.center`/`.homebtn`/`.roomseg` (variant .full) e `.navbar .seg-mini` (variant .segMini).
// CD-Q7 RISOLTA e RATIFICATA (LIBRO v31, sez.2, riga 2026-07-11): «+» OMESSO finché §8 non
// arriva; l'header Q-Stage è IDENTICO a Q-Live (`.roombar.center`/`.roomseg`), nessun bottone
// morto o disabilitato al suo posto. Quando §8 arriverà il «+» rientra ancorato a destra —
// il segmento è già centrato, NESSUN reflow. Quindi il `.full` implementato qui (solo
// `.roombar.center`) NON è provvisorio: è il layout definitivo dell'header Q-Stage finché §8
// non arriva. (Prima di CD-Q7 era un'apertura per CD; ora è deciso.)
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
            // .roombar.center: seg centrato sull'INTERA barra, home in `position:absolute;left:14px` (§CSS .roombar.center)
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
            // per lato → barra a larghezza piena W, contenuto inset 14/lato (= §CSS .roombar
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

    // .homebtn: 34×34, radius 10, bg white .05, bordo white .09 (§CSS .homebtn).
    // FIX 1 (referee): icona = path SVG verbatim (§markup .homebtn), NON SF Symbol "house" —
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

    // .roomseg / .navbar .seg-mini: container bg white .05, bordo white .10 (§CSS .roomseg / .seg-mini)
    // GATE-FIX S3 (2026-07-14): chrome reso come .background shape-fill (fill + stroke della
    // stessa RoundedRectangle) al posto di background(Color)+clipShape+overlay. Resa IDENTICA
    // (clippare un colore full-bleed con una shape = riempire la stessa shape; lo .stroke resta
    // centrato sul medesimo perimetro), ma NESSUN clipShape antenato tra i Button e la barra —
    // il clip era il sospettato #1 del gate fallito e qui esce dal percorso dell'hit-test.
    // L'HStack è ora alto quanto l'hit-area REALE dei Button (54 su .full, vedi pill()); il
    // chrome VISIVO resta 42/36, centrato via .frame(height:). Su .segMini (espansione 0)
    // .frame(minHeight:) tiene il layout a 36 come prima: geometria riportata INVARIATA
    // per entrambe le varianti (.full riportava 42 al ZStack che la centrava in 54; ora
    // riporta 54 in 54 — chrome negli stessi pixel).
    private var segment: some View {
        // A129 — «.seg-mini abolita»: il freeze rev3 (pannello ③, callout «un controllo che il
        // refuso non ritorni») non porta più ALCUNA regola CSS `.seg-mini`: «il room switch è
        // un componente solo in tutta l'app, con una misura sola». Container e pill hanno gli
        // stessi valori su entrambe le varianti — resta diverso solo COSA rendono (`.full`
        // aggiunge l'home button, `.segMini` no: vedi lo `switch` sul `body`), non le misure.
        // A130 — le due righe sotto erano forcelle `variant == .full ? X : X`: stesso valore
        // su entrambi i rami. Il freeze vieta esplicitamente quella FORMA, non solo il valore
        // sbagliato: «un controllo, una misura, nessuna domanda» — una forcella che risponde
        // sempre uguale È la domanda che il freeze dice di non lasciare aperta. Costanti.
        let containerPadding: CGFloat = 4    // era 3 su .segMini
        let containerRadius: CGFloat = 12    // era 10 su .segMini
        // Altezza VISIVA del chrome: pill (34, uniforme A129) + anello padding sopra/sotto (4/4)
        // → 42 su ENTRAMBE le varianti (era 42 / 36). NON è l'altezza dell'hit-area (54 su
        // .full, MAI su .segMini — vedi `hitExpansion` più sotto, riga NON toccata da A129).
        // ⚠️ SEGNALATO AL REFEREE, NON RISOLTO: il testo del freeze calcola questo chrome in
        // «34+3+3 = 40pt», usando il VECCHIO containerPadding di .segMini (3) anche per la
        // pill NUOVA (34). Il foglio di stile dello stesso freeze dà invece a `.roomseg` un
        // padding UNIFORME di 4px (riga 102: `.roomseg{padding:4px}`), che con la pill unica
        // fa 34+4+4 = 42 su ENTRAMBE le varianti — il valore che questo codice ora produce.
        // 40 e 42 stanno entrambi dentro una navbar da 50: non blocca, ma è una contraddizione
        // interna al normativo e va incisa, non nascosta dietro un valore intermedio.
        let chromeHeight: CGFloat = 34 + containerPadding * 2   // era 30 su .segMini; = 42 (34 + 4×2)
        return HStack(spacing: 3) {
            pill(.qStage, label: "Q-Stage")
            pill(.qLive, label: "Q-Live")
        }
        .padding(.horizontal, containerPadding)
        .frame(minHeight: chromeHeight)
        .background {
            RoundedRectangle(cornerRadius: containerRadius, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: containerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .frame(height: chromeHeight)
        }
    }

    // .roomseg .opt(.stage-on/.live-on) e .navbar .seg-mini .o(.live-on) (§CSS .roomseg .opt / .seg-mini .o)
    private func pill(_ room: Room, label: String) -> some View {
        let isOn = room == active
        let tint: Color = room == .qStage ? QStageTheme.blue : QStageTheme.orange
        // A129 — `.roomseg .opt` verbatim su entrambe le varianti (freeze rev3 riga 103):
        // `font-size:10.5px;...padding:7px 12px;border-radius:9px;...min-height:34px`.
        // Il vecchio valore .segMini (9 · 9/5 · 8 · 30) veniva da `.navbar .seg-mini .o` del
        // freeze SUPERATO 07/11 — quel selettore non esiste più in rev3, per costruzione: la
        // citazione CD-Q8 poco più sotto resta come STORIA della ratifica, non come valore.
        // A130 — le cinque righe sotto erano forcelle `variant == .full ? X : X`: stesso
        // valore su entrambi i rami, forma vietata dal freeze (vedi nota su `segment`).
        let fontSize: CGFloat = 10.5   // era 9 su .segMini
        let hPad: CGFloat = 12         // era 9 su .segMini
        let vPad: CGFloat = 7          // era 5 su .segMini
        let radius: CGFloat = 9        // era 8 su .segMini
        let minHeight: CGFloat = 34    // era 30 su .segMini
        // FIX 4-bis (referee): hit-area 54pt su tutta l'altezza barra (§CSS .roomseg, commento CD
        // verbatim). Scoping: solo `.full` ha la claim sourced (la nota hit-area sta sul
        // `.roomseg`, la variante piena).
        // ⚠️ REFUSO CORRETTO IN A129: qui c'era scritto «chrome visibile resta 34/30»,
        // già stale nello stesso commit che lo introduceva — il 30 non esiste più da due
        // blocchi sopra. Tolto invece di lasciarlo a mentire al prossimo lettore.
        // ⚠️ MARCATURA A129 — I NUMERI QUI SOTTO SONO STORIA, NON PIÙ IL VALORE CORRENTE.
        // Chrome visibile: 30pt → 34pt (freeze rev3). Il PRINCIPIO resta intatto e NON si tocca:
        // hit-area ≥44pt gattata dal RI-GATE S3, `.segMini` a hitExpansion ZERO finché non
        // sblocca. Anche il calcolo proiettato «(50−30)/2 = 10pt» in fondo al blocco è STORIA:
        // con minHeight ora 34 non è più valido, e ricalcolarlo qui sarebbe fare il lavoro di
        // S5 in anticipo — NON è in questo perimetro.
        // ── `.navbar .seg-mini` — CD-Q8 RISOLTA e RATIFICATA (LIBRO v31, sez.4): hit-area
        // ≥44pt, chrome visibile 30pt. NON è un'omissione del freeze — i 44pt sono regola
        // globale HIG e CD ha CONFERMATO il risultato (verificato a fonte: `.navbar{height:50px}`
        // e `.seg-mini .o{min-height:30px}`). ⚠️ La TECNICA che CD aveva prescritto
        // (`minHeight:44` sulla cella) è RESPINTA dal referee: farebbe crescere anche
        // background/bordo → pill 44pt VISIBILI, contraddicendo il «chrome resta 30pt» di CD
        // stesso. CD owna il RISULTATO; la tecnica è dominio CC/referee. 🔒 GATTATA DAL
        // RI-GATE S3: NON dare l'hit-area a `.segMini` finché il ri-gate non prova la tecnica
        // ristrutturata su `.full`. Quando sblocca: `hitExpansion` .segMini = (50 − 30) / 2 =
        // 10pt (navbar 50pt, coerente con `.roomseg` che riempie i 54). Lavoro per S5, NON qui.
        // Il primo tentativo (`.contentShape(Rectangle().inset(by: -N))`) insettava
        // TUTTI E 4 I LATI: le due pill (3pt di gap) finivano con hit-area sovrapposte di 17pt,
        // e nella sovrapposizione vince il sibling successivo → toccando il bordo destro di
        // "Q-Stage" si attivava "Q-Live". Bug funzionale, trovato dal referee. → espansione
        // SOLO verticale: la larghezza non è MAI toccata, zero sovrapposizione orizzontale.
        // ── GATE DEVICE S3 2026-07-14: FALLITO con la tecnica precedente (pad→contentShape→
        // pad-negativo applicati FUORI dal Button, sul suo wrapper): tocchi [2]/[3] mai
        // loggati, espansione INERTE, bersaglio reale 34pt. CAUSA PRIMARIA (a source): il
        // `.contentShape` esteso apparteneva al wrapper — una vista SENZA gesto; il gesto del
        // Button copriva solo la label (34pt). Il `.clipShape` del container (sospettato #1
        // originario) non è escluso come strato aggiuntivo, ma il tocco moriva già prima.
        // RISTRUTTURAZIONE (questa revisione) — elimina ENTRAMBI i meccanismi per costruzione:
        //  (1) espansione DENTRO la label → il gesto del Button copre i 54pt REALI;
        //  (2) chrome container = .background shape-fill (vedi segment) → nessun clipShape
        //      antenato sul percorso dell'hit-test;
        //  (3) ZERO padding negativo → Button alto 54 REALI = altezza barra (.frame(height:54)
        //      nel body): nessun tocco deve atterrare fuori dai bounds di alcun antenato.
        // Verità finale = solo il ri-gate device (4 tocchi, da capo).
        let hitExpansion: CGFloat = variant == .full ? (54 - minHeight) / 2 : 0

        return Button(action: { if !isOn { onSwitch() } }) {
            Text(label)
                .font(.jbMono(.bold, size: fontSize))
                .tracking(1)   // A130, era forcella .full?1:1 — A129 aveva GIÀ TOLTO lo 0.8 su .segMini; `.roomseg .opt` verbatim (freeze rev3 :103, letter-spacing:1px)
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
                    // attivo (assente su .seg-mini nel freeze, §CSS .roomseg .opt vs .seg-mini .o).
                    // Rifinitura (referee): .strokeBorder invece di .stroke — il CSS globale è
                    // box-sizing:border-box (§CSS globale), bordo/inset stanno DENTRO; .stroke è
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
                // GATE-FIX S3 (2026-07-14): l'espansione hit vive DENTRO la label del Button —
                // così il GESTO del Button copre tutti i 54pt (.full; 0 su .segMini). Il chrome
                // visivo (background/bordo qui sopra) resta 34: il padding aggiunto è
                // trasparente. Larghezza MAI toccata (vedi storia inset(-N) qui sopra).
                .padding(.vertical, hitExpansion)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Icona home, viewBox 24×24: roofline "M4 11l8-6 8 6" + pareti "M6 10v9h12v-9" (§markup .homebtn)
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
