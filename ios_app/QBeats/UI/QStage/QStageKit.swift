import SwiftUI

// MARK: - Token visivi condivisi di Q-Stage
// Coerenti con l'app esistente (#0e0e10 bg, #16161a surface, ambra #f5b820).
// Il fine-tuning al Design System di CD è una passata successiva.
enum QStageTheme {
    static let bg       = Color(hex: "#0e0e10")
    static let surface  = Color(hex: "#16161a")
    static let surface2 = Color(hex: "#1c1c22")
    static let accent   = Color(hex: "#f5b820")   // ambra authoring
    static let text     = Color.white
    static let text2    = Color.white.opacity(0.55)
    static let text3    = Color.white.opacity(0.30)
}

// MARK: - Header custom (nav-bar nativa nascosta ovunque in Q-Stage, stile app)
struct QStageNavBar: View {
    let backTitle: String
    let onBack: () -> Void
    let crumb: String
    var trailingTitle: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Text(crumb)
                .font(.custom("JetBrainsMono-Bold", size: 12))
                .tracking(2)
                .foregroundColor(QStageTheme.text2)
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                        Text(backTitle)
                    }
                    .font(.custom("JetBrainsMono-Medium", size: 13))
                    .foregroundColor(QStageTheme.text2)
                }
                Spacer()
                if let trailingTitle, let trailingAction {
                    Button(action: trailingAction) {
                        Text(trailingTitle)
                            .font(.custom("JetBrainsMono-Bold", size: 15))
                            .foregroundColor(QStageTheme.accent)
                    }
                } else {
                    Color.clear.frame(width: 24, height: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(QStageTheme.bg)
    }
}

// MARK: - Placeholder per le tab non ancora costruite (Shows / Media nella prima fetta)
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
                            .font(.custom("JetBrainsMono-Bold", size: 20))
                            .foregroundColor(QStageTheme.text)
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundColor(QStageTheme.text3)
                    }
                    Spacer()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
