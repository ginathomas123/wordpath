import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A saved chapter bookmark. Bookmarks are a set of (book, chapter) pairs; the
/// reader's ribbon reflects whether the current chapter is among them.
class BookmarkEntry {
  final int bookIndex;
  final int chapter;
  const BookmarkEntry({required this.bookIndex, required this.chapter});

  Map<String, dynamic> toJson() => {'b': bookIndex, 'c': chapter};
  factory BookmarkEntry.fromJson(Map<String, dynamic> j) =>
      BookmarkEntry(bookIndex: j['b'] as int, chapter: j['c'] as int);

  @override
  bool operator ==(Object other) =>
      other is BookmarkEntry &&
      other.bookIndex == bookIndex &&
      other.chapter == chapter;

  @override
  int get hashCode => Object.hash(bookIndex, chapter);
}

Future<List<BookmarkEntry>> loadBookmarks() async {
  final prefs = await SharedPreferences.getInstance();
  // Migrate the legacy single-ribbon bookmark (bmk_book / bmk_chap) into the
  // new multi-bookmark list on first run.
  final legacyBook = prefs.getInt('bmk_book');
  final legacyChap = prefs.getInt('bmk_chap');
  if (legacyBook != null && legacyChap != null) {
    final entry = BookmarkEntry(bookIndex: legacyBook, chapter: legacyChap);
    await saveBookmarks([entry]);
    await prefs.remove('bmk_book');
    await prefs.remove('bmk_chap');
    return [entry];
  }
  final raw = prefs.getString('bookmarks_v2');
  if (raw == null) return [];
  final list = jsonDecode(raw) as List;
  return list.map((e) => BookmarkEntry.fromJson(e as Map<String, dynamic>)).toList();
}

Future<void> saveBookmarks(List<BookmarkEntry> bookmarks) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      'bookmarks_v2', jsonEncode(bookmarks.map((e) => e.toJson()).toList()));
}
