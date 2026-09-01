# CONGEDO CC — A270 — 30/08/2026 sera

Da: CC · A: il CC che apre dopo di me.

**Orologio**: 30/08/2026, **17:30:59 locale (UTC+2)** — da `date` di sistema di questa macchina, non allineato agli altri artefatti (che dicono la stessa data: verificato, non assunto).

Marcatura: **[M]** misurato da me ORA · **[R]** riportato da altri · **[A]** giudizio mio.

⛔ **Questo congedo NON copre**: canonici, decisioni di Mauro, ticket, regole nuove, roadmap, lavoro di CD. Quella materia è del **congedo del referee** — vedi §1, esiste ed è depositato. Non la duplico: se ti serve, leggi là.
✅ **Questo congedo copre** ciò che il referee non può misurare: **il disco, la macchina, il regime di lavoro, e ciò che ho visto passando.**

---

## §0 — ID

`A270`. Cancello (R-δ.8/.9/.10), misurato ORA, gamba contenuto con `DESIGN/` escluso:

| gamba | esito |
|---|---|
| nome, repo `C:` | 0 |
| nome, `E:` | 0 |
| contenuto, repo `C:` (`git grep -lI` tracked + `grep -rlI` disco, `:!DESIGN`) | 0 |
| contenuto, `E:` | 8 file, tutti `LOG/RUN/TEST LUNGA DISTANZA/*.log` — **aperti** come obbliga R-δ.8: frammenti di UUID `corewifi`, non assegnazioni ⇒ **non occupano** |
| `git log --all --grep` | 0 |
| **positivo, ID occupato noto** (`A267`, committato oggi) | **2 commit visti** (`8a9faad`, `98c3aa2`) — la sonda git vede |

I candidati scartati non si nominano per cifra: sono quelli immediatamente precedenti, tutti assegnati oggi da questa sessione.

⚠️ **Conteggi di file non tracciati dichiarati come scattati PRIMA del deposito di questo congedo** (R-δ.9): al momento della misura questo file non esisteva ancora su nessuna gamba.

---

## §1 — 🚨 LA COSA PIÙ URGENTE: il congedo del referee è su UNA GAMBA SOLA

**[M]** `CONGEDO_REFEREE_2026-08-30_sera_8a9faad.md` — **236 righe, 20 286 byte, sha256 `f39104e0c09ea66c6b27dcd9a7863d1eec8a681cf653801723fdb6e9c8baaa35`**, timestamp **17:29**.

| gamba | c'è? |
|---|---|
| `E:\…\FILE X CLAUDE.MD\HANDOFF\` | ✅ **SÌ** |
| repo `C:\…\Q-BEATS\HANDOFF\` | ⛔ **NO** — `ls` rende «No such file or directory» |

⛔ **Non l'ho letto**: ne ho misurato solo esistenza, peso e impronta. Serviva l'indipendenza fra i due congedi, e leggerlo prima di scrivere il mio l'avrebbe azzerata.

**[A] Perché è urgente per te:** quel documento contiene la materia che questo congedo NON copre (canonici, decisioni, ticket, roadmap). Se apri solo il repo — la gamba naturale per chi lavora col codice — **non lo vedi**, e concluderesti che non esiste. È lo stesso errore che ho quasi commesso io stamattina in senso opposto: [R] i congedi `A264` e `A268` di questa stessa sessione dichiarano «congedo referee non trovato», misurato due volte a un'ora di distanza — **era vero allora** (le sonde erano corrette e complete), è **falso adesso**: il file è comparso alle 17:29, dopo il merge. La misura non era sbagliata, era **scaduta**.

⇒ **Vai a leggerlo su `E:`.** E se qualcuno decide di allinearlo, la propagazione al repo non è avvenuta.

---

## §2 — Stato della macchina, misurato ora

**[M] Repo `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS`**
- branch **`master`**, HEAD **`8a9faad975090410471e071ade90dd4f461a66aa`** = `origin/master` (allineati).
- **Working tree PULITO**: zero file modificati, zero in stage. ⇒ Apri su terreno fermo, non c'è lavoro a metà.
- **333 file non tracciati** (`git status` `??`), misurati prima del deposito di questo congedo.
- Ultimi tre commit: `8a9faad` (A267, oggi) · `b1b4c1f` (A260+A261) · `9c3616e` (A253+A254).

**[M] `HANDOFF/` — i due mondi non coincidono, e la differenza è grande**

| | repo `C:` | `E:` |
|---|---|---|
| file totali in `HANDOFF/` | **382** | **488** |
| di cui **tracciati in git** | **66** | — (non è un repo) |
| presenti **solo su E:** | — | **98** |
| presenti **solo su repo** | **3** | — |

I 3 solo-repo: `CONGEDO_CC_2026-08-29_A249.md`, `CONGEDO_REFEREE_2026-08-29_A251.md`, `_SUPERATO__ROADMAP_2026-07-24.txt`. I 98 solo-E: sono in larga parte materiale storico (aprile-luglio: handoff CD, diff BOX3/BUGS, accertamenti).

⇒ **[A] Nessuna delle due gambe è un soprainsieme dell'altra.** Una ricerca su una gamba sola può rendere zero su qualcosa che esiste. La spazzata va fatta su entrambe — e il referee, che vede solo l'albero committato, ne vede **66 su 382**.

**[M] Worktree e cloni** (esistenza verificata su disco):
- `git worktree list` **dal Desktop**: `…/Q-BEATS` (`8a9faad`, master) + `C:\Users\BULLFROG\qb_fixB` (`add556f`, `test/bug2b-test7-fixtures`).
- Esistono anche `C:\Users\BULLFROG\qb468clone` e `C:\Users\BULLFROG\qb_fixA` — **non elencati** dal worktree del Desktop (qb_fixA pende da qb468clone, che è un clone separato). ⛔ Nessuno di questi è stato toccato oggi.

**[M] Rami locali non-merged in `master`: 13**, incluso `fix/a267-…` (vedi §3). Gli altri 12 sono il debito di triage già noto — non li ho toccati.

**[M] `gh` CLI**: autenticato, account `19Bullfrog78`, attivo. Funziona: l'ho usato oggi per lanciare e osservare due build.

**[M] Due voci che segnalo perché stonano, senza proporre azione:**
- `.tmp.driveupload/` esiste nella radice del repo (non tracciata), contiene file **fermi al 26 giugno** — residuo di sincronizzazione, non pulito da due mesi.
- `CLAUDE.md` in radice è **non tracciato E non ignorato** (`git check-ignore` rende vuoto): 82 righe di istruzioni operative che nessun commit protegge. Se il disco si perde, si perde.

---

## §3 — Il ramo `fix/a267-rientro-dalla-sua-sezione`: tenere o rimuovere

**Misurato ora, ed è il punto che conta:**

| misura | esito |
|---|---|
| `git diff master fix/a267-…` | **VUOTO** — contenuto identico a master |
| `git log master..fix/a267-…` | **1 commit** (`98c3aa2`) formalmente non in master |
| `git branch --no-merged master` | **lo elenca** |

⚠️ **Non è una contraddizione, è l'effetto dello squash**: il merge ha prodotto un commit NUOVO (`8a9faad`) con lo stesso contenuto, non ha incorporato `98c3aa2` nella catena. Per git il ramo resta «non-merged» **per sempre**, anche se non porta una sola riga che master non abbia già.

**[A] La mia raccomandazione — ma la decisione è di Mauro, e NON l'ho eseguita:** il ramo si può rimuovere **senza perdita di contenuto**, ed è provato dal diff vuoto qui sopra. Due ragioni per farlo:
1. Lasciandolo, va ad **ingrossare la lista dei «rami non-merged»** insieme ai 12 del debito storico — e lì dentro sembrerà lavoro non integrato, che non è. Chi farà il triage dovrà rimisurarlo per scoprire quello che ho appena scritto qui.
2. Il commit `98c3aa2` **non sparisce** cancellando il ramo: resta raggiungibile per sha finché non passa il garbage collector, ed è citato per esteso nel referto A267 e nel messaggio di `8a9faad`.

**Una ragione per tenerlo**: finché il collaudo su device è confermato ma l'IPA non è passata sotto le dita di Mauro in una serata vera, un ramo intatto è una scialuppa a costo zero.

⇒ **Io lo terrei fino alla prima serata di palco con questa build, poi via.** ⛔ Non rimosso, come da istruzione.

---

## §4 — Il regime di lavoro, misurato agendo (non leggendo)

Queste sono le cose che ho imparato **facendole** oggi, non deducendole. Ti risparmiano un giro di ricognizione:

**[M] La CI parte SOLO sul push a `master`.** Su un ramo di servizio, dopo il push **non parte nulla**: il silenzio è normale, non un guasto. Va dispatchata a mano:
```
gh workflow run "iOS Signed Build" --ref <ramo>
```
Verificato agendo: push sul ramo → nessuna run; dispatch manuale → run `33315106030`, verde in 2m26s. Poi sul merge a master la run è partita **da sola**: `33318807294`, verde in 2m44s.

**[M] Le due annotazioni della build sono ambientali e preesistenti** — deprecazione Node.js 20 nelle action (`actions/checkout@v4`, `actions/upload-artifact@v4`) e tap Homebrew `aws/tap` non trusted. Compaiono su ENTRAMBE le run. ⛔ Non incolparle a un diff: non c'entrano.

**[M] 🚨 Disco e blob DIVERGONO davvero su `ios_app/`, e l'ho toccato con mano.** `LiveView.swift` a `8a9faad`:
```
BLOB  (git show 8a9faad:ios_app/QBeats/UI/Live/LiveView.swift | sha256sum)
      905b2f3ff0a967488061aa77480aec63ea30dc908262796e28eabd17fa8c63e7   775 righe, 48 763 byte
DISCO (sha256sum ios_app/QBeats/UI/Live/LiveView.swift)
      c267ecd1436be57457d186cd8996770a289c9bdc80dce6ce5c969c792125141a   775 righe, 49 538 byte
```
**775 byte esatti di differenza = un `\r` per riga.** `.gitattributes` mette `-text` solo su `HANDOFF/`, `DESIGN/`, `BOX3_QBEATS.md`, `BOX5_QBEATS.md` — **`ios_app/**` NON è escluso**, quindi git normalizza a LF e il disco Windows resta CRLF.
⇒ **Per i file tracciati sotto `ios_app/`, dichiara sempre l'impronta del BLOB** e dillo esplicitamente. [R] Questa regola è nata da un falso allarme costato tempo oggi (riportato dal referee nel mandato rev3): io avevo dato l'impronta del disco, il referee leggeva il blob, nessuno dei due aveva sbagliato.

**[M] Identità git già a posto**: `user.name`/`user.email` locali sono già `Mauro Martintoni <di_tutto@icloud.com>` — non serve impostarli, e i commit escono con autore=committer corretto senza intervento. Precedente di squash in casa: `ee0cbc0`.

**[M] La trappola del `grep` sugli ID si è ripetuta QUATTRO volte oggi** (su quattro ID diversi): i log in `E:\…\LOG\RUN\TEST LUNGA DISTANZA\*.log` contengono frammenti di UUID `corewifi` che matchano qualunque `A2NN`. `-I` non basta (sono file di testo): **va aperto il match**, come impone R-δ.8. Se automatizzi il cancello ID, escludi quella cartella.

---

## §5 — Cosa NON so, e cosa non ho verificato

⛔ **Non ho letto il congedo del referee** (§1) — di proposito. Non so cosa contenga.
⛔ **Non ho verificato l'IPA** prodotta dalle build: so che i job sono verdi, non ho aperto il binario né controllato che contenga le righe attese.
⛔ **Non ho letto i log estesi** delle due build riga per riga — solo la vista a step. Warning nuovi nascosti nel testo completo: non cercati.
⛔ **Non so cosa abbia fatto nel pomeriggio la seconda sessione CC concorrente**: [R] la sua esistenza è documentata nei congedi `A264`/`A266` di stamattina; l'ultimo suo artefatto che vedo è delle 11:37. Dopo, nulla di suo in `HANDOFF/`.
⛔ **Non ho toccato né misurato** i canonici, `DESIGN/`, i ticket, la roadmap: perimetro del referee.
⛔ **Non ho aperto** i 12 rami del debito storico né i cloni di servizio.

---

## §6 — Se apri domani, in tre righe

1. **Leggi il congedo del referee su `E:`** (§1) — sul repo non c'è.
2. **`master` = `8a9faad`, pulito, build verde, A267 chiuso e collaudato.** Non c'è lavoro a metà da riprendere.
3. **Prima di misurare qualunque cosa**: due gambe, mai una (§2); impronte dal blob per `ios_app/` (§4); apri sempre i match del cancello ID (§4).

---

## Percorsi

*(l'impronta di questo file vive nel messaggio di consegna, non qui)*

```
repo : HANDOFF\CONGEDO_CC_2026-08-30_A270-DISCO-E-MACCHINA.md
E:   : FILE X CLAUDE.MD\HANDOFF\CONGEDO_CC_2026-08-30_A270-DISCO-E-MACCHINA.md
```

⛔ Nessun commit, nessun push, nessuna modifica a codice/canonici/`DESIGN/`. Nessun ramo, worktree o clone rimosso. In questa sessione di congedo ho scritto **solo questo file** (più il suo gemello su `E:`).

*A270-DISCO-E-MACCHINA-FINE*
