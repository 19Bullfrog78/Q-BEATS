# MISURE CC — A113, COLLISIONE SPEC/SCHEDA

Da: CC · A: Mauro + referee · 18/08/2026
⛔ **SOLA LETTURA.** Nessun canonico modificato, zero righe sotto `ios_app/`, zero commit, zero
push, HEAD invariato a `44fea3e378414c300ffd50fcac527c683740735b`. A112 non eseguito.
⛔ **Non ho corretto la scheda**, come disposto: qui si misura soltanto.

Marcatura: **[M]** misurato ora, da me · **[R]** riportato · **[A]** giudizio mio.

---

## L'ERRORE, prima di tutto

**[A] Il rilievo è fondato e la responsabilità è mia, e non è la stessa di A111.**
In A108 mi era stata posta una domanda di **disegno** — «standby e `.stopped` sono la stessa cosa?»
— e io ho risposto con una **misura di codice**. La misura era giusta: `.standby` ha un valore
associato, il default è `.stopped`, la parola è occupata. **Ma la domanda non era quella.**
Se una cosa è già decisa in un canonico, il codice che non la implementa non è una prova
contraria: è **codice in ritardo**.

⛔ **Non ho cercato in BOX5, e BOX5 aveva già deciso.** È la regola di casa che conoscevo e non ho
applicato: la verità sta al livello più profondo, e per una domanda di contratto quel livello è la
spec, non il sorgente. ⇒ La `Cond (b)` che ho proposto e che è stata ratificata **contraddice la
spec**, e va riscritta.

⚠️ **E c'è un secondo pezzo, che mi riguarda ancora di più:** in A105 avevo misurato che il
capitolo Q-Live › Shows di BOX5 esiste, e in A108 e A110 **non ci sono tornato**. Avevo la fonte
in mano e ho guardato altrove.

---

# B1 · LA SPEC — ciò che vincola l'ingresso in uno show, verbatim

## Le due righe che decidono

**[M]** `BOX5_QBEATS.md:331` — il contratto:

```text
331	**QL-SHOWS-07 · Confine dello show.** L'ingresso in uno show è SEMPRE arma + standby, qualunque sia il flag standby della prima canzone. Il flag per-canzone (LIBRO 26/06) governa solo le transizioni canzone→canzone. «Standby off» = «non fermarti fra le canzoni», mai «parti senza di me». Il count-in configurato si suona comunque, al tap. Corollario: il flag della canzone in prima posizione è inerte finché è prima.
```


**[M]** `BOX5_QBEATS.md:354` — la forma della riga, §3:

```text
354	- **§3 — Start = arma + standby** sulla prima canzone. Il click parte al **secondo** tap (schermo ovunque) o via MIDI: Start non fa danni, è il tap successivo che suona. È lo stesso standby già ratificato fra le canzoni — non un secondo modello di avvio. Un tap dalla lista che facesse partire subito il click manderebbe il click in PA col telefono ancora in mano.
```


⇒ **[M] Cinque vincoli, tutti espliciti:**

1. **L'ingresso in uno show è SEMPRE arma + standby.** Non è condizionato al flag della prima
   canzone: quel flag è **inerte finché la canzone è prima**.
2. **Il click parte al SECONDO tap** — «schermo ovunque» — **o via MIDI**. Lo Start «non fa
   danni».
3. ⛔ **È LO STESSO STANDBY già ratificato fra le canzoni, NON un secondo modello di avvio.**
4. **Il count-in configurato si suona comunque, al tap.**
5. La motivazione è di palco, non estetica: «un tap dalla lista che facesse partire subito il click
   manderebbe il click in PA col telefono ancora in mano».

## Le altre righe che vincolano lo stesso ingresso

**[M]** `BOX5:323` — **QL-SHOWS-04**, il consumatore dello stato armato: ««Remove from Q-Live» è
INERTE con **sessione armata** o in play (voce disabilitata) … Resta VISIBILE e disabilitato, **non
nascosto**».

**[M]** `BOX5:333` — **QL-SHOWS-08**, e questa la scheda ⟦S5b⟧ non la cita affatto: «Il DETTAGLIO
show SARÀ la sede della scelta modalità … e conserverà il proprio Start … Pillola ▶ della lista
= stessa azione, modalità di default, nessuna domanda. **Stato prodotto IDENTICO.**»
⇒ **[A] Vincolo forte e non registrato:** ciò che ⟦S5b⟧ costruisce per lo Start del dettaglio
**è la stessa azione** che la pillola ▶ dovrà fare. Non due percorsi: uno solo, due ingressi.

**[M]** `BOX5:362` — la pillola ▶ resta **gated** finché l'avvio non è cablato: «tratteggiata,
icona spenta, **inerte** … una pillola arancio che non fa nulla è vietata dal contratto vigente».
⇒ ⟦S5b⟧ è ciò che toglie il gate a quella pillola.

**[M]** `BOX5:324` e `BOX5:404` — lo stato «sessione armata» non esiste a HEAD e **«nasce insieme
all'arma + standby»**. Verbatim di `:404`:

```text
404	8. **Stato «sessione armata» — non esiste a HEAD.** (LIBRO r.303) Nasce insieme all'arma + standby. La dipendenza è soddisfatta per costruzione finché i pezzi restano nel blocco unico di QL-SHOWS-06; va scritta perché non si perda **se quel blocco venisse spezzato**.
```


---

# B2 · LO STATO «SESSIONE ARMATA»

## 1 · Esiste a HEAD? **NO.**

**[M] Sonda A** — token `armed`, insensibile alle maiuscole, su `*.swift` `*.mm` `*.h` `*.cpp`:
**7 occorrenze nell'app, tutte `backtrackArmed`** (`AudioEngine.swift:370, 1488, 1489, 1495, 1506,
1536, 2966`) — flag del buffer del backtrack, **nessun rapporto** con l'armamento di uno show —
più una variabile locale in un test C++ (`core_engine/test_main.cpp:390`).
**[M] Sonda B**, forma diversa (`\barm\(|isArmed|sessionArmed|armSession|sessionState`): **zero**
pertinenti — i soli match sono commenti su `ABLLink AudioSessionState`.

**[M] Controlli positivi in forma LESSICALE DIVERSA dalla sonda** (non la parola «armed»), perché
un controllo che riusa la forma cercata non prova nulla — lezione di A111:

| controllo | forma | esito |
|---|---|---|
| `playbackState` | nome di proprietà, stato che **esiste** | **8 file** |
| `@Published` | attributo, forma di stato osservabile | **9 file** |
| `case standby` | dichiarazione di case | **1 file** |

⇒ La ricerca sa trovare gli stati che ci sono. **Lo stato armato non c'è.** BOX5:324 regge.

⚠️ **[M] Un difetto di puntatore trovato passando, in un canonico:** `BOX5:324` cita
`ios_app/QBeats/Audio/AudioEngine.swift:370`. Quel percorso **a HEAD non esiste** (0 file);
il file vero è `ios_app/QBeats/AudioEngine.swift` (1 file), **senza** il segmento `Audio/`.
La riga e il numero sono giusti, il percorso no. **Registrato, non corretto** — sola lettura.

## 2 · Chi deve costruirlo: ⟦S5b⟧ o un atomo suo?

**[A] Argomento dalle fonti, e la fonte è una sola riga che parla proprio di questo caso.**

- **[M]** `BOX5:404` dice che la dipendenza è «soddisfatta **per costruzione** finché i pezzi
  restano nel **blocco unico di QL-SHOWS-06**», e che **va scritta perché non si perda «se quel
  blocco venisse spezzato»**.
- **[M]** Quel blocco — pillola ▶, «···», swipe, popup, campo di persistenza — è materia di
  ⟦S4L⟧. E **[M]** l'ordine ratificato mette ⟦S5b⟧ **prima** di ⟦S4L⟧
  (`SCALETTA:323` + marcatura `:324`).
- ⇒ **[A] Il blocco È spezzato, nel tempo. Quindi la condizione che BOX5:404 prevede si è
  avverata, e la riga dice cosa fare: scriverlo.**

⇒ **[A] Chi produce e chi consuma sono atomi diversi, e questo scioglie la domanda:**
**⟦S5b⟧ è l'atomo che ARMA**, quindi è lui a dover **produrre** e dichiarare lo stato armato —
«nasce insieme all'arma + standby», e l'arma è sua. **⟦S4L⟧ lo CONSUMA** (QL-SHOWS-04: Remove
inerte a sessione armata). ⛔ **Non serve un atomo proprio**: servirebbe se lo stato avesse una
vita indipendente dai due, e non ce l'ha.

⚠️ **[A] Ma ⟦S5b⟧ deve produrre il MINIMO, non il concetto pieno.** Il gating di Remove è lavoro
di ⟦S4L⟧ e non va anticipato qui. E **[A] la forma tecnica è scelta CC** — per simmetria con
`BOX5:401`, che dichiara CC la forma del campo di persistenza. ⚠️ Segnalo, senza deciderlo, che nel
codice esiste già un candidato naturale: lo slot `roomSession.runner` è non-`nil` **se e solo se**
lo Start ha armato. Se regga come stato armato **non lo decido io**: è disegno tecnico, e questo
giro è di misura.

## 3 · `.standby(nextSongName:)` regge il primo brano? **SÌ — e non è un'ipotesi, è misurato**

**[M] La chiave sta nell'ORDINE di due righe**, `SetlistRunner.swift:343-348`:

```text
341	            } else if !self.isLastSongInSetlist {
342	                // === RAMO STANDBY ===
343	                self.currentSongIdx += 1
344	                self.currentSectionIdx = 0
345	                let nextSongName = self.currentSong?.name ?? "—"
346	                os_log("[Q-BEATS][L1.b] standby — nextSong:%{public}@",
347	                       log: .default, type: .default, nextSongName)
348	                session.playbackState = .standby(nextSongName: nextSongName)
```


⇒ **`nextSongName` è calcolato DOPO `currentSongIdx += 1`.** Quindi il valore associato **non è**
«la canzone dopo quella corrente»: è **«la canzone che partirà al prossimo tap»**.

⇒ **[M] All'ingresso in uno show, con `currentSongIdx == 0`, `currentSong?.name` è la PRIMA
canzone.** Il payload si legge esattamente giusto senza cambiare nulla del modello.
⚠️ Il **nome** del parametro è fuorviante — dice «next» e significa «la prossima a suonare» —
ma la semantica è già quella che serve. ⇒ **`.standby` NON è modellato solo per le transizioni.**

**[M] E l'obiezione storica non si applica.** `LiveSession.swift:30-34` spiega perché il default
fu portato da `.standby(nextSongName: "—")` a `.stopped` il 17/05 (TD #28):

```text
29	    // MARK: - Stato
30	    // Default `.stopped`: all'avvio Vista LIVE niente em-dash centrale.
31	    // L'overlay `.standby` viene mostrato SOLO quando il SetlistRunner
32	    // imposta esplicitamente lo state tra una canzone e l'altra (vedi
33	    // SetlistRunner.swift ramo standby). Cambiato da `.standby(nextSongName: "—")`
34	    // il 17/05/2026 — TD #28, Step 2 roadmap pre-CD.
35	    @Published var playbackState: LivePlaybackState = .stopped
```


⇒ Il difetto era **l'em-dash**, cioè uno standby **senza un nome vero da mostrare**, all'epoca in
cui il player si apriva senza runner. Con un runner armato il nome c'è. **TD #28 non contraddice
QL-SHOWS-07: lo precede e riguarda un altro caso.**

---

# B3 · IL PERIMETRO — **I TRE FILE NON BASTANO. Sono QUATTRO.**

## Quello che NON va costruito, perché c'è già tutto

**[M] Il modello «arma + standby + secondo tap» è già costruito per intero**, e la spec lo dice
(«è lo stesso standby già ratificato»). Verbatim, `LiveView.swift:129-138`:

```text
129	                .opacity(isStandby ? 0.10 : 1.0)
130	                .animation(.easeInOut(duration: 0.3), value: isStandby)
131	
132	                if case .standby(let nextSong) = session.playbackState {
133	                    StandbyOverlayView(nextSongName: nextSong, scaleFactor: scaleFactor)
134	                        .contentShape(Rectangle())
135	                        .onTapGesture {
136	                            runner.startCurrentSong(audioEngine: audioEngine, session: session)
137	                        }
138	                }
```


- `:129` — tutto il player **si abbassa a opacità 0,10** quando è in standby;
- `:132-133` — l'overlay rende il titolo della canzone;
- `:134` — `.contentShape(Rectangle())` **estende l'area sensibile a tutto il rettangolo**;
- `:135-137` — un tocco chiama `runner.startCurrentSong(…)`.

⇒ **[M] «Il click parte al secondo tap, schermo ovunque» è GIÀ VERO nel codice** — vale fra le
canzoni. Manca solo che quello stato sia **acceso all'ingresso**.

## Perché servono quattro file e non tre

**[M]** Lo stato vive in `session`, che è `@StateObject **private** var session = LiveSession()`
(`LiveView.swift:11`): **nessuno, da fuori, può assegnarlo.**

**[M] Ma una porta verso quella sessione è già aperta al montaggio, ed è UNA SOLA:**
`LiveView.swift:231` chiama `runner.primeDisplay(session:)`. E `primeDisplay` (`SetlistRunner.swift:271`)
ha **esattamente un chiamante in tutto il corpus** — quello.

⇒ **[A] Accendere lo standby d'ingresso dentro `primeDisplay` illumina tutta la macchina esistente
SENZA toccare `LiveView`** — il paletto ② regge, `LiveSession` resta privata, i due tipi non si
riconciliano. **Ma il file è un quarto: `ios_app/QBeats/SetlistRunner.swift`.**

⛔ **Non riduco la spec per far tornare il numero: il numero è quattro.**

⚠️ **[M] E serve una guardia, che oggi la scheda non prevede.** `primeDisplay` gira a **ogni**
`onAppear` del player, non solo al primo. Accendere `.standby` senza condizione significherebbe
poter rimettere in standby uno show **già in esecuzione** a una ricomparsa della vista. ⇒ **È qui
che lo stato armato guadagna il suo posto**: distinguere «armato e mai partito» da «già partito».
Non progetto la guardia: registro che senza di essa il passo è rotto.

## E una cosa più grande: **il count-in della spec NON ESISTE nel codice**

**[M]** QL-SHOWS-07 impone: «Il count-in configurato si suona comunque, al tap».
Ma il campo `Song.countIn` (`Models/Song.swift:21`, «0=nessuno, 1=1 battuta, 2=2 battute») è
**scritto** dall'editor (`UI/QStage/SongEditorView.swift:34`, un `Picker`) e **non è letto da
nulla che avvii l'audio**: zero occorrenze in `SetlistRunner.swift` e in tutta `UI/Live/`.
Le occorrenze di `countIn` che restano sono **un altro oggetto**: lo stato di UI
`LivePlaybackState.countIn(countdown:)`, che `LiveView.swift:270-271` imposta con un
**`countdown: 4` costante**, non con il valore della canzone.

**[M] Controlli positivi, forma identica sugli stessi percorsi**, per escludere il falso-zero:
`sections` → 1 file · `beatsPerBar` → 2 · `accentPattern` → 2. La sonda trova i campi di `Song`
che qualcuno legge. **`countIn` non lo legge nessuno.**

⇒ **[A] Questo non è cablaggio: è lavoro di dominio audio.** E qui rispondo alla domanda del
mandato senza addolcirla:

⛔ **Se ⟦S5b⟧ deve soddisfare QL-SHOWS-07 PER INTERO, è troppo grande per un atomo e va
SPEZZATO** — non compresso:

- **⟦S5b⟧ — l'arma:** costruire il runner, riempire lo slot, navigare, accendere lo standby
  d'ingresso col titolo della prima canzone, dichiarare lo stato armato. **Quattro file**, tutti
  di cablaggio, gate device.
- **un atomo separato — il count-in configurato:** far leggere `Song.countIn` al percorso d'avvio.
  Tocca il motore audio, ha rischi propri, e **non ha nulla a che vedere con lo Start**: serve
  anche al tap fra le canzoni, dove il difetto esiste già oggi.

⚠️ **[A] La seconda metà non è un difetto introdotto da ⟦S5b⟧:** è già rotta a HEAD, sul
percorso inter-canzone. ⟦S5b⟧ la rende soltanto **visibile**, come per END SHOW.

---

# B4 · IL CANCELLO CIECO — e sì, oggi si vede a occhio

**[A] Il rilievo è giusto:** «il player si monta, la videata è piena, non suona nulla» lo supera
anche un player **fermo e statico**, che viola la spec. Il passo non discrimina.

**[M] Ma lo standby ha tre segni misurabili, e nessuno dei tre può essere simulato da uno stato
`.stopped`.** Verbatim, `StandbyOverlayView.swift:15-35`:

```text
15	    var body: some View {
16	        GeometryReader { geo in
17	            VStack {
18	                Spacer().frame(height: geo.size.height * 0.27)
19	                Text(nextSongName.uppercased())
20	                    .font(.custom("Inter-Black", size: 52 * scaleFactor))
21	                    .foregroundColor(.white)
22	                    .multilineTextAlignment(.center)
23	                    .opacity(pulseOpacity)
24	                    .padding(.horizontal, 20)
25	                Spacer()
26	            }
27	        }
28	        .onAppear { startPulse() }
29	    }
30	
31	    private func startPulse() {
32	        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
33	            pulseOpacity = 1.0
34	        }
35	    }
```


| segno | dove | perché non è falsificabile da `.stopped` |
|---|---|---|
| **il player si oscura** a opacità **0,10** | `LiveView.swift:129` | in `.stopped` la videata è a piena opacità: è un confronto binario, non una sfumatura |
| **il titolo della prima canzone a 52 pt** `Inter-Black`, centrato al **27 %** dell'altezza | `StandbyOverlayView.swift:18-24` | in `.stopped` quel testo **non esiste**: l'overlay è dentro `if case .standby` |
| **il titolo PULSA**, 0,45 ↔ 1,0 in **2,2 s**, all'infinito | `:31-35` | un player fermo è **statico**: il respiro è il segno che nessuna schermata ferma può imitare |

⇒ **[A] Formulazione del passo, verificabile a occhio, senza alcun disegno CD:**

> **(1)** Da un dettaglio con brani risolti, tocca **START SHOW**. ✅ Deve comparire il **titolo
> della PRIMA canzone**, grande e centrato in alto, **che pulsa lentamente**, sopra il player
> **visibilmente oscurato**; **non deve suonare nulla**.
> ⛔ Se la videata è piena e nitida, o il titolo non c'è, o il titolo c'è ma **immobile**:
> **il passo è FALLITO** — il player è fermo, non armato.
> **(2)** Tocca lo schermo **in un punto qualsiasi**. ✅ Il click deve partire **da quella canzone**.

**[M] E non serve né CD-1 né CD-2:** quei due sono backlog UX (`BUGS:672-673`, «proposto») e
riguardano la zona swipe e il perimetro rosso dell'overlay. **Il pulse e l'oscuramento sono già nel
codice a HEAD**, costruiti per il caso inter-canzone. ⇒ Il collaudo è possibile **oggi**.

⚠️ **[A] Un solo limite dichiarato:** «schermo ovunque» è misurato come `.contentShape(Rectangle())`
sull'overlay (`LiveView.swift:134`), **non** come tocco su tutta la finestra. Se sul device
risultasse che i bordi non rispondono, è uno scarto fra spec e resa, e va visto lì.

---

# B5 · TRE RIGHE PER MAURO

**Cosa cambia.** Lo Start non deve lasciare il player «fermo»: deve lasciarlo **armato**, col titolo
della prima canzone grande al centro che pulsa, e il click parte al **secondo tocco** — dove vuoi
sullo schermo — oppure da MIDI. Era già scritto in BOX5 dal 27 luglio; io ho guardato il codice e
ho concluso il contrario. **La `Cond (b)` della scheda va riscritta: dice l'opposto della spec.**

**Quanto è grande.** Meno di quanto sembri per la parte che conta: **il meccanismo esiste già
tutto** — l'oscuramento, il titolo che pulsa, il tocco che fa partire — perché è lo stesso che usi
già fra una canzone e l'altra. Manca solo **accenderlo all'ingresso**. Ma i file diventano
**quattro** invece di tre, e c'è un pezzo che va staccato: **il count-in configurato per canzone
oggi non lo suona nessuno** — il campo si imposta nell'editor e non lo legge nulla. Quello è
lavoro sull'audio, e non appartiene allo Start.

**Cosa serve da te.** Tre decisioni, e nessuna è tecnica: **(1)** confermare che ⟦S5b⟧ si spezza in
due — l'arma adesso, il count-in in un atomo suo — invece di crescere; **(2)** decidere se lo stato
«sessione armata» lo produce ⟦S5b⟧ (io leggo di sì nelle fonti, ma è una lettura) o se preferisci
tenerlo con ⟦S4L⟧, che è chi lo consuma; **(3)** sapere che la pillola ▶ della lista, per
QL-SHOWS-08, deve fare **la stessa identica cosa** dello Start del dettaglio — quindi ciò che si
decide qui vale anche per lei.

---

## COSA NON HO FATTO

⛔ Non ho corretto la scheda, non ho scritto la `Cond` nuova, non ho progettato la guardia di
`primeDisplay` né la forma dello stato armato. Nessun codice, nessun canonico toccato.

⚠️ **Lacuna dichiarata, la stessa dei tre giri precedenti: nessuna verifica indipendente.** Tutto
ciò che è **[M]** l'ho misurato io, con controllo positivo in forma diversa dalla sonda su ogni
zero. Ma questo referto **corregge un mio errore che nessuno strumento aveva intercettato** — l'ha
intercettato il referee leggendo una fonte che io non avevo aperto.

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1.

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `698e8864c24655895bd17cfa089aa6c266a6c5259cf83847f276956a860fbe89`
- **byte** (file completo): `20419`
- **righe** (file completo): `375`
- **CR** (0x0D, contati sui byte, mai con grep): `0`
- **byte NUL** (0x00, controprova sul bersaglio): `0`

---

*A113-COLLISIONE-FINE*
