# REFERTO A126 — CORREZIONE §7 SU UN COMMENTO

Da: CC · A: referee, + Mauro · Data: **19/08/2026**
Mandato: **A126**, che segue **A125 RATIFICATO**. Perimetro: **un solo commento**.
⛔ **NON COMMITTATO.** ⛔ **Zero righe di codice toccate** — dimostrato sotto.

Marcatura: **[M]** misurato da me · **[A]** giudizio mio.

---

## ⓘ PRIMA DI TUTTO: LA FONTE ESISTE, E L'HO TROVATA

Il mandato dice: «*Se una fonte ufficiale la trovi TU, portala e la frase originale può
restare: in quel caso è §7 soddisfatto, non aggirato*».

**[M] L'ho cercata e c'è.** La pagina ufficiale Apple di `Published` porta, nell'Overview, un
esempio con l'output dichiarato — e quell'output **mostra** il comportamento:

```text
https://developer.apple.com/documentation/combine/published
```

```swift
let weather = Weather(temperature: 20)
cancellable = weather.$temperature
    .sink() {
        print ("Temperature now: \($0)")
}
weather.temperature = 25

// Prints:
// Temperature now: 20.0
// Temperature now: 25.0
```

La prima riga stampata è **`20.0`**, il valore **corrente**, emessa **prima** di qualunque
cambio della proprietà — l'unica cosa accaduta fino a lì è la sottoscrizione.

⚠️ **MA UNA DISTINZIONE CHE VA FATTA, ED È IL MOTIVO PER CUI NON MI SONO LIMITATO A INCOLLARE
L'URL.** La documentazione **mostra** il comportamento nell'esempio; **non lo enuncia in prosa**.
La sola frase di prosa sulla tempistica è un'altra, e riguarda il `willSet`, verbatim:

> «When the property changes, publishing occurs in the property's `willSet` block, meaning
> subscribers receive the new value before it's actually set on the property.»

⇒ **[A] Un esempio con output dichiarato è fonte ufficiale** — è Apple che descrive il proprio
API — **ma è una fonte più debole di un'affermazione normativa in prosa.** Appoggiarci sopra la
tenuta di ⟦S5b⟧ resterebbe fragile.

⇒ **Ho fatto entrambe le cose, ed è meglio di ciascuna da sola:**
**(a)** ho riformulato il motivo (2) come prescrivi, così che **la protezione non dipenda più
da alcun assunto su Combine** — la guardia vale per **ogni** `.stopped`, in qualunque momento
arrivi; **(b)** ho **tenuto** il fatto della consegna iniziale, ora **con l'URL**, retrocesso a
nota che spiega *perché il rischio si presenta già al montaggio*. Se domani quella nota cadesse,
il motivo (2) **reggerebbe intatto**.

---

## 1 · IL COMMENTO NUOVO — VERBATIM DAL FILE

`ios_app/QBeats/UI/Live/LiveView.swift`, righe **261-279** (il blocco `(2)`; `(1)` e la
riga-cappello sono invariati):

```swift
                //  (2) ⟦S5b⟧ — È CIÒ CHE TIENE IN PIEDI L'ARMAMENTO D'INGRESSO. Da ⟦S5b⟧
                //      `primeDisplay` (:231) lascia la sessione in `.standby` quando si
                //      entra in uno show. Questa guardia impedisce a QUALSIASI `.stopped`
                //      proveniente dal motore — in qualunque momento arrivi, e qualunque
                //      ne sia la causa — di scrivere sopra quello standby. Senza il
                //      `case .standby` qui sotto l'overlay verrebbe cancellato e lo Start
                //      sembrerebbe non fare nulla.
                //      ⛔ La protezione NON dipende da QUANDO il motore parli: vale per
                //      ogni `.stopped`, il primo compreso. Non c'è alcun assunto sul
                //      momento della prima consegna — se anche non ne arrivasse nessuna
                //      al montaggio, la guardia resterebbe necessaria per tutte le altre.
                //      ⓘ Fatto SORGENTATO, che spiega perché il rischio si presenta già
                //      al montaggio e non solo a show avviato: la documentazione Apple di
                //      `Published` mostra un sottoscrittore che riceve il valore corrente
                //      all'atto della sottoscrizione — nel suo esempio la `sink` stampa
                //      «Temperature now: 20.0» prima di qualunque cambio della proprietà.
                //      https://developer.apple.com/documentation/combine/published
                //      ⚠️ Una pulizia futura che togliesse `.standby` da questa lista
                //      romperebbe ⟦S5b⟧ senza toccarne una riga.
```

**Cosa è cambiato rispetto ad A125, in una riga:** l'affermazione su `@Published` **non è più
la ragione** della protezione — è una nota a corredo, con URL. La ragione ora è che la guardia
copre **ogni** `.stopped`, senza ipotesi sul momento.

---

## 2 · PROVA CHE LE 17 RIGHE DI CODICE SONO IMMUTATE

**Baseline:** l'artefatto **ratificato** `HANDOFF/DIFF_2026-08-19_A125-S5b-CABLAGGIO.txt`,
**non toccato** da questo mandato — riverificato: sha256
`00628d781472c537dff20df5f09d70f4aced2e5b55b9c76a7e9f25909010d3ba`, identico al ratificato.
Idem il referto A125 (`e54044558597a7464cc3a60710691205c65525d314f0773046b995334fa7c748`).

**Metodo:** dal diff si estraggono le righe **aggiunte**, escluse intestazioni, commenti e
vuote; devono essere **17** e **identiche una per una**, nell'ordine, a quelle di A125.

⛔ **DIMOSTRAZIONE DI FALLIBILITÀ — tre forme di rottura, tre bocciature:**

| caso noto-cattivo | esito | messaggio |
|---|---|---|
| riga di codice **alterata** (`.disabled(isEnabled)`) | ✅ **BOCCIATO** | `riga 17 DIVERSA` |
| riga di codice **aggiunta** (`session.beatActive = 0`) | ✅ **BOCCIATO** | `righe di codice = 18, attese 17` |
| riga di codice **tolta** (`.disabled(!isEnabled)`) | ✅ **BOCCIATO** | `righe di codice = 16, attese 17` |

⇒ **Il controllo sa fallire su tutte e tre le forme. È una controprova vera**, non una conferma
che mi do da solo.

**ESITO SUL DIFF REALE: PASSA** — «17 righe, identiche una per una ad A125».
⛔ **CORREZIONE A127 — QUI C'ERA UN'IMPRONTA NON RIPRODUCIBILE, E IL DIFETTO ERA MIO.**
La riga diceva «sha256 della sequenza delle 17 righe: `b958bb9dccf703bbd91b3aebbf246266`»:
**32 caratteri, non 64**. Non era uno sha256 sbagliato — era uno sha256 **troncato** e non
dichiarato tale, perché il mio script di controprova stampava `…hexdigest()[:32]`. Il referee
ha provato a riprodurla su quattro varianti di estrazione, con sha256 e con md5, e nessuna
delle otto poteva renderla: **cercava un valore che non esisteva.**
⚠️ **Lezione, e non è la prima volta in questo progetto:** un'impronta senza il comando che la
genera non è verificabile, e un'impronta della lunghezza sbagliata è peggio di nessuna impronta.

**Valore ricalcolato, INTERO, e il comando che lo produce — verbatim, eseguibile da chiunque:**

```bash
grep '^+' HANDOFF/DIFF_2026-08-19_A126-S5b-COMPLETO.txt \
  | grep -v '^+++' | sed 's/^+//' \
  | grep -vE '^[[:space:]]*//' | grep -vE '^[[:space:]]*$' \
  | sha256sum
```

```text
8db688672c617b6ed1a1035544087a114545126ac3a5b1c4259bab1534650317
```

⛔ **È ancorato al FILE del diff, non a `git diff`**, e la scelta è deliberata: dopo il commit
`git diff` rende vuoto, il file tracciato no. Il comando resta rifacibile per sempre.

✅ **E DIMOSTRA DA SOLO LA TESI DI QUESTO REFERTO:** lo stesso comando applicato al diff
**ratificato di A125** (`HANDOFF/DIFF_2026-08-19_A125-S5b-CABLAGGIO.txt`) rende
**lo stesso identico valore** — `8db68867…`. Due file diversi, stessa sequenza di 17 righe di
codice. **A126 non ha toccato una riga di codice.**

```text
   1 |         if case .stopped = session.playbackState, let song = currentSong {
   2 |             session.playbackState = .standby(nextSongName: song.name)
   3 |         }
   4 |                 QLiveShowDetailView(
   5 |                     setlist: show,
   6 |                     onBack: { navigate(to: .shows) },
   7 |                     onStart: { runner in
   8 |                         roomSession.install(runner)
   9 |                         navigate(to: .metronome)
  10 |                     }
  11 |                 )
  12 |     func install(_ newRunner: SetlistRunner) {
  13 |         runner = newRunner
  14 |     }
  15 |     let onStart: (SetlistRunner) -> Void
  16 |             onStart(SetlistRunner(setlist: setlist, store: store))
  17 |         .disabled(!isEnabled)
```

**Controprova secondaria:** righe `+`/`-` di `LiveView.swift` che **non** siano commento e non
vuote → **0**, attese 0. (Stesso controllo di CP-8 in A125, che sa fallire: applicato allo
stesso diff con una riga di codice aggiunta, la segnala.)

---

## 3 · FACCIA DEL FILE — PRIMA E DOPO

CR contati sui **byte** (`tr -cd '\r' | wc -c`), **mai** con `grep`.

| | CRLF | LF-sole | righe | |
|---|---:|---:|---:|---|
| `LiveView.swift` **PRIMA** | 487 | **0** | 487 | uniforme |
| `LiveView.swift` **DOPO** | 497 | **0** | 497 | uniforme |

⇒ **Uno zero e un numero**, prima e dopo. +10 righe, **tutte commento**.
Gli altri quattro file **non sono stati aperti**.

---

## 4 · IMPRONTE AGGIORNATE

**Diff nuovo — è questo che andrebbe a commit:**

| | |
|---|---|
| file | `HANDOFF/DIFF_2026-08-19_A126-S5b-COMPLETO.txt` |
| byte | **17 496** |
| righe | **267** |
| CR | **0** |
| sha256 | `cfd490950aef94a37ef6fba8c998fbc071c17db4915e62ecfd4c6bd82d3a20b3` |
| totale | **+169 / −9** (erano +159/−9: le 10 righe in più sono il commento) |
| file toccati | **5**, gli stessi di A125 |

**Referto A126 (questo file):** impronte nel messaggio di consegna, come prescrive R7 §1
(«sha256 = trasporto, non puntatore»). ⛔ **Non le incido qui dentro**: sarebbe la stessa
autoreferenza che ho già rilevato nel congedo A123.

**Artefatti A125, invariati e verificati:**

| file | sha256 |
|---|---|
| `DIFF_2026-08-19_A125-S5b-CABLAGGIO.txt` | `00628d78…` invariato |
| `MISURE_CC_2026-08-19_A125-S5b-CABLAGGIO.md` | `e5404455…` invariato |

⚠️ **Non ho sovrascritto il diff di A125 e non ho rigenerato il suo referto.** È l'oggetto che
il referee ha ratificato: rifarlo cancellerebbe la storia della ratifica. Il diff di A126 è un
file **nuovo e affiancato**.

---

## 5 · LIMITI — INVARIATI E NON ATTENUATI

⛔ **Il codice non è mai passato da un compilatore.** Niente Mac, niente Xcode; la CI
(`iOS Signed Build`) gira **solo dopo un commit**. A126 non cambia questo di una virgola: ha
toccato **zero righe di codice**, quindi non aggiunge rischio di compilazione — **ma non ne
toglie nemmeno**.

⛔ **Nulla è stato visto a schermo.** Restano da guardare al gate device: l'overlay d'ingresso
(compare · nome della **prima** canzone · **pulsa** · **non suona**) e l'aspetto dello Start
disabilitato con `.disabled()`.

⇒ **La CI è la prima prova vera. Il device è la seconda. Nessuna delle due è stata fatta.**

---

*A126-FINE*
