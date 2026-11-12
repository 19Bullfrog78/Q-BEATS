import Foundation

// === A432, parte 2b (12/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3c-1: L'«UNO» DEL RITORNO DEL FOLLOWER DAL CONTO ===
// Il fatto (referto A423, Aperto A.4 i; referto A424 par. 3.3 b, «L'"uno" del ritorno del Follower», e Aperto A.14).
// Dopo un buco il volume del Follower torna sul primo «uno» di battuta dopo le due ore del ritorno. Fino a qui l'«uno»
// era la fase 0 della battuta di Link col quanto della sezione del motore (`OutputReturnDecision.nextBarBeat`): dopo un
// cambio di metro quella battuta può non essere un «uno» della canzone (4/4 per 8 battiti e poi 3/4: gli «uno» della
// canzone sono 8, 11, 14…; le battute di Link col quanto 3 cadono su 9, 12, 15…).
// La regola: col conto certo (`FollowerBandCount` aperto, con l'àncora) l'«uno» è il prossimo inizio di battuta DELLA
// CANZONE, cercato sulla mappa dal posto della band (`ShowClock.downbeat`), e si porta come battito della sessione nella
// numerazione del conto (l'orologio `.band`), coi battiti per battuta della sezione in cui cade. Senza conto, o col conto
// non certo, o se la canzone finisce prima: questo tipo rende `nil` e il motore fa come prima (l'«uno» di Link o della
// linea propria).
// DA-SOLO (referto A424 par. 3.3 b, «DA-SOLO»): un righello solo, i secondi sulla mappa. Il posto alla scadenza viene
// dall'ora (`next(count:atOrAfterTicks:)`), e l'ora dell'«uno» è quella della mappa portata sulla linea propria: il
// battito intero della linea propria più vicino, contato dall'ultimo «uno» uscito (`ownBeat`).
// Solo la regola: valori in ingresso, valori in uscita; non chiama Link né il motore. Legge il conto e non lo cambia.
// Solo Foundation e i tipi di Models/: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

enum FollowerBandUno {

    /// Il conto dà un «uno»: aperto e con l'àncora.
    static func isCertain(_ count: FollowerBandCount?) -> Bool {
        guard let count = count else { return false }
        return count.closed == nil && count.anchor != nil
    }

    /// Il primo inizio di battuta della canzone non prima del battito della sessione `linkBeat` (nella numerazione del
    /// conto), come «uno» del ritorno: il suo battito della sessione, l'orologio `.band` e i battiti per battuta della
    /// sezione in cui cade. `nil` se il conto è chiuso o senza àncora, se il battito cade prima della sezione
    /// dell'àncora o in un ciclo, o se la canzone finisce prima del prossimo inizio di battuta.
    static func next(count: FollowerBandCount, atOrAfterLinkBeat linkBeat: Double) -> FollowerReturnUno? {
        guard count.closed == nil, let anchor = count.anchor, linkBeat.isFinite else { return nil }
        let clock = ShowClock(map: count.map, anchor: anchor)
        guard case .found(let downbeat) = clock.downbeat(atOrAfterLinkBeat: linkBeat) else { return nil }
        let beatsPerBar = count.map.sections[downbeat.section].beatsPerBar
        guard beatsPerBar > 0, downbeat.linkBeat.isFinite else { return nil }
        return FollowerReturnUno(beat: downbeat.linkBeat, clock: .band, beatsPerBar: beatsPerBar)
    }

    /// DA-SOLO: lo stesso, dal posto che il righello dei secondi dà all'ora `ticks`.
    static func next(count: FollowerBandCount, atOrAfterTicks ticks: UInt64, ticksPerSecond: Double) -> FollowerReturnUno? {
        guard count.closed == nil, let anchor = count.anchor else { return nil }
        let ruler = ShowClock(map: count.map, anchor: anchor).bySeconds(nowTicks: ticks, ticksPerSecond: ticksPerSecond)
        guard ruler.place.isLocated else { return nil }
        return next(count: count, atOrAfterLinkBeat: anchor.linkBeat + ruler.beatsFromAnchor)
    }

    /// L'«uno» della battuta dopo `uno` (orologio `.band`): il primo inizio di battuta della canzone dopo di lui. Non è
    /// «il battito più una battuta»: al confine di sezione la battuta dopo può avere un altro metro.
    static func nextBar(count: FollowerBandCount, after uno: FollowerReturnUno) -> FollowerReturnUno? {
        guard uno.clock == .band, uno.beat.isFinite else { return nil }
        return next(count: count, atOrAfterLinkBeat: uno.beat + 0.5)
    }

    /// A ogni rilettura: l'«uno» salvato è ancora un inizio di battuta della canzone per il conto di adesso, con gli
    /// stessi battiti per battuta. Falso se il conto si è chiuso, o se la sua àncora ha preso un salto (una
    /// rinumerazione riconosciuta) che non è di battute intere: il motore riarma con la stessa regola.
    static func confirms(count: FollowerBandCount?, uno: FollowerReturnUno) -> Bool {
        guard let count = count, uno.clock == .band, uno.beat.isFinite,
              let again = next(count: count, atOrAfterLinkBeat: uno.beat - 0.5) else { return false }
        return abs(again.beat - uno.beat) < 1e-6 && again.beatsPerBar == uno.beatsPerBar
    }

    /// DA-SOLO: l'ora dell'«uno» sulla mappa (il righello dei secondi dall'àncora). `nil` se il conto non la sa dire.
    static func mapTicks(count: FollowerBandCount, uno: FollowerReturnUno, ticksPerSecond: Double) -> UInt64? {
        guard count.closed == nil, let anchor = count.anchor, uno.clock == .band, uno.beat.isFinite else { return nil }
        let clock = ShowClock(map: count.map, anchor: anchor)
        guard case .found(let downbeat) = clock.downbeat(atOrAfterLinkBeat: uno.beat - 0.5) else { return nil }
        return clock.ticks(of: downbeat, ticksPerSecond: ticksPerSecond)
    }

    /// DA-SOLO: l'«uno» portato sulla linea propria. I click dell'iPad cadono sui battiti interi della linea propria
    /// contati dall'ultimo «uno» uscito: l'«uno» è quello più vicino all'ora della mappa.
    static func ownBeat(mapTicks: UInt64, timeline: OwnClockTimeline, lastUnoBeat: Double, ticksPerSecond: Double) -> Double? {
        guard lastUnoBeat.isFinite, ticksPerSecond > 0, ticksPerSecond.isFinite, timeline.bpm > 0, timeline.bpm.isFinite else {
            return nil
        }
        let atMap = timeline.beat(atTicks: mapTicks, ticksPerSecond: ticksPerSecond)
        guard atMap.isFinite else { return nil }
        return lastUnoBeat + (atMap - lastUnoBeat).rounded()
    }
}
