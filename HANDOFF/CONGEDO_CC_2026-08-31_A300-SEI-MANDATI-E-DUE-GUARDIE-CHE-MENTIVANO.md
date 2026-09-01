# CONGEDO CC — A300 — 31/08/2026

Da: CC · A: il CC che apre dopo di me e non ricorda niente di oggi.

**Orologio**: 31/08/2026, **14:48 locale (UTC+2)** — da `date` di sistema di questa macchina.

Marcatura: **[M]** misurato da me ORA, alla fonte, in questa sessione · **[R]** riportato da altri, **non** verificato da me · **[A]** giudizio mio.

---

## 🚨 PRIMA DI USARE UNA RIGA DI QUI SOTTO

⛔ **Questo documento NON È UNA FONTE.** È un puntatore. Ogni cosa che dice va rimisurata prima di essere riusata: gli indirizzi di riga slittano a ogni commit, i numeri scadono, e le mie conclusioni possono essere sbagliate come quelle di chiunque.

⚠️ **Non è una cautela di forma, ed è successo oggi.** Il referee ha ereditato un congedo che dichiarava **chiuso** un punto che chiuso non era, e ha ripetuto quella dichiarazione per mezza sessione prima che la misura la smentisse. **Un congedo letto e creduto è il modo più veloce per propagare un errore.** Scrivo questo sapendo che qualcuno lo crederà: per favore, non farlo.

⛔ **Non copio qui lo stato del progetto** — versioni, HEAD, quali ticket sono aperti, quali cancelli chiusi. Quelle cose vivono nei canonici e **soltanto** lì. Un congedo che le copia mente entro un'ora. Qui trovi **dove guardare** e **come mi sono rotto**, non cosa c'è scritto.

⚠️ **Tutto ciò che è marcato [M] l'ho misurato IO, in questa sessione, con i miei comandi.** In questa sessione hanno girato anche agenti di misura in parallelo: **le loro misure NON sono marcate [M] in questo documento**, e dove le cito lo dico. Uno di essi ha trovato un errore vero nel mio testo (§c.3): quello lo dichiaro, perché conta.

---

## (a) ID — `A300`

**[M]** Cancello a sei gambe, misurato ORA: nomi su `C:` = 0 · nomi su `E:` = 0 · `git grep` tracciato = 0 · disco `C:` = 0 · **disco `E:` = 3** · `git log --all --grep` = 0.

⚠️ **Le tre occorrenze su `E:` sono state APERTE, non contate** (`R-δ.8`: un numero non chiude un cancello). Stanno tutte e tre in file di cattura syslog sotto `LOG/RUN/TEST LUNGA DISTANZA/`, e il contesto esatto è `uuid=8A300…` / `uuid=A300A…`: **`A300` è una sottostringa dentro un campo UUID di iOS**, non un identificativo di mandato. È la classe `R-δ.10` — **falso-UNO**, un riscontro che sembra un fatto.

✅ Controlli positivi nello stesso giro: `A298`/`A297`/`A295` rendono tutti >0 su più gambe. **Le sonde vedono.** ⇒ ID **libero**, assegnato.

---

## (b) COSA HO FATTO — sei mandati, quattro commit, e dove stanno le prove

**[M]** Perimetro: da `597961eee7b4046815f580e406a40d2d96512a51` (dove ho trovato il repo) a `05283ced21de8456099cf8f6b9cda0caf573da35` (dove chiudo). Tutti e quattro i commit sono **doc-only o design-only: zero righe di codice.**

```
05283ced21de8456099cf8f6b9cda0caf573da35  14:18  SCALETTA v16
8d665e1e003990ac5e8af004cc7a6c8fbfa5a6a4  14:18  LIBRO v70
0000dd4f743ca9a1e08d2304b33664f61f91a39a  14:18  BUGS v78
5eb18c7de46dba72483710feb18416c8a9eed0a9  13:22  DESIGN: foglio CD 30/08
```

⛔ **Non riassumo il contenuto: sta nei messaggi di commit, nei diff e nei referti.** Tutti depositati su **due gambe** con `cmp` exit 0, in `HANDOFF/` sul repo e su `E:\…\FILE X CLAUDE.MD\HANDOFF\`:

- `MISURE_CC_2026-08-31_A295-FOGLIO-CD-30-08-IMPRONTA-IDENTICA.md` (contiene in coda la **correzione A296**)
- `MISURE_CC_2026-08-31_A297-COMMIT-PUSH-FOGLIO-CD.md`
- `MISURE_CC_2026-08-31_A298-GIRO-DOCUMENTI-TRE-COMMIT-PRONTI.md`
- `MISURE_CC_2026-08-31_A299-COMMIT-PUSH-TRE-DOCUMENTI.md`
- `DIFF_BUGS-v78_A298_2026-08-31_CC.txt` · `DIFF_LIBRO-v70_A298_2026-08-31_CC.txt` · `DIFF_SCALETTA-v16_A298_2026-08-31_CC.txt`

**[M]** Le tre stampe R-δ dei canonici sono su `E:` in `BUGS_QBEATS/`, `LIBRO_MASTRO/` e `HANDOFF/`, **estratte dal blob** con `git show` e verificate `cmp` exit 0 contro il blob stesso.

---

## (c) I MIEI ERRORI — con il MECCANISMO, che è l'unica parte che serve

⛔ Sono tutti miei e tutti di oggi. Scrivo **come si sono prodotti**, non il rimorso.

### ① L'impronta composta a memoria — e la disciplina che copriva il file ma non la frase

**[M]** In una sintesi in chat ho scritto l'impronta `0b11c226` + `c398860f`. Scomposta carattere per carattere: la **testa è giusta** (foglio CD); la **coda `c398860` appartiene a un altro file** — è la coda del contratto `2026-07-18_QLive-Exit-in-Play.html`, la forma che ricorre più volte nei documenti di questo progetto **e nel mandato stesso**; la `f` finale non appartiene a nessuno dei due.

🚨 **Il meccanismo, ed è il punto:** il **referto** era corretto — l'avevo generato con variabili di shell e `assert`, e le sue celle portavano i 64 caratteri pieni. L'errore stava **nella prosa che descriveva il referto**, scritta a mano fuori da quella disciplina. ⇒ **La guardia copriva l'artefatto e non la frase sull'artefatto.** Il richiamo di una forma familiare è più veloce della misura e produce stringhe **plausibili**, che nessuna guardia di sola forma intercetta.

✅ **Rimedio:** un'impronta o si scrive **intera**, o si abbrevia **con un comando nello stesso turno in cui la si misura** (`${H:0:8}…${H: -7}`), mai ricordandola da un altro contesto. Ratificato oggi come regola ② in `LIBRO` Sezione 2.

### ② Ho riprodotto `R-δ.9` nell'atto di descriverla

**[M]** Correggendo ① ho scritto una nota che diceva «la guardia trova **2** occorrenze» — e la nota **citava per esteso la stringa rotta** dentro il comando che descriveva. Con quella citazione le occorrenze sono diventate **3**: la nota ha reso falso il numero che riportava, nell'istante in cui lo scriveva.

🚨 **Meccanismo:** non è «un documento altera il proprio stato» in astratto. È una mossa precisa: **citare la cosa che stai contando**. ✅ **Rimedio:** il conteggio delle occorrenze di X non si scrive in prosa **insieme a X**; si legge dalla guardia, che gira dopo.

### ③ Un'affermazione universale senza spazzata — trovata da un altro, non da me

**[M]** Nella marcatura SCALETTA avevo scritto che «l'audio si ferma uscendo dalla STANZA, **non dal player**». Letta come universale è **falsa**: `git grep` rende **altri chiamanti** di `audioEngine.stop()`, fra cui **il comando STOP del transport**, `ios_app/QBeats/UI/Live/TransportView.swift:58` — che è dentro il player.

🚨 **Meccanismo:** ho generalizzato dall'**unico** sito che il mandato mi aveva indicato, senza cercare **chi altro produce quell'effetto**. La regola «sweep per effetto» esiste già in casa e non l'ho applicata perché l'indirizzo mi era stato **dato**, e un indirizzo dato sembra un perimetro.

⚠️ **Non me ne sono accorto io**: l'ha trovato un passaggio di **verifica avversariale** che avevo lanciato in parallelo, il cui compito era provare che le mie misure fossero sbagliate. **[A] È l'unica ragione per cui non è finito nel canonico.** Ho ristretto la frase e **dichiarato la spazzata in loco**, elencando gli altri chiamanti.

### ④⑤ DUE GUARDIE MIE CHE HANNO MENTITO — ed è la lezione più riusabile di oggi

**[M] ④ Guardia troppo grossolana.** La mia guardia di parità dei backtick ha dichiarato `BUGS_QBEATS.md` **rotto**. Non lo era: il conteggio **globale** era dispari **già nel blob**, e le righe responsabili sono **3**, tutte **delimitatori di blocco di codice** — markdown corretto. Prima 3, dopo 3: non ne avevo introdotta nessuna. ⇒ **La granularità della guardia non corrispondeva alla proprietà che pretendeva di testare.** Quella significativa è **per riga**, non globale.

**[M] ⑤ Guardia che pone la domanda sbagliata.** La mia guardia di sostanza verifica che ogni SHA scritto risolva, e lo faceva con `git cat-file -e <sha>^{commit}`. Ha bocciato **sei** valori su nove. Erano **tutti corretti**: tre erano **blob**, non commit; e tre erano **OID calcolati con `git hash-object`, che NON scrive l'oggetto** — non esistevano ancora nel database, e non dovevano esistere, perché sarebbero nati col `git add`.

🚨 **Meccanismo comune a ④ e ⑤:** una guardia incorpora un'**assunzione non dichiarata** — sulla granularità, sul tipo dell'oggetto — e quando l'assunzione non regge, **la guardia produce un allarme che sembra un fatto**. È la stessa polarità del falso-UNO.

✅ **Rimedio, e vale più delle due guardie:** ⛔ **quando una tua guardia fallisce, la prima cosa da interrogare è la guardia, non il dato.** Due volte oggi ho quasi riportato un allarme falso al referee. In entrambi i casi la domanda giusta era «che cosa sta davvero chiedendo questa sonda?».

### ⑥ Difetti minori, per completezza

**[M]** Una nota finita **dopo** la riga di chiusura di un documento, perché ho fatto due `append` in sequenza su un file che aveva già il proprio terminatore (⇒ ancorare gli inserimenti al **contenuto**, mai alla fine del file). E un **backtick al posto dell'apostrofo** in un file di memoria, intercettato dalla guardia di parità.

---

## (d) TRAPPOLE DI QUESTA MACCHINA — costano tempo e non stanno in nessun canonico

**[M]** Misurate oggi, tutte a mie spese:

- 🚨 **Il heredoc di Bash si rompe su contenuti lunghi con backtick.** `<<EOF` **non quotato** innesca la sostituzione di comando sui backtick. `<<'EOF'` quotato dovrebbe essere letterale, e **ha comunque fallito ripetutamente** (`unexpected EOF while looking for matching '`) su testo lungo con virgolette ed emoji miste. **Ho perso tre tentativi.** ✅ Per scrivere un documento lungo, usa lo strumento di scrittura dedicato, non il heredoc.
- `rev` **non esiste** in questa Git Bash.
- `basename` su un path **non quotato** con spazi rende `extra operand` — e `E:\HOBBY\MUSICA - BATTERIA -SISTA\…` ha spazi ovunque.
- Lo **stdout di Python è cp1252**: stampare emoji solleva `UnicodeEncodeError`. Scrivi su file, oppure `sys.stdout.reconfigure(encoding='utf-8')`.
- ⚠️ **`grep -c` conta RIGHE, `grep -o | wc -l` conta OCCORRENZE**, e i due numeri divergono. **Le sonde ID di questo progetto usano la lettura per RIGA**: verificato oggi riproducendo esattamente i controlli positivi del referee (`A244`=5 · `A253`=8 · `A290`=11 · `A291`=2) **solo** su quella lettura. La lettura per occorrenza rende 5/9/13/3. **Dichiara sempre quale stai usando.**
- **La CI parte sul PUSH, non su ogni commit.** Tre commit spediti in un push solo producono **una** run, sulla punta. ⛔ Non scrivere «CI verde su tutti e tre»: scrivi «verde sulla punta che li comprende».
- ⚠️ **Un file scritto solo nel repo `C:` non arriva su Drive.** Il riflesso è agganciato a `E:\…\FILE X CLAUDE.MD\`.

---

## (e) COSA NON HO FATTO, E PERCHÉ

- ⛔ **Non ho verificato l'IPA** prodotta dalla CI: so che il job è verde, non ho aperto il binario.
- ⛔ **Non ho inciso le due voci che il congedo precedente lasciava aperte**, e **[M] sono ancora assenti**: in `BOX5_QBEATS.md` rendono **0** sia «la quadratura che torna non prova i numeri» sia «pattern degenere su campi con prefisso» (controllo positivo: `PATTERN DEGENERE`, la classe generale, rende **1** ⇒ la sonda vede). Nessun mandato di oggi le ha chieste. **Restano il primo lavoro documentale disponibile, se il referee lo ratifica.**
- ⛔ **Non ho riordinato `E:`.** **[M]** Il foglio CD del 30/08 esiste ora in **tre** posti: nel repo (`DESIGN/QLive_Nav/`), in `DA_CD_PER_CC/30_08_2026/` (sede R-δ), e **ancora** in `_TRANSITO_DA_VERIFICARE/A275_foglio-CD-30-08/` insieme al suo `PROVENIENZA.txt`. La copia in transito è **invariata e verificata tale**. Il riordino è un atomo suo, registrato e non aperto.
- ⛔ **Non ho aperto il censimento degli altri ID mancanti dai canonici.** `A242` era assente e ora è registrato in `BUGS`; **[A] se manca uno, possono mancarne altri**, ma il censimento non era di questo giro ed è dichiarato come sospetto in una riga.
- ⛔ **Non ho toccato i 13 rami non-merged.** ⚠️ **[M] Se rimisuri `fix/a267-rientro-dalla-sua-sezione`:** il diff filtrato `-- 'ios_app/'` è **vuoto** (il codice è già in master), ma quello **non filtrato rende 902 righe** — ed è cresciuto da 420 in un solo giorno, perché **master avanza sui canonici e il ramo no**. 🚨 **Un merge oggi cancellerebbe lavoro documentale.**
- ⛔ **Non ho riparato i 30 sorgenti a fine-riga divergenti.** **[M] Rimisurato ora: 30 su 282** — istogramma `224 lf→lf` + `30 lf→crlf` + `28 -text→-text` = **282**, quadratura chiusa. Ticket aperto, e c'è una build collaudata da proteggere.
- ⛔ **Non ho scritto la scheda ⟦S-EXIT⟧** né deciso alcuna roadmap: non è materia mia.

---

## (f) COSA MI È STATO DETTO E NON HO VERIFICATO — non ereditarlo come misurato

- **[R]** **Il collaudo su device di Mauro del 31/08** (quattro cicli, numeri mai trattini) e quello del 30/08 sul blocco schermo. **Non verificabili da qui: non ho un device.** Sono la gamba su cui poggia la chiusura di un bloccante palco e una marcatura di SCALETTA.
- **[R]** Che l'OK di Mauro ai commit sia arrivato, e che valga come sua firma sulla chiusura del bloccante: mi è stato riferito dal referee, **non l'ho letto io**.
- **[R]** Le riverifiche che il referee dichiara di aver fatto dal repo pubblico. Le impronte che riporta coincidono con le mie, **ma il confronto l'ha fatto lui**.
- **[R]** Gli errori di indirizzo che il referee attribuisce a sé stesso e al referee precedente, registrati nella regola ② di `LIBRO`. **Ho verificato solo il mio.**

---

## (g) UNA PREMESSA DI MANDATO CHE OGGI È SCADUTA — perché non ci ricaschi

**[M]** Il mandato A299 prescriveva di estrarre dal blob perché «LIBRO e BUGS hanno due facce, CRLF su disco e LF nel deposito, e `.gitattributes` non le copre entrambe». **A HEAD non è più vero:** `git check-attr text` rende `unset` su tutti e tre i canonici toccati, i CR sul disco sono **0**, e `git hash-object` sul disco coincide con `git rev-parse HEAD:<file>`. **La faccia è una sola**, da `b962c48` del 30/08.

⇒ **L'estrazione dal blob resta la procedura corretta** — è ciò che ho fatto — ma la sua **motivazione storica è scaduta**. ⚠️ Se qualcuno te la ripete come fatto vivo, rimisurala.

---

## (h) IL COMMIT DI QUESTO DOCUMENTO — la mia valutazione, non una prescrizione

**[A] Raccomando di committarlo.** Non per abitudine: per una misura.

**[M] La pratica attuale è incoerente e non è una politica.** Sul disco ci sono **29** congedi CC e **7** sono tracciati; **80** referti `MISURE_CC` e **21** tracciati. `.gitignore` **non contiene alcuna regola** su `HANDOFF/` o sui congedi (verificato), e in `HANDOFF/` **66** file sono tracciati: quindi non è una scelta, è **deriva**.

⚠️ **`R-δ.9` in atto su questa riga stessa, e la lascio visibile perché insegna:** il **29** qui sopra è **scattato PRIMA del deposito di questo documento**. Depositandolo il conteggio è diventato **30** — misurato dopo. Il numero dei tracciati resta **7**, perché questo congedo non è committato. ⇒ **Un documento che conta una popolazione a cui appartiene si conta di meno finché non si deposita.** Non correggo il 29 in 30: la regola prescrive di dichiarare le misure come scattate prima del deposito, e vedere le due cifre accanto vale più di vederne una sola giusta.

🚨 **E quella deriva è costata un turno intero oggi.** Il mandato A294 mi ha assegnato un ID **già occupato** dal congedo depositato poche ore prima. Il referee non poteva vederlo: **il suo campo visivo è il repository pubblico, e quel congedo era untracked.** Il referee stesso lo ha scritto nel mandato successivo — «è il buco che ha bruciato A289 e A294».

⇒ **[A] Un congedo committato è un congedo che il referee può vedere, e il cancello ID smette di avere un punto cieco.** ⛔ **Ma non è una decisione mia**: cambia un regime, e i regimi li ratifica il referee e li approva Mauro. **Il documento è depositato e NON committato.** Comando pronto, fermo:

    git add -- HANDOFF/CONGEDO_CC_2026-08-31_A300-SEI-MANDATI-E-DUE-GUARDIE-CHE-MENTIVANO.md
    git commit -m "HANDOFF: congedo CC del 31/08 (A300)"

---

## (i) SE APRI DOPO DI ME

1. **Rimisura prima di fidarti**, di questo documento come di qualunque altro. Stato, versioni e HEAD si leggono **dalla testa dei canonici e da `git`**, mai da un congedo.
2. **[M] Il lavoro di oggi è tutto committato e pushato, tree pulito sui tracciati** (`git status` rende **0** righe non-`??`). Non c'è niente a metà, niente in staging, niente in attesa di un mio ritorno.
3. **Prima di credere a un allarme di una tua guardia, interroga la guardia** (§c.④⑤). Due volte su due, oggi, l'allarme era della sonda e non del dato.
4. **Prima di scrivere «l'unico», «non esiste», «solo qui»: fai la spazzata per EFFETTO e dichiarala** (§c.③). Un indirizzo che ti è stato **dato** non è un perimetro.
5. **Non abbreviare mai un'impronta a memoria** (§c.①). O intera, o abbreviata da un comando nello stesso turno.
6. ⚠️ **Se un mandato ti dà un ID, verificalo sul TUO disco**, untracked compresi: il referee non li vede, ed è già costato due volte.

---

*A300-SEI-MANDATI-E-DUE-GUARDIE-CHE-MENTIVANO — FINE.*
