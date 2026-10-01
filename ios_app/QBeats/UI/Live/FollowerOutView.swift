import SwiftUI

// A386 · B2b (30/09/2026) — LA FACCIA DEL FOLLOWER FUORI DALLA BAND: Join · Out · Ready, con la
// scaletta (foglio CD 2D-QUATER, file 1 L2 ②③④, file 2 L4 L5 L6 L7 L8, `.qb-ou`). Tre righe
// nell'ordine delle domande (sono fuori? · perché? · posso rientrare adesso?) e poi la scaletta
// già posizionata. Tutto è deciso in `FollowerVeilDecision`: la parola in testa (`.qb-ow`, ambra
// «Out» o bianca «Join»/«Ready»), la riga sotto (`.qb-or`, STAGE-BODY, con il divieto sui due
// rifiuti), lo slot E (`FollowerSignalView`), l'intestazione (`.qb-lh`: «Join at»/«Rejoin at» e
// «N songs»), la riga evidenziata (`.qb-r.pr`: proposta piena o tratteggiata, o armata bianca
// che pulsa come il gigante del velo) e la posizione della lista (la riga evidenziata seconda,
// con la precedente sopra; senza, in cima). Questa vista disegna e basta.
// Le righe sono sempre toccabili (punto 6): un tocco arma, non parte — il tocco va alla stanza
// (`onTapSong` → `QLiveSession.armRientra`), che passa dalla macchina; nessuna porta di qui
// chiama `start()`. La testata resta sopra (freccia e muto toccabili, centro al 10%, come sul
// velo). Corpi con la legge provvisoria (`QLiveStage.scaled`), distanze e margini in punti.
// A386 · B2d (01/10/2026) — LA RIGA ARMATA PULSA SEMPRE (lastra L7). Fino a B2c la pulsazione
// partiva una volta sola, all'`onAppear` di questa vista, su uno stato della vista intera: la
// vista resta la stessa fra Join, Out e Ready, quindi una riga armata DOPO la comparsa leggeva
// lo stato già arrivato in fondo e restava ferma (collaudo D7). Ora la pulsazione appartiene al
// nome della riga armata (`ArmedNamePulse`, in fondo al file): nasce quando la riga diventa
// armata — in qualunque momento, anche su un'altra riga, anche dopo uno scorrimento — e muore
// quando non lo è più. Stesso periodo, stessa ampiezza e stessa curva di prima.
struct FollowerOutView: View {
    let decision: FollowerVeilDecision
    let songNames: [String]
    let scaleFactor: CGFloat
    let onTapSong: (Int) -> Void

    var body: some View {
        let wordSize = QLiveStage.scaled(QLiveStage.Word.size, scaleFactor)
        let bodySize = QLiveStage.scaled(QLiveStage.Body.size, scaleFactor)
        let capsSize = QLiveStage.scaled(QLiveStage.Caps.size, scaleFactor)
        let secondarySize = QLiveStage.scaled(QLiveStage.Secondary.size, scaleFactor)
        let dataSize = QLiveStage.scaled(QLiveStage.Data.size, scaleFactor)

        VStack(alignment: .leading, spacing: 0) {
            // ── La testa: parola, riga sotto, slot E (`.qb-ob`) ──
            VStack(alignment: .leading, spacing: 0) {
                Text(decision.headWord ?? "")
                    .font(.custom(QLiveStage.Word.fontName, size: wordSize))
                    .tracking(QLiveStage.Word.tracking)
                    .foregroundColor(decision.headWordIsAmber ? QLiveStage.Follower.amber : .white)
                    .lineLimit(1)
                if let bodyLine = decision.bodyLine {
                    HStack(alignment: .top, spacing: bodySize * QLiveStage.Follower.bodyIconGapEm) {
                        if let icon = decision.bodyIcon {
                            FollowerIconView(icon: icon,
                                             size: bodySize * QLiveStage.Follower.iconEm,
                                             color: QLiveStage.Follower.amber)
                                .padding(.top, bodySize * QLiveStage.Follower.bodyIconTopEm)
                        }
                        Text(bodyLine)
                            .font(.custom(QLiveStage.Body.fontName, size: bodySize))
                            .tracking(QLiveStage.Body.tracking)
                            .foregroundColor(Color.white.opacity(QLiveStage.Body.opacity))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, QLiveStage.Follower.bodyTop)
                }
                FollowerSignalView(decision: decision, scaleFactor: scaleFactor, centered: false)
                    .padding(.top, QLiveStage.Follower.slotTop)
            }
            .padding(.top, QLiveStage.Follower.headTop)
            .padding(.horizontal, QLiveStage.Follower.sideMargin)

            // ── L'intestazione della scaletta (`.qb-lh`) ──
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(decision.headingLine ?? "")
                    .font(.jbMono(QLiveStage.Caps.weight, size: capsSize))
                    .tracking(QLiveStage.Caps.tracking)
                    .foregroundColor(Color.white.opacity(QLiveStage.Caps.opacity))
                    .textCase(.uppercase)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(decision.songsLine ?? "")
                    .font(.jbMono(QLiveStage.Secondary.weight, size: secondarySize))
                    .foregroundColor(Color.white.opacity(QLiveStage.Secondary.opacity))
                    .lineLimit(1)
            }
            .padding(.top, QLiveStage.Follower.listHeaderTop)
            .padding(.bottom, QLiveStage.Follower.listHeaderBottom)
            .padding(.horizontal, QLiveStage.Follower.sideMargin)
            Rectangle()
                .fill(QLiveStage.Follower.listHeaderRule)
                .frame(height: 1)
                .padding(.horizontal, QLiveStage.Follower.sideMargin)

            // ── La scaletta (`.qb-ls`, `.qb-r`) ──
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(songNames.enumerated()), id: \.offset) { idx, name in
                            row(idx: idx, name: name, bodySize: bodySize, dataSize: dataSize,
                                secondarySize: secondarySize)
                                .id(idx)
                        }
                    }
                }
                .onAppear { scroll(proxy) }
                .onChange(of: decision.scrollTargetRow) { _ in scroll(proxy) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Le righe

    @ViewBuilder
    private func row(idx: Int, name: String, bodySize: CGFloat, dataSize: CGFloat,
                     secondarySize: CGFloat) -> some View {
        if idx == decision.highlightedRow, let style = decision.rowStyle {
            highlightedRow(idx: idx, name: name, style: style, bodySize: bodySize,
                           dataSize: dataSize, secondarySize: secondarySize)
        } else {
            plainRow(idx: idx, name: name, bodySize: bodySize, dataSize: dataSize)
        }
    }

    /// `.qb-r`: numero (STAGE-DATA, largo 1,6em, a destra) e nome (STAGE-BODY, una riga).
    private func plainRow(idx: Int, name: String, bodySize: CGFloat, dataSize: CGFloat) -> some View {
        HStack(spacing: QLiveStage.Follower.rowGap) {
            rowNumber(idx, dataSize: dataSize)
            Text(name)
                .font(.custom(QLiveStage.Body.fontName, size: bodySize))
                .tracking(QLiveStage.Body.tracking)
                .foregroundColor(Color.white.opacity(QLiveStage.Body.opacity))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, QLiveStage.Follower.sideMargin)
        .frame(height: QLiveStage.Follower.rowHeight)
        .overlay(alignment: .bottom) {
            Rectangle().fill(QLiveStage.Follower.rowRule).frame(height: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTapSong(idx) }
    }

    /// `.qb-r.pr` (proposta, bordo pieno) · `.un` (ipotesi, tratteggio) · `.ar` (armata, bianca,
    /// il nome pulsa come il gigante del velo: «armato, aspetta il Play»).
    private func highlightedRow(idx: Int, name: String, style: FollowerVeilDecision.RowStyle,
                                bodySize: CGFloat, dataSize: CGFloat, secondarySize: CGFloat) -> some View {
        let border: Color = style == .armed ? QLiveStage.Follower.armedBorder : QLiveStage.Follower.amber
        let fill: Color
        switch style {
        case .proposalNormal: fill = QLiveStage.Follower.proposedFill
        case .proposalGuess:  fill = QLiveStage.Follower.guessFill
        case .armed:          fill = QLiveStage.Follower.armedFill
        }
        let lineColor: Color = style == .armed
            ? Color.white.opacity(QLiveStage.Body.opacity)
            : QLiveStage.Follower.amberLight
        let dash: [CGFloat] = style == .proposalGuess ? QLiveStage.Follower.guessDash : []
        return HStack(alignment: .center, spacing: QLiveStage.Follower.rowGap) {
            rowNumber(idx, dataSize: dataSize)
            VStack(alignment: .leading, spacing: 0) {
                highlightedName(name, armed: style == .armed, bodySize: bodySize)
                if let line = decision.rowLine {
                    Text(line)
                        .font(.jbMono(QLiveStage.Secondary.weight, size: secondarySize))
                        .tracking(QLiveStage.Secondary.tracking)
                        .foregroundColor(lineColor)
                        .lineLimit(1)
                        .padding(.top, QLiveStage.Follower.rowLineTop)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, QLiveStage.Follower.proposedPaddingV)
        .padding(.horizontal, QLiveStage.Follower.proposedPaddingH)
        .frame(minHeight: QLiveStage.Follower.proposedMinHeight)
        .background(
            RoundedRectangle(cornerRadius: QLiveStage.Follower.proposedRadius).fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QLiveStage.Follower.proposedRadius)
                .stroke(border, style: StrokeStyle(lineWidth: QLiveStage.Follower.proposedBorder, dash: dash))
        )
        .padding(.vertical, QLiveStage.Follower.proposedMarginV)
        .padding(.horizontal, QLiveStage.Follower.proposedMarginH)
        .contentShape(Rectangle())
        .onTapGesture { onTapSong(idx) }
    }

    /// Il nome della riga evidenziata. Armata: pulsa (`ArmedNamePulse`). Proposta o ipotesi:
    /// fermo. Sono due rami distinti apposta: quando la riga diventa armata il ramo che pulsa
    /// NASCE (stato nuovo, la pulsazione parte), quando smette di esserlo sparisce, e con lui
    /// la pulsazione. Con un solo testo e un'opacità condizionata non partiva e non si fermava.
    @ViewBuilder
    private func highlightedName(_ name: String, armed: Bool, bodySize: CGFloat) -> some View {
        let text = Text(name)
            .font(.custom(QLiveStage.Body.fontName, size: bodySize))
            .tracking(QLiveStage.Body.tracking)
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
        if armed {
            text.modifier(ArmedNamePulse())
        } else {
            text
        }
    }

    private func rowNumber(_ idx: Int, dataSize: CGFloat) -> some View {
        Text(String(idx + 1))
            .font(.jbMono(QLiveStage.Data.weight, size: dataSize))
            .foregroundColor(Color.white.opacity(QLiveStage.Data.opacity))
            .lineLimit(1)
            .frame(width: dataSize * QLiveStage.Follower.rowNumberWidthEm, alignment: .trailing)
    }

    // MARK: - La posizione della lista (L4, L5)

    private func scroll(_ proxy: ScrollViewProxy) {
        guard !songNames.isEmpty else { return }
        let target = decision.scrollTargetRow ?? 0
        proxy.scrollTo(min(max(0, target), songNames.count - 1), anchor: .top)
    }
}

// MARK: - La pulsazione della riga armata (L7)

/// A386 · B2d — il nome della riga armata pulsa come il gigante del velo («armato, aspetta il
/// Play»: foglio CD 2D-QUATER file 2, lastra L7, `.qb-r.ar b`). Gli stessi numeri e la stessa
/// curva di `StandbyOverlayView`: `QLiveStage.Veil.pulsePeriod` (2,2 s per mezza corsa),
/// opacità fra `pulseOpacityLow` (0,45) e `pulseOpacityHigh` (1,0), `easeInOut` che si ripete
/// avanti e indietro. Pulsa solo il nome: non la sottoriga, non il bordo, non il fondo.
/// Lo stato è di QUESTO modificatore, non della vista intera: `FollowerOutView` lo applica solo
/// nel ramo della riga armata, quindi nasce (da 1,0, senza scatto: il nome era a 1,0 un attimo
/// prima) ogni volta che una riga diventa armata, e sparisce quando non lo è più.
/// L'animazione è legata al solo valore `dimmed` (`.animation(_:value:)`): non tocca nient'altro
/// di ciò che cambia a schermo nello stesso passo. All'`onAppear` lo stato si INVERTE, non si
/// «mette a»: se la riga esce dallo schermo e ci rientra con lo stato già cambiato, un valore
/// uguale non farebbe ripartire niente; un valore invertito sì, sempre.
private struct ArmedNamePulse: ViewModifier {
    @State private var dimmed = false

    func body(content: Content) -> some View {
        content
            .opacity(dimmed ? QLiveStage.Veil.pulseOpacityLow : QLiveStage.Veil.pulseOpacityHigh)
            .animation(.easeInOut(duration: QLiveStage.Veil.pulsePeriod).repeatForever(autoreverses: true),
                       value: dimmed)
            .onAppear { dimmed.toggle() }
    }
}
