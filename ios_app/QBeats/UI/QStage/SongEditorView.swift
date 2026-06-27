import SwiftUI

/// Q-Stage › Songs › Editor Canzone (F2.5, prima fetta).
/// Edita una COPIA (draft); commit unico su SAVE via updateSong (un solo punto di salvataggio).
/// Modello INVARIATO — nessun campo nuovo.
struct SongEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = QBeatsStore.shared
    @State private var draft: Song
    @State private var editMode: EditMode = .inactive

    init(song: Song) {
        _draft = State(initialValue: song)
    }

    var body: some View {
        ZStack {
            QStageTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                QStageNavBar(backTitle: "SONGS",
                             onBack: { dismiss() },
                             crumb: "EDIT SONG",
                             trailingTitle: "SAVE",
                             trailingAction: save)
                List {
                    Section {
                        TextField("Song name", text: $draft.name)
                            .font(.custom("JetBrainsMono-SemiBold", size: 17))
                            .foregroundColor(QStageTheme.text)
                        Picker(selection: $draft.countIn) {
                            Text("Off").tag(0)
                            Text("1 bar").tag(1)
                            Text("2 bars").tag(2)
                        } label: {
                            Text("Count-in")
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(QStageTheme.surface)

                    Section {
                        ForEach($draft.sections) { $section in
                            NavigationLink {
                                SectionEditorView(section: $section)
                            } label: {
                                SectionRow(section: section)
                            }
                            .listRowBackground(QStageTheme.surface)
                        }
                        .onDelete { draft.sections.remove(atOffsets: $0) }
                        .onMove { draft.sections.move(fromOffsets: $0, toOffset: $1) }

                        Button {
                            draft.sections.append(SongSection.makeDefault())
                        } label: {
                            Label("Add Section", systemImage: "plus.circle")
                                .foregroundColor(QStageTheme.accent)
                        }
                        .listRowBackground(QStageTheme.surface)
                    } header: {
                        HStack {
                            Text("Sections").foregroundColor(QStageTheme.text2)
                            Spacer()
                            if !draft.sections.isEmpty {
                                Button(editMode == .active ? "Done" : "Reorder") {
                                    withAnimation { editMode = editMode == .active ? .inactive : .active }
                                }
                                .font(.custom("JetBrainsMono-Medium", size: 12))
                                .foregroundColor(QStageTheme.accent)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, $editMode)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private func save() {
        Task { @MainActor in
            await store.updateSong(draft)
            dismiss()
        }
    }
}

private struct SectionRow: View {
    let section: SongSection
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(section.name.isEmpty ? "Untitled" : section.name)
                    .font(.custom("JetBrainsMono-SemiBold", size: 15))
                    .foregroundColor(QStageTheme.text)
                Text(meta)
                    .font(.custom("JetBrainsMono-Medium", size: 11))
                    .foregroundColor(QStageTheme.text3)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    private var meta: String {
        let sig = TimeSignature.matching(section)?.label ?? "\(section.beatsPerBar)/\(section.beatUnit)"
        let reps = section.repetitions < 0 ? "∞" : "×\(section.repetitions)"
        return "\(Int(section.bpm)) BPM · \(sig) · \(reps)"
    }
}
