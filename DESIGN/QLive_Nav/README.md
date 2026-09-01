# DESIGN/QLive_Nav — Freeze CD "Cancello 1" (Q-Live Nav)

Contratto di design per la navigazione Q-Live/Q-Stage. File CD, versionati per derivazione
storica. Zero sha256 incisi qui sotto come puntatori — sono dichiarati nel messaggio di
commit e nella cronologia git, non in questo documento (REGOLA ANTI-CASCATA).

## Quale file governa cosa — indice normativo (20/08/2026)

Questa cartella contiene file che si somigliano nel nome e NON hanno lo stesso
peso. Il nome del file non dice il suo stato: lo dice questa tabella.

| file | stato |
|---|---|
| `2026-07-11_Q7-Q16.html` | **VIVO — sorgente dei token.** Colori e misure si prendono da qui. Se un altro file di questa cartella porta un token diverso, vince Q7-Q16. |
| `2026-08-20_..._rev5__SUPERSEDE-rev4-TESTO__ritiri-e-correzioni_390x844.html` | **NORMATIVO — il testo in vigore per Q-Live › Shows.** Supersede la rev4 **nel solo testo**: due ritiri e quattro correzioni. **Zero cambi di disegno.** Opzione A ratificata (Mauro, 20/08). ⚠️ Due difetti noti: cita due righe di canonici senza ancoraggio a commit (puntatori destinati a slittare), e chiama la rev3 con un nome che non ha (manca `__rev3-NORMATIVA`). **Corretti dalla nota del 21/08, riga sotto.** ⛔ **MARCATURA 21/08 (A144) — SUPERATA IN PARTE DALLA rev6, NON ABOLITA.** Zero parole riscritte sopra: si marca. La rev6 la supera sui **due soli selettori** che nomina — **ancoraggio del badge `.dhrow`** e **ritiro del `padding:0 4px` su `.navbar .back`**. **Su tutto il resto la rev5 resta IN VIGORE**, parola per parola. |
| `2026-08-21_..._NOTA-DI-CORREZIONE-rev5__citazioni-e-scostamento.html` | **SI LEGGE ACCANTO ALLA rev5** — non la sostituisce, non e' una rev6. Supera i **due difetti di citazione** della rev5 (riferimento per riga ritirato, nome della rev3 corretto) e riformula il segmento inerte del dettaglio **da «proposta» a «scostamento»**: il contratto del 18/07 lo prescrive gia' vivo, oggi il codice lo tiene muto. **Chi legge la rev5 deve leggere anche questa.** |
| `2026-08-20_..._rev4__SUPERSEDE-rev3__navbar-centrata-ritmo-testata_390x844.html` | ⛔ **SUPERATA NEL TESTO dalla rev5.** Conservata di proposito: è l'artefatto che la rev5 rettifica, e senza di essa i due ritiri non hanno referente. **Il suo DISEGNO resta valido** — i quattro selettori sono identici nelle due. ⚠️ Contiene un'affermazione errata su «List view», ritirata dalla rev5. |
| `2026-08-06_..._rev3-NORMATIVA.html` | **NORMATIVA per tutto ciò che rev4/rev5 non toccano** — parola per parola. I quattro selettori del dettaglio sono superati; il resto no. |
| `2026-08-06_..._rev2-BUONA.html` | ⛔ **NON NORMATIVO.** Conservato come impronta dell'evento di ratifica: è il file che il referee lesse e approvò, e contiene ancora la voce che quella ratifica ELIMINA. ⚠️ **Il nome «BUONA» dice il contrario del suo stato.** **NON RINOMINARE:** un canonico lo cita con questo nome. |
| `2026-07-18_QLive-Exit-in-Play.html` | **CONTRATTO rev.2 per ⟦S-EXIT⟧ e ⟦S6F⟧.** ⚠️ Il suo `:root` è una copia di lavoro: se un token diverge, vince Q7-Q16. ⚠️ **MARCATURA 01/09/2026 (A306) — SUL DETTAGLIO SENZA OGGETTO, SULLA LISTA VIGENTE. Zero parole riscritte sopra: si marca.** Il foglio CD del 30/08 abolisce il selettore delle stanze nel dettaglio dello show attivo — verbatim: «Abolire la porta è più forte che chiedere conferma: il contratto 18/07 lì non è violato, è rimasto senza oggetto — e resta vigente sulla LISTA, dove le sue due porte esistono ancora.» Vedi la riga sotto per il foglio. |
| `2026-08-21_..._rev6__SUPERSEDE-rev5-SU-2-SELETTORI__ancoraggio-Read-only-e-ritiro-4px_390x844.html` | **NORMATIVO sui DUE selettori che tocca.** Riga d'indice **scritta da CD** (pannello ④ del foglio), riportata qui verbatim: rev6 · 21/08 · SUPERSEDE rev5 su 2 selettori — **.dhrow: baseline** (cadono center e flex-start; cade .ro margin-top) · **.navbar .back: padding 0 4px RITIRATO**. Non tocca geometria A, badge, .roomseg, .viewtoggle. ⛔ **Porta 5 errata AUTOCITANTI di giornata**: regola riformulata («stesso ancoraggio del livello 1», non «sul baseline») · origine y · movimento Ⓓ 13,97 · **lh 1.05→1.12 inesistente nell'app** · **nesso causale ritirato: il gradino È l'ancoraggio (5–8pt su `baaa172`), non la geometria A**. **Aperti:** H (altezza badge nell'app) · il titolo più in alto, inspiegato · lh 1.12 ratificata ma inattuabile. **Le due decisioni non si muovono**; i numeri assoluti del foglio **non si incidono**. ⚠️ **Trasporto: da Drive solo il tasto Scarica — i byte sono l'unico giudice, mai il nome.** |
| `2026-08-25_..._Show-in-esecuzione__rev2-RESTART-SONG-e-gruppo-2-1_390x844.html` | **PROPOSTA rev2 — APPROVATA DA MAURO il 25/08.** ⚠️ **In attesa di collaudo device: nessun dispositivo l'ha vista.** Governa il **menù dello show in esecuzione**. **Supersede il predecessore di pari data su DUE punti soli** — **nomi delle voci** · **divisione del menù in due gruppi**; **sul resto non cambia una parola.** ⛔ **NON tocca** rev5, nota 21/08, rev6, freeze 06/08, contratto 18/07. ⚠️ **I DUE FILE DEL 25/08 NON SI DISTINGUONO PER NOME — solo per PESO:** questo, **APPROVATO, 106 024 byte**; il predecessore `2026-08-25_..._Show-in-esecuzione__N1-N5_390x844.html`, **SUPERATO, 97 267 byte**, **non depositato — lasciato su Drive**. ⚠️ **SCOSTAMENTO SEGNALATO, NON EMENDATO:** il foglio cita al suo interno un file `__rev2-ratificata` che **non esiste** — zero corrispondenze su `C:`, `E:` e Drive, con controllo positivo che trova i due file del 06/08 su **tutti e tre** i supporti. Le misure che cita sono però **identiche nei due file del 06/08**, quindi la sostanza tiene. ⛔ **Il foglio di CD non si riscrive: lo scostamento si annota qui.** |
| `2026-08-24_QLive-Exit-in-Play_NOTA-DI-CORREZIONE-contratto-18-07__ritiro-chip-N-on-Link.html` | **SI LEGGE ACCANTO AL CONTRATTO 18/07** — ritira la targhetta **«N on Link»**. **Chi legge il 18/07 deve leggere anche questa.** ⚠️ **NON È IN QUESTA CARTELLA: 27 145 byte, vive solo su Drive** (`Qbeats_IN_CD`) — zero copie in `DESIGN/QLive_Nav/`, zero su `E:`. Citata dal foglio del 25/08 (riga 41) e finora **senza rimando in questo indice**: questa riga esiste per darglielo. ⛔ **Il deposito è materia di un mandato suo, non fatto qui.** |
| **— 27/08/2026 · LA POLITICA DEL RIENTRO E I FOGLI DEL PLAYER —** | ⬇️ **Depositati il 29/08 (mandato A249).** Fino a quel giorno vivevano **solo su Drive** e l'indice si fermava al 25/08: chi costruiva non li raggiungeva. Le descrizioni delle righe che seguono sono **scritte da CD** (§G del rev3) e riportate qui, non ricostruite. ⚠️ **CD le colloca in `DESIGN/QLive_Player/`**, cartella che **non esiste**: sono depositate qui, dove i fogli CD già vivono. **La cartella è materia del referee, non di questo giro** — se si crea, è un `git mv` e queste righe si spostano con lui. |
| `2026-08-27_..._POLITICA-DEL-RIENTRO__risposta-CD-16-voci.html` | ⛔ **rev1 della politica. SUPERATO dal rev2, poi dal rev3.** 28 562 byte. Conservato come primo anello della catena. |
| `2026-08-27_..._POLITICA-DEL-RIENTRO__rev2-TERZO-SEGNALE__SUPERSEDE-rev1.html` | ⛔ **rev2 · il terzo segnale. SUPERATO dal rev3 — NON FIRMARE.** Resta **la fonte delle 12 voci non toccate** dal rev3. 38 179 byte. ⚠️ **Trappola misurata:** tre file del 27/08 portano `POLITICA-DEL-RIENTRO` nel nome e **si distinguono solo per peso** — questo 38 179 · il rev1 28 562 · e un terzo marcato `_SUPERATA__…chip-PULITO-illeggibile` da **28 222**, **non depositato, lasciato su Drive**. |
| `2026-08-27_..._Attesa-vestita__velo-corto-fascia-viva_390x844.html` | **Riferimento visivo 1:1 del gradino 2** — l'attesa vestita: velo corto + fascia viva. 37 113 byte. |
| `2026-08-27_..._Attesa-e-Dettaglio__rev2-FRECCIA-AL-DETTAGLIO-SPIA__SUPERSEDE-rev1_390x844.html` | **Attesa + dettaglio, freccia al dettaglio.** È **la strada che il §2 riusa per la guardia alla porta**. 42 276 byte. |
| `2026-08-27_..._Bivio-tre-vie-e-TERZA-FACCIA-del-Dettaglio__390x844.html` | **RATIFICATO.** Popup a tre vie + terza faccia del dettaglio. ⚠️ **Il suo RESUME è BLOCCATO dal §D del rev3** — la terza faccia eredita il blocco. 53 496 byte. |
| `2026-08-28_..._POLITICA-DEL-RIENTRO__rev3-LA-PORTA-E-IL-SEGNALE-BUGIARDO__SUPERSEDE-rev2.html` | **NORMATIVO per la politica del rientro** — parola di CD: «CORRENTE». La porta (§A) · il gradino 1 riscritto (§B) · il +1 corretto (§C) · la sentenza sull'overlay (§D) · **le righe di questo indice (§G)**. 41 629 byte. ⇒ Firme A e B di Mauro, 28/08. |
| `2026-08-28_..._POLITICA-DEL-RIENTRO__rev3.1-CHIUDE-LA-FIRMA-B__tetto-cintura-e-due-gradi.html` | **SI LEGGE ACCANTO AL rev3** — lo chiude su tetto, cintura e due gradi. **Chi legge il rev3 deve leggere anche questo.** 29 593 byte. ⇒ Firma C di Mauro, 29/08 (**TRATTENUTA in parte: il grado 2 è un lavoro a sé**). |
| `2026-08-29_..._USCITA-DA-UNO-SHOW-VIVO__e-il-contatore-senza-fonte.html` | **NORMATIVO sull'uscita da uno show vivo** e sui trattini del contatore. ⇒ Firma D, 29/08 — **NON COSTRUITA**: è il ticket `TD-show-non-abbandonabile` in BUGS. 29 752 byte. |
| `2026-08-29_..._AMMISSIBILE-E-LUCINA__uno-solo-e-spenta.html` | **NORMATIVO sull'ammissibile 20–400 BPM e sulla lucina.** ⇒ Firma E, 29/08. ⚠️ **Trappola:** esiste un gemello `ZZ_SUPERATO_da-fix-CSS__2026-08-29_AMMISSIBILE-E-LUCINA.html` da **25 790** byte — **non depositato, lasciato su Drive**. Questo è **25 096**. |
| `2026-08-30_QLive-Player_IL-VELO-DICE-DA-DOVE__END-SHOW-sullo-scaffale-e-sei-decisioni-incise__390x844.html` | **NORMATIVO sul player fermo (bivio, velo) e sul DETTAGLIO — sei decisioni incise, CD 30/08/2026.** Abolisce il selettore delle stanze nel dettaglio dello show attivo (D④): **sul dettaglio il contratto 18/07 resta senza oggetto**, per dichiarazione di CD, non per abrogazione. ⛔ **NON tocca la LISTA:** le due porte del contratto 18/07 lì restano vive e invariate. Vedi la marcatura sulla riga del contratto 18/07 sopra. |
| gli altri | storico di derivazione — vedi «Derivazione» più sotto. |

⚠️ **MARCATURA 26/08 — DIFETTO DI FORMA NELLE TRE RIGHE DEPOSITATE IL 25/08, CORRETTO. Le righe non sono riscritte: si marca qui cosa è cambiato e perché.** I pesi delle righe nuove erano scritti col separatore **U+202F** (*narrow no-break space*) fra le migliaia — `106<U+202F>024`, `97<U+202F>267`, `27<U+202F>145` — mentre la stessa tabella usa lo **spazio normale** per il peso della rev6 (`87 570`). ⛔ **Il difetto ne minava la funzione:** quelle righe esistono per **distinguere due file omonimi per peso**, e chi cercava `106 024` scritto con lo spazio normale **non lo trovava**. Misurato: tre occorrenze in due righe, zero altrove in questo file. ✅ **Tutte e tre portate a spazio normale**, coerenti col resto della tabella. ⚠️ **Due occorrenze della stessa forma restano in `LIBRO_MASTRO_QBEATS.md`** (riga della decisione 25/08 e registro versioni): **fuori dal perimetro di questo giro, dichiarate e non toccate.**

⚠️ **MARCATURA 26/08 — LA RIGA DELLA NOTA DI CORREZIONE AL 18/07 È SUPERATA DAL DEPOSITO DI OGGI. La riga non si riscrive: si marca qui.** Quella riga dichiara «**NON È IN QUESTA CARTELLA … vive solo su Drive** — zero copie in `DESIGN/QLive_Nav/`, zero su `E:`», e al momento in cui fu scritta era **vera e misurata**. ✅ **Oggi non lo è più:** il file è stato depositato in **questa cartella** e su **`E:` in `DA_CD_PER_CC/24_08_2026/`** — 27 145 byte, `cmp` fra le due scritture a exit 0, sha256 `b926aaf6…93e8`, identico al sorgente. ⇒ **Della riga sopra resta valido tutto tranne la clausola di assenza:** la nota **si legge accanto al contratto 18/07** e **chi legge il 18/07 deve leggere anche questa**. ⚠️ **Il deposito era materia di un mandato suo, ed è arrivato:** questa marcatura lo registra invece di lasciare in piedi una frase che il giro successivo ha smentito.
⚠️ **Regola di trasporto, pagata cara il 20/08.** Un HTML **ri-salvato da un
browser non è quel file**: nome troncato, estensione `.htm`, e byte diversi senza
alcun avviso (misurato: 793 byte in meno su un normativo). Da Drive si usa
**solo** il tasto Scarica.

⚠️ **Seconda faccia della stessa regola, verificata il 21/08 sulla rev6.** Il download
ha troncato il **NOME** (tagliato dentro la parola `ancoraggio`) ma **non i BYTE**: il
file era integro. ⛔ Una sonda per nome su `*rev6*` rendeva **DUE** file, uno dei quali
**RITIRATO da CD**; il nome non discriminava. La verifica è passata **solo perché CD
aveva dichiarato il PESO** (87 570 byte), che ha reso **una sola** corrispondenza,
confermata poi da sha256, righe, CR e NUL. ✅ **I byte sono l'unico giudice, mai il
nome.** Rinominare al deposito **non è emendare**: i byte non cambiano, e va
rimisurato dopo la copia.

## Contratto VIVO

`2026-07-11_Q7-Q16.html` — è la versione da cui CC cabla oggi. Contiene tutte le decisioni
ratificate (Q7-Q16). Ogni riferimento nel codice va a **questo** file, citato per selettore
CSS/markup, mai per numero di riga (il documento cresce a ogni taglio, le righe slittano).

## Derivazione (storico, in ordine cronologico)

1. `2026-07-09_standalone_b23dfc78.html` — versione più antica reperita, nome file
   "Q-BEATS Freeze Q-Live Nav (standalone).html" nel mirror CD. Citata (troncata a 8 char,
   `b23dfc78…`) in `RoomSwitchBar.swift:3`, `MetroFAB.swift:3`, `QLiveKit.swift:3` — i
   commit S0/S1/S2F/S2 sono stati scritti contro questa versione.
2. `2026-07-09_base_e141295.html` — versione "anchor HEAD e141295" nel mirror CD, cartella
   `09_07_2026/FREEZE/`. Punto di partenza dichiarato per la serie di tagli Q7-Q16.
3. `2026-07-11_Q7-Q10.html` — +4 emendamenti (Q7 header senza «+», Q8 nota hit-area,
   Q9 `.cta.dead`→`.cta.quiet`, Q10 copy N-agnostica).
4. `2026-07-11_Q7-Q13.html` — +3 risposte (Q11 sort, Q12 copy plurale, Q13 empty Q-Stage).
5. `2026-07-11_Q7-Q16.html` — +3 correzioni dal markup (Q14 copy impossibile corretta,
   Q15 eredità confermata, Q16 reset a riavvio confermato). **VIVO.**

## ⚠️ Precisazione su `b23dfc78…` vs `e141295` — NON sono lo stesso documento

I file 1 e 2 sopra sono **due file diversi**: sha256 diversi (`b23dfc78831ccf84…` vs
`3eb78cc5a45a8af9…`), lunghezza diversa (206 righe vs 446 righe). **Non fondere i due fatti
verificati in uno**:

- **Condividono** lo stesso `<title>` dichiarato nell'HTML: entrambi contengono
  testualmente *"FREEZE Q-LIVE NAV (Cancello 1) — §1 congelato 1:1 · e141295"* — cioè
  entrambi i file si auto-dichiarano parte dello stesso "Cancello 1"/anchor `e141295`.
- **Condividono**, verificato con `diff` mirato, le stesse regole CSS testuali sui
  selettori citati da `RoomSwitchBar.swift`/`MetroFAB.swift` (`.roombar`, `.homebtn`,
  `.roomseg`, `.metrofab`): nessuna differenza di contenuto su quei selettori tra i due
  file.
- **NON è verificato** che il resto del contenuto sia identico, né che uno sia una copia
  esatta dell'altro con solo il nome cambiato — sono file fisicamente distinti, di
  lunghezza diversa, con contenuto diverso altrove nel documento (il file 2 è più lungo,
  presumibilmente con più sezioni/frame). La relazione esatta tra i due (stesso documento
  esportato due volte con differenze editoriali? evoluzioni sequenziali? file di lavoro
  diversi convergenti sullo stesso anchor?) **non è riconciliata** — CD stesso, nel taglio
  Q7-Q10, dichiara di non poterlo affermare (non ha accesso a git/codice per verificarlo).

**Conclusione operativa:** i commit S0/S1/S2F/S2 (`RoomSwitchBar`/`MetroFAB`/`QLiveKit`),
scritti contro `b23dfc78…`, restano validi perché i selettori che usano sono testualmente
identici anche nella versione `e141295` successiva — verificato, non assunto. Ma
`b23dfc78…` non va trattato come "la stessa cosa" di `e141295` in senso stretto.

## Terzo identificatore — `438fcaf3…`

Citato nel codice (`QLiveEmptyStates.swift`, header) come sha256 di
`FREEZE_QLIVE_NAV_DECODED_2026-07-11.txt` — un file `.txt` prodotto dal referee (non un
HTML di CD), usato come fonte per S2. Non presente in questa cartella (non è un file CD,
è un artefatto di lavoro del referee); non riconciliato con gli HTML sopra oltre al fatto
che tratta lo stesso argomento (Q-Live Nav) nello stesso periodo.

## Cosa manca

Nessun handoff CD `.md` più recente di Q7-Q10: le risposte Q11-Q16 sono documentate solo
dentro i pannelli "Addendum" degli HTML `2026-07-11_Q7-Q13.html` e `2026-07-11_Q7-Q16.html`
stessi, non in un documento separato.
