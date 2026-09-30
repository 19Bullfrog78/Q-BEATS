import SwiftUI

// A386 · B2b (30/09/2026) — LO SLOT E: IL SEGNALE DEL DIRETTORE, CINQUE FACCE (foglio CD
// 2D-QUATER, file 1, riquadro «slot E — il segnale — cinque facce», `.qb-sg`). La faccia la
// decide `FollowerVeilDecision` (precedenza: Start Stop Sync spento · Searching… · No director
// signal · segnale OK con «band playing» · segnale OK): questa vista mette a schermo. Riga 1 in
// STAGE-CAPS (`.qb-sg p`: JetBrains Mono 600 21, spaziatura 1,5, MAIUSCOLE, bianco 0,60 —
// ambra `.no` quando qualcosa non va), con davanti il pallino (`.qb-sg p i`, `.5em`: verde
// pieno con l'OK, vuoto col bordo 2 mentre cerca) oppure l'icona di stato (`.qb-ic`, ambra);
// sotto, le righe di dettaglio in STAGE-SECONDARY (`.qb-sg em`: JetBrains Mono 500 17,
// spaziatura 0,3, bianco 0,60; `em.a` ambra chiara per «band playing»), a capo se serve
// (`text-wrap:pretty`). Sul velo L1 le righe stanno al centro (`.qb-vs .qb-sg p{justify-content:
// center}`); nella testa del velo FUORI a sinistra. Corpi con la legge provvisoria
// (`QLiveStage.scaled`), distanze in punti.
struct FollowerSignalView: View {
    let decision: FollowerVeilDecision
    let scaleFactor: CGFloat
    let centered: Bool

    var body: some View {
        if let line = decision.slotELine {
            let capsSize = QLiveStage.scaled(QLiveStage.Caps.size, scaleFactor)
            let secondarySize = QLiveStage.scaled(QLiveStage.Secondary.size, scaleFactor)
            let lineColor: Color = decision.slotEIsAmber
                ? QLiveStage.Follower.amber
                : Color.white.opacity(QLiveStage.Caps.opacity)
            let detailColor: Color = decision.slotEDetailIsAmber
                ? QLiveStage.Follower.amberLight
                : Color.white.opacity(QLiveStage.Secondary.opacity)
            VStack(alignment: centered ? .center : .leading, spacing: 0) {
                HStack(spacing: capsSize * QLiveStage.Follower.slotGapEm) {
                    if let icon = decision.slotEIcon {
                        FollowerIconView(icon: icon,
                                         size: capsSize * QLiveStage.Follower.iconEm,
                                         color: QLiveStage.Follower.amber)
                    } else if decision.slotE == .searching {
                        Circle()
                            .stroke(Color.white.opacity(QLiveStage.Caps.opacity),
                                    lineWidth: QLiveStage.Follower.slotDotRing)
                            .frame(width: capsSize * QLiveStage.Follower.slotDotEm,
                                   height: capsSize * QLiveStage.Follower.slotDotEm)
                    } else {
                        Circle()
                            .fill(QLiveStage.Follower.linkGreen)
                            .frame(width: capsSize * QLiveStage.Follower.slotDotEm,
                                   height: capsSize * QLiveStage.Follower.slotDotEm)
                    }
                    Text(line)
                        .font(.jbMono(QLiveStage.Caps.weight, size: capsSize))
                        .tracking(QLiveStage.Caps.tracking)
                        .foregroundColor(lineColor)
                        .textCase(.uppercase)
                        .lineLimit(1)
                }
                ForEach(Array(decision.slotEDetailLines.enumerated()), id: \.offset) { _, detail in
                    Text(detail)
                        .font(.jbMono(QLiveStage.Secondary.weight, size: secondarySize))
                        .tracking(QLiveStage.Secondary.tracking)
                        .foregroundColor(detailColor)
                        .multilineTextAlignment(centered ? .center : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, QLiveStage.Follower.slotDetailTop)
                }
            }
            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        }
    }
}
