#include "TempoMap.h"
#include <cmath>

bool operator==(const TempoPoint& a, const TempoPoint& b) {
    // Confronto ESATTO anche sul double: serve al test di round-trip JSON,
    // che garantisce l'esattezza via %.17g — nessuna tolleranza mascherante.
    return a.sampleOffset == b.sampleOffset && a.bpm == b.bpm;
}

namespace tempomap {

double bpmAt(const TempoPoint* points, size_t count, uint64_t sample) {
    if (count == 0) return 0.0;                    // difensivo — vedi header
    if (sample <= points[0].sampleOffset) return points[0].bpm;
    const size_t lastIdx = count - 1;
    if (sample >= points[lastIdx].sampleOffset) return points[lastIdx].bpm;
    // Invariante: points[lo].sampleOffset <= sample < points[hi].sampleOffset
    size_t lo = 0, hi = lastIdx;
    while (hi - lo > 1) {
        const size_t mid = lo + (hi - lo) / 2;
        if (points[mid].sampleOffset <= sample) lo = mid;
        else                                    hi = mid;
    }
    const TempoPoint& a = points[lo];
    const TempoPoint& b = points[hi];
    const double t = (double)(sample - a.sampleOffset)
                   / (double)(b.sampleOffset - a.sampleOffset);
    return a.bpm + t * (b.bpm - a.bpm);
}

} // namespace tempomap

bool TempoMap::isValidSeries(const std::vector<TempoPoint>& points,
                             double sourceSampleRate) {
    if (points.empty() || points.size() > kMaxPoints) return false;
    if (!(sourceSampleRate > 0.0) || !std::isfinite(sourceSampleRate)) return false;
    for (size_t i = 0; i < points.size(); ++i) {
        // !(bpm > 0) intercetta anche NaN; isfinite intercetta ±inf.
        if (!(points[i].bpm > 0.0) || !std::isfinite(points[i].bpm)) return false;
        if (i > 0 && points[i].sampleOffset <= points[i - 1].sampleOffset) return false;
    }
    return true;
}

bool TempoMap::make(std::vector<TempoPoint> points, double sourceSampleRate,
                    TempoMap& out) {
    if (!isValidSeries(points, sourceSampleRate)) return false;
    out._points           = std::move(points);
    out._sourceSampleRate = sourceSampleRate;
    return true;
}

bool operator==(const TempoMap& a, const TempoMap& b) {
    return a.sourceSampleRate() == b.sourceSampleRate()
        && a.points() == b.points();
}
