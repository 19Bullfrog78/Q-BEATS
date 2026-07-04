import Foundation

// === B7-A5a — Modalità del METRONOMO (off / fixed / adaptive) ===
// Dominio METRONOMO: come suona il click per una canzone. NON è il ruolo Link
// (Standalone/Direttore/Follower — altro enum, altro dominio).
// TRE casi (decisione Mauro 04/07, aggiorna il piano che ne diceva 2):
// fixed↔adaptive mappano sul booleano DSP `_adaptiveActive`
// (MetronomeDSP.h:179); `off` = click SOPPRESSO A MONTE (gestione play: solo
// backing, niente click) — scenario da palco reale, NON uno stato del DSP.
// Raw value String ESPLICITI: il valore serializzato è contratto stabile dei
// file utente, resistente ai rinomini dei case. Song.metronomeMode arriva con
// l'atomo A5b (decoder retro-compat `decodeIfPresent ?? .fixed`, ruling ⑤) —
// NON qui: in A5a il tipo è inerte, nessun consumatore.
enum MetronomeMode: String, Codable, Equatable, CaseIterable {
    case off = "off"
    case fixed = "fixed"
    case adaptive = "adaptive"
}
