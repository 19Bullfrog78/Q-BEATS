import SwiftUI
import os

struct ContentView: View {
    // === MODIFICATO 6A ===
    // === PLACEHOLDER 6E Ableton Link ===
    // Quando Link è enabled, presentare ABLLinkSettingsViewController 
    // per conformità Ableton. Aggiungere import nel bridging header se necessario:
    // #include "ABLLinkSettingsViewController.h"

    @StateObject private var audioEngine = AudioEngine()
    @State private var showSettings = false

    private let timeSignatures: [(label: String, beats: UInt32)] = [
        ("2/4", 2), ("3/4", 3), ("4/4", 4),
        ("5/4", 5), ("6/8", 6), ("7/8", 7), ("12/8", 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Q-Beats")
                .font(.largeTitle)
                .bold()

            Text("\(Int(audioEngine.currentBPM.rounded())) BPM")
                .font(.system(size: 48, weight: .thin, design: .monospaced))

            Text("Click: \(audioEngine.clickStatus)")
                .font(.caption)
                .foregroundColor(.yellow)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Slider(value: $audioEngine.currentBPM, in: 40...240, step: 1) { isEditing in
                if !isEditing {
                    audioEngine.setBPM(audioEngine.currentBPM)
                }
            }
            .padding(.horizontal, 32)

            VStack(spacing: 8) {
                Text("Time Signature")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Time Signature", selection: $audioEngine.beatsPerBar) {
                    ForEach(timeSignatures, id: \.beats) { sig in
                        Text(sig.label).tag(sig.beats)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)
                .onChange(of: audioEngine.beatsPerBar) { newVal in
                    audioEngine.setBeatsPerBar(newVal)
                }
            }

            Button(action: {
                if audioEngine.isPlaying {
                    audioEngine.stop()
                } else {
                    audioEngine.start()
                }
            }) {
                Text(audioEngine.isPlaying ? "Stop" : "Start")
                    .font(.title2)
                    .bold()
                    .frame(width: 120, height: 120)
                    .background(audioEngine.isPlaying ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }


        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if audioEngine.linkEnabled {
                    Text(audioEngine.linkIsConnected ? "● Link" : "○ Link")
                        .font(.caption)
                        .foregroundColor(audioEngine.linkIsConnected ? .green : .secondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(audioEngine: audioEngine)
        }
        }
    }
}
