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
    final verses = (json['data'] as List)
        .map((v) => BibleVerse(
              number: int.parse(v['verse'] as String),
              text: (v['text'] as String).trim().replaceAll('\n', ' ').replaceAll(RegExp(r' {2,}'), ' '),
            ))
        .toList();
    return ChapterContent(verses: verses);
  }
}
