import SwiftUI

/// Contenitore di Q-Live (performance) — specchio esatto di `QStageRootView`.
/// È la RADICE in-tree di Q-Live: raggiunta per commutazione di schermata da
/// `AppRootView` (`switch screen` → `.qLive`), NON come modale UIKit.
///
/// Nodo A N1a: `QLiveRootView` POSSIEDE il seam `onExit` (hookpoint unico,
/// riusato dallo step S4) e lo INOLTRA a `LiveRootView`. NON costruisce mai
/// `{ screen = .home }` — quella closure vive solo in `AppRootView` (`Screen`
/// è `private enum` del file). In N1a il path `.qLive` è DEAD CODE: la porta
/// Q-Live della Home resta su `presentLive()` fino a N1b.
///
/// INVARIANTI (gate Nodo A — non derogabili):
///  - renderizza `LiveRootView`, MAI `LiveView` diretto → `audioEngine`
///    ereditato da `QBeatsApp` + `runner` @StateObject iniettato da
///    `LiveRootView` = niente crash `@EnvironmentObject`.
///  - resta IN-TREE: MAI reintrodurre uno `UIHostingController` qui.
///  - montaggio via `switch` (condizionale) = `LiveRootView` distrutto
///    all'uscita → `runner` FRESCO ad ogni entrata (identico al ciclo-vita
///    modale di oggi). NON un overlay always-on (persisterebbe un runner stale).
struct QLiveRootView: View {
    let onExit: () -> Void

    var body: some View {
        LiveRootView(onExit: onExit)
    }
}
