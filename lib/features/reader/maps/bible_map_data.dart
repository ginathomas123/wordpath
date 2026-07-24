import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

/// A single located place in the biblical world.
///
/// Coordinates come from OpenBible.info's Bible Geocoding data (CC-BY-4.0);
/// [approx] carries their ~ / < / > / ? uncertainty markers, which the atlas
/// renders as a soft confidence halo rather than a crisp point.
class MapPlace {
  final String name;
  final double lat;
  final double lon;
  final bool approx;

  const MapPlace({
    required this.name,
    required this.lat,
    required this.lon,
    required this.approx,
  });
}

/// The baked atlas: a clipped land outline (Natural Earth, public domain) plus
/// the curated place set. Rings store points as `Offset(lon, lat)`.
class BibleAtlasData {
  final double lonMin, latMin, lonMax, latMax;
  final List<List<Offset>> land;
  final List<MapPlace> places;

  const BibleAtlasData({
    required this.lonMin,
    required this.latMin,
    required this.lonMax,
    required this.latMax,
    required this.land,
    required this.places,
  });
}

/// Loads and indexes the atlas assets once, and resolves English place words
/// (KJV spellings included) to their location.
class BibleGeo {
  BibleGeo._();

  static BibleAtlasData? _data;
  static Map<String, MapPlace>? _index;

  static BibleAtlasData? get data => _data;

  /// KJV spellings that differ from OpenBible's (ESV-based) canonical names.
  static const Map<String, String> _aliases = {
    'colosse': 'colossae',
    'pergamos': 'pergamum',
    'cenchrea': 'cenchreae',
    'melita': 'malta',
    'nineve': 'nineveh',
    'sion': 'zion',
    'salem': 'jerusalem',
  };

  static Future<BibleAtlasData> ensureLoaded() async {
    if (_data != null) return _data!;
    final placesRaw = await rootBundle.loadString('assets/maps/places.json');
    final baseRaw = await rootBundle.loadString('assets/maps/basemap.json');

    final places = (jsonDecode(placesRaw) as List)
        .map((j) => MapPlace(
              name: j['name'] as String,
              lat: (j['lat'] as num).toDouble(),
              lon: (j['lon'] as num).toDouble(),
              approx: j['approx'] as bool,
            ))
        .toList();

    final base = jsonDecode(baseRaw) as Map<String, dynamic>;
    final bbox = (base['bbox'] as List).map((e) => (e as num).toDouble()).toList();
    final land = (base['land'] as List)
        .map<List<Offset>>((ring) => (ring as List)
            .map<Offset>((p) =>
                Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList())
        .toList();

    _data = BibleAtlasData(
      lonMin: bbox[0],
      latMin: bbox[1],
      lonMax: bbox[2],
      latMax: bbox[3],
      land: land,
      places: places,
    );
    _index = {for (final p in places) p.name.toLowerCase(): p};
    return _data!;
  }

  static String _norm(String w) =>
      w.toLowerCase().replaceAll(RegExp(r"[^a-z\-]"), '');

  static final RegExp _wordRe = RegExp(r"[A-Za-z][A-Za-z'\-]*");

  /// Whether a single word resolves to a known place.
  static bool isPlace(String word) {
    final idx = _index;
    if (idx == null) return false;
    final key = _norm(word);
    if (key.isEmpty) return false;
    return idx.containsKey(_aliases[key] ?? key);
  }

  /// Char ranges `[start, end)` of words in [text] that name a known place —
  /// used by the reader to underline them so the map is discoverable.
  static List<List<int>> placeRangesIn(String text) {
    final idx = _index;
    if (idx == null) return const [];
    final ranges = <List<int>>[];
    for (final m in _wordRe.allMatches(text)) {
      final key = _norm(m.group(0)!);
      if (key.isEmpty) continue;
      if (idx.containsKey(_aliases[key] ?? key)) {
        ranges.add([m.start, m.end]);
      }
    }
    return ranges;
  }

  /// First place matched among [words] (handles KJV alias spellings), or null.
  static MapPlace? match(Iterable<String> words) {
    final idx = _index;
    if (idx == null) return null;
    for (final w in words) {
      final key = _norm(w);
      if (key.isEmpty) continue;
      final canon = _aliases[key] ?? key;
      final hit = idx[canon];
      if (hit != null) return hit;
    }
    return null;
  }

  /// Nearby places for context on the atlas (excludes [center]).
  static List<MapPlace> neighbors(MapPlace center,
      {int count = 6, double maxDeg = 3.0}) {
    final d = _data;
    if (d == null) return const [];
    final scored = <MapEntry<MapPlace, double>>[];
    for (final p in d.places) {
      if (p.name == center.name) continue;
      final dLat = p.lat - center.lat;
      final dLon = (p.lon - center.lon) * math.cos(center.lat * math.pi / 180);
      final d2 = dLat * dLat + dLon * dLon;
      if (d2 <= maxDeg * maxDeg) scored.add(MapEntry(p, d2));
    }
    scored.sort((a, b) => a.value.compareTo(b.value));
    return scored.take(count).map((e) => e.key).toList();
  }
}
