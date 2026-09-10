import SwiftUI
import os

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
    /// ⟦A343⟧ (10/09/2026) — IL BIVIO A TRE VIE: aperto/chiuso, e i due dati che
    /// mostra, risolti ALL'ATTO DI AGIRE in `leavePlayer()` dal runner. Non e' una
    /// pagina (`QLivePage` resta a tre casi): e' un overlay sulla pagina `.metronome`,
    /// e si chiude in `navigate(to:)` a OGNI uscita da quella pagina.
    @State private var bivioAperto = false
    @State private var bivioCanzone = ""
    @State private var bivioMeta = ""
    /// ⟦A345⟧ (10/09/2026) — IL SEGNO DELLA TERZA FACCIA. La faccia la decide la PORTA
    /// (BOX5 «MODELLO DI SESSIONE Q-LIVE» §2(b): «da dove si entra»), non una rilettura
    /// del motore dentro il dettaglio. Lo alza SOLO `onShowDetails` del bivio, DOPO
    /// `navigate(to: .detail)` nella stessa closure sincrona, leggendo dal runner il nome
    /// della sezione corrente all'atto di agire; `navigate(to:)` lo abbassa a OGNI
    /// chiamata (stessa forma di `bivioAperto`), quindi le altre due porte verso `.detail`
    /// (il tocco sulla lista e la freccia a show vivo) e ogni uscita da `.detail` lo
    /// trovano basso per costruzione. Al dettaglio arrivano due valori semplici, mai il
    /// contenitore (VINCOLO DI PROPAGAZIONE, `QLiveSession.swift:26-38`).
    @State private var terzaFaccia = false
    @State private var terzaFacciaSezione = ""

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

    /// A253 — il motore, DICHIARATO e non iniettato: arriva dall'iniezione di
    /// `AppRootView.swift:53` su questa stessa view (catena provata nel cartello
    /// del gate `.metronome` più sotto, «`audioEngine` NON si re-inietta»).
    /// Serve ai due chiamanti di `endShow(audioEngine:)`: lo stop del motore
    /// vive LÀ, dove ogni innesco passa, e il parametro obbliga chi chiama.
    /// ⚠️ ASIMMETRIA CON LO SPECCHIO, dichiarata: `QStageRootView` non dichiara
    ///    `audioEngine` (0 occorrenze) e resta così — Q-Stage non possiede una
    ///    sessione da chiudere. Lo specchio è di struttura, non un vincolo di
    ///    identità riga-per-riga.
    ///
    /// ⚠️ COSTO DICHIARATO (A254, 29/08/2026): DA OGGI QUESTA RADICE OSSERVA
    ///    IL MOTORE, e il suo `body` si ridisegna a ogni `@Published` che
    ///    pubblica — `currentBeat` (`AudioEngine.swift:104`) compreso,
    ///    scritto una volta per battuta dentro il callback di render
    ///    (`:2419-2421`): 2-4 volte al secondo a tempi da palco. Non è un
    ///    difetto: è un costo nuovo, non una svista. PRIMA di A253 questa
    ///    view aveva ZERO occorrenze reali di `audioEngine` — lo stesso «0
    ///    occorrenze» che il cartello del gate `.metronome` più sotto misura
    ///    su `QStageRootView`, misurato identico anche su questo file a
    ///    `HEAD`. Da A253 vale solo per lo specchio.
    @EnvironmentObject private var audioEngine: AudioEngine

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
        // ⟦A343⟧ — il bivio non sopravvive alla pagina `.metronome`: OGNI uscita passa
        //    da questa porta unica, quindi e' l'unico punto che lo chiude per
        //    costruzione. `.onChange(of: page)` e' vietato anche inerte (decisione CD
        //    18/07, qui sopra); questa riga NON e' uno stop audio e non tocca il
        //    transport — abbassa un bit di stato della stanza.
        if newPage != .metronome { bivioAperto = false }
        // ⟦A345⟧ — il segno della terza faccia cade a ogni passaggio dalla porta unica;
        //    chi lo vuole alto lo alza DOPO aver navigato (solo `onShowDetails`, sotto).
        terzaFaccia = false
        terzaFacciaSezione = ""
        page = newPage
    }

    /// ⚠️ MARCATURA A341 (09/09/2026) — DA OGGI LA NAVIGAZIONE NON E' PIU' «IDENTICA»
    ///    e la condizione non e' piu' «una sola»: a show vivo la freccia va a `.detail`,
    ///    non a `.shows`. Le righe qui sotto restano vere per il ramo `.fineSetlist`,
    ///    che e' INVARIATO. I tre rami e le loro ragioni stanno dentro il metodo.
    /// ⚠️ A343 (10/09/2026): QUATTRO rami — a show FERMO (`.stopped`) la freccia apre
    ///    il bivio e NON naviga. Passo 2a; il velo e RESUME sono mandati loro.
    /// ⚠️ A345 (10/09/2026): il ramo del bivio ha una condizione di RUOLO — il Follower a
    ///    show fermo va a `.detail` (faccia 2), non al bivio. RESUME e' nato (terza
    ///    faccia, `onResume` sotto); il velo (2c) resta mandato suo.
    /// ⟦PORTA-RIENTRO⟧ ② — USCITA dal player verso l'imbuto interno. Sostituisce
    /// la closure nuda `{ navigate(to: .shows) }` che stava al sito di montaggio:
    /// la navigazione è IDENTICA, si aggiunge una sola condizione.
    ///
    /// ⛔ NON tocca il transport e non ferma l'audio: la decisione CD 18/07
    ///    («navigazione ≠ transport», :78-85) resta intatta, e questo metodo la
    ///    rispetta alla lettera. Qui si chiude una sessione GIÀ FINITA DA SÉ —
    ///    non si ferma niente che stia suonando.
    ///
    /// PERCHÉ LA CONDIZIONE STA QUI E NON SUL BOTTONE — è il TERZO innesco della
    /// firma, la FINE SCALETTA. Uno show esaurito è finito qualunque porta si usi
    /// per uscire: se lo svuotamento vivesse solo sul BACK TO SHOWS di END SHOW,
    /// chi esce dalla schermata di fine con la FRECCIA (`LiveHeaderView`)
    /// lascerebbe in stanza un runner esaurito, e al rientro si riattaccherebbe a
    /// uno show che non esiste più. È esattamente il caso che CD descrive al §1b:
    /// «a scaletta finita, riaprendo, comparirebbe il velo sull'ultima canzone,
    /// con un invito a toccare che rifarebbe partire un pezzo di uno show che non
    /// esiste più».
    ///
    /// ⚠️ Lettura di `roomSession.liveSession.playbackState` AL MOMENTO DELL'AZIONE,
    ///    dentro una closure — NON una dipendenza del `body`. Il VINCOLO DI
    ///    PROPAGAZIONE (`QLiveSession.swift:26-38`) riguarda l'UI che non si
    ///    aggiorna osservando un `ObservableObject` annidato: qui non si osserva
    ///    nulla e non si disegna nulla, si legge un valore per decidere un'azione.
    /// ⚠️ MARCATURA A253 (29/08/2026) — DA OGGI `endShow(audioEngine:)` PORTA LO
    ///    STOP DEL MOTORE, e il «non ferma l'audio» qui sopra resta vero PER
    ///    MISURA, non più per costruzione: su questo ramo il motore è già fermo
    ///    (`SetlistRunner.swift:466`, ramo fineSetlist) e `stopSync()` esce al
    ///    `guard self.isRunning` (`AudioEngine.swift:1694`) prima di
    ///    `link_engine_stop` — nessun evento alla band. Non si ferma niente che
    ///    stia suonando, perché non c'è.
    private func leavePlayer() {
        let stato = roomSession.liveSession.playbackState
        // Ramo 1 — FINE SCALETTA: INVARIATO (lastra ⑮→⑯ di CD). Chiude lo show e
        // porta alla lista; tutto il cartello qui sopra vale per questo ramo.
        if case .fineSetlist = stato {
            roomSession.endShow(audioEngine: audioEngine)
            os_log("[Q-BEATS][A341] freccia player - stato:%{public}@ runner:chiuso ramo:fineSetlist -> shows",
                   log: .default, type: .default, String(describing: stato))
            navigate(to: .shows)
            return
        }
        // ⟦A343⟧ (10/09/2026) — PASSO 2a: A SHOW FERMO LA FRECCIA APRE IL BIVIO A TRE
        //    VIE (LIBRO:383, 30/08, scelta di Mauro; frame ① del foglio CD 30/08).
        //    Chiude la TAPPA dichiarata da A341 qui sotto. Il bivio NON e' una pagina:
        //    e' un overlay sulla pagina `.metronome`, il player fermo resta sotto —
        //    qui NON si naviga. Solo `.stopped`: `.overlayStop` e' un caso distinto e
        //    va al dettaglio come prima; `.fineSetlist` e' gia' uscito sopra.
        //    I dati mostrati vengono dal RUNNER — `currentSong`/`currentSection`, lo
        //    stesso indice da cui `startCurrentSection` riparte — letti ALL'ATTO DI
        //    AGIRE, come `runner` qui sotto; mai dal mirror della schermata
        //    (`liveSession.currentSongName`/`currentTimeSig`, che segue la vista e
        //    deriva il tempo da un'euristica). Forma della riga meta: l'idioma del
        //    dettaglio (`QLiveShowDetailView.swift:484`), che e' gia' «121 · 6/8» del
        //    frame. Se la sezione non si risolve, la riga resta vuota: non si inventa.
        //    ⚠️ MARCATURA A345 (10/09/2026) — il bivio si apre SOLO se l'apparecchio comanda il
        //    trasporto: predicato del PLAY (`TransportView.swift:59`). Il Follower cade nel ramo
        //    show-vivo qui sotto (ratifica Mauro 09/09 (c): a show attivo ha la sola freccia
        //    verso i Dettagli, e li' END SHOW e BACK TO SHOW). Il testo sopra resta come scritto.
        // ⟦A345⟧ — CHI COMANDA IL TRASPORTO, letto all'atto di agire: e' la regola del PLAY
        //    (`TransportView.swift:59`: `currentLinkMode == .collaborativa` ⇒ Follower, che al
        //    Play non parte e aspetta il Direttore). RESUME e' un PLAY e obbedisce alla stessa
        //    regola, e il bivio che porta a RESUME pure. Standalone e Direttore comandano
        //    (ratifica (a): «non vale in standalone»). Il badge del player aggiunge
        //    `linkEnabled` (`LiveView.swift:124`): e' veste, non regola — qui vale la regola.
        let comandaTrasporto = audioEngine.currentLinkMode != .collaborativa
        if case .stopped = stato, let runner = roomSession.runner, comandaTrasporto {
            let canzone = runner.currentSong?.name ?? ""
            let meta: String
            if let sez = runner.currentSection {
                meta = "\(sez.name) \u{00B7} \(Int(sez.bpm.rounded())) \u{00B7} \(sez.beatsPerBar)/\(sez.beatUnit)"
            } else {
                meta = ""
            }
            bivioCanzone = canzone
            bivioMeta = meta
            bivioAperto = true
            os_log("[Q-BEATS][A343] bivio APERTO - stato:%{public}@ canzone:%{public}@ meta:%{public}@ sottoriga:%{public}@",
                   log: .default, type: .default,
                   String(describing: stato), canzone, meta, audioEngine.linkIsConnected ? "si" : "no")
            return
        }
        // ⟦A345⟧ — IL FOLLOWER A SHOW FERMO: niente bivio, va ai Dettagli (faccia 2: END SHOW +
        //    BACK TO SHOW), come a show che suona. Fino a oggi apriva il bivio: lo STOP del
        //    Direttore ferma anche il suo motore (`AudioEngine.swift:550-552`) e lo specchio
        //    porta la sessione a `.stopped` (`LiveView.swift:492`) — contraddiceva la ratifica
        //    (c). Strumentazione (1), passiva; poi cade nel ramo show-vivo qui sotto, INVARIATO.
        if case .stopped = stato, roomSession.runner != nil {
            os_log("[Q-BEATS][A345] freccia player - stato:%{public}@ ruolo:follower ramo:show-vivo -> detail (niente bivio)",
                   log: .default, type: .default, String(describing: stato))
        }
        // ⟦A341⟧ (09/09/2026) — PORTA DUE: A SHOW VIVO LA FRECCIA DEL PLAYER HA UNA
        //    DESTINAZIONE SOLA, I DETTAGLI. Ratifiche: LIBRO:379 (29/08, col click che
        //    suona la freccia ha una destinazione: i dettagli); LIBRO:404 (03/09, «se
        //    lo show e' attivo la casa non esiste, l'uscita non esiste»); Mauro 09/09
        //    al referee («una stanza, due entrate, mobili diversi»). Vale per OGNI
        //    stato dello show: che suona, in attesa fra due canzoni (BOX5 §2(f):
        //    l'attesa conta come «gira»), e anche FERMO dopo STOP.
        // ⚠️ TAPPA DICHIARATA, NON REGOLA — lo STOP: la destinazione ratificata dopo
        //    uno STOP e' il bivio (LIBRO:383), che arriva col passo 2 di questo lavoro.
        //    Nel frattempo il dettaglio e' onesto: BACK TO SHOW riporta al player
        //    fermo, PLAY riparte da canzone e sezione.
        // ⚠️ MARCATURA A343 (10/09/2026) — TAPPA CHIUSA: il ramo `.stopped` apre il
        //    bivio (qui sotto, prima del ramo show-vivo). Le quattro righe qui sopra
        //    restano come storia: si marcano, non si riscrivono.
        // COME SI ARRIVA ALLA PAGINA GIUSTA — NESSUN SECONDO CANALE: il ramo `.detail`
        //    legge `selectedSetlist` (:48), che ha UN solo scrittore (:179, il tocco
        //    sulla riga della lista) e dentro il cui `if let` il runner e' nato
        //    (`onStart`). A runner vivo la lista e' irraggiungibile — le sole vie
        //    verso `.shows` passano da `endShow`, che svuota lo slot prima — quindi
        //    `selectedSetlist` non puo' cambiare: E' lo show del runner, invariante
        //    PER NAVIGAZIONE, non per dato. ⛔ Chi aprisse una via nuova verso
        //    `.shows` a runner vivo romperebbe questa garanzia. Misura: A341 §2.
        // Lettura di `runner` ALL'ATTO DI AGIRE, come la riga di `playbackState` sopra
        //    e come `orchestrateDirectorPlay` (A337): non e' un'osservazione
        //    attraverso il contenitore.
        if roomSession.runner != nil {
            os_log("[Q-BEATS][A341] freccia player - stato:%{public}@ runner:presente ramo:show-vivo -> detail",
                   log: .default, type: .default, String(describing: stato))
            navigate(to: .detail)
        } else {
            // Ramo DIFENSIVO, mai vivo nel codice (A341 §3): il player monta solo nel
            // gate `if let runner`, e i due chiamanti di `endShow` navigano a `.shows`
            // nella stessa closure sincrona. Se questa riga compare nel log, qualcuno
            // ha aperto una via nuova.
            os_log("[Q-BEATS][A341] freccia player - stato:%{public}@ runner:nil ramo:difensivo -> shows",
                   log: .default, type: .default, String(describing: stato))
            navigate(to: .shows)
        }
    }

    /// ⟦PORTA-RIENTRO⟧ ② — END SHOW ESPLICITO. Seam separato da `onExit`, e la
    /// separazione È la mossa: `endShow()` deve poter essere chiamato da OGNI
    /// innesco di fine-show senza che l'innesco debba ricordarsene.
    ///
    /// ⚠️ **[M] OGGI L'INNESCO È UNO SOLO, NON DUE.** Il mandato ne nomina due —
    /// e CD ne disegna due il 27/08: la voce del BIVIO e la voce del DETTAGLIO
    /// (rinomina STOP→END SHOW). Misurato a `eca1ae6c`: nel prodotto esiste
    /// soltanto il BACK TO SHOWS di `FineSetlistView`, inoltrato da
    /// `LiveView`. Il secondo non è stato dimenticato: **non è costruito**, ed è
    /// disegno non ancora consegnato. ⛔ Non l'ho inventato.
    /// ⇒ Quando arriverà, si aggancia QUI e non deve sapere altro. È
    ///   precisamente il motivo per cui lo spegnimento non sta nel bottone.
    ///
    /// ⚠️ MARCATURA A253 (29/08/2026) — È ARRIVATO: il secondo innesco è la voce
    ///    END SHOW del dettaglio (`QLiveShowDetailView`, `endShowRow`),
    ///    agganciata a questo stesso metodo come secondo chiamante. Nessun
    ///    percorso nuovo, e la previsione delle due righe qui sopra si è
    ///    avverata alla lettera: è nato senza dover sapere altro.
    private func endShowAndLeave() {
        roomSession.endShow(audioEngine: audioEngine)
        navigate(to: .shows)
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
                    // ⟦PORTA-RIENTRO⟧ ③ — l'unico bit che decide la PAROLA del
                    // bottone. ✅ LETTURA LEGITTIMA del contenitore-sessione, ed è
                    // l'unico segnale che sa dare: «la si osserva SOLO per sapere se
                    // il runner c'è — apparizione e scomparsa» (`QLiveSession.swift:
                    // 34-38`). Qui si chiede esattamente quello. ⛔ NON è la lettura
                    // VIETATA dallo stesso cartello: il runner non viene letto
                    // ATTRAVERSO la sessione per darlo ai figli — quella continua a
                    // passare per il gate `.metronome` qui sotto, invariato.
                    isShowLive: roomSession.runner != nil,
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
                    // ⟦PORTA-RIENTRO⟧ ① — COSTRUISCE LA STANZA, NON LA FOGLIA.
                    // «Costruire o riattaccarsi» è una decisione di SESSIONE, e la
                    // sessione la possiede questo nodo. La foglia ora dice soltanto
                    // «l'utente ha premuto»: non sa, e non deve sapere, se in stanza
                    // c'è uno show vivo.
                    //
                    // ⛔ COSA C'ERA PRIMA, e perché è stato tolto: il runner nasceva
                    //    nella foglia e arrivava qui già costruito; `install` lo
                    //    installava ANCHE a slot pieno, e il runner vivo perdeva
                    //    l'ultimo riferimento forte. Lo show in corso restava ORFANO
                    //    — il motore scaricava la coda e taceva con `isPlaying`
                    //    ancora vero, la closure di fine-sezione usciva al `guard let
                    //    self` (`SetlistRunner.swift:375-376`), e nessuno accendeva
                    //    più END SHOW. È il guasto visto sul device il 28/08.
                    //
                    // ⛔ A SLOT PIENO NON SI COSTRUISCE E NON SI INSTALLA NULLA: si
                    //    naviga e basta, ed è il «BACK TO SHOW» della firma B. Per
                    //    ricostruire serve prima `endShow()` — che è ② e sta in
                    //    questo stesso commit, per vincolo di indivisibilità: il gate
                    //    da solo incatenerebbe la stanza al primo show della serata.
                    //
                    // ⚠️ L'INVARIANTE ⟦S5b⟧ `Cond (a)` È INTATTA E ORA VALE PER
                    //    ENTRAMBI I RAMI: la decisione e la `navigate` stanno nella
                    //    STESSA closure sincrona, senza attese in mezzo. Il ramo
                    //    `else` del gate `.metronome` non può apparire né a slot
                    //    vuoto (si è appena installato) né a slot pieno (c'era già).
                    //
                    // `QBeatsStore.shared` è lo stesso accesso che la foglia usava
                    // per costruire (`QLiveShowDetailView.swift`, `store`): il
                    // singleton non cambia, cambia solo chi lo chiama.
                    onStart: {
                        if roomSession.runner == nil {
                            roomSession.install(SetlistRunner(setlist: show,
                                                              store: QBeatsStore.shared))
                        }
                        // ⟦A337⟧ (09/09/2026) — L'ASCOLTO DEL PLAY DEL DIRETTORE SI
                        //    ATTACCA ALLA STANZA QUI, non nel player: idempotente
                        //    (guardia booleana in `QLiveSession`), sincrono e senza
                        //    attese — l'invariante ⟦S5b⟧ `Cond (a)` qui sopra resta
                        //    intatta. Il motore entra per parametro, idioma di
                        //    `endShow(audioEngine:)`. Muore col cassetto della
                        //    stanza, cioe' col `switch` di `AppRootView`.
                        roomSession.attachDirectorPlay(audioEngine: audioEngine)
                        navigate(to: .metronome)
                    },
                    // A253 — il SECONDO innesco di END SHOW: la voce del dettaglio
                    // (fogli CD 27/08 §② e 29/08 §B). STESSA funzione del primo,
                    // nessun percorso nuovo. La foglia dice «l'utente ha premuto
                    // END SHOW»; chi chiude — stop del motore, slot, stato — è la
                    // stanza. Un tap, NESSUNA conferma (§C del 29/08: da fuori lo
                    // show non sta sotto le mani, la sottoriga ha già detto cos'è
                    // vivo; un «sei sicuro?» addestrerebbe a spingere via i popup).
                    onEndShow: { endShowAndLeave() },
                    // ⟦A345⟧ (10/09/2026) — LA TERZA FACCIA (dal bivio, show fermo): due valori
                    //    semplici risolti alla porta (`onShowDetails` del bivio, sotto).
                    isThirdFace: terzaFaccia,
                    resumeSectionName: terzaFacciaSezione,
                    // ⟦A345⟧ — RESUME: fa ripartire il click da canzone e sezione con la STESSA
                    //    strada del PLAY dopo STOP (`SetlistRunner.startCurrentSection`, A240,
                    //    collaudo device 28/08 e 10/09) e riporta al player (BOX5 §2(g): RESUME
                    //    «sposta lo SHOW» e vive nel dettaglio; il click si regola nel player).
                    //    ⛔ NON `AudioEngine.resumeFromCurrentSection()`: e' la strada del
                    //    pannello superato (BOX5 §3, A260), salta il runner e scrive `.countIn`
                    //    senza suonarlo (LIBRO:393). Nessun count-in qui: ratificato (LIBRO:166
                    //    punto 3, :392) e mai costruito (TD-countin-ratificato-mai-costruito) —
                    //    una sola strada di ripresa = un solo posto dove un giorno si costruira'.
                    //    LETTURE ALL'ATTO DI AGIRE (come `leavePlayer()`): runner presente ·
                    //    predicato del PLAY (`TransportView.swift:59`) · `audioEngine.isPlaying`.
                    //    · Follower, oppure motore gia' in moto → SOLO navigazione al player:
                    //      niente avvio, niente `.starting`.
                    //    · altrimenti, in quest'ORDINE, nella stessa closure sincrona e con nulla
                    //      in mezzo: `.starting` → `startCurrentSection` → `navigate(.metronome)`.
                    //      `.starting` va scritto PRIMA dell'avvio: nel caso degenere
                    //      `prepareAndStartCurrentSection` scrive `.fineSetlist`
                    //      (`SetlistRunner.swift:203-210`) e una scrittura successiva lo
                    //      cancellerebbe. E' lo stato che tiene il velo lontano dal player che
                    //      si rimonta: `primeDisplay` arma solo da `.stopped`
                    //      (`SetlistRunner.swift:368`) e la guardia di `LiveView` scarta il
                    //      `.stopped` iniziale del motore su `.starting` (referto A345 §2.2,
                    //      scelta G1). Chi lo spegne: lo specchio del motore (`.playing`) o
                    //      `endShow` (`.stopped`). Strumentazione (3): stato letto, ramo, stato
                    //      scritto. Il log sta DOPO `navigate`, cosi' fra avvio e navigazione
                    //      non c'e' nemmeno una riga.
                    onResume: {
                        let follower = audioEngine.currentLinkMode == .collaborativa
                        let inMoto = audioEngine.isPlaying
                        guard let runner = roomSession.runner else {
                            // Ramo DIFENSIVO, mai vivo nel codice: la terza faccia nasce dal bivio,
                            // che esige il runner (`leavePlayer()`). Se compare nel log, qualcuno
                            // ha aperto una via nuova.
                            os_log("[Q-BEATS][A345] RESUME - runner:nil ramo:difensivo -> shows",
                                   log: .default, type: .default)
                            navigate(to: .shows)
                            return
                        }
                        if follower || inMoto {
                            navigate(to: .metronome)
                            os_log("[Q-BEATS][A345] RESUME - isPlaying:%{public}@ follower:%{public}@ ramo:solo-navigazione stato-scritto:nessuno -> metronome",
                                   log: .default, type: .default,
                                   inMoto ? "true" : "false", follower ? "true" : "false")
                            return
                        }
                        roomSession.liveSession.playbackState = .starting
                        runner.startCurrentSection(audioEngine: audioEngine, session: roomSession.liveSession)
                        navigate(to: .metronome)
                        os_log("[Q-BEATS][A345] RESUME - isPlaying:false follower:false ramo:avvio stato-scritto:starting songIdx:%d sectionIdx:%d -> metronome",
                               log: .default, type: .default, runner.currentSongIdx, runner.currentSectionIdx)
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
                // ⚠️ ⟦PORTA-RIENTRO⟧ — `onExit` non è più una closure nuda di
                //    navigazione: passa da `leavePlayer()`, che aggiunge UNA
                //    condizione e nient'altro (vedi lì il perché). `onEndShow` è un
                //    seam NUOVO: fino a oggi END SHOW riusava questo stesso `onExit`
                //    («TERZO inoltro dello stesso seam», `LiveView.swift`), e con un
                //    seam solo non c'è modo di distinguere «me ne vado» da «lo show
                //    è finito».
                //    ⚠️ A341 (09/09/2026): da oggi `leavePlayer()` ha TRE rami, non «una
                //    condizione e nient'altro» — a show vivo porta a `.detail`.
                //    A343 (10/09/2026): QUATTRO — a show fermo apre il bivio, non naviga.
                LiveView(onExit: { leavePlayer() },
                         onEndShow: { endShowAndLeave() },
                         session: roomSession.liveSession)
                    .environmentObject(runner)
                    // ⟦A343⟧ — IL BIVIO A TRE VIE, overlay sul player fermo (frame ① del
                    //    foglio CD 30/08). Il player resta montato sotto; la vista riceve
                    //    stringhe gia' risolte in `leavePlayer()` e non legge il motore.
                    //    ⚠️ RETTIFICA 1 (10/09/2026): le righe sotto sulla sottoriga sono SUPERATE —
                    //    la sottoriga NON si costruisce (CD 30/08 :351, due gambe, la seconda non
                    //    leggibile). Vedi il cartello accanto a `endShowSubline: nil`. Restano
                    //    come storia: si marcano, non si riscrivono.
                    //    La sottoriga ambra segue la REGOLA DEL DETTAGLIO — compare con
                    //    `linkIsConnected`, stato da `isPlaying`, mai `isShowLive`
                    //    (`QLiveShowDetailView.swift:548-563`, codice `:581-585`) — scritta
                    //    qui una seconda volta perche' nel dettaglio vive dentro un
                    //    `private var` non riusabile; NON e' una terza regola. ⚠️ Copy dal
                    //    frame ① (`CD:220`): «the other devices», una parola in piu' del
                    //    dettaglio (29/08 §B) — discordanza di CD, referto A343 §5(b). Lo
                    //    stato «playing» non ha copy nel frame: si riusa quella del
                    //    dettaglio (`:583`), ramo irraggiungibile per costruzione (il bivio
                    //    apre solo su `.stopped`). La radice osserva gia' il motore (A254):
                    //    i due segnali qui sono vivi. Le tre uscite: X → resta sul player
                    //    fermo · SHOW DETAILS → `.detail` · END SHOW → `endShowAndLeave()`,
                    //    che si CHIAMA e non si modifica.
                    .overlay {
                        if bivioAperto {
                            QLiveBivioView(
                                songName: bivioCanzone,
                                meta: bivioMeta,
                                // ⟦A343 · RETTIFICA 1⟧ (10/09/2026) — LA SOTTORIGA NON SI COSTRUISCE.
                                //    Foglio CD 30/08, MISURE :351, verbatim: «Condizionata, e la
                                //    condizione ha due gambe: apparecchio collegato E sincronizzazione
                                //    Start/Stop accesa. La seconda oggi non e' leggibile ⇒ finche' non
                                //    lo e', la riga non si costruisce: assenza silenziosa, mai allarme
                                //    mezzo armato.» Misura del referee, confermata da CC: la seconda
                                //    gamba non e' esposta a Swift — `LinkEngine.mm` ha solo il callback
                                //    (:22-23, :503-514), nessun getter; zero simboli `startStopSync`
                                //    in `ios_app/*.swift`. Il getter e' un atomo di Layer 2, mandato suo.
                                //    ⚠️ Il dettaglio (`QLiveShowDetailView.swift:548-585`) porta la
                                //    regola VECCHIA a una gamba (`linkIsConnected` + `isPlaying`): va
                                //    allineato quando la seconda gamba sara' leggibile — ticket nel
                                //    prossimo giro di documenti. Lo slot `endShowSubline` resta: e' il
                                //    contratto del frame ① (la vista gestisce gia' 64/56), non una
                                //    predisposizione. Il log «sottoriga:si/no» qui sopra e'
                                //    strumentazione, non una riga a schermo: resta.
                                endShowSubline: nil,
                                onClose: {
                                    os_log("[Q-BEATS][A343] bivio uscita X -> resta sul player fermo",
                                           log: .default, type: .default)
                                    bivioAperto = false
                                },
                                onShowDetails: {
                                    os_log("[Q-BEATS][A343] bivio uscita SHOW DETAILS -> detail",
                                           log: .default, type: .default)
                                    bivioAperto = false
                                    navigate(to: .detail)
                                    // ⟦A345⟧ — LA PORTA DECIDE LA FACCIA: il segno si alza DOPO
                                    //    `navigate` (che lo abbassa), nella stessa closure sincrona —
                                    //    SwiftUI non ridisegna fra due assegnazioni sincrone. Il nome
                                    //    della sezione viene dal RUNNER all'atto di agire — lo stesso
                                    //    indice da cui `startCurrentSection` riparte, come `bivioMeta`
                                    //    in `leavePlayer()`; se non si risolve resta vuoto e il
                                    //    dettaglio NON costruisce RESUME (garanzia contro la bugia,
                                    //    foglio CD 30/08 :369, applicata al tasto).
                                    terzaFaccia = true
                                    terzaFacciaSezione = roomSession.runner?.currentSection?.name ?? ""
                                },
                                onEndShow: {
                                    os_log("[Q-BEATS][A343] bivio uscita END SHOW -> endShowAndLeave",
                                           log: .default, type: .default)
                                    bivioAperto = false
                                    endShowAndLeave()
                                })
                        }
                    }
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
