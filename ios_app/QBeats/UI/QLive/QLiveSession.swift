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
/// ⚠️ MARCATURA 23/08 — LA CONDIZIONE QUI SOPRA SI È AVVERATA IL 19/08/2026.
/// Il mutatore c'è: `install(_:)`, più sotto in questo stesso file,
/// introdotto dal commit `7c04bea` («S5b: Start del dettaglio show»).
/// ⛔ NON leggere al presente «il mutatore MANCA APPOSTA»: descrive perché lo
/// slot NACQUE senza mutatore, ed è ancora la ragione per cui `install(_:)` è
/// il solo posto in cui il runner può nascere.
/// ⚠️ Chi arriva qui per ⟦S-EXIT⟧ — «lo stato dello show appartiene allo show,
/// non alla schermata» — legga: la stanza PUÒ tenere lo stato. Lo tiene già.
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
    /// `private(set)`: da ⟦S5b⟧ si riempie SOLO da `install(_:)` qui sotto.
    @Published private(set) var runner: SetlistRunner? = nil

    /// ⟦S5b⟧ — MUTATORE DELLO SLOT: la porta che ⟦S4R⟧ aveva lasciato mancante
    /// APPOSTA (:12-15). È il solo punto in cui il runner entra nella stanza.
    ///
    /// ⛔ SOSTITUISCE SEMPRE, ANCHE A SLOT PIENO — ed è una scelta, non una
    /// distrazione. Un `if runner == nil` qui riuserebbe il runner del PRIMO show
    /// quando la band ne apre un SECONDO nella stessa serata: partirebbe la
    /// scaletta sbagliata. L'assegnazione secca è l'unica forma che non sa
    /// sbagliare. Il vecchio runner perde qui il suo ultimo riferimento forte.
    ///
    /// ⛔ INSTALLA E BASTA: non avvia l'audio, non arma nulla, non tocca
    /// AudioEngine. Contratto `BOX5_QBEATS.md:331` (QL-SHOWS-07) e
    /// `BOX5_QBEATS.md:354` (§3): l'ingresso in uno show è SEMPRE arma + standby,
    /// il click parte al SECONDO tap. L'armamento vive in
    /// `SetlistRunner.primeDisplay(session:)`, che gira nell'`onAppear` del player.
    ///
    /// ⚠️ L'INVARIANTE DEL CHIAMANTE È LA SINCRONIA, non l'ordine (⟦S5b⟧ `Cond (a)`,
    /// come corretta dal referee): questa chiamata e la `navigate(to: .metronome)`
    /// che la segue devono stare nella STESSA closure e SENZA alcuna attesa in
    /// mezzo — niente `Task`, niente `async`, niente `asyncAfter`. SwiftUI non
    /// ridisegna fra due assegnazioni sincrone, quindi il ramo `else` del gate
    /// `if let runner` non può apparire. Basta un'attesa a spezzare la garanzia:
    /// lì il ramo `else` diventa visibile. L'ordine si rispetta comunque — costa
    /// nulla — ma non è lui a proteggere.
    func install(_ newRunner: SetlistRunner) {
        runner = newRunner
    }
}
