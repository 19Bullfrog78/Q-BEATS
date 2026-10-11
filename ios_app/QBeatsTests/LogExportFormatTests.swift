#if DEBUG
import XCTest

// === A402 — banco della forma del registro esportato dall'app (banco Models) ===
// La riga ha la forma dei registri di iMazing più i millesimi; l'apparecchio è «iPhone» o «iPad»; il messaggio è
// scritto com'è. Le righe di confronto sono prese verbatim dai registri di iMazing: tre dal collaudo dell'11/10/2026
// (`LOG_COLLAUDI/COLLAUDO A401 REV20/REV20_P1-2_iPhone.txt`, righe 1, 2 e 14), una dal collaudo dell'08/10
// (`LOG_COLLAUDI/COLLAUDO A398 M3/A398_P1-4_iPhone.txt`). Le frazioni di secondo usate qui
// sono esatte in binario (0,5 · 0,25 · 0,125 · 0,75 · 0,875 · 1023/1024): così i millesimi attesi vengono dalla
// regola (troncare), non dall'arrotondamento di un numero in virgola mobile.

final class LogExportFormatTests: XCTestCase {

    private let rome = LogExportFormat.calendar(timeZone: TimeZone(identifier: "Europe/Rome")!)
    private let utc = LogExportFormat.calendar(timeZone: TimeZone(identifier: "UTC")!)

    private let iMazingRow1 =
        "Oct 11 09:22:35 Bullfrog-13 QBeats[1477] <Notice>: [Q-BEATS][SOLO-M3][VELO] tocco schermo:V esito:runner.startCurrentSong"
    private let iMazingRow2 =
        #"Oct 11 09:22:35 Bullfrog-13 QBeats[1477] <Notice>: [Q-BEATS][L1.b] startCurrentSong \M-b\M^@\M^T songIdx:1 sectionIdx:0"#
    private let iMazingRow14 =
        #"Oct 11 09:22:35 Bullfrog-13 QBeats[1477] <Notice>: [Q-BEATS][SOLO-M3][SCHERMO] schermo:V sezioneIdx:0 sezione:Verse nomeCorpo:0 nomeRighe:0 puntini:no tempo:120 \M-B\M-7 4/4 testata:COLLAUDO SOLO REV20"#
    /// `LOG_COLLAUDI/COLLAUDO A398 M3/A398_P1-4_iPhone.txt`: giorno a una cifra e una «à» (`\M-C\240`).
    private let iMazingRowOctal =
        #"Oct  8 11:34:35 Bullfrog-13 QBeats[38138] <Notice>: [Q-BEATS][INTERRUPTION] began \M-b\M^@\M^T engine gi\M-C\240 fermo, noop"#

    /// Un istante in ora di Roma, più una frazione di secondo.
    private func romeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int,
                          plus fraction: Double = 0) -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        return rome.date(from: parts)!.addingTimeInterval(fraction)
    }

    private func entry(_ date: Date, _ message: String, level: String = "Notice", process: String = "QBeats",
                       sender: String = "QBeats", pid: Int32 = 1477) -> LogExportEntry {
        LogExportEntry(date: date, process: process, sender: sender, processIdentifier: pid, level: level,
                       message: message)
    }

    /// iMazing scrive i byte non ASCII per byte, in tre forme (misurate sui suoi file: 219.216 righe, 604.406
    /// sequenze, nessuna riga che decodificata non sia UTF-8): `\M-c` = il byte di `c` più 0x80; `\M^c` = il byte di
    /// `c` XOR 0x40, più 0x80; `\ooo` = il byte in ottale (`\240` = 0xA0). Qui il cammino inverso, per confrontare.
    private func decodedFromIMazing(_ text: String) -> String {
        let bytes = Array(text.utf8)
        var out: [UInt8] = []
        var i = 0
        func isOctal(_ byte: UInt8) -> Bool { byte >= 0x30 && byte <= 0x37 }
        while i < bytes.count {
            let isEscape = i + 3 < bytes.count && bytes[i] == 0x5C && bytes[i + 1] == 0x4D
            if isEscape && bytes[i + 2] == 0x2D {
                out.append(bytes[i + 3] | 0x80)
                i += 4
            } else if isEscape && bytes[i + 2] == 0x5E {
                out.append((bytes[i + 3] ^ 0x40) | 0x80)
                i += 4
            } else if i + 3 < bytes.count && bytes[i] == 0x5C && isOctal(bytes[i + 1]) && isOctal(bytes[i + 2])
                        && isOctal(bytes[i + 3]) {
                let value = Int(bytes[i + 1] - 0x30) * 64 + Int(bytes[i + 2] - 0x30) * 8 + Int(bytes[i + 3] - 0x30)
                out.append(UInt8(value & 0xFF))
                i += 4
            } else {
                out.append(bytes[i])
                i += 1
            }
        }
        return String(decoding: out, as: UTF8.self)
    }

    /// La riga esportata riportata alla forma di iMazing: via i millesimi, dentro il nome dell'apparecchio.
    private func asIMazing(_ row: String, thousandths: String, device: String, name: String) -> String {
        row.replacingOccurrences(of: ".\(thousandths) \(device) ", with: " \(name) ")
    }

    // MARK: - La riga

    func testARowHasTheFormOfIMazingPlusTheThousandths() {
        let message = "[Q-BEATS][SOLO-M3][VELO] tocco schermo:V esito:runner.startCurrentSong"
        let row = LogExportFormat.line(entry(romeDate(2026, 10, 11, 9, 22, 35, plus: 0.5), message),
                                       device: "iPhone", calendar: rome)
        XCTAssertEqual(row, "Oct 11 09:22:35.500 iPhone QBeats[1477] <Notice>: " + message)
        XCTAssertEqual(asIMazing(row, thousandths: "500", device: "iPhone", name: "Bullfrog-13"), iMazingRow1,
                       "tolti i millesimi e rimesso il nome dell'apparecchio, è la riga di iMazing")
    }

    func testTheMessageIsWrittenAsItIsWhereIMazingWritesBytes() {
        let dash = "[Q-BEATS][L1.b] startCurrentSong \u{2014} songIdx:1 sectionIdx:0"
        let dot = "[Q-BEATS][SOLO-M3][SCHERMO] schermo:V sezioneIdx:0 sezione:Verse nomeCorpo:0 nomeRighe:0 "
            + "puntini:no tempo:120 \u{B7} 4/4 testata:COLLAUDO SOLO REV20"
        let date = romeDate(2026, 10, 11, 9, 22, 35, plus: 0.125)
        let rowDash = LogExportFormat.line(entry(date, dash), device: "iPhone", calendar: rome)
        let rowDot = LogExportFormat.line(entry(date, dot), device: "iPhone", calendar: rome)
        XCTAssertTrue(rowDash.hasSuffix(dash))
        XCTAssertTrue(rowDot.hasSuffix(dot))
        XCTAssertEqual(Array("\u{2014}".utf8), [0xE2, 0x80, 0x94], "«—» in UTF-8: i tre byte che iMazing scrive \\M-b\\M^@\\M^T")
        XCTAssertEqual(Array("\u{B7}".utf8), [0xC2, 0xB7], "«·» in UTF-8: i due byte che iMazing scrive \\M-B\\M-7")
        // La riga di iMazing, riportati i byte a caratteri, è la riga esportata senza millesimi.
        XCTAssertEqual(asIMazing(rowDash, thousandths: "125", device: "iPhone", name: "Bullfrog-13"),
                       decodedFromIMazing(iMazingRow2))
        XCTAssertEqual(asIMazing(rowDot, thousandths: "125", device: "iPhone", name: "Bullfrog-13"),
                       decodedFromIMazing(iMazingRow14))
        // Giorno a una cifra, un altro numero di processo, «—» e «à» nella stessa riga.
        let accent = "[Q-BEATS][INTERRUPTION] began \u{2014} engine gi\u{E0} fermo, noop"
        let rowAccent = LogExportFormat.line(entry(romeDate(2026, 10, 8, 11, 34, 35, plus: 0.75), accent, pid: 38138),
                                             device: "iPhone", calendar: rome)
        XCTAssertEqual(rowAccent, "Oct  8 11:34:35.750 iPhone QBeats[38138] <Notice>: " + accent)
        XCTAssertEqual(asIMazing(rowAccent, thousandths: "750", device: "iPhone", name: "Bullfrog-13"),
                       decodedFromIMazing(iMazingRowOctal))
    }

    func testTheDayTakesTwoPlacesWithASpaceInFront() {
        // iMazing: «Oct  8», «Sep  9», «Jul  3» (due spazi), «Oct 11».
        XCTAssertEqual(LogExportFormat.stamp(romeDate(2026, 10, 8, 7, 5, 9, plus: 0.25), calendar: rome),
                       "Oct  8 07:05:09.250")
        XCTAssertEqual(LogExportFormat.stamp(romeDate(2026, 9, 9, 12, 52, 10), calendar: rome), "Sep  9 12:52:10.000")
        XCTAssertEqual(LogExportFormat.stamp(romeDate(2026, 10, 11, 23, 59, 59), calendar: rome), "Oct 11 23:59:59.000")
    }

    func testTheMonthsAreTheEnglishOnes() {
        XCTAssertEqual(LogExportFormat.months,
                       ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
        for month in 1...12 {
            let stamp = LogExportFormat.stamp(romeDate(2026, month, 15, 12, 0, 0), calendar: rome)
            XCTAssertEqual(stamp, "\(LogExportFormat.months[month - 1]) 15 12:00:00.000")
        }
    }

    func testTheThousandthsAreTruncatedNeverRounded() {
        let base = romeDate(2026, 10, 11, 9, 22, 35)
        XCTAssertEqual(LogExportFormat.milliseconds(base), 0)
        XCTAssertEqual(LogExportFormat.milliseconds(base.addingTimeInterval(0.875)), 875)
        XCTAssertEqual(LogExportFormat.milliseconds(base.addingTimeInterval(1023.0 / 1024.0)), 999)
        // 0,9990234375 s dopo le 09:22:35 è ancora il secondo 35: niente riporto al 36.
        XCTAssertEqual(LogExportFormat.stamp(base.addingTimeInterval(1023.0 / 1024.0), calendar: rome),
                       "Oct 11 09:22:35.999")
        XCTAssertEqual(LogExportFormat.stamp(base, calendar: rome), "Oct 11 09:22:35.000")
    }

    func testTheTimeIsTheLocalOne() {
        // L'11 ottobre a Roma è ora legale (due ore avanti); il 15 gennaio no (un'ora avanti).
        let autumn = romeDate(2026, 10, 11, 9, 22, 35, plus: 0.5)
        XCTAssertEqual(LogExportFormat.stamp(autumn, calendar: rome), "Oct 11 09:22:35.500")
        XCTAssertEqual(LogExportFormat.stamp(autumn, calendar: utc), "Oct 11 07:22:35.500")
        let winter = romeDate(2026, 1, 15, 9, 0, 0)
        XCTAssertEqual(LogExportFormat.stamp(winter, calendar: utc), "Jan 15 08:00:00.000")
        // Lo stesso istante a cavallo della mezzanotte cambia giorno con la zona.
        let night = romeDate(2026, 10, 9, 0, 30, 0)
        XCTAssertEqual(LogExportFormat.stamp(night, calendar: rome), "Oct  9 00:30:00.000")
        XCTAssertEqual(LogExportFormat.stamp(night, calendar: utc), "Oct  8 22:30:00.000")
    }

    func testTheProcessFieldNamesTheImageOnlyWhenItIsAnotherOne() {
        let date = romeDate(2026, 10, 11, 9, 22, 35)
        XCTAssertEqual(LogExportFormat.processField(entry(date, "x")), "QBeats[1477]")
        XCTAssertEqual(LogExportFormat.processField(entry(date, "x", sender: "")), "QBeats[1477]")
        // Forma misurata sui registri di iMazing: «audiomxd(MediaExperience)[…]».
        XCTAssertEqual(LogExportFormat.processField(entry(date, "x", sender: "CoreMIDI")), "QBeats(CoreMIDI)[1477]")
        XCTAssertEqual(LogExportFormat.processField(entry(date, "x", process: "", sender: "", pid: 0)), "-[0]")
        XCTAssertEqual(LogExportFormat.line(entry(date, "x", level: "Error", sender: "CoreMIDI"), device: "iPad",
                                            calendar: rome),
                       "Oct 11 09:22:35.000 iPad QBeats(CoreMIDI)[1477] <Error>: x")
    }

    func testOneEntryIsOneRow() {
        XCTAssertEqual(LogExportFormat.singleLine("uno\ndue"), "uno\\ndue")
        XCTAssertEqual(LogExportFormat.singleLine("uno\r\ndue"), "uno\\ndue", "la coppia vale un a capo solo")
        XCTAssertEqual(LogExportFormat.singleLine("uno\rdue"), "uno\\ndue")
        XCTAssertEqual(LogExportFormat.singleLine("uno\n\ndue"), "uno\\n\\ndue")
        XCTAssertEqual(LogExportFormat.singleLine("uno\r\rdue"), "uno\\n\\ndue")
        XCTAssertEqual(LogExportFormat.singleLine("in coda\n"), "in coda\\n")
        XCTAssertEqual(LogExportFormat.singleLine("senza a capo \u{2014} \u{B7}"), "senza a capo \u{2014} \u{B7}")
        XCTAssertTrue(LogExportFormat.hasLineBreak("uno\r\ndue"))
        XCTAssertFalse(LogExportFormat.hasLineBreak("uno due"))
        let row = LogExportFormat.line(entry(romeDate(2026, 10, 11, 9, 22, 35), "uno\r\ndue\ntre"), device: "iPhone",
                                       calendar: rome)
        XCTAssertEqual(row, "Oct 11 09:22:35.000 iPhone QBeats[1477] <Notice>: uno\\ndue\\ntre")
        XCTAssertFalse(LogExportFormat.hasLineBreak(row))
    }

    // MARK: - L'apparecchio e il nome del file

    func testTheDeviceLabelKeepsAsciiLettersAndDigits() {
        XCTAssertEqual(LogExportFormat.deviceLabel("iPhone"), "iPhone")
        XCTAssertEqual(LogExportFormat.deviceLabel("iPad"), "iPad")
        XCTAssertEqual(LogExportFormat.deviceLabel("iPod touch"), "iPodtouch")
        XCTAssertEqual(LogExportFormat.deviceLabel("Bullfrog\u{2019}s iPad 13"), "BullfrogsiPad13")
        XCTAssertEqual(LogExportFormat.deviceLabel(""), "device")
        XCTAssertEqual(LogExportFormat.deviceLabel(" \u{2014} "), "device")
    }

    func testTheFileNameCarriesTheDeviceAndTheLocalDateAndTime() {
        let date = romeDate(2026, 10, 11, 9, 22, 35, plus: 0.5)
        XCTAssertEqual(LogExportFormat.fileName(device: "iPhone", date: date, calendar: rome),
                       "QBeats_registro_iPhone_2026-10-11_09-22-35.txt")
        XCTAssertEqual(LogExportFormat.fileName(device: "iPad", date: date, calendar: utc),
                       "QBeats_registro_iPad_2026-10-11_07-22-35.txt")
        XCTAssertEqual(LogExportFormat.fileName(device: "iPad", date: romeDate(2026, 1, 5, 7, 4, 9), calendar: rome),
                       "QBeats_registro_iPad_2026-01-05_07-04-09.txt")
        let name = LogExportFormat.fileName(device: LogExportFormat.deviceLabel("iPod touch"), date: date, calendar: rome)
        let allowed = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-")
        XCTAssertTrue(name.allSatisfy { allowed.contains($0) }, "niente spazi né segni che un file non regge: \(name)")
    }

    // MARK: - L'intestazione

    func testTheFullStampCarriesTheDateAndTheOffset() {
        let date = romeDate(2026, 10, 11, 9, 22, 35, plus: 0.5)
        XCTAssertEqual(LogExportFormat.fullStamp(date, calendar: rome), "2026-10-11 09:22:35.500 +02:00")
        XCTAssertEqual(LogExportFormat.fullStamp(date, calendar: utc), "2026-10-11 07:22:35.500 +00:00")
        let newYork = LogExportFormat.calendar(timeZone: TimeZone(identifier: "America/New_York")!)
        XCTAssertEqual(LogExportFormat.fullStamp(date, calendar: newYork), "2026-10-11 03:22:35.500 -04:00")
        let kolkata = LogExportFormat.calendar(timeZone: TimeZone(identifier: "Asia/Kolkata")!)
        XCTAssertEqual(LogExportFormat.fullStamp(date, calendar: kolkata), "2026-10-11 12:52:35.500 +05:30")
        XCTAssertEqual(LogExportFormat.fullStamp(romeDate(2026, 1, 15, 9, 0, 0), calendar: rome),
                       "2026-01-15 09:00:00.000 +01:00")
    }

    func testTheHeaderSaysWhereWhenAndHowMany() {
        var tally = LogExportTally()
        tally.add(entry(romeDate(2026, 10, 11, 8, 49, 54, plus: 0.125), "[Q-BEATS][A345] dettaglio montato"))
        tally.add(entry(romeDate(2026, 10, 11, 8, 49, 55), "riga\ncon a capo", level: "Error", sender: "CoreMIDI"))
        // Una voce più vecchia arrivata dopo: prima e ultima riga non dipendono dall'ordine d'arrivo.
        tally.add(entry(romeDate(2026, 10, 11, 8, 49, 53, plus: 0.75), "store", level: "Info"))
        let info = LogExportInfo(device: "iPhone", systemName: "iOS", systemVersion: "27.0.1", appVersion: "1.0",
                                 appBuild: "142", processName: "QBeats", processIdentifier: 1477)
        let header = LogExportFormat.header(info: info, tally: tally,
                                            exportedAt: romeDate(2026, 10, 11, 9, 57, 0, plus: 0.5), calendar: rome)
        XCTAssertEqual(header, [
            "# Q-BEATS registro esportato dall'app",
            "# apparecchio: iPhone",
            "# sistema: iOS 27.0.1",
            "# app: 1.0 build 142",
            "# processo: QBeats[1477]",
            "# esportazione: 2026-10-11 09:57:00.500 +02:00",
            "# righe: 3",
            "# prima riga: 2026-10-11 08:49:53.750 +02:00",
            "# ultima riga: 2026-10-11 08:49:55.000 +02:00",
            "# livelli: Error 1; Info 1; Notice 1",
            "# immagini: QBeats 2; CoreMIDI 1",
            "# processi: QBeats[1477] 3",
            "# righe con a capo interni: 1",
            "# fine intestazione",
        ])
        XCTAssertEqual(tally.rows, 3)
        XCTAssertEqual(tally.rowsWithLineBreaks, 1)
    }

    func testTheHeaderOfAnEmptyLog() {
        let info = LogExportInfo(device: "iPad", systemName: "iPadOS", systemVersion: "27.0.1", appVersion: "1.0",
                                 appBuild: "142", processName: "QBeats", processIdentifier: 257)
        let header = LogExportFormat.header(info: info, tally: LogExportTally(),
                                            exportedAt: romeDate(2026, 10, 11, 9, 57, 0), calendar: rome)
        XCTAssertEqual(header, [
            "# Q-BEATS registro esportato dall'app",
            "# apparecchio: iPad",
            "# sistema: iPadOS 27.0.1",
            "# app: 1.0 build 142",
            "# processo: QBeats[257]",
            "# esportazione: 2026-10-11 09:57:00.000 +02:00",
            "# righe: 0",
            "# prima riga: -",
            "# ultima riga: -",
            "# livelli: -",
            "# immagini: -",
            "# processi: -",
            "# righe con a capo interni: 0",
            "# fine intestazione",
        ])
    }

    func testAHeaderRowIsNeverTakenForALogRow() {
        let info = LogExportInfo(device: "iPhone", systemName: "iOS", systemVersion: "27.0.1", appVersion: "1.0",
                                 appBuild: "142", processName: "QBeats", processIdentifier: 1477)
        let header = LogExportFormat.header(info: info, tally: LogExportTally(), exportedAt: romeDate(2026, 10, 11, 9, 57, 0),
                                            calendar: rome)
        XCTAssertEqual(LogExportFormat.headerPrefix, "# ")
        XCTAssertTrue(header.allSatisfy { $0.hasPrefix("# ") })
        // Una riga di registro comincia sempre col mese, anche se il messaggio comincia con «# ».
        let row = LogExportFormat.line(entry(romeDate(2026, 10, 11, 9, 22, 35), "# non è un'intestazione"),
                                       device: "iPhone", calendar: rome)
        XCTAssertTrue(LogExportFormat.months.contains { row.hasPrefix($0 + " ") })
        XCTAssertFalse(row.hasPrefix("# "))
    }

    func testTheCountsGoFromTheHighestAndThenByName() {
        XCTAssertEqual(LogExportFormat.counts(["Notice": 5, "Error": 5, "Info": 9]), "Info 9; Error 5; Notice 5")
        XCTAssertEqual(LogExportFormat.counts(["Notice": 1200]), "Notice 1200")
        XCTAssertEqual(LogExportFormat.counts([:]), "-")
    }

    func testTheTallyCountsLevelsImagesAndProcesses() {
        var tally = LogExportTally()
        let date = romeDate(2026, 10, 11, 9, 0, 0)
        tally.add(entry(date, "a"))
        tally.add(entry(date.addingTimeInterval(1), "b"))
        tally.add(entry(date.addingTimeInterval(2), "c", level: "Boundary", process: "", sender: "", pid: 0))
        XCTAssertEqual(tally.rows, 3)
        XCTAssertEqual(tally.first, date)
        XCTAssertEqual(tally.last, date.addingTimeInterval(2))
        XCTAssertEqual(tally.levels, ["Notice": 2, "Boundary": 1])
        XCTAssertEqual(tally.senders, ["QBeats": 2, "-": 1])
        XCTAssertEqual(tally.processes, ["QBeats[1477]": 2, "-[0]": 1])
        XCTAssertEqual(tally.rowsWithLineBreaks, 0)
    }
}
#endif
