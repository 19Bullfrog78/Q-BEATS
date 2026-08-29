import SwiftUI

struct BarCounterView: View {
    let current: Int
    let total: Int
    let state: LivePlaybackState

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Vedi `LiveView` per la baseline 390pt.
    let scaleFactor: CGFloat

    var body: some View {
        HStack {
            switch state {
            case .countIn, .standby:
                Text("— / —")
                    .font(.jbMono(.medium, size: 16 * scaleFactor))
                    .foregroundColor(Color.white.opacity(0.88))
            default:
                let isInf   = total == -1
                let isReady = total > 0 || isInf
                // ⟦DISPLAY-FIRMA-A⟧ A5+C1 (29/08) — current == 0 significa SPENTO
                // (stessa semantica di `beatActive`: «0 = nessuno»). Accade al
                // rientro su uno show che suona, finché il primo confine di
                // sezione non consegna l'ancora vera: la posizione dentro la
                // sezione non è pubblicata da nessuno, e «Bar 0» sarebbe una
                // bugia quanto un numero vecchio. Trattino, non zero — verdetto
                // CD firmato 28/08. Il TOTALE resta disegnato: si ricava dalla
                // sezione («il binario si disegna anche senza il treno»).
                Group {
                    Text("Bar ")
                        .foregroundColor(Color.white.opacity(0.88))
                    + Text(isReady && current > 0 ? "\(current)" : "—")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    + Text(" of ")
                        .foregroundColor(Color.white.opacity(0.88))
                    + Text(isInf ? "∞" : isReady ? "\(total)" : "—")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .font(.jbMono(.medium, size: 16 * scaleFactor))
            }
            Spacer()
        }
    }
}
