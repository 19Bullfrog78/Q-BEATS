import Foundation

// === A386 · FASE B1 (2D) — LA FALSA PARTENZA: DENTRO O FUORI, TESTATO ===
// D7-bis (Mauro, 24/09/2026): uno Stop del Direttore ENTRO LA PRIMA BATTUTA DAL PLAY non
// chiude la canzone, in TUTTE le canzoni — Direttore e Follower tornano sul velo della STESSA
// canzone («falsa partenza»). Oltre la prima battuta vale D6: lo Stop chiude.
// `Song.countIn` NON entra nella regola: oggi il count-in non suona (SetlistRunner, «niente
// count-in tra canzoni»; `TD-countin-ratificato-mai-costruito`); quando verra' costruito la
// regola si riguarda. Il margine e' UNA BATTUTA: i battiti per battuta della prima sezione
// della canzone in corso (`marginBeats(beatsPerBar:)`).
// Regole del referee, identiche su ogni apparecchio:
//  · conta l'istante in cui il Direttore ha fermato, portato da Link nello stato di stop
//    (`ABLLinkTimeForIsPlaying` con `ABLLinkIsPlaying` falso), MAI l'istante in cui lo Stop
//    arriva al Follower: la latenza di rete sul bordo farebbe decidere diversamente Direttore
//    e Follower;
//  · falsa partenza se `battitoStop − battitoAvvio < margine`, in BATTITI DI SESSIONE letti da
//    Link (`phaseAtStampQBig` delle due catture, la fase e' condivisa fra i peer: ABLLink.h
//    :280-287 [R]); il Direttore usa la stessa formula sugli stessi numeri, non il proprio
//    `playbackState`;
//  · intervallo chiuso a sinistra e aperto a destra: `[avvio, avvio + margine)`; uno stop
//    prima dell'avvio e' dentro; margine nullo -> mai dentro.
// La differenza dei battiti si prende con `beatDelta(startPhase:stopPhase:modulus:)`, che gira
// a giro in modo SIMMETRICO: `phaseAtStampQBig` rende `1e6 + battito` per i battiti negativi,
// e l'ora del Play puo' cadere prima del battito 0 (la richiesta di battito 0 con un peer va
// alla prossima corrispondenza di fase); una differenza riportata in [0, 1e6) leggerebbe uno
// stop un millesimo PRIMA dell'avvio come «lontanissimo» e chiuderebbe la canzone (Q19).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum FalseStartDecision {

    /// `[startBeat, startBeat + marginBeats)`: dentro, fuori al bordo, dentro prima dell'avvio;
    /// con `marginBeats <= 0` sempre fuori.
    static func isFalseStart(stopBeat: Double, startBeat: Double, marginBeats: Double) -> Bool {
        guard marginBeats > 0 else { return false }
        return stopBeat - startBeat < marginBeats
    }

    /// Una battuta: i battiti per battuta della PRIMA sezione della canzone in corso.
    static func marginBeats(beatsPerBar: UInt32) -> Double {
        Double(beatsPerBar)
    }

    /// `stopPhase − startPhase` riportata nell'intervallo `(−modulus/2, +modulus/2]`: il giro
    /// dello zero e' simmetrico, uno stop letto un attimo prima dell'avvio resta un numero
    /// piccolo e negativo. Con `modulus <= 0` (o non finito) rende la differenza semplice, senza
    /// riporto.
    static func beatDelta(startPhase: Double, stopPhase: Double, modulus: Double) -> Double {
        let raw = stopPhase - startPhase
        guard modulus > 0, modulus.isFinite else { return raw }
        var delta = raw.truncatingRemainder(dividingBy: modulus)
        let half = modulus / 2
        if delta > half {
            delta -= modulus
        } else if delta <= -half {
            delta += modulus
        }
        return delta
    }
}
