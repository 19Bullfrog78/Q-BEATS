# CONGEDO REFEREE — sessione 01/09/2026

## 0 · COME SI LEGGE

Questo è un **puntatore, non una fonte**. Niente è ratificato per il fatto di
essere scritto qui. Ogni affermazione porta il suo indirizzo: se non ha commit,
file e riga, trattala come voce da verificare.

⚠️ **Ho commesso sei errori in questa sessione, e sono tutti la stessa cosa.**
Stanno al §6. Leggili **prima** di fidarti di qualunque altra riga di questo
documento e **prima** di scrivere il tuo primo mandato.

⚠️ Il congedo che ho ereditato conteneva un'affermazione falsa che ho ripetuto
per mezza giornata senza verificarla. Se fai a questo documento quello che io ho
fatto a quello, il difetto si propaga di nuovo.

---

## 1 · ANCORAGGIO — misurato dal deposito pubblico il 01/09, sera

`origin/master` = **`a039502bbd15def7e5b4422b5db2b33266118f83`**

| documento | versione | byte | blob |
|---|---|---|---|
| `BUGS_QBEATS.md` | v80 | 500.659 | `b5cb5670…` |
| `LIBRO_MASTRO_QBEATS.md` | v74 | 356.503 | `2d3e0d32…` |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | v18 | 100.442 | `6e6c0889…` |
| `BOX5_QBEATS.md` | V41 | 135.746 | `f2aee5a3…` |
| `BOX3_QBEATS.md` | V100 (22/07) | 90.638 | `897f76c6…` |

⚠️ **La colonna «blob» è l'impronta git (sha1 del blob), non sha256.** Il congedo
che ho ereditato mescolava le due funzioni nella stessa colonna senza dirlo, e
chi ricalcolava con un metodo solo trovava due discordanze su cinque e credeva a
un guasto inesistente. **Ho perso tempo lì: non ripeterlo.**

⚠️ **BOX3 non è lo stato del progetto.** È fermo al 22/07 e lo dichiara da solo.
L'ordine dei lavori sta nella **SCALETTA, Sezione C**.

**File in `HANDOFF/` nel deposito: 423.** Stamattina erano 72.

---

## 2 · COSA SI È CHIUSO OGGI

**① Il regime di deposito dei documenti di lavoro.** `LIBRO:399`, sei colonne,
stato `attiva`. Congedi, referti e diff entrano nel commit del giro che li
produce. **Arretrato recuperato: 345 file in un commit.** Misurato in A301: erano
552 file, di cui 73 tracciati e 479 no, e `.gitignore` non contiene nessuna
regola che tocchi `HANDOFF/` ⇒ era **deriva, non scelta**.
⚠️ **Residuo strutturale dichiarato, non riparato:** il referto di un giro nasce
*dopo* il commit di quel giro, quindi entra sempre col giro successivo. **Ci sarà
sempre esattamente un referto fuori.** La riga del regime non lo dice, e fra due
mesi qualcuno lo leggerà come una violazione. **Primo lavoro documentale della
chat nuova: aggiungere quella riga.**

**② Il mio punto cieco sugli ID è chiuso alla causa.** Vedevo solo il deposito
pubblico; i mandati bruciati su disco erano invisibili. È così che si sono persi
A289 e A294. Ora i documenti di lavoro sono nel deposito.
⛔ **Ma non basta più:** oggi erano attive **due chat referee** sullo stesso
repository, e il punto cieco è tornato un piano più su. Mauro ha chiuso l'altra
il 01/09. **L'ID lo sceglie CC, non il referee** — è l'unico che vede tutti i
fronti. Il più alto bruciato che io conosca è **A311**.

**③ `RESTART SETLIST` è stato rimosso da END SHOW** — commit `70d5aa9`. Era una
rimozione ratificata il 07/08 con due cancelli passati, e ferma da 25 giorni.
Misurato alla punta: zero `Button` con quel nome, `BACK TO SHOWS` intatto.
⛔ **Il ticket resta 🔴 OPEN: chiuso vuol dire device, e Mauro non ha ancora fatto
la prova.**

**④ Chi comanda su cosa, fra il contratto CD del 18/07 e il foglio del 30/08.**
La risposta esisteva già, scritta da CD in prosa dentro il foglio del 30/08, e
**nessuno l'aveva mai messa dove si va a cercarla**. Ora è in tre posti — indice
dei disegni, SCALETTA, LIBRO. Verbatim:
> «Abolire la porta è più forte che chiedere conferma: il contratto 18/07 lì non
> è violato, è rimasto senza oggetto — e resta vigente sulla LISTA, dove le sue
> due porte esistono ancora.»

**⑤ La scheda ⟦S-EXIT⟧ esiste.** Il buco registrato il 07/08 è colmato:
`SCALETTA:428`, Sezione B. Testo integrale anche in
`HANDOFF/CASSAFORTE_2026-09-01_…md`, Parte B.

**⑥ Due documenti che esistevano in una copia sola sono nel deposito** —
`CONGEDO_REFEREE_2026-09-01_A308-…md` e `CASSAFORTE_2026-09-01_…md`. Verificati
byte per byte contro l'originale: **identici**.

**⑦ Una regola di processo che vale contro il referee.** `LIBRO`, Sezione 2,
**formulazione di Mauro**: *quando Mauro contraddice una misura, il referee la
rimisura, verifica, e gli porta il risultato con la propria opinione spiegata.*
La misura nuova decide, **e può cadere a metà per uno.**

---

## 3 · SUL PALCO NE RESTANO CINQUE — ricensiti alla punta finale

| | ticket | riga | cosa manca |
|---|---|---|---|
| 1 | `TD-show-non-abbandonabile` | `BUGS:65` | il bivio a tre vie dentro il player — disegno CD firmato 29/08 |
| 2 | `TD-qlive-exit-unconfirmed-stop` | `BUGS:182` | la conferma d'uscita, ora **per la sola Lista** |
| 3 | `TD-direttore-parte-da-bar2` | `BUGS:262` | causa non attribuita: si legge dopo ⟦S-EXIT⟧ (f) |
| 4 | `TD-follower-parte-cieco-a-player-chiuso` | `BUGS:328` | l'ascolto del comando del Direttore deve uscire dalla schermata |
| 5 | `TD-fineshow-bottoni-morti` | `BUGS:648` | **solo il collaudo di Mauro** — il codice è fatto |

**Sonda dichiarata:** schede `###` di Sezione 1 che portano il marcatore non
negato, titolo non chiuso. **Controllo positivo:** 11 titoli in forma negata, che
la sonda non confonde.

⛔ **Una conta sui soli titoli SBAGLIA.** Il ticket 2 porta la gravità solo nel
corpo, e `BUGS:320` dichiara che il marcatore viene tolto dai titoli di
proposito. Il congedo che ho ereditato ne dichiarava tre: **erano cinque.**

---

## 4 · ORDINE DEI LAVORI

⛔ **La fila degli atomi NON si tocca:** `⟦S-EXIT⟧ → ⟦S4L⟧ → ⟦S6⟧`, sede unica,
`SCALETTA` Sezione C.

`⟦S-EXIT⟧` scomposto: **(a)** misura · **(b)** peso · **(c)** scheda ✅ fatta oggi
· **(d)** decisioni di Mauro · **(e)** contratto CD · **(f)** codice.
· **(b) è già costruito e collaudato** — A242 + `LiveView.swift:439`, quattro
  cicli su quattro il 31/08.
· **(a) ha una gamba scoperta:** «recupero memoria di iOS», **senza prova**, né in
  codice né su device.
· **(f) va in chat sua**: tocca lo stop dell'audio.

**Ordine proposto dal referee, MAI ratificato da Mauro** — la SCALETTA mette la
conferma d'uscita al quarto posto fra i lavori a fianco, io propongo di portarla
prima. **Serve la parola di Mauro:**

1. 🚨 **Verifica meccanica dei backtick** — prima di qualunque OK su A308.
2. Incidere le **otto ratifiche** della cassaforte, riconfermate da Mauro.
3. **A308 riparte** — ⚠️ punto d'inserimento **da riverificare a fonte**: il LIBRO
   è avanzato di più commit e gli indirizzi sono slittati.
4. Collaudo device su END SHOW → chiude il bloccante 5.
5. Il bivio a tre vie nel player → chiude il bloccante 1.
6. La conferma d'uscita, **per la sola Lista** → chiude il bloccante 2.
7. ⟦S-EXIT⟧ da (d) a (f) → chiude il bloccante 4.
8. bar2 → chiude il bloccante 3.
9. Igiene documenti e freeze grafico.

⚠️ **IL COLLO DI BOTTIGLIA È MAURO**, non CC né CD: fa la staffetta a mano fra
più interlocutori ⇒ **mai due fronti aperti insieme sul lato decisionale.**

---

## 5 · COSA ASPETTA MAURO, E SOLO LUI

**① Il collaudo su END SHOW.** ⚠️ Da fare con la **procedura sicura**, perché i
dati di test possono sovrascrivere quelli veri (`TD-injecttestdata-sovrascrive-dati-reali`,
🔴 ALTA). **Innesco esatto, misurato da CC in A311 leggendo il meccanismo
intero:** la scrittura su disco scatta su una **operazione CRUD** (aggiungi,
modifica, cancella, riordina) su **Song, Setlist o Backtrack** — mai per aprire,
vedere o riprodurre. **Il ticket ne cita 4 funzioni; ce ne sono 10.**
⇒ **Il giro del collaudo non tocca l'innesco in nessun punto.**
Giro: debug → carica dati di test → Shows → apri `TESTSONG L1.b` → Start →
percorri fino in fondo → su END SHOW **un pulsante solo**, BACK TO SHOWS, che
riporta alla libreria → **chiudi l'app dal multitasking**.

**② D2 — la domanda del Follower.** Il Direttore preme Play, il batterista ha in
mano la lista: **l'app lo porta dentro al player, o lo lascia dov'è con una spia
accesa?** ⛔ **Misurato: nessun documento del progetto dice niente su questo
scenario.** Tre strade nominate in `SCALETTA:428`, Parte B.4. Parere del referee:
**C se è uscito lui, A se il comando arriva dal Direttore** — l'app sposta solo
quando l'evento arriva da fuori. Prezzo dichiarato della A: un Play premuto per
sbaglio in soundcheck fa saltare dentro al player **tutti** i telefoni.

**③ D1 — si scioglie con una prova, non a tavolino.** Se lo show sopravviva
all'uscita dalla stanza **non lo sa nessuno**: il codice non ha righe che lo
svuotino fuori da `endShow()`, un commento dice che muore, il tracker dice che
sopravvive, e `QLiveRootView.swift` porta una marcatura §7 che dichiara **non
sorgentata** la tesi su cui tutto poggia. Protocollo in `SCALETTA:428`, Parte B.7:
si legge la parola sul tasto — **BACK TO SHOW** (sopravvissuto) o **START SHOW**
(morto). Tre giri.

**④ Le otto ratifiche** della cassaforte, da riconfermare voce per voce.

**⑤ L'ordine dei lavori del §4**, che è una proposta e non una ratifica.

---

## 6 · I MIEI SEI ERRORI — NON EREDITARLI

**①** Ho detto a Mauro che uscire dalla stanza **cancella la memoria dello show**.
Avevo letto un commento nel codice e l'avevo ripetuto come fatto — **mentre nello
stesso file c'è un cartello §7 che dichiara quella tesi non sorgentata.**
L'avevo sotto gli occhi.

**②** Ho dettato una riga per il LIBRO con **due colonne** in una tabella che ne
ha **sei**. Avevo letto le righe sorelle **tagliate ai primi 230 caratteri** e
dedotto la forma dall'inizio.

**③** Ho dichiarato **superato** il contratto CD del 18/07. **Falso**, e non era
una zona grigia: CD aveva scritto la risposta in chiaro nel foglio del 30/08. Lo
avevo letto **due volte**, fermandomi tutte e due all'elenco in cima.

**④** Quando Mauro mi ha detto «NO NON È COSÌ», la mia scena aveva **una parte
giusta e una sbagliata**, e **ho buttato via tutte e due senza rimisurare.**
È più grave di sbagliare una misura: una misura sbagliata la trova qualcun altro,
**una misura giusta abbandonata non la ritrova nessuno.**

**⑤** Ho chiesto in un mandato una marcatura **già fatta dal 07/08**
(`SCALETTA:313`). Avevo letto in `LIBRO:353` che era «materia del giro doc sulla
SCALETTA» e ho **dedotto** che non fosse stata fatta, senza aprire la SCALETTA.

**⑥** Ho descritto la scena «esci dal player e sei sulla lista». **La freccia
porta al DETTAGLIO** con il click che suona — decisione di Mauro, incisa il
30/08, e una delle strade scartate era proprio «la freccia porta sempre alla
lista». Ho ridescritto come attuale una strada che lui aveva bocciato.

### IL FILO UNICO

**Tutti e sei sono la stessa cosa: ho letto l'inizio di qualcosa e ho dedotto il
resto.** Il congedo precedente ne dichiarava cinque della stessa famiglia su
nove. **Tre referee di fila, stesso guasto.**

Non è distrazione: in un corpus da oltre un milione di byte **le forme ricorrenti
si ricordano da sole, e ricordare è più veloce che misurare.** E la frequenza
**sale con la lunghezza della chat**: i miei primi tre errori sono arrivati tutti
nella seconda metà.

⛔ **Il rimedio non è «starò attento».** È la regola ② — misurato, oppure marcato
«non misurato» — più la regola nuova di Mauro del §2⑦. Sono controllabili da un
altro; la buona volontà no.

---

## 7 · CC — COME SI È COMPORTATO

**Mi ha fermato tre volte, e aveva ragione tre volte.**

- Ha rilevato da solo una collisione di ID che io non potevo vedere, ha
  rinominato e dichiarato.
- Ha aperto i falsi positivi invece di contarli — un payload base64 dentro uno
  script di CD, un UUID di cartella temporanea — e li ha classificati uno per uno.
- Ha **dichiarato un proprio difetto trovato dopo un push** (un numero di
  versione disallineato dalla sua stessa coda) e l'ha **riparato in avanti**
  invece di riscrivere un commit già pubblico.
- Ha corretto la mia premessa su un intero mandato (A304) invece di eseguirlo.
- Ha letto il **meccanismo intero** sull'innesco dei dati di test: il ticket ne
  cita 4 funzioni, **ce ne sono 10**.

⇒ **Quando CC si ferma, ci si ferma.** È scritto in LIBRO.

### ⚠️ UN DIFETTO DA REGISTRARE, PICCOLO NEGLI EFFETTI E GRANDE NEL PRINCIPIO

In A311 CC ha dichiarato di aver **corretto una propria trascrizione**, riportando
il testo a quello «dettato». **Misurato da me alla punta:** il testo dettato dal
referee diceva «il difetto non è il file **ma** il processo»; nel LIBRO è entrato
«il difetto non è il file, **è** il processo».

**Il significato è identico e nessuna affermazione falsa è entrata in un
canonico** — per questo non l'ho fatto riscrivere: sarebbe stato un commit per
due caratteri.

⛔ **Ma la garanzia che si è rotta è quella su cui poggia tutto il resto.** Il
mandato imponeva un confronto **carattere per carattere col testo dettato**, e
quel confronto è stato fatto **contro il ricordo della dettatura, non contro la
dettatura.** È la regola ② violata nell'atto stesso di farla rispettare — la
stessa cosa che ho fatto io sei volte.

⇒ **Da mettere nel primo mandato della chat nuova:** la verifica verbatim si fa
**contro il testo del mandato come ricevuto**, mai contro la sua memoria. E se il
confronto differisce, **ci si ferma** — anche quando la differenza sembra un
miglioramento.

---

## 8 · APERTO, IN ORDINE

1. 🚨 **Verifica dei backtick** — un nome di file fabbricato intercettato in
   `D-59`; le altre 140 voci vengono dallo stesso processo; il controllo **non è
   mai stato mandato a CC**. ⚠️ Il mandato deve chiedere **QUANTE**, non solo
   **SE**: «un'altra» e «trenta» portano a decisioni diverse.
2. **Le otto ratifiche** in `HANDOFF/CASSAFORTE_2026-09-01_…md`, Parte A —
   `ricostruite, non misurate`, registrate in `LIBRO` e **non ratificate**.
3. **A308 congelato**, punto d'inserimento da riverificare a fonte.
4. La riga del regime da precisare (§2①).
5. **Gamba «recupero memoria di iOS»** del punto (a) — senza prova.
6. **24 puntatori nudi nel codice** — misurato da me: 27 citazioni ai canonici nei
   sorgenti, **solo 3 ancorate a un commit**. Le altre puntano a numeri di riga in
   documenti che crescono in testa: quasi certamente già sbagliate, e non danno
   errore.
7. **123 file esistenti solo su E:**, censiti in A301 ed esclusi di proposito dal
   recupero dell'arretrato. Operazione a parte, deliberata.
8. **BOX3 fermo al 22/07** ed è il «leggi-per-primo».
9. **Freeze grafico** — zero elementi costruiti, due decisioni di Mauro prima.
10. Il ticket dell'innesco dati di test cita **4 funzioni su 10** — da aggiornare.

---

## 9 · COSE DA NON RIPETERE

⛔ **NON scrivere un passo di collaudo che presupponga di creare uno show da
zero:** `ShowsListView.swift:221` lo dichiara impossibile. L'unica sorgente di
setlist è il DEBUG.

⛔ **NON chiedere a Mauro verifiche tecniche, versioni, conteggi, forensica di
file.** È mestiere del referee (deposito pubblico) o di CC (via mandato). E non
chiedergli mai di ricostruire a posteriori quante volte ha fatto qualcosa: **la
regola di ripetizione si dichiara prima, e il foglio di raccolta si consegna
insieme alla prova, in forma copiabile.**

⛔ **NON scrivere su Drive.** È il riflesso di E:, non una cartella da riempire.
Ma tu puoi leggerlo e CC no: è così che ho letto i referti prima che fossero
committati.

⛔ **NON ratificare su un riassunto.** Nemmeno sul proprio.

⛔ **NON contare i bloccanti palco sui soli titoli.** Vedi §3.

⛔ **NON dedurre la forma di una riga da una lettura tagliata.** Vedi §6②.

⛔ **Quando due misure attente differiscono di ESATTAMENTE UNO, sospetta la
convenzione prima del file.** Oggi è successo due volte: 204 contro 205 righe di
registro (una conta l'intestazione, l'altra no — stesso file, sha256 identico) e
577 contro 578 righe (una conta l'elemento vuoto finale). **Due «conflitti» che
non esistevano.**

⛔ **NON tirare la chat oltre il lavoro che finisce.** Il taglio va **prima** di
un cancello pesante, mai dentro.

---

**FINE CONGEDO**
