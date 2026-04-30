import Foundation
import os

struct MIDILearnStore {
    private static let udKey = "com.bullfrog.qbeats.midiMapping"

    var table: [MIDIAction: MIDILearnMapping] = [:]

    static func load() -> MIDILearnStore {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([String: MIDILearnMapping].self, from: data)
        else { return MIDILearnStore() }
        var store = MIDILearnStore()
        for (key, value) in decoded {
            if let action = MIDIAction(rawValue: key) {
                store.table[action] = value
            }
        }
        return store
    }

    func save() {
        let encoded = Dictionary(uniqueKeysWithValues: table.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(encoded) else { return }
        UserDefaults.standard.set(data, forKey: Self.udKey)
        os_log("[Q-BEATS][MIDI LEARN] Mapping salvato — %d azioni mappate",
               log: .default, type: .default, table.count)
    }

    mutating func setMapping(_ mapping: MIDILearnMapping, for action: MIDIAction) {
        table[action] = mapping
        save()
    }

    mutating func removeMapping(for action: MIDIAction) {
        table.removeValue(forKey: action)
        save()
    }

    func mapping(for action: MIDIAction) -> MIDILearnMapping? {
        table[action]
    }

    func action(for type: MIDIEventType, channel: UInt8, number: UInt8) -> MIDIAction? {
        for (action, mapping) in table {
            guard mapping.type == type && mapping.number == number else { continue }
            if mapping.channel == 0 || mapping.channel == channel { return action }
        }
        return nil
    }
}
