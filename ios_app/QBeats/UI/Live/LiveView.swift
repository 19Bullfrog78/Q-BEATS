import SwiftUI
import os

struct LiveView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @StateObject private var session = LiveSession()

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
                    MicroSegBarView(current: session.currentBar, total: session.totalBarsInSection)
                        .frame(height: geo.size.height * 0.04)
                    TeleprompterCapsuleView(session: session)
                        .frame(height: geo.size.height * 0.35)
                    MacroBarView(current: session.macroBarCurrent, total: session.macroBarTotal, state: session.playbackState)
                        .frame(height: geo.size.height * 0.02)
                    POIView(nextSection: session.nextSectionName, nextSong: session.nextSongName)
                        .frame(height: geo.size.height * 0.10)
                    HandleStripView()
                        .frame(height: geo.size.height * 0.02)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onEnded { value in
                                    if value.translation.height > 15 {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            session.showMixer = true
                                        }
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
                        .onTapGesture { audioEngine.start() }
                }

                if case .overlayStop(let sec, let song) = session.playbackState {
                    OverlayStopView(sectionName: sec, songName: song, audioEngine: audioEngine)
                }

                if case .fineSetlist = session.playbackState {
                    FineSetlistView()
                }

                if session.showMixer {
                    MixerOverlayView(session: session, audioEngine: audioEngine)
                        .transition(.move(edge: .top))
                }

            }
        }
        .onDisappear { audioEngine.stop() }
        // MARK: - AudioEngine → LiveSession sync
        .onReceive(audioEngine.$playbackState) { state in
            switch state {
            case .stopped:
                session.playbackState = .stopped
                session.beatActive = 0
            case .countIn:
                session.playbackState = .countIn(countdown: 4)
            case .playing:
                session.playbackState = .playing
            case .pausedAwaitingChoice(let sec, let song):
                session.playbackState = .overlayStop(sectionName: sec, songName: song)
                session.beatActive = 0
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
        .onReceive(audioEngine.$isPlaying) { playing in
            if !playing { session.beatActive = 0 }
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
