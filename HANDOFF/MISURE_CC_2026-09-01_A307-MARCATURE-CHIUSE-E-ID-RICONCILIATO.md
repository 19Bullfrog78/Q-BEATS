# MISURE CC — A307 — MARCATURE CHIUSE E ID RICONCILIATO — 2026-09-01

Da: CC · A: referee. Mandato: **A307-MARCATURE-CHIUSE-E-ID-RICONCILIATO**, dichiarato in testa e coincidente con quello ricevuto.

**Orologio**: 2026-09-01, **14:59:51 locale (UTC+2)**.

Marcatura: **[M]** misurato ora da me, alla fonte · **[R]** riportato, non verificato da me · **[A]** giudizio mio.

---

## 0 · Orologio e cancello sull'ID

**[M]** Cancello a sei gambe su `A307`, binari esclusi (`grep -rI`): tutte e sei le gambe = **0**. Nessun falso-UNO. Tree pulito prima di iniziare, HEAD `976d986`.

---

## 1 · 🚨 Riconciliazione — prima di tutto il resto

**[M] Rimisurato a fonte, non ricostruito a memoria.** Sei gambe fresche su entrambi i numeri, oggi:

| | A305 | A306 |
|---|---|---|
| nomi C:/E: | 0 / 0 | 1 / 1 (i miei) |
| git grep tracciato | 0 | 3 (i miei, working tree) |
| disco C: contenuto (testo, no binari) | 0 | 4 file (i miei) |
| disco E: contenuto (testo, no binari) | 1 — **stesso rumore binario già classificato in A306**, non un uso reale | 1 (il mio referto) |
| git log --grep | 0 | 0 |

**Risposte alle tre domande del mandato:**

1. **A305 era libero o occupato quando l'ho aperto?** **Libero**, misurato da me con cancello a sei gambe (tutte zero) e controllo positivo, prima di iniziare il lavoro del giro scorso. Assegnazione pulita e valida al momento.

2. **A306 è stato scelto per collisione misurata, o è uno slittamento?** **Uno slittamento precauzionale, non una collisione misurata.** Quando Mauro ha segnalato il rischio di lavoro parallelo, la mia rimisura su A305 rendeva ANCORA zero su tutte le gambe — nessuna prova diretta di uso altrui. Ho cambiato numero seguendo la regola standing («se collide, cambialo da te») per eccesso di cautela su una segnalazione `[R]` che non potevo verificare, non perché avessi misurato un'occupazione reale.

3. **Quali dei due risultano bruciati, oggi?** **A305 è oggi completamente pulito** — zero residui, nessuna prova che sia mai stato usato da altri su questo disco. **A306 porta l'intero corpo di lavoro verificato**: referto su due gambe, tre marcature (poi diventate quattro con questo giro), tutto internamente coerente.

**[A] Decisione, e perché**: **mantengo A306** come numero che entra nei documenti permanenti. Tornare ad A305 non eliminerebbe il rischio che ha causato lo slittamento — lo riproporrebbe, dato che non ho mai avuto conferma indipendente che fosse sicuro. A306 è il numero con lavoro reale, verificato tre volte (compreso questo giro), dietro di sé. **Dichiaro A305 bruciato e saltato per igiene del registro**: nessun lavoro futuro dovrà riusarlo, e questa riga ne spiega il perché così chi lo cerca trova la ragione invece del vuoto.

⚠️ **Resta un limite dichiarato**: non ho visibilità sull'altra chat. Questa riconciliazione si basa su misure fatte sul MIO disco; se l'altra sessione ha usato A305 o A306 altrove in modi che non lasciano traccia qui, non posso saperlo.

---

## 2 · La regola di processo — sostituita con la formulazione di Mauro

**[M]** Contenuto della riga LIBRO 401 **sostituito per intero** col testo dettato. **Verificato byte-per-byte**: 1139/1139 byte, identico. Colonna Chi aggiornata: **Mauro (formulazione, ratifica 01/09) + referee (autodichiarazione dell'errore) + CC (verifica a fonte, scrittura)** — la forma (6 colonne, 7 pipe) coincide con la sorella 399.

---

## 3 · Il dubbio sciolto — Sezione G

**[M]** Sostituita la clausola «non è misurato» con la risoluzione del referee. **Verificato byte-per-byte**: 292/292 byte, identico.

---

## 4 · Marcatura nuova — `BUGS_QBEATS.md`, `TD-segmini-onswitch-morto`

**[M]** Inserita come nuovo sotto-punto della faccia (a), stessa forma delle sorelle (`- ⚠️ **...**`, stesso livello di indentazione). **Verificato byte-per-byte**: 919/919 byte, identico.

---

## 5 · Le due riserve scadute — sostituite

**[M]** Sostituite entrambe le clausole «in attesa della parola di Mauro» (riga LIBRO 400 «CHI COMANDA SU COSA» e la coda della marcatura di Sezione G) col testo dettato al §5. La terza occorrenza (riga di processo, §2) è sparita per costruzione: la sostituzione integrale del §2 non la conteneva più.

---

## Bump di versione, dove il file ne ha una

| file | prima | dopo |
|---|---|---|
| `LIBRO_MASTRO_QBEATS.md` | v72 | **v73** — corpo di v72 preservato per intero nella catena (R-δ.7, verificato: 6.451 caratteri presenti intatti), 577 righe invariate |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | v16 | **v17** — nuovo segmento appeso alla catena in testa, stesso pattern delle 16 transizioni precedenti (incluso il buco noto v14/v15, non toccato) |
| `BUGS_QBEATS.md` | v78 | **v79** — formato semplice (Versione + Ultima modifica), nessuna catena da preservare |
| `DESIGN/QLive_Nav/README.md` | — | **nessuna intestazione di versione in questo file**: nessun bump, per costruzione |

**[M] Verifica strutturale finale, prima del commit**: righe totali README 112, SCALETTA 770, LIBRO 577 — tutte invariate rispetto a prima di questo giro (solo sostituzioni di testo, zero righe aggiunte o perse); BUGS 1662 (+1 riga, il nuovo sotto-punto). Pipe delle righe LIBRO toccate: 399→7, 400→7, 401→7, coincidenti.

---

## 6-7 · Commit

**Messa in scena da lista esplicita, mai `git add -A`, verifica bidirezionale su entrambi i commit** (0/0 discrepanze in entrambi i casi).

**Commit ① — le quattro marcature:**
```
1c05e306532ca5ae82da588da6bb3dc432702102
docs: chi comanda su cosa — marcature 18/07 vs 30/08 (A307)
autore: Mauro Martintoni <di_tutto@icloud.com>
4 files changed, 12 insertions(+), 6 deletions(-)
```

**Commit ② — il regime (referti del giro precedente ancora fuori):**
```
2c9b0bf8d4e48e2d6133029245b4db8e9bf5b9e3
docs(handoff): referti del giro marcature (A307)
autore: Mauro Martintoni <di_tutto@icloud.com>
3 files changed, 397 insertions(+)
 (A303, A304, A306 — i tre referti rimasti fuori dai commit precedenti)
```

**[M]** Zero trailer `Co-Authored-By` su entrambi. Tree pulito sui tracciati dopo entrambi i commit.

---

## 8 · Push e CI

**[M] Un push solo**: `976d986..2c9b0bf master -> master`, comprende entrambi i commit.

**[M] CI sulla punta**: run `33511389027`, titolo "docs(handoff): referti del giro marcature (A307)" (il commit di testa, che include ① sotto di sé). **Esito: SUCCESS, 2m39s.** Stesse annotazioni standard preesistenti (Node 20, Homebrew tap trust), non pertinenti a questo giro.

---

## 9 · Consegna

Referto depositato su due gambe, `cmp` e sha256 misurati dopo il deposito — coda del documento.

⚠️ Come nei giri precedenti: questo referto non è nei due commit di oggi (non esisteva ancora quando sono stati costruiti) — resta untracked, backlog per il prossimo giro.

---

## 10 · Fermarsi e dichiarare — esito

- **La riconciliazione del §1 non si chiude con un fatto misurato?** Si chiude: sei gambe fresche su entrambi i numeri, decisione dichiarata con la motivazione.
- **Un testo applicato non coincide col dettato?** Tutti e tre coincidono, byte-per-byte (1139/1139, 292/292, 919/919).
- **Una destinazione non ha righe sorelle da cui misurare la forma?** Tutte e quattro ne avevano.
- **Staged e lista non coincidono?** Coincidono, 4/4 e 3/3.
- **La CI non è verde?** È verde.
- **Una premessa è falsa alla misura?** No.

Nessuna condizione di arresto. Consegna completa.

---

*A307-MARCATURE-CHIUSE-E-ID-RICONCILIATO — fine corpo.*
