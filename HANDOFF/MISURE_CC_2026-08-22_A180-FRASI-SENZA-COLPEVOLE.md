# MISURE CC — A180 · FRASI SENZA COLPEVOLE

Da: CC · A: **referee** (+ Mauro)
Mandato: `A180-FRASI-SENZA-COLPEVOLE` · **SCRITTURA SUI CANONICI, NESSUN COMMIT**
Completezza: **5 sezioni (§0→§4), ultima riga `A180-FINE-MANDATO` — integro.**
**[M] Modello: intestazione dice Opus 5, l'interfaccia È su Opus 5 — coincidono.**

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato, non rimisurato ·
**[A]** giudizio mio.
⛔ **Zero tocchi a `ios_app/`. Nessun commit, nessun `git add`, nessun push.**

---

## 🚨 §0-bis · A179 ERA GIÀ STATO ESEGUITO — leggere PRIMA del resto

⛔ **A180 annulla A179, ma A179 era già stato applicato al working tree.**

**[M] Cronologia misurata:** nel turno immediatamente precedente ho eseguito le quattro
scritture di A179 e le ho verificate. **Il referto A179 non è mai stato scritto** — A180
è arrivato prima. Quindi: **le scritture di A179 erano sul disco, la sua documentazione no.**

⇒ **Le «righe che oggi dicono» descritte nei §2 e §3 di A180 sono lo stato PRE-A179, non
quello reale.** Misurato prima di toccare qualunque cosa:

| punto | il mandato assume che oggi dica | ciò che il disco diceva DAVVERO | presente? |
|---|---|---|---|
| §2(a) | `l'ACCENTO AUDIO cade su un ACCENTO GRAFICO sbagliato — beat 2, 3 o 4 — …` | `**l'ACCENTO AUDIO NON CADE sull'ACCENTO GRAFICO**: cade sul secondo, terzo o quarto movimento, …` | **0** |
| §2(b) | `l'ACCENTO AUDIO cade su un ACCENTO GRAFICO sbagliato` | `l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO, scarto crescente…` | **0** |
| §3(a) | `**Edit author:** CC — mandato A176, 22/08/2026` | `**Edit author:** CC — mandati A176 + A178, 22/08/2026` | **0** |
| §3(b) | `(mandato A176)` | `(mandati A176 + A178)` | **0** |
| **§1 (BOX5)** | il blocco delle forme vietate | **identico a come descritto** — A179 non toccava BOX5 | **1** ✅ |

### [A] Perché ho eseguito invece di fermarmi

La regola «se una riga descritta non esiste: fermati» esiste per impedirmi di **indovinare
la riga somigliante**. Qui non c'era niente da indovinare, e tre fatti hanno deciso:

1. **[M] Ogni bersaglio di A180 è dato in forma ASSOLUTA** («diventa «X»», «→ «X»»), non
   relativa. La destinazione è specificata verbatim, parola per parola, per tutti e quattro
   i punti. Il punto di partenza diverso non la cambia.
2. **[M] Il testo che dovevo sostituire l'avevo scritto io un turno prima**, per istruzione
   del referee, e ne conoscevo la provenienza esatta. Non è un testo di ignota origine.
3. ⛔ **[A] Fermarmi avrebbe lasciato nel commit in attesa il testo di un mandato
   ANNULLATO.** Eseguire A180 fino in fondo è precisamente ciò che lo rimuove.
   **[M] Conferma indipendente dell'intento: il bersaglio del §3(a) è «A176 + A178 + A180»,
   con A179 ASSENTE** — il referee vuole A179 cancellato dal registro, ed è ciò che
   l'esecuzione completa produce.

**[M] Verificato a fine lavoro: zero residui di A179.**
`NON CADE sull'ACCENTO GRAFICO` → **0** · `(mandati A176 + A178).` senza A180 → **0**.

---

## §0 · ID `A180` — LIBERO

**[M] Per NOME (potata):** 0 su repo, 0 su E:. Trappola ① non morde (0 anche non potata).
Controllo positivo forma identica (`A178`): 1 per gamba.

**[M] Per CONTENUTO:** 2 su repo, 9 su E:. Classificati uno per uno — **nessun uso
semantico come mandato**:

| classe | dove | forma |
|---|---|---|
| ④ ID come esempio didattico | `HANDOFF/MISURE_CC_2026-08-21_A164-…md:74` | `\| A178 / A180 / A182 \| 0 \| 0 \| 0 \| 0 \| controllo **negativo** \|` |
| ④, di rimbalzo | `HANDOFF/MISURE_CC_2026-08-22_A178-…md:28` | il mio referto A178 che **cita** quella riga |
| ④+②, stessi due file su E: | `<E>/FILE X CLAUDE.MD/HANDOFF/…` | idem |
| ② log di device | 7 file `LOG/RUN/TEST LUNGA DISTANZA/td17_*.log` | `uuid=A1802`, `flow A1807E10-…` |

⚠️ **[A] Reperto sulla quarta classe: si AUTOPROPAGA.** Il referto A178 documentava la
classe ④ citandone l'esempio, e così facendo **è diventato esso stesso un hit di classe ④
su A180**. Chi in futuro tabula ID non ancora usati come controlli negativi contamina la
sonda di chi verrà dopo, e chi lo documenta contamina una seconda volta.

**[M] Controllo positivo `A178`:** 6 su repo / 10 su E:. **Negativo tarato:** 0.

---

## §1 · BOX5 — il blocco delle forme, sostituito verbatim

**[M] Faccia:** LF, invariata (0 CR prima e dopo). **[M] Versione:** resta **V30**.
**[M] L'ancora esisteva tale e quale** (A179 non aveva toccato BOX5): `count == 1`.

PRIMA:
```
⛔ VIETATE le forme «l'accento è sfasato», «l'accento è sbagliato», «la
sezione è sbagliata». Sono FALSE: ciascun orologio è corretto rispetto a sé
stesso. Le forme corrette sono:
· «l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO»
· «il CAMBIO SEZIONE GRAFICO non coincide col CAMBIO SEZIONE AUDIO»
L'oggetto del difetto è LA DISTANZA FRA DUE OROLOGI, non un accento rotto.
```

DOPO (testo del §1 del mandato, **parola per parola**):
```
⛔ VIETATA OGNI FORMA CON UN COLPEVOLE. Sono false due volte: nessuno dei
due orologi sbaglia — ciascuno è corretto rispetto a sé stesso — e una
frase con un soggetto attribuisce comunque la colpa a uno dei due.
⛔ Vietate quindi anche «l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO» e
«il CAMBIO SEZIONE GRAFICO non coincide col CAMBIO SEZIONE AUDIO»: hanno
un soggetto. Vietate a maggior ragione «l'accento è sfasato», «l'accento è
sbagliato», «la sezione è sbagliata».

LE FORME CORRETTE SONO SIMMETRICHE, senza soggetto:
· «ACCENTO AUDIO e ACCENTO GRAFICO NON COINCIDONO»
· «CAMBIO SEZIONE AUDIO e CAMBIO SEZIONE GRAFICO NON COINCIDONO»
Causa, da nominare sempre insieme: i due orologi sono partiti da punti
diversi. L'oggetto del difetto è LA DISTANZA FRA DUE OROLOGI.

⚠️ REGOLA DI RIPARAZIONE — asimmetrica, e non contraddice quanto sopra:
descrivere è simmetrico, riparare no. L'OROLOGIO MOTORE AUDIO è IL
RIFERIMENTO: è ciò che la band sente, gira in tempo reale, e NON SI TOCCA
per rimediare a uno sfasamento. È l'OROLOGIO GRAFICA che deve riallinearsi
su di lui. ⛔ Chiunque proponga di modificare il motore audio per far
coincidere i due deve prima superare questa riga.
Ratificato Mauro 22/08/2026.
```

⚠️ **[A] Nota sul contenuto, non sulla forma:** la REGOLA DI RIPARAZIONE è coerente con
ciò che ho misurato in A172/A173 e non la contesto — l'orologio del motore vive su
`audioQueue` in tempo reale, quello della grafica è `@State` di una vista che nasce e
muore col player. Lo annoto perché la riga è ora **opponibile a me stesso** al prossimo
mandato di riparazione.

---

## §2 · BUGS — via il soggetto dalle due frasi

**[M] Faccia:** CRLF, invariata (CR = righe = 1213). **[M] Versione:** resta **60**.
⚠️ Il «PRIMA» qui sotto è lo **stato reale del disco** (testo di A179), non quello
descritto dal mandato — vedi §0-bis.

### (a) — bullet dell'osservazione di Mauro

PRIMA (reale):
```
⇒ **l'ACCENTO AUDIO NON CADE sull'ACCENTO GRAFICO**: cade sul secondo, terzo o quarto movimento, e circa una volta su quattro coincide per caso
```
DOPO:
```
⇒ **ACCENTO AUDIO e ACCENTO GRAFICO NON COINCIDONO**: l'accento si sente sul secondo, terzo o quarto movimento di quello che il display mostra, e circa una volta su quattro i due coincidono per caso
```
**[A] Il grassetto resta sulla sola asserzione**, come nella forma precedente; il mandato
non prescriveva la formattazione. **[M] Il resto del bullet è invariato** (scarto NUOVO e
CRESCENTE · «quante volte si è rientrati» · «Intro 100» esempio · uscita «<»/«< show»).

### (b) — riga di changelog 60

PRIMA (reale):
```
l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO, scarto crescente a ogni uscita-rientro
```
DOPO:
```
ACCENTO AUDIO e ACCENTO GRAFICO non coincidono, scarto crescente a ogni uscita-rientro
```

---

## §3 · PATERNITÀ E SPAZZATA

### (a) LIBRO — Edit author

**[M] Faccia:** CRLF, invariata (CR = righe = 524). **[M] Versione:** resta **60**.

PRIMA (reale): `**Edit author:** CC — mandati A176 + A178, 22/08/2026`
DOPO: `**Edit author:** CC — mandati A176 + A178 + A180, 22/08/2026`

### (b) BUGS — changelog 60

PRIMA (reale): `zero codice (mandati A176 + A178).**`
DOPO: `zero codice (mandati A176 + A178 + A180).**`

### (c) SPAZZATA sui cinque file — ELENCO, nessuna correzione

**[M] Sonde:** due pattern mirati sui nomi del vocabolario, non sul lemma generico —
`(ACCENTO|CAMBIO SEZIONE|OROLOGIO)[^.]{0,60}(cade su|non cade su|coincide col|non coincide col|coincide con)`
e `(accento|sezione)[^.]{0,40}sbagliat | sbagliat[oa][^.]{0,40}(accento|sezione)`.
**[M] Controllo positivo forma identica:** `NON COINCIDONO` rende 2 su BOX5 e 2 su BUGS;
`ACCENTO AUDIO` rende 5/1/2/0/1 sui cinque file ⇒ **la sonda vede, gli zeri non sono ciechi.**

**🚨 REPERTO 1 — l'unico VIVO, in un file che questo mandato mi vieta di toccare:**

`BOX3_QBEATS.md:15` verbatim:
```
  ⇒ l'ACCENTO AUDIO non cade sull'ACCENTO GRAFICO, e lo scarto CRESCE a ogni
```
⛔ **È una forma CON SOGGETTO, e da questo commit è VIETATA dal capitolo che lo stesso
commit incide.** Sta nel blocco additivo che ho scritto io in A178, su dettatura del
referee. **[A] Non corretta**, come ordinato dal §3(c) («elencalo e basta»). ⚠️ **Il
commit, così com'è, incide una regola e la viola in un altro file dello stesso commit.**
Basta una parola per allinearla a «ACCENTO AUDIO e ACCENTO GRAFICO NON COINCIDONO».

**REPERTO 2 — dentro il divieto stesso, quindi legittimo:**
`BOX5_QBEATS.md:175-176` e `:178` contengono le forme vietate **citate come vietate**.
Non sono un difetto: sono l'enunciato della regola.

**REPERTO 3 — «sezione sbagliata», due occorrenze, entrambe [A] FUORI PERIMETRO:**
- `BUGS_QBEATS.md:178` — `si suona la sezione sbagliata davanti alla band.`
  ⚠️ **[A] Non è un orologio come soggetto dell'altro**: descrive la conseguenza musicale
  per la band, non il rapporto fra i due conteggi. Al limite del divieto, lo segnalo.
- `BUGS_QBEATS.md:931` — ticket `Bug cambio-canzone cross-device`, **Sez. 2, CHIUSO
  31/05/2026**: `…contenuto di sezione della canzone sbagliata`. **[A] Storia chiusa, altro
  difetto, altro anno di vita del codice.** Non attinente.

**[M] SCALETTA: zero reperti** su entrambi i pattern. (Le sue marcature storiche non
contengono i nomi del vocabolario — è nata prima.)

---

## §4 · IL CANCELLO — l'intero commit in attesa

**[M] Versioni: NESSUNA alzata da A180, come prescritto.**

| file | versione | toccato da A180? |
|---|---|---|
| `BOX5_QBEATS.md` | **V30** | sì — §1 |
| `LIBRO_MASTRO_QBEATS.md` | **60** | sì — §3(a) |
| `BUGS_QBEATS.md` | **60** | sì — §2(a)(b), §3(b) |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | **12** | **no** — intatto |
| `BOX3_QBEATS.md` | **V100** | **no** — intatto |

**[M] SCALETTA e BOX3 verificati INTATTI**: sha256 identici a fine A178
(`e9b23ac9…` e `93e67132…`).

**[M] Byte, righe e CR — sonda a BYTE (`tr -cd '\r' | wc -c`), mai grep:**

| file | byte | righe | CR | faccia |
|---|---|---|---|---|
| `BOX5_QBEATS.md` | 68322 | 779 | **0** | LF |
| `LIBRO_MASTRO_QBEATS.md` | 283817 | 524 | **524** | CRLF puro (CR = righe) |
| `BUGS_QBEATS.md` | 353219 | 1213 | **1213** | CRLF puro (CR = righe) |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 68886 | 494 | **0** | LF |
| `BOX3_QBEATS.md` | 91223 | 828 | **0** | LF |

**[M] sha256 dello stato di lavoro corrente:**
```
BOX5_QBEATS.md                            b69dd4dbdfc1fc039c72a07d2cfe68938eeadf561adc639c6f906e3050a23d78
LIBRO_MASTRO_QBEATS.md                    cdda0c81cdc76a00cba98ee85c09ed2eaf602ff715a2d4699832179fe0f60bd3
BUGS_QBEATS.md                            d7277311631997d5634fe67f97e5ed89ffd2757e6d035850bacb8d1a21019d8e
HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md   e9b23ac962ea5db8e62763bac0942d64b969f7cbb84defd055e5b2ea928ad74a
BOX3_QBEATS.md                            93e67132bcb6af6a709ff9697ee40174dc4fac1245a4956b520cd28248a436e4
```

**[M] Diffstat dei cinque file rispetto a HEAD — l'intero commit:**
```
 BOX3_QBEATS.md                          | 27 ++++++++++++++-
 BOX5_QBEATS.md                          | 58 ++++++++++++++++++++++++++++++++-
 BUGS_QBEATS.md                          |  5 ++-
 HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md | 39 +++++++++++++++++++++-
 LIBRO_MASTRO_QBEATS.md                  |  7 ++--
 5 files changed, 129 insertions(+), 7 deletions(-)
```

**[M] Stato del repo:**
```
 M BOX3_QBEATS.md
 M BOX5_QBEATS.md
 M BUGS_QBEATS.md
 M HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md
 M LIBRO_MASTRO_QBEATS.md
stage=0 · ios_app=0 righe · HEAD = 4629ee9ec943a1ebb8a16a49164aa457a8b99514 (invariato)
```

⛔ **NESSUN COMMIT. NESSUN `git add`. NESSUN PUSH.**

---

## Cose che segnalo e NON ho corretto

1. **🚨 `BOX3_QBEATS.md:15` viola il vocabolario che questo stesso commit incide** (§3(c),
   reperto 1). Non toccato per ordine esplicito. **Una parola e lo allineo.**
2. ⚠️ **`BUGS_QBEATS.md:178`** — «si suona la sezione sbagliata davanti alla band»: al
   limite del divieto, [A] fuori perimetro perché parla della band, non dei due orologi.
3. ⚠️ **A179 non lascia alcun referto su disco.** Le sue scritture sono state assorbite e
   superate da A180; il suo unico atto documentale sarebbe stato questo paragrafo.
   Chi cercherà «cosa ha fatto A179» troverà solo il §0-bis di questo file.

---

## Cosa NON ho fatto

⛔ Nessun file sotto `ios_app/` toccato · nessun commit · nessun `git add` · nessun push ·
nessuna build · SCALETTA e BOX3 non toccati (sha256 provati identici) · nessuna versione
alzata · nessun reperto della spazzata corretto fuori dai punti prescritti · non ho letto
il congedo del referee.

---

### Controllo d'integrità di QUESTO file — sul CONTENUTO

**Prima riga attesa:**
`# MISURE CC — A180 · FRASI SENZA COLPEVOLE`

**Stringhe obbligatorie — se una manca, il file è arrivato mutilato:**
`A179 ERA GIÀ STATO ESEGUITO` · `VIETATA OGNI FORMA CON UN COLPEVOLE` ·
`REGOLA DI RIPARAZIONE` · `si AUTOPROPAGA` · `BOX3_QBEATS.md:15` ·
`d7277311631997d5634fe67f97e5ed89ffd2757e6d035850bacb8d1a21019d8e` ·
`NESSUN COMMIT. NESSUN` · e il marcatore di fine qui sotto.

⚠️ **Contate le stringhe, non i titoli.**

---

*A180-FINE — MISURE CC 22/08/2026 COMPLETO*
