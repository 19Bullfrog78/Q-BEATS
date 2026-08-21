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
| `2026-07-18_QLive-Exit-in-Play.html` | **CONTRATTO rev.2 per ⟦S-EXIT⟧ e ⟦S6F⟧.** ⚠️ Il suo `:root` è una copia di lavoro: se un token diverge, vince Q7-Q16. |
| `2026-08-21_..._rev6__SUPERSEDE-rev5-SU-2-SELETTORI__ancoraggio-Read-only-e-ritiro-4px_390x844.html` | **NORMATIVO sui DUE selettori che tocca.** Riga d'indice **scritta da CD** (pannello ④ del foglio), riportata qui verbatim: rev6 · 21/08 · SUPERSEDE rev5 su 2 selettori — **.dhrow: baseline** (cadono center e flex-start; cade .ro margin-top) · **.navbar .back: padding 0 4px RITIRATO**. Non tocca geometria A, badge, .roomseg, .viewtoggle. ⛔ **Porta 5 errata AUTOCITANTI di giornata**: regola riformulata («stesso ancoraggio del livello 1», non «sul baseline») · origine y · movimento Ⓓ 13,97 · **lh 1.05→1.12 inesistente nell'app** · **nesso causale ritirato: il gradino È l'ancoraggio (5–8pt su `baaa172`), non la geometria A**. **Aperti:** H (altezza badge nell'app) · il titolo più in alto, inspiegato · lh 1.12 ratificata ma inattuabile. **Le due decisioni non si muovono**; i numeri assoluti del foglio **non si incidono**. ⚠️ **Trasporto: da Drive solo il tasto Scarica — i byte sono l'unico giudice, mai il nome.** |
| gli altri | storico di derivazione — vedi «Derivazione» più sotto. |

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
