# DESIGN/QLive_Nav — Freeze CD "Cancello 1" (Q-Live Nav)

Contratto di design per la navigazione Q-Live/Q-Stage. File CD, versionati per derivazione
storica. Zero sha256 incisi qui sotto come puntatori — sono dichiarati nel messaggio di
commit e nella cronologia git, non in questo documento (REGOLA ANTI-CASCATA).

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
