import SwiftUI

// MARK: - Token visivi condivisi di Q-Stage — Design System CD (27/06)
// Q-STAGE = ambiente "fuori dal play" → BLU NOTTE (#0c1024).
// Il neutro #0e0e10 (antracite) resta SOLO alla Vista Q-Live sul palco.
enum QStageTheme {
    static let bg       = Color(hex: "#0c1024")      // sfondo schermo · blu notte
    static let surface  = Color(hex: "#141832")      // card · contenitore gear
    static let surface2 = Color(hex: "#1c2248")      // superficie più chiara (raro)
    static let line     = Color.white.opacity(0.08)  // bordo card / gear / tabbar
    static let line2    = Color.white.opacity(0.14)  // bordo più marcato
    static let text     = Color.white                // titolo schermata, nome brano
    static let text2    = Color.white.opacity(0.55)  // sottotitolo, meta, gear, back
    static let text3    = Color.white.opacity(0.30)  // crumb, tab inattiva
    static let blue     = Color(hex: "#2a6bd6")      // accento Q-Stage · stati selezionati
    static let amber    = Color(hex: "#f5b820")      // azione primaria (FAB +), tab attiva
    static let green    = Color(hex: "#28cd41")      // chip IN SYNC (solo stile, non funzione)
    static let stop     = Color(hex: "#ff3b30")      // BLOCKED / distruttivo
    static let ink      = Color(hex: "#11131a")      // glifo "+" scuro su FAB ambra

    static let accent   = amber                      // alias storico (= azione primaria)
}

// MARK: - Header custom (nav-bar nativa nascosta ovunque in Q-Stage)
// Valori CD: altezza 50pt · back JBMono 12 --text2 · crumb JBMono 10 UPPER ls2.5 --text3.
// `sf` = scaleFactor (default 1 per i tab placeholder che non lo calcolano).
struct QStageNavBar: View {
    let backTitle: String
    let onBack: () -> Void
    let crumb: String
    var trailingTitle: String? = nil
    var trailingAction: (() -> Void)? = nil
    var sf: CGFloat = 1

    var body: some View {
        ZStack {
            Text(crumb)
                .font(.jbMono(.medium, size: 10 * sf))
                .tracking(2.5 * sf)
                .foregroundColor(QStageTheme.text3)
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 3 * sf) {
                        Image(systemName: "chevron.left")
                        Text(backTitle)
                    }
                    .font(.jbMono(.medium, size: 12 * sf))
                    .foregroundColor(QStageTheme.text2)
                }
                Spacer()
                if let trailingTitle, let trailingAction {
                    Button(action: trailingAction) {
                        Text(trailingTitle)
                            .font(.jbMono(.bold, size: 15 * sf))
                            .foregroundColor(QStageTheme.accent)
                    }
                } else {
                    Color.clear.frame(width: 24 * sf, height: 1)
                }
            }
        }
        .padding(.horizontal, 16 * sf)
        .frame(height: 50 * sf)
        .background(QStageTheme.bg)
    }
}

// MARK: - Placeholder per le tab non ancora costruite (Shows / Media)
struct QStagePlaceholderTab: View {
    let title: String
    let message: String
    let systemImage: String
    let onExit: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                QStageTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    QStageNavBar(backTitle: "BIVIO", onBack: onExit, crumb: "Q-STAGE")
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: systemImage)
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(QStageTheme.text3)
                        Text(title)
                            .font(.custom("Inter-ExtraBold", size: 20))
                            .foregroundColor(QStageTheme.text)
                        Text(message)
                            .font(.jbMono(.regular, size: 12))
                            .foregroundColor(QStageTheme.text3)
                    }
                    Spacer()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
