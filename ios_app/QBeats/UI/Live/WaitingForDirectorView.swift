import SwiftUI

/// Vista CD-6 (27/05/2026) — Schermata d'attesa Follower Collaborativo.
///
/// Mostrata in LiveView quando `session.playbackState == .waitingForDirector`.
/// Entry: l'utente tappa Play in Vista LIVE con `linkMode == .collaborativa`
/// e nessun Director ha ancora premuto Play cross-device.
///
/// Uscita:
///  - Director attivo → callback Link emette `audioEngine.linkStartedSubject`
///    → LiveView observer chiama `runner.startSetlist(...)` → transizione
///    seamless a `.playing` (questa vista scompare automaticamente).
///  - `START LOCAL` → callback `onStartLocal` → `runner.startSetlist(...)`
///    standalone, ignora l'attesa Director.
///  - `CANCEL` → `dismiss()` (Environment) → UIHostingController dismissato
///    → ritorno a Bivio. Deviazione esplicita da CD-Q2=B "CANCEL → Select
///    Setlist" ratificata da Mauro 28/05/2026 con nota "→ Select Setlist
///    quando F2.3 pronto" (libro mastro v15).
///
/// File presentational puro: nessun `@EnvironmentObject`, le azioni sono
/// iniettate dal parent (LiveView) come callback. Più testabile e isolato.
///
/// Specifica CD-Q2=B ratificata libro mastro v14.
struct WaitingForDirectorView: View {
    let scaleFactor: CGFloat
    let onStartLocal: () -> Void
    @Environment(\.dismiss) private var dismiss

    /// Pulse opacity 1.0 ↔ 0.40, periodo 2.2s (1.1s easeInOut autoreverses).
    /// Avviato al primo `onAppear` e mai fermato — la vista scompare
    /// quando `playbackState` esce da `.waitingForDirector`.
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            Color(hex: "#0e0e10").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("WAITING FOR DIRECTOR…")
                    .font(.jbMono(.bold, size: 22 * scaleFactor))
                    .foregroundColor(Color.white.opacity(0.85))
                    .opacity(pulse ? 0.45 : 1.0)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        onStartLocal()
                    } label: {
                        Text("START LOCAL")
                            .font(.jbMono(.bold, size: 16 * scaleFactor))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color(hex: "#16161a"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        dismiss()
                    } label: {
                        Text("CANCEL")
                            .font(.jbMono(.regular, size: 14 * scaleFactor))
                            .foregroundColor(Color.white.opacity(0.55))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
