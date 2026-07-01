import SwiftUI

/// Q-Stage › Songs › Editor Sezione (prima fetta).
/// Edita una Binding<SongSection>: il commit reale è il SAVE della Song (un solo punto di salvataggio).
/// Accenti in v1 = SOLA LETTURA (rispecchiano il display Live; encoding accenti deferito al cluster-ratifica).
struct SectionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var section: SongSection
    // Campo BPM digitabile: bozza testuale + focus. Il commit (parse + validazione) avviene
    // a fine digitazione (Done / perdita focus), MAI per-keystroke → si scrive libero.
    @State private var bpmText: String
    @FocusState private var bpmFocused: Bool

    // Dominio del campo BPM = 20...400: UNA costante, condivisa da Stepper +/- e input scrivibile
    // (era il literal inline dello Stepper). Il motore NON clampa (MetronomeDSP.cpp:35-49 /
    // AudioEngine.swift:1091-1123) → il limite vive qui, a livello UI/L3.
    private let bpmRange: ClosedRange<Double> = 20...400

    init(section: Binding<SongSection>) {
        self._section = section
        self._bpmText = State(initialValue: String(Int(section.wrappedValue.bpm)))
    }

    var body: some View {
        GeometryReader { geo in
            let sf = geo.size.width / 390
            ZStack {
                QStageTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    QStageNavBar(backTitle: "SONG",
                                 onBack: { commitBPM(); dismiss() },
                                 crumb: "SECTION",
                                 trailingTitle: "DONE",
                                 trailingAction: { commitBPM(); dismiss() },
                                 sf: sf)
                    List {
                        nameTempo(sf)
                        meterAccents(sf)
                        repeatFeel(sf)
                        notesField(sf)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private func nameTempo(_ sf: CGFloat) -> some View {
        Section {
            TextField("Section name", text: $section.name)
                .font(.custom("JetBrainsMono-SemiBold", size: 16 * sf))
                .foregroundColor(QStageTheme.text)
            HStack {
                Text("BPM").font(.jbMono(.medium, size: 15 * sf)).foregroundColor(QStageTheme.text2)
                Spacer()
                TextField("", text: $bpmText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($bpmFocused)
                    .font(.custom("JetBrainsMono-Bold", size: 17 * sf))
                    .foregroundColor(QStageTheme.text)
                    .frame(maxWidth: 64 * sf)
                    .onSubmit { commitBPM() }
                // +/- come Stepper STANDALONE (label nascosta), separato dal campo (l'anti-pattern
                // Test 5 — campo DENTRO la label — NON torna). onIncrement/onDecrement (non value:)
                // per controllare la SEQUENZA, fix della combinazione "digito poi +/-":
                //   1) commitBPM() PRIMA → consegna il bpmText pendente a section.bpm (clampato)
                //      → l'incremento parte dal digitato (es. 120), non dal valore vecchio;
                //   2) ±1 RI-clampato a bpmRange (400 + → resta 400; 20 - → resta 20);
                //   3) refresh esplicito bpmText → il display si muove anche col campo in focus
                //      (non dipende più dalla guardia !bpmFocused).
                // NB §7: hold-to-repeat (tieni-premuto) ATTESO preservato con onIncrement/onDecrement,
                // ma è comportamento framework → CONFERMA DEVICE (non asserito).
                Stepper("",
                        onIncrement: {
                            commitBPM()
                            section.bpm = min(bpmRange.upperBound, section.bpm + 1)
                            bpmText = String(Int(section.bpm))
                        },
                        onDecrement: {
                            commitBPM()
                            section.bpm = max(bpmRange.lowerBound, section.bpm - 1)
                            bpmText = String(Int(section.bpm))
                        })
                    .labelsHidden()
                    .fixedSize()
            }
            .onChange(of: bpmFocused) { focused in
                if !focused { commitBPM() }          // perdita focus = commit
            }
            .onChange(of: section.bpm) { newValue in
                // +/- (o revert) ha mosso il modello: riallinea il testo SOLO se non sto digitando.
                if !bpmFocused { bpmText = String(Int(newValue)) }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if bpmFocused {
                        Spacer()
                        Button("Done") { bpmFocused = false }   // numberPad: no return → Done resigna → commit
                    }
                }
            }
        }
        .listRowBackground(QStageTheme.surface)
    }

    /// Commit del campo BPM scrivibile. Chiamato a fine digitazione (Done / perdita focus), MAI per-keystroke.
    /// Dominio = bpmRange (20...400). In-range → accetta; vuoto / non-numerico / fuori-range → REVERT al
    /// valore corrente del modello (sempre in-range) — niente clamp-a-min silenzioso, niente assert/crash/
    /// force-unwrap. Write SOLO sul modello (`section.bpm`), MAI sul motore vivo (L3 puro).
    private func commitBPM() {
        let trimmed = bpmText.trimmingCharacters(in: .whitespaces)
        if let v = Int(trimmed), bpmRange.contains(Double(v)) {
            section.bpm = Double(v)
        }
        bpmText = String(Int(section.bpm))   // riallinea SEMPRE il testo al modello (valore accettato o revert)
    }

    private func meterAccents(_ sf: CGFloat) -> some View {
        Section {
            Picker(selection: meterBinding) {
                ForEach(TimeSignature.all) { ts in
                    Text(ts.label).tag(ts.label)
                }
            } label: {
                Text("Meter").font(.jbMono(.medium, size: 15 * sf)).foregroundColor(QStageTheme.text2)
            }
            AccentDisplay(beatsPerBar: Int(section.beatsPerBar), pattern: section.accentPattern, sf: sf)
        } header: {
            Text("Meter & Accents").font(.jbMono(.medium, size: 11 * sf)).textCase(.uppercase).foregroundColor(QStageTheme.text2)
        } footer: {
            Text("Accents are read-only in v1 (they mirror the Live display). Editing arrives with the ratified accent encoding.")
                .font(.jbMono(.regular, size: 11 * sf))
                .foregroundColor(QStageTheme.text3)
        }
        .listRowBackground(QStageTheme.surface)
    }

    private func repeatFeel(_ sf: CGFloat) -> some View {
        Section {
            Toggle(isOn: loopBinding) {
                Text("Loop ∞").font(.jbMono(.medium, size: 15 * sf)).foregroundColor(QStageTheme.text2)
            }
            .tint(QStageTheme.accent)

            if section.repetitions >= 0 {
                Stepper(value: $section.repetitions, in: 1...64) {
                    HStack {
                        Text("Repeat").font(.jbMono(.medium, size: 15 * sf)).foregroundColor(QStageTheme.text2)
                        Spacer()
                        Text("×\(section.repetitions)")
                            .font(.custom("JetBrainsMono-Bold", size: 16 * sf))
                            .foregroundColor(QStageTheme.text)
                    }
                }
            }

            Stepper(value: subdivBinding, in: 1...4) {
                HStack {
                    Text("Subdivision").font(.jbMono(.medium, size: 15 * sf)).foregroundColor(QStageTheme.text2)
                    Spacer()
                    Text("\(section.subdivisionMultiplier)×")
                        .font(.jbMono(.bold, size: 16 * sf))
                        .foregroundColor(QStageTheme.text)
                }
            }

            VStack(alignment: .leading, spacing: 6 * sf) {
                HStack {
                    Text("Swing").font(.jbMono(.medium, size: 15 * sf)).foregroundColor(QStageTheme.text2)
                    Spacer()
                    Text(section.subdivisionMultiplier == 2 ? "\(Int(section.swingRatio * 100))%" : "—")
                        .font(.jbMono(.bold, size: 16 * sf))
                        .foregroundColor(QStageTheme.text)
                }
                // CONTRATTO L1 (sourced): MetronomeDSP.h:37 swingRatio valido in [0.5, 1.0[;
                // .cpp:135/140 lo swing agisce SOLO con subdivisionMultiplier == 2 (crome).
                Slider(value: $section.swingRatio, in: 0.5...0.75)
                    .tint(QStageTheme.accent)
                    .disabled(section.subdivisionMultiplier != 2)
                if section.subdivisionMultiplier != 2 {
                    Text("Swing applies only with eighth-note subdivision (×2).")
                        .font(.jbMono(.regular, size: 11 * sf))
                        .foregroundColor(QStageTheme.text3)
                }
            }
        } header: {
            Text("Repeat & Feel").foregroundColor(QStageTheme.text2)
        }
        .listRowBackground(QStageTheme.surface)
    }

    private func notesField(_ sf: CGFloat) -> some View {
        Section {
            TextField("Notes", text: $section.notes, axis: .vertical)
                .font(.jbMono(.regular, size: 15 * sf))
                .lineLimit(1...4)
                .foregroundColor(QStageTheme.text)
        } header: {
            Text("Notes").font(.jbMono(.medium, size: 11 * sf)).textCase(.uppercase).foregroundColor(QStageTheme.text2)
        }
        .listRowBackground(QStageTheme.surface)
    }

    // MARK: - Bindings derivati

    /// Metro corrente come label; sul set aggiorna beatsPerBar/beatUnit e RIDIMENSIONA accentPattern
    /// a beatsPerBar — INVARIANTE `accentPattern.count == beatsPerBar` (brief §2 / Scenario B): il DSP
    /// `MetronomeDSP.cpp:352` indicizza `_accentPattern[_currentBeatInBar]` fino a beatsPerBar-1.
    /// Resize ≠ ratifica: preserva i valori esistenti dove gli indici coincidono, riempie i nuovi slot
    /// con `1` (= "beat", convenzione corrente 0=subdiv/1=beat/2=accent). NESSUN remap di convenzione
    /// (1→2,0→1) — quello resta ratifica, fuori da qui.
    /// (Verificato 27/06: nessun resize a monte — `SongSection.init(from:):49` decodifica RAW, niente didSet sul modello.)
    private var meterBinding: Binding<String> {
        Binding(
            get: { TimeSignature.matching(section)?.label ?? "" },
            set: { label in
                guard let ts = TimeSignature.all.first(where: { $0.label == label }) else { return }
                let newCount = Int(ts.numerator)
                section.beatsPerBar = ts.numerator
                section.beatUnit = ts.denominator
                if section.accentPattern.count > newCount {
                    section.accentPattern = Array(section.accentPattern.prefix(newCount))
                } else if section.accentPattern.count < newCount {
                    section.accentPattern.append(
                        contentsOf: Array(repeating: 1, count: newCount - section.accentPattern.count)
                    )
                }
            }
        )
    }

    /// repetitions = -1 (sentinel loop) ⇄ toggle.
    private var loopBinding: Binding<Bool> {
        Binding(
            get: { section.repetitions < 0 },
            set: { section.repetitions = $0 ? -1 : 1 }
        )
    }

    /// subdivisionMultiplier (UInt8) come Int per lo Stepper.
    private var subdivBinding: Binding<Int> {
        Binding(
            get: { Int(section.subdivisionMultiplier) },
            set: { section.subdivisionMultiplier = UInt8(max(1, min(4, $0))) }
        )
    }
}

/// Griglia accenti — SOLA LETTURA in v1 (l'editing arriva col cluster-ratifica encoding).
/// CONVENZIONE (sourced, `AudioEngine.swift:1359-1360`): 0 = subdiv, 1 = beat, 2 = accent.
/// Rispecchia ESATTAMENTE il display Live autorevole (`LiveView.swift:415-422` + `MetSlotStripView`:
/// 2→accent verde #28cd41, 1→beat, 0→subdiv). Nessuna scrittura, nessun remap, nessuna migrazione.
/// Mostra `beatsPerBar` celle: legge pattern[i] se presente, altrimenti "beat" come solo default VISIVO
/// (non riscrive il modello). Difetti pre-esistenti (audio 1≈0; default [1,0,0,0] accentless) = cluster-ratifica.
private struct AccentDisplay: View {
    let beatsPerBar: Int
    let pattern: [UInt8]
    let sf: CGFloat

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 40 * sf), spacing: 8 * sf)] }
    private let accentColor = Color(hex: "#28cd41")   // = MetSlotStripView accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * sf) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8 * sf) {
                ForEach(0..<max(beatsPerBar, 0), id: \.self) { i in
                    Text("\(i + 1)")
                        .font(.custom("JetBrainsMono-Bold", size: 13 * sf))
                        .frame(width: 40 * sf, height: 40 * sf)
                        .background(background(value(i)))
                        .foregroundColor(value(i) == 0 ? QStageTheme.text3 : QStageTheme.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 8 * sf))
                }
            }
            HStack(spacing: 14 * sf) {
                legend(accentColor, "Accent")
                legend(QStageTheme.text.opacity(0.85), "Beat")
                legend(QStageTheme.text.opacity(0.20), "Subdiv")
                Spacer()
                Text("read-only").foregroundColor(QStageTheme.text3)
            }
            .font(.jbMono(.regular, size: 10 * sf))
            .foregroundColor(QStageTheme.text3)
        }
        .padding(.vertical, 4 * sf)
    }

    // Valore della cella i: pattern[i] se presente, altrimenti default VISIVO "beat" (1). Nessuna scrittura.
    private func value(_ i: Int) -> UInt8 { i < pattern.count ? pattern[i] : 1 }

    private func background(_ v: UInt8) -> Color {
        switch v {
        case 2:  return accentColor
        case 1:  return QStageTheme.text.opacity(0.85)
        default: return QStageTheme.text.opacity(0.20)
        }
    }

    private func legend(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4 * sf) {
            RoundedRectangle(cornerRadius: 3 * sf).fill(color).frame(width: 12 * sf, height: 12 * sf)
            Text(label)
        }
    }
}
