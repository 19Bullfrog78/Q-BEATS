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

// === A401 (10/10/2026) — SOLO REV20, PUNTO 116: UNA CANZONE SENZA NOME ===
// Foglio `DESIGN/QLive_Nav/2026-10-10_QLive-Player_G1-SOLO-REV20_390x844_1.html`, punto 116: «Dove il player scrive
// il nome della canzone (testata di K, dopo «Next song», sui veli) una canzone senza nome, o di soli spazi, si scrive
// «Song» col suo numero nello show, da 1: come «Section N» per le sezioni (punto 109). Prende il posto del valore
// vuoto della costruzione (A397 §10, caso 6). Il numero è del posto: cambia se la canzone cambia posto nello show.»
// Il posto lo tiene il runner (`SetlistRunner.currentSongIdx`, in sola lettura), contato da 1: è lo stesso indice da
// cui il runner legge il nome che scrive nella sessione e nel caso `.standby(nextSongName:)`.
// Si applica nel player del Solo; sugli schermi di Direttore e Follower entra nel loro giro.
enum SongNameDecision {
    static let unnamedPrefix = "Song "

    /// Il nome come è scritto, oppure «Song N» (N = il posto della canzone nello show, contato da 1).
    static func displayName(_ name: String, numberInShow: Int) -> String {
        SectionNameDecision.isBlank(name) ? unnamedPrefix + String(numberInShow) : name
    }

    /// Il titolo di K. `displayWritten`: il runner ha già scritto il display della canzone
    /// (`LiveSession.macroBarCurrent > 0`; nome e numero di sezione li scrive insieme, `updateSessionDisplay`, e
    /// insieme li azzera). Prima, il nome in sessione è vuoto perché non è ancora scritto, non perché la canzone è
    /// senza nome: resta com'è, come la sezione (`SoloPlayerView.sectionDisplayName`).
    static func titleInMotion(_ name: String, numberInShow: Int, displayWritten: Bool) -> String {
        displayWritten ? displayName(name, numberInShow: numberInShow) : name
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
    /// canzone dopo (`nil` = non c'è, oppure non serve perché c'è ancora una sezione); `nextSongNumber`: il suo
    /// posto nello show, da 1 (A401, punto 116: senza nome «Song N»).
    static func next(nextSectionName: String?, nextSectionNumber: Int, nextSongName: String?,
                     nextSongNumber: Int) -> SoloNext {
        if let section = nextSectionName {
            return SoloNext(label: nextLabel,
                            value: SectionNameDecision.displayName(section, numberInSong: nextSectionNumber))
        }
        if let song = nextSongName {
            return SoloNext(label: nextSongLabel,
                            value: SongNameDecision.displayName(song, numberInShow: nextSongNumber))
        }
        return SoloNext(label: nextLabel, value: endShow)
    }
}
