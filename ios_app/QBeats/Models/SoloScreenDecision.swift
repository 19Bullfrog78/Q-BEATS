import Foundation

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — QUALE SCHERMO VEDE IL SOLO, E COSA C'È SCRITTO ===
// Una regola pura, letta da `LiveView`, totale sui casi di `LivePlaybackState` (mandato M3 §3.1):
//  · `.standby` con indice di sezione 0 → V1/V2, i veli prima della canzone e fra due canzoni (foglio Solo REV18,
//    V1, V2, i1; punti 80, 89, 100, 102, 114);
//  · `.standby` con indice > 0 (rientro con la sezione conservata) e `.stopped` (dopo lo Stop) → H senza la fila
//    (BOX5 V54, decisione 6: «Dopo lo Stop, fino al pezzo 2: il Solo vede il velo dello schermo H senza la fila e
//    senza tocco, e riparte col Play dalla sezione conservata»; referto A393 §12.6, rischio 1);
//  · `.fineSetlist` → V4 (BOX5 V54, decisione 5: la fine scaletta V4 «ora per tutti»);
//  · `.playing`, `.countIn`, `.starting`, `.loopActive` → K di M2, com'è;
//  · `.overlayStop` → com'è oggi (pezzo 2; decisione b del cancello A397).
// Dalla stessa regola escono parole, tocco e tasto (BOX5, «Overlay Standby», marcatura A355: «Un solo dato per il
// testo e per il tocco»). La sezione è `runner.currentSection`: con indice 0 in `.standby` è la prima della canzone
// che il tocco fa partire (`startCurrentSong`); in H è quella che il Play fa ripartire (`startCurrentSection`;
// BOX5, «Invarianti tecnici Layer 3», riga «RESUME = runner.startCurrentSection»). Nessuna riga di conto sui veli
// (BOX5, invariante «Il velo NON porta righe di count-in finché il count-in non suona»): tempo e metrica non sono
// il conto.
// Le parole: «Next» senza i due punti (`.p-va`, V1/V2); «Resume from » e la sezione (`.p-va`, `.p-va b`, H); senza
// nome, o con soli spazi, «Section N» (punto 109, `SectionNameDecision`); «Tap to start» (punto 100, forma A);
// tempo e metrica «121 · 4/4» (`.p-vt`): il BPM come in K, `Int(bpm.rounded())`, la metrica con `MeterLabel`.
// La testata dice lo show sui veli e su V4 (punto 102: `room.showName`; se manca o è vuoto, il centro resta vuoto,
// D6), la canzone in K. Per Direttore e Follower su V4 la testata senza il nome dello show e niente riga di stato
// (BOX5 V54, decisione 5: «Per ora solo nel Solo: la riga di stato, 'Next' senza i due punti, il nome dello show in
// testata»).
// ⚠️ A401 (10/10/2026) — SOLO REV20 (`DESIGN/QLive_Nav/2026-10-10_QLive-Player_G1-SOLO-REV20_390x844_1.html`):
//  · punto 117: su V4 il nome dello show sta al centro della testata per i tre ruoli («Anche per Direttore e Follower
//    al centro della testata va il nome dello show, nella veste del Solo»); la riga di stato resta del solo Solo («La
//    riga di stato resta come dice la decisione 5»). «Per Direttore e Follower su V4 la testata senza il nome dello
//    show» qui sopra è storia: si marca. Il 117 supera, per il solo centro della testata di V4, la decisione 5 del
//    05/10 (LIBRO, riga 2026-10-10);
//  · punto 116: sui veli, su H e nel titolo di K una canzone senza nome si scrive «Song N», N = il posto nello show
//    (`SongNameDecision`; il posto è `runner.currentSongIdx + 1`, passato dal chiamante).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum SoloScreenKind: String, Equatable {
    /// V1/V2: il velo prima della canzone e fra due canzoni.
    case veil
    /// H senza la fila: fermo dopo lo Stop, o rientro con la sezione conservata.
    case resume
    /// K, il player in moto (e il conto, e l'avvio comandato).
    case playing
    /// V4, la fine scaletta.
    case endShow
    /// Il pannello superato del pedale sopra K, com'è oggi (pezzo 2).
    case overlayStop
}

/// Cosa fa un tocco sul velo.
enum SoloVeilTap: Equatable {
    /// V1/V2: la canzone parte (`runner.startCurrentSong`).
    case startSong
    /// H: niente (punto 87).
    case none
}

struct SoloScreen: Equatable {
    let kind: SoloScreenKind
    /// Il centro della testata: lo show sui veli e su V4, la canzone in K.
    let headerTitle: String
    /// La riga di stato c'è (nel Solo sempre: punto 80).
    let statusRow: Bool
    /// La riga A: la frase («Next» oppure «Resume from ») e, in H, la sezione come si scrive.
    let relationPrefix: String
    let relationSection: String?
    /// Il nome della canzone sul velo.
    let songName: String
    /// «121 · 4/4», oppure vuoto se la sezione non si risolve.
    let tempoLine: String
    /// «Tap to start» sui veli V1/V2; `nil` altrove.
    let gestureLine: String?
    /// Il tocco sul velo.
    let tap: SoloVeilTap
    /// La console c'è (H: Play al centro, Mixer acceso; V1/V2 e V4: no).
    let consoleVisible: Bool
    /// In H il Play fa ripartire la sezione conservata (`runner.startCurrentSection`).
    let playStartsSection: Bool

    /// La riga A intera, come si legge.
    var relationLine: String { relationPrefix + (relationSection ?? "") }
}

enum SoloScreenDecision {

    static let nextWord = "Next"
    static let resumePrefix = "Resume from "
    static let tapToStart = "Tap to start"
    /// Il punto a mezza altezza di «121 · 4/4» (U+00B7), con gli spazi.
    static let tempoSeparator = " \u{00B7} "

    /// «121 · 4/4»: il BPM arrotondato come in K (`Int(bpm.rounded())`: 180,5 → 181), la metrica dai due numeri
    /// della sezione (`MeterLabel`). Senza sezione, vuoto.
    static func tempoLine(bpm: Double?, beatsPerBar: UInt32?, beatUnit: UInt32?) -> String {
        guard let bpm, let beatsPerBar, let beatUnit, bpm.isFinite else { return "" }
        return "\(Int(bpm.rounded()))" + tempoSeparator + MeterLabel.text(beatsPerBar: beatsPerBar, beatUnit: beatUnit)
    }

    /// Lo show in testata: come è scritto; se manca o è di soli spazi, vuoto (D6).
    static func showTitle(_ showName: String?) -> String {
        guard let showName, !SectionNameDecision.isBlank(showName) else { return "" }
        return showName
    }

    /// Lo schermo del Solo.
    /// - `state`: lo stato del player (`session.playbackState`).
    /// - `sectionIndex`: `runner.currentSectionIdx`; `sectionName`: `runner.currentSection?.name` (`nil` = non si risolve).
    /// - `currentSongName`: `runner.currentSong?.name`, la canzone che il Play fa ripartire a `.stopped`.
    /// - `showName`: `room.showName`; `songNameInMotion`: `session.currentSongName`, il titolo di K.
    /// - `songNumber`: il posto nello show della canzone del runner, da 1 (`runner.currentSongIdx + 1`): è la
    ///   canzone di `currentSongName`, del nome in `.standby(nextSongName:)` e di `songNameInMotion` (il runner li
    ///   legge tutti da `currentSong`); `displayWritten`: il display della canzone è scritto
    ///   (`session.macroBarCurrent > 0`). Senza nome, «Song N» (punto 116, `SongNameDecision`). Una canzone che non si
    ///   risolve a `.stopped` (`currentSongName == nil`) non è una canzone senza nome: il nome resta vuoto.
    /// - tempo e metrica della sezione (`runner.currentSection`): bpm, beatsPerBar, beatUnit.
    static func screen(state: LivePlaybackState,
                       sectionIndex: Int,
                       sectionName: String?,
                       currentSongName: String?,
                       showName: String?,
                       songNameInMotion: String,
                       songNumber: Int,
                       displayWritten: Bool,
                       sectionBPM: Double?,
                       sectionBeatsPerBar: UInt32?,
                       sectionBeatUnit: UInt32?) -> SoloScreen {
        let tempo = tempoLine(bpm: sectionBPM, beatsPerBar: sectionBeatsPerBar, beatUnit: sectionBeatUnit)
        let sectionWritten = SectionNameDecision.displayName(sectionName ?? "", numberInSong: max(sectionIndex, 0) + 1)
        let show = showTitle(showName)
        let titleInMotion = SongNameDecision.titleInMotion(songNameInMotion, numberInShow: songNumber,
                                                           displayWritten: displayWritten)
        switch state {
        case .standby(let nextSongName):
            let song = SongNameDecision.displayName(nextSongName, numberInShow: songNumber)
            if sectionIndex > 0 {
                return resume(songName: song, section: sectionWritten, tempo: tempo, show: show)
            }
            return SoloScreen(kind: .veil, headerTitle: show, statusRow: true,
                              relationPrefix: nextWord, relationSection: nil,
                              songName: song, tempoLine: tempo, gestureLine: tapToStart,
                              tap: .startSong, consoleVisible: false, playStartsSection: false)
        case .stopped:
            let song = currentSongName.map { SongNameDecision.displayName($0, numberInShow: songNumber) } ?? ""
            return resume(songName: song, section: sectionWritten, tempo: tempo, show: show)
        case .fineSetlist:
            return SoloScreen(kind: .endShow, headerTitle: show, statusRow: true,
                              relationPrefix: "", relationSection: nil,
                              songName: "", tempoLine: "", gestureLine: nil,
                              tap: .none, consoleVisible: false, playStartsSection: false)
        case .overlayStop:
            return playing(kind: .overlayStop, title: titleInMotion)
        case .playing, .countIn, .starting, .loopActive:
            return playing(kind: .playing, title: titleInMotion)
        }
    }

    private static func resume(songName: String, section: String, tempo: String, show: String) -> SoloScreen {
        SoloScreen(kind: .resume, headerTitle: show, statusRow: true,
                   relationPrefix: resumePrefix, relationSection: section,
                   songName: songName, tempoLine: tempo, gestureLine: nil,
                   tap: .none, consoleVisible: true, playStartsSection: true)
    }

    private static func playing(kind: SoloScreenKind, title: String) -> SoloScreen {
        SoloScreen(kind: kind, headerTitle: title, statusRow: true,
                   relationPrefix: "", relationSection: nil,
                   songName: "", tempoLine: "", gestureLine: nil,
                   tap: .none, consoleVisible: true, playStartsSection: false)
    }

    // MARK: V4 per tutti i ruoli (BOX5 V54, decisione 5; Solo REV20, punto 117)

    /// Il centro della testata a fine scaletta: il nome dello show, per i tre ruoli (A401, punto 117; fino ad A400
    /// lo show nel Solo e vuoto per Direttore e Follower). Il ruolo resta nella firma: i chiamanti lo passano già,
    /// e la regola resta per ruolo come quella della riga di stato qui sotto.
    static func endShowHeaderTitle(role: PlayerRole, showName: String?) -> String {
        showTitle(showName)
    }

    /// La riga di stato a fine scaletta: solo nel Solo.
    static func endShowStatusRow(role: PlayerRole) -> Bool {
        role == .solo
    }

    static let backToShows = "Back to Shows"
}
