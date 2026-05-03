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
                    MetSlotStripView(pattern: session.accentPattern, beatActive: session.beatActive)
                        .frame(height: geo.size.height * 0.10)
                    BarCounterView(current: session.currentBar, total: session.totalBarsInSection, state: session.playbackState)
                        .frame(height: geo.size.height * 0.08)
                    MicroSegBarView(current: session.currentBar, total: session.totalBarsInSection)
                        .frame(height: geo.size.height * 0.04)
                    TeleprompterCapsuleView(session: session)
                        .frame(height: geo.size.height * 0.35)
                    MacroBarView(current: session.macroBarCurrent, total: session.macroBarTotal, state: session.playbackState)
                        .frame(height: geo.size.height * 0.04)
                    POIView(nextSection: session.nextSectionName, nextSong: session.nextSongName)
                        .frame(height: geo.size.height * 0.10)
                    TransportView(session: session, audioEngine: audioEngine)
                        .frame(height: geo.size.height * 0.21)
                }
                .frame(width: geo.size.width, height: geo.size.height)
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
                }

                Rectangle()
                    .fill(Color.red.opacity(0.3))
                    .ignoresSafeArea(.all)
            }
        }
        .ignoresSafeArea(.all)
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
            session.accentPattern = buildAccentPattern(beatsPerBar: beats)
            session.totalBarsInSection = Int(beats)
        }
        .onReceive(audioEngine.$currentBeat) { beat in
            guard case .playing = session.playbackState else { return }
            let bpb = max(1.0, Double(audioEngine.beatsPerBar))
            session.beatActive = Int(beat.truncatingRemainder(dividingBy: bpb)) + 1
            session.currentBar = Int(beat / bpb) + 1
            session.macroBarCurrent = session.currentBar
        }
        .onReceive(audioEngine.$audioMode) { mode in
            session.isProMode = mode == .pro
        }
        .onReceive(audioEngine.$isPlaying) { playing in
            if !playing { session.beatActive = 0 }
        }
    }

    private func timeSigString(for beats: UInt32) -> String {
        let denom: UInt32 = (beats == 6 || beats == 12) ? 8 : 4
        return "\(beats)/\(denom)"
    }

    private func buildAccentPattern(beatsPerBar: UInt32) -> [String] {
        guard beatsPerBar > 0 else { return ["accent"] }
        return (0..<Int(beatsPerBar)).map { $0 == 0 ? "accent" : "beat" }
    }
}
