# MISURE CC — A158-COMMIT-LIBRO-v58

**ID ricevuto e verificato: `A158`.**
Da: CC · A: referee, + Mauro · 21/08/2026

🔎 **Integrita' del mandato: PASSA.** Visti §0 §1 §2 §3 §4 e la chiusura
`FINE MANDATO A158`. Nessun taglio.

✅ **COMMITTATO E PUSHATO. CI verde, letta due volte per vie indipendenti.**

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ LE TRE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. ✅ IL LIBRO v58 NON VIVE PIU' SOLO SUL MIO DISCO.** Fino a questo mandato la
riga del collaudo device esisteva **solo nel working tree**: il registro cross-team
restava fermo al 19/08 e nessun altro attore poteva leggerla. Adesso e' in
`e4764f9`, su GitHub, con la CI verde. ⚠️ **[A] Vale la pena dire perche' contava:
quella riga esiste per smentire due punteggi falsi che vivevano solo in chat e in
un congedo non tracciato. Finche' non era committata, la smentita era nella stessa
condizione della cosa che doveva smentire.**

**2. ⛔ HO RIPRODOTTO DAL VIVO IL FALSO ZERO DELLO SHA CORTO, invece di ereditarlo.**
**[M]** Sullo stesso identico commit: `gh run list --commit e4764f9` rende **`[]`
con exit 0**; `--commit e4764f9aedea2e9cc0d98c92b48553bd60b3d93f` rende la run.
⇒ **Un comando che fallisce restituendo «nessun risultato» e uscita zero e' il
peggior tipo di falso negativo: non c'e' niente da vedere che segnali l'errore.**
✅ **Sempre lo sha a 40.**

**3. ⚠️ LE DESTINAZIONI SU DRIVE SONO CAMBIATE DUE VOLTE IN TRE MANDATI, IN
DIREZIONI OPPOSTE.** A155 §4 diceva `Qbeats\HANDOFF\` · A157 §4 lo ha corretto in
**radice `Qbeats`** sulla mia misura · A158 §4 lo ha ri-corretto in
**`Qbeats\HANDOFF\`**, con una regola diversa e piu' forte: *su Drive si copia la
struttura del repo*. Ho eseguito quest'ultima.
⛔ **Conseguenza misurata, che non nascondo: i referti del 21/08 ora stanno in DUE
posti su Drive.** A151 · A152 · A153 · A155 in **radice**, A158 in **`HANDOFF\`**.
⇒ **Chi cerca «i referti di oggi» deve guardare in due cartelle.** Il mandato lo
prevede e rimanda il riordino a un lavoro suo, gia' deciso da Mauro. **Lo registro
qui perche' e' esattamente la trappola che A151 aveva segnalato: due posti che
sembrano lo stesso.**

---

## §0 · L'ID

**[M]** Sonda a due forme, due supporti, piu' ispezione del contesto. Perimetro
documentale, binari esclusi, confine di parola.

| ID | NOME repo | NOME E: | CONT repo | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A158** | **0** | **0** | **0** | **0** | ✅ **LIBERO**, contesto vuoto |
| A155 | 2 | 2 | 3 | 2 | controllo positivo |
| A157 | 0 | 0 | 1 | 1 | controllo positivo (rende per **contenuto**) |
| A190 | 0 | 0 | 0 | 0 | controllo **negativo** |

⚠️ **[M] `A157` rende 0 per NOME e 1 per CONTENUTO su entrambi i supporti**: e' la
cecita' strutturale della sonda per nome, misurata di nuovo. **Nome e contenuto
insieme, mai uno solo.**

---

## §1 · R2 — i quattro cancelli, PRIMA di toccare l'indice

**[M]**

| cancello | esito |
|---|---|
| (a) HEAD locale e remoto | `638b73835f7ac52fdcd01dd94dc23f81ce818b2d` = atteso ✅ |
| (b) sha256 del LIBRO | `7df3468b518bf0691f680aa51453fb277d9988ef1b016b0249e3248b4a86d114` = atteso ✅ |
| (c) working tree | LIBRO ` M`, **stage vuoto** ✅ |
| (d) file nuovi dopo il referto A155 | **nessuno** ✅ |

⚠️ **[M] Un refuso del mandato, dichiarato:** §1(d) diceva «il referto A155 delle
**17:40**». Il mtime reale e' **19:40:27**. Due ore di scarto. **La sostanza non
cambia** — nessun file successivo — ma l'ho misurato invece di accettarlo.

---

## §2 · IL COMMIT

**[M]** Staging **file per file**, mai `git add -A`.

⛔ **Contenuto verificato DALL'INDICE, non dal disco** (`git show :LIBRO_MASTRO_QBEATS.md`):

| misura sul blob in stage | reso | atteso |
|---|---:|---|
| `^\*\*Versione:\*\* 58` | 1 | 1 ✅ |
| `^\*\*Versione:\*\* 57` | 0 | 0 ✅ |
| righe | 521 | 521 ✅ |
| `«8/8»` | 3 | 3 ✅ |
| `«8/8**` | 0 | 0 ✅ |
| file in stage | **1** | 1 ✅ |
| numstat | **5 / 3** | 5 aggiunte, 3 rimozioni ✅ |

**Il commit, riletto dal repo:**

```
sha       e4764f9aedea2e9cc0d98c92b48553bd60b3d93f
author    Mauro Martintoni <di_tutto@icloud.com>
committer Mauro Martintoni <di_tutto@icloud.com>
data      21/08/2026 19:50
```

| verifica sul commit | esito |
|---|---|
| trailer | **nessuno** (`%(trailers)` vuoto) ✅ |
| riferimenti a strumenti | **0** — grep `claude\|co-authored\|generated\|anthropic\|assistant` ✅ |
| file toccati | **1**, `LIBRO_MASTRO_QBEATS.md` ✅ |
| em-dash del titolo | `M-bM-^@M-^T` = UTF-8 corretto, verificato con `cat -A` ✅ |

**[M] Metodo:** autore fissato con **`--author=` sulla riga di comando**, mai con
`git config` — verificabile da solo e indipendente dalla configurazione. Messaggio
passato come **file** con `-F`, mai heredoc inline.

---

## §3 · PUSH E COMPILAZIONE

**[M]** `638b738..e4764f9  master -> master`. Locale = remoto = `e4764f9…`.

⛔ **Interrogata per NOME, mai «verde» secco. Due letture per vie indipendenti.**

| lettura | via | esito |
|---|---|---|
| 1 | `gh run list --commit <sha 40>` | `iOS Signed Build` · id `32510297807` · `completed` · **success** |
| 2 | `gh run view 32510297807` | stesso, **e conferma `headSha` = `e4764f9aedea2e9cc0d98c92b48553bd60b3d93f`** |

**Durata:** `2026-08-21T17:51:07Z` → `17:54:19Z`, tre minuti e dodici secondi.

⛔ **`F1 — Build Check (zero errors, zero warnings)`: NON PARTITO.** Non e'
«fallito» e non e' «verde». Interrogato **per ID `266323994`**: le sue run restano
quelle di **31/07** (due, **entrambe fallite**) e **25/04** (una riuscita), tutte
`workflow_dispatch`. **Nessuna sul commit di oggi.**
⚠️ **[A] Il fatto che F1 non parta da quasi quattro mesi, e che le ultime due volte
che qualcuno l'ha lanciato sia fallito, e' una pendenza vera** — non e' materia di
questo mandato, ma non va lasciata implicita dietro un «CI verde».

⛔ **Non ho usato `gh run watch | tail`**: restituirebbe l'exit code di `tail` e puo'
dare un falso verde. Ho usato polling sullo stato e poi due letture esplicite.

**[M] Stato finale:** HEAD locale = remoto = `e4764f9…` · working tree **pulito** ·
il blob a HEAD porta `**Versione:** 58 (21/08/2026)`.

---

## §4 · R-DELTA — le tre gambe

| gamba | destinazione |
|---|---|
| **C:** | `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\` |
| **E:** | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` |
| **Drive** | `I:\Il mio Drive\Qbeats\HANDOFF\` — **regola nuova: si copia la struttura del repo** |

⚠️ **Divergenza dichiarata e non appianata:** vedi riga 3 in testa. I referti di
oggi restano in due posti su Drive fino al riordino, che e' un lavoro a se'.

---

## COSA NON HO FATTO — e lo dico

- ⛔ **`git add -A` mai usato.** Staging del solo `LIBRO_MASTRO_QBEATS.md`.
- ⛔ **Nessun trailer, nessuna firma, nessun riferimento a strumenti** nel messaggio.
- ⛔ **Non ho toccato `git config`.**
- ⛔ **Non ho spostato nulla di gia' depositato su Drive**, ne' in radice ne' in
  `HANDOFF\`. Non ho toccato `Qbeats_IN_CD`, `INDICE.md`, `TD44_REPORT`.
- ⛔ **Nessun altro file toccato**, in nessun supporto, oltre al referto di questo
  mandato.
- ⛔ **Nessuna memoria scritta.**

---

## IN CODA — quello che resta aperto

1. **Il riordino dei referti su Drive** — quattro in radice, uno in `HANDOFF\`.
   Deciso da Mauro, rimandato a un giro suo.
2. **🚨 `F1` non parte da quasi quattro mesi**, e le ultime due esecuzioni sono
   fallite. Oggi nessun commit lo ha attivato.
3. **Il TEST 8 su iPad resta NON ESEGUITO**, inciso come tale. Si chiudera' con una
   **marcatura additiva** sulla riga, non riscrivendola.
4. **🚨 Il regime dei congedi** — nove file non tracciati su un repo pubblico, due
   dei quali del referee. E' il motivo per cui la riga v58 e' dovuta esistere.
5. **Il cancello R2** (§0bis di A155, §1 di A158) e' nato perche' mi sono accorto
   **per caso** di una seconda sessione CC viva oggi. ⚠️ **[A] Finche' resta una
   clausola scritta a mano in ogni mandato, dipende da chi si ricorda di
   metterla.**
6. **Restano valide tutte le pendenze del congedo del 21/08 sera**: BOX3 fermo dal
   22/07, BOX5 dal 28/07, il clone vivo su `F:` con push verso il GitHub vero,
   l'esito di **⟦S5b⟧** mai inciso in nessun canonico.

---

*A158-FINE*
