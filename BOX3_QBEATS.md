BOX3 V99 — 2026-07-22 (AUTOPORTANTE) · HEAD=origin=bfa07eb (⚠️ campo strutturalmente stale by-design, come Sez.5 di LIBRO: cita l'HEAD al momento della scrittura, NON aggiornato dopo; chi ha bisogno dell'HEAD vero verifica `git log -1` a fonte — verificato a fonte 22/07: HEAD = origin/master = `bfa07eba05aecb25c334d54fe8a9695f57464d76` = BUGS v42; CI `29912886883` verde, `headSha` coincidente)
Supersede V98 (chiusura del giro doc 22/07: il punto (k) di V98 sciolto a fonte, due righe storiche falsificate, tre commit + tre CI verdi, e DUE nuove modalità di guasto silenzioso; ZERO codice toccato):
 · **(a) SCALETTA — il punto (k) di V98 È SCIOLTO: è TRACCIATA.** `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` è tracciata dal commit `fe6d34b` del **2026-07-18** («SCALETTA_ATOMI_S6 tracciata in git — cambio di regime, contenuto invariato»). `attr/-text`, disco = blob `0714a975…`. Le **tre** copie note — repo, E:, Progetto Claude — sono **byte-identiche** (sha256 `D2CDF120…`) e portano **Versione 2 (17/07)**, cioè quella buona: **un solo contenuto in tre posti**. ⚠️ Di conseguenza il punto **(g) di V97**, riportato invariato nel corpo sotto, è **FALSO SU ENTRAMBE LE METÀ**: non «ZERO copie in git» (è tracciata da quattro giorni prima che quella riga fosse scritta) e non «DUE copie divergenti su E:» (ce n'è una; la v1 stale in `REFEREE_SYNC_2026-07-13/` non esiste più). La storia non si riscrive: si marca qui. **RESTA APERTO — regime della SCALETTA:** è tracciata ma vive in `HANDOFF/` con nome per-data, fuori dal regime root + in-place dei canonici, mentre R-γ la enumera fra i canonici. Atomo doc a sé. Ratificato in **LIBRO v40**, riga `2026-07-22`.
 · **(b) TD#17 — CONDIZIONE DI CHIUSURA AGLI ATTI, nell'ordine R-γ.** Prima **LIBRO v40** (`131a511`, Sez.2 riga `2026-07-22`), poi **BUGS v42** (`bfa07eb`, §1.1 nuovo bullet + clausola «NON CHIUSO» allineata). Chiusura con **(A)** run di palco 2-3 h su VR2800 in banda singola senza perdita peer **OPPURE (B)** Soluzione C in produzione — **alternative, non cumulative**; il cross-banda sotto roaming è **caratterizzazione**, non condizione. Stato invariato: 🟠 **OPEN MEDIA, NON bloccante**. Chiusa anche la contraddizione interna di BUGS v41, che teneva la formula in AND accanto a uno SCOPING (23/06) che già dava il roam «in coda». ⚠️ **Debito minore aperto:** dal ticket TD#17 è sparita l'ancora «Soluzione C = backlog Fase 6-7», che viveva solo nella riga Stato sostituita; sopravvive in LIBRO alla riga `2026-07-02`. Da rimettere in un giro futuro di BUGS, non urgente.
 · **(c) CATENA COMMIT E CI DEL 22/07, verificata a fonte.** `ccb8151` BOX3 V98 (CI `29907914508` ✅) → `131a511` LIBRO v40 (CI `29911607478` ✅) → `bfa07eb` BUGS v42 (CI `29912886883` ✅). Tutti single-purpose, un file per commit, autore = committer = Mauro, **zero trailer**. Propagazione a E: verificata per tutti e tre: le stampe **sono il blob al byte** (BOX3 `8de560bc…`; LIBRO `efef5320…` su 3 copie; BUGS `84df1a1…` su 3 copie). Prima applicazione piena del regime ratificato il 21/07.
 · **(d) 🚨 FALSO-ZERO SILENZIOSO — `gh run list --commit` con lo sha CORTO.** Con lo sha a **7** caratteri il comando rende `[]` **con exit 0**; con lo sha a **40** rende la run. Nessun errore, nessun codice d'uscita diverso da zero: un comando che sembra dire «non esiste nessuna CI per quel commit» sta solo dicendo che non sa risolvere la notazione corta. Scoperto il 22/07 perché il referee aveva scritto lo sha corto nel proprio prompt e CC, invece di fermarsi al vuoto come il prompt gli chiedeva, ha rilanciato con quello pieno. → **REGOLA: nei comandi `gh … --commit` si usa SEMPRE lo sha a 40 caratteri.** E in generale: **un risultato vuoto restituito da un filtro non è un fatto negativo** finché non si è verificata la notazione del filtro.
 · **(e) FANTASMA — esiste anche la DIREZIONE OPPOSTA, e una diagnosi archiviata è SMENTITA.** V98 (e) registra l'indice di ricerca che serve un file assente dal filesystem. Il 22/07 si è misurato anche il contrario: BOX3 V98 e LIBRO v40 **presenti** nel magazzino del Progetto (conteggio righe 795 e 433, convenzione tarata su quattro file di contenuto noto: BUGS 874, BOX5 475, SCALETTA 184, NODO_A 93 — quattro su quattro) e **assenti** dalla copia-file letta dal referee. Le due direzioni sono indipendenti: vanno considerate entrambe. ⚠️ **SMENTITA:** `SCALETTA-rename_BOX3v95_DIFF_2026-07-13.txt` archiviava il fenomeno come «CACHE DI SESSIONE del project upload (fantasma di sessione), NON un difetto del progetto». Falsificata due volte — dalla misura del 21/07 (rimuovendo il BUGS v41 quello spariva dall'indice all'istante, il v36 no) e dall'osservazione diretta del 22/07. Quella diagnosi viveva in un `.txt` sciolto, **mai in un canonico**: stessa forma di E3 (una conclusione che non atterra in un documento canonico non esiste operativamente, e non viene mai rivista).
 · **(f) CANCELLO DI RATIFICA SALTATO su BUGS v42 — registrato perché non si ripeta.** CC ha committato v42 dichiarando chiuso il cancello di Mauro e trattando quello del referee come assolto dal fatto che il diff «era sul tavolo del referee». **Consegna ≠ ratifica.** Il referee non aveva ratificato: il diff non gli era arrivato (quinto guasto di trasporto della giornata). Contenuto poi verificato riga per riga e **ratificato a posteriori: corretto**, nessuna rettifica necessaria. → La lezione non è sul contenuto. È che **due volte in un giorno la SOSTANZA era giusta e la PROCEDURA no** (la propagazione del 21/07, certificata con una frase impossibile; e questa ratifica). È per questo che il cancello sembra superfluo — regge quasi sempre lo stesso — ed è esattamente per questo che non lo è: l'unica volta in cui non regge, te ne accorgi **dopo**.
 · **(g) METODO DI SCRITTURA SU CANONICI — consolidato, 3 atomi su 3.** (1) Su file a **due facce** (CRLF disco / LF blob: LIBRO e BUGS) **non si usa un editor**: script sui byte grezzi, ancore verificate una per una con **ABORT prima della scrittura**, CRLF preservato, niente BOM. (2) **Il cancello non è il diff: sono le IMPRONTE PRECALCOLATE** dal referee per ricostruzione indipendente — OID disco, OID blob, lunghezza in byte, conteggio righe. Chi scrive e chi controlla non condividono la misura, e il controllo cattura qualunque errore di encoding. (3) Ha retto **3/3** (V98, LIBRO v40, BUGS v42) e ha funzionato **anche quando il diff si è perso in trasporto** — che oggi è successo cinque volte. Il diff verbatim resta dovuto; le impronte sono ciò che lo rende verificabile quando il diff non arriva.
 · Nient'altro cambiato nella sostanza rispetto a V98; il corpo di V98 (da «Supersede V97» in giù) è riportato sotto INVARIATO per continuità autoportante, coda esclusa (riscritta).

Supersede V97 (giro di igiene documentale 21-22/07: regime dei canonici ratificato e applicato, propagazione a E: rettificata a fonte, tre difetti di trasporto/indice verificati per misura; ZERO codice toccato):
 · **(a) REGIME DEI CANONICI — BOX3 NON È PIÙ UNTRACKED.** Ratificato 21/07 (LIBRO v39, Sez.2 riga 2026-07-21; spec in BOX5 V27). `BOX3_QBEATS.md` e `BOX5_QBEATS.md` vivono in **root**, **tracciati**, con `-text` in `.gitattributes` (disco = blob al byte), e si modificano **IN PLACE**: niente più un file nuovo per versione, le versioni precedenti stanno nella storia git. Rinomino puro in `edaa80f`. ⚠️ Il blocco di coda di V97 istruiva il contrario («Nessun commit git (BOX3 è untracked)») e si autodescriveva «V95»: RISCRITTO in questa versione. **Il pezzo che regge non è il nome fisso, è il TRACCIAMENTO.**
 · **(b) HEAD e CI — verificati a fonte 22/07.** `git log -1` = `git rev-parse origin/master` = `9784294c05437dc727a9618014d147e0d9fab66e`. `gh run view 29855951057` → `conclusion: success`, `headSha` identico a HEAD, `headBranch: master`, workflow «iOS Signed Build»; `gh run list --commit 9784294…` restituisce **una sola** run. Prima di questa verifica il numero di CI viveva in una memoria di stato-corrente senza fonte mai mostrata.
 · **(c) PROPAGAZIONE A E: — ESEGUITA E CORRETTA, ma la DESCRIZIONE della verifica era FALSA.** I 4 file ci sono (stampa `LIBRO_MASTRO_QBEATS_V39_2026-07-21_9784294.md`, stampa `BOX5_V27_2026-07-21_fc06ed5.md`, 2 mirror vivi del LIBRO), timestamp identico 22/07 06:46:42, e portano il contenuto del **BLOB** — che è ciò che BOX5 V27 prescrive. ⚠️ La formula «sha256 riletti DAL DISCO contro `git show`, tutte le coppie coincidono», propagata in handoff e in MEMORY.md, è **impossibile**: stampa LIBRO = `F78A1F70` / 121.680 B = blob `d2805d13`; disco = `0D2F887E` / 122.109 B. Non possono coincidere. Il confronto valido è **stampa-vs-blob**, mai stampa-vs-disco. Rettificato in MEMORY.md il 22/07. Danno sugli artefatti: zero. Danno sul registro: un ✅ che nessuno avrebbe più rifatto.
 · **(d) LE DUE FACCE, provate a fonte.** `git ls-files --eol` a HEAD: `BOX3_QBEATS.md` e `BOX5_QBEATS.md` → `i/lf w/lf attr/-text`, e i loro OID blob e disco (`git hash-object --no-filters`) sono **identici** → disco = blob, `-text` funziona. `BUGS_QBEATS.md` e `LIBRO_MASTRO_QBEATS.md` → `i/lf w/crlf attr/` (nessun attributo) → **due facce reali**, blob LF / disco CRLF, delta = 1 byte per riga. Normalizzando CRLF→LF il disco si ottiene esattamente l'OID del blob per entrambi → **nessun edit non committato**, la divergenza è solo di fine-riga. `git status --porcelain` conferma: zero file tracciati modificati.
 · **(e) FANTASMA NELL'INDICE — verificato IN DIRETTA il 22/07, non ereditato.** Una ricerca su TD#17 nel Progetto ha restituito chunk da `BUGS_QBEATS36.md` (versione RIMOSSA, 15/07) accanto a materiale del LIBRO, **senza marcatore di versione nello snippet**. In parallelo, `LIBRO_MASTRO_QBEATS.md` risultava presente all'indice di ricerca e **assente dal filesystem** del Progetto: i due canali si contraddicono. → **REGOLA:** ogni volta che si cita un canonico si DICHIARA la versione letta nell'intestazione del blocco; e un risultato di ricerca NON è una fonte — non è verificabile né ancorabile a un commit, quindi non ci si ratifica sopra.
 · **(f) IL NOME FISSO È UNA TRAPPOLA — dimostrato per misura, non argomentato.** Nel Progetto i canonici caricati col nome fisso del repo sono indistinguibili per versione: non si sa QUALE versione l'indice stia servendo, e un caricamento vecchio si sovrascrive in silenzio. → La copia propagata al Progetto Claude segue la stessa regola di E: — **nome per-versione ancorato al commit introduttivo**, MAI nome fisso. Il nome fisso vale SOLO per il file tracciato in root.
 · **(g) GUASTO DI TRASPORTO, seconda occorrenza.** Il 21/07 file caricati arrivavano vuoti pur essendo pieni sul disco; il 22/07 due canonici sono scomparsi dal Progetto durante un aggiornamento e un ricaricamento non si è propagato. Il canale-allegato-di-messaggio ha funzionato quando il canale-progetto no. → **Né allegato né incollato sono affidabili per definizione:** si dichiara esplicitamente «il file è arrivato, l'ho letto, versione X, impronta Y» PRIMA di ratificare. Verifica end-to-end riuscita il 22/07: gli allegati ricevuti dal referee coincidono bit per bit con i file su disco C:.
 · **(h) TD#17 — LA CONDIZIONE DI CHIUSURA NON È RATIFICATA.** Per il test R-γ («è in LIBRO_MASTRO o non è ratificato»): Sez.2 del LIBRO v39 ha **una sola** riga datata 21/07 ed è il regime dei canonici; **nessuna riga TD#17**. L'ultima parola del LIBRO resta quella del 22/06: «Chiusura piena = pendente run palco VR2800 **(caso roam)**» — che include ancora il roam, cioè proprio ciò che la decisione del 21/07 intendeva declassare a caratterizzazione. → La condizione (chiusura con **(A)** run palco 2-3h VR2800 in banda singola senza perdita peer **OPPURE (B)** Soluzione C in produzione; roaming cross-banda = caratterizzazione, non condizione) va **prima ratificata in LIBRO**, poi scritta in BUGS. Ordine invertito rispetto alla coda dell'handoff. Stato TD#17 invariato: 🟠 OPEN MEDIA, NON bloccante.
 · **(i) UN'IMPRONTA PROVA LA CORRISPONDENZA, NON LA COMPLETEZZA.** Uno sha256 che coincide dice che due copie hanno lo stesso contenuto; non dice che sia stato propagato TUTTO ciò che andava propagato, né che il file di partenza fosse quello giusto. La verifica di completezza è un'altra cosa: si elenca il bersaglio e si conta.
 · **(j) IGIENE REPO — stato reale al 22/07.** `git status --porcelain`: 26 file **non tracciati** (24 in `HANDOFF/`, 2 piani `.md` in root), zero file tracciati modificati. Non tracciati = **non pubblicati**: la scelta di repo PUBBLICO non li espone. ⚠️ Fra questi ci sono `DOC_BOX3_V97…`, `DOC_BUGS_v39…`, `DOC_LIBRO_v36…`: copie di canonici che vivono fuori da git, cioè lo stesso stampo che ha prodotto le due SCALETTA divergenti. Registrato, non risolto.
 · **(k) SCALETTA — anomalia da chiarire prima di dire che l'elenco canonico è coerente.** `SCALETTA_ATOMI_S6_2026-07-10.md` NON compare fra i non tracciati e NON risulta modificata. Delle due l'una: o è tracciata (e la voce di backlog «da tracciare» è scaduta), o **non è nel repo affatto** e vive solo su E:, il che spiegherebbe le due copie omonime divergenti. R-γ la enumera fra i canonici: l'ambiguità va sciolta a fonte. NON dedotto qui.
 · **(l) R8 — worktree confermati a fonte 22/07.** `Q-BEATS @ 9784294 [master]` (LIVE) e `qb_fixB @ add556f [test/bug2b-test7-fixtures]`. Due, entrambi noti, nessuna sorpresa. Il gruppo STALE `qb468clone`/`qb_fixA` resta fuori dai worktree del repo LIVE (§14, cloni indipendenti).
 · **(m) FORMA D'ERRORE RICORRENTE, registrata perché si ripeta di meno.** Tutti i difetti di questo giro hanno la stessa forma: si possiede METÀ del fatto e si completa l'altra metà per inferenza plausibile invece di andare nella fonte. Il caso (c) ne è l'esemplare puro: la propagazione ERA giusta, la frase che la certificava no. **La contromisura che ha retto è la verifica indipendente non collassata** — chi scrive e chi controlla non condividono la stessa misura.
 · Nient'altro cambiato nella sostanza rispetto a V97; il corpo di V97 (da «Supersede V96» in giù) è riportato sotto INVARIATO per continuità autoportante, coda esclusa (riscritta, vedi (a)).

Supersede V96 (S4a su master + tre ratifiche 18/07 che RISCRIVONO il prereq di S4; il punto (k) di V96 è SUPERATO — istruiva a costruire uno stop sulla navigazione interna, ora vietato da CD; vedi (a) e i marcatori ⛔/✅/⚠️ inline nel corpo sotto):
 · §1 CANCELLI §6: **S4a 🟢 su master** — commit `f8276f6` «S4a: QLiveShowsView come dead code (frame ② read-only, non referenziato)», 1 file +309/−0, autore Mauro, zero trailer; CI `29653954692` verde (build 4m41s, soli warning noti Node20/aws-tap). ⚠️ **CI-verde ≠ chiuso**: QLiveShowsView è DEAD CODE, non referenziato, mai visto a schermo → chiusura visiva = gate device S4b. QLiveRootView.swift e AppRootView.swift NON toccati (S4b, atomo separato, bloccato in attesa della stesura ratificata).
 · **(a) 🚨 PUNTO (k) RISCRITTO — la direzione di V96 DECADE.** La decisione CD 18/07 (opzione (c)) stabilisce che **navigazione e transport sono separati**: uscendo dal metronomo il click NON si ferma MAI; lo ferma SOLO uno STOP esplicito (bottone nel metronomo, o MIDI Stop da pedaliera). Ragione dirimente: con Link Director uno stop è un evento di BANDA, non può essere il sottoprodotto di un «indietro». → Il prereq (k) nella forma «aggiungi uno stop alla navigazione interna» è **SUPERATO**; vietato installare `.onChange(of: page)` con stop, in nessuna forma (neanche inerte). → Al suo posto, il PREREQUISITO VERO: se l'audio SOPRAVVIVE alla navigazione, deve sopravvivere anche lo STATO che lo governa. Oggi `SetlistRunner` è `@StateObject` in `LiveRootView.swift:12-13` → muore al pop; `audioEngine` viene da `QBeatsApp` e sopravvive. Al rientro nascerebbe un runner FRESCO (canzone 1) col click già avanti = UI e clock divergenti sul palco. **DECISIONE MAURO 18/07 (ratificata): la proprietà del runner SALE** — il runner sopravvive alla navigazione interna e muore SOLO all'uscita da Q-Live. Atterra in **S4L**, NON in S4. In S4 il problema è MUTO (metronomo irraggiungibile dopo il flip S4b → S6).
 · **(b) §0/§7 — CLAIM LINK SORGENTATO A HEAD E CORRETTO** (supersede reperto (l) di V96, che restava «da riancorare»). Fonte terza = header Ableton VENDORED nel repo `Vendors/AbletonLink/LinkKit.xcframework/ios-arm64/Headers/ABLLink.h`. Catena a HEAD f8276f6: `link_engine_stop` (`LinkEngine.mm:485-496`) fa `ABLLinkSetIsPlaying(state,false,…)` + `ABLLinkCommitAppSessionState`; l'header dice (`:230-236`) che il commit «will be communicated to other peers in the session», MA (`:18-20`) «only shared with other peers when start/stop synchronization is enabled», e (`:75-82`) tale abilitazione è «only controllable by the USER via the Link settings dialog… not controllable programmatically». → **CORREZIONE del claim V96**: `ABLLinkStartStopSyncSupported: true` (`project.yml:19`) NON attiva la propagazione — **PERMETTE ALL'UTENTE** di attivarla dal dialog Link, ed è una scelta **PER-PEER**. Conseguenza operativa: l'effetto-banda (i Follower si fermano su uno stop del leader) esiste SOLO a configurazione utente accesa, sui device coinvolti. La conclusione operativa del §0 non cambia: lo stop non deve essere il sottoprodotto spurio di altro — ora RAFFORZATA dalla decisione CD. Interruzione iOS (telefonata) INVARIATA: `AudioEngine.swift:2676-2677` non chiama `link_engine_stop` → NON propaga (righe identiche a HEAD, riverificate). Il reperto (l) passa da «da riancorare» a **FATTO OPERATIVO sorgentato**.
 · **(c) RULING D1-SPLIT (per S4b).** Si installa: `page` + `switch page` + `navigate(to:)` + il COMMENTO DI GUARDIA con la decisione CD 18/07 (incisione della ratifica dove un futuro lettore la cablerebbe per errore — NON uno stop commentato). NON si installa `.onChange(of: page)` con stop (dead code che ESEGUE una politica vietata: E3 al contrario). NON si installa `previousPage` (unico consumatore era l'handler di stop = stato morto senza lettore; si aggiungerà col suo lettore quando servirà, presumibilmente S6). Vincolo tecnico invariato: `QLivePage` case-only (Equatable auto-sintetizzato, come `Screen`); il payload sta in `@State` separato, mai nell'enum.
 · **(d) MODELLO RATIFICATO «sessione ≡ stanza».** La navigazione INTERNA di Q-Live NON chiude la sessione live (runner + click); l'uscita dalla STANZA la chiude. Con questo modello il canonico `AppRootView.swift:61-68` (stop all'uscita da `.qLive`) e la decisione CD convivono SENZA contraddizione: il canonico non è «stop-da-navigazione», è fine-sessione al bordo-stanza. (Resta la questione di sicurezza sull'uscita-stanza col click attivo: vedi BUGS v39 + LIBRO v36 punto (3) — direzione CD (iii) ratificata, freeze del disegno atteso.)
 · **(e) VINCOLO TECNICO S4L da incidere.** Un `ObservableObject` ANNIDATO dentro un altro NON propaga: `QLiveSession.@Published runner` notifica solo APPARIZIONE/SCOMPARSA del runner, NON i suoi cambi interni (canzone/sezione/BPM). I figli devono osservare **IL RUNNER** (`@ObservedObject`/`@EnvironmentObject` sul runner), NON la sessione — pena UI metronomo CONGELATA che sembrerebbe un bug del DSP. Da scrivere come VINCOLO nella scheda ⟦S4L⟧ alla riscrittura SCALETTA (ratifica referee), insieme all'emendamento esplicito dell'invariante Nodo A «renderizza LiveRootView, MAI LiveView diretto» (scopo preservato — mai LiveView senza runner iniettato, garantito dal gate `if let runner`; lettera cambiata).
 · **(f) RETTIFICA — `qb_fixB` NON era un errore di memoria** (vedi marcatore ⚠️ inline alla riga d'origine dell'errore, nel corpo Supersede V96→V95). È un worktree REALE del repo LIVE: verificato 18/07 `git worktree list` → `C:\Users\BULLFROG\qb_fixB` branch `test/bug2b-test7-fixtures @ add556f`. L'errore riguardava SOLO il gruppo STALE, che è **`qb_fixA` su `qb468clone`**. La nota di V96 («NB: corregge il mio handoff 14/07 che parlava di qb_fixB») correggeva TROPPO LARGO: cancellava anche un dato giusto. `qb_fixB` resta il worktree con trigger-di-rimozione soddisfatto (§14, azione manuale Mauro); `qb468clone`+`qb_fixA` restano i cloni cancellabili.
 · **(g) SCALETTA — regime da decidere: NON è a copia singola.** Ne esistono DUE copie sullo STESSO disco E: con lo STESSO nome e contenuto DIVERGENTE: v2 corretta (Versione 2, 17/07, NODO A 🟢) in `FILE X CLAUDE.MD/HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`; v1 STALE (Versione 1, 12/07) in `FILE X CLAUDE.MD/HANDOFF/REFEREE_SYNC_2026-07-13/SCALETTA_ATOMI_S6_2026-07-10.md`; ZERO copie in git. È una TRAPPOLA PER NOME-FILE. Registrato come DEBITO APERTO in §14 (vedi voce inline); la cancellazione della v1 è azione manuale di Mauro. (Al prossimo giro doc la SCALETTA va anche riscritta per S4L — punto (e) — e portata a regime doppia-copia C:+E: come BOX3/BOX5, ratifica referee.)
 · **(h) HEAD e stato:** campo di testa aggiornato a `f8276f6` (riga di testa sopra), **STALE BY-DESIGN**: non usarlo come puntatore; l'HEAD vero si verifica con `git log -1` a fonte.
 · Nient'altro cambiato nella sostanza rispetto a V96; il corpo di V96 (da «Supersede V95» in giù) è riportato sotto INVARIATO per continuità autoportante, SALVO i marcatori inline ⛔/✅/⚠️ (che NON riscrivono la storia: la marcano superata dove istruirebbe male — la catena Supersede È il versionamento di BOX3, non-git).
Supersede V95 (NODO A CHIUSO — Q-Live assorbita in `AppRootView.Screen.qLive`, modale UIKit ritirata, device-validato 17/07; E3 registrato come SUPERATO ma con una scoperta che sopravvive come prereq bloccante di S4):
 · §1 CANCELLI §6: **NODO A 🟢 CHIUSO, device-validato 17/07** — 3 atomi N0 `a2fb816` / N1a `beb9e08` / N1b `152445e` (master, CI verdi; ultima CI `29608514870`, «build in 3m58s»). Gate device B+C+A-cheap PASSATO (Mauro): C (uscita col click attivo → tace) · A-cheap (3-4 rientri a freddo, no crash) · B (import `.qbeats` da app File con Q-Live a schermo → sheet SOPRA Q-Live + 2 song di test ritrovate in Q-Stage›Songs = import a fondo). **Sblocca S4.** Shippato **E1+E2**, NON E3 (vedi punto (j)).
 · 🔴 CAVEAT GATE C (da NON perdere): `HomeRootView.swift:43 .onAppear { audioEngine.stop() }` è PRE-ESISTENTE e col flip ri-scatta a ogni ritorno in Home → su back e CANCEL lo stop è DOPPIAMENTE coperto. Il gate C prova la sicurezza di palco (il click tace) ma **NON isola** il nuovo handler `AppRootView.onChange(of: screen)` (le sonde GATE-NODOA di E2/E3 non sono mai state costruite — verificato a fonte). Discriminante vero = la prima uscita che NON passa da Home = RoomSwitchBar (S4/step 3). Fino ad allora il canonico è ratificato per costruzione, non provato in isolamento.
 · E2 (17/07, ratifica referee): `{ screen = .home }` vive SOLO in `AppRootView` (`Screen` è `private enum`); `QLiveRootView` possiede `onExit` e lo INOLTRA a `LiveRootView` (hookpoint unico riusato da S4 = Cond A). Specchio esatto di `QStageRootView`.
 · Lezione CRLF/LF + `.gitattributes` (creato 11/07; copre `HANDOFF/**` e `DESIGN/**`, NON il BUGS di root): i canonici tracciati esistono in due formati byte-diversi (CRLF sul disco di lavoro, LF nel blob git). Snapshot su E: dai BLOB git (`git show`), MAI Copy-Item dal disco. Formalizzato in **BOX5 V26** (invariante due-regimi).
 · Fragilità future pipeline CI (warning, NON errori — il build gira): deprecazione Node.js 20 sui runner GitHub + tap Homebrew `aws/tap` non-trusted. Il giorno che GitHub toglie Node 20, master va rosso «da solo».
 · Lista COMMENTI-STALE da bonificare in S4L (solo commenti, zero impatto funzionale): `SetlistRunner.swift` cita `AudioEngine.swift:503` (guardia start reale `:859`) · `AudioEngine.swift:169` e `LiveView.swift:378` citano «~436-442» per il callback start/stop (reale `:524`) · `AudioEngine.swift:616-618` (deinit) attribuisce ad Apple docs che `engine.stop()` sia «blocking/sincrono» (le docs NON lo dichiarano) · `HomeRootView` header cita `LiveView.swift:82` (scaleFactor, spostata) · `LivePlaybackState.swift:16` e `TransportView.swift:46` citano «dismiss a Bivio» (falso post-N1b). Bonifica in UN giro quando si tocca quella zona.
 · §13 PROSSIMI STEP: NODO A rimosso (FATTO). Prossimo atomo reale = **S4** (Q-Live›Shows).
 · §14 DEBITI — triage cloni giugno: i 2 rami di giugno sono su origin con SHA IDENTICO al locale (backup remoto garantito), contenuto confluito in master via squash `ee0cbc0` (`git cherry` dà falso-negativo sugli squash). Cartelle locali `qb468clone` + `qb_fixA` CANCELLABILI in sicurezza (azione manuale Mauro); i rami su GitHub si CONSERVANO (traccia storica). ⚠️ Topologia = DUE cloni indipendenti, non worktree di uno solo; il live è `Desktop\ANTIGRAVITY\Q-BEATS`. (NB: corregge il mio handoff 14/07 che parlava di `qb_fixB`.) ⚠️ RETTIFICA V97 (f): questa nota correggeva TROPPO LARGO. `qb_fixB` è worktree REALE del repo LIVE (verificato 18/07 `git worktree list` → `qb_fixB @ add556f`, branch `test/bug2b-test7-fixtures`), NON un errore di memoria; l'errore era SOLO su `qb_fixA`/`qb468clone`.
 · Campo HEAD in testa → `152445e` (col caveat «strutturalmente stale by-design»).
 · **(j) E3 — SUPERATO, con una scoperta che SOPRAVVIVE.** E3 (14/07, ratificato referee+Mauro, vissuto SOLO in `HANDOFF_CC_2026-07-14_sera_NODOA.txt` §2.B, MAI entrato nel piano canonico) disponeva il RITIRO di E1 = TENERE `LiveView .onDisappear{ audioEngine.stop() }` come rete ridondante. **Verdetto referee 17/07: E3 SUPERATO, E1 resta; il codice spedito (`152445e`) è E1+E2.** Motivi: (1) la premessa di E3 («le sonde GATE-NODOA discriminano il gate → la rimozione non compra nulla») NON si è avverata — le sonde non esistono nel codice spedito (verificato a fonte CC 17/07) → la ragione R1 di E1 resta valida; (2) E3 stesso documenta la posta contraria (sparo spurio della rete col click attivo → `link_engine_stop` → stop propagato ai Follower = si ferma la BAND; `.onDisappear` è non-deterministico); (3) nessuna uscita scoperta nello stato spedito (back+CANCEL passano dal canonico) → nessuna emergenza. **LEZIONE DI PROCESSO (la più seria del giro): una ratifica che non atterra in un documento canonico NON esiste operativamente** — E3 era ratificato e abbiamo spedito il suo contrario senza saperlo, perché viveva in un handoff. Le ratifiche vanno in piano/LIBRO/BOX3, non negli handoff.
 · ⛔ SUPERATO da V97 (a) — CD 18/07: navigazione ≠ transport, NESSUNO stop sulla navigazione interna. NON eseguire quanto segue; tenuto SOLO come storia. Il prereq VERO di S4 è la proprietà del runner (V97 (a)), e atterra in S4L. ↓
 · **(k) 🚨 PREREQUISITO BLOCCANTE DI S4 (la scoperta di E3 che sopravvive).** `AppRootView.onChange(of: screen)` è **strutturalmente cieco alle uscite che NON cambiano `screen`**. Da S4 nasceranno uscite **intra-`.qLive`** (dal metronomo verso lista Shows/dettaglio: `screen` resta `.qLive`) — richiesta esplicita Mauro 17/07 («il back dal metronomo deve portare a Q-Live›Shows, non a Home»). Su quel percorso, oggi, **NESSUN meccanismo ferma l'audio**: il canonico non scatta e la rete `.onDisappear` è stata rimossa da E1 → **il click continuerebbe a suonare uscendo dal metronomo, sul palco.** Direzione ratificata (referee 17/07): NON resuscitare `.onDisappear` (non-deterministico + posta band-stop, punto (j)); mettere lo stop al **punto di mutazione della navigazione INTERNA di Q-Live** — stesso principio del canonico, un livello sotto, deterministico. **Da progettare DENTRO S4, non dopo.**
 · ✅ CHIUSO da V97 (b) — claim Link sorgentato a `ABLLink.h` e CORRETTO (il flag PERMETTE l'attivazione utente, non attiva; scelta per-peer). Il testo sotto = storia del reperto. ↓
 · **(l) REPERTO DA RIANCORARE (non ancora fatto operativo).** E3 dichiara [V] che uno `stop()` con `isRunning==true` supera la guardia e chiama `link_engine_stop` → stop propagato ai Follower (fonti: `AudioEngine.swift` guardia `:1638`→`:1645` @ `872dd5b`; `project.yml:19 ABLLinkStartStopSyncSupported: true`), mentre l'interruzione iOS (chiamata) è ingegnerizzata per NON notificare Link (`AudioEngine.swift:2676-2677` @ `872dd5b`). Fonti a `872dd5b` (commit vecchio) → §7: **da RIANCORARE a HEAD prima di trattarlo come fatto operativo.** Reperto, non fatto chiuso.
Nient'altro cambiato nella sostanza rispetto a V95; il corpo di V95 (da «Supersede V94» in giù) è riportato sotto INVARIATO per continuità autoportante, SALVO §1 (riga Nodo A/S4) e §13 (prossimo atomo) aggiornati nel corpo per coerenza con questo blocco.

Supersede V94 (S3 CHIUSO — primo atomo §6 device-validato in assoluto; 5 scoperte operative registrate; debiti riconciliati):
 · §1 CANCELLI §6: S3 passa da «pronto, NON aperto» a 🟢 **CHIUSO, device-validato 14/07** — commit `c77d69f` (master, fast-forward da `bench/s3-gate`, zero merge-commit). Gate 4 tocchi PASSATO su iPhone reale (build #564). Sblocca S5.
 · §8 REGISTRO RESI: resi 1/3/5 chiusi — riclassificati (vedi scoperta 🔴3 sotto): 1 è device-testabile (chiuso su device), 3 e 5 NON lo sono per costruzione (chiusi contro contratto, verbatim codice↔freeze).
 · §12 REGOLE DI PROCESSO: BRANCH FIAMMIFERO ora ha un track record reale a 2 cicli completi (gate FAIL→hitfix→ri-gate PASS). Nuova sotto-sezione «SCOPERTE GATE S3 (14/07)» — 5 lezioni operative, 3 correggono assunti tenuti per giorni.
 · §13 PROSSIMI STEP: S3/gate rimossi (fatto). S5 tecnicamente sbloccato ma resta dietro Nodo A→S4→S4L nell'ordine SCALETTA sez.C — non è il prossimo atomo. Nodo A resta il prossimo atomo reale, prerequisiti invariati.
 · Nuova §14 DEBITI APERTI — registro consolidato (era sparso tra §13 e note sparse): B1 torna a 12 (bench/s3-gate cancellato, era temporaneo per costruzione) · 4 file memoria CC orfani trovano casa qui · BOX5 non-autoportante RICONCILIATO (criteri dichiarati; le stime precedenti NON sono comparabili — vedi sotto) · worktree qb_fixB (trigger di rimozione ora soddisfatto, rimozione non eseguita in questo turno) · scaleFactor iPad, ancore nude NODO A/S4/S4L/S5, TD import-validation, TD-1, tab-bar SF Symbols — tutti invariati, con fonte.
 · Nuova §15: 5 cose per CD (le 4 note + 1 nuova: fascia di sistema iOS sul bordo alto).
Nient'altro cambiato nella sostanza rispetto a V94; tutto il corpo storico (§2-§7, §9-§11) è riportato INVARIATO sotto per continuità autoportante (stesso criterio con cui V94 riportava V93/V92/V91).

Supersede V93 (doc-only, 1 aggiunta — registrazione debito, esito accertamento A/B/C):
 · §13 nuovo punto: DEBITO scaleFactor iPad (QStageRootView senza GeometryReader alla
   radice; atomi §6 con .font in pt fissi). Da chiudere prima di test/rilascio iPad.
   NON blocca S3. Verdetto referee su accertamento sha 3c1a21a0… ([A] gap confermato).
Nient'altro cambiato dal contenuto di V93.
Supersede V92 (doc-only, 3 correzioni — ratifica referee della SCALETTA-S3 ricevuta 13/07):
 (1) rimosso il blocco «SCALETTA PERICOLOSA» (§10 svuotato in nota di ratifica; puliti i
     4 rimandi collegati in testa/§1/§9/§13). La scaletta è stata riscritta il 12/07 dal
     contratto ratificato e RATIFICATA dal referee il 13/07 → S3 può essere guidato.
 (2) corretto l'auto-riferimento della riga «mirror di consegna»: diceva «QUESTO BOX3 V91»
     dentro un file che si chiamava V92 (refuso di copia) → ora «V93».
 (3) aggiunto ai prossimi step (§13) il worktree secondario qb_fixB trovato in R1 (residuo
     storico, NON fiammifero §6, rimozione dopo il gate device S3) e il debito «ancore-codice
     stale negli atomi futuri» (bonifica prima del NODO A).
Nient'altro cambiato dal contenuto di V92.
Supersede V91 (correzione R7, 3 righe — ironia: V91 violava la SUA STESSA regola §7 punto 6
«ancorare a HEAD, MAI a un commit storico»). Tre citazioni `file.swift @ commit-storico`
riancorate a HEAD `6fca624`, di cui 2 puntavano a versioni SUPERATE del file: la più grave era
`RoomSwitchBar.swift @ 87a8280`, che rimandava alla versione PRE-S2e col commento «APERTO PER
CD, non deciso» — la trappola che S2e ha appena RIMOSSO — cioè il puntatore alla bugia, dentro
il documento che ratifica R7. Simboli verificati presenti a HEAD PRIMA di riancorare
(`pill`/`hitExpansion` in RoomSwitchBar · `QBeatsStore`/`save` · `.cta.quiet`/`GoToQStageCTA`
in QLiveEmptyStates). Nient'altro cambiato dal contenuto di V91.
V91 a sua volta superava V90 (fermo a HEAD `04df53a`, quindi stale su tutta la catena
committata del pomeriggio). Cosa è cambiato dalla V90, tutto verificato a fonte (`git log`, non
sul prompt): la catena di oggi è CHIUSA in git e CI-verde —
  `9994bc0` freeze CD in git · `04df53a` LIBRO v30 (9 ratifiche CD Q7/Q9-Q16) ·
  `e9d7754` LIBRO v31 (R7 anti-cascata + fix Sez.5) · `7550476` S2e (allineamento
  commenti, 3 file) · `ab6b553` S2d (EmptyStateKit, move puro) · `6fca624` BUGS v35
  (mini-TD emptystatekit).
Le cose che in V90 erano "IN CORSO / bozza / proposto" sono ORA FATTE:
  · LIBRO v31 + R7 → COMMITTATO (`e9d7754`), non più "in attesa dei due cancelli";
  · S2e → COMMITTATO (`7550476`); ha anche CHIUSO il "RESTA APERTO" dei commenti Swift;
  · S2d → ESEGUITO (`ab6b553`), non più "proposto";
  · BUGS v35 → COMMITTATO (`6fca624`) + propagato a tutti i target E:.
NOVITÀ di questo giro, oltre agli aggiornamenti di stato:
  · nuova regola «PUSHATO ≠ PROPAGATO» (§7, fratello della regola due-sessioni);
  · SCALETTA_ATOMI_S6 riscritta su S3 (12/07) e RATIFICATA dal referee (13/07); ora
    versionata internamente («Versione: 1»). Non più "pericolosa" — vedi §10.
Questo documento si legge DA SOLO: zero rimandi a V91/V90 per contenuto sostanziale.
Untracked: `ARCHIVIO.MD/16_05_2026/BOX3_V62_16_05_2026.md` resta l'ultima versione BOX3
tracciata in git (V63 in poi mai tracciata) — fatto stabile da V89, non ri-verificato
qui perché nulla di oggi lo tocca. Zero sha256 incisi qui dentro (R7). Zero codice: solo stato.

════════════════════════════════════════════════════════════════════
1) CANCELLI §6 — STATO VIVO
════════════════════════════════════════════════════════════════════
· S0 (QLiveTheme) — 🟢 CHIUSO. `995a3bf`.
· S1 (RoomSwitchBar) — 🟡 CI-verde, componente ORA modificato dal gate-fix S3 (vedi S3 sotto) — il device-test di S1 in isolamento non è mai stato rifatto, ma la sua unica superficie a schermo (Q-Stage header) È stata device-validata via S3. `87a8280` (storico) → sostanza corrente in `c77d69f`.
· S2F (MetroFAB) — 🟡 CI-verde, NON chiuso device. `f91533f`.
· S2 (QLiveEmptyStates, corpo base) — 🟡 CI-verde, NON chiuso device. `ed11f65`.
· S2b (rework CD-Q9/CD-Q10) — 🟡 CI-verde, NON chiuso device. `8d7c7d1`.
· S2c (correzione nome + pulizia riferimenti) — 🟡 CI-verde, NON chiuso device. `9bb4ef6`.
· S2e (allineamento commenti: R7 path@commit + CD-Q7/Q8 risolte + gate reali) — 🟡 CI-verde, NON chiuso device. `7550476`.
· S2d (estrazione EmptyStateKit, move puro) — 🟡 CI-verde come commit (`ab6b553`); componente condiviso, la SUA unica superficie a schermo in questo periodo (badge/lineSpacing empty-state Q13) è stata device-validata via S3 (vedi resi 3/5, §8).
· **S3 (Shows list + sort sheet) — 🟢 CHIUSO, DEVICE-VALIDATO 14/07.** S3 = DUE commit su
  master (catena lineare, zero merge): `36775a4` (bulk — ShowsListView + QBeatsStore sort +
  innesto QStageRootView, +583/−4) + `c77d69f` (gate-fix hit-test, tip, +63/−33). **PRIMO
  ATOMO §6 CHIUSO TRAMITE UN GATE DEVICE REALE.** (S0 è 🟢 CHIUSO ma è un enum di token puri,
  chiuso senza gate device — niente da testare a schermo; S3 è il primo a passare un gate
  device vero e proprio.)
  Gate 4 tocchi (iPhone reale, build #564, filtro Console `GATE-S3`):
    [1] centro Q-Live → log presente + dimming visivo. PASS (sanity).
    [2] 8-10pt sopra il bordo → NON testabile pulito: iOS intercetta i tocchi vicino alla
        fascia di sistema in alto. Non un difetto app. Reso superfluo dal [3] (vedi sotto).
    [3] 8-10pt sotto il bordo, fuori dal riquadro visibile → log presente. **PASS, PROVA
        DECISIVA**: al primo gate (stesso giorno, tentativo precedente) questo tocco era
        MORTO. L'espansione è UNA sola `.padding(.vertical: hitExpansion)` simmetrica
        (sopra E sotto insieme): se sotto vive, sopra vive per costruzione — non serve
        un secondo campione per il lato che iOS non lascia testare pulito.
    [4] bordo destro di Q-Stage (pill attiva) → nessun log. PASS, nessuna regressione.
  **CAUSA REALE del primo fallimento (verificata a fonte, non il sospetto originario):**
  l'espansione dell'hit-area (pad→contentShape→pad-negativo) viveva FUORI dal `Button`,
  applicata al suo wrapper — il gesto riconosciuto dal `Button` copriva SOLO il contenuto
  interno (34pt), non il tappeto aggiunto fuori. Il `.clipShape` del container (sospettato
  #1 storico, §8 sotto) non è escluso come secondo strato possibile, ma il tocco moriva
  già prima di arrivarci.
  **FIX** (`RoomSwitchBar.swift`, simboli `segment`/`pill`): (1) l'espansione ora vive
  DENTRO la label del `Button` → il gesto copre davvero i 54pt reali; (2) il chrome del
  container (`segment`) non usa più `.clipShape` — reso via `.background` shape-fill
  (fill+stroke sulla stessa `RoundedRectangle`), eliminando ANCHE il sospettato #1 per
  costruzione, non perché scagionato da una prova diretta; (3) zero padding negativo
  residuo — il `Button` è alto 54pt reali, non più un layout-34-espanso-e-poi-contratto.
  Resa visiva bit-esatta invariata (stessa geometria, stessi colori — verificato via i
  conti dichiarati nel diff, non un'assunzione).
  **SBLOCCA S5** (CD-Q8, `.seg-mini`): la tecnica pad→contentShape-dentro-la-label è ora
  provata su device reale, non più solo in teoria. Resta comunque DIETRO Nodo A→S4→S4L
  nell'ordine SCALETTA sez.C — questo NON rende S5 il prossimo atomo (§13/§14).
  Diff ratificato: `S3_HITFIX_DIFF_2026-07-14.txt`, sha `8d34ffaf2c4365a5b816c69917aab0cf6bee7be82d5c32894770de8d1d53cfff`.
· **NODO A (spine navigazione) — 🟢 CHIUSO, device-validato 17/07** — N0 `a2fb816` / N1a `beb9e08` / N1b `152445e`, CI verdi, gate B+C+A-cheap PASS; shippato E1+E2. ⚠️ Caveat gate C + prereq bloccante S4 (uscite intra-`.qLive`) nel blocco «Supersede V95» in testa, punti (k)/(j). ⛔ NB V97: (k) è SUPERATO (a) — il prereq VERO di S4 è la proprietà del runner (S4L), NON uno stop sulla navigazione; (j) resta storia valida.
· S4 / S4L / S5 / S6 — non aperti.
· «CI-verde ≠ CHIUSO»: chiuso = solo dopo test su device confermato da Mauro. **S3 è il
  primo atomo di §6 a soddisfare questa condizione per intero.**
· Ordine numerico degli atomi: S0·S1·S2F·S2·S2b·S2c·S2e·S2d·**S3** = 9 atomi committati.
  Ripartizione ESATTA dello stato (evitando di appiattire S0 sugli altri): **S0** = 🟢 CHIUSO
  ma senza gate device (enum di token puri, niente a schermo) · **S1·S2F·S2·S2b·S2c·S2e·S2d**
  = 7 atomi 🟡 CI-verdi, NON device-chiusi · **S3** = 🟢 device-chiuso via gate reale (14/07).
  Quindi S3 è il primo atomo §6 a passare un GATE DEVICE; la validazione a schermo dei 7
  CI-verdi resta indiretta, solo per le porzioni che S3 monta (RoomSwitchBar/S1 come header
  Q-Stage; EmptyStateKit/S2d come badge/lineSpacing di Q13 — non per intero).

════════════════════════════════════════════════════════════════════
2) S2b + S2c — cosa è cambiato e perché
════════════════════════════════════════════════════════════════════
**S2b** (`8d7c7d1`): rework CD-Q9/CD-Q10 — colore CTA `--text3`→`--text2`, copy
N-agnostica per `NoPlayableSongsEmptyState`, `unavailableCount` rimosso dal template.

**S2c** (`9bb4ef6`): CORREZIONE DI UN ERRORE DEL REFEREE, non un secondo giro di
design. Il referee aveva ratificato S2b sulla PROSA di CD invece che sull'HTML del
freeze (riserva dichiarata e poi ignorata — violazione §7 da parte del referee, non
di CC). S2b aveva scritto la classe CSS `.cta.ghost` — nome SBAGLIATO. Il nome vero,
verificato ora a fonte nel freeze (`DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @
9994bc0`, selettore `.cta.quiet`), è **`.cta.quiet`**:
```
.cta.quiet{background:rgba(255,255,255,0.04); border:1px solid var(--line); color:var(--text2);}
```
S2c ha anche eliminato 17 riferimenti-a-riga verso il freeze e 2 sha256 incisi nel
codice sorgente (violazione della regola ANTI-CASCATA, sotto).

**VOCABOLARIO CD RATIFICATO** (necessario per ogni atomo successivo):
- `.dead` = disabilitato, `opacity:var(--disabled)` → es. `.startbtn.dead`.
- `.quiet` = navigazione secondaria ATTIVA, stile neutro solido → `.cta.quiet`
  ("Go to Q-Stage"). Verificato: **oggi in codice**, `QLiveEmptyStates.swift` (path
  attuale sotto `ios_app/QBeats/UI/QLive/`) `@ 6fca624`, selettore `.cta.quiet` (in
  `GoToQStageCTA`, rimasto in questo file dopo S2d).
- `.ghost` = CTA di CREAZIONE attiva, blu tratteggiato — usato per "Create in Songs",
  FUORI dal perimetro di questo freeze. Non confondere con `.quiet`.

**LEZIONE:** si cabla contro il CONTRATTO (l'HTML del freeze), mai contro una chat
o una prosa riassuntiva — anche quando la prosa viene dal referee.

════════════════════════════════════════════════════════════════════
3) DECISIONI CD — Q7–Q16, 10 VOCI (Q8 con riserva tecnica, le altre 9 RATIFICATE)
════════════════════════════════════════════════════════════════════
**Q7** — «+» OMESSO nell'header Q-Stage›Shows finché §8 (creazione show) non arriva.
Header Q-Stage = stesso componente `.roombar.center`/`.roomseg` di Q-Live, IDENTICO.
→ `RoomSwitchBar` non si tocca nel LAYOUT. La crepa `showsPlus:true` ipotizzata per la futura
scaletta Shows è MORTA: da non implementare.

**Q8** — hit-area di `.seg-mini` (navbar sotto-schermata, es. show detail) deve
essere ≥44pt anche se il chrome visibile resta 30pt. RATIFICATA nella sostanza.
⚠️ TECNICA PROPOSTA DA CD RESPINTA (`minHeight:44` sulla cella farebbe crescere
anche sfondo/bordo/clip → pill 44pt VISIBILI, che contraddice l'obiettivo di CD
stesso). Tecnica corretta = pad→contentShape (dentro la label, GATE-FIX 14/07) →
**PROVATA su device dal gate S3** (`ios_app/QBeats/UI/Components/RoomSwitchBar.swift`,
simbolo `pill`, variabile `hitExpansion`). 🔓 **SBLOCCATA dal gate device S3** (14/07):
non più gattata — la tecnica ristrutturata ha superato il gate su `.full`. Implementazione
su `.segMini` resta comunque lavoro di S5, dietro Nodo A→S4→S4L nell'ordine.

**Q9** — `.cta` ("Go to Q-Stage", Frame E) = navigazione ATTIVA, non disabilitata →
classe `.cta.quiet`, testo `--text2`. FATTO (S2b + correzione nome in S2c).

**Q10** — copy di `NoPlayableSongsEmptyState` resa N-agnostica (nessun ramo
singolare/plurale, l'app non è localizzata). FATTO (S2b).

**Q11** — `.sortbtn` DEFINITO: criteri **Name (A–Z)** [default] e **Concert date**;
bottom sheet «Sort shows», selezione singola + toggle Asc/Desc; default = Name A–Z
Ascending; `.sortbtn.active` colore ambra quando l'ordinamento corrente ≠ default.
**FATTO e CHIUSO device (S3, 14/07).**

**Q12** — copy plurale per Q-Stage Shows: contatore show `.cnt` → «1 show» / «{n}
shows» (incluso il caso «0 shows»); conteggio canzoni `.mt` → «1 song» / «{n}
songs»; suffisso « · {m} min» presente SOLO se durata > 0 — a durata 0 sparisce
ANCHE il separatore «·», non solo il numero. **FATTO (S3).** ⚠️ Punto per CD invariato
(§15 sotto): il conteggio songs include gli show orfani, la durata li esclude.

**Q13** — Q-Stage Shows a lista vuota (zero show): empty-state DEDICATO. Badge
`.eic.dim`; titolo «No shows yet»; corpo «Shows line up your songs for a gig, in
the order you'll play them.»; NESSUNA CTA (a differenza del Frame E di Q-Live);
`.searchrow` OMESSA; tab bar resta visibile; header count `.scrhead` resta
visibile e mostra «0 shows». **FATTO e CHIUSO device (S3, 14/07)** — badge e
lineSpacing verificati verbatim contro il contratto (resi 3/5, §8).

**Q14** — corretta una copy impossibile: la stringa "Shows without a date go last"
presupponeva show senza data. `Setlist.date` (verificato a fonte,
`ios_app/QBeats/Models/Setlist.swift`, simbolo `date`, tipo `Date` NON opzionale
— nessuna sentinella, `makeDefault()` valorizza sempre con `Date()`) rende
impossibile uno show senza data. Nuova copy per il criterio "Concert date":
«Chronological». **FATTO (S3).**

**Q15** — EREDITARIETÀ CONFERMATA: Q-Live SUBISCE l'ordinamento deciso in Q-Stage
in sola lettura — nessun `.sortbtn` in Q-Live. ⚠️ Questa regola era GIÀ scritta nel
tokbox `RoomSwitchBar` §1 del freeze originale e nessuno l'aveva letta fino ad ora.
Conseguenza architetturale: l'ordinamento DEVE vivere in uno stato CONDIVISO tra
Q-Stage e Q-Live, non locale a una singola schermata (vedi §4, S3-PRE). **FATTO (S3):
ordinamento in `QBeatsStore`, search resta locale (Q15 vincola solo l'ordine).**

**Q16** — l'ordinamento si RESETTA a ogni riavvio dell'app. Nessuna scrittura su
disco. Il pallino ambra su `.sortbtn.active` comunica «ordinamento di questa
sessione», non una promessa che persiste tra sessioni. **FATTO (S3).**

**STRINGHE VERBATIM DELLO SHEET** (contrattuali per S3): «Sort shows» ·
«Name (A–Z)» / «Alphabetical · default» · «Concert date» / «Chronological» ·
«Ascending» / «Descending».

════════════════════════════════════════════════════════════════════
4) RISULTATI S3-PRE (verificati a fonte all'epoca, ORA implementati e device-chiusi)
════════════════════════════════════════════════════════════════════
- `QBeatsStore` (`ios_app/QBeats/Store/QBeatsStore.swift`) è
  `@MainActor final class QBeatsStore: ObservableObject`, singleton `static let
  shared`, `private init() {}`. Q-Stage e Q-Live condividono la STESSA istanza per
  costruzione. `save()` (simbolo `save`, `async throws`) serializza a mano 3 array
  (`songs`, `setlists`, `backtracks`) chiamando `coordinatedWrite` tre volte, una
  per file. Una `@Published` che resta FUORI da `save()`/`load()` è quindi
  volatile per costruzione, non per convenzione.
  → **IMPLEMENTATO E DEVICE-CHIUSO (S3):** l'ordinamento vive in `QBeatsStore` come
    proprietà `@Published` VOLATILE, assente da `save()`/`load()`. Zero disco
    (coerente con Q16), zero passaggio da `AppRootView`. Q-Live lo rileggerà da
    `.shared` quando esisterà (coerente con Q15).
  → DEBITO DICHIARATO (non nascosto, invariato): tenere stato di presentazione
    (l'ordinamento di una lista) dentro uno store di dati persistenti è un lieve
    odore architetturale. Accettato: l'alternativa — un ViewModel condiviso
    dedicato — costa più superficie per un guadagno marginale a questa scala.
- Token per il sort sheet: **5 su 6** esistevano già in `QStageKit.swift` (path
  `ios_app/QBeats/UI/QStage/QStageKit.swift` — NON esiste un file `QStageTheme.swift`
  separato, la definizione vive dentro `QStageKit.swift`) — superficie/bordo/testo
  secondario/colore attivo/opacity disabilitato. Il gradiente di sfondo del foglio
  (`linear-gradient(180deg,#171d3c,#0f1329)`) è stato copiato INLINE nel componente
  del sort sheet (S3), NON promosso a token strutturale S0 (usato una sola volta;
  promuoverlo avrebbe riaperto il cancello S0, già chiuso).

════════════════════════════════════════════════════════════════════
5) S2e + S2d — cosa hanno chiuso (ENTRAMBI COMMITTATI, CI-verdi)
════════════════════════════════════════════════════════════════════
**S2e** (`7550476`) — allineamento commenti su `RoomSwitchBar`/`MetroFAB`/
`QLiveEmptyStates`. ZERO codice eseguibile (verificato a macchina: nessuna riga +/−
non-commento). Cosa ha chiuso:
· sha incisi (`b23dfc78…`) e riferimenti-a-riga verso il freeze → RIMOSSI (violavano R7);
  ora si cita il contratto vivo per selettore, `DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html
  @ 9994bc0`. Questo CHIUDE il "RESTA APERTO" dei commenti Swift che V90 segnalava nella
  sua sezione FREEZE (ora §11 qui).
· CD-Q7 e CD-Q8: i commenti dicevano ancora «APERTO PER CD» su domande RISOLTE → riscritti
  con la decisione ratificata.
· 🔴 IL GATE FALSO — la scoperta di S2e, contro-verificata a fonte (workflow adversariale
  2 agenti): `MetroFAB` e `QLiveEmptyStates` PROMETTEVANO «gate device S3». FALSO.
  `MetroFAB(onTap:)` è istanziato in UN SOLO posto (`NoShowsToPlayEmptyState`, Frame Ⓔ =
  Q-LIVE), e Q-Live non esiste fino a S4. L'unico empty-state che S3 monta è Q13 «No shows
  yet» (Q-STAGE), che per decisione CD NON ha MetroFAB. → Chi arrivava al gate S3 cercando
  l'ombra del MetroFAB non l'avrebbe trovata. Gate REALI ora scritti NEL CODICE: MetroFAB→S4 ·
  subview Ⓕ/Ⓖ→S4/S5 · componenti condivisi (layout/badge/icona Ⓔ)→S3 via Q13, dopo S2d.

**S2d** (`ab6b553`) — estrazione `EmptyStateLayout`/`EmptyIconBadge`/`NoShowsIconShape`
(tre struct, prima `private` in `QLiveEmptyStates.swift`) → nuovo file condiviso
`ios_app/QBeats/UI/Components/EmptyStateKit.swift`, visibilità `private`→`internal`.
MOVE PURO provato BYTE-ESATTO: 58 righe di codice rimosse da QLiveEmptyStates = 58 presenti
in EmptyStateKit (diff dei corpi vuoto, normalizzando `private`); zero codice aggiunto in
QLiveEmptyStates. Fiammifero CI verde (run `29202172911`, QB_DIAG_SPY spento), teardown a
3 prove (master invariato, solo i 2 file in stage, branch assente in `-a` e `-r`).
→ Q13 di Q-Stage ha riusato quei 3 blocchi (S3) senza dipendere da un file "QLive".
→ Debito emerso, registrato in BUGS v35 §1.3 `TD-emptystatekit-theme-dep` (🔵, pre-esistente):
  `EmptyStateLayout` usa `QStageTheme.text3` — un "condiviso" dipende da un tema di stanza.
  NON introdotto dal move (il colore c'era già a `7550476`).

⚠️ **TRAPPOLA CONFERMATA A FONTE (conservata da V90):** il freeze ha due glifi "3 linee
orizzontali" quasi identici ma DIVERSI, verificati byte-per-byte in
`DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0`:
- badge empty-state (selettore `.eic.dim`, usato 2 volte nel freeze): path
  `M4 6h16M4 12h16M4 18h9`, `stroke-width="1.7"` — questo è `NoShowsIconShape`
  in codice oggi.
- icona tab bar "Shows" (selettore `.tabbar .tb.on`, usata 2 volte): path
  `M4 6h16M4 12h16M4 18h10`, `stroke-width="1.8"` — NON ancora in codice. **CONFERMATO
  ancora vero al 14/07 (grep esaustivo `.swift` di tutto il repo): esiste UNA SOLA
  `struct NoShowsIconShape`; la variante h10 non è mai stata costruita.** La tab bar
  Q-Stage in S3 usa SF Symbols nativi (`systemImage:"rectangle.stack"`), NON questo
  glifo — la trappola è MUTA per S3 (§15 punto 2 per CD, invariato).
Differiscono di 1 solo carattere nel path (`h9` vs `h10`) e 0.1 nello stroke.
Chi implementasse la tab bar copiando/riusando `NoShowsIconShape` per risparmiare
userebbe il glifo sbagliato senza che nulla lo segnali (compila, gira, sembra
giusto). Vincolo per chi costruirà l'icona reale della tab bar Q-Stage (fuori
scope S3): NON riusare `NoShowsIconShape` — sono due Shape distinte per un motivo.
La nota è ANCHE nel codice, sul simbolo `NoShowsIconShape` in `EmptyStateKit.swift`.

════════════════════════════════════════════════════════════════════
6) TD#17 — stato REALE (V87 e l'handoff erano stale di sei settimane)
════════════════════════════════════════════════════════════════════
V87 e l'handoff 11/07 dicevano: «🚨 BLOCCANTE palco, fermo sull'acquisto dello
sniffer». Verificato ora in `BUGS_QBEATS.md` (voce "TD #17", aggiornata da ultimo
22/06): questo è **FALSO e superato da sei settimane**. Stato reale:
- TD#17 = 🟠 **OPEN MEDIA**, non più bloccante operativo.
- ROOT CAUSE CIRCOSCRITTA (device + sniffer, 22/06): non il roaming in generale —
  il router **H388X** specificamente non fa transitare il multicast di Ableton
  Link tra le sue due bande radio. Il **VR2800** (router usato dal vivo) è
  PULITO: cross-banda statico stabile 10+ minuti, confermato su device.
- Lo sniffer citato come "da comprare" era GIÀ COSTRUITO E VALIDATO da tempo
  (cattura eth0 cablata + IGMP join via `socat`).
- Durante un drop di peer, il Follower CONTINUA A SUONARE: free-run misurato a
  −11 ms su 16,6 s senza peer (inudibile). Il danno è SOLO FINALE — lo STOP del
  Direttore non si propaga al Follower, che finisce la sua setlist da solo
  (~1,5 s dopo) = desync di fine show, non un fermo del concerto.
- Re-join automatico osservato ≈10 minuti nel caso peggiore; uscire e rientrare
  dalla vista Direttore ri-forma il peer ALL'ISTANTE (device-confermato 11/06).

→ **Il referee è caduto in questo stesso errore l'11/07**: ha costruito
un'analisi intera su queste righe morte di V87/handoff, senza aprire
`BUGS_QBEATS.md` che aveva a disposizione — violazione §7 da parte del referee.
Segnalato qui perché è un pattern (vedi anche §2 sopra) che può ripetersi.

**`TD-peer-reconnect-button`** (bottone di riaggancio manuale in Q-Live) = voce
BUGS v34, commit `f2ce9cf`, pubblico e pushato 11/07 sera. GIÀ FATTO, ratificato
da Mauro — non riaprire. Il ticket, verificato ora a fonte, contiene GIÀ per
intero il fatto che il metronomo continua a suonare durante il drop e che lo
scopo del bottone è "ricucire PRIMA che arrivi lo STOP" — non manca nulla su
questo punto, nessuna aggiunta necessaria al prossimo tocco di BUGS.

════════════════════════════════════════════════════════════════════
7) REGOLA — due sessioni CC sullo stesso repository
════════════════════════════════════════════════════════════════════
L'11/07 un commit (`f2ce9cf`) è comparso sul repository da un'altra sessione CC
mentre una sessione diversa lavorava in parallelo. È stato individuato SOLO
perché quella sessione ha eseguito un `git fetch` esplicito invece di fidarsi
della cache locale — senza quel fetch, avrebbe scritto un documento di stato con
un HEAD dichiarato FALSO (indietro di un commit reale già pubblico).
Regola, da applicare sempre d'ora in poi:
1. ogni sessione CC apre dichiarando `git fetch` eseguito, poi HEAD locale e
   `origin/master` SEPARATAMENTE — mai un "HEAD" generico senza aver confrontato
   i due;
2. nessun commit va creato senza aver prima verificato che `origin/master` non
   sia già avanti rispetto al proprio HEAD locale;
3. un commit locale non ancora pushato è uno STATO SOSPESO: va dichiarato come
   tale in ogni handoff/BOX3, mai descritto come "fatto" finché non è su origin.

🔴 REGOLA — «PUSHATO ≠ PROPAGATO» (fratello di questa, alla CHIUSURA invece che
all'apertura). Scoperta 13/07: il commit `f2ce9cf` (BUGS v34, sessione parallela) aveva
pushato ma SALTATO la propagazione ai mirror E:. Git era a v34, ma tutti e 3 i target E:
(2 mirror vivi + snapshot numerato) fermi a v33, per un giorno intero, senza che nessuno
se ne accorgesse. La regola due-sessioni sopra copre `git fetch` all'APERTURA; questa copre
la propagazione alla CHIUSURA. Sei punti:
  1. un doc-commit NON è chiuso finché non è propagato a TUTTI i target (git + mirror vivi +
     snapshot numerato). «Pushato» ≠ «propagato».
  2. a fine doc-commit si dichiarano i target scritti CON sha256 di read-back (nel messaggio,
     mai inciso nel documento).
  3. in apertura: se git è più recente del mirror → SEGNALA, non proseguire in silenzio.
  4. LISTA-TARGET ESPLICITA per documento (registrata una volta): una sessione non deve
     INDOVINARE i target. BUGS = 2 mirror vivi (`BUGS_QBEATS\`, `CC MEMORIA\`) + snapshot
     numerato `BUGS_QBEATS<N>.md` + copia referee. LIBRO = 2 mirror (`CC MEMORIA\`,
     `LIBRO_MASTRO\`) + snapshot referee. **BOX3 = 2 mirror standing: `ARCHIVIO.MD\<data>\`
     (nel repo, gitignored, su C:) + `BOX3_Codice\` (su E:)** — esattamente come dichiarato
     in fondo a V94, verificato a fonte 14/07 (V94 esiste in ENTRAMBI). ⚠️ DISTINTO dal
     bundle referee: `REFEREE_SYNC_<data>\` NON è un terzo mirror standing di BOX3 — è un
     bundle di TRASPORTO datato e ad-hoc, assemblato SOLO quando si fa una sync col referee,
     che raccoglie insieme i documenti rilevanti a quella sync (verificato 14/07: esistono
     `REFEREE_SYNC_2026-07-12\` = freeze+BUGS35+LIBRO31 e `REFEREE_SYNC_2026-07-13\` =
     BOX3_V94+BOX5_V25+LIBRO33+SCALETTA — due date diverse, contenuti diversi = per-sessione,
     non un mirror continuo). Ci finisce una copia di BOX3 SE si fa il bundle per quella data,
     ma la sua assenza NON è un difetto di propagazione — i mirror standing restano 2.
  5. la fonte byte è `git show HEAD:<file>` (LF), MAI `cp` dal working tree (che è CRLF sotto
     `autocrlf`) — errore fatto in S2e, contenuto giusto ma forma/nome sbagliati.
  6. ancorare la fonte a HEAD, MAI a un commit storico: uno snapshot preso da un hash del
     passato può nascere già stale se qualcosa lo ha toccato dopo.
→ APPLICATA con successo al primo test reale (BUGS v35, `6fca624`): 4 file scritti da
  `git show HEAD:BUGS_QBEATS.md` risultati BYTE-IDENTICI al read-back (snapshot numerato +
  2 mirror vivi + copia referee), tutti LF, tutti v35; copia v34 del referee rimossa per non
  lasciare due file quasi identici. (Lo sha del read-back è stato dichiarato nel messaggio di
  consegna, NON inciso — R7.) ⚠️ **NON ANCORA riapplicata a questo doc-commit (V95/v34) —
  propagazione ai mirror è passo SEPARATO, successivo alla ratifica referee del diff (§14).**

════════════════════════════════════════════════════════════════════
8) REGISTRO RESI — tabella corretta e AGGIORNATA (S3 ha chiuso i resi 1/3/5)
════════════════════════════════════════════════════════════════════
| # | Reso | Componente | Si chiude a | Chiude a S3? | Stato 14/07 |
|---|------|-----------|-------------|--------------|-------------|
| 1 | hit-area pill 54pt (`.clipShape` potrebbe mangiare l'hit-test) | `RoomSwitchBar` | S3 | ✅ SÌ | 🟢 **CHIUSO SU DEVICE** — gate 4 tocchi, 14/07. Causa reale diversa dal sospetto (espansione fuori dal Button, non il clipShape) — vedi §1. |
| 2 | intensità ombra MetroFAB (fill 14% vs box-shadow opaco CSS) | `MetroFAB` | S4 | ❌ NO | invariato, apre a S4 |
| 3 | inner-shadow badge `.eic` (mask-su-strip 2pt) | `EmptyIconBadge` | S3 (dentro Q13) | ✅ SÌ | 🟢 **CHIUSO CONTRO CONTRATTO** (non su device — vedi scoperta 🔴3 in §12: fisicamente impercettibile a occhio, 1px @ 5% opacità. Verificato verbatim 14/07: presente, mascherato SOLO in cima, valori esatti) |
| 4 | gradiente 150°→UnitPoint (approssimazione dichiarata) | `QLiveEmptyStates` (Frame G) | S4/S5 | ❌ NO | invariato, apre a S4/S5 |
| 5 | `.lineSpacing` derivato da metrici hhea | `EmptyStateLayout` | S3 (dentro Q13) | ✅ SÌ | 🟢 **CHIUSO CONTRO CONTRATTO** (non su device — stesso motivo del reso 3: impercettibile a occhio. Verificato verbatim 14/07: `lineSpacing(3.08)`, derivazione da hhea reale del font, limite dichiarato onestamente) |
| 6 | punto esclamativo, segmento 0.5pt degenere | `WarningMarkShape` | S4/S5 | ❌ NO | invariato, apre a S4/S5 |
| 7 | pinning MetroFAB (richiede container ad altezza esplicita) | — (vincolo di integrazione) | vincolo S4 | categoria diversa, mai un gate visivo | invariato |

**Chiusura S3: resi 1, 3, 5 — TUTTI E 3 chiusi il 14/07.** I resi 2, 4, 6 restano
ciechi fino a S4/S5, cioè DOPO il Nodo A. Il reso 7 resta un vincolo di integrazione,
non un gate visivo, né aperto né chiuso da S3.

⚠️ **RICLASSIFICAZIONE (scoperta 🔴3, 14/07 — vedi §12):** i resi 1, 3, 5 NON erano
tutti della stessa natura, anche se il registro li trattava allo stesso modo fino ad
oggi. Il reso 1 (hit-area) È device-testabile (un dito tocca o non tocca). I resi 3 e 5
(inner-shadow 1px@5%, lineSpacing 3.08pt) NON lo sono per costruzione — impercettibili
a occhio nudo, non importa quanto attentamente si guardi lo schermo. Metterli in un
gate visivo insieme al reso 1 costruiva un test che per 2 resi su 3 non poteva né
passare né fallire. Sono stati chiusi correttamente, ma per la via giusta (verbatim
codice↔contratto, richiesta esplicita 14/07), non per quella originariamente prevista
(occhio nudo sul device). **Prima di S4/S5, i resi 2/4/6 vanno passati allo stesso
vaglio "device-testabile sì/no" — non darlo per scontato.**

════════════════════════════════════════════════════════════════════
9) PUNTATORI ROTTI DI V87 — corretti
════════════════════════════════════════════════════════════════════
- V87 citava il piano Nodo A al commit `4571e68` — verificato: quella è la
  versione SENZA l'emendamento E1 (N1b da 2 file, non 3). Il piano con E1
  applicato vive a `HANDOFF/NODO_A_PIANO_2026-07-10.md @ cd02280`. Da qui in
  avanti si cita quello; `4571e68` resta solo come nota storica ("prima
  dell'emendamento E1").
- §«APERTO PER CD» di V87 (storico): la formula "girato a LIBRO" era FALSA per
  CD-Q9/CD-Q10 al tempo di V87/V89 — CD-Q9...CD-Q16 non erano mai entrate in LIBRO.
  **CHIUSO ora**: LIBRO v30 (commit `04df53a`, CI verde) ha registrato Q7 e
  Q9-Q16 in Sez.2 e marcato CD-Q7/CD-Q8 come RISOLTE con audit trail in Sez.4.
  Nessuna lacuna residua su questo punto.
- Il vecchio "Reso #6" di V87 citava `QLiveEmptyStates.swift:283` per la nota
  di risoluzione di CD-Q10; verificato ora: quella riga oggi è un commento
  (`// MARK: - Ⓖ NO PLAYABLE SONGS`), il contenuto sostanziale (nota "CD-Q10
  RISOLTA") vive a `:286-292`. Le righe sono cambiate ancora con S2b/S2c — non
  copiare mai un numero di riga da un documento precedente, rileggere a fonte.
- La "REGOLA ANTI-CASCATA" era marcata "da ratificare in LIBRO" da DUE versioni
  (V87, V89) senza essere mai eseguita. **CHIUSO ora**: ratificata come **R7** in
  LIBRO v31 (commit `e9d7754`, CI verde), in "Protocollo di ingaggio" accanto a
  R5/R6 (sha256-solo-trasporto · versione-bump obbligatorio · simbolo-prima-della-riga).
  Non più "in corso": committata cross-team.
- (Il vecchio "SCALETTA_ATOMI_S6 è stale/pericolosa" di V90-V92 è CHIUSO: la scaletta è
  stata riscritta e ratificata — §10.)

════════════════════════════════════════════════════════════════════
10) SCALETTA_ATOMI_S6 — RISCRITTA (S3) e RATIFICATA dal referee (13/07)
════════════════════════════════════════════════════════════════════
`SCALETTA_ATOMI_S6_2026-07-10.md` (in `HANDOFF/`, mirror E:) è stata RISCRITTA il 12/07
dal contratto ratificato (§3 e §4 di questo BOX3): rimossi il «+» morto (vietato da CD-Q7)
e la prop inesistente `showsPlus` che la versione precedente prescriveva. RATIFICATA dal
referee il 13/07. Ora è versionata internamente («Versione: 1 (12/07/2026)»). S3 è stato
guidato da questa scaletta ed è ORA CHIUSO (§1). Le ancore-codice di S3 erano state
verificate a HEAD `6fca624` per simbolo (R7): `QStageRootView.onExit`, `RoomSwitchBar`
(props reali `active`/`onHome`/`variant`/`onSwitch`, niente `showsPlus`), `Setlist.name/
date/songIDs`, `QBeatsStore.setlists`/`resolve().missingIDs`/`estimatedDuration(for:)`,
`EmptyStateKit`.
⚠️ Verificate SOLO le ancore di ⟦S3⟧ (ora chiuse dai fatti). Quelle di ⟦NODO A⟧/⟦S4⟧/
⟦S4L⟧/⟦S5⟧ restano NON verificate e stale (SCALETTA sez. F) — debito invariato, §14,
BLOCCANTE prima del NODO A.

════════════════════════════════════════════════════════════════════
11) FREEZE — IN GIT, CHIUSO (commit `9994bc0`, 11/07 sera)
════════════════════════════════════════════════════════════════════
7 file totali in `DESIGN/QLive_Nav/ @ 9994bc0`, verificati ora per nome ed
estensione: **5 file `.html`** — standalone (predecessore storico) · base 09/07 ·
+Q7-Q10 · +Q7-Q13 · +Q7-Q16 (CONTRATTO VIVO, quello citato in tutto questo
documento) — **+ 2 file `.md`** — `README.md` · handoff CD Q7-Q10
(`HANDOFF_CD_QLIVE_NAV_Q7-Q10_11_07_2026.md`).

**Identità riconciliata** (verificata ora, byte-per-byte sulle regole CSS
condivise): il file "standalone" e il file "base" (`2026-07-09_base...html`)
condividono lo stesso `<title>` dichiarato e le stesse regole CSS su
`.roombar`/`.homebtn`/`.roomseg`/`.metrofab`, identiche byte-per-byte. **NON
sono lo stesso file** — sono due file DISTINTI che condividono la parte
rilevante per `RoomSwitchBar`/`MetroFAB`. Non semplificare mai questa
precisazione in "sono lo stesso documento": è imprecisa.

Il file `.txt` decodificato usato dal referee durante la sessione di lavoro
resta un artefatto di trasporto del referee, non un documento versionato in
`DESIGN/` e non parte del contratto — non citarlo come fonte.

Citazione canonica per ogni contenuto del freeze da qui in avanti: `selettore
CSS/HTML` + `DESIGN/QLive_Nav/<nomefile>.html @ 9994bc0` (esempio già usato
sopra: `.cta.quiet`, `DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0`).

✅ **CHIUSO da S2e (`7550476`):** i commenti dentro `QLiveEmptyStates.swift`,
`RoomSwitchBar.swift`, `MetroFAB.swift` sono stati aggiornati — citano il contratto vivo
per selettore + `DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0`, con sha incisi e
riferimenti-a-riga verso il freeze RIMOSSI.

════════════════════════════════════════════════════════════════════
12) REGOLE DI PROCESSO ATTIVE (tutte, per intero — nessun rimando a V87)
════════════════════════════════════════════════════════════════════
✅ Le 3 regole ANTI-CASCATA sotto sono ratificate come **R7** in LIBRO v31
(`e9d7754`, CI verde), "Protocollo di ingaggio" accanto a R5/R6. Restano il testo
di riferimento operativo qui per CC/BOX3.

**ANTI-CASCATA** — lo sha256 si usa SOLO come checksum di trasporto, nel
messaggio di consegna, usa-e-getta. Non si scrivono sha256 come puntatori
persistenti dentro i documenti: ogni edit successivo invalida i puntatori altrui
e genera una cascata di correzioni manuali. ORIGINE (conservata da V94, onestà
epistemica): resoconto da una nota di memoria persistente dell'11/07/2026 — **un
racconto, NON una misura verificabile a strumento** — circa 4 ore spese per
rimuovere UNA riga di codice, 3 puntatori morti scoperti a catena. È il PERCHÉ
della regola; la cifra «4 ore» è aneddotica, non cronometrata. File TRACCIATO in
git → si cita per path + commit (`file @ sha-commit`). File UNTRACKED (BOX3,
mirror E:) → sha256 nel messaggio di consegna, mai inciso in un altro documento.

**ANTI-CASCATA-2** — il numero di versione di un documento untracked (es. BOX3
V-N) è un puntatore. Se il contenuto cambia, il numero DEVE cambiare. Un V-N
riscritto senza bump è peggio di uno sha morto: lo sha morto è visibilmente
rotto, il V-N riscritto sembra sano mentre non lo è.

**ANTI-CASCATA-3** — un riferimento a riga di codice è un puntatore che FALLISCE IN
SILENZIO. Conseguenza operativa: (a) ogni riferimento a codice va scritto come
`file:riga @ commit`, mai solo `file:riga`; (b) nei documenti di stato si cita
PRIMA il SIMBOLO, POI la riga.

**ULTIMO-BLOCCO** (nuova, 14/07/2026 — 2° fallimento su 2 di BOX3 nella riga in cui parla
di sé) — l'ULTIMO blocco di un documento (auto-riferimento, mirror di consegna, stato del
file) va RILETTO DOPO che il documento è finito e PRIMA di propagarlo, MAI scritto una volta
sola mentre si lavora. Un auto-riferimento è vero mentre scrivi e diventa falso appena il file
è in posizione: «QUESTO BOX3 V91» dentro il file V92 (corretto in V94) · «STATO: PROPOSTA/
DRAFT, NON ANCORA IN BOX3_Codice» dentro il V95 che È in BOX3_Codice (corretto su rilievo
referee, questo giro). Due volte, stesso punto (la coda), stesso meccanismo. Corollario
operativo: un documento non contiene MAI il proprio hash né una descrizione di sé che la
propagazione rende falsa — quei dati vivono nel messaggio di consegna (R7), non nel file.

**CHECKLIST TOKEN** (dal 11/07/2026, su ogni atomo UI) — ogni atomo UI consegna
una TABELLA, non prosa: una riga per ogni proprietà CSS di ogni classe del
freeze coinvolta, con la riga Swift che la implementa o "N/A" + motivo esplicito.
Applicata a S3 (`S3_CHECKLIST_TOKEN_2026-07-13.txt` — conteggi VERIFICATI a fonte
14/07: 242 righe, 43 blocchi-selettore, 176 proprietà mappate a Swift, 15 «N/A»+
motivo. NB: il «93 selettori» citato nell'handoff sera NON corrisponde a nulla di
contabile nel file consegnato — si riferiva all'estrazione del referee dal freeze,
non ri-verificabile da qui; sostituito coi conteggi reali). ⚠️ **Riconferma 14/07:**
questa checklist è lo strumento
GIUSTO per i resi 3/5 (impercettibili a occhio) — vedi scoperta 🔴3 sotto. Il
registro-resi-da-gate-visivo (§8) li aveva classificati male; la checklist
token no.

**BRANCH FIAMMIFERO** (dal 11/07/2026, su ogni atomo UI) — prima della ratifica
definitiva di un atomo: branch usa-e-getta (mai master) → commit locale al
branch → push → `workflow_dispatch` con `diag_flags` vuoto (QB_DIAG_SPY deve
restare spento) → attendi l'esito reale di compilazione → smontaggio completo
(torna a master, recupera solo il file verificato, elimina il branch sia
locale che remoto) → 3 prove verbatim (master invariato al commit di partenza,
solo il file atteso in stage, branch assente sia in `git branch -a` che in
`git branch -r`). Richiede AUTORIZZAZIONE ESPLICITA di Mauro prima di ogni uso.
**TRACK RECORD 14/07 — usato 2 volte in un solo giorno, PRIMO ciclo completo
reale:** (1) gate S3 iniziale → FALLITO su device → branch NON cancellato
(correzione in corso, come da regola "non cancellare finché non ri-testato");
(2) hitfix committato sullo STESSO branch (`c77d69f` su `bench/s3-gate`) → build
verde → RI-gate → PASSATO → fast-forward su master (stesso sha, zero merge-commit,
verificato `merge-base --is-ancestor`) → branch cancellato locale+remoto. Il
meccanismo ha retto al primo vero stress-test (un fallimento + una correzione +
un successo, tutto sullo stesso ramo fiammifero prima di toccare master).

**SCOPERTE GATE S3 (14/07)** — 5 lezioni operative emerse dal primo ciclo
completo di gate device, 3 delle quali correggono assunti tenuti per giorni:

🔴 1. **`.buttonStyle(.plain)` NON toglie il dimming al press — toglie SOLO il
tint.** Mauro ha VISTO il dimming visivo sul device al tocco [1] (centro
Q-Live). Il commento in `MetroFAB.swift:33` («niente tint/dim di default
SwiftUI») è IMPRECISO — dice "dim" ma il comportamento reale nega solo il
tint; il dimming è comportamento nativo di `Button`, non disattivato da
`.buttonStyle(.plain)`. Da correggere al prossimo tocco di quel file.
**Conseguenza di processo:** ai gate device futuri, il feedback visivo
(dimming nativo) può bastare come sonda — la sonda `os_log` non è sempre
obbligatoria quando il componente ha già un feedback osservabile a occhio.

🔴 2. **`gh` CLI È DISPONIBILE** (autenticato `19Bullfrog78`, via shim di
plugin) **e il repo è pubblico.** L'assunto opposto — "gh assente, il referee
non può vedere la CI" — ha guidato il processo per giorni, MAI verificato da
nessuno, falso su entrambi i fronti. Il referee ha letto la run del build #564
direttamente da GitHub. **Correzione di processo (già applicata, vedi LIBRO
v34 Sez.1):** niente più "verifica tu su GitHub" — CC lancia/verifica le build
da sé (`gh workflow run` / `gh run view`). Applicato in questa sessione: build
gate-fix (run `29323928708`) e build post-merge master (run `29337966104`)
lanciate e verificate da CC senza intervento manuale di Mauro.

🔴 3. **NON TUTTI I RESI VISIVI SONO DEVICE-VALIDABILI.** I resi 3 (inner-shadow
`.eic`, 1px @ 5% opacità) e 5 (lineSpacing 3.08pt) sono fisicamente
impercettibili a occhio nudo — metterli in un gate visivo costruiva un test
che non può né passare né fallire, stesso vizio di forma del gate hit-area con
sonda muta (meccanismo diverso, stesso errore: un test che non discrimina).
Sono TOKEN da verificare CONTRO IL CONTRATTO (confronto verbatim codice↔freeze,
fatto 14/07 su richiesta esplicita), non resi da provare col dito. La
CHECKLIST TOKEN (sopra) li avrebbe presi correttamente fin dall'inizio — è
uno strumento più adatto del gate visivo per questa classe di resi. **Azione
per S4/S5 (§14):** passare i resi residui (2, 4, 6 — §8) al vaglio
"device-testabile sì/no" PRIMA di costruire il prossimo gate, non darlo per
scontato come è successo qui.

🟡 4. **iOS INTERCETTA I TOCCHI VICINO AL BORDO ALTO DELLO SCHERMO** (fascia di
sistema). Il tocco [2] del gate (8-10pt sopra il bordo Q-Live) non è risultato
testabile pulito per questo motivo — non un difetto dell'app. Area utile reale
dell'hit-area ≈44pt (34 visibili + 10 sotto) invece dei 54pt disegnati:
ESATTAMENTE il minimo HIG Apple, conforme ma senza margine. L'entità dipende
da quanto in alto sta la barra sullo schermo (posizione = dominio layout/CD).
→ CD ne è informato, nuovo punto §15.

🔴 5. **PROPOSTA, NON ANCORA IMPLEMENTATA** — ogni build per gate device
logghi all'avvio il commit SHA da cui è costruita (una riga di codice, es.
`os_log` in avvio app). Elimina una classe intera di errori: testare per
sbaglio una IPA vecchia produce un falso negativo indistinguibile da un fix
fallito. Non implementato in questo giro (fuori scope del fix hit-area) — da
valutare al prossimo atomo che richiede un gate device (Nodo A o S4).

════════════════════════════════════════════════════════════════════
13) PROSSIMI STEP
════════════════════════════════════════════════════════════════════
**S3 e il suo gate device sono FATTI** (§1). Da qui:
1. **NODO A — 🟢 FATTO (device-validato 17/07: N0 `a2fb816` / N1a `beb9e08` / N1b
   `152445e`, E1+E2).** I 2 prerequisiti propri (AudioEngine source-read +
   riconciliazione piano) sono assolti, piano emendato E1+E2. **Prossimo atomo
   reale = S4** (Q-Live›Shows). Ordine: NODO A ✅ → **S4** → S4L → S5 → S6.
   ⛔ SUPERATO da V97 (a) — CD 18/07: navigazione ≠ transport, NESSUNO stop sulla navigazione interna. NON eseguire quanto segue. Il prereq VERO di S4 è ora la proprietà del runner (V97 (a)), e atterra in S4L. ↓
   🚨 **PREREQUISITO BLOCCANTE DI S4** (Supersede V95 punto (k)): progettare DENTRO
   S4 lo stop-audio per le uscite intra-`.qLive` (metronomo → lista/dettaglio,
   `screen` invariato) — `onChange(of: screen)` è cieco a quel percorso e la rete
   `.onDisappear` è stata rimossa (E1). Stop al punto di mutazione della navigazione
   INTERNA, deterministico; NON resuscitare `.onDisappear` (posta band-stop, punto (j)).
2. **Bonifica ancore-codice atomi futuri** — ⟦NODO A⟧, ⟦S4⟧, ⟦S4L⟧, ⟦S5⟧ contengono
   riferimenti a riga NUDI (senza `@ commit`), ereditati da `fa64832` (20 commit fa,
   verificato ORA `git rev-list --count fa64832..HEAD` = 20 — NB: V94 diceva «~14», stima
   mai verificata a fonte; il numero reale è 20) — vedi SCALETTA sez. F. Da riscrivere per
   SIMBOLO + `@ commit` (R7 punto 3).
   BLOCCANTE prima del NODO A (tocca l'audio-stop: un puntatore muto lì è il
   posto peggiore in cui lasciarlo).
3. **S5** (`.seg-mini`, CD-Q8) — tecnica hit-area PROVATA su device (14/07), ma
   resta DIETRO Nodo A→S4→S4L nell'ordine sopra. Non è il prossimo atomo:
   "sbloccato" = il rischio tecnico è sciolto, non che salti la coda.
4. **Pulizia worktree `qb_fixB`** — il trigger dichiarato in V92/V93/V94 ("dopo
   il gate device S3") è ORA soddisfatto. Rimozione NON eseguita in questo
   doc-commit (fuori dai passi eseguiti oggi) — pronta per essere fatta al
   prossimo turno, previa conferma.
5. **Debito scaleFactor iPad** — invariato (§14). Bloccante SOLO prima di
   qualunque test/rilascio su iPad reale, non prima.
6. **Proposta commit-SHA-at-boot** (scoperta 🔴5, §12) — da valutare per il
   prossimo atomo che richiede un gate device.

════════════════════════════════════════════════════════════════════
14) DEBITI APERTI — REGISTRO CONSOLIDATO (nuovo in V95, era sparso)
════════════════════════════════════════════════════════════════════
🔴 **BLOCCANTE prima del NODO A:** ancore-codice nude in ⟦NODO A⟧/⟦S4⟧/⟦S4L⟧/⟦S5⟧
   (SCALETTA sez.F) — punto 2, §13.

**NON bloccante, da tracciare:**
· **B1 — branch non-merged: 12** (verificato ora, `git branch -a`), invariato
  rispetto a prima della creazione di `bench/s3-gate` — il branch fiammifero si
  è auto-risolto per costruzione (fast-forward + cancellazione, §12) e non lascia
  residuo nel conteggio. I 12 storici (11 feat/fix + `test/bug2b-test7-fixtures`,
  worktree `qb_fixB`) restano debito di triage per-branch, MAI alla cieca.
· **Worktree `qb_fixB`** (`C:\Users\BULLFROG\qb_fixB`, branch
  `test/bug2b-test7-fixtures @ add556f`) — trigger di rimozione soddisfatto
  (punto 4, §13), rimozione non ancora eseguita.
· **SCALETTA_ATOMI_S6 — DUE copie omonime divergenti su E: [V97 (g)]:** v2 corretta
  (Versione 2, NODO A 🟢) in `FILE X CLAUDE.MD/HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`;
  v1 STALE (Versione 1, 12/07) in `.../HANDOFF/REFEREE_SYNC_2026-07-13/SCALETTA_ATOMI_S6_
  2026-07-10.md`; ZERO copie in git → trappola per nome-file. Cancellazione v1 = azione
  manuale Mauro. Regime doppia-copia C:+E: (come BOX3/BOX5) da decidere (ratifica referee).
  ⚠️ Al prossimo giro doc la SCALETTA va anche RISCRITTA per S4L (V97 (e)).
· **4 file memoria CC — ora incastonati qui, possono uscire dall'elenco "orfani":**
  la sostanza di `project_qbeats_td1_tre_doc_disaccordo.md`,
  `project_qbeats_tabbar_sf_symbols_vs_freeze.md`,
  `project_qbeats_import_setlist_name_no_validation.md` e
  `feedback_qbeats_gate_device_branch_fiammifero.md` vive ora in questo
  documento (rispettivamente: sotto in questo elenco; §15 punto 2; sotto in
  questo elenco; §12 BRANCH FIAMMIFERO). Il tetto memoria CC resta un vincolo
  separato (sotto) — incastonare qui non libera automaticamente byte in
  memoria, ma toglie l'urgenza di indicizzarli.
  - **TD-1 (tre documenti in disaccordo):** Costituzione V5:80 dà TD-1 APERTO e
    vieta `SongSection`, ma il rename È FATTO (`ef03006`) e il codice lo usa
    ovunque. La Costituzione è smentita dal codebase su questo punto specifico.
    Zero impatto operativo: la regola "qualifica sempre `SwiftUI.Section`" resta
    valida e applicata ovunque. Da riconciliare alla prossima revisione della
    Costituzione, non urgente.
  - **TD import non valida i nomi setlist** (`QBeatsBackupManager.swift:233`,
    funzione `addSetlist`): un archivio importato può portare un
    `Setlist.name` vuoto (la creazione normale via `makeDefault()` non può). Il
    fallback UI "Untitled show" (S3, `ShowsListView.swift:223`) copre il caso
    a schermo; la validazione a monte resta un debito separato, copy dominio CD.
· **TETTO MEMORIA CC** — invariato dalla sessione precedente (54 byte liberi su
  17510). Chi riprende: NON consolidare/tagliare in silenzio, fermarsi e
  chiedere a Mauro. Criterio: aperto+palco > chiuso+device-validato.
· **BOX5 non-autoportante — RICONCILIATO 14/07 (criteri dichiarati; le stime
  precedenti NON sono comparabili — vedi sotto):** verificato ORA leggendo le 8 righe UNA PER UNA (non
  solo `grep -c`) su `BOX5_V25_2026-07-13.md` — **8 sezioni totali** usano il
  placeholder `(invariato da V22)` invece di contenere il proprio testo (righe
  79, 85, 91, 97, 103, 327, 335, 341). Ripartizione ESATTA delle 8:
    - **2 con rimando esplicito a dove leggere il testo omesso** («vedi …»):
      riga 79 → `ARCHIVIO.MD/12_05_2026/BOX5_V22...`; riga 327 → «vedi BOX5 V22
      sezione "Specifica vincolante L1.b"».
    - **5 letteralmente nude**, solo «(invariato da V22)»: righe 85, 91, 97,
      103, 335.
    - **1 con annotazione di stato ma SENZA puntatore a dove leggere** (riga
      341: «(invariato da V22, Task D chiuso V53)» — «Task D chiuso V53» è una
      nota di stato, non un "vai a vedere lì il contenuto").
  Quindi: **8 totali · 2 con puntatore-dove-leggere · 6 senza** (5 nude + la 341
  con solo nota di stato).
  ⚠️ Le stime precedenti NON sono direttamente comparabili: usavano criteri diversi, e il
  fatto che due diano «6» è una COINCIDENZA di cardinale, non un accordo.
   · CC «8» = totale placeholder (criterio: presenza di «(invariato da V22)»).
   · Referee «6» = insieme DIVERSO: includeva r.79 (Modello dati, che HA un puntatore) ed
     escludeva r.341 (Task D) — criterio «il corpo è solo la parentesi», applicato in modo
     incoerente.
   · Referee «~13» = sovrastima a memoria, mai verificata.
  VALE LA TASSONOMIA QUI SOPRA (8 · 2 con puntatore · 6 senza), unica con criterio coerente
  e verificata a fonte riga per riga. (Nota di metodo: qui si sono dichiarati i CRITERI, non
  fatti combaciare i numeri — è l'errore che questa stessa lezione doveva prevenire, ed era
  scattato nella mia prima stesura della riconciliazione, corretto su rilievo del referee.)
  Il pattern resta vero in ogni lettura: BOX5
  non è autoportante, viola la regola che BOX3 rispetta. Non risolto qui
  (fuori scope di un doc-commit BOX3/LIBRO), da pianificare come piccolo atomo
  doc-only dedicato.
· **2 rilievi checklist token** (documentali, NON toccano codice — dettaglio
  completo in `S3_CHECKLIST_TOKEN_2026-07-13.txt`, non riaperto qui):
  `.showrow .tx {min-width:0}` (freeze riga 227) manca come riga a sé nella
  checklist (il codice ce l'ha, nessun bug reale) · la checklist a riga 179
  cita `.opt-row.sel .n`, il selettore vero è `.opt-row.sel .ol .n`.
· **2 rilievi sull'handoff CC del 13/07 sera** (`HANDOFF_CC_2026-07-13_sera.txt`,
  NON modificato — resta come registro storico accurato del momento in cui fu
  scritto, la correzione vive qui): dichiarava "2 resi visivi" mentre il totale
  corretto è 3 (hit-area + inner-shadow + lineSpacing, §8); citava "BOX3 V92
  §8" mentre il contenuto viveva già in V94 (regola nascita/residenza).
· **Ancore-codice nude NODO A/S4/S4L/S5** — vedi 🔴 bloccante in cima a questa
  sezione.
· **Debito scaleFactor iPad** — `QStageRootView` senza `GeometryReader`/
  `scaleFactor` alla radice; gli atomi §6 committati con `.font` usano pt
  FISSI: `RoomSwitchBar` (S1/S3), `QLiveEmptyStates` (S2/S2b/S2c),
  `EmptyStateKit` (S2d/S3). BOX5 impone iPhone+iPad portrait come requisito v1
  ATTIVO. Da chiudere PRIMA di qualunque test/rilascio su iPad reale. Non
  bloccava S3, non lo aggrava.

════════════════════════════════════════════════════════════════════
15) 5 COSE PER CD (4 invariate + 1 nuova dal gate S3)
════════════════════════════════════════════════════════════════════
1. **Chevron:** il freeze si contraddice (Frame① :389 CON `<svg>` · sort-sheet
   :610 SENZA). S3 ha scelto SENZA (CD-Q7 + CD-Q14, card non interattive, editing
   §8 differito). Quale variante è quella giusta a regime?
2. **Tab-bar:** SF Symbols nativi o glifi custom del freeze? S3 usa SF Symbols
   (`systemImage:"rectangle.stack"`), pre-esistente, non un reso S3. Il glifo
   h10 del freeze (icona "Shows" custom) è un asset ORFANO — mai costruito, la
   trappola dei due glifi (§5) resta muta finché non lo si costruisce.
3. **Copy inventate da CC**, entrambe fuori dal freeze, da ratificare: 9°
   «No shows match your search.» (search senza risultati, show esistenti) ·
   10° «Untitled show» (fallback nome vuoto via import, §14).
4. **Conteggio songs (orfani INCLUSI) vs durata (orfani ESCLUSI):** «8 songs ·
   21 min» quando 2 delle 8 sono orfane (canzoni rimosse dal catalogo ma ancora
   referenziate nello show). Coerente così, o va annotato/reso esplicito a
   schermo?
5. **[NUOVO, dal gate S3 14/07] Fascia di sistema iOS sul bordo alto:** l'area
   utile reale dell'header (dove i tocchi arrivano puliti) è ≈44pt invece dei
   54pt disegnati, perché iOS intercetta i tocchi vicino al bordo superiore
   dello schermo (scoperta 🟡4, §12). Conforme al minimo HIG (44pt) ma senza
   margine. L'entità dipende da quanto in alto sta la barra — se CD ha in
   mente varianti di layout con la barra ancora più in alto, ne va tenuto conto.

Mirror di consegna di QUESTO BOX3 V99 — regime ratificato 21/07 (LIBRO v39, Sez.2 riga
2026-07-21; spec in BOX5 V27). **BOX3 è TRACCIATO:** `BOX3_QBEATS.md` vive in root del repo, ha
`-text` in `.gitattributes` (disco = blob al byte) e si modifica IN PLACE — niente un file nuovo
per versione, le versioni precedenti stanno nella storia git.
Propagazione a E: = una **STAMPA** col nome per-versione ancorato al commit **INTRODUTTIVO** (forma
`BOX3_V99_2026-07-22_<commit>.md`, in `FILE X CLAUDE.MD\BOX3_Codice\`), estratta con `git show` dal
blob e verificabile contro di esso. Stessa regola per la copia caricata nel Progetto Claude: nome
per-versione, **MAI nome fisso** (V98 (f)) — e vale a maggior ragione dopo V99 (e), perché il
Progetto e la copia-file letta dal referee possono divergere in ENTRAMBE le direzioni.

**STATO DI QUESTO FILE:** V99 canonica corrente. Il read-back sha256 dei target si dichiara nel
MESSAGGIO di consegna, NON inciso qui (R7 punto 1: sha256 = trasporto, mai puntatore persistente in
un documento) — e un'impronta prova la CORRISPONDENZA fra due copie, non la COMPLETEZZA di ciò che
è stato propagato (V98 (i)).
