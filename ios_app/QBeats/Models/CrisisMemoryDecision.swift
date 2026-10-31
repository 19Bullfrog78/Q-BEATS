import Foundation

// === A421 · SEGUITO 3 (31/10/2026) — LA MEMORIA DELLA CRISI DEL SOLO: UNA CRISI CHE NON TROVA NIENTE DA FERMARE NON LA TOCCA ===
// Il fatto (mandato del referee «A421 · SEGUITO 3», par. 2.1). `crisisOutcomeQ` riscriveva la causa ricordata e azzerava «Stop
// voluto dopo la crisi» a ogni esito diverso da «niente». Per il Solo con una causa che non lo ferma (configurazione, modo,
// «uscita-aggiunta», «buco-del-render») `CrisisStopDecision.outcome` dà «come oggi» anche a motore fermo: la memoria si riscriveva
// anche quando non c'era niente da fermare. Il ramo del modo di `handleRouteChange` chiama la regola prima di `guard wasRunning`,
// e ci si arriva a motore fermo con un cambio di percorso che cambia il modo Base/Pro senza cambiare la frequenza (una scheda USB
// multicanale alla stessa frequenza). Tre sequenze:
//  (a) il Solo fermo con lo Stop della console («Resume from»), il cambio di modo, un inizio d'interruzione: lo Stop voluto
//      tornava falso, m4 (`InterruptionActivationDecision.soloAtInterruptionBegin`) vedeva «ripartenza in corso» e il Solo si
//      fermava una seconda volta: «Resume from» tornava a «fermo»;
//  (b) il Solo mai partito (nessuna causa, nessuno Stop voluto), il cambio di modo, un inizio d'interruzione: la causa diventava
//      «modo» e il Solo, già «fermo», si fermava come allo Stop della console senza essere mai partito, con una riga di Stop falsa;
//  (c) il Solo con una catena di ripartenza in volo (una crisi che non lo ferma col motore in moto, la `setActive` che fallisce, i
//      tentativi ogni 0,5 s), fermato dall'utente con lo Stop della console (lo Stop voluto alzato, la catena non chiusa fuori da
//      un'interruzione), poi il cambio di modo a motore fermo: lo Stop voluto tornava falso e il tentativo dopo passava
//      (`RecoveryDecision.route`: «avvio-come-oggi»): il Solo fermato dall'utente ripartiva da solo.
// La regola (par. 2.2): per il Solo col motore fermo (`isRunning` falso: lo stato dell'app, non l'AVAudioEngine) e una causa che non
// lo ferma (`stopsSolo` falso), la causa ricordata e lo Stop voluto non si toccano; l'esito e la riga [CRISI] decisione restano
// quelli di oggi, più una riga. Tutto il resto come oggi: gli altri ruoli; il Solo col motore in moto; le cause che fermano il Solo
// (a motore fermo l'esito è già «niente», che non toccava la memoria). `CrisisStopDecision` (outcome, rememberedCause, stopsSolo),
// `RecoveryDecision` e `InterruptionActivationDecision` non cambiano: m4 riceve gli ingressi giusti.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Che cosa fa una crisi della memoria delle ripartenze (`_crisisCauseQ`, `_wantedStopSinceCrisisQ`).
enum CrisisMemoryStep: String, Equatable, CaseIterable {
    /// Come oggi: la causa ricordata (`CrisisStopDecision.rememberedCause`) e «Stop voluto dopo la crisi» a falso.
    case rewrite = "riscrive"
    /// Il Solo a motore fermo con una causa che non lo ferma: la causa ricordata e lo Stop voluto invariati, con la riga.
    case keep = "invariati"
    /// L'esito «niente»: la memoria non si tocca, come oggi (nessuna riga in più).
    case nothing = "niente"
}

enum CrisisMemoryDecision {

    /// La regola. `outcome` è l'esito di `CrisisStopDecision.outcome` per la stessa crisi; `engineRunning` è `isRunning`.
    static func step(playerRole: PlayerRole,
                     cause: CrisisCause,
                     engineRunning: Bool,
                     outcome: CrisisStopOutcome) -> CrisisMemoryStep {
        guard outcome != .nothing else { return .nothing }
        if playerRole == .solo, !engineRunning, !cause.stopsSolo {
            return .keep
        }
        return .rewrite
    }

    /// La causa ricordata e lo Stop voluto dopo il passo: invariati con `keep` e `nothing`, come oggi con `rewrite`.
    static func memoryAfter(step: CrisisMemoryStep,
                            previousCause: CrisisCause?,
                            wantedStopSinceCrisis: Bool,
                            cause: CrisisCause,
                            playerRole: PlayerRole) -> (cause: CrisisCause?, wantedStopSinceCrisis: Bool) {
        switch step {
        case .rewrite:
            return (CrisisStopDecision.rememberedCause(previous: previousCause, new: cause, playerRole: playerRole), false)
        case .keep, .nothing:
            return (previousCause, wantedStopSinceCrisis)
        }
    }
}
