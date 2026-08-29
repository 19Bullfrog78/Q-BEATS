# Q-BEATS — BOX 5 — Specifiche e Contratti
**Versione:** V37 — 29/08/2026

> **Regola di aggiornamento:** aggiornare BOX5 quando cambiano spec, modello dati, token visivi, o invarianti Layer 3. NON aggiornare per avanzamento build o fix — quello va in BOX3.

**Delta V31 vs V30:**

- **Due regole NUOVE nel capitolo R-δ, nessuna delle quali esisteva prima.** **(a)** quando la data che un documento dichiara di se' e quella del suo commit divergono, nel nome della stampa d'archivio va la **prima**: lo sha7 identifica gia' il commit. Prima occorrenza reale `9edc120` (documenti datati 22/08, commit del 23/08). **(b)** le **stringhe di controllo d'integrita'** si scelgono copiandole da **una riga sola**, oppure la sonda gira sul testo **appiattito**: una stringa a cavallo di un a capo rende ZERO su un file integro. Regola nata da **quattro** falsi allarmi in due giorni (A182, A185, A187, A190).

Tutto il resto invariato da V30.

**Delta V30 vs V29:**

- **Capitolo NUOVO «VOCABOLARIO DEI DUE OROLOGI».** Lessico che separa il conteggio del motore audio da quello della grafica, e nomina i due punti dove lo scarto si vede (ACCENTO AUDIO / ACCENTO GRAFICO dentro la battuta; CAMBIO SEZIONE AUDIO / CAMBIO SEZIONE GRAFICO fra le sezioni). **Tutti e sei i nomi sono ratificati da Mauro il 22/08/2026** (mandati A176 + A178). Cinque su sei erano stati proposti diversamente dal referee e corretti da Mauro prima della ratifica: OROLOGIO MOTORE AUDIO (era «orologio motore»), ACCENTO AUDIO (era «accento sonoro»), ACCENTO GRAFICO (era «primo verde»), CAMBIO SEZIONE AUDIO (era «cambio suonato»), CAMBIO SEZIONE GRAFICO (era «cambio scritto»). Solo OROLOGIO GRAFICA è rimasto come proposto.

Tutto il resto invariato da V29.

**Delta V29 vs V28:**

- **Capitolo NUOVO «R-δ — dove vanno i file».** Prima di V29 il regime di consegna non aveva una sede operativa: viveva sparso nei mandati, e fra il 20 e il 21/08/2026 l'indirizzo Drive e' cambiato **tre volte in tre mandati, in direzioni opposte**. Il capitolo dichiara **quattro destinazioni e due sole scritture**: `C:` e `E:` si scrivono, git arriva col push, **Drive arriva da solo** come riflesso di `E:` sotto «Il mio computer». Le righe `LIBRO_MASTRO_QBEATS.md:336` e `:346` non si riscrivono: si circoscrivono. Il capitolo contiene anche il **cartello di rettifica su A159**.

- **⚠️ MARCATURA sul Delta V26 — il bullet «Canonici NON tracciati» e' SCADUTO.** Non e' riscritto: e' marcato in loco. La SCALETTA, unico soggetto rimasto a quel regime, e' tracciata dal **18/07/2026**; oggi **nessun canonico e' non tracciato**, quindi il secondo regime non ha piu' soggetto.

Tutto il resto invariato da V28.

**Delta V28 vs V27:**

- **Capitolo NUOVO «Q-Live › Shows».** Prima di V28 BOX5 non conteneva nulla sulla stanza Q-Live: misurato a fonte sul blob `9a0243447dd04e41930c70c48ff26acf400278d6` (BOX5 V27 a `4b55686c04e3bd14ccf06c31b5e89e74a38341ab`), le stringhe `QL-SHOWS`, `Q-Live`, `Remove`, `Q20` e `alert` rendono **0** tutte e cinque **in quattro notazioni** (righe / occorrenze × sensibile / insensibile al caso); controlli positivi sullo stesso file: `Q-Stage` 5 · `Token` 4 · `metronomo` 5 (righe, insensibile al caso) · `BOX5` 11 (occorrenze). Il capitolo raccoglie il contratto delle dieci righe QL-SHOWS, la forma della riga, il congedo tastiera, il menu «···» e «Remove from Q-Live».

- **⚠️ IL CATALOGO DEI TOKEN COLORE NON ENTRA IN V28 — va in V29.** La sezione «Token visivi — UNICA FONTE DI VERITÀ» resta invariata da V22, byte per byte. Ratifica Mauro 28/07; il motivo è già inciso in `BUGS_QBEATS.md` v44: «Il catalogo completo dei token va misurato contro il codice a HEAD prima di essere inciso — atomo a sé, non in coda a un'altra consegna.» **Conseguenza sulla citazione:** il deliverable CD `2026-07-27_BOX5-V28__Token-Colore-PAYLOAD.md` porta nel proprio nome una versione che NON lo contiene. Il payload resta valido e **non si riemette**; il suo bersaglio è **V29**. Chi lo cita scriva V29, non V28.

- **Nessun nome d'atomo nel capitolo.** Il capitolo descrive il **comportamento dello schermo**, non il calendario di costruzione: nessuna etichetta d'atomo compare, nemmeno dove le fonti la portano — quella che le fonti usano più spesso è sotto disambiguazione (tre lavori distinti la portano), e chi-costruisce-cosa vive nella SCALETTA. Dove una fonte formula una clausola come sequenza («prima si costruisce X, poi Y»), qui se ne incide il **contenuto** — che cosa fa lo schermo, e che cosa a HEAD non esiste — mai la sequenza. La sostituzione è dichiarata riga per riga dove avviene, così che nessun «verbatim» copra un testo trasformato in silenzio.

Tutto il resto invariato da V27.

**Delta V27 vs V26:**

- **BOX3 e BOX5 escono dai «canonici NON tracciati» ed entrano nei TRACCIATI** — commit `edaa80f`, 21/07/2026. Da lì vivono in root come `BOX3_QBEATS.md` e `BOX5_QBEATS.md`, tracciati in git, con `-text` in `.gitattributes`. Si modificano **in place**: il diff si legge riga per riga e le versioni precedenti stanno nella storia git, non in un file separato. Il bullet «Canonici NON tracciati» del Delta V26 è riscritto di conseguenza e resta valido per la sola SCALETTA. Per BOX3/BOX5 vale ora la **prescrizione** del bullet «Canonici TRACCIATI» — estrarre dal blob con `git show <commit>:<path>`, mai copiare dal file di lavoro — ma **non la motivazione scritta lì**: vedi la rettifica qui sotto.

- **RETTIFICA 21/07/2026 — il messaggio di commit di `edaa80f` motiva male il proprio vincolo.** Quel messaggio afferma che seguire il vecchio bullet «Canonici NON tracciati» produrrebbe, per BOX3/BOX5, la corruzione silenziosa descritta nel bullet dei tracciati. **È falso, e la rettifica vive qui perché un messaggio di commit è pushato e non si corregge.** Quella corruzione nasce dal divario CRLF-su-disco / LF-nel-blob, che è reale per `LIBRO_MASTRO_QBEATS.md` e `BUGS_QBEATS.md` ma **non esiste per BOX3 e BOX5**: lo stesso commit `edaa80f` ha messo `-text` su entrambi, e disco e blob coincidono al byte (verificato). Una copia dal disco non li corromperebbe. Il difetto reale del vecchio bullet era un altro, e regge: dichiarava «non esiste blob» — falso da `edaa80f` — e prescriveva una verifica d'impronta sorgente↔destinazione **non ancorata a un commit**, cioè una copia di cui non si sa a quale stato del documento corrisponda. Il vincolo di `edaa80f` era giusto; la ragione scritta accanto no.

- **Formato dei canonici propagati a E:/project — nome PER VERSIONE, con data e commit di estrazione in coda** (ratificato Mauro 21/07/2026). Forma: `BOX3_V98_2026-07-22_edaa80f.md`. Due motivi, entrambi vincolanti. **(1)** Su E: il file è una **stampa**, non l'originale: il nome per-versione lo distingue a colpo d'occhio dal file a nome fisso che vive nel repo, ed evita di ricostruire su E: la trappola-per-nome che ha già prodotto le due `SCALETTA` omonime e divergenti. **(2)** Il commit in coda rende la stampa **verificabile**: la sua impronta deve coincidere con quella del blob a quel commit, e il controllo resta eseguibile con un comando anche fra anni. ⚠️ **L'archivio esistente non si tocca:** i file da V8 a V97 restano col nome che hanno.

Tutto il resto invariato da V26.

**Delta V26 vs V25:**

- **Formato dei canonici propagati a E:/project — due regimi, secondo il tracciamento git.**
  · **Canonici TRACCIATI** (`BUGS_QBEATS.md`, `LIBRO_MASTRO_QBEATS.md`, `HANDOFF/**`): lo snapshot si produce ESTRAENDO DAL BLOB GIT (`git show <commit>:<path>`), MAI con Copy-Item dal file di lavoro. Il file di lavoro in root è CRLF, il blob è LF: i 32 snapshot storici su E: sono tutti LF, e una copia dal disco produrrebbe l'unico CRLF in mezzo a 32 LF — corruzione invisibile, scoperta mesi dopo. La verifica confronta l'impronta con quella del BLOB, non con quella del file su disco.
  · **Canonici NON tracciati** (dal 21/07/2026 la sola SCALETTA — vive fuori da git): l'estrazione da git è IMPOSSIBILE, non esiste blob. La copia dal disco è l'unica via → la verifica è un confronto d'impronta sorgente↔destinazione (stesso sha256 alle due estremità), e il formato del file sorgente È il formato canonico per definizione. ⚠️ **Limite noto del regime, ed è la ragione per cui se ne esce appena possibile:** un'impronta sorgente↔destinazione non è ancorata a un commit, quindi certifica che la copia è fedele ma NON a quale stato del documento corrisponda. **BOX3 e BOX5 sono usciti da questa categoria con `edaa80f` (21/07/2026)** e seguono ora il bullet «Canonici TRACCIATI» qui sopra — con la qualificazione della RETTIFICA nel Delta V27: ne vale la **prescrizione** (estrarre dal blob), non la **motivazione** CRLF/LF, che per loro non si applica.
  ⚠️ **MARCATURA 21/08/2026 — QUESTO BULLET E' SCADUTO, E LO ERA GIA' QUANDO FU SCRITTO.** ⛔ **Non si riscrive: si marca qui.** La SCALETTA — unico soggetto rimasto a questo regime — **e' TRACCIATA dal commit `fe6d34b` del 18/07/2026** («SCALETTA_ATOMI_S6 tracciata in git, cambio di regime, contenuto invariato»), cioe' **tre giorni PRIMA** di `edaa80f` (21/07/2026), in occasione del quale questa frase fu scritta. ⇒ La clausola «dal 21/07/2026 la sola SCALETTA — vive fuori da git» **era gia' falsa nel momento in cui e' stata incisa**. **[M] Verificato a fonte il 21/08/2026:** `git ls-files` rende tracciati **tutti e cinque** i canonici — LIBRO, BUGS, BOX3, BOX5, SCALETTA. ⇒ **Il regime «canonici NON tracciati» non ha piu' alcun soggetto**, e la sua prescrizione — copia dal disco con confronto d'impronta — **non si applica oggi a nulla**. ⚠️ **[A] Il difetto non fu la scadenza, fu la fretta:** la frase enunciava una regola su un file di cui non era stato misurato il tracciamento, tre giorni dopo che era cambiato.
  · **Regola generale:** non si dichiara mai una propagazione «verde» senza aver confrontato un'impronta con la sorgente giusta per il regime del file. Nato 17/07/2026, dopo che un prompt di propagazione diceva «Copy-Item dal disco» per un file tracciato e sarebbe passato verde producendo corruzione silenziosa.

Tutto il resto invariato da V25.

**Delta V25 vs V24:**

- **Invariante `@Published` (riga «@Published assignment») annotato — equivalenza `@MainActor`.** Il testo storico imponeva ESCLUSIVAMENTE `DispatchQueue.main.async`. Un tipo dichiarato `@MainActor` a livello di classe (es. `QBeatsStore`) soddisfa lo stesso invariante con garanzia più forte (compile-time, non runtime) e non richiede `DispatchQueue` esplicito. Annotazione, non cambio di intento. Esito accertamento 13/07 (sha `3c1a21a0…`), verdetto referee [C]. Tutto il resto invariato da V24.

**Delta V24 vs V23:**

- **Fix package Fase D "Rafforzamento modalità Direttore" (28/05/2026):** guard start/stop e BPM estesi a tutti gli stati (`isRunning` rimosso, Bug 5 + Bug 5-BPM fix). Modello fresh play branching evoluto da 3 a 4 rami (Director standalone ratificato — chiude latenza 1.j). Rimosso claim stale "tre callback condividono guard" — ogni callback documentato separatamente. **Default LinkMode corretto da `.direttore` a `.collaborativa`** (commit `cb92faa` 24/05/2026 — BOX5 V23 lo documentava ancora erroneamente come `.direttore`). Tutto il resto invariato da V23.

**Delta V23 vs V22:**

- **Correzione baseline scaling responsive 430pt → 390pt.** V22 dichiarava erroneamente `iPhone 13 portrait = 430pt larghezza` e tutte le percentuali in BOX5 erano calcolate su 430. Misurazione empirica 18/05/2026 (commit `adfcc39` Fase 1 TD #23) con `os_log(.default, "[QBEATS][ScaleFactor] geo.size.width = %f", geo.size.width)` su iPhone 13 portrait reale ha riportato **`390.000000`**. La specifica Apple iPhone 13 portrait è 390pt, non 430 (430pt è la specifica di iPhone 14/15 Plus o iPhone 14/15 Pro Max). La calibrazione V22 era teorica e sbagliata.
- **Cambio pattern: percentuali pre-calcolate → `pt_originale * scaleFactor`.** V22 indicava per ogni callsite font la percentuale calibrata (es. `geo.size.width * 0.065`). V23 sostituisce con il pattern moltiplicativo `pt_originale * scaleFactor` dove `scaleFactor = geo.size.width / 390` calcolato una sola volta in `LiveView.swift` e propagato come parametro `CGFloat` esplicito a tutti i sub-View che ne hanno bisogno. Vantaggi: leggibilità (la pt originale resta visibile nel codice = facile cross-reference con il design), unica fonte di verità del denominatore, propagazione esplicita evita catture implicite ambigue. Esempio: `song name 28pt` → `.font(.jbMono(.bold, size: 28 * scaleFactor))` (era `geo.size.width * 0.065`).
- **`scaleFactor` propagation pattern** (V23 — NUOVO): `LiveView` calcola `scaleFactor` dentro il `GeometryReader { geo in ... }` come `let scaleFactor: CGFloat = geo.size.width / 390`. Lo passa come parametro a tutti i sub-View della Vista LIVE che hanno callsite font. ButtonStyle (es. `OverlayStopButtonStyle`) riceve `scaleFactor` come parametro all'init, NON cattura dall'ambiente. Sub-component nested (es. `MixerChannelView` dentro `MixerOverlayView`) ricevono propagazione esplicita dal parent. **Niente cattura implicita.**
- **TD #23 chiuso V63** post-test su iPhone 13 (verde pixel-identico, `scaleFactor = 1.0`) + iPad portrait (verde proporzionato, `scaleFactor ≈ 1.97` su iPad pre-2018 a 768pt). Validato empiricamente, NON più tech debt.
- **Backlog CD raccolto in sessione 17-18/05/2026** (CD-1 schermata iniziale Vista LIVE "standby vestito", CD-2 perimetro rosso pulsante standby tra canzoni, CD-3 bottone "Ricomincia setlist" a fine setlist). Da consegnare a CD nel brief Fase 4 Vista Emergenza.

Tutto il resto invariato da V22: identità progetto (iPhone + iPad universal portrait v1), modello dati, token visivi, contratti Layer 3 esistenti, specifica vincolante L1.b "Fade scatta SOLO a fine vera", Task D (chiuso V53), Limite v1 Modalità Direttore, struttura file, backlog, decisioni UX 09/05, decisioni V22 (Strada A scaling proporzionale, TARGETED_DEVICE_FAMILY universal, API vietate Dynamic Type).

---

## Identità progetto

**Q-BEATS** — metronomo e sequencer live nativo iOS per musicisti professionisti.
**iPhone + iPad universal, portrait v1.** Livello: AUM / Cubasis / Drambo.

| Voce | Valore |
|---|---|
| Bundle ID | `com.bullfrog.qbeats` |
| Team ID | `X42CX3ZP3T` |
| iCloud Container | `iCloud.com.bullfrog.qbeats` |
| iOS deployment target | 16.0 |
| **Device family v22** | **Universal — `TARGETED_DEVICE_FAMILY` non impostato in `project.yml`, default Xcode `1,2` (iPhone + iPad). Decisione esplicita V55** |
| **Orientation v1** | **Portrait obbligato su tutti i device. Landscape iPad ("Vista Bella v2") rimandato a v2 reale** |
| **Layout strategy v1** | **Stesso layout componenti per tutti i device (Strada A — scaling proporzionale). Font/spacing ≥ 20pt tramite `pt_originale * scaleFactor` con `scaleFactor = geo.size.width / 390` (V23). Strada B (layout iPad dedicato multipanel) rimandata a v2 reale** |
| Repository | `github.com/19Bullfrog78/Q-BEATS` |

**Attori:**
- **Mauro** — supervisore, decisore, tester su device (Windows-only, debug via iMazing Console)
- **Claude referee** — arbitro tecnico senior, review ogni decisione architetturale
- **Claude Code (CC)** — implementazione Swift/SwiftUI Layer 3
- **Claude Design (CD)** — wireframe, mockup, specs visive — nessun codice Swift

**Flusso handoff:** CD produce → referee valida → Mauro approva → CC implementa.

**Device:**

| Device | Ruolo | Connettore | `geo.size.width` portrait |
|---|---|---|---|
| iPhone 13 | Sviluppo e test (baseline scaling — `scaleFactor = 1.0`) | Lightning | **390pt** (misurato empiricamente 18/05/2026) |
| iPhone 15+ | Produzione | USB-C — HDMI + audio interface simultanei via adattatore | ~393pt o 430pt secondo modello |
| iPad mini / iPad pre-2018 | Target leggio piccolo | Lightning/USB-C | **768pt** (`scaleFactor ≈ 1.97`) |
| iPad mini 8.3" (2021+) | Target leggio piccolo | USB-C | **744pt** (`scaleFactor ≈ 1.91`) |
| iPad Pro 11" | Target leggio | USB-C | **834pt** (`scaleFactor ≈ 2.14`) |
| iPad Pro 12.9" | Target leggio fisso | USB-C | **1024pt** (`scaleFactor ≈ 2.63`) |

**Hardware validato:** Behringer UMC404HD (4 uscite, class-compliant) · Adattatore Ticenpe MFi Lightning→USB-A · Akai MPK Mini 3 (validato con tap tempo MIDI Learn 17/05/2026)

---

## Architettura — Strada B (INVIOLABILE)

```
LAYER 3 — Swift / SwiftUI + ObjC++ Bridge        🔄 IN CORSO
LAYER 2 — CoreMIDI C-API + Sequencer PPQN-960 + Ableton Link    ✅ CHIUSO
LAYER 1 — Core Audio C-API + C++ DSP Engine      ✅ CHIUSO
```

**REGOLA ASSOLUTA:** qualsiasi problema visivo si risolve ESCLUSIVAMENTE in Layer 3. MAI toccare Layer 1/2 per problemi di carrozzeria.

---

## Modello dati — Ratificato

(invariato da V22, vedi `ARCHIVIO.MD/12_05_2026/BOX5_V22_12_05_2026.md` sezione "Modello dati — Ratificato")

---

## AudioEngine — @Published Properties

(invariato da V22)

---

## AudioEngine — Altri membri esposti (non @Published)

(invariato da V22)

---

## MIDI Learn — Ratificato

(invariato da V22)

---

## Token visivi — UNICA FONTE DI VERITÀ

(invariato da V22)

---

## VOCABOLARIO DEI DUE OROLOGI — ratificato Mauro 22/08/2026

REGOLA UNICA: ogni cosa esiste in versione AUDIO e in versione GRAFICO.
Il difetto è SEMPRE la distanza fra le due, mai una delle due "sbagliata".

I due conteggi:
· OROLOGIO MOTORE AUDIO — il conteggio dei battiti tenuto dal motore audio.
  Riparte da zero SOLO quando il motore viene fermato e riavviato.
· OROLOGIO GRAFICA — il conteggio su cui il display costruisce battute e
  sezioni. Riparte da zero a OGNI rientro nel player.

Dentro la battuta:
· ACCENTO AUDIO — il click a frequenza diversa, prodotto dal motore audio.
· ACCENTO GRAFICO — l'accento reso dalla grafica. Oggi è il primo pallino
  verde della battuta; «primo pallino verde» è COME È RESO OGGI, non il nome
  della cosa. Se il disegno cambia, il nome resta.

Fra le sezioni:
· CAMBIO SEZIONE AUDIO — il motore comincia a suonare la sezione successiva.
· CAMBIO SEZIONE GRAFICO — il display aggiorna nome e numero della sezione.

⛔ VIETATA OGNI FORMA CON UN COLPEVOLE. Sono false due volte: nessuno dei
due orologi sbaglia — ciascuno è corretto rispetto a sé stesso — e una
frase con un soggetto attribuisce comunque la colpa a uno dei due.
⛔ Vietate quindi anche «l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO» e
«il CAMBIO SEZIONE GRAFICO non coincide col CAMBIO SEZIONE AUDIO»: hanno
un soggetto. Vietate a maggior ragione «l'accento è sfasato», «l'accento è
sbagliato», «la sezione è sbagliata».

LE FORME CORRETTE SONO SIMMETRICHE, senza soggetto:
· «ACCENTO AUDIO e ACCENTO GRAFICO NON COINCIDONO»
· «CAMBIO SEZIONE AUDIO e CAMBIO SEZIONE GRAFICO NON COINCIDONO»
Causa, da nominare sempre insieme: i due orologi sono partiti da punti
diversi. L'oggetto del difetto è LA DISTANZA FRA DUE OROLOGI.

⚠️ REGOLA DI RIPARAZIONE — asimmetrica, e non contraddice quanto sopra:
descrivere è simmetrico, riparare no. L'OROLOGIO MOTORE AUDIO è IL
RIFERIMENTO: è ciò che la band sente, gira in tempo reale, e NON SI TOCCA
per rimediare a uno sfasamento. È l'OROLOGIO GRAFICA che deve riallinearsi
su di lui. ⛔ Chiunque proponga di modificare il motore audio per far
coincidere i due deve prima superare questa riga.
Ratificato Mauro 22/08/2026.

Tutti e sei i nomi sono ratificati da Mauro il 22/08/2026. CINQUE SU SEI
erano stati proposti diversamente dal referee e corretti da Mauro:
OROLOGIO MOTORE AUDIO (era «orologio motore»), ACCENTO AUDIO (era «accento
sonoro»), ACCENTO GRAFICO (era «primo verde»), CAMBIO SEZIONE AUDIO (era
«cambio suonato»), CAMBIO SEZIONE GRAFICO (era «cambio scritto»; quei due
non erano italiano). Solo OROLOGIO GRAFICA è rimasto come proposto.

COMPORTAMENTO ATTESO AL RIENTRO NEL PLAYER — ratificato Mauro 22/08/2026.

Ragionamento di Mauro, nelle sue parole:
(1) premendo STOP prima di uscire, al rientro grafica e audio ripartono
    correttamente;
(2) NON premere STOP è una SCELTA DELL'UTENTE: significa che non vuole
    fermare l'audio, per i più disparati motivi. Il motore infatti continua
    a suonare anche nelle videate Shows e Dettaglio;
(3) ⇒ al rientro nel player, poiché l'utente ha scelto di non fermare la
    canzone, la grafica NON deve ripartire da zero: deve RECUPERARE LA
    POSIZIONE DELL'AUDIO E ALLINEARSI AD ESSO. Ripartire da zero è il
    difetto.

⇒ QUESTO È IL REQUISITO. Non è una preferenza estetica: la grafica che
riparte da zero sta ignorando una scelta esplicita dell'utente.

⚠️ PRECISAZIONE TECNICA DEL REFEREE — RETTIFICATA 22/08/2026, misurata a
`4629ee9`. Una versione precedente di questa riga diceva che il motore
«scarta la posizione senza consegnarla a nessuno» e che la grafica «non ha
modo di chiedere». ERA FALSA, e la falsificazione è di CC (referto A181),
rimisurata dal referee. In realtà:
· il DSP C++ espone un accessore PUBBLICO della posizione dentro la battuta;
· il ponte lo legge in produzione (zero compilazione condizionale nel file);
· il flag di accento per-battito ATTRAVERSA GIÀ il confine C→Swift e viene
  letto dentro AudioEngine;

⇒ CIÒ CHE MANCA È UN SOLO PASSAGGIO, L'ULTIMO: AudioEngine non ripubblica
quell'informazione alla vista — il messaggio che raggiunge la grafica a
ogni battito porta SOLTANTO il numero progressivo del battito.

⛔ CHI RIPARERÀ NON DEVE COSTRUIRE UN CANALE NUOVO: il canale esiste e
arriva già fino a Swift. Va esteso l'ultimo tratto. ⛔ E non deve toccare
il motore audio: vedi la REGOLA DI RIPARAZIONE sopra.

⛔ Questo comportamento atteso NON contraddice la simmetria della
descrizione: descrivere il sintomo resta senza colpevole (i due orologi
partono da punti diversi); il comportamento atteso e la riparazione sono
asimmetrici, e puntano entrambi nella stessa direzione — è la grafica che
si riallinea, il motore audio non si tocca.

---

## Vista LIVE — Spec complete

### Grid verticale fissa

```
8%  header
10% slot metronomo
8%  bar counter
4%  micro bar
35% giant text (teleprompter)
2%  macro bar
10% NEXT zone (ex POI)
2%  handle strip
21% transport
```

Total: 100%.

### Header

```
[ ← BACK ]  [ LED·LED·LED  {song.name}  ·  {bpm}[🔒]  ·  {time sig} ]  [ SVG MUTE ]
```

**V23 — pattern font responsive**: tutti i font in formato `pt_originale * scaleFactor` dove `scaleFactor` è propagato come parametro da `LiveView` (calcolato come `geo.size.width / 390`).

- `song.name` — JetBrains Mono 700, **28pt * scaleFactor**
- BPM — JetBrains Mono 400, **17pt * scaleFactor**. Lucchetto SVG se `backtrackFilename != nil` (opacity 0.45)
- Time sig — JetBrains Mono 400, **15pt * scaleFactor**
- Mute button top-right: SVG speaker. Attivo = onde sonore bianco 85%. Muto = barra diagonale ambra `#f5b820`. Glyph `13pt * scaleFactor`.
- Chevron back: glyph `12pt * scaleFactor`
- 3 LED 5px (pt assoluti, sotto soglia 20pt), invisibili se non attivi
- Separatori `·`: `13pt * scaleFactor`
- Lock icon: `9pt * scaleFactor`
- Stato STOPPED: aggiunge separatore `·` + label "STOP" JBMono 600, **10pt * scaleFactor** caps, opacity 0.35

**Nota V23:** le dimensioni in pt riportate sono valori baseline iPhone 13 portrait (390pt larghezza, misurata empiricamente). Su iPad le stesse pt × scaleFactor producono dimensioni proporzionalmente maggiori (≈ 1.97× su iPad pre-2018, ≈ 2.63× su iPad Pro 12.9"). Calibrazione finale validata empiricamente su iPad portrait 18/05/2026.

### Slot metronomo

N slot = beatsPerBar. Flash singolo frame ~16ms, no decay, no easing.
- **Accento: `#28cd41` (V21)**
- Beat: `rgba(255,255,255,0.85)`
- Subdivisione: `rgba(255,255,255,0.20)`
- Off: `rgba(255,255,255,0.08)`

SubdivisionMultiplier = audio-only, zero impatto visivo.

### Bar counter

"Battuta X di Y". Display "— / —" se total ≤ 0.
- Count-in / Standby → "— / —"
- Loop ∞ → "Battuta X di ∞"
- Font: JetBrains Mono 500, **16pt * scaleFactor**

### Micro bar

Segmentata N segmenti = N battute della sezione corrente. (Niente font, solo Rectangle shapes — non interessato dal refactor V23.)

### Giant text (teleprompter)

`Section.name`. Se vuoto → BPM sezione come fallback. Mai coesistenti.

Font: Inter-Black, logica adattiva per lunghezza testo (in `TeleprompterCapsuleView.swift`):
- **`(56 * scaleFactor)` se `count ≤ 10`** caratteri
- **`(44 * scaleFactor)` altrimenti**

Count-in numero: JetBrains Mono 700, **80pt * scaleFactor**
BPM fallback (no section name): JetBrains Mono 700, **48pt * scaleFactor**
Label "BPM" fallback: JetBrains Mono 400, **11pt * scaleFactor**

### Macro bar (2%)

Segmentata N segmenti = N sezioni canzone. (Niente font.)

### Zona NEXT (10%)

Label statica `NEXT:` (JBMono semibold, **10pt * scaleFactor**, tracking 2, `rgba(255,255,255,0.25)`)
seguita da nome dinamico (Inter ExtraBold, **34pt * scaleFactor**, `rgba(255,255,255,0.45)`).

- Sezione successiva stessa canzone → `NEXT: {nextSection.name}`
- Ultima sezione + canzone successiva → `FINE · NEXT SONG: {nextSong.name}` (JBMono semibold, **10pt * scaleFactor**)
- Ultima sezione ultima canzone → zona vuota

### Handle strip (2%)

- Posizione: tra zona NEXT e Transport
- Contenuto: barretta 32×3pt, `rgba(255,255,255,0.20)`, corner radius 1.5 (pt assoluti, sotto soglia 20pt)
- Funzione: affordance visiva per gesture mixer

### Transport

Tasti: Play/Stop · Loop · KILL BASE · EMERG. Dettagli identici a V19.

Font interni gestiti da `RubberBtnView`: label **8pt * scaleFactor**, glyph **18pt * scaleFactor** se `glyph.count ≤ 3` altrimenti **13pt * scaleFactor**.

### Overlay mixer

Trigger apertura: swipe DOWN da zona estesa (Teleprompter+MacroBar+NEXT+HandleStrip = 49% schermo).
- DragGesture(minimumDistance: 10), threshold > 15
- Apparizione **istantanea** (zero animazione)

Trigger chiusura: tap.
- Tap sul pannello mixer → chiude
- Tap su `Color.clear` 49% sopra il pannello → chiude
- Sliders consumano gesture propri
- Chiusura **istantanea**

Aspetto:
- Pannello altezza 21% schermo
- Background `#16161a` (Surface token)
- 4 slider verticali: CLICK / BACKT / CH3 / CH4
- CH3/CH4 grayed out in modalità Base hardware
- Label canale (CLICK/BACKT/CH3/CH4): JBMono medium, **9pt * scaleFactor**

### Overlay Standby (tra canzoni)

`StandbyOverlayView` mostra il nome canzone successiva al centro schermo.
- Font: Inter-Black, **52pt * scaleFactor**
- Pulse animation: `easeInOut(duration: 2.2).repeatForever(autoreverses: true)` su `opacity` (0.45 ↔ 1.0)
- `GeometryReader` interno preservato — serve per layout verticale (`Spacer 0.27 × height`), NON per scaling font (quello arriva da parent via parametro `scaleFactor`)

### Overlay Stop (pausedAwaitingChoice)

`OverlayStopView` mostra 2 bottoni "Riprendi da X" / "Dall'inizio · Y".
- Background semi-trasparente `Color.black.opacity(0.65)` (intenzionale — overlay stop intermedio)
- Bottoni con `OverlayStopButtonStyle`: JBMono bold, **15pt * scaleFactor**

### Overlay Fine Setlist

`FineSetlistView` mostra "FINE SETLIST" + 2 bottoni "TORNA A SETLIST" / "RICOMINCIA".
- Background: `Color(hex: "#0e0e10")` — **V23: deve essere opacity 1.0** (TD #43 aperto in BOX3 V63, da fixare in Step 6: `.opacity(0.95)` è errore di copy-paste da `OverlayStopView`)
- Testo "FINE SETLIST": JBMono bold, **28pt * scaleFactor**, tracking 2
- Bottoni con `OverlayStopButtonStyle` (riusato da OverlayStopView): JBMono bold, **15pt * scaleFactor**

### Stati Vista LIVE

(invariati da V19)

### Comportamenti ratificati Vista LIVE — V21

(invariati da V21)

### Invarianti Vista LIVE

(invariati da V19)

---

## Vista LISTA — Spec complete

(invariati da V19)

---

## Modalità Vista — UX-9, UX-10, UX-11

(invariati da V19; UX-11 ratificata 09/05: long press confermato come gesture BPM Vista LIVE.)

---

## Q-Live › Shows — Spec complete

Capitolo NUOVO in V28. Descrive il comportamento dello schermo **Q-Live › Shows**: che cosa fa, che cosa promette all'utente, e che cosa a HEAD non esiste ancora. Non contiene calendario — vedi il terzo bullet del Delta V28.

**Gerarchia delle fonti:** in caso di divergenza fra un deliverable CD e una riga di `LIBRO_MASTRO_QBEATS.md`, **vince LIBRO**. Le righe LIBRO citate qui sono lette dal blob a `8926c2af482dce5f4fa0e0dd36d2ba36eb90c199` (v42), non dal file di lavoro.

**Fonti del capitolo** — verificate il 28/07 a impronta **e a contenuto** (l'impronta di un file non prova che dentro ci sia ciò che si crede):

| Fonte | Impronta e misura | Copre |
|---|---|---|
| `DA_CD_PER_CC\27_07_2026\27_07_2026_g3\2026-07-27_QL-SHOWS-01-10__RIEMISSIONE.html` | sha256 `83c5c51d…8fabdf6c` · 27803 byte(disco) · 250 righe(terminatori) | le dieci righe del contratto, versione corrente |
| `DA_CD_PER_CC\26_07_2026\2026-07-26_QLive-Shows-Keyboard-Dismiss__Q20-RIEMISSIONE.html` | sha256 `5dcfbbfb…5ab9d408` · 37430 byte(disco) · 308 righe(terminatori) | congedo tastiera |
| `DA_CD_PER_CC\24_07_2026\2026-07-24_QLive-Shows-Card-Azione-Overflow-FREEZE.html` | sha256 `a97a4f54…0ee62764` · 45161 byte(disco) · 337 righe(terminatori) | forma della riga, menu, conferma |
| `LIBRO_MASTRO_QBEATS.md` righe 299 · 301 · 302 · 303 · 304 · 306 · 307 · 308 · 311 · 312 · 313 · 314 @ `8926c2af482dce5f4fa0e0dd36d2ba36eb90c199` | — | le ratifiche |

⚠️ **Trappola di nome sulla prima fonte:** esistono **tre** file omonimi `2026-07-27_QL-SHOWS-01-10__RIEMISSIONE.html`. Quello in `…\27_07_2026\UPDATE2\` è byte-identico a quello buono; quello in `…\27_07_2026\UPDATE\` **no** (sha256 `bd23b010…55416bc0`, 26268 byte(disco), 244 righe(terminatori)). Vale **solo** la copia in `27_07_2026_g3\`.

### Contratto QL-SHOWS — le dieci righe

**QL-SHOWS-01 · Persistenza.** «Remove from Q-Live» è PERMANENTE: sopravvive al riavvio dell'app. Persistenza LOCALE sul device (forma tecnica del campo = scelta CC). Default di ogni show, nuovo o esistente: VISIBILE in Q-Live. Campo assente nel JSON ⇒ visibile (retrocompat modello dati).
⚠️ Nessuna promessa cross-device: a HEAD non esiste sync (entitlement iCloud rimossi, zero CloudKit). Il cross-device è **gated sul ticket Opzione B**, non è una riga da incidere oggi.

**QL-SHOWS-02 · Reversibilità.** Reversibile SOLO da Q-Stage: toggle «Show in Q-Live» nell'editor dello show, chip «Not in Q-Live» sulla riga Q-Stage. Nessun ripristino dentro Q-Live. Lo stato è proprietà dello SHOW (non della lista Q-Live): vive nel dato dello show, non in una preferenza di vista.

**QL-SHOWS-03 · Ricerca.** Uno show tolto esce anche dai risultati di RICERCA in Q-Live. Q-Stage li mostra tutti. Nessuna resurrezione automatica: modifica/rinomina non lo rimettono in lista.

**QL-SHOWS-04 · Inerzia di palco.** «Remove from Q-Live» è INERTE con sessione armata o in play (voce disabilitata): è un gesto di preparazione, non di palco. Resta VISIBILE e disabilitato, **non nascosto** — una voce che scompare non insegna nulla, una voce spenta dice «non ora». [postilla 3, LIBRO r.303]
⚠️ Contratto, non descrizione dello stato corrente: a HEAD **non esiste uno stato di sessione armata** — l'unica occorrenza di `armed` è `backtrackArmed` (`ios_app/QBeats/Audio/AudioEngine.swift:370` come citato in LIBRO r.303), flag interno al buffer del backtrack, senza rapporto con l'armamento di uno show. Lo stato nasce insieme all'arma + standby.

**QL-SHOWS-05 · Terzo stato vuoto.** Lista Q-Live vuota ma Q-Stage pieno ⇒ «No shows in Q-Live · N shows are in Q-Stage». Vietato «No shows yet» in questo caso.

**QL-SHOWS-06 · Blocco unico.** Pillola ▶ · «···» a UNA sola voce («Remove from Q-Live») · swipe trailing rosso sulla riga · popup di conferma · campo di persistenza: **cinque pezzi, un blocco solo**. Non si separano, e Remove non si stacca dalla pillola. Motivo aritmetico (LIBRO r.302): tolto Remove, nel «···» resterebbe la sola voce «View songs», che duplica il tap sulla riga — un menu che duplica il gesto sottostante è decorazione, vietata da §6. Lo sheet a 3 voci (View songs · Start options… · Remove) **non appartiene a questo blocco**; il tetto «max 3 voci» del freeze 24/07 (nota ④) resta — una voce sta **sotto** il tetto, non lo viola. [postilla 2 — OK Mauro]
⚠️ **Trasformazione dichiarata:** la fonte formula questa riga come clausola d'ordine (che cosa si costruisce prima, che cosa dopo). Qui se ne incide la sola **composizione del blocco**; la sequenza è calendario e vive nella SCALETTA.

**QL-SHOWS-07 · Confine dello show.** L'ingresso in uno show è SEMPRE arma + standby, qualunque sia il flag standby della prima canzone. Il flag per-canzone (LIBRO 26/06) governa solo le transizioni canzone→canzone. «Standby off» = «non fermarti fra le canzoni», mai «parti senza di me». Il count-in configurato si suona comunque, al tap. Corollario: il flag della canzone in prima posizione è inerte finché è prima.

**QL-SHOWS-08 · Dettaglio e pillola.** Il DETTAGLIO show SARÀ la sede della scelta modalità (Q-Live / LIST / per song) e conserverà il proprio Start: **a HEAD non esiste**. Pillola ▶ della lista = stessa azione, modalità di default, nessuna domanda. Stato prodotto IDENTICO. Un solo componente per la scelta modalità, con due ingressi: dettaglio + «Start options…».
⚠️ Il futuro è normativo: al presente indicativo la riga si leggerebbe come stato del prodotto, e chi implementa cercherebbe una schermata che non c'è.

**QL-SHOWS-09 · Copy del popup Remove.** Ratificata 26/07, bottone confermato 27/07. Verbatim da `LIBRO_MASTRO_QBEATS.md:301 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`:

> Titolo `Remove "{show}" from Q-Live?` · messaggio `It leaves this list only — you'll find it again in Q-Stage.` (em-dash) · bottoni `Cancel` / `Remove` (destructive).

«Remove» compare **2 volte** in tutto il flusso: voce d'ingresso + bottone di conferma. **MAI nel messaggio** (là si dice «leaves»). Ripristino = toggle «Show in Q-Live» nell'editor show (Q-Stage), **non** nel popup. Questa copy SUPERSEDE la postilla 1 (coda «turn it back on from there»), **non la attua**: la via di ritorno si scopre dal chip «Not in Q-Live» (QL-SHOWS-02).
🔴 **VINCOLO DURO DI SPEDIZIONE (LIBRO r.301): Remove non si spedisce senza il chip «Not in Q-Live».** Tolto dal popup il nome del luogo di ripristino, la scopribilità poggia interamente sul chip: se il chip slitta o cade, il popup deve tornare a nominare il ripristino. È sicurezza d'uso, non layout.
⚠️ **Due chip diversi, da non confondere** (LIBRO r.313): «Read-only», testata della lista Q-Live — **RIMOSSO**; «Not in Q-Live», chip sulla riga in Q-Stage — **RESTA**, ed è il vincolo qui sopra. Toglierne uno non tocca l'altro.

**QL-SHOWS-10 · Congedo tastiera — contratto Q20** (serie Q17–Q22 · taratura 20/07/2026). **RATIFICATO**: 26/07 («ok va bene», LIBRO r.304) e riconfermato sul contenuto riletto per intero il 27/07 («SI VA BENE», LIBRO r.312). Dettaglio nel § «Congedo tastiera» qui sotto.
⚠️ I due deliverable CD che marcano Q20 «APERTA» — la riga QL-SHOWS-10 della riemissione 27/07 e la riemissione 26/07 — sono **superati su questo solo punto** (LIBRO r.312); **non si fa riemettere niente**. Cade con essi la clausola «NON incidere come chiusa finché Mauro non ratifica»: la ratifica c'è.
⚠️ Resta in piedi la distinzione: ratificare il contratto **sblocca** la costruzione, **non la sostituisce**. Finché il congedo non è nell'app e provato su device, in Q-Live › Shows la tastiera non ha via d'uscita che non sia lasciare la stanza — e lasciare la stanza, quando l'avvio setlist sarà cablato, spegnerà la sessione del metronomo.

### Forma della riga

Contratto vigente: freeze CD 24/07, ratificato Mauro — quattro decisioni chiuse, riprese in `LIBRO_MASTRO_QBEATS.md:299 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`.

- **§1 — forma ③ riga compatta, UNA SOLA.** Nessuna soglia card/riga: una soglia («≤4 card / ≥5 riga») rimodellerebbe lo schermo alla quinta data, e sul palco la prevedibilità batte l'ottimizzazione. La forma ① card resta agli atti come **scartata**, non come stato da costruire. Densità misurata dalla fonte: card ~140pt contro riga ~76pt, cioè 5 show a schermo invece di 2 — e la lista cresce, che è il motivo per cui Remove esiste.
- **§2 — nessuna label a schermo** sulla pillola ▶: la riga è già il nome dello show. VoiceOver = «Start show · {nome}». Se un domani si tornasse alla card ①, la label è «Start».
- **§3 — Start = arma + standby** sulla prima canzone. Il click parte al **secondo** tap (schermo ovunque) o via MIDI: Start non fa danni, è il tap successivo che suona. È lo stesso standby già ratificato fra le canzoni — non un secondo modello di avvio. Un tap dalla lista che facesse partire subito il click manderebbe il click in PA col telefono ancora in mano.
- **§4 — «Remove from Q-Live», semantica (a):** toglie solo da questa lista, la setlist **resta in Q-Stage**, nessuna canzone toccata. La variante (b), cancellazione vera, è **scartata**: aprirebbe la politica UUID orfani, non fissata. **Un solo nome in tutto il contratto: mai «Remove setlist»** — se non cancella, non può chiamarsi così.

Altre proprietà della riga, dalla stessa fonte:

- **Tap sul corpo della riga: invariato** — apre il dettaglio (le canzoni). Si aggiunge una scorciatoia, non se ne sostituisce una: nessuna riabitudine da fare sotto pressione.
- **«···» con tap-area 44×44**, allineato al bordo: separa «vado» da «gestisco».
- **Pillole distanti ~32pt in verticale**, per non sfiorare quella sbagliata.
- **Pillola ▶ in stato «gated» finché l'avvio setlist non è cablato**: tratteggiata, icona spenta, **inerte**. Un'affordance primaria accesa si accende solo quando l'azione esiste; una pillola arancio che non fa nulla è vietata dal contratto vigente.
- ⚠️ **Due frammenti del freeze 24/07 sono superati, le quattro decisioni no** (LIBRO r.299): (i) la coda della decisione §4, «Popup: "leaves this list · stays in Q-Stage"», è superata dalla copy ratificata la sera del 26/07 — vale QL-SHOWS-09; (ii) la fascia-cancello «Riga, meta e "···" sono già vivi — il menu contiene solo letture e il Remove, che esistono», è superata dalla postilla 2 — vale QL-SHOWS-06.
- ⚠️ **Chip «Read-only» in testa alla lista: RIMOSSO** (LIBRO r.313). Dal giorno in cui Remove esiste, «sola lettura» non è più vero. I mockup CD che lo mostrano ancora sono superati **su questo solo punto** e non vanno riemessi ora: si correggono al primo tocco utile di ciascuno.

### Congedo tastiera

Contratto Q20, ratificato (vedi QL-SHOWS-10). Il campo ricerca è un filtro sulla lista show; oggi la tastiera non ha via d'uscita che non sia lasciare la stanza. Il congedo deve vivere **dentro** Shows.

1. **Gesto canonico — «Done» su toolbar accessoria pinnata** sopra la tastiera, **sempre visibile**, tap-area **≥44pt**, **arancio = accento Q-Live** (**non** ambra: in Q-Live l'ambra è ALERT). Azione **unica** della toolbar, a destra. Label EN «Done» (§6). Affordance esplicita: sul palco, sotto pressione, il congedo non si affida alla scoperta di un gesto.
2. **Gesti perdonanti — in aggiunta, non al posto:** tap fuori (lista o area vuota) e swipe giù interattivo sulla lista (`scrollDismissesKeyboard(.interactively)`). Costano ~0 e sono muscle-memory iOS, ma **non sono garantiti come scoperta**: il contratto è il «Done».
3. **Return = «Search» → conferma il filtro E congeda**, conservando la query. Via di comodo, non il canonico.
4. **Il congedo CONSERVA query, filtro, scroll e selezione.** Congedo ≠ cancella (se svuotasse, la lista tornerebbe piena proprio mentre stai per toccare lo show filtrato: ostile) e congedo ≠ tocca la lista (lo show «picked» resta picked). L'unico effetto è la tastiera che scende.
5. **A svuotare è solo la «×»** nel campo, visibile finché c'è query: azione esplicita e separata, riporta la lista completa.
6. **MetroFAB: occluso, non rimosso.** Sta a fondo schermo e la tastiera lo copre, come ogni contenuto in fondo. Non si sposta, non si nasconde con logica propria, non lascia buchi; al congedo ricompare nella sua posizione, **senza animazione dedicata**.
7. **iPad coperto in tutti gli stati.** Software (docked o floating): la toolbar «Done» cavalca la tastiera. Hardware attaccata: non c'è trappola, e la resign resta garantita da tap-fuori + Return + «×». In nessuno stato l'uscita richiede di lasciare la stanza.

⛔ **Vietato affidare il congedo all'uscita dalla stanza.**
⚠️ **Vincolo di deployment — due fatti distinti, di rango diverso.** **[V] Il minimo del progetto è iOS 16.0**, misurato a fonte: `ios_app/project.yml:14 @ 4b55686c04e3bd14ccf06c31b5e89e74a38341ab` rende `deploymentTarget: "16.0"` per il target `QBeats` (dichiarato a `:11`); il target `QBeatsTests` (`:129`) porta lo stesso valore a `:132`. ⚠️ **[R] La disponibilità di `scrollDismissesKeyboard(.interactively)` a partire da iOS 16.0 è DICHIARATA, non misurata:** la fonte non è acquisita e non è acquisibile da qui — vedi PENDENZE DEL CAPITOLO, punto 9. Finché quella misura manca, il «senza margine» è un allarme, non un fatto: **se** le due versioni coincidono, un abbassamento del minimo farebbe cadere questa specifica per prima. «Done» e «×» **non** dipendono da quella API — il congedo resta garantito comunque.

### Menu «···» e «Remove from Q-Live»

**Entrambe le vie sulla riga — opzione A-bis** (`LIBRO_MASTRO_QBEATS.md:308 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`, con la rettifica di r.314 sulla clausola di deposito della fonte): la riga Q-Live porta il menu «···» con **una sola voce**, «Remove from Q-Live», **più** uno **swipe trailing rosso** sulla riga. «View songs» e «Start options…» non appartengono a questo schermo finché il dettaglio e il selettore di modalità non esistono.

- ⚠️ **Lo swipe è un'affordance NUOVA:** non è nel freeze 24/07. L'unico swipe ratificato in LIBRO è quello della Vista LIVE, **serie CD-5, ratificate `2026-05-21`**, citate per riga: `Q8=A` → `LIBRO_MASTRO_QBEATS.md:219 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199` · `Q9=A` → `:220` · `Q10=A` → `:221` · `R-CD5-06` → `:235` (stesso blob). Altra schermata, altro gesto. **Citare serie E riga è obbligatorio**: nel freeze Q7-Q16 dell'11/07 esistono di nuovo un `Q9` e un `Q10`, con contenuto tutt'altro — e la data da sola non discrimina, perché tutte e quattro le righe qui sopra portano la stessa.
- **Percorso al danno: due gesti intenzionali.** «···» → «Remove from Q-Live» → «Remove». Nessun tap accidentale al buio. Il Remove sta **isolato in fondo**, rosso, mai adiacente a Start.
- **Voce disabilitata con sessione armata o in play**, visibile e non nascosta: vedi QL-SHOWS-04.
- **Confine distruttivo Q-Live / Q-Stage — regola normativa** (LIBRO r.307): **Q-Live non contiene, e non conterrà, alcuna azione distruttiva sui dati dell'utente.** Quando la cancellazione definitiva di una setlist verrà costruita, potrà vivere **solo in Q-Stage**. «Remove from Q-Live» agisce esclusivamente sull'appartenenza dello show alla lista di palco e lascia la setlist **intatta e viva** in Q-Stage.
- **Prima scrittura sui dati utente** (LIBRO r.306): con Remove, Q-Live cessa di essere di sola lettura. La scrittura è **limitata allo stato di appartenenza dello show a Q-Live**; ogni altra scrittura resta vietata in §6.
- **Forma del popup: ② riquadro centrale, due bottoni impilati** (LIBRO r.311, scelta Mauro). Proprietà attribuite al file, non a Mauro: ordine **Remove in alto / Cancel in basso** · default **Cancel**, in basso e in grassetto · distruttivo in cima, isolato · **tap fuori NON chiude**. Nessuna collisione col congedo tastiera. ⚠️ La **fattibilità nativa** di questa forma è APERTA — vedi PENDENZE DEL CAPITOLO, punto 1.
- ⚠️ **Non è incisa** la clausola «pattern per ogni conferma futura» (LIBRO r.311): impegnerebbe ogni conferma distruttiva successiva a un contenitore custom prima di sapere se serve.

### PENDENZE DEL CAPITOLO

Voci aperte. Nessuna di queste è stata riempita con un'ipotesi plausibile: dove una fonte tace, qui c'è una riga, non un'invenzione.

1. **Forma ② del popup Remove — fattibilità nativa APERTA.** (LIBRO r.311) iOS impila i due bottoni da sé **solo con etichette lunghe**; con «Cancel»/«Remove» corte l'esito nativo atteso è **affiancato**. Servirebbe il foglio dal basso (forma ③, non scelta) oppure un contenitore custom, con focus, VoiceOver, tap-fuori e ritorno da rifare a mano. **Si chiude SOLO con documentazione ufficiale Apple (URL) o prova su device.** Finché è aperta, la forma ② è ratificata ma non dimostrata costruibile come nativa.
2. **Debito `#f3e2c0` → `#f3e2b0` in `.q20b`.** (LIBRO r.311) Un carattere di scarto da `.gatebox`, misurato a fonte: stesso fondo `#1c1608`, stesso bordo, diverge solo il testo. Va corretto **alla riemissione del deliverable imposta dalla verifica del punto 1**. **Dipende dal punto 1:** se quella verifica non si fa, la riemissione non parte e il debito resta appeso.
3. **Catalogo dei token colore — NON in questo capitolo, va in V29**, misurato contro il codice a HEAD. Restano quindi fuori anche i valori che le fonti citano di passaggio: il rosso del bottone distruttivo (`#ff453a`, fonte delle dieci righe, QL-SHOWS-09) e il fondo della toolbar di congedo (`#1c1c20`, fonte del congedo tastiera, §1). Nominati qui **come debito**, non incisi.
4. **Placeholder del titolo del popup — due forme in circolazione.** `LIBRO_MASTRO_QBEATS.md:301` (la ratifica) porta `Remove "{show}" from Q-Live?`, con virgolette **dritte**; la riemissione CD del 27/07 porta `Remove “{showName}” from Q-Live?`, con virgolette **curve**. Il capitolo incide la forma di LIBRO, per la gerarchia delle fonti. La divergenza è di un identificatore e di due caratteri, non tocca il messaggio né i bottoni: si risolve alla prima riemissione utile, **non si riemette nulla ora**.
5. **Forma tecnica del campo di persistenza — non decisa da alcuna fonte.** È scelta CC, dichiarata tale da QL-SHOWS-01. Non si incide qui.
6. **Cross-device — nessuna promessa.** A HEAD non esiste sync. Gated sul ticket Opzione B. Quando quel ticket si chiuderà, QL-SHOWS-01 e -02 **non si riscrivono**: la propagazione è una conseguenza del fatto che lo stato è proprietà dello show, già inciso in QL-SHOWS-02.
7. **Swipe trailing — conflitto coi gesti di navigazione non determinabile a fonte.** (LIBRO r.308) È provata solo la metà di codice (zero `swipeActions` in `QLiveShowsView`); il resto **si verifica su device**, con due affordance da provare invece di una.
8. **Stato «sessione armata» — non esiste a HEAD.** (LIBRO r.303) Nasce insieme all'arma + standby. La dipendenza è soddisfatta per costruzione finché i pezzi restano nel blocco unico di QL-SHOWS-06; va scritta perché non si perda **se quel blocco venisse spezzato**.
9. **Disponibilità di `scrollDismissesKeyboard(.interactively)` — fonte NON acquisita.** Il valore «iOS 16.0» circola nei deliverable CD e in `LIBRO_MASTRO_QBEATS.md:304 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`, ma nessuno lo ha misurato contro l'SDK: è un numero senza fonte. **Non è misurabile da questa macchina**, e la ricerca è stata fatta prima di dirlo — `*.swiftinterface` su **sette dischi** (C D E F G H I) = **0 file**, con controllo positivo nella stessa forma (`Get-ChildItem -Filter -Recurse -File -Force`) su `*.swift` sotto il repo = **66 file**; `xcodebuild`, `xcrun`, `swift`, `swiftc` tutti assenti dal PATH; nessun `SwiftUI.framework`, `SwiftUI.swiftmodule`, `iPhoneOS.sdk` né `Xcode.app` su `C:`. La compilazione avviene su runner CI, non qui. **Si chiude SOLO con l'annotazione `@available` letta nell'interfaccia del modulo SwiftUI dell'SDK usato dalla CI, oppure con documentazione ufficiale Apple (URL).** ⚠️ La distinzione da non riperdere: il minimo del progetto è **[V]** e misurato (`ios_app/project.yml:14 @ 4b55686c04e3bd14ccf06c31b5e89e74a38341ab`); la disponibilità dell'API è **[R]** e non lo è. La formula «esattamente il minimo del progetto» li faceva sembrare un fatto solo.

---

## Invarianti tecnici Layer 3 — INVIOLABILI

| Regola | Dettaglio |
|---|---|
| Feedback visivo beat | Callback C++ → dispatch main via `PassthroughSubject` — MAI timer SwiftUI |
| `beatTickSubject` | `PassthroughSubject<Int, Never>` — MAI `@Published Double` per tick |
| `if isBeat` non `guard...continue` | Il `continue` rompe schedulazione audio subdivision |
| Cambio BPM sezione | `scheduleBPMChange` — sample-accurate al downbeat |
| `setBPM` vs `scheduleBPMChange` | `setBPM` = immediato (UI/Link/tap). `scheduleBPMChange` = cambio sezione |
| Backtrack | `AVAudioPlayerNode` in `AVAudioEngine` — MAI `AVPlayer` |
| Streaming backtrack | VIETATO |
| Route change | Clock C++ non si ferma |
| `midi_engine_start()` | Solo in `init()` — MAI in `start()`. Spostato dopo `setupGraph()` |
| `midi_engine_stop()` | RIMOSSO da `stopSync()` — MIDI sempre attivo |
| `os_log` | Unico debug — `print()` non catturato da iMazing |
| `@Published` assignment | ESCLUSIVAMENTE su main. Due forme equivalenti: (a) `DispatchQueue.main.async`; (b) tipo `@MainActor` a livello di classe (vedi `QBeatsStore`) — garanzia più forte, compile-time, non richiede `DispatchQueue` esplicito |
| `UIBackgroundModes: audio` | In `project.yml` — non toccare |
| **Portrait + universal v1 (V22)** | **Portrait obbligato su tutti i device (iPhone + iPad). Universal default Xcode `1,2`. Landscape iPad ("Vista Bella v2") rimandato a v2 reale** |
| `SwiftUI.Section` | Qualificare sempre fino a TD-1 risolto |
| DebugView | Solo `#if DEBUG` — mai in produzione |
| RT thread | Zero malloc/free/new/delete/ARC/ObjC/mutex/I-O |
| `MetSlotStripView` contratto | Riceve `pattern: [String]` e `beatActive: Int`. MAI riferimento diretto ad `AudioEngine` |
| `currentAccentPattern` mapping | `2→"accent"`, `1→"beat"`, `0→"subdiv"`. Conversione `[UInt8]→[String]` in LiveView |
| `totalBarsInSection` | Legge `repetitions`, NON `beatsPerBar` |
| Glyph STOP | Sempre "■" — mai "⏹" |
| Mute click UI | SVG speaker — mai emoji |
| `RubberBtnView` | Parametro `accentColor: Color? = nil`. V23: parametro `scaleFactor: CGFloat` (propagato da TransportView) |
| Link — init silente | `ABLLinkSetActive(false)` subito dopo `ABLLinkNew` |
| Link — fresh play branching | Modello a 4 rami: (peers==0 && !isPlaying) → standalone puro; (_linkMode == .direttore, qualsiasi stato peer) → direttore-standalone, detta la timeline con start_at_beat_zero (Director comanda sempre — i peer si adeguano); (collaborativa con peer in play) → join_running_session; resume → start_at_beat. Build #309 esteso 28/05/2026. Nota: in .direttore, start_at_beat_zero è chiamato anche con peers > 0. Comportamento progettato e ratificato. |
| Link — `start(resumeAtBeat:)` | Parametro `skipLinkWait` rimosso. Distinzione standalone/shared via probe + num_peers. Build #309 |
| Link — preference pane | `ABLLinkSettingsSheetView` sempre accessibile via Button in SettingsView quando linkEnabled. Commit `a5451bd` |
| `isIdleTimerDisabled` | Gestione centralizzata su root view via `onChange(of: scenePhase)`: true se `.active`, false altrimenti. Commit `341559d` |
| AppDelegate — applicationDidBecomeActive | V20 — al ritorno foreground, se `linkEnabled == true` ri-asserisce `setLinkEnabled(true)`. LinkKit best practice. Risolve "Link rotto mid-session". Commit `9a2e529` |
| Link — modalità Direttore/Collaborativa | V20 — `appSettings.linkMode` controlla comportamento Link. `_linkMode` audioQueue-private aggiornato in `applySettings()`. Default `.collaborativa` (cambiato da `.direttore` in `cb92faa` 24/05/2026). Commit `c8434b3`. V24 28/05/2026: guard start/stop e BPM estesi a tutti gli stati (`isRunning` rimosso). Phase guard invariato (implicito in play — vive dentro `scheduleNextBuffer`). Ogni callback documentato separatamente nelle righe seguenti. |
| Link — Direttore tempo callback | V20 — Re-broadcast del proprio BPM quando peer prova a cambiarlo, vincendo sempre la negoziazione. Check `bpm != _audioBPM` evita loop di re-broadcast quando peer riceve il valore Q-B e ritorna lo stesso. V24 28/05/2026: guard esteso a tutti gli stati — `if _linkMode == .direttore` (rimosso `isRunning`). Pre-fix: Director in stop avrebbe adottato BPM del peer (Bug 5-BPM latente). Director è sorgente unica del tempo in ogni stato. Commit `a42e877` + `4375ee3` |
| Link — Direttore phase sync | V20 — Skip silenzioso del `link_engine_sync_phase` quando in director play |
| Link — Direttore start/stop callback | V20/V24 — Ignora start/stop da peer in ogni stato (anche in stop). Guard: `if _linkMode == .direttore { return }`. Bug 5 fix 28/05/2026: pre-fix richiedeva `isRunning`, Director in stop accettava start da peer Collab via START LOCAL. |
| Link — UI Picker bloccato in play | V20 — Picker modalità in SettingsView ha `.disabled(audioEngine.isPlaying)` |
| Link — `_audioBPM` audioQueue-private | V20 — Mirror BPM su audioQueue. Aggiornato in `setBPM()`. NON aggiornato in `scheduleBPMChange()` (Task D — vedi sezione dedicata) |
| **Pattern reconciliation Layer 2 — Link** | **V21** — Schema `query → apply → propagate` per ogni flag persistito da LinkKit replicato in stato C++ locale. Boot reconciliation come secondo entry point Link (oltre a `ABLLinkSetIsEnabledCallback`). Indispensabile perché alcuni callback LinkKit non scattano se lo stato persistito è già allineato al target. Commit `97e2174` |
| **L1.a — Pattern closure end-of-section** | **V21** — AudioEngine NON deve avere hardcoded la decisione di "cosa fare a fine sezione". Il caller (Layer 3) passa una closure a `loadSection(beatsPerBar:repetitions:onEnd:)` che decide se: caricare prossima sezione, andare in standby, fermarsi. Commit `1da26bf` |
| **L1.a — Drain mode audio** | **V21** — A fine ultima ripetizione di una sezione, il flag `_sectionEndPending` in `scheduleNextBuffer` salta `metronome_processBuffer` per il buffer post-drain. Sample-accurate, deterministico, niente `asyncAfter` nel thread audio. Commit `f652f29` |
| **`AudioEngine.stop()` — allineamento stato** | **V21** — Ogni percorso di stop dispatcha `playbackState = .stopped` su main async dopo `stopSync()`. Pattern già usato in `handleStop()` per `.countIn` e in `restartFromBeginning()`. Senza questo, `TransportView` (che dichiara `let audioEngine` non `@ObservedObject`) non si re-rendera. Commit `217ebac` |
| **Pattern state-aware View — Vista LIVE** | **V21** — Ogni componente visivo che cambia aspetto in funzione dello stato di esecuzione (`BarCounterView`, `MicroSegBarView`, `MacroBarView`) riceve `state: LivePlaybackState` come parametro esplicito. MAI dedurlo implicitamente da campi numerici (es. `currentBar == 1` ≠ "siamo in play"). Commit `7720833` |
| **Pattern `sectionEndedSubject` + `sectionHold`** | **V21** — Per spegnimento sincronizzato di componenti UI multipli a fine ciclo naturale: AudioEngine espone `sectionEndedSubject: PassthroughSubject<Void, Never>`. LiveView riceve il subject, attiva `@State sectionHold: Bool` che funge da OVERRIDE del gate `state==.playing` per la durata del fade. Un `asyncAfter(60.0/currentBPM)` su main resetta `sectionHold` e `beatActive` insieme. Distinzione automatica autostop vs stop manuale via presenza/assenza dell'emissione del subject. Commit `5deabeb` + `89790fa` + `e38416e` |
| **`asyncAfter` cosmetico in UI — chiarimento** | **V21** — Il divieto "no asyncAfter con delay calcolato" stabilito in L1.a si applica al thread audio dove serve precisione al campione. In UI cosmetica su main thread è il meccanismo standard, ammesso. VIETATO invece l'`asyncAfter` "cosmetico per mascherare un problema di stato": va sempre preferito il modello di stato che non genera il problema in origine |
| **`let` vs `@ObservedObject` su View figli** | **V21** — TransportView dichiara `let audioEngine: AudioEngine`, NON si re-rendera sui cambi di proprietà di audioEngine. Si re-rendera solo quando cambia `session` (@ObservedObject). Conseguenza: ogni transizione di stato visibile in UI DEVE passare per `session.playbackState`. Soluzione adottata in P1+P3 invece di cambiare `let` in `@ObservedObject` |
| **Scaling responsive font (V23 — CORRETTO)** | **V23** — Tutti i font Vista LIVE in formato `pt_originale * scaleFactor` dove `scaleFactor: CGFloat = geo.size.width / 390` calcolato una sola volta in `LiveView.swift` (dentro `GeometryReader { geo in ... }`) e propagato come parametro CGFloat esplicito a tutti i sub-View. Pattern moltiplicativo invece di percentuali pre-calcolate (V22 era errato: baseline 430pt teorica, reale è 390pt iPhone 13). Baseline misurata empiricamente: `[QBEATS][ScaleFactor] geo.size.width = 390.000000` su iPhone 13 portrait (commit `adfcc39`). Specifica implementativa completa in BOX3 V63. ButtonStyle ricevono `scaleFactor` come parametro all'init (NON cattura ambiente). Sub-component nested ricevono propagazione esplicita dal parent (NON cattura implicita). |
| **API SwiftUI VIETATE per scaling device-aware (V22)** | **V22** — `@ScaledMetric`, `UIFont.preferredFont(forTextStyle:)`, `Font.preferredFont(...)`, `@Environment(\.sizeCategory)`. Tutte ancorate a Dynamic Type accessibility (preferenza testo dell'utente in Impostazioni iOS), NON a device size. Su iPad con accessibility default = identico a iPhone, esattamente il sintomo da evitare. Quando in futuro si aggiungerà supporto accessibility ipovedenti, allora `@ScaledMetric` SOPRA il geo.size scaling (composizione moltiplicativa) |
| **Spacing piccoli + frame fissi in pt assoluti (V22)** | **V22** — Spacing interni a `HStack`/`VStack` con valore < 20pt restano in pt assoluti (es. `spacing: 6` in TransportView resta 6, non `geo.size.width * 0.014`). V23 aggiunge: `frame(width:height:)` di bottoni icona (es. back/mute `34×34`) e bottoni overlay (`height: 56`) restano in pt assoluti — sono dimensioni hit-target/touch, non visuali |
| `Bridge MIDIEngineBridge.h` | Singola sorgente di verità. Disallineamento con `MIDIEngine.mm` = build rossa |
| Count-in BPM | Prima sezione canzone target |
| TempoMap | Campo opzionale in BacktrackFile. `nil` = BPM fisso invariato |
| La backtrack comanda | In modalità adaptive la sorgente di verità è la TempoMap, non il BPM utente |

---

## Specifica vincolante L1.b — Fade scatta SOLO a "fine vera"

(invariato da V22, vedi BOX5 V22 sezione "Specifica vincolante L1.b")

**Aggiornamento V23**: L1.b chiuso definitivamente in sessione 17/05/2026 (commit `dc1da0b`). TD #41 `pendingDisplayUpdate` flag + subscribe a `session.$beatActive` filter ==1 in SetlistRunner implementa la regola "fine vera vs transizione intermedia" senza fade spurio.

---

## Limite v1 — Modalità Direttore

(invariato da V22)

---

## Task D — Section BPM broadcast su Link

(invariato da V22, Task D chiuso V53)

---

## Struttura file Layer 3

```
ios_app/QBeats/
  AudioEngine.swift
  AppSettings.swift
  MIDILearnTypes.swift
  MIDILearnStore.swift
  ContentView.swift               ← V23: $audioEngine.beatsPerBar binding Picker (NON tocca scaling — modalità Studio metronomo libero)
  SettingsView.swift
  AppDelegate.swift               ← applicationWillTerminate + applicationDidBecomeActive
  QBeatsApp.swift
  DebugView.swift                 ← Solo #if DEBUG
  MIDIEngineBridge.h / MIDIEngine.mm
  MetronomeDSPBridge.h / .mm
  BTMIDICentralPickerView.swift
  MIDINetworkViewModel.swift
  LinkEngine.h / .mm
  LinkSettingsPresenter.h / .mm
  QBeats-Bridging-Header.h
  Models/
    Section.swift
    Song.swift
    Setlist.swift
    TimeSignature.swift
    LiveSession.swift
    LivePlaybackState.swift
  Store/
    QBeatsStore.swift
  UI/
    AppRootView.swift             ← onChange(of: scenePhase) per isIdleTimerDisabled
    BivioBoardView.swift
    SplashView.swift
    QStageRootView.swift
    LiveRootView.swift
    Live/
      LiveView.swift              ← GeometryReader principale + scaleFactor calcolo + propagazione (V23)
      LiveHeaderView.swift        ← V23: parametro scaleFactor, 8 callsite font scalati
      MetSlotStripView.swift      ← (no font, no scaleFactor)
      BarCounterView.swift        ← V23: parametro scaleFactor, 2 callsite font scalati
      SegBarViews.swift           ← (no font: MicroSegBarView + MacroBarView solo shapes)
      TeleprompterCapsuleView.swift ← V23: parametro scaleFactor, 4 callsite font scalati
      POIView.swift               ← V23: parametro scaleFactor, 3 callsite font scalati
      MixerOverlayView.swift      ← V23: parametro scaleFactor, propagato a MixerChannelView sub-component (1 callsite font)
      TransportView.swift         ← V23: parametro scaleFactor, propagato ai 6 RubberBtnView
      RubberBtnView.swift         ← V23: parametro scaleFactor, 3 callsite font scalati
      StandbyOverlayView.swift    ← V23: parametro scaleFactor, 1 callsite font (GeometryReader interno preservato per layout)
      OverlayStopView.swift       ← V23: parametro scaleFactor, propagato a OverlayStopButtonStyle (1 callsite font in ButtonStyle)
      FineSetlistView.swift       ← V23: parametro scaleFactor + TD #43 aperto (opacity 0.95 → 1.0 in Step 6)
```

---

## R-δ — DOVE VANNO I FILE

**Sede operativa unica.** La regola e' ratificata in `LIBRO_MASTRO_QBEATS.md:336`
(01/08/2026, le destinazioni) e `:346` (04/08/2026, la quarta destinazione).
Quelle righe non si riscrivono: qui si dice **come si esegue**.

### 1 · QUATTRO DESTINAZIONI, DUE SCRITTURE

| destinazione | come ci arriva |
|---|---|
| `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS` | CC scrive |
| git online — `github.com/19Bullfrog78/Q-BEATS` | push |
| `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD` | CC copia |
| drive online | **da solo** — riflesso di `E:` |

⛔ **SU DRIVE NON SI SCRIVE.** Drive non e' una cartella da riempire: e' il
riflesso di `E:`, sotto la sezione **«Il mio computer»**. Un file scritto su `E:`
compare su Drive da solo, per tutto l'albero. **Un mandato che prescrive un
indirizzo Drive e' difettoso: CC non lo esegue, si ferma e lo dichiara.**

⚠️ **Perche' questa riga esiste:** fra il 20 e il 21/08/2026 l'indirizzo Drive e'
cambiato **tre volte in tre mandati, in direzioni opposte**, lasciando i referti
del 21/08 divisi in due cartelle. Non fu distrazione: fu una gamba morta che
nessuno aveva dichiarato morta.

⚠️ **La consegna e' completa con le DUE copie scritte verificate identiche**
(`cmp` exit 0 o sha256). Drive non entra nella verifica di consegna: chi puo'
ispezionarlo e' il referee, non CC.

### 1-bis · QUANDO SI DEPOSITA: ALLA PRODUZIONE, NON A FINE MANDATO

⛔ **Ogni artefatto destinato a Mauro o al referee — referto, diff, stampa,
congedo, contratto — si deposita sulle DUE gambe NELL'ISTANTE IN CUI ESISTE**,
non alla chiusura del mandato.

⚠️ **Il motivo e' misurato, non prudenziale.** Il diff nasce **al cancello**,
cioe' a meta' mandato, ed e' esattamente il momento in cui Mauro e il referee
devono leggerlo. Se R-δ vive nell'ultima sezione del mandato, ogni volta che CC
si ferma al cancello — comportamento **corretto** e imposto dal mandato stesso —
il diff resta **solo su `C:`**, e Mauro deve andarselo a prendere sul disco di
lavoro. **Successo il 21/08/2026** con i due diff di A162, verificato dal referee
sul riflesso: assenti.

⇒ **Un mandato che colloca R-δ soltanto in coda e' DIFETTOSO.** CC deposita
comunque alla produzione, e lo dichiara nel referto.

### 2 · DOVE VA COSA, PER NATURA

| natura | su C: (repo) | su E: (archivio) |
|---|---|---|
| canonici LIBRO · BUGS · BOX3 · BOX5 | **radice**, in place | `LIBRO_MASTRO/` `BUGS_QBEATS/` `BOX3_Codice/` `BOX5_Test/` |
| SCALETTA | `HANDOFF/` | `HANDOFF/` |
| referti · congedi · diff | `HANDOFF/` — tutti, zero altrove | `HANDOFF/` |
| contratti e freeze CD | `DESIGN/QLive_Nav/` | `DA_CD_PER_CC/<data>/` |

⛔ **Le due strutture sono DIVERSE, ed e' voluto:** `C:` segue il **repo**, `E:`
segue l'**archivio**. Nessuna delle due copia l'altra, e **nessuna delle due
descrive Drive**. Chi scrive «su Drive si copia la struttura del repo» sta
descrivendo una cosa che non esiste.

### 3 · COME SI PRODUCE LA STAMPA SU E:

Invariato e gia' in questo documento (Delta V26 e Delta V27): **nome per versione
con data e commit** — forma `BOX3_V98_2026-07-22_edaa80f.md` — e per i file
**TRACCIATI** estrazione **dal blob** con `git show <commit>:<path>`, **mai copia
dal disco**.

⚠️ QUANDO LA DATA DELLA VERSIONE E QUELLA DEL COMMIT DIVERGONO —
ratificato dal referee 23/08/2026, prima occorrenza `9edc120`.
Nel nome della stampa d'archivio va LA DATA CHE IL DOCUMENTO DICHIARA DI
SE', non la data di estrazione ne' quella del commit: lo sha7 nel nome
identifica gia' il commit. ⇒ un nome non deve mai contraddire l'intestazione
del file che nomina.

### 4 · CIO' CHE NON E' UNA DESTINAZIONE

- **`I:\Il mio Drive\Qbeats\`** — albero manuale creato il 01/08/2026 alle 13:09,
  due ore e mezza **prima** che nascesse il riflesso di `E:` (15:47). Ha svolto un
  ruolo che il riflesso ha poi assorbito. **Non e' piu' una destinazione: non si
  scrive.** ⛔ **Non si cancella e non si sposta:** resta agli atti.
- **`F:`** — secondo disco interno, contiene un clone del repo.
  **NON e' una destinazione R-δ.** Regola sua, da scrivere separatamente.

### 4-bis · STRINGHE DI CONTROLLO D'INTEGRITA'

⚠️ STRINGHE DI CONTROLLO D'INTEGRITA' — regola di CC, ratificata 23/08/2026
dopo tre morsi in un giorno solo (A182, A185, A187).
Una stringa di controllo va scelta COPIANDOLA da UNA RIGA SOLA del file,
corta, senza ritorni a capo — oppure la sonda va eseguita sul testo
APPIATTITO (ritorni a capo sostituiti da spazi) prima di contare.
⛔ Una stringa che cade a cavallo di un a capo rende ZERO su un file
perfettamente integro: e' un falso allarme, non una mutilazione.

⚠️ **Quarto morso, misurato il 23/08 mentre si incideva questa regola:** la sonda
ID per contenuto su `A190` non rendeva l'unico hit reale (`HANDOFF/MISURE_CC_2026-08-21_A158-COMMIT-LIBRO-v58.md`),
perche' la riga di tabella che lo contiene va a capo. La stessa ricerca sul testo
appiattito lo trovava. ⇒ **la regola vale anche per le sonde ID, non solo per i
controlli d'integrita' dei referti.**

### 5 · QUARTA COPIA — NAS

Manuale, **nessuna sincronizzazione**, cadenza settimanale, **entrambi gli
alberi** (`C:` e `E:`). E' l'unica copia che non e' un riflesso, quindi l'unica
difesa contro una cancellazione propagata — argomento invariato da
`LIBRO_MASTRO_QBEATS.md:336`. **Invecchia**: fino alla fotografia successiva, il
rischio residuo non e' «assente», e' «vecchia di al massimo sette giorni».

### 6 · CARTELLO DI RETTIFICA — A159

Il referto `HANDOFF/MISURE_CC_2026-08-21_A159-CENSIMENTO-TRE-GAMBE.md` conclude in
prima riga che **la sincronizzazione E: → Drive e' ferma da meta' agosto**.
⛔ **La conclusione e' FALSA. La misura era GIUSTA.**

`I:` e' Drive montato come disco e **non rimonta la sezione «Il mio computer»
della macchina locale**: da li' il riflesso e' **invisibile per costruzione**, e
lo zero misurato su `I:` e' uno zero vero che non dice nulla su Drive. Il
confronto 370 contro 186 metteva a confronto `E:\…\HANDOFF` con
`I:\Il mio Drive\Qbeats\HANDOFF`, cioe' **due cose diverse**, non due copie della
stessa cosa.

**Verificato dal referee dal lato cloud il 21/08/2026:** i tre campioni citati da
A159 — `CONGEDO_CC_2026-08-18.md`, `CONGEDO_CC_2026-08-19.md`,
`MISURE_CC_2026-08-19_A128-STANDBY-CENTRATURA.md` — sono **tutti e tre presenti**
nel riflesso; e **il referto A159 stesso vi e' comparso quattordici secondi dopo
essere stato scritto**.

⛔ **Il difetto era del MANDATO, non dell'esecutore:** A159 chiese una misura con
uno strumento che non la poteva vedere. CC dichiaro' il proprio limite nello
stesso referto — ⚠️ ma **un limite dichiarato a pagina tre non annulla una
conclusione data per certa a pagina uno**, ed e' la lezione che questo cartello
incide.

⛔ **Il file del referto A159 NON si corregge** — stessa forma di A64,
`LIBRO_MASTRO_QBEATS.md:352`: e' depositato e citato, la rettifica vive qui.

⚠️ **LIMITE DICHIARATO, e scade:** il referee ha verificato che il riflesso
riceve, non che sia **completo** file per file contro i 370 di `E:`. Nessuno puo'
citare questo capitolo per affermare che Drive sia una copia integrale.

---

### R-δ.7 — LA TESTA DI UN DOCUMENTO CITATO NON CRESCE MAI (ratificata Mauro 24/08/2026)

⛔ **REGOLA:** ciò che si accumula a ogni versione — riassunti, blocchi Delta, cappelli — va **IN CODA**, mai in testa. La testa di un documento che altri citano **non cresce mai**. Vale per tutti i canonici, **BOX3 compreso**.

**Perché, misurato:** un blocco aggiunto in testa sposta di N righe **tutto** il file, e con esso ogni citazione `FILE:riga` che altri documenti e il **codice di produzione** gli puntano contro. Misura del 24/08 su BOX5: **29 citazioni nude + 7 ancorate = 36**, distribuite su otto sedi — BUGS, LIBRO, SCALETTA e **cinque file `.swift`** (`SetlistRunner`, `LiveView`, `StandbyOverlayView`, `QLiveSession`, `QLiveShowDetailView`). Un solo blocco in testa le avrebbe rotte **tutte e ventinove** in un colpo.

⚠️ **Non è un'ipotesi: è già successo.** Il ticket `TD-box3-citazioni-nude-slittate` in `BUGS_QBEATS.md` nasce esattamente così — BOX3 V100 ha aggiunto 16 righe in testa e ha slittato 27 citazioni. **Stesso difetto, stesso tipo di file, seconda volta.** La regola esiste per non farne una terza.

⚠️ **La convenzione precedente NON era scritta:** cercata il 24/08 nei cinque canonici e nella Costituzione, rende **zero regole** sulla posizione — solo sedici intestazioni `Delta VN vs VN-1:`, che sono **istanze di un'abitudine**, non una prescrizione. Non si sta ribaltando una ratifica: se ne sta scrivendo una dove non ce n'era nessuna.

✅ **Il numero di versione in testa resta in testa**, e si aggiorna **dentro la riga**: sostituire una cifra non sposta nulla.

⛔ **I riassunti già in testa NON si spostano.** Muoverli costerebbe quanto aggiungerne uno. Si marca, non si riscrive — vedi la dichiarazione di transizione in coda a questo documento.

### R-δ.8 — UN ID È OCCUPATO QUANDO È ASSEGNATO A UN LAVORO (ratificata referee, approvata Mauro 26/08/2026)

⛔ **REGOLA:** un identificativo di mandato è **occupato** quando è **assegnato a un lavoro** — un referto, un congedo, un commit, una riga di canonico che lo attribuisce. **NON è occupato** quando compare **nominato come campione** dentro un documento che ne sta verificando la disponibilità.

**Perché:** il cancello ID esiste per impedire che **due lavori diversi portino lo stesso numero**. Una citazione dentro una tabella di sonda non è un secondo lavoro: non ha artefatti, non ha commit, non ha attribuzione. Trattarla come occupazione brucia numeri senza proteggere nulla.

✅ **Precedente misurato, e distinzione operativa:** A213 e A214 erano occupati da **referti veri** — bruciati, correttamente. A218 compariva **una volta sola**, dentro la tabella di controllo del congedo del 25/08, senza alcun lavoro attaccato: **libero**, e infatti è stato usato.

⚠️ **La sonda non distingue da sola.** Rende un numero; è **chi legge** a stabilire se quell'occorrenza è un'assegnazione o una citazione. ⛔ **Un `1` non chiude il cancello: obbliga ad aprire il file e guardare cosa c'è su quella riga.**

### R-δ.9 — IL DOCUMENTO CHE NOMINA UN CAMPIONE LO CONSUMA (rilievo CC, ratificata referee 26/08/2026)

⛔ **REGOLA:** i numeri **candidati** non si scrivono per esteso nei documenti. **Si nomina solo quello assegnato.**

**Perché, misurato:** il congedo del 25/08 dichiarò in tabella un ID «secondo campione» a `0 / 0 / 0`, e **con quella riga lo rese `1`**. La misura era vera nell'istante in cui fu presa e **falsa nell'istante in cui fu pubblicata**: il documento ha invalidato la propria misura nell'atto di scriverla.

⇒ **Come si scrive un cancello ID senza consumarlo:** si riporta la tabella del solo ID **preso**, più i **controlli positivi** — che sono ID **già occupati**, quindi nominarli non costa nulla. I candidati scartati si descrivono **per relazione** («quello immediatamente precedente»), mai per cifra.

⚠️ **Faccia generale della regola:** un documento che descrive il proprio stato **lo altera**. Vale per il conteggio dei non tracciati (un congedo si conta di meno finché non si deposita) e per le stringhe di un controllo d'integrità (la nota che spiega un conteggio entra nel conteggio). ⇒ **Le misure di un documento si dichiarano come scattate PRIMA del suo deposito, e l'auto-test si misura sull'ULTIMA stesura, mai sulla penultima.**

### R-δ.10 — LA GAMBA CONTENUTO DELLA SONDA ID ESCLUDE `DESIGN/` (misurata referee 26/08/2026)

⛔ **REGOLA:** la gamba **CONTENUTO** del cancello ID gira con `-- ':!DESIGN'`. La gamba **NOME** non ha bisogno dell'esclusione.

**Perché, misurato:** la stringa `A219` compare **una sola volta** in tutto il repo, e non è un identificativo: è una **sottostringa dentro il base64 di un font woff2** in `DESIGN/QLive_Nav/2026-07-09_standalone_b23dfc78.html`. Una sonda ingenua dichiara quell'ID **occupato** e lo brucia.

⚠️ **È una polarità NUOVA rispetto a quanto già agli atti: un falso-UNO, non un falso-zero.** Le forme censite in casa producono un **vuoto** che sembra un fatto; questa produce un **riscontro** che sembra un fatto. ⛔ **Non rinumerare le serie esistenti su questa riga:** la classificazione tassonomica non è decisa qui.

✅ **Corollario operativo:** un ID che risulta pulito **solo grazie all'esclusione** è un ID che qualcun altro dichiarerà occupato. **Quando è possibile, si prende quello pulito in ENTRAMBE le letture.**

## Backlog — feature da implementare

| # | Feature | Fase | Priorità | Specs CD |
|---|---|---|---|---|
| F2.1 | Splash animato + bivio Q-STAGE/LIVE | 2 | 🔴 | ✅ |
| F2.2 | Navigazione principale | 2 | 🔴 | ✅ |
| F2.3 | Selezione Setlist | 2 | 🔴 | ⏳ |
| F2.4 | Q-STAGE: libreria canzoni | 2 | 🔴 | ⏳ |
| F2.5 | Q-STAGE: editor canzone | 2 | 🔴 | ⏳ |
| F2.6 | Q-STAGE: libreria backtrack | 2 | 🟡 | ⏳ |
| F2.7 | Q-STAGE: gestione setlist | 2 | 🔴 | ⏳ |
| ~~Task D~~ | ~~`scheduleBPMChange` broadcast su Link~~ | ✅ CHIUSO V53 | — | — |
| ~~L1.b~~ | ~~Multi-section setlist — wiring Layer 3~~ | ✅ CHIUSO V62 + TD#41 v2 commit `dc1da0b` | — | — |
| ~~#23~~ | ~~Refactor font Vista LIVE responsive~~ | ✅ CHIUSO V63 commit `8a5432b` (V23) | — | — |
| **#43 (V63)** | **FineSetlistView opacity 0.95→1.0** | **6 (cleanup)** | 🟡 | — |
| F3.x | Vista LIVE — stati completi (Standby, Fine setlist, Swipe canzone) | 3 | 🔴 | ✅ |
| F4.x | Vista LISTA — completa | 4 | 🔴 | ✅ |
| F5.6 | Metronomo adattivo (aubio) | 5 | 🟡 | ✅ doc B7 |
| F6 | MIDI Learn UI completa | 6 | 🟡 | — |
| UX-1 | Banner post-VoIP | 3+ | 🟡 | — |
| UX-9 | Modalità Vista selezionabile | 2 | 🔴 | ✅ |
| UX-10 | Swipe orizzontale canzoni | 2 | 🟡 | ✅ |
| UX-11 | BPM swipe (solo senza backtrack) | 2 | 🟡 | ✅ (long press ratificato 09/05) |
| **CD-1** | **Schermata iniziale Vista LIVE "standby vestito"** (nome setlist + canzone, tap-anywhere start) | 3 | 🟡 | ⏳ raccolto V63 |
| **CD-2** | **Perimetro rosso sfumato pulsante su standby tra canzoni** | 3 | 🟡 | ⏳ raccolto V63 |
| **CD-3** | **Bottone "Ricomincia setlist" a fine setlist** (UX live) | 3 | 🟡 | ⏳ raccolto V63 |

**Schermate CD mancanti (bloccano CC):** Selezione Setlist · Lista Canzoni · Editor Canzone · Lista/Editor Setlist · Libreria Backtrack · Settings completi · CD-1/CD-2/CD-3 backlog raccolto.

---

## Decisioni UX 09/05/2026 — Ratificate

(invariate da V22)

---

## Decisioni V22 — Ratificate 12/05/2026 sera tardi

(invariate da V22, ma vedi correzione baseline V23 sotto)

---

## Decisioni V23 — Ratificate 18/05/2026 mattina

| Voce | Decisione |
|---|---|
| **Baseline scaling corretta** | iPhone 13 portrait = **390pt** (misurato empiricamente, NON 430pt come V22 dichiarava). Tutte le percentuali pre-calcolate di V22 sono state sostituite con il pattern `pt * scaleFactor` (V23). |
| **Pattern `pt_originale * scaleFactor`** | Sostituisce le percentuali pre-calcolate di V22. La pt originale del design resta visibile nel codice (es. `size: 28 * scaleFactor`), facilitando cross-reference con le specifiche tipografiche. Unica fonte di verità del denominatore (`390` calcolato una volta in `LiveView`). |
| **Propagazione `scaleFactor` esplicita** | Da `LiveView` a tutti i sub-View che ne hanno bisogno (via parametro `CGFloat`). ButtonStyle riceve all'init (NO cattura ambiente). Sub-component nested ricevono propagazione esplicita (NO cattura implicita). |
| **Spacing/padding/frame in pt assoluti** | V22 aveva soglia 20pt per spacing. V23 estende: `frame(width:height:)` di bottoni icona (`34×34`) e bottoni overlay (`height: 56`) restano in pt assoluti — sono dimensioni hit-target/touch, non visuali. |
| **Validazione empirica** | iPhone 13 portrait: `scaleFactor = 390/390 = 1.0` → layout pixel-identico al pre-refactor. iPad pre-2018 portrait (768pt): `scaleFactor ≈ 1.97` → proporzionato. Test verde 18/05/2026. |

---

## Cambio open per ratifica (da V19, invariato)

**Proporzioni layout Vista LIVE** — proposta in attesa di test su device con sessione live attiva e contenuti reali. Vedi V19 per dettagli.

---

## MODELLO DI SINCRONIZZAZIONE — «GLI SCAFFALI» (ratificato Mauro 23/08/2026, riconfermato 24/08)

⛔ **Sede unica del modello.** Le parole sono di Mauro; qui sono messe nella forma di casa, non riformulate.

**D1 · LA TABELLA.** Quando una canzone parte si costruisce la sua tabella: **uno scaffale per ogni battito**. Ogni scaffale dichiara **sezione, battuta, quale battito, se accentato**.

**D2 · UN NUMERO SOLO.** Il motore consegna **UN numero**. La grafica va a quello scaffale e disegna. **Non converte, non divide, non conta: legge.**

**D3 · DOVE STA IL TRADUTTORE.** Il traduttore sta **nello SHOW**, mai nel motore audio. Il motore **non sa cosa sia una canzone e non deve saperlo**.

**D4 · L'ENTITÀ.** Ogni canzone è un'entità a sé, con o senza pausa prima di lei. «Una canzone vive e muore dentro se stessa» — parole di Mauro.

**D5 · COSA SIGNIFICA IL NUMERO.** È sempre «a che battito di **QUESTA** canzone siamo», mai «da quanto suona il motore».

**D6 · CHI CONTA E CHI SOTTRAE.** Il motore **conta e basta**; lo Show **sottrae**. Il motore **non azzera mai niente mentre suona**.

**D7 · DA DOVE COMINCIA.** La numerazione comincia al **PRIMO battito prodotto, conto alla rovescia COMPRESO**. Gli scaffali del conto alla rovescia **dicono «conto alla rovescia»**.

**D8 · L'ATTACCA FRA CANZONI.** 1→250, poi 1→180, **niente in mezzo**. All'orecchio un blocco unico, **sullo schermo due canzoni**. Pausa o non pausa **si decide in Q-Stage, mai dal vivo**. ⚠️ **Oggi l'attacca NON esiste, e la casella nemmeno.**

**D9 · IL CONTO ALLA ROVESCIA — FORMA.** Tre valori: **Off · 1 battuta · 2 battute**. Velocità e metrica **dalla PRIMA SEZIONE della canzone**: 100 BPM in 3/4 → **3-2-1**; 115 BPM in 4/4 → **4-3-2-1**. **Deve chiudersi esattamente sul battito 1 della musica.**

**D10 · IL CONTO ALLA ROVESCIA — NATURA.** È **parte della canzone, non un prefisso**. Ce l'hanno **tutti i dispositivi** e lo producono **uguale**.

⚠️ **Stato a HEAD `8ee5485`, misurato 24/08: il conto alla rovescia è ROVESCIATO rispetto a D9/D10.** Due difetti distinti, agli atti in `BUGS_QBEATS.md`: `TD-countin-rovesciato` e `TD-countin-impostazione-non-letta`.

### D17 — LE SCALETTE IDENTICHE (ratificata Mauro 24/08/2026)

**Le scalette devono essere identiche su tutti i dispositivi, e oggi niente lo verifica.**

⚠️ **Il difetto è ATTIVO ADESSO, non lo introduce l'attacca.** Il passaggio sezione→sezione è **senza interruzione** e **ogni dispositivo decide quando farlo contando la PROPRIA copia**; se due copie divergono **gli schermi si sfasano mentre il click resta insieme**, senza errore né avviso. **L'attacca non crea il problema: toglie la rete di sicurezza**, cioè lo stop di fine canzone che oggi rimette tutti d'accordo.

⛔ **Senza un canale fra i dispositivi la garanzia non esiste** — misurato sull'header LinkKit: Link trasporta **il tempo**; il nome del dispositivo si scrive in `Info.plist`, **non è impostabile a comando e non è leggibile dagli altri peer**.

**QUATTRO MISURE, TUTTE DICHIARATE PROVVISORIE:**
- **(a)** impronta della scaletta calcolata **in locale**, mostrata **IN FORMA DI PAROLE**, non di codice esadecimale;
- **(b)** mostrata **dove il musicista sta già guardando prima di partire**, mai in un menù impostazioni;
- **(c)** condividere una scaletta dev'essere **UN GESTO UNICO** fra dispositivi, non un caricamento manuale su ognuno;
- **(d)** impronta **stabile nel tempo**, così un cambiamento si nota da solo senza confronto.

⚠️ **Si sostituiscono quando arriva il protocollo Q-BEATS.**

⛔ **Misurato a HEAD `8ee5485`, 24/08: nessun meccanismo di verifica identità esiste.** L'unico riscontro su «hash» nel codice è `ios_app/QBeats/Models/TimeSignature.swift:11`, che è `Hashable` di Swift — **falso amico**, altra materia.

---

## TASSONOMIA DEI DIFETTI DI MISURA — sede unica (raccolta A224, 26/08/2026)

⛔ **QUESTA TASSONOMIA NON NUMERA, E L'ASSENZA DI NUMERI È LA REGOLA, NON UNA
DIMENTICANZA.** Gli ordinali sono esattamente ciò che ha prodotto il disordine
che questa sede raccoglie: al 26/08/2026 esistevano **tre «sesta» diverse**, in
tre documenti, riferite a **tre difetti differenti**, e **due erano tracciate in
git**. Nessuna delle tre sapeva delle altre. ⇒ **Ogni difetto ha un NOME e un
INDIRIZZO. Chi ne aggiunge uno gli dà un nome, mai un numero.**

⛔ **Le voci già incise altrove NON sono riscritte né rinumerate.** Restano dove
sono, con i loro ordinali storici, e qui si citano **per indirizzo**. Questa sede
**raccoglie**: non sostituisce, non corregge, non rinumera.

### Le tre polarità — si classifica per ciò che l'esito fa CREDERE, non per lo strumento

| polarità | la sonda dice… | mentre in realtà… |
|---|---|---|
| **P1 — IL VUOTO CHE SEMBRA UN FATTO** | «zero» | la sonda **non ha risposto affatto**: la domanda non è arrivata, o l'output non è mai stato stampato |
| **P2 — IL FATTO CHE SEMBRA UN VUOTO** | «zero» | l'oggetto **c'è**, in una forma che quella sonda non conta |
| **P3 — IL TUTTO CHE SEMBRA UNA PARTE** | un numero **plausibile** | quel numero è **il totale**: il filtro non ha filtrato niente |

⚠️ **P1 e P2 rendono entrambe zero, e si distinguono SOLO col controllo
positivo.** ⛔ **P3 è la più pericolosa delle tre, e per una ragione strutturale:
non rende zero — rende un numero che sembra una misura.** Nessun controllo
positivo sull'esistenza dell'oggetto la smaschera, perché l'oggetto c'è e la
sonda risponde. **La smaschera solo la quadratura: la somma delle classi deve
tornare col totale.**

### Le voci

| nome | polarità | causa meccanica | come si smaschera | dove è già inciso |
|---|---|---|---|---|
| **TRONCAMENTO DA `&&`** | P1 | `grep X && echo "positivo" && grep -c Y` — `grep` esce **1** su nessuna corrispondenza e la catena si spezza: **il controllo positivo non viene stampato proprio quando servirebbe** | separare le sonde con `;`, **mai** con `&&` | `LIBRO_MASTRO_QBEATS.md:323` (30/07/2026, «SESTA FORMA DI FALSO-NEGATIVO») |
| **STDERR SOFFOCATO** | P1 | `2>/dev/null` su un comando che l'ambiente **rifiuta**: `--jq` su un errore rende stringa vuota, e la variabile vuota diventa «ASSENTE» | ⛔ **mai `2>/dev/null` su una sonda il cui esito finisce in un referto**; un risultato **vuoto** e un comando **rifiutato** devono restare distinguibili | `HANDOFF/CONGEDO_CC_2026-08-26_A220.md` §1.2 (righe 105-126) e §8 (riga 350) |
| **RIGHE INVECE DI OCCORRENZE** | P2 | `grep` conta **RIGHE**, non occorrenze: una stringa spezzata da un a-capo **non esiste** per `grep`, e su un documento mandato a capo a 76 colonne ogni frase lunga può nascondersi in mezzo | contare sul **testo appiattito** (`tr '\n' ' '`), oppure scegliere stringhe **copiate da una riga sola** | `HANDOFF/CONGEDO_CC_2026-08-26_A220.md:439` («sesta faccia») |
| **PATTERN DEGENERE** | P3 | `grep -c $'\r'` su un file **senza CR** rende **il numero totale delle righe**, non zero: il pattern matcha ogni riga. ⚠️ Anche la forma ancorata `$'\r$'` mente allo stesso modo | confrontare l'esito col **totale** delle righe: se coincide, il filtro non ha filtrato | `LIBRO_MASTRO_QBEATS.md:352` (06/08/2026, «FALSO-*POSITIVO* DA FILTRO — PRIMA DELLA SUA SERIE») |
| **PARAMETRO IGNORATO IN SILENZIO** | P3 | l'API di GitHub Actions accetta parametri **sconosciuti senza errore** e li **scarta**: `?conclusion=success` non filtra nulla e la risposta rende l'insieme intero | **quadratura**: enumerare le classi e verificare che la somma torni col totale non filtrato | **misurato qui il 26/08/2026 — prima incisione** |

### La voce nuova, misurata alla fonte prima di inciderla

**[M]** Sul workflow `iOS Signed Build` (id `257042728`), a parità di istante:

    ?status=success              -> 582      corretto
    ?status=failure              ->  63      corretto
    ?status=cancelled            ->   1      corretto
    ?conclusion=success          -> 646      = IL TOTALE
    ?conclusion=failure          -> 646      = IL TOTALE
    ?zzzparametroinventato=xyz   -> 646      = IL TOTALE
    (nessun filtro)              -> 646
    enumerazione: 582 success + 63 failure + 1 cancelled = 646  ✅ quadra

⇒ **[M] La causa è dimostrata, non supposta:** un parametro **inventato di sana
pianta** rende lo stesso numero di `conclusion` ⇒ `conclusion` **non esiste** in
questo endpoint, e ciò che non esiste **viene scartato senza dirlo**. Il
parametro valido è `status`, che accetta anche i valori di conclusione.
⛔ **Un filtro sbagliato non fallisce: rende TUTTO.**

⚠️ **[A] Perché questa voce ha un predecessore e non apre una serie:** la
meccanica è diversa da `LIBRO:352` — là un pattern degenere che matcha tutto, qui
un parametro scartato — ma **l'esito è identico**: il filtro non filtra e il
totale si presenta come sottoinsieme. ⇒ **La riga `LIBRO:352` si dichiarava
«PRIMA DELLA SUA SERIE»: da oggi quella serie ha un secondo membro**, ed è la
polarità **P3**.

### ⛔ Ciò che è stato OSSERVATO e NON è stato inciso

**[M]** Alle 12:0x del 26/08 la stessa query `?status=success` rese **173**, poi
**494**, poi l'enumerazione rese **580**. Alle 12:2x, **sei chiamate identiche
rendono 582 stabilmente**, e 582 coincide con l'enumerazione.
⇒ **[M] «Numero non riproducibile» NON si riproduce, quindi non è una voce.**
L'ipotesi residua — un indice filtrato che si allinea in ritardo — **è
un'ipotesi**, e in questa sede non entra. ⚠️ **Resta il fatto operativo, che
vale comunque:** un `total_count` filtrato, letto una volta sola e mai
quadrato, ha reso un numero **sbagliato di quattrocento** senza alcun segnale.

### La regola che tiene insieme tutte le voci

⛔ **Il controllo positivo non è un ornamento: è la sonda.** Un oggetto che
**sai** esistere, cercato **con lo stesso identico comando**. Senza, non stai
misurando: stai sperando.
⛔ **E per la polarità P3 il controllo positivo NON BASTA** — lì la sonda
risponde e l'oggetto c'è. **Serve la quadratura della somma col totale.**

⚠️ **Rimando, senza deciderne la collocazione:** `R-δ.10` incide un **falso-UNO**
— un ID che risulta occupato perché è sottostringa del base64 di un font — e
dichiara di **non** decidere lì la tassonomia. È un riscontro **vero su
un'occorrenza reale ma di un altro oggetto**: non è nessuna delle tre polarità
sopra. **Si nomina qui per indirizzo e si lascia aperto.**

---

## ⚠️ DA V32 I RIASSUNTI VANNO IN CODA — dichiarazione di transizione, 24/08/2026

⛔ **Questo documento ha i riassunti VECCHI in testa (`Delta V31` … `Delta V23`, righe 6-64) e i NUOVI qui in coda.** Non è disordine: è una **transizione datata**, ratificata da Mauro il 24/08/2026 insieme alla regola **R-δ.7**. I vecchi **restano dove sono**: spostarli costerebbe quanto aggiungerne uno in testa, cioè rompere ventinove citazioni. **Si marca, non si riscrive.**

**Delta V32 vs V31:**

- **Capitolo NUOVO «MODELLO DI SINCRONIZZAZIONE — GLI SCAFFALI»**, sede unica delle decisioni **D1-D10** e **D17** di Mauro (23/08, riconfermate 24/08). Nessuna di esse esisteva in alcun canonico prima di oggi: vivevano solo in chat.
- **Regola NUOVA `R-δ.7`** nel capitolo R-δ: la testa di un documento citato **non cresce mai**; ciò che si accumula va in coda. Vale per tutti i canonici, BOX3 compreso.
- ⚠️ **La convenzione precedente non era scritta**: misurato il 24/08, zero regole sulla posizione nei cinque canonici e nella Costituzione.


**Delta V33 vs V32:**

- **Tre regole NUOVE nel capitolo R-δ, tutte sul cancello degli identificativi di mandato.** **`R-δ.8`** — un ID è occupato quando è **assegnato a un lavoro**, non quando è **nominato come campione** dentro un documento che ne verifica la disponibilità (ratificata referee, approvata Mauro). **`R-δ.9`** — **il documento che nomina un campione lo consuma**: i numeri candidati non si scrivono per esteso, si nomina solo quello assegnato (rilievo CC, ratificata referee). **`R-δ.10`** — la gamba **contenuto** della sonda esclude `DESIGN/`: la stringa `A219` compare una sola volta nel repo, dentro il **base64 di un font woff2**, ed è un **falso-UNO** — polarità nuova rispetto ai falsi-zero già censiti (misurata referee).
- ⚠️ **Nessuna riga esistente è stata riscritta**: le tre regole sono in coda al capitolo R-δ, il numero di versione è cambiato **dentro la riga** in testa, e questo blocco Delta sta in coda come prescrive `R-δ.7`.
- ✅ **Misurato prima di scrivere: l'inserimento NON sposta alcuna citazione nuda.** Tutte le citazioni `BOX5_QBEATS.md:NN` del corpus puntano a righe **≤ 390**; il punto d'innesto è la **806**.

**Delta V34 vs V33:**

- **Capitolo NUOVO «TASSONOMIA DEI DIFETTI DI MISURA»**, sede unica dei cinque difetti di misura che vivevano sparsi in tre documenti con nomi che si somigliavano. ⛔ **Non numera**: ogni difetto ha un **nome** e un **indirizzo**, perché gli ordinali sono precisamente ciò che ha prodotto il disordine — al 26/08 esistevano **TRE «sesta» diverse**, riferite a tre difetti differenti, **due tracciate in git**. ⛔ **Le due voci già incise (`LIBRO:323` e `LIBRO:352`) NON sono state riscritte né rinumerate:** si citano per indirizzo.
- **Voce NUOVA, prima incisione — «PARAMETRO IGNORATO IN SILENZIO»:** l'API di GitHub Actions scarta i parametri sconosciuti **senza errore** e rende l'insieme intero. Dimostrata per controprova, non supposta: un parametro **inventato** rende lo stesso numero di `?conclusion=`. ⇒ **La riga `LIBRO:352`, che si dichiarava «PRIMA DELLA SUA SERIE», da oggi ha un secondo membro**, ed è la polarità **P3**.
- ⛔ **Una voce candidata NON è stata incisa perché non si riproduce:** «numero non riproducibile» (173 → 494 → 580) rende **582 stabile su sei chiamate identiche**. **Osservata, dichiarata, non incisa.**
- ✅ **Misurato prima di scrivere: l'innesto alla riga 943 NON sposta alcuna citazione nuda.** Le citazioni `BOX5_QBEATS.md:NN` più alte del corpus sono `:564` e `:566`, che **precedono** l'innesto. ⚠️ **Vivono solo sulla gamba `E:`** (`HANDOFF/A58-USCITA-FINESHOW-RICOGNIZIONE.txt`): su `C:` il massimo è **390**, e una sonda che guardi solo `C:` **sottostima**.

**Delta V36 vs V35:**

- **MARCATURA ADDITIVA nel blocco 3**, riga «STOP nel player è REVERSIBILE»: **[R] Mauro il 28/08 ha sciolto «da dov'eri» in CANZONE e SEZIONE** — opzione (B), la (A) scartata. **Zero parole riscritte:** la riga del 27/08 resta, e la marcatura le sta accanto.
- ⚠️ **La decisione è incisa come CONSEGUENZA, non come voce isolata:** nasce dalla rimozione dell'overlay di ripresa (§2, «nessun pannello sopra») — tolto il pannello, la scelta fra i suoi due bottoni diventa un default silenzioso, e questa è la scelta di quel default. **Chi rimettesse il pannello riaprirebbe una scelta.**
- **[M] Costruita in A240, commit `d0225ef`** (terza partenza che conserva entrambi gli indici, tre siti cablati). ⛔ **Collaudo su device NON eseguito** al momento di questa incisione.
- ✅ **Misurato prima di scrivere: nessuna citazione nuda slitta.** La riga BOX5 più alta citata dal corpus è **`:562`**; entrambi gli innesti di questa versione stanno **oltre la riga 1059**, quindi tutte le citazioni restano a monte e non si muovono. Controllo positivo sulla stessa sonda: le citazioni nel sorgente Swift (`:68 :331 :354 :458`) sono viste.

**Delta V35 vs V34:**

- **Capitolo NUOVO «MODELLO DI SESSIONE Q-LIVE»**, sede unica delle decisioni di sessione che fino a oggi vivevano SOLO in due chat e in un documento su Drive. Contiene: le **decisioni 6-18 del 26/08** di CD (ratificate in chat da Mauro, **nessun device le ha viste**), la **copy della conferma** con la riga ambra, le **decisioni di Mauro del 27/08 sera** che le superano in parte (bivio a tre vie sulla freccia dopo lo stop · le tre facce del dettaglio · «STOP significa una cosa sola» · il pulsante del dettaglio si chiama END SHOW · la decisione 8 regge · l'ambiguità di «gira» sciolta), e le **tre sorti della decisione 7**.
- ⛔ **La decisione 7 è SPACCATA IN TRE, e non è un vezzo:** la reversibilità dello stop REGGE, l'overlay di ripresa è **RATIFICATA E MAI COSTRUITA**, il comando del dettaglio REGGE ma CAMBIA NOME. Una riga sola avrebbe detto una cosa falsa qualunque parola si scegliesse. ⚠️ **«Ratificata e mai costruita» si legge in modo diverso da «superata»**, e fra sei mesi la differenza conta.
- **VINCOLO APERTO inciso, non risolto:** la riga ambra «This will stop the other devices too» ha perso il suo innesco quando l'alert a due bottoni è diventato un bivio a tre vie. **Non è stata ritirata**: deve vivere dentro il bivio, e ora ha DUE inneschi. In mano a CD.
- 🚨 **COLLISIONE rilevata da CC e NON risolta:** «END SHOW» è insieme l'**etichetta di stato** della striscia viva a fine scaletta (decisione 10) e il **pulsante distruttivo** del dettaglio (decisione (d) del 27/08) — stessa schermata, stesse due parole, due significati. Contando il titolo della schermata di fine scaletta dentro il player, i sensi sono **tre**. Stessa forma di collisione che il 26/08 ha portato a rinominare «Mode» in «Role».
- ⛔ **Il puntatore all'indietro da «Vista LISTA» NON è stato messo, ed è una MISURA non una dimenticanza:** inserire una riga in quel capitolo sposterebbe di +1 dodici citazioni nude a BOX5, **due delle quali stanno nel sorgente Swift** (`QLiveShowDetailView.swift` cita `BOX5:458` in due punti, e il mandato era di sola lettura sotto `ios_app/`). Va fatto nello stesso passaggio che ripara quelle citazioni.
- ✅ **Misurato prima e dopo aver scritto: l'innesto in coda NON sposta alcuna citazione nuda.** Le undici righe-bersaglio citate dal corpus (`:253 :324 :328 :331 :354 :390 :401 :404 :458 :532 :562`) sono state confrontate una a una col blob committato: **tutte invariate**. Zero righe esistenti riscritte o cancellate.

---

## MODELLO DI SESSIONE Q-LIVE — ratificato in chat da Mauro 26/08 e 27/08/2026, MAI VISTO SU DEVICE

### Perché questo capitolo esiste, e cosa è costato non averlo

⛔ **Questo modello è vissuto per un giorno intero soltanto dentro due chat e un documento su Drive.** Nessun canonico lo conteneva.

⚠️ **Il conto è arrivato il 27/08:** il referee, non avendo mai letto il documento di CD, ha fatto **ridecidere a Mauro tre cose che erano già chiuse col 26/08** — il salto di canzone, la striscia viva, il testo della conferma. Mezza serata bruciata a rifare decisioni che esistevano già.

⇒ **La regola di casa dice che una ratifica che non atterra in un canonico non esiste.** Questo capitolo la fa atterrare. Chi lo legge fra un mese deve sapere che è nato da un debito, non da una pianificazione.

**⚠️ STATO — vale per TUTTO ciò che segue:** ratificato **in chat** da Mauro. **Nessun device ha visto niente di tutto questo.** Non è collaudato, non è costruito, e in almeno un caso è ratificato da mesi e mai costruito (vedi le sorti della decisione 7).

⚠️ **Sede:** questo capitolo attraversa il player, il dettaglio, il bivio, la semantica di STOP e la copy di una conferma. **Non appartiene alla «Vista LISTA»**, che è una delle superfici che tocca. ⛔ **Il puntatore all'indietro dal capitolo «Vista LISTA» NON è stato messo, ed è una misura, non una dimenticanza:** inserire una riga lì sposterebbe di +1 dodici citazioni nude a BOX5, **due delle quali stanno nel sorgente Swift** (`QLiveShowDetailView.swift` cita `BOX5:458` in due punti). Va fatto nello stesso passaggio che ripara quelle citazioni, non prima.

---

### 1 · BLOCCO 1 — le decisioni del 26/08/2026 (CD, ratificate in chat da Mauro)

Fonte: documento di chiusura del 26/08 di CD, **revisione 2** (la prima è marcata superata e corregge la 11-bis). Numerazione in continuità col registro di CD.

| # | Decisione | Sorte al 27/08 |
|---|---|---|
| **6** | **La freccia non ferma mai niente.** Player che gira → dettaglio · Player fermo → SHOW / card | ⚠️ **prima metà chiarita, seconda metà SUPERATA** — vedi §2 |
| **7** | **Solo STOP ferma.** Nel player ferma la musica (reversibile, overlay di ripresa) · nel dettaglio ferma tutto **e** esce | ⛔ **SPACCATA IN TRE SORTI DIVERSE** — vedi §3 |
| **8** | **Nel dettaglio entrato dal player la freccia non c'è.** Unica porta: il comando di uscita | ✅ **REGGE** — confermata 27/08 |
| **9** | **Salto di canzone:** tocco su riga = selezione **inerte** · secondo gesto + conferma per agire · dopo la quarta si prosegue con quinta, sesta, settima · sempre in standby | ✅ regge |
| **10** | **Striscia viva** nel dettaglio: sezione in corso · `Standby · ⟨canzone⟩` · `END SHOW` a fine scaletta | ⚠️ regge, **ma vedi la collisione in §5** |
| **11** | **`CHART MODE`** per la modalità statica · **`Q-LIVE MODE`** per la dinamica, così la coppia si legge come coppia | ✅ scelta di Mauro, contro la raccomandazione di CD |
| **11-bis** | **`Mode` in Impostazioni → `Role`.** È il selettore del **ruolo Link** (Director / Follower), dentro la sezione «Ableton Link» — **non del metronomo**. Rinominarlo libera la parola «Mode» per Chart Mode | ✅ approvato **sull'intento**; l'indirizzo è stato **corretto il 26/08 sera** dopo una misura falsa. ⚠️ È un cambio di sola stringa **ma nella sezione Link**: CI da guardare |
| **12** | **Riga attiva in Chart Mode: SPENTA di default** | ✅ regge |
| **13** | **Il velo dell'attesa si accorcia:** si ferma sotto la fascia dell'intestazione, **la freccia resta scoperta**. Il tap-per-partire cede circa l'8% sul bordo alto — il più scomodo da raggiungere, e qui è un pregio | ✅ regge. *«dev'essere scomodo da raggiungere per scongiurare chiusure accidentali»* |
| **14** | **La base si ferma col salto.** Abbandonando una canzone si ferma tutto ciò che è suo | ✅ regge — **richiede lavoro che oggi non esiste** |
| **15** | **Overlay SCALETTA assorbito dalla stanza dettaglio.** Riordino durante la sessione **tolto**, non rimandato | ✅ regge |
| **16** | **La conferma sta sul confine, non su un bottone.** Ovunque la sessione stia per morire, chiede. **Due INNESCHI:** il comando di chiusura nel dettaglio · la freccia dal player fermo verso le card | ⚠️ **i due inneschi hanno sorti DIVERSE** — vedi §2 |
| **17** | **`List view` = `Chart Mode`.** Nome vecchio della stessa cosa, non un elenco di canzoni | ✅ regge |
| **18** | **Barra delle stanze: centrata** (decisione Mauro 19/08, riemessa) | ✅ regge |

#### 1.1 · La copy della conferma — 26/08, supera quella congelata il 18/07

«Stop & Exit» e «Stop & Switch» non tornano più: non esiste più uno «switch», e le due porte che nominavano sono chiuse.

```
End the show?
You'll lose your place in the setlist.
[ Cancel ] [ End show ]   ← distruttivo
```

Con Link Start/Stop acceso **e almeno un collegato**, si aggiunge la riga ambra asimmetrica:

```
⚠ This will stop the other devices too.
```

**Forma:** coppia `Cancel` / azione distruttiva colorata — modello inciso nel libro mastro il 26/07, dichiarato *«modello per ogni conferma distruttiva successiva»*.

---

### 2 · BLOCCO 2 — le decisioni di Mauro del 27/08/2026 sera, che SUPERANO in parte il blocco 1

⛔ **Superano, non sostituiscono: il blocco 1 resta leggibile sopra, e qui si vede cosa ha superato cosa e quando.**

**(a) 27/08 — Il bivio a tre vie.** La freccia premuta **con lo show fermo** non porta più direttamente alle card: alza un bivio a **tre** vie.

- **X** sul perimetro → annulla, si resta nel player fermo
- **END SHOW** → chiude, si torna alle card
- **SHOW DETAILS** → si entra nel dettaglio con lo show fermo

⚠️ **Il nome di quella terza via è `SHOW DETAILS`, NON «SETLIST» — scelto da Mauro il 27/08.** La parola «setlist» nomina già la struttura dati, e la sezione dell'app si chiama Shows: usarla sul bivio avrebbe creato la terza collisione di nome della giornata.

⇒ **La terza via nasce da un buco:** dopo lo stop, con due sole vie, per guardare la scaletta bisognava chiudere lo show.

⇒ **SUPERA la seconda metà della decisione 6** («Player fermo → SHOW / card»): la destinazione «card» sopravvive, ma come **una delle tre**, non più diretta.

⇒ **SUPERA la copy del §1.1**, che ha due bottoni. ⚠️ **NON supera il conteggio degli inneschi della 16**, che sono un'altra cosa: quelli sono i punti d'ingresso della conferma, non le sue uscite.

⇒ **Delle due porte della 16:** il comando di chiusura nel dettaglio **regge e cambia nome** (vedi (d)); la freccia-dal-player-fermo **è sostituita da questo bivio**.

**(b) 27/08 — Il dettaglio ha TRE facce, non due.**

| da dove si entra | stato dello show | cosa offre |
|---|---|---|
| **dalle card** | nessuno show in corso | lista + **avvio da una canzone a scelta** |
| **dal player** | show attivo | lista + salto + **RESTART** + **RESUME** + **END SHOW** |
| **dal bivio** | show fermo | lista + salto + **RESUME** + **END SHOW** |

⛔ **Nella terza faccia NON c'è RESTART**, ed è voluto: **butterebbe via il punto che l'utente sta cercando di non perdere**.

⚠️ **Rettifica di percorso, incisa perché non sembri una svista.** Una formulazione intermedia del 27/08 diceva che dalla terza faccia **non si potesse chiudere lo show**, con la motivazione che *«chiuderlo era possibile un istante prima»*, al bivio. ⇒ **Quella motivazione cade**, e cade **per la decisione (d)**, non per distrazione: da quando END SHOW vive nel dettaglio in **tutte** le facce, la terza non fa eccezione.

**(c) 27/08 — «STOP» significa UNA COSA SOLA, ovunque: ferma tutto.** Mauro non ha scelto fra i due significati: **ha detto che il significato è uno.** L'app poi concede di annullare e di riprendere, **ma è una concessione, non un secondo senso.**

- Parole di Mauro, agli atti: ***«lo show è compromesso, ma è una scelta dell'utente»***.
- ⇒ **CHIUDE l'aperto lasciato dal 26/08** sul doppio significato di STOP.

**(d) 27/08 — Nel dettaglio il pulsante NON si chiama «STOP»: si chiama «END SHOW».** Non si sdoppia il significato di STOP: **si cambia il nome del pulsante.**

- **STOP** vive nel player e ferma il click. **Reversibile.**
- **END SHOW** vive nel dettaglio e chiude la sessione. **Distruttivo.**
- ⚠️ **Vale in TUTTE le facce del dettaglio, anche con lo show che gira.**
- ⇒ **CONSEGUENZA DICHIARATA E RATIFICATA:** dal dettaglio **non si può più fermare il click restando dentro**. Per fermare senza chiudere si torna al player. **È voluto — nel dettaglio non si suona, si decide.**

**(e) 27/08 — La decisione 8 regge, e non era in conflitto col resto.** Nel dettaglio entrato dal player la freccia non c'è, e **la via di ritorno non è la freccia: è il comando di ripresa.** Navigazione e transport restano separati.

**(f) 27/08 — L'ambiguità della parola «gira» è sciolta.** Nella decisione 6, **l'attesa fra due canzoni conta come «player che gira»**, e la freccia da lì porta al **dettaglio**. ⛔ Quella parola non deve restare leggibile in due modi.

**(g) 27/08 — LA REGOLA CHE RENDE LA (d) UNA STRUTTURA E NON UNA CONSEGUENZA SUBITA.** Dal foglio di CD ratificato la sera del 27/08, verbatim:

> **«Nel dettaglio non manca STOP: nel dettaglio non c'è il transport del click.»**

⇒ **Due famiglie di comandi, e non si mescolano:**

| famiglia | comandi | dove vivono |
|---|---|---|
| **spostano lo SHOW** | `RESTART SONG` · `RESUME` · `END SHOW` | nel dettaglio |
| **regolano il CLICK** | `STOP` · `PLAY` | **dove il click si vede**, cioè nel player |

⚠️ **Perché conta:** senza questa riga, l'assenza di STOP nel dettaglio si legge come una **mancanza** — qualcosa che prima o poi qualcuno «aggiusterà» rimettendocelo. Con questa riga si legge come una **divisione**: nel dettaglio non si suona, si decide, e il transport non ci abita per costruzione. ⇒ **Chi in futuro proponesse di aggiungere STOP al dettaglio sta proponendo di rompere questa regola, non di colmare un buco.**

---

### 3 · BLOCCO 3 — LE TRE SORTI DELLA DECISIONE 7

⛔ **La 7 non è «superata» né «riformulata»: le sue tre metà hanno sorti diverse, e una riga sola direbbe una cosa falsa qualunque parola si scegliesse.**

| metà della 7 | sorte | perché |
|---|---|---|
| **«STOP nel player è REVERSIBILE»** | ✅ **REGGE** | confermata da Mauro il 27/08: dopo lo stop si riparte da dov'eri. **Non superata.** |
| **«con un OVERLAY DI RIPRESA»** | ⛔ **RATIFICATA E MAI COSTRUITA** | l'overlay **esiste nel codice** e il pulsante STOP **non lo raggiunge**: si accende da un solo stato, acceso da una sola funzione che ha due soli chiamanti — una schermata di debug e l'esecutore di azioni MIDI. ⚠️ **E il 27/08 Mauro ha deciso una forma DIVERSA:** dopo lo stop **resta la schermata del player**, ferma e pronta a ripartire. **Nessun pannello sopra.** |
| **«nel dettaglio ferma tutto ED ESCE»** | ✅ **REGGE nella sostanza, CAMBIA NOME** | il comportamento non cambia; il pulsante si chiama **END SHOW** — vedi §2(d) |

⚠️ **«Ratificata e mai costruita» si legge in modo diverso da «superata», e fra sei mesi la differenza conta.** La prima dice che qualcuno aveva deciso e nessuno ha eseguito; la seconda dice che la decisione non vale più. **Qui vale la prima.**

⇒ **Il difetto che ne discende è tracciato:** il ticket sul punto perso dopo lo stop, aperto il 27/08 su osservazione device di Mauro.

⇒ ✅ **MARCATURA ADDITIVA 28/08 — «DA DOV'ERI» È SCIOLTO, e la riga sopra resta com'è.** Mauro ha deciso il 28/08 che «da dov'eri» significa **CANZONE e SEZIONE**: opzione **(B)** di un bivio posto dal referee; la **(A)** — canzone giusta, sezione riportata all'inizio — è **scartata come rimedio parziale**. ⇒ **Costruita in A240 (`d0225ef`); collaudo device NON ancora eseguito.**

⚠️ **[A] E la scelta nasce come CONSEGUENZA della riga qui sopra, non a fianco:** tolto l'overlay di ripresa — «nessun pannello sopra», §2 e riga precedente — **la scelta fra i suoi due bottoni smette di essere dell'utente e diventa un default**. ⇒ **Questo è quel default.** Chi un giorno rimettesse il pannello deve sapere che sta riaprendo una scelta, non aggiungendo un comodo.

---

### 4 · VINCOLO APERTO — la riga ambra ha perso il suo innesco

🚨 **Non è una decisione, ed è la ragione per cui sta qui.** La riga *«This will stop the other devices too»* viveva **dentro l'alert della decisione 16**. Quell'alert, dopo il bivio a tre vie, **non ha più un innesco**.

⛔ **La riga NON è stata ritirata.** Deve vivere **dentro il bivio**, e ora ha **DUE inneschi**: END SHOW dal bivio **e** END SHOW dal dettaglio.

⇒ **È in mano a CD, e qui è inciso come VINCOLO APERTO, non come cosa fatta.** Chi costruisce il bivio senza quella riga toglie all'utente l'unico avviso che sta per fermare anche gli strumenti degli altri.

---

### 5 · ⚠️ COLLISIONE RILEVATA DA CC, NON RISOLTA — «END SHOW» in due sensi sulla stessa schermata

**Nessuno l'aveva nominata, e non è una decisione: è un conflitto fra due decisioni entrambe vigenti.**

- La **decisione 10** prescrive che la **striscia viva del dettaglio** mostri `END SHOW` **a fine scaletta**. Lì è un'**etichetta di stato**: dice *dove sei arrivato*.
- La **decisione (d) del 27/08** chiama `END SHOW` il **pulsante distruttivo del dettaglio**. Lì è un'**azione**: dice *cosa succede se tocchi*.

⇒ **Stessa schermata, stesse due parole, due significati.** ⚠️ **È la stessa forma di collisione che il 26/08 ha portato a rinominare «Mode» in «Role» e «List view» in «Chart Mode».**

⛔ **Inciso come aperto, non risolto: decidono CD e Mauro.** ⚠️ E fuori dal dettaglio le stesse due parole sono **già** il titolo della schermata di fine scaletta dentro il player: **contando quella, i sensi sono tre.**


---

## SETTE REGOLE DI METODO — nate misurando, 27-29/08/2026 (raccolta A249)

> **Perché stanno qui e non in un referto:** ognuna è nata da un errore **già commesso** in questi tre giorni, e ognuna sarebbe rifatta da chi non la trova **prima**. Sede unica: questo capitolo. ⛔ **Non si riassumono altrove: si citano.**

**1 · LE CINTURE SI METTONO SULL'ATTO, NON SUL BOTTONE.** I bottoni si moltiplicano, l'atto no. Una guardia appesa a un controllo nasce già dimenticata dal controllo successivo. *(CD — terza migrazione dello stesso tipo in tre giorni. Istanza misurata: gli inneschi dell'avvio sono tre, e uno è il MIDI.)*

**2 · 🚨 UN GUASTO PUÒ ESSERE L'UNICA IMPLEMENTAZIONE DI UNA FUNZIONE CHE NESSUNO HA SCRITTO.** Chiudendolo la si perde, e **nessuna riga dice che è sparita**. ⇒ **Quando si chiude un guasto, si enumera cosa stava facendo per sbaglio, PRIMA che se ne vada.** *(Nato da `TD-show-non-abbandonabile`: la porta rotta ricostruiva il runner, e quella ricostruzione era anche l'unica uscita da uno show. A244 ha chiuso il guasto e ha creato un bloccante palco.)*

**3 · UN VERDETTO SULLA SOPRAVVIVENZA NON È UN VERDETTO SUL FUNZIONAMENTO.** Che un dato sopravviva non dice che il comando che lo usa funzioni. *(Firma A, +1 punto di ripresa: il dato sopravviveva davvero, e l'esecutore non onorava la sezione.)*

**4 · UN VERDETTO CHE NOMINA UNA FONTE NON È UN VERDETTO CHE LA FONTE ESISTE.** ⇒ **Accanto a ogni «si legge da» va il nome di chi lo pubblica, o è un desiderio.** *(C1 fu scritto «si legge dal motore» quando nessuno pubblicava quel numero; ritirato e poi ripristinato quando si è misurato che la fonte c'era, privata.)*

**5 · 🚨 LA DOMANDA È «IL MOTORE LO SA?», NON «LO PUBBLICA?».** ⚠️ **Tre volte su tre, in tre giorni, la cosa che mancava era PRIVATA, non assente** — e le tre volte sono **errori del referee**, che si incidono come tali. **La protesi la paga chi suona ogni sera; l'esposizione la paga chi costruisce, una volta.** *(La terza istanza ha prodotto `snapshotSectionPosition` e la sincronizzazione istantanea al rientro, dopo che «la fonte non esiste» era già stato scritto in un mandato.)*

**6 · GLI ID DEI MANDATI-CODICE VIVONO NEI MESSAGGI DI COMMIT, NON NEI FILE.** Una sonda ID senza `git log --grep` **ha un buco**, e ⛔ **un positivo a zero è una sonda cieca, non un ID libero**. *(Reperto di CC, A247: la prima sonda rendeva zero anche sui controlli positivi, perché A244 e A245 non vivono in nessun file.)* Vedi anche la TASSONOMIA DEI DIFETTI DI MISURA, sopra.

**7 · IL TEST DA APPLICARE A OGNI STATO CHE SI DISEGNA:** se questo stato si apre e l'utente **cambia idea**, con quale gesto esce — **e QUEL GESTO È COSTRUITO?** ⛔ **«Disegnato» non è una risposta.** *(CD. È il test che avrebbe intercettato `TD-show-non-abbandonabile` prima del device.)*

