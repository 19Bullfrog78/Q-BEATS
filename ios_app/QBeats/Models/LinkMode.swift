import Foundation

// A360 (16/09/2026) — L'ENUM DEL RUOLO VIVE IN `Models/`, non più in `AppSettings.swift`.
// Trasloco senza una parola cambiata (i tre commenti sono quelli di prima): la regola del
// Follower (`FollowerDecision`) lo legge, e il banco `QBeatsTests` compila SOLO
// `QBeats/Models` (`ios_app/project.yml`, target QBeatsTests) — da `AppSettings.swift`
// non lo avrebbe visto. `AppSettings` continua a usarlo tale e quale: stesso modulo.
enum LinkMode: String, Codable {
    case standalone      // Solo — NUOVO DEFAULT: Q-BEATS suona il proprio click, NON comanda NON segue i peer.
                         // Isolamento = Link OFF (linkEnabled default false). RUOLO scelto, ≠ stato-connessione "nessun peer".
    case direttore       // Q-BEATS sorgente unica autoritativa: detta start/stop, BPM, phase.
                         // Ignora SEMPRE input dai peer — in play e in stop. Timeline e tempo
                         // imposti dal Director, i peer si adeguano.
    case collaborativa   // Standard Link peer-to-peer. Q-BEATS accetta tutto dai peer.
}
