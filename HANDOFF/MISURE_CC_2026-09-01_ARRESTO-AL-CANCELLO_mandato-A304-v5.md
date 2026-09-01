# MISURE CC — ARRESTO AL CANCELLO — MANDATO «A304 v5 — DECISIONI-ATTIVE-NASCITA» — 2026-09-01

Da: CC · A: referee.

**Orologio**: 2026-09-01, **15:11:20 locale (UTC+2)**.

⛔ **MANDATO NON ESEGUITO. ARRESTO AI CANCELLI D'INGRESSO, PRIMA DI QUALUNQUE LAVORO.**
⛔ **Zero scritture: nessun canonico toccato, nessun file creato oltre questo referto, zero commit, zero staging.** Il working tree è come il mandato l'ha trovato.

⚠️ **Non dichiaro un ID in testa**: l'ID che il mandato assegna è occupato (§1). Assegnarmene uno nuovo di mia iniziativa per un mandato che non eseguo creerebbe un secondo ID bruciato senza lavoro dietro. Questo referto è **anonimo per scelta** e prende il nome dall'evento, non da un mandato.

Marcatura: **[M]** misurato ora da me, alla fonte · **[R]** riportato, non verificato da me · **[A]** giudizio mio.

---

## Sintesi in tre righe

1. **L'ID `A304` è occupato** — da un mio referto di stamattina, oggi **committato e tracciato**.
2. **L'ancoraggio è scaduto** — `LIBRO_MASTRO_QBEATS.md` ha ricevuto un commit dopo `976d986`. Il mandato prescrive l'arresto in questo caso, testualmente.
3. 🚨 **E c'è un terzo problema, che il mandato NON prevedeva e che è il più pericoloso dei tre**: la clausola di ABORT sull'ancora testuale della riga 399 **NON sarebbe scattata** — quel testo combacia ancora carattere per carattere — ma inserire lì oggi metterebbe la riga **nel posto sbagliato**. Dettaglio al §3.

---

## 1 · L'ID `A304` è occupato

**[M]** Riverificato sul disco, come il mandato stesso prescrive di fare per coprire ciò che il referee non vede:

| gamba | esito |
|---|---|
| nome-file su C: | **1** — `HANDOFF/MISURE_CC_2026-09-01_A304-CENSIMENTO-PUNTATORI-CONTRATTO-18-07.md` |
| nome-file su E: | **1** — stesso file, gamba mirror |
| `git grep` tracciato | **3 file** — il referto stesso, il referto A306 che lo cita, e `LIBRO_MASTRO_QBEATS.md` |
| `git log --all --grep` | 0 |

⚠️ **Perché il referee ha misurato ZERO in buona fede, e non è un suo errore di metodo:** ha misurato **al commit `976d986`**, e a quel commit il referto A304 era **untracked** — invisibile a `git`. È stato committato **dopo**, nel giro A307 (commit `2c9b0bf`, insieme ad A303 e A306). La misura era corretta quando è stata presa; è l'oggetto misurato che si è mosso sotto.

🚨 **[A] Vale la pena dirlo perché è la stessa lezione dell'arco A301→A307, in una forma nuova.** Quel giro ha chiuso il buco «il referee non vede gli untracked» facendoli entrare nel deposito. Qui il buco riappare ruotato di novanta gradi: non più «il file non è in git», ma **«la misura è di un commit che nel frattempo è avanzato»**. Il rimedio del regime nuovo non copre questo caso — e questa è, a mio giudizio, la cosa più utile che esce da questo arresto.

**A304 non si riusa.** Il mandato lo dice da sé («Se collide: ID nuovo, mai riuso») e sono d'accordo: il referto A304 esistente è committato, pubblico e citato da altri due documenti.

---

## 2 · L'ancoraggio è scaduto — arresto prescritto dal mandato stesso

Il mandato: *«⛔ Se `LIBRO_MASTRO_QBEATS.md` ha ricevuto commit DOPO `976d986`, FERMATI: impronte, numeri e ancora della riga 399 vanno rifatti dal referee.»*

**[M]** Comando prescritto dal mandato, eseguito verbatim:

```
git log --oneline 976d986..HEAD -- LIBRO_MASTRO_QBEATS.md
1c05e30 docs: chi comanda su cosa — marcature 18/07 vs 30/08 (A307)
```

**Un commit. La condizione d'arresto è soddisfatta.** Controllo positivo sulla stessa sonda: `BUGS_QBEATS.md` rende **1** commit nello stesso intervallo (anch'esso toccato da A307) ⇒ la sonda vede, lo zero non sarebbe stato cecità.

### Le impronte, tutte scadute

| oggetto | atteso dal mandato (blob `976d986`) | reale oggi (blob `HEAD` = `2c9b0bf`) |
|---|---|---|
| LIBRO intero, sha256 | `b1c50f98…2526bcd9` | **`4472e96c1db6d920e900f638209e2ae7a7d1915001f042c05cfb73a2b7d57042`** |
| LIBRO intero, byte | 350.791 | **353.989** (+3.198) |
| LIBRO intero, righe | 575 | **577** (+2) |

**[M] Verificato che l'impronta del mandato è corretta ALLA SUA BASELINE**: `git show 976d986:LIBRO_MASTRO_QBEATS.md | sha256sum` rende esattamente `b1c50f98…2526bcd9`, 350.791 byte, 575 righe. ⇒ **Il referee non ha sbagliato una misura: ha misurato un'istantanea che è stata superata.** Le impronte di prefisso (righe 1-399) e suffisso (righe 400-fine) sono per costruzione scadute anch'esse, e non le riporto per non moltiplicare numeri morti.

### Anche i conteggi sono scaduti

**[M]** Righe-tabella della Sezione 2, con la mia sonda applicata al perimetro definito dal mandato (righe che iniziano con `|` fra l'intestazione di Sezione 2 e quella di Sezione 3, escluso il separatore):

| | righe-tabella Sezione 2 |
|---|---|
| blob `976d986` (baseline del referee) | **203** |
| **atteso dal mandato** | **203** ✅ |
| blob `HEAD` oggi | **205** (+2) |

✅ **La mia sonda riproduce esattamente il numero del referee alla sua baseline.** Questo è il controllo che conta: **il perimetro che ho usato coincide col suo**, quindi la divergenza a HEAD è vera crescita del documento, non una discordanza di definizione. Le due righe nuove sono quelle incise da A307 (`CHI COMANDA SU COSA` e la regola di processo nella formulazione di Mauro).

⇒ Anche `137 / 62 / 141` vanno rifatti: sono derivati da una popolazione che è cambiata.

⛔ **Non li ho ricalcolati io**, e la scelta è deliberata: ricalcolarli sarebbe eseguire la metà misurativa della Tappa 1 su un ancoraggio che il mandato dichiara non valido. Il conteggio delle righe qui sopra è **diagnostica dell'arresto** (quanto si è mosso il terreno), non esecuzione del censimento.

---

## 3 · 🚨 Il terzo problema — la clausola di ABORT sull'ancora NON avrebbe protetto

Questo è il punto per cui vale la pena leggere il referto, e non lo trovo scritto in nessuna clausola del mandato.

Il mandato identifica il punto d'inserimento **per testo**, non per numero di riga — scelta giusta, ed è la regola di questo progetto. Prescrive:

> riga 399 → `| 2026-09-01 | **I DOCUMENTI DI LAVORO ENTRANO NEL DEPOSITO `
> riga 400 → (VUOTA)
> *«La riga nuova va fra la 399 e la riga vuota.»*
> *«⛔ Se il testo alla riga 399 NON corrisponde carattere per carattere: ABORT.»*

**[M] Il testo alla riga 399 corrisponde ancora, oggi, carattere per carattere.** Misurato al blob HEAD:

```
riga 398 → | 2026-08-31 | **③ CC MISURA DOVE IL REFEREE NON VEDE, ED
riga 399 → | 2026-09-01 | **I DOCUMENTI DI LAVORO ENTRANO NEL DEPOSITO      ← combacia
riga 400 → | 2026-09-01 | **CHI COMANDA SU COSA — SUL DETTAGLIO IL CO       ← NUOVA (A307)
riga 401 → | 2026-09-01 | **IL REFEREE, QUANDO MAURO CONTRADDICE UNA MI     ← NUOVA (A307)
riga 402 → (vuota)
```

⇒ **La guardia sarebbe passata, e il lavoro sarebbe proseguito.** Ma la riga 399 **non è più l'ultima riga-tabella di Sezione 2** — lo sono la 400 e la 401. Il mandato chiede la riga nuova *«SUBITO DOPO l'ultima riga-tabella di Sezione 2»*, e inserirla dopo la 399 l'avrebbe messa **in mezzo alle decisioni, non in coda**, spezzando due righe di A307 dal loro contesto.

**[A] Il meccanismo, che è la parte riusabile:** l'ancora verificava **l'identità di una riga**, ma la proprietà che serviva davvero era **la sua posizione relativa** («è l'ultima?»). Sono due cose diverse, e coincidevano solo finché nulla veniva aggiunto sotto. Una guardia che controlla l'identità non intercetta un cambio di posizione — **è la stessa classe già a verbale in BOX5: la guardia con un'assunzione non dichiarata**, qui l'assunzione «399 è l'ultima».

✅ **Rimedio che propongo, se il referee lo ratifica:** un'ancora d'inserimento in coda non si verifica sul testo della riga bersaglio, ma sulla **coppia** «questo testo È seguito dalla riga vuota / dal separatore di sezione». La coppia rende falso l'istante in cui qualcuno inserisce sotto; il testo da solo no.

---

## 4 · Cosa serve al referee per ri-emettere

Tutto misurato da me a fonte, così la ri-emissione non riparte da zero:

1. **ID nuovo.** A304 occupato, A305 bruciato (vedi referto A307 §1), A306 e A307 usati. **Il primo libero misurato oggi è `A308`** — cancello a sei gambe non ancora eseguito su di esso: lo farà chi apre il mandato.
2. **Ancoraggio nuovo**: commit `2c9b0bf8d4e48e2d6133029245b4db8e9bf5b9e3` (HEAD attuale).
3. **Impronta LIBRO a quel commit**: `4472e96c1db6d920e900f638209e2ae7a7d1915001f042c05cfb73a2b7d57042` · 353.989 byte · 577 righe · **blob, non disco** (LIBRO è CRLF su disco).
4. **Righe-tabella Sezione 2 a quel commit**: **205**. Gli altri tre conteggi (gamba 1, SICURE, complemento) da rifare sulla popolazione nuova.
5. **Ancora d'inserimento**: l'ultima riga-tabella di Sezione 2 è oggi quella che inizia `| 2026-09-01 | **IL REFEREE, QUANDO MAURO CONTRADDICE UNA MI…`, seguita da riga vuota. ⚠️ **Suggerisco di ancorare alla coppia riga+vuota, non alla sola riga** (§3).

---

## 5 · Cosa NON ho fatto, e perché

- ⛔ **Non ho eseguito la Tappa 1**, nemmeno parzialmente: né la classificazione a due gambe, né la resa delle voci, né l'indice. L'ancoraggio è dichiarato non valido dal mandato stesso; lavorare comunque avrebbe prodotto 62 voci ancorate a una popolazione superata, che è esattamente il tipo di artefatto che questo progetto passa il tempo a marcare come scaduto.
- ⛔ **Non ho scelto un ID nuovo per proseguire.** Il mandato autorizza «Se collide: ID nuovo, mai riuso» — ma quella clausola presuppone che il resto del mandato regga. Qui **anche l'ancoraggio è caduto**, e le sue impronte e i suoi numeri sono espressamente dichiarati «da rifare **dal referee**». Proseguire con un ID nuovo su misure che il mandato stesso affida a un altro sarebbe scavalcare una consegna esplicita.
- ⛔ **Non ho ricalcolato i tre conteggi** (§2, motivo dichiarato lì).
- ⛔ **Non ho creato `DECISIONI_ATTIVE.md`**, non ho toccato `LIBRO_MASTRO_QBEATS.md`, non ho toccato la riga R-γ del 2026-07-20, non ho aperto le pendenze R-γ di luglio, non ho toccato codice.

---

## 6 · Nota sul merito, che tengo separata dall'arresto

**[A]** L'arresto è procedurale e non dice nulla sul valore del mandato. Il disegno di `DECISIONI_ATTIVE.md` mi pare solido, e due sue clausole in particolare mi sembrano le più forti che abbia visto passare in questa sessione: **la valvola del custode** (che impedisce alla regola di bloccare una scrittura su LIBRO — un debito dichiarato è meglio di un blocco) e **il contatore calcolato invece che asserito**. Nessuna delle due va rivista per via di questo arresto: cadono solo le misure d'ancoraggio.

⚠️ **Una cosa segnalo come parere, non come misura**: il mandato prevede che io fermi il lavoro al cancello e attenda l'OK di Mauro su 62 voci riscritte, dichiarando che «leggere 62 voci può richiedere più di una seduta». Quando sarà ri-emesso, varrà la pena considerare se 62 voci in un colpo solo siano il taglio giusto, o se convenga un primo giro più corto — non per il costo di scriverle, ma perché **un OK dato su una lista troppo lunga rischia di essere un timbro**, che è precisamente ciò contro cui il LIBRO ha già una ratifica incisa il 31/08 («una firma richiesta per tutto smette di valere»). Non è materia mia deciderlo: lo lascio al referee e a Mauro.

---

## 7 · Consegna

Questo referto è depositato su **due gambe** (repo `HANDOFF/` + mirror `E:`), `cmp` exit 0 — esito e impronta in coda.

⚠️ **Untracked**, coerente col regime: entrerà nel commit del prossimo giro, come A303/A304/A306 prima di lui.

---

*ARRESTO AL CANCELLO — mandato «A304 v5» non eseguito — FINE.*
