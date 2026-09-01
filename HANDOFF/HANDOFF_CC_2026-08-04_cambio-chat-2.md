# HANDOFF CC — cambio chat 2 — 2026-08-04

**Deposito, NON ratifica. Verificare, non ereditare.**

Scritto da questa sessione CC, in chiusura, **senza aver letto il congedo del referee** — deliberatamente: i due documenti devono essere misure indipendenti, non una copia dell'altra. So che `HANDOFF/CONGEDO_REFEREE_2026-08-04.md` esiste (16303 byte, misurato solo come esistenza — mai aperto) e mi fermo lì.

Ogni numero qui sotto è stato rimisurato all'ultima ora di questa sessione, non ricordato dai turni precedenti dello stesso giro. Convenzione: **[V]** = misurato da me in questo turno di chiusura. **[R]** = riferito da altri e non verificabile direttamente da me.

⚠️ **Scarto d'orologio, dichiarato subito perché il nome del file non lo dice:** scrivo alle **2026-08-05T08:13:09+02:00** (`2026-08-05T06:13:09Z`) [V] — abbiamo passato la mezzanotte. Il nome `…_2026-08-04_cambio-chat-2.md` porta la data della **sessione descritta**, non quella in cui scrivo; lo uso verbatim perché è quello che Mauro ha dato, con lo stesso principio applicato oggi stesso all'ID di `A39` (il nome è un indirizzo, non si corregge). Tutto ciò che segue è accaduto il 04/08, fra le 19:44 di ieri e le 23:21 di poco fa; scrivo io ora, qualche ora dopo.

---

## 1. Stato verificato adesso (fine sessione, non a memoria)

**HEAD e remoto** [V]
```
HEAD:            5183758d8b80b0d1f975fb0e6074d146cec3e3ae
remoto (ls-remote): 5183758d8b80b0d1f975fb0e6074d146cec3e3ae
commit locali non pushati: 0
```
Allineati e verificati al remoto, non dal solo output di `push`.

**Ultimi 4 commit** [V]
```
5183758  2026-08-04T23:21:38+02:00  Mauro Martintoni  LIBRO v53: quarta destinazione R-δ = NAS Synology, la chiavetta esce dal regime (doc-only)
ea3f94a  2026-08-04T15:15:23+02:00  Mauro Martintoni  SCALETTA v7 — cancello END SHOW nella scheda S5 (doc-only)
5cd6397  2026-08-04T15:14:25+02:00  Mauro Martintoni  BUGS v50 — marcatura additiva su TD-qlive-libero-limbo (doc-only)
bce6a73  2026-08-04T15:11:06+02:00  Mauro Martintoni  BUGS v49 — nuovo ticket TD-fineshow-bottoni-morti (doc-only)
```
Tutti sole-authored Mauro, zero Co-Authored-By su questo commit [V]. `5183758` è il solo che questa sessione ha prodotto e pushato; gli altri tre erano già a HEAD quando questa chat si è aperta.

**Impronte dei cinque canonici, disco vs blob a HEAD** [V] — tutte pulite:
| file | hash (disco = blob) |
|---|---|
| `LIBRO_MASTRO_QBEATS.md` | `cbe016692354cac5da8e993a77bb5533fdcce551` |
| `BUGS_QBEATS.md` | `2598ae0288aefc29ac3d29c8b2e3b33e4057bb82` |
| `BOX3_QBEATS.md` | `490d6d9b38c355dc53ddc9b31431f9a858f2b342` |
| `BOX5_QBEATS.md` | `21b23d621ac224c759b53d813196058483e3b056` |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | `e799b6b0b29f8d1e2afb179edfad28bb41489228` |

**Versioni dichiarate, lette dentro ciascun file, non dedotte** [V]: LIBRO **53** (04/08/2026) · BUGS **50** (04/08/2026) · SCALETTA **7** (04/08/2026, con un difetto interno noto — vedi §3 sotto). BOX3 e BOX5 non toccati oggi.

**`git status` completo** [V] — 162 righe totali, **0** non-`??`, 162 `??`. Nessun file tracciato modificato fuori dal commit già fatto.

**I tre diff-proposta di oggi, tutti ancora presenti e non sovrascritti** [V] (in `HANDOFF/`, accanto l'uno all'altro come da regola — un artefatto in attesa di ratifica non si cancella):
```
DIFF_LIBRO-v53_2026-08-04_A39-NAS-QUARTA-DESTINAZIONE.txt          38284 B  7b8f0413…73e03
DIFF_LIBRO-v53_2026-08-04_A40-NAS-PERIMETRO-E-STRETTA-DI-MANO.txt  39293 B  f9dae338…53826
DIFF_LIBRO-v53_2026-08-04_A41-ALLINEAMENTO-PUNTATORI.txt           39635 B  c5af5812…8622a
```
A41 è quello applicato dal commit `5183758`; i primi due restano come storia del giro, non come proposte vive.

**R-δ del lotto di oggi — completa, incluso ciò che stamattina mancava** [V], tutte estratte dal blob via `git show`, mai dal disco, su E::
```
BUGS_QBEATS/BUGS_QBEATS_V49_2026-08-04_bce6a73.md            280493 B  1c7c761c…1fd3c
BUGS_QBEATS/BUGS_QBEATS_V50_2026-08-04_5cd6397.md            283858 B  04de830d…2e1778
HANDOFF/SCALETTA_v7_2026-08-04_ea3f94a.md                     42035 B  91e42123…20b11317
LIBRO_MASTRO/LIBRO_MASTRO_QBEATS_V53_2026-08-04_5183758.md   247862 B  bbf5caf0…ab3fbd
```
Il nome fisso `E:\…\LIBRO_MASTRO_QBEATS.md` combacia col blob committato (`bbf5caf0…ab3fbd`) [V]. Tutte e quattro propagate anche su Drive e riscaricate per sha256 nel giro che le ha prodotte (mai fidandosi del solo metadato, che non espone checksum).

**Cosa NON è su Drive/NAS, dichiarato non dedotto:** Drive riflette C:/E: automaticamente (sync desktop attivo dal 01/08, verificato più volte oggi) — quindi ciò che è vero per C:/E: sopra è vero anche per Drive, salvo il ritardo di sync (nell'ordine di secondi, misurato in giri precedenti). **Il NAS è un'altra storia**: nessun accesso, nessuna verifica possibile da qui — vedi §3 punto 10.

---

## 2. Chiuso oggi / coda aperta

**Chiuso:**
1. **La discordanza chiavetta/NAS** (punto 1 della coda del primo handoff di stamattina) — **sciolta**: LIBRO v53 dichiara il NAS Synology quarta destinazione, con perimetro doppio (C: **e** E:) e cadenza settimanale; la chiavetta esce dal regime; l'argomento di R-δ (`:336`) non cade, resta marcato con un cartello, testo originale intatto.
2. **R-δ del lotto di oggi, completa** — le quattro istantanee mancanti (BUGS V49/V50, SCALETTA v7, LIBRO V53) sono state create e verificate su tre copie indipendenti ciascuna.
3. **Push eseguito e verificato al remoto** — `ls-remote`, non l'output testuale del comando.
4. **Metodologia di idempotenza rifinita**: forma stretta per gli ID di giro, ormai standard dopo due falsi presi oggi (§4).
5. **Regola "riga per aritmetica non è misura"**, scritta ieri in memoria persistente, **riconfermata oggi** da un mio stesso errore (§3).

**Aperto — non toccato oggi, riportato dal primo handoff o scoperto in giornata:**
1. **`TD-fineshow-bottoni-morti`** (`BUGS_QBEATS.md:319`) resta dentro §1.2 «non bloccanti palco» benché sia 🚨 **BLOCCANTE PALCO** — confermato indipendentemente stamattina, **mai più toccato**: la giornata è finita interamente nel filone NAS/R-δ. È lo stesso rischio segnalato all'apertura, invariato.
2. **Backfill della voce v48** nel registro BUGS — debito dichiarato da tempo (`BUGS_QBEATS.md`, voce 49: «v48 NON HA RIGA»), non affrontato.
3. **Le due righe con pipe rotte** (voci 45/46 del registro BUGS) — non toccate.
4. **`tools/` fuori da git** — non toccato.
5. **`LIBRO:316` («REGOLA INDIRIZZO DI CONTENUTO»)** — identificata con certezza durante A37/A38 come la riga nominata in un prompt precedente, ma **cosa vada corretto lì resta ignoto**: l'ho letta, non l'ho capita come debito. Non invento una correzione.
6. **Registro `:495` (voce 50, «R-δ», nomina ancora la chiavetta) NON è marcata** — fork esplicito lasciato aperto in A39/A40/A41: Sezione 6 non ha alcun precedente di riga di registro marcata come superata (zero, contro tre in Sezione 2, stessa forma di misura), quindi non ne ho inventato uno. **Decide Mauro** se vuole comunque un cartello lì, aprendo un precedente nuovo, o se il registro resta storia intatta.
7. **Duplicato Drive di V47** (`BUGS_QBEATS_V47_2026-08-01_0ee9543.md`) — trovato oggi in due cartelle-parent diverse su Drive, stesso nome, ID diversi. Non indagato, non è dei nuovi file di oggi.
8. **SCALETTA v7, difetto interno noto**: la sua propria riga di versione elenca «cancello END SHOW in scheda ⟦S5⟧ 02/08» per la voce (v7) — ma (v7) è di **oggi**, 04/08. Refuso di copia dalla voce (v6) precedente, trovato in A37, mai corretto (è contenuto di un canonico, fuori perimetro di un giro doc-only sulla data).
9. **`HANDOFF/MISURE_CC_2026-08-04_A35-QUARTA-DESTINAZIONE-NAS.txt` è ora parzialmente superato, e non lo dichiara da solo**: il suo §4 elenca tre letture possibili della discordanza chiavetta/NAS e vieta di sceglierne una per inferenza. LIBRO v53 ha scelto la lettura **(a)** — ma A35 stesso non porta alcuna nota che lo segnali; chi lo legge oggi (6423 B, sha256 `6e6eafa0…060058a` [V], misurato ora, mai dichiarato prima) trova ancora «non risolta qui» su una cosa che *è* stata risolta altrove.
10. **Il buco di copertura NAS più urgente di tutti**: per ammissione della stessa riga appena committata, il NAS «invecchia» invece di specchiare, e la cadenza è **settimanale**, non a evento. La fotografia manuale più recente dichiarata (in A35) è delle ~14:00-15:35 del 04/08 — **precede** sia i tre commit delle 15:11-15:15 sia il commit di stasera (`5183758`, 23:21). Con cadenza settimanale, non c'è garanzia che il lotto appena pushato sia sul NAS prima di giorni. La regola appena incisa protegge da un errore umano, ma non copre ancora se stessa.

---

## 3. I miei errori di oggi, per esteso — compresi quelli presi da sola

**Il più grande, trovato dal referee, non da me.** In A38, ho dedotto che una riga aggiunta in un diff fosse l'**ultima** delle sette righe di un blocco `@@ -342,6 +342,7@@`, quindi riga **348**. Era la **quarta**, riga **345**; 348 era una riga vuota. L'aritmetica dell'header era corretta (individuava bene l'ultimo indice del blocco); l'errore era nell'assunzione taciuta su QUALE riga del blocco fosse quella cambiata. Il mio stesso controllo incrociato («Sezione 3 inizia a 349, quindi 348 è l'ultima di Sezione 2») era vero ma **non discriminante**: 345 rispettava lo stesso vincolo, quindi non poteva smentire l'ipotesi sbagliata. Trovato dal referee con due forme indipendenti su una copia già provata identica a HEAD. Ho scritto una regola di memoria persistente da questo (`feedback_qbeats_riga_aritmetica_non_misura.md`): un numero di riga per aritmetica resta un'ipotesi finché non si legge quella riga.

**Trovato da me stessa, prima che finisse in un referto.** In A42 §3, lo script di verifica che ho scritto asseriva che la riga 335 del LIBRO dovesse iniziare con una data `2026-07-31` — non l'avevo letta, l'avevo assunta dal contesto delle righe vicine. L'assert è fallita: riga 335 è in realtà `2026-08-01` (le due righe `07-31` sono la 333 e la 334). È lo stesso difetto di ieri — un numero/contenuto per assunzione anziché per lettura — questa volta preso dalla mia **stessa asserzione difensiva**, prima di dichiarare qualunque cosa a Mauro. Nessuna delle verifiche effettivamente richieste (byte, sha256, pipe, ancore, stretta di mano) è fallita: è fallita solo una mia ipotesi di contorno, e l'ho corretta misurando prima di scrivere.

**Falso positivo nella ricerca di idempotenza (A39).** La ricerca in forma larga di «A39» ha reso un match dentro un digest esadecimale (`B7A39593A7…`, sottostringa di uno sha256 in un file estraneo), non un ID di giro. Intercettato prima di concludere «già eseguito», con una forma stretta (`A39[-_ ]` o `QB-…-A39`) che sullo stesso identico controllo positivo (A35) continuava a mordere.

**Falso-zero dello strumento `Glob` (A40, alla ripresa).** `Glob` con pattern `HANDOFF/*A39*` ha reso «No files found» su un file che **esiste**, verificato nello stesso istante da `Grep`. Il controllo positivo con quella stessa forma è fallito anche lui — segnale che lo zero non valeva nulla, non che il file mancasse. Buttato, ripetuto con `**/*A40*`, che morde correttamente su entrambi i lati.

**Un blocco degli strumenti, non un mio errore ma una mia scelta sotto blocco (A40, primo tentativo).** Bash e PowerShell hanno rifiutato ogni comando (*"claude-sonnet-5[1m] is temporarily unavailable"*) per l'intero turno. Non ho asserito né confermato né smentito i tre valori della stretta di mano che il referee aveva già misurato: mi sono fermata e l'ho dichiarato esplicitamente, invece di echeggiare numeri altrui senza averli calcolati io. Vedi §5.

**Un incidente di codifica console, non di dati (A42).** Lo script Python di verifica ha lanciato `UnicodeEncodeError` provando a stampare `δ` su una console `cp1252` — dopo che i confronti critici (byte, sha256, righe che differiscono) erano già passati. Limite di stampa, non dei dati: `sys.stdout.reconfigure(encoding="utf-8", errors="replace")` ha risolto, e nessun valore già dichiarato ne era inficiato.

---

## 4. Trappole di misura di oggi — la forma che morde e quella che mente

**Ricerca di un ID di giro.** MENTE: `grep "A39"` (forma larga) — morde dentro sottostringhe esadecimali di uno sha256, non solo dentro un ID vero. MORDE: `grep -E "A39[-_ ]|QB-[0-9]{4}-[0-9]{2}-[0-9]{2}-A39"` — richiede un separatore o il prefisso completo. Controprova obbligatoria in entrambi i casi: la stessa forma su un ID noto esistere deve mordere; se anche il controllo positivo tace, lo zero non è una misura.

**Esistenza di un file per nome.** MENTE: `Glob` con pattern che comincia con un prefisso di cartella diretto (`HANDOFF/*TERMINE*`) — ha reso zero su un file reale. MORDE: `Glob` con `**/*TERMINE*` (doppio asterisco) o `ls DIR | grep -i TERMINE`. Stessa regola: controllo positivo nella stessa identica forma prima di fidarsi di uno zero.

**Numero di riga di un contenuto in un diff.** MENTE: dedurlo dalla posizione nell'header di un hunk (`@@ -a,b +c,d@@`), assumendo che la riga cambiata occupi una posizione fissa (es. l'ultima) del blocco — l'aritmetica individua correttamente l'**intervallo**, mai la riga esatta al suo interno. MORDE: leggere la riga con `awk 'NR==N'` (mai `sed`, che altera l'uscita) **dopo** aver applicato la modifica, o scorrere l'hunk contenuto per contenuto invece che per posizione. Presa due volte in due giorni, in due forme diverse (un diff altrui ieri, una mia asserzione oggi).

**Stampa di caratteri non-ASCII su console Windows.** MENTE: assumere che se lo script scrive corretto su file (UTF-8 esplicito), anche stampare a video vada bene — la console di questa macchina è `cp1252` per default, e caratteri come `δ` o `§` mandano in eccezione la sola stampa. MORDE: forzare `utf-8` sullo stream di stampa a inizio script, o non stampare mai il contenuto originale — solo le sue impronte.

---

## 5. Le volte in cui ho fermato il referee, con l'esito

**A39 — formula di provenienza falsa, sostituita.** Il mandato ricevuto dichiarava, per la decisione NAS, «nessuna fonte documentale precedente — stessa natura di provenienza che R-δ dichiara per sé a :336». Avevo letto per intero `HANDOFF/MISURE_CC_2026-08-04_A35-QUARTA-DESTINAZIONE-NAS.txt` (non a memoria, prima di scrivere il diff) e la dichiarazione **era** già depositata lì, con tanto di perimetro doppio e proprietà dell'invecchiamento — semplicemente non ratificata. Ho scritto una formula onesta («nessuna fonte la ratifica, ma la dichiarazione è depositata e lì è NON VERIFICATA») invece di quella data, e l'ho segnalato esplicitamente invece di correggere in silenzio. **Esito: ratificata** in apertura di A40 — «la formula del referee era falsa, la tua è corretta. Tienila.»

**A38 punto 3 — non ho confermato in blocco.** Il referee aveva misurato «una sola riga aggiunta» fra due versioni del LIBRO. La misura vera, sul file intero, era 5 aggiunte/3 rimozioni — ma la frase del referee nominava un perimetro preciso («dentro Sezione 2, dopo :336, prima della fine sezione»), e dentro **esattamente** quel perimetro l'affermazione era vera. Non l'ho né confermata né smentita in blocco: l'ho concessa solo dove il testo la rendeva vera. **Esito: registrato come comportamento giusto** in apertura di A40.

**A40, primo tentativo — rifiuto di asserire senza misurare.** Con gli strumenti di esecuzione bloccati, non ho confermato né smentito i tre valori della stretta di mano (byte, sha256, pipe) che il referee aveva già dichiarato di aver misurato — mi sono fermata e ho dichiarato il blocco. **Esito: esplicitamente lodato** al momento della ripresa — «Fermarsi non è un fallimento del giro: è il giro che funziona.»

---

## 6. Se fossi la prossima chat, farei per primo questo

Nell'ordine: **(1)** decidere il fork lasciato aperto sul registro `:495` (§2, punto 6) — è l'unico dei debiti di oggi che ha una domanda esplicita in sospeso rivolta a Mauro, il resto sono debiti dichiarati ma senza bivio da sciogliere. **(2)** riportare `TD-fineshow-bottoni-morti` fuori da §1.2 (§2, punto 1) — è il rischio più grave nel merito, segnalato due volte oggi e mai lavorato, perché la giornata intera è finita nel filone NAS. **(3)** una copia manuale sul NAS che copra almeno il commit `5183758`, quale che sia la cadenza dichiarata — è la ragione stessa per cui la riga appena scritta esiste, e oggi non è ancora vera.

Non rifarei la stretta di mano né le verifiche di identità già chiuse in A37-A42: sono ratificate, misurate due volte da parti indipendenti, e rimisurarle senza un motivo nuovo sarebbe lo stesso overhead procedurale che la sessione di stamattina si era già rimproverata da sola.

---

## Consegna

| campo | valore |
|---|---|
| nome | `HANDOFF_CC_2026-08-04_cambio-chat-2.md` |

⚠️ **Stessa nota di metodo del primo handoff di oggi:** questo file non può contenere la propria impronta — scriverla qui dentro cambierebbe il file e falserebbe il numero appena inciso. Byte, sha256 e verifica di propagazione sono dichiarati nel referto in chat che accompagna questa scrittura, mai in questa tabella.
