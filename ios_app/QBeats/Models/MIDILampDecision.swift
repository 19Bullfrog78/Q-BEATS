import Foundation

// === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — IL LAMPO DEL PEDALE: «QUESTA AZIONE AGISCE?» ===
// Punto 98 del foglio Solo REV17 (deciso): la spia MIDI «lampeggia solo quando il pedale fa fare
// davvero qualcosa all'app». La regola dice, per ogni azione del MIDI Learn, se oggi agisce
// (A393 §6.4, misure su `AudioEngine.executeMIDIAction` e sulle funzioni che chiama):
//  · `.playPause`: agisce sempre (ferma se suona, altrimenti avvia);
//  · `.stop`: `handleStop` agisce solo se il trasporto è in moto (suona o conta); da fermo niente;
//  · `.muteClickToggle`: agisce sempre, su tutti e tre i ruoli;
//  · `.stopBacktrack`: ferma la base solo se la base suona;
//  · `.tapTempo`: agisce sempre (ogni tocco entra nella misura del tempo);
//  · i cinque comandi muti (`.nextSection`, `.prevSection`, `.nextSong`, `.startSong`,
//    `.loopToggle`): scrivono solo una riga di log, «richiede Layer 3» — mai.
// Sul Follower passa solo il muto (A360/A361): per tutto il resto il pedale è ignorato, e il lampo
// con lui. Il filtro dei byte (Clock, Active Sensing, Note Off, i tipi ignorati) sta prima, nel
// richiamo di CoreMIDI e in `handleMIDIInput`, e non si sposta: qui arrivano solo le azioni
// riconosciute dal MIDI Learn.
// Il lampo è un segnale (`AudioEngine.midiActionLampSubject`) mandato sul main dentro
// `executeMIDIAction`, dopo il passaggio al main che c'è già: niente di nuovo sul thread di
// CoreMIDI né su audioQueue.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum MIDILampDecision {

    /// I cinque comandi che oggi non fanno niente nel player.
    static let silentActions: [MIDIAction] = [.nextSection, .prevSection, .nextSong, .startSong, .loopToggle]

    /// `transportInMotion`: il motore suona o conta (`AudioEngine.playbackState` `.playing` o
    /// `.countIn`), cioè la condizione sotto cui `handleStop` agisce.
    /// `backtrackPlaying`: la base sta suonando. Nel player la base non parte (A387 §2.2); decisione
    /// di Mauro del 05/10/2026: finché la base non arriva nel player, Stop Backtrack non lampeggia.
    static func fires(action: MIDIAction,
                      role: PlayerRole,
                      transportInMotion: Bool,
                      backtrackPlaying: Bool) -> Bool {
        if role == .follower {
            return action == .muteClickToggle
        }
        switch action {
        case .playPause:
            return true
        case .stop:
            return transportInMotion
        case .muteClickToggle:
            return true
        case .stopBacktrack:
            return backtrackPlaying
        case .tapTempo:
            return true
        case .nextSection, .prevSection, .nextSong, .startSong, .loopToggle:
            return false
        }
    }
}
