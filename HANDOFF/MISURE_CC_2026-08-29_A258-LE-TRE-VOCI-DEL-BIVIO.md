# MISURE CC — A258 — LE TRE VOCI DEL BIVIO, COME SONO DAVVERO — 29/08/2026

Da: CC · **Parte A: a MAURO** · Parti B/C/D: al referee (+ CD)

**ID ESEGUITO: A258.** **⏱ Orologio:** sab 29/08/2026 **21:25 locale (UTC+2)** · 19:25 UTC. **Aggancio:** risponde ad A257 (chiuso).

**Cancello ID — quattro gambe, tutte a zero.** Positivo dichiarato: **`A253`, che vede su CIASCUNA** — nome (C: 3 · E: 3) · contenuto (C: 10 · E: 5) · `git log --all --grep` **1** (`9c3616e`).

⛔ **Nessuna modifica sotto `ios_app/`.** Nessun commit, push o staging. `HEAD` = `9c3616e`, invariato.

---

# PARTE A — IL FOGLIO PER MAURO

> Questa parte non contiene codice. Le frasi fra virgolette sono di CD, prese dal suo foglio del 27/08.

## 1 · Quale gesto apre il pannello, e quando

**Lo apre la FRECCIA in alto a sinistra — non lo STOP.** E si apre **solo a show fermo**.

CD, verbatim:

> «La freccia è **marcata**: è lei che apre il bivio, **non lo STOP**.»

> «Perché la apre la freccia e non lo STOP. Se il bivio comparisse **su STOP**, l'app metterebbe una domanda davanti al gesto più urgente della serata — quello che premi **perché ti serve silenzio adesso**. **Mai.** STOP ferma, e basta. Il bivio arriva **un gesto dopo**, quando il silenzio c'è già e la fretta è finita.»

**In una riga:** prima fermi con STOP, e non ti chiede nulla. Poi, se vuoi andartene, tocchi la freccia — e *quella* ti chiede dove vuoi andare.

⚠️ **Ti era stato descritto come un pannello che si apre premendo STOP. Il foglio dice il contrario, ed è il contrario di come lo avevi deciso.** Per questo la decisione è stata sospesa.

## 2 · Le tre voci — parole esatte, ordine esatto

CD le elenca così:

> «**X** sul perimetro → si resta nel player fermo · **END SHOW** → card · **SHOW DETAILS** → terza faccia.»

Sullo schermo il pannello mostra **due righe**, e la terza via è la **X** all'angolo, fuori dalle righe:

| | voce (parole di CD) | cosa fa, in una riga |
|---|---|---|
| 1 | **Show details** | Ti porta a vedere la scaletta dello show, **senza chiudere niente**. Lo show resta lì dov'è, fermo. |
| 2 | **End show** — sotto, più piccolo: *«This will stop the other devices too»* | Chiude lo show e ti riporta alla lista degli show. **Non si torna indietro.** |
| 3 | **X** (cerchietto all'angolo in alto a destra) | Annulla. Chiudi il pannello e **resti nel player, fermo, dov'eri**. Non fa nient'altro. |

**Sull'ordine e sulla forma**, CD è preciso: `SHOW DETAILS` è **pieno arancio** («è la strada che non toglie niente»), `END SHOW` è **solo contornato di rosso** perché «distruttivo **non** vuol dire invitante». La **X** sta sul perimetro, staccata, «fuori dal ritmo delle due righe, così il pollice che vuole annullare **non passa mai sopra END SHOW**».

**⚠️ Una cosa che NON c'è, ed è importante che tu lo sappia prima di decidere: in questo pannello non esiste una voce «riparti» o «riprendi».** Le tre vie sono: guarda la scaletta · chiudi lo show · lascia perdere. Per far ripartire il click si esce con la X e si preme Play, come adesso.

## 3 · Cosa cambia per la freccia quando il pannello non si apre

CD lo lega allo stato, non al capriccio:

> «La freccia risponde a: **esci da questa lastra**, e il numero di risposte legittime dipende dallo stato. **In attesa è una** (il dettaglio) ⇒ nessuna domanda, si va. **Dopo STOP sono due** (il dettaglio, oppure fuori) ⇒ il bivio **non è un alert: è una disambiguazione. Non chiede permesso, chiede dove.**»

Quindi:

- **Show fermo (dopo STOP)** → due strade possibili → **si apre il pannello**.
- **In attesa del Direttore** → una strada sola → **niente pannello**, la freccia porta dritta al dettaglio.
- **Show che sta suonando** → ⛔ **il foglio non lo dice.** Vedi la Parte B, punto ⑤: è una domanda aperta, e non l'ho riempita indovinando.

## 4 · Come si esce senza scegliere

Due modi, entrambi previsti da CD:

- **La X** all'angolo in alto a destra.
- **Toccare lo sfondo scuro** attorno al pannello: «tap sullo scrim = come la X».

⚠️ Con una precisazione di CD che vale la pena conoscere, perché è una protezione: quel tocco sullo sfondo **«consuma il tap — non deve arrivare al "tap anywhere" sotto, o il bivio si trasformerebbe in un avvio»**. Cioè: senza quella cautela, chiudere il pannello toccando fuori **farebbe partire il click**.

---

# PARTE B — LE MISURE, PER IL REFEREE

## 🚨 LA DOMANDA DECISIVA — è mal posta, e questa è la risposta

Il mandato chiede: *«la voce di RITORNO del bivio è "rientra dove eri" — cioè ciò che il Play fa già oggi dopo A240 — oppure è `Resume from ⟨sezione⟩`, quello che CD ha VIETATO nel §D?»*

**[M] Né l'una né l'altra: NEL BIVIO NON ESISTE UNA VOCE DI RITORNO.** Misurato a fonte, due volte per due strade indipendenti:

- **il testo normativo** (`bivio.txt` righe 46-58, e la ratifica **R1** righe 668-679): «X sul perimetro → si resta nel player fermo · END SHOW → card · SHOW DETAILS → terza faccia»;
- **il markup del frame ①**: contiene esattamente due `.vrow` — `Show details` e `End show` (+ la sua sottoriga Link). **Nessun `Restart song`, nessun `Return`, nessun `Resume`.**

⇒ **Il bivio PUÒ uscire intero: nessuna delle sue tre vie tocca `Resume`.** La X è un annullamento, non un rientro — non fa ripartire niente, e non ha bisogno di nessun esecutore.

⚠️ **MA — e questo cambia comunque la scelta di Mauro, per un'altra strada: la sua terza via porta in una stanza che è bloccata a metà.** `SHOW DETAILS` → **terza faccia**, e la terza faccia porta `END SHOW` **+ `RESUME from [section]`**. Il §D del rev3 (28/08) dice verbatim: *«La terza faccia **eredita il blocco**»*. ⇒ Il bivio esce intero, ma **consegna l'utente a una schermata che oggi può mostrare solo una delle sue due righe.**

## ⑤ Le tre voci, una per una

### Voce 1 — `SHOW DETAILS` → terza faccia

**[M] Il codice esiste per ~90%, manca il seam.** `navigate(to: .detail)` è la porta unica ed esiste (`QLiveRootView.swift:180`). `selectedSetlist` — il payload che il ramo `.detail` richiede (`:186`) — **è già valorizzato ogni volta che si è nel player**, perché l'unica strada al player è `onStart` dal dettaglio.
**Cosa va scritto:** un seam nuovo dal player alla stanza (come `onEndShow` in A253), più il pannello. **Layer 3, reversibile.**
🚨 **Difetto ereditato, misurato:** `selectedSetlist` è l'**ultimo show APERTO nel dettaglio**, non quello che suona. Dopo A253 è raggiungibile: apri il dettaglio di B mentre A suona → `BACK TO SHOW` → player (suona A) → freccia → `SHOW DETAILS` **ti porta al dettaglio di B**. È la conseguenza **(iii-a)** già dichiarata su `isShowLive` e girata a CD, **che questa voce estende a un secondo percorso.** Non risolta qui.

### Voce 2 — `END SHOW` → card

**[M] Esiste, ed è l'unica delle tre già collaudata su device.** `QLiveRootView.endShowAndLeave()` (`:170-173`) → `QLiveSession.endShow(audioEngine:)` → ferma il motore, svuota lo slot, naviga a `.shows`. **Costruita in A253 (`9c3616e`), collaudata verde da Mauro tre volte su tre.** Riuso diretto: la voce del bivio si aggancia come **terzo** chiamante, senza sapere altro — che è esattamente ciò per cui quel seam è stato separato.
**Costo: una riga.**

### Voce 3 — `X` / tap sullo scrim → si resta nel player fermo

**[M] Non esiste, e non esiste nemmeno la cosa che dovrebbe chiudere.** Sonda a più forme su `UI/Live/` e `UI/QLive/`: `confirmationDialog` · `.alert(` · `.sheet(` · `fullScreenCover` → **zero**. **Il pannello non c'è.** L'unico overlay con velo nel player è `OverlayStopView` (`:14`), che è un'altra cosa (l'overlay dello STOP, §A257).
**Cosa va scritto:** la vista del pannello. **È il vero costo di questo lavoro** — le altre due voci sono cablaggi, questa è una schermata. **Layer 3, nessun tocco a Layer 1/2, reversibile.**
⚠️ **La clausola «consuma il tap» è un requisito, non una rifinitura:** senza, il tocco sullo scrim cade sul «tap anywhere» sottostante e **avvia il click**. Da verificare al collaudo, non per lettura.

### ⑤-bis — La domanda che il foglio non chiude

**[M] Cosa fa la freccia col player che SUONA: non trovato in nessuno dei tre fogli.** Il 27/08 copre «in attesa» e «dopo STOP»; il 29/08 §A dice che «dal player non si arriva mai a END SHOW con uno show che suona» — ma descrive il percorso a END SHOW, **non cosa fa la freccia in play**. Oggi nel codice la freccia fa `onExit` → `leavePlayer()` → torna alla lista **lasciando lo show vivo** (e il click acceso). **Non l'ho dedotto: lo dichiaro aperto.**

---

# PARTE C — CONFLITTI CON CIÒ CHE È STATO RATIFICATO DOPO IL 27/08

**Voce per voce, senza risolvere.**

| voce del bivio | A240 (28/08) | Firma D (29/08) | A253 (29/08) |
|---|---|---|---|
| `SHOW DETAILS` | — | — | 🔶 **sovrapposizione** |
| `END SHOW` | — | ✅ **coerente** | 🔶 **duplicazione** |
| `X` | ✅ nessun conflitto | — | — |

**① `END SHOW` — duplicazione VOLUTA, non conflitto.** La Firma D di Mauro dice «due posti, non uno»: dentro (STOP → bivio → END SHOW) e fuori (dettaglio, un tap). A253 ha costruito **il secondo**. Il bivio porta **il primo**. ⇒ Non si contraddicono: **sono le due metà della stessa firma**, e A253 ha costruito quella che non aveva bisogno del pannello. Il seam è già predisposto per riceverne un terzo.

**② `SHOW DETAILS` — sovrapposizione REALE con A253, e va guardata.** La destinazione di questa voce è **la terza faccia**, cioè il dettaglio a show fermo. **A253 ha già costruito un pezzo di quella faccia** — la voce `END SHOW` nel dettaglio, gattata su `isShowLive`. ⇒ Chi arriva al dettaglio dal bivio **trova già END SHOW lì**, e si ritrova a un tap di distanza dallo stesso comando che aveva appena visto nel pannello da cui è passato. **Non è un difetto, è una ridondanza** — ma è una decisione di CD, non mia, e la lascio aperta.
**[M] Cosa manca ancora della terza faccia, misurato:** `RESUME` (vietato dal §D) · la **spia nel terzo stato** (`Stopped`, anello vuoto) · il marcatore di riga **`▸ STOPPED`**. Nessuno dei tre esiste nel dettaglio oggi.

**③ `X` e A240 — nessun conflitto, e vale dirlo perché il rischio era lì.** A257 aveva segnalato che dare una porta all'*overlay dello STOP* avrebbe riaperto la decisione di A240. **Questo bivio non lo fa**: non tocca STOP, non tocca il Play, non ha una voce che riparte. Il ciclo STOP → Play continua a fare «riparti da dov'eri» esattamente come collaudato il 28/08. ⇒ **Il bivio e A240 vivono su due gesti diversi e non si incontrano.**

---

# PARTE D — L'IPOTESI DEL REFEREE, TRATTATA COME DA SMENTIRE

**Ipotesi:** *«tutte e tre le voci si agganciano a codice che esiste già ed è collaudato: `startCurrentSong` per "da capo", il comportamento del Play post-A240 per il rientro, `endShowAndLeave()` per la chiusura.»*

**[M] FALSIFICATA per due terzi — e il modo in cui è sbagliata dice dov'è l'errore.**

| pezzo dell'ipotesi | esito | perché |
|---|---|---|
| `endShowAndLeave()` per la chiusura | ✅ **REGGE** | `END SHOW` → card è esattamente quella funzione. |
| `startCurrentSong` per «da capo» | ❌ **FALSIFICATA** | **Nel bivio non c'è nessuna voce «da capo».** |
| Play post-A240 per «il rientro» | ❌ **FALSIFICATA** | **Nel bivio non c'è nessuna voce di rientro.** |

**🚨 [A] E la diagnosi dell'errore è precisa, perché le due voci fantasma esistono — in un altro frame.** Il **frame ②** dello stesso foglio (la lamella del dettaglio a show **vivo**) porta **tre righe**: `End show` · `Restart song` · `Return`. Sono esattamente le tre a cui l'ipotesi si aggancia — `Restart song` → «da capo», `Return` → «il rientro», `End show` → la chiusura.

⇒ **Il referee non ha misurato il bivio: ha misurato il frame ②.** Ed è comprensibile, perché anche quello ha **tre** righe — ma «il bivio a tre vie» è il **frame ①**, e le sue tre vie sono altre. ⚠️ **È la stessa famiglia dell'errore che il mandato stesso dichiara** («l'ho descritto come un pannello che si apre premendo STOP»): non un dato sbagliato, **il frame sbagliato letto due volte di fila.**

⚠️ **Nota per non far nascere un terzo errore da questa correzione:** `Return`, nel frame ②, **non è transport**. CD lo scrive esplicitamente respingendo quel nome per l'altro comando: *«Return … significa **navigazione pura**»*. Torna al player, **non fa ripartire il click**.

---

## ⛔ COSA NON HO MISURATO — dichiarato, non riempito per deduzione

- ⛔ **Cosa fa la freccia col player che suona: NON TROVATO nei tre fogli** (§⑤-bis). Non l'ho dedotto dal codice attuale, perché il codice attuale è ciò che il disegno vuole cambiare.
- ⛔ **Non ho misurato il rev2 «Attesa e Dettaglio»** né la «POLITICA DEL RIENTRO rev3.1»: il mandato nomina tre fogli e ho letto quei tre. Il caso «in attesa» è citato da CD **come rimando al rev2**, e quel rimando non l'ho aperto — se la risposta alla domanda di §⑤-bis esiste, il rev2 è il primo posto dove cercarla.
- ⛔ **Zero device, zero build.** Tutto è lettura, a `9c3616e`.
- ⛔ **Non ho stimato in ore/giorni.** Il mandato chiede «esiste o va scritto», e ho risposto a quello; convertirlo in tempo sarebbe un numero inventato.
- ⛔ **La clausola «consuma il tap» non è verificabile per lettura**: dipende dalla gestione dei gesti a run-time. La riporto come requisito di CD, **non come misura mia**.
- ⛔ **Non ho verificato se il pannello del bivio abbia un ticket in BUGS.**

---

## I DUE PERCORSI E LE IMPRONTE

```
REFERTO repo: HANDOFF\MISURE_CC_2026-08-29_A258-LE-TRE-VOCI-DEL-BIVIO.md
        E:  : FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-29_A258-LE-TRE-VOCI-DEL-BIVIO.md
        (impronta nel messaggio di consegna: il file non può contenere il proprio hash)
```

*A258-LE-TRE-VOCI-DEL-BIVIO-FINE*
