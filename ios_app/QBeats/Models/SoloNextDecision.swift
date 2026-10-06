import Foundation

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — NEXT E IL NOME DELLA SEZIONE ===
// Punto 108 (Solo REV18, schermi c1 e c2): dopo la sezione in corso viene la sezione dopo («Next» e il nome);
// all'ultima sezione della canzone «Next song» e la canzone dopo, nella stessa casella e con la stessa veste;
// all'ultima sezione dell'ultima canzone «Next» e «END SHOW», la parola della fine scaletta (V4). Via il «FINE ·
// NEXT SONG:» di oggi (`POIView`). Punto 109 (schermo d): una sezione senza nome si chiama «Section» col suo
// numero nella canzone, contato da 1, dovunque il player scrive il nome (teleprompter, Next, fila, «Resume
// from»); un nome di soli spazi conta come senza nome, come nel velo (`StandbyOverlayDecision`). Il numero è il
// posto, non un nome: se la sezione cambia posto nell'editor, cambia numero.
// Testo a schermo in inglese (BOX5 §6); le parole sono quelle del foglio.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum SectionNameDecision {
    static let unnamedPrefix = "Section "

    /// Vero se il nome, tolti gli spazi, è vuoto.
    static func isBlank(_ name: String) -> Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Il nome come è scritto, oppure «Section N» (N contato da 1 nella canzone).
    static func displayName(_ name: String, numberInSong: Int) -> String {
        isBlank(name) ? unnamedPrefix + String(numberInSong) : name
    }
}

struct SoloNext: Equatable {
    /// «Next» oppure «Next song».
    let label: String
    /// Il nome della sezione o della canzone che viene dopo, oppure «END SHOW».
    let value: String
}

enum SoloNextDecision {
    static let nextLabel = "Next"
    static let nextSongLabel = "Next song"
    static let endShow = "END SHOW"

    /// `nextSectionName`: il nome della sezione dopo nella stessa canzone (`nil` = la sezione in corso è
    /// l'ultima della canzone); `nextSectionNumber`: il suo numero nella canzone, da 1; `nextSongName`: la
    /// canzone dopo (`nil` = non c'è, oppure non serve perché c'è ancora una sezione).
    static func next(nextSectionName: String?, nextSectionNumber: Int, nextSongName: String?) -> SoloNext {
        if let section = nextSectionName {
            return SoloNext(label: nextLabel,
                            value: SectionNameDecision.displayName(section, numberInSong: nextSectionNumber))
        }
        if let song = nextSongName {
            return SoloNext(label: nextSongLabel, value: song)
        }
        return SoloNext(label: nextLabel, value: endShow)
    }
}
