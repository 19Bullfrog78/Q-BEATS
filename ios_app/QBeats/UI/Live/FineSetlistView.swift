import SwiftUI

struct FineSetlistView: View {
    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Propagato a `OverlayStopButtonStyle` con lo stesso valore ricevuto
    /// da `LiveView` (denominatore 390pt unico in tutta la Vista LIVE).
    let scaleFactor: CGFloat
    /// ⟦S5x⟧ (A64) — tap su BACK TO SHOWS. Comportamento ratificato
    /// `LIBRO_MASTRO_QBEATS.md:154` (R-CD5-10, 21/05): «torna alla libreria SHOWS».
    /// Closure OPACA e OBBLIGATORIA (niente default no-op: un default rifarebbe il
    /// bottone morto): questa vista non sa nulla di sessione né di navigazione —
    /// la composizione delle azioni vive nel presentatore (`LiveView`, unico callsite),
    /// che possiede la sessione.
    /// ⛔ RESTART SETLIST resta volutamente inerte: comportamento solo «proposto
    /// (CD-3)» (`LIBRO:153`), mai ratificato — cablarlo, disabilitarlo o
    /// nasconderlo è decisione CD, non di questo atomo.
    /// ⚠️ MARCATURA 23/08 — LA DECISIONE C'È: NON È PIÙ MATERIA DA DECIDERE.
    /// `LIBRO_MASTRO_QBEATS.md:353` (07/08/2026) dispone che RESTART SETLIST
    /// **si toglie** da END SHOW — opzione Ⓐ di CD, con due cancelli distinti
    /// passati entrambi: ratifica tecnica del referee e OK di Mauro.
    /// ⛔ Chi apre questo file per eseguire la rimozione NON deve tornare da CD
    /// per la decisione: è presa. Resta aperto il solo DISEGNO del piede con un
    /// pulsante unico, che la stessa riga dichiara non ratificato.
    /// ⚠️ Il testo sopra resta come fu scritto: era vero fino al 07/08.
    let onBackToShows: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#0e0e10").ignoresSafeArea()
            VStack(spacing: 24) {
                Text("END SHOW")
                    .font(.jbMono(.bold, size: 28 * scaleFactor))
                    .foregroundColor(.white)
                    .tracking(2)

                VStack(spacing: 12) {
                    Button("BACK TO SHOWS") { onBackToShows() }
                        .buttonStyle(OverlayStopButtonStyle(primary: true, scaleFactor: scaleFactor))
                    Button("RESTART SETLIST") { /* restart setlist — Fase successiva */ }
                        .buttonStyle(OverlayStopButtonStyle(primary: false, scaleFactor: scaleFactor))
                }
            }
            .padding(.horizontal, 40)
        }
    }
}
