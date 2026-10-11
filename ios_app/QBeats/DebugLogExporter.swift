#if DEBUG
import Foundation
import OSLog
import os
import UIKit

// === A402 (11/10/2026) — REGISTRO ESPORTATO DALL'APP ===
// L'app rilegge le proprie righe di registro e le salva in un file di testo da condividere (foglio di condivisione
// di iOS), così un registro si prende da qualunque apparecchio senza iMazing collegato. Le righe restano `os_log`,
// come oggi (Costituzione §6): qui si leggono soltanto, con `OSLogStore` e lo scope del processo corrente
// (`OSLogStore.Scope.currentProcessIdentifier`, iOS 15.0 e oltre; l'altro scope, `.system`, è solo macOS).
// Si scrive TUTTO quello che lo scope rende, non solo le righe `[Q-BEATS]`, senza posizione di partenza e senza
// filtro. La forma del file sta in `Models/LogExportFormat.swift`, col suo banco.
// Dove gira: lettura e scrittura su una coda propria, seriale, a priorità bassa: mai sul main, mai sul thread
// audio. I dati che vengono da UIKit (`currentInfo`) si leggono sul main, prima di passare alla coda.
// Le tre righe `[SONDA]` scritte a ogni esportazione servono al collaudo: una per livello (Debug, Info, Notice),
// l'ultima con una stringa pubblica, una privata e un numero. Dicono, rilette, quali livelli lo scope rende e se i
// valori escono interi o mascherati. Una sonda può non essere ancora leggibile nell'esportazione che la scrive:
// allora si legge nella successiva.
// Tutto il file è `#if DEBUG`, come la schermata che lo usa.
enum DebugLogExporter {
    struct Outcome {
        let url: URL
        let rows: Int
        let bytes: Int
        let seconds: TimeInterval
    }

    private static let queue = DispatchQueue(label: "com.bullfrog.qbeats.registro", qos: .utility)

    /// I dati dell'intestazione che non vengono dalle righe. `device`: dal tipo d'interfaccia («iPhone», «iPad»);
    /// su un altro tipo, `UIDevice.model` ridotto a lettere e cifre.
    @MainActor static func currentInfo() -> LogExportInfo {
        let device = UIDevice.current
        let label: String
        switch device.userInterfaceIdiom {
        case .phone: label = "iPhone"
        case .pad: label = "iPad"
        default: label = LogExportFormat.deviceLabel(device.model)
        }
        let bundle = Bundle.main.infoDictionary
        let process = ProcessInfo.processInfo
        return LogExportInfo(device: label,
                             systemName: device.systemName,
                             systemVersion: device.systemVersion,
                             appVersion: bundle?["CFBundleShortVersionString"] as? String ?? "?",
                             appBuild: bundle?["CFBundleVersion"] as? String ?? "?",
                             processName: process.processName,
                             processIdentifier: process.processIdentifier)
    }

    /// Rilegge il registro del processo e lo scrive in un file nella cartella temporanea dell'app.
    static func export(info: LogExportInfo) async throws -> Outcome {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try readAndWrite(info: info))
                } catch {
                    os_log("[Q-BEATS][REGISTRO] esportazione fallita: %{public}@", log: .default, type: .error,
                           error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func readAndWrite(info: LogExportInfo) throws -> Outcome {
        let started = Date()
        os_log("[Q-BEATS][REGISTRO] esportazione avviata apparecchio:%{public}@", log: .default, type: .default,
               info.device)
        os_log("[Q-BEATS][REGISTRO][SONDA] livello:debug", log: .default, type: .debug)
        os_log("[Q-BEATS][REGISTRO][SONDA] livello:info", log: .default, type: .info)
        os_log("[Q-BEATS][REGISTRO][SONDA] livello:notice pubblico:%{public}@ privato:%@ numero:%d",
               log: .default, type: .default, info.device, info.device, 121)

        let calendar = LogExportFormat.calendar(timeZone: TimeZone.current)
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        var tally = LogExportTally()
        var body = Data()
        for entry in try store.getEntries() {
            autoreleasepool {
                let row = exportEntry(from: entry)
                tally.add(row)
                body.append(contentsOf: LogExportFormat.line(row, device: info.device, calendar: calendar).utf8)
                body.append(0x0A)
            }
        }

        let header = LogExportFormat.header(info: info, tally: tally, exportedAt: started, calendar: calendar)
        var data = Data(header.joined(separator: "\n").utf8)
        data.append(0x0A)
        data.append(body)
        let name = LogExportFormat.fileName(device: info.device, date: started, calendar: calendar)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)

        let seconds = Date().timeIntervalSince(started)
        os_log("[Q-BEATS][REGISTRO] esportazione finita righe:%d byte:%d secondi:%.2f file:%{public}@",
               log: .default, type: .default, tally.rows, data.count, seconds, name)
        return Outcome(url: url, rows: tally.rows, bytes: data.count, seconds: seconds)
    }

    private static func exportEntry(from entry: OSLogEntry) -> LogExportEntry {
        let level: String
        if let log = entry as? OSLogEntryLog {
            level = levelName(log.level)
        } else if entry is OSLogEntrySignpost {
            level = "Signpost"
        } else if entry is OSLogEntryActivity {
            level = "Activity"
        } else if entry is OSLogEntryBoundary {
            level = "Boundary"
        } else {
            level = "Entry"
        }
        let source = entry as? OSLogEntryFromProcess
        return LogExportEntry(date: entry.date,
                              process: source?.process ?? "",
                              sender: source?.sender ?? "",
                              processIdentifier: source?.processIdentifier ?? 0,
                              level: level,
                              message: entry.composedMessage)
    }

    /// I nomi dei livelli come li scrive iMazing (`Notice` e `Error` misurati sui suoi file; gli altri sono i nomi
    /// di Apple, `OSLogEntryLog.Level`).
    private static func levelName(_ level: OSLogEntryLog.Level) -> String {
        switch level {
        case .undefined: return "Undefined"
        case .debug: return "Debug"
        case .info: return "Info"
        case .notice: return "Notice"
        case .error: return "Error"
        case .fault: return "Fault"
        @unknown default: return "Level\(level.rawValue)"
        }
    }
}
#endif
