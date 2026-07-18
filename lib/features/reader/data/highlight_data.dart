import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/bible_data.dart';
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
