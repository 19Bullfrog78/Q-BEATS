import Foundation
import Combine

/// Contenitore-sessione della stanza Q-Live — forma B, ratificata in
/// `LIBRO_MASTRO_QBEATS.md:285 @ 40f099bb28ad87627e3c6df926993a3df297df90`.
///
/// Possiede lo SLOT del runner, non il runner. All'ingresso nella stanza lo
/// slot è VUOTO, perché nessuna scaletta è ancora stata scelta; il runner
/// nasce allo Start con la setlist SCELTA, sopravvive alla navigazione INTERNA
/// della stanza e muore all'uscita dalla stanza.
///
/// In ⟦S4R⟧ lo slot resta VUOTO e nessuno lo riempie: il mutatore MANCA
/// APPOSTA, così lo slot è strutturalmente non riempibile invece che vuoto per
/// convenzione. Chi costruisce lo Start (⟦S5⟧) aggiunge qui il mutatore, ed è
/// il solo posto in cui il runner può nascere.
///
/// VINCOLO DI PROPAGAZIONE — verbatim da
/// `BOX3_QBEATS.md:34 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`:
/// «Un `ObservableObject` ANNIDATO dentro un altro NON propaga:
/// `QLiveSession.@Published runner` notifica solo APPARIZIONE/SCOMPARSA del
/// runner, NON i suoi cambi interni (canzone/sezione/BPM). I figli devono
/// osservare IL RUNNER (`@ObservedObject`/`@EnvironmentObject` sul runner), NON
/// la sessione — pena UI metronomo CONGELATA che sembrerebbe un bug del DSP.»
///
/// Conseguenza operativa, che è anche il solo modo corretto di usare questa
/// classe: la si osserva SOLO per sapere se il runner c'è — apparizione e
/// scomparsa sono l'unico segnale che sa dare. ⛔ Nessun figlio legga MAI
/// il runner ATTRAVERSO il contenitore-sessione: compila, SEMBRA GIUSTA, ed è
/// il difetto descritto sopra.
@MainActor
final class QLiveSession: ObservableObject {

    /// Slot del runner. `nil` = nessuna scaletta in esecuzione.
    /// `private(set)` e senza mutatore: in ⟦S4R⟧ non è riempibile da nessuno.
    @Published private(set) var runner: SetlistRunner? = nil
}
