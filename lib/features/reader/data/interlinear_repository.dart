import 'dart:convert';
import 'package:http/http.dart' as http;

/// One English word in a verse, with the Strong's number it maps to (if any).
class InterlinearWord {
  final String text;
  final int? strong; // bare number, e.g. 1254 (Hebrew for OT, Greek for NT)
  const InterlinearWord(this.text, this.strong);
}

/// Provides KJV+Strong's word tags for the reverse-interlinear popover.
///
/// The reader itself renders plain KJV from its existing source; this repo
/// fetches the *tagged* KJV from bolls.life (which appends a Strong's number
/// after each tagged word) and aligns it to the displayed words by position.
/// Chapters are cached in-memory so a chapter is fetched at most once.
class InterlinearRepository {
  InterlinearRepository._();

  static final Map<String, Map<int, List<InterlinearWord>>> _cache = {};
  static final Map<String, Future<Map<int, List<InterlinearWord>>>> _inflight = {};

  static Future<Map<int, List<InterlinearWord>>> _chapter(
      int bookIndex, int chapter) {
    final key = '${bookIndex}_$chapter';
    final cached = _cache[key];
    if (cached != null) return Future.value(cached);
    final pending = _inflight[key];
    if (pending != null) return pending;

    final future = _fetch(bookIndex, chapter).then((map) {
      _cache[key] = map;
      _inflight.remove(key);
      return map;
    }).catchError((e) {
      _inflight.remove(key);
      throw e;
    });
    _inflight[key] = future;
    return future;
  }

  static Future<Map<int, List<InterlinearWord>>> _fetch(
      int bookIndex, int chapter) async {
    final bookNum = bookIndex + 1; // bolls uses 1-based canonical order
    final url = 'https://bolls.life/get-text/KJV/$bookNum/$chapter/';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
    final list = jsonDecode(resp.body) as List;
    final out = <int, List<InterlinearWord>>{};
    for (final v in list) {
      final num = v['verse'] as int;
      out[num] = _parseVerse(v['text'] as String);
    }
    return out;
  }

  /// Returns the Strong's number for the tapped word, or null if unknown.
  static Future<int?> strongForWord(
    int bookIndex,
    int chapter,
    int verse,
    int wordIndex,
    String wordText,
  ) async {
    final map = await _chapter(bookIndex, chapter);
    final words = map[verse];
    if (words == null || words.isEmpty) return null;
    final target = _norm(wordText);

    // Exact position (KJV↔KJV usually aligns 1:1).
    if (wordIndex >= 0 && wordIndex < words.length &&
        _norm(words[wordIndex].text) == target) {
      return words[wordIndex].strong;
    }
    // Search nearby to absorb minor tokenization drift.
    for (int d = 1; d <= 4; d++) {
      for (final i in [wordIndex + d, wordIndex - d]) {
        if (i >= 0 && i < words.length && _norm(words[i].text) == target) {
          return words[i].strong;
        }
      }
    }
    // Fall back to whatever tag sits at that position.
    if (wordIndex >= 0 && wordIndex < words.length) return words[wordIndex].strong;
    return null;
  }

  /// Returns the distinct Strong's numbers underlying a span of English words
  /// (indices [start]..[end] inclusive, aligned via [words]), in first-appearance
  /// order. Repeats are collapsed because one original word is frequently
  /// rendered by several English words (and vice versa).
  static Future<List<int>> strongsForRange(
    int bookIndex,
    int chapter,
    int verse,
    int start,
    int end,
    List<String> words,
  ) async {
    final out = <int>[];
    final seen = <int>{};
    for (int i = start; i <= end && i < words.length; i++) {
      final s = await strongForWord(bookIndex, chapter, verse, i, words[i]);
      if (s == null) continue;
      if (seen.add(s)) out.add(s);
    }
    return out;
  }

  // ── parsing ────────────────────────────────────────────────────────────────

  static final RegExp _noteMarker =
      RegExp(r':\s+(?:Heb|Gr|Chald|Sept|or,|Or\s|That is|call)');
  static final RegExp _strongTag = RegExp(r'<S>(\d+)</S>');
  static final RegExp _wordToken = RegExp(r"[A-Za-z][A-Za-z'\-]*");
  static final RegExp _nonLetter = RegExp(r"[^a-z]");

  /// Trims bolls' trailing translator notes (e.g. "firmament: Heb. expansion")
  /// so they don't pollute the word→Strong's map. Display text is unaffected —
  /// it comes from the reader's own source.
  static String _stripNotes(String s) {
    final m = _noteMarker.firstMatch(s);
    if (m == null) return s.trim();
    final head = s.substring(0, m.start);
    int cut = -1;
    for (final t in ['.', '?', '!']) {
      final i = head.lastIndexOf(t);
      if (i > cut) cut = i;
    }
    if (cut >= 0) return s.substring(0, cut + 1).trim();
    return head.trim();
  }

  /// Parses one tagged verse (bolls markup: `word<S>1234</S>`) into ordered
  /// words. Each `<S>` tag annotates the word cluster that precedes it since
  /// the previous tag, matching the reverse-interlinear convention.
  static List<InterlinearWord> _parseVerse(String raw) {
    final text = _stripNotes(raw);
    final result = <InterlinearWord>[];
    final pending = <int>[]; // indices awaiting a Strong's number
    var last = 0;

    void addWords(String chunk) {
      for (final m in _wordToken.allMatches(chunk)) {
        result.add(InterlinearWord(m.group(0)!, null));
        pending.add(result.length - 1);
      }
    }

    for (final m in _strongTag.allMatches(text)) {
      addWords(text.substring(last, m.start));
      final n = int.parse(m.group(1)!);
      for (final idx in pending) {
        result[idx] = InterlinearWord(result[idx].text, n);
      }
      pending.clear();
      last = m.end;
    }
    // Trailing words after the final tag carry no Strong's number.
    for (final m in _wordToken.allMatches(text.substring(last))) {
      result.add(InterlinearWord(m.group(0)!, null));
    }
    return result;
  }

  static String _norm(String s) => s.toLowerCase().replaceAll(_nonLetter, '');
}
