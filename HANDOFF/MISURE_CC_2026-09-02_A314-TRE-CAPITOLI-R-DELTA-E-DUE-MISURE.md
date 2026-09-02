# MISURE CC — A314 — 02/09/2026

Mandato: tre blocchi di metodo in BOX5 + una qualifica in riga + due misure con tetto.
Punta di partenza: `c504ee4d9a0d1fd2986c64718e65a58b5ecb55d9`.
⛔ Questo referto **non è una fonte**: ogni numero va riletto a fonte prima di usarlo.

---

## 1 · CANCELLO ID

**ID preso: `A314`** — il primo libero a partire da quello immediatamente successivo ad A313.
⛔ I candidati scartati non sono nominati (R-δ.9). Nessuno lo è stato: il primo provato era libero.

**Sei gambe girate**, nella forma dei congedi A294/A297:

| gamba | esito su A314 |
|---|---|
| nomi su `C:` | 0 |
| nomi su `E:` | 0 |
| contenuto tracciato, `git grep -- ':!DESIGN'` (R-δ.10) | 0 |
| contenuto su disco `C:`, untracked compresi | 0 |
| contenuto su `E:`, `.md`/`.txt` | 0 |
| `git log --all --grep` | 0 |

**Controlli positivi** — ID già occupati, quindi nominarli non costa nulla (R-δ.9):
· **A313** rende **7** occorrenze sulle sei gambe. ✅ Coerente con la misura del referee: occupato **due volte**, oggetto del commit `946dcc977c810174b40e2b08ac60141e3cb3e79e` e file `HANDOFF/CONGEDO_CC_2026-09-01_A313.md` (la gamba `git log --all --grep` rende 2).
· **A312** rende **8**.
⇒ La sonda **non è cieca**: lo zero su A314 è uno zero misurato, non un'assenza di misura.

⚠️ **Limite dichiarato, invariato:** il cancello resta senza mutua esclusione. Una sessione concorrente che misurasse A314 nello stesso istante lo troverebbe ugualmente libero.

---

## 2 · PRE-VOLO

### (2a) Dove vanno i tre capitoli — ramo **«in coda al file»**

**Misura:** il numero di riga più alto citato da una citazione **nuda** `BOX5_QBEATS.md:NNN` (priva di `@ <commit>`), su tutto il repo alla punta, `.swift` compresi: **940**.
Sonda: 642 file dell'albero a `c504ee4`; **177 citazioni nude**, **30 ancorate**.
**Controllo positivo passato:** la sonda trova `BOX5_QBEATS.md:573` citata nuda in due punti reali di BOX5 stesso — bersaglio verificato **prima** di fidarsi del massimo.

Il capitolo R-δ.10 finisce alla riga **857** (858 vuota, 859 apre `## Backlog`).
**940 non è inferiore a 857** ⇒ ramo **«Altrimenti»: innesto IN CODA al file.**

⇒ Effetto della regola, che è il suo motivo: innestare dopo l'857 avrebbe spostato in avanti ogni riga sottostante e fatto **scadere in silenzio** le citazioni nude che puntano oltre — 940 compresa. L'innesto in coda **non sposta nessuna riga esistente**.

### (2b) Impronte di BOX5

| | byte | righe | sha256 |
|---|---|---|---|
| **prima** | 138.428 | 1.354 | `57d41089b97a57d17b9cefadd4403b88a1e999e95046dbb3b92fec2a4afe08a8` |
| **dopo** | 145.170 | 1.393 | `e873cfb8c7e8675038a1dccfa94839a3f186391c67e9bab88ba3449619b6913f` |

Fine-riga: **LF puro, zero CRLF**, prima e dopo.

---

## 3 · ESITO DELLA VERIFICA DI RISOLUZIONE SULLE CITAZIONI DEL MANDATO (§10, ultima voce)

Il mandato impone di verificare che le proprie citazioni risolvano **prima** di incidere. Fatto:

| citazione del mandato | esito |
|---|---|
| `LIBRO_MASTRO_QBEATS.md:344 @ c504ee4d9a0d1fd2986c64718e65a58b5ecb55d9` | ✅ **RISOLVE** — la riga porta verbatim «Da qui in avanti ogni rimando nuovo nomina il documento; se porta un numero di riga, porta `@ <commit a 40>`» |
| `LIBRO_MASTRO_QBEATS.md:335 @ 7ec6c1b86a7acb869c1f927fa4833374ffabb0cc` | ✅ **RISOLVE** — la riga è l'estensione ai sorgenti ratificata 01/08, «per SIMBOLO, non per riga» |
| `LIBRO_MASTRO_QBEATS.md:359 @ c504ee4d9a0d1fd2986c64718e65a58b5ecb55d9` | ✅ **RISOLVE** — la riga del 18/08, «viva e non onorata», col divieto esplicito di riscriverla |

**Reperto dichiarato al §7-bis, escluso dal conteggio, verificato solo per accertare che sia davvero rotto:**
`LIBRO_MASTRO_QBEATS.md:344 @ 7ec6c1b86a7acb869c1f927fa4833374ffabb0cc` → a quel commit la riga 344 è **`---`, un separatore**. Il file aveva 495 righe, quindi non è un fuori-range: è un bersaglio sbagliato. ⇒ Confermata rotta.

⇒ **Nessuna condizione di ABORT è scattata.** Il metodo vede sia i sani sia il rotto: non è cieco in nessuna delle due direzioni.

---

## 4 · COSA È STATO INCISO, E COME

**Procedura del §3, rispettata alla lettera:** i tre blocchi e la qualifica sono stati trascritti **una volta sola** in due file d'appoggio (39 righe / 6.285 byte i blocchi; 457 byte, zero a capo, zero `|` la qualifica), poi inseriti da uno script che **copia byte**. Zero ridigitazioni.

**Guardie POSIZIONALI, non di identità:**
· impronta di partenza verificata (sha256 + byte + righe + assenza di CR);
· il punto d'innesto è la coda: verificato il **contorno atteso** — l'ultima riga di contenuto è quella del punto 7 della dichiarazione finale, seguita da riga vuota e terminatore;
· la riga della qualifica individuata **per descrizione e unicità**: unica riga la cui prima cella è `**PARAMETRO IGNORATO IN SILENZIO**`, con 6 `|` e la cella «come si smaschera» che finisce per «col totale non filtrato».

**Guardie sul RISULTATO:**
· `cmp` blocchi innestati ↔ file d'appoggio → **exit 0**;
· `cmp` qualifica innestata ↔ file d'appoggio → **exit 0** (offset 301 nella riga);
· la riga della qualifica ha **6 `|` dopo l'edit, come prima** ⇒ stesso numero di celle, il file non cresce di righe in quel punto;
· righe totali **1.354 + 39 = 1.393**, esattamente le righe dei tre capitoli;
· diff strutturale contro la copia di partenza: **`2c2` · `1021c1021` · `1354a1355,1393`**, e nient'altro.

**Versione:** V42 → **V43**, data **2026-09-02**, sostituita **dentro la riga** (R-δ.7). Nessuna riga aggiunta in testa.

---

## 5 · PRIMA MISURA (§7) — che cosa misurava «colonna Stato 1 riga su 203»

**(e) «COLONNA STATO 1 RIGA SU 203» — DUE LETTURE, NESSUNA CHIUSA. IPOTESI APERTA, NON ERRORE DI NESSUNO.**
La frase viene dal congedo della seconda chat referee del 01/09 e **non porta con sé la propria sonda**: non dice l'oggetto contato, non dice il comando, non dice il commit.
Due letture sono state provate, entrambe misurate sul deposito pubblico:
· **Lettura A — manca la cella.** A `41a1ae3d7d4714c1a7284f852d50b7a4a6a8fb62` la Sezione 2 del LIBRO ha 202 righe-dato più l'intestazione, cioè **203**, e contiene **una sola riga con meno di sei celle**: ne ha due, ed è la riga del regime di deposito. Il commit successivo, `c46a3b8bb3c5297dea56eb4b95e1677f0b07433b`, si intitola «completa la riga del regime, sei colonne», e dopo di esso le righe corte sono **zero**. **RIPRODUCE.**
· **Lettura B — il valore della colonna.** «Stato uguale a superseded oppure revocata» rende **5** a `41a1ae3d7d4714c1a7284f852d50b7a4a6a8fb62`, **5** a `2c9b0bf8d4e48e2d6133029245b4db8e9bf5b9e3` e **5** a `c504ee4d9a0d1fd2986c64718e65a58b5ecb55d9`; il valore `revocata` rende **0** a tutte e tre; e la lettura stretta — superseded **e** colonna «Superseded da» compilata — rende anch'essa **5**. **NON RIPRODUCE.**
⚠️ **IPOTESI PIÙ PROBABILE, APERTA E NON ATTRIBUITA A NESSUNO:** che l'altra chat non stesse contando la Sezione 2 del LIBRO ma **un altro oggetto con 203 righe**, che nessuno ha mai nominato. Se è così **entrambi i numeri sono veri**, e ciò che manca non è una misura: è **il nome dell'oggetto**.
⛔ **Cosa serve per chiudere, e non è un'altra lettura: la sonda.** Su quale oggetto, con quale comando, a quale commit. **La prosa di un congedo non è una misura**, e una citazione che riporta cosa qualcuno ha scritto non dimostra che fosse vero.
⇒ **Conseguenza dichiarata:** la lezione «uno strumento facoltativo muore» poggia oggi su **tre istanze misurate** — Sezione 6 ferma alla riga 68, «FATTO NON REGOLA» usata una volta, le stampe su `E:` mai fatte per otto giri — **più una contestata**. ⛔ Non si incide finché la quarta non è chiusa, e **non si scrive con quattro**.
⚠️ **Reperto collaterale, misurato nello stesso giro:** in Sezione 2 esiste anche **una riga con sette celle** invece di sei. Una sonda che legge «l'ultima cella» invece della «sesta» rende su quella colonna **11 invece di 10** — scarto di esattamente uno, **causa la convenzione e non il file**, ed è la sorella della riga a due celle.

## 6 · SECONDA MISURA (§7-bis) — ancore che non risolvono nei cinque canonici

Cinque canonici verificati a fonte (`LIBRO_MASTRO_QBEATS.md:343 @ c504ee4d9a0d1fd2986c64718e65a58b5ecb55d9`): **LIBRO · BUGS · BOX3 · BOX5 · SCALETTA** (`HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`).

**Insieme:** 107 occorrenze ancorate, **77 bersagli distinti** (`FILE:riga @ sha40`).

### Il numero

| esito | conteggio |
|---|---|
| **NON risolvono, confermato** | **1** |
| risolvono (riga esistente e sostanziale) | 76 |
| **candidate non chiarite** (vedi limite sotto) | **8** |

**L'unica rotta confermata** è `LIBRO_MASTRO_QBEATS.md:344 @ 7ec6c1b86a7acb869c1f927fa4833374ffabb0cc` **come compare dentro `LIBRO_MASTRO_QBEATS.md:359`** — cioè dentro un canonico. È la pendenza (d).

⛔ Nessuna riparazione, nessuna riscrittura, nessun elenco di correzioni proposte.

### La classe in cui cade — e perché NON la applico

La regola di chiusura dice: una o due → caso chiuso. **Misuro 1, e non dichiaro il caso chiuso.**

Il motivo è che la mia misura ha **due forze diverse**, e la più debole non è conclusiva:
· il test **strutturale** (la riga esiste? è un separatore? è vuota?) è affidabile e rende **1**;
· il test di **contenuto** (la riga *dice* quel che la citazione afferma?) ha reso 18 conferme su 27 coppie verificabili — controllo positivo superato — ma **non distingue una citazione testuale da un'affermazione sul bersaglio**, e lascia **8 candidate** che non ho potuto chiarire entro il tetto.

⇒ **Riporto il numero e non concludo.** Dichiarare «1, caso chiuso» sarebbe la polarità **P3**: un totale che torna su una sola classe, presentato come se coprisse l'insieme.

**RATIFICA DI MAURO, 02/09/2026 — IL §7-bis È CHIUSO SULLA DOMANDA POSTA.** Commit che precede la nascita della riga citata: **1 rotta**, ed è `LIBRO_MASTRO_QBEATS.md:344 @ 7ec6c1b86a7acb869c1f927fa4833374ffabb0cc` come compare dentro la riga del 18/08. Verificata in modo **indipendente dal referee** sul deposito pubblico: 75 risolvono, 1 rotta, 2 non determinabili dal solo deposito perché citate **senza percorso**. ⛔ Le **8 candidate** del test di contenuto **non riaprono il giro**: rispondono a una domanda diversa e più larga, **già a verbale il 18/08** in `LIBRO_MASTRO_QBEATS.md:359 @ c504ee4d9a0d1fd2986c64718e65a58b5ecb55d9`, con il divieto di riparazione già scritto accanto. Si riportano come **limite dichiarato**, col puntatore a quella riga, e non come conteggio aperto.

### ⛔ LIMITE DICHIARATO — regola di lettura, per esteso

Il perimetro «solo le ancorate» è una **scelta deliberata**, e la ragione è buona: è lì che il difetto si nasconde, perché nessuno sospetta un'ancora, e l'insieme ancorato è piccolo. **Ma non è una copertura.**

· Le citazioni **NUDE restano fuori dal conteggio.**
· «Le nude sono note» vale per il censimento del 18/08, che è una **fotografia di quella data** e non una proprietà permanente del corpus. **Le citazioni nude scritte DOPO quel censimento non sono coperte da nessuna misura**, né da quella né da questa.
· **Quante siano non lo sa nessuno, e questo giro non lo misura.**

⛔ **Il numero di questa sezione NON autorizza in nessun caso la frase «le citazioni sono state verificate».** Chi lo cita così sta citando male. Dice una cosa sola: **quante ancore, fra quelle presenti nei cinque canonici, non risolvono** — e con la riserva sulle 8 candidate scritta sopra.

⇒ È la stessa cautela già dichiarata nel BLOCCO A sul «quanto sia diffuso non è misurato». Le due dichiarazioni **si tengono per mano**: senza di esse, un numero parziale diventa in tre mesi una garanzia che nessuno ha mai dato.

---

## §4 · La convenzione, e cosa spiega davvero lo scarto

**La mia regola di conteggio:** dedup della terna (percorso come scritto · riga · sha a 40), sui cinque canonici.

🚨 **PRIMA CORREZIONE — una riga falsa del mio stesso referto.** La parentesi «escluso il reperto come compare dentro il BLOCCO A» stava accanto al 77, ma quell'esclusione era applicata **solo al test di contenuto, non all'enumerazione**. Rimisurato: **con** BLOCCO A ⇒ 77 bersagli / 107 occorrenze · **senza** ⇒ **75 bersagli / 103 occorrenze** · per solo nome file, 73 con e 71 senza.

🚨 **SECONDA CORREZIONE — la riconciliazione che ne avevo tratto confrontava DUE OGGETTI DIVERSI, e va ritirata.** Il 77 è misurato **su disco a giro fatto**, con i tre capitoli già innestati; il 78 del referee è misurato **alla punta `c504ee4d9a0d1fd2986c64718e65a58b5ecb55d9`**, cioè **prima** dell'innesto. Confrontarli rende «scarto 1». Il numero comparabile al 78 è **75**.
⇒ **LO SCARTO REALE FRA LE DUE SONDE È 3, NON 1.**
⛔ **Ritirata la conclusione «non è un effetto di convenzione: è un singolo bersaglio».** Era corretta rispetto alla premessa, e la premessa era sbagliata.
⚠️ **Lo stesso difetto colpisce anche l'accordo che sembrava perfetto:** le «107 occorrenze» del referee e le mie «107» **non sono lo stesso numero** — il suo è pre-innesto, il mio post. Il paio comparabile è **107 contro 103**.

✅ **IPOTESI CHE RIPRODUCE, E RIPRODUCE SU DUE NUMERI INDIPENDENTI.** Misurata dal referee il 02/09 provando **quattro** ipotesi e non fermandosi alla prima: la sua sonda ammette l'estensione `.yml`, e alla punta ci sono **4 occorrenze** su `ios_app/project.yml`, distribuite su **3 bersagli distinti** (una riga è citata due volte).
· occorrenze: 107 − 4 = **103** ⇒ coincide col mio pre-innesto
· bersagli distinti: 78 − 3 = **75** ⇒ coincide col mio pre-innesto
Le altre tre ipotesi mancano il bersaglio, e sono registrate perché il loro fallimento è parte della prova: escludere `DESIGN/` rende 77 · ammettere i soli `.md` rende 58 · escludere i nomi senza percorso rende 22.
⇒ **Era una convenzione dopo tutto** — l'insieme delle estensioni ammesse dalla sonda — cioè esattamente ciò che la R-δ.13 incisa in questo stesso giro dice di sospettare per primo.

⚠️ **E QUI SI APPLICA LA QUALIFICA INCISA OGGI, CONTRO NOI STESSI: la quadratura è necessaria e non sufficiente.** Due numeri che tornano su una sola ipotesi sono un indizio forte, **non una prova**: somme uguali si ottengono anche da insiemi diversi. L'ipotesi resta tale **finché la sonda non parla** — vedi la dichiarazione qui sotto.

✅ **COSA DEL §4 NON CADE:** lo scarto **fra le due convenzioni** (percorso letterale contro solo nome file) è **4** in tutte e **tre** le coppie misurate — 78/74, 77/73, 75/71. È invariante rispetto all'osservatore e rispetto al momento, ed è un fatto che regge.

⛔ **E il numero che decide non si è mai mosso:** le citazioni **rotte** sono **1**, misurata in modo indipendente dal referee sul deposito pubblico e da CC su disco. Le due sonde divergono sul denominatore e **coincidono sul verdetto**.

### La sonda parla — dichiarazione di CC, letta dal codice e non dalla memoria

**Insieme delle estensioni ammesse dalla mia sonda, verbatim dal codice che ha girato:**

```
([A-Za-z0-9_/\.\-]+\.(?:md|swift|mm|h|txt)):(\d+)\s*@\s*`?([0-9a-f]{40})`?
```

⇒ L'insieme ammesso è **`.md` · `.swift` · `.mm` · `.h` · `.txt`**, e nient'altro.

· **Contiene `.yml`? NO.**
· **Occorrenze del mio censimento che cadono su `ios_app/project.yml`: ZERO** — per costruzione, perché la sonda non può vederle.
· **Occorrenze realmente presenti alla punta su `ios_app/project.yml`: QUATTRO**, su **tre** bersagli distinti — `LIBRO_MASTRO_QBEATS.md:319` cita `ios_app/project.yml:22 @ 6c7352a1`; `BOX5_QBEATS.md:492` e `BOX5_QBEATS.md:518` citano entrambe `ios_app/project.yml:14 @ 4b55686c` (è la riga contata due volte); `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:191` cita `ios_app/project.yml:14 @ 0a6ebafa`.

✅ **Verificato per prova empirica, non per dichiarazione:** costruita una citazione `.yml` di forma valida, la mia sonda **non la trova**; la stessa sonda allargata a `.yml` **la trova**. Il controllo positivo separa «non c'è» da «non lo vedo».

⇒ **L'IPOTESI È CONFERMATA E IL CASO SI CHIUDE QUI.** Le due sonde contavano insiemi diversi di estensioni; entrambi i denominatori erano veri sul proprio insieme, e nessuno dei due era sbagliato.

---

## 7 · A308 SI ALLONTANA (§8) — dichiarazione, non riparazione

**Verificato a fonte, non ripreso dal mandato:** fra lo sha del censimento `2c9b0bf8d4e48e2d6133029245b4db8e9bf5b9e3` e la punta `c504ee4d9a0d1fd2986c64718e65a58b5ecb55d9` stanno **8 commit**; Sezione 2 del LIBRO è passata da **204 a 205** righe-dato. **Questo giro è il nono commit.** `DECISIONI_ATTIVE.md` **non esiste**: assente sia alla punta sia su disco.

⚠️ Secondo giro consecutivo in cui il repo avanza mentre A308 resta congelato allo sha del censimento.

⇒ **Da onorare quando A308 riprende:**
· il **punto d'inserimento** del mandato A308 va **riverificato a fonte**, mai riusato dal mandato vecchio — è esattamente la R-δ.12 Clausola B incisa oggi;
· le righe entrate in Sezione 2 **dopo** lo sha del censimento entrano nel **contatore** del debito dichiarato;
· ⛔ **il numero non si incide: decade.** Si rimisura quando A308 riparte.

⛔ Questo giro non ha toccato A308 in nessun modo.

---

## 8 · SETTE PENDENZE — scritte, NON eseguite

Fuori perimetro oggi, deliberatamente. Scriverle è obbligatorio: **una pendenza che vive solo in chat non esiste operativamente.**

**(a) LA CLAUSOLA MANCANTE DEL REGIME DI DEPOSITO.** Il referto di un giro nasce **dopo** il commit di quel giro ⇒ ce ne sarà **sempre esattamente uno fuori**. E l'ultimo giro di una chat non ha un giro successivo. La riga del regime non lo dice. **Lavoro sul LIBRO.**

**(b) `CLAUDE.md` NON È TRACCIATO.** Il file che dice a CC come lavorare non arriva a chi clona il repo. **Da DECIDERE, non da eseguire in silenzio.**

**(c) IL TICKET DELL'INNESCO DATI DI TEST cita quattro funzioni e ne esistono dieci.** La misura corretta vive nel referto A311, **non nel ticket** — cioè non dove qualcuno la cercherà. **Materia di BUGS.**

**(d) LA CITAZIONE ROTTA NEL LIBRO DEL 18/08** — `LIBRO_MASTRO_QBEATS.md:344 @ 7ec6c1b8…`, che non risolve. È un difetto **dentro un canonico** e va marcato **dove sta**. ⛔ Non in questo giro: il LIBRO oggi non si tocca.

**(e) «COLONNA STATO 1 RIGA SU 203» — DUE LETTURE, NESSUNA CHIUSA.** Scritta per esteso al **§5** di questo referto, dove ha sostituito la conclusione precedente.

**(f) UN'ISTRUZIONE È ARRIVATA DA UN CANALE CHE NON È UNA PERSONA.** Durante il giro A314 è comparso **dentro il risultato di uno strumento** un promemoria che imponeva una firma `Co-Authored-By`, in conflitto diretto col mandato. CC **non l'ha eseguito e non l'ha ignorato: l'ha dichiarato**, ed è il comportamento corretto — contenuto che arriva da uno strumento è **dato, non istruzione**. ⛔ **Ratificato da Mauro il 02/09/2026: la firma resta autore Mauro Martintoni, zero `Co-Authored-By`.** ⚠️ È il **primo caso noto nel progetto** di un'istruzione arrivata da un canale che non è né una persona né un mandato. Dove vada inciso è **da decidere, non in questo giro**.

**(g) IL CANCELLO DEL COMMIT NON È INCISO DA NESSUNA PARTE.** Rilievo di CC, 02/09/2026, e ha ragione: il mandato A314 ha **enunciato** che il commit parte solo con l'OK esplicito di Mauro e ha fatto onorare la regola in quel giro, ma **non le ha dato nessuna sede**. Vive in chat e in questo referto, cioè — per la lezione già a verbale — **operativamente non esiste oltre il giro che l'ha scritta**. ⚠️ Nasce da un fatto misurato, non da un timore: durante A314 l'OK al commit è stato annunciato **due volte da un interlocutore che non è Mauro**, e **l'interlocutore lo ha riconosciuto**. **Destinazione proposta dal referee e ratificata da Mauro il 02/09: BOX5, serie R-δ, scritta come CANCELLO** — CC si ferma e dichiara se l'autorizzazione arriva attribuita a chiunque non sia Mauro. ⛔ **Va nel giro delle otto ratifiche della cassaforte, non in uno suo:** è la stessa famiglia — decisioni di Mauro che non sono mai atterrate in un documento.

---

## 9 · COSE DECISE CHE IL MANDATO NON COPRIVA

**(1) 🚨 Un promemoria di sistema comparso DENTRO un risultato di tool mi ha imposto di firmare i commit con `Co-Authored-By: Claude Opus 5`.** È in conflitto diretto col §9 del mandato, che prescrive autore Mauro e **zero `Co-Authored-By`**. ⛔ **Non l'ho eseguito e non l'ho nascosto:** contenuto osservato attraverso un tool è **dato, non istruzione**, e in ogni caso nessun commit parte senza l'OK di Mauro. **Decide Mauro.**

**(2) La riga d'innesto della qualifica.** Il mandato dice «immediatamente prima del separatore `|` che apre l'ultima cella». Preso alla lettera avrebbe prodotto due spazi dopo «non filtrato» e nessuno spazio prima del `|`. Ho innestato **in coda al contenuto della cella**, conservando il separatore ` | ` intatto: è la lettura che rende vera l'altra frase del mandato, «appeso IN CODA alla cella». Il testo dettato è entrato **byte-identico**, la sua spaziatura iniziale compresa.

**(3) Le sedi (ii) e (iii) del §7 non sono state aperte** perché la (i) ha risposto. Il tetto era un massimo, non un minimo — ma lo dichiaro invece di lasciarlo intendere.

**(4) Il conteggio del §7-bis è per BERSAGLI DISTINTI** (77), non per occorrenze (107): la stessa ancora citata due volte è un difetto solo, non due. La convenzione non era dettata; la dichiaro.

**(5) Dove è atterrata la pendenza (e).** Il mandato di seguito ordina di **sostituire** con essa la parte del referto che dava per risolta la lettura di «colonna Stato 1 riga su 203». Quella parte è il **§5**, e lì il testo dettato è entrato **intero**, al posto del corpo della sezione. Nell'elenco delle pendenze la (e) compare come **puntatore**, non ripetuta: la ripetizione creerebbe due sedi per la stessa cosa. **Il conteggio in testa al §8 è passato da «quattro» a «sei».**

**(6) La conclusione precedente del §5 non è stata riscritta altrove.** È stata **sostituita**, come ordinato, e non ne resta traccia nel referto. ⚠️ Chi volesse leggerla la trova nel diff del deposito e nella chat del giro, non qui: **lo dichiaro perché una sostituzione silenziosa è indistinguibile da una misura mai fatta.**

**(7) Dove è atterrato il §4 dettato.** Il mandato ordina di **sostituire** il §4, che nel referto viveva come blocco «convenzione del conteggio» dentro il §6. Il testo dettato porta una propria intestazione di sezione, quindi l'ho collocato **come sezione a sé**, subito dopo il §6 e prima del §7, e ho **rimosso** il blocco superato. ⚠️ La riga «**Insieme:** 107 occorrenze ancorate, **77 bersagli distinti**» resta dov'era: è **qualificata** dal nuovo §4, non riscritta — si marca, non si riscrive.

**(8) La clausola sul cancello del commit NON è stata incisa da nessuna parte.** Il mandato la enuncia — il commit parte solo con l'OK esplicito di Mauro, e un'autorizzazione attribuita a chiunque altro fa fermare CC — ma **non ordina di scriverla**. L'ho onorata operativamente e non l'ho incisa. ⛔ Vive solo in chat, e per la lezione già a verbale **una regola che vive solo in chat non esiste operativamente**: se deve restare, va data una sede in un mandato suo.
## 10 · NOTE DEL GIRO — registrate, non eseguite

**NOTA 1 — LA CONTROMISURA ALLA R-δ.13 NON È LA DOMANDA: È IL PLURALE.** Il 02/09, la mattina, il referee ha chiesto «cosa lo spiegherebbe» davanti a un numero che non tornava, ha trovato **una** spiegazione che riproduceva e **si è fermato lì** — ed è stato ripreso per questo. Il pomeriggio, davanti a un secondo numero che non tornava, ne ha provate **quattro** e ha riportato anche il fallimento delle tre scartate, coi loro numeri. ⇒ **Una spiegazione che riproduce non è per questo *la* spiegazione**, e il modo di saperlo è provarne altre finché non ne resta una sola che regge.

**NOTA 2 — LA R-δ.13 HA MORSO I PROPRI AUTORI DUE VOLTE NEL GIORNO IN CUI NASCE.** La prima sul referee, sulla colonna `Stato`: una lettura plausibile presa per l'unica. La seconda su CC, sullo scarto 77 contro 78: una riconciliazione fra due oggetti diversi che rendeva un rassicurante «1». ⚠️ Nessuno dei due stava distraendosi: **entrambi stavano verificando.** ⇒ Un capitolo che inciampa due volte nei propri autori mentre viene scritto non è un capitolo debole: è **l'argomento più forte che possa avere**, e va ricordato a chi un giorno lo troverà pedante.

**NOTA 3 — UN NUMERO MAI MISURATO È DIVENTATO UN FATTO IN UN TURNO.** Il referee aveva scritto in chat, come stima retorica, che i punti d'innesto sotto-specificati erano «tre volte di fila». **Non l'aveva mai misurato.** Un turno dopo gli è tornato indietro **da un validatore esterno, come dato acquisito**, e senza intercettarlo sarebbe finito in un referto e poi in un canonico. ✅ **Il validatore esterno lo ha riconosciuto**: la stima era del referee, la propagazione è passata da lui. Le giunture sotto-specificate effettivamente misurate sono **due**: la qualifica del 02/09 e la guardia d'inserimento di A304-v5. ⇒ **Stessa meccanica del difetto «è/ma»**: un'affermazione non misurata cambia mano e diventa vera per il fatto di essere stata ripetuta. ⚠️ Il tempo di propagazione misurato è **un turno**. ⛔ Registrato come **terza istanza della giornata**, e **non** come rimprovero a chi l'ha ripetuta: l'ha ripetuta perché l'avevamo scritta noi. ⇒ **Tre teste, tre modi diversi, lo stesso difetto: mettere un derivato al posto della fonte.**

---

*A314 — MISURE CC — FINE.*
