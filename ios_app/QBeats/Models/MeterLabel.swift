import Foundation

// === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — LA METRICA IN TESTATA, DAI DUE NUMERI DELLA SEZIONE ===
// Fino a oggi la testata la ricavava `LiveView.timeSigString(for:)` dal solo numero di battiti:
// denominatore 8 per 6 e 12, 4 per tutto il resto. Così un 6/4 si leggeva «6/8» e 5/8, 7/8, 9/8,
// 11/8 si leggevano con «/4» (A393 §2.3; metriche della lista chiusa, `TimeSignature.all`).
// La sezione porta anche il denominatore (`SongSection.beatUnit`): la scritta si fa da lì, sempre,
// senza passare dalla lista delle metriche, così ogni metrica ha la sua scritta anche fuori dalla
// lista (A393 §9, caso 14). I punti di scrittura restano i tre di oggi, in `LiveView`.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum MeterLabel {

    /// Il denominatore che `SongSection` dà a una sezione che non lo dichiara (`init`,
    /// `beatUnit: UInt32 = 4`, e la decodifica dei JSON vecchi). Lo usa chi scrive la metrica
    /// quando la sezione del runner non si risolve.
    static let defaultBeatUnit: UInt32 = 4

    /// «beatsPerBar/beatUnit», così come la sezione li porta.
    static func text(beatsPerBar: UInt32, beatUnit: UInt32) -> String {
        "\(beatsPerBar)/\(beatUnit)"
    }
}
