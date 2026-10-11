#if DEBUG
import Foundation

// === A402 (11/10/2026) — REGISTRO ESPORTATO DALL'APP: LA FORMA DEL FILE ===
// L'app rilegge le proprie righe di registro (`OSLogStore`, in `DebugLogExporter`) e le salva in un file di testo.
// Qui sta quello che si prova senza telefono: la forma di una riga, l'intestazione, il nome del file.
// La riga segue i registri che oggi esporta iMazing (misurato sui file in `LOG_COLLAUDI`, 219.414 righe):
//   `Oct 11 09:22:35 Bullfrog-13 QBeats[1477] <Notice>: [Q-BEATS][SOLO-M3][VELO] tocco schermo:V …`
//   mese in inglese · giorno su due posti con lo spazio davanti (`Oct  8`) · ora · apparecchio · processo[pid] ·
//   `<Livello>:` · messaggio; quando la riga la scrive un'altra immagine del processo: `processo(immagine)[pid]`.
// Tre differenze, volute:
//   1. l'ora porta i millesimi (`09:22:35.500`), troncati;
//   2. l'apparecchio è «iPhone» o «iPad»: il nome dato dall'utente («Bullfrog-13») da iOS 16 non si legge senza
//      un permesso dedicato (Apple, `UIDevice.name`);
//   3. il messaggio è scritto com'è, in UTF-8: iMazing scrive i caratteri non ASCII per byte (`\M-b\M^@\M^T` per
//      «—», `\M-B\M-7` per «·»).
// Una voce = una riga: un a capo dentro il messaggio diventa i due caratteri `\n`.
// Solo in Debug (`#if DEBUG`), come la schermata che lo usa. Solo Foundation: il banco `QBeatsTests` compila
// QBeats/Models e nient'altro.

/// Una voce del registro come l'app la rilegge, ridotta ai valori che vanno nel file.
struct LogExportEntry: Equatable {
    let date: Date
    /// Il nome del processo; vuoto se la voce non viene da un processo.
    let process: String
    /// L'immagine binaria che ha scritto la voce.
    let sender: String
    let processIdentifier: Int32
    /// `Notice`, `Error`, `Info`, `Debug`, `Fault`, `Undefined` per le righe di registro; `Activity`, `Signpost`,
    /// `Boundary` per le altre voci che il registro rende.
    let level: String
    let message: String
}

/// I dati dell'intestazione che non vengono dalle righe.
struct LogExportInfo: Equatable {
    /// «iPhone» o «iPad»: va anche nel nome del file e nella colonna dell'apparecchio di ogni riga.
    let device: String
    let systemName: String
    let systemVersion: String
    let appVersion: String
    let appBuild: String
    let processName: String
    let processIdentifier: Int32
}

/// Il conto delle righe scritte, per l'intestazione.
struct LogExportTally: Equatable {
    private(set) var rows = 0
    private(set) var first: Date?
    private(set) var last: Date?
    private(set) var levels: [String: Int] = [:]
    private(set) var senders: [String: Int] = [:]
    private(set) var processes: [String: Int] = [:]
    private(set) var rowsWithLineBreaks = 0

    mutating func add(_ entry: LogExportEntry) {
        rows += 1
        if let earliest = first {
            if entry.date < earliest { first = entry.date }
        } else {
            first = entry.date
        }
        if let latest = last {
            if entry.date > latest { last = entry.date }
        } else {
            last = entry.date
        }
        levels[entry.level, default: 0] += 1
        senders[entry.sender.isEmpty ? "-" : entry.sender, default: 0] += 1
        processes[LogExportFormat.processTag(name: entry.process, identifier: entry.processIdentifier), default: 0] += 1
        if LogExportFormat.hasLineBreak(entry.message) { rowsWithLineBreaks += 1 }
    }
}

enum LogExportFormat {
    static let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    /// Ogni riga dell'intestazione comincia così; nessuna riga di registro può (comincia col mese).
    static let headerPrefix = "# "
    static let fileNamePrefix = "QBeats_registro_"
    static let fileNameExtension = ".txt"

    static func calendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    // MARK: - L'ora

    /// I millesimi dentro il secondo, troncati (mai arrotondati: `…35.9996` resta nel secondo 35).
    static func milliseconds(_ date: Date) -> Int {
        let seconds = date.timeIntervalSince1970
        let fraction = seconds - seconds.rounded(.down)
        return min(999, max(0, Int((fraction * 1000).rounded(.down))))
    }

    /// «Oct 11 09:22:35.500»: la forma di iMazing più i millesimi.
    static func stamp(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: date)
        let month = months[min(11, max(0, (c.month ?? 1) - 1))]
        let dayOfMonth = padded(c.day ?? 0, width: 2, with: " ")
        let thousandths = padded(milliseconds(date), width: 3, with: "0")
        return "\(month) \(dayOfMonth) \(clock(c, separator: ":")).\(thousandths)"
    }

    /// «2026-10-11 09:22:35.500 +02:00»: data intera e scarto dal tempo universale, per l'intestazione.
    static func fullStamp(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let offset = calendar.timeZone.secondsFromGMT(for: date)
        let minutes = abs(offset) / 60
        let sign = offset < 0 ? "-" : "+"
        let offsetHours = padded(minutes / 60, width: 2, with: "0")
        let offsetMinutes = padded(minutes % 60, width: 2, with: "0")
        let thousandths = padded(milliseconds(date), width: 3, with: "0")
        return "\(day(c)) \(clock(c, separator: ":")).\(thousandths) \(sign)\(offsetHours):\(offsetMinutes)"
    }

    // MARK: - La riga

    /// `QBeats[1477]`; `-[0]` per una voce che non viene da un processo.
    static func processTag(name: String, identifier: Int32) -> String {
        "\(name.isEmpty ? "-" : name)[\(identifier)]"
    }

    /// `QBeats[1477]`, oppure `QBeats(CoreMIDI)[1477]` quando la riga la scrive un'altra immagine del processo.
    static func processField(_ entry: LogExportEntry) -> String {
        if entry.sender.isEmpty || entry.sender == entry.process {
            return processTag(name: entry.process, identifier: entry.processIdentifier)
        }
        return "\(entry.process.isEmpty ? "-" : entry.process)(\(entry.sender))[\(entry.processIdentifier)]"
    }

    static func hasLineBreak(_ message: String) -> Bool {
        message.unicodeScalars.contains { $0.value == 10 || $0.value == 13 }
    }

    /// Il messaggio com'è; un a capo (`\n`, `\r`, oppure la coppia `\r\n`) diventa i due caratteri `\n`.
    static func singleLine(_ message: String) -> String {
        guard hasLineBreak(message) else { return message }
        var out = ""
        var afterCarriageReturn = false
        for scalar in message.unicodeScalars {
            if scalar.value == 13 {
                out += "\\n"
                afterCarriageReturn = true
            } else if scalar.value == 10 {
                if !afterCarriageReturn { out += "\\n" }
                afterCarriageReturn = false
            } else {
                out.unicodeScalars.append(scalar)
                afterCarriageReturn = false
            }
        }
        return out
    }

    static func line(_ entry: LogExportEntry, device: String, calendar: Calendar) -> String {
        let time = stamp(entry.date, calendar: calendar)
        return "\(time) \(device) \(processField(entry)) <\(entry.level)>: \(singleLine(entry.message))"
    }

    // MARK: - L'apparecchio e il nome del file

    /// Solo lettere e cifre ASCII: l'etichetta va nel nome del file e in una colonna che non può avere spazi.
    static func deviceLabel(_ raw: String) -> String {
        var kept = ""
        for scalar in raw.unicodeScalars {
            let v = scalar.value
            if (v >= 48 && v <= 57) || (v >= 65 && v <= 90) || (v >= 97 && v <= 122) {
                kept.unicodeScalars.append(scalar)
            }
        }
        return kept.isEmpty ? "device" : kept
    }

    /// «QBeats_registro_iPhone_2026-10-11_09-22-35.txt»: l'apparecchio e data-ora locali dell'esportazione.
    static func fileName(device: String, date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return "\(fileNamePrefix)\(device)_\(day(c))_\(clock(c, separator: "-"))\(fileNameExtension)"
    }

    // MARK: - L'intestazione

    /// Le righe d'intestazione, una per elemento, senza a capo. `righe` conta le righe di registro che seguono.
    static func header(info: LogExportInfo, tally: LogExportTally, exportedAt: Date, calendar: Calendar) -> [String] {
        let firstRow = tally.first.map { fullStamp($0, calendar: calendar) } ?? "-"
        let lastRow = tally.last.map { fullStamp($0, calendar: calendar) } ?? "-"
        let lines: [String] = [
            "Q-BEATS registro esportato dall'app",
            "apparecchio: \(info.device)",
            "sistema: \(info.systemName) \(info.systemVersion)",
            "app: \(info.appVersion) build \(info.appBuild)",
            "processo: \(processTag(name: info.processName, identifier: info.processIdentifier))",
            "esportazione: \(fullStamp(exportedAt, calendar: calendar))",
            "righe: \(tally.rows)",
            "prima riga: \(firstRow)",
            "ultima riga: \(lastRow)",
            "livelli: \(counts(tally.levels))",
            "immagini: \(counts(tally.senders))",
            "processi: \(counts(tally.processes))",
            "righe con a capo interni: \(tally.rowsWithLineBreaks)",
            "fine intestazione",
        ]
        return lines.map { headerPrefix + $0 }
    }

    /// «Notice 1200; Error 3»: dal conto più alto al più basso, a parità per nome; «-» se non c'è niente.
    static func counts(_ values: [String: Int]) -> String {
        guard !values.isEmpty else { return "-" }
        let ordered = values.sorted { a, b in
            a.value != b.value ? a.value > b.value : a.key < b.key
        }
        return ordered.map { "\($0.key) \($0.value)" }.joined(separator: "; ")
    }

    // MARK: - Privato

    private static func padded(_ value: Int, width: Int, with pad: Character) -> String {
        let digits = String(value)
        return String(repeating: pad, count: max(0, width - digits.count)) + digits
    }

    private static func clock(_ c: DateComponents, separator: String) -> String {
        let hour = padded(c.hour ?? 0, width: 2, with: "0")
        let minute = padded(c.minute ?? 0, width: 2, with: "0")
        let second = padded(c.second ?? 0, width: 2, with: "0")
        return "\(hour)\(separator)\(minute)\(separator)\(second)"
    }

    private static func day(_ c: DateComponents) -> String {
        let year = padded(c.year ?? 0, width: 4, with: "0")
        let month = padded(c.month ?? 0, width: 2, with: "0")
        let dayOfMonth = padded(c.day ?? 0, width: 2, with: "0")
        return "\(year)-\(month)-\(dayOfMonth)"
    }
}
#endif
