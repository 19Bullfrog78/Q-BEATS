# Q-BEATS — HANDOFF REFEREE — 27/07/2026, sera

Vige la Costituzione V5 e §7 FONTE-O-NIENTE. Se questo file e i canonici divergono,
**vincono i canonici**. Stato vivo: leggi-per-primo BOX3.

**RUOLI** — Mauro (decisore/tester, unico committer, TRAMITE fra i ruoli, **non è
developer**) · REFEREE (ultima parola tecnica, **nessun accesso a dischi o repo**) ·
CC (ha il repo) · CD (design/UX; scrive nel proprio progetto, la copia su E: la fa
Mauro a mano e può ritardare).

---

## 0 · COME LEGGERE QUESTO FILE

`[V]` = **misurato dal referee uscente con le proprie mani**, sui file caricati nel
Progetto Claude. È un numero calcolato, non un racconto.
`[R]` = riportato da CC, da CD o da Mauro. Il referee non vede i dischi: **ogni fatto
su file, git o E: è per costruzione un resoconto** finché CC non lo misura.

Non c'è una terza categoria. Una riga senza marcatore è un errore di questo file e va
trattata come `[R]`.

⚠️ **Il referee uscente ha sbagliato tre volte oggi** (§6). Tutte e tre le volte
l'errore aveva la stessa forma: plausibile, non misurato. Nessuna è arrivata a un
canonico perché CC aveva le mani sui file e ha controllato. **Dove CC non può misurare
— design, processo, regole inventate dal referee — quel cancello non esiste.** Chi
legge non deve fidarsi di questo file più di quanto io mi sia fidato di quello che ho
ricevuto stamattina.

---

## 1 · LA COSA PIÙ IMPORTANTE — la malattia di questo progetto

In tre giorni sono state contate **quattordici istanze** di un solo modo di sbagliare,
distribuite su tutti e quattro i ruoli — Mauro compreso, referee compreso:

> **Non sbagliamo dicendo cose false. Sbagliamo dicendo cose vere senza averle
> misurate.**

Esempi, tutti reali e tutti di oggi:

- una clausola in LIBRO diceva «file non depositato su E:»: era una dichiarazione di
  CD mai verificata. Il file c'era;
- «CR = 0» dichiarato dal referee e da CC: il comando usato (`grep -c $'\r'`) rende **0
  su qualunque file**, LF o CRLF. La conclusione era vera, la prova era vuota;
- LIBRO r.305 ancorava una riga di codice a `54ccddc`, un commit di **documentazione**
  che quel file non l'ha mai toccato;
- un sigillo «decisione CD» su una forma dell'alert mai ratificata da nessuno;
- CD ha misurato altezze su una pagina non ricaricata, e in un altro giro ha letto
  `el.style.left` (vuoto per gli elementi che prendono il left dal CSS);
- CC ha generalizzato una soglia di troncamento da un caso solo — la misura reale la
  falsificava con un caso che aveva già in mano;
- il referee ha dedotto quale valore usasse una classe CSS **da un totale aggregato**;
- il referee ha dato un conteggio («16») **senza dichiarare l'ambito**;
- un reperto stava **dentro un controllo positivo** e nessuno l'ha letto, perché quel
  comando lo si guardava per un altro motivo.

Il difetto è difficile da vedere **perché il risultato è quasi sempre giusto**. Lo è
finché un giorno non lo è, e quel giorno non c'è niente che lo intercetti.

**Corollario operativo, già applicato oggi:** una rettifica si motiva con la **mancanza
di misura**, non con la falsità dell'esito. Motivata sull'esito è deperibile — se
domani la misura cambia, la rettifica diventa a sua volta falsa. Motivata sulla
provenienza è vera per sempre.

---

## 2 · STATO — dove siamo davvero

**ZERO codice dal 23/07.** Ultimo commit di codice `ee31281` (⟦FIX-PILL⟧). Quattro
giorni di soli documenti, gli ultimi due spesi a **verificare come verifichiamo**.

`[V]` **Canonici, misurati sulle copie del Progetto** (impronte calcolate dal referee,
`CR` misurato con `tr -cd '\r' | wc -c`, **mai con grep** — vedi §6):

| documento | byte | sha256 | righe (`wc -l`) | CR |
|---|---|---|---|---|
| LIBRO_MASTRO v41 | 141.762 | `e096cbc6…5e86922` | 444 | 0 |
| BOX3 V99 | 89.457 | `c728bacc…4d29fb3c` | 803 | 0 |
| BUGS v43 | 195.668 | `2fcf1d06…238f438f` | 882 | 0 |
| BOX5 V27 | 34.541 | `852a7269…8c6b7afa` | 474 | 0 |
| SCALETTA v2 | 20.750 | `d2cdf120…d6a60437` | 183 | 0 |
| NODO_A piano | 14.760 | `5dfbb365…4c64d72c` | 92 | 0 |
| Costituzione V5 | 5.812 | `e4b3b26b…12dea6b1` | 101 | 0 |

`[R]` HEAD = `8fa50189b13f49ba3b291510f7d1a388d75b5909` (LIBRO v41, CI verde).

⚠️ **Convenzione righe, inchiodata oggi**: `righe = terminatori = wc -l sul BLOB`.
Lo stesso file rende 444 (terminatori), 445 (campi), 367 (righe non vuote), 4499 (un
`od` malusato). **La quarta impronta del cancello di scrittura deve portare scritto il
proprio nome**: `righe(terminatori, wc -l sul blob) = 444`, mai un numero nudo.
⚠️ La taratura in BOX3 V99 (e) usa la convenzione **campi** (= `wc -l` + 1) e uno dei
sei numeri fu letto a una versione superata (BUGS 874 = v41, non v42). Si **marca**,
non si rettifica: i numeri sono corretti nella loro convenzione.

---

## 3 · RATIFICATO OGGI, IN ATTESA DEL SOLO ATTO DI SCRITTURA

**Il primo cancello è chiuso: il referee ha ratificato. Il secondo cancello — l'OK di
Mauro — era in corso a fine giornata.** Verificare con Mauro prima di far scrivere.

Cinque righe per **LIBRO Sez.2**, prodotte da CC, verificate a fonte, ratificate.
Sono qui **verbatim** perché domani CC potrebbe essere una sessione nuova e non
averle più. Non riassumerle: si incidono così.

### Riga ① — PALETTE ANNOTAZIONI CD

```
| 2026-07-27 | **PALETTE ANNOTAZIONI CD — chiusa a 4 voci.** `pro` verde `#28cd41` · `con` rosso scuro `#b1281f` · `warn` ambra `#f5b820` · `asse`/`fatto`: la **chiave `#ffd35a` è l'invariante**, il fondo scala col peso del contenitore — riga in colonna `#16140f` · banda autonoma `#1c1608` · carta d'identità `#1b1a16`→`#131210`. Due clausole, entrambe vincolanti. **(1) Le coincidenze di VALORE sono permesse e attese:** `#28cd41` è accento di componente dentro la cornice (slot metronomo, BOX5 V27 r.167 da V21) e «pro» fuori — stesso numero, due ruoli legittimi. Vietato solo che un valore cambi ruolo **restando dallo stesso lato**. **(2) Un valore che identifica un AMBIENTE — `blue` `#2a6bd6` Q-Stage · `orange` `#d43f00` Q-Live · `teal` `#17a8a8` Q-Studio — non compare mai fuori dal PROPRIO ambiente: né fuori dalla cornice, né nel codice di un'altra stanza.** La formulazione stretta («mai fuori dalla cornice») è falsificata da una misura di CC: `#2a6bd6`, accento Q-Stage, è hardcoded in una vista di Q-**Live** (`LiveHeaderView.swift:107,109`, dentro `if false`) — dentro la cornice, nella stanza sbagliata. Stesso errore del blu usato per un'annotazione, commesso nel codice. Un accento di COMPONENTE non porta identità di ambiente e resta sotto la (1). Quinta voce = ratifica propria. Mauro: «si approvo» | Mauro | ⚠️ **La ratifica è stata presa su uno stato del documento che non esiste più.** Al «si approvo» il payload era `df55ccdc…9489115` (7444 B), **distrutto per sovrascrittura in place il 27/07 alle 20:14** e non più presente su alcun supporto (scansione dei 615 file sotto `E:\…\FILE X CLAUDE.MD`, controllo positivo su lunghezza 13092 → 2 match). Fonte citabile oggi: `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\DA_CD_PER_CC\27_07_2026\27_07_2026_g3\2026-07-27_BOX5-V28__Token-Colore-PAYLOAD.md` sha256 `b5f40d9e…b46a891e` (13092 B), che **incorpora una correzione POSTERIORE alla ratifica** — il ritiro della clausola falsa «non è UI, non finisce mai in `.swift`» — la quale **non altera ciò che Mauro ha ratificato**: le quattro voci e il confine. **La catena non è rotta:** la clausola ritirata sopravvive *dentro* `b5f40d9e…` alla sua riga 65, citata verbatim e marcata falsa, quindi il delta fra le due versioni è verificabile senza il file perduto | attiva | — |
```

🔴 **MODIFICA OBBLIGATORIA alla cella Doc ref di ①, condizione della ratifica.**
`[V]` Il referee ha misurato il payload `b5f40d9e…`: **non contiene la clausola (2)
nella forma generalizzata**. Si ferma al corollario di r.101; `LiveHeaderView`, «altra
stanza», «proprio ambiente» → **zero occorrenze**. Va aggiunto alla cella:

> la clausola (2) nella forma generalizzata **non viene dal payload**: nasce da una
> misura di CC sul sorgente — `#2a6bd6` a
> `ios_app/QBeats/UI/Live/LiveHeaderView.swift:107,109 @ 8fa5018`, dentro `if false`.
> Il payload sostiene la palette e la clausola base; la generalizzazione sta in piedi
> sul codice.

⚠️ Lo sha **deve** essere attaccato: un riferimento per riga senza commit è la trappola
in cui è caduta la riga 305 di LIBRO. Il diff verbatim prima del commit è il punto in
cui questa modifica si verifica.

### Riga ② — REGOLA DENTRO/FUORI LA CORNICE

```
| 2026-07-27 | **REGOLA DENTRO/FUORI LA CORNICE — nei deliverable CD.** **Dentro** il disegno del telefono si rende ciò che l'utente vedrà: colori di sistema iOS + token dell'app. **Fuori**, la palette annotazioni chiusa a 4 voci. Il confine **non** vieta le coincidenze di valore — le prevede (clausola 1 della riga `2026-07-27` **PALETTE ANNOTAZIONI CD**). Vieta tre cose: **(a)** che un valore identificativo di ambiente esca dal proprio ambiente (clausola 2); **(b)** che un colore inventato entri da un lato qualsiasi — se un'annotazione ha bisogno di un colore che non esiste, non si inventa: si chiede la ratifica; **(c)** che un valore cambi ruolo restando dallo stesso lato. Mauro: «si approvo» | Mauro | ⚠️ **Stessa avvertenza della riga PALETTE ANNOTAZIONI CD, stesso documento:** ratifica presa su `df55ccdc…9489115` (7444 B), **distrutto per sovrascrittura in place il 27/07 alle 20:14**, assente da 615 file scansionati (controllo positivo eseguito). Fonte citabile oggi: `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\DA_CD_PER_CC\27_07_2026\27_07_2026_g3\2026-07-27_BOX5-V28__Token-Colore-PAYLOAD.md` sha256 `b5f40d9e…b46a891e` (13092 B), che porta una correzione **posteriore** alla ratifica e **non incidente** su ciò che è stato ratificato. Delta ricostruibile dall'interno: la clausola ritirata è citata verbatim alla riga 65 del file vivo | attiva | — |
```

### Riga ③ — FORMA POPUP REMOVE

```
| 2026-07-27 | **FORMA POPUP REMOVE — Mauro sceglie ②** (riquadro centrale, due bottoni impilati). Proprietà attribuite al FILE, non a Mauro: `Ordine` Remove in alto / Cancel in basso · `Default` Cancel, in basso e in grassetto · `Distruttivo` in cima, isolato · `Tap fuori` NON chiude (r.252, r.257, r.278). Nessuna collisione col congedo-tastiera Q20: lo stesso file marca ② «identico a ①». ⚠️ **PENDENZA:** il file (r.255) segnala che iOS impila i due bottoni da sé solo con etichette lunghe; con «Cancel»/«Remove» corte l'esito nativo atteso è affiancato — servirebbe il foglio dal basso (③, non scelta) o un contenitore custom con focus/VoiceOver/tap-fuori/ritorno da rifare a mano. **Si chiude solo con documentazione ufficiale Apple (URL) o prova su device.** **Alla riemissione di C imposta da quella verifica: correggere `#f3e2c0` → `#f3e2b0` in `.q20b`** — un carattere di scarto da `.gatebox`, nato oggi, misurato a fonte (stesso fondo `#1c1608`, stesso bordo, diverge solo il testo). **NON incisa la clausola «pattern per ogni conferma futura»**: impegnerebbe ogni conferma distruttiva successiva a un contenitore custom prima di sapere se serve. Copy invariata (`0f90dae6…`). Mauro: «② Riquadro al centro, due bottoni uno sopra l'altro» | Mauro | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\DA_CD_PER_CC\27_07_2026\27_07_2026_g3\2026-07-27_Alert-Distruttivo-FORMA__3-vie.html` sha256 `9c3ea2bf…dc1edd` (43464 B) — stesso file, byte-identico, anche in `…\27_07_2026\UPDATE2\` | attiva | — |
```

### Riga ④ — CONTRATTO Q20 RICONFERMATO

```
| 2026-07-27 | **CONTRATTO Q20 — RICONFERMATO SUL CONTENUTO RILETTO.** La ratifica è **già agli atti** alla riga `2026-07-26` **CONTRATTO Q20** (`Mauro: «ok va bene»`, stato `attiva`): questa riga **non la ripara e non la sposta**. Il 27/07 Mauro ha riletto il contratto per intero — «Done» su toolbar pinnata · in aggiunta tap fuori e swipe giù · Return = «Search», conferma **e** congeda · il congedo conserva query, filtro, scroll e selezione, a svuotare è solo la «×» — e ha confermato: «SI VA BENE». 🔴 **IL BLOCCO SU ⟦S4L⟧ RESTA IN PIEDI.** Il `🔴 blocca ⟦S4L⟧` di r.304 è attaccato a «Chiude `TD-qlive-search-keyboard-trap` **a codice fatto**»: riguarda la **costruzione**, non la decisione. Ratificare il contratto **sblocca** l'atomo e lo rende costruibile; **non lo costruisce**. Finché il congedo non è nell'app e provato su device, a ⟦S4L⟧ l'utente resta con la tastiera alzata e l'unica uscita spegne la sessione del metronomo — sul palco. Cade **solo** la clausola dei deliverable CD «NON incidere come chiusa finché Mauro non ratifica». ⚠️ I due file CD che marcano Q20 «APERTA» (`2026-07-27_QL-SHOWS-01-10__RIEMISSIONE.html` riga QL-SHOWS-10 · `2026-07-26_…Q20-RIEMISSIONE.html`) sono **superati su questo solo punto**: si registra qui, **non si fa riemettere niente**. | Mauro | questa ratifica (27/07) — fonte primaria; contratto in `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\DA_CD_PER_CC\26_07_2026\2026-07-26_QLive-Shows-Keyboard-Dismiss__Q20-RIEMISSIONE.html` sha256 `5dcfbbfb…5ab9d408` (37430 B) | attiva | — |
```

### Riga ⑤ — CHIP «Read-only» RIMOSSO

```
| 2026-07-27 | **CHIP «Read-only» in testa alla lista Q-Live — RIMOSSO.** Via A delle tre proposte da CD. Motivo: dal giorno in cui Remove esiste, «sola lettura» non è più vero — e la riga `2026-07-26` **EMENDAMENTO ALL'INVARIANTE** (Q-Live cessa di essere di sola lettura) l'ha già sciolto. Mauro: «TOGLILA E BASTA». 🔴 **DUE CHIP DIVERSI, da non confondere in nessuna citazione futura:** «**Read-only**», testata della lista Q-Live → **RIMOSSO da qui**; «**Not in Q-Live**», chip sulla riga in Q-Stage → **RESTA**, ed è il vincolo duro di spedizione di Remove — riga `2026-07-26` **COPY POPUP REMOVE**, quella che contiene «**REMOVE NON SI SPEDISCE SENZA IL CHIP**» e supersede la postilla 1. ⚠️ **La citazione richiede il terzo discriminante:** a quella data esistono due righe che nominano il chip «Not in Q-Live» — la postilla 1 (`superseded`) e questa (`attiva`); titolo e data **non bastano**, e nemmeno il nome del chip. Toglierne uno non tocca l'altro. ⚠️ I mockup CD che mostrano ancora «Read-only» sono **superati su questo solo punto** e **NON vanno riemessi ora**: si correggono al primo tocco utile di ciascuno. Scritto perché nessuno lo ricostruisca leggendo un disegno vecchio. | Mauro | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\DA_CD_PER_CC\27_07_2026\UPDATE\2026-07-27_QLive-Shows-Read-only-Chip__3-vie.html` sha256 `646d0aa7…bc0d83ef` (45484 B) — byte-identico anche in `…\27_07_2026\UPDATE2\`; ⚠️ **NON presente** in `…\27_07_2026\27_07_2026_g3\`, la cartella coerente del terzo giro | attiva | — |
```

### Più: la rettifica che aspetta il prossimo tocco di LIBRO

**Due voci, non una.** Ratificate ma mai incise: LIBRO r.194 vieta di cancellare
righe, quindi si **aggiungono**.

1. **Clausola di deposito mai misurata** (riga `2026-07-27` «opzione A-bis», r.308).
   ⚠️ Motivare con la **mancanza di misura**, non con la falsità: se il file non ci
   fosse stato, la riga sarebbe stata vera **e ugualmente illegittima**. §7 non ammette
   eccezioni di segno — una negazione di deposito è una misura come un'affermazione, o
   non entra. A misura (CC, 27/07) il file è in `DA_CD_PER_CC\27_07_2026\`, 40367 B,
   sha256 `6455c8a9…1d2e19fc`. Impronta e byte restano corretti, la ratifica A-bis è
   invariata: cade la sola clausola di non-deposito.
2. **Ancora sbagliata** (riga `2026-07-26` «TAB-RESET Q-STAGE», r.305). `[R]` CC:
   `54ccddc` è un commit di **documentazione** che non tocca `QStageRootView.swift`.
   L'ancora corretta è `ee31281`, e la citazione va **per simbolo**
   (`@State private var tab: Tab = .songs`), non per riga. ⚠️ Da correggere in **LIBRO**,
   non in BUGS: BUGS r.546 cita già per simbolo, cioè nella forma giusta.
3. **Risposta CD sulla variante `-standalone`** (r.291, stato `attiva`, «Decisione CD
   attesa»): `[R]` CD ha risposto **NON-NORMATIVA** — non entra nel repo, «farlo entrare
   adesso ratificherebbe per via di deposito ciò che non è passato da una decisione».
   Da incidere.

### La sezione BOX5 «Token visivi», e il ticket

Entrambi prodotti da CC e ratificati. Vivono verbatim nell'artefatto
`MISURE_G3_INVENTARIO-E-TICKET_2026-07-27.txt` (`532e4a78…`, 10971 B) e nel corpo della
chat del 27/07. La sezione è **cinque righe** e rimanda al codice invece di duplicarlo;
il ticket è `TD-design-system-non-ancorato`, 🟡 bassa, **dopo §6**, con dieci voci.

---

## 4 · IL GIRO DOC — ordine e taglie vere

**B3 · BOX5 V28 — NON è iniziato.** Oggi si è fatta la **sezione token**, che era
un'aggiunta. Il capitolo Q-Live›Shows — le dieci righe `QL-SHOWS-01…10`, il contratto
Remove, la forma dell'alert — **è ancora tutto da scrivere, ed è il lavoro di domani**.

`[V]` BOX5 V27 **non contiene una sola occorrenza** di `QL-SHOWS`, `Q-Live`, `Remove`,
`Q20`, `alert` — nemmeno a maiuscole ignorate. Misurato dal referee sulla copia del
Progetto. L'indice finisce a r.472, «Cambio open per ratifica (da V19, invariato)».
**B3 incide un capitolo che non esiste**, non riformula due righe.

Il testo sorgente delle dieci righe è nel Progetto:
`2026-07-27_QL-SHOWS-01-10__RIEMISSIONE.html`, `[V]` `83c5c51d…fabdf6c`, 27803 B.

⚠️ **Nel Progetto convivono due versioni delle dieci righe**: quella **corrente** qui
sopra, e quella **vecchia** dentro `2026-07-26_QLive-Shows-Card-5-Risposte-di-Chiusura__rev2.html`
(`f1b362f0…6ee1ea`, 38185 B). Il file del 26/07 **non si toglie**: è il supporto di
ratifiche ancora vive (LIBRO r.299, r.302, r.303). Ma **la fonte del capitolo è quella
del 27/07** — citare l'altra significa incidere copy superata.

Poi: **B4** SCALETTA v3 → **B5** BUGS v44 → **B6** BOX3 V100 → **LIBRO v42**.

- ⚠️ **B4 è una riscrittura, non una toppa.** `[V]` SCALETTA v2 dice «RESTANO: **S3**
  (prossimo) · NODO A · S4 · S4L · S5 · S6», mentre `[R]` a fonte S3 è chiuso, NODO A
  chiuso da `152445e`, S4 fatto **e spezzato in S4a `f8276f6` + S4b `6ded4ab`** — una
  suddivisione che la scaletta non modella. Ferma alla riscrittura del 12/07.
- **B5 · BUGS v44 — TRE voci, non due:**
  1. **Chiusura di `TD-qstage-tab-reset`.** `[V]` Divergenza fra canonici: LIBRO r.305
     lo chiude by-design a zero codice; BUGS v43 r.543 lo tiene 🟡 OPEN BASSA con
     «domanda CD aperta». `[R]` CC: **BUGS non sa che la ratifica esiste** — zero
     occorrenze di `2026-07-26` nel file. È stallo di propagazione, non disaccordo.
  2. **Accumulo setlist.** `[R]` `deleteSetlist` (`Store/QBeatsStore.swift`) ha **zero
     call-site**: non esiste alcun modo di cancellare una setlist, né in Q-Live né in
     Q-Stage. Voce **separata**, NON agganciata a `TD-setlist-id-orfani` (quel ticket
     riguarda l'integrità a valle di una cancellazione che avvenga; questo è che a monte
     la cancellazione non esiste). Il rifiuto di CC sull'aggancio fu ratificato.
     Precondizioni da scrivere: la guardia «non si cancella in sessione» non può stare
     nello Store (`isPlaying` = zero occorrenze in `Store/`), e va deciso cosa succede
     al campo di appartenenza a Q-Live quando la setlist sparisce.
  3. **Angolo del riordino** su `TD-qlive-libero-limbo` causa (i): `LiveRootView` prende
     sempre `setlists.first` (`// L1.b DEV FALLBACK`) e `moveSetlists` esiste — qualunque
     riordino cambia quale show Q-Live carica. Riga da **aggiungere** al ticket
     esistente, non ticket nuovo.
  4. Più il ticket nuovo `TD-design-system-non-ancorato`.
- **B6 · BOX3 V100** — i reperti di §6, con in testa la sintesi di §1.
- **LIBRO v42** — le cinque righe + le tre voci di rettifica.

---

## 5 · APERTE — verso Mauro e verso CD

**Verso Mauro:** nulla di bloccante a fine 27/07. Ha deciso forma ② del popup, palette
a 4 voci, regola dentro/fuori, Q20, chip Read-only rimosso.
⚠️ **Una sola cosa non verificata**: il verbatim «si approvo» delle righe ① e ② arriva
dal canale CC e il referee non l'ha visto. Se serve certezza, si chiede **una volta**.
⛔ **NON chiedergli mai più se ratificò Q20 il 26/07.** Glielo si è chiesto tre volte,
è stato un errore di formulazione del referee, e la questione è chiusa dalla ratifica
del 27/07 sul contenuto riletto.

**Verso CD:** fermo, payload congelato, nulla in sospeso. Restano da chiedere, quando
si aprirà il ticket DS:
- quale nome è quello buono fra `--studio` e `--blue`, e in quale documento sta la
  versione da tenere (`[R]` CC: i quattro documenti CD **non concordano fra loro**);
- i tre token di `QLiveTheme`, che nessuno dei quattro documenti nomina.

**⚠️ Riemissioni CD: NON si fanno adesso.** I mockup che mostrano «Read-only» e i file
che dicono «Q20 aperta» sono superati **solo su quei punti** e si correggono al primo
tocco utile di ciascuno.

---

## 6 · TRAPPOLE VIVE — misurate oggi, in forma incidibile

### 🔴 I comandi che mentono sui fine-riga
`[V]` Verificato dal referee su tre ambienti indipendenti (dash · bash 5.2.21 + GNU grep
3.11 Linux · `[R]` MSYS2/MINGW64 + GNU grep 3.0 di CC):

- **`grep -c $'\r' <file>` rende 0 su QUALUNQUE file**, LF o CRLF, nell'ambiente di CC.
  È una costante travestita da misura. Ogni «CR = 0» ottenuto così è una frase vuota.
- **`grep -cP '\r'` rende 0 sempre** su file CRLF in quell'ambiente (in GNU grep 3.11 su
  Linux rende il numero giusto: **il comportamento è locale, il reperto va scoped**).
- Dentro `$( )` la stessa invocazione rende il **conteggio righe** — e su un file CRLF
  quel numero **coincide col numero di CR**: il primo guasto maschera il secondo dietro
  una risposta corretta.
- ⚠️ `od -c F | grep -c '\\r'` rende un terzo numero plausibile e sbagliato (conta righe
  di output di `od`).

→ **REGOLA: per i CR si usa `tr -cd '\r' | wc -c`**, corroborato da
`od -An -v -tu1 | tr ' ' '\n' | grep -c '^13$'`. **Mai grep, in nessuna forma.**
→ **Controllo strutturale che non passa da nessun pattern**: `byte_disco − byte_blob`.
0 = LF puro · = `wc -l` → CRLF puro · qualsiasi altro valore = finali misti.
`[V]` Verificato su LIBRO (142206−141762=444) e BUGS (196550−195668=882).

### 🔴 Le negazioni richiedono il controllo positivo — e il controllo può contenere un reperto
Un filtro che rende vuoto **non è un fatto negativo** finché non hai provato il filtro.
Oggi un controllo positivo è fallito due volte ed è stato correttamente buttato.
⚠️ **E un controllo positivo può contenere un ritrovamento che nessuno legge**, perché
si guarda quel comando per un altro motivo: `28cd41 → 5 occorrenze` era un controllo, ed
era anche la prova che la deduplica del verde non è mai avvenuta.

### 🔴 Una consegna nuova va SOLO in una cartella nuova
`[R]` Il payload `df55ccdc…` è stato **sovrascritto in place** in `UPDATE2` alle 20:14 e
non esiste più (615 file scansionati, controllo positivo). Quarta impronta orfana dopo
`04ce650a…`, `4d488900…`, `fd62da58…` — **e la prima creata da noi mentre bonificavamo
la stessa famiglia**.
⚠️ È andata bene **solo perché le righe non erano ancora incise**: un giro più veloce
avrebbe messo in LIBRO due ratifiche che citano il nulla. *Il cancello che ha retto non
è stata l'attenzione: è stata la lentezza.*
→ «Affianca» non è un'intenzione, è una **collocazione**. Copiare un file omonimo in una
cartella esistente lo distrugge in silenzio.
→ `…\27_07_2026\UPDATE2\` è uno **SNAPSHOT MISTO** (4 file del giro 19:32 + 1 payload del
20:14): non rappresenta nessun momento. La cartella coerente è `27_07_2026_g3` —
**dove però il file D non c'è**.

### 🔴 Troncamento dei nomi file
`[V]` Misurato su tre casi: il taglio cade a **64 caratteri del nome INTERO**, estensione
compresa — **non** dello stem (un nome con stem 62 è stato mutilato lo stesso, il che
falsifica la regola sullo stem).
→ **BUDGET: nome file ≤ 64 caratteri totali, cioè stem ≤ 59 con `.html`.**
⚠️ Dove avvenga il taglio resta ignoto; non è MAX_PATH (94 caratteri, ben sotto 260).

### 🔴 Citazioni ambigue — e il terzo discriminante
`[V]` `COPY POPUP REMOVE` esiste in **tre** righe di LIBRO (299, 300, 301), **due con la
stessa data**; r.300 è `superseded`, r.301 `attiva`. `Not in Q-Live` è in **tre** righe
(300, 301, 440): **il nome del chip non disambigua**. L'unico univoco misurato è
`REMOVE NON SI SPEDISCE` → solo r.301.
→ Titolo + data non bastano quando lo stesso titolo si ripete nello stesso giorno.
⚠️ **Verificare l'ambiguità nello stato del documento DOPO la scrittura**: una riga nuova
aggiunge occorrenze del titolo che cita. CC l'ha fatto ed è il primo controllo della
giornata che **previene** un difetto invece di trovarlo.

### 🔴 Il PowerShell che legge un testo diverso
`[R]` `Get-Content` senza `-Encoding UTF8` rende mojibake sui deliverable CD (nessun BOM),
mentre `Select-String` sullo stesso file decodifica bene. **Due lettori, due testi, nessun
errore segnalato.** Le impronte non ne risentono; **le citazioni di copy sì** — ed è copy
che si incide.

### 🔴 Le coppie a una cifra
`[V]` `#f3e2b0`/`#f3e2c0` · `#131210`/`#171210` · `#1b1a16`/`#1c1608`. Tutte legittime,
tutte a un carattere di distanza, tutte visivamente identiche.
→ **In una palette con più coppie a una cifra, un refuso è indistinguibile da una
decisione**: non a occhio, non in revisione, mai. È il motivo per cui `#f3e2c0` è nato
**nel giro che correggeva una deriva di colore, con un controllo residui apposta**.
→ Conseguenza: la sezione token non serve a documentare, serve a rendere il confronto
**meccanico**.

### Trappole ereditate, ancora vive
- `gh run watch … | tail` restituisce l'exit code di **`tail`**. La conclusione della CI
  si legge SOLO da `gh run view --json`.
- `gh … --commit` con sha **corto** rende `[]` con exit 0. Sempre 40 caratteri.
- **Due cartelle `HANDOFF`** (C: e E:) e ora **due `DA_CD_PER_CC`** (E: e progetto CD):
  ogni percorso va scritto col **disco esplicito**, e si cerca per **impronta**.
- **BOX3 è stratificato**: citare sempre lo strato — «BOX3 V99 (g)», mai «BOX3 (g)».
- **Due `Q9` e due `Q10`** in LIBRO: serie CD-5 (21/05) e freeze Q7-Q16 (11/07).
- ⚠️ **`Q17–Q22` è un'ETICHETTA DI INTERVALLO, non un elenco**: `[V]` nel file del 20/07
  la stringa `Q20` compare **zero volte** (ci sono Q17, Q19, Q22).
  → **La serie e la data disambiguano il NUMERO; non sostituiscono mai la FONTE.**
- ⚠️ Durante ogni gate device **NON premere «Carica dati test»** del ⚙ DEBUG:
  `injectTestData` SOSTITUISCE songs+setlists e un CRUD successivo li salva su disco.

---

## 7 · REGOLE DI CONDOTTA

- **DUE CANCELLI: ratifica referee ≠ OK di Mauro.** Entrambi obbligatori, mai
  collassati. «Incidere direttamente» **non è un'opzione** e non va offerta come tale.
- **Il referee non ratifica su un riassunto.** Pretende il verbatim e le misure come
  **file caricati**, mai incollati: il testo di questo progetto è pieno di caratteri
  fragili (⟦⟧ › ③ ▶ ⚠️ 🔴) e il trasporto si è rotto più volte.
- **Il referee non scrive pareri in prima persona** e **non decide di UX**. Segnalare un
  vincolo è il mestiere; consegnare la soluzione no.
- **Ogni messaggio che implica un'azione CC o CD finisce con un prompt pronto
  copia-incolla**, con destinatario e modello. **Mauro non riscrive i prompt.**
- 🔴 **NIENTE PROMPT CONDIZIONALI.** Mai «se hai già mandato X, manda solo i punti 3 e
  4»: obbliga Mauro a ricostruire uno stato che deve tenere il referee. O si chiede in
  una riga cosa è partito, o si scrive un prompt **idempotente** («se l'hai già fatto,
  scrivi *già fatto* e reincolla»).
- 🔴 **Un cancello dev'essere verificabile da chi lo attraversa.** «Esegui solo se Mauro
  ha autorizzato in chat» è inutile: CC quella chat non la vede. **L'autorizzazione
  viaggia dentro il prompt**, scritta come atto di Mauro, o il prompt non chiede la
  scrittura.
- **Mauro non è developer.** Si spiega raccontando cosa succede a chi usa l'app. **Se una
  cosa va spiegata tre volte, il problema è la spiegazione** — e una domanda mal posta
  si riformula, non si ripete.
- **Se CC o CD rifiutano con una fonte in mano, di norma hanno ragione.** Oggi è successo
  cinque volte e cinque volte avevano ragione.
- **PROPORZIONE.** Il rigore §7 va dove il danno è permanente. ⚠️ Il referee uscente ha
  lasciato crescere B3 da «un capitolo» a «un progetto», atomo per atomo, ognuno
  giustificato: **è così che un giro doc diventa una bonifica.** Tagliare è un atto da
  fare presto e da dichiarare.
- **PROATTIVITÀ**: parere esplicito sempre, criticità segnalata **prima** di procedere.
- **Modelli**: verifica meccanica → Haiku 4.5 · verifica di merito o scrittura su file a
  due facce → Opus 4.8 xhigh · L3 pre-flip CI-only → Sonnet 5. Se CC alza il modello e lo
  motiva, di norma ha ragione.
- **Vincoli §6**: `SwiftUI.Section` qualificato (TD-1), `SongSection` vietato, flash
  metronomo via `PassthroughSubject` e mai timer SwiftUI.
- Commit single-purpose, staging file per file (mai `git add -A`), Mauro solo autore,
  zero trailer. Branch fiammifero = autorizzazione esplicita di Mauro.
- **«Chiuso» = confermato su device**, mai CI verde da solo. **«Pushato ≠ propagato.»**
- **«Dove siamo»** → 5 righe, niente prompt.

---

## 8 · IL RITUALE R1 — cosa rimisurare prima di fidarsi di questo file

1. **I canonici**: ricalcolare le impronte della tabella §2 dalle copie del Progetto.
   Se una non torna, questo file è vecchio e vincono i canonici.
2. **`CR`** con `tr`, mai con grep — la tabella §2 è stata prodotta così.
3. **Far verificare a CC**, che è l'unico che vede i dischi:
   - HEAD reale (`git log -1`), e se le cinque righe sono state incise o no;
   - lo stato di `27_07_2026_g3`, `UPDATE`, `UPDATE2`;
   - se `TD-qstage-tab-reset` è ancora aperto in BUGS mentre LIBRO lo chiude;
   - la verifica di natività della forma ② (documentazione Apple o device) — è ciò che
     sblocca la pendenza della riga ③ **e** il debito `#f3e2c0`.
4. **Non ereditare i verbatim di questo file senza rileggerli** dai documenti veri.

### Inventario del Progetto a fine 27/07 — `[V]`, impronte del referee

| file | byte | sha256 |
|---|---|---|
| `2026-07-27_QL-SHOWS-01-10__RIEMISSIONE.html` | 27.803 | `83c5c51d…fabdf6c` |
| `2026-07-27_BOX5-V28__Token-Colore-PAYLOAD.md` | 13.092 | `b5f40d9e…b46a891e` |
| `MISURE_TOKEN-COLORE_FORMA-POPUP_2026-07-27.txt` | 20.376 | `6bef059c…f80d55e` |
| `MISURE_ADDENDUM_CODICE-A-HEAD_2026-07-27.txt` | 11.146 | `56176e4c…f6c93b9c` |
| `MISURE_G3_INVENTARIO-E-TICKET_2026-07-27.txt` | 10.971 | `532e4a78…cb26c187` |
| `2026-07-24_…Card-Azione-Overflow-FREEZE.html` | 45.161 | `a97a4f54…0ee62764` |
| `2026-07-26_…5-Risposte-di-Chiusura__rev2.html` | 38.185 | `f1b362f0…fc6ee1ea` |
| `2026-07-26_…Q20-RIEMISSIONE.html` | 37.430 | `5dcfbbfb…5ab9d408` |
| `2026-07-20_…Taratura-Q17-Q22_rev2.html` | 45.604 | `5ff27046…77700946` |
| `2026-07-18_QLive-Exit-in-Play.html` | 58.463 | `8d7a3150…5c398860` |
| `2026-07-11_Q7-Q16.html` | 74.645 | `c9bd0b02…93341e74` |

⚠️ **Non nel Progetto** e citato in LIBRO: il mockup A-bis
`2026-07-27_QLive-Shows-Remove-a-S4L-confronto.html` (`6455c8a9…1d2e19fc`, 40367 B).
`[R]` misurato da CC su E:.
⚠️ **Senza ancora in alcun canonico**: il deliverable del 20/07 (`5ff27046…`) —
`[V]` la sua impronta e le stringhe `Q17`/`Taratura` rendono **zero** in LIBRO, BUGS,
BOX3 e BOX5.

---

## 9 · CODA NON BLOCCANTE

**TD#17** 🟠 OPEN MEDIA — perdita peer Link in sessione lunga. **Non bloccante.** Causa
circoscritta al router H388X, che non fa transitare il multicast Link fra le sue due
bande; il VR2800 di palco è pulito. Chiude con **(A)** una run di palco 2-3 h su VR2800
in banda singola senza perdita peer **OPPURE (B)** Soluzione C in produzione —
alternative, non cumulative. Il test cross-banda sotto roaming è caratterizzazione, non
condizione. Rete di sicurezza già tracciata: ticket `TD-peer-reconnect-button`,
BUGS riga 262.

---

*Chi apre la prossima sessione dichiari cosa ha letto e misurato (R1), e cosa resta `[R]`.*
