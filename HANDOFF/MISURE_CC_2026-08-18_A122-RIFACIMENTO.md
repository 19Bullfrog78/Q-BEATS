# MISURE CC — A122, RIFACIMENTO DELL'INNESTO SCALETTA

Da: CC · A: Mauro + referee · 18/08/2026
⛔ **NESSUN COMMIT, NESSUN PUSH.** HEAD invariato a `44fea3e378414c300ffd50fcac527c683740735b`.
⛔ **Zero righe sotto `ios_app/`.** Toccati: `SCALETTA` (rifatta da HEAD) e `LIBRO` (una riga).
✅ **`BUGS` NON è stato toccato:** il suo diff è ratificato in A121 e resta esattamente com'era.

Marcatura: **[M]** misurato ora, da me · **[R]** riportato · **[A]** giudizio mio.

---

## L'ERRORE DI A121, E PERCHÉ LE MIE TRE CONTROPROVE NON POTEVANO VEDERLO

**[M] Il difetto, confermato prima di ripristinare:** in `SCALETTA` l'intestazione
`### ⟦S6⟧ METROFAB …` (riga 315) era seguita **immediatamente** da
`### ⟦S5b⟧ Start del dettaglio …`. ⇒ ⟦S6⟧ senza corpo, e il corpo di ⟦S6⟧ finito in coda a
⟦S5b⟧, che si ritrovava **due `Scopo:` e due `File:`**.

**[M] Causa, a livello di una riga:** l'asserzione era giusta — `assert S[312].startswith('### ⟦S6⟧')`
**verifica che la riga 313 sia davvero l'intestazione di ⟦S6⟧** — ma poi ho scritto `S[313:313]`,
che inserisce **dopo** quella riga. Serviva `S[312:312]`. Un indice, e l'asserzione non poteva
accorgersene perché controllava il **bersaglio**, non il **verso**.

⛔ **[A] E qui sta la lezione, che vale più dell'errore.** Le mie tre controprove di A121 erano
tutte **vere**, e tutte **incapaci di fallire su questo**:

| controprova di A121 | che cosa dimostrava | perché era cieca |
|---|---|---|
| «103 righe su 103, divergenti 0» | che il **contenuto** della scheda è quello di A118 | confronta la scheda a partire dalla **sua** intestazione, ovunque essa sia |
| «13 intestazioni in sezione B» | il **conteggio** | 13 è 13 anche in ordine sbagliato |
| `git apply -R --check` OK | la **reversibilità** del diff | un diff che introduce un difetto è reversibile esattamente come uno sano |

⇒ **Nessuna delle tre guardava l'ORDINE, ed è l'unica cosa che era rotta.**
**Una controprova che non può fallire non è una controprova**: è una conferma che ci si dà da soli.

---

# B1 · L'INNESTO RIFATTO

**[M]** Ripartito da **HEAD pulito** sulla sola `SCALETTA`
(`git checkout --`, sha256 tornato a `09bf3442…`; `BUGS` lasciato intatto e ancora modificato).
La scheda è stata **riestratta programmaticamente** da
`HANDOFF/MISURE_CC_2026-08-18_A118-SCHEDA-STRETTA.md` (blockquote, prefisso `> ` rimosso) e inserita
**PRIMA** della riga `### ⟦S6⟧`, cioè dopo la fine del blocco di ⟦S5⟧, ultima marcatura compresa.
La marcatura del titolo di sezione è rimasta **identica** a quella di A121.

**[M] Verbatim, ricontrollato dopo la scrittura: 103 righe confrontate una a una, DIVERGENTI 0.**

## ⛔ LA CONTROPROVA D'ORDINE — e la prova che sa dire di NO

**[A] Come funziona, dichiarato perché sia rifacibile:** estrae la sequenza **ordinata** delle
intestazioni `###` fra `## B ·` e `## C ·`; per **ciascuna**, isola il blocco fino all'intestazione
successiva e misura due cose:

1. la prima riga non vuota che segue l'intestazione **non deve essere un'altra intestazione**;
2. il blocco deve contenere **esattamente UN** `- **Scopo:**`.

⚠️ La seconda è quella che morde: se una scheda è innestata nel posto sbagliato, **una scheda
resta con zero `Scopo` e un'altra ne prende due**. Il difetto non può nascondersi.
⚠️ La regola è sul **blocco**, non sulla prima riga: ⟦S3⟧ apre con `🔴 **RISCRITTO 12/07**` e non
con `Scopo:`, e passa lo stesso — correttamente.

### La verifica FALLISCE sulla disposizione di A121 — ricostruita in memoria, non riscritta

```text
  [A121] intestazioni: 13  |  ANOMALE: 2
     ⛔ :313  ⟦S6⟧ METROFAB — cablaggio porta (d -> blocco con 0 `Scopo:` invece di 1
     ⛔ :314  ⟦S5b⟧ Start del dettaglio → player -> blocco con 2 `Scopo:` invece di 1
```

⇒ **È una controprova vera:** applicata al difetto che doveva trovare, lo trova, e lo nomina.
Lo script si **ferma da solo** se questa dimostrazione non fallisce.

### Sequenza ORDINATA — PRIMA (12 intestazioni)

```text
  :42   ⟦S0⟧ QLiveTheme — token strutturali
  :48   ⟦S1⟧ RoomSwitchBar — componente INERTE + tipo `Room`
  :54   ⟦S2F⟧ MetroFAB — componente condiviso
  :60   ⟦S2⟧ Empty-state E/F/G (solo corpo)
  :66   ⟦S3⟧ Q-Stage Shows list (frame ①) + sort sheet
  :125  ⟦NODO A⟧ N0→N1a→N1b
  :132  ⟦S4⟧ QLiveShowsView (frame ②) = nuova root QLiveRootView
  :165  ⟦S4K⟧ Congedo tastiera (contratto Q20)
  :194  ⟦S4R⟧ Live launcher: iniezione setlist + kill phantom makeDefault
  :247  ⟦S4L⟧ Prima scrittura: «Remove from Q-Live» + menu «···»
  :298  ⟦S5⟧ QLiveShowDetailView (frame ③) + Start
  :313  ⟦S6⟧ METROFAB — cablaggio porta (dest differita stub)
  [PRIMA] intestazioni: 12  |  ANOMALE: 0
```

### Sequenza ORDINATA — DOPO (13 intestazioni), con `Scopo` e prima riga utile

```text
  :44   ⟦S0⟧ QLiveTheme                       scopo=1  - **Scopo:** nuovo enum top-level `QLi
  :50   ⟦S1⟧ RoomSwitchBar                    scopo=1  - **Scopo:** componente `.roomseg` (0
  :56   ⟦S2F⟧ MetroFAB                        scopo=1  - **Scopo:** estrarre il METROFAB in c
  :62   ⟦S2⟧ Empty-state E/F/G                scopo=1  - **Scopo:** 3 corpi empty (no-shows/s
  :68   ⟦S3⟧ Q-Stage Shows list               scopo=1  🔴 **RISCRITTO 12/07** dal contratto ra
  :127  ⟦NODO A⟧ N0→N1a→N1b                   scopo=1  - **Scopo:** `Screen.qLive`; `QLiveRoo
  :134  ⟦S4⟧ QLiveShowsView                   scopo=1  - **Scopo:** Q-Live apre lista Shows r
  :167  ⟦S4K⟧ Congedo tastiera                scopo=1  - **Scopo:** costruire il contratto Q2
  :196  ⟦S4R⟧ Live launcher                   scopo=1  - **Scopo:** parametrizzare l'ingresso
  :249  ⟦S4L⟧ Prima scrittura                 scopo=1  - **Scopo:** costruire «Remove from Q-
  :300  ⟦S5⟧ QLiveShowDetailView              scopo=1  - **Scopo:** detail read-only pushato
  :315  ⟦S5b⟧ Start del dettaglio → player    scopo=1  - **Scopo:** costruire **una porta sol
  :419  ⟦S6⟧ METROFAB                         scopo=1  - **Scopo:** legare `onTap` MetroFAB (
  [DOPO] intestazioni: 13  |  ANOMALE: 0
```

⇒ **[M] ⟦S5b⟧ a `:315`, ⟦S6⟧ a `:419`: la scheda sta PRIMA, e ⟦S6⟧ ha di nuovo il suo corpo.**

---

# B2 · LA CITAZIONE CHE ROMPEVAMO NOI

**[M] Ancorata a commit, non aggiornata di numero**, come disposto. Una sola sostituzione, su
`LIBRO_MASTRO_QBEATS.md:356`:

```text
PRIMA:  …a `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:329` («NIENT…
DOPO:   …a `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:329 @ 44fea3e378414c300ffd50fcac527c683740735b`…
```

⇒ **[M] Da nuda a IMMUNE.** Il numero `:329` non si tocca: ancorato al commit, continua a
significare esattamente ciò che significava, **anche dopo il nostro innesto e dopo tutti i
prossimi**. Aggiornarlo a `:435` lo avrebbe rimesso in fila per rompersi al prossimo inserimento.

**[M] E la marcatura `SCALETTA:324` è stata MARCATA, non riscritta.** La riga resta identica; sotto
di essa è stata posata una marcatura che registra: la clausola «zero citazioni nude ≥320» era
**VERA** al blob `779172e6…` (**0**) ed è **FALSA** a HEAD (**1**, in `LIBRO:356`, introdotta dopo
quella misura dalla riga `2026-08-18` sui pulsanti inerti); che quella citazione è stata ancorata
in questo stesso giro; e la lezione generale — **una clausola di quel tipo è una misura, e le
misure scadono: chi inserisce righe la rimisura, non la rilegge.**

---

# B3 · LE DUE COSE NON PIÙ PENDENTI — prese in carico

- ✅ **A117 RESTA, ID bruciato come ESEGUITO.** Ne prendo atto e non lo tocco: l'artefatto e le sue
  tre gambe restano dove sono. **A116 non è mai esistito** — confermo la misura: la sua unica
  occorrenza nel repo è la **menzione** dentro il referto A117.
- ✅ **Bump di versione: NON in questo giro**, va nel giro di deposito insieme al commit.
  ⚠️ Lo ripeto qui perché non si perda: **restano da bumpare due canonici**, `SCALETTA` e `BUGS`,
  più `LIBRO` se la convenzione lo prevede anche per una modifica di una riga sola.

---

# B4 · COSA CONSEGNO

## I diff — artefatti separati, verbatim

| file | byte | sha256 |
|---|---:|---|
| `HANDOFF/DIFF_2026-08-18_A122-SCALETTA-S5b.txt` | 20 499 | `47a786f5e6508a65eca68ea93eae44006522c3b0f5cac2489174f1cec87fc6e2` |
| `HANDOFF/DIFF_2026-08-18_A122-LIBRO-ANCORA.txt` | 15 806 | `c567e1c7d4f86e9e2702b9fed675d6a164c2e5ea3272870ab122994866251b89` |

⚠️ **Il diff di `BUGS` NON è in questa lista e NON è stato rigenerato:** resta quello di A121,
ratificato — `DIFF_2026-08-18_A121-BUGS.txt`, sha256
`1451c95328a5473bcac086b91cd52f7f12607eebaf95bb9ad96fab177a13e2c9`.

**[M]** `git apply -R --check` → **OK su entrambi i nuovi**.
**[M]** Stato complessivo dell'albero: **3 file, 129 inserzioni, 1 cancellazione** — e l'unica
cancellazione è la riga di `LIBRO:356` sostituita dalla sua versione ancorata.

## Impronte prima / dopo

**[M]**

| file | | sha256 | byte | righe | CR |
|---|---|---|---:|---:|---:|
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | **prima** (= HEAD) | `09bf3442a372a17e66dda7d53ca512e0d1bc551e80f42d2c7a08614811d84fe5` | 56 791 | 350 | 0 |
| | **dopo** | `258e7e690af377a2bfb64dec80075e70d92989b11e46f8487e674b70a215a0a8` | 66 316 | 457 | 0 |
| `LIBRO_MASTRO_QBEATS.md` | **prima** (= HEAD) | `9e09446380af90550b417b299d5e785532c2ac1d1b6ef1a19f619255936e02a1` | 275 988 | 518 | 518 |
| | **dopo** | `b7355296f6281e4e7c1f763f90f9474df39a166ee57f072361b8f2ddd539bd25` | 276 031 | 518 | 518 |
| `BUGS_QBEATS.md` | **invariato da A121** | `5261157b2236d5fe1317b20f7b136eb3a26832aa1c3025b15f342f92b17411df` | 310 426 | 1 088 | 1 088 |

⚠️ **Facce disco diverse, dichiarate:** `SCALETTA` è **LF** (`CR 0`), `LIBRO` e `BUGS` sono
**CRLF** (`CR = righe`). **[M] Omogeneità verificata dopo ogni scrittura:** `SCALETTA` 457 LF /
0 CRLF · `LIBRO` 518 CRLF / 0 LF-sole. ⇒ Il difetto di fini-riga miste che avevo introdotto in
A121 **non si è ripetuto**: l'adattamento alla faccia del bersaglio è ora dentro lo strumento.

## Cosa NON ho toccato

⛔ `BUGS_QBEATS.md` (ratificato in A121) · **sezione C** della SCALETTA · qualunque riga sotto
`ios_app/` · il **bump di versione** dei canonici · il numero `:329` dentro la citazione di LIBRO
(ancorato, non aggiornato) · il testo storico di `SCALETTA:324` e del titolo di sezione B
(marcati, non riscritti) · nessun commit, nessun push.

---

## COSA NON HO FATTO

⚠️ **Lacuna dichiarata:** nessuna verifica indipendente. ⛔ E il fatto che pesa: **il difetto di
A121 l'ho consegnato con tre controprove verdi in mano.** La controprova d'ordine di oggi esiste
perché il referee ha guardato il diff, non perché uno strumento mio abbia gridato.

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1.

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `31505f475a6367f008922a434d2f5ecb6844eebcfb6c53c56742508609773c5d`
- **byte** (file completo): `11588`
- **righe** (file completo): `216`
- **CR** (0x0D, contati sui byte, mai con grep): `0`
- **byte NUL** (0x00, controprova sul bersaglio): `0`

---

*A122-RIFACIMENTO-FINE*
