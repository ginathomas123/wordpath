import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/fonts.dart';

import '../../app/theme.dart';
import '../../app/widgets/app_icon_button.dart';
import '../../data/bible_data.dart';
import '../../data/read_progress.dart';
import '../../data/study_data.dart';
import '../reader/data/bible_data.dart' as reader;
import '../reader/reader_launch.dart';

/// Finds the reader's canonical book for a reference name, tolerating the
/// singular "Psalm" → "Psalms".
reader.BibleBook? _findReaderBook(String name) {
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
class _StudyEntry {
  const _StudyEntry({
    required this.displayNumber,
    required this.readerBook,
    required this.readerChapter,
    required this.pillLabel,
    required this.title,
    required this.preview,
    required this.seededComplete,
  });

  /// 1-based position in the path (used by the chapter chips).
  final int displayNumber;

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
List<_StudyEntry> buildStudyEntries(BibleBook book) {
  final parts = book.attribution.trim().split(RegExp(r'\s+'));
  final refChapter = parts.length >= 2 ? int.tryParse(parts.last) : null;

  if (refChapter != null) {
    final refName = parts.sublist(0, parts.length - 1).join(' ');
    final rb = _findReaderBook(refName);
    if (rb != null) {
      final available = rb.chapterCount - refChapter + 1;
      final count = available.clamp(1, 4);
      return List.generate(count, (i) {
        final ch = refChapter + i;
        return _StudyEntry(
          displayNumber: i + 1,
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
      _StudyEntry(
        displayNumber: c.number,
        readerBook: book.title,
        readerChapter: c.number,
        pillLabel: '${book.title} ${c.number}',
        title: c.title,
        preview: c.preview,
        seededComplete: c.completed,
      ),
  ];
}

/// The "Path to [book]" study screen reached from a book's Study action: a
/// header, a horizontally scrolling chapter checklist, and a vertical stack of
/// dreamy, soft-focus chapter cards.
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.book});

  final BibleBook book;

  /// A wide pool of atmospheric photos and textures the chapter cards draw
  /// from — nature (dune light, water, clouds, forest, sun, bokeh, topical
  /// moods) plus a few patterns (plaster, concrete, plaid, slate). Each study
  /// starts at a different offset into this pool (see [_imageFor]) so no two
  /// studies look alike.
  static const List<String> _cardImages = [
    'assets/covers/blur_dune.jpg',
    'assets/covers/blur_water.jpg',
    'assets/covers/blur_clouds.jpg',
    'assets/covers/blur_forest.jpg',
    'assets/covers/blur_sun.jpg',
    'assets/covers/blur_gold.jpg',
    'assets/covers/topic_hope.jpg',
    'assets/covers/topic_gratitude.jpg',
    'assets/covers/topic_fear.jpg',
    'assets/covers/topic_anxiety.jpg',
    'assets/covers/topic_marriage.jpg',
    'assets/covers/topic_anger.jpg',
    'assets/covers/uns_plaster.jpg',
    'assets/covers/uns_concrete.jpg',
    'assets/covers/uns_plaid.jpg',
    'assets/covers/uns_blackboard.jpg',
  ];

  /// Deterministic per-study image selection: each book title yields a distinct
  /// starting offset, and chapters step through the pool by a coprime stride so
  /// images stay distinct within a study and the whole set differs per study.
  static String _imageFor(String bookTitle, int chapterIndex) {
    var seed = 0;
    for (final c in bookTitle.codeUnits) {
      seed = (seed * 31 + c) & 0x7fffffff;
    }
    final offset = seed % _cardImages.length;
    final index = (offset + chapterIndex * 3) % _cardImages.length;
    return _cardImages[index];
  }

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  Set<String> _read = {};

  @override
  void initState() {
    super.initState();
    _loadRead();
  }

  Future<void> _loadRead() async {
    final read = await ReadProgress.load();
    if (mounted) setState(() => _read = read);
  }

  /// A card is checked when its real passage has been read (persisted) or it
  /// was seeded complete.
  bool _isRead(_StudyEntry entry) =>
      entry.seededComplete || _read.contains(entry.readKey);

  Future<void> _openEntry(_StudyEntry entry) async {
    await openReader(
      context,
      bookTitle: entry.readerBook,
      chapter: entry.readerChapter,
      immersive: true,
    );
    // Reading marks chapters read — refresh the checkmarks on return.
    _loadRead();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final entries = buildStudyEntries(book);

    return Scaffold(
      backgroundColor: context.palette.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(book: book),
            _PathStrip(entries: entries, isRead: _isRead),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                physics: const BouncingScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _ChapterCard(
                    entry: entry,
                    image: StudyScreen._imageFor(book.title, index),
                    isRead: _isRead(entry),
                    onTap: () => _openEntry(entry),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.book});

  final BibleBook book;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Row(
        children: [
          AppIconButton(
            icon: LucideIcons.chevronLeft,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: AppFonts.serif(
                    color: context.palette.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _todayLabel(),
                  style: AppFonts.sans(
                    color: context.palette.inkSoft,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Overflow ("⋯") menu — hidden for now.
          // AppIconButton(icon: LucideIcons.ellipsis, onPressed: () {}),
        ],
      ),
    );
  }
}

/// The horizontal strip of chapter chips.
class _PathStrip extends StatelessWidget {
  const _PathStrip({required this.entries, required this.isRead});

  final List<_StudyEntry> entries;
  final bool Function(_StudyEntry) isRead;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Center(
            child: _ChapterChip(
              label: 'Ch ${entry.displayNumber}',
              done: isRead(entry),
            ),
          );
        },
      ),
    );
  }
}

/// Today's date, e.g. "Saturday, July 18" — refreshes each day.
String _todayLabel() {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final now = DateTime.now();
  return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
}

class _ChapterChip extends StatelessWidget {
  const _ChapterChip({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: done ? context.palette.paperDim : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? Colors.transparent : context.palette.inkFaint.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            Icon(LucideIcons.check, size: 14, color: context.palette.inkSoft),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppFonts.sans(
              color: done ? context.palette.ink : context.palette.inkSoft,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.entry,
    required this.image,
    required this.isRead,
    required this.onTap,
  });

  final _StudyEntry entry;
  final String image;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tapping a chapter card drops straight into that chapter in the reader's
      // distraction-free immersive mode.
      onTap: onTap,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 236,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover, cacheWidth: 800),
            // Uniform 30% black overlay across the whole card for a consistent,
            // moodier tone regardless of the underlying photo/pattern.
            const ColoredBox(color: Color(0x4D000000)),
            // Legibility scrim, heavier toward the bottom where the text sits.
            // These photos are often bright, so the bottom is nearly opaque.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0x14000000),
                    Color(0xE0000000),
                  ],
                  stops: [0.0, 0.42, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _NumberPill(label: entry.pillLabel.toUpperCase()),
                      const Spacer(),
                      _CardCheckbox(checked: isRead),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    entry.title,
                    style: AppFonts.serif(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.05,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.sans(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _NumberPill extends StatelessWidget {
  const _NumberPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.sans(
          color: AppPalette.light.ink,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CardCheckbox extends StatelessWidget {
  const _CardCheckbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? Colors.white.withValues(alpha: 0.92) : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
      ),
      child: checked
          ? Icon(LucideIcons.check, size: 17, color: AppPalette.light.ink)
          : null,
    );
  }
}

