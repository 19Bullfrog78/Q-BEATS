# MISURE CC — A93, COMPLETAMENTO ANTI-CASCATA DI A92 (doc-only)

Da: CC · A: referee + Mauro · 18/08/2026
Perimetro rispettato: **zero righe sotto `ios_app/`**, zero commit. Le sei incisioni di A92 **non
sono state toccate nel contenuto** — verificato per hash, vedi §4. Scritture: solo questo referto +
aggiornamento del **preambolo** del diff (fuori dalle righe `---`/`+++`), in `HANDOFF/` + R-δ.

Marcatura: **[M]** misurato ora da CC.

---

## AGGANCIO — A93 libero

**[M]** Forma a token, due supporti: `\bA93\b` → **0** in `HANDOFF/` e **0** su E:. Controllo
positivo `\bA92\b` → **2** file su entrambi. Non collide. HEAD invariato dal referto A92
(`321293e18094d9d4f1c167bfc921be1ad216e3ac`), diff A92 ancora applicabile all'apertura del mandato.

---

## ① CENSIMENTO COMPLETO — con una correzione al mio stesso metodo

**[M] Il primo giro di censimento aveva un difetto, e l'ho scoperto confrontando due mie misure che
non tornavano fra loro.** Un conteggio grezzo (`grep` sull'intero output, snippet compresi) rendeva
per `LIBRO:467` **22** occorrenze; un conteggio più stretto ne rendeva **11**; nessuno dei due era
falso quanto **inutilizzabile**: il primo contava anche i numeri che comparivano nel **testo di
contesto** stampato accanto a ogni riga trovata (rumore da snippet), non solo le occorrenze vere. Ho
rifatto il censimento con estrazione pulita, deduplicata per **(bersaglio, file sorgente, riga
sorgente)** — l'unità che conta davvero, perché una riga fisica di questo progetto è spesso un
paragrafo intero e più menzioni dello stesso numero nella stessa riga sono **un solo punto da
editare**, non tre.

**[M] Due forme di notazione, controllo positivo per ciascuna, come richiesto:**

| target | forma lunga (`FILE.md:NNN`) | forma corta (`LIBRO:`/`BUGS:`) |
|---|---:|---:|
| LIBRO | 71 | 36 |
| BUGS | 23 | 19 |
| SCALETTA (riverifica indipendente) | 18 | 12 |

Nessuna forma rende zero: **entrambe le forme sono verificate vive** su tutti e tre i file.

**[M] Totali (dedup per sorgente+riga):** LIBRO 107 citazioni (62 nude · 45 ancorate) · BUGS 42 (33
nude · 9 ancorate).

**[M] Riconciliazione con i tuoi numeri — fatta, come disponi al §① del mandato, prima di dichiarare
qualunque divergenza:**

| target | tuo conteggio | il mio (sorgenti distinte) | riconciliato? |
|---|---|---|---|
| `BUGS:243` | (implicito ×1) | 1 sorgente (`BUGS:1048`) | ✅ |
| `BUGS:266` | (implicito ×1) | 1 sorgente (`BUGS:1048`, stessa riga di sopra) | ✅ |
| `BUGS:289` | (implicito ×1) | 1 sorgente (`LIBRO:335`) | ✅ |
| `BUGS:349` | ×2 | 2 sorgenti (`BUGS:394`, `BUGS:1057`) | ✅ |
| `BUGS:355` | ×2 | 2 sorgenti (`BUGS:394`, `BUGS:1057`) | ✅ |
| `BUGS:741` | ×3 | 2 sorgenti (`LIBRO:338` — 2 menzioni nella stessa riga, `LIBRO:339`) → 3 token grezzi, 2 punti-editabili | ✅ (il tuo numero è il conteggio-token; il mio è il conteggio-sorgenti; **2 menzioni dentro `LIBRO:338` spiegano lo scarto 3→2**) |
| `BUGS:743` | (implicito ×1) | 1 sorgente (`LIBRO:339`) | ✅ |

**Non ho trovato divergenze reali.** L'unico scarto (741: tuo 3, mio 2) è spiegato dalla differenza
fra «occorrenze del token» e «punti fisici da editare», e riconciliato sopra.

**[M] LIBRO:467 — il tuo «undici, di cui nove dentro BUGS» riconcilia altrettanto bene** come
conteggio-token: la mia lista deduplicata rende **6 sorgenti distinte** (4 in BUGS: righe 394, 395,
1057, 1058 · 2 in LIBRO stesso: righe 500, 502), e la riga 395 da sola contiene **cinque o sei
menzioni letterali** del token dentro un unico paragrafo lunghissimo — è lì che il tuo conteggio-token
sale a nove dentro BUGS.

---

## ② QUALI RISOLVONO OGGI — e qui il censimento cambia forma

**[M] Prima distinzione, verificata a fonte e non presunta: il registro non si tocca.** Ho controllato
riga per riga se ogni sorgente NUDA che cita un bersaglio ≥ soglia sta dentro una riga numerata `| NN |`
delle sezioni «storico versioni» (LIBRO Sez.6, e l'equivalente in BUGS che comincia dopo `## 🟢 Luglio
2026` a riga 743). **Cinque sorgenti sono registro, frozen per convenzione già stabilita nel progetto
(«è storia e non si marca mai»):**

| sorgente | riga registro | frozen |
|---|---|---|
| `BUGS:1048` | `\| 37 \| 2026-07-15 \|...` | ✅ |
| `BUGS:1057` | `\| 46 \| 2026-07-30 \|...` | ✅ |
| `BUGS:1058` | `\| 47 \| 2026-08-01 \|...` | ✅ |
| `LIBRO:500` | `\| 48 \| 2026-07-31 \|...` | ✅ |
| `LIBRO:502` | `\| 50 \| 2026-08-01 \|...` | ✅ |

⇒ Restano **cinque sorgenti VIVE** da verificare per contenuto: `LIBRO:335`, `BUGS:394` (che cita due
bersagli, 349 e 355), `LIBRO:338`, `LIBRO:339`. Le ho verificate tutte, una per una, leggendo cosa
afferma la sorgente e cosa c'è OGGI al bersaglio.

### Il risultato, e perché cambia il mandato

**[M] TUTTE E CINQUE SONO GIÀ ROTTE OGGI. Zero sane trovate.**

**1) `LIBRO:335` → `BUGS:289`.** La riga afferma che a `BUGS:289` vivono riferimenti a
`AppRootView.swift:8,13,27-33` e `:10-12`. **Falso oggi:** `BUGS:289` parla di `nextSection`/
`prevSection` MIDI, tutt'altro ticket. Il contenuto vero descritto da `LIBRO:335` è oggi a
**`BUGS:317`** — verificato: «Cos'è: la radice dell'app commuta tra due schermate
(`AppRootView.swift:8,13,27-33`…)» e «commento `AppRootView.swift:10-12`».

**2) `BUGS:394` → `BUGS:349`.** La riga afferma che quattro frasi («uccide la sessione», «muore SOLO»,
«spegne il metronomo», «uscita dalla stanza») sono «tutte e quattro **la riga 349** di questo stesso
ticket». **Falso oggi, e nel modo più netto fra i cinque:** riga 349 appartiene al ticket
`TD-fineshow-bottoni-morti` (titolo a `:344`), **non** a `TD-qlive-search-keyboard-trap` (titolo a
`:384`, il ticket che contiene la riga 394 stessa). Misurato dove vivono davvero le quattro frasi
oggi: «uccide la sessione» → righe **394**, 1056 · «muore SOLO» → **388**, 394 · «spegne il metronomo»
→ **388**, 394 · «uscita dalla stanza» → **394**. Nessuna delle quattro è a 349.

**3) `BUGS:394` → `BUGS:355`, con la clausola «questa stessa riga».** È il caso più diretto da
misurare: la riga che scrive «questa stessa riga» **non è fisicamente a 355**, è a **394**. Falso per
costruzione — non serve nemmeno leggere il contenuto del bersaglio, la riga si contraddice sulla
propria posizione. (Letto comunque: `BUGS:355` oggi appartiene al ticket `TD-shows-authoring` e parla
del mount di `ShowsListView` — nulla a che fare con la tastiera di ricerca.)

**4-5) `LIBRO:338`/`LIBRO:339` → `BUGS:741`/`:743`.** Le due righe citano `BUGS_QBEATS.md:741-743`
come sede del ticket `TD-ipad-home` (chiuso 30/06, collaudo `b1c50ab`, con la formula
`sf = .pad ? min(width/390, height*0.92/844) : width/390`). **Falso oggi:** `BUGS:741-743` è oggi
testo di intestazione della Sezione 2 («Per data di chiusura, decrescente.» / «## 🟢 Luglio 2026»).
`TD-ipad-home` vive oggi a **`BUGS:775`** (titolo) con la formula citata verbatim a **`BUGS:777`**.

**6) `LIBRO:467`, citato da `BUGS:394` e `BUGS:395`.** Afferma di puntare alla «voce 43 del registro
… proprietà del runner». **Falso oggi:** a `LIBRO:467` c'è una voce di changelog del 26/05 sul rename
del file (`STATO_QBEATS.md → LIBRO_MASTRO_QBEATS.md`). La voce 43 vera è oggi a **`LIBRO:495`**. ⚠️
**Ma questa è l'unica delle sei per cui il progetto si è già dato una risposta:** `BUGS:395` è **già**
una marcatura, datata 30/07, che dichiara esplicitamente «`LIBRO:467` È UN PUNTATORE SCADUTO: il suo
bersaglio si indirizza per CONTENUTO» — e prescrive di cercare per contenuto invece che fidarsi del
numero. **Non serve una seconda marcatura**: quella già scritta assolve la stessa funzione, anche se
il numero specifico che *lei stessa* riportava (`:476`, poi `:477`, poi `:484`) è a sua volta
scaduto più volte — il meccanismo descritto («il numero è deriva pura») resta vero e sufficiente.

---

## ③ RIPARAZIONE ASIMMETRICA — perché mi fermo prima di ripararne una

Il tuo §③ dispone tre esiti: sana→sposta, rotta→marca-e-lascia, ambigua→elenca-e-lascia. **Ho
applicato la griglia e il risultato è che il primo esito — quello che avrebbe richiesto aritmetica —
non ha NESSUN caso.** Zero citazioni sane trovate nel range del delta. Le cinque vive sono tutte
rotte; una (`LIBRO:467`) è già marcata; le altre quattro non lo sono ancora.

⛔ **Qui scatta la tua clausola di proporzione, e non per un'interpretazione larga: è il caso
esatto che descrivi.** «Se ti accorgi che ② è molto più grande di quanto sembra — per esempio che le
citazioni rotte sono la maggioranza — FERMATI e riferisci prima di ripararne una». Non è la
maggioranza: è **la totalità**. Aggiungere quattro marcature nuove per documentare un decadimento che
non ha alcuna relazione causale con A92 — le sue radici sono datate 30/07 (v46), 01/08 (v47), e
antecedenti — sarebbe esattamente «riordinare altro» sotto la copertura di un mandato che non lo
prevede. **Mi fermo prima di scrivere la prima marcatura, come da disposizione, e riferisco.**

**[M] Una cosa però la posso affermare con sicurezza, ed è la parte che completa A92:** poiché
nessuna delle cinque citazioni vive era sana anche PRIMA di questo diff, **A92 non introduce alcuna
rottura nuova**. Il delta (+4 in LIBRO, +1 in BUGS) non danneggia nulla che funzionasse, perché non
c'era nulla che funzionasse in quel range. L'anti-cascata di A92, nella sostanza che conta — «questo
diff non silenzia un puntatore che oggi dice il vero» — **è verificata e chiusa**. Quello che resta
aperto è un problema **preesistente e più grande**, non un sottoprodotto di A92.

**Nessuna riga è AMBIGUA fra le cinque**: ognuna è stata decisa con una lettura diretta del bersaglio,
non per sospetto.

---

## ④ DIFF AGGIORNATO

`HANDOFF/DIFF_2026-08-18_A92-METRONOMO.txt`

- **Contenuto delle sei incisioni: INVARIATO, byte-esatto.** Verificato con hash sulle sole righe `+`
  di contenuto (esclusi gli header `+++`): `55d7ec95…e359a796c`. Nessuna parola delle incisioni
  ratificate è stata toccata.
- **Preambolo aggiornato**, fuori dalle righe `---`/`+++`: dichiara l'anti-cascata su **tutti e tre i
  file** (non solo SCALETTA), riporta il censimento del §② in forma compatta, ed elenca le cinque
  citazioni preesistenti-rotte con i loro bersagli veri, per chi le vorrà riprendere in un giro
  proprio.
- **[M] Verificato applicabile dopo l'aggiornamento**: `git apply --check` → **exit 0** su tutti e tre
  i file (LIBRO, SCALETTA, BUGS), albero pulito.
- Impronta nuova del file diff: sha256 `3c21d241…7d0022a`, 13 354 B, 83 righe (era 11 808 B, 253
  righe — la crescita è tutta nel preambolo informativo, zero nei tre hunk).

---

## ⑤ LA REGOLA PROPOSTA — proposta, non scritta come regola

Sì, la propongo, e i fatti di oggi la motivano meglio di quanto potessi immaginare aprendo il
mandato: **cinque citazioni vive su cinque, in due canonici sorvegliati come questi, sono risultate
scadute.** Non è un incidente isolato: è un pattern misurato tre volte nello stesso pomeriggio
(SCALETTA in A92, LIBRO/BUGS qui).

**Proposta di formulazione, da ratificare se e come deciderai:**
> Ogni nuovo riferimento numerico fra canonici (LIBRO, BUGS, BOX3, BOX5, SCALETTA) **deve** portare
> `@ <commit a 40>`. Un riferimento nudo è debito dal momento in cui nasce, non uno stato normale in
> attesa di rottura.

**[I] Cosa NON farebbe questa regola, dichiarato per onestà:** non ripara nulla di esistente — le
cinque rotte di oggi restano rotte finché qualcuno non apre l'atomo dedicato. Ferma solo il
sanguinamento futuro. Se pensi che valga comunque, è materia dei due cancelli come ogni regola; non
l'ho scritta da nessuna parte nei canonici.

---

## RIEPILOGO

| # | esito |
|---|---|
| ① | Censimento completo, due forme, controllo positivo su entrambe. Riconciliato con i tuoi numeri: **zero divergenze reali**, un solo scarto spiegato (conteggio-token vs conteggio-sorgenti su `BUGS:741`) |
| ② | 5 sorgenti registro **escluse per convenzione** (frozen) · 5 sorgenti vive verificate **una per una**: **tutte e cinque già rotte oggi**, indipendentemente da A92 |
| ③ | Zero citazioni sane → zero da spostare. **Mi fermo prima di marcare** le quattro non ancora marcate: è la clausola di proporzione del mandato, applicata alla lettera, non un'interpretazione larga. `LIBRO:467` ha già una marcatura sufficiente dal 30/07 |
| ④ | Diff aggiornato: contenuto ratificato **invariato byte-esatto** (hash verificato), preambolo esteso a tutti e tre i file, **applicabile** (`git apply --check` exit 0) |
| ⑤ | Regola «citazioni nude = debito» **proposta**, non scritta: i fatti di oggi la motivano (5/5 rotte), ma è materia dei due cancelli |

**Conclusione operativa:** l'anti-cascata di A92 è chiusa nella sostanza — nessuna rottura nuova
introdotta. Il decadimento preesistente in LIBRO/BUGS (cinque citazioni, radici al 30/07-01/08) è
**censito per intero, con bersaglio vero per ciascuna**, e proposto come atomo a sé, non eseguito qui.

⛔ Nessun commit. Servono i due cancelli: tua ratifica sul diff aggiornato, poi OK esplicito di
Mauro. Se decidi di aprire l'atomo di riparazione delle cinque citazioni, questo referto ne è già il
censimento di partenza — non andrebbe rifatto.

---

*A93-ANTICASCATA-FINE*
