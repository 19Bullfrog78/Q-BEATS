# CONGEDO CC — 2026-08-18

Da: CC · A: chi apre la chat CC successiva, + referee + Mauro
Sessione: mandati **A90 → A101**, tutti in giornata. Rientro dalla pausa 07/08→18/08.
Scritto alla cieca, senza leggere il congedo del referee — come dispone A101.

Marcatura: **[M]** misurato in questa sessione · **[R]** riportato da altri, non rimisurato da me ·
**[A]** assunzione o giudizio mio.

---

## PARTE MECCANICA

### 1. HEAD e albero

**[M]** HEAD locale = HEAD remoto = **`44fea3e378414c300ffd50fcac527c683740735b`**
(`git rev-parse HEAD` e `git ls-remote origin master`, non `rev-parse origin/master`).
Albero pulito sui tracciati: **sì** — `git status --porcelain=v1 | grep -vc '^??'` → **0**.

### 2. I due workflow, per nome

**[M]**

| workflow | run id | esito | data |
|---|---|---|---|
| **`iOS Signed Build`** | `32148440889` | **success** | 2026-08-18T14:27:32Z |
| **`F1 — Build Check (zero errors, zero warnings)`** | `30639169986` | **failure** | 2026-07-31T14:34:28Z |
| `F1 — Build Check` (penultima) | `30638276963` | **failure** | 2026-07-31T14:21:52Z |

⛔ **F1 non gira dal 31/07 e le sue ultime due run sono entrambe fallite.** È
`workflow_dispatch`, manuale: non parte da sola. ⚠️ **«CI verde» in questo progetto significa
sempre e solo `iOS Signed Build`** — un terzo workflow esiste (`Build LinkHut Diagnostic`, ultima
run `26290451025` del 22/05, success) ma non tocca l'app.

### 3. Impronte dei cinque canonici a HEAD

**[M]** Estratte con `git show 44fea3e:<path>`, **mai da disco**. CR contati sui byte (`tr -cd '\r' | wc -c`),
mai con `grep` — la forma `grep -c $'\r'` è un falso-positivo noto, censita in `LIBRO:352`.

| canonico | sha256 (blob) | byte | righe | CR |
|---|---|---:|---:|---:|
| `LIBRO_MASTRO_QBEATS.md` | `59c1fd73b431c04f6b289178999d6feb92231b171e5ce276af0ca199b4072722` | 275 470 | 518 | 0 |
| `BUGS_QBEATS.md` | `64f7df0927448915f2913e0281aeb0be3b96a0018bfd2dde7ba2a1123eb2ac06` | 299 772 | 1 067 | 0 |
| `BOX3_QBEATS.md` | `c728baccb7823f7f20d4544b72130147e7f72fc40104887f0da3fcf24d29fb3c` | 89 457 | 803 | 0 |
| `BOX5_QBEATS.md` | `cf425ff0d576910c9caa2899cad232e0c8447f605d240021262608aed184ff5b` | 57 158 | 596 | 0 |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | `09bf3442a372a17e66dda7d53ca512e0d1bc551e80f42d2c7a08614811d84fe5` | 56 791 | 350 | 0 |

⚠️ **CR=0 su tutti e cinque perché sono impronte del BLOB.** LIBRO e BUGS sono `text: unspecified`:
la loro **faccia disco** porta CRLF (misurato in A95: 518 e 1 067 CR rispettivamente). Se al rientro
misuri l'impronta su disco e non torna, **non è un guasto** — è questo. Dichiara sempre quale faccia
stai misurando.

### 4. Prossimo ID mandato libero

**[M] Comando**: `grep -rlE '\bA<N>\b' <supporto>` — forma **a token**, non nuda. La forma nuda
(`grep -icE 'a<N>'`) cattura le sottostringhe dentro gli sha ed è un falso-positivo che mi ha già
ingannato in apertura di A90 (28 file invece di 2).

**Due supporti indipendenti**: `HANDOFF/` (repo, su C:) e
`E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\`.

| ID | repo | E: | stato |
|---|---:|---:|---|
| A97 | 0 | 0 | **mai emesso** — buco di sequenza, non un artefatto perso |
| A98 | 1 | 1 | ⛔ **bruciato.** L'unica occorrenza è una *menzione* dentro `MISURE_CC_2026-08-18_A99-SEI-BLOCCHI.md` («A98 mai arrivato, non eseguito, non cercato»), non un artefatto |
| A99 | 1 | 1 | usato — il referto dei sei blocchi |
| A100 | 0 | 0 | ⛔ **bruciato** per dichiarazione del referee in A101 |
| A101 | 0 | 0 | questo congedo (l'occorrenza nascerà con questo file) |
| **A102** | **0** | **0** | ⇒ **PROSSIMO LIBERO** |

**Controllo positivo adiacente, forma esatta identica**: `\bA96\b` → **2** file su repo, **2** su E:.
Non nullo: la forma di ricerca funziona.

⚠️ **A97, A98, A100 non vanno riusati.** A97 non è un buco da riempire — è saltato e resta saltato;
riusarlo creerebbe un ID la cui posizione nella sequenza mente sulla cronologia.

---

## COSA È SUCCESSO IN QUESTA SESSIONE — dodici mandati, in breve

**[M]** A90 contraddittorio sulla roadmap (6 accettati / 3 corretti su 9) · A91 anatomia di
`tmp_fix.ps1` · A92 chiusura dell'equivoco metronomo (diff, 6 su 7 fatti incisi, uno fermato) ·
A93 completamento anti-cascata · A94 ricomposizione · A95 **commit `44fea3e` + push + CI verde**
(l'unico commit della giornata) · A96 ticket interruzione **non scritto**, la misura ha smentito la
premessa · A99 sei blocchi in sola lettura · A101 questo congedo.

**[M] Un solo commit in dodici mandati, doc-only, zero righe di codice.** `ios_app/` non è stato
toccato in nessun momento della sessione.

---

## TRE DOMANDE

### ① Cosa deve sapere chi arriva dopo, e oggi non è scritto in nessun documento ufficiale

**[A] Il metodo nato oggi e mai inciso — verificare le citazioni DENTRO un diff.**
In A94 ho trovato che la riga 3 del diff citava `SCALETTA:327`, ma **quel diff stesso** inseriva due
marcature sopra quel punto: il contenuto sarebbe vissuto a `:329` appena il commit atterrava. Citarlo
a 327 avrebbe generato un puntatore **nato già rotto, il giorno stesso della sua nascita**. L'ho
corretto. In A95 il referee ha trovato che avevo corretto **il corpo ma non la colonna fonti** della
stessa riga.

⇒ **La regola, che non è in nessun canonico:** ogni citazione scritta *dentro* un diff va verificata
contro i delta **di quel diff stesso**, **corpo e colonna fonti**, non solo contro il corpus
esistente. Il difetto che intercetta è una classe sua: *il testo ratificato descrive un mondo che il
commit stesso cambia.* Le due correzioni di A94 (la frase «sessione finita o morta» e `:327`) hanno
**quella** causa comune, non due diverse. Vive solo nei referti A94/A95 e in questo congedo.

**[A] La seconda cosa che sta solo in chat: il *perché* il diff finale è stato rigenerato da
`git diff`.** In A95 ho ricomposto a mano il corpo del diff tre volte, e due volte lo strumento di
scrittura ha **ricollassato le righe di contesto vuote** — un carattere invisibile, `\n` invece di
` \n`, che rende il patch corrotto senza che nulla lo segnali. Lo stesso difetto era già comparso in
A92. ⇒ **Per i diff sui canonici, il corpo si cattura da `git diff` reale e si concatena ai byte
grezzi, non si ricompone a mano.** Il preambolo A86 va sopra; il corpo viene dalla macchina. E la
verifica che vale davvero non è `git apply --check` ma **`git apply -R` su una copia, confrontando
`git hash-object` con i blob HEAD di partenza** — l'ho fatta in A95 e ha dato la certezza che
`--check` non dà.

**[A] La terza, ed è la più scomoda: quanto sono fragili le ricognizioni di intestazione.**
In A95, in fase di staging, ho scoperto che `LIBRO_MASTRO_QBEATS.md` ha un blocco
`**Versione:**` / `**Ultima modifica:**` / `**Edit author:**` a **righe 5-7**, mai visto in A92, A93,
né nella prima stesura di A94 — perché tutte quelle ricognizioni si erano fermate a leggere le prime
4 righe del file. Il documento **vieta a se stesso** esattamente questo, `LIBRO:89`: «Versione =
puntatore. […] Un numero non bumpato è peggio di un puntatore rotto: sembra sano, non lo è.» ⇒ Chi
tocca un canonico legga **le prime 12 righe**, non le prime 4, e non presuma che l'intestazione sia
dove sta negli altri file: BUGS l'ha a `:3`, SCALETTA a `:3`, LIBRO a `:5`. **Tre file, tre posizioni
diverse.**

**[A] Un fatto sul contenuto, non sul metodo, che vive solo nella roadmap (non canonica).**
La misura più importante di A90 non è in nessun canonico: **la quota di commit che tocca `ios_app/`
è passata dal 59 % (settimana del 29/06) all'8-18 % da fine luglio.** La roadmap la porta, ma la
roadmap è un file in `HANDOFF/`, non un canonico — e per la regola di casa, ciò che non è in un
canonico non esiste operativamente. Non l'ho incisa perché nessun mandato l'ha disposto, e non
spettava a me deciderlo.

### ② Cosa NON va rimisurato, e cosa SÌ perché la mia misura è debole

**NON va rimisurato — è solido, misurato a fonte più volte:**

- **[M] La catena a quattro anelli per cui l'app non può far partire uno show.** `SetlistRunner` mai
  costruito (zero siti) · slot senza mutatore (`QLiveSession.swift:35`) · nessuno chiama
  `navigate(to: .metronome)` · `START SHOW` a closure vuota
  (`QLiveShowDetailView.swift:289-292`). Misurato in A90, riconfermato in A92 e A99.
- **[M] L'interruzione audio È gestita**, con cinque `addObserver` a `AudioEngine.swift:2648-2658`,
  retry a 20+20 tentativi, guardia hardware, safety-net. E **testata su device tre volte**, con PASS
  3/3 registrato in `BUGS_QBEATS.md:1048`. A96 ha smentito la premessa del suo mandato: non
  riaprirlo senza una misura nuova.
- **[M] Il percorso di gioco non scrive il catalogo.** Dieci CRUD in `QBeatsStore`, tutte con
  `save()`, **nessuna raggiungibile** da Start→sezione→brano→END SHOW→uscita. Verificato file per
  file in A99 con controllo positivo non nullo.
- **[M] Il riancoraggio della catena interruzione-Link a HEAD**: `AudioEngine.swift:2676-2677`,
  stessi numeri di riga di `872dd5b`, `link_engine_stop` una sola occorrenza (`:1645`) e **fuori** dal
  ramo `.began`.

**SÌ, va rimisurato — la mia misura è debole o parziale, e non voglio sia ereditata come solida:**

1. ⚠️ **«≥15 decisioni ratificate senza riscontro nel codice» — è [R], non [M].** L'ho relayato da un
   agente di lettura in A90 e l'ho presentato come misura mia. Il referee l'ha contestato in A93 e
   aveva ragione. La tabella di 11 righe che ho scritto io è verificata; **il numero 15 no**. Va
   rifatto da zero, e con il filtro cronologico: tre di quelle righe sono «decise dopo l'ultimo
   commit di codice», che è una categoria diversa da «ratificato e mai costruito».
2. ⚠️ **Il censimento delle citazioni nude è un CAMPIONE, non il totale.** In A93 ho verificato per
   contenuto **cinque** citazioni vive (tutte rotte). Ma il censimento completo conta **62 nude su
   107** in LIBRO e **33 su 42** in BUGS. **Cinquantasette non sono state aperte.** Chi legge «cinque
   su cinque rotte» e conclude «il corpus è rotto» sta extrapolando da un campione che non ho scelto
   per rappresentatività: l'ho scelto perché era il tratto toccato dal delta di quel diff.
3. ⚠️ **La geometria del mixer sopra END SHOW è calcolata, non vista.** In A90 ho derivato che il
   velo trasparente copre 30 %-79 % dello schermo e che i bottoni cadono al 52-62 %, quindi «primo
   tocco morto, non trappola». È aritmetica su `frame(height:)` e sul centraggio dello `ZStack`:
   **nessuno l'ha vista su un device**, e non può vederla finché ⟦S5b⟧ non esiste. Se il layout reale
   diverge (safe area, iPad, `scaleFactor`), la conclusione «recuperabile al secondo tocco» cade e
   torna quella del referee («l'unica uscita è coperta»). **Non ereditare il mio verdetto come
   fatto osservato.**
4. ⚠️ **Il confronto fra `LiveHost_Fase3_InterruptionHandling.md` e il codice reale (A99, B6.1) è mio
   e non è stato ratificato da nessuno.** Ho classificato quattro regole su cinque come «seguite» e
   una come «implementata diversamente». È un giudizio tecnico, non una misura binaria: chi lo
   riprende lo rilegga, perché ho letto la nota una volta sola e il codice a blocchi.
5. ⚠️ **`BUGS:163` è misurato falso e NON è stato corretto.** Il ticket `TD-emerg-bottone-morto`
   afferma che «emerg» è «RAGGIUNGIBILE OGGI … sul percorso normale»: è falso, la pulsantiera vive
   solo dentro `LiveView`, irraggiungibile. L'ho segnalato in A90, marcato di lato in A92, e **la
   frase è ancora lì**. È la frase che dà al ticket la sua urgenza.

### ③ Cosa serve da Mauro — solo decisioni sue

1. **Severità di `TD-mixer-copre-endshow` e `TD-emerg-bottone-morto`.** Entrambi sono in §1.1 con
   «PROPOSTA, non assegnata: decide Mauro» dal 07/08 — undici giorni. **[M]** Verificato in A99: il
   primo non è stato toccato **dalla nascita**, zero modifiche. Finché il valore non c'è, la loro
   collocazione fisica in §1.1 è provvisoria per costruzione.
2. **Il disegno del piede di END SHOW a un bottone solo.** **[M]** `LIBRO:353` ratifica il
   *comportamento* (togliere RESTART) ma dichiara **esplicitamente non ratificato** il *disegno*, e
   nessuna riga successiva lo ha ratificato. Il codice ha ancora due bottoni
   (`FineSetlistView.swift:28-33`). Serve che il deliverable CD del 07/08 passi per un canale
   byte-fedele, e la decisione di aprire quel canale non è tecnica.
3. **Se F1 conta come cancello.** **[M]** Non gira dal 31/07 e l'ultima volta è fallito (6 warning
   contro una policy zero-warning). Nessuno ha deciso se è un cancello vero o un attrezzo
   abbandonato. Finché non si decide, «CI verde» resta un'affermazione parziale a ogni consegna.
4. **`tmp_fix.ps1`: si toglie o resta.** **[M]** A91 ha misurato che è **innocuo in pratica** — mai
   eseguito in quattro mesi (0 su 244 versioni di `AudioEngine.swift`), niente lo richiama, morde
   solo se lanciato a mano dalla radice del repo, e `git rm` **non lo toglie dalla storia pubblica**.
   ⚠️ **Ho declassato io stesso la mia Fase 0.1**: non è urgente come l'avevo scritto. Resta una
   decisione, non un'emergenza.
5. **Se la roadmap va incisa in un canonico o resta un documento di lavoro.** Porta misure che nessun
   canonico ha (§1.2 ratificato-vs-costruito, §1.3 quota di codice). Per la regola di casa — una
   ratifica che non atterra in un canonico non esiste operativamente — oggi quelle misure **non
   esistono** ai fini del progetto. È una scelta di regime, non tecnica.

⚠️ **Su una delle tre domande ho un rilievo.** La terza — «cosa serve da Mauro» — è formulata bene,
ma manca il suo complemento, e credo sia la domanda che il mandato non ha fatto: **cosa serve da CD.**
**[M]** Ne ho contate almeno tre, tutte ferme: l'empty-state del caso FALLIMENTO (caso Ⓐ, motore
audio non disponibile — l'unica domanda legittima ancora aperta dopo la cancellazione dell'A3) · la
destinazione del tasto «emerg» (il *cosa deve fare*, che nessun canonico ratifica) · le quattro
domande CD-Q5/Q6b/Q17/Q18, col campo risposta vuoto. Nessuna di queste è di Mauro, e nessuna è mia:
se il congedo non le nomina, restano dove sono.

---

## COSA NON RIFARE

**[M]** Il commit `44fea3e` è pushato e la CI `iOS Signed Build` è verde (`32148440889`): non
ri-committare, non ri-pushare. · I file `HANDOFF/DIFF_2026-08-18_A92-METRONOMO.txt` e
`HANDOFF/DIFF_2026-08-18_A94-CHIUSURA-DOC.txt` sono **storia della proposta**, non lavoro pendente —
il secondo è già applicato, riapplicarli fallisce. · A96 non ha prodotto un ticket **per misura**, non
per dimenticanza: non riaprirlo. · A97, A98, A100 sono bruciati o mai emessi: non cercare i loro
artefatti, non esistono.

**[A] E la cosa che vale più di tutte, che vale sia per me che per chi arriva:** in dodici mandati e
una giornata intera, questa sessione ha prodotto **un commit doc-only e zero righe di codice**. Il
cardine — ⟦S5b⟧, cablare lo Start — non è stato toccato, e non ha nemmeno una scheda propria nella
SCALETTA (**[M]** A99: le 12 intestazioni di sezione B si fermano a `⟦S6⟧`; `⟦S5b⟧` esiste solo come
una frase dentro la marcatura di `⟦S5⟧` a `SCALETTA:324`). Se la prossima sessione apre un altro giro
documentale prima di quello, il rapporto misurato in §1.3 della roadmap peggiora di un'altra
giornata.

---

## IMPRONTE DI QUESTO CONGEDO

⚠️ Il congedo del 07/08 non le portava, e sono serviti undici giorni per accorgersene. Qui stanno,
e si riferiscono alla **faccia disco** di questo file — verificato `git check-attr text` →
`text: unset`, cioè `HANDOFF/**` è `-text`: **disco e blob coincidono**, una faccia sola.

⛔ **UN LIMITE STRUTTURALE, dichiarato invece che aggirato:** lo sha256 del file **completo** non può
stare dentro il file stesso — inciderlo lo cambierebbe, e il valore inciso sarebbe falso nell'istante
in cui viene scritto. È autoriferimento, non pigrizia. ⇒ Si incide lo sha256 del **CORPO** (tutto ciò
che precede il marcatore `## IMPRONTE DI QUESTO CONGEDO`), che è stabile e riproducibile; lo sha del
file intero vive nel **messaggio di consegna**, che è esattamente ciò che `LIBRO` R7 §1 prescrive
(«sha256 = trasporto, non puntatore»).

- **sha256 del CORPO** (fino al marcatore, escluso): `db541a0bc39929d9e37e4e7f5063cb8fbdec996ccfac5569587ccb7380249d9c`
  Riproducibile: `python -c "import hashlib,io; t=io.open(FILE,encoding='utf-8',newline='').read(); print(hashlib.sha256(t[:t.find('## IMPRONTE DI QUESTO CONGEDO')].encode()).hexdigest())"`
- **byte** (file completo): `16837`
- **righe** (file completo): `257`
- **CR (0x0D, contati sui byte, mai con grep)**: `0`

---

*A101-CONGEDO-CC-FINE*
