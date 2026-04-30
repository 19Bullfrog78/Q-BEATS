#if DEBUG
import SwiftUI
import os

struct DebugView: View {
    @ObservedObject var audioEngine = AudioEngine.shared
    
    // Stato locale per scaffolding (feature non ancora implementate nel Layer 3 bridge)
    @State private var sectionLoopEnabled: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // --- INFO HARDWARE ---
                SwiftUI.Section("Stato Hardware") {
                    HStack {
                        Text("Modalità:")
                        Spacer()
                        Text(audioEngine.audioMode == .pro ? "PRO" : "BASE")
                            .bold()
                            .foregroundColor(audioEngine.audioMode == .pro ? .green : .orange)
                    }
                    HStack {
                        Text("Sample Rate:")
                        Spacer()
                        Text("\(Int(audioEngine.sampleRateInfo)) Hz")
                    }
                    HStack {
                        Text("Beat Corrente:")
                        Spacer()
                        Text(String(format: "%.2f", audioEngine.currentBeat))
                            .monospacedDigit()
                    }
                    HStack {
                        Text("BPM:")
                        Spacer()
                        Text("\(Int(audioEngine.currentBPM))")
                            .monospacedDigit()
                    }
                }

                // --- CONTROLLI MOTORE ---
                SwiftUI.Section("Controlli Motore") {
                    HStack {
                        Button(action: { 
                            os_log("[DebugView] Azione: Play", log: .default, type: .default)
                            audioEngine.start() 
                        }) {
                            Label("Play", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(audioEngine.isPlaying)

                        Spacer()

                        Button(action: { 
                            os_log("[DebugView] Azione: Stop", log: .default, type: .default)
                            audioEngine.stop() 
                        }) {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(!audioEngine.isPlaying)
                    }

                    Button(role: .destructive, action: { 
                        os_log("[DebugView] Azione: STOP EMERGENZA", log: .default, type: .error)
                        audioEngine.stopBacktrack()
                        audioEngine.stop()
                    }) {
                        Label("STOP EMERGENZA", systemImage: "exclamationmark.octagon.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                // --- MIXER 4 CANALI ---
                SwiftUI.Section("Mixer (Fase 1.4)") {
                    VolumeSlider(label: "Ch1 - Click", channelIndex: 1, audioEngine: audioEngine)
                    VolumeSlider(label: "Ch2 - Backtrack", channelIndex: 2, audioEngine: audioEngine)
                    
                    Group {
                        VolumeSlider(label: "Ch3 - Guide", channelIndex: 3, audioEngine: audioEngine)
                        VolumeSlider(label: "Ch4 - FX", channelIndex: 4, audioEngine: audioEngine)
                    }
                    .disabled(audioEngine.audioMode == .base)
                    .opacity(audioEngine.audioMode == .base ? 0.5 : 1.0)
                }

                // --- Sezione VOL ---
                SwiftUI.Section {
                    Text("CLICK VOLUMES").font(.caption).foregroundColor(.gray)
                    
                    HStack {
                        Text("Accent")
                        Slider(value: $audioEngine.appSettings.accentVolume, in: 0...1)
                    }
                    
                    HStack {
                        Text("Beat")
                        Slider(value: $audioEngine.appSettings.beatVolume, in: 0...1)
                    }
                    
                    HStack {
                        Text("Subdiv")
                        Slider(value: $audioEngine.appSettings.subdivVolume, in: 0...1)
                    }
                    
                    Toggle("Mute Click", isOn: $audioEngine.appSettings.clickMuted)
                }

                // --- TOGGLES ---
                SwiftUI.Section("Impostazioni") {
                    Toggle("Ableton Link", isOn: Binding(
                        get: { audioEngine.linkEnabled },
                        set: { 
                            os_log("[DebugView] Azione: Toggle Link %{public}@", log: .default, type: .default, $0 ? "ON" : "OFF")
                            audioEngine.setLinkEnabled($0) 
                        }
                    ))
                    
                    Toggle("Loop Sezione", isOn: Binding(
                        get: { sectionLoopEnabled },
                        set: { 
                            os_log("[DebugView] Azione: Toggle Loop Sezione %{public}@", log: .default, type: .default, $0 ? "ON" : "OFF")
                            sectionLoopEnabled = $0 
                        }
                    ))
                }

                // --- BACKTRACK ---
                SwiftUI.Section("Backtrack (Fase 1.3)") {
                    Button("Arm Test Backtrack") {
                        os_log("[DebugView] Azione: Arm Test Backtrack", log: .default, type: .default)
                        if let url = Bundle.main.url(forResource: "test_backtrack", withExtension: "mp3") {
                            audioEngine.armBacktrack(url: url)
                            audioEngine.addLog("Arming test_backtrack.mp3")
                        } else {
                            os_log("[DebugView] ERRORE: test_backtrack.mp3 non trovato", log: .default, type: .error)
                            audioEngine.addLog("ERRORE: file mancante")
                        }
                    }
                    
                    HStack {
                        Button("Play BT") {
                            os_log("[DebugView] Azione: Play Backtrack", log: .default, type: .default)
                            audioEngine.playBacktrack()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Disarm") {
                            os_log("[DebugView] Azione: Disarm Backtrack", log: .default, type: .default)
                            audioEngine.disarmBacktrack()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }

                // --- LOG DI SISTEMA ---
                SwiftUI.Section("Log Eventi (Ultimi 10)") {
                    ForEach(audioEngine.debugLogs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption2, design: .monospaced))
                            .lineLimit(2)
                    }
                }
            }
            .navigationTitle("Debug Scaffolding")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct VolumeSlider: View {
    let label: String
    let channelIndex: Int
    @ObservedObject var audioEngine: AudioEngine

    var body: some View {
        VStack(alignment: .leading) {
            let volume = (channelIndex > 0 && channelIndex <= audioEngine.channelVolumes.count) ? audioEngine.channelVolumes[channelIndex - 1] : 0.0
            
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(volume * 100))%")
                    .font(.caption.monospacedDigit())
            }
            Slider(value: Binding(
                get: { volume },
                set: { 
                    os_log("[DebugView] Azione: Volume Ch%d = %f", log: .default, type: .default, channelIndex, $0)
                    audioEngine.setChannelVolume(channelIndex, volume: $0) 
                }
            ), in: 0...1)
        }
        .padding(.vertical, 4)
    }
}

struct DebugToolbarModifier: ViewModifier {
    @State private var showDebug = false
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showDebug = true } label: {
                        Image(systemName: "ladybug").foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showDebug) { DebugView() }
    }
}
#endif
