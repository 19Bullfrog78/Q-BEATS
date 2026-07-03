#include "TempoMapJSON.h"

#include <cerrno>
#include <cmath>
#include <cstdio>
#include <cstdlib>

// --- Numeri locale-indipendenti (sempre formato "C": punto decimale) ---
// strtod/snprintf nudi seguono la locale del processo: se qualcosa settasse
// una locale con la virgola (it-IT), il formato si corromperebbe in silenzio.
// App da palco: nessuna dipendenza dall'ambiente. Non-RT (magic static al
// primo uso; questo modulo non gira mai sul thread audio).
#if defined(_MSC_VER)
  #include <locale.h>
  static double qb_strtod_c(const char* s, char** end) {
      static _locale_t loc = _create_locale(LC_ALL, "C");
      return _strtod_l(s, end, loc);
  }
  static void qb_fmt_double_c(char* buf, size_t n, double v) {
      static _locale_t loc = _create_locale(LC_ALL, "C");
      _snprintf_s_l(buf, n, _TRUNCATE, "%.17g", loc, v);
  }
#elif defined(__APPLE__)
  #include <locale.h>
  #include <xlocale.h>
  static double qb_strtod_c(const char* s, char** end) {
      static locale_t loc = newlocale(LC_ALL_MASK, "C", (locale_t)0);
      return strtod_l(s, end, loc);
  }
  static void qb_fmt_double_c(char* buf, size_t n, double v) {
      static locale_t loc = newlocale(LC_ALL_MASK, "C", (locale_t)0);
      snprintf_l(buf, n, loc, "%.17g", v);
  }
#else
  // Nessun target Linux/altro oggi (banco = MSVC, CI iOS = Apple clang):
  // fallback sulla locale del processo ("C" di default).
  static double qb_strtod_c(const char* s, char** end) {
      return strtod(s, end);
  }
  static void qb_fmt_double_c(char* buf, size_t n, double v) {
      snprintf(buf, n, "%.17g", v);
  }
#endif

namespace {

// Cursore del parser — schema chiuso, discesa ricorsiva minima.
struct Cursor {
    const char* p;     // punta dentro il buffer NUL-terminato di json.c_str()
    const char* end;

    bool atEnd() { skipWs(); return p >= end; }
    void skipWs() {
        while (p < end && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r'))
            ++p;
    }
    bool consume(char c) {
        skipWs();
        if (p < end && *p == c) { ++p; return true; }
        return false;
    }
    // Chiave JSON: stringa ASCII semplice senza escape (le chiavi dello schema
    // sono identificatori fissi — un escape qui è fuori schema).
    bool readKey(std::string& out) {
        skipWs();
        if (p >= end || *p != '"') return false;
        const char* start = ++p;
        while (p < end && *p != '"') {
            if (*p == '\\') return false;
            ++p;
        }
        if (p >= end) return false;
        out.assign(start, (size_t)(p - start));
        ++p;                                    // chiude "
        return true;
    }
    // Intero senza segno, senza frazione né esponente (schema: sampleOffset).
    bool readUint64(uint64_t& out) {
        skipWs();
        if (p >= end || *p < '0' || *p > '9') return false;
        char* stop = nullptr;
        errno = 0;
        unsigned long long v = std::strtoull(p, &stop, 10);
        if (stop == p || errno == ERANGE) return false;
        if (stop < end && (*stop == '.' || *stop == 'e' || *stop == 'E')) return false;
        out = (uint64_t)v;
        p = stop;
        return true;
    }
    bool readDouble(double& out) {
        skipWs();
        if (p >= end) return false;
        char* stop = nullptr;
        double v = qb_strtod_c(p, &stop);
        if (stop == p) return false;
        if (!std::isfinite(v)) return false;    // niente inf/nan nel formato
        out = v;
        p = stop;
        return true;
    }
};

// { "sampleOffset": <uint>, "bpm": <double> } — chiavi in qualunque ordine,
// ciascuna esattamente una volta.
bool parsePoint(Cursor& c, TempoPoint& out) {
    if (!c.consume('{')) return false;
    bool haveOffset = false, haveBpm = false;
    for (;;) {
        std::string key;
        if (!c.readKey(key)) return false;
        if (!c.consume(':')) return false;
        if (key == "sampleOffset") {
            if (haveOffset || !c.readUint64(out.sampleOffset)) return false;
            haveOffset = true;
        } else if (key == "bpm") {
            if (haveBpm || !c.readDouble(out.bpm)) return false;
            haveBpm = true;
        } else {
            return false;                       // chiave fuori schema
        }
        if (c.consume(',')) continue;
        break;
    }
    if (!c.consume('}')) return false;
    return haveOffset && haveBpm;
}

} // namespace

namespace tempomap_json {

std::string toJSON(const TempoMap& map) {
    char num[64];
    std::string s;
    s.reserve(map.size() * 48 + 64);
    s += "{\"sourceSampleRate\":";
    qb_fmt_double_c(num, sizeof num, map.sourceSampleRate());
    s += num;
    s += ",\"points\":[";
    bool first = true;
    for (const TempoPoint& pt : map.points()) {
        if (!first) s += ',';
        first = false;
        s += "{\"sampleOffset\":";
        s += std::to_string(pt.sampleOffset);   // intero: locale-safe
        s += ",\"bpm\":";
        qb_fmt_double_c(num, sizeof num, pt.bpm);
        s += num;
        s += '}';
    }
    s += "]}";
    return s;
}

bool fromJSON(const std::string& json, TempoMap& out) {
    Cursor c{ json.c_str(), json.c_str() + json.size() };
    if (!c.consume('{')) return false;

    bool haveRate = false, havePoints = false;
    double rate = 0.0;
    std::vector<TempoPoint> pts;

    for (;;) {
        std::string key;
        if (!c.readKey(key)) return false;
        if (!c.consume(':')) return false;
        if (key == "sourceSampleRate") {
            if (haveRate || !c.readDouble(rate)) return false;
            haveRate = true;
        } else if (key == "points") {
            if (havePoints || !c.consume('[')) return false;
            if (!c.consume(']')) {              // array non vuoto
                for (;;) {
                    TempoPoint pt;
                    if (!parsePoint(c, pt)) return false;
                    if (pts.size() >= TempoMap::kMaxPoints) return false;  // oltre cap
                    pts.push_back(pt);
                    if (c.consume(',')) continue;
                    if (c.consume(']')) break;
                    return false;
                }
            }
            havePoints = true;
        } else {
            return false;                       // chiave fuori schema
        }
        if (c.consume(',')) continue;
        break;
    }
    if (!c.consume('}')) return false;
    if (!c.atEnd()) return false;               // niente coda dopo la chiusura
    if (!haveRate || !havePoints) return false;

    // Validazione UNICA — stessa via di ogni costruzione (ordinamento, bpm>0,
    // cap, rate). Su errore `out` resta invariata: make scrive solo su successo.
    return TempoMap::make(std::move(pts), rate, out);
}

} // namespace tempomap_json
