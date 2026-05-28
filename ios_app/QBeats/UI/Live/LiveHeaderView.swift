import SwiftUI

struct LiveHeaderView: View {
    @ObservedObject var session: LiveSession
    @EnvironmentObject var audioEngine: AudioEngine
    @Environment(\.dismiss) private var dismiss

    /// TD #23 (17/05/2026) — fattore di scala per font responsive iPad v1.
    /// Calcolato in `LiveView` come `geo.size.width / 390` (baseline iPhone 13
    /// portrait misurata empiricamente). Propagato come parametro esplicito.
    /// Tutti gli 8 `.font(...)` di questo file moltiplicano la loro size in pt
    /// per questo fattore.
    let scaleFactor: CGFloat

    /// Badge HEAD CD-Q1=B (libro mastro v14) — `"FOLLOWER"` / `"DIRECTOR"` /
    /// `nil` (Link disabilitato → nessun badge). Calcolato in LiveView dal
    /// mirror `@Published audioEngine.linkMode` + `audioEngine.linkEnabled`.
    /// LiveHeaderView resta presentational: nessuna logica di mode-mapping
    /// qui, solo render del testo se non-nil.
    let linkRoleBadge: String?

    var body: some View {
        HStack(spacing: 8) {

            // ── Back button ──
            Button { dismiss() } label: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.09), lineWidth: 1)
                    )
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12 * scaleFactor, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.65))
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            // ── Centro: song name · BPM [lock] · time sig ──
            HStack(spacing: 6) {
                Text(session.currentSongName)
                    .font(.jbMono(.bold, size: 28 * scaleFactor))
                    .foregroundColor(Color.white.opacity(0.95))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("·")
                    .foregroundColor(Color.white.opacity(0.20))
                    .font(.system(size: 13 * scaleFactor))

                HStack(spacing: 3) {
                    Text("\(Int(session.currentBPM.rounded()))")
                        .font(.jbMono(.regular, size: 17 * scaleFactor))
                        .foregroundColor(Color.white.opacity(0.50))

                    if session.isBacktrackLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9 * scaleFactor))
                            .foregroundColor(Color.white.opacity(0.35))
                    }
                }

                Text("·")
                    .foregroundColor(Color.white.opacity(0.20))
                    .font(.system(size: 13 * scaleFactor))

                Text(session.currentTimeSig)
                    .font(.jbMono(.regular, size: 15 * scaleFactor))
                    .foregroundColor(Color.white.opacity(0.50))
            }

            Spacer()

            // ── LED status: Link · BT · WiFi ──
            // Visibili SOLO se connessione attiva. Spento = non renderizzato.
            HStack(spacing: 4) {
                // CD-Q1=B (libro mastro v14, 27/05/2026) — Badge HEAD persistente
                // FOLLOWER/DIRECTOR. Render solo se non-nil (Link enabled).
                // Caveat R3-α: in Fase 6-7 implementiamo solo il badge; il
                // counter offset "bar 2 di N" (Bug 2.b) è rimandato a
                // Fase 6-7-bis. Ratifica CD-Q1=B nel libro mastro resta
                // target di design completo, no comunicazione CD ora.
                if let role = linkRoleBadge {
                    Text(role)
                        .font(.jbMono(.regular, size: 12 * scaleFactor))
                        .foregroundColor(Color.white.opacity(0.55))
                        .padding(.trailing, 4)
                }
                if audioEngine.linkIsConnected {
                    Circle()
                        .fill(Color(hex: "#00c96e"))
                        .frame(width: 5, height: 5)
                        .shadow(color: Color(hex: "#00c96e"), radius: 3)
                }
                // STEP 2: sostituire false con audioEngine.bleMIDIConnected
                if false {
                    Circle()
                        .fill(Color(hex: "#2a6bd6"))
                        .frame(width: 5, height: 5)
                        .shadow(color: Color(hex: "#2a6bd6"), radius: 3)
                }
                // STEP 2: sostituire false con audioEngine.networkMIDIActive
                if false {
                    Circle()
                        .fill(Color(hex: "#f5b820"))
                        .frame(width: 5, height: 5)
                        .shadow(color: Color(hex: "#f5b820"), radius: 3)
                }
            }

            // ── Mute click button ──
            // Attivo: speaker.wave.2.fill bianco — Muto: speaker.slash.fill ambra
            // Toggle clickMuted → applySettings → metronome_set_muted su audioQueue
            let isMuted = audioEngine.appSettings.clickMuted
            Button {
                audioEngine.appSettings.clickMuted.toggle()
            } label: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 13 * scaleFactor))
                            .foregroundColor(
                                isMuted
                                    ? Color(hex: "#f5b820")
                                    : Color.white.opacity(0.85)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }
}
