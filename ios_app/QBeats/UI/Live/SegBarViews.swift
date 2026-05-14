import SwiftUI

struct MicroSegBarView: View {
    let current: Int
    let total: Int
    let state: LivePlaybackState
    let sectionHold: Bool

    // P2 sync: il segmento e' acceso quando lo state e' .playing OPPURE quando
    // siamo nella finestra di "fade post-sezione naturale" (sectionHold=true).
    // Questo allinea lo spegnimento del segmento a quello del LED metronomo:
    // entrambi durano la durata di un beat al BPM corrente, poi si spengono
    // INSIEME dallo stesso istante (sectionHold=false + beatActive=0 dispatchati
    // dall'asyncAfter in LiveView).
    // Stop manuale: NON attiva sectionHold → segmento si spegne subito a .stopped
    // (comportamento ratificato Test 4 P1+P3, LED resta acceso da TD#10).
    var body: some View {
        let segs = max(total, 1)
        let isPlaying: Bool = {
            if case .playing = state { return true }
            return false
        }()
        // TD #29 — guard esplicito .standby: tutti i segmenti spenti.
        // Pattern state-aware coerente con TD #25 (TeleprompterCapsuleView).
        // BOX5 V22 "Comportamenti ratificati": "Pre-Play (apertura, standby) → spenti".
        let isStandby: Bool = {
            if case .standby = state { return true }
            return false
        }()
        let isLit = !isStandby && (isPlaying || sectionHold)
        HStack(spacing: 3) {
            ForEach(0..<segs, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill((isLit && i < current) ? Color.white.opacity(0.85) : Color.white.opacity(0.07))
                    .frame(height: 5)
            }
        }
    }
}

struct MacroBarView: View {
    let current: Int
    let total: Int
    let state: LivePlaybackState

    var body: some View {
        let t = max(total, 1)
        let step = t > 32 ? Int(ceil(Double(t) / 32.0)) : 1
        let segs = Int(ceil(Double(t) / Double(step)))
        // TD #29 — guard esplicito .standby: tutti i segmenti spenti.
        // Coerente con MicroSegBarView. BOX5 V22 "Pre-Play (apertura, standby) → spenti".
        let isStandby: Bool = {
            if case .standby = state { return true }
            return false
        }()
        let filled = isStandby ? 0 : Int(ceil(Double(current) / Double(step)))

        HStack(spacing: 2) {
            ForEach(0..<segs, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < filled ? Color.white.opacity(0.65) : Color.white.opacity(0.09))
                    .frame(height: 3)
            }
        }
    }
}
