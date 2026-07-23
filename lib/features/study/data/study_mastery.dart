import '../../../data/bible_data.dart';
import '../../../data/read_progress.dart';
import '../../../data/study_data.dart';
import '../../../data/study_progress.dart';
import '../../reader/data/bible_data.dart' as reader;
import 'key_verses.dart';

/// Finds the reader's canonical book for a reference name, tolerating the
/// singular "Psalm" → "Psalms".
reader.BibleBook? findReaderBook(String name) {
  final n = name.trim().toLowerCase();
  for (final b in reader.bibleBooks) {
    if (b.name.toLowerCase() == n) return b;
  }
  for (final b in reader.bibleBooks) {
    if (b.name.toLowerCase() == '${n}s') return b;
  }
  return null;
}

/// One card on a study path, already resolved to the real scripture it opens
/// and records progress against — so the reader location and the study
/// checkmarks always agree.
class StudyEntry {
  const StudyEntry({
    required this.readerBook,
    required this.readerChapter,
    required this.pillLabel,
    required this.title,
    required this.preview,
    required this.seededComplete,
  });

  /// Reader book name + chapter this card opens and tracks.
  final String readerBook;
  final int readerChapter;

  /// Reference label shown on the card (e.g. "PHILIPPIANS 4").
  final String pillLabel;
  final String title;
  final String preview;

  /// Seeded-complete flag from the curated study data.
  final bool seededComplete;

  String get readKey => ReadProgress.keyFor(readerBook, readerChapter);
}

/// Builds the study path for [book]. Canonical books (whose `attribution` is an
/// author, e.g. "Moses") use their curated/generic chapters. Topical studies
/// (whose `attribution` is a reference, e.g. "Ephesians 5") map to consecutive
/// real chapters starting at the reference — only as many as actually exist, so
/// each card is a distinct passage.
List<StudyEntry> buildStudyEntries(BibleBook book) {
  final parts = book.attribution.trim().split(RegExp(r'\s+'));
  final refChapter = parts.length >= 2 ? int.tryParse(parts.last) : null;

  if (refChapter != null) {
    final refName = parts.sublist(0, parts.length - 1).join(' ');
    final rb = findReaderBook(refName);
    if (rb != null) {
      final available = rb.chapterCount - refChapter + 1;
      final count = available.clamp(1, 4);
      return List.generate(count, (i) {
        final ch = refChapter + i;
        return StudyEntry(
          readerBook: rb.name,
          readerChapter: ch,
          pillLabel: '${rb.name} $ch',
          title: book.title,
          preview: book.about ?? 'Read ${rb.name} $ch.',
          seededComplete: false,
        );
      });
    }
  }

  return [
    for (final c in chaptersFor(book))
      StudyEntry(
        readerBook: book.title,
        readerChapter: c.number,
        pillLabel: '${book.title} ${c.number}',
        title: c.title,
        preview: c.preview,
        seededComplete: c.completed,
      ),
  ];
}

double _frac(int done, int total) => total == 0 ? 0 : done / total;

/// True when every mastery track for [book] is complete — the same formula the
/// study screen uses for its capstone, evaluated purely from persisted state so
/// the shelf can decorate a completed book without opening the study.
bool isStudyMastered({
  required BibleBook book,
  required Set<String> readKeys,
  required StudyProgressData progress,
}) {
  final studyId = book.title;
  final entries = buildStudyEntries(book);
  if (entries.isEmpty) return false;
  final keyVerses = keyVersesFor(book.title);

  final readFrac = _frac(
    entries.where((e) => e.seededComplete || readKeys.contains(e.readKey)).length,
    entries.length,
  );
  final understandFrac = _frac(
    entries
        .where((e) => progress.isUnderstood(studyId, e.readerBook, e.readerChapter))
        .length,
    entries.length,
  );
  final memorizeFrac = keyVerses.isEmpty
      ? 1.0
      : _frac(
          keyVerses.where((kv) => progress.isMemorized(studyId, kv.ref)).length,
          keyVerses.length,
        );
  final applyFrac = progress.isReflected(studyId) ? 1.0 : 0.0;

  return (readFrac + understandFrac + memorizeFrac + applyFrac) / 4 >= 0.999;
}

/// Loads persisted progress once and reports, per book title, whether that
/// study is fully mastered — for decorating the shelf.
Future<Map<String, bool>> loadMasteredTitles(Iterable<BibleBook> books) async {
  final read = await ReadProgress.load();
  final progress = await StudyProgress.load();
  return {
    for (final b in books)
      b.title: isStudyMastered(book: b, readKeys: read, progress: progress),
  };
}
