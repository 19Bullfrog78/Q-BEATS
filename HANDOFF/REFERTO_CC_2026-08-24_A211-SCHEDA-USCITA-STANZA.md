# REFERTO CC — A211 — ESEGUITO: SCALETTA v14 → v15, SCHEDA G INCISA IN CODA

Da: CC · A: referee + Mauro · 24/08/2026
Mandato: A211 (referee), terza riemissione — blocco senza numeri di riga.
**ESITO: ESEGUITO. Due modifiche, entrambe nella SCALETTA, nient'altro toccato.**
Marcatura: [M] misurato alla fonte · [R] riportato · [A] giudizio mio.

## 1 · Collisione A211 — LIBERA, coi tre positivi

| sonda | A211 | A168 | A209 | A210 |
|---|---|---|---|---|
| nomi repo/HANDOFF | 0 | 1 | 1 | 1 |
| nomi E:/HANDOFF | 0 | 1 | 1 | 1 |
| nomi git a HEAD | 0 | 1 | — | — |
| contenuto repo (`\b…\b`) | 0 | — | 2 | 1 |
| contenuto E: | 0 | — | — | — |

## 2 · Ancore del blocco — rimisurate TUTTE prima di scrivere, nessuno stop

[M] Le quattro ultime, misurate in questo mandato: stringa del freeze rev3 con tag HTML
(`room switch <b>34pt</b> (era 30)` e `<code>.seg-mini</code> abolita`, stessa riga del
file `…rev3-NORMATIVA.html`) ✓ · il commento di `QLiveSession.swift` cita
`BOX3_QBEATS.md:34 @ 0a6ebafa…` e A QUEL BLOB la riga 34 È «(e) VINCOLO TECNICO S4L da
incidere» ✓ (il claim del blocco sullo sha è vero) · la riga ⟦S6F⟧ sta in «Sezione 2 —
Decisioni ratificate» del LIBRO ✓ · «onHome non-defaulted → SÌ (Cond A
enforced-by-compiler)» sta in «D · Risposte referee alle 8 domande» della SCALETTA ✓.
[M] Più: contratto = 536 righe ✓ · copy IT in `OverlayStopView.swift` («Riprendi da
\(sectionName)» / «Dall'inizio · \(songName)») ✓ · «VINCOLO DI PROPAGAZIONE» unico in
`QLiveSession.swift` ✓ · `72001a5` ESISTE come commit: 26/05/2026, «fix(link): linkPeers
usa count reale via link_engine_num_peers» — misurato da me ORA, quindi la nota [R] in
coda al blocco poggia su una misura reale ✓.
[M] Tutte le altre erano già state misurate da me in A209/A210 sullo stesso HEAD e albero
intatto: sonda Start/Stop Sync = 2 config zero codice · ABLLink 4+8 · 41 dichiarazioni
(45 grezze, 4 in commenti) · IsConnected/SetIsConnectedCallback binarie · commento
LinkEngine verbatim · scheda TD linkPeers completa · 0de5aa0 · ARCHIVIO 12+5 fermo a
27_05_2026 · catena SCALETTA repo 0 · montaggi Shows/Detail · default onSwitch.

## 3 · Le due modifiche, e la prova che nient'altro si è mosso

```
PRIMA  sha256 7f9f6eee605e819c3203bcb2595a0dbcccb12d49e6e99617a62b7daecacb6108
       byte 75417 · LF 551 · CR 0 · NUL 0 · termina \n      (= mandato, terza verifica)
DOPO   sha256 18e2f4d1af7c9bf7b8de04055e8e947023295166cd68ae7d431cfcd8980deb01
       byte 89757 · LF 750 · CR 0 · NUL 0 · termina \n
       75417 + 14340 (blocco) = 89757 ✓ · 551 + 199 = 750 ✓
```
[M] Confronto riga per riga PRIMA/DOPO sulle righe 1-551: **l'unica diversa è la 3**
(«Versione: 14» → «Versione: 15»), che resta di **1381 byte** — NON allungata, R-δ.7
rispettata. Le 199 righe nuove sono TUTTE in coda, dopo l'ultima riga preesistente.
[M] Guardie pre-scrittura tutte passate (bersaglio unico · file termina \n · blocco
inizia con riga vuota + `---` · coda blocco attesa). Copia PRIMA conservata in scratchpad.

## 4 · Il diff — struttura e depositi

[M] 2 hunk: riga 3 (1 tolta, 1 aggiunta) + coda (`@@ -549,3 +549,202 @@` = 3 di contesto
+ 199 aggiunte). Righe `+` totali = 200, di cui 27 vuote.
⚠️ [M] Trappola di sonda incontrata E corretta: `grep -c '^+[^+]'` rendeva **173** perché
una riga aggiunta VUOTA è solo `+` e il `[^+]` non ha nulla da mangiare. Conteggio giusto:
`grep -c '^+'` meno l'header. Registrata perché è una falsa-mancanza facile da rifare.

```
DIFF_2026-08-24_A211-SCHEDA-USCITA-STANZA.txt
  repo = E:  · cmp exit 0 · 19536 byte · CR 0 · LF 215
  sha256 d78478bfd3126edba94874ffc1bd7e97ac645ae51633615b28128741d3373845
```
⛔ Fa fede il FILE depositato, non il paste in chat (transito-modello altera gli apostrofi).

## 5 · Stato git alla chiusura

```
HEAD = 8727f8e · SCALETTA modificata NEL WORKING TREE, NON in stage
zero commit · zero push · il diff torna a Mauro: cancello DISTINTO
```

*REFERTO-CC-2026-08-24-A211-FINE*
