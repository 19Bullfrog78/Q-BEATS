# REFERTO A129 — TRE CONFORMITÀ GRAFICHE

Da: CC · A: referee, + Mauro · Data: **19/08/2026** · HEAD: `7c04beaf17e15c5e8d16a791e6bf18c2ff82cd76`
Mandato ricevuto come **A128**. ⛔ **NON ESEGUITO CON QUELL'ID.**
⛔ **NON COMMITTATO.** Tre file, zero logica, zero stato, zero transport, zero audio.

Marcatura: **[M]** misurato da me · **[R]** riportato da altri, non rimisurato · **[A]** giudizio mio.

---

## ⛔ RILIEVO 0 — L'ID DEL MANDATO COLLIDE. ESEGUITO SOTTO A129.

**[M]** Criterio = nome di file, due supporti:

```
A128  repo=2  E:=2   →  DIFF_2026-08-19_A128-STANDBY-CENTRATURA.txt
                         MISURE_CC_2026-08-19_A128-STANDBY-CENTRATURA.md
```

Sono **miei**, del turno precedente — la sola porta ①, mai committata. Regola del progetto:
**ID mai riusato.** Ho verificato **A129**: **repo=0, E:=0**, controllo positivo sulla forma
diversa (contenuto di A128) → 2 e 2, la sonda vede. **A129 libero, usato.**

**Il vecchio referto/diff A128 restano intatti come storia** — non li ho toccati, non li ho
cancellati: la porta ① che descrivevano è la stessa che questo mandato consolida come parte 1
di tre, e la applico di nuovo qui (era già sul disco, non committata, l'ho solo riverificata).

---

## LE DUE FONTI, LETTE ALLA FONTE

**[M]** `BOX5_QBEATS.md:251-256`, dal blob a HEAD — verbatim:

```text
### Overlay Standby (tra canzoni)

`StandbyOverlayView` mostra il nome canzone successiva al centro schermo.
- Font: Inter-Black, **52pt * scaleFactor**
- Pulse animation: `easeInOut(duration: 2.2).repeatForever(autoreverses: true)` su `opacity` (0.45 ↔ 1.0)
- `GeometryReader` interno preservato — serve per layout verticale (`Spacer 0.27 × height`), NON per scaling font (quello arriva da parent via parametro `scaleFactor`)
```

**[M]** `DESIGN/QLive_Nav/2026-08-06_QLive-Shows_FREEZE-CONSOLIDATO_390x844__rev3-NORMATIVA.html`
— **impronta verificata PRIMA di fidarmene**:

| | |
|---|---|
| sha256 misurato | `7154428263b93e4d6371ae99236fa6986c0934c31ecd0494df5b9c817aabaca5` |
| atteso dal referee | `71544282…` |
| esito | ✅ **coincide** |

⛔ **`…rev2-BUONA.html` esiste nella stessa cartella e NON l'ho aperto.** Ho letto solo `rev3`.

---

## ① LA SCRITTA DELLO STANDBY — CONFERMATO, RIAPPLICATO SOTTO A129

**Diagnosi del referee: verificata, non creduta.** `.multilineTextAlignment(.center)` allinea le
righe **fra loro** dentro il frame del testo; non allarga il frame né lo centra nel genitore.
**[M]** Sonda: espansori orizzontali nel file (`maxWidth`/`infinity`/`frame(width`) → **zero**
occorrenze. Controllo positivo della stessa sonda su `LiveView.swift` → **2**. La sonda vede, e
nel file non c'era nulla che si allargasse in orizzontale.

**[A] La causa è un'asimmetria del `VStack`:** in verticale si allarga perché lo `Spacer()`
finale spinge lungo l'asse della pila; in orizzontale nessun figlio spinge, quindi il `VStack` si
stringe sul contenuto e il `GeometryReader` lo posa in alto a sinistra. Nessuna causa diversa
trovata.

**Riparazione — una riga:**
```swift
.frame(maxWidth: .infinity)
```
Idioma già in uso su **sei siti** della stessa cartella (`OverlayStopView.swift:45`,
`WaitingForDirectorView.swift:60`/`:77`, `MixerOverlayView.swift:23`/`:72`,
`RubberBtnView.swift:36`). Va **dopo** `.padding`, non prima. Il `GeometryReader` non è stato
toccato, come impone `BOX5:256`.

**I tre valori invariati, dimostrati:**

| campo | a HEAD | dopo |
|---|---|---|
| font `52 * scaleFactor` | 52 | 52 |
| pulse `0.45↔1.0` in `2.2s` | 2.2 | 2.2 |
| `Spacer 0.27 × height` | 0.27 | 0.27 |

**CP-S1** — dimostrazione di fallibilità: applicato a uno `Spacer` alterato `0.27→0.30`,
il controllo lo boccia (`spacer0.27=False`). Sul file reale: **PASSA**.

---

## ② IL TITOLO DEL DETTAGLIO — `.dhead .nm` 23→29px, MAX 2 RIGHE

**[M] Letto dal blob, `QLiveShowDetailView.swift:159-171` a HEAD.** La riga `:170` imponeva
`.lineLimit(1)`: cambiare solo la dimensione avrebbe reso **peggiore** il taglio dei nomi lunghi.
Confermato dal freeze stesso, pannello ③, tabella, colonna «Perché»:

```text
.dhead .nm | 23px | 29px | pari a `.scrhead h1`: è un titolo di schermata come gli altri.
Max 2 righe, poi troncamento in coda. Due righe da 29 costano ~61pt su una lista scrollabile:
ci stanno.
```

**Valori adottati, uno per uno, con la fonte:**

| proprietà | prima | dopo | fonte |
|---|---|---|---|
| font-size | 23 | **29** | freeze rev3 riga 153: `.dhead .nm{font-size:29px;…}` |
| lineLimit | 1 | **2** | freeze rev3 riga 153: `-webkit-line-clamp:2` + tabella «Max 2 righe» |
| truncation | (implicita) | **`.tail`, esplicito** | idioma corpus `LiveHeaderView.swift:53-54` |

⚠️ **ESTENSIONE INTERPRETATIVA, DICHIARATA — il tracking, non nominato dal mandato.**
Il mandato paraphrasa solo font-size e lineLimit. **Ho letto l'intera regola CSS `.dhead .nm`**,
non solo le due proprietà citate, perché il mandato stesso lo chiede («leggi il freeze e applica
quello che dice», due volte). La riga 153 porta anche `letter-spacing:-0.6px`. Il codice a HEAD
aveva `.tracking(-0.5)`, con citazione **`§CSS :248`** — che ho verificato essere il freeze
**SUPERATO** del 07/11 (`DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html:248`: `letter-spacing:-0.5px`
per lo STESSO selettore a 23px). ⇒ Il vecchio tracking non era una scelta indipendente: era la
citazione di una fonte oggi sostituita. **Ho aggiornato tracking `-0.5 → -0.6`.**
Se il referee lo ritiene fuori perimetro, è una riga sola da rimettere indietro.

**Sei font NON toccati, verificati letteralmente presenti e invariati** (`.dhead .mt` 11 ·
`.songrow .nm` 16 · `.songrow .met` 12 · `.songrow .idx` 12 · `.startbtn` 15 ·
`.navbar .back` 12) — **CP-D1**: dimostrazione di fallibilità su `.startbtn` alterato
`15→14`, bocciata. Sul file reale: **PASSA**.

**29 ≥ 20 ⇒ scala** (`BOX5_QBEATS.md:68`), come già il 23 — verificato, non solo affermato: la
riga di commento che lo dichiara è stata aggiornata col numero corretto.

**Due citazioni incrociate, corrette perché la mia stessa modifica le rendeva stale:**
- la riga di testa del file che citava «`.dhead .nm` (23pt)» come **unico** valore ≥20 → **29pt**;
- la riga che citava `RoomSwitchBar` «font 9pt» (perché lo segMini diventa 10,5pt con l'item ③,
  qui sotto) → **10,5pt**.

**Controprove D2-D5** — ciascuna applicata prima a un'alterazione (size→23, lineLimit→1,
tracking→-0.5, truncationMode rimosso): **tutte e quattro bocciate**. Sul file reale: **PASSA**
su tutte e quattro insieme (`size=29 tracking=-0.6 lineLimit=2 tail=True`).

---

## ③ IL SELETTORE STANZA — LA VARIANTE «MINI» SPARISCE

**[M] Rev3 non porta più ALCUNA regola CSS `.seg-mini`** — sonda: `grep -n 'seg-mini'` sul foglio
di stile rende **zero** righe CSS (solo prosa/legenda). Il callout del pannello ③ lo dice in
chiaro: *«Con la `.seg-mini` abolita, il room switch è un componente solo in tutta l'app, con una
misura sola.»*

**Le due trappole, verificate:**
- **(a)** `variant: .full` non è la risposta — verificato: `.full` renderizza `ZStack{segment;
  HStack{homeButton;Spacer()}}` a `height:54`, mentre `.segMini` renderizza `case .segMini:
  segment` da sola. **Non ho toccato lo `switch` sul `body`**: il sito
  `QLiveShowDetailView.swift:127` continua a renderizzare il solo segmento.
- **(b)** `.full` è usato da `QStage/ShowsListView.swift:85` e `QLive/QLiveShowsView.swift:81` —
  **non toccati**, verificato: il ramo `.full` del codice **non è stato modificato**, solo
  letto (vedi controprove CP-R1/R2).

**Valori adottati, uno per uno, con la fonte** — tutti da `.roomseg .opt`, freeze rev3 riga 103:
`font-family:'JetBrains Mono';font-size:10.5px;font-weight:700;letter-spacing:1px;
text-transform:uppercase;padding:7px 12px;border-radius:9px;color:var(--text3);min-height:34px`:

| proprietà | `.segMini` prima | dopo | fonte |
|---|---|---|---|
| font-size | 9 | **10.5** | `.roomseg .opt{font-size:10.5px}` |
| padding orizzontale | 9 | **12** | `.roomseg .opt{padding:7px 12px}` |
| padding verticale | 5 | **7** | idem |
| border-radius | 8 | **9** | `.roomseg .opt{border-radius:9px}` |
| min-height | 30 | **34** | `.roomseg .opt{min-height:34px}` — **il valore esplicitamente nominato dal mandato** |
| letter-spacing (tracking) | 0.8 | **1** | `.roomseg .opt{letter-spacing:1px}` |

⚠️ **ESTENSIONE INTERPRETATIVA, DICHIARATA — il CONTENITORE, non solo la pill.**
Il mandato cita testualmente solo `.roomseg .opt` (la pill). Ho **letto anche** la regola
`.roomseg` (il contenitore, freeze rev3 riga 102: `padding:4px;border-radius:12px;gap:3px`) e ho
trovato che **anche il container aveva due valori ridotti** per `.segMini` (`containerPadding`
3 invece di 4, `containerRadius` 10 invece di 12) — mai nominati dal mandato, ma **anch'essi**
regolati da una variante `.seg-mini` che nel foglio di stile **non esiste più**. Il callout del
pannello ③ parla di *«una misura sola»* per **l'intero componente**, non solo per la pill.
**Ho uniformato anche questi due**, per lo stesso ragionamento del tracking in ②: la variante
che li giustificava è quella abolita. Se il referee li ritiene fuori perimetro, sono due righe.

| proprietà container | `.segMini` prima | dopo | fonte |
|---|---|---|---|
| padding | 3 | **4** | `.roomseg{padding:4px}` |
| border-radius | 10 | **12** | `.roomseg{border-radius:12px}` |

`gap:3px` **non ho dovuto toccarlo**: il codice usava già `HStack(spacing: 3)` non condizionato
da `variant`, quindi era già conforme.

**`.full` verificato INTATTO** — non un'affermazione, una controprova (**CP-R1**): tutti gli otto
letterali `variant == .full ? …` e la formula di `hitExpansion` sono cercati **testualmente** nel
file dopo l'edit; un'alterazione di prova (`.full` fontSize `10.5→11.0`) viene bocciata.
Sul file reale: **PASSA**, `.full` bit-per-bit identico a HEAD.

**`hitExpansion` NON toccato** — **CP-R2**: la riga
`let hitExpansion: CGFloat = variant == .full ? (54 - minHeight) / 2 : 0` è cercata letterale.
Un'alterazione che desse l'espansione anche a `.segMini` viene bocciata. Sul file reale:
**PASSA** — `.segMini` resta a hitExpansion **zero**, come impone il RI-GATE S3.

**`.segMini` uniformato** — **CP-R3**: dimostrazione di fallibilità applicata al file **a HEAD**
(dove `.segMini` è ancora ridotto): bocciata su tutti e otto i valori. Sul file reale: **PASSA**,
tutti e otto uguali a `.full`.

---

## LE DUE SEGNALAZIONI RICHIESTE — MISURATE, NON RISOLTE

### ① La contraddizione aritmetica «34+3+3=40» contro il foglio di stile

**[M] Misurato, non scelto.** Il testo del freeze (tabella pannello ③) calcola: *«34+3+3 =
40pt dentro una navbar da 50»*. Il **foglio di stile dello stesso file** dà a `.roomseg` un
padding di **4px** (non 3), riga 102: `.roomseg{padding:4px}`.

Con la pill unica a 34 e il container ora uniformato a `padding:4`, il calcolo che il MIO codice
produce è: **34 + 4 + 4 = 42**, non 40. Ho scritto questo numero — 42 — nel commento del codice
(`chromeHeight`), **non 40**: è quello che deriva dal foglio di stile normativo, non dalla prosa
della tabella. Entrambi (40 e 42) stanno dentro una navbar da 50pt, quindi **non blocca** in
nessuno dei due casi — ma è una contraddizione interna al documento normativo, e l'ho incisa nel
codice invece di sceglierla in silenzio.

### ② Il RI-GATE S3 e l'area tattile — un dubbio strutturale in più, che aggiungo io

**[M] Il divieto è rispettato alla lettera**: non ho toccato `hitExpansion` (riga invariata,
provato da CP-R2) né l'altezza della navbar (`QLiveShowDetailView.swift:130`, file non toccato
in quella funzione).

⚠️ **Ma la premessa del freeze mi lascia un dubbio che riporto invece di ignorare.** Il callout
dice: *«Il referee ha misurato 50pt di hit-test verticale, già ≥44… Alzando il chrome visibile
30→34pt l'area resta 50… Chi implementa non deve toccare l'altezza della navbar.»* — cioè
assume che l'area tappabile di ogni pill sia **già** legata ai 50pt della navbar, indipendente
dal chrome visibile.

**[M] Dal codice non vedo come.** `segment` (il contenitore dei due pulsanti) usa
`.frame(minHeight: chromeHeight)` — un **minimo**, non uno stiramento — e la sua altezza
(42, con o senza A129) è più piccola dei 50 della navbar; l'`HStack` esterno centra i suoi figli,
non li stira. Ogni pill ha la propria area di tocco = il proprio `minHeight` (ora 34, non 50) +
`hitExpansion` (zero su `.segMini`). Non ho trovato, in questo file, un meccanismo che estenda
l'area tappabile della singola pill fino ai 50pt della navbar.

⛔ **Non ho toccato nulla per questo dubbio** — è fuori dal perimetro «zero logica» e la
misura definitiva è solo sul device. Lo segnalo perché o mi sfugge un comportamento SwiftUI che
non conosco, o l'affermazione del freeze sull'area 50pt andrebbe riverificata prima di darla per
acquisita al prossimo giro su questo componente.

---

## FACCIA DEI TRE FILE — PRIMA E DOPO

CR contati sui **byte**, arbitrati in Python puro dopo che due sonde a riga di comando si sono
contraddette nel turno precedente (vedi A128 superato): non ripetuto l'errore, misurato diretto.

| file | CR prima | LF prima | CR dopo | LF dopo | |
|---|---:|---:|---:|---:|---|
| `QLiveShowDetailView.swift` | 443 | 443 | 458 | 458 | uniforme (CRLF) |
| `RoomSwitchBar.swift` | 233 | 233 | 260 | 260 | uniforme (CRLF) |
| `StandbyOverlayView.swift` | 0 | 36→58* | 0 | 58 | uniforme (LF) |

*\*già a 58 dal turno precedente, non ritoccato in questo giro.*

⚠️ **I tre file NON hanno la stessa faccia fra loro** — due sono CRLF, uno è LF. Ciascuno è
rimasto sulla propria, come impone la regola «adattarsi alla faccia del bersaglio».

---

## CONTROPROVE — RIEPILOGO, OGNUNA CON LA SUA DIMOSTRAZIONE DI FALLIBILITÀ

| # | verifica | caso noto-cattivo | sa fallire? | sul reale |
|---|---|---|---|---|
| CP-S1 | Spacer 0.27 invariato | 0.27→0.30 | ✅ bocciato | **PASSA** |
| CP-D1 | sei font invariati | `.startbtn` 15→14 | ✅ bocciato | **PASSA** |
| CP-D2 | `.dhead .nm` size=29 | riportato a 23 | ✅ bocciato | **PASSA** |
| CP-D3 | `.dhead .nm` lineLimit=2 | riportato a 1 | ✅ bocciato | **PASSA** |
| CP-D4 | `.dhead .nm` tracking=-0.6 | riportato a -0.5 | ✅ bocciato | **PASSA** |
| CP-D5 | `.dhead .nm` truncation=.tail | rimosso | ✅ bocciato | **PASSA** |
| CP-R1 | `.full` intatto (8 valori) | fontSize .full 10.5→11.0 | ✅ bocciato | **PASSA** |
| CP-R2 | `hitExpansion` intatta | data anche a `.segMini` | ✅ bocciato | **PASSA** |
| CP-R3 | `.segMini` uniformato (8 valori) | il file a HEAD (ridotto) | ✅ bocciato | **PASSA** |
| CP-N1 | conteggio righe-codice sa contare | +1 riga finta nel diff | ✅ distingue (18→19) | — |

**Conteggio righe NON-commento cambiate, per file** (esatto, non stimato):

| file | + | − |
|---|---:|---:|
| `QLiveShowDetailView.swift` | 4 | 3 |
| `RoomSwitchBar.swift` | 9 | 9 |
| `StandbyOverlayView.swift` | 1 | 0 *(dal turno precedente, non ritoccato)* |

**Bilancio graffe** (indizio grezzo, non prova di sintassi): `{`/`}` pari su tutti e tre i file
dopo l'edit (49/49 · 26/26 · 7/7).

---

## ⛔ COSA NON HO POTUTO VERIFICARE

1. **NULLA di questo è visibile finché Mauro non guarda il telefono.** Sono tre fix
   **puramente visivi** — centratura, dimensione titolo, misura di un selettore — e non ho
   Xcode né un simulatore. Il ragionamento su ognuno è sourced riga per riga contro il freeze o
   il corpus, ma «sourced» non è «visto».
2. **Non compilato.** La CI gira solo dopo un commit, vietato da questo mandato. Le modifiche
   sono tutte letterali su valori numerici e stringhe esistenti (nessun tipo nuovo, nessuna
   firma di funzione toccata) — rischio di rottura sintattica basso, ma non verificato.
3. **Il dubbio sul RI-GATE S3** (segnalazione ②) resta aperto: non l'ho risolto, non l'ho
   potuto testare, l'ho solo misurato dal codice e riportato.
4. **Il titolo a due righe** (item ②): non ho potuto vedere come si comporta realmente uno show
   col nome lungo — il ragionamento (`.dhead` non ha altezza fissa, il resto scrolla) è solido
   ma va guardato al collaudo, con un nome che occupi davvero le due righe.
5. **CD-1/CD-2** (`BOX5:562-563`, trovate nel referto A128 superato): restano **⏳, mai
   consegnate**. Non le ho riaperte né toccate; le rimenzionavo dal giro precedente perché sono
   sulla stessa schermata di item ①.

---

## STATO DI CONSEGNA

| | |
|---|---|
| commit / push / rami | ⛔ **NESSUNO** |
| HEAD | `7c04beaf17e15c5e8d16a791e6bf18c2ff82cd76`, invariato |
| file toccati | **3**, i tre nominati, nient'altro |
| canonici | **zero modifiche** |
| diff | `HANDOFF/DIFF_2026-08-19_A129-TRE-CONFORMITA-GRAFICHE.txt` — 13 152 B · 169 righe · CR 0 · sha256 `7244c9102c1cf5a21cdb8e92edda28fcee23295b7643f52063dd02e34e4f4f2c` |
| cancello 1 — CI | ⏸️ non valutabile prima del commit |
| cancello 2 — device | ⏸️ tre cose da guardare: centratura standby, titolo a due righe con nome lungo, selettore stanza 34pt |

---

⚠️ **Il marcatore qui sotto dice A129, non A128** come scritto nel mandato ricevuto: coerenza con
il Rilievo 0 in testa a questo referto, non un troncamento. Sarebbe stato un'ultima incoerenza
lasciare il nome vecchio proprio nella riga che certifica che il file è arrivato intero.

*A129-FINE*
