import SwiftUI
import os

/// Home (ex Bivio) — trivio top-level Q-STUDIO · Q-STAGE · Q-LIVE.
/// Grafica CD (kit Home v2, 28/06): blu notte #0c1024 · terna accenti per-modulo (§3.4 DS) ·
/// nomi-porta Inter ExtraBold (estensione §4.1) · resto JetBrains Mono ·
/// scaleFactor = geo.size.width / 390 (pattern Vista Live · LiveView.swift, blocco `scaleFactor` TD #23 — per SIMBOLO).
/// Q-Studio = porta COMING SOON (non interattiva). Q-Live = in-tree via screen-swap (Nodo A completo, N1b).
struct HomeRootView: View {
    let onOpenQStage: () -> Void
    /// Nodo A N1b — porta Q-Live: fornito da AppRootView (`{ screen = .qLive }`),
    /// specchio di `onOpenQStage`. Entry-point canonico unico verso `.qLive`.
    let onOpenQLive: () -> Void
    @EnvironmentObject var audioEngine: AudioEngine
    #if DEBUG
    @State private var showDebug = false
    #endif

    var body: some View {
        GeometryReader { geo in
            // TD-ipad-home: iPhone INVARIATO (sf = width/390). Su iPad la sola larghezza
            // dà sf enormi (12.9" portrait ≈ 2.63) → Home in overflow verticale; quindi su
            // iPad si limita anche con l'altezza (baseline 844 pt, margine ~8%). Il gating
            // .pad evita di rimpicciolire iPhone tozzi (SE/8, ratio < 2.16).
            let sf = UIDevice.current.userInterfaceIdiom == .pad
                ? min(geo.size.width / 390, geo.size.height * 0.92 / 844)
                : geo.size.width / 390
            ZStack {
                QStageTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    WordmarkLockup(sf: sf)
                        .padding(.top, 46 * sf)
                    Spacer(minLength: 0)
                    doors(sf)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 22 * sf)
            }
            #if DEBUG
            .overlay(alignment: .bottom) { debugEntry(sf) }
            #endif
        }
        .onAppear { audioEngine.stop() }
        .toolbar(.hidden, for: .navigationBar)
        #if DEBUG
        .fullScreenCover(isPresented: $showDebug, onDismiss: { audioEngine.stop() }) {
            ZStack(alignment: .topTrailing) {
                ContentView()
                Button("✕  HOME") { showDebug = false }
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.40))
                    .padding(.top, 60)
                    .padding(.trailing, 20)
            }
        }
        #endif
    }

    // Le 3 porte — ordine ratificato Studio · Stage · Live, gap 14, gruppo centrato.
    private func doors(_ sf: CGFloat) -> some View {
        VStack(spacing: 14 * sf) {
            ModeDoorCard(kick: "PRACTICE", title: "Q-STUDIO",
                         subtitle: "Rehearse freely — no stage gate",
                         accent: QStageTheme.teal, accentTint: QStageTheme.tealTint,
                         state: .comingSoon, sf: sf)
            ModeDoorCard(kick: "BUILD", title: "Q-STAGE",
                         subtitle: "Songs & Shows — prepare the set",
                         accent: QStageTheme.blue, accentTint: QStageTheme.blueTint,
                         state: .active, sf: sf,
                         action: { os_log("Home: Q-STAGE selezionato"); onOpenQStage() })
            ModeDoorCard(kick: "PERFORM", title: "Q-LIVE",
                         subtitle: "Choose a Show and take the stage",
                         accent: QStageTheme.orange, accentTint: QStageTheme.orangeTint,
                         state: .active, sf: sf,
                         action: { os_log("Home: Q-LIVE selezionato"); onOpenQLive() })
        }
    }

    #if DEBUG
    // Ingresso DEBUG → ContentView → ⚙ Settings (UNICO ingresso Settings, solo DEBUG; ticket v21).
    private func debugEntry(_ sf: CGFloat) -> some View {
        Button("⚙ DEBUG") { showDebug = true }
            .foregroundColor(Color.white.opacity(0.30))
            .font(.system(size: 13, design: .monospaced))
            .padding(.bottom, 8 * sf)
    }
    #endif
}

// MARK: - Lockup di testa (wordmark + equalizer + tagline)
private struct WordmarkLockup: View {
    let sf: CGFloat
    var body: some View {
        VStack(spacing: 0) {
            Text("Q-BEATS")
                .font(.jbMono(.bold, size: 30 * sf))
                .tracking(6 * sf)
                .foregroundColor(QStageTheme.text)
            EqualizerMark(sf: sf)
                .padding(.vertical, 15 * sf)
            Text("LIVE · IN SYNC")
                .font(.jbMono(.regular, size: 10 * sf))
                .tracking(3.5 * sf)
                .foregroundColor(QStageTheme.text3)
        }
    }
}

// MARK: - Equalizer statico (7 barre, la 3ª = spark ambra — ratificato Mauro)
private struct EqualizerMark: View {
    let sf: CGFloat
    private let heights: [CGFloat] = [9, 16, 25, 14, 22, 11, 17]
    var body: some View {
        HStack(alignment: .bottom, spacing: 5 * sf) {
            ForEach(heights.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2 * sf, style: .continuous)
                    .fill(i == 2 ? QStageTheme.amber : Color.white.opacity(0.18))
                    .frame(width: 3 * sf, height: heights[i] * sf)
            }
        }
        .frame(height: 25 * sf)
    }
}

// MARK: - Porta-modalità (riusabile ×3)
private enum DoorState { case active, comingSoon }

private struct ModeDoorCard: View {
    let kick: String
    let title: String
    let subtitle: String
    let accent: Color
    let accentTint: Color
    let state: DoorState
    let sf: CGFloat
    var action: (() -> Void)? = nil

    var body: some View {
        if state == .active {
            Button(action: { action?() }) { card }.buttonStyle(.plain)
        } else {
            card   // COMING SOON: non tappabile
        }
    }

    private var card: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(kick)
                    .font(.jbMono(.semibold, size: 10 * sf))
                    .tracking(2.5 * sf)
                    .foregroundColor(state == .comingSoon ? accentTint.opacity(0.65) : accentTint)
                Text(title)
                    .font(.custom("Inter-ExtraBold", size: 25 * sf))
                    .tracking(-0.5 * sf)
                    .foregroundColor(state == .comingSoon ? QStageTheme.text.opacity(0.5) : QStageTheme.text)
                    .padding(.top, 7 * sf)
                    .padding(.bottom, 5 * sf)
                Text(subtitle)
                    .font(.jbMono(.regular, size: 11 * sf))
                    .tracking(0.2 * sf)
                    .foregroundColor(state == .comingSoon ? QStageTheme.text3 : QStageTheme.text2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22 * sf)
            .padding(.vertical, 21 * sf)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 115 * sf)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 22 * sf, style: .continuous))
        .overlay(border)
        .overlay(alignment: .trailing) { if state == .active { chevron } }
        .overlay(alignment: .topTrailing) { if state == .comingSoon { comingSoonTag } }
    }

    @ViewBuilder private var background: some View {
        if state == .active {
            // CD mock 150° → resa SwiftUI corner-to-corner ≈135° (come FAB). Stage end 0.045≈0.05 unificato.
            LinearGradient(colors: [accent.opacity(0.20), accent.opacity(0.05)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            Color.clear
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 22 * sf, style: .continuous)
            .strokeBorder(state == .comingSoon ? Color.white.opacity(0.16) : QStageTheme.line2,
                          style: state == .comingSoon
                              ? StrokeStyle(lineWidth: 1, dash: [4 * sf, 4 * sf])
                              : StrokeStyle(lineWidth: 1))
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 18 * sf, weight: .semibold))   // ≈20×20 sw2.2 (approssimato dal peso SF)
            .foregroundColor(accentTint)
            .padding(.trailing, 20 * sf)
    }

    private var comingSoonTag: some View {
        HStack(spacing: 6 * sf) {
            Image(systemName: "clock").font(.system(size: 9 * sf, weight: .semibold))
            Text("COMING SOON").font(.jbMono(.bold, size: 9 * sf)).tracking(1.5 * sf)
        }
        .foregroundColor(QStageTheme.tealTint)
        .padding(.horizontal, 9 * sf).padding(.vertical, 4 * sf)
        .background(QStageTheme.teal.opacity(0.10), in: RoundedRectangle(cornerRadius: 7 * sf, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 7 * sf, style: .continuous)
            .strokeBorder(QStageTheme.teal.opacity(0.28), lineWidth: 1))
        .padding(.top, 16 * sf).padding(.trailing, 16 * sf)
    }
}
