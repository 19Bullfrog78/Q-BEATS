#if DEBUG
import SwiftUI
import os
import UniformTypeIdentifiers

struct DebugView: View {
    @ObservedObject var audioEngine = AudioEngine.shared
    
    // Stato locale per scaffolding (feature non ancora implementate nel Layer 3 bridge)
    @State private var sectionLoopEnabled: Bool = false
    @State private var subdivisionMultiplier: Int = 1

    // --- Backup / Restore (.qbeats) — strumenti di TEST device (B7-A5c) ---
    // Gli ingressi export/import sono assenti dall'UI di produzione (BackupView
    // orfana; import solo via onOpenURL — TD-backup-restore-no-ui, BUGS §1.3):
    // questi 2 pulsanti danno un round-trip REALE sul device (export → "Salva
    // su File" → re-import) per esercitare il restore A5c-2 su dati veri
    // (collisione id al re-import → ricostruzione Song duplicata, riga :219).
    // Solo #if DEBUG: nessun impatto sulla build di produzione.
    // Presentazione UNIFICATA item-driven (fix bug "foglio bianco" 05/07):
    // un solo .sheet(item:) ancorato al CONTENITORE (List), non alle righe —
    // le righe di un List sono riciclate/lazy e i modifier di presentazione
    // attaccati lì non si presentano in modo affidabile (foglio vuoto). Un
    // solo sheet elimina anche la competizione fra due .sheet(isPresented:)
    // (il "si sblocca alternando export/import"). enum = quale schermata.
    private enum ActiveModal: Identifiable {
        case export(URL)
        case importReview(BackupManifest)
        var id: String {
            switch self {
            case .export(let u): return "export:\(u.path)"
            case .importReview:  return "import"
            }
        }
    }
    @State private var activeModal: ActiveModal? = nil
    @State private var showImporter = false
    @State private var backupError: String? = nil

    // Tipi accettati dal selettore file: il tipo custom .qbeats (registrato in
    // project.yml) + zip (conformità) + data come rete di sicurezza debug.
    private var qbeatsImportTypes: [UTType] {
        var types: [UTType] = []
        if let t = UTType("com.bullfrog.qbeats.backup") { types.append(t) }
        types.append(.zip)
        types.append(.data)
        return types
    }

    private func doDebugExport() {
        backupError = nil
        Task {
            do {
                // settings: nil = backup del SOLO catalogo per il round-trip
                // (niente sovrascrittura delle impostazioni al re-import).
                let songs = QBeatsStore.shared.songs
                let setlists = QBeatsStore.shared.setlists
                let url = try await QBeatsBackupManager.export(
                    settings: nil,
                    songs: songs,
                    setlists: setlists,
                    includeAudio: false,
                    store: QBeatsStore.shared
                )
                await MainActor.run {
                    activeModal = .export(url)
                    os_log("[DebugView] Export OK: %{public}@", log: .default, type: .default, url.lastPathComponent)
                }
            } catch {
                await MainActor.run {
                    backupError = "Export fallito: \(error.localizedDescription)"
                    os_log("[DebugView] Export error: %{public}@", log: .default, type: .error, error.localizedDescription)
                }
            }
        }
    }

    private func handleImporterResult(_ result: Result<URL, Error>) {
        backupError = nil
        switch result {
        case .success(let url):
            Task {
                // File scelto dal picker = security-scoped: va aperto prima di
                // leggerlo (parse fa unzip+read) e chiuso dopo l'await.
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                do {
                    let manifest = try await QBeatsBackupManager.parse(url)
                    await MainActor.run {
                        activeModal = .importReview(manifest)
                        os_log("[DebugView] Import parse OK: %d song(s)", log: .default, type: .default, manifest.songs.count)
                    }
                } catch {
                    await MainActor.run {
                        backupError = "Import fallito: \(error.localizedDescription)"
                        os_log("[DebugView] Import parse error: %{public}@", log: .default, type: .error, error.localizedDescription)
                    }
                }
            }
        case .failure(let err):
            backupError = "Selezione file fallita: \(err.localizedDescription)"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // --- BACKUP / RESTORE (.qbeats) — TEST device B7-A5c ---
                SwiftUI.Section("Backup / Restore (.qbeats · TEST)") {
                    Button(action: { doDebugExport() }) {
                        Label("Export backup (.qbeats)", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button(action: { showImporter = true }) {
                        Label("Import backup (.qbeats)", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)

                    if let err = backupError {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                    Text("Export → foglio di condivisione → \"Salva su File\". Poi Import → scegli il .qbeats da File.")
                        .font(.caption2).foregroundColor(.secondary)
                }

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

                // --- RIENTRO-P1 (A366) — PROVA A/B SUL TEMPO AL CONFINE DI SEZIONE (W2) ---
                // Strumento di misura per la decisione 9.1 (referto A364): acceso = oggi (il
                // Follower scrive il tempo su Link al proprio confine di sezione), spento = il
                // Follower salta quella scrittura. Tocca SOLO il Follower; nasce acceso a ogni
                // avvio dell'app e non si conserva. Tutta questa vista è `#if DEBUG`.
                SwiftUI.Section("RIENTRO-P1 · prova A/B") {
                    Toggle("Follower: tempo al confine (W2)", isOn: Binding(
                        get: { audioEngine.debugFollowerBoundaryTempoWrite },
                        set: { audioEngine.setDebugFollowerBoundaryTempoWrite($0) }
                    ))
                    Text("Acceso = comportamento di oggi. Spento = il Follower non scrive il tempo su Link al cambio di sezione. Direttore e Solo non cambiano. Torna acceso a ogni avvio dell'app.")
                        .font(.caption)
                        .foregroundColor(.gray)
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
                    Text("Popola lo store in RAM con 2 songs + 1 show. Poi tap Q-Live → Play del transport.")
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
                    Button("Carica dati test 110 Mono") {
                        loadTestData110Mono()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    Button("Carica dati test 110 Quad") {
                        loadTestData110Quad()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    Button("Carica dati test BPM Quad") {
                        loadTestDataBpmQuad()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    Button("Carica dati test BPB Mixed") {
                        loadTestDataBpbMixed()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.mint)
                    Button("Carica dati test 3/4 Long") {
                        loadTestData34Long()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brown)
                    Button("Carica dati test TD#17 Long") {
                        loadTestDataTD17Long()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    // A386 · B2b — la scaletta del collaudo del 2D (5 canzoni da circa un minuto).
                    Group {
                        Button("Carica dati test COLLAUDO 2D") {
                            loadTestDataCollaudo2D()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        // A397 · SOLO-G1-PEZZO-1-M2 — la scaletta del collaudo del player del Solo, Giro 1 (M1 + M2).
                        // (Nel `Group` col tasto del 2D: la sezione aveva già dieci figli.)
                        Button("Carica dati test COLLAUDO SOLO G1") {
                            loadTestDataCollaudoSoloG1()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
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
            // Presentazione ancorata al List (contenitore stabile), NON alle
            // righe: il fileImporter + un unico .sheet(item:) per export/import.
            .fileImporter(isPresented: $showImporter, allowedContentTypes: qbeatsImportTypes) { result in
                handleImporterResult(result)
            }
            .sheet(item: $activeModal) { modal in
                switch modal {
                case .export(let url):
                    ActivitySheet(items: [url])
                case .importReview(let manifest):
                    ImportView(manifest: manifest, store: QBeatsStore.shared)
                }
            }
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

    /// Test diagnostico 110 Mono — 1 sezione 110 BPM 4/4 × 45 misure (~98s).
    /// Isola se il drift intra-sezione osservato in L2.b Sez 110 è
    /// BPM-intrinsic (drifta anche standalone) o cambio-driven (sparisce
    /// senza cambi BPM precedenti). 45 misure scelte per amplificare un
    /// drift lineare ~4ms/s a ~390ms, ben oltre rumore di misura Audacity.
    private func loadTestData110Mono() {
        os_log("[DebugView] Carica dati test 110 Mono", log: .default, type: .default)

        let s1 = SongSection(name: "110 Mono", bpm: 110, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 45, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song = Song(id: UUID(), name: "Test Song 110 Mono",
                        sections: [s1],
                        countIn: 0, backtrackFilename: nil)

        let setlist = Setlist(id: UUID(), name: "Test Setlist 110 Mono",
                              date: Date(), songIDs: [song.id])

        QBeatsStore.shared.injectTestData(songs: [song], setlists: [setlist])
    }

    /// Test diagnostico 110 Quad — 4 sezioni 110 BPM 4/4 × 7 misure ciascuna.
    /// Isola se le transizioni di sezione causano drift indipendentemente
    /// dal cambio di BPM (qui il BPM resta 110 in tutte le sezioni).
    /// Durata totale ~61s, paragonabile a L2.b (~54s).
    private func loadTestData110Quad() {
        os_log("[DebugView] Carica dati test 110 Quad", log: .default, type: .default)

        let s1 = SongSection(name: "110 Quad — 1", bpm: 110, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 7, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s2 = SongSection(name: "110 Quad — 2", bpm: 110, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 7, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s3 = SongSection(name: "110 Quad — 3", bpm: 110, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 7, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s4 = SongSection(name: "110 Quad — 4", bpm: 110, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 7, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song = Song(id: UUID(), name: "Test Song 110 Quad",
                        sections: [s1, s2, s3, s4],
                        countIn: 0, backtrackFilename: nil)

        let setlist = Setlist(id: UUID(), name: "Test Setlist 110 Quad",
                              date: Date(), songIDs: [song.id])

        QBeatsStore.shared.injectTestData(songs: [song], setlists: [setlist])
    }

    /// Test diagnostico BPM Quad — Strada A validazione T-BPM.
    /// 4 sezioni 4/4 × 7 misure ciascuna, BPM variabile: 100 → 130 → 110 → 140.
    /// Simmetria identica al 110 Quad (7 misure fisse, durata totale variabile
    /// con BPM) per confronto diretto. Sequenza scelta per testare:
    ///   T1 100→130 (+30 BPM ascendente)
    ///   T2 130→110 (-20 BPM discendente)
    ///   T3 110→140 (+30 BPM ascendente)
    /// Verifica broadcast Link atomic + DSP exchange BPM al downbeat di
    /// transizione. Soglia VERDE: offset SB→Q-B ≤5ms su tutti i downbeat,
    /// NON accumulativo (vs baseline pre-Strada-A).
    private func loadTestDataBpmQuad() {
        os_log("[DebugView] Carica dati test BPM Quad", log: .default, type: .default)

        let s1 = SongSection(name: "BPM Quad — 100", bpm: 100, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 7, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s2 = SongSection(name: "BPM Quad — 130", bpm: 130, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 7, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s3 = SongSection(name: "BPM Quad — 110", bpm: 110, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 7, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s4 = SongSection(name: "BPM Quad — 140", bpm: 140, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 7, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song = Song(id: UUID(), name: "Test Song BPM Quad",
                        sections: [s1, s2, s3, s4],
                        countIn: 0, backtrackFilename: nil)

        let setlist = Setlist(id: UUID(), name: "Test Setlist BPM Quad",
                              date: Date(), songIDs: [song.id])

        QBeatsStore.shared.injectTestData(songs: [song], setlists: [setlist])
    }

    /// Test diagnostico BPB Mixed — Strada A validazione T-BPB.
    /// 4 sezioni × 4 misure × 120 BPM costante, BPB variabile:
    /// 4/4 → 3/4 → 5/4 → 4/4 con accent pattern misti.
    /// Verifica:
    ///   - DSP atomic exchange BPB al downbeat (modulo % _beatsPerBar con NEW)
    ///   - metronome_schedule_accent_pattern_change (length variabile 3,4,5)
    ///   - link_engine_set_quantum aggiornato al downbeat
    ///   - SB segue il cambio metro senza staccarsi
    /// Soglia VERDE:
    ///   - cambio metro percepibile chiaro a ogni transizione
    ///   - accent in posizione giusta (beat 1 sempre + secondari come da pattern)
    ///   - SB resta in sync (no disconnect Link)
    ///   - nessun click "fantasma" dal pattern precedente
    private func loadTestDataBpbMixed() {
        os_log("[DebugView] Carica dati test BPB Mixed", log: .default, type: .default)

        // Sez 1: 4/4 con accent default (solo beat 1)
        let s1 = SongSection(name: "BPB Mixed — 4/4", bpm: 120, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 4, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        // Sez 2: 3/4 (length pattern shorter del precedente)
        let s2 = SongSection(name: "BPB Mixed — 3/4", bpm: 120, beatsPerBar: 3, beatUnit: 4,
                             repetitions: 4, notes: "", accentPattern: [2,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        // Sez 3: 5/4 con accent secondario al beat 4 (length pattern longer)
        let s3 = SongSection(name: "BPB Mixed — 5/4", bpm: 120, beatsPerBar: 5, beatUnit: 4,
                             repetitions: 4, notes: "", accentPattern: [2,1,1,2,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        // Sez 4: 4/4 con accent doppio (beat 1 e 3) — verifica pattern UI→DSP non-default
        let s4 = SongSection(name: "BPB Mixed — 4/4 alt", bpm: 120, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 4, notes: "", accentPattern: [2,1,2,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song = Song(id: UUID(), name: "Test Song BPB Mixed",
                        sections: [s1, s2, s3, s4],
                        countIn: 0, backtrackFilename: nil)

        let setlist = Setlist(id: UUID(), name: "Test Setlist BPB Mixed",
                              date: Date(), songIDs: [song.id])

        QBeatsStore.shared.injectTestData(songs: [song], setlists: [setlist])
    }

    /// Test diagnostico 3/4 Long — Prerequisito Item 5 TD #39 quantum mismatch 3/4.
    /// Setlist con sezione 3/4 di 16 battute (lunga abbastanza per mismatch progressivo)
    /// incastonata tra 2 sezioni 4/4 di 8 battute. BPM costante 100 in tutte e 3 le
    /// sezioni: isola l'effetto del cambio di time signature dal cambio di BPM.
    /// Step 0 del 25/05/2026 sera ha testato il 3/4 di L1.b ma con sezione di sole
    /// 2 battute — troppo corta per mismatch progressivo cross-device QB↔QB.
    /// Questa setlist permette di chiudere/riaprire TD #39 con dato conclusivo.
    private func loadTestData34Long() {
        os_log("[DebugView] Carica dati test 3/4 Long", log: .default, type: .default)

        let s1 = SongSection(name: "3/4 Long — 4/4 intro", bpm: 100, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 8,  notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s2 = SongSection(name: "3/4 Long — 3/4 main",  bpm: 100, beatsPerBar: 3, beatUnit: 4,
                             repetitions: 16, notes: "", accentPattern: [2,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let s3 = SongSection(name: "3/4 Long — 4/4 outro", bpm: 100, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 8,  notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song = Song(id: UUID(), name: "Test Song 3/4 Long",
                        sections: [s1, s2, s3],
                        countIn: 0, backtrackFilename: nil)

        let setlist = Setlist(id: UUID(), name: "Test Setlist 3/4 Long",
                              date: Date(), songIDs: [song.id])

        QBeatsStore.shared.injectTestData(songs: [song], setlists: [setlist])
    }

    /// Test diagnostico TD#17 Long — sessione lunga per riprodurre la perdita
    /// peer Link in foreground (RUN9, 11/06/2026: peer perso mid-play, app in
    /// primo piano, recovery solo con socket nuovo). 121 BPM costante, ciclo BPB
    /// 4/4 → 3/4 → 5/4 → 4/4 ripetuto 200 volte: 800 sezioni, ~8,8 ore, 799 cambi
    /// sezione (~uno ogni 40 s) per massimizzare la copertura del candidato
    /// "il processing del cambio sezione sul Direttore fa saltare il keepalive
    /// LinkKit". Durata estesa (15/06/2026, TD#17 step ②: 23→200 cicli) così la
    /// run a oltranza NON presidiata non raggiunge END SHOW nella finestra di
    /// cattura. Nessun requisito musicale: fixture diagnostica. Da compilare con
    /// QB_DIAG_SPY OFF per tenere magro il log del Direttore sulla sessione lunga.
    private func loadTestDataTD17Long() {
        os_log("[DebugView] Carica dati test TD#17 Long", log: .default, type: .default)

        // (nome, beatsPerBar, accentPattern, repetitions). Invariante: accentPattern.count == beatsPerBar.
        let cycle: [(String, UInt32, [UInt8], Int)] = [
            ("4/4", 4, [2, 1, 1, 1],    20),   // ~39,7 s
            ("3/4", 3, [2, 1, 1],       27),   // ~40,2 s
            ("5/4", 5, [2, 1, 1, 1, 1], 16),   // ~39,7 s
            ("4/4", 4, [2, 1, 1, 1],    20),   // ~39,7 s
        ]

        var sections: [SongSection] = []
        for c in 0..<200 {
            for (label, bpb, accent, reps) in cycle {
                sections.append(SongSection(name: "TD17 c\(c + 1) \(label)",
                                            bpm: 121, beatsPerBar: bpb, beatUnit: 4,
                                            repetitions: reps, notes: "",
                                            accentPattern: accent,
                                            subdivisionMultiplier: 1, swingRatio: 0.5))
            }
        }

        let song = Song(id: UUID(), name: "Test Song TD#17 Long",
                        sections: sections,
                        countIn: 0, backtrackFilename: nil)

        let setlist = Setlist(id: UUID(), name: "Test Setlist TD#17 Long",
                              date: Date(), songIDs: [song.id])

        QBeatsStore.shared.injectTestData(songs: [song], setlists: [setlist])
    }

    /// A386 · B2b (30/09/2026) — LA SCALETTA DEL COLLAUDO DEL 2D: «COLLAUDO 2D», cinque canzoni
    /// di circa un minuto, countIn 0, BPM non interi (Costituzione §6: «testare sempre con BPM
    /// non interi (es. 121.0)» — quattro sul modello dell'esempio, uno davvero non intero).
    /// Durate con la semantica del motore: `bpm` = click al minuto, un click per unità di
    /// `beatsPerBar`; `beatUnit` non entra (il DSP conta `spb = sampleRate·60/bpm` per click,
    /// `MetronomeDSP.cpp`; `loadSection` totalizza `repetitions × beatsPerBar` battiti,
    /// `AudioEngine.loadSection`): durata = battute × beatsPerBar × 60 / bpm.
    ///   (1) 4/4 a 121, 30 battute = 59,5 s · (2) 4/4 a 141, 35 battute = 59,6 s ·
    ///   (3) 6/8 a 101, 17 battute = 60,6 s · (4) 4/4, 15 battute a 121 (29,8 s) + 11 a 91
    ///   (29,0 s) = 58,8 s · (5) 4/4 a 110,5, 28 battute = 60,8 s.
    /// Nomi corti (≤ 12 caratteri, una riga sul velo), col numero della canzone — B2b-BIS: la 3
    /// era «3 Charlie 6/8», 13 caratteri; ora «3 Charly 6/8», 12. Come le altre
    /// scalette di prova: `injectTestData` sostituisce il contenuto dello store e vive solo in
    /// RAM (sparisce al kill dell'app).
    private func loadTestDataCollaudo2D() {
        os_log("[DebugView] Carica dati test COLLAUDO 2D", log: .default, type: .default)

        let s1 = SongSection(name: "Uno 121", bpm: 121.0, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 30, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song1 = Song(id: UUID(), name: "1 Alfa 121", sections: [s1],
                         countIn: 0, backtrackFilename: nil)

        let s2 = SongSection(name: "Due 141", bpm: 141.0, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 35, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song2 = Song(id: UUID(), name: "2 Bravo 141", sections: [s2],
                         countIn: 0, backtrackFilename: nil)

        let s3 = SongSection(name: "Tre 6/8 101", bpm: 101.0, beatsPerBar: 6, beatUnit: 8,
                             repetitions: 17, notes: "", accentPattern: [2,1,1,2,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song3 = Song(id: UUID(), name: "3 Charly 6/8", sections: [s3],
                         countIn: 0, backtrackFilename: nil)

        let s4a = SongSection(name: "Prima 121", bpm: 121.0, beatsPerBar: 4, beatUnit: 4,
                              repetitions: 15, notes: "", accentPattern: [2,1,1,1],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let s4b = SongSection(name: "Seconda 91", bpm: 91.0, beatsPerBar: 4, beatUnit: 4,
                              repetitions: 11, notes: "", accentPattern: [2,1,1,1],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let song4 = Song(id: UUID(), name: "4 Delta 2sez", sections: [s4a, s4b],
                         countIn: 0, backtrackFilename: nil)

        let s5 = SongSection(name: "Cinque 110.5", bpm: 110.5, beatsPerBar: 4, beatUnit: 4,
                             repetitions: 28, notes: "", accentPattern: [2,1,1,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song5 = Song(id: UUID(), name: "5 Echo 110.5", sections: [s5],
                         countIn: 0, backtrackFilename: nil)

        let setlist = Setlist(id: UUID(), name: "COLLAUDO 2D",
                              date: Date(), songIDs: [song1.id, song2.id, song3.id, song4.id, song5.id])

        QBeatsStore.shared.injectTestData(songs: [song1, song2, song3, song4, song5], setlists: [setlist])
    }

    /// A397 · SOLO-G1-PEZZO-1-M2 (06/10/2026) — LA SCALETTA DEL COLLAUDO DEL PLAYER DEL SOLO, GIRO 1: «COLLAUDO SOLO
    /// G1», cinque canzoni intorno al minuto, countIn 0, nessuna base, sul modello di «COLLAUDO 2D». Dentro: le
    /// metriche 7/8, 9/8, 11/8, 12/8, 6/4, 5/8 della lista chiusa (`TimeSignature.all`) più 4/4, 2/4 e 3/4; battute sui
    /// tre gradini del punto 107 (fino a 16; fra 17 e 32; 64); una sezione senza nome, non la prima della sua canzone
    /// (punto 109); un titolo più lungo di quanto tiene la testata (circa 20 caratteri a 24) e «Next song» (circa 11);
    /// una sezione col nome su due righe (punto 51); accenti: ogni sezione col 2 sul battito 1, il 7/8 come 2+2+3, il
    /// 5/8 come 2+3, il 9/8 e l'11/8 a gruppi di tre (accenti dentro la battuta), il 12/8 con lo 0 nel pattern (BOX5
    /// V54, decisione 8); BPM non interi (Costituzione §6: 180,5 · 160,5 · 110,5); una canzone con tre sezioni;
    /// l'ultima sezione dell'ultima canzone («Next» e «END SHOW»). Durate con la semantica del motore (come
    /// «COLLAUDO 2D»): battute × beatsPerBar × 60 / bpm.
    ///   (1) 7/8 a 161, 8 battute (20,9 s) + 9/8 a 180,5, 8 battute, senza nome (23,9 s) + 4/4 a 121, 6 battute
    ///       (11,9 s) = 56,7 s · (2) 2/4 a 128, 64 battute = 60,0 s · (3) 12/8 a 180, 10 battute (40,0 s) + 6/4 a 150,
    ///       8 battute (19,2 s) = 59,2 s · (4) 11/8 a 198, 8 battute (26,7 s) + 5/8 a 160,5, 18 battute (33,6 s) =
    ///       60,3 s · (5) 4/4 a 110,5, 16 battute (34,8 s) + 3/4 a 120, 16 battute (24,0 s) = 58,8 s.
    /// Vive in RAM e sparisce se l'app si chiude (`injectTestData` sostituisce il contenuto dello store).
    private func loadTestDataCollaudoSoloG1() {
        os_log("[DebugView] Carica dati test COLLAUDO SOLO G1", log: .default, type: .default)

        let s1a = SongSection(name: "Intro 7/8", bpm: 161.0, beatsPerBar: 7, beatUnit: 8,
                              repetitions: 8, notes: "", accentPattern: [2,1,2,1,2,1,1],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let s1b = SongSection(name: "", bpm: 180.5, beatsPerBar: 9, beatUnit: 8,
                              repetitions: 8, notes: "", accentPattern: [2,1,1,2,1,1,2,1,1],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let s1c = SongSection(name: "Chorus", bpm: 121.0, beatsPerBar: 4, beatUnit: 4,
                              repetitions: 6, notes: "", accentPattern: [2,1,1,1],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let song1 = Song(id: UUID(), name: "1 Alfa 7/8", sections: [s1a, s1b, s1c],
                         countIn: 0, backtrackFilename: nil)

        let s2 = SongSection(name: "Long Run 2/4", bpm: 128.0, beatsPerBar: 2, beatUnit: 4,
                             repetitions: 64, notes: "", accentPattern: [2,1],
                             subdivisionMultiplier: 1, swingRatio: 0.5)
        let song2 = Song(id: UUID(), name: "2 Bravo Sixty-Four Bars", sections: [s2],
                         countIn: 0, backtrackFilename: nil)

        let s3a = SongSection(name: "Groove 12/8", bpm: 180.0, beatsPerBar: 12, beatUnit: 8,
                              repetitions: 10, notes: "", accentPattern: [2,0,0,1,0,0,1,0,0,1,0,0],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let s3b = SongSection(name: "Bridge attenzione vai piano", bpm: 150.0, beatsPerBar: 6, beatUnit: 4,
                              repetitions: 8, notes: "", accentPattern: [2,1,1,1,1,1],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let song3 = Song(id: UUID(), name: "3 Charlie 12/8", sections: [s3a, s3b],
                         countIn: 0, backtrackFilename: nil)

        let s4a = SongSection(name: "Verse 11/8", bpm: 198.0, beatsPerBar: 11, beatUnit: 8,
                              repetitions: 8, notes: "", accentPattern: [2,1,1,2,1,1,2,1,1,2,1],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let s4b = SongSection(name: "Mid 5/8", bpm: 160.5, beatsPerBar: 5, beatUnit: 8,
                              repetitions: 18, notes: "", accentPattern: [2,1,2,1,1],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let song4 = Song(id: UUID(), name: "4 Delta 11/8", sections: [s4a, s4b],
                         countIn: 0, backtrackFilename: nil)

        let s5a = SongSection(name: "Outro 4/4", bpm: 110.5, beatsPerBar: 4, beatUnit: 4,
                              repetitions: 16, notes: "", accentPattern: [2,1,1,1],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let s5b = SongSection(name: "Coda", bpm: 120.0, beatsPerBar: 3, beatUnit: 4,
                              repetitions: 16, notes: "", accentPattern: [2,1,1],
                              subdivisionMultiplier: 1, swingRatio: 0.5)
        let song5 = Song(id: UUID(), name: "5 Echo", sections: [s5a, s5b],
                         countIn: 0, backtrackFilename: nil)

        let setlist = Setlist(id: UUID(), name: "COLLAUDO SOLO G1",
                              date: Date(), songIDs: [song1.id, song2.id, song3.id, song4.id, song5.id])

        QBeatsStore.shared.injectTestData(songs: [song1, song2, song3, song4, song5], setlists: [setlist])
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
