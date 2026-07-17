import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible_data.dart';

/// Holds the user's library as mutable state, seeded from [kBibleSections].
///
/// The + menu adds books/topics from [kAddableItems] into the matching shelf.
class LibraryController extends Notifier<List<BibleSection>> {
  @override
  List<BibleSection> build() => [
    for (final section in kBibleSections)
      BibleSection(
        title: section.title,
        itemNoun: section.itemNoun,
        books: List<BibleBook>.of(section.books),
      ),
  ];

  /// Whether a book with [item]'s title already lives on any shelf.
  bool contains(AddableItem item) => state.any(
    (section) => section.books.any((b) => b.title == item.book.title),
  );

  /// Appends [item]'s book to its target section. No-op if already present or
  /// the section is missing.
  void add(AddableItem item) {
    if (contains(item)) return;
    state = [
      for (final section in state)
        if (section.title == item.section)
          BibleSection(
            title: section.title,
            itemNoun: section.itemNoun,
            books: [...section.books, item.book],
          )
        else
          section,
    ];
  }
}

final libraryProvider =
    NotifierProvider<LibraryController, List<BibleSection>>(
      LibraryController.new,
    );

/// The addable items not yet on any shelf — what the + menu should offer.
final availableToAddProvider = Provider<List<AddableItem>>((ref) {
  final sections = ref.watch(libraryProvider);
  final owned = {
    for (final section in sections)
      for (final book in section.books) book.title,
  };
  return [
    for (final item in kAddableItems)
      if (!owned.contains(item.book.title)) item,
  ];
});
