import 'dart:convert';
import 'package:http/http.dart' as http;

class BibleVerse {
  final int number;
  final String text;
  const BibleVerse({required this.number, required this.text});
}

class ChapterContent {
  final List<BibleVerse> verses;
  const ChapterContent({required this.verses});
}

class BibleRepository {
  // Upstream KJV appends translator footnotes to the verse text, glued on as a
  // "<chapter>.<verse>" reference followed by the note, e.g. "…already.1.5
  // loins: Heb. thigh". KJV body text never contains a decimal number, so
  // everything from the first "\d+\.\d+" to the end is footnotes and is cut.
  static final RegExp _footnotes = RegExp(r'\s*\d+\.\d+[\s\S]*$');

  // A raw paragraph pilcrow the dataset prefixes to some verses; the reader
  // doesn't use it, so strip it rather than show a stray "¶".
  static final RegExp _pilcrow = RegExp(r'^¶\s*');

  static String _clean(String raw) {
    return raw
        .trim()
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .replaceFirst(_footnotes, '')
        .replaceFirst(_pilcrow, '')
        .trim();
  }

  static Future<ChapterContent> fetchChapter(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    // The upstream KJV dataset sometimes lists every verse twice; keep the first
    // occurrence of each verse number so the reader and study cards don't repeat.
    final seen = <int>{};
    final verses = <BibleVerse>[];
    for (final v in (json['data'] as List)) {
      final number = int.parse(v['verse'] as String);
      if (!seen.add(number)) continue;
      verses.add(BibleVerse(number: number, text: _clean(v['text'] as String)));
    }
    return ChapterContent(verses: verses);
  }
}
