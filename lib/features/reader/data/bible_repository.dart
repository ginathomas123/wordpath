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
      verses.add(BibleVerse(
        number: number,
        text: (v['text'] as String)
            .trim()
            .replaceAll('\n', ' ')
            .replaceAll(RegExp(r' {2,}'), ' '),
      ));
    }
    return ChapterContent(verses: verses);
  }
}
