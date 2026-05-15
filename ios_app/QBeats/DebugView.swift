#if DEBUG
import SwiftUI
import os

struct DebugView: View {
    @ObservedObject var audioEngine = AudioEngine.shared
    
    // Stato locale per scaffolding (feature non ancora implementate nel Layer 3 bridge)
    @State private var sectionLoopEnabled: Bool = false
    @State private var subdivisionMultiplier: Int = 1

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

                    Button(action: {
                        os_log("[DebugView] Azione: handleStop", log: .default, type: .default)
                        audioEngine.handleStop()
                    }) {
                        Label("STOP", systemImage: "stop.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                    if case let .pausedAwaitingChoice(section, song) = audioEngine.playbackState {
                        Button(action: {
                            os_log("[DebugView] Azione: resumeFromCurrentSection", log: .default, type: .default)
                            audioEngine.resumeFromCurrentSection()
                        }) {
                            Text("Riprendi da \(section.isEmpty ? "sezione" : section)")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        Button(action: {
                            os_log("[DebugView] Azione: restartFromBeginning", log: .default, type: .default)
                            audioEngine.restartFromBeginning()
                        }) {
                            Text("Dall'inizio\(song.isEmpty ? "" : " \(song)")")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.gray)
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

                // --- SUBDIVISION (TEST) ---
                SwiftUI.Section("Subdivision (Test)") {
                    Picker("Suddivisione", selection: $subdivisionMultiplier) {
                        Text("Nessuna (1)").tag(1)
                        Text("Crome (2)").tag(2)
                        Text("Terzine (3)").tag(3)
                        Text("Semicrome (4)").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: subdivisionMultiplier) { newValue in
                        os_log("[DebugView] Subdivision multiplier: %d", log: .default, type: .default, newValue)
                        audioEngine.setSubdivision(multiplier: UInt8(newValue), swingRatio: 0.5)
                    }
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

                // --- MIDI LEARN ---
                SwiftUI.Section("MIDI Learn (Fase 1.6)") {
                    Picker("Azione", selection: Binding(
                        get: { audioEngine.midiLearnPendingAction },
                        set: { _ in }
                    )) {
                        Text("—").tag(Optional<MIDIAction>.none)
                        ForEach(MIDIAction.allCases) { action in
                            Text(action.rawValue).tag(Optional(action))
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(audioEngine.midiLearnPendingAction != nil)

                    ForEach(MIDIAction.allCases) { action in
                        HStack {
                            Text(action.rawValue)
                                .font(.caption)
                            Spacer()
                            if let m = audioEngine.midiLearnStore.mapping(for: action) {
                                Text("\(m.type.rawValue.uppercased()) ch:\(m.channel) #\(m.number)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.green)
                            } else {
                                Text("—")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Button("LEARN") {
                                os_log("[DebugView] MIDI Learn avviato per %{public}@",
                                       log: .default, type: .default, action.rawValue)
                                audioEngine.midiLearnPendingAction = action
                                audioEngine.addLog("LEARN attivo: \(action.rawValue) — premi un controllo")
                            }
                            .buttonStyle(.bordered)
                            .tint(audioEngine.midiLearnPendingAction == action ? .orange : .blue)
                            .disabled(audioEngine.midiLearnPendingAction != nil &&
                                      audioEngine.midiLearnPendingAction != action)

                            Button("✕") {
                                audioEngine.midiLearnStore.removeMapping(for: action)
                                audioEngine.addLog("Mapping rimosso: \(action.rawValue)")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .disabled(audioEngine.midiLearnStore.mapping(for: action) == nil)
                        }
                    }

                    if audioEngine.midiLearnPendingAction != nil {
                        Text("⏳ In attesa di evento MIDI...")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Button("Annulla Learn") {
                            audioEngine.midiLearnPendingAction = nil
                            audioEngine.addLog("Learn annullato")
                        }
                        .buttonStyle(.bordered)
                        .tint(.gray)
                    }
                }

                // --- UX-2 DND REMINDER TEST ---
                SwiftUI.Section("UX-2 DND Reminder") {
                    Button("TEST DND Reminder") {
                        AudioEngine.shared.triggerDNDReminderIfNeeded()
                    }
                }

                // --- TEST BAR COUNTER ---
                #if DEBUG
                SwiftUI.Section("Test Bar Counter") {
                    Button("Sezione A — 8 battute") {
                        audioEngine.loadSection(beatsPerBar: audioEngine.beatsPerBar,
                                                repetitions: 8) { [weak audioEngine] in
                            audioEngine?.sectionEndedSubject.send()
                            audioEngine?.stop()
                        }
                    }
                    Button("Sezione B — 4 battute") {
                        audioEngine.loadSection(beatsPerBar: audioEngine.beatsPerBar,
                                                repetitions: 4) { [weak audioEngine] in
                            audioEngine?.sectionEndedSubject.send()
                            audioEngine?.stop()
                        }
                    }
                    Button("Loop infinito (∞)") {
                        audioEngine.loadSection(beatsPerBar: audioEngine.beatsPerBar,
                                                repetitions: -1) { }
                    }
                    Button("Reset (—)") {
                        audioEngine.loadSection(beatsPerBar: audioEngine.beatsPerBar,
                                                repetitions: 0) { }
                    }
                }
                #endif

                // --- TEST L1.b — Dati di prova ---
                #if DEBUG
                SwiftUI.Section("Test L1.b — Dati di prova") {
                    Text("Popola lo store in RAM con 2 canzoni + 1 setlist. Poi tap LIVE → Play del transport.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Carica dati test L1.b") {
                        loadTestDataL1b()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    Button("Carica dati test L2.b") {
                        loadTestDataL2b()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                #endif

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

    #if DEBUG
    /// Popola QBeatsStore.shared con 2 canzoni + 1 setlist hardcoded per
    /// validazione L1.b multi-section. Nessuna persistenza, solo RAM.
    private func loadTestDataL1b() {
        os_log("[DebugView] Carica dati test L1.b", log: .default, type: .default)

        // Song A — 3 sezioni con cambio BPM e cambio time signature
        let intro  = SongSection(name: "Intro 100",  bpm: 100, beatsPerBar: 4, beatUnit: 4,
                                 repetitions: 12, notes: "", accentPattern: [2,1,1,1],
                                 subdivisionMultiplier: 1, swingRatio: 0.5)
        let verse  = SongSection(name: "Verse 120",  bpm: 120, beatsPerBar: 4, beatUnit: 4,
                                 repetitions: 3,  notes: "", accentPattern: [2,1,1,1],
                                 subdivisionMultiplier: 1, swingRatio: 0.5)
        let bridge = SongSection(name: "Bridge 3/4", bpm: 140, beatsPerBar: 3, beatUnit: 4,
                                 repetitions: 2,  notes: "", accentPattern: [2,1,1],
                                 subdivisionMultiplier: 1, swingRatio: 0.5)
        let songA = Song(id: UUID(), name: "Test Song A",
                         sections: [intro, verse, bridge],
                         countIn: 0, backtrackFilename: nil)

        // Song B — 2 sezioni
        let slow  = SongSection(name: "Slow 90",   bpm: 90,  beatsPerBar: 4, beatUnit: 4,
                                repetitions: 3,  notes: "", accentPattern: [2,1,1,1],
                                subdivisionMultiplier: 1, swingRatio: 0.5)
        let build = SongSection(name: "Build 110", bpm: 110, beatsPerBar: 4, beatUnit: 4,
                                repetitions: 12, notes: "", accentPattern: [2,1,1,1],
                                subdivisionMultiplier: 1, swingRatio: 0.5)
        let songB = Song(id: UUID(), name: "Test Song B",
                         sections: [slow, build],
                         countIn: 0, backtrackFilename: nil)

        // Setlist
        let setlist = Setlist(id: UUID(), name: "Test Setlist L1.b",
                              date: Date(), songIDs: [songA.id, songB.id])

        QBeatsStore.shared.injectTestData(songs: [songA, songB], setlists: [setlist])
    }

    /// Popola QBeatsStore.shared con 1 canzone × 4 sezioni in 4/4 puro per
    /// test Step 2.5 (γ): isolare l'effetto pre-roll del broadcast BPM dal
    /// mismatch quantum (3/4 vs 4/4 di SB). 3 cambi BPM con Δ diversi.
    private func loadTestDataL2b() {
        os_log("[DebugView] Carica dati test L2.b", log: .default, type: .default)

        let s1 = SongSection(name: "Sez 1 — 100", bpm: 100, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 4,  notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s2 = SongSection(name: "Sez 2 — 130", bpm: 130, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 6,  notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s3 = SongSection(name: "Sez 3 — 110", bpm: 110, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 12, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s4 = SongSection(name: "Sez 4 — 140", bpm: 140, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 4,  notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song = Song(id: UUID(), name: "Test Song L2.b",
                        sections: [s1, s2, s3, s4],
                        countIn: 0, backtrackFilename: nil)

        let setlist = Setlist(id: UUID(), name: "Test Setlist L2.b",
                              date: Date(), songIDs: [song.id])

        QBeatsStore.shared.injectTestData(songs: [song], setlists: [setlist])
    }
    #endif
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
