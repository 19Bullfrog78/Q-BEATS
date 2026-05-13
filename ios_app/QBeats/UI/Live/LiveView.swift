import SwiftUI
import os

struct LiveView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var runner: SetlistRunner
    @StateObject private var session = LiveSession()
    // P2 — Finestra "fade post-sezione naturale": acceso fra l'autostop L1.a e
    // lo spegnimento sincronizzato di segmento+LED, durata = un beat al BPM corrente.
    @State private var sectionHold: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#0e0e10").ignoresSafeArea(.all)

                let isStandby: Bool = {
                    if case .standby = session.playbackState { return true }
                    return false
                }()

                VStack(spacing: 0) {
                    LiveHeaderView(session: session)
                        .frame(height: geo.size.height * 0.08)
                    MetSlotStripView(pattern: accentPatternToStrings(audioEngine.currentAccentPattern), beatActive: session.beatActive)
                        .frame(height: geo.size.height * 0.10)
                    BarCounterView(current: session.currentBar, total: session.totalBarsInSection, state: session.playbackState)
                        .frame(height: geo.size.height * 0.08)
                    MicroSegBarView(current: session.currentBar, total: session.totalBarsInSection, state: session.playbackState, sectionHold: sectionHold)
                        .frame(height: geo.size.height * 0.04)
                    VStack(spacing: 0) {
                        TeleprompterCapsuleView(session: session)
                            .frame(height: geo.size.height * 0.35)
                        MacroBarView(current: session.macroBarCurrent, total: session.macroBarTotal, state: session.playbackState)
                            .frame(height: geo.size.height * 0.02)
                        POIView(nextSection: session.nextSectionName, nextSong: session.nextSongName)
                            .frame(height: geo.size.height * 0.10)
                        HandleStripView()
                            .frame(height: geo.size.height * 0.02)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onEnded { value in
                                if value.translation.height > 15 {
                                    session.showMixer = true
                                }
                            }
                    )
                    TransportView(session: session, audioEngine: audioEngine)
                        .frame(height: geo.size.height * 0.21)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .opacity(isStandby ? 0.10 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isStandby)

                if case .standby(let nextSong) = session.playbackState {
                    StandbyOverlayView(nextSongName: nextSong)
                        .onTapGesture {
                            runner.startCurrentSong(audioEngine: audioEngine, session: session)
                        }
                }

                if case .overlayStop(let sec, let song) = session.playbackState {
                    OverlayStopView(sectionName: sec, songName: song, audioEngine: audioEngine)
                }

                if case .fineSetlist = session.playbackState {
                    FineSetlistView()
                }

                VStack(spacing: 0) {
                    Spacer()
                    if session.showMixer {
                        Color.clear
                            .frame(height: geo.size.height * 0.49)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                session.showMixer = false
                            }
                        MixerOverlayView(session: session, audioEngine: audioEngine)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(session.showMixer)

            }
        }
        .onDisappear { audioEngine.stop() }
        // MARK: - AudioEngine → LiveSession sync
        .onReceive(audioEngine.$playbackState) { state in
            switch state {
            case .stopped:
                // L1.b: il runner gestisce .standby e .fineSetlist impostando
                // session.playbackState PRIMA di chiamare audioEngine.stop().
                // Lo stop() dispatcha .stopped su main qualche ms dopo —
                // NON sovrascrivere stati già impostati dal runner.
                switch session.playbackState {
                case .standby, .fineSetlist:
                    return
                default:
                    break
                }
                session.playbackState = .stopped
                // P2 sync stop manuale: spegnimento all'unisono LED+trattini.
                // Se sectionHold=false → stop manuale (o overlay) → reset beatActive
                // subito (LED metronomo si spegne insieme ai trattini gia gestiti
                // dal gate state==.playing in MicroSegBarView).
                // Se sectionHold=true → autostop in corso → NON toccare beatActive:
                // ci pensa l'asyncAfter di sectionEndedSubject a fare il reset
                // sincronizzato dopo durata-beat (mantiene il fade di ~500ms).
                // Ordine eventi su main: sectionEndedSubject.send() viene processato
                // PRIMA di playbackState=.stopped (dispatch async successivo dalla
                // stop()), quindi quando arrivo qui sectionHold e' gia' true se
                // siamo in autostop.
                if !sectionHold {
                    session.beatActive = 0
                }
            case .countIn:
                session.playbackState = .countIn(countdown: 4)
            case .playing:
                session.playbackState = .playing
                // P2: chiusura della finestra fade se l'utente preme Play durante
                // i ~500ms post-autostop (asyncAfter pendente sara' poi no-op via guard).
                sectionHold = false
            case .pausedAwaitingChoice(let sec, let song):
                session.playbackState = .overlayStop(sectionName: sec, songName: song)
                session.beatActive = 0
                sectionHold = false
            }
            session.currentSongName = audioEngine.currentSong ?? ""
            session.currentSectionName = audioEngine.currentSection ?? ""
        }
        .onReceive(audioEngine.$currentBPM) { bpm in
            session.currentBPM = bpm
        }
        .onReceive(audioEngine.$beatsPerBar) { beats in
            session.currentTimeSig = timeSigString(for: beats)
        }
        .onReceive(audioEngine.$currentSectionRepetitions) { reps in
            session.totalBarsInSection = reps
        }
        .onReceive(audioEngine.beatTickSubject) { tickN in
            let bpb = max(1, Int(audioEngine.beatsPerBar))
            session.beatActive = ((tickN - 1) % bpb) + 1
            session.currentBar = ((tickN - 1) / bpb) + 1
            session.macroBarCurrent = session.currentBar
        }
        .onReceive(audioEngine.$audioMode) { mode in
            session.isProMode = mode == .pro
        }
        // P2 — Fade SINCRONIZZATO segmento+LED a fine sezione NATURALE (autostop L1.a).
        // sectionHold=true tiene acceso il segmento durante la finestra di fade
        // (override del gate state==.playing). Dopo durata-beat al BPM corrente,
        // sectionHold=false E beatActive=0 dispatchati nello stesso istante:
        // segmento e LED si spengono INSIEME, esattamente quello che serve a fine
        // sezione naturale ("metronomo e segmento si comportano insieme").
        // Stop manuale: NON emette il subject — segmento si spegne subito al
        // .stopped (Test 4 verde) e LED resta da TD#10.
        // Guard su .stopped: se l'utente preme Play durante il fade, lo switch
        // su .playing ha gia' resettato sectionHold; questo asyncAfter diventa
        // un no-op silenzioso.
        .onReceive(audioEngine.sectionEndedSubject) { _ in
            sectionHold = true
            let beatDurationSeconds = 60.0 / max(audioEngine.currentBPM, 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + beatDurationSeconds) {
                if case .stopped = session.playbackState {
                    sectionHold = false
                    session.beatActive = 0
                }
            }
        }
    }

    private func accentPatternToStrings(_ pattern: [UInt8]) -> [String] {
        pattern.map { value in
            switch value {
            case 2:  return "accent"
            case 1:  return "beat"
            default: return "subdiv"
            }
        }
    }

    private func timeSigString(for beats: UInt32) -> String {
        let denom: UInt32 = (beats == 6 || beats == 12) ? 8 : 4
        return "\(beats)/\(denom)"
    }


}

private struct HandleStripView: View {
    var body: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white.opacity(0.20))
                .frame(width: 32, height: 3)
            Spacer()
        }
    }
}
