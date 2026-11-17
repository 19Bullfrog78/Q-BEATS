import Foundation

// === A435 (16/11/2026) — LA (b): IL PLAY DOPO UN CONTO NON CERTO, IL TEMPO CHE COMBACIA ===
// Mandato A435, par. 4 e; il disegno: referto A431 par. 3.2 e referto A424 par. 2.2 f; la decisione 9.5 del LIBRO_MASTRO
// (la ripartenza). Quando l'iPad del Follower ha taciuto perché non sapeva più dove fosse la band (il segno del
// silenzio del conto, `OutputSilenceState.uncertainSilence`), al Play dopo del Direttore riparte solo se il tempo
// della sessione combacia col tempo della PRIMA sezione della canzone che ha davanti: se non combacia la band sta
// suonando un'altra canzone, e l'iPad resta zitto (mai un click sbagliato).
// La tolleranza è un decimo di BPM: il richiamo del tempo di Link porta valori come 120,9999 per 121 (referto A424
// par. 2.2 f, il richiamo dell'01/11). Un tempo che non si sa (la consegna non è arrivata) o non valido non combacia:
// non si può dire che la canzone è la stessa.
// Regola pura, solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro (Costituzione V6, par. 4:
// si decide sulla coda del motore, al richiamo del Play, mai nel callback di render).

/// L'ingresso dell'evento del Play nella macchina del Follower (`FollowerSyncEvent.linkPlay`).
enum FollowerPlayTempo: String, Equatable {
    /// Il segno del silenzio è basso: il confronto non si fa, il Play vale come sempre.
    case notAsked
    /// Il segno è alto e il tempo combacia: l'iPad può ripartire.
    case matches
    /// Il segno è alto e il tempo non combacia: l'iPad non parte.
    case differs
}

enum BandTempoMatchDecision {

    /// Un decimo di BPM.
    static let toleranceBpm: Double = 0.1
    /// Il margine del confronto in virgola mobile: 121,1 − 121 non è esattamente un decimo.
    /// ⚠️ CORRETTO A435 · SEGUITO 3 (16/11/2026; seguito 3 di A435, par. 5 b; nota 2 del verificatore B2-M del referee).
    /// L'esempio qui sopra non regge: 121,1 − 121 in virgola mobile fa 0,09999999999999432, sotto il decimo, e combacia
    /// anche senza margine. L'esempio giusto: 60,1 − 60 fa 0,10000000000000142, sopra il decimo di un soffio; senza
    /// margine un decimo esatto non combacerebbe (`BandTempoMatchDecisionTests`, i bordi del decimo).
    static let comparisonSlackBpm: Double = 1.0e-9

    /// Il tempo della sessione combacia col tempo della prima sezione della canzone?
    static func matches(sessionBpm: Double, songFirstBpm: Double?) -> Bool {
        guard let song = songFirstBpm, song.isFinite, song > 0, sessionBpm.isFinite, sessionBpm > 0 else {
            return false
        }
        return abs(sessionBpm - song) <= toleranceBpm + comparisonSlackBpm
    }

    /// L'ingresso per la macchina: col segno basso il confronto non si fa.
    static func check(uncertainSilence: Bool, sessionBpm: Double, songFirstBpm: Double?) -> FollowerPlayTempo {
        guard uncertainSilence else { return .notAsked }
        return matches(sessionBpm: sessionBpm, songFirstBpm: songFirstBpm) ? .matches : .differs
    }
}
