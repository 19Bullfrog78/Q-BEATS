# MISURE CC — A228, il velo dello standby: cosa copre, cosa si sbloccherebbe

Da: CC · A: chi disegna o tocca `StandbyOverlayView` (CD in primis) + Mauro + referee

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato da altri, non
rimisurato · **[A]** giudizio mio. Mai mescolati in una frase.

Origine: mandato A228 (referee), che autorizza il deposito della misura fatta
sotto mandato A227 (referee → CC, sola lettura). Le due domande a monte di
questa misura — "il rientro riprende o ricomincia" e "chi azzera davvero" —
sono risolte in A227 e non ripetute qui: qui c'è solo la Domanda 3, il velo.

---

## 0 · ID A228 — misurato, non scelto

**[M]** Sonda su due supporti (NOME e CONTENUTO), su entrambe le gambe, con
`-- ':!DESIGN'` sulla gamba CONTENUTO-git.

| ID | NOME git / hoffC / hoffE | CONT git / hoffC / hoffE |
|---|---|---|
| **A228** (preso) | 0 / 0 / 0 | 0 / 0 / 0 |
| A225 (positivo) | 1 / 1 / 1 | 1 / 2 / 2 |
| A226 (positivo parziale) | 0 / 1 / 1 | 0 / 1 / 1 |

✅ **[M] A225 rende positivo pieno su tutte e sei le colonne: la sonda vede.**
A226 rende 0 su git e 1 su entrambe le `HANDOFF/`: coerente, è depositato ma
non tracciato — non è un secondo positivo indipendente, è la controprova che
la sonda distingue "su disco" da "in git".

---

## 1 · COSA COPRE IL VELO — [M]

Il velo è `StandbyOverlayView`, montato a `LiveView.swift:132-138`:

```
if case .standby(let nextSong) = session.playbackState {
    StandbyOverlayView(nextSongName: nextSong, scaleFactor: scaleFactor)
        .contentShape(Rectangle())
        .onTapGesture {
            runner.startCurrentSong(audioEngine: audioEngine, session: session)
        }
}
```

Il suo corpo è radicato in un `GeometryReader` (`StandbyOverlayView.swift:16`)
⇒ occupa tutto lo spazio offerto dal genitore, e `LiveView.swift:134` gli
applica `.contentShape(Rectangle())` ⇒ **l'area sensibile è lo schermo
intero.** Corroborato dal commento dell'autore stesso,
`SetlistRunner.swift:286`: *«overlay + **tap-ovunque**»*.

Sotto, alla stessa quota, il VStack `LiveView.swift:96-126` con
`.opacity(isStandby ? 0.10 : 1.0)` a `:129`. Contiene, nell'ordine: freccia
indietro + mute (`LiveHeaderView`, `:97`) · display metronomo/battute/micro-
segmento (`:99-103`) · teleprompter, macrobar, POI (`:106-111`) · gesto di
trascinamento che apre il mixer (`:116-123`) · la console (`TransportView`,
`:124`).

---

## 2 · RAGGIUNGIBILE COL DITO OGGI — [M] niente

⚠️ **Non è l'opacità a bloccare.** `.opacity()` in SwiftUI non toglie il
tocco, e a `LiveView.swift:127-130` non c'è né `.disabled()` né
`.allowsHitTesting(false)`. L'unico `allowsHitTesting` di tutto il file è a
`:207` e riguarda il mixer, non il velo — cercato apposta, non scartato.

Il Play della console, in particolare: **oggi non si tocca**, per due
lucchetti indipendenti:
1. il velo lo copre (tap-ovunque, sopra tutto);
2. `TransportView.swift:34` — `disabled: isStandby`, un secondo blocco che
   non dipende dal primo.

---

## 3 · SE IL VELO SMETTESSE DI COPRIRE — [M], nessuna ipotesi sul disegno

Misura di cosa succede *oggi* se si toglie solo il velo, lasciando invariato
il resto del codice. Non è una previsione su come sarà il velo accorciato —
quel disegno è di CD e non esiste ancora.

| comando | indirizzo | dopo la rimozione del solo velo |
|---|---|---|
| **freccia indietro** | `LiveHeaderView.swift:30` `Button { onExit() }` | ✅ funzionerebbe subito — zero blocchi propri |
| **mute click** | `LiveHeaderView.swift:124` | ✅ funzionerebbe — zero blocchi propri |
| **trascinamento → apre mixer** | `LiveView.swift:116-123` | ✅ funzionerebbe — zero blocchi propri |
| **console: 5 bottoni su 6** | `TransportView.swift:27 · 34 · 70 · 76 · 82` | ⛔ resterebbero morti — `disabled: … isStandby`, secondo lucchetto indipendente dal velo |
| **console: `emerg`** | `TransportView.swift:93-95` | ⛔ non è bloccato (`disabled: false`) ma la sua azione è vuota: `{ /* navigazione Vista LISTA — Fase successiva */ }` |

🚨 **[A] Il punto che serve a CD, ed è controintuitivo:** scoprire il velo
**non sblocca il transport**. Sblocca la freccia, il mute e il mixer — cioè
uscire, non suonare. Cinque bottoni su sei hanno un secondo lucchetto che il
velo non tocca, e il sesto non fa niente in ogni caso.

### ⚠️ MARCATURA A228 — gli indirizzi qui sopra sono ANCORATI, e l'ancora è storica

**Additiva: la tabella qui sopra resta com'è, esatta a `3808bdb`. Questa è la
traduzione verso l'HEAD che la contiene.**

**[M]** Questo referto e i due **cartelli A228** entrano in git con lo **stesso
commit**. I cartelli inseriscono **dieci righe di solo commento** ciascuno,
**sopra** le righe misurate — quindi dal commit in poi sette indirizzi della
tabella non corrispondono più al file vivo:

| il testo sopra cita | dal commit in poi sta a |
|---|---|
| `TransportView.swift:34` (Play) | `:44` |
| `TransportView.swift:70 · 76 · 82` | `:80 · :86 · :92` |
| `TransportView.swift:93-95` (`emerg`) | `:103-105` |
| `SetlistRunner.swift:286` (`tap-ovunque`) | `:296` |
| `SetlistRunner.swift:307` | `:317` |
| `TransportView.swift:27` · `SetlistRunner.swift:113-115` | **invariati** — stanno sopra l'inserimento |
| `LiveView` · `LiveHeaderView` · `StandbyOverlayView` · `OverlayStopView` · `FineSetlistView` | **invariati** — file non toccati |

⛔ **Non fidarti di questa aritmetica: è vera solo finché i due file non
cambiano ancora.** Il modo che non scade è **cercare per contenuto**:
i due cartelli si trovano con la stringa `CARTELLO A228`, e le righe misurate
stanno immediatamente sotto ciascuno di essi.

**[A] La lezione, e vale oltre questo file:** un referto destinato a chi il
repo non ce l'ha non dovrebbe citare numeri di riga — sono fragili per
costruzione, e qui sono scaduti in dieci righe per mano dello stesso mandato
che li ha misurati. Si cita per **contenuto** o per **`file:riga @ commit`**.

---

## 4 · IL LIMITE DI QUESTA MISURA — [A], parte della misura, non nota a piè

Quanto sopra è letto dalla **struttura del codice**: dichiarazioni,
`.contentShape`, `.disabled`, assenza di `.allowsHitTesting`. Non è stato
osservato su un device. Il commento a `SetlistRunner.swift:286` corrobora la
lettura ("tap-ovunque") ma resta testo, non un fatto osservato a runtime.

**La prova definitiva è un collaudo, e non è stato fatto.** Chi userà questa
tabella per disegnare o per decidere un ticket deve trattarla come lettura di
codice ferma a oggi (27/08/2026, HEAD `3808bdb`), non come esito di test.

---

## 5 · COSA NON C'È IN QUESTO FILE

Non contiene la Domanda 1 (il rientro riprende dalla seconda canzone, prima
sezione — non "da capo") né la Domanda 2 (i tre chiamanti di `startSetlist`,
nessuno dei quali è il rientro dell'utente): sono già state scritte in chat
sotto A227 e non duplicate qui per non avere due copie della stessa misura.
Chi ha bisogno di quel contesto lo trova lì, non qui.

Non contiene nessun giudizio su come dovrebbe essere il velo accorciato: è
disegno di CD, fuori dal perimetro di sola-lettura di questo mandato.

---

*A228-MISURE-VELO-STANDBY-FINE*
