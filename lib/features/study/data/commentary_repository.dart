import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single verse's commentary note.
class CommentaryVerse {
  const CommentaryVerse({required this.number, required this.text});
  final int number;
  final String text;
}

/// Fetches Matthew Henry's (public-domain) commentary from the free, keyless
/// HelloAO Bible API: https://bible.helloao.org
///
/// Endpoint shape:
///   `GET /api/c/matthew-henry/{USFM_BOOK}/{chapter}.json`
/// whose `chapter.content` is an ordered list of `{type:'verse', number,
/// content:[String]}` items (plus the occasional heading/intro we skip).
class CommentaryRepository {
  CommentaryRepository._();

  static const _base = 'https://bible.helloao.org/api/c/matthew-henry';

  /// Cache keyed by "USFM|chapter" so re-opening a passage is instant.
  static final Map<String, List<CommentaryVerse>> _cache = {};

  /// Whether Matthew Henry commentary exists for [bookName]. (HelloAO's edition
  /// is missing Song of Solomon.)
  static bool isAvailable(String bookName) => _usfm.containsKey(_norm(bookName));

  static Future<List<CommentaryVerse>> fetch(String bookName, int chapter) async {
    final usfm = _usfm[_norm(bookName)];
    if (usfm == null) return const [];

    final cacheKey = '$usfm|$chapter';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final res = await http
        .get(Uri.parse('$_base/$usfm/$chapter.json'))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Commentary unavailable (${res.statusCode})');
    }

    final data = json.decode(res.body) as Map<String, dynamic>;
    final content = (data['chapter']?['content'] as List?) ?? const [];
    final verses = <CommentaryVerse>[];
    for (final item in content) {
      if (item is! Map || item['type'] != 'verse') continue;
      final number = (item['number'] as num?)?.toInt() ?? 0;
      final parts = (item['content'] as List?) ?? const [];
      final text = parts
          .whereType<String>()
          .join('\n')
          .trim();
      if (text.isNotEmpty) {
        verses.add(CommentaryVerse(number: number, text: text));
      }
    }
    _cache[cacheKey] = verses;
    return verses;
  }

  static String _norm(String s) => s.trim().toLowerCase();

  /// Reader book name → USFM id used by the HelloAO API.
  static const Map<String, String> _usfm = {
    'genesis': 'GEN', 'exodus': 'EXO', 'leviticus': 'LEV', 'numbers': 'NUM',
    'deuteronomy': 'DEU', 'joshua': 'JOS', 'judges': 'JDG', 'ruth': 'RUT',
    '1 samuel': '1SA', '2 samuel': '2SA', '1 kings': '1KI', '2 kings': '2KI',
    '1 chronicles': '1CH', '2 chronicles': '2CH', 'ezra': 'EZR',
    'nehemiah': 'NEH', 'esther': 'EST', 'job': 'JOB', 'psalms': 'PSA',
    'proverbs': 'PRO', 'ecclesiastes': 'ECC', 'isaiah': 'ISA',
    'jeremiah': 'JER', 'lamentations': 'LAM', 'ezekiel': 'EZK',
    'daniel': 'DAN', 'hosea': 'HOS', 'joel': 'JOL', 'amos': 'AMO',
    'obadiah': 'OBA', 'jonah': 'JON', 'micah': 'MIC', 'nahum': 'NAM',
    'habakkuk': 'HAB', 'zephaniah': 'ZEP', 'haggai': 'HAG',
    'zechariah': 'ZEC', 'malachi': 'MAL', 'matthew': 'MAT', 'mark': 'MRK',
    'luke': 'LUK', 'john': 'JHN', 'acts': 'ACT', 'romans': 'ROM',
    '1 corinthians': '1CO', '2 corinthians': '2CO', 'galatians': 'GAL',
    'ephesians': 'EPH', 'philippians': 'PHP', 'colossians': 'COL',
    '1 thessalonians': '1TH', '2 thessalonians': '2TH', '1 timothy': '1TI',
    '2 timothy': '2TI', 'titus': 'TIT', 'philemon': 'PHM', 'hebrews': 'HEB',
    'james': 'JAS', '1 peter': '1PE', '2 peter': '2PE', '1 john': '1JN',
    '2 john': '2JN', '3 john': '3JN', 'jude': 'JUD', 'revelation': 'REV',
  };
}
