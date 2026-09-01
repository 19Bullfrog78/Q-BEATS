# MISURE CC — A302 — DEPOSITO ARRETRATO E REGIME — 2026-09-01

Da: CC · A: referee. Mandato: **A302-DEPOSITO-ARRETRATO-E-REGIME**, dichiarato in testa e coincidente con quello ricevuto.

**Orologio**: 2026-09-01, **09:41:55 locale (UTC+2)** — da `date` di sistema, letta prima di scrivere qualunque data.

✅ **OK di Mauro dichiarato nel mandato, non riletto da me** — marco questa premessa `[R]`, coerente con la disciplina di questo progetto: non ho un canale diretto su quella chat.

Marcatura: **[M]** misurato ora da me, alla fonte · **[R]** riportato, non verificato da me · **[A]** giudizio mio.

---

## 0 · Orologio e cancello sull'ID

**[M]** Cancello a sei gambe su `A302`: nomi C:=0 · nomi E:=0 · git grep tracciato=0 · disco E: contenuto=0 · git log=0 · **disco C: contenuto=1**.

⚠️ **Quel 5° valore non è un'occupazione: è un falso-UNO (R-δ.10), aperto non solo contato.** L'unica occorrenza sta in `HANDOFF/MISURE_CC_2026-09-01_A301-CENSIMENTO-CONGEDI-E-REFERTI.md:242`, riga scritta da me stesso pochi minuti prima: *«Prossimo libero dopo la consegna di questo referto: A302.»* — è una **previsione**, non un uso dell'ID.

**Controllo positivo, stessa sonda**: `A290` (tracciato) → git grep=3, git log=1 · `A301` (su disco, non tracciato — il mio stesso censimento) → nomi C:=1, nomi E:=1, git grep=0. La sonda vede e distingue correttamente. ⇒ **A302 libero, confermato.**

**[M] Identità git locale**: già `Mauro Martintoni <di_tutto@icloud.com>` — nessuna impostazione necessaria. **Tree pulito** prima di iniziare (0 righe tracciate non-`??`), HEAD `05283ce`, branch `master`.

---

## 1 · Lista esplicita

**[M] Costruita dal censimento A301** (non da una rilettura fresca di `HANDOFF/`, per istruzione del mandato): filtrati i 479 file non tracciati per `presenza != 'solo E:'` → **356 candidati**, 7.309.702 byte, verificati fisicamente presenti ora (0 mancanti) e fresh-cross-checked contro `git ls-files` (0 già tracciati).

🚨 **Riduzione da 356 a 345, trovata PRIMA di mettere in scena**: `git check-ignore` su tutti e 356 rende **11 colpiti** da `.gitignore:93:/_cc_processo/` — gli 11 `DIFF_*` già identificati nel setaccio A301 come untracked ***by design*** (decisione dichiarata di Mauro, 10/07 — non deriva). Esclusi, non forzati: portarli dentro avrebbe scavalcato una decisione già presa, cosa che questo mandato non chiede.

**Lista finale: 345 file, 7.196.011 byte.** Depositata come `HANDOFF/LISTA_ARRETRATO_A302_2026-09-01.md`, su due gambe (`cmp` exit 0 — vedi §6).

I **123 file esistenti solo su E:** (479 − 356) **non entrano in questo giro**, per istruzione esplicita del mandato: operazione a parte.

---

## 2 · Commit ① — arretrato

**[M] Messa in scena**: 345 chiamate `git add --` individuali, un percorso alla volta dalla lista finale, **zero `-A`, zero jolly**.

**Verifica nei due sensi** (dopo la messa in scena, prima del commit):

| confronto | esito |
|---|---|
| in staged ma NON in lista | **0** |
| in lista ma NON in staged | **0** |
| coincidenti | **345 / 345** |

✅ **Coincidono esattamente.** Controlli aggiuntivi: 0 file sotto `ios_app/` (nessun codice), tutti i 345 sono addizioni pure (`git diff --cached --name-status` → 345× `A`, zero `M`).

**Commit eseguito**:
```
8a3ca7902a854ad2c927f002771d76ccd90f0baa
docs(handoff): deposito arretrato congedi/referti/diff (A302)
autore: Mauro Martintoni <di_tutto@icloud.com>
345 files changed, 77690 insertions(+)
```
**[M]** Zero trailer `Co-Authored-By` (verificato con grep sul corpo del commit, nessun match).

---

## 3 · Commit ② — la regola nel LIBRO

**[M] Riga inserita in coda alla Sezione 2**, immediatamente dopo l'ultima riga di registro (2026-08-31, ex-riga 398) e prima del separatore/intestazione della Sezione 3 — verificato via `git diff` che nessun'altra porzione del file sia stata toccata a parte questo inserimento e le righe 5-6 (§3bis).

**Verifica byte-per-byte, come richiesto dal mandato**: estratta la riga applicata (`grep` sul file, marcatore univoco), confrontata contro il testo dettato salvato in un file di riferimento **prima** dell'edit. `cmp` fra i due, newline finale normalizzata su entrambi i lati (l'unica differenza grezza era quell'unico byte, artefatto della mia scrittura del riferimento — non della riga applicata): **contenuto identico, 1304 byte su 1304**. ✅ Nessun FERMATI necessario.

⚠️ **Nota strutturale, non bloccante**: la riga dettata ha **2 colonne** (Data, Contenuto — 3 pipe), mentre tutte le righe sorelle della Sezione 2 ne hanno **6** (Data, Contenuto, Chi, Fonte, Stato, Fine — 7 pipe). Il mandato imponeva l'inserimento **verbatim, senza riscriverne una parola**: non ho aggiunto le 4 colonne mancanti, perché farlo avrebbe reso la riga applicata diversa da quella dettata — esattamente ciò che il cancello del mandato vieta. La riga renderà con le ultime 4 celle vuote (markdown GFM lo accetta senza errori). Segnalato per decisione del referee, non corretto di mia iniziativa.

### 3bis · Bump di versione (righe 5-6, "come da regime")

**[M]** `**Versione:** 70 (2026-08-31)` → **`71 (2026-09-01)`**.

Riga 6 ("Ultima modifica") aggiornata seguendo il pattern osservato su tutte le transizioni precedenti (v67→v68→v69→v70): la nuova descrizione **avvolge** la vecchia, etichettata `— v70 era: {contenuto integrale della vecchia riga 6, spogliato del proprio wrapper "(v70 — ... )"}`. **[M] Verificato programmaticamente che il corpo della vecchia riga 6 (5.348 caratteri) sia presente per intero, senza tagli, dentro la nuova.** ⚠️ **R-δ.7 rispettata**: la testa resta UNA riga (verificato: `wc -l` invariato a parte le due righe sostituite in-place + la riga nuova in Sez.2 — nessuna crescita di conteggio-righe dalla history-chain).

Descrizione v71 scritta da me (non dettata verbatim, il mandato lasciava libertà qui): *"Sez.2 +1 riga, doc-only, zero codice: il REGIME DI DEPOSITO DEI DOCUMENTI DI LAVORO — congedi, referti e diff entrano nel commit del giro che li produce, non più per deriva; misurato in A301 (552 file, 73 tracciati, `.gitignore` senza regola su `HANDOFF/`) e ratificato da Mauro il 01/09. Arretrato di 345 file su C: committato nello stesso giro (mandato A302); i file solo su E: restano fuori, operazione a parte."*

⛔ **Non ho toccato la Sezione 6** (Storico versioni file): la sua ultima riga tracciata è **#68** mentre l'header era già a v70 prima di questo mandato — un buco pre-esistente e noto (stesso genere del buco v25/v26 già a verbale), non uno che ho aperto io. Il mandato chiedeva solo "bump di versione... e dichiara la versione nuova": non ho aggiunto una riga #69/#70/#71 a quella tabella, per non inventare un'attribuzione "Chi" e un changelog che nessuno mi ha dettato.

**Messa in scena**: **solo** `LIBRO_MASTRO_QBEATS.md` (verificato: `git diff --cached --name-only` rendeva un solo file prima del commit).

**Commit eseguito**:
```
41a1ae3d7d4714c1a7284f852d50b7a4a6a8fb62
docs(libro): regime di deposito dei documenti di lavoro (A302)
autore: Mauro Martintoni <di_tutto@icloud.com>
1 file changed, 3 insertions(+), 2 deletions(-)
```
**[M]** Zero trailer `Co-Authored-By`. Tree pulito dopo i due commit (0 righe tracciate non-`??`).

---

## 4 · Push e CI

**[M] Un push solo**: `05283ce..41a1ae3 master -> master`, comprende entrambi i commit di questo giro.

**[M] CI sulla punta che li comprende entrambi** (non "verde su due commit" separatamente): run `33484052137`, titolo "docs(libro): regime di deposito dei documenti di lavoro (A302)" — cioè il commit di testa, che include per definizione anche ① sotto di sé. **Esito: SUCCESS, 2m52s.** Annotazioni presenti sono standard e preesistenti (deprecazione Node.js 20 nelle action, trust dei tap Homebrew) — non toccano questo giro, nessuna riguarda i file modificati.

---

## 5 · Consegna

Questo referto e la lista del §1 (`LISTA_ARRETRATO_A302_2026-09-01.md`) sono depositati su due gambe. Esito `cmp` e sha256 alla fine del documento, misurati **dopo** il deposito.

⚠️ **Come previsto dal mandato**: questo referto e la lista **non sono nel commit ① di oggi** (non esistevano ancora quando quel commit è stato costruito) e restano **untracked** — entreranno nel deposito nel giro successivo, sotto il regime appena inciso. Non è un'eccezione al regime nuovo: è la conseguenza dell'ordine stesso delle operazioni che il mandato ha prescritto.

---

## 6 · Fermarsi e dichiarare — verifica retrospettiva delle quattro condizioni

- **L'ID collide?** No — §0.
- **Staged e lista non coincidono?** Coincidevano esattamente (345/345, 0/0 nei due sensi) — §2. La riduzione 356→345 è avvenuta **prima** della messa in scena, non è una discrepanza fra staged e lista: la lista finale depositata è già quella a 345.
- **La riga applicata al LIBRO non è identica a quella dettata?** È identica, verificato byte-per-byte — §3. (La nota sulle colonne mancanti è una proprietà della riga dettata stessa, non una mia divergenza.)
- **La CI non è verde?** È verde — §4.
- **Una premessa del mandato è falsa alla misura?** Nessuna trovata falsa. L'unica cosa emersa e non anticipata dal mandato è l'esclusione dei file `_cc_processo/` — non contraddice una premessa, la precisa.

Nessuna condizione di arresto. Consegna completa, non parziale.

---

*A302-DEPOSITO-ARRETRATO-E-REGIME — fine corpo.*
