import SwiftUI

/// Contenitore di Q-Live (performance) — specchio esatto di `QStageRootView`.
/// È la RADICE in-tree di Q-Live: raggiunta per commutazione di schermata da
/// `AppRootView` (`switch screen` → `.qLive`), NON come modale UIKit.
///
/// Nodo A: `QLiveRootView` POSSIEDE il seam `onExit` (hookpoint unico) e lo
/// INOLTRA alla gerarchia della stanza (da S4b: `QLiveShowsView`, che lo cabla
/// a `RoomSwitchBar.onHome`). NON costruisce mai `{ screen = .home }` né
/// `{ screen = .qStage }` — quelle closure vivono solo in `AppRootView`
/// (`Screen` è `private enum` di quel file, E2).
///
/// S4b (flip della root): la root interna è `QLiveShowsView` (frame ② Shows);
/// la navigazione INTERNA della stanza è `page` + funnel `navigate(to:)`.
/// I rami `.detail`/`.metronome` sono scaffold (EmptyView): i mutatori
/// arrivano con S5/S6; S4L innesterà la sessione/runner nel ramo `.metronome`.
///
/// INVARIANTI (gate Nodo A — non derogabili):
///  - resta IN-TREE: MAI reintrodurre uno `UIHostingController` qui.
///  - montaggio via `switch` da AppRootView (condizionale) = sottoalbero
///    distrutto all'uscita dalla stanza. VIETATO ripiegare su un overlay
///    always-on (persisterebbe un runner stale). Il divieto vale DOPPIO da
///    S4L, quando la proprietà del runner sale alla stanza (BOX3 V97 (a)):
///    è proprio lì che la scorciatoia «overlay sempre montato» diventa
///    strutturalmente attraente.
///  - «mai il player senza runner iniettato» RESTA IN VIGORE: a S4b il player
///    NON è montato affatto (ramo `.metronome` = EmptyView). L'emendamento
///    formale della lettera storica («renderizza `LiveRootView`, MAI `LiveView`
///    diretto») è ATTESO A S4L (BOX3 V97 (e)) e NON è anticipato qui.
struct QLiveRootView: View {
    let onExit: () -> Void
    /// Switch di stanza → Q-Stage. Iniettata da AppRootView
    /// (`{ screen = .qStage }` ESPLICITO, non un toggle).
    let onSwitchToStage: () -> Void

    /// Navigazione INTERNA della stanza — specchio esatto di `Screen` in
    /// AppRootView: enum NIDIFICATO, CASE-ONLY (Equatable auto-sintetizzato).
    /// L'eventuale payload (selected show, S5) vivrà in un `@State` SEPARATO,
    /// MAI dentro l'enum.
    private enum QLivePage { case shows, detail, metronome }

    @State private var page: QLivePage = .shows

    // DECISIONE CD 18/07 (ratificata — LIBRO Sez.2, riga 18/07/2026):
    // navigazione ≠ transport. NESSUNO stop audio va agganciato alle
    // transizioni di `page`, in NESSUNA forma (niente `.onChange(of: page)`
    // con stop — ruling D1; vietato anche inerte). Il click lo ferma SOLO uno
    // STOP esplicito del transport: con Link Director uno stop è un evento di
    // BANDA, non può essere il sottoprodotto di un «indietro». Lo stop
    // legittimo al bordo-stanza (uscita da `.qLive`) vive in AppRootView
    // `.onChange(of: screen)` — FUORI da questo strato.
    /// Porta UNICA di mutazione di `page`: nessuna assegnazione diretta fuori
    /// da qui. A S4b ha zero chiamanti (la porta è installata per S5/S6).
    private func navigate(to newPage: QLivePage) {
        page = newPage
    }

    var body: some View {
        switch page {
        case .shows:
            QLiveShowsView(onExit: onExit, onSwitchToStage: onSwitchToStage)
        case .detail:
            EmptyView()   // scaffold — mutatori a S5 (tap riga → navigate(.detail))
        case .metronome:
            EmptyView()   // scaffold — S4L innesta qui la sessione (`if let runner`)
        }
    }
}
