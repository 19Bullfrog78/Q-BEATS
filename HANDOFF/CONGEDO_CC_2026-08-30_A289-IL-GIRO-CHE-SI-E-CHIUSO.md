# CONGEDO CC — A289 — 30/08/2026 notte

Da: CC · A: il CC che apre dopo di me.

**Orologio**: 30/08/2026, **23:15 locale (UTC+2)** — da `date` di sistema di questa macchina.

Marcatura: **[M]** misurato da me ORA, alla fonte · **[R]** riportato da altri · **[A]** giudizio mio.

---

## 🚨 DICHIARAZIONE DI CONTAMINAZIONE — leggila prima di pesare questo congedo

⛔ **Ho letto un congedo del referee oggi**, e il mandato mi obbliga a dirlo.

**[M]** È `CONGEDO_REFEREE_2026-08-30_sera_8a9faad.md` (20 286 byte, 17:29, **solo su `E:`**). L'ho letto **integralmente** in apertura di questa sessione, prima di qualunque lavoro.

⚠️ **Ma la contaminazione è PARZIALE, e la misura dice dove finisce:** quel congedo chiude a `8a9faad`, cioè **prima** che questa sessione cominciasse. Non contiene una riga su A270→A288 — il lavoro di stasera. ⇒ **Le zone A, B, C, D di questo congedo non possono esserne influenzate: descrivono fatti che quel documento non poteva conoscere.** Ciò che può esserne influenzato è il mio **modo di guardare**, non i fatti.

⛔ **Se il referee ha depositato un congedo NUOVO stasera, quello NON l'ho letto e non l'ho cercato.** All'ultima misura (23:15) il più recente su entrambe le gambe restava quello delle 17:29.

---

## (a) ID — `A289`

Cancello R-δ.8 / R-δ.9 / R-δ.10, misurato ORA:

| gamba | esito |
|---|---|
| nome, repo `C:` | 0 |
| nome, `E:` | 0 |
| contenuto, repo `C:` tracciato (`git grep`, `:!DESIGN` per R-δ.10) | 0 |
| contenuto, repo `C:` su disco (untracked compresi) | 0 |
| contenuto, `E:` | **8 file**, tutti `LOG/RUN/TEST LUNGA DISTANZA/*.log` |
| `git log --all --grep` | 0 |

⛔ **Gli 8 match sono stati APERTI, come obbliga R-δ.8** — un `1` non chiude il cancello. **[M]** Tutte e **79** le occorrenze sono frammenti dentro UUID di `corewifi`: `uuid=5A289`, `uuid=A2896`, `566A2893-A6C2-4739-`, `FFCB9D53-9E71-49ED-A289-594019468B7`. **Nessuna è un'assegnazione di mandato** ⇒ non occupano.

✅ **Controlli positivi su ID già bruciati** (nominarli non costa nulla): `A287` → 1 commit, 1 file per nome, 3 file per contenuto · `A285` → 3 commit. **Le sonde vedono.**

⚠️ **R-δ.9 rispettata:** i candidati scartati non sono nominati per cifra. Conteggi dei non tracciati dichiarati come scattati **prima** del deposito di questo file.

---

## (b) LA COSA PIÙ URGENTE — il sync Drive non è dove tutti crediamo

🚨 **[M] Il sync verso Drive è agganciato a `E:\...\Q-BEATS\FILE X CLAUDE.MD\`, NON al repo `C:`.**

La cartella Drive `HANDOFF` (id `1lVJaqtTT4bGfCpuS884qnhgY12-mC5Y8`) ha come genitore la cartella Drive **`FILE X CLAUDE.MD`** (id `1BSsFiju0nt1xbXZZYvg5OPex0B-RzoZn`).

**Prova a due gambe, discriminante:**

| file | dove sta in locale | su Drive? |
|---|---|---|
| `CONGEDO_REFEREE_2026-08-30_sera_8a9faad.md` | **solo `E:`** | ✅ SÌ, 20 286 byte |
| `CONGEDO_CC_2026-08-29_A249.md` | **solo repo `C:`** | ⛔ **NO** |

⇒ **Un file scritto solo in `HANDOFF/` del repo non arriva su Drive. Mai.** Non è una dimenticanza di chi l'ha depositato: è la topologia.

**[M] Conseguenza già in essere, non teorica:** i **3 file che stanno solo sul repo** — `CONGEDO_CC_2026-08-29_A249.md`, `CONGEDO_REFEREE_2026-08-29_A251.md`, `_SUPERATO__ROADMAP_2026-07-24.txt` — **non sono su Drive**. Se contano, vanno copiati su `E:`. ⛔ Non l'ho fatto: fuori mandato.

**[M] Il sync è automatico e quasi istantaneo**: i tre snapshot canonici depositati in A288 su `E:` erano su Drive **entro un secondo**, ciascuno nella propria cartella. Non si scrive su Drive a mano.

⚠️ **[M] Ma copre SOLO l'albero sotto `FILE X CLAUDE.MD`.** La cartella `E:\...\Q-BEATS\_TRANSITO_DA_VERIFICARE\` che ho creato in A277 è **fuori**, e **non è sincronizzata**. Dentro c'è l'unica copia di servizio del foglio CD del 30/08 (59 659 byte) più il suo `PROVENIENZA.txt`. **[A] Se quella cartella si perde, il foglio resta in una copia sola al mondo, quella su Drive.**

---

## (c) ZONA A — ciò che vive fuori da git, e che il referee non può vedere

**[M] Stato della macchina, 23:15**
- branch `master`, HEAD **`da7deb03c491f71a684207aad10f842837c3738a`** = `origin/master`. **Allineati: il push è passato.**
- **Working tree tracciato PULITO.** Nessun lavoro a metà.
- **337 file non tracciati** (misurati prima del deposito di questo congedo).
- **CI verde**: run `33335055984` su `da7deb0`, `success`, 3m07s.

**[M] I tre commit di questa sessione**
```
da7deb0  docs: le sette decisioni del 30/08, i limiti di Link, il timbro SOL-C e la regola del cancello (A287)
a2a6503  BUGS v74 (A282+A285)
b962c48  chore(git): BUGS, LIBRO e .gitattributes protetti con -text (A285)
```

**[M] I cinque canonici sono ora coerenti su entrambe le facce** — è la riparazione strutturale di stasera:
```
i/lf  w/lf  attr/-text   .gitattributes
i/lf  w/lf  attr/-text   BOX3_QBEATS.md
i/lf  w/lf  attr/-text   BOX5_QBEATS.md
i/lf  w/lf  attr/-text   BUGS_QBEATS.md
i/lf  w/lf  attr/-text   LIBRO_MASTRO_QBEATS.md
```
Disco e blob coincidono su tutti e tre i canonici toccati (`03ee6c07…` / `4a5343e5…` / `9db8e039…`).

### 🚨 UNA PROVA DEL CONGEDO A270 È SCADUTA — e chi la rifà male conclude il contrario

**[R]** Il congedo `A270` dichiarava, sul ramo `fix/a267-rientro-dalla-sua-sezione`: *«`git diff master fix/a267-…` → **VUOTO** — contenuto identico a master»*, e ne concludeva che il ramo si può rimuovere senza perdita.

**[M] Oggi quel comando NON rende più vuoto:**
```
 .gitattributes         |  3 ---
 BOX5_QBEATS.md         | 49 +-----------------
 BUGS_QBEATS.md         | 48 +------------------
 LIBRO_MASTRO_QBEATS.md | 16 +-----
 4 files changed, 11 insertions(+), 105 deletions(-)
```
⚠️ **Non perché il ramo abbia acquistato qualcosa: perché MASTER è andato avanti di tre commit stasera.** Quelle «105 deletions» sono il lavoro di stasera che il ramo non ha.

✅ **La conclusione di A270 REGGE, ma la prova che la sosteneva no. La prova valida oggi è un'altra, e va usata questa:**
```
git diff master fix/a267-rientro-dalla-sua-sezione -- 'ios_app/'   →   VUOTO
```
⇒ **Il CODICE è identico.** Il commit `98c3aa2` esiste ancora ed è raggiungibile. **[A] Il ramo resta rimovibile senza perdita, ma chi rifà la misura vecchia vedrà 4 file e 105 righe e concluderà che c'è lavoro non integrato.** ⛔ **Non l'ho rimosso: la decisione è di Mauro.**

**[M] Rami locali non-merged: 13**, invariato.

### Tre cose fuori da git che segnalo senza proporre azione
- **`.tmp.driveupload/` nella radice del repo: 790 file.** [R] Il congedo A270 lo dava per residuo fermo al 26 giugno. **[A] Non ho rimisurato le date interne: 790 file è tutto ciò che dichiaro.**
- **`CLAUDE.md` in radice, 8 888 byte: non tracciato E non ignorato** (`git ls-files` rende «did not match»; `git check-ignore` rende vuoto). Nessun commit lo protegge. Se il disco si perde, si perde.
- **La cartella di lavoro di sessione (`scratchpad`) muore con la sessione.** Tutti gli script di misura di oggi — il censimento a tre clausole, il laboratorio git dei fine-riga — vivono lì e **spariranno**. ⚠️ **[A] Il censimento in particolare è riscrivibile in dieci minuti, ma nessuno saprà che esisteva.**

### Artefatti depositati oggi, verificati su due gambe
**[M]** Tutti e tre presenti sia in `HANDOFF/` del repo sia su `E:`, e quindi su Drive:
`DIFF_DUE-RATIFICHE-E-IL-TICKET-NATO-CHIUSO_A282_…` · `DIFF_PROTEZIONE-TEXT-E-BUGS-v74_A285_…` · `DIFF_GIRO-DOCUMENTI-30-08_A287_…`
Più i tre snapshot canonici di A288 (`v75` / `V39` / `v67`, sha `da7deb0`), nelle rispettive cartelle di `E:`.

---

## (d) ZONA B — dove mi sono fermato, e cosa sarebbe successo se non l'avessi fatto

**① A274 — mandato intestato a CD, arrivato a me.** Chiedeva l'impronta del file «sul TUO disco locale», presa **prima** del trasporto, per avere un riferimento indipendente da Drive.
**Avevo ragione.** ⛔ **Se non mi fossi fermato:** avrei dato i numeri che avevo — quelli dei metadati Drive — spacciandoli per un riferimento indipendente. **Avrebbero distrutto in silenzio esattamente l'indipendenza che il mandato serviva a costruire**, e nessuno se ne sarebbe accorto finché quel riferimento non fosse stato usato per validare uno scarico già compromesso. Il referee lo ha registrato come il pezzo più utile del giro.

**② A281 — mandato troncato a metà frase**, più due collisioni con precedenti ratificati che non erano state viste: lo spostamento di `TD-mixer` avrebbe reso **falsa la voce di registro 51**, e la collocazione del ticket nato chiuso contraddiceva il precedente `TD-qstage-tab-reset`.
**Avevo ragione su tutte e tre.** ⛔ **Se non mi fossi fermato:** avrei spostato un ticket rompendo una voce di registro storica — che non si riscrive — e avrei collocato il ticket nuovo in una sezione che il suo stesso precedente smentisce.

**③ A285 — «fai i passi 1-3 e FERMATI prima di committare»**, dove il passo 3 *era* il primo commit. Contraddizione interna. Mi sono fermato prima di qualunque commit, e ho chiesto.
**Avevo ragione:** l'OK di Mauro è arrivato subito dopo, esplicito. ⛔ **Se avessi «interpretato»:** avrei committato su un OK che in quel momento non esisteva, violando il secondo cancello — quello che il progetto tiene separato dal primo apposta.

**④ A286 — collisione di stato.** Il mandato diceva «BUGS, prima di committarlo», ma BUGS era già committato (`a2a6503`) su ordine di A285 più l'OK di Mauro. Chiedeva inoltre tre commit senza l'«OK AI COMMIT» che esso stesso richiedeva.
**Avevo ragione:** il referee ha annullato A286 e lo ha riscritto come A287, riconoscendo di averlo spedito mentre A285 era in esecuzione. ⛔ **Se non mi fossi fermato:** avrei rifatto lavoro già in `master` e committato tre volte senza autorizzazione.

**⑤ A271 / A272 — il foglio CD non trovato.** Mi sono fermato invece di «trovare qualcosa di plausibile». **Avevo ragione:** il file non era su nessuna delle due gambe disco, stava solo su Drive. ⛔ **Se avessi indicato un file simile:** avremmo lavorato per ore sul disegno sbagliato.

**[A] Il filo comune delle cinque: in nessuna mi sono fermato per chiedere COME fare una cosa. Sempre per una misura che non tornava o una collisione con un precedente.** È la forma che stasera è diventata regola in `LIBRO` v67.

---

## (e) ZONA C — dove il referee ha sbagliato

⛔ Ho cercato. **Non è «nulla trovato»: sono nove, e cinque sono errori di misura.**

**① [M] «Il default Link è dichiarato in DUE punti» — sono TRE.** Il mandato A286/A287 dava `AppSettings.swift:22` e `AudioEngine.swift:283`. Lo sweep per effetto su chi *scrive* il campo rende anche **`AudioEngine.swift:55`** (`@Published var currentLinkMode: LinkMode = .standalone`), la copia pubblicata alla UI. **Inciso il numero giusto in BOX5 V39.**

**② [M] `LinkEngine.mm:57` — la riga è giusta per la scrittura, sbagliata per il calcolo.** Il mandato dava *«scrittore unico `:57` (`isConnected ? 1 : 0`)»* come una riga sola. Sono **due**: `:56` calcola `uint32_t peers = isConnected ? 1 : 0;`, `:57` esegue `le->numPeers_.store(peers)`. La sostanza regge (scrittore unico, booleano), l'indirizzo no.

**③ [M] `ABLLinkStartStopSyncEnabled` — la sonda del mandato avrebbe reso due falsi positivi.** In `ios_app/` esistono due occorrenze di `StartStopSync`: `Info.plist:45` e `project.yml:24`. **Sono un'altra chiave** (`ABLLinkStartStopSyncSupported`), che dichiara il *supporto*, non la leggibilità. Il fatto regge; senza questa distinzione il primo che rifà la sonda lo crede smentito.

**④ [M] `BOX5:253` per `StandbyOverlayView` — l'indirizzo è falso.** Il congedo referee del 30/08 sera cita quel fatto come «`BOX5:253`». A `8a9faad`, r.253 apre un blocco di percentuali di layout; il testo vero è a **r.366**, 113 righe più sotto. ⛔ **Chi correggesse BOX5 usando «253» come ancora scriverebbe nel posto sbagliato.**

**⑤ [M] Il verbatim di A240 era troncato nel mandato.** A282 lo dava come *«NON toccati: tap sul velo standby e segnale Link in standby»*. Il verbatim reale, nel messaggio di commit di `d0225ef`, prosegue: **«…, che restano su `startCurrentSong`.»** Un verbatim si cita intero o si dichiara il taglio.

**⑥ Ordine impossibile come scritto, due volte.** A283 punto 8 e A285 punto 8 chiedevano di *«confermare che `master` = `origin/master`»* **dopo due commit**, senza autorizzare il push — e tutti i mandati precedenti dicevano «⛔ NESSUN PUSH». Come scritto era ineseguibile. L'ho dichiarato invece di risolverlo da solo; l'autorizzazione è arrivata in A287.

**⑦ A281 troncato a metà frase** («riportalo verbatim dal») e privo dei punti successivi — header bump e voce di registro, che il referee ha poi riconosciuto di aver dimenticato.

**⑧ A286 scritto su uno stato già superato**, spedito mentre A285 era in esecuzione. Riconosciuto e annullato dal referee stesso.

**⑨ [A] Il difetto di forma che li contiene quasi tutti, e che il referee ha autodichiarato:** un giro documenti che era **uno** è stato spezzato in **sedici mandati**, applicando a due righe di configurazione la stessa cautela dovuta al codice audio. Tre dei nove errori sopra (⑤, ⑦, ⑧) **esistono solo perché il lavoro è stato frammentato**: un mandato unico non si tronca a metà e non si scrive su uno stato vecchio. È diventata ratifica in `LIBRO` v67 — *«il cancello deve essere proporzionato al rischio»*.

✅ **Va detto anche l'altro lato, perché è la parte che ha funzionato:** il referee ha **verificato alla fonte** prima di ratificare il diff A282 (run CI, collaudo verbatim, `LIBRO:212`), ha **ritirato di sua iniziativa** un argomento sbagliato in A280 riconoscendo di aver attaccato una posizione che non era la mia, e ha **accolto tutte e quattro** le obiezioni di A281. ⛔ **Quando ha sbagliato è stato sui NUMERI e sulla FORMA dei mandati, mai sul metodo.**

---

## (f) ZONA D — i miei errori, e ciò che non ho misurato

**① 🚨 Ho introdotto 16 apostrofi curvi in `BUGS`, in un file che ne aveva zero.** Scrivendo il testo di A282. Non è cosmetica: con l'apostrofo curvo, chi cerca `dall'inizio` o `l'altro` **non trova quelle righe** — cioè il difetto contro cui avevo appena vinto l'argomento in A280. Corretti (975→991 dritti, quadratura esatta).

**② 🚨 La sonda con cui li ho cercati era rotta, e non me ne sono accorto dal risultato.** `grep -o $'\u2019'` ha reso **0 prima e 0 dopo** — sembrava pulito. L'ho scoperto **solo** perché il controllo positivo (apostrofi dritti) cresceva di `+6` invece che di decine. ⛔ **Se non avessi guardato il controllo positivo, avrei dichiarato pulito un file con 16 apostrofi sbagliati.**

**③ [M] Una terza sonda rotta, stasera, mentre scrivevo questo congedo.** Per verificare l'esistenza dei congedi referee ho usato `ls | grep REFEREE | tail -5`: `tail` su un elenco **alfabetico** taglia proprio i `CONGEDO_*`, e mi ha reso «nessun congedo del 30/08» — **falso**. Rifatta con `ls -lat`. ⚠️ **Quarto episodio in un giorno.**

**④ 🚨 Non ho depositato gli snapshot canonici su `E:` dopo il push, e non me l'ha ricordato nessuno.** Li ha chiesti Mauro in A288. **Il difetto è mio, non del mandato:** la prescrizione è canonica e standing — `BOX5`, capitolo `R-δ`: *«Ogni artefatto destinato a Mauro o al referee — referto, diff, stampa, congedo, contratto — si deposita sulle DUE gambe NELL'ISTANTE IN CUI ESISTE»*. **[A] E aggrava, non attenua, che nello stesso giro io abbia depositato diligentemente i DIFF: ho applicato la regola a ciò che il mandato nominava e non a ciò che nomina solo il canonico.** È la forma esatta contro cui esiste `feedback_qbeats_mandato_non_e_fonte`.
⚠️ **Conseguenza misurata:** per circa venti minuti `master` è stato a `v75/V39/v67` mentre `E:` mostrava `v73/V38/v66`. Chi avesse aperto `E:` in quella finestra avrebbe letto versioni vecchie credendole correnti — **lo stesso danno che il ticket `TD-mirror-e-copie-nude-stantie` descrive, ma prodotto da noi oggi.**

**⑤ In A279 ho dato la diagnosi sbagliata, e ci è voluto A280 per ribaltarla.** Avevo concluso «stesso difetto, marcatura additiva». **[A] L'errore non era nelle misure — quelle reggono — ma nell'aver ragionato sulla struttura del CODICE e concluso sulla struttura dell'ARCHIVIO**, che è governata da regole diverse. Ho ceduto sulle misure, ed è stato giusto.

**⑥ Una mia previsione operativa era sbagliata.** Nel piano di A283 avevo scritto che dopo la conversione del disco di LIBRO «`git status` non lo mostrerà più». Lo mostrava. La sostanza era salva (hash disco = index = HEAD, `git diff` a zero righe), ma **la verifica che avevo definito io non è passata come scritta**, e l'ho dichiarato invece di riscriverla a posteriori.

**⑦ Non ho verificato se `LIBRO` avesse già apostrofi curvi PRIMA di scriverci.** L'ho fatto solo dopo, allarmato dal conteggio. Ne aveva 7, preesistenti, in righe storiche — ma **l'ho scoperto per fortuna, non per metodo**.

### Lacune dichiarate — cose che non ho misurato
- ⛔ **Non ho letto il congedo referee di stasera**, se esiste (vedi la dichiarazione in testa).
- ⛔ **Non ho verificato l'IPA** prodotta dalla CI: so che il job è verde, non ho aperto il binario.
- ⛔ **`*.md -text` resta NON MISURATA.** È mia proposta, respinta in A285 proprio perché non misurata: non so quanti `.md` tracciati risulterebbero modificati. Registrata come opzione aperta nel ticket nuovo.
- ⛔ **I 30 sorgenti divergenti non sono riparati** — ticket aperto, gravità proposta e non assegnata.
- ⛔ **Le copie «nude» su `E:`** (`BUGS_QBEATS.md`, `LIBRO_MASTRO_QBEATS.md`, senza versione nel nome) **non le ho aggiornate**: sono materia di `TD-mirror-e-copie-nude-stantie`, decisione di Mauro.
- ⛔ **Non ho rimisurato le date interne di `.tmp.driveupload/`**: dichiaro 790 file, non la loro età.
- ⛔ **Non ho toccato i 12 rami del debito storico** né i cloni di servizio.

---

## (g) SE APRI DOMANI, IN CINQUE RIGHE

1. **`master` = `origin/master` = `da7deb0`, tree pulito, CI verde.** Non c'è lavoro a metà. BUGS **v75**, BOX5 **V39**, LIBRO **v67**, tutti pushati e con gli snapshot su `E:`.
2. **Il giro documenti è CHIUSO.** Le sette decisioni del 30/08, i limiti di Link, il timbro `⟦SOL-C⟧` e la regola Drive in forma stretta sono nei canonici, non più solo in chat.
3. 🚨 **Se depositi qualcosa e vuoi che arrivi su Drive, scrivilo su `E:\...\FILE X CLAUDE.MD\`.** Il repo `C:` non è sincronizzato (§b). È la cosa che più facilmente ti farà perdere un file senza accorgertene.
4. **Prima di misurare qualunque cosa:** due gambe mai una · impronte dal **blob** per tutto ciò che non è protetto da `-text` · **apri sempre i match** del cancello ID · e **fai vedere alla sonda qualcosa di noto prima di fidarti del suo zero** (§f, quattro episodi in un giorno).
5. **Il prossimo lavoro non è documentale.** I bloccanti palco sono **sei**, contati per contenuto sul file committato, quadratura 6+2+1=9. Il primo che tocca `startCurrentSection` deve sapere che regge **due** ticket insieme: sta scritto in entrambi.

---

*A289-IL-GIRO-CHE-SI-E-CHIUSO — FINE*
