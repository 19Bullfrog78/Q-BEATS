# REFERTO CC — A209 — FERMATO AL CANCELLO DELLE PREMESSE, ZERO SCRITTURE

Da: CC · A: referee + Mauro · 24/08/2026
Mandato: A209 (referee) — incidere la scheda «conferma d'uscita dalla stanza» in coda alla
SCALETTA e alzare la versione 14 → 15.
**ESITO: NON ESEGUITO. Il file SCALETTA non è stato toccato: zero byte scritti.**
Marcatura: [M] misurato da me alla fonte · [R] riportato · [A] giudizio mio.

---

## 1 · PERCHÉ MI SONO FERMATO — due righe del blocco da incidere sono smentite dalla misura

**① «ZERO occorrenze» è falso: sono DUE.** [M] La sonda dichiarata nel blocco, rifatta
IDENTICA (`StartStopSync|IsStartStopSync|SetStartStopSync|startStopSync`, tutto `ios_app/`,
a `8727f8e`) rende:

```
ios_app/QBeats/Info.plist:45   <key>ABLLinkStartStopSyncSupported</key>
ios_app/project.yml:24         ABLLinkStartStopSyncSupported: true
```

[M] Entrambe sono chiavi di CONFIGURAZIONE, non codice: nate il 18/04 (`4af9a78`, «Blocco 6D —
Start/Stop sync + entitlement multicast») e il 18/05 (`2b379e4`).
[A] La SOSTANZA del punto del referee regge — nessuna riga di codice legge lo stato, e le due
chiavi la RAFFORZANO: il supporto è dichiarato da aprile, la lettura non è mai esistita.
Ma «ZERO occorrenze» inciso in un canonico è un falso misurabile: chi rifarà la sonda ne
troverà 2 e dichiarerà il canonico bugiardo. [M] Il controllo positivo del referee regge
(`ABLLink`: 4 in `LinkSettingsPresenter.mm`, 8 in `MIDIEngineBridge.h`), quindi
[A] l'ipotesi più probabile è che la sua sonda girasse su un perimetro più stretto (soli
sorgenti?) di quello DICHIARATO («tutto ios_app/»).

**② `BOX3_QBEATS.md:34` è un indirizzo slittato.** [M] A `8727f8e` la riga 34 è
«(f) IL NOME FISSO È UNA TRAPPOLA…». Il vincolo QLiveSession sta a **`BOX3:50`**:
«(e) VINCOLO TECNICO S4L da incidere. Un `ObservableObject` ANNIDATO dentro un altro NON
propaga: `QLiveSession.@Published runner` notifica solo APPARIZIONE/SCOMPARSA…».
Slittamento **+16** = le 16 righe che V100 ha aggiunto in testa: è il livello ① della deriva
descritta nel congedo A192-A208 §4 — dentro il paragrafo del mandato che ammonisce «andare
per SIMBOLO, mai per riga».
[M] Il vincolo «ripetuto dentro `QLiveSession.swift`» invece c'è, righe 35-37: regge.

[A] Non ho emendato da solo: il blocco è testo del referee e il mandato prescrive il verbatim;
la regola di casa vieta di incidere un falso misurabile. Le due cose insieme = stop. È uno
stop della stessa famiglia dei tre del congedo: il difetto è nel mandato, non nell'esecuzione.

---

## 2 · COLLISIONE A209 — LIBERA (misurata PRIMA di tutto)

| sonda | A209 | positivo A168 |
|---|---|---|
| nomi repo/HANDOFF | 0 | 1 |
| nomi E:/HANDOFF | 0 | 1 |
| nomi git a HEAD | 0 | 1 |
| contenuto repo/HANDOFF (`\bA209\b`) | 0 | 3 |
| contenuto E:/HANDOFF (`\bA209\b`) | 0 | — |

⚠️ [A] QUESTO referto consuma A209: da ora l'ID risulta usato, per un mandato fermato.
Il numero della riemissione lo decide il referee — non lo assegno io.

---

## 3 · IMPRONTE DEL BERSAGLIO — coincidono TUTTE con quelle del mandato

```
HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md · disco = blob a HEAD (git diff HEAD: vuoto)
sha256 = 7f9f6eee605e819c3203bcb2595a0dbcccb12d49e6e99617a62b7daecacb6108   ✓
byte   = 75417 ✓ · a capo = 551 ✓ · CR = 0 ✓ · NUL = 0 ✓ · termina con \n ✓
riga 3 = «**Versione:** 14 (24/08/2026)  ·  …», 1381 BYTE (1303 caratteri) ✓
stringa «**Versione:** 14 (24/08/2026)»: 1 occorrenza — la sostituzione SAREBBE stata sicura ✓
.gitattributes: `HANDOFF/** -text` ✓ (una faccia sola)
```

[M] Impronte DOPO = impronte PRIMA: il file non è stato toccato.
[M] Diff: NON ESISTE. Il file `DIFF_2026-08-24_A209-…` non è stato creato: un diff vuoto
sarebbe un falso reperto.

---

## 4 · TUTTE LE ALTRE PREMESSE [M] DEL BLOCCO: rimisurate a `8727f8e`, REGGONO

1. contratto `DESIGN/QLive_Nav/2026-07-18_QLive-Exit-in-Play.html`: 58 463 byte, sha256
   `8d7a3150050f2d9ee88d552f6a59649081518a1189182174c5dfed655c398860` — INTERO, coincide ✓
2. `QLiveShowsView.swift:78-83` monta `RoomSwitchBar(active: .qLive, onHome: onExit,
   variant: .full, onSwitch: onSwitchToStage)` ✓
3. `QLiveShowDetailView.swift:153` monta `RoomSwitchBar(active: .qLive, onHome: {},
   variant: .segMini)` senza `onSwitch` ⇒ inerte ✓ · slittamento :127→:153 vs BUGS,
   già dichiarato nel blocco ✓
4. `RoomSwitchBar.swift:36` — `var onSwitch: () -> Void = {}`, il default silenzioso ✓
5. `AudioEngine.swift:39` — `@Published var linkPeers: Int = 0` ✓
6. `ABLLink.h:83` `ABLLinkIsStartStopSyncEnabled` ✓ · `ABLLinkSetIsStartStopSyncEnabledCallback`
   a `:164` ✓ (slice `ios-arm64_x86_64-simulator`, come citato; presente anche negli altri slice)
7. `ARCHIVIO.MD/` tracciati: 12 snapshot BOX3 ✓ · 5 BOX5 ✓ · ultima cartella-data
   `27_05_2026` ✓ (il mio «87 BOX3» del 23/08 era filesystem CON i non-tracciati:
   domanda diversa, entrambe vere)
8. `UI/Live/OverlayStopView.swift` tracciato: 1 ✓
9. `TD-segmini-onswitch-morto` esiste in BUGS §1.2 (`BUGS:486`) ✓
10. `LIBRO:334` = ⟦S6F⟧, fascia «Q-LIVE · PLAYING», 31/07 ✓
11. catena snapshot SCALETTA nel repo: 0 ✓ (vive su E:, 12 file v3→v14, buco v10)

---

## 5 · PARERE, PRIMA DELLA RIEMISSIONE — il chip «N on Link» non potrà mai dire N

[M] Le scritture di `linkPeers` sono sette; `AudioEngine.swift:458`
(`engine.linkPeers = Int(count)`) riceve `count` dal callback peers-changed. Ma
[M] `BUGS:1060` incide: «`numPeers_` interno C++ è popolato solo dal callback booleano»
(branch archeologico `fix/td-link-peer-count`, preservato per evitare ri-tentativi).
⇒ [A] `linkPeers` vale di fatto 0 o 1. La frase della scheda «il conteggio peer invece C'È
già» è LETTERALMENTE vera — la variabile esiste — ma il valore è degenere: la condizione
«≥1 peer» dell'ambra FUNZIONA, la prova device 5 FUNZIONA, però il chip `N on Link`
mostrerà SEMPRE «1 on Link». [A] Tre uscite possibili: la copy del chip si degrada a
presenza («On Link»), oppure la scheda dichiara il limite come dichiara gli altri, oppure
si riapre il ticket del conteggio. Deciderlo PRIMA che un collaudo device lo scopra da solo.

---

## 6 · STATO GIT ALLA CHIUSURA — nulla toccato

```
HEAD = origin/master = 8727f8e422e2720b4d5086958684e6cff1ca261a
0 tracciati modificati · 0 in stage · zero commit · zero push
```

Depositato SOLO questo referto (scrittura autorizzata dal mandato), su due gambe.

*REFERTO-CC-2026-08-24-A209-FINE*
