import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LO SCHERMO K: LA COMPOSIZIONE DEL PLAYER DEL SOLO ===
// Chi lo vede: il Solo di `PlayerRoleDecision.playerRole` (M1); lo sceglie `LiveView`, che resta uno per tutti
// i ruoli (A393 §12.2: niente secondo `LiveView`, niente specchi copiati). Qui si mette a schermo e basta: ogni
// blocco al suo posto (`SoloPlayerGeometry`, decisione D4: cornice 390 x 766, fattore unico, posizioni in punti),
// con le misure del foglio per il fattore. Testata, riga di stato, spie, battuta e BPM, barra delle battute,
// sezione, Next, barra della canzone, console. Per gli stati con la console in vista: `.playing`, `.countIn`,
// `.starting`, `.stopped` (a `.stopped` è K fermo col Play al centro, provvisorio fino a M3). Sui veli e a fine
// scaletta (fino a M3) sopra questa composizione stanno le schermate di oggi: sotto il velo la composizione si
// attenua (`contentOpacity`, come oggi `standbyOpacity`) e il velo prende i tocchi.
// I dati arrivano dalla sessione (`LiveSession`: i campi che oggi leggono le viste del player, scritti dal runner
// al tick giusto, TD #41) e dal chiamante (pattern e stato di oggi, le spie, le facce della console, le battute
// delle sezioni della canzone dal runner in sola lettura). Le azioni tornano al chiamante: freccia, muto, tasti
// della console (`SoloConsoleKey`), che agisce con le chiamate di oggi e logga.
struct SoloPlayerView: View {
    @ObservedObject var session: LiveSession
    let geometry: SoloPlayerGeometry
    let displayAccentPattern: [UInt8]
    let sectionHold: Bool
    let lights: StatusLights
    let midiLampOff: Bool
    let faces: SoloConsoleFaces
    let clickMuted: Bool
    let barsPerSection: [Int]
    let contentOpacity: Double
    let onExit: () -> Void
    let onToggleMute: () -> Void
    let onConsoleKey: (SoloConsoleKey) -> Void

    var body: some View {
        let g = geometry
        let s = g.scale
        ZStack(alignment: .topLeading) {
            place(g.header) {
                SoloHeaderView(title: session.currentSongName,
                               muted: clickMuted,
                               scale: s,
                               contentOpacity: contentOpacity,
                               onExit: onExit,
                               onToggleMute: onToggleMute)
            }
            Group {
                // La riga di stato prende la larghezza intera della cornice: la striscia «Link lost» parte dal
                // bordo (punto 112); le voci stanno a 18 dai bordi come nel foglio (`.p-rl{left:18px;right:18px}`).
                place(g.rect(sheetX: 0, sheetY: 98, width: SoloPlayerGeometry.frameWidth, height: 30)) {
                    SoloStatusRowView(lights: lights, midiLampOff: midiLampOff, scale: s,
                                      sidePadding: CGFloat(g.scaled(18)))
                }
                place(g.beatLights) {
                    BeatLightsView(pattern: displayAccentPattern, beatActive: session.beatActive, scale: s)
                }
                place(g.barRow) {
                    SoloBarRowView(current: session.currentBar, total: session.totalBarsInSection,
                                   state: session.playbackState, bpm: session.currentBPM, scale: s)
                }
                place(g.barMeter) {
                    SoloBarMeterView(current: session.currentBar, total: session.totalBarsInSection,
                                     state: session.playbackState, sectionHold: sectionHold, scale: s)
                }
                place(g.prompter) {
                    SoloPrompterView(name: sectionDisplayName, scale: s)
                }
                place(g.next) {
                    SoloNextView(next: nextDecision, scale: s)
                }
                place(g.songBar) {
                    SoloSongBarView(layout: songBarLayout, scale: s)
                }
                place(g.console) {
                    SoloConsoleView(faces: faces, scale: s, onKey: onConsoleKey)
                }
            }
            .opacity(contentOpacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Il nome della sezione in corso: come è scritto, oppure «Section N» (punto 109; N = `macroBarCurrent`, che il
    /// runner scrive come indice + 1 al tick giusto). Con il display non ancora scritto (0) niente.
    private var sectionDisplayName: String {
        guard session.macroBarCurrent > 0 else { return "" }
        return SectionNameDecision.displayName(session.currentSectionName, numberInSong: session.macroBarCurrent)
    }

    /// Next (punto 108): la sezione dopo (`nextSectionName`, scritta dal runner da `nextSection`), la canzone dopo
    /// all'ultima sezione (`nextSongName`, scritta dal runner da `nextSong` solo se `isLastSectionInSong`), oppure
    /// «END SHOW» all'ultima dell'ultima canzone. Con il display non ancora scritto (0) niente.
    private var nextDecision: SoloNext {
        guard session.macroBarCurrent > 0 else { return SoloNext(label: SoloNextDecision.nextLabel, value: "") }
        return SoloNextDecision.next(nextSectionName: session.nextSectionName,
                                     nextSectionNumber: session.macroBarCurrent + 1,
                                     nextSongName: session.nextSongName)
    }

    /// La barra della canzone: le battute di ogni sezione della canzone (dal runner, `currentSong`), la sezione in
    /// corso (`macroBarCurrent` − 1) e l'avanzamento dentro di lei (`currentBar` / `totalBarsInSection`).
    private var songBarLayout: SoloSongBarLayout {
        SoloSongBarLayout(barsPerSection: barsPerSection,
                          currentSectionIndex: session.macroBarCurrent - 1,
                          currentBar: session.currentBar,
                          totalBarsInSection: session.totalBarsInSection)
    }

    /// Un blocco al suo posto: misura e posizione dalla geometria, in punti dell'area utile.
    private func place<Content: View>(_ r: SoloRect, @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(width: CGFloat(r.width), height: CGFloat(r.height))
            .offset(x: CGFloat(r.x), y: CGFloat(r.y))
    }
}
