import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/bible_data.dart';
import '../maps/bible_map_data.dart';
import '../theme/bible_theme.dart';

class HighlightEntry {
  final int bookIndex;
  final int chapter;
  final int verseNumber;
  final int start; // char offset within verse.text (not including verse number prefix)
  final int end;

  const HighlightEntry({
    required this.bookIndex,
    required this.chapter,
    required this.verseNumber,
    required this.start,
    required this.end,
  });

  Color get color {
    final abbrev = bibleBooks[bookIndex].abbrev;
    final base = BibleColors.tabColors[abbrev] ?? const Color(0xFF7A4828);
    return base.withValues(alpha: 0.28);
  }

  Map<String, dynamic> toJson() => {
    'b': bookIndex, 'c': chapter, 'v': verseNumber, 's': start, 'e': end,
  };

  factory HighlightEntry.fromJson(Map<String, dynamic> j) => HighlightEntry(
    bookIndex: j['b'] as int,
    chapter: j['c'] as int,
    verseNumber: j['v'] as int,
    start: j['s'] as int,
    end: j['e'] as int,
  );
}

Future<List<HighlightEntry>> loadHighlights() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('highlights_v1') ?? '[]';
  try {
    return (jsonDecode(raw) as List)
        .map((j) => HighlightEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> saveHighlights(List<HighlightEntry> entries) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'highlights_v1',
    jsonEncode(entries.map((e) => e.toJson()).toList()),
  );
}

// Splits verse text into spans, applying highlight backgrounds where stored.
List<TextSpan> buildHighlightedSpans(
  String verseText,
  List<HighlightEntry> versHighlights,
  TextStyle base,
) {
  if (versHighlights.isEmpty) return [TextSpan(text: verseText, style: base)];

  final sorted = [...versHighlights]..sort((a, b) => a.start.compareTo(b.start));
  final spans = <TextSpan>[];
  int pos = 0;

  for (final h in sorted) {
    final s = h.start.clamp(0, verseText.length);
    final e = h.end.clamp(0, verseText.length);
    if (s >= e) continue;
    if (s > pos) spans.add(TextSpan(text: verseText.substring(pos, s), style: base));
    spans.add(TextSpan(
      text: verseText.substring(s, e),
      style: base.copyWith(backgroundColor: h.color),
    ));
    pos = e;
  }
  if (pos < verseText.length) {
    spans.add(TextSpan(text: verseText.substring(pos), style: base));
  }
  return spans;
}

/// Muted burgundy used for the dotted underline under place names.
const Color _placeUnderline = Color(0x807A1828);

/// Like [buildHighlightedSpans], but also draws a subtle dotted underline
/// beneath recognized place names so the tap-to-map feature is discoverable.
List<TextSpan> buildReaderSpans(
  String verseText,
  List<HighlightEntry> versHighlights,
  TextStyle base,
) {
  final places = BibleGeo.placeRangesIn(verseText);
  if (versHighlights.isEmpty && places.isEmpty) {
    return [TextSpan(text: verseText, style: base)];
  }

  final len = verseText.length;
  final cuts = <int>{0, len};
  for (final h in versHighlights) {
    cuts.add(h.start.clamp(0, len));
    cuts.add(h.end.clamp(0, len));
  }
  for (final p in places) {
    cuts.add(p[0].clamp(0, len));
    cuts.add(p[1].clamp(0, len));
  }
  final bounds = cuts.toList()..sort();

  final spans = <TextSpan>[];
  for (var i = 0; i < bounds.length - 1; i++) {
    final s = bounds[i];
    final e = bounds[i + 1];
    if (s >= e) continue;

    Color? bg;
    for (final h in versHighlights) {
      if (h.start <= s && h.end >= e && h.start < h.end) {
        bg = h.color;
        break;
      }
    }
    var isPlace = false;
    for (final p in places) {
      if (p[0] <= s && p[1] >= e) {
        isPlace = true;
        break;
      }
    }

    var style = base;
    if (bg != null) style = style.copyWith(backgroundColor: bg);
    if (isPlace) {
      style = style.copyWith(
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.dotted,
        decorationColor: _placeUnderline,
        decorationThickness: 1.4,
      );
    }
    spans.add(TextSpan(text: verseText.substring(s, e), style: style));
  }
  return spans;
}
