# DESIGN SYSTEM — Q-BEATS

> **Scopo:** ricostruire *esattamente* lo stile grafico dell'app. Tutto ciò che serve per la grafica:
> colori, font, sistema responsive, componenti, regole semantiche, principi cardine.
>
> **Stato:** consolidamento CC al **27/06/2026**, ancorato alle risposte di CD (in `…/DA_CD_PER_CC/27_06_2026/`)
> e al codice (`QStageKit.swift`, `SongListView.swift`, `LiveView.swift`). La fonte canonica a monte resta
> il design-system di CD; questo file è la versione operativa allineata — se CD aggiorna, si riconcilia qui.
> **Unica copia (no mirror).**

---

## INDICE
1. [Principi cardine](#1-principi-cardine)
2. [I due ambienti](#2-i-due-ambienti)
3. [Palette colori](#3-palette-colori)
4. [Tipografia (font)](#4-tipografia-font)
5. [Sistema responsive (scaleFactor)](#5-sistema-responsive-scalefactor)
6. [Componenti — specifiche](#6-componenti--specifiche)
7. [Colori semantici / stati](#7-colori-semantici--stati)
8. [Regole d'oro e divieti](#8-regole-doro-e-divieti)
9. [Stato implementazione](#9-stato-implementazione)

---

## 1. PRINCIPI CARDINE

- **"Come l'ha disegnata CD, non il look Apple."** → font **Inter**, **mai SF Pro**.
- **Due ambienti, due fondali** (vedi §2): Q-Stage = **blu notte**, Q-Live = **neutro/antracite**.
- **L'ambra è sacra:** `#f5b820` = **azione primaria** (FAB +) e **stato attivo** (tab attiva). Mai per utility secondarie.
- **Il blu è il "selezionato":** `#2a6bd6` = stato selezionato generico in Q-Stage.
- **Terna accenti per-modulo:** ogni modulo ha il suo accento — **Q-Stage blu** `#2a6bd6` · **Q-Live arancio** `#d43f00` · **Q-Studio teal** `#17a8a8` — ognuno col suo `-tint` (regola simmetrica, §3.4).
- **Il verde è uno STATO, non un colore "attivo":** `#28cd41` ha **solo 3 usi semantici** (§7). Non usarlo mai come generico "selezionato".
- **Inter solo per 2 testi "umani":** titolo schermata + nome brano. **Tutto il resto = JetBrains Mono** (label, dati, meta, crumb, tab, chip, contatori, status bar).
- **Responsive solo via `scaleFactor`** (§5). **Vietati** Dynamic Type, `@ScaledMetric`, `preferredFont`, `sizeCategory`.

---

## 2. I DUE AMBIENTI

| Ambiente | Quando | Fondale | Note |
|---|---|---|---|
| **Q-Stage** | "fuori dal play" — authoring: Songs / Shows / Media / Editor | **BLU NOTTE `#0c1024`** | card blu su fondo blu notte = coerente |
| **Q-Live** | sul palco, durante l'esecuzione | **NEUTRO `#0e0e10`** (antracite) | l'unico posto col neutro |

⚠️ Errore storico: si era usato il neutro `#0e0e10` anche in Q-Stage. **Sbagliato** — Q-Stage è blu notte.

---

## 3. PALETTE COLORI

### 3.1 Q-Stage (blu notte) — token canonici
```
--bg:        #0c1024   /* sfondo schermo · BLU NOTTE */
--surface:   #141832   /* card · contenitore gear */
--surface2:  #1c2248   /* superficie più chiara (raro) */
--line:      rgba(255,255,255,0.08)   /* bordo card / gear / tabbar */
--line2:     rgba(255,255,255,0.14)   /* bordo più marcato */
--text:      #ffffff                  /* titolo schermata, nome brano */
--text2:     rgba(255,255,255,0.55)   /* sottotitolo, meta, icona gear, back */
--text3:     rgba(255,255,255,0.30)   /* crumb, tab inattiva */
--blue:      #2a6bd6   /* accento Q-Stage · stati selezionati */
--amber:     #f5b820   /* azione primaria (FAB +), tab attiva */
--green:     #28cd41   /* chip IN SYNC (stato) */
--stop:      #ff3b30   /* BLOCKED / distruttivo */
--ink:       #11131a   /* glifo "+" scuro sulla FAB ambra */
```
Testo-su-tint: **blu chiaro `#9cc0f5`** = **`--blue-tint`** (tint dell'accento blu, §3.4 — **doppio uso:** è anche il testo-su-blu degli stati selezionati §7, *stesso identico valore*). **Verde chiaro `#7fe39a`** = companion di `--green` (pre-esistente, solo-doc / mai in codice; **NON** parte della terna §3.4).
Bezel device (fuori schermo, mockup): `#050507`.

Gradiente FAB ambra: `linear-gradient(150deg, #ffd35a → #f5b820)`.

### 3.2 Q-Live (palco) — neutro
```
--bg (Live): #0e0e10   /* antracite · SOLO Vista Q-Live */
```
*(La palette completa di Q-Live vive nelle view `UI/Live/`; va sorgentata da lì se serve ricostruirla — questo doc copre soprattutto Q-Stage.)*

### 3.3 Mappa in codice
`enum QStageTheme` in `ios_app/QBeats/UI/QStage/QStageKit.swift`. Colori via `Color(hex:)` (`Extensions/Color+Hex.swift`).
Alias storico: `QStageTheme.accent` = `--amber`.

### 3.4 Accenti per-modulo (terna simmetrica) + regola `-tint`
> Ratificato 28/06 — Mauro: 3 moduli (terna accenti); referee: regola `-tint` **simmetrica** = canon DS. Usati nella **Home** (trivio 3 porte).

**Ogni modulo ha un accento + il suo `-tint`** — il `-tint` è il foreground leggibile (testo/glifo) sul fill a bassa opacità di quell'accento, **hand-tuned al valore** (NON una formula lighten):

```
ACCENTO (base)               -TINT
--blue    #2a6bd6  Q-Stage    --blue-tint    #9cc0f5   (già in §3.1 · doppio uso, sotto)
--orange  #d43f00  Q-Live     --orange-tint  #ff8a5c   [NUOVO 28/06]
--teal    #17a8a8  Q-Studio   --teal-tint    #5fc8c8   [NUOVO 28/06]
```

- **`--orange #d43f00` = asserzione di BRAND Q-Live** (ratifica prodotto/naming, *non* semplice tokenizzazione tecnica): è il colore-marchio di Q-Live, finora hardcoded (`BivioBoardView.swift:43` + viste `UI/Live/`). Diventa token **condiviso** → riferire questo, non duplicare. *(La palette palco hardcoded `#16161a`/`#0e0e10` resta debito a sé → ticket BUGS, fuori da questo fronte.)*
- **`--blue-tint #9cc0f5` = doppio ruolo, stesso token:** (a) tint dell'accento blu (§3.1) · (b) testo-su-blu degli stati selezionati (§7). Verificato **byte-a-byte 28/06: DS:67 == DS:199** → un ritocco al tint muove *entrambi*, di proposito. Resta **sync codice↔doc**, non token nuovo da ratificare.
- **Gradiente porta attiva (Home):** mock CD = `linear-gradient(150°, rgba(accent,0.20)→0.05)`; **resa SwiftUI = `.topLeading→.bottomTrailing` (≈135°)** = stessa convenzione del FAB (`SongListView.swift:84`). Il DS **non impone un 150° preciso** che il codice non rende (gap CSS↔SwiftUI; le annotazioni FAB "150deg" a §3.1/§6.3 portano lo stesso scarto pre-esistente → fix doc separato, **non** in questo fronte). Q-Studio (COMING SOON) = nessun gradiente: sfondo **trasparente** + bordo **tratteggiato** `rgba(255,255,255,0.16)`.
- **Mappa codice:** i token `orange` · `teal` · `orange-tint` · `teal-tint` (+ `blue-tint` di sync) si aggiungono a `QStageTheme` con la **diff Home** (il codice oggi non li ha).

---

## 4. TIPOGRAFIA (FONT)

**Due sole famiglie:**
- **Inter** (proporzionale, licenza OFL/libera) — i 2 testi "umani".
- **JetBrains Mono** (monospace) — tutto il resto.
- **MAI SF Pro. MAI Dynamic Type.**

### 4.1 Regola d'uso (vale per tutta l'app)
> **Inter SOLO per: titolo schermata + nome brano + nomi-modulo della Home (Q-STAGE / Q-LIVE / Q-STUDIO). Tutto il resto = JetBrains Mono.**
>
> *(Estensione 28/06: i nomi-modulo della Home sono destinazioni = classe-titolo, coerenti col titolo «Songs» → Inter ExtraBold. Il wordmark «Q-BEATS» è **logotipo**, resta JetBrains Mono.)*

### 4.2 Pesi Inter (PostScript)
```
Inter-Regular (400) · Inter-Medium (500) · Inter-SemiBold (600)
Inter-Bold (700) · Inter-ExtraBold (800) · Inter-Black (900)
```

### 4.3 Registrazione (XcodeGen)
- File `.ttf` in **`ios_app/QBeats/Fonts/`**.
- Elencati in **`UIAppFonts`** in `ios_app/project.yml` **e** `ios_app/QBeats/Info.plist`.
- Helper JetBrains: `Font.jbMono(.weight, size:)` (`Extensions/Font+JBMono.swift`). Inter via `.custom("Inter-…", size:)`.
- ⚠️ Se un `.custom("Inter-…")` non è registrato → iOS **ripiega in silenzio** sul font di sistema.

### 4.4 Scala tipografica — Songs (riferimento, pt @390)
| Elemento | Font | Size · peso · tracking |
|---|---|---|
| Titolo "Songs" | **Inter** | 30 · ExtraBold(800) · −0.6 · line-height 1.0 |
| Nome brano (card) | **Inter** | 17 · SemiBold(600) · −0.2 |
| Sottotitolo "N songs in catalog" | JetBrains | 12 · Medium · ls 0.5 · `--text2` |
| Riga meta "N sections · BPM · 4/4" | JetBrains | 11 · Medium · ls 0.3 · `--text2` |
| Crumb header "Q-STAGE" | JetBrains | 10 · UPPER · ls 2.5 · `--text3` |
| Back "HOME" | JetBrains | 12 · Medium · `--text2` |
| Label tabbar (SONGS/SHOWS/MEDIA) | JetBrains | 10 · 600 · UPPER · ls 1.5 |
| Chip "IN SYNC" | JetBrains | 10 · 700 · ls 0.5 |
| Status bar | JetBrains | 14 · 600 |

---

## 5. SISTEMA RESPONSIVE (scaleFactor)

**Unico schema ammesso.** Baseline = **iPhone 13 = 390pt** (i px dei mock di CD = punti 1:1 a 390).

```swift
GeometryReader { geo in
    let scaleFactor = geo.size.width / 390   // pattern di riferimento: LiveView.swift:82
    // ogni size / padding / tracking:  valore_pt * scaleFactor
    Text("Songs").font(.custom("Inter-ExtraBold", size: 30 * scaleFactor))
}
```
- Si passa `scaleFactor` giù come parametro alle sotto-view (es. `QStageNavBar(..., sf:)`).
- **Tutto** scala: font, padding, frame, corner radius, tracking, ombre.

---

## 6. COMPONENTI — SPECIFICHE (pt @390)

### 6.1 Nav-bar custom (header Q-Stage)
```
altezza        : 50      (la status bar di sistema sopra = 44, separata)
padding-h      : 16
crumb (centro) : JetBrains 10 · UPPER · ls 2.5 · --text3
back (sinistra): chevron.left + label · JetBrains 12 · --text2
trailing       : opzionale (es. "SAVE" ambra); nav-bar nativa SEMPRE nascosta
```

### 6.2 Card brano
```
bg       : --surface (#141832)
bordo    : 1px --line
radius   : 16
padding  : 14 verticale · 16 orizzontale
gap card : 11 (tra card adiacenti)
highlight: box-shadow inset 0 1px 0 rgba(255,255,255,0.04)  (rifinitura, top)
```

### 6.3 FAB "+" (azione primaria)
```
size     : 44×44 · radius 14
fondo    : gradiente 150° #ffd35a → #f5b820
glow     : box-shadow 0 6px 18px rgba(245,184,32,0.25)
glifo    : "+" · stroke --ink (#11131a, scuro) · ~22pt · sw 2.6
```

### 6.4 Glifo ⚙ header (ingresso Settings)
```
container: 38×38 · radius 11 · bg --surface · bordo 1px --line
simbolo  : SF Symbol "gearshape" · ~18pt
tint     : --text2  (NON ambra — è utility secondaria)
area-tap : ≥ 44×44 (estendi l'hit oltre il visibile)
```
⚠️ Destinazione = schermata Settings (governance/IA da confermare; oggi è un fronte a parte).

### 6.5 Tab bar a 3 linguette (custom, NON la `UITabBar` di sistema)
```
larghezza : full-bleed edge-to-edge (inset 0) · raggio 0
altezza   : 66 totali  (~58 contenuto + cuscinetto safe-area; àncora alla safe-area inferiore)
fondo     : rgba(10,12,26,0.82) + blur 18  (frosted — serve contenuto sotto)
bordo     : 1px --line solo in alto
tab       : 3 terzi uguali · icona sopra, label sotto · gap 5
attiva    : --amber (icona+label)      inattiva: --text3
label     : JetBrains 10 · 600 · UPPER · ls 1.5
icone     : 20×20 (Songs/Shows/Media)
```

### 6.6 Chip stato (IN SYNC / NEEDS SYNC)
Stile: `--green` (in-sync) — JetBrains 10 · 700. **Solo aspetto in questa fase**; la *funzione* è la validazione setlist (in standby), non si accende con la grafica.

### 6.7 Misure canoniche (anti ±2px tra file)
```
status bar : 44     nav : 50     content padding : 16     tab bar : 66
```

---

## 7. COLORI SEMANTICI / STATI

- **Attivo/selezionato generico = BLU** `#2a6bd6` → fill `rgba(42,107,214,0.22)` · testo `#9cc0f5` (= **`--blue-tint`**, stesso token §3.4 — un ritocco al tint muove anche questo) · bordo `rgba(42,107,214,0.4)`.
- **Verde `#28cd41` = SOLO 3 usi** (stati/dati che già esistono, solo colore):
  1. **Accenti del metronomo** (caselle accenti Editor Sezione + mini-preview sulle card) — token TD #26.
  2. **Chip di stato**: `IN SYNC`, `PRONTA`, `BASE · IN SYNC`.
  3. **Segmentato "modalità click/sync"** (schermata Media & Sync).
- **Editor** (Count-in Off/1/2, Avvio Standby/Parte-subito, selezione sezione) = **BLU**, *non* verde.
- **Rosso `--stop` `#ff3b30`** = BLOCKED / azione distruttiva.

---

## 8. REGOLE D'ORO E DIVIETI

✅ **Fare**
- Colori **al valore** dai token (mai "a occhio").
- Responsive **solo** via `scaleFactor = larghezza/390`.
- Inter solo titolo-schermata + nome-brano; resto JetBrains.
- Ambra = azione primaria/attivo · Blu = selezionato · Verde = i 3 stati.

🚫 **Non fare**
- **SF Pro** (mai).
- **Dynamic Type / `@ScaledMetric` / `preferredFont` / `sizeCategory`** (mai).
- Verde come "selezionato generico".
- Neutro `#0e0e10` in Q-Stage (è solo di Q-Live).
- Mirror di questo file (evita copie stale).

---

## 9. STATO IMPLEMENTAZIONE (27/06/2026)

| Pezzo | Stato |
|---|---|
| `QStageTheme` → palette blu notte | ✅ in codice (in attesa ratifica/commit) |
| Songs — grafica completa | ✅ costruita (diff, in attesa: `.ttf` Inter + ratifica + commit + device) |
| Home (trivio 3 porte Studio/Stage/Live) | 🔜 prossima diff — rinomina Bivio→Home + 3 porte (terna §3.4) |
| Terna accenti + `-tint` (`orange`/`teal`/`orange-tint`/`teal-tint`, +`blue-tint` sync) | ⏳ ratificati 28/06 — da scrivere in `QStageTheme` con la diff Home |
| File font Inter (`Fonts/`) | ⏳ da aggiungere (6 pesi) — registrati in plist, mancano i `.ttf` |
| Barra a 3 linguette custom | 🔜 da costruire (spec §6.5; oggi = pill di sistema) |
| ⚙ Settings nell'header | 🔜 fronte a parte (la schermata Settings esistente è orfana + diversa) |
| Editor — grafica (blu/verdi) | 🔜 prossima diff |
| Q-Live — già a stile | ✅ (neutro, già sul palco) |

---

*Autore consolidamento: CC · 27/06/2026 · **agg. 28/06**: terna accenti per-modulo + regola `-tint` simmetrica (§3.4) + riga Home (§9). Ancorato a risposte CD + codice repo. Aggiornare qui ad ogni token nuovo ratificato.*
