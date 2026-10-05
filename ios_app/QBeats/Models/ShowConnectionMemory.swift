import Foundation

// === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — IL RICORDO «VISTO COLLEGATO IN QUESTO SHOW» ===
// Per Link, Wi-Fi e MIDI la stanza (`QLiveSession`) ricorda se la cosa è stata vista collegata
// durante lo show: azzerato a `install` e a `endShow`. Serve alle spie (`StatusLightsDecision`):
// ambra solo se la cosa «si è persa durante lo show» (LIBRO, riga di ratifica 2026-10-04, punti 42
// e 52); mai vista = grigia.
// Regola del referee (05/10/2026): quando l'APP spegne Link da sé — lo specchio `linkEnabled`
// falso con l'interruttore dell'utente `linkUserEnabled` acceso (`QBeatsApp`, sfondo a click
// fermo) — il ricordo di Link si azzera: al ritorno la spia è grigia finché non si ricollega, mai
// «Link lost» per uno spegnimento fatto dall'app, che non è una perdita (A393 §6.5 e §9, caso 13).
// È una funzione pura perché il banco la provi (il banco compila solo Models/).
struct ShowConnectionMemory: Equatable {
    /// Link visto collegato in questo show (`linkIsConnected` vero almeno una volta).
    let linkSeen: Bool
    /// Wi-Fi visto collegato in questo show.
    let wifiSeen: Bool
    /// Un apparecchio MIDI visto collegato in questo show.
    let midiSeen: Bool

    /// Show nuovo: niente visto.
    static let none = ShowConnectionMemory(linkSeen: false, wifiSeen: false, midiSeen: false)

    /// Il ricordo dopo una lettura dei collegati. `linkUserEnabled`/`linkAppEnabled` sono i due
    /// interruttori di Link (`FollowerDecision`): app spento con utente acceso = spegnimento
    /// fatto dall'app, e il ricordo di Link si azzera invece di accumulare.
    func updated(linkConnected: Bool,
                 wifiConnected: Bool,
                 midiConnected: Bool,
                 linkUserEnabled: Bool,
                 linkAppEnabled: Bool) -> ShowConnectionMemory {
        let appSuspendedLink = linkUserEnabled && !linkAppEnabled
        let link = appSuspendedLink ? false : (linkSeen || linkConnected)
        return ShowConnectionMemory(linkSeen: link,
                                    wifiSeen: wifiSeen || wifiConnected,
                                    midiSeen: midiSeen || midiConnected)
    }
}
