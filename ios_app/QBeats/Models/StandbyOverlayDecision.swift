import Foundation

// === A355 — LA DECISIONE DEL VELO: UN SOLO POSTO, TESTATO ===
// Il velo dell'attesa (`StandbyOverlayView`) e il tocco che fa ripartire
// (`LiveView`) leggevano due dati diversi: il tocco decideva da solo su
// `runner.currentSectionIdx > 0`, e il testo non esisteva. Da qui escono, dallo
// STESSO ingresso, sia il ramo del tocco sia le tre righe a schermo — così il
// velo non può dire una cosa e il tocco farne un'altra.
// Ratifiche: LIBRO riga `2026-08-30` «⑤ IL VELO DEL PLAYER DEVE DIRE DOVE RIPARTE»
// (nome canzone + RESUME + nome sezione, tap ovunque) · LIBRO riga `2026-09-09/11`
// «IL TRASPORTO È DEL DIRETTORE» · LIBRO riga `2026-09-11` «CRITERIO GENERALE DEL
// PERIMETRO DEL FOLLOWER» (al Follower il tocco sul velo è tolto) · BOX5
// «SCALA DI PALCO» (regola del gigante) · foglio CD 11/09
// `IL-FOLLOWER-NON-TOCCA-IL-TRASPORTO`, lastre ①②⑥ (`.vlbl`, `.vnm`, `.vhint`).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro
// (`ios_app/project.yml`, target QBeatsTests). Niente SwiftUI, niente motore:
// «Follower» lo calcola il chiamante con la regola incisa in BOX5
// (`audioEngine.currentLinkMode == .collaborativa`), e qui arriva come booleano.
// ⚠️ MARCATURA A360 (16/09/2026) — «Follower» arriva ancora come booleano, ma chi lo
//    calcola è `FollowerDecision` (ruolo E Link acceso dall'utente), non più il solo
//    ruolo. Con `nobodyConnected` (Follower senza nessun apparecchio collegato) il velo
//    aggiunge le due righe della lastra ⑧ del foglio CD 11/09 (`.vlink .s`, `.vlink .c`).
// ⚠️ MARCATURA A386 · B2b (30/09/2026) — DUE COSE CAMBIANO SUL FOLLOWER, foglio CD 2D-QUATER:
//    (1) il collegato di Link (`nobodyConnected`) non decide più niente sul velo del Follower:
//        le righe «No device connected» e «nothing will start from here» ESCONO, e al loro
//        posto sta lo slot E del foglio («Director signal OK» sul velo IN SYNC, L1), deciso da
//        `FollowerVeilDecision` e passato alla vista da `LiveView`;
//    (2) sul Follower il velo non scrive MAI «Resume from»: si entra solo a inizio canzone
//        (2D-D6) e il foglio L1 dice «Next:». Per il Follower questo SUPERA la decisione (a) di
//        A355 in BOX5 (la marcatura va al giro dei canonici). Il velo di chi comanda il trasporto
//        (Direttore, Solo) non cambia: «Resume from ⟨sezione⟩» resta suo.
//    Il testo dell'A360 qui sopra resta come storia: si marca, non si riscrive.
struct StandbyOverlayDecision: Equatable {

    /// Regola del gigante (BOX5 «SCALA DI PALCO» · foglio CD 11/09 LA-TABELLA-FINALE §③):
    /// fino a 12 caratteri una riga (il nome scende da STAGE-HERO fino a STAGE-NEXT,
    /// mai sotto) · da 13 a 25 due righe al pavimento · oltre 25 due righe con ellissi.
    /// Le soglie le ha calcolate CD su 338 px utili e avanzamento medio 0,60 em:
    /// qui si contano i caratteri, non si misura il testo.
    enum NameForm: Equatable {
        case oneLine
        case twoLines
        case twoLinesEllipsis
    }

    static let oneLineMaxCharacters = 12
    static let twoLinesMaxCharacters = 25

    // Copy a schermo, sempre in inglese (BOX5 §6). Le MAIUSCOLE le mette la vista
    // (stile STAGE-CAPS), non il testo: qui la forma è quella dei fogli CD.
    static let resumePrefix = "Resume from "
    static let nextLine = "Next:"
    static let tapGesture = "Tap anywhere"
    static let directorGesture = "The director starts"

    /// C'è un punto di ripresa nella canzone corrente (indice di sezione > 0).
    /// È il dato che sceglie la ripartenza — `startCurrentSection` contro
    /// `startCurrentSong` — e lo leggono in due: il tocco e la riga A.
    let hasResumePoint: Bool
    /// L'apparecchio è Follower: il gesto non è suo (LIBRO `2026-09-11` «CRITERIO
    /// GENERALE DEL PERIMETRO DEL FOLLOWER»).
    let isFollower: Bool
    /// Il nome della sezione corrente, tolti gli spazi, è vuoto (lo legge la
    /// strumentazione: «nome vuoto sì/no»).
    let sectionNameIsBlank: Bool
    /// Riga A — relazione: «Resume from ⟨sezione⟩» oppure «Next:». Sul Follower sempre «Next:».
    let relationLine: String
    /// Riga B — il nome della canzone, come è scritto.
    let songName: String
    /// Forma della riga B secondo la regola del gigante.
    let nameForm: NameForm
    /// Riga C — gesto: «Tap anywhere» oppure «The director starts».
    let gestureLine: String

    init(currentSectionIdx: Int, currentSectionName: String, songName: String,
         isFollower: Bool) {
        let hasResumePoint = currentSectionIdx > 0
        // Garanzia contro la bugia (foglio CD 11/09, lastra ①): se il nome della
        // sezione non si risolve, il velo NON scrive «Resume from —» — ricade
        // sulla riga della partenza. Il punto di ripresa resta: lo legge il tocco.
        let sectionName = currentSectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.hasResumePoint = hasResumePoint
        self.isFollower = isFollower
        self.sectionNameIsBlank = sectionName.isEmpty
        // B2b: sul Follower mai «Resume from» (2D-D6, foglio 2D-QUATER L1: «Next:»).
        self.relationLine = (!isFollower && hasResumePoint && !sectionName.isEmpty)
            ? Self.resumePrefix + sectionName
            : Self.nextLine
        self.songName = songName
        self.nameForm = Self.nameForm(for: songName)
        self.gestureLine = isFollower ? Self.directorGesture : Self.tapGesture
    }

    /// Caratteri, non byte: `String.count` conta i grafemi.
    static func nameForm(for name: String) -> NameForm {
        let count = name.count
        if count <= oneLineMaxCharacters { return .oneLine }
        if count <= twoLinesMaxCharacters { return .twoLines }
        return .twoLinesEllipsis
    }
}
