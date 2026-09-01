# HANDOFF CC — cambio chat — 2026-08-04

**Deposito, NON ratifica. Verificare, non ereditare.**

Scritto da questa sessione CC, in chiusura, senza aver letto il congedo del referee — non me l'ha mandato, deliberatamente, e non l'ho cercato. Ogni numero qui sotto è stato rimisurato nell'ultima ora di questa sessione, non ricordato. Dove non ho potuto rimisurare, l'ho scritto e marcato come tale.

Convenzione usata in tutto il file: **[V]** = misurato da me, ora o in un comando di questo stesso turno di chiusura. **[R]** = riferito da altri (Mauro, il referee, un documento) e NON verificabile da me direttamente. Non ho trattato nulla di [R] come se fosse [V].

Orologio a inizio scrittura: **2026-08-04T19:44:28+02:00** / `2026-08-04T17:44:28Z` [V] (`date -Iseconds` e `date -u`).

---

## 1. Stato verificato adesso

Tutti i comandi sono stati eseguiti in questo turno, non ricopiati da turni precedenti.

**HEAD e remoto** [V]
```
git rev-parse HEAD                    -> ea3f94a4a11153a2f4c9f08ab8e1cd73d55d00ae
git ls-remote origin master           -> ea3f94a4a11153a2f4c9f08ab8e1cd73d55d00ae
git log origin/master..HEAD --oneline -> (vuoto, 0 righe)
```
Allineati. Il lotto del giorno è pubblico.

**Ultimi tre commit** [V] (`git log -3 --format="%H %cI %an"`)
```
ea3f94a4a11153a2f4c9f08ab8e1cd73d55d00ae  2026-08-04T15:15:23+02:00  Mauro Martintoni
5cd6397288203dfc19725dd1e10625c6657479c7 2026-08-04T15:14:25+02:00  Mauro Martintoni
bce6a736762f81eaf572b689a0c6237c1785b786 2026-08-04T15:11:06+02:00  Mauro Martintoni
```
Sole-authored, zero `Co-Authored-By` [V] (`git log -3 --format=%B | grep -ci co-authored` → 0). Precedono: `c1556e57b1a81fafa7973b8647741ede9c92e6cf` (2026-08-02T19:05:01+02:00) e `ebbb864c59bbb8b3cff3dbcd5ebbccf756062b3e` (2026-08-02T19:04:36+02:00).

**`git status` completo** [V] — 157 righe totali (`git status --short | wc -l`), tutte `??`. Nessun file `M`. I due canonici del lotto (`BUGS_QBEATS.md`, `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`) sono puliti.

**Untracked, per categoria** [V]
```
HANDOFF/  : 153 file  (git status --porcelain --untracked-files=all HANDOFF/ | grep -c '^??')
tools/    :   1 voce  (l'intera cartella, non file singoli)
repo tot. : 157
```

**Impronte dei cinque canonici, working-tree vs blob a HEAD** [V] — tutte combacianti, tutte pulite:
| file | hash | status |
|---|---|---|
| `BUGS_QBEATS.md` | `2598ae0288aefc29ac3d29c8b2e3b33e4057bb82` | pulito |
| `LIBRO_MASTRO_QBEATS.md` | `526dcd608e10e2b73a0e52b912368302153df310` | pulito |
| `BOX3_QBEATS.md` | `490d6d9b38c355dc53ddc9b31431f9a858f2b342` | pulito |
| `BOX5_QBEATS.md` | `21b23d621ac224c759b53d813196058483e3b056` | pulito |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | `e799b6b0b29f8d1e2afb179edfad28bb41489228` | pulito |

**Tracciato vs no** [V] — `HANDOFF/` ha esattamente 4 file tracciati (`git ls-files HANDOFF/`): `MISURE_CC_2026-07-30_R1-ACCERTAMENTI.txt`, `NODO_A_PIANO_2026-07-10.md`, `PIANO_S4b_REV_2026-07-18.txt`, `SCALETTA_ATOMI_S6_2026-07-10.md`. `tools/` ha **zero** file tracciati (`git ls-files tools/` vuoto, `git status --porcelain tools/` → `?? tools/`).

**E:, allineamento** [V] su tre file (i due del lotto + LIBRO, non ho riverificato BOX3/BOX5 su E: in questo giro — dichiaralo come non fatto, non come fatto):
```
BUGS_QBEATS.md                            C:2598ae0288 E:2598ae0288 -> MATCH
LIBRO_MASTRO_QBEATS.md                    C:526dcd608e E:526dcd608e -> MATCH
HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md   C:e799b6b0b2 E:e799b6b0b2 -> MATCH
```

---

## 2. Separazione [V] / [R] — esempi che contano

Applicata sopra e in tutto il file. I casi più rilevanti:
- **[R]** — la ratifica del referee sui tre diff (SCALETTA `A26`, BUGS v49/v50 `A33`): io ho prodotto le dimostrazioni, l'atto di ratifica è del referee, non mio.
- **[R]** — la severità 🔴 ALTA/BLOCCANTE PALCO decisa da Mauro il 04/08: eseguita perché il valore ricevuto coincideva col proposto, ma la decisione non è misurabile da me.
- **[R]** — la quarta destinazione R-δ = NAS Synology, copia manuale delle ~14:00-15:35 del 04/08: dichiarazione di Mauro, nessun accesso al NAS né da me né dal referee.
- **[R]** — «backup su disco esterno completato prima dell'autorizzazione» (citato come motivo dell'OK di Mauro al push, giro `A34`): mai verificato da nessuno dei due.
- **[V]→[R] misto** — l'oggetto `.git/objects` su Drive: il referee lo ha misurato per primo (`[R]`), io l'ho ri-misurato indipendentemente in modo diverso (l'oggetto sciolto del commit HEAD, non solo la struttura delle cartelle) e ho ottenuto lo stesso esito (`[V]`, giro `A26`).

---

## 3. I miei errori di questa sessione, per esteso

**Il più grande: una misura falsa che mi ha fatto contraddire un canonico, non solo il referee.**
Nel giro `QB-2026-08-04-A34-COMMIT-LOTTO-FINESHOW`, prima di preparare il primo commit, ho scritto: «il blob non è LF, porta CR su tutte le righe» — e su quella base ho dichiarato «superata» l'istruzione del referee di estrarre le copie con `git show` invece che dal disco. La misura era `grep -c $'\r' file`. In quel contesto `$'\r'` non viene interpretato come carattere CR: il comando conta le righe che contengono la lettera **r**, non i ritorni a capo. Su `BUGS_QBEATS.md` ha reso `1039` — che è il numero totale di righe del file, non il numero di CR (che erano zero).

**Chi l'ha trovato:** io stessa, nello stesso turno, pochi minuti dopo — non un controllo esterno. Mi sono accorta rimisurando con `tr -cd '\r' < file | wc -c` (che rende 0) e confermando sui byte grezzi con `od -c` sul blob. Ho corretto pubblicamente nella stessa risposta, prima di procedere.

**La parte che rende l'errore più serio di un refuso tecnico:** ho scoperto solo *dopo*, cercando dove viva R-δ per il giro `A35`, che l'istruzione «per i file tracciati la fonte è il blob, mai il disco» **è già una regola canonica**, incisa in `LIBRO_MASTRO_QBEATS.md:336 @ ea3f94a4a11153a2f4c9f08ab8e1cd73d55d00ae` [V, riverificato ora], con tanto di misura a fonte del 01/08/2026 che dimostra ESATTAMENTE lo stesso fenomeno (LIBRO e BUGS con due facce, byte-CR compresi) che io ho «riscoperto» il 04/08 credendo fosse una cosa nuova. Non avevo controllato se un canonico coprisse già la materia prima di rimisurarla da zero — e nel farlo, per un attimo, ho contraddetto quel canonico stesso senza saperlo.

**Un secondo errore, non auto-intercettato:** nel giro `A28`/`A29` avevo proposto, per la voce 45 del registro BUGS (pipe rotte dentro pattern di ricerca fra backtick), l'escape `\|` come «riparazione tipografica compatibile». Il referee l'ha respinta in `A31`: un `\|` inciso in un pattern documentato rompe la riverifica futura con `grep` (chi cerca la stringa letterale non la trova più) ed è invisibile a un linter che non sa leggere l'escape. Ho ritirato la mia conclusione e registrato la materia come divergenza aperta, decisione di Mauro — ma non l'ho trovato da sola: me l'ha segnalato il referee.

**Un quasi-errore, questo sì auto-intercettato prima di scrivere:** nel giro `A32` il mandato ricevuto (dal referee) indicava di copiare la forma del titolo da `TD-qlive-exit-unconfirmed-stop` come esempio di «titolo con severità» — ma quel ticket, verificato, **non ha severità nel titolo**. Prima di incidere ho misurato l'intera sezione (34 titoli con severità, 30 senza, su tutto il file) e mi sono fermata, segnalando che il modello nominato non conteneva ciò che doveva esemplificare, invece di eseguire alla lettera. Il referee ha riconosciuto l'errore come suo nel giro successivo (`A33`, testuale: «Errore del referee, non tuo»). Lo registro qui non per meriti ma perché è la controprova che il metodo — misurare prima di scrivere — ha retto quando contava.

**Un errore piccolo, auto-intercettato prima della consegna:** nella riga di registro `| 49 |` scritta in `A28` avevo incluso, dentro il testo della cella, la citazione `` `| 47 |` `` — due pipe di troppo che avrebbero rotto la tabella markdown. Trovato dal mio stesso controllo pipe (5/7/5 anziché 5/5/5) prima di consegnare, corretto in «la voce **47**».

**Un errore di conteggio, corretto nello stesso giro in cui l'ho fatto:** in `A26`, la prima stesura del reperto sulla propagazione Drive dichiarava «~100 file untracked» e «HANDOFF/ non è tracciata». Il conteggio vero era 147 (oggi: 153, la cartella è cresciuta), e 4 file **sono** tracciati. L'ho corretto prima della consegna finale dello stesso giro, non in uno successivo.

---

## 4. Trappole d'ambiente, con la controprova

**`grep -c $'\r'` non conta i CR.** Vedi sopra. Controprova sullo stesso file, oggi: `tr -cd '\r' < BUGS_QBEATS.md | wc -c` → `0` contro `grep -c $'\r' BUGS_QBEATS.md` → `1039`, che coincide col numero di righe del file. Il valore falso ha la forma di un valore plausibile — è il caso peggiore.

**`sed`, in questo ambiente, non è trasparente ai fine-riga.** In lettura: `git show <blob> | sed -n 'Np' | od -c` mostra righe terminate da `\n` anche quando si sta cercando di capire se il blob ha CR — perché `sed` li ha già tolti in uscita. In scrittura: un `sed -i "Ns|…|…\r|"` ha scritto un CR letterale nella preparazione del primo commit del lotto (innocuo: `core.autocrlf=true` lo ha normalizzato in ingresso, verificato `CR=0` sul blob con `od -c` sui byte grezzi) — ma non era voluto. Regola: `sed` non entra mai in una catena di misura sui fine-riga, né come lettore né come scrittore.

**Il perimetro delle «due facce» è più stretto di quanto sembri, ed è già misurato in canonico.** `.gitattributes` porta `HANDOFF/** -text`, `BOX3_QBEATS.md -text`, `BOX5_QBEATS.md -text`, `DESIGN/** -text`. Solo **`BUGS_QBEATS.md` e `LIBRO_MASTRO_QBEATS.md`** restano senza attributo e soggetti ad `autocrlf`. Misurato oggi [V] e già misurato il 01/08/2026 [R, citato in `LIBRO_MASTRO_QBEATS.md:336`] con numeri quasi identici. **La SCALETTA non è mai interessata.**

**`&&` e `grep -c` a zero match rompono le catene di comando.** `grep -c pattern file` con zero corrispondenze stampa `0` ma esce con status 1: in una catena `comando1 && comando2 && grep -c … && comando3`, se il grep rende zero, `comando3` non parte — anche se lo `0` stampato era esattamente il risultato voluto. Successo più volte in sessione; il rimedio è isolare quei conteggi dalla catena o accettare l'interruzione e continuare a mano.

**Il censimento delle ancore di commit dipende dalla notazione, e ce ne sono almeno tre.** `@ sha`, `` @ `sha` `` (chiocciola-backtick), e `: sha` (due punti, senza chiocciola — quella dell'unica ancora di blame dichiarata nel file). Un pattern che cerchi solo la prima forma perde due terzi delle occorrenze reali su `BUGS_QBEATS.md` (5 trovate contro 17 vere). Dettaglio completo in `HANDOFF/MISURE_CC_2026-08-04_A28-NOTAZIONE-ANCORE.txt`.

**Uno sha256 troncato a 40 caratteri è indistinguibile da uno SHA-1 git.** Due casi reali in `BUGS_QBEATS.md`, censiti nello stesso reperto: chi ci prova `git cat-file -e` ottiene un fallimento legittimo (non è un oggetto git) e può concludere erroneamente «ancora falsificata» — stessa firma diagnostica di un'ancora davvero rotta, causa del tutto diversa.

**`git ls-remote origin master` è l'unica fonte affidabile per lo stato del remoto.** L'output testuale di `git push` (`c1556e5..ea3f94a  master -> master`) è stato coerente in questa sessione, ma la verifica dichiarata si è sempre fatta con `ls-remote` a parte, mai fidandosi del solo output del comando.

---

## 5. Che cos'è esposto

- **~153 file in `HANDOFF/`**, untracked, nessuna rete git sotto: l'intera scia di lavoro dal 18/07 in poi — diff, misure, referti, congedi, gli handoff di cambio-chat precedenti (incluso questo). Protezione oggi: C: + E: (sincronizzati fra loro via Drive-desktop [R, misurato dal referee e ri-misurato da me in `A26`]) + Drive (che È il riflesso di C: ed E:, non una terza copia indipendente — questo è scritto nel canonico stesso, `LIBRO_MASTRO_QBEATS.md:336`, L3) + la quarta destinazione, sulla cui identità c'è discordanza (vedi §6.1).
- **L'intera cartella `tools/`**, incluso `lint_canonici.py` (12 KB, quattro famiglie di controlli funzionanti, ha già impedito un difetto reale in questo stesso lotto — vedi §3) — untracked, stesso rischio di sopra, in più: **fuori da git significa fuori dalla storia**, nessun modo di sapere chi l'ha scritto o quando senza il filesystem.
- **I sei diff del lotto** (`A25`/`A26`/`A28`/`A33`, tre generazioni per BUGS v49/v50 più due per SCALETTA) e **i quattro reperti di misura** di questa sessione (notazione ancore, Drive-sync-live, quarta-destinazione-NAS, e questo stesso handoff) — propagati C:/E:/Drive [V], **mai arrivati sul NAS**: la fotografia manuale dichiarata è delle ~14:00-15:35 del 04/08, e tutto ciò che è nato dopo (compresi i tre commit stessi) non c'è.
- **Se C: muore oggi**: E: e Drive cadono insieme (sono un riflesso), quindi la sola protezione realmente indipendente è la quarta destinazione — la cui fotografia, quale che sia il supporto vero, non copre le ultime ore di lavoro.

---

## 6. Coda aperta, nel mio ordine

1. **Sciogliere la discordanza chiavetta / NAS.** `LIBRO_MASTRO_QBEATS.md:336` [V, riverificato ora] dichiara verbatim: «Quarta destinazione, periodica e manuale, di Mauro: **la chiavetta**», con un paragrafo L3 lungo e motivato (dettato 01/08) che spiega perché quella copia deve essere indipendente e non sincronizzata. Il 04/08, a metà di questo turno, Mauro ha dichiarato [R] la quarta destinazione = **NAS Synology**, con la stessa identica motivazione (copia manuale, nessuna sincronizzazione, unica a non essere un riflesso). Le due dichiarazioni **non sono incompatibili nel ruolo** — sembra lo stesso ruolo su un supporto fisico diverso — ma nessuno le ha unificate in un canonico. Finché resta così, chi legge `LIBRO:336` per sapere «dov'è la quarta copia» trova una risposta superata senza saperlo. È in cima perché è la base di ogni valutazione di rischio del §5.
2. **Propagare questo lotto sulla quarta destinazione, quale che sia.** I tre commit e tutti gli artefatti nati oggi dopo le ~14:00 non ci sono ancora.
3. **Backfill della voce `v48`** nel registro versioni di BUGS — dichiarato nella voce `49` stessa come debito, mai eseguito. Verificato ora: `grep '^| 48 | 2026-'` su `BUGS_QBEATS.md` rende ancora **0** [V].
4. **Ricollocazione del ticket `TD-fineshow-bottoni-morti`** fuori da §1.2 (che si dichiara «non bloccanti palco» e lo contiene invece bloccante) — marcato nel campo Stato del ticket, mai risolto. Verificato ora: il ticket è ancora a `BUGS_QBEATS.md:319` [V], dentro la sezione aperta a `:148`.
5. **Le due righe di registro con le pipe rotte**, voci `45` e `46` — verificato ora, ancora `13` e `11` pipe contro `5` sano [V]. Cause diverse (dettaglio nel reperto notazione-ancore, sezione 6.3): la 46 è riformulabile senza rischio, la 45 è una divergenza aperta fra la mia proposta ritirata e l'obiezione del referee — decisione di Mauro.
6. **`tools/` dentro git.** È l'unico strumento automatico del progetto e vive fuori da ogni rete, incluso git stesso.
7. **«Rettifica di `LIBRO:316`»** — nominata nel prompt che ha aperto il giro `A35`, mai spiegata né investigata in questa sessione. L'ho letta ora [V]: parla della «REGOLA INDIRIZZO DI CONTENUTO», materia di processo cross-team, non ovviamente collegata al lotto fineshow. **Non so cosa vada corretto lì** — lo dichiaro invece di indovinarlo. Va chiesto a chi l'ha nominato.

Il mio ordine mette **1** davanti a tutto il resto perché condiziona la lettura del §5; se ti risulta diverso — per esempio perché **2** è più urgente indipendentemente da come si risolve **1** — è una scelta legittima e diversa dalla mia.

---

## 7. Dove penso che il referee abbia sbagliato — o dove un'istruzione mi ha fatto lavorare male

Un caso chiaro, già riconosciuto da entrambe le parti: il mandato del giro `A32` (C18 punto 1) indicava di copiare la forma del titolo da un ticket che non conteneva ciò che doveva esemplificare (§3, sopra). Il referee stesso lo ha corretto nel giro successivo dichiarandolo proprio errore. Non aggiungo altro perché è già chiuso e concorde.

Un'osservazione più larga, che non è un errore ma vale la pena scrivere perché nessun altro la scriverà: **il rapporto fra overhead procedurale e contenuto sostanziale in questa sessione è stato alto.** Per fondare due ticket e circa 15-20 righe di contenuto sostanziale in tre commit, sono serviti tredici referti numerati (`A23` → `A36`), ciascuno con il proprio giro di verifica-idempotenza-orologio-controllo-positivo. Il metodo ha funzionato — ha trovato quattro ancore rotte, una tabella che si sarebbe spezzata, un titolo copiato dal modello sbagliato, un mio errore di misura che contraddiceva un canonico — e non credo che nessuno di quei ritrovamenti sarebbe emerso con un protocollo più leggero. Ma **alcune correzioni indipendenti fra loro (C6, C9, C17, la scoperta della quarta destinazione) avrebbero potuto viaggiare nello stesso giro invece che in giri separati**, senza perdere nessuna delle verifiche. Non so se questo sia stato un costo necessario per la posta in gioco (repo pubblico, contenuto ratificato) o un margine di efficienza reale. Lo segnalo perché è l'unico giudizio di questo tipo che questa sessione può dare, e nessun'altra sessione lo scriverà al posto mio.

---

## 8. Cosa farei per primo, al posto della prossima chat

**Porterei il punto 6.1 (chiavetta vs NAS) a Mauro esplicitamente, prima di qualunque altra propagazione o commit.** Non perché sia il debito più grave in astratto — la ricollocazione del ticket in §1.2 nasconde un bloccante-palco, che è più grave nel merito — ma perché è l'unico punto che condiziona la lettura di tutti gli altri: finché non è chiaro dove sia oggi la quarta copia indipendente, non si può dire con certezza quanto sia davvero esposto il lavoro di questa sessione, né a chi tocchi rifarne la fotografia. Un errore commesso credendo di avere una rete che in realtà non c'è (o è vecchia di ore) è più costoso di un debito dichiarato e noto.

---

## Consegna

| campo | valore |
|---|---|
Nome: `HANDOFF_CC_2026-08-04_cambio-chat.md`.

⚠️ **Nota di metodo, non aggirabile:** questo file non può contenere la propria impronta — scriverla qui dentro cambierebbe il file e falserebbe il numero appena scritto. Byte, sha256 e verifica di propagazione sono dichiarati nella consegna del referto in chat che accompagna questa scrittura, non in questa tabella. I due handoff precedenti (`2026-08-02`, `2026-08-03`) sono stati verificati intatti prima di questa consegna, non toccati.

⚠️ **Non ancora sul NAS.** La copia manuale dichiarata è delle ~14:00-15:35 del 04/08; questo file nasce dopo. Rientra nel prossimo giro settimanale, o in una copia dedicata se il punto 6.1/6.2 viene sciolto prima.
