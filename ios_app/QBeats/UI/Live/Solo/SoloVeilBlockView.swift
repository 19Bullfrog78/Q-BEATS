import SwiftUI

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — IL BLOCCO DEL VELO E «TAP TO START» ===
// Il blocco del velo (Solo REV18, `.p-vb` a 248, largo 338; tabella 3 «Blocco del velo»; punto 114): la riga A
// (`.p-va`: Inter 600 21/1,25 `--w66`; in H la sezione in Inter 700 bianco pieno, `.p-va b`), 14 sotto il nome
// (`.p-vn`: Inter 900 da 80 a 48, interlinea 1,02, spaziatura −0,03 em, bianco pieno, respiro 2,2 s), 12 sotto
// tempo e metrica (`.p-vt`: JetBrains Mono 500 21/1,2 `--w66`). Le tre scritte le decide il pezzo del testo
// (`TextFitter`, `SoloVeilTypography`) col misuratore vero (`CoreTextWidthMeasurer`): corpi e righe in punti del
// foglio, il fattore D4 sul risultato. «Tap to start» (`.p-tap`, 618–662, forma A, punto 100): la mano `i-tp` di 44
// (tratto 1,7), 10 fra mano e scritta, Inter 600 21 bianco .86, gruppo centrato.

/// Le tre scritte del blocco, già decise, e l'altezza del blocco.
struct SoloVeilTexts: Equatable {
    let relation: FittedText
    let name: FittedText
    let tempo: FittedText

    init(screen: SoloScreen, measurer: TextWidthMeasurer) {
        relation = TextFitter.fit(SoloVeilTypography.relationSpec(prefix: screen.relationPrefix,
                                                                  section: screen.relationSection),
                                  measurer: measurer)
        name = TextFitter.fit(SoloVeilTypography.nameSpec(screen.songName), measurer: measurer)
        tempo = TextFitter.fit(SoloVeilTypography.tempoSpec(screen.tempoLine), measurer: measurer)
    }

    /// L'altezza del blocco in punti del foglio: riga A, 14, nome, 12, tempo e metrica.
    var blockHeight: Double { SoloVeilTypography.blockHeight(relation: relation, name: name, tempo: tempo) }
}

struct SoloVeilBlockView: View {
    let texts: SoloVeilTexts
    let scale: Double

    var body: some View {
        let s = CGFloat(scale)
        VStack(spacing: 0) {
            FittedTextView(fit: texts.relation,
                           colors: [QLiveSolo.whiteAlpha(QLiveSolo.Veil.relationOpacity), QLiveSolo.white],
                           scale: scale)
            FittedTextView(fit: texts.name, colors: [QLiveSolo.white], scale: scale)
                .modifier(SoloVeilNamePulse())
                .padding(.top, CGFloat(SoloVeilTypography.gapRelationToName) * s)
            FittedTextView(fit: texts.tempo,
                           colors: [QLiveSolo.whiteAlpha(QLiveSolo.Veil.tempoOpacity)],
                           scale: scale)
                .padding(.top, CGFloat(SoloVeilTypography.gapNameToTempo) * s)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

/// «Tap to start» con la mano a sinistra (forma A): il gruppo centrato nei 44 di altezza (618–662).
struct SoloTapToStartView: View {
    let scale: Double

    var body: some View {
        let s = CGFloat(scale)
        let hand = CGFloat(QLiveSolo.Tap.hand) * s
        let color = QLiveSolo.whiteAlpha(QLiveSolo.Tap.opacity)
        HStack(spacing: CGFloat(QLiveSolo.Tap.gap) * s) {
            SoloIconView(icon: .tapHand, size: hand, color: color,
                         strokeWidth: hand * CGFloat(QLiveSolo.Tap.handStroke / QLiveSolo.iconViewBox))
            Text(SoloScreenDecision.tapToStart)
                .font(.custom(SoloFonts.interSemiBold, size: CGFloat(SoloVeilTypography.tapSize) * s))
                .foregroundColor(color)
                .lineLimit(1)
                .fixedSize()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
