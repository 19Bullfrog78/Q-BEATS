# MISURE CC — A261 — LA TESTATA CHE MENTE, E IL COMMIT — 29/08/2026

Da: CC · A: referee + Mauro + CD

**ID ESEGUITO: A261.** **⏱ Orologio:** sab 29/08/2026 **22:27 locale (UTC+2)** · 20:27 UTC. **Aggancio:** risponde ad A260.

**Cancello ID — quattro gambe a zero.** Positivo **`A253`, che vede su CIASCUNA**: nome (C: 3 · E: 3) · contenuto (C: 15 · E: 8) · `git log --all --grep` **1** (`9c3616e`).

---

## §0 — LA VERIFICA CHE MI HAI CHIESTO: la riga del registro è INTEGRA

**[M]** Riletta a fonte, riga **543** di `LIBRO_MASTRO_QBEATS.md`: **1647 caratteri · 5 pipe** (= 4 colonne, corretto per il registro Sez.5) · **chiude con ` |`**.

⇒ **Il troncamento era del TRANSITO, non del file.** Coerente col limite che hai dichiarato («letto via Drive, formattazione alterata in transito») ed è la terza volta che il transito altera un documento in questa direzione.

---

## §1 — 🚨 IL DIFETTO CHE HO INTRODOTTO E CORRETTO DENTRO QUESTO GIRO

**Lo scrivo per primo perché è la cosa che conta di più di tutto il mandato.**

Il mandato prevedeva: *«se per stare dentro R-δ.7 devi tagliare la coda più vecchia, fallo e dichiaralo»*. **L'ho fatto: ho tagliato la coda `v61` dalla testata, e ho scritto nella riga stessa che «resta integra nel registro di Sezione 5, sede autoritativa».**

**[M] FALSO. E l'ho scoperto perché ho verificato la mia stessa affermazione invece di darla per buona.**

Sonda di controllo (`grep -c "^| 61 | "`) → **0**. Non fidandomi di un solo zero, **quadratura del registro**:

```
righe registro trovate: 62   ·   range: 1 … 66
MANCANTI: 25 · 26 · 60 · 61
```

⇒ **Il registro di Sezione 5 NON copre v61.** La testata ne era **l'unica sede**, e il taglio l'avrebbe **cancellata dal documento**, non compattata.

**COSA HO FATTO:**
- **Coda `v61` RIPRISTINATA dal blob a `HEAD`** (`git show HEAD:LIBRO_MASTRO_QBEATS.md`) — **dalla fonte, non dalla mia memoria di ciò che avevo tagliato.**
- **Clausola riscritta**: non dice più che v61 è nel registro; dice che **la testa non cresce in RIGHE**, che nessuna coda è stata tagliata, e **dichiara i quattro buchi misurati**.
- **[M] Il taglio non serviva affatto:** `R-δ.7` letta a fonte vincola le **RIGHE** — *«un blocco aggiunto in testa sposta di N righe tutto il file»* — e chiude con *«Il numero di versione in testa resta in testa, e si aggiorna dentro la riga: sostituire una cifra non sposta nulla»*. **La riga 6 resta UNA riga qualunque sia la sua lunghezza. 546 righe prima, 546 dopo.**

⇒ **[A] La lezione, e non è sulla testata:** il mandato mi autorizzava a tagliare, e **l'autorizzazione a fare una cosa non è la misura che quella cosa sia innocua**. La riga che ho scritto per giustificare il taglio conteneva **la sua stessa smentita**, e sarebbe passata: era plausibile, citava una sede reale, e nessuno l'avrebbe riletta. **L'ha smascherata una sonda su ciò che avevo appena affermato io.**

⚠️ **Reperto lasciato aperto, NON riparato:** i buchi **25, 26, 60, 61** nel registro. Non so se siano versioni mai registrate o cancellate; **non l'ho indagato** e non è di questo giro.

---

## §2 — R-δ.7: LETTA A FONTE, NON VIETA L'AGGIORNAMENTO

Il mandato chiedeva di fermarmi se R-δ.7 vietasse anche l'aggiornamento. **Non lo vieta.** Verbatim: *«ciò che si accumula a ogni versione … va IN CODA, mai in testa. La testa di un documento che altri citano non cresce mai»*, con la ragione misurata (**36 citazioni** su otto sedi, cinque delle quali file `.swift`), e la clausola esplicita: *«✅ Il numero di versione in testa resta in testa, e si aggiorna dentro la riga»*.

⇒ **Il vincolo è sulle RIGHE. Rispettato: 546 → 546, delta 0.**

**TESTATA CORRETTA:**

| campo | prima | dopo |
|---|---|---|
| `Versione` | 66 | 66 *(invariato)* |
| `Ultima modifica` | descriveva **v65** | descrive **v66**, con `v65 era:` che scala |
| `Edit author` | si fermava ad `A249` | `A249 + A260 + A261` |
| catena in testa | v65→v61 | **v66→v61** *(nessun taglio)* |

**[M] Coerenza verificata a valle:** `Versione` dichiarata **66** == prima voce della catena **v66** ✅.

---

## §3 — IL TICKET SUL REPERTO DEL GIRO SCORSO

**`TD-mirror-e-copie-nude-stantie`** aperto in `BUGS §1.1`, come chiesto, e **viaggia nello stesso commit** dei documenti che descrive.

Contiene: la tabella delle tre cartelle (BUGS **v68** vs snapshot **v70** · LIBRO **v64** vs **v65** · BOX5 **nessuna copia nuda**) · il danno dichiarato come **di lettura, non di dati** · l'asimmetria fra le tre cartelle come reperto a sé · **tre ipotesi non discriminate** sulla natura delle copie (residui · comodità voluta · propagazione interrotta) — ⛔ **non dedotte**, perché distinguerle richiede la memoria di chi le ha create · **la rimozione dichiarata DECISIONE DI MAURO**, con la nota che se fossero volute la riparazione **non è cancellarle ma aggiornarle a ogni propagazione**, che è lavoro ricorrente.

---

## §4 — COMMIT, CI, WARNING

```
sha completo : b1b4c1fd0864b1713eec7cda5a4d142fac431339
branch       : master · origin/master ALLINEATO (verificato, non presunto)
file (3)     : BUGS_QBEATS.md · LIBRO_MASTRO_QBEATS.md · BOX5_QBEATS.md
messaggio    : docs: le tre decisioni della sera, due ticket, tre regole (A260+A261)
diffstat     : 3 files changed, 88 insertions(+), 5 deletions(-)
```

**CI — per NOME e run id:**

```
workflow  : iOS Signed Build
run id    : 33273703426
headSha   : b1b4c1fd0864b1713eec7cda5a4d142fac431339   (match pieno)
conclusion: success
url       : https://github.com/19Bullfrog78/Q-BEATS/actions/runs/33273703426
durata    : 20:31:22Z → 20:33:32Z (~2m10s)
```

**WARNING: 12 — INVARIATI dal baseline.** Nessun warning nuovo (atteso: giro doc-only, zero file di codice).

**Versioni finali:** LIBRO **66** · BUGS **73** · BOX5 **V38**.

---

## §5 — R-δ COMPLETO: LE TRE GAMBE

**Snapshot dei canonici su `E:` col SHA nel nome — ora il commit esiste:**

```
FILE X CLAUDE.MD\BUGS_QBEATS\BUGS_QBEATS_v73_2026-08-29_b1b4c1f.md          451 926 B · sha 167879a29aff149b…
FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v66_2026-08-29_b1b4c1f.md 316 542 B · sha 9f71088a0a4aab8f…
FILE X CLAUDE.MD\BOX5_Test\BOX5_V38_2026-08-29_b1b4c1f.md                   120 430 B · sha 0595708d7e9daa25…
```

**[M] `cmp` contro il repo: IDENTICI tutti e tre.**

⚠️ **Le copie NUDE non le ho aggiornate**, ed è una scelta dichiarata: sono l'oggetto del ticket appena aperto, e **toccarle prima che Mauro decida** significherebbe risolvere di mia iniziativa una domanda che il ticket pone.

**Drive:** verificato dopo la propagazione — pesi nel messaggio di consegna.

---

## §6 — ⛔ COSA NON HO MISURATO

- ⛔ **Zero device.** Il commit è doc-only, ma **`TD-show-non-abbandonabile` resta 🚨 aperto** e il lavoro di A253 **non è ancora stato collaudato**.
- ⛔ **Non ho indagato i buchi 25, 26, 60, 61** del registro: misurati, dichiarati, non spiegati.
- ⛔ **Non ho riletto le tre righe di Sez.2 scritte in A260** contro il resto della sezione (~190 righe): il limite dichiarato in A260 §4 **resta identico**.
- ⛔ **La ratifica del referee su A260 è di CONTENUTO, non di byte** — dichiarato da lui stesso (transito Drive). ⇒ **Il diff committato non è stato ratificato byte per byte da nessuno**; la sola verifica byte è la mia.
- ⚠️ **Faccia dei file:** `numstat` rende **7/50/31** righe, cioè solo le modifiche vere — nessun cambio di faccia di massa. Git avverte che riporterà LIBRO e BUGS a CRLF su disco al prossimo checkout (`.gitattributes` li lascia fuori da `-text`): **nessun effetto sul blob.**

*A261-LA-TESTATA-CHE-MENTE-FINE*
