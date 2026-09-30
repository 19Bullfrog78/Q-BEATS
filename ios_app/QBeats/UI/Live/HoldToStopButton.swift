import SwiftUI
import os

// A386 · B2b (30/09/2026) — LO STOP A PRESSIONE DELLA FASCIA DA SOLO (foglio CD 2D-QUATER,
// file 2, L3 e riquadro «Stop · pressione 0,6 s — approvato (punto 2)», `.qb-st`). Si tiene
// premuto: il riempimento da sinistra è il tempo che manca (`::before`, `--hp`); a 0,6 s scatta
// lo Stop del musicista (`QLiveSession.followerMusicianStop`, via il chiamante) e si va FUORI,
// «You stopped the click.»; rilasciato prima, si svuota e non succede niente. Il numero vive in
// un posto solo (`QLiveStage.Follower.holdToStopSeconds`) perché si fissa al collaudo. Il
// pedale del Follower resta solo muto (BOX5 V52, punto 2): nessuno Stop da pedale. ■ è già il
// segno dello Stop in tutta l'app: nessuna icona nuova. Tre righe di log: inizio, rilascio
// anticipato (con quanto è durata), fine.
struct HoldToStopButton: View {
    let scaleFactor: CGFloat
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var holding = false
    @State private var startedAt: Date? = nil
    @State private var fireItem: DispatchWorkItem? = nil

    var body: some View {
        let textSize = QLiveStage.scaled(QLiveStage.Secondary.size, scaleFactor)
        let square = textSize * QLiveStage.Follower.stopSquareEm
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // `.qb-st::before{width:var(--hp)}`: il riempimento da sinistra.
                Rectangle()
                    .fill(QLiveStage.Follower.stopFill)
                    .frame(width: geo.size.width * progress)
                // `.qb-st i` (il quadrato ■) + «hold to stop» (JetBrains Mono 700 17, `--red-l`).
                HStack(spacing: QLiveStage.Follower.stopGap) {
                    RoundedRectangle(cornerRadius: QLiveStage.Follower.stopSquareRadius)
                        .fill(QLiveStage.Follower.stopRed)
                        .frame(width: square, height: square)
                    Text(FollowerVeilDecision.holdToStopLine)
                        .font(.jbMono(.bold, size: textSize))
                        .foregroundColor(QLiveStage.Follower.stopRed)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: QLiveStage.Follower.stopRadius))
            .overlay(
                RoundedRectangle(cornerRadius: QLiveStage.Follower.stopRadius)
                    .stroke(QLiveStage.Follower.stopBorder, lineWidth: QLiveStage.Follower.stopBorderWidth)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in beginHold() }
                    .onEnded { _ in endHold() }
            )
        }
    }

    private func beginHold() {
        guard !holding else { return }
        holding = true
        startedAt = Date()
        os_log("[Q-BEATS][2D][STOP] pressione inizio - soglia_ms:%.0f",
               log: .default, type: .default, QLiveStage.Follower.holdToStopSeconds * 1000.0)
        withAnimation(.linear(duration: QLiveStage.Follower.holdToStopSeconds)) {
            progress = 1
        }
        let item = DispatchWorkItem { fire() }
        fireItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + QLiveStage.Follower.holdToStopSeconds, execute: item)
    }

    private func endHold() {
        guard holding, let item = fireItem else { return }
        item.cancel()
        fireItem = nil
        holding = false
        let heldMs = startedAt.map { Date().timeIntervalSince($0) * 1000.0 } ?? 0
        startedAt = nil
        os_log("[Q-BEATS][2D][STOP] pressione rilascio anticipato - durata_ms:%.0f - nessuno stop",
               log: .default, type: .default, heldMs)
        withAnimation(.easeOut(duration: QLiveStage.Follower.releaseEmptySeconds)) {
            progress = 0
        }
    }

    private func fire() {
        guard holding else { return }
        fireItem = nil
        holding = false
        startedAt = nil
        os_log("[Q-BEATS][2D][STOP] pressione fine - stop del musicista",
               log: .default, type: .default)
        onComplete()
        progress = 0
    }
}
