import Foundation

struct TapTempoEngine {
    // Finestra mobile dei tap recenti. 6 = buon bilancio reattività/stabilità.
    // Pro Metronome usa 4-8. Ridotto da 8 a 6 per migliorare reattività ai
    // cambi di velocità di tap (17/05/2026, Step 1.7 roadmap pre-CD).
    private let maxTaps: Int = 6

    // Tap minimi prima di restituire un BPM. 4 tap = 3 intervalli minimi per
    // una mediana significativa. Allineato a Pro Metronome (4) e best practice
    // generale; Soundbrenner usa 3, ma con 2 (precedente) il primo BPM era
    // basato su 1 solo intervallo => rumoroso. Innalzato da 2 a 4 per
    // stabilità iniziale (17/05/2026, Step 1.7).
    private let minTapsForBPM: Int = 4

    // Timeout reset: se passa più di questo tra due tap, scarta la cronologia.
    private let timeoutSeconds: Double = 2.0

    // Range BPM accettato.
    private let minBPM: Double = 40.0
    private let maxBPM: Double = 250.0

    private var timestamps: [Date] = []

    mutating func tap() -> Double? {
        let now = Date()

        if let last = timestamps.last,
           now.timeIntervalSince(last) > timeoutSeconds {
            timestamps.removeAll()
        }

        timestamps.append(now)

        if timestamps.count > maxTaps {
            timestamps.removeFirst()
        }

        guard timestamps.count >= minTapsForBPM else { return nil }

        // Calcola tutti gli intervalli tra tap consecutivi.
        var intervals: [Double] = []
        for i in 1..<timestamps.count {
            intervals.append(timestamps[i].timeIntervalSince(timestamps[i-1]))
        }

        // Mediana invece di media aritmetica: robusta contro tap outlier
        // (tap mancati, doppi accidentali, esitazioni iniziali). La mediana
        // ignora per design i valori estremi senza bisogno di un passo
        // esplicito di outlier rejection. (17/05/2026, Step 1.7 — era media
        // aritmetica semplice, sostituita dopo confronto con best practice
        // tap tempo: vedi roadmap pre-CD.)
        let sorted = intervals.sorted()
        let medianInterval: Double
        if sorted.count % 2 == 0 {
            // Finestra pari: media dei 2 valori centrali.
            medianInterval = (sorted[sorted.count/2 - 1] + sorted[sorted.count/2]) / 2.0
        } else {
            // Finestra dispari: valore centrale puro.
            medianInterval = sorted[sorted.count / 2]
        }

        let bpm = 60.0 / medianInterval

        guard bpm >= minBPM && bpm <= maxBPM else {
            timestamps.removeAll()
            return nil
        }

        return bpm
    }

    mutating func reset() {
        timestamps.removeAll()
    }
}
