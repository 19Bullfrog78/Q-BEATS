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
/// Il ramo `.detail` da ⟦S5a⟧ rende `QLiveShowDetailView` (era scaffold EmptyView fino a S4b).
/// Il ramo `.metronome` porta da ⟦S4R⟧ il gate `if let runner` sulla sessione.
///
/// INVARIANTI (gate Nodo A — non derogabili):
///  - resta IN-TREE: MAI reintrodurre uno `UIHostingController` qui.
///  - montaggio via `switch` da AppRootView (condizionale) = sottoalbero
///    distrutto all'uscita dalla stanza. VIETATO ripiegare su un overlay
///    always-on (persisterebbe un runner stale). Il divieto vale DOPPIO da
///    S4L, quando la proprietà del runner sale alla stanza (BOX3 V97 (a)):
///    è proprio lì che la scorciatoia «overlay sempre montato» diventa
///    strutturalmente attraente.
///  - «mai il player senza runner iniettato» RESTA IN VIGORE, e da ⟦S4R⟧ è
///    GARANTITO DAL GATE `if let runner` del ramo `.metronome`. L'emendamento
///    della LETTERA storica («renderizza `LiveRootView`, MAI `LiveView`
///    diretto») è RATIFICATO in `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:210-213
///    @ 40f099bb28ad87627e3c6df926993a3df297df90`: questo file lo APPLICA, non
///    lo dispone. Applicazione: `LiveRootView` non esiste più — esisteva solo
///    per possedere il runner phantom — e il player si renderizza direttamente,
///    col runner iniettato DENTRO il gate. Lo SCOPO dell'invariante è intatto.
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
    /// Show selezionata per il dettaglio — il payload separato di cui sopra (:42-43). ⟦S5a⟧.
    @State private var selectedSetlist: Setlist? = nil

    /// Contenitore-sessione della stanza — forma B, `LIBRO_MASTRO_QBEATS.md:285`.
    /// Possiede lo SLOT del runner: VUOTO in ⟦S4R⟧, si riempie allo Start ⟦S5⟧.
    ///
    /// PERCHÉ VIVE QUI, e perché la morte del runner è STRUTTURALE e non
    /// procedurale: `QLiveRootView` è l'unico nodo che nasce e muore con la
    /// stanza. Misura a `40f099bb28ad87627e3c6df926993a3df297df90`, prima di
    /// questo atomo: NESSUN CODICE TIENE IN VITA UN RUNNER — 0 overlay
    /// always-on, 0 cache, 0 singleton; unico sito di costruzione
    /// `LiveRootView.swift:12`, con 0 chiamanti. Un azzeramento esplicito su un
    /// evento d'uscita sarebbe invece cieco a ogni percorso non previsto, e
    /// l'unico posto dove appenderlo — `AppRootView.onChange(of: screen)` — è
    /// già dichiarato cieco alle uscite che NON cambiano `screen`
    /// (`BOX3_QBEATS.md:51`): erediterebbe quella cecità per costruzione.
    ///
    /// ⚠️ NON SORGENTATO (§7): la tesi «il ramo di `switch` rilascia la memoria
    /// del sottoalbero», che il blocco INVARIANTI qui sopra usa, è comportamento
    /// SwiftUI di cui NON abbiamo fonte. È marcata, non rimossa, e NON è la
    /// motivazione di questa scelta: la motivazione è la misura qui sopra.
    ///
    /// ⛔ SI CHIAMA `roomSession`, e non col nome nudo, per una COLLISIONE:
    /// `LiveView.swift:11` porta già una propria proprietà con quel nome nudo
    /// (di tipo `LiveSession`), e `LiveView` è renderizzata DENTRO il gate qui
    /// sotto. Due oggetti diversi con lo stesso identificatore, uno annidato nel
    /// sottoalbero dell'altro, renderebbero ambiguo ogni divieto scritto su quel
    /// nome. Il NOME DELLA CLASSE `QLiveSession` è ratificato
    /// (`LIBRO_MASTRO_QBEATS.md:285`) e NON si tocca: cambia la sola proprietà.
    @StateObject private var roomSession = QLiveSession()

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
            QLiveShowsView(onExit: onExit, onSwitchToStage: onSwitchToStage, onSelectShow: { show in
                selectedSetlist = show
                navigate(to: .detail)
            })
        case .detail:
            // ⟦S5a⟧: raggiunge QLiveShowDetailView col payload separato (:47). Ramo `else`
            // difensivo — non dovrebbe accadere (unico chiamante di navigate(.detail) è
            // onSelectShow sopra, che valorizza selectedSetlist nello stesso gesto).
            if let show = selectedSetlist {
                QLiveShowDetailView(
                    setlist: show,
                    onBack: { navigate(to: .shows) },
                    // ⟦S5b⟧ `Cond (a)` — L'INVARIANTE È LA SINCRONIA, NON L'ORDINE
                    // (correzione del referee). Le due righe qui sotto stanno nella
                    // STESSA closure e senza alcuna attesa in mezzo: niente `Task`,
                    // niente `async`, niente `asyncAfter`. SwiftUI non ridisegna fra
                    // due assegnazioni sincrone, quindi il ramo `.metronome` non può
                    // mai montarsi con `runner == nil` e il ramo `else` non si vede.
                    // ⚠️ Basta infilare un'attesa fra le due per perdere la garanzia:
                    //    lì il ramo `else` diventa visibile per un frame. L'ordine
                    //    prescritto dalla scheda è rispettato — costa nulla — ma non
                    //    è lui a proteggere.
                    // ⛔ NESSUNO stop audio qui e nessun avvio: `navigate` resta muto
                    //    sul transport (decisione CD 18/07, :78-85). Questo è un
                    //    INGRESSO — arma e basta. Il click parte al secondo tap
                    //    (`LiveView.swift:134-137`).
                    onStart: { runner in
                        roomSession.install(runner)
                        navigate(to: .metronome)
                    }
                )
            } else {
                EmptyView()
            }
        case .metronome:
            // ⟦S4R⟧ GATE — MAI il player senza runner iniettato.
            if let runner = roomSession.runner {
                // UNICO punto in cui il runner entra nell'albero delle viste.
                // I figli lo osservano DIRETTAMENTE (`@EnvironmentObject` sul
                // runner: `LiveView.swift:6`). ⛔ MAI leggere attraverso la
                // sessione — il contenitore-sessione della stanza: compila, SEMBRA GIUSTO, e
                // produce l'UI metronomo CONGELATA che sembra un guasto del DSP
                // — `BOX3_QBEATS.md:34 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`.
                //
                // ⛔ IL BACK DEL PLAYER NON È UN'USCITA DI STANZA: va all'IMBUTO
                //    INTERNO (`navigate(to: .shows)`), MAI a `onExit`. Freeze CD
                //    `DESIGN/QLive_Nav/2026-07-18_QLive-Exit-in-Play.html:286 @
                //    40f099bb28ad87627e3c6df926993a3df297df90` — «Navigazione ≠
                //    transport … back dal player → lista (click continua, (c));
                //    … Nessuna tocca il clock.» — e `:290`, stesso commit:
                //    «Player (metronomo) = nessun terzo sfondo … sul player la
                //    barra stanze non c'è → nessuna uscita-stanza, niente gate
                //    lì.» Passare `onExit` qui significherebbe che a ⟦S5⟧ un
                //    tocco involontario esce dalla stanza e UCCIDE IL CLICK,
                //    saltando il gate «Stop & Exit / Stay» obbligatorio in play.
                //    ⛔ Quel gate NON si costruisce qui: è ⟦S-EXIT⟧, e nel
                //    freeze vive su lista e dettaglio, non sul player.
                //    ⚠️ INFERITO, NON DECISO — il CANCEL del Follower. `LiveView`
                //    inoltra la closure a DUE leaf (`LiveView.swift:9`):
                //    `LiveHeaderView` (back) e `WaitingForDirectorView` (CANCEL
                //    del Follower in attesa). Questo ricablaggio li muove
                //    ENTRAMBI, ma il freeze copre il SOLO back dal player e sul
                //    CANCEL non dice nulla. Restare in stanza è corretto e qui
                //    NON si cambia: si DICHIARA che la scelta è inferita, e la
                //    ratifica spetta a ⟦S-EXIT⟧.
                //
                // `audioEngine` NON si re-inietta, e NON è un'omissione:
                //  · iniettato a `AppRootView.swift:53 @
                //    40f099bb28ad87627e3c6df926993a3df297df90`, DIRETTAMENTE su
                //    questa view — un livello sopra il gate;
                //  · Apple, `View.environmentObject(_:)`: «Supplies an
                //    observable object to a view's hierarchy», disponibile alle
                //    subview della gerarchia — developer.apple.com/
                //    documentation/swiftui/view/environmentobject(_:);
                //  · prova IN-REPO su percorso esercitato A OGNI AVVIO:
                //    `HomeRootView.swift:14` dichiara `@EnvironmentObject var
                //    audioEngine` e `AppRootView.swift:34-35` NON gliene inietta
                //    uno locale — arriva solo da `QBeatsApp.swift:16`. Se la
                //    propagazione non funzionasse, l'app crasherebbe all'avvio;
                //  · simmetria: lo specchio `QStageRootView` non dichiara
                //    `audioEngine` (0 occorrenze) pur ricevendolo a
                //    `AppRootView.swift:45`. Re-iniettarlo qui romperebbe lo
                //    specchio dichiarato in testa a questo file.
                // ⚠️ A242 — la sessione è passata ESPLICITA, senza default: la
                //    possiede la stanza (`roomSession.liveSession`, cartello A242
                //    in QLiveSession.swift) e sopravvive alla navigazione
                //    interna. Il VINCOLO DI PROPAGAZIONE resta rispettato: qui
                //    si passa il RIFERIMENTO una volta sola; LiveView la osserva
                //    direttamente, mai attraverso il contenitore.
                LiveView(onExit: { navigate(to: .shows) }, session: roomSession.liveSession)
                    .environmentObject(runner)
            } else {
                // COMMENTO DI GUARDIA (forma D1-SPLIT): l'incisione sta dove un
                // futuro lettore cablerebbe per errore.
                // Qui va l'EMPTY-STATE ONESTO della pagina metronomo.
                // ⛔ NON messo in ⟦S4R⟧: il disegno è materia CD e NON esiste
                //    freeze per questa pagina. CC non genera UX.
                // ⛔ Nessun testo d'interfaccia, nessun componente
                //    `QLiveEmptyStates`/`EmptyStateKit`, nessun pulsante —
                //    nemmeno disabilitato: un disabilitato è già una promessa di
                //    Start, e lo Start è ⟦S5⟧.
                // ⟦S5⟧ NON parte senza questo empty-state.
                // Oggi la pagina resta comunque IRRAGGIUNGIBILE: nessuno chiama
                // `navigate(to: .metronome)`. L'unico chiamante dell'imbuto è
                // il back del player qui sopra, e porta a `.shows`.
                //
                // ⚠️ MARCATURA ⟦S5b⟧ — LE DUE FRASI QUI SOPRA SONO SCADUTE. Si marcano,
                //    non si riscrivono: sono la storia di come ci si è arrivati.
                //    (1) «⟦S5⟧ NON parte senza questo empty-state» — superata dalla
                //        CANCELLAZIONE dell'atomo A3 empty-state
                //        (`LIBRO_MASTRO_QBEATS.md:355`). Nessun disegno CD serve: qui il
                //        ramo `else` resta una GUARDIA DIFENSIVA, come il gemello a
                //        :105-107 nello stesso `switch`. ⟦S5b⟧ è partita senza.
                //    (2) «nessuno chiama `navigate(to: .metronome)`» — falsa da ⟦S5b⟧:
                //        lo chiama `onStart` qui sopra. ⇒ il ramo resta irraggiungibile,
                //        ma per una RAGIONE DIVERSA: non più «nessuno naviga qui», bensì
                //        «chi naviga qui ha già installato il runner, nella stessa
                //        closure sincrona».
                EmptyView()
            }
        }
    }
}
