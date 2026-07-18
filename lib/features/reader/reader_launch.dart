import 'package:flutter/material.dart';

import 'data/bible_data.dart' as reader;
import 'screens/reading_screen.dart';

/// Opens the bundled Bible reader.
///
/// When [bookTitle] matches one of the canonical books (e.g. "Genesis"), the
/// reader opens directly at that book; otherwise it falls back to Genesis.
/// [chapter] jumps straight to a chapter (defaults to 1). Pass [immersive] to
/// land in the distraction-free reading mode (chrome hidden) — used when
/// tapping a specific chapter card. Pass [replace] when launching from a
/// transient overlay (like the opened-book animation) so backing out returns to
/// the shelf rather than the overlay.
Future<void> openReader(
  BuildContext context, {
  String? bookTitle,
  int chapter = 1,
  bool immersive = false,
  bool replace = false,
}) {
  final route = _readerRoute(
    _bookIndexForTitle(bookTitle),
    chapter: chapter,
    immersive: immersive,
  );
  final navigator = Navigator.of(context);
  if (replace) {
    return navigator.pushReplacement(route);
  }
  return navigator.push(route);
}

/// A soft cross-fade with a gentle scale-up so the reader emerges from the
/// opened book instead of sliding in from the edge — the page you opened settles
/// into the reading surface. Mirrored (fade + slight scale-down) on the way out.
Route<void> _readerRoute(int bookIndex, {int chapter = 1, bool immersive = false}) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 440),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) => ReadingScreen(
      initialBookIndex: bookIndex,
      initialChapter: chapter,
      initialImmersive: immersive,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.965, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Resolves a WordPath book title to an index into the reader's [reader.bibleBooks].
/// Returns 0 (Genesis) when there's no exact name match — e.g. topical cards.
int _bookIndexForTitle(String? title) {
  if (title == null) return 0;
  final needle = title.trim().toLowerCase();
  final index = reader.bibleBooks.indexWhere(
    (b) => b.name.toLowerCase() == needle,
  );
  return index < 0 ? 0 : index;
}
