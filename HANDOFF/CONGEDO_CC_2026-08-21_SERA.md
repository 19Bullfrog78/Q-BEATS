# CONGEDO CC — sessione 21/08/2026 sera, mandati A139 → A149

Da: CC · A: **la chat CC che apre dopo di me**, + Mauro
Scritto **alla cieca**: non ho letto il congedo del referee e non gli ho chiesto
cosa metterci. È il protocollo, e serve a non farci convergere sulla stessa
versione dei fatti. Dove divergiamo, quella è informazione.

Marcatura: **[M]** misurato da me alla fonte in questa sessione · **[R]**
riportato da altri, non rimisurato · **[A]** giudizio mio.

---

## ⛔ LE TRE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. Il mandato non è una fonte, e oggi te lo dimostro con tre casi, non con un
principio.** Tre volte in undici giri il mandato ha portato qualcosa che non
reggeva, e **ogni volta è stata la misura della premessa a prenderlo**, mai
l'intuizione:

| # | cosa portava il mandato | cosa ho misurato |
|---|---|---|
| A142 | dieci sostituzioni di apostrofi, «attese ZERO, tutte e dieci» | **la lista era incompleta**: mancava `gravita'` minuscolo, che nessuna delle dieci tocca. ⛔ **Il cancello prescritto avrebbe chiuso lo stesso**, lasciando nel canonico l'errore che il mandato esisteva per correggere |
| A143 | §0…§6 | **arrivato troncato** a metà del §2, sulla riga che stava per darmi il criterio. Fermato con zero consegnato |
| A146 | «controllo positivo: **sei** titoli in Sezione 2 con `CHIUSO`» | **cinque**. Riconciliato in A148: era il **perimetro** — il sei è su tutto il file. Entrambi giusti, su domande diverse |

⛔ **[A] Il caso A142 è quello da ricordare, perché è il più insidioso: il
cancello enumerava ciò che il referee intendeva fare, quindi non poteva accorgersi
di ciò che non aveva pensato.** Se avessi eseguito le dieci e verificato le dieci,
avrei consegnato verde un lavoro sbagliato. **Un cancello che elenca le proprie
operazioni non è un cancello sull'obiettivo.**

**2. 🚨 LA SONDA PER CONTENUTO SU `E:` RENDE FALSI POSITIVI, e a smascherarla è il
controllo NEGATIVO — non quello positivo.**
**[M]** Cercando `A139` su tutto l'albero `E:`, la sonda rende **11**. Cercando
`A140`, un ID che **nessuno aveva mai usato**, rende **11 uguali**. Sono match
dentro i blob **base64** dei `*_STANDALONE.html`.
⇒ **Il controllo positivo diceva «la sonda vede» ed era vero, e non serviva a
niente.** Il pavimento di rumore lo trova solo un ID che *non può* rendere nulla.
✅ **Cura, usata in tutti i giri successivi:** perimetro documentale
(`--include='*.md' --include='*.txt'`), binari esclusi (`-I`), pattern con
confine di parola (`\b`), **più un controllo NEGATIVO oltre a quello positivo**.

**3. ⛔ Una stringa che sembra unica può non esserlo, e il secondo bersaglio può
essere quello che non devi toccare.**
**[M]** In A144 dovevo cambiare `HStack(spacing: 10)` dentro `dhead`. Quella
stringa compare **due volte** in `QLiveShowDetailView.swift`: la seconda è dentro
**`startfoot`**, cioè il pulsante **START SHOW**. Una sostituzione testuale
avrebbe cambiato **l'avvio dello show**, in silenzio e fuori perimetro.
✅ **Cura:** ancorare su una **coppia** di righe che sia unica, e mettere nello
script un `assert` che il conteggio passi da 2 a 1. Non «ho controllato»: **lo
script si nega la scrittura**.

---

## PARTE MECCANICA — tutto [M]

### 1 · HEAD

```
HEAD locale = HEAD remoto = c46c0d4b82e1db6eb8f157f4cc9c38da21e21be2
```

Letto con `git rev-parse HEAD` e `git ls-remote origin master`. ⛔ **Mai
`rev-parse origin/master`**: legge una copia locale che può essere vecchia.

### 2 · I quattro commit della sessione

Tutti autore **`Mauro Martintoni <di_tutto@icloud.com>`**, **zero trailer**,
verificati rileggendo il corpo dal repo.

| sha (40) | ora | cosa |
|---|---|---|
| `baaa172895cfafba57b187356ed8ae1036eee17e` | 10:46 | A139 — navbar dettaglio a 54, selettore centrato, ritmo testata |
| `981e109477937523fc8fe00c7e6d62f6c2dd8902` | 13:30 | BUGS v57 — ticket `TD-direttore-parte-da-bar2` |
| `a83353c382877037d27b35912f6d3bdda6ee1988` | 14:19 | deposito freeze rev6 + indice + ancoraggio baseline `.dhrow` |
| `c46c0d4b82e1db6eb8f157f4cc9c38da21e21be2` | 14:54 | BUGS v58 — ticket `TD-qlive-non-scalata-ipad` |

⚠️ **Due commit portano DUE mandati ciascuno**, perché il primo dei due non era
mai stato committato: `981e109` porta A141+A142, `c46c0d4` porta A146+A147.
⇒ **Non esiste in cronologia un commit col ticket A141 dagli apostrofi sbagliati,
né uno col ticket A146 a «severità proposta».** Quelle versioni non sono mai
entrate nel repo. Se le cerchi, non le trovi: non è un buco.

### 3 · CI — per NOME, mai «verde» secco

| workflow | esito su tutti e quattro gli sha |
|---|---|
| `iOS Signed Build` | **success** — run `32464754200` · `32477532415` · `32481404824` · `32484210993` |
| `F1 — Build Check (zero errors, zero warnings)` | **NON PARTITO** |

⛔ **F1 non è «fallito» e non è «verde»: è NON PARTITO.** Interrogato per **ID**
`266323994`: rende **quattro run in tutto**, tutte `workflow_dispatch`, l'ultima
riuscita del **25 aprile 2026**. Nessuna sui quattro sha di oggi.

### 4 · Le versioni dei canonici

| canonico | versione | ultimo commit che l'ha toccato |
|---|---|---|
| `BUGS_QBEATS.md` | **58** | `c46c0d4` — **oggi** |
| `LIBRO_MASTRO_QBEATS.md` | **57** (18/08) | `fe2091a` — **19/08** |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | **11** (18/08) | 19/08 |
| `BOX5_QBEATS.md` | **V28** (28/07) | `0a6ebaf` — 28/07 |
| `BOX3_QBEATS.md` | *(nessuna riga `Versione:` in testa)* | `7c804c1` — **22/07** |

🚨 **[A] IL FATTO PIÙ IMPORTANTE DI QUESTA TABELLA, e non è nei numeri: il LIBRO
MASTRO NON SA NULLA DI OGGI.** È fermo al 19/08. Non registra i quattro commit,
non registra il freeze rev6, e **non registra il collaudo device**. Il registro
cross-team CD↔CC — l'unico posto dove un altro attore va a leggere cosa è
successo — **è indietro di due giorni su una giornata che ha prodotto quattro
commit e un gate device superato.** BOX3 è fermo da **trenta** giorni.

### 5 · Prossimo ID libero

**[M]** Sonda a **due forme** su **due supporti**, più ispezione del contesto.
Perimetro documentale, binari esclusi, confine di parola.

| ID | NOME repo | CONT repo | NOME E: | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| A149 | 0 | 1 | 0 | 1 | questo giro |
| **A150** | **0** | **0** | **0** | **0** | ⇒ **PROSSIMO LIBERO** |
| A146 | 5 | 4 | 5 | 4 | controllo positivo |
| A147 | 3 | 5 | 3 | 4 | controllo positivo |
| A148 | 1 | 2 | 1 | 2 | controllo positivo |

⛔ **Ispezione del contesto:** l'unico hit di `A149` è la riga del referto A148
che lo citava **come controllo negativo**. Menzione, non uso.

⚠️ **AUTORIFERIMENTO dichiarato:** i referti di A149 e questo congedo nascono
adesso. Dopo questo commit, `A149` renderà per nome e per contenuto.

---

## ⛔ I MIEI ERRORI, PER NOME

**[A] Li cerco davvero, perché il congedo che ho ereditato faceva lo stesso e mi
ha risparmiato tempo.** Quattro, e il secondo è quello che mi preoccupa di più.

**[M] 1. A140 — HO TOCCATO `git config` PRIMA DI VERIFICARE CHE SERVISSE.** Per
fissare l'autore ho eseguito `git config user.name` e `user.email` (locali al
repo), poi ho scoperto che **ogni commit precedente portava già quell'identità**:
quasi certamente un no-op. **Non posso provarlo con un'impronta**, perché non
avevo letto `.git/config` prima. Non l'ho revertito — disfare alla cieca sarebbe
stata una seconda azione sulla stessa superficie.
✅ **Cura applicata quattro volte dopo:** `--author="…"` sulla riga di comando,
verificabile da solo e indipendente dalla config. **Mai `git config`.**

**[M] 2. A147 — HO MISURATO CON CONFINI DI SEZIONE SCADUTI, E IL NUMERO È USCITO
GIUSTO PER CASO.** Ho contato i titoli con `CHIUSO` in Sezione 2 usando le righe
`822-997`, che erano quelle di **prima** dell'inserimento fatto in A146: le righe
si erano spostate di **13**. Il conteggio dei `CHIUSO` rendeva **5** in entrambi i
casi — ma il **totale** dei titoli passava da 26 a 28, ed è così che me ne sono
accorto.
⛔ **[A] È il peggiore dei quattro proprio perché il risultato tornava.** Se
avessi guardato solo il numero che mi serviva, avrei consegnato una misura
sbagliata con l'aria di essere giusta. **I confini di sezione vanno ricavati per
contenuto (`grep "^# Sezione"`) a ogni misura, mai riusati da una misura
precedente — nemmeno della stessa sessione, nemmeno di venti minuti prima.**

**[M] 3. A139 — REFUSO UNICODE: `Ὢ8` invece di `\U0001F6A8`.** Volevo 🚨 e
Python ha interpretato l'escape a 4 cifre producendo una **lettera greca** seguita
da un `8`. Trovato e corretto **prima della consegna**, con uno sweep sul blocco
greco. ✅ **Cura:** dopo ogni scrittura con escape unicode, sweep
`re.findall(r"[ἀ-῿]", testo)`; deve rendere zero.

**[M] 4. A139 e A142 — HO USATO `grep -c` PER CONTARE I CR, E RENDEVA ZERO SU FILE
CRLF.** Due volte, in due giri diversi. Vedi trappola ① sotto.

---

## ⛔ COSA NON CREDERE

### Affermazioni ereditate che ho SMENTITO alla fonte

**[M] 1. «In tre giorni non è stata incisa una riga in nessuno dei cinque
canonici» (congedo 21/08 mattina, §4).** **FALSO.** Misurati **quattro** commit
sui canonici dal 18/08: `44fea3e` (18/08), `fe2091a` e `547017f` (19/08),
`ce07fbd` (**20/08**, +33 righe in BUGS, versione 54→56). Il congedo aveva ragione
sulla *propria* sessione — `ce07fbd` la precede — ma la conclusione generalizzata,
che era la riga più marcata di quel paragrafo, non regge.

**[M] 2. «BUGS v56, ultima voce 19/08».** La v56 è stata raggiunta il **20/08**.

**[M] 3. «SSS ha zero occorrenze in `ios_app/`».** Sono **due**, e il vero è
peggio: sono **dichiarazioni di capacità** —
`ABLLinkStartStopSyncSupported: true` in `Info.plist` e `project.yml`. Le chiamate
all'API restano zero mentre l'header le espone. ⇒ **L'app annuncia agli altri peer
Link di supportare Start/Stop Sync e poi non onora mai il contratto.** Non è una
funzione mancante: è una **dichiarazione da onorare o da ritirare**, e la scelta è
di prodotto.

**[M] 4. «`linkPeers`: sette scritture, una vera più sei di ripiego booleano».**
Sono **booleane tutte e sette**. `numPeers_` ha **un solo scrittore** in tutto
`LinkEngine.mm` (`:57`, alimentato da `peers = isConnected ? 1 : 0`), e la
`AudioEngine.swift:458` che sembra numerica passa da lì.
🚨 **Conseguenza su ⟦S-EXIT⟧: l'ambra «band» non ha OGGI nessuna sorgente di
conteggio peer reale**, né via `linkPeers` né via `link_engine_num_peers`.

**[M] 5. La «rettifica A134» in memoria sovradichiarava.** Diceva che
`link_engine_num_peers` «esiste e funziona»: esiste e compila, ma la semantica è
booleana. **Il vincolo originale regge.** Corretto in memoria.

### Le mie ipotesi, e come le ho tenute

**[A] Non ho ipotesi rivelatesi false in questa sessione — e non è merito: è che
ho evitato di formularne.** Dove non avevo la misura mi sono fermato (A143), o ho
dichiarato la divergenza invece di appianarla (il 5 contro 6 di A146).
⚠️ **L'unica cosa che ho affermato senza poterla provare è al punto 1 dei miei
errori** — «quasi certamente un no-op» sul `git config` — ed è marcata come tale
proprio lì.

---

## ⚠️ LE TRAPPOLE — undici, contate da me

**① [M] `grep -c $'\r'` rende 0 su file CRLF.** Il grep di MSYS apre in modo testo
e **scarta i CR prima del match**. Su `LIBRO` e `BUGS`, che su disco sono CRLF,
rende zero e sembra «il file è LF».
✅ **Cura:** `tr -cd '\r' | wc -c`. Controprova: deve coincidere col conteggio
degli LF, e la differenza disco−blob deve pareggiare.

**② [M] `grep -c` che rende 0 esce con codice 1**, e questo **tronca in silenzio
una catena `&&`**. Mi ha tagliato un comando a metà senza errore visibile.
✅ **Cura:** separare con `;` quando un conteggio a zero è un esito legittimo.

**③ [M] La sonda per contenuto rende FALSI POSITIVI** — vedi riga 2 in testa.

**④ [M] La sonda per NOME è strutturalmente cieca** — ereditata e riconfermata:
`A138` e `A143` rendono **0 per nome** su entrambi i supporti pur essendo usati.
⇒ **Nome e contenuto insieme, più ispezione del contesto. Nessuna delle due
basta.**

**⑤ [M] Una stringa apparentemente unica può colpire due punti** — vedi riga 3 in
testa.

**⑥ [M] I confini di sezione scadono dentro la stessa sessione** — vedi errore 2.

**⑦ [M] `\u` a 4 cifre non basta per gli emoji**: serve `\U` a 8. `Ὢ8`
produce silenziosamente una lettera greca.

**⑧ [M] La console Windows è cp1252**: uno script Python che stampa `⛔` muore con
`UnicodeEncodeError`. ✅ `sys.stdout.reconfigure(encoding="utf-8")` in testa a ogni
script.

**⑨ [M] I heredoc Bash si rompono su contenuti complessi.** Un `<<'EOF'` con
tabelle markdown, backtick e apostrofi mi ha reso `unexpected EOF`. ✅ **Cura:**
scrivere lo script Python **come file** e poi eseguirlo. Vale anche per i
messaggi di commit: file, mai heredoc inline.

**⑩ [M] `gh run list --commit <sha corto>` rende `[]` con exit 0** — falso zero.
Serve lo sha a **40**. Riprodotto dal vivo quattro volte oggi per taratura.

**⑪ [M] `gh run list --workflow "F1 — Build Check"` risponde «could not find any
workflows named»** — il nome vero è più lungo:
`F1 — Build Check (zero errors, zero warnings)`. ⇒ **Interrogare per ID
(`266323994`) o col nome intero.**

⚠️ **[A] E una dodicesima che non è una trappola tecnica ma di metodo, ed è la più
sottile — l'ho incontrata in A147.** Il mandato mi chiedeva di eliminare ogni
frase che rimandasse a Mauro una decisione **già presa**. Uno sweep largo su
`decid*|decision*|assegn*|propost*|dipend*` ha trovato tre residui. Due erano la
ragione ratificata; **il terzo era la riconciliazione dei ticket iPad, una
decisione DIVERSA e genuinamente ancora aperta.**
⇒ **Un cancello che avesse cancellato ogni «decisione» avrebbe prodotto una
regressione mentre chiudeva verde.** È il rovescio della trappola ①-A142: non solo
«non vedere ciò che non hai pensato», ma anche **«vedere troppo e distruggere ciò
che era giusto»**. Uno sweep largo **si legge nel contesto, riga per riga**, mai
si applica.

---

## LE PENDENZE CHE LASCIO — con l'anzianità

⚠️ **[A] Le ordino per anzianità e non per gravità, di proposito: quelle vecchie
sono vecchie perché nessuno le guarda, non perché contino meno.**

| # | pendenza | anzianità |
|---|---|---|
| 1 | **🚨 `BOX3_QBEATS.md` fermo dal 22/07** — trenta giorni. Nessuna riga `Versione:` in testa, quindi non dichiara nemmeno la propria staleness | **30 giorni** |
| 2 | **`BOX5_QBEATS.md` fermo dal 28/07** | 24 giorni |
| 3 | **🚨 Il clone vivo su `F:`** — `/f/QBEATS_PREFLIGHT_A61_2026-08-06`, branch `master`, **push configurato verso il GitHub vero**, fermo a `25056b6`: **[M] oggi è 19 commit indietro**. Chi ci lavora dentro legge canonici di due settimane fa e può pushare sul remoto vero | **16 giorni** |
| 4 | **Un file di CD non tracciato** in `DESIGN/QLive_EndShow/…/2026-08-07_QLive-EndShow_Secondo-Pulsante__RISPOSTA-A.html`, **19 476 byte** — e su Drive quel nome esiste in tre versioni (18 463 · 18 799 · 19 398 B), **nessuna con quei byte**. Nome giusto, byte di nessuno | 14 giorni |
| 5 | **`LIBRO-sez6-buco-v25-v26` dichiara `🟢 CHIUSO 01/08` ma sta in §1.3, fra i bug APERTI** — faccia opposta e simmetrica di `TD #23`. **Chi conta i ticket aperti per sezione sbaglia di uno** | 20 giorni |
| 6 | **🚨 Il LIBRO MASTRO è fermo al 19/08** e non registra nessuno dei quattro commit di oggi, né il freeze rev6, né il collaudo device | 2 giorni |
| 7 | **L'esito di ⟦S5b⟧ non è inciso in nessun canonico.** Il documento `HANDOFF/MISURE_CC_2026-08-19_A127-COLLAUDO-S5b.md` esiste dal 19/08; l'esito non è mai atterrato. **[M] Misurato in A146: `S5b` rende zero in BOX3 e BOX5, e in LIBRO le due occorrenze parlano d'altro** | 2 giorni |
| 8 | **🚨 [R] Il 7/7 di A139 su iPhone vive SOLO IN CHAT.** Non è in BUGS, non è in LIBRO. **Segnalato cinque volte oggi, mai atterrato.** ✅ **[M] Ma il posto è misurato**, non più da indovinare: vedi sotto | **oggi** |
| 9 | **Due puntatori `file:riga` scaduti dentro il codice**, già falsi prima che io aprissi: `QLiveShowDetailView` cita `RoomSwitchBar.swift:152-164` (la lezione vera è a **`:197`**) e `:182-204` (la tecnica mask è a **`:228-241`**). **[M] Rimisurati oggi a HEAD** | preesistente |
| 10 | **Il debito dell'ancoraggio, creato oggi da A144/A145**: `readOnlyBadge` era già una seconda copia della specifica, e ora anche `.firstTextBaseline` vive in due punti. **Possono divergere senza che il compilatore dica nulla** | **oggi** |
| 11 | **`.tmp.driveupload/` dentro l'albero di lavoro del repo** — staging di Google Drive, file di giugno-luglio. Non tracciato, quindi non pubblicato | preesistente |
| 12 | **Il §Workflow punto 4 di BUGS** prescrive `BUGS_QBEATS.md: vN — [decisione]` come formato di commit, che **nessun commit recente usa**. O la regola è scaduta o è violata da tempo. **Segnalato cinque volte oggi** | preesistente |
| 13 | **La collocazione della riga rev6 nell'indice** — CD scriveva «in coda», l'ho messa **prima** del catch-all `| gli altri |`. **Già committata**: se va spostata è un giro doc | oggi |
| 14 | **Il collaudo iPad di A144** — su iPhone è 7/7, su iPad il badge scivola, ed è il ticket `TD-qlive-non-scalata-ipad` | oggi |
| 15 | **La riconciliazione dei ticket doppione** — i cinque di `TD-direttore-parte-da-bar2` e i tre iPad. Del referee, **dichiarata rinviata** in entrambi i ticket | oggi |

### ✅ Il posto dove incidere il 7/7 — misurato, non indovinato

**[M] In A146 ho censito dove sono registrati gli esiti dei gate device
precedenti**, perché seguire il precedente vale più che inventarlo. ⟦S5a⟧ è inciso
in **due** posti:

1. **`LIBRO_MASTRO_QBEATS.md:358`** — riga datata nel registro di Sezione 2:
   *«⟦S5a⟧ CHIUSO DEVICE — collaudo Mauro 18/08 … nessun crash … verde»*
2. **`HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:433`** — **marcatura additiva** sulla
   scheda dell'atomo, che supera la precedente **senza riscriverla**

⛔ **BOX3 e BOX5 rendono zero, con sonda tarata** (BOX3 rende 43 su `S4`, BOX5 23
su `Q-Live`): gli esiti dei gate **non si registrano lì**.

⚠️ **Una riserva da non nascondere:** la seconda gamba vale perché ⟦S5a⟧ **è un
atomo con una scheda in SCALETTA**. **A139 è un mandato, non un atomo.** Il
precedente si applica per intero **solo sulla prima gamba**.

---

## LO STATO DEL PRODOTTO

**[R] A139 è collaudato device 7/7 su iPhone il 21/08**, tasto «Shows» compreso.
**Non l'ho misurato io** — è il device di Mauro. ⚠️ Resta l'iPad, dove il difetto
registrato in `TD-qlive-non-scalata-ipad` si vede.

**[M] Quattro commit, tutti `iOS Signed Build` verdi.** ⛔ Ma **la CI verde non è
un collaudo**: prova che compila e firma, non che si veda giusto.

**[R] Ereditate e NON rimisurate da me in questa sessione:**
- **⟦S-EXIT⟧ fermo prima della scheda.** ⚠️ **[M] Ma la sua premessa tecnica è
  caduta oggi**: nessuna sorgente di conteggio peer reale esiste (vedi «cosa non
  credere» 4). La terza decisione da portare a Mauro non è «come mostrarla»: è
  **se sia costruibile senza un bump di LinkKit**.
- **🚨 Dal player in standby non si esce.** **[M] Riverificato riga per riga
  all'apertura** e regge: `LiveView.swift:88` ZStack → `:96` VStack col tasto
  indietro come **primo figlio** → `:129` opacità 0,10 → `:132` overlay sopra con
  `contentShape` a pieno schermo. **Invisibile e irraggiungibile, a ogni START
  SHOW.**
- **Due collaudi device pendenti** dal 19/08, documenti pronti, esito mai
  arrivato.

---

## [A] CIÒ CHE VALE PIÙ DI TUTTO

**Non è una trappola né una pendenza: è una forma di errore che oggi ho visto in
due direzioni opposte, e credo sia la cosa che vale di più portarsi via.**

⛔ **Un controllo che verifica le OPERAZIONI non può sostituire un controllo
sull'OBIETTIVO.**

In A142 il cancello elencava dieci sostituzioni e chiedeva zero residui su quelle
dieci. Ha chiuso — e avrebbe lasciato nel canonico un `gravita'` che nessuna delle
dieci toccava. **Il cancello non poteva vedere ciò che chi l'aveva scritto non
aveva pensato.**

In A147 è successo l'opposto: uno sweep largo, fatto proprio per rimediare a quel
difetto, ha trovato una «decisione» che **andava lasciata dov'era**. Applicarlo
avrebbe distrutto una dichiarazione corretta mentre il cancello segnava verde.

⇒ **Le due facce hanno la stessa radice: un cancello meccanico non sa cosa stai
cercando di ottenere.** L'unico controllo che le prende entrambe è **rileggere
l'oggetto intero e chiedersi se dice il vero**, con la lista in mano ma non al
posto della testa. Nei referti l'ho chiamato «controllo sull'obiettivo», e in
questa sessione è servito **due volte in cinque giri**.

⚠️ **La seconda, che costa poco e vale molto: il controllo NEGATIVO vale quanto
quello positivo, e in un caso oggi valeva di più.** Il falso positivo su `E:` non
l'avrebbe trovato nessun controllo positivo — quello diceva «la sonda vede», ed
era vero. L'ha trovato un ID mai usato che rendeva **undici**.
⇒ **Ogni sonda va tarata da entrambi i lati: qualcosa che DEVE rendere, e
qualcosa che NON PUÒ rendere.**

⛔ **Terza, per chi eredita questo file: NON crederci sulla parola. RIMISURA.**
Il congedo che ho ereditato reggeva quasi tutto, ma aveva **quattro affermazioni
false**, e le ho trovate **solo perché ho rifatto le misure invece di
rileggerle**. Questo congedo non è diverso. Marcalo **[R]** e comincia da lì.

---

*A149-FINE*
