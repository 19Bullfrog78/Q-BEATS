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
    /// ✅ ESEGUITO 01/09/2026 (mandato A309): il bottone RESTART SETLIST e il suo
    /// `.buttonStyle` sono stati rimossi da questo file.
    /// ✅ DISEGNO RATIFICATO 05/09/2026 (mandato A318): `LIBRO_MASTRO_QBEATS.md`
    /// Sezione 2, riga `2026-09-05` contiene il disegno del piede a un pulsante
    /// per intero — è la fonte, non il foglio CD. Vestito qui (mandato A319).
    let onBackToShows: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#0e0e10").ignoresSafeArea()

            // Colonna unica: il titolo prende lo spazio che avanza SOPRA il
            // pulsante (non l'intero schermo) — il pulsante occupa il proprio
            // spazio nel flusso, non è sovrapposto. Zero spacing fra i due:
            // altrimenti lo spazio di sistema fra i figli sposta il baricentro.
            VStack(spacing: 0) {
                VStack {
                    Spacer()
                    Text("END SHOW")
                        .font(.custom("Inter-Black", size: 46 * scaleFactor))
                        .foregroundColor(.white)
                        .tracking(3)
                    Spacer()
                }
                .padding(.bottom, 26)

                Button("BACK TO SHOWS") { onBackToShows() }
                    .buttonStyle(EndShowButtonStyle(scaleFactor: scaleFactor))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
    }
}
