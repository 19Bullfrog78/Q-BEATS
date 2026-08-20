# REFERTO A132 — UN TICKET + UNA CORREZIONE. DOC-ONLY.

Da: CC · A: referee, + Mauro · Data: **19/08/2026** · HEAD: `547017f7d4e4df9c5d5a84774b0ccfe63bc01b1d`
Mandato: **A132**. Le tre conformità grafiche sono **CHIUSE** (gate device Mauro 19/08,
controlli 1·4·5·6 verdi) — **non toccate**.
⛔ **ZERO MODIFICHE A `ios_app/`.** Un solo file toccato: `BUGS_QBEATS.md`. ⛔ **NON COMMITTATO.**

Marcatura: **[M]** misurato da me · **[A]** giudizio mio.

---

## FONTI — LETTE ALLA FONTE, NON DALLE CITAZIONI DEL MANDATO

**[M]** `QLiveShowDetailView.swift:127` (blob a HEAD): `RoomSwitchBar(active: .qLive, onHome: {},
variant: .segMini)` — nessun `onSwitch`. `RoomSwitchBar.swift:36`: `var onSwitch: () -> Void =
{}`. Commento a `:123-126` presente e verbatim, dichiara l'inerzia come richiesta dalla scheda
di ⟦S5a⟧. **Due siti vivi confermati**: `QLiveShowsView.swift:78-83` e
`QStage/ShowsListView.swift:82-90`, entrambi passano `onSwitch` esplicito.

**[M] La classe di difetto già nota — cercata, non presunta.** Trovata in
`QLiveEmptyStates.swift:101-106`, «REGISTRO RESI — VINCOLO ESPLICITO PER S6», verbatim: *«
`onGoToQStage` è `() -> Void = {}`, un no-op silenzioso. Se S4/S6 dimenticano di cablarlo, il
risultato è un bottone che si preme … e NON fa nulla — il compilatore non segnala nulla, perché
il default è una closure sintatticamente valida. […] Va verificato a schermo/integrazione quando
S6 collega il routing.»* — è un **avviso preventivo** scritto per un ALTRO bottone, che qui si è
avverato per davvero.

**[M] L'allineamento, verificato su DUE fonti indipendenti, non solo sulla tabella del freeze:**
- `RoomSwitchBar.swift:41-49` — `.full` usa `ZStack { segment; HStack { homeButton; Spacer() } }`:
  il centraggio del segmento **non dipende** dalla presenza dell'home button ⇒ centrale anche
  dove l'home manca.
- `QLiveShowDetailView.swift:120-127` — `.segMini` dentro `HStack { backButton; Spacer();
  RoomSwitchBar(...) }` ⇒ a destra.
- **Freeze rev3, markup**: righe 395-398, `<div class="navbar"><div class="back">…</div><div
  class="roomseg">…</div></div>` — **due soli figli**, nessun home.
- **Freeze rev3, CSS**: riga 150, `.navbar{…justify-content:space-between…}`. Con due soli figli
  flex e `space-between`, il primo va all'estremo sinistro, il secondo all'estremo destro.
- ⇒ **Codice e freeze concordano**: il dettaglio è disegnato a destra, non è una deriva del
  codice dal freeze.

---

## IL TICKET NUOVO — `TD-segmini-onswitch-morto`, TRE FACCE

Inserito in coda a §1.2 (🟠 OPEN MEDIA), subito dopo `TD-segmini-hitarea-sotto-44pt` — stessa
sezione, stesso criterio posizionale della convenzione.

**(a) Il fatto.** Morto e deliberato, con la citazione della classe di difetto già incisa
(`QLiveEmptyStates.swift:101-106`) e l'argomento del freeze stesso contro l'inerzia («un
componente solo… una misura sola»). ⛔ Dichiarato non riparabile ora, per istruzione di Mauro:
farlo funzionare è una decisione di prodotto (navigazione di stanza dentro il dettaglio), non
di codice.

**(b) L'allineamento.** Registrato come **divergenza fra decisione di prodotto e freeze**, non
come bug di codice. Mauro vuole i selettori centrali; il freeze rev3 — verificato riga per riga,
non solo a tabella — li disegna a destra nel dettaglio. La risoluzione dichiarata è una modifica
del **freeze**, da chiedere a CD, non una riga di layout. ⛔ Zero righe di layout toccate, in
nessun file — verificato: solo `BUGS_QBEATS.md` è nello stage.

**(c) L'area di tocco.** Il collegamento con `TD-segmini-hitarea-sotto-44pt` è scritto **nei due
sensi**, come richiesto: il ticket nuovo dichiara di bloccare la chiusura di quello di ieri; il
ticket di ieri riceve la marcatura additiva simmetrica (sotto).

**Severità proposta: 🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE PALCO.** Motivata nel ticket: MEDIA perché
viola una regola già scritta e la violazione è stata osservata **direttamente da Mauro**, non
ipotizzata; NON BLOCCANTE perché il sito è una schermata di selezione, mai attiva durante un
playback. **Il valore resta a Mauro.**

---

## LA CORREZIONE — MARCATURA ADDITIVA SU `TD-segmini-hitarea-sotto-44pt`

**Zero parole riscritte sopra**, come impone la convenzione: la marcatura è una riga nuova,
inserita **in coda al ticket**, subito prima di «Dominio:» — stessa collocazione già osservata
nel precedente `TD-emerg-bottone-morto` (marcature del 18/08, verificate a fonte prima di
scrivere la mia).

Dichiara: il dato **34pt < 44pt resta vero e misurato** — non è stato messo in discussione.
Cambia solo che il **collaudo sul device** (10 tocchi di fretta) non era eseguibile, e che
**questo ticket non può chiudersi prima di `TD-segmini-onswitch-morto`**.

---

## IL DIFF — VERBATIM E COMPLETO

```diff
diff --git a/BUGS_QBEATS.md b/BUGS_QBEATS.md
index b6fc5f4..f2fda9c 100644
--- a/BUGS_QBEATS.md
+++ b/BUGS_QBEATS.md
@@ -1,6 +1,6 @@
 # BUGS_QBEATS — Tracker centralizzato bug e tech debt
 
-**Versione:** 54
+**Versione:** 55
 **Ultima modifica:** 2026-08-19
 **Autore iniziale:** CC chat principale 26/05/2026 sera
 **Repo:** `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\`
@@ -415,8 +415,23 @@ Documento di riferimento **UNICO** per tutti i bug e tech debt (TD) Q-BEATS. Agg
 - ⚠️ **Dubbio strutturale in più, misurato e non risolto (già nel referto A129, non ripetuto qui per intero):** dal codice non è chiaro come l'area tappabile di una pill possa «restare 50pt» quando il contenitore (`segment`) usa `.frame(minHeight:)` — un minimo, non uno stiramento — dentro una navbar più alta. Se quella premessa non regge nemmeno per `.full`, la lacuna su `.segMini` è più grande di quanto sembri qui.
 - **Il rimedio non è automatico.** `hitExpansion` è gattato dal **RI-GATE S3** (commento a `RoomSwitchBar.swift:164-171`, invariato): l'espansione dentro la label del Button, che su `.full` porta il bersaglio a 54pt, è vietata su `.segMini` finché il ri-gate non prova la tecnica ristrutturata su `.full`. Applicarla oggi senza quel collaudo rischierebbe di ripetere il bug funzionale già trovato una volta (hit-area che si sovrappone fra le due pill — stesso file, righe :183-189). ⇒ **Serve un giro di progettazione + collaudo device dedicato, non una riga.**
 - **Stato: PROPOSTA di severità 🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE PALCO — il valore lo assegna MAURO, non è assegnato qui.** Motivo MEDIA: è sotto la soglia di accessibilità della piattaforma, su un controllo di navigazione reale, non un dettaglio cosmetico. Motivo NON BLOCCANTE: l'unico sito che lo monta è una schermata di **selezione show**, mai visibile mentre un playback è in corso — chi lo tocca per sbaglio cambia schermata, non perde audio né dati.
+- ⛔ **MARCATURA 19/08 — IL DATO 34pt<44pt RESTA VERO, MA LA MISURA SUL DEVICE È SOSPESA. Zero parole riscritte sopra: si marca.** Il gate device previsto per questo ticket (toccare il selettore dieci volte di fretta, con una mano) **non è stato eseguibile**: `TD-segmini-onswitch-morto` (nuovo, stesso giorno) misura che il pulsante non fa nulla al tocco — non c'è nulla da misurare finché resta muto. ⇒ **Questo ticket NON PUÒ CHIUDERSI prima di `TD-segmini-onswitch-morto`.** La misura statica (34pt di bersaglio, `hitExpansion` a zero) resta valida e non cambia: cambia solo che nessuno può ancora confermarla o smentirla sul telefono.
 - **Dominio:** CC (tecnica) + referee (RI-GATE S3, quando sblocca). Trovato durante A129, ticket aperto su mandato A130. Misura: `HANDOFF/MISURE_CC_2026-08-19_A129-TRE-CONFORMITA-GRAFICHE.md`. ⛔ **Nessun fix in questo giro.**
 
+### TD-segmini-onswitch-morto — il room switch del dettaglio non fa nulla al tocco, ed è disallineato dal freeze (🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE PALCO — **PROPOSTA, non assegnata: decide Mauro**)
+- **(a) IL FATTO — È MORTO, ED È DELIBERATO.** `QLiveShowDetailView.swift:127` monta `RoomSwitchBar(active: .qLive, onHome: {}, variant: .segMini)` e NON passa `onSwitch`, che a `RoomSwitchBar.swift:36` ha default `= {}`. Il commento a `:123-126` lo dichiara esplicitamente: «`onSwitch` resta al suo default no-op ⇒ INERTE come richiesto», su prescrizione della scheda di ⟦S5a⟧. **Misurato da Mauro sul device il 19/08: «se premo non succede nulla».** Gli ALTRI DUE siti che montano `RoomSwitchBar` PASSANO `onSwitch`: `QLiveShowsView.swift:78-83` (`onSwitch: onSwitchToStage`) e `QStage/ShowsListView.swift:82-90` (closure con log + `onSwitchToLive()`). ⇒ **il dettaglio è l'unico sito muto dell'app.**
+  - ⚠️ **CLASSE DI DIFETTO GIÀ NOTA AL PROGETTO — incisa per un altro pulsante, e qui si è materializzata:** `QLiveEmptyStates.swift:101-106`, «REGISTRO RESI — VINCOLO ESPLICITO PER S6»: «`onGoToQStage` è `() -> Void = {}`, un no-op silenzioso. Se S4/S6 dimenticano di cablarlo, il risultato è un bottone che si preme … e NON fa nulla — il compilatore non segnala nulla, perché il default è una closure sintatticamente valida. Non deducibile da qui … va verificato a schermo/integrazione.» Quella nota avvertiva del rischio in anticipo per un ALTRO bottone. Qui il rischio si è avverato per davvero: un parametro con default silenzioso, un sito che lo lascia al default, zero segnalazione dal compilatore, scoperto solo al tocco sul device.
+  - ⚠️ **ARGOMENTO CONTRARIO ALL'INERZIA, dal freeze stesso, rev3, callout «un controllo che il refuso non ritorni»:** «il room switch è un componente solo in tutta l'app, con una misura sola.» Un componente dichiarato UNO SOLO che si comporta in modo diverso in un terzo dei suoi siti (muto qui, vivo altrove) tradisce esattamente la premessa che lo ha reso uno solo.
+  - ⛔ **NON RIPARATO QUI, per istruzione esplicita di Mauro (19/08):** far funzionare il tocco significa portare una navigazione di stanza (Q-Stage↔Q-Live) fin dentro il dettaglio show — è una decisione di prodotto (dove va, cosa succede alla setlist aperta) prima che di codice. Questo mandato è **solo ticket**.
+- **(b) L'ALLINEAMENTO — DECISIONE DI MAURO CHE CONTRADDICE IL FREEZE. NON SI RIPARA ORA.** Misurato: `.full` centra il segmento in una `ZStack` (`RoomSwitchBar.swift:41-49`, il centraggio non dipende dalla presenza dell'home button) ⇒ Q-Stage e la lista Q-Live lo hanno **centrale**. Il dettaglio usa `.segMini` dentro `HStack { backButton; Spacer(); RoomSwitchBar(…) }` (`QLiveShowDetailView.swift:120-127`) ⇒ **a destra**.
+  - ⚠️ **IL FREEZE rev3 DISEGNA DESTRA, verificato sul markup E sul CSS, non solo sulla tabella:** la navbar del frame dettaglio ha **due soli figli**, `.back` e `.roomseg`, **nessun home** (`DESIGN/QLive_Nav/2026-08-06_QLive-Shows_FREEZE-CONSOLIDATO_390x844__rev3-NORMATIVA.html`, markup del frame ③); e `.navbar{…justify-content:space-between…}` — con due soli figli flex, il primo va all'estremo sinistro e il secondo all'estremo destro. Codice e freeze **concordano** sulla posizione attuale.
+  - ⚠️ **DECISIONE DI MAURO 19/08, verbale: «i selettori li voglio funzionanti E CENTRALI.»** Contraddice il freeze appena verificato.
+  - ⇒ **Il ticket registra che decisione di prodotto e freeze DIVERGONO.** La risoluzione è una **modifica del freeze da chiedere a CD**, non una modifica di codice: centrare ora verrebbe disfatto quando si costruirà il prossimo freeze — motivo dichiarato da Mauro per l'intero mandato: non si costruisce due volte la stessa cosa.
+  - ⛔ **NON toccato: zero righe di layout, in nessun file.**
+- **(c) L'AREA DI TOCCO — LEGA CON `TD-segmini-hitarea-sotto-44pt` (ieri, A130), NEI DUE SENSI.** Il gate device di quel ticket prevedeva un controllo — toccare il selettore ridotto dieci volte di fretta — che **non è stato eseguibile**: il pulsante non fa nulla, quindi non c'è nulla da misurare al tocco. ⇒ **Questo ticket BLOCCA la chiusura di `TD-segmini-hitarea-sotto-44pt`**: quel ticket non può chiudersi finché QUESTO non è risolto, perché la sua stessa misura sul device resta sospesa. Marcatura additiva incisa anche nell'altro ticket, per lo stesso motivo nel verso opposto.
+- **Stato: PROPOSTA di severità 🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE PALCO — il valore lo assegna MAURO, non è assegnato qui.** Motivo MEDIA: viola una classe di difetto già segnalata per iscritto nel progetto (`QLiveEmptyStates.swift:101-106`) e la violazione è stata osservata **direttamente da Mauro** sul device — non è un'ipotesi. Motivo NON BLOCCANTE: l'unico sito che lo monta è la schermata di **selezione show**, mai visibile durante un playback.
+- **Dominio:** CD (destinazione della navigazione dal dettaglio, e il disegno centrato) → poi CC (cablaggio, quando il nuovo freeze arriva). ⛔ **Nessun fix in questo giro, e nessuno finché il freeze che sostituirà queste schermate non è pronto** (istruzione di Mauro, 19/08). Misura: referto A132.
+
 ## 📦 1.3 — Backlog (🟡 OPEN BASSA)
 
 ### Ripresa da interruzione (telefonata) riparte da capo — single-device (🟡 OPEN BASSA / da tracciare)
@@ -1094,6 +1109,7 @@ Per data di chiusura, decrescente.
 | 52 | 2026-08-18 | Mauro + CC + referee | **Marcatura additiva su `TD-emerg-bottone-morto` — la regola violata cade, lo Stato cambia, la domanda ha risposta (doc-only, zero parole riscritte sopra).** «Regola violata — CD-Q7» falsa per questo ticket: CD-Q7 fu decisa per un pulsante solo (il «+» di Q-Stage) ed è eccettuata per i pulsanti in coda di lavoro di Q-Live — `LIBRO_MASTRO_QBEATS.md`, riga `2026-08-18`. Stato: da «da rimuovere» (implicito nella regola violata) a **«in attesa di destinazione, per scelta»** — dichiarazione di prodotto Mauro 18/08. La domanda «cosa deve fare emerg» ha risposta di prodotto: modalità dinamica Q-Live → versione a LISTA, stessa materia del `.viewtoggle` del dettaglio show. Fonte: `HANDOFF/MISURE_CC_2026-08-18_A92-METRONOMO.md`. Header bump 51→52. Doc-only. |
 | 53 | 2026-08-18 | Mauro + CC + referee | **Due ticket NUOVI + due marcature additive, doc-only, zero codice.** **(1)** `TD-countin-ratificato-mai-costruito` (§1.2): il count-in è ratificato in `LIBRO_MASTRO_QBEATS.md:166` con **tre** punti d'attivazione e **nessuno dei tre suona** — `startCountIn` è uno **stub** (`AudioEngine.swift:1560-1563`), fra le canzoni il rinvio è dichiarato nel codice (`SetlistRunner.swift:232`), e il campo `Song.countIn` si imposta ma non viene mai letto nei percorsi d'avvio (**0**, controllo positivo stesso ricevitore: `sections`→1, `name`→1). Il `countdown: 4` di `LiveView.swift:271` è il numero **ratificato mostrato senza suono**. **(2)** `TD-canonici-puntatori-path-stale` (§1.3): `BOX5_QBEATS.md:324` cita un percorso inesistente (`…/Audio/AudioEngine.swift`, **0 file**; il vero è senza `Audio/`, **1**) mentre riga e contenuto sono giusti. ⛔ **Aperto come ticket proprio e NON fuso** con `TD-doccomment-navigate-zero-chiamanti`: quello si chiude «nel primo atomo che apre quel file», questo in un giro doc-only — due condizioni che si escludono, e fonderle sarebbe «un nome per due contratti» (`LIBRO:334`). **Marcature:** `:167` — «il sesto è l'unico muto» **falsificato**, i tasti muti sono **quattro su sei** (`prevSection`/`nextSection`/`toggleLoop` sono funzioni vuote, `AudioEngine.swift:1267-1269`; controllo positivo `stopBacktrack` ha corpo vero `:1522-1526`); `:288` — «equivalente UI mid-play ESISTE ⇒ MIDI = mirror del TAP» **falsificato e URGENTE**: il tap esiste, l'effetto no, quindi il ticket **non può chiudersi cablando il MIDI**. ⚠️ Severità di entrambi i ticket **PROPOSTE, non assegnate**: decide Mauro. Header bump 52→53. |
 | 54 | 2026-08-19 | CC + referee | **Un ticket NUOVO in §1.2, doc-only, zero codice.** `TD-segmini-hitarea-sotto-44pt` — il pulsante del room switch in `.segMini` (`RoomSwitchBar.swift`) ha `minHeight` 34pt e `hitExpansion` sempre 0, bersaglio reale 34pt contro il minimo HIG di 44. NON regressione di A129 (era 30pt). Trovato durante A129 (tre conformità grafiche), aperto su mandato A130 del referee. Severità PROPOSTA 🟠 MEDIA / ⚠️ NON BLOCCANTE PALCO, decide Mauro. Header bump 53→54. |
+| 55 | 2026-08-19 | CC + referee | **Un ticket NUOVO in §1.2 + una marcatura additiva, doc-only, zero codice.** `TD-segmini-onswitch-morto` — il room switch del dettaglio (`QLiveShowDetailView.swift:127`) non passa `onSwitch` a `RoomSwitchBar`, che ha default `= {}`: il pulsante non fa nulla al tocco, misurato da Mauro sul device il 19/08. Stessa classe di difetto già segnalata per un altro bottone (`QLiveEmptyStates.swift:101-106`). Include anche il disallineamento: `.full` centra, `.segMini` è a destra come il freeze rev3 prescrive, ma Mauro vuole i selettori centrati — freeze e prodotto divergono, si chiede a CD. **Marcatura additiva su `TD-segmini-hitarea-sotto-44pt`:** il suo gate device (10 tocchi di fretta) non era eseguibile col pulsante muto — dipendenza incisa nei due sensi, nessuno dei due ticket si chiude da solo. Doc-only, zero riparazioni: istruzione esplicita di Mauro, il freeze 06/08 sostituirà queste schermate. Header bump 54→55. |
 
 ---
```

---

## FACCIA DEL CANONICO — PRIMA E DOPO

CR contati sui **byte** puri, mai con grep.

| | CR | LF | byte | |
|---|---:|---:|---:|---|
| **PRIMA** | 1100 | 1100 | 315 908 | uniforme (CRLF) |
| **DOPO** | 1116 | 1116 | 322 806 | uniforme (CRLF) |

---

## OGNI MODIFICA DI FORMA — DICHIARATA

**Una riga vuota nuova**, fra il ticket appena scritto e `## 📦 1.3` — è la stessa forma già
usata per separare ogni ticket dalla sezione successiva in tutto il documento (non introduce
un'incongruenza: è coerente con `TD-canonici-puntatori-path-stale`/`## 1.4`, verificato). Nessun
altro spazio bianco toccato oltre a quello del changelog che A131 aveva già dichiarato.

---

## CONTROPROVE — DUE, INDIPENDENTI, ENTRAMBE CON FALLIBILITÀ DIMOSTRATA

**CP-1, sul conteggio.** Il diff reale porta **+17 / −1**. Applicato prima a una dichiarazione
volutamente sbagliata (+18 invece di +17): **bocciata**. Sul conteggio vero, dichiarato
correttamente: **PASSA**.

**CP-2, ricostruzione byte-esatta — la prova che conta davvero.** Ho preso il blob a HEAD e gli
ho applicato **in sequenza, meccanicamente, i quattro edit dichiarati** (header · marcatura
additiva · ticket nuovo · riga di changelog), poi confrontato lo sha256 del risultato con lo
sha256 del file reale sul disco:

```
sha256 RICOSTRUITO (blob + 4 edit dichiarati): 4f6728c3246030eb0f27fb7f628f468e2bd8f563eb146807d20f1e85b87ce8d7
sha256 REALE (file sul disco)                : 4f6728c3246030eb0f27fb7f628f468e2bd8f563eb146807d20f1e85b87ce8d7
IDENTICI: True
```

⇒ **Ogni byte cambiato nel file è riconducibile a uno dei quattro edit dichiarati — nessuno di
più, nessuno di meno.** Dimostrazione di fallibilità: alterata la versione ricostruita da 55 a
56, lo sha256 diverge subito dal reale — il controllo sa fallire.

---

## LIMITI DICHIARATI

1. ⛔ **Nessuna delle due facce (a) e (b) è stata vista a schermo in questo giro** — sono misure
   di codice e di documento, non un collaudo device. Non serviva: il mandato è doc-only.
2. ⚠️ **La severità proposta (🟠 MEDIA) è un giudizio mio**, motivato nel ticket, non un fatto
   misurato: resta a Mauro.
3. ⚠️ **Non ho verificato se esistono ALTRI siti, oltre ai tre censiti, che costruiscono
   `RoomSwitchBar`** al di fuori di `ios_app/QBeats/UI/` — la sonda (`git grep`) copre tutto
   `ios_app/*.swift`, quindi il perimetro è l'intero corpus Swift, ma non ho ri-verificato che
   non esistano varianti costruite dinamicamente (reflection, factory) che sfuggirebbero a una
   sonda testuale. Ritengo il rischio nullo in questo corpus — nessun precedente di quel tipo —
   ma non l'ho escluso per misura diretta.

---

## STATO DI CONSEGNA

| | |
|---|---|
| commit / push | ⛔ **NESSUNO** |
| HEAD | `547017f7d4e4df9c5d5a84774b0ccfe63bc01b1d`, invariato |
| file toccati | **1** — `BUGS_QBEATS.md`, v54→v55 |
| `ios_app/` | **zero modifiche**, verificato (`git status` mostra un solo file modificato) |
| ticket | **+1** nuovo (`TD-segmini-onswitch-morto`) · **+1** marcatura additiva |

---

*A132-FINE*
