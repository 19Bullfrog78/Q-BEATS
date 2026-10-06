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
// SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — due decisioni del referee del 05/10 (BOX5 V54, capitolo «PLAYER DEL
// SOLO, GIRO 1 — DECISIONI DEL REFEREE DEL 05/10/2026», punti 3 e 4): (3) uno spegnimento VOLUTO di Link non
// è una perdita, anche quello fatto dall'UTENTE dal pannello Link: con l'uno o l'altro interruttore spento il
// ricordo di Link si azzera (in M1 restava: il banco `testLinkOffByTheUserIsNotAnAppSuspension` è rovesciato in
// `testLinkOffByTheUserForgetsLinkToo`); (4) il ricordo vale solo a SHOW APERTO: `showOpen` entra come
// ingresso e a show chiuso il ricordo resta `.none` — fuori dallo show deve essere vuoto, o le righe [RICORDO]
// fra due show mentono a chi legge il log del collaudo. Lo show aperto è quello della stanza: il runner nello
// slot, lo stesso confine di `install` ed `endShow`.
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
    /// interruttori di Link (`FollowerDecision`): con uno dei due spento Link è spento di proposito, dall'utente
    /// o dall'app, e il ricordo di Link si azzera invece di accumulare. `showOpen`: lo show è aperto nella
    /// stanza; a show chiuso niente si ricorda.
    func updated(linkConnected: Bool,
                 wifiConnected: Bool,
                 midiConnected: Bool,
                 linkUserEnabled: Bool,
                 linkAppEnabled: Bool,
                 showOpen: Bool) -> ShowConnectionMemory {
        guard showOpen else { return .none }
        let linkSwitchedOff = !linkUserEnabled || !linkAppEnabled
        let link = linkSwitchedOff ? false : (linkSeen || linkConnected)
        return ShowConnectionMemory(linkSeen: link,
                                    wifiSeen: wifiSeen || wifiConnected,
                                    midiSeen: midiSeen || midiConnected)
    }
}
