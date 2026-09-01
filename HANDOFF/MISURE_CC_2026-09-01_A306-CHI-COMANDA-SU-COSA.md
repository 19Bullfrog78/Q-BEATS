# MISURE CC — A306 — CHI COMANDA SU COSA — 2026-09-01

Da: CC · A: referee. Mandato: **A306-CHI-COMANDA-SU-COSA**, dichiarato in testa e coincidente con quello ricevuto.

**Orologio**: 2026-09-01, **13:03:12 locale (UTC+2)**.

⛔ **Zero commit, zero push in questo giro.** Le tre destinazioni sono state effettivamente modificate sul disco — per produrre un diff vero, verificabile, non una trascrizione a mano — ma **nulla è in staging e HEAD è invariato**. Il diff completo è in coda a questo documento.

Marcatura: **[M]** misurato ora da me, alla fonte · **[R]** riportato, non verificato da me · **[A]** giudizio mio.

---

## 0 · Orologio e cancello sull'ID

**[M]** Cancello a sei gambe su `A306`: nomi C:=0 · nomi E:=0 · git grep=0 · disco C:=0 · **disco E:=1** · git log=0.

⚠️ **Aperto, non solo contato — falso positivo di un tipo diverso dai precedenti.** L'unica occorrenza sta in un vecchissimo file HTML autoportante su E: (`DA_CD_PER_CC/11_07_2026/.../Q-BEATS Vista LIVE v2 (standalone).html`), dentro un **blob JavaScript compresso in base64**: la stringa «A306» compare per puro caso nei byte compressi, non come identificativo. È la stessa classe di trappola già a verbale in `CLAUDE.md` («grep -r senza esclusione dei binari produce falsi positivi... hanno già fatto risultare occupati tre ID liberi») — questo è il quarto caso, di un genere diverso dai falsi-UNO precedenti (auto-citazione), ma stessa disciplina: si apre, non si conta.

**Controllo positivo su `A304`** (su disco, non tracciato): nomi=1, contenuto=1. La sonda vede. ⇒ **A306 libero, confermato.** Tree pulito, HEAD `976d986`.

---

## 1 · Verifica della premessa corretta — prima di usarla

**[M] Citazione riverificata byte-per-byte, come richiesto.** Estratta dal foglio 30/08 (`DESIGN/QLive_Nav/2026-08-30_QLive-Player_IL-VELO-DICE-DA-DOVE...html`, riga D④ del pannello ⑤), confrontata contro il testo dettato nel mandato salvato PRIMA in un file di riferimento: **identica, 189/189 byte.**

> «Abolire la porta è più forte che chiedere conferma: il contratto 18/07 lì non è violato, è rimasto senza oggetto — e resta vigente sulla LISTA, dove le sue due porte esistono ancora.»

**[M] Conteggi confermati esatti**: `18/07` nel foglio = **2** (atteso 2) · controllo positivo `27/08` = **9** (atteso 9, e la sonda vede).

**[M] D② riverificato**, per la correzione sul «non tutto dentro il player»: *«Dal dettaglio l'unica via verso la LISTA è END SHOW... Nessuna freccia verso la lista dal dettaglio a show vivo: si torna con RETURN/RESUME, o si chiude.»* — conferma che il foglio 30/08 parla ESPLICITAMENTE del dettaglio, non solo del player. **Nessun FERMATI necessario: la premessa del §1 regge alla misura.**

---

## 2 · Le tre marcature — forma misurata prima di scrivere

**[M] Metodo**: per ciascuna destinazione, misurata la forma di almeno due righe sorelle prima di scrivere, poi verificato che la riga nuova/modificata la combaci esattamente (conteggio separatori `|`).

### (a) `DESIGN/QLive_Nav/README.md` — due interventi

**Forma misurata**: tabella a 2 colonne, 3 separatori `|` per riga (righe sorelle 15, 20, 22 verificate: tutte 3).

1. **Riga 20 (contratto 18/07)** — marcatura appesa in coda alla cella esistente, **zero parole precedenti toccate**. Verificato: 3 pipe dopo la modifica, come prima e come le sorelle.
2. **Nuova riga**, inserita fra la riga del 29/08 (AMMISSIBILE-E-LUCINA) e la riga «gli altri» — nomina il foglio 30/08, dichiara cosa governa. Verificato: 3 pipe, come le sorelle.

### (b) `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`, Sezione G

**Forma misurata**: blocco di marcatura a paragrafo intero, stile già in uso nel file stesso per marcature di superamento (esempio-sorella: la riga 24/08 su D16 in Sezione C, «⚠️ MARCATURA 24/08 — D16 È SUPERATA E GIÀ INCISA. Non si riscrive nulla: si marca.»). Inserito **subito dopo l'intestazione** `## G ·`, **prima** della riga «Incisa dal referee, 24/08/2026»: additivo, zero righe esistenti spostate o riscritte. Verificato: +2 righe nel file (il paragrafo + una riga vuota di separazione), nessuna riga preesistente modificata.

**Contenuto**: dei quattro punti del PERIMETRO POSITIVO della scheda, il punto 2 (selettore gattato del Dettaglio) è dichiarato senza oggetto; i punti 1, 3, 4 (le due porte della Lista, il modale, la lettura Start/Stop Sync) restano vivi — **con una riserva dichiarata**: se il modale di conferma debba ancora servire entrambi gli sfondi o solo la Lista **non è misurato in questo giro**, e l'ho scritto invece di deciderlo da me.

### (c) `LIBRO_MASTRO_QBEATS.md`, Sezione 2

**Forma misurata**: 6 colonne, 7 separatori `|` (riga sorella più recente, 399, verificata: 7). Due righe nuove aggiunte in coda, **entrambe verificate a 7 pipe**, coincidenti con la sorella.

⚠️ **Colonna Stato = `attiva` per entrambe**, non un valore nuovo come «proposta»: verificato che l'enum del file (riga 193: `attiva | superseded | revocata | ratificata-no-CC-review`) non ha un valore per «in attesa di OK» — e che righe precedenti nella stessa condizione (es. riga 371, «APPROVATO, NON ratificato — in attesa del collaudo su device») usano comunque `attiva`, con la riserva scritta nel CONTENUTO, non nella colonna. Ho seguito la stessa convenzione: **entrambe le righe nuove dichiarano esplicitamente «in attesa della parola di Mauro» nel testo**, perché nessuna delle due ha ricevuto quell'OK in questo giro.

---

## 3 · La riga di processo

**[M] Scritta come seconda riga nuova in LIBRO**, stessa sede e forma della prima. Contenuto: il referee, quando Mauro contraddice una misura, la rimisura prima di dargli ragione — dare ragione non è verificare. Il caso che l'ha prodotta (A304→A306, con la misura giusta persa per due giri) è nominato nella riga stessa. **Marcata «proposta dal referee, in attesa della parola di Mauro»**, come richiesto: quella parola non è presente in questo mandato.

---

## 4 · Consegna

Referto depositato su due gambe, `cmp` misurato dopo il deposito — coda del documento.

⚠️ **Stato del working tree, dichiarato**: i tre file (`README.md`, `SCALETTA_ATOMI_S6...md`, `LIBRO_MASTRO_QBEATS.md`) hanno modifiche **presenti sul disco ma non in staging e non committate**. `git status`/`git diff` le mostrano; nessun `git add` è stato eseguito. Restano in questo stato finché referee e Mauro non danno l'OK per il commit di un giro successivo.

Il diff completo, catturato con `git diff` (non trascritto a mano — elimina il rischio di errore di trascrizione sulle stesse righe che dichiarano «zero parole riscritte»), è in Appendice A.

---

## 6 · Fermarsi e dichiarare — esito

- **L'ID collide?** No — falso positivo binario aperto e scartato, §0.
- **La citazione del §1 non si trova identica?** Si trova identica, verificato byte-per-byte.
- **Una destinazione non ha righe sorelle da cui misurare la forma?** Tutte e tre ne avevano; misurate e verificate.
- **Un quarto posto non nominato dal referee?** Cercato con la stessa sonda di A304 (`QLive-Exit-in-Play`, `S-EXIT`, `S6F`, `contratto.*18/07`) ristretta ai canonici + DESIGN + sorgenti: nessun quarto punto nuovo oltre ai tre già nominati e ai minori già dichiarati in A304 (`LIBRO:327`, `:334`, `:553` — invariati, non toccati da questo giro: riguardano l'esistenza degli atomi, non l'autorità del contratto sul dettaglio/lista).
- **Una premessa è falsa alla misura?** No — la premessa corretta del §1 regge; l'unica riserva (se il modale di Sezione G serva ancora entrambi gli sfondi) è dichiarata, non nascosta, nel testo della marcatura (b).

Nessuna condizione di arresto. Consegna completa, non applicata.

---

*A306-CHI-COMANDA-SU-COSA — fine corpo, diff in appendice.*

## Appendice A — diff completo, catturato con `git diff` (non trascritto)

```diff
diff --git a/DESIGN/QLive_Nav/README.md b/DESIGN/QLive_Nav/README.md
index 3b213ee..90bf04f 100644
--- a/DESIGN/QLive_Nav/README.md
+++ b/DESIGN/QLive_Nav/README.md
@@ -17,7 +17,7 @@ peso. Il nome del file non dice il suo stato: lo dice questa tabella.
 | `2026-08-20_..._rev4__SUPERSEDE-rev3__navbar-centrata-ritmo-testata_390x844.html` | ⛔ **SUPERATA NEL TESTO dalla rev5.** Conservata di proposito: è l'artefatto che la rev5 rettifica, e senza di essa i due ritiri non hanno referente. **Il suo DISEGNO resta valido** — i quattro selettori sono identici nelle due. ⚠️ Contiene un'affermazione errata su «List view», ritirata dalla rev5. |
 | `2026-08-06_..._rev3-NORMATIVA.html` | **NORMATIVA per tutto ciò che rev4/rev5 non toccano** — parola per parola. I quattro selettori del dettaglio sono superati; il resto no. |
 | `2026-08-06_..._rev2-BUONA.html` | ⛔ **NON NORMATIVO.** Conservato come impronta dell'evento di ratifica: è il file che il referee lesse e approvò, e contiene ancora la voce che quella ratifica ELIMINA. ⚠️ **Il nome «BUONA» dice il contrario del suo stato.** **NON RINOMINARE:** un canonico lo cita con questo nome. |
-| `2026-07-18_QLive-Exit-in-Play.html` | **CONTRATTO rev.2 per ⟦S-EXIT⟧ e ⟦S6F⟧.** ⚠️ Il suo `:root` è una copia di lavoro: se un token diverge, vince Q7-Q16. |
+| `2026-07-18_QLive-Exit-in-Play.html` | **CONTRATTO rev.2 per ⟦S-EXIT⟧ e ⟦S6F⟧.** ⚠️ Il suo `:root` è una copia di lavoro: se un token diverge, vince Q7-Q16. ⚠️ **MARCATURA 01/09/2026 (A306) — SUL DETTAGLIO SENZA OGGETTO, SULLA LISTA VIGENTE. Zero parole riscritte sopra: si marca.** Il foglio CD del 30/08 abolisce il selettore delle stanze nel dettaglio dello show attivo — verbatim: «Abolire la porta è più forte che chiedere conferma: il contratto 18/07 lì non è violato, è rimasto senza oggetto — e resta vigente sulla LISTA, dove le sue due porte esistono ancora.» Vedi la riga sotto per il foglio. |
 | `2026-08-21_..._rev6__SUPERSEDE-rev5-SU-2-SELETTORI__ancoraggio-Read-only-e-ritiro-4px_390x844.html` | **NORMATIVO sui DUE selettori che tocca.** Riga d'indice **scritta da CD** (pannello ④ del foglio), riportata qui verbatim: rev6 · 21/08 · SUPERSEDE rev5 su 2 selettori — **.dhrow: baseline** (cadono center e flex-start; cade .ro margin-top) · **.navbar .back: padding 0 4px RITIRATO**. Non tocca geometria A, badge, .roomseg, .viewtoggle. ⛔ **Porta 5 errata AUTOCITANTI di giornata**: regola riformulata («stesso ancoraggio del livello 1», non «sul baseline») · origine y · movimento Ⓓ 13,97 · **lh 1.05→1.12 inesistente nell'app** · **nesso causale ritirato: il gradino È l'ancoraggio (5–8pt su `baaa172`), non la geometria A**. **Aperti:** H (altezza badge nell'app) · il titolo più in alto, inspiegato · lh 1.12 ratificata ma inattuabile. **Le due decisioni non si muovono**; i numeri assoluti del foglio **non si incidono**. ⚠️ **Trasporto: da Drive solo il tasto Scarica — i byte sono l'unico giudice, mai il nome.** |
 | `2026-08-25_..._Show-in-esecuzione__rev2-RESTART-SONG-e-gruppo-2-1_390x844.html` | **PROPOSTA rev2 — APPROVATA DA MAURO il 25/08.** ⚠️ **In attesa di collaudo device: nessun dispositivo l'ha vista.** Governa il **menù dello show in esecuzione**. **Supersede il predecessore di pari data su DUE punti soli** — **nomi delle voci** · **divisione del menù in due gruppi**; **sul resto non cambia una parola.** ⛔ **NON tocca** rev5, nota 21/08, rev6, freeze 06/08, contratto 18/07. ⚠️ **I DUE FILE DEL 25/08 NON SI DISTINGUONO PER NOME — solo per PESO:** questo, **APPROVATO, 106 024 byte**; il predecessore `2026-08-25_..._Show-in-esecuzione__N1-N5_390x844.html`, **SUPERATO, 97 267 byte**, **non depositato — lasciato su Drive**. ⚠️ **SCOSTAMENTO SEGNALATO, NON EMENDATO:** il foglio cita al suo interno un file `__rev2-ratificata` che **non esiste** — zero corrispondenze su `C:`, `E:` e Drive, con controllo positivo che trova i due file del 06/08 su **tutti e tre** i supporti. Le misure che cita sono però **identiche nei due file del 06/08**, quindi la sostanza tiene. ⛔ **Il foglio di CD non si riscrive: lo scostamento si annota qui.** |
 | `2026-08-24_QLive-Exit-in-Play_NOTA-DI-CORREZIONE-contratto-18-07__ritiro-chip-N-on-Link.html` | **SI LEGGE ACCANTO AL CONTRATTO 18/07** — ritira la targhetta **«N on Link»**. **Chi legge il 18/07 deve leggere anche questa.** ⚠️ **NON È IN QUESTA CARTELLA: 27 145 byte, vive solo su Drive** (`Qbeats_IN_CD`) — zero copie in `DESIGN/QLive_Nav/`, zero su `E:`. Citata dal foglio del 25/08 (riga 41) e finora **senza rimando in questo indice**: questa riga esiste per darglielo. ⛔ **Il deposito è materia di un mandato suo, non fatto qui.** |
@@ -31,6 +31,7 @@ peso. Il nome del file non dice il suo stato: lo dice questa tabella.
 | `2026-08-28_..._POLITICA-DEL-RIENTRO__rev3.1-CHIUDE-LA-FIRMA-B__tetto-cintura-e-due-gradi.html` | **SI LEGGE ACCANTO AL rev3** — lo chiude su tetto, cintura e due gradi. **Chi legge il rev3 deve leggere anche questo.** 29 593 byte. ⇒ Firma C di Mauro, 29/08 (**TRATTENUTA in parte: il grado 2 è un lavoro a sé**). |
 | `2026-08-29_..._USCITA-DA-UNO-SHOW-VIVO__e-il-contatore-senza-fonte.html` | **NORMATIVO sull'uscita da uno show vivo** e sui trattini del contatore. ⇒ Firma D, 29/08 — **NON COSTRUITA**: è il ticket `TD-show-non-abbandonabile` in BUGS. 29 752 byte. |
 | `2026-08-29_..._AMMISSIBILE-E-LUCINA__uno-solo-e-spenta.html` | **NORMATIVO sull'ammissibile 20–400 BPM e sulla lucina.** ⇒ Firma E, 29/08. ⚠️ **Trappola:** esiste un gemello `ZZ_SUPERATO_da-fix-CSS__2026-08-29_AMMISSIBILE-E-LUCINA.html` da **25 790** byte — **non depositato, lasciato su Drive**. Questo è **25 096**. |
+| `2026-08-30_QLive-Player_IL-VELO-DICE-DA-DOVE__END-SHOW-sullo-scaffale-e-sei-decisioni-incise__390x844.html` | **NORMATIVO sul player fermo (bivio, velo) e sul DETTAGLIO — sei decisioni incise, CD 30/08/2026.** Abolisce il selettore delle stanze nel dettaglio dello show attivo (D④): **sul dettaglio il contratto 18/07 resta senza oggetto**, per dichiarazione di CD, non per abrogazione. ⛔ **NON tocca la LISTA:** le due porte del contratto 18/07 lì restano vive e invariate. Vedi la marcatura sulla riga del contratto 18/07 sopra. |
 | gli altri | storico di derivazione — vedi «Derivazione» più sotto. |
 
 ⚠️ **MARCATURA 26/08 — DIFETTO DI FORMA NELLE TRE RIGHE DEPOSITATE IL 25/08, CORRETTO. Le righe non sono riscritte: si marca qui cosa è cambiato e perché.** I pesi delle righe nuove erano scritti col separatore **U+202F** (*narrow no-break space*) fra le migliaia — `106<U+202F>024`, `97<U+202F>267`, `27<U+202F>145` — mentre la stessa tabella usa lo **spazio normale** per il peso della rev6 (`87 570`). ⛔ **Il difetto ne minava la funzione:** quelle righe esistono per **distinguere due file omonimi per peso**, e chi cercava `106 024` scritto con lo spazio normale **non lo trovava**. Misurato: tre occorrenze in due righe, zero altrove in questo file. ✅ **Tutte e tre portate a spazio normale**, coerenti col resto della tabella. ⚠️ **Due occorrenze della stessa forma restano in `LIBRO_MASTRO_QBEATS.md`** (riga della decisione 25/08 e registro versioni): **fuori dal perimetro di questo giro, dichiarate e non toccate.**
diff --git a/HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md b/HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md
index ce3acf4..3ddc642 100644
--- a/HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md
+++ b/HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md
@@ -571,6 +571,8 @@ Prima di usare QUALSIASI riferimento qui, RI-VERIFICARE a `@ 6fca624` per SIMBOL
 ---
 
 ## G · LAVORO NON-ATOMO N.4 — SCHEDA DELLA CONFERMA D'USCITA DALLA STANZA
+⚠️ **MARCATURA 01/09/2026 (A306) — IL PERIMETRO DI QUESTA SCHEDA SI DIMEZZA: SUL DETTAGLIO SENZA OGGETTO, SULLA LISTA VIGENTE. Zero righe sotto riscritte: si marca solo qui.** Il foglio CD del 30/08 (`DESIGN/QLive_Nav/2026-08-30_QLive-Player_IL-VELO-DICE-DA-DOVE...`), riga D④, verbatim: «Abolire la porta è più forte che chiedere conferma: il contratto 18/07 lì non è violato, è rimasto senza oggetto — e resta vigente sulla LISTA, dove le sue due porte esistono ancora.» ⇒ **Del PERIMETRO POSITIVO qui sotto**: il punto **2** (selettore gattato del Dettaglio) è **senza oggetto** — non c'è più selettore da gattare. I punti **1** (le due porte della Lista), **3** (il modale di conferma) e **4** (lettura Start/Stop Sync) **restano vivi, invariati**; se il modale serva ancora entrambi gli sfondi o solo la Lista non è misurato qui. ⚠️ **In attesa della parola di Mauro**, non ancora raccolta al momento di questa scrittura.
+
 **Incisa dal referee, 24/08/2026. ASSOLVE IL CANCELLO di sez. C punto 4.**
 ⛔ NON è un atomo e NON entra nella riga d'ordine, che resta ⟦S-EXIT⟧ → ⟦S4L⟧ → ⟦S6⟧.
 Perimetro deciso da Mauro il 24/08: **una scheda sola**, che comprende il risveglio del
diff --git a/LIBRO_MASTRO_QBEATS.md b/LIBRO_MASTRO_QBEATS.md
index 31be1cf..0c37109 100644
--- a/LIBRO_MASTRO_QBEATS.md
+++ b/LIBRO_MASTRO_QBEATS.md
@@ -397,6 +397,8 @@ Colonna `stato`: `attiva` | `superseded` | `revocata` | `ratificata-no-CC-review
 | 2026-08-31 | **② NON SI CITA A MEMORIA — ogni indirizzo, numero, impronta o nome che entra in un mandato o in un documento O È STATO MISURATO IN QUELLA SESSIONE, OPPURE SI SCRIVE MARCATO «non misurato».** Non esiste una terza via: **un valore ricordato è un valore non misurato, anche quando è giusto.** **MOTIVO AGLI ATTI, misurato il 31/08 e non aneddotico:** in una sola sessione il **referee ha sbagliato quattro indirizzi**, tutti richiamati perché familiari; **CC ha composto a mano una coda di impronta** — testa del foglio CD, coda del contratto 18/07 e un carattere estraneo — richiamandola da una forma ricorrente del progetto e appiccicandola al file sbagliato (mandato A296); **il referee precedente ne ha dichiarati sette, di cui quattro della stessa famiglia**. ⇒ **È il modo caratteristico in cui questo sistema si rompe**, non un incidente isolato: il richiamo di una forma familiare è più veloce della misura e produce stringhe **plausibili**, che nessuna guardia di sola forma intercetta. | Mauro (ratifica 31/08) + referee (mandato A298) + CC (misura del proprio difetto in A296, scrittura) | `HANDOFF/MISURE_CC_2026-08-31_A295-FOGLIO-CD-30-08-IMPRONTA-IDENTICA.md`, sezione CORREZIONE A296 | attiva | — |
 | 2026-08-31 | **③ CC MISURA DOVE IL REFEREE NON VEDE, ED È L'ULTIMO CANCELLO PRIMA DEL REPOSITORY.** Il campo visivo del referee è il **repository pubblico**; quello di CC è il **disco reale** — file non tracciati, working tree, build. ⇒ **Quando CC contesta la premessa di un mandato PORTANDO UNA MISURA, la misura vince: per struttura, non per gerarchia.** CC può **fermare** un mandato del referee, e quando lo fa ci si ferma. ⚠️ **MA FERMARSI NON È L'UNICA RISPOSTA:** se il difetto è riparabile senza cambiare il lavoro — un'etichetta, un indirizzo, una cartella inesistente — **CC ripara, dichiara e prosegue**. Il blocco duro si riserva a ciò che **si rompe**: byte che non tornano, controllo positivo fallito, strada non raggiungibile. **Il parere tecnico di CC è un contributo, non un rapporto di esecuzione.** **MOTIVO AGLI ATTI:** il 31/08 è stato misurato che **questa regola non esisteva in nessun canonico** — zero occorrenze, con controllo positivo superato: la stringa «CC» rende **243** righe in questo file e **293** in `BUGS_QBEATS.md`, misurate **sul blob** a `5eb18c7de46dba72483710feb18416c8a9eed0a9`. Viveva **solo in un congedo**, che per propria dichiarazione non è una fonte. Nello stesso giorno **CC ha fermato due volte il referee e aveva ragione entrambe le volte**; e una clausola «FERMATI» **sproporzionata**, scritta dal referee su una semplice etichetta, **è costata un turno intero** (mandati A294→A295). | Mauro (ratifica 31/08) + referee (mandato A298, misura di assenza) + CC (scrittura) | i due arresti del 31/08: ID `A294` già occupato da un congedo untracked · `DA_CD_PER_CC/30_08_2026/DESIGN/QLive_Player/` inesistente | attiva | — |
 | 2026-09-01 | **I DOCUMENTI DI LAVORO ENTRANO NEL DEPOSITO NEL GIRO CHE LI PRODUCE.** Congedi, referti e diff vivevano fuori da git per **deriva, non per scelta**: misurato in A301 — **552 file**, **73 tracciati e 479 no**, e `.gitignore` **non contiene nessuna regola che tocchi `HANDOFF/`** (verbatim nel referto A301), mentre `ARCHIVIO.MD/` e `/_cc_processo/` sono untracked per decisione dichiarata di Mauro del 10/07. ⚠️ **Conseguenza misurata:** il campo visivo del referee è il solo repository pubblico ⇒ un ID assegnato su quella sola base è **strutturalmente cieco** ai mandati già bruciati su disco — così si sono persi **A289** e **A294**. **Regime (referee 01/09, OK di Mauro 01/09):** ogni congedo, referto e diff entra nel commit del giro che lo produce. **Arretrato:** un commit di soli documenti, limitato ai file **presenti su C:**; quelli esistenti **solo su E:** restano fuori, operazione a parte. **Messa in scena da lista esplicita, mai `git add -A`**, con verifica che lo staged coincida con la lista. **Setaccio A301 (nove categorie, ogni colpo positivo aperto uno per uno): nulla da non rendere pubblico**; l'unico dato personale è l'email dell'autore, già pubblica su ogni commit — **verificata dal referee sul feed pubblico: 20 occorrenze, una per commit**. | Mauro (OK 01/09) + referee (decisione e dettatura, mandato A302; riga incompleta per errore del referee, completata in A303) + CC (censimento A301, esecuzione A302) | referto A301 (552 file · 73 tracciati / 479 no · `.gitignore` verbatim, nessuna regola su `HANDOFF/`) · commit `8a3ca7902a854ad2c927f002771d76ccd90f0baa` — 345 file, tutti sotto `HANDOFF/`, zero rimozioni, `ios_app/` e `DESIGN/` identici al byte: confronto d'albero indipendente del referee fra `05283ced21de8456099cf8f6b9cda0caf573da35` e `41a1ae3d7d4714c1a7284f852d50b7a4a6a8fb62` · email dell'autore già pubblica: 20 occorrenze nel feed atom del repository | attiva | — |
+| 2026-09-01 | **CHI COMANDA SU COSA — SUL DETTAGLIO IL CONTRATTO DEL 18/07 È SENZA OGGETTO, SULLA LISTA RESTA VIGENTE. Non una decisione nuova: una citazione di ciò che CD aveva già stabilito il 30/08 e che non era ancora inciso in nessun canonico.** Foglio CD 30/08 (`DESIGN/QLive_Nav/2026-08-30_QLive-Player_IL-VELO-DICE-DA-DOVE...html`), riga D④, verbatim: «Abolire la porta è più forte che chiedere conferma: il contratto 18/07 lì non è violato, è rimasto senza oggetto — e resta vigente sulla LISTA, dove le sue due porte esistono ancora.» ⇒ **Sul DETTAGLIO:** il selettore delle stanze è abolito, e con esso l'oggetto a cui si applicava una clausola del 18/07. **Sulla LISTA:** le due porte (`onHome`/`onSwitch`) e il contratto che le governa restano invariati. ⚠️ **In attesa della parola di Mauro**, non raccolta al momento di questa scrittura. | CD (dichiarazione, foglio 30/08) + referee (rilievo, mandato A306) + CC (verifica a fonte, scrittura) | foglio 30/08 riga D④ · `BUGS_QBEATS.md:325` · Sezione G della SCALETTA, marcata nello stesso giro | attiva | — |
+| 2026-09-01 | **IL REFEREE, QUANDO MAURO CONTRADDICE UNA MISURA, LA RIMISURA PRIMA DI DARGLI RAGIONE. Dare ragione non è verificare.** Caso che l'ha prodotta, 01/09: il referee aveva misurato correttamente che le due porte sulla lista sono vive e senza conferma; alla smentita ha ceduto senza rimisurare, e la misura giusta è stata persa per due giri (A304→A306). **Dichiarata dal referee, vale contro di lui.** ⚠️ **Proposta dal referee, in attesa della parola di Mauro.** | referee (autodichiarazione, mandato A306) + CC (scrittura) | mandati A304 e A306, questa stessa sessione | attiva | — |
 
 ---
 
```

---

*A306-CHI-COMANDA-SU-COSA — FINE.*
