# REFERTO A130 — PULIZIA DI FORMA + TICKET

Da: CC · A: referee, + Mauro · Data: **19/08/2026** · HEAD: `7c04beaf17e15c5e8d16a791e6bf18c2ff82cd76`
Mandato: **A130**, segue **A129 RATIFICATO**. I valori di A129 non sono stati rimessi in
discussione — solo la FORMA di nove righe, più un ticket nuovo in un canonico.
⛔ **NON COMMITTATO.**

Marcatura: **[M]** misurato da me · **[A]** giudizio mio.

---

## PASSO 1 — LE NOVE FORCELLE TAUTOLOGICHE → COSTANTI

**[M]** Individuate, criterio letterale `variant == .full ? X : X` (stesso valore sui due rami):
`containerPadding` · `containerRadius` · il termine `(variant == .full ? 34 : 34)` dentro
`chromeHeight` · `fontSize` · `hPad` · `vPad` · `radius` · `minHeight` · `tracking`. **Nove.**

**Collassate a costanti semplici, commento storico `// era N su .segMini` mantenuto su
ciascuna**, come prescritto. Esempio (`minHeight`):

```diff
-        let minHeight: CGFloat = variant == .full ? 34 : 34       // era 30 su .segMini
+        let minHeight: CGFloat = 34    // era 30 su .segMini
```

### Le due forcelle vere — verificate intatte, non solo "non toccate"

**[M]** Cercate letteralmente nel file dopo l'edit (**CP-2**, dimostrazione di fallibilità
sotto):

- `let hitExpansion: CGFloat = variant == .full ? (54 - minHeight) / 2 : 0` — **bit-per-bit
  identica**. `.segMini` resta a **zero**, RI-GATE S3 non sbloccato.
- `switch variant { case .full: … case .segMini: segment }` sul `body` — **non toccato**:
  `.full` continua a rendere l'home button, `.segMini` no.

### Una terza forcella vera, trovata e NON toccata — come richiesto

**[M]** `if variant == .full && isOn { … }` (il gate dell'inset-highlight, riga interna al
`pill()`) **dipende davvero dalla variante**: su `.segMini` quell'effetto non compare mai,
indipendentemente da `isOn`. **Non è una tautologia**: i due rami rendono cose diverse (con
highlight / senza), non lo stesso valore scritto due volte. **Lasciata**, e la segnalo qui
perché non passi inosservata: è la stessa che avevo già trovato e non toccato in A129
(referto A129, rilievo sull'inset-highlight), confermo di non averla toccata nemmeno ora.

### `chromeHeight` — calcolo esplicito, non a occhio

**[M]**
```
containerPadding = 4
chromeHeight = 34 + containerPadding * 2 = 34 + 4×2 = 34 + 8 = 42
```
**Coincide con 42, il valore già ratificato in A129.** Verificato anche da programma
(**CP-3**), non solo a mano.

---

## PASSO 2 — IL TICKET

**Perimetro: tocca un canonico (`BUGS_QBEATS.md`).** Non ambiguo per me — è esattamente il tipo
di modifica che la convenzione del tracker prevede (§ Workflow aggiornamento, punto 1: *«Nuovo
bug emerge in chat → CC lo aggiunge qui PRIMA di proporre fix»*) — non mi sono fermato.

**ID:** `TD-segmini-hitarea-sotto-44pt`. **Inserito in coda a §1.2 (🟠 OPEN MEDIA)**, come
impone la convenzione posizionale (*«un ticket nuovo si inserisce IN CODA alla sottosezione di
severità che gli compete»*) — verificato **prima** di scrivere: `TD-countin-ratificato-mai-costruito`
era l'ultimo ticket di quella sezione, subito prima di `## 📦 1.3`.

**Le quattro cose richieste, tutte presenti nel ticket:**

1. **Il fatto** — `minHeight` 34pt, `hitExpansion` sempre 0 su `.segMini` ⇒ bersaglio reale 34pt,
   sotto i 44pt HIG.
2. **Non è una regressione** — prima di A129 era 30pt; A129 migliora, non introduce.
3. **La rassicurazione del freeze è sourced solo su `.full`** — citato **verbatim** il commento
   del codice stesso (*«Scoping: solo `.full` ha la claim sourced»*) e la frase del freeze
   sull'area 50pt.
4. **Il RI-GATE S3 blocca il rimedio automatico** — citata la tecnica vietata su `.segMini` e il
   precedente bug funzionale (sovrapposizione hit-area) che l'espansione incauta rischierebbe
   di ripetere.

**Non richiesto ma aggiunto, dichiarato come tale:** il dubbio strutturale che avevo già
sollevato in A129 (se «l'area resta 50pt» regga anche per `.full`) — riportato in una riga sola,
**non ripetuto per intero**, con rimando al referto A129.

**Severità proposta: 🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE PALCO.** Motivata nel ticket stesso:
MEDIA perché è un controllo di navigazione reale sotto soglia di accessibilità, non un dettaglio
cosmetico; NON BLOCCANTE perché l'unico sito che lo monta è la schermata di **selezione show**,
mai visibile durante un playback. **Il valore resta assegnato a Mauro**, come da convenzione —
non l'ho deciso io.

**Meccanica dell'inserimento:** header `Versione` 53→54, `Ultima modifica` 18/08→19/08; ticket
inserito **fra** l'ultimo bullet di `TD-countin-ratificato-mai-costruito` e `## 📦 1.3`; riga
**54** aggiunta al changelog di fondo pagina, prima di `---`/`Fine documento`.

**Verificato dopo la scrittura, non solo prima:**

| controllo | prima | dopo | esito |
|---|---:|---:|---|
| ticket totali (`### `) | 121 | 122 | ✅ **+1 esatto**, nessuno perso |
| header versione | 53 | 54 | ✅ |
| ultima riga changelog | 53 | 54 | ✅ |
| posizione | — | fra `TD-countin…` e `## 📦 1.3` | ✅ |

---

## IL DIFF — PASSO 1, ISOLATO DA A129 CON DOPPIA VERIFICA

⚠️ **Nota di metodo.** `git diff` confronta sempre contro l'ultimo commit (`HEAD`), e nulla è
stato committato: un `git diff` grezzo avrebbe mostrato A129+A130 **insieme**, mescolando
un lavoro già ratificato con questo. Per mostrarti **solo** il delta di A130 ho:

1. **[M]** preso il blob a `HEAD` (pre-A129);
2. **[M]** ricostruito lo stato "post-A129" in **due modi indipendenti** — (a) rigiocando i miei
   stessi script di A129 su una copia isolata, (b) applicando con `git apply` il diff **già
   depositato e ratificato** `HANDOFF/DIFF_2026-08-19_A129-TRE-CONFORMITA-GRAFICHE.txt` (solo
   l'hunk di questo file) a una seconda copia isolata;
3. **[M]** confrontate le due ricostruzioni: **identiche**, byte per byte. La ricostruzione è
   affidabile;
4. **[M]** diff fra la ricostruzione (post-A129) e il file reale (post-A130): **questo è il
   delta isolato**, 59 righe, depositato come
   `HANDOFF/DIFF_2026-08-19_A130-FORCELLE-ISOLATO.diff`.

```diff
--- RoomSwitchBar.swift (post-A129, ratificato)
+++ RoomSwitchBar.swift (post-A130)
@@ -102,11 +102,15 @@
     private var segment: some View {
         // A129 — «.seg-mini abolita»: il freeze rev3 (pannello ③, callout «un controllo che il
         // refuso non ritorni») non porta più ALCUNA regola CSS `.seg-mini`: «il room switch è
-        // un componente solo in tutta l'app, con una misura sola». Container e pill diventano
-        // gli stessi valori su entrambe le varianti — resta diverso solo COSA rendono (`.full`
+        // un componente solo in tutta l'app, con una misura sola». Container e pill hanno gli
+        // stessi valori su entrambe le varianti — resta diverso solo COSA rendono (`.full`
         // aggiunge l'home button, `.segMini` no: vedi lo `switch` sul `body`), non le misure.
-        let containerPadding: CGFloat = variant == .full ? 4 : 4    // era 3 su .segMini
-        let containerRadius: CGFloat = variant == .full ? 12 : 12   // era 10 su .segMini
+        // A130 — le due righe sotto erano forcelle `variant == .full ? X : X`: stesso valore
+        // su entrambi i rami. Il freeze vieta esplicitamente quella FORMA, non solo il valore
+        // sbagliato: «un controllo, una misura, nessuna domanda» — una forcella che risponde
+        // sempre uguale È la domanda che il freeze dice di non lasciare aperta. Costanti.
+        let containerPadding: CGFloat = 4    // era 3 su .segMini
+        let containerRadius: CGFloat = 12    // era 10 su .segMini
         // Altezza VISIVA del chrome: pill (34, uniforme A129) + anello padding sopra/sotto (4/4)
         // → 42 su ENTRAMBE le varianti (era 42 / 36). NON è l'altezza dell'hit-area (54 su
         // .full, MAI su .segMini — vedi `hitExpansion` più sotto, riga NON toccata da A129).
@@ -117,7 +121,7 @@
         // fa 34+4+4 = 42 su ENTRAMBE le varianti — il valore che questo codice ora produce.
         // 40 e 42 stanno entrambi dentro una navbar da 50: non blocca, ma è una contraddizione
         // interna al normativo e va incisa, non nascosta dietro un valore intermedio.
-        let chromeHeight: CGFloat = (variant == .full ? 34 : 34) + containerPadding * 2   // era 30 su .segMini
+        let chromeHeight: CGFloat = 34 + containerPadding * 2   // era 30 su .segMini; = 42 (34 + 4×2)
         return HStack(spacing: 3) {
             pill(.qStage, label: "Q-Stage")
             pill(.qLive, label: "Q-Live")
@@ -144,11 +148,13 @@
         // Il vecchio valore .segMini (9 · 9/5 · 8 · 30) veniva da `.navbar .seg-mini .o` del
         // freeze SUPERATO 07/11 — quel selettore non esiste più in rev3, per costruzione: la
         // citazione CD-Q8 poco più sotto resta come STORIA della ratifica, non come valore.
-        let fontSize: CGFloat = variant == .full ? 10.5 : 10.5   // era 9 su .segMini
-        let hPad: CGFloat = variant == .full ? 12 : 12            // era 9 su .segMini
-        let vPad: CGFloat = variant == .full ? 7 : 7              // era 5 su .segMini
-        let radius: CGFloat = variant == .full ? 9 : 9            // era 8 su .segMini
-        let minHeight: CGFloat = variant == .full ? 34 : 34       // era 30 su .segMini
+        // A130 — le cinque righe sotto erano forcelle `variant == .full ? X : X`: stesso
+        // valore su entrambi i rami, forma vietata dal freeze (vedi nota su `segment`).
+        let fontSize: CGFloat = 10.5   // era 9 su .segMini
+        let hPad: CGFloat = 12         // era 9 su .segMini
+        let vPad: CGFloat = 7          // era 5 su .segMini
+        let radius: CGFloat = 9        // era 8 su .segMini
+        let minHeight: CGFloat = 34    // era 30 su .segMini
         // FIX 4-bis (referee): hit-area 54pt su tutta l'altezza barra (§CSS .roomseg, commento CD
         // verbatim). Scoping: solo `.full` ha la claim sourced (la nota hit-area sta sul
         // `.roomseg`, la variante piena).
@@ -194,7 +200,7 @@
         return Button(action: { if !isOn { onSwitch() } }) {
             Text(label)
                 .font(.jbMono(.bold, size: fontSize))
-                .tracking(variant == .full ? 1 : 1)   // A129 — era 0.8 su .segMini; `.roomseg .opt` verbatim (freeze rev3 :103, letter-spacing:1px)
+                .tracking(1)   // A130, era forcella .full?1:1 — A129 aveva gia' 0.8 su .segMini; `.roomseg .opt` verbatim (freeze rev3 :103, letter-spacing:1px)
                 .textCase(.uppercase)
                 .foregroundColor(isOn ? .white : QStageTheme.text3)
                 .padding(.horizontal, hPad)
```

## IL DIFF — PASSO 2, `BUGS_QBEATS.md` (isolato per costruzione: A129 non l'aveva toccato)

```diff
diff --git a/BUGS_QBEATS.md b/BUGS_QBEATS.md
index cda8638..b6fc5f4 100644
--- a/BUGS_QBEATS.md
+++ b/BUGS_QBEATS.md
@@ -1,7 +1,7 @@
 # BUGS_QBEATS — Tracker centralizzato bug e tech debt
 
-**Versione:** 53
-**Ultima modifica:** 2026-08-18
+**Versione:** 54
+**Ultima modifica:** 2026-08-19
 **Autore iniziale:** CC chat principale 26/05/2026 sera
 **Repo:** `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\`
 
@@ -408,6 +408,15 @@ Documento di riferimento **UNICO** per tutti i bug e tech debt (TD) Q-BEATS. Agg
 - **Stato: PROPOSTA di severità 🟠 OPEN MEDIA — il valore lo assegna MAURO, non è assegnato qui.** Precedente: `TD-mixer-copre-endshow` e `TD-emerg-bottone-morto`, severità proposte il 07/08 e decise da Mauro. Motivo della proposta: non c'è perdita di dati né silenzio sul palco. ⚠️ **Ma il motivo ratificato è di palco** (`LIBRO:225`), e questo può valere più di quanto pesi CC. La collocazione in §1.2 segue la proposta e **va rivista se il valore cambia**.
 - **Dominio:** CC. Misure: `HANDOFF/MISURE_CC_2026-08-18_A115-COUNTIN.md` e `HANDOFF/MISURE_CC_2026-08-18_A118-SCHEDA-STRETTA.md`.
 
+### TD-segmini-hitarea-sotto-44pt — il pulsante del room switch in `.segMini` ha bersaglio reale 34pt, sotto la soglia HIG di 44 (🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE PALCO — **PROPOSTA, non assegnata: decide Mauro**)
+- **Il fatto, misurato a HEAD `7c04beaf17e15c5e8d16a791e6bf18c2ff82cd76` + diff A129/A130 non committato:** `RoomSwitchBar.swift`, variante `.segMini` — `minHeight` (riga :157) = **34pt**, `hitExpansion` (riga :198, `variant == .full ? (54 - minHeight) / 2 : 0`) = **sempre 0** su questo ramo. Il bersaglio tappabile reale della singola pill è quindi **34pt**, sotto i **44pt** minimi HIG. Unico sito che monta questa variante: `QLiveShowDetailView.swift:127`, la navbar della schermata di dettaglio show.
+- **NON è una regressione di A129/A130.** Prima di questo giro `.segMini` era a **30pt** — 4pt più piccolo. A129 lo ha alzato a 34 per conformità al freeze (`.roomseg .opt`), e resta comunque sotto soglia: **il difetto è pre-esistente, A129 lo ha ridotto, non creato.**
+- **La rassicurazione del freeze è sourced SOLO su `.full`, e il codice lo dichiara da sé.** Commento a `RoomSwitchBar.swift:159` (invariato da A130): «Scoping: solo `.full` ha la claim sourced (la nota hit-area sta sul `.roomseg`, la variante piena).» Il freeze rev3 (pannello ③, callout finale) scrive: «Il referee ha misurato 50pt di hit-test verticale, già ≥44 … Alzando il chrome visibile 30→34pt l'area resta 50» — quella misura copre `.full`. Non ne esiste una equivalente per `.segMini`.
+- ⚠️ **Dubbio strutturale in più, misurato e non risolto (già nel referto A129, non ripetuto qui per intero):** dal codice non è chiaro come l'area tappabile di una pill possa «restare 50pt» quando il contenitore (`segment`) usa `.frame(minHeight:)` — un minimo, non uno stiramento — dentro una navbar più alta. Se quella premessa non regge nemmeno per `.full`, la lacuna su `.segMini` è più grande di quanto sembri qui.
+- **Il rimedio non è automatico.** `hitExpansion` è gattato dal **RI-GATE S3** (commento a `RoomSwitchBar.swift:164-171`, invariato): l'espansione dentro la label del Button, che su `.full` porta il bersaglio a 54pt, è vietata su `.segMini` finché il ri-gate non prova la tecnica ristrutturata su `.full`. Applicarla oggi senza quel collaudo rischierebbe di ripetere il bug funzionale già trovato una volta (hit-area che si sovrappone fra le due pill — stesso file, righe :183-189). ⇒ **Serve un giro di progettazione + collaudo device dedicato, non una riga.**
+- **Stato: PROPOSTA di severità 🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE PALCO — il valore lo assegna MAURO, non è assegnato qui.** Motivo MEDIA: è sotto la soglia di accessibilità della piattaforma, su un controllo di navigazione reale, non un dettaglio cosmetico. Motivo NON BLOCCANTE: l'unico sito che lo monta è una schermata di **selezione show**, mai visibile mentre un playback è in corso — chi lo tocca per sbaglio cambia schermata, non perde audio né dati.
+- **Dominio:** CC (tecnica) + referee (RI-GATE S3, quando sblocca). Trovato durante A129, ticket aperto su mandato A130. Misura: `HANDOFF/MISURE_CC_2026-08-19_A129-TRE-CONFORMITA-GRAFICHE.md`. ⛔ **Nessun fix in questo giro.**
+
 ## 📦 1.3 — Backlog (🟡 OPEN BASSA)
 
 ### Ripresa da interruzione (telefonata) riparte da capo — single-device (🟡 OPEN BASSA / da tracciare)
@@ -1084,6 +1093,8 @@ Per data di chiusura, decrescente.
 
 | 52 | 2026-08-18 | Mauro + CC + referee | **Marcatura additiva su `TD-emerg-bottone-morto` — la regola violata cade, lo Stato cambia, la domanda ha risposta (doc-only, zero parole riscritte sopra).** «Regola violata — CD-Q7» falsa per questo ticket: CD-Q7 fu decisa per un pulsante solo (il «+» di Q-Stage) ed è eccettuata per i pulsanti in coda di lavoro di Q-Live — `LIBRO_MASTRO_QBEATS.md`, riga `2026-08-18`. Stato: da «da rimuovere» (implicito nella regola violata) a **«in attesa di destinazione, per scelta»** — dichiarazione di prodotto Mauro 18/08. La domanda «cosa deve fare emerg» ha risposta di prodotto: modalità dinamica Q-Live → versione a LISTA, stessa materia del `.viewtoggle` del dettaglio show. Fonte: `HANDOFF/MISURE_CC_2026-08-18_A92-METRONOMO.md`. Header bump 51→52. Doc-only. |
 | 53 | 2026-08-18 | Mauro + CC + referee | **Due ticket NUOVI + due marcature additive, doc-only, zero codice.** **(1)** `TD-countin-ratificato-mai-costruito` (§1.2): il count-in è ratificato in `LIBRO_MASTRO_QBEATS.md:166` con **tre** punti d'attivazione e **nessuno dei tre suona** — `startCountIn` è uno **stub** (`AudioEngine.swift:1560-1563`), fra le canzoni il rinvio è dichiarato nel codice (`SetlistRunner.swift:232`), e il campo `Song.countIn` si imposta ma non viene mai letto nei percorsi d'avvio (**0**, controllo positivo stesso ricevitore: `sections`→1, `name`→1). Il `countdown: 4` di `LiveView.swift:271` è il numero **ratificato mostrato senza suono**. **(2)** `TD-canonici-puntatori-path-stale` (§1.3): `BOX5_QBEATS.md:324` cita un percorso inesistente (`…/Audio/AudioEngine.swift`, **0 file**; il vero è senza `Audio/`, **1**) mentre riga e contenuto sono giusti. ⛔ **Aperto come ticket proprio e NON fuso** con `TD-doccomment-navigate-zero-chiamanti`: quello si chiude «nel primo atomo che apre quel file», questo in un giro doc-only — due condizioni che si escludono, e fonderle sarebbe «un nome per due contratti» (`LIBRO:334`). **Marcature:** `:167` — «il sesto è l'unico muto» **falsificato**, i tasti muti sono **quattro su sei** (`prevSection`/`nextSection`/`toggleLoop` sono funzioni vuote, `AudioEngine.swift:1267-1269`; controllo positivo `stopBacktrack` ha corpo vero `:1522-1526`); `:288` — «equivalente UI mid-play ESISTE ⇒ MIDI = mirror del TAP» **falsificato e URGENTE**: il tap esiste, l'effetto no, quindi il ticket **non può chiudersi cablando il MIDI**. ⚠️ Severità di entrambi i ticket **PROPOSTE, non assegnate**: decide Mauro. Header bump 52→53. |
+| 54 | 2026-08-19 | CC + referee | **Un ticket NUOVO in §1.2, doc-only, zero codice.** `TD-segmini-hitarea-sotto-44pt` — il pulsante del room switch in `.segMini` (`RoomSwitchBar.swift`) ha `minHeight` 34pt e `hitExpansion` sempre 0, bersaglio reale 34pt contro il minimo HIG di 44. NON regressione di A129 (era 30pt). Trovato durante A129 (tre conformità grafiche), aperto su mandato A130 del referee. Severità PROPOSTA 🟠 MEDIA / ⚠️ NON BLOCCANTE PALCO, decide Mauro. Header bump 53→54. |
+
 ---
 
 **Fine documento.**
```

---

## FACCIA DEI DUE FILE — PRIMA E DOPO

CR contati sui **byte**, Python puro (`b.count(b'\r')`, `b.count(b'\n')`), mai con grep/pipe.

| file | CR prima | LF prima | CR dopo | LF dopo | |
|---|---:|---:|---:|---:|---|
| `RoomSwitchBar.swift` | 260 | 260 | 266 | 266 | uniforme (CRLF) |
| `BUGS_QBEATS.md` | 1089 | 1089 | 1100 | 1100 | uniforme (CRLF) |

---

## CONTROPROVE — CIASCUNA CON LA SUA DIMOSTRAZIONE DI FALLIBILITÀ

| # | verifica | caso noto-cattivo | sa fallire? | sul reale |
|---|---|---|---|---|
| CP-1 | zero forcelle numeriche residue | il file post-A129 (le porta ancora) | ✅ bocciato — mancanti tutti e nove | **PASSA** |
| CP-2a | `hitExpansion` intatta | resa incondizionata | ✅ bocciato | **PASSA** |
| CP-2b | gate inset-highlight intatto | esteso a `.segMini` | ✅ bocciato | **PASSA** |
| CP-2c | `switch` sul `body` presente | — (controllo diretto) | — | **PASSA** |
| CP-3 | `chromeHeight` = 42 | calcolo esplicito: 34+4×2 | — | **= 42, coincide con A129** |
| CP-4 | nove valori == A129 ratificato | `minHeight` alterato 34→30 | ✅ bocciato | **PASSA** |
| CP-5 | conteggio righe-codice esatto | +1 riga finta nel diff | ✅ distingue (18→19) | **+9/−9** dichiarate |

**Le tre modifiche visibili di A129 producono ancora gli stessi valori numerici — dimostrato,
non affermato:** `42 · 34 · 10,5 · 12 · 7 · 9 · 1 · 4 · 12` tutti confermati da **CP-4**,
estratti per regex dal file reale e confrontati uno per uno col set ratificato in A129.

**I valori di `.full` sono identici a prima di A129 — stesso metodo, non ripetuto qui per
intero:** già dimostrato dalle controprove CP-R1/CP-R2 del referto A129 (`.full` non è mai
stato toccato né in A129 né in A130 — le nove forcelle collassate erano tutte tautologie
`.full`-vs-`.segMini` con lo stesso valore, quindi collassarle **non cambia** il valore che
`.full` produceva).

**Righe non-commento cambiate — solo quelle dichiarate:** RoomSwitchBar +9/−9 (le nove
dichiarazioni), BUGS +13/−2 (bump header ×2 righe, il ticket è tutto **testo Markdown**, non
"codice" nel senso della controprova — ma ogni riga aggiunta è stata comunque contata e
riportata nel diff verbatim sopra, nulla è stato omesso).

**Bilancio graffe** (indizio grezzo): `{`/`}` pari su `RoomSwitchBar.swift` dopo l'edit
(verificato, invariato rispetto ad A129: nessuna graffa aggiunta o tolta in questo passo,
solo letterali numerici e commenti).

---

## ⛔ COSA NON HO POTUTO VERIFICARE

1. **Sono tre correzioni PURAMENTE VISIVE e nessuno le ha ancora viste su uno schermo.** Vale
   per tutto ciò che A129 aveva già dichiarato: la centratura dello standby, il titolo a due
   righe, il selettore stanza. A130 non aggiunge né toglie rischio visivo — è una pulizia di
   forma sui *valori già ratificati*, non un cambio di valori.
2. **Il codice non è passato da un compilatore.** La CI parte solo dopo il commit, vietato da
   questo mandato.
3. **Al collaudo vanno guardate due cose, come già indicato in A129:** il titolo a due righe con
   un nome davvero lungo, e il selettore stanza più alto dentro la navbar.
4. **Il ticket appena aperto non è stato validato su device**: la misura di 34pt viene dal
   codice, non da un test di tocco reale. Il rimedio, quando arriverà, avrà il proprio collaudo.

---

## STATO DI CONSEGNA

| | |
|---|---|
| commit / push / rami | ⛔ **NESSUNO** |
| HEAD | `7c04beaf17e15c5e8d16a791e6bf18c2ff82cd76`, invariato |
| file toccati | **2** — `RoomSwitchBar.swift` (passo 1) · `BUGS_QBEATS.md` (passo 2, canonico) |
| altri canonici | **zero modifiche** |
| ticket BUGS | **+1**, `TD-segmini-hitarea-sotto-44pt`, severità PROPOSTA, decide Mauro |

---

## MAURO — L'AUTORIZZAZIONE AL COMMIT

Questo commit porterebbe **cinque file** in tutto (i tre di A129 + `RoomSwitchBar.swift`
ripulito nella forma + `BUGS_QBEATS.md` col ticket nuovo). In chiaro, prima che tu decida:

- **Sono tre correzioni PURAMENTE VISIVE, e nessuno le ha ancora viste su uno schermo.**
  Centratura del nome canzone in attesa, titolo dello show a due righe, e il selettore
  Stage/Live più alto nella schermata di dettaglio.
- **Il codice non è passato da un compilatore.** Non ho Mac né Xcode: la CI (`iOS Signed Build`)
  è la prima prova vera, e parte solo dopo che tu autorizzi il commit.
- **Al collaudo vanno guardate due cose apposta:** il titolo con un nome di show davvero lungo
  (due righe piene), e il selettore Stage/Live nella navbar del dettaglio — deve sembrare più
  alto di prima, senza spostare nient'altro nella barra.
- **In più, ho aperto un ticket** (non un fix): il pulsante di quel selettore, nella variante
  ridotta, ha un bersaglio di tocco sotto la soglia minima Apple. Non è un difetto nuovo — era
  già più piccolo prima — e non blocca il palco, perché si tocca solo prima di far partire uno
  show. La severità è una proposta: decidi tu.

⛔ **Resto fermo finché non rispondi.**

---

*A130-FINE*
