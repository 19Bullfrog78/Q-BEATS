# CONGEDO CC — sessione del 26/08/2026, notte

Da: CC · A: **la chat CC che apre dopo di me**, + Mauro + CD + referee

⛔ **Scritto senza leggere il congedo di CD**, che esiste ed e' su Drive. Se
convergiamo, la convergenza vale perche' e' indipendente. Se divergiamo,
misurate la divergenza invece di appianarla.

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato da altri, non
rimisurato · **[A]** giudizio mio. ⛔ Mai mescolati in una frase.

⚠️ **La prima cosa che ti dico e' di non credermi: marca questo file [R] e
rimisura.** Oggi ho sbagliato quattro volte, e due di quelle volte l'errore e'
arrivato a un passo dal codice o dentro un documento di CD.

⚠️ **TUTTE LE MISURE DI QUESTO FILE SONO STATE SCATTATE PRIMA DI DEPOSITARLO.**

---

## 0 · ID A226 — misurato, non scelto

**[M]** Sonda su due supporti (NOME e CONTENUTO), su entrambe le gambe, con
`-- ':!DESIGN'` sulla gamba CONTENUTO-git.

| ID | NOME git / hoffC / hoffE | CONT git / hoffC / hoffE |
|---|---|---|
| **A226** (preso) | 0 / 0 / 0 | 0 / 0 / 0 |
| A225 (positivo) | 1 / 1 / 1 | 1 / 1 / 1 |
| A222 (positivo) | 1 / 1 / 1 | 2 / 2 / 2 |
| A211 (positivo storico) | 2 / 2 / 2 | 7 / 12 / 12 |

✅ **[M] Tre positivi, tutti non-zero su tutte e sei le colonne: la sonda vede.**

---

## 1 · I MIEI ERRORI — quattro, e le prime due sono la stessa malattia

### 1.1 — 🚨 IL PIU' GRAVE: ho spacciato una deduzione per una misura, ed e' arrivata a un passo dal codice

**[M]** Ho scritto che `SettingsView.swift:27`, `Picker("Mode", ...)`, sceglie il
**modo del metronomo**. **Falso.** Quel Picker sta dentro
`SwiftUI.Section("Ableton Link")` e lega `appSettings.linkMode`, con i tag
`Text("Director")` e `Text("Follower")`: e' il **ruolo Link**.

⛔ **Come l'ho sbagliata, che e' la parte che serve.** La mia sonda ha reso la
sola stringa `Picker("Mode", selection: Binding(`. **Non ho mai letto a cosa
fosse legata.** Ho visto un Picker chiamato «Mode», ho visto nel modello un tipo
chiamato `MetronomeMode`, e ho unito i due. Poi ho marcato **[M]** il risultato.
Era **una inferenza travestita da misura**.

⚠️ **[M] E ha viaggiato:** l'ho scritta io, CD l'ha adottata e dichiarata
«corroborata» su BOX5 `:559` — riga che dice *«Picker modalita' in
SettingsView»* e **non dice mai metronomo** — Mauro ha ratificato la decisione
11-bis, e mancava una parola perche' entrasse in app come etichetta falsa.
**L'ha fermata il referee.**

✅ **[M] Cio' che regge:** la collisione esiste davvero, «Mode» e' sullo schermo
di Impostazioni e significa un'altra cosa. Sbagliato era **quale**. La 11-bis e'
stata corretta in `Role`, non ritirata.

### 1.2 — La stessa malattia, poche ore dopo, ed e' finita nel documento corrente di CD

**[M]** Ho detto a CD che per la barra delle stanze centrata restava un residuo
lato codice, perche' la variante `.segMini` di `RoomSwitchBar` rende il solo
segmento senza contenitore che centra.

⛔ **Vero sul componente, falso sul prodotto.** `QLiveShowDetailView.navbar`
monta quel segmento dentro uno `ZStack` con `.frame(maxWidth: .infinity)` e
`.frame(height: 54)`: **lo ZStack centra.** Ed e' li' dal **21/08**, commit
`baaa172`, il cui messaggio dice testualmente «selettore centrato».

⇒ **[A] Decisione 18 lato codice: gia' fatta, non aperta.** E la mia riga e'
entrata nell'aperto 5 del documento corrente di CD.
⇒ **[A] Lezione, ed e' la stessa della 1.1:**
**ho misurato il componente e dedotto il montaggio.** Un componente non centra
da solo — lo centra chi lo monta. La sonda va portata **al sito di chiamata**.

### 1.3 — «sette campi» che erano sei

**[M]** Ho scritto che `Song` ha sette campi, e ne ho elencati sei. Il settimo
che avevo contato e' `estimatedDurationSeconds`, che e' **calcolato**: la mia
sonda contava `var ` e non distingue.

⇒ **[A] Misura giusta, didascalia sbagliata** — la stessa classe che avevo
diagnosticato nel mio congedo del mattino, capitata a me **tre volte in una
giornata**. ✅ La conclusione non cambia: nessuno dei sei e' un flag standby
per-canzone, e QL-SHOWS-07 resta ratificato ma non costruito.

### 1.4 — Ho corretto in prosa e non ho riemesso la lista

**[M]** Corretta la 1.1 in chat e nel documento, **la mia coda operativa e'
rimasta con dentro la versione falsa** del rename. Chi avesse lavorato dalla
tabella avrebbe applicato la riga sbagliata.

⇒ **[A] Non e' rientrata: non e' mai uscita.** La correzione viveva in prosa e
la lista da cui si lavora era un'altra. ⛔ **Una svista sopravvive quando ci sono
due liste che non sono la stessa lista.** L'ha vista CD, non io.

---

## 2 · COSA HO FATTO — [M]

**[M] Zero commit in tutta la sessione.** HEAD e' rimasto
`3808bdbdf07a76adcc20918b13865a7d7b2503da` dall'inizio alla fine, working tree
con 0 tracciati modificati e 0 in stage.

Il prodotto della sessione e' **misura e documenti in chat**: il verdetto
tecnico che ha sbloccato CD, le risposte alle sue tre domande, un prompt per CD
sulla schermata d'attesa, e le rimisure che hanno corretto tre affermazioni —
due sue e una mia.

⚠️ **[M] Quattro documenti di CD sono nati oggi e vivono SOLO su Drive.** Due non
mi sono mai arrivati in chat: li ho trovati andandoli a cercare. **Il deposito su
Drive non avvisa nessuno**, e nessuno di quei quattro e' su una gamba vera.

---

## 3 · LO STATO — tutto [M], misurato PRIMA di depositare questo file

    HEAD locale = HEAD remoto = 3808bdbdf07a76adcc20918b13865a7d7b2503da
    0 tracciati modificati · 0 in stage · 1075 non tracciati
    HANDOFF: 331 file · 50 tracciati · 281 no

⚠️ **[M] I 1075 diventano 1076 al deposito di questo file, e 1075 di nuovo al
suo commit.** Lo dichiaro invece di lasciarlo scoprire.

**[M] I cinque canonici, uno per uno alla fonte:**
BOX3 **V100** · BOX5 **V34** · BUGS **63** · LIBRO **64** · SCALETTA **15**.
⚠️ La SCALETTA non e' in radice: `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`, e la
data nel nome e' piu' vecchia del contenuto. **Si cerca per contenuto.**

**[M] La CI, per ENUMERAZIONE:**

| workflow | totale | enumerazione | su HEAD |
|---|---|---|---|
| iOS Signed Build | 648 | **584** success · 63 failure · 1 cancelled | ✅ **success** |
| F1 — Build Check | 4 | **1** success · 3 failure | non partito |

✅ **[M] 584 + 63 + 1 = 648: la somma quadra col totale.** E' la sola verifica
che smaschera il difetto in cui il totale sembra una parte.

⛔ **[M] E su F1 la mia prima sonda ha reso ZERO, che era falso.** Filtrando per
nome esatto, il trattino lungo non aggancia. Ripetuta per sottostringa: 4 run.
**Un altro zero che non era una misura, preso solo perche' l'ho rifatto in una
seconda forma.**

**[M] Ultimo commit con righe .swift NON di commento: `baaa172`, 21/08.** Il
successivo, `d6e2415` del 23/08, dichiara «zero logica» e **il diff lo dimostra**:
43 righe cambiate, zero fuori dai commenti.

---

## 4 · IL VERDETTO TECNICO — cosa ho misurato, ed e' la sostanza della giornata

**[M] 1. La freccia del player NON spegne il motore.** `QLiveRootView.swift:178`
e' `LiveView(onExit: { navigate(to: .shows) })`: navigazione interna, non tocca
`screen`, non innesca lo stop di `AppRootView`. `.onDisappear{stop()}` non
esiste in tutto il progetto. **Il timore di CD costava zero.**

**[M] 2. Ma `LiveSession` e' del player e muore con lui.** `LiveView.swift:11`,
`@StateObject private var session = LiveSession()`. Il runner la tiene **debole**
(`SetlistRunner.swift:321-322`, `[weak session]` + `guard ... else { return }`).
⇒ Smontato il player, a fine sezione la closure trova `session == nil` e ritorna:
non avanza, non pre-carica, non entra in standby.

🚨 **[A] L'audio non continua a suonare lo show: il click batte e non segue.**
Peggio di uno stop. **E oggi il guasto non fa rumore**: il `guard` esce PRIMA
dell'`os_log` della riga dopo, quindi non si logga niente.

**[M] 3. `.stopped` non distingue «sessione mai aperta» da «sessione chiusa».**
E' il default di `LiveSession.swift:35` e insieme lo stato dopo lo stop; e ha
**tre scrittori dentro AudioEngine**. `.overlayStop` invece e' lo specchio di
`.pausedAwaitingChoice` del motore, e `OverlayStopView` offre «Riprendi da
sezione» / «Dall'inizio»: li' la sessione e' **viva**.
⇒ **[A] Il criterio giusto di CD — «c'e' una sessione aperta?» — oggi non e'
leggibile da nessuna parte:** ne' da `playbackState`, ne' da
`roomSession.runner`, che dopo il primo Start non si svuota mai.

**[M] 4. Il salto:** `currentSongIdx` e' `@Published private(set)`, scritture
solo `= 0` e `+= 1` ⇒ serve un mutatore nuovo, **una porta sola**. Il taglio
netto e' gia' la forma che il motore richiede. Nessuna scrittura su disco.
**[M] 5. La base:** zero occorrenze di backtrack in `SetlistRunner` ⇒ non si
ferma con la canzone e il salto non la sfiora.

---

## 5 · LA CODA — cinque lavori pronti, NESSUNO partito

⛔ Tutti fermi al cancello: propongo, mostro il diff, aspetto.

| # | lavoro | dove |
|---|---|---|
| 1 | riga `os_log(.error)` sul ramo muto | `SetlistRunner.swift:322` |
| 2 | ticket BUGS: la base non si ferma col salto | doc-only |
| 3 | `Picker("Mode")` → **`Picker("Role")`** | `SettingsView.swift:27` |
| 4 | marcatura riga 40 del congedo A225 (dice «sette», sono otto) | `HANDOFF/` |
| 5 | ticket BUGS: il velo dell'attesa copre freccia e console | doc-only |

⛔ **Sulla 3, il cartello che va nel ticket:** `"Show Airplane Mode / Do Not
Disturb reminder"` a `SettingsView.swift:55` **NON si tocca** — «Mode» li' e' il
nome iOS della funzione di sistema. Senza quella riga il prossimo finisce il
lavoro e rinomina un termine Apple.

🔴 **E fuori dalla coda, la cosa che tiene fermo tutto: la proprieta' di
`LiveSession` deve salire alla stanza**, come gia' fatto per il runner. Il
referee ha detto che e' il primo cancello di un atomo gia' istituito. **Finche'
non e' assegnata, CD non disegna** — e ha ragione.

---

## 6 · [A] COSA DEVE SAPERE CHI APRE DOMANI

⛔ **Misurare il componente non e' misurare il prodotto.** Due volte oggi ho
letto un file e dedotto cosa facesse una volta montato. Il Picker e il selettore
centrato sono la stessa identica malattia. **La sonda va portata al sito di
chiamata, sempre.**

⛔ **Una riga compatibile con la tesi non e' una riga che la dimostra.** E' la
regola che CD si e' data dopo la 11-bis, ed e' la migliore uscita dalla
giornata. Vale per me nella stessa misura.

⛔ **Uno zero non e' una misura finche' non lo hai rifatto in una seconda forma.**
Oggi mi ha morso su F1, e stamattina su un'altra sonda. Il controllo positivo va
sempre a fianco.

⛔ **Correggere in prosa non corregge la lista.** Se hai emesso una tabella
operativa e poi correggi in chat, **riemetti la tabella**: nessuno lavora dalla
prosa.

⛔ **I documenti di CD non arrivano.** Vivono su Drive e Drive non notifica.
Chiedi il link, e chiedi che vengano depositati su una gamba vera:
**chi apre domani non ha questa chat**.

---

## 7 · [A] CIO' CHE LASCIO

Il modello di sessione e' chiuso lato disegno, e il codice ha **una sola** cosa
che lo blocca. Non e' un lavoro grande: e' un lavoro **non assegnato**.

⛔ **Non credere a questo file. Marcalo [R] e rimisura**, cominciando dal §4:
sono le mie misure di oggi, e oggi ho visto misure di ieri scadere in due ore.

---

### Controllo d'integrita' di QUESTO file — sul CONTENUTO

⚠️ Stringhe **copiate** da una riga sola, senza accenti ne' apostrofi, e
**contate sul testo APPIATTITO** — non riga per riga. Attese **2** occorrenze
ciascuna, corpo + questa lista. Il marcatore di fine: **1**, in ultima riga.

`una inferenza travestita da misura` ·
`ho misurato il componente e dedotto il montaggio` ·
`il click batte e non segue` ·
`oggi il guasto non fa rumore` ·
`sessione mai aperta` ·
`due liste che non sono la stessa lista` ·
`la somma quadra col totale` ·
`Zero commit in tutta la sessione` ·
`chi apre domani non ha questa chat` ·
e il marcatore di fine qui sotto.

🚨 **[M] Questa lista e' stata contata A FILE FINITO, non prima.** Se un numero
non torna, e' questo file a essere rotto, non la lista.

---

*A226-CONGEDO-CC-2026-08-26-NOTTE-FINE*
