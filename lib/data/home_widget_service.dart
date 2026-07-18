import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/reader/data/bible_data.dart' as reader;

/// Bridges the app's reading state to the native Android home-screen widget.
///
/// The widget shows a "continue reading" summary and a flipping stack of book
/// spines. We push the current chapter label whenever the reader moves, and we
/// expose the last-read position so a widget tap can resume exactly there.
class HomeWidgetService {
  HomeWidgetService._();

  /// Must match the AppWidgetProvider class name registered in the manifest.
  static const _androidProvider = 'WordPathWidgetProvider';

  static const _lastBookKey = 'lastBookIndex';
  static const _lastChapterKey = 'lastChapter';

  /// Pushes the given reading position to the widget as "Book N".
  static Future<void> update(int bookIndex, int chapter) async {
    final safeIndex = bookIndex.clamp(0, reader.bibleBooks.length - 1);
    final name = reader.bibleBooks[safeIndex].name;
    await HomeWidget.saveWidgetData<String>('wp_category', 'CONTINUE READING');
    await HomeWidget.saveWidgetData<String>('wp_title', '$name $chapter');
    await HomeWidget.updateWidget(androidName: _androidProvider);
  }

  /// Refreshes the widget from the last-read position saved by the reader,
  /// falling back to Genesis 1 when nothing has been read yet.
  static Future<void> refreshFromLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final book = prefs.getInt(_lastBookKey) ?? 0;
    final chapter = prefs.getInt(_lastChapterKey) ?? 1;
    await update(book, chapter);
  }

  /// The last-read (bookIndex, chapter), for resuming from a widget tap.
  static Future<(int, int)> lastRead() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_lastBookKey) ?? 0, prefs.getInt(_lastChapterKey) ?? 1);
  }
}
