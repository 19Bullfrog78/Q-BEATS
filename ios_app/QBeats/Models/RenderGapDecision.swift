import Foundation

// === A421 (24/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 2: IL BUCO DEL RENDER DIVENTA UNA CRISI (U7, U8) ===
// Il fatto (referto A419, §3.2; collaudo del 24/10). Il misuratore (`RenderGapMeter`, A416) vede un buco alla prima chiamata
// di `scheduleNextBuffer` dopo la ripresa del render, quando almeno un buffer è già passato al rendering; fino ad A420 la
// riga `[RENDER]` e basta, e sul Direttore il buffer del buco faceva l'assert e spostava la band (19/10: 1,4371 battiti;
// 24/10: 1,5253). I buchi misurati: sul Direttore e nel Solo solo con un cambio di percorso (108-906 ms); sul Follower
// senza (32,2-48,8 ms).
//
// La regola (mandato «USCITA AUDIO PASSO 2a PEZZO 2», par. 2.1 U7 e U8; referto A419, §3.2.b e §3.2.c (iii)):
//  · la crisi da misuratore, a 75 ms (in millisecondi, accanto alla soglia della riga, che resta a tre buffer), solo per il
//    Direttore a show aperto con la canzone in corso e il motore in moto: il silenzio, la crisi «buco-del-render», l'arresto
//    locale, e il buffer del buco non si programma (né assert né correzione). Anche col Direttore che segue già Link (T4):
//    i buffer in coda escono in ritardo, e il rientro rimette la battuta;
//  · sotto la soglia col Direttore in canzone, e fuori da una canzone per ogni buco sopra la soglia della riga: il Direttore
//    segue Link fino al Play dopo (`_directorFollowsLinkQ`), e la correzione nel buffer del buco resta (la (iii) del referto
//    A419, decisa dal referee il 23/10);
//  · Follower e Solo: la riga e basta (il Follower resta di registro, scelta 5 del referee; il Solo non ha una band).
// La notizia del cambio di percorso viene prima (U1): questa regola è la rete per i buchi senza notizia, o con una notizia
// di classe «nessuna».
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// L'esito, col nome che va nella riga `[RENDER] … -> esito:`.
enum RenderGapOutcome: String, Equatable, CaseIterable {
    case lineOnly = "solo-riga"
    case followLink = "segue-link"
    case crisis = "crisi"
}

enum RenderGapDecision {

    /// La regola. `holeSeconds`: il buco stimato dal misuratore (scarto meno base), già sopra la soglia della riga.
    static func outcome(holeSeconds: Double,
                        playerRole: PlayerRole,
                        showOpen: Bool,
                        songInProgress: Bool,
                        engineRunning: Bool,
                        followsLink: Bool,
                        silentInSong: Bool) -> RenderGapOutcome {
        guard playerRole == .direttore, engineRunning else { return .lineOnly }
        let inSong = showOpen && songInProgress
        guard inSong else { return .followLink }
        guard holeSeconds.isFinite, holeSeconds >= RenderGapMeter.crisisThresholdSeconds else { return .followLink }
        return .crisis
    }

    /// L'innesco nella riga `[DIR-RIENTRO] segue Link innesco:…` quando l'esito è `followLink`.
    static func followLinkTrigger(showOpen: Bool, songInProgress: Bool) -> String {
        (showOpen && songInProgress) ? "buco-piccolo" : "buco-fuori-canzone"
    }
}
