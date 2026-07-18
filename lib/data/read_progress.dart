import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which Bible chapters the reader has actually read, persisted across
/// launches. Chapters are keyed by book title + chapter so the reader (which
/// knows the book name) and the study screen (which knows the book title) agree.
///
/// Keep book naming consistent between the two — canonical titles like
/// "Genesis" match the reader's `bibleBooks[i].name`.
class ReadProgress {
  ReadProgress._();

  static const _prefsKey = 'readChapters';

  static String keyFor(String book, int chapter) =>
      '${book.trim().toLowerCase()}|$chapter';

  /// All read-chapter keys currently stored.
  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_prefsKey) ?? const <String>[]).toSet();
  }

  /// Marks a chapter read. Returns true if this was newly added.
  static Future<bool> mark(String book, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_prefsKey) ?? const <String>[]).toSet();
    final added = current.add(keyFor(book, chapter));
    if (added) await prefs.setStringList(_prefsKey, current.toList());
    return added;
  }
}
