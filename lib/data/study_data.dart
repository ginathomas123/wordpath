import 'bible_data.dart';

/// A single chapter entry shown on a book's study "path".
class StudyChapter {
  const StudyChapter({
    required this.number,
    required this.title,
    required this.preview,
    this.completed = false,
  });

  /// Chapter number within the book, e.g. 1 for "Luke 1".
  final int number;

  /// Human title for the chapter's main passage.
  final String title;

  /// Short opening snippet of the chapter, shown under the title.
  final String preview;

  /// Whether the reader has finished this chapter.
  final bool completed;
}

/// Curated study chapters keyed by book title. Books without a curated path
/// fall back to [_genericChapters].
const Map<String, List<StudyChapter>> _curatedPaths = {
  'Luke': [
    StudyChapter(
      number: 1,
      title: 'The Birth of John Foretold',
      preview:
          'In the time of Herod king of Judea, there was a priest named '
          'Zechariah\u2026',
      completed: true,
    ),
    StudyChapter(
      number: 2,
      title: 'The Sermon on the Plain',
      preview:
          'He went down with them and stood on a level place, with a great '
          'crowd\u2026',
      completed: true,
    ),
    StudyChapter(
      number: 3,
      title: 'The Good Samaritan',
      preview:
          'A man was going down from Jerusalem to Jericho, and he fell among '
          'robbers\u2026',
      completed: true,
    ),
    StudyChapter(
      number: 4,
      title: 'The Prodigal Son',
      preview:
          'There was a man who had two sons, and the younger said to his '
          'father\u2026',
    ),
    StudyChapter(
      number: 5,
      title: 'The Road to Emmaus',
      preview:
          'That very day two of them were going to a village named '
          'Emmaus\u2026',
    ),
  ],
};

List<StudyChapter> _genericChapters(BibleBook book) {
  final base = book.about ?? 'Begin reading ${book.title}.';
  return [
    StudyChapter(
      number: 1,
      title: '${book.title} 1',
      preview: base,
      completed: true,
    ),
    StudyChapter(number: 2, title: '${book.title} 2', preview: base),
    StudyChapter(number: 3, title: '${book.title} 3', preview: base),
    StudyChapter(number: 4, title: '${book.title} 4', preview: base),
  ];
}

/// Returns the ordered study path for [book].
List<StudyChapter> chaptersFor(BibleBook book) =>
    _curatedPaths[book.title] ?? _genericChapters(book);
