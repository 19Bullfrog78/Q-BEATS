# MISURE CC — A229: la freccia nascosta, la collisione END SHOW, e i sedici campi

Da: CC · A: CD (parte 1) + referee e chi costruirà la mossa (parte 2) + Mauro

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato da altri, non
rimisurato · **[A]** giudizio mio. Mai mescolati in una frase.

Origine: mandato A229 (referee). Misurato a **HEAD `8ab651a`**, albero pulito.

⚠️ **Gli indirizzi di questo referto sono per CONTENUTO, non per numero di
riga** — lezione di A228, dove i numeri di riga sono scaduti in dieci righe per
mano dello stesso mandato che li aveva misurati. Ogni riferimento qui si trova
cercando la stringa citata dentro il file nominato. **Chi legge non ha bisogno
del repo per capire, e non ha bisogno che le righe stiano ferme.**

---

## 0 · ID A229 — misurato, non scelto

**[M]** Sonda su due supporti (NOME e CONTENUTO), su entrambe le gambe, con
`-- ':!DESIGN'` sulla gamba CONTENUTO-git.

| ID | NOME git / hoffC / hoffE | CONT git / hoffC / hoffE |
|---|---|---|
| **A229** (preso) | 0 / 0 / 0 | 0 / 0 / 0 |
| A228 (positivo) | 1 / 1 / 1 | 3 / 1 / 1 |
| A226 (positivo) | 0 / 1 / 1 | 1 / 2 / 2 |
| A225 (positivo) | 1 / 1 / 1 | 2 / 3 / 3 |

✅ **[M] Tre positivi non-zero: la sonda vede.**

---

# PARTE 1 — PER CD

## 1 · In tre stati su quattro la freccia del player OGGI non si tocca

**[M]** La freccia indietro vive nell'intestazione del player
(`LiveHeaderView.swift`, il `Button` la cui azione è `onExit()`). Sopra di lei,
a seconda dello stato, si monta un pannello a schermo pieno.

| stato | la freccia si tocca? | cosa c'è sopra, e come si trova |
|---|---|---|
| **mai partito** (`.stopped`) | ✅ **sì — l'unico** | niente sopra |
| **fra due canzoni** (`.standby`) | ⛔ no | `StandbyOverlayView`, montato dove `LiveView.swift` scrive `case .standby(let nextSong)`. È radicato in un `GeometryReader` (occupa tutto lo spazio offerto) e riceve `.contentShape(Rectangle())` con `.onTapGesture` ⇒ **area sensibile = schermo intero** |
| **stop reversibile** (`.overlayStop`) | ⛔ no | `OverlayStopView`, il cui corpo si apre con `Color.black.opacity(0.65).ignoresSafeArea()` ⇒ fondo pieno sopra la freccia |
| **fine scaletta** (`.fineSetlist`) | ⛔ no | `FineSetlistView`, il cui corpo si apre con `Color(hex: "#0e0e10").ignoresSafeArea()` ⇒ fondo pieno. **E ha già un suo pulsante `BACK TO SHOWS`** ⇒ lì la freccia sarebbe anche ridondante |

**[M] Corroborazione indipendente:** il commento dell'autore in
`SetlistRunner.swift`, dentro `primeDisplay`, descrive il velo dello standby
come **«overlay + tap-ovunque»**. È il codice che dichiara sé stesso.

⚠️ **[M] Non è l'opacità a bloccare.** La pila sotto il velo viene portata al
10% di opacità, ma in SwiftUI l'opacità **non toglie il tocco**: nel corpo di
`LiveView` non c'è né `.disabled()` né `.allowsHitTesting(false)` su quella
pila. L'unico `.allowsHitTesting` del file governa **il mixer**, non il velo.

### ⇒ [A] Le due conseguenze per il disegno

1. **La destinazione della freccia non è una domanda urgente**, e non lo diventa
   finché i veli restano com'è. Diventa urgente **nell'istante** in cui si
   scopre un velo — cioè esattamente ciò che propone «standby vestito con la
   freccia scoperta».
2. **Oggi c'è UNA sola uscita, uguale in tutti gli stati: porta alle card.**
   Non è indecisa né differenziata: è una regola sola. ⛔ Quindi la domanda
   «in quali stati la freccia porta alle card» è capovolta — la domanda vera è
   **«in quali stati vogliamo ROMPERE la regola che già c'è»**, e chi risponde
   alla prima crede di scegliere un comportamento mentre autorizza una
   divisione.

### ⚠️ E «freccia scoperta» oggi non esiste da sola

**[M]** Freccia, **pulsante mute** e **gesto che apre il mixer** stanno tutti e
tre nella **stessa pila coperta**, e **nessuno dei tre ha un blocco proprio**.
Scoprirne uno li scopre tutti e tre. ⇒ **[A] È una decisione in più, non un
dettaglio di attuazione.**

*(Il transport invece resterebbe morto anche scoprendolo: cinque dei suoi sei
pulsanti portano un secondo lucchetto `disabled: … isStandby`, indipendente dal
velo, e il sesto — `emerg` — non ha azione. Misurato per esteso in A228.)*

---

## 2 · «END SHOW» è già occupato, dentro il player

**[M]** In `FineSetlistView.swift` la stringa `"END SHOW"` è **il titolo** della
schermata di fine scaletta — un `Text`, non un pulsante. I pulsanti di quella
schermata sono `"BACK TO SHOWS"` e `"RESTART SETLIST"`.

⇒ **[A] Mettere END SHOW sul dettaglio come AZIONE dà alle stesse due parole
due significati in due posti**: titolo-di-stato dentro il player, azione fuori.
È la stessa malattia che la domanda sul doppio STOP vuole curare, spostata di
un passo. **Non è fatale — il titolo si può rinominare — ma va deciso, non
ereditato.**

**[A] Delle quattro opzioni sul tavolo, «STOP CLICK / STOP SHOW» è l'unica che
non collide con una stringa oggi in uso.** Resta scelta di CD: qui misuro il
vincolo, non il gusto.

### ⚠️ E sulla stessa schermata c'è una decisione ratificata non eseguita

**[M]** Il pulsante `"RESTART SETLIST"` ha per azione un blocco **vuoto**. Il
commento immediatamente sopra la dichiarazione di `onBackToShows`, nello stesso
file, dichiara che la sua **rimozione è già decisa**: opzione Ⓐ di CD, con
ratifica tecnica del referee **e** OK di Mauro, riferita al LIBRO MASTRO e
datata 07/08. Il pulsante è ancora lì, inerte.

⇒ **[A] La domanda sul doppio STOP non andrebbe chiusa senza quella rimozione
sul tavolo**, perché cambia cosa *è* la schermata END SHOW.

---

# PARTE 2 — I SEDICI CAMPI

## 3 · Cosa sono, e perché sedici

**[M]** `LiveSession.swift` dichiara **16 proprietà memorizzate, tutte
`@Published`**: zero proprietà calcolate, zero proprietà non pubblicate. Il
numero è esatto, non stimato.

Oggi il player le riceve **pulite a ogni ingresso**, perché la sessione nasce
come `@StateObject` dentro `LiveView` e muore con lui. **Se la proprietà sale
alla stanza, questi sedici valori sopravvivono all'uscita e tornano indietro
al rientro.** Questo referto misura **cosa sopravvive e chi se ne accorge** —
niente altro.

⛔ **Non contiene nessuna proposta di politica di azzeramento.** Quella è
disegno, è di CD, e arriva dopo.

## 4 · Il quadro — quattro famiglie, e la somma torna

**[M] Chiave di lettura:** «rinfrescato all'armamento» = riscritto da
`primeDisplay` (che gira nell'`onAppear` del player) prima che un valore vecchio
possa contare. «Guidato dal motore» = riscritto solo quando l'audio pubblica o
batte: **fermo il motore, non si rinfresca**.

### Famiglia A — rinfrescati all'armamento (8) ⇒ un valore vecchio non sopravvive

`currentSongName` · `currentSectionName` · `nextSectionName` · `nextSongName` ·
`macroBarCurrent` · `macroBarTotal` · `currentBPM` · `totalBarsInSection`

**[M]** Tutti e otto sono riscritti da `primeDisplay` — i primi sei tramite
`updateSessionDisplay`, gli ultimi due direttamente. **Lettori al montaggio:**
l'intestazione (nome canzone, BPM), la capsula del teleprompter (nome sezione,
BPM), il contatore battute, la macrobarra, il POI.

⚠️ **[M] Con UNA eccezione che li riguarda tutti e otto:** `primeDisplay` si
apre con `guard let section = currentSection else { return }`. **Se quella
guardia scatta — scaletta vuota o indice fuori intervallo — non rinfresca
NIENTE, e tutti e otto restano al valore vecchio.**

### Famiglia B — lo stato del player (1) ⇒ il più pericoloso

`playbackState`

**[M]** `primeDisplay` lo riscrive **solo se vale `.stopped`**: la riga è
`if case .stopped = session.playbackState, let song = currentSong`. È una
**lista di permessi con un solo membro** — e il commento immediatamente sopra
spiega che è voluto così, perché un divieto scritto al contrario
calpesterebbe gli altri sette stati.

⇒ 🚨 **[A] Se la sessione sopravvive in `.playing`, `.countIn`, `.overlayStop`
o `.waitingForDirector`, l'armamento non scatta: il velo dello standby non
compare e il player si monta mostrando uno stato che non corrisponde
all'audio.** È il campo con più lettori al montaggio di tutti — decide quale
pannello si monta, se il transport è spento, e cosa mostra il teleprompter.

### Famiglia C — guidati dal motore (4) ⇒ sopravvivono visibili finché l'audio tace

| campo | chi lo riscrive | chi lo legge al montaggio |
|---|---|---|
| `currentBar` | il gestore del tick audio | contatore battute, barra micro-segmento |
| `beatActive` | il gestore del tick audio (e alcuni azzeramenti a mano) | striscia degli slot metronomo |
| `currentTimeSig` | i gestori di «battute per misura» e del tick | intestazione |
| `isProMode` | il gestore di «modalità audio» | mixer (abilita CH3 e CH4) |

⇒ **[A] Sono quelli del «display stantio»:** a motore fermo nessuno li
riscrive, quindi al rientro mostrerebbero i valori dell'uscita — battuta
vecchia, LED acceso su un beat che non sta suonando — **finché non riparte
l'audio**, che li corregge al primo tick.

### Famiglia D — né armamento né motore (3)

| campo | misura | lettore al montaggio |
|---|---|---|
| `showMixer` | scritto **solo da gesti** dell'utente (trascinamenti e tocchi) | sì — `LiveView` e il transport |
| `isBacktrackLocked` | 🚨 **[M] ZERO scritture in tutto il progetto** | sì — l'intestazione, che ne fa un `if` |
| `accentPattern` | 🚨 **[M] ZERO scritture e ZERO letture** | **nessuno** |

⇒ **[M] `showMixer`: esci col mixer aperto, rientri col mixer aperto.** È il
caso più semplice da vedere e da riprodurre.

⇒ 🚨 **[M] `isBacktrackLocked` non viene scritto da nessuna parte**, quindi vale
`false` per sempre, e il ramo dell'intestazione che dipende da lui **non può
mai essere preso**. Sopravviverebbe come `false`, cioè in modo innocuo — ma
**[A] il reperto vero non è il rientro: è che una porzione di interfaccia è
irraggiungibile oggi.** ⛔ **Non ho verificato se questo contraddica una
decisione ratificata: non l'ho cercato, ed è una cosa che qualcuno deve
guardare.** Vedi §6.

⇒ 🚨 **[M] `accentPattern` di `LiveSession` è morto:** nessuno lo scrive,
nessuno lo legge. La striscia del metronomo usa uno **stato locale di
`LiveView`**, riempito dalla sezione corrente del runner. Il nome compare 56
volte nel progetto, ma sono altre proprietà omonime (quella di `SongSection`).
⇒ **[A] Un campo che nessuno legge non è un problema al rientro. È informazione
utile: è l'unico dei sedici che si può ignorare.**

### ✅ [M] La quadratura: 8 + 1 + 4 + 3 = 16

**È la sola verifica che smaschera il difetto in cui una parte sembra il
tutto.** Nessun campo è in due famiglie, nessuno è fuori.

## 5 · ⚠️ Un ordine che conta, e non l'ho provato

**[A]** SwiftUI disegna il corpo di una vista **prima** di eseguire il suo
`onAppear`. Se è così anche qui, allora **esiste un disegno in cui i valori
vecchi sono già a schermo e `primeDisplay` non è ancora girato** — anche per
gli otto della famiglia A, che pure verrebbero corretti subito dopo.

⛔ **Non l'ho misurato: è comportamento del framework, non una riga di questo
progetto, e non l'ho osservato su un device.** Lo scrivo perché chi progetta la
politica di azzeramento deve sapere che potrebbe non bastare rinfrescare
nell'`onAppear`. **Va provato, non dedotto.**

---

## 6 · IL LIMITE DI QUESTA MISURA — parte della misura, non nota a piè

**[M]** Tutto quanto sopra è letto dalla **struttura del codice** a
`HEAD 8ab651a`: dichiarazioni, chi scrive, chi legge, dove si monta un
pannello. **Non è stato osservato su un device.** Nessuno ha rientrato nel
player con un cronometro in mano.

**La prova definitiva è un collaudo, e non è stato fatto.**

⛔ **E tre cose che questo referto NON ha guardato, dichiarate perché non
vengano scambiate per assenti:**
1. se `isBacktrackLocked` senza scrittori **contraddica una decisione
   ratificata** — non l'ho cercato nei canonici;
2. se `RESTART SETLIST` ancora presente **abbia già un ticket aperto** — non
   l'ho cercato nel tracker;
3. l'ordine disegno/`onAppear` del §5, che è del framework e va provato.

## 7 · ⚠️ UN DIFETTO DELLA MIA SONDA, dichiarato

**[M]** Il mio primo passaggio sui campi «senza scrittori» ha reso **zero** per
`isProMode`. **Era falso.** La scrittura esiste, dentro il gestore di
«modalità audio», e la mia sonda l'ha persa perché filtravo via le righe
contenenti `==` per escludere i confronti — e quella riga assegna il risultato
di un confronto.

⇒ **[M] Rifatta senza quel filtro, `isProMode` ha il suo scrittore**, e le
uniche due caselle davvero vuote sono `isBacktrackLocked` e `accentPattern`,
confermate in **seconda forma** con controllo positivo.

⛔ **[A] La lezione, ed è la stessa di ieri con un vestito nuovo: un filtro
messo per togliere rumore può togliere il segnale.** Uno zero da una sonda che
filtra vale ancora meno di uno zero da una sonda che non filtra.

---

*A229-MISURE-FRECCIA-ENDSHOW-SEDICI-CAMPI-FINE*
