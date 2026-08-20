# REFERTO A128 — OVERLAY STANDBY: CENTRATURA ORIZZONTALE

Da: CC · A: referee, + Mauro · Data: **19/08/2026** · HEAD: `7c04beaf17e15c5e8d16a791e6bf18c2ff82cd76`
⛔ **NON COMMITTATO.** Un solo file, **una sola riga di codice**.

Marcatura: **[M]** misurato da me · **[R]** riportato da altri, non rimisurato · **[A]** giudizio mio.

---

## 1 · LA SPEC, LETTA ALLA FONTE

**[M]** `git show HEAD:BOX5_QBEATS.md`, righe **251-256**, verbatim:

```text
### Overlay Standby (tra canzoni)

`StandbyOverlayView` mostra il nome canzone successiva al centro schermo.
- Font: Inter-Black, **52pt * scaleFactor**
- Pulse animation: `easeInOut(duration: 2.2).repeatForever(autoreverses: true)` su `opacity` (0.45 ↔ 1.0)
- `GeometryReader` interno preservato — serve per layout verticale (`Spacer 0.27 × height`), NON per scaling font (quello arriva da parent via parametro `scaleFactor`)
```

✅ **La citazione del referee regge**: `:253` dice «al centro schermo». Non è materia di disegno,
è già deciso, e nessun giro CD è stato aperto.

---

## 2 · LA DIAGNOSI — VERIFICATA, NON DATA PER BUONA

**[M] Il referee ha ragione sul meccanismo, e aggiungo il pezzo che lo rende inequivocabile.**

Il codice a HEAD:

```swift
GeometryReader { geo in
    VStack {
        Spacer().frame(height: geo.size.height * 0.27)
        Text(nextSongName.uppercased())
            …
            .padding(.horizontal, 20)
        Spacer()
    }
}
```

**[M] Sonda:** espansori orizzontali nel file (`maxWidth` / `infinity` / `frame(width`) →
**ZERO occorrenze**. ⛔ **Controllo positivo della stessa sonda** su `LiveView.swift`,
noto-positivo → **2**. ⇒ La sonda vede, e nel file non c'è nulla che si allarghi in orizzontale.

**[A] L'ASIMMETRIA È IL CUORE DELLA COSA, e spiega perché il difetto è sopravvissuto:**

| asse | il VStack si allarga? | perché |
|---|---|---|
| **verticale** | **SÌ** | lo `Spacer()` finale spinge lungo l'asse della pila |
| **orizzontale** | **NO** | nessun figlio spinge ⇒ il VStack si stringe sul contenuto |

⇒ Il `GeometryReader` riceve un figlio più stretto di sé e lo posa **in alto a sinistra**.
Verticalmente tutto funzionava — ed è per questo che lo `Spacer 0.27` non aveva mai dato segno
di sé. **Mancava un vincolo di larghezza, e solo quello.**

⛔ **`.multilineTextAlignment(.center)` non era il colpevole, e va detto o l'errore si ripete:**
allinea le righe **fra loro** dentro il frame del testo; non allarga il frame né lo centra nel
genitore. **Le due modifiche fanno lavori diversi e servono entrambe** — quella governa il testo
a capo, questa governa dove sta il blocco.

⇒ **[M] Nessuna causa diversa trovata.** Non mi sono fermato: la misura conferma la diagnosi.

---

## 3 · LA RIPARAZIONE — UNA RIGA

```swift
                    .frame(maxWidth: .infinity)
```

**Perché questa forma e non un'altra:**

- **[M] È l'idioma già in uso nella stessa cartella, su sei siti**: `OverlayStopView.swift:45`,
  `WaitingForDirectorView.swift:60` e `:77`, `MixerOverlayView.swift:23` e `:72`,
  `RubberBtnView.swift:36`. ⇒ **Riusato, non ritradotto.** L'allineamento predefinito di
  `.frame(maxWidth:)` è `.center`: la forma nuda è quella che il corpus usa, e l'intento sta
  nel commento.
- **[A] VA DOPO `.padding`, non prima.** Così la larghezza piena avvolge il testo **già**
  spaziato, e i 20pt restano un margine interno anche con un nome lungo. Invertendo, il padding
  si sommerebbe **fuori** dal frame pieno.
- ✅ **Il `GeometryReader` resta dov'è**, come impone `BOX5:256`. La riparazione **ci convive**:
  non lo rimuove, non lo sostituisce, non gli toglie il lavoro verticale.

---

## 4 · CONTROPROVA — I VALORI INVARIATI, DIMOSTRATI E NON AFFERMATI

**Baseline:** estratta dal **blob a HEAD**, non dalla memoria. I commenti vengono **rimossi
prima** dell'estrazione: un numero citato in un commento non è un valore.

| campo | a HEAD | dopo A128 |
|---|---|---|
| font `52 * scaleFactor` | `52` | `52` |
| pulse opacità iniziale | `0.45` | `0.45` |
| pulse durata | `2.2` | `2.2` |
| pulse `autoreverses` | `true` | `true` |
| pulse opacità bersaglio | `1.0` | `1.0` |
| `Spacer 0.27 × height` | `0.27` | `0.27` |

⛔ **DIMOSTRAZIONE DI FALLIBILITÀ — cinque alterazioni, cinque bocciature:**

| alterazione | esito | messaggio |
|---|---|---|
| font `52 → 48` | ✅ **BOCCIATO** | `ora ['48'], a HEAD ['52']` |
| durata `2.2 → 2.0` | ✅ **BOCCIATO** | `ora ['2.0'], a HEAD ['2.2']` |
| Spacer `0.27 → 0.30` | ✅ **BOCCIATO** | `ora ['0.30'], a HEAD ['0.27']` |
| pulse `0.45 → 0.50` | ✅ **BOCCIATO** | `ora ['0.50'], a HEAD ['0.45']` |
| `autoreverses → false` | ✅ **BOCCIATO** | `ora ['false'], a HEAD ['true']` |

⇒ **Il controllo sa fallire su tutte e cinque. È una controprova vera.**
**ESITO SUL FILE REALE: PASSA** — «tutti e sei i valori identici a HEAD».

**Controprova secondaria sul perimetro:** righe **tolte** dal diff = **0** · righe aggiunte che
sono **codice** = **1**, ed è `.frame(maxWidth: .infinity)`. Tutto il resto è commento.

**[M] E un settimo invariante, che sta fuori dalle sei righe ma sullo stesso file:** `BOX5:532`
dichiara «**1 callsite font**». Prima: 1. Dopo: **1**. ✅

---

## 5 · FACCIA DEL FILE — E UN INCIDENTE DI MISURA CHE VA RACCONTATO

| | CR (0x0D) | LF (0x0A) | byte |
|---|---:|---:|---:|
| **PRIMA** | **0** | 36 | 1 194 |
| **DOPO** | **0** | 58 | 3 128 |

⇒ Uno zero e un numero, prima e dopo. **Il file è LF**, e ci ho scritto LF.

⚠️ **QUESTO FILE NON HA LA STESSA FACCIA DI QUELLI DI ⟦S5b⟧.** `LiveView.swift` è **CRLF** (497),
`StandbyOverlayView.swift` è **LF** (0). Chi arriva dal giro precedente e assume CRLF **corrompe
il file in silenzio**.

⛔ **INCIDENTE DI MISURA, dichiarato perché è il reperto di metodo del giro.**
Ho misurato la faccia **due volte con due strumenti**, e i due si sono **contraddetti**: `tr -cd
'\r' | wc -c` rendeva **0**, mentre `od -c | grep -o '\r' | wc -l` rendeva **1**.
**Non ho scelto: ho arbitrato con un terzo metodo** — conteggio dei byte `0x0D` in Python, senza
pipe e senza regex → **0**. La prima misura era giusta.
**La seconda sonda era rotta, e in un modo istruttivo:** `grep -o '\r'` sull'uscita di `od -c`
non contava i ritorni a capo, **contava la lettera «r» di `import`**. Rendeva un numero
plausibile e sbagliato.
⇒ **[A] Regola: due sonde che si contraddicono non si risolvono a maggioranza né a preferenza.
Ne serve una terza, di natura diversa. E una sonda che cerca un carattere dentro la
RAPPRESENTAZIONE di un file, invece che nel file, misura la rappresentazione.**

---

## 6 · IL CENSIMENTO CHE MI HAI CHIESTO — SPEC CONTRO CODICE, RIGA PER RIGA

**Non è riparazione: è misura, e non ho toccato nulla di quanto segue.**

### Le sei righe, una per una

| riga di `BOX5` | codice | esito |
|---|---|---|
| `:253` «al centro schermo» | mancava il vincolo di larghezza | ⛔ **DIVERGEVA — riparato in A128** |
| `:254` font Inter-Black **52pt × scaleFactor** | `.font(.custom("Inter-Black", size: 52 * scaleFactor))` | ✅ conforme |
| `:255` pulse `easeInOut(2.2).repeatForever(autoreverses: true)` su `opacity` 0.45↔1.0 | `pulseOpacity` 0.45 → 1.0, stessa curva | ✅ conforme |
| `:256` `GeometryReader` preservato per layout verticale, **non** per scaling font | GR presente; `Spacer 0.27 × geo.height`; il font usa il **parametro** `scaleFactor`, non `geo` | ✅ conforme |

⇒ **[M] RISPOSTA DIRETTA: nessun'altra divergenza fra le sei righe di spec e il codice.**
Quella segnalata da Mauro era l'unica.

### Ma tre cose che il codice FA e la spec NON dice

Non sono divergenze — la spec tace — ma sono comportamenti non coperti, e qualcuno li ha decisi
senza scriverli:

1. **`.uppercased()`** — il nome viene reso **tutto maiuscolo**. **[M]** `BOX5` ha **zero**
   occorrenze di `uppercase`/`maiuscol`. ⛔ Controllo positivo della stessa sonda su
   `scaleFactor` → **54**: la sonda vede, e la parola non c'è.
2. **`.foregroundColor(.white)`** — colore non prescritto in `:251-256`.
3. **`.padding(.horizontal, 20)`** — margine non prescritto in `:251-256`.

⛔ **Il silenzio di quella sezione È significativo, e lo dimostro invece di supporlo:** la sezione
**adiacente** «Overlay Stop» (`:258-262`) **prescrive** un colore
(`Color.black.opacity(0.65)`, `:261`). ⇒ La spec sa specificare i colori quando vuole. Sullo
standby non l'ha fatto.

### ⚠️ E DUE COSE PIÙ GRANDI, FUORI DALLE SEI RIGHE

**① `BOX5:562` e `:563` — DUE ARRETRATI CD APERTI PROPRIO SU QUESTA SCHERMATA**, verbatim:

```text
| **CD-1** | **Schermata iniziale Vista LIVE "standby vestito"** (nome setlist + canzone, tap-anywhere start) | 3 | 🟡 | ⏳ raccolto V63 |
| **CD-2** | **Perimetro rosso sfumato pulsante su standby tra canzoni** | 3 | 🟡 | ⏳ raccolto V63 |
```

⚠️ **CD-1 è letteralmente la schermata che ⟦S5b⟧ ha appena reso raggiungibile**, e chiede
**nome setlist + canzone**, non il solo nome canzone. Entrambi sono **⏳, mai consegnati**.
⇒ **[A] La centratura era decisa e l'ho fatta. Ma il DISEGNO di questa schermata non è chiuso:**
quello che Mauro vede oggi è la forma minima, non quella che CD ha in coda. **Non ho aperto
nessun giro CD** — lo segnalo perché la decisione è di Mauro, non mia.

**② AMBIGUITÀ INTERNA ALLA SPEC — `:253` contro `:256`.**
`:253` dice «al centro schermo». `:256` prescrive `Spacer 0.27 × height`, che mette il testo
**al 27 % dall'alto, non centrato verticalmente**. Se «centro» valesse su entrambi gli assi, le
due righe si contraddirebbero.
⇒ **Lettura adottata: centro ORIZZONTALE, verticale al 27 %.** È l'unica che le fa stare
insieme, ed è coerente con quello che Mauro ha visto («tutto a sinistra», non «troppo in alto»).
⚠️ **Chi domani leggesse `:253` come «centro anche in verticale» "riparerebbe" rompendo `:256`.**
Proposta d'incisione in fondo.

---

## 7 · UNA COSA CHE HO TROVATO STRADA FACENDO, FUORI PERIMETRO E NON RIPARATA

**[M] La faccia su disco dei sorgenti Swift è spaccata a metà, e git lo sa:**

```text
.swift su disco in LF   : 44
.swift su disco in CRLF : 23
```

Il repo ha `core.autocrlf=true` e `.gitattributes` **non copre `ios_app/`**. Git lo dichiara da
sé, sul mio file:

> `warning: in the working copy of 'ios_app/QBeats/UI/Live/StandbyOverlayView.swift', LF will be
> replaced by CRLF the next time Git touches it`

⚠️ **Conseguenza pratica: al prossimo checkout quei 44 file diventano CRLF sul disco**, senza che
nessuno li abbia modificati. Chi misurasse la «faccia prima / faccia dopo» a cavallo di un
checkout vedrebbe cambiare una cosa che non ha toccato, e potrebbe leggerlo come corruzione.

⛔ **Non è colpa di A128** — ho scritto LF su un file che era LF, CR=0 prima e dopo — **e non l'ho
riparato: è fuori perimetro.** Proposta d'incisione in fondo.

---

## 8 · LIMITI DICHIARATI

1. ⛔ **NON HO VISTO NULLA A SCHERMO, e questo è un fix VISIVO.** Non ho Mac né Xcode. Il
   ragionamento sul layout SwiftUI è solido e poggia su sei precedenti in-repo, **ma è un
   ragionamento**: la prova è il device.
2. ⛔ **Non compilato.** La CI gira solo dopo un commit, che questo mandato vieta. È una riga
   sola e usa un'API già presente sei volte nella stessa cartella, ma «una riga» non è «compila».
3. ⚠️ **Non ho misurato come si comporta con un nome MOLTO lungo** (due o tre righe a capo).
   Il ragionamento dice che il padding regge e le righe si centrano fra loro — è proprio il
   lavoro di `.multilineTextAlignment(.center)`, che resta — **ma va guardato al collaudo con un
   titolo lungo**, non solo con uno corto.

---

## 9 · PROPOSTE DI INCISIONE — SOLO PROPOSTE, NON HO TOCCATO NULLA

1. **`BOX5:253`** — disambiguare «al centro schermo» in «**al centro in orizzontale**; il
   posizionamento verticale è governato da `:256`». Costa una riga ed evita una "riparazione"
   futura che romperebbe lo `Spacer 0.27`.
2. **`BOX5:251-256`** — incidere i tre valori oggi non scritti e presenti nel codice:
   **maiuscolo**, **bianco**, **padding orizzontale 20pt**. Oggi vivono solo nel codice.
3. **`BUGS`** — ticket nuovo, 🟡 proposta BASSA: `TD-faccia-disco-swift-spaccata`. 44 file LF e
   23 CRLF con `autocrlf=true` e nessun `.gitattributes` su `ios_app/`: al prossimo checkout 44
   file cambiano faccia da soli.
4. **Per Mauro, non per i canonici** — decidere se **CD-1** e **CD-2** (`BOX5:562-563`) vanno
   sbloccati ora che la schermata è finalmente raggiungibile. **Non è una mia decisione.**
5. **Reperto di metodo** da registrare: *due sonde che si contraddicono si arbitrano con una
   terza di natura diversa, mai a preferenza; e una sonda che cerca dentro la RAPPRESENTAZIONE
   di un file misura la rappresentazione, non il file.*

---

## STATO DI CONSEGNA

| | |
|---|---|
| commit / push / rami | ⛔ **NESSUNO** |
| HEAD | `7c04beaf17e15c5e8d16a791e6bf18c2ff82cd76`, invariato |
| file toccati | **1** — `ios_app/QBeats/UI/Live/StandbyOverlayView.swift` |
| righe | **+22 / −0**; di queste **1 sola è codice** |
| canonici | **zero modifiche** |
| cancello 1 — CI | ⏸️ non valutabile prima del commit |
| cancello 2 — device | ⏸️ da fare: **guardare anche con un nome lungo** |

---

*A128-FINE*
