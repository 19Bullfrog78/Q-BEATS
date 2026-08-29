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

    /// ⚠️ CARTELLO A242 (28/08/2026) — LA MEMORIA DELLO SCHERMO È DELLA STANZA.
    /// Prima mossa di due (⟦S-EXIT⟧: «lo stato dello show appartiene allo show,
    /// non alla schermata» — l'invito è nel doc di questa classe, più sopra).
    /// Fino ad A242 la `LiveSession` nasceva `@StateObject` dentro `LiveView` e
    /// MORIVA a ogni uscita dal player: i sedici campi (censimento A229) e
    /// l'ascoltatore del Play del Direttore morivano con lei — è il meccanismo
    /// dietro `TD-rientro-senza-stop-sgancia-audio-e-grafica` 🚨 e
    /// `TD-follower-parte-cieco-a-player-chiuso` 🚨 (BUGS v68).
    ///
    /// COSA SOPRAVVIVE ORA all'uscita dal player (restando nella stanza):
    /// TUTTI i sedici campi — di proposito. I tredici che descrivono lo show
    /// (stato, nomi, posizione, BPM, time-sig, ProMode) SONO la memoria che si
    /// voleva salvare; i due morti (`isBacktrackLocked`, `accentPattern` —
    /// A229 famiglia D) sopravvivono inerti, invariati.
    /// COSA NO: `showMixer` è mobilio della schermata, azzerato ESPLICITAMENTE
    /// a ogni ingresso (`LiveView`, onAppear — l'unico azzeramento del giro);
    /// gli otto `@State` di `LiveView` (ancora del bar counter, finestre di
    /// fade, mirror seamless) restano della vista e muoiono con lei PER
    /// SCELTA: sono ritmo di rendering, non stato dello show.
    ///
    /// ⚠️ EFFETTO SECONDARIO DICHIARATO: la closure di fine-sezione del runner
    /// tiene la sessione con `weak`; finché la sessione moriva, fuori dal
    /// player la closure usciva al guard e lo show NON avanzava. Ora avanza
    /// anche a player chiuso (standby a fine canzone compreso). È il
    /// comportamento voluto — la memoria vive — ma NESSUN device l'ha visto.
    ///
    /// ⛔ LA MOSSA (b) NON È FATTA: l'ascoltatore del Play del Direttore
    /// (`.onReceive(audioEngine.linkStartedSubject)`) vive ANCORA in `LiveView`
    /// e muore ANCORA con la schermata. `TD-follower-parte-cieco` NON è chiuso
    /// da questa mossa: serve il mandato successivo.
    ///
    /// Il VINCOLO DI PROPAGAZIONE qui sopra vale identico per questo campo:
    /// `let` NON pubblicato — il contenitore continua a notificare solo la
    /// comparsa del runner. I figli osservano la `LiveSession` DIRETTAMENTE
    /// (`@ObservedObject`, passata esplicita al montaggio), MAI attraverso il
    /// contenitore.
    let liveSession = LiveSession()

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
    ///
    /// ⚠️ CARTELLO ⟦PORTA-RIENTRO⟧ (28/08/2026) — LA CLAUSOLA «SOSTITUISCE SEMPRE,
    /// ANCHE A SLOT PIENO» (:87-91) È SUPERATA DALLA FIRMA B DI MAURO. Si marca e
    /// NON si riscrive: come descrizione di QUESTO metodo resta vera — continua
    /// ad assegnare e basta — ed è la storia di perché lo slot nacque con
    /// un'assegnazione secca.
    /// ⛔ COSA CAMBIA: il caso che quella clausola voleva coprire — «la band apre
    /// un SECONDO show nella stessa serata» — non passa più di qui. La decisione
    /// è salita al chiamante, cioè alla STANZA: `QLiveRootView` costruisce e
    /// installa SOLO a slot vuoto, e a slot pieno si riattacca senza toccare lo
    /// slot. Il secondo show ora esige `endShow()` prima, ed è la firma a dirlo.
    /// ⇒ A slot pieno questo metodo non è più raggiungibile dal prodotto.
    /// ⛔ Resta assegnazione secca DI PROPOSITO: un `guard runner == nil` qui
    ///   metterebbe la stessa decisione in due posti, e due posti divergono. Il
    ///   posto è uno solo, ed è la stanza.
    /// ⚠️ COSA NON CAMBIA: il prezzo dichiarato in :91 — «il vecchio runner perde
    ///   qui il suo ultimo riferimento forte» — è ancora esatto. È il meccanismo
    ///   con cui lo show vivo restava orfano al rientro, e non è stato tolto: è
    ///   stato reso irraggiungibile a monte.
    func install(_ newRunner: SetlistRunner) {
        runner = newRunner
    }

    /// ⟦PORTA-RIENTRO⟧ ② — IL SECONDO MUTATORE: lo slot si SVUOTA.
    ///
    /// **[M] Prima di oggi non esisteva UNA SOLA istruzione, in tutto il
    /// prodotto, che riportasse `runner` a `nil`** — misurato per enumerazione:
    /// `install` era l'unico scrittore, e assegnava sempre un valore non-nil. È
    /// il difetto che CD ha chiamato «il bit *show aperto* non si spegne mai»
    /// (politica del rientro, §1b): dentro la stanza, dopo il primo Start, quel
    /// bit diceva **sì per sempre**.
    ///
    /// ⛔ NON È UN BOTTONE, ED È IL PUNTO. Si chiama DOVE LA SESSIONE SI CHIUDE,
    /// non dentro il gesto che la chiude. Appendere lo spegnimento al bottone di
    /// END SHOW significherebbe che il SECONDO innesco di END SHOW nasce già
    /// dimenticandolo — ed è testuale in CD: «se lo si attacca al bottone, il
    /// secondo innesco lo dimentica».
    ///
    /// DUE EFFETTI, e il secondo non è un di più:
    ///  1. lo slot torna vuoto ⇒ la porta ricomincia a COSTRUIRE, e la band può
    ///     aprire il secondo show della serata. Senza questo, il gate della
    ///     porta da solo incatenerebbe la stanza al primo show — ed è la ragione
    ///     per cui ① e ② sono indivisibili per firma.
    ///  2. `liveSession.playbackState` torna a `.stopped`. ⛔ Senza (2) la (1) è
    ///     una trappola: da A242 la sessione SOPRAVVIVE alla schermata, e uno
    ///     stato `.fineSetlist` rimasto addosso farebbe aprire lo show NUOVO
    ///     direttamente sulla schermata di END SHOW (`LiveView.swift:149`),
    ///     perché `primeDisplay` arma lo standby SOLO da `.stopped`
    ///     (`SetlistRunner.swift:361`). ⚠️ La riga NON è nuova e non è una
    ///     decisione mia: è la stessa che viveva dentro la closure del bottone
    ///     in `LiveView`, con la sua motivazione già scritta lì — qui è
    ///     SPOSTATA, perché è al chiudersi della sessione che appartiene.
    ///
    /// ⛔ NON azzera i tredici campi di show della `liveSession`: non è chiesto,
    ///    e cosa lo schermo legge al rientro è materia della FIRMA A (le sedici
    ///    voci), che non è questo mandato. Qui si chiude la sessione, non si
    ///    pulisce la vetrina.
    /// ⚠️ CARTELLO A253 (29/08/2026) — TERZO EFFETTO: LO STOP DEL MOTORE, e la
    /// firma cambia APPOSTA. L'etichetta di CD promette «this will stop other
    /// devices too» (fogli 27/08 R4 e 29/08 §B): chiudere lo show DEVE fermare
    /// il click, o l'etichetta mente — la categoria che il §D del rev3 esiste
    /// per vietare. Fino ad A253 questo metodo non chiamava nessuno stop.
    ///
    /// ⛔ LO STOP STA QUI E NON NEI BOTTONI, per la stessa ragione di :139-143:
    ///    ogni innesco di END SHOW passa di qui. E il motore entra come
    ///    PARAMETRO — idioma di casa: `SetlistRunner` lo riceve per parametro e
    ///    non lo conserva (`startSetlist(audioEngine:session:)`) — così
    ///    l'obbligo è strutturale: il prossimo innesco non può nascere senza,
    ///    non compila.
    ///
    /// ✅ A MOTORE GIÀ FERMO LA CHIAMATA È INERTE, misurato a fonte:
    ///    `stopSync()` esce al `guard self.isRunning` (`AudioEngine.swift:1694`)
    ///    PRIMA di `link_engine_stop` (`:1701`) ⇒ nessun evento alla band. È ciò
    ///    che rende lo stop INCONDIZIONATO qui: sul ramo `.fineSetlist` (motore
    ///    già fermato dal runner, `SetlistRunner.swift:466`) non fa nulla.
    ///
    /// ⚠️ ORDINE: lo stop PRIMA di svuotare lo slot — prima si zittisce la
    ///    stanza, poi si chiude la sessione.
    ///
    /// ⚠️ CORREZIONE A254 (29/08/2026) — LA FRASE CHE SEGUIVA QUI ERA VERA MA
    ///    INDICAVA LA PROTEZIONE SBAGLIATA. `stop()` dispatcha `.stopped`
    ///    SUL MOTORE (`AudioEngine.playbackState`, un `@Published` diverso da
    ///    quello di questa sessione) async su main SENZA CONDIZIONE —
    ///    `AudioEngine.swift:1100-1101` sta FUORI dal `guard self.isRunning`
    ///    di `stopSync()` (:1694): parte a OGNI `stop()`, motore già fermo
    ///    compreso. Quella scrittura può arrivare TARDI: se nel frattempo si
    ///    è aperto un secondo show e `primeDisplay` ha già armato
    ///    `liveSession.playbackState = .standby`, un `.stopped` dell'ENGINE
    ///    in ritardo la scavalcherebbe. La scrittura sincrona di questo
    ///    metodo non protegge da questo: è un evento successivo, indipendente,
    ///    su un campo diverso.
    ///
    ///    CIÒ CHE LO IMPEDISCE è la GUARDIA in `LiveView.swift:461-466`
    ///    (`case .standby, .fineSetlist: return`, dentro
    ///    `.onReceive(audioEngine.$playbackState)`) — non un ordine scritto
    ///    qui. Quella stessa guardia è dichiarata (`LiveView.swift:442-460`)
    ///    come ciò che tiene in piedi l'ARMAMENTO D'INGRESSO DI ⟦S5b⟧, e
    ///    `:459-460` avverte già, da PRIMA di A253, che togliere `.standby`
    ///    da quella lista «romperebbe ⟦S5b⟧ senza toccarne una riga». A253
    ///    non crea questa dipendenza: la EREDITA — e senza questa riga
    ///    restava una protezione che nessuno sapeva di dover difendere.
    ///    (Righe citate sul file DOPO A253.)
    func endShow(audioEngine: AudioEngine) {
        audioEngine.stop()
        runner = nil
        liveSession.playbackState = .stopped
    }
}
