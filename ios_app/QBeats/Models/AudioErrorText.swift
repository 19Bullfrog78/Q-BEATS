import Foundation

// === A416 (21/10/2026) — USCITA AUDIO, PASSO 1: L'ERRORE DELLA SESSIONE AUDIO NEL REGISTRO ===
// Il fatto (referto A415, §5.6). Il ramo `catch` della `setActive` in `AudioEngine.activateSessionAndStart` scriveva
// «retry attempt n/20» e, all'ultimo, «setActive esaurito», ma non l'errore; il `catch` di `setupSession` scriveva solo
// lo stato a schermo. Il 19/10 (voce 3 del messaggio di `1314127e`) sette tentativi in sfondo sono falliti senza dire
// perché: forse `cannotInterruptOthers` (una sessione non mescolabile non si attiva in sfondo), ma il registro non lo
// prova.
// La forma (mandato del referee «USCITA-AUDIO-PASSO-1», §2.4): dominio e codice dell'errore (`NSError`), col codice
// di quattro lettere accanto (`560557684` = `!int`). Le quattro lettere esistono solo se i quattro byte del codice, letto
// come intero a 32 bit, sono caratteri stampabili; altrimenti «-». Gli spazi diventano «_», perché nelle righe un
// valore non ha spazi.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum AudioErrorText {

    /// Il codice di quattro lettere, o «-».
    static func fourCharCode(_ code: Int) -> String {
        let value = UInt32(truncatingIfNeeded: code)
        let bytes: [UInt8] = [UInt8((value >> 24) & 0xFF), UInt8((value >> 16) & 0xFF),
                              UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
        // Solo un codice che entra in 32 bit ha le sue quattro lettere (un numero più grande non è un codice di quattro
        // lettere: i suoi byte bassi da soli direbbero un'altra cosa).
        guard Int64(code) >= Int64(Int32.min), Int64(code) <= Int64(UInt32.max),
              bytes.allSatisfy({ $0 >= 0x20 && $0 <= 0x7E }) else { return "-" }
        return String(decoding: bytes, as: UTF8.self).replacingOccurrences(of: " ", with: "_")
    }

    /// La parte della riga: `<dominio> codice:<n> quattroLettere:<xxxx>`.
    static func line(domain: String, code: Int) -> String {
        let cleanDomain = domain.isEmpty ? "-" : domain.replacingOccurrences(of: " ", with: "_")
        return "\(cleanDomain) codice:\(code) quattroLettere:\(fourCharCode(code))"
    }
}
