import Foundation

// === A386 · FASE B2b (2D) — IL VELO DEL FOLLOWER: UNA DECISIONE SOLA, TESTATA ===
// Il foglio CD 2D-QUATER (26/09/2026, ratificato da Mauro; `DESIGN/QLive_Nav/2026-09-26_QLive-
// Player_2D-QUATER-FOLLOWER-FUORI-RIENTRA_390x844_1.html` e `_2.html`) disegna cosa vede il
// musicista sul Follower quando perde il Direttore: la lista d'ingresso di START SHOW (L2, A1),
// il velo FUORI con RIENTRA (L4-L6, L8), Ready (L2-④, L7), il velo IN SYNC (L1) e la fascia DA
// SOLO (L3). Qui, come `StandbyOverlayDecision` (A355), sta la decisione: le viste disegnano e
// basta. Entrano: stato della macchina, ragione, show aperto, segnale, Start Stop Sync, sessione
// Link in moto, proposta e scaletta. Escono: la parola in testa (Join, Out, Ready),
// l'intestazione (Join at, Rejoin at), la riga della ragione, la faccia dello slot E, le icone,
// la forma della proposta.
//
// Le regole, con la fonte:
//  · la lista d'ingresso si vede quando il Follower e' FUORI non armato con ragione nulla o
//    `reset`, e c'e' uno show aperto nella stanza (decisione del referee, mandato B2b §3.a):
//    all'avvio dell'app la ragione e' nulla, dopo un END SHOW e' `reset`, START SHOW arriva
//    sempre con una delle due — e' la stessa equivalenza di `RientraProposal`;
//  · FUORI armato e' «Ready» (L2-④, L7): un armamento riuscito tiene la ragione precedente,
//    per questo «Ready» dopo Join resta «Join at» e dopo RIENTRA resta «Rejoin at»;
//  · FUORI con ogni altra ragione e' «Out» con la riga della ragione (tabella «Riga sotto
//    Out», file 1 §0); l'icona di divieto sta SOLO sui due rifiuti (R1);
//  · la ragione `directorFalseStartWhileAlone` porta la stessa riga di `directorStoppedWhileAlone`
//    (punto 27 del foglio, chiuso dal referee: il Direttore si e' fermato davvero, entro la
//    prima battuta; cambia solo la canzone proposta);
//  · IN SYNC fermo e' il velo di sempre (L1) con lo slot E che dice SOLO «Director signal OK»
//    (mandato §3.f); in moto la fascia grigia; DA SOLO la fascia ambra (L3): niente slot E;
//  · lo slot E ha cinque facce (file 1 §0 e riquadro «slot E»), in quest'ordine di precedenza:
//    Start Stop Sync spento su questo apparecchio (prende il posto di «No director signal»),
//    Searching…, No director signal con le due righe di controllo, segnale OK con «band
//    playing» (sessione Link in moto: il dato che R1 legge all'armamento), segnale OK;
//  · le righe sono sempre toccabili (punto 6): un tocco arma, non parte; il tocco non passa di
//    qui, passa dalla stanza (`QLiveSession.armRientra`);
//  · la posizione della lista (L4, L5): la riga evidenziata seconda, con la precedente sopra
//    come contesto; senza riga evidenziata la lista sta in cima;
//  · senza show aperto non c'e' faccia (`noShow`): il player si monta solo col runner.
// Le parole sono quelle del foglio, 1:1, copiate dal sorgente HTML carattere per carattere
// (mandato §3.j): le MAIUSCOLE dello slot E e delle intestazioni le mette la vista (STAGE-CAPS).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct FollowerVeilDecision: Equatable {

    enum Face: Equatable {
        /// Nessuno show aperto nella stanza: niente da disegnare.
        case noShow
        /// L2: la lista d'ingresso di START SHOW (A1) — «Join».
        case join
        /// L4-L6, L8, R2: FUORI con la ragione — «Out».
        case out
        /// L2-④, L7: FUORI armato — «Ready».
        case ready
        /// L1 da fermo: il velo di sempre con lo slot E; in moto la fascia grigia.
        case inSync
        /// L3: in moto, la fascia ambra DA SOLO.
        case alone
    }

    enum Heading: Equatable {
        case joinAt
        case rejoinAt
    }

    /// Le cinque facce dello slot E, nell'ordine di precedenza.
    enum SlotE: Equatable {
        case startStopSyncOff
        case searching
        case noSignal
        case signalOKBandPlaying
        case signalOK
    }

    /// Le quattro icone di stato del foglio (file 1, «icone · 4»). Del Direttore solo la prima
    /// scelta (con la bacchetta): la riserva non si costruisce.
    enum Icon: Equatable {
        case directorBarred
        case playStopBarred
        case noEntry
        case toTheBarline
    }

    /// La riga evidenziata nella scaletta: proposta (bordo pieno o tratteggio) o armata.
    enum RowStyle: Equatable {
        case proposalNormal
        case proposalGuess
        case armed
    }

    // MARK: - Le parole del foglio, 1:1 (file 1 §0; file 2 L3)

    static let joinWord = "Join"
    static let outWord = "Out"
    static let readyWord = "Ready"
    static let joinAtHeading = "Join at"
    static let rejoinAtHeading = "Rejoin at"
    static let pickLine = "Pick the song the band starts from."
    static let readyLineSuffix = " starts at the director's Play."
    static let changeLine = "tap another song to change"
    static let suggestedLine = "suggested"
    static let guessLine = "a guess \u{2014} check the band"
    static let yourPickLine = "your pick"
    static let songsLineSuffix = " songs"
    static let signalOKLine = "Director signal OK"
    static let searchingLine = "Searching\u{2026}"
    static let noSignalLine = "No director signal"
    static let noSignalDirectorLine = "director: show open \u{00B7} Link \u{00B7} Start Stop Sync"
    static let noSignalNetworkLine = "network: Wi-Fi on both \u{00B7} router"
    static let bandPlayingLine = "band playing \u{2014} wait for the stop"
    static let startStopSyncOffLine = "Start Stop Sync off"
    static let startStopSyncOffDetailLine = "on this device \u{00B7} Settings \u{203A} Ableton Link"
    static let onYourOwnLine = "On your own"
    static let clickStopsLine = "click stops at the song's end"
    static let holdToStopLine = "hold to stop"
    // «Riga sotto Out» (file 1 §0, tabella a destra)
    static let reasonLostWhileStopped = "Director signal lost."
    static let reasonPlayLate = "Play came late: the band started without you."
    static let reasonAloneSongEnded = "Song finished on your own."
    static let reasonDirectorStoppedWhileAlone = "Director stopped while you played alone."
    static let reasonMusicianStop = "You stopped the click."
    static let reasonRefusedNotHeard = "Couldn't join: no director signal."
    static let reasonRefusedSessionPlaying = "Couldn't join: band playing."
    static let reasonLostWhileArmed = "Director signal lost \u{2014} no longer ready."

    static func readyLine(songName: String) -> String { songName + readyLineSuffix }
    static func songsLine(count: Int) -> String { String(count) + songsLineSuffix }

    // MARK: - Uscite

    let face: Face
    /// «Join», «Out», «Ready»; `nil` sulle facce senza parola in testa.
    let headWord: String?
    /// Ambra = tocca a te o qualcosa non va («Out»); bianco = nessun problema («Join», «Ready»).
    let headWordIsAmber: Bool
    /// Join: cosa fare · Out: la ragione · Ready: «⟨song⟩ starts at the director's Play.»
    let bodyLine: String?
    /// Il divieto d'accesso, solo sui due rifiuti di R1.
    let bodyIcon: Icon?
    let heading: Heading?
    /// «Join at» / «Rejoin at».
    let headingLine: String?
    /// «24 songs».
    let songsLine: String?
    /// La faccia dello slot E; `nil` in moto (la fascia E' il segnale) e senza show.
    let slotE: SlotE?
    /// La riga in STAGE-CAPS dello slot E.
    let slotELine: String?
    /// Le righe sotto (STAGE-SECONDARY): due di controllo, o una di dettaglio.
    let slotEDetailLines: [String]
    /// L'icona dello slot E, se qualcosa non va; con l'OK c'e' il pallino verde.
    let slotEIcon: Icon?
    /// La riga dello slot E e' ambra (qualcosa non va) o grigia (tutto a posto / cerca).
    let slotEIsAmber: Bool
    /// La riga di dettaglio e' ambra chiara («band playing — wait for the stop»).
    let slotEDetailIsAmber: Bool
    /// La riga evidenziata nella scaletta (proposta o armata), `nil` = nessuna, lista in cima.
    let highlightedRow: Int?
    let rowStyle: RowStyle?
    /// «suggested» · «a guess — check the band» · «your pick» · «tap another song to change».
    let rowLine: String?
    /// La riga da portare in cima: la precedente all'evidenziata (contesto), `nil` = in cima.
    let scrollTargetRow: Int?

    /// La lista d'ingresso (Join) contro RIENTRA (Rejoin): ragione nulla o `reset`.
    static func isEntry(reason: FollowerOutReason?) -> Bool {
        switch reason {
        case nil, .reset?: return true
        default: return false
        }
    }

    init(state: FollowerSyncState,
         reason: FollowerOutReason?,
         showOpen: Bool,
         directorHeard: Bool,
         searching: Bool,
         startStopSyncEnabled: Bool,
         linkSessionPlaying: Bool,
         proposal: RientraProposal,
         songNames: [String]) {
        let entry = Self.isEntry(reason: reason)

        // La faccia.
        var armedIdx: Int? = nil
        let face: Face
        if !showOpen {
            face = .noShow
        } else {
            switch state {
            case .inSync:
                face = .inSync
            case .alone:
                face = .alone
            case .out(let armed):
                if let armed {
                    face = .ready
                    armedIdx = armed
                } else if entry {
                    face = .join
                } else {
                    face = .out
                }
            }
        }
        self.face = face

        // La parola in testa e la riga sotto.
        switch face {
        case .join:
            headWord = Self.joinWord
            headWordIsAmber = false
            bodyLine = Self.pickLine
            bodyIcon = nil
        case .out:
            headWord = Self.outWord
            headWordIsAmber = true
            let line = Self.reasonLine(reason)
            bodyLine = line?.text
            bodyIcon = line?.icon
        case .ready:
            headWord = Self.readyWord
            headWordIsAmber = false
            let name = armedIdx.flatMap { songNames.indices.contains($0) ? songNames[$0] : nil } ?? ""
            bodyLine = Self.readyLine(songName: name)
            bodyIcon = nil
        case .noShow, .inSync, .alone:
            headWord = nil
            headWordIsAmber = false
            bodyLine = nil
            bodyIcon = nil
        }

        // L'intestazione della scaletta.
        switch face {
        case .join, .out, .ready:
            heading = entry ? .joinAt : .rejoinAt
            headingLine = entry ? Self.joinAtHeading : Self.rejoinAtHeading
            songsLine = Self.songsLine(count: songNames.count)
        case .noShow, .inSync, .alone:
            heading = nil
            headingLine = nil
            songsLine = nil
        }

        // Lo slot E.
        let slot: SlotE?
        switch face {
        case .join, .out, .ready:
            if !startStopSyncEnabled {
                slot = .startStopSyncOff
            } else if searching {
                slot = .searching
            } else if !directorHeard {
                slot = .noSignal
            } else if linkSessionPlaying {
                slot = .signalOKBandPlaying
            } else {
                slot = .signalOK
            }
        case .inSync:
            // Sul velo L1 compare solo il segnale OK: se il Direttore non si sente si va FUORI (D1).
            slot = .signalOK
        case .noShow, .alone:
            slot = nil
        }
        slotE = slot
        switch slot {
        case .startStopSyncOff?:
            slotELine = Self.startStopSyncOffLine
            slotEDetailLines = [Self.startStopSyncOffDetailLine]
            slotEIcon = .playStopBarred
            slotEIsAmber = true
            slotEDetailIsAmber = false
        case .searching?:
            slotELine = Self.searchingLine
            slotEDetailLines = []
            slotEIcon = nil
            slotEIsAmber = false
            slotEDetailIsAmber = false
        case .noSignal?:
            slotELine = Self.noSignalLine
            slotEDetailLines = [Self.noSignalDirectorLine, Self.noSignalNetworkLine]
            slotEIcon = .directorBarred
            slotEIsAmber = true
            slotEDetailIsAmber = false
        case .signalOKBandPlaying?:
            slotELine = Self.signalOKLine
            slotEDetailLines = [Self.bandPlayingLine]
            slotEIcon = nil
            slotEIsAmber = false
            slotEDetailIsAmber = true
        case .signalOK?:
            slotELine = Self.signalOKLine
            slotEDetailLines = []
            slotEIcon = nil
            slotEIsAmber = false
            slotEDetailIsAmber = false
        case nil:
            slotELine = nil
            slotEDetailLines = []
            slotEIcon = nil
            slotEIsAmber = false
            slotEDetailIsAmber = false
        }

        // La riga evidenziata nella scaletta.
        switch face {
        case .ready:
            highlightedRow = armedIdx
            rowStyle = .armed
            rowLine = Self.changeLine
        case .join, .out:
            if let idx = proposal.songIdx, songNames.indices.contains(idx) {
                highlightedRow = idx
                switch proposal.form {
                case .guess:
                    rowStyle = .proposalGuess
                    rowLine = Self.guessLine
                case .yourPick:
                    rowStyle = .proposalNormal
                    rowLine = Self.yourPickLine
                case .normal, .none:
                    rowStyle = .proposalNormal
                    rowLine = Self.suggestedLine
                }
            } else {
                highlightedRow = nil
                rowStyle = nil
                rowLine = nil
            }
        case .noShow, .inSync, .alone:
            highlightedRow = nil
            rowStyle = nil
            rowLine = nil
        }
        scrollTargetRow = highlightedRow.map { max(0, $0 - 1) }
    }

    /// «Riga sotto Out — BODY 21» (file 1 §0). Le ragioni d'ingresso non hanno riga: sono Join.
    static func reasonLine(_ reason: FollowerOutReason?) -> (text: String, icon: Icon?)? {
        switch reason {
        case nil, .reset?:
            return nil
        case .lostWhileStopped?:
            return (reasonLostWhileStopped, nil)
        case .playLate?:
            return (reasonPlayLate, nil)
        case .aloneSongEnded?:
            return (reasonAloneSongEnded, nil)
        case .directorStoppedWhileAlone?, .directorFalseStartWhileAlone?:
            return (reasonDirectorStoppedWhileAlone, nil)
        case .musicianStop?:
            return (reasonMusicianStop, nil)
        case .armRefusedNotHeard?:
            return (reasonRefusedNotHeard, .noEntry)
        case .armRefusedSessionPlaying?:
            return (reasonRefusedSessionPlaying, .noEntry)
        case .lostWhileArmed?:
            return (reasonLostWhileArmed, nil)
        }
    }
}
