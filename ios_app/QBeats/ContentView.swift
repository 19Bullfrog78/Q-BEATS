import SwiftUI
import os

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    @State private var bpm: Double = 120.0
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

            Text("\(Int(bpm)) BPM")
                .font(.system(size: 48, weight: .thin, design: .monospaced))

            Text("Click: \(audioEngine.clickStatus)")
                .font(.caption)
                .foregroundColor(.yellow)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Slider(value: $bpm, in: 40...240, step: 1)
                .padding(.horizontal, 32)
                .onChange(of: bpm) { newBPM in
                    audioEngine.setBPM(newBPM)
                }

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

            // MIDI Debug Log — temporaneo, Blocco 4A
            if let debugVM = audioEngine.midiDebugViewModel {
                MIDIDebugView(viewModel: debugVM)
            }
        }
        .padding()
        .toolbar {
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

struct MIDIDebugView: View {
    @ObservedObject var viewModel: MIDIDebugViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("MIDI IN")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                // [NUOVO] Bottone Bluetooth LE MIDI
                Button("BT MIDI") {
                    os_log("[Q-BEATS][BT] Apertura picker CABTMIDICentralViewController", type: .info)
                    viewModel.showBTMIDIPicker = true
                }
                .font(.caption)
                .padding(.trailing, 8)
                
                Button("Clear") { viewModel.clear() }
                    .font(.caption)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.entries) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(entry.timestamp)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Text(entry.decoded)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            .id(entry.id)
                        }
                    }
                }
                .frame(height: 160)
                .background(Color.black.opacity(0.8))
                .cornerRadius(8)
                .onChange(of: viewModel.entries.count) { _ in
                    if let last = viewModel.entries.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $viewModel.showBTMIDIPicker, onDismiss: {
            os_log("[Q-BEATS][BT] Picker chiuso — avvio scanAndConnectPhysicalPorts ottimistico", type: .info)
            // Nota: Il riferimento all'engine è gestito tramite AudioEngine che chiama il bridge C
        }) {
            BTMIDICentralPickerView()
        }
    }
}