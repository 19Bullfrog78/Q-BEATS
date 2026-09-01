# MISURE CC — A299 — 31/08/2026

Da: CC · A: referee. **Orologio**: 31/08/2026, 14:24 locale (UTC+2), da `date` di sistema.

Marcatura: **[M]** misurato da me ORA · **[R]** riportato, non verificato da me · **[A]** giudizio mio.

---

## APERTURA (R1 + R8)

**[M]** LIBRO letto: **v70** sul disco (era v69 nel blob; diventa v70 con questo giro, come il mandato prevede). Working directory `C:\Users\BULLFROG`. `git worktree list`: repo Desktop @ `5eb18c7` [master] + `qb_fixB` @ `add556f`. Pre-commit: HEAD locale = `origin/master` = `5eb18c7de46dba72483710feb18416c8a9eed0a9`.

**[M] Cancello ID `A299`**: **0 su sei gambe**. Controlli positivi `A298`/`A297`/`A295` tutti >0. Nessuna collisione.

## CANCELLI PRE-COMMIT — tutti passati, impronte misurate ADESSO

Le tre impronte disco sono state ricalcolate con `git hash-object` in questo turno, **non richiamate dal referto A298** (regola 2):

- `BUGS_QBEATS.md` → `f6d586f98d6dbced69ea2a6f342cdaae3dde428b` — coincide
- `LIBRO_MASTRO_QBEATS.md` → `4855017ec4c9d788db33c2c74460d08f20e92262` — coincide
- `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` → `ce3acf455649c573b76f3703dd85c3ef43bcbae1` — coincide

## I TRE COMMIT — sha a 40 caratteri

| # | sha | file | modifica |
|---|---|---|---|
| 1 | `0000dd4f743ca9a1e08d2304b33664f61f91a39a` | `BUGS_QBEATS.md` | 29 inserzioni, 2 cancellazioni |
| 2 | `8d665e1e003990ac5e8af004cc7a6c8fbfa5a6a4` | `LIBRO_MASTRO_QBEATS.md` | 5 inserzioni, 2 cancellazioni |
| 3 | `05283ced21de8456099cf8f6b9cda0caf573da35` | `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 19 inserzioni, 1 cancellazione |

**[M]** Ciascuno tocca **un solo file** (verificato con `git show --name-only`). Autore = committer = `Mauro Martintoni <di_tutto@icloud.com>` su tutti e tre. **Zero trailer**: il corpo di ogni messaggio rende **una sola riga non vuota**, e `Co-Authored-By` rende **0** su tutti e tre. Staging file per file, mai `git add -A` (assert a 1 file prima di ogni commit).

Push: `5eb18c7..05283ce master -> master`. `origin/master` = HEAD locale = `05283ced21de8456099cf8f6b9cda0caf573da35`. Tree pulito sui tracciati.

## VERIFICA A DESTINAZIONE — dal blob di ciascun commit pushato

| file | byte | OID | sha256 |
|---|---|---|---|
| `BUGS_QBEATS.md` | 498740 | `f6d586f98d6dbced69ea2a6f342cdaae3dde428b` | `bad644211e088d6ed76c3dd85f6f9257541487ea7f7d422e146e0191cadb5b84` |
| `LIBRO_MASTRO_QBEATS.md` | 347714 | `4855017ec4c9d788db33c2c74460d08f20e92262` | `dcd4a5f39aaa5eec50476174935cd3bf1231fe0e523367ba353f4b81b75128a1` |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 92157 | `ce3acf455649c573b76f3703dd85c3ef43bcbae1` | `3776ec6e6866be753ff662f612b521f3a4ad9b10f5cc16a1528964194876ccca` |

**Byte e OID coincidono con gli attesi su tutti e tre.**

## CI — e una precisazione che il mandato non prevedeva

⚠️ **Le run NON sono tre: è UNA sola.** `gh run list --commit <sha40>` rende **zero run** per `0000dd4f…` e per `8d665e1e…`, e **una** per `05283ced…`. **Non è un guasto ed è atteso**: `iOS Signed Build` parte **sul push**, non su ogni commit, e i tre commit sono stati spediti in un push solo ⇒ la CI gira sulla **punta**, che contiene il contenuto di tutti e tre.

Run **`33391131461`** — `iOS Signed Build` — su `05283ced21de8456099cf8f6b9cda0caf573da35` (sha pieno a 40, mai corto). Esito: **success**.

⛔ **Non si scrive «CI verde su tutti e tre»**: si scrive che la CI è verde **sulla punta che li comprende**. I due commit intermedi non hanno una propria run e non sono stati costruiti isolatamente.

## PROPAGAZIONE R-δ — contenuto estratto DAL BLOB

| stampa su `E:` | byte | verifica |
|---|---|---|
| `BUGS_QBEATS/BUGS_QBEATS_v78_2026-08-31_0000dd4.md` | 498740 | `cmp` exit 0 contro il blob |
| `LIBRO_MASTRO/LIBRO_MASTRO_QBEATS_v70_2026-08-31_8d665e1.md` | 347714 | `cmp` exit 0 contro il blob |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 92157 | `cmp` exit 0 contro il blob |

Nomi conformi alla convenzione già in uso su `E:` (`BUGS_QBEATS_v77_2026-08-31_597961e.md`, `LIBRO_MASTRO_QBEATS_v69_2026-08-31_597961e.md`). La SCALETTA su `E:` non ha stampe versionate: esiste come **copia viva** in `HANDOFF/`, ed è quella che è stata aggiornata — coerente con `BOX5` §2, che per la SCALETTA dà `HANDOFF/` su entrambe le gambe.

### ⚠️ La premessa del mandato sulle DUE FACCE è SUPERATA — misurato

Il mandato avverte che «LIBRO e BUGS hanno due facce (CRLF su disco, LF nel deposito) e `.gitattributes` non le copre entrambe». **A HEAD non è più così**, misurato ora:

- `git check-attr text` rende **`unset`** su tutti e tre i file ⇒ `-text` **li copre**.
- **CR sul disco = 0** su tutti e tre.
- `git hash-object` sul disco e `git rev-parse HEAD:<file>` **COINCIDONO** su tutti e tre.

⇒ Il rischio che la precauzione voleva evitare **non esiste più a HEAD**: la faccia è una sola. **L'estrazione dal blob è stata comunque eseguita come prescritto** — è la procedura corretta a prescindere, e sarebbe l'unica difesa se `.gitattributes` cambiasse. La precauzione era giusta; la sua motivazione è scaduta. Cambiamento introdotto da `b962c48` (30/08), già registrato.

## PERIMETRO NEGATIVO — rispettato

⛔ Zero BOX3 · zero BOX5 · zero codice · zero `DESIGN/` · nessuna scrittura su Drive · `E:` non riordinato (residuo in `_TRANSITO_DA_VERIFICARE/A275_foglio-CD-30-08/` invariato e non toccato).

---

*MISURE_CC A299 — FINE. Giro documenti A298 chiuso: tre commit pushati, verificati a destinazione, CI verde sulla punta, propagati su `E:` dal blob.*
