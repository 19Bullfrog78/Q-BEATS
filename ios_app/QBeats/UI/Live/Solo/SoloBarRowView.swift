import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — BATTUTA E TEMPO: «Bar 5 of 8» E «121 bpm» ===
// Foglio (REV9, `.p-bc`, riga «Battuta · tempo» delle misure): 226-252; a sinistra «Bar», il numero, «of 8»; a
// destra il tempo e «bpm»; numeri JetBrains Mono 700 26 bianco, spaziatura −0,02 em; parole Inter 600 17
// `--w66`, margine 7 dal numero. Le regole di oggi di `BarCounterView`: trattino al posto del numero quando la
// battuta è 0 (ancora non conquistata) o il totale non è pronto; «∞» per la sezione infinita (−1); «— / —» in
// `.countIn` e in `.standby`. Il BPM come lo scrive oggi la testata: `Int(currentBPM.rounded())`.
// Caso che il foglio non disegna (D6): in `.countIn` il foglio disegna «Count-in 1 of 1» (K0, pezzo 3): qui vale
// il «— / —» di oggi, nella veste dei numeri.
struct SoloBarRowView: View {
    let current: Int
    let total: Int
    let state: LivePlaybackState
    let bpm: Double
    let scale: Double

    var body: some View {
        let numberSize = CGFloat(QLiveSolo.BarRow.numberSize * scale)
        let numberFont = Font.jbMono(.bold, size: numberSize)
        let numberTracking = numberSize * CGFloat(QLiveSolo.BarRow.numberTrackingEm)
        let wordFont = Font.custom("Inter-SemiBold", size: CGFloat(QLiveSolo.BarRow.wordSize * scale))
        let wordColor = QLiveSolo.whiteAlpha(QLiveSolo.BarRow.wordOpacity)
        let gap = CGFloat(QLiveSolo.BarRow.wordGap * scale)
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: gap) {
                switch state {
                case .countIn, .standby:
                    Text("— / —")
                        .font(numberFont)
                        .tracking(numberTracking)
                        .foregroundColor(QLiveSolo.white)
                default:
                    Text("Bar")
                        .font(wordFont)
                        .foregroundColor(wordColor)
                    Text(currentText)
                        .font(numberFont)
                        .tracking(numberTracking)
                        .foregroundColor(QLiveSolo.white)
                    Text("of \(totalText)")
                        .font(wordFont)
                        .foregroundColor(wordColor)
                }
            }
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: gap) {
                Text("\(Int(bpm.rounded()))")
                    .font(numberFont)
                    .tracking(numberTracking)
                    .foregroundColor(QLiveSolo.white)
                Text("bpm")
                    .font(wordFont)
                    .foregroundColor(wordColor)
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Le regole di `BarCounterView`, identiche.
    private var isInf: Bool { total == -1 }
    private var isReady: Bool { total > 0 || isInf }
    private var currentText: String { (isReady && current > 0) ? "\(current)" : "—" }
    private var totalText: String { isInf ? "∞" : (isReady ? "\(total)" : "—") }
}
