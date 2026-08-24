# REFERTO CC — A210 — FERMATO DI NUOVO: TRE ANCORE DEL BLOCCO SMENTITE DALLA MISURA

Da: CC · A: referee + Mauro · 24/08/2026
Mandato: A210 (referee) — riemissione di A209 con tre correzioni; incidere la scheda
«conferma d'uscita» in coda alla SCALETTA, versione 14 → 15.
**ESITO: NON ESEGUITO. Il file SCALETTA non è stato toccato: zero byte scritti.**
Lo ordina il mandato stesso: «Se trovi UN'ALTRA premessa [M] smentita: fermati di nuovo».
Ne ho trovate TRE. Marcatura: [M] misurato alla fonte · [R] riportato · [A] giudizio mio.

---

## 1 · LE TRE ANCORE SMENTITE — tutte nel punto sul chip, tutte di forma, nessuna di sostanza

**① `ABLLinkIsConnected` NON sta a `:72`: sta a `:73`.** [M] Nell'header citato
(`ios-arm64_x86_64-simulator/Headers/ABLLink.h`) la riga 72 è il commento
`/*! @brief Is Link currently connected to other peers? */`; la dichiarazione
`bool ABLLinkIsConnected(ABLLinkRef);` è alla **73**. Off-by-one — nello stesso header
dove `:83` e `:164` reggono entrambe.

**② Le funzioni non sono «quaranta»: sono QUARANTUNO.** [M] Conteggio ferreo: dichiarazioni
con nome `ABLLink*(`, FUORI dai commenti, typedef e puntatori-a-funzione esclusi = **41**,
elenco completo stampato riga per riga (da `:49 ABLLinkNew` a `:594
ABLLinkCommitCoreAudioBufferWithHostTime`). Il grep grezzo rende 45 righe: 4 sono citazioni
di funzioni DENTRO commenti doc (`:284,:285,:298,:390`) — [A] probabile origine del
conteggio corto, se il filtro le ha tolte insieme a una dichiarazione vera.

**③ `BUGS:1060` NON incide sintomo/causa/fix: incide il tentativo null-op.** [M] La scheda
«TD linkPeers» va da `:1057` a `:1064`, così:
```
:1058  Sintomo: display "Peers: N" mostrava sempre 0 o 1 …
:1059  Causa root: LinkKit 4.0 non espone API pubblica peer count …
:1060  Tentativo precedente null-op: commit 72001a5 …
:1061  Fix vero: PR #1 squash merge in commit 0de5aa0 master 26/05/2026 sera …
:1062  Validato device: 26/05 sera …
```
I tre elementi che il blocco attribuisce alla `:1060` stanno a `:1058`, `:1059`, `:1061`.
La `:1060` è la riga che il MIO referto A209 §5 citava — per il contenuto che davvero porta.

[A] Nessuna delle tre tocca la sostanza: la ratifica «il numero non si mostra» è SOLIDA
(vedi §2). Ma i tre numeri sono [M] smentiti dalla misura, e la casa incide [M] esatti o
non incide: chi rimisura troverebbe 73, 41, 1058-1061 e userebbe lo scarto per dichiarare
inaffidabile l'intero canonico.

---

## 2 · TUTTO IL RESTO REGGE — misurato, non presunto

1. **Sonda Start/Stop Sync, eseguita IDENTICA alla dichiarata**
   (`grep -rnoE "(StartStopSync|IsStartStopSync|SetStartStopSync|startStopSync)" ios_app/`):
   **2 occorrenze**, `project.yml:24` e `Info.plist:45`, zero in codice ✓ — la correzione ① di A210 è giusta.
2. **Commento LinkEngine.mm citato verbatim** ✓ — `:54` «ABLLinkIsConnectedCallback è
   boolean: 0=nessun peer, 1=almeno un peer.», `:55` «LinkKit 3.x non espone un contatore
   nativo via callback.», `:56` `uint32_t peers = isConnected ? 1 : 0;`
3. **`0de5aa0`** esiste: 26/05/2026, «fix(ui): Settings Peers display da contatore numerico
   a stato binario» ✓ · **validato device** = `BUGS:1062` ✓
4. **«NESSUNA rende un numero di peer»** ✓ — nell'elenco delle 41, le uniche sulla
   connessione sono `ABLLinkIsConnected` (`:73`) e `ABLLinkSetIsConnectedCallback` (`:172`),
   entrambe binarie. Positivo: `ABLLink` rende 91 righe nell'header (124 occorrenze con `-o`).
5. **Sintomo, causa root e fix esistono VERBATIM in BUGS** ✓ — alle righe dette in §1③.
6. **`BOX3:50` «(e) VINCOLO TECNICO S4L da incidere»** ✓ (correzione ② di A210 giusta) ·
   `QLiveSession.swift:35-37` ✓
7. Ereditate da A209 e già verificate a `8727f8e`: contratto design 58 463 byte + sha256
   INTERO ✓ · `QLiveShowsView.swift:78-83` ✓ · `QLiveShowDetailView.swift:153` ✓ ·
   `RoomSwitchBar.swift:36` default `= {}` ✓ · `ABLLink.h:83` e `:164` ✓ · ARCHIVIO 12+5,
   fermo a `27_05_2026` ✓ · `BUGS:486` ✓ · `LIBRO:334` ✓ · `OverlayStopView.swift` ✓ ·
   catena SCALETTA repo = 0 ✓

---

## 3 · COLLISIONE A210 — LIBERA, coi DUE positivi chiesti

| sonda | A210 | pos. A168 | pos. A209 |
|---|---|---|---|
| nomi repo/HANDOFF | 0 | 1 | 1 |
| nomi E:/HANDOFF | 0 | 1 | 1 |
| nomi git a HEAD | 0 | 1 | — |
| contenuto repo (`\b…\b`) | 0 | — | 1 |
| contenuto E: | 0 | — | 1 |

⚠️ [A] QUESTO referto consuma anche A210. La riemissione la numeri il referee.

---

## 4 · IMPRONTE DEL BERSAGLIO — coincidono ANCORA, nessun'altra chat l'ha toccato

```
sha256 = 7f9f6eee605e819c3203bcb2595a0dbcccb12d49e6e99617a62b7daecacb6108 ✓
byte 75417 ✓ · LF 551 ✓ · CR 0 ✓ · NUL 0 ✓ · termina \n ✓ · riga 3 = 1381 byte ✓
bersaglio «**Versione:** 14 (24/08/2026)» unico ✓ · disco = blob ✓
```
Impronte DOPO = PRIMA. Diff: NON ESISTE — file `DIFF_…A210…` non creato.

---

## 5 · CORREZIONI PRONTE — perché la riemissione costi tre sostituzioni

1. `(\`:72\`)` → `(\`:73\`)`
2. «quaranta funzioni» → «**quarantuno** funzioni» (dichiarazioni fuori commento, typedef
   esclusi; il grep grezzo ne rende 45 di cui 4 in commenti doc)
3. «`BUGS:1060` incide sintomo … causa root … fix …» → «`BUGS:1058-1062`: sintomo `:1058`,
   causa root `:1059`, fix `:1061` (`0de5aa0`), validato device `:1062`; la `:1060` è il
   tentativo null-op `72001a5`»

[A] Parere di processo, senza girarci intorno: tre giri dello stesso mandato, tre famiglie
di ancore cadute — e le tre di oggi sono la trappola ③ del congedo (ancora scritta a memoria
o per aritmetica, non riletta dalla sonda). Il ping-pong sta funzionando da correttore, ma
costa un giro intero per ancora. Proposta: nella riemissione il referee dichiari quali ancore
ha RILETTO alla fonte nell'atto di scrivere e quali no — CC sigilla solo le seconde.

---

## 6 · STATO GIT ALLA CHIUSURA — nulla toccato

```
HEAD = origin/master = 8727f8e422e2720b4d5086958684e6cff1ca261a
0 tracciati modificati · 0 in stage · zero commit · zero push
```
Depositato SOLO questo referto, due gambe, `cmp` a seguire nel messaggio di consegna.

*REFERTO-CC-2026-08-24-A210-FINE*
