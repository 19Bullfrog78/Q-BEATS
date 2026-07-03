#pragma once
#include "TempoMap.h"
#include <string>

// === B7-fondazione — Serializzazione JSON TempoMap (Atomo A1) ===
// Serializzatore SOLO-PER-QUESTO-SCHEMA, zero dipendenze — NON è un parser
// JSON generale (scope ratificato referee 03/07). Schema:
//   {"sourceSampleRate":48000,"points":[{"sampleOffset":0,"bpm":121}, ...]}
// I nomi-campo dei punti ("sampleOffset","bpm") DEVONO restare identici al
// futuro modello Swift `TempoPoint` (BacktrackFile.tempoMap, Atomo A5 —
// Codable canonico on-device). Il container C++ `sourceSampleRate` specchia
// il campo Swift separato `tempoMapSampleRate` (ratifica referee, punto 5a).
// Parser: chiavi in qualunque ordine, ciascuna esattamente una volta; chiave
// sconosciuta = errore (schema chiuso, formato del banco). Round-trip esatto:
// double scritti con %.17g, locale-indipendente (helper C-locale nel .cpp).

namespace tempomap_json {

// Precondizione: map.isValid().
std::string toJSON(const TempoMap& map);

// Ritorna true e riempie `out` SOLO se il testo è ben formato secondo lo
// schema E la serie passa la validazione unica di TempoMap::make (ordinamento,
// bpm > 0, cap, sample rate). In caso di errore `out` resta INVARIATA.
bool fromJSON(const std::string& json, TempoMap& out);

} // namespace tempomap_json
