// === A432 (09/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3c-1: renamePendingBeat (P26; referto A424, par. 2.2 a) ===
// Gli scenari A-G del modello di A424: la funzione rinomina il battito in attesa e nient'altro. Due corse in passo
// con gli stessi ingressi, una con la rinomina e una senza («oggi»), devono dare gli stessi click agli stessi
// campioni (battiti e suddivisioni); le etichette sono giuste solo con la rinomina. L'oracolo dell'etichetta e'
// la band (il battito intero piu' vicino al campione del click, dall'origine comune), come in test_pending_beat;
// la rinomina usa l'identita' che il getter del DSP dice nella chiamata del buco. Il modello del Follower in sync
// e' quello di A424 par. 2.2 a e di VR-3c (lettura con scarto alternato di ±0,006, soglia 0,01, un buco di G
// battiti alla chiamata gapBuffer). Le varianti «vecchio (A423)», resetForStart + setBeatPosition, sono
// riportate dove il modello le confrontava (B, D, F): sono comportamenti del DSP di oggi, non del disegno.
// I banchi di core_engine segnalano gli errori solo con assert(): con NDEBUG definito questo file non si compila.
#ifdef NDEBUG
#error "test_rename_pending_beat: NDEBUG definito, gli assert() sarebbero spenti - compilare in Debug (-DCMAKE_BUILD_TYPE=Debug)"
#endif

#include "MetronomeDSP.h"

#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <memory>
#include <vector>

// Solo per una compilazione locale su Windows con la CRT di debug di MSVC: un assert() fallito andrebbe in una
// finestra modale e il banco resterebbe appeso; qui va su stderr e il processo esce, come su macOS. Nessun effetto
// sul runner della CI.
#if defined(_MSC_VER) && defined(_DEBUG)
#include <crtdbg.h>
#include <cstdlib>
static void assertSuStderr() {
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
    _CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ERROR, _CRTDBG_FILE_STDERR);
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
}
#else
static void assertSuStderr() {}
#endif

namespace {

const double   kRate = 48000.0;
const uint32_t kBuf  = 512;

struct Pending { double beat; int64_t ahead; };
Pending  readPending(const MetronomeDSP& d) { return { d.getPendingBeat(), d.getPendingSamplesAhead() }; }
long long ll(double x) { return std::llround(x); }
double    spbOf(double bpm) { return kRate * 60.0 / bpm; }
uint64_t  cursorOf(double beat, double spb) { return (uint64_t)std::round(beat * spb); }

int advanceUntil(MetronomeDSP& dsp, uint64_t& cursor, double spb, double targetBeat, uint32_t buf = kBuf) {
    int n = 0;
    while ((double)cursor / spb < targetBeat) {
        for (const auto& e : dsp.processBuffer(buf)) if (e.isBeat) ++n;
        cursor += buf;
    }
    return n;
}

struct Click { uint64_t sample; uint32_t offset; uint32_t label; bool accent; Pending before; };
Click nextClick(MetronomeDSP& dsp, uint64_t& cursor, uint32_t buf = kBuf, int maxBuffers = 100000) {
    for (int b = 0; b < maxBuffers; ++b) {
        const Pending g = readPending(dsp);
        const uint32_t label = dsp.getCurrentBeatInBar();
        const auto evs = dsp.processBuffer(buf);
        for (const auto& e : evs) {
            if (!e.isBeat) continue;
            Click c = { cursor + e.offset, e.offset, label, e.accent, g };
            cursor += buf;
            return c;
        }
        cursor += buf;
    }
    assert(false && "nessun battito");
    return Click();
}

// ─────────────────────────── il Follower in sync: due corse in passo ───────────────────────────

struct Ev { uint64_t sample; bool isBeat; };

struct RunOut {
    std::vector<Ev> ev;
    int beats = 0, labelWrong = 0, doubles = 0, asapGap = 0;
    // Scarto massimo dei battiti dalla griglia (origine + k) * spb, misurato sui battiti usciti dopo il primo
    // campione del buffer: un battito al campione 0 puo' essere un fire-asap di FIX-B (la correzione della chiamata
    // lo ha scavalcato di pochi campioni, lo scarto della lettura), che esce fuori griglia del ritardo dello scavalco.
    double maxGridDevSamples = 0.0;
    int asapBeats = 0;                // battiti usciti al campione 0 fuori griglia (gli scavalcati)
};

struct RunCfg {
    double   bpm = 121.0;
    uint32_t bpb = 4;
    double   gap = 1.61;
    int      gapBuffer = 200;
    int      total = 400;
    double   origin = 0.0;
    uint32_t buf = kBuf;
    bool     swing = false;      // crome con swing 0,6
    bool     exactGap = false;   // nella chiamata del buco nessuno scarto di lettura (il battito in attesa al campione 0)
};

RunOut run(const RunCfg& c, bool rename) {
    auto dspBox = std::make_unique<MetronomeDSP>(kRate, c.bpm);   // sullo heap, come metronome_create
    MetronomeDSP& dsp = *dspBox;
    dsp.setBeatsPerBar(c.bpb);
    if (c.swing) dsp.setSubdivision(2, 0.6);
    dsp.resetForStart(c.origin);
    const double spb = spbOf(c.bpm);
    assert(spb > (double)c.buf);
    uint64_t cursor = cursorOf(c.origin, spb);
    RunOut r;
    int sign = +1;
    long long last = -1;
    for (int n = 0; n < c.total; ++n) {
        const double band    = c.origin + (double)n * c.buf / spb + (n >= c.gapBuffer ? c.gap : 0.0);
        const double noise   = (c.exactGap && n == c.gapBuffer) ? 0.0 : sign * 0.006;
        const double reading = band + noise;
        sign = -sign;
        const double before = (double)cursor / spb;
        if (std::fabs(reading - before) > 0.01) {
            dsp.setBeatPositionTimeOnly(reading);
            cursor = cursorOf(reading, spb);
        }
        if (rename && n == c.gapBuffer) {
            const Pending g = readPending(dsp);
            if (g.ahead == 0) ++r.asapGap;
            dsp.renamePendingBeat((uint32_t)(ll(g.beat - c.origin) % (long long)c.bpb));
        }
        const uint32_t label = dsp.getCurrentBeatInBar();
        const auto evs = dsp.processBuffer(c.buf);
        for (const auto& e : evs) {
            const uint64_t s = cursor + e.offset;
            r.ev.push_back({ s, e.isBeat });
            if (!e.isBeat) continue;
            ++r.beats;
            const long long k = ll((double)s / spb - c.origin);   // il nome vero: la band, dall'origine comune
            if (k == last) ++r.doubles;
            last = k;
            if ((uint32_t)(k % (long long)c.bpb) != label) ++r.labelWrong;
            const double dev = std::fabs((double)s - (c.origin + (double)k) * spb);
            if (e.offset == 0 && dev > 0.5) ++r.asapBeats;
            else if (dev > r.maxGridDevSamples) r.maxGridDevSamples = dev;
        }
        cursor += c.buf;
    }
    return r;
}

bool sameEvents(const RunOut& a, const RunOut& b) {
    if (a.ev.size() != b.ev.size()) return false;
    for (size_t i = 0; i < a.ev.size(); ++i)
        if (a.ev[i].sample != b.ev[i].sample || a.ev[i].isBeat != b.ev[i].isBeat) return false;
    return true;
}

// ─────────────────────────── A: i buchi del 29/10 e del 01/11 ───────────────────────────

void test_scenario_A_gli_stessi_click_le_etichette_giuste() {
    struct S { const char* nome; double bpm; uint32_t bpb; double gap; };
    const S scen[] = {
        { "121 4/4 1,61",   121.0, 4, 1.61 },
        { "91 4/4 1,19",     91.0, 4, 1.19 },
        { "141 4/4 1,86",   141.0, 4, 1.86 },
        { "101 6/8 1,30",   101.0, 6, 1.30 },
        { "180,5 9/8 1,61", 180.5, 9, 1.61 },
        { "121 4/4 1,00",   121.0, 4, 1.00 },
        { "121 4/4 2,00",   121.0, 4, 2.00 },
        { "121 4/4 1,20",   121.0, 4, 1.20 },
    };
    const int fasi = 61;
    for (const S& s : scen) {
        int corseDiverse = 0, doppi = 0, sbagliateOggi = 0, sbagliateNuovo = 0, asap = 0, battiti = 0;
        for (int f = 0; f < fasi; ++f) {
            RunCfg c; c.bpm = s.bpm; c.bpb = s.bpb; c.gap = s.gap; c.gapBuffer = 200 + f;
            const RunOut nuovo = run(c, true);
            const RunOut oggi  = run(c, false);
            if (!sameEvents(nuovo, oggi)) ++corseDiverse;
            doppi += nuovo.doubles + oggi.doubles;
            sbagliateOggi  += oggi.labelWrong;
            sbagliateNuovo += nuovo.labelWrong;
            asap += nuovo.asapGap;
            battiti += nuovo.beats;
        }
        std::printf("  %-16s fasi:%d battiti:%d corseConClickDiversi:%d corseConDoppi:%d etichetteSbagliate oggi:%d"
                    " nuovo:%d battitiASubito:%d\n", s.nome, fasi, battiti, corseDiverse, doppi, sbagliateOggi,
                    sbagliateNuovo, asap);
        assert(corseDiverse == 0);    // gli stessi click alle stesse ore, con e senza la funzione
        assert(doppi == 0);           // nessun click raddoppiato
        assert(sbagliateNuovo == 0);  // con la rinomina nella chiamata del buco nessuna etichetta sbagliata
        assert(sbagliateOggi > 0);    // oggi, dopo il buco, le etichette restano indietro
    }
    std::printf("PASS test_scenario_A_gli_stessi_click_le_etichette_giuste\n");
}

// ─────────────────────────── B: una correzione indietro subito dopo un click ───────────────────────────

void test_scenario_B_correzione_indietro_nessun_doppio() {
    // A 120 il battito 1 esce al campione 24000; subito dopo una correzione indietro di 0,3 battiti: col
    // battito in attesa tenuto (FIX-B) e la rinomina il prossimo click e' il 2, a 48000, nessun doppio del 1.
    auto dspBox = std::make_unique<MetronomeDSP>(kRate, 120.0);   // sullo heap, come metronome_create
    MetronomeDSP& dsp = *dspBox;
    dsp.resetForStart(0.0);
    const double spb = spbOf(120.0);
    uint64_t cursor = 0;
    Click c = nextClick(dsp, cursor);
    assert(c.sample == 0);
    c = nextClick(dsp, cursor);
    assert(c.sample == 24000);
    const double pos = (double)cursor / spb - 0.3;
    dsp.setBeatPositionTimeOnly(pos);
    cursor = cursorOf(pos, spb);
    const Pending g = readPending(dsp);
    assert(ll(g.beat) == 2 && (int64_t)cursor + g.ahead == 48000);
    dsp.renamePendingBeat((uint32_t)(ll(g.beat) % 4));
    c = nextClick(dsp, cursor);
    assert(c.sample == 48000 && c.label == 2 && !c.accent);
    // il vecchio modo (A423): resetForStart(0) + setBeatPosition sulla stessa posizione rifa' il battito 1 a 24000,
    // un doppio (comportamento di setBeatPosition oggi: il «ceil» rideriva il battito in attesa)
    auto oldBox = std::make_unique<MetronomeDSP>(kRate, 120.0);   // sullo heap, come metronome_create
    MetronomeDSP& old = *oldBox;
    old.resetForStart(0.0);
    uint64_t cur2 = 0;
    nextClick(old, cur2); nextClick(old, cur2);
    old.resetForStart(0.0);
    old.setBeatPosition(pos);
    cur2 = cursorOf(pos, spb);
    const Click d = nextClick(old, cur2);
    assert(d.sample == 24000);   // il doppio
    std::printf("PASS test_scenario_B_correzione_indietro_nessun_doppio\n");
}

// ─────────────────────────── C: buchi di 1, 2, 3 battiti interi, il battito in attesa al campione 0 ───────────────────────────

void test_scenario_C_buchi_interi_al_primo_campione() {
    // A 120 con buffer da 500 il cursore cade sui confini di battito (24000 = 48 x 500): alla chiamata del buco
    // (buffer 144, battito 3) la band salta di G battiti interi e il battito in attesa e' al campione 0.
    for (double G = 1.0; G <= 3.0; G += 1.0) {
        for (int gapBuffer : { 144, 150 }) {
            RunCfg c; c.bpm = 120.0; c.bpb = 4; c.gap = G; c.gapBuffer = gapBuffer; c.total = 400; c.buf = 500;
            c.exactGap = true;
            const RunOut nuovo = run(c, true);
            const RunOut oggi  = run(c, false);
            assert(sameEvents(nuovo, oggi));
            assert(nuovo.doubles == 0 && oggi.doubles == 0);
            assert(nuovo.labelWrong == 0);
            assert(oggi.labelWrong > 0);
            // lo stesso numero di click e gli stessi vuoti: i nomi dei battiti usciti saltano di G al buco
            std::vector<long long> ids;
            for (const Ev& e : nuovo.ev) if (e.isBeat) ids.push_back(ll((double)e.sample / 24000.0));
            int holes = 0;
            for (size_t i = 1; i < ids.size(); ++i) {
                assert(ids[i] > ids[i - 1]);
                if (ids[i] - ids[i - 1] > 1) { ++holes; assert(ids[i] - ids[i - 1] == (long long)G + 1); }
            }
            assert(holes == 1);
            if (gapBuffer == 144) assert(nuovo.asapGap == 1);   // il battito in attesa al primo campione del buffer
        }
    }
    std::printf("PASS test_scenario_C_buchi_interi_al_primo_campione\n");
}

// ─────────────────────────── D: l'origine con un residuo ───────────────────────────

void test_scenario_D_origine_intatta() {
    // Origine 0,004 battiti a 121: i click restano sulla griglia (origine + k) * spb a mezzo campione, la rinomina
    // non tocca l'origine; il vecchio modo (resetForStart(0) + setBeatPosition) sposta la griglia di 0,004 battiti
    // (1,98 ms a 121).
    RunCfg c; c.bpm = 121.0; c.bpb = 4; c.gap = 1.61; c.gapBuffer = 230; c.total = 400; c.origin = 0.004;
    const RunOut nuovo = run(c, true);
    const RunOut oggi  = run(c, false);
    std::printf("  D: battiti:%d scartoMassimoDallaGriglia_campioni:%.3f scavalcati:%d\n", nuovo.beats,
                nuovo.maxGridDevSamples, nuovo.asapBeats);
    assert(sameEvents(nuovo, oggi));
    assert(nuovo.labelWrong == 0 && oggi.labelWrong > 0);
    assert(nuovo.maxGridDevSamples <= 0.5);   // mezzo campione (0,010 ms): la griglia e' quella dell'origine 0,004
    assert(nuovo.asapBeats == oggi.asapBeats);
    assert(nuovo.beats > 5);
    {
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        dsp.resetForStart(0.004);
        dsp.renamePendingBeat(2);
        assert(dsp.getStartAbsoluteBeat() == 0.004);
        assert(dsp.getCurrentBeatInBar() == 2);
    }
    {   // il vecchio modo: la griglia va sull'origine 0
        const double spb = spbOf(121.0);
        auto oldBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& old = *oldBox;
        old.resetForStart(0.004);
        uint64_t cursor = cursorOf(0.004, spb);
        advanceUntil(old, cursor, spb, 2.5);
        const double pos = (double)cursor / spb;
        old.resetForStart(0.0);
        old.setBeatPosition(pos);
        const Click k = nextClick(old, cursor);
        const long long id = ll((double)k.sample / spb);
        const double dev = std::fabs((double)k.sample - (0.004 + (double)id) * spb);
        assert(dev > 0.5);                                     // fuori dalla griglia dell'origine vera
        assert(std::fabs(dev - 0.004 * spb) <= 1.0);           // di 0,004 battiti (circa 95 campioni, 1,98 ms)
    }
    std::printf("PASS test_scenario_D_origine_intatta\n");
}

// ─────────────────────────── E: crome con lo swing ───────────────────────────

void test_scenario_E_suddivisioni_identiche() {
    // Crome con swing 0,6 e il buco di 1,61 a 121: battiti e suddivisioni agli stessi campioni con e senza la rinomina.
    for (int f = 0; f < 61; f += 5) {
        RunCfg c; c.bpm = 121.0; c.bpb = 4; c.gap = 1.61; c.gapBuffer = 200 + f; c.total = 400; c.swing = true;
        const RunOut nuovo = run(c, true);
        const RunOut oggi  = run(c, false);
        assert(sameEvents(nuovo, oggi));
        size_t subdiv = 0;
        for (const Ev& e : nuovo.ev) if (!e.isBeat) ++subdiv;
        assert(subdiv > 0);
        assert(nuovo.labelWrong == 0 && oggi.labelWrong > 0);
    }
    std::printf("PASS test_scenario_E_suddivisioni_identiche\n");
}

// ─────────────────────────── F: il battito messo a «subito» ───────────────────────────

void test_scenario_F_il_battito_a_subito_esce_una_volta_col_nome_nuovo() {
    const double spb = spbOf(121.0);
    {   // F1: un buco di 1,2 con la posizione 0,02 prima del battito 4: il battito scavalcato (il 5) esce al primo
        // campione, 0,18 battiti in ritardo (89 ms a 121); con la rinomina lo stesso campione, etichetta giusta
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        dsp.resetForStart(0.0);
        uint64_t cursor = 0;
        assert(advanceUntil(dsp, cursor, spb, 3.5) == 4);          // in attesa il 4
        dsp.setBeatPositionTimeOnly(3.98); cursor = cursorOf(3.98, spb);
        Pending g = readPending(dsp);
        assert(ll(g.beat) == 4);
        dsp.setBeatPositionTimeOnly(5.18); cursor = cursorOf(5.18, spb);   // il buco: round(5,18 + 0,02) = 5, nel passato
        g = readPending(dsp);
        assert(g.ahead == 0 && ll(g.beat) == 5);
        dsp.renamePendingBeat((uint32_t)(ll(g.beat) % 4));           // 1
        assert(dsp.getCurrentBeatInBar() == 1);
        g = readPending(dsp);
        assert(g.ahead == 0 && ll(g.beat) == 5);                     // la rinomina non tocca il battito in attesa
        const auto evs = dsp.processBuffer(kBuf);
        assert(!evs.empty() && evs[0].isBeat && evs[0].offset == 0 && !evs[0].accent);
        int beatsInBuffer = 0;
        for (const auto& e : evs) if (e.isBeat) ++beatsInBuffer;
        assert(beatsInBuffer == 1);                                   // una volta sola
        const double late = ((double)cursor - 5.0 * spb) / spb;
        assert(late > 0.17 && late < 0.19);
        cursor += kBuf;
        const Click c6 = nextClick(dsp, cursor);                      // il 6 col nome dopo
        assert(c6.label == 2 && ll(c6.before.beat) == 6);
    }
    {   // F2: una correzione in avanti di 0,03 senza buco, con la posizione 0,0246 prima del 4: il 4 esce al primo
        // campione 0,0054 battiti (2,7 ms) in ritardo, e si sente; con la rinomina lo stesso
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        dsp.resetForStart(0.0);
        uint64_t cursor = 0;
        assert(advanceUntil(dsp, cursor, spb, 3.5) == 4);
        dsp.setBeatPositionTimeOnly(4.0 - 0.0246); cursor = cursorOf(4.0 - 0.0246, spb);
        dsp.setBeatPositionTimeOnly(4.0 + 0.0054); cursor = cursorOf(4.0 + 0.0054, spb);
        Pending g = readPending(dsp);
        assert(g.ahead == 0 && ll(g.beat) == 4);
        dsp.renamePendingBeat(0);
        const auto evs = dsp.processBuffer(kBuf);
        assert(!evs.empty() && evs[0].isBeat && evs[0].offset == 0 && evs[0].accent);
        const double lateMs = ((double)cursor - 4.0 * spb) / kRate * 1000.0;
        assert(lateMs > 2.0 && lateMs < 3.5);
        // il vecchio modo (A423) sulla stessa posizione: il battito 4 non esce (il «ceil» va al 5): un click perso
        auto oldBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& old = *oldBox;
        old.resetForStart(0.0);
        uint64_t cur2 = 0;
        advanceUntil(old, cur2, spb, 3.5);
        old.setBeatPositionTimeOnly(4.0 - 0.0246); cur2 = cursorOf(4.0 - 0.0246, spb);
        old.resetForStart(0.0);
        old.setBeatPosition(4.0 + 0.0054); cur2 = cursorOf(4.0 + 0.0054, spb);
        const Click k = nextClick(old, cur2);
        assert(k.sample == (uint64_t)ll(5.0 * spb));
    }
    std::printf("PASS test_scenario_F_il_battito_a_subito_esce_una_volta_col_nome_nuovo\n");
}

// ─────────────────────────── G: un cambio armato e il riallineo ───────────────────────────

void test_scenario_G_cambio_armato_e_riallineo() {
    const double spb9 = spbOf(180.5), spb4 = spbOf(121.0);
    {   // senza applicare la sezione: un 4/4 a 121 armato sul 9/8 a 180,5 e una rinomina a 2: i battiti restano in 9
        // finche' l'etichetta non torna a 0, dove lo scambio scatta
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 180.5);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        dsp.setBeatsPerBar(9);
        dsp.resetForStart(0.0);
        uint64_t cursor = 0;
        assert(advanceUntil(dsp, cursor, spb9, 2.5) == 3);      // in attesa il 3 (etichetta 3)
        dsp.scheduleBeatsPerBarChange(4);
        dsp.scheduleBPMChange(121.0);
        dsp.renamePendingBeat(2);
        const uint32_t labels[] = { 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3 };
        double exact = 3.0 * spb9;
        for (int i = 0; i < 11; ++i) {
            const Click c = nextClick(dsp, cursor);
            assert(c.label == labels[i]);
            assert(c.accent == (labels[i] == 0));
            assert(ll(c.before.beat) == 3 + i);
            assert(c.before.ahead == (int64_t)c.offset);
            assert(std::llabs((long long)c.sample - ll(exact)) <= 1);
            exact += (i >= 7) ? spb4 : spb9;                      // dal battito con etichetta 0 la durata nuova
        }
    }
    {   // con l'annullo dei cambi armati e i setter immediati (l'ordine di A424 par. 2.2 a), poi la rinomina a 2:
        // 2, 3, 0 accentato, 1 in 4/4 a 121
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 180.5);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        dsp.setBeatsPerBar(9);
        dsp.resetForStart(0.0);
        uint64_t cursor = 0;
        assert(advanceUntil(dsp, cursor, spb9, 2.5) == 3);
        dsp.scheduleBeatsPerBarChange(4);
        dsp.scheduleBPMChange(121.0);
        dsp.cancelPendingBPB();
        dsp.cancelPendingBPM();
        dsp.setBPM(121.0);
        dsp.setBeatsPerBar(4);
        dsp.renamePendingBeat(2);
        const Pending g = readPending(dsp);
        assert(ll(g.beat) == 3);
        double exact = (double)cursor + (3.0 * spb9 - (double)cursor) * (180.5 / 121.0);   // setBPM riscala la distanza
        const uint32_t labels[] = { 2, 3, 0, 1 };
        for (int i = 0; i < 4; ++i) {
            const Click c = nextClick(dsp, cursor);
            assert(c.label == labels[i]);
            assert(c.accent == (labels[i] == 0));
            assert(ll(c.before.beat) == 3 + i);
            assert(c.before.ahead == (int64_t)c.offset);
            assert(std::llabs((long long)c.sample - ll(exact)) <= 1);
            exact += spb4;
        }
    }
    std::printf("PASS test_scenario_G_cambio_armato_e_riallineo\n");
}

// ─────────────────────────── il bordo del buffer e le guardie ───────────────────────────

void test_bordo_del_buffer_e_guardie() {
    {   // il battito in attesa al campione 511: rinominato a 2, esce a 511 senza accento, l'identita' non cambia
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 120.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        dsp.setAbsolutePositionForTesting(24000 - 511);
        const Pending g0 = readPending(dsp);
        dsp.renamePendingBeat(2);
        const Pending g1 = readPending(dsp);
        assert(g0.beat == g1.beat && g0.ahead == g1.ahead && g1.ahead == 511);
        assert(dsp.getStartAbsoluteBeat() == 0.0);
        const auto evs = dsp.processBuffer(512);
        assert(evs.size() == 1 && evs[0].isBeat && evs[0].offset == 511 && !evs[0].accent);
        assert(dsp.getCurrentBeatInBar() == 3);
    }
    {   // al campione 0: rinominato a 0, esce a 0 accentato
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 120.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        dsp.setAbsolutePositionForTesting(24000);
        dsp.renamePendingBeat(0);
        const auto evs = dsp.processBuffer(512);
        assert(evs.size() == 1 && evs[0].isBeat && evs[0].offset == 0 && evs[0].accent);
    }
    {   // il modulo e la guardia
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 120.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        dsp.setBeatsPerBar(4);
        dsp.renamePendingBeat(7);
        assert(dsp.getCurrentBeatInBar() == 3);
        dsp.setBeatsPerBar(0);
        dsp.renamePendingBeat(2);
        assert(dsp.getCurrentBeatInBar() == 0);   // setBeatsPerBar(0) ha messo 0; con _beatsPerBar == 0 la rinomina non fa niente
    }
    std::printf("PASS test_bordo_del_buffer_e_guardie\n");
}

// ─────────────────────────── H: un cambio di suddivisione armato ───────────────────────────

struct CorsaH { std::vector<Ev> ev; std::vector<uint64_t> accenti; };

// A 120 in 4/4 (24000 campioni per battito): usciti 0, 1, 2; in attesa il 3 con l'etichetta 3. Le crome si armano
// li' (scheduleSubdivisionChange), poi la rinomina (rinomina < 0: nessuna). Rende gli eventi fino al campione 200192.
CorsaH corsaH(int rinomina, double swing) {
    auto dspBox = std::make_unique<MetronomeDSP>(kRate, 120.0);   // sullo heap, come metronome_create
    MetronomeDSP& dsp = *dspBox;
    dsp.setBeatsPerBar(4);
    dsp.resetForStart(0.0);
    uint64_t cursor = 0;
    const int usciti = advanceUntil(dsp, cursor, 24000.0, 2.5);
    assert(usciti == 3 && cursor == 60416 && dsp.getCurrentBeatInBar() == 3);
    dsp.scheduleSubdivisionChange(2, swing);
    if (rinomina >= 0) dsp.renamePendingBeat((uint32_t)rinomina);
    const Pending g = readPending(dsp);
    assert(ll(g.beat) == 3 && (int64_t)cursor + g.ahead == 72000);   // ne' l'armo ne' la rinomina toccano il battito in attesa
    CorsaH out;
    for (int b = 0; b < 273; ++b) {
        for (const auto& e : dsp.processBuffer(kBuf)) {
            out.ev.push_back({ cursor + e.offset, e.isBeat });
            if (e.isBeat && e.accent) out.accenti.push_back(cursor + e.offset);
        }
        cursor += kBuf;
    }
    assert(cursor == 200192);
    return out;
}

void assertEventi(const CorsaH& c, const uint64_t* campioni, const bool* battito, size_t n) {
    assert(c.ev.size() == n);
    for (size_t i = 0; i < n; ++i) {
        assert(c.ev[i].sample == campioni[i]);
        assert(c.ev[i].isBeat == battito[i]);
    }
}

void test_scenario_H_cambio_di_suddivisione_armato() {
    // (A432 parte 2a; il ramo scoperto di VERIFICA_REFEREE_A432_PARTE1 par. 1 e NOTE_VERIFICATORI_A432_PARTE1,
    // A par. 5 a e 7.) Lo scambio di una suddivisione armata scatta al battito con etichetta 0, come quelli del
    // metro e del tempo (scenario G): la rinomina sposta quell'«uno», quindi sposta il battito da cui partono le
    // suddivisioni. I BATTITI restano agli stessi campioni (la rinomina non tocca la linea a campioni e qui il
    // tempo non cambia); le suddivisioni compaiono da un battito diverso. E' il contratto della rinomina: con un
    // cambio armato lo scambio scatta sul nuovo «uno», quindi i click dopo cambiano campione.
    {   // senza rinomina: etichette 3, 0, 1, 2, 3, 0; lo scambio sul battito 4 (96000), la prima croma a 108000
        const CorsaH c = corsaH(-1, 0.5);
        const uint64_t s[] = { 72000, 96000, 108000, 120000, 132000, 144000, 156000, 168000, 180000, 192000 };
        const bool     b[] = { true,  true,  false,  true,   false,  true,   false,  true,   false,  true   };
        assertEventi(c, s, b, 10);
        assert(c.accenti.size() == 2 && c.accenti[0] == 96000 && c.accenti[1] == 192000);
    }
    {   // rinominato a 0: il battito 3 e' il nuovo «uno», lo scambio scatta li' (72000) e la prima croma e' a 84000
        const CorsaH c = corsaH(0, 0.5);
        const uint64_t s[] = { 72000, 84000, 96000, 108000, 120000, 132000, 144000, 156000, 168000, 180000, 192000 };
        const bool     b[] = { true,  false, true,  false,  true,   false,  true,   false,  true,   false,  true   };
        assertEventi(c, s, b, 11);
        assert(c.accenti.size() == 2 && c.accenti[0] == 72000 && c.accenti[1] == 168000);
    }
    {   // rinominato a 2: etichette 2, 3, 0, 1, 2, 3; lo scambio due battiti dopo, sul 5 (120000), la prima croma a 132000
        const CorsaH c = corsaH(2, 0.5);
        const uint64_t s[] = { 72000, 96000, 120000, 132000, 144000, 156000, 168000, 180000, 192000 };
        const bool     b[] = { true,  true,  true,   false,  true,   false,  true,   false,  true   };
        assertEventi(c, s, b, 9);
        assert(c.accenti.size() == 1 && c.accenti[0] == 120000);
    }
    {   // con lo swing 0,6 e la rinomina a 0: la croma lunga a 0,6 * 24000 = 14400 campioni dal nuovo «uno»
        const CorsaH c = corsaH(0, 0.6);
        const uint64_t s[] = { 72000, 86400, 96000, 110400, 120000, 134400, 144000, 158400, 168000, 182400, 192000 };
        const bool     b[] = { true,  false, true,  false,  true,   false,  true,   false,  true,   false,  true   };
        assertEventi(c, s, b, 11);
    }
    {   // i battiti: gli stessi campioni con e senza la rinomina, e nei tre casi
        const CorsaH senza = corsaH(-1, 0.5), aZero = corsaH(0, 0.5), aDue = corsaH(2, 0.5);
        std::vector<uint64_t> bs, b0, b2;
        for (const Ev& e : senza.ev) if (e.isBeat) bs.push_back(e.sample);
        for (const Ev& e : aZero.ev) if (e.isBeat) b0.push_back(e.sample);
        for (const Ev& e : aDue.ev)  if (e.isBeat) b2.push_back(e.sample);
        assert(bs.size() == 6 && bs == b0 && bs == b2);
    }
    std::printf("PASS test_scenario_H_cambio_di_suddivisione_armato\n");
}

}  // namespace

int main() {
    assertSuStderr();
    setvbuf(stdout, nullptr, _IONBF, 0);   // le righe PASS subito, anche con l'uscita su un file
    test_scenario_A_gli_stessi_click_le_etichette_giuste();
    test_scenario_B_correzione_indietro_nessun_doppio();
    test_scenario_C_buchi_interi_al_primo_campione();
    test_scenario_D_origine_intatta();
    test_scenario_E_suddivisioni_identiche();
    test_scenario_F_il_battito_a_subito_esce_una_volta_col_nome_nuovo();
    test_scenario_G_cambio_armato_e_riallineo();
    test_bordo_del_buffer_e_guardie();
    test_scenario_H_cambio_di_suddivisione_armato();
    std::printf("\nALL TESTS PASSED (test_rename_pending_beat)\n");
    return 0;
}
