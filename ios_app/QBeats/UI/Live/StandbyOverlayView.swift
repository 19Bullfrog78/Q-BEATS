import SwiftUI

struct StandbyOverlayView: View {
    let nextSongName: String

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Ricevuto come parametro esplicito da `LiveView` per uniformità
    /// (denominatore 390pt unico per tutta la Vista LIVE). Il
    /// `GeometryReader` interno serve invece per il layout verticale
    /// (Spacer 0.27 × height) e NON va toccato.
    let scaleFactor: CGFloat

    @State private var pulseOpacity: Double = 0.45

    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer().frame(height: geo.size.height * 0.27)
                Text(nextSongName.uppercased())
                    .font(.custom("Inter-Black", size: 52 * scaleFactor))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(pulseOpacity)
                    .padding(.horizontal, 20)
                    // A128 — CENTRATURA ORIZZONTALE. `BOX5_QBEATS.md:253`: «mostra il nome
                    // canzone successiva AL CENTRO SCHERMO». Prima di questa riga il nome
                    // usciva TUTTO A SINISTRA sul device.
                    // ⛔ IL DIFETTO NON ERA `.multilineTextAlignment(.center)` QUI SOPRA, e
                    //    va capito o si ripete: quella allinea le righe FRA LORO dentro il
                    //    frame del testo, non allarga il frame e non lo centra nel genitore.
                    //    Le due modifiche fanno lavori diversi e servono ENTRAMBE.
                    // ⚠️ LA CAUSA VERA È UN'ASIMMETRIA DEL VStack QUI SOPRA: in verticale
                    //    si allarga perché lo `Spacer()` finale spinge lungo l'asse della
                    //    pila; in ORIZZONTALE non spinge nulla, quindi il VStack si stringe
                    //    sul contenuto — e il `GeometryReader` posa il proprio figlio in
                    //    ALTO A SINISTRA. Mancava un vincolo di larghezza, ed è questo.
                    // ✅ Il `GeometryReader` resta dov'è, come prescrive `BOX5:256`: questa
                    //    riparazione ci convive, non lo sostituisce.
                    // Forma: `.frame(maxWidth: .infinity)` — allineamento predefinito
                    // `.center`. È l'idioma già in uso nella stessa cartella su sei siti
                    // (`OverlayStopView.swift:45`, `WaitingForDirectorView.swift:60` e `:77`,
                    // `MixerOverlayView.swift:23` e `:72`, `RubberBtnView.swift:36`).
                    // ⚠️ VA DOPO `.padding`, non prima: così la larghezza piena avvolge il
                    //    testo GIÀ spaziato e i 20pt restano un margine interno anche a nome
                    //    lungo. Invertendo, il padding si sommerebbe FUORI dal frame pieno.
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .onAppear { startPulse() }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            pulseOpacity = 1.0
        }
    }
}
