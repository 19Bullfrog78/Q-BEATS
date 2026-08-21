# MISURE CC — A139-NAVBAR54-DETTAGLIO

**ID ricevuto e verificato: `A139-NAVBAR54-DETTAGLIO`.**
Da: CC · A: referee, + Mauro · 21/08/2026
Ancoraggio: **HEAD = `98b8fc6c335f5c9b7279650584412b3bbced70c1`**, locale **=** remoto
(`git rev-parse HEAD` e `git ls-remote origin master`, mai `rev-parse origin/master`).

⛔ **NESSUN COMMIT IN QUESTO GIRO.** Il diff è nell'albero di lavoro e nel file
`HANDOFF/DIFF_2026-08-21_A139-NAVBAR54-DETTAGLIO.txt`. Aspetto **ratifica del
referee** e **poi** l'OK esplicito di Mauro: due permessi separati, nessuno
sostituisce l'altro.

Marcatura: **[M]** misurato da me alla fonte in questo giro · **[R]** riportato ·
**[A]** giudizio mio.

---

## ⛔ LE QUATTRO RIGHE DA LEGGERE PRIMA DI TUTTO

**1. Nessuna condizione di stop del §6 è scattata.** ID libero, i cinque verbatim
corrispondono, le metriche **confermano** il punto 3(d), e la ristrutturazione in
ZStack **migliora** la raggiungibilità del tasto «Shows» invece di intaccarla.

**2. Ho scritto DUE RIGHE OLTRE LA LETTERA DEL MANDATO.** Sono due intestazioni
`// MARK:` che (a) e (c) rendono false. Le dichiaro in una sezione propria perché
il referee possa **respingerle in una riga**.

**3. 🚨 Ho trovato DUE PUNTATORI `file:riga` GIÀ SCADUTI A HEAD**, dentro il
codice, che il mio cambiamento sposta ancora. **Non li ho toccati** — sono fuori
perimetro — ma lasciarli taciuti sarebbe peggio. Misure e sostituzioni sotto.

**4. ⚠️ La sonda per contenuto su `E:` rende FALSI POSITIVI.** `A139` e `A140`
rendevano **entrambi 11** su tutto l'albero: match dentro blob base64 di HTML
standalone. Un ID mai usato che rende lo stesso conteggio del candidato è il
segnale che il conteggio è rumore.

---

## §0 · L'ID — DUE SUPPORTI, DUE FORME, PIÙ CONTESTO

**[M]** Sonda stretta: perimetro documentale, solo `*.md` e `*.txt`, binari
esclusi (`-I`), pattern con confine di parola.

| ID | NOME repo | CONT repo | NOME E: | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A139** | **0** | **1** | **0** | **1** | ⇒ **LIBERO** |
| A140 | 0 | 0 | 0 | 0 | controllo negativo |
| A133 | 2 | 5 | 2 | 4 | **controllo positivo** |
| A134 | 1 | 4 | 1 | 4 | **controllo positivo** |
| A138 | **0** | 3 | **0** | 3 | usato e **invisibile al nome** |

⛔ **ISPEZIONE DEL CONTESTO** — l'unico hit di `A139`, identico sui due supporti,
è **una menzione come libero**, non un uso:

```
HANDOFF/CONGEDO_CC_2026-08-21.md:118:| **A139** | **0** | **0** | **0** | **0** | ⇒ **PROSSIMO LIBERO** |
```

⚠️ **A138 riconferma la cecità strutturale del §6 del congedo 21/08**: usato,
`0` per nome su entrambi i supporti.

🚨 **LA SONDA PER CONTENUTO HA UNA TERZA FORMA DI ERRORE, non solo le menzioni.**
Su `E:` senza filtri, `A139` e `A140` rendono **11 entrambi**: match dentro i blob
base64 dei `*_STANDALONE.html`.

**[A] Il controllo che l'ha smascherata è quello NEGATIVO, non quello positivo.**
Un ID che nessuno ha mai usato non può rendere 11. Chi sondasse col solo controllo
positivo leggerebbe «la sonda vede» e non si accorgerebbe del pavimento di rumore.
⇒ **La sonda per contenuto va ristretta ai file di testo e ancorata a `\b`, e
serve SEMPRE anche un controllo negativo.**

---

## §1 · I VERBATIM — TUTTI E CINQUE CORRISPONDONO

**[M]** Letti a HEAD `98b8fc6`. Impronte dei file letti:

| file | sha256 (blob = disco) | righe a HEAD |
|---|---|---:|
| `QLiveShowDetailView.swift` | `3c16cf98b26ebc57853b5d80a42c17ac…` | 458 |
| `RoomSwitchBar.swift` | `15f4d100724c92a242d556f4e7638ce3…` | 266 |

⚠️ **Faccia dichiarata:** entrambi i file Swift sono **CRLF su disco**, LF nel
blob (`core.autocrlf=true`; `.gitattributes` marca `-text` solo `HANDOFF/**`,
`DESIGN/**`, BOX3, BOX5). Ho scritto preservando CRLF: dopo la modifica
`CR = LF` su entrambi (526 e 278), zero righe miste.

### (a) `navbar` — VERBATIM A HEAD, righe 117-131

```swift
    // MARK: - Navbar (§CSS `.navbar`: height 50, padding 0 14)

    private var navbar: some View {
        HStack {
            backButton
            Spacer()
            // Componente prescritto dalla scheda dell'atomo: `.segMini[active:.qLive]` INERTE.
            // `onHome` non è usato dalla variante `.segMini` (il suo `body` rende il solo
            // `segment`, RoomSwitchBar.swift:65-66) ma è un parametro non-opzionale: passata
            // una closure vuota. `onSwitch` resta al suo default no-op ⇒ INERTE come richiesto.
            RoomSwitchBar(active: .qLive, onHome: {}, variant: .segMini)
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
    }
```

⇒ corrisponde a 3(a): `HStack { backButton ; Spacer() ; RoomSwitchBar(...) }`,
altezza **50**.

### (b) `backButton` col commento sopra — VERBATIM A HEAD, righe 133-155

```swift
    // Back «Shows» — unica uscita dalla schermata. Hit-area ≥44pt (vincolo globale): il
    // padding verticale sta DENTRO la label del Button, così il GESTO lo copre — lezione del
    // gate device S3 fallito su `RoomSwitchBar` (`RoomSwitchBar.swift:152-164`: un
    // `.contentShape` fuori dal Button appartiene a una vista senza gesto e resta inerte).
    // Il chrome visivo non cambia: il padding aggiunto è trasparente. Navbar 50pt ⇒ i 44
    // ci stanno senza sfondare.
    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: 5) {
                BackChevronShape()
                    .stroke(QLiveTheme.accent,
                            style: StrokeStyle(lineWidth: 2 * 16 / 24, lineCap: .round, lineJoin: .round))
                    .frame(width: 16, height: 16)
                Text("Shows")
                    .font(.jbMono(.semibold, size: 12))
                    .tracking(0.4)
                    .foregroundColor(QLiveTheme.accent)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
```

⇒ corrisponde a 3(b): `minHeight: 44` e `.contentShape` **dentro** la label.

### (c) `dhead` fino ai suoi `.padding` — VERBATIM A HEAD, righe 157-199

Riportate le righe portanti; il blocco intero sta nel diff.

```swift
    // MARK: - Dhead (§CSS `.dhead` padding 6/18/10 · `.dhrow` gap 10 · `.mt` / `.mt.a`)

    private func dhead(_ resolved: (songs: [Song], missingIDs: [UUID]), scaleFactor: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ...
                Text(setlist.name.isEmpty ? "Untitled show" : setlist.name)
                    .font(.custom("Inter-ExtraBold", size: 29 * scaleFactor))
                    .tracking(-0.6)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            ...
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
```

⇒ corrisponde a 3(c): `6 / 18 / 10`. **Zero `.lineSpacing` presente**, coerente
con 3(d).

### (d) `RoomSwitchBar` ramo `.full` — VERBATIM A HEAD, righe 38-67

```swift
    var body: some View {
        switch variant {
        case .full:
            // .roombar.center: seg centrato sull'INTERA barra, home in `position:absolute;left:14px` (§CSS .roombar.center)
            // → ZStack (non HStack+Spacer): il centraggio del segment non dipende dalla presenza dell'home.
            ZStack {
                segment
                HStack {
                    homeButton
                    Spacer()
                }
            }
            // FIX 8 (referee): dichiarare la larghezza piena, NON ereditarla dallo Spacer +
            // inferenza sul genitore (S3/S4 non ancora scritti; senza un genitore che proponga
            // la larghezza piena, lo ZStack collasserebbe alla larghezza intrinseca e il
            // "seg centrato sull'intera barra" salterebbe).
            // ORDINE dei modificatori (SwiftUI wrappa dall'interno all'esterno, `.padding`
            // DEVE restare l'ULTIMO/esterno): `.frame(maxWidth:.infinity)` fa reclamare al
            // contenuto (W−28) proposti dal padding; `.padding(.horizontal,14)` riaggiunge 14
            // per lato → barra a larghezza piena W, contenuto inset 14/lato (= §CSS .roombar
            // `padding:0 14px`, border-box), home ancorato al bordo interno sx (HStack riempie
            // W−28, Spacer spinge), seg centrato dallo ZStack. Invertendo (padding interno,
            // frame esterno) il contenuto galleggerebbe centrato con 14 di minimo ma senza
            // ancoraggio a 14 → home NON al bordo. `.frame(height:54)` è asse indipendente.
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .padding(.horizontal, 14)
        case .segMini:
            segment
        }
    }
```

⚠️ **[M] Fatto che il mandato non dice e che rende il riuso perfetto:** il ramo
`.full` è **già a 54 e già con padding 14**. Dopo il cambio la navbar del
dettaglio non «assomiglia» a `.full`: **coincide**.

### (e) il calcolo di `hitExpansion` — VERBATIM A HEAD, righe 164-179 e 198

```swift
        // ⚠️ MARCATURA A129 — I NUMERI QUI SOTTO SONO STORIA, NON PIÙ IL VALORE CORRENTE.
        // Chrome visibile: 30pt → 34pt (freeze rev3). Il PRINCIPIO resta intatto e NON si tocca:
        // hit-area ≥44pt gattata dal RI-GATE S3, `.segMini` a hitExpansion ZERO finché non
        // sblocca. Anche il calcolo proiettato «(50−30)/2 = 10pt» in fondo al blocco è STORIA:
        // con minHeight ora 34 non è più valido, e ricalcolarlo qui sarebbe fare il lavoro di
        // S5 in anticipo — NON è in questo perimetro.
        ...
        // ristrutturata su `.full`. Quando sblocca: `hitExpansion` .segMini = (50 − 30) / 2 =
        // 10pt (navbar 50pt, coerente con `.roomseg` che riempie i 54). Lavoro per S5, NON qui.
        ...
        let hitExpansion: CGFloat = variant == .full ? (54 - minHeight) / 2 : 0
```

⇒ corrisponde a 3(e). Confermata anche la premessa che `minHeight` è **già 34
dall'A130 e il file lo dichiara scaduto**: riga 157,
`let minHeight: CGFloat = 34    // era 30 su .segMini`.

---

## §1-bis · HO MISURATO ANCHE I NUMERI, NON SOLO IL CODICE

**[A] Il mandato non è una fonte, e non lo è nemmeno per i numeri.** I valori
54 / 8 / 14 / 1,12 vengono da CD, non dal referee: li ho letti nel freeze **rev4**,
che è la fonte corrente.

**[M]** `DESIGN/QLive_Nav/2026-08-20_QLive-Shows_rev4__…390x844.html`:

```css
:121  .navbar{flex:0 0 auto;display:flex;align-items:center;padding:0 14px;}
:123  .frame.v3 .navbar{height:50px;flex:0 0 50px;justify-content:space-between;}
:124  .frame.v4 .navbar{height:54px;flex:0 0 54px;justify-content:center;position:relative;}
:125  .frame.v4 .navbar .back{position:absolute;left:14px;top:50%;transform:translateY(-50%);min-height:44px;padding:0 4px;}
:126  .dhead{padding:8px 18px 14px;}
:127  .dhead .nm{font-size:29px;font-weight:800;letter-spacing:-0.6px;color:#fff;line-height:1.12;…}
```

⇒ **Ogni numero del mandato è confermato alla fonte.** Nessuna divergenza.

⚠️ **[M] UNA COSA CHE IL MANDATO NON MENZIONA, e che NON ho eseguito:** la rev4
`:125` prescrive anche `padding:0 4px` sul `.back`. **Nel codice non c'è.** CD
scrive in rev5 che il punto 2 è «la SPEC che si allinea al CODICE» — ma i 4px
orizzontali **non sono nel codice**, quindi quella parte è una **prescrizione
nuova**, non un allineamento. Fuori dal perimetro di 3(b), che dice «NESSUNA
MODIFICA DI COMPORTAMENTO». **Non l'ho toccato: lo dichiaro.**

---

## §2 · LE METRICHE DEL CARATTERE — NUMERI GREZZI

**Metodo dichiarato:** lettura **diretta dei byte del TTF**, senza librerie di
terze parti (nessun `fontTools` su questa macchina). Script Python che legge la
directory sfnt (`numTables` a offset 4, voci da 16 byte da offset 12) e poi i
campi alle posizioni imposte dalla specifica OpenType: `head.unitsPerEm` @18,
`hhea.ascender/descender/lineGap` @4/6/8, `OS/2.fsSelection` @62,
`OS/2.sTypoAscender/Descender/LineGap` @68/70/72.

**Controllo positivo del metodo:** `head.magicNumber` letto = **`0x5F0F3CF5`**,
il valore che la specifica impone. Se il mio calcolo degli offset fosse sbagliato,
quel campo non tornerebbe.

**File misurato:** `ios_app/QBeats/Fonts/Inter-ExtraBold.ttf`
· 344 900 byte
· sha256 `1b9fab96ffc7bca31a9d4cd4d660cce80b94695908ec7613afdece2b8cf803c2`
· **disco = blob a HEAD** (stessa impronta, verificato).

| campo | valore |
|---|---:|
| `head.unitsPerEm` | **2048** |
| `hhea.ascender` | **1984** |
| `hhea.descender` | **−494** |
| `hhea.lineGap` | **0** |
| `OS/2.sTypoAscender` | **1984** |
| `OS/2.sTypoDescender` | **−494** |
| `OS/2.sTypoLineGap` | **0** |
| `OS/2.fsSelection` | **0x00C0** |
| **bit 7 `USE_TYPO_METRICS`** | **ACCESO** |

Accessori letti nella stessa passata, non richiesti: `OS/2.version` = 4,
`usWinAscent` = 2269, `usWinDescent` = 660.

### Il dubbio di `EmptyStateKit.swift` — sciolto, e dico in che senso

`EmptyStateKit.swift:41-43` lascia aperto: *«da confermare a schermo … se CoreText
usa hhea o OS/2 typo metrics — possono differire leggermente»*.

**[M] Su questo font le due tabelle sono IDENTICHE**: 1984 / −494 / 0 in entrambe.
E `USE_TYPO_METRICS` è **acceso**, che per specifica impone comunque i valori typo.

⛔ **Sono preciso su cosa ho sciolto e cosa no.** La domanda *«quale tabella legge
CoreText»* **resta senza risposta**, e su questo font **non è nemmeno decidibile**:
nessun esperimento può distinguere due tabelle uguali. Ciò che è sciolto è la sua
**conseguenza** — qualunque tabella scelga CoreText, il numero non cambia. Il
rischio dichiarato in `EmptyStateKit` **non esiste qui**.

✅ **[M] E non esiste nemmeno nell'altro punto, dove quel dubbio morde davvero.**
`EmptyStateKit.swift:63` applica un `.lineSpacing(3.08)` **reale** su
JetBrainsMono-Regular, e a `:56-58` lo dichiara «APPROSSIMAZIONE». Misurato:
upem **1000**, hhea **1020 / −300 / 0**, OS/2 typo **1020 / −300 / 0** —
**identiche anche lì**, `USE_TYPO_METRICS` acceso. Ricalcolo su entrambe le
ipotesi: `11 × 1,32 = 14,52` ⇒ `17,6 − 14,52 = 3,08`, **esatto in tutti e due i
casi**. ⇒ **Quel valore non è un'approssimazione: è esatto.** La rettifica di quel
commento è **fuori dal perimetro di A139** — la lascio in coda, non l'ho scritta.

### L'aritmetica del punto 3(d)

```
rapporto riga/em = (1984 − (−494) + 0) / 2048 = 2478 / 2048 = 1,209961
riga NATURALE    = 29 × 1,209961                            = 35,0889 pt
bersaglio CD     = 29 × 1,12                                = 32,4800 pt
bersaglio − naturale                                        = −2,6089 pt  ⇒ NEGATIVO
```

⇒ **I miei numeri CONFERMANO la conclusione del referee.** Il naturale supera già
il bersaglio, SwiftUI sa solo aggiungere, e il pattern di `EmptyStateKit`
prescrive di non applicare nulla e di dichiararlo. **Non scatta lo stop di 3(d).**

⚠️ **[M] Due precisazioni che rendono la conclusione più forte di come è posta nel
mandato.**

**(i) Non è un fatto dei 29pt: vale a ogni corpo.** Il fattore `size` si semplifica
— `1,209961 > 1,12` è una disuguaglianza fra **rapporti**. Lo scarto resta negativo
**a qualunque dimensione**, `scaleFactor` compreso. Non c'è un iPad su cui questa
conclusione si ribalti.

**(ii) 🚨 Il difetto che CD ripara, SU iOS NON È MAI ESISTITO — e questo il mandato
non lo dice.** CD motiva l'1,12 così (rev4, risposta ⓑ): a `line-height:1.05` fra
il discendente della prima riga e il cap della seconda restano **2,34pt**, «le due
righe si sfiorano». Ma **1,05 è un valore CSS**: il CSS può **comprimere** la riga
sotto il naturale del font, iOS **no**. Su iOS la riga è **sempre stata 35,09pt**,
cioè **più larga dei 32,48 che CD chiede adesso**.

⇒ Non stiamo «rinunciando» a un miglioramento: **il freeze si sta muovendo verso
ciò che iOS già faceva**, e su iOS il cambio è a effetto zero perché il difetto era
del mock HTML. **[A] È la differenza fra «non possiamo farlo» e «non c'è niente da
fare», e le due frasi invecchiano in modo molto diverso.**

---

## §3 · LE MODIFICHE — COSA HO FATTO

Diff completo: `HANDOFF/DIFF_2026-08-21_A139-NAVBAR54-DETTAGLIO.txt`
· 176 righe
· sha256 `adf608e3ea67dde06b6dfdc9150029254e5574cc4f028b66168a22e0ee1e21c6`
· **2 file, +95 / −15**.

| # | cosa | righe di CODICE toccate |
|---|---|---|
| (a) | `navbar` → ZStack, seg centrato, back a sinistra, 50→**54** | sì |
| (b) | `backButton` | **solo commento** |
| (c) | `dhead` padding top 6→**8**, bottom 10→**14**, fianchi **18 invariato** | sì |
| (d) | interlinea | **solo commento — zero codice** |
| (e) | `hitExpansion` `.segMini` | **solo commento** |

### (a) come l'ho costruita, e perché è lo stesso meccanismo

```swift
        ZStack {
            RoomSwitchBar(active: .qLive, onHome: {}, variant: .segMini)
            HStack {
                backButton
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .padding(.horizontal, 14)
```

Identico al ramo `.full` (`RoomSwitchBar.swift:43-64`): stesso ZStack, stesso
ordine dei tre modificatori, `.padding` ultimo/esterno. **Nessun secondo modo di
fare la stessa cosa introdotto.** La ragione dell'ordine **non l'ho duplicata**:
il commento la cita dove già vive (`RoomSwitchBar.swift:50-61`).

**[M] Precondizione verificata, non assunta.** Il commento di `.full` avverte che
senza un genitore che proponga la larghezza piena lo ZStack collassa
sull'intrinseca. Misurato: il genitore è `QLiveShowDetailView.swift:106-112`,
`VStack(spacing: 0)` con `.frame(maxWidth: .infinity, maxHeight: .infinity)` dentro
un `GeometryReader`. ⇒ la larghezza piena **è** proposta.

### §6 · LA RAGGIUNGIBILITÀ DEL TASTO «SHOWS» — la verifica richiesta

**[M] Non è intaccata, ed è per costruzione, non per fortuna.**

1. **Ordine dei figli.** In uno `ZStack` vince il **sibling successivo**. Il
   segmento sta **primo** (sotto), `HStack { backButton ; Spacer() }` **secondo**
   (sopra) — lo stesso ordine di `.full`, dove `homeButton` sta sopra. ⇒ in
   qualunque sovrapposizione il tocco va al **back**, mai al segmento. Invertendoli
   si regalerebbe l'unica uscita a un componente `INERTE`: l'ho scritto nel
   commento perché non venga invertito per estetica.
2. **Lo `Spacer()` non ruba nulla.** L'`HStack` sopra riempie la larghezza, ma
   l'area sensibile di un `Button` è quella della sua label + `.contentShape`, e lo
   `Spacer` non ha gesto. ⇒ il segmento sotto resta raggiungibile dov'è scoperto
   (e comunque è `INERTE`).
3. **Il bersaglio cresce, non cala.** `minHeight: 44` invariato dentro una barra
   che passa da 50 a 54 ⇒ margine da **3pt a 5pt per lato**. Nessun tocco può
   atterrare fuori dai bounds di un antenato.
4. **`onBack` non è toccato**, né `minHeight`, né `.contentShape`.

⛔ **[A] Ma la verità è il device.** Questa è una verifica **statica**, ed è
esattamente ciò che il gate S3 del 14/07 ha già smentito una volta su questo stesso
componente: allora la lettura statica diceva «l'espansione c'è» e il device disse
no. **Il collaudo va rifatto sul telefono**, e finché non è fatto questo punto è
**argomentato, non provato**.

---

## ⚠️ OLTRE LA LETTERA DEL MANDATO — DUE RIGHE, DA RATIFICARE O RESPINGERE

**[A] Le dichiaro separate perché il §3 dice «SOLO QUESTE, NESSUN'ALTRA».** Sono
due intestazioni `// MARK:` che (a) e (c) rendono **false nello stesso commit**.
Ognuna è **una riga** e si respinge in una riga.

| # | file | da | a |
|---|---|---|---|
| M1 | `QLiveShowDetailView.swift` | `MARK: - Navbar (§CSS .navbar: height 50, padding 0 14)` | `MARK: - Navbar (§CSS .frame.v4 .navbar: height 54, padding 0 14, seg centrato)` |
| M2 | `QLiveShowDetailView.swift` | `MARK: - Dhead (§CSS .dhead padding 6/18/10 · …)` | `MARK: - Dhead (§CSS .dhead padding 8/18/14 · …)` |

**Perché le ho scritte invece di solo segnalarle:** citano il freeze **rev3**, che
la rev4 SUPERSEDE, e stanno **a due righe** dal codice che le smentisce. Il mandato
stesso, ai punti (b) ed (e), stabilisce il principio «riparo i commenti che questa
modifica rende falsi»: queste due sono la stessa classe di oggetto. **Il referee
ne ha contate due; sono quattro.**

**Se il referee le respinge**, tornano indietro in due sostituzioni e il resto del
diff non cambia.

---

## 🚨 DUE PUNTATORI GIÀ SCADUTI A HEAD — MISURATI, NON TOCCATI

**[M] Non li ho rotti io: erano già falsi prima del mio cambiamento.** Trovati
sweepando i riferimenti `file:riga` che le mie inserzioni spostano (+68 righe in
`QLiveShowDetailView`, +12 in `RoomSwitchBar`).

⛔ **Li ho lasciati intatti**, perché non sono in (a)-(e) e uno dei due sta in
`startfoot`, esplicitamente fuori perimetro. Le misure sono qui, la sostituzione è
pronta.

### P1 — la lezione del gate device

`QLiveShowDetailView.swift`, blocco `backButton`, cita `RoomSwitchBar.swift:152-164`
per *«un `.contentShape` fuori dal Button appartiene a una vista senza gesto e resta
inerte»*.

**[M] A HEAD, a 152-164 c'è tutt'altro**: le cinque `let` di misura, il `FIX 4-bis`
e il refuso corretto in A129. La lezione citata sta a **`185-190`**
(`── GATE DEVICE S3 2026-07-14: FALLITO…` a 185, `.contentShape esteso apparteneva
al wrapper` a 188). **Scarto: ~33 righe, già a HEAD.** Dopo il mio cambiamento:
**197-202**.

### P2 — la tecnica mask-su-strip-2pt

`QLiveShowDetailView.swift:422`, blocco `startfoot`, cita
`RoomSwitchBar.swift:182-204` per *«la tecnica mask-su-strip-2pt»*.

**[M] A HEAD, 182 è dentro il commento sull'overlap orizzontale e 204 è un
`.textCase(.uppercase)`.** La tecnica vera sta a **`216-235`**
(`FIX 3 (referee): CSS inset 0 1px 0…` a 216, `.mask(` a 229). **Scarto: ~34 righe,
già a HEAD.** Dopo il mio cambiamento: **228-247**.

⚠️ **[A] Perché contano più dei due numeri.** Sono **deriva**, non errori d'origine:
A129 e A130 hanno inserito righe sopra e nessuno ha rimisurato i puntatori a valle.
È lo stesso meccanismo che produrrà il prossimo. **Un puntatore `file:riga` senza
ancora al commit è un numero che marcisce.** La forma ancorata già in uso —
`QLiveShowDetailView.swift:50 @ 321293e18094d9d4f1c167bfc921be1ad216e3ac`
(`LIBRO:356`) — **non marcisce**, ed è infatti l'unica che ho trovato ancora valida.

---

## ⚠️ QUATTRO PUNTATORI NEI CANONICI CHE QUESTO DIFF SPOSTA

**[M] Fuori perimetro (è materia di un giro doc), ma se il commit passa diventano
falsi.** `BUGS_QBEATS.md` cita **senza ancora al commit**:

| dove | puntatore | a HEAD | dopo il commit |
|---|---|---|---|
| `BUGS:412` `:422` `:438` `:1127` | `QLiveShowDetailView.swift:127` | la riga `RoomSwitchBar(...)` | **:144** |
| `BUGS:426` | `QLiveShowDetailView.swift:120-127` | l'`HStack` della navbar | ⛔ **non esiste più**: a **143** c'è uno `ZStack`, e l'`HStack` a **145** è un altro |

✅ **Sani perché ANCORATI, verificati:** `BUGS:171`, `LIBRO:356-357`
(`…:50 @ 321293e1…`) e `LIBRO:349` (`RoomSwitchBar.swift:152-157 @ 4e4c2411…`).

⚠️ **`BUGS:416` cita `RoomSwitchBar.swift:164-171`**: il numero **regge** — la mia
modifica (e1) sostituisce 6 righe con 6 righe, zero spostamento fino a 177 — ma
**il testo puntato è cambiato**. Puntatore valido, contenuto diverso.

---

## COSA NON HO FATTO — E LO DICO

- ⛔ **Nessun commit**, nessun `git add`.
- ⛔ **Nessuna modifica di comportamento a `backButton`**: `minHeight: 44` e
  `.contentShape` sono dove erano e come erano.
- ⛔ **Nessun `.lineSpacing`**, nessun `NSParagraphStyle`, nessun
  `AttributedString`, nessun `UIViewRepresentable`.
- ⛔ **`hitExpansion` non toccato**: la riga
  `variant == .full ? (54 - minHeight) / 2 : 0` è identica a HEAD.
- ⛔ **Non toccati:** `.roomseg` / `.opt`, l'inerzia del selettore, il
  `.viewtoggle`, `.scrhead`, `core_engine/`.
- ⛔ **`EmptyStateKit.swift` NON toccato**, benché la mia misura provi che la sua
  «APPROSSIMAZIONE» a `:56` è in realtà esatta.
- ⛔ **Non toccato il `padding:0 4px`** che rev4 `:125` prescrive sul `.back`.

## CONTROLLI DI INTEGRITÀ SUL DIFF

| controllo | esito |
|---|---|
| a-capo dopo la scrittura | `CR = LF` su entrambi (526 · 278) ⇒ **CRLF uniforme, zero righe miste** |
| bilancio graffe, dopo | `{` = `}` su entrambi |
| bilancio graffe, a HEAD (controllo positivo) | `{` = `}` su entrambi |
| variazione graffe sul dettaglio | 49 → **50** coppie: **+1**, esattamente lo `ZStack` aggiunto |
| caratteri sperduti | zero — avevo introdotto un refuso unicode (`\u1f6a8` invece di `\U0001F6A8`, che rendeva una lettera greca): **trovato e corretto prima della consegna**, verificato con sweep sul blocco greco |

⛔ **Non compilato.** Su questa macchina non c'è Xcode: la prova di compilazione è
`iOS Signed Build` **dopo** il commit. I controlli qui sopra sono **necessari, non
sufficienti**.

---

## IN CODA — non fatto, non autorizzato qui

1. **P1 e P2**, i due puntatori scaduti nel codice (sopra, coi valori pronti).
2. **`BUGS:412/422/426/438/1127`** da riancorare — preferibilmente alla forma
   `file:riga @ sha`, l'unica che non marcisce.
3. **`EmptyStateKit.swift:56-58`**: «APPROSSIMAZIONE» → misurata **esatta**.
4. **CD chiede di incidere il rischio inverso** (rev5, Ritiro 2, verbatim):
   *«chi avesse "conformato" il codice alla rev3 avrebbe rotto l'unica uscita della
   schermata. Il codice non è sempre quello indietro.»* Non è nei canonici.
5. **`padding:0 4px` sul `.back`** (rev4 `:125`): prescritto da CD, assente dal
   codice, non è un «allineamento di spec al codice» come dice rev5. Serve una
   decisione.
6. **Il collaudo device** della raggiungibilità di «Shows» dopo lo ZStack.

---

## DOVE HO SCRITTO — dichiarato da me, come chiede il §5

**[M] Verificato che i file esistono dopo la scrittura.**

| gamba | percorso |
|---|---|
| repo | `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\` |
| mirror `E:` | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` |

Due file per gamba: `MISURE_CC_2026-08-21_A139-NAVBAR54-DETTAGLIO.md` e
`DIFF_2026-08-21_A139-NAVBAR54-DETTAGLIO.txt`.

⚠️ **R-δ: questa consegna arriva a DUE GAMBE SU TRE.** La gamba **Drive** (`I:`) è
**raggiungibile** — verificata in questo giro — ma il mandato **non autorizza a
scriverci**. ⇒ **Per la lettera di R-δ questo referto è SCRITTO, NON CONSEGNATO**,
e non lo nascondo dietro un «propagato».

---

*A139-FINE*
