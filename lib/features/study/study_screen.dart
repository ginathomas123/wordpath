import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../data/bible_data.dart';
import '../../data/study_data.dart';

/// The "Path to [book]" study screen reached from a book's Study action: a
/// header, a horizontally scrolling chapter checklist, and a vertical stack of
/// leather chapter cards.
class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key, required this.book});

  final BibleBook book;

  /// Leather textures + tints the chapter cards cycle through for visual rhythm.
  static const List<(String, Color)> _cardStyles = [
    (LeatherTexture.brown, Color(0xFF6B4226)),
    (LeatherTexture.sage, Color(0xFF4F6B4E)),
    (LeatherTexture.indigo, Color(0xFF3E6B8A)),
  ];

  @override
  Widget build(BuildContext context) {
    final chapters = chaptersFor(book);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(book: book),
            _PathStrip(chapters: chapters),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                physics: const BouncingScrollPhysics(),
                itemCount: chapters.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final style = _cardStyles[index % _cardStyles.length];
                  return _ChapterCard(
                    book: book,
                    chapter: chapters[index],
                    texture: style.$1,
                    tint: style.$2,
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
          _CircleButton(
            icon: Icons.chevron_left,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: GoogleFonts.newsreader(
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Path to ${book.title}',
                  style: GoogleFonts.inter(
                    color: AppColors.inkSoft,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _CircleButton(icon: Icons.more_horiz, onTap: () {}),
        ],
      ),
    );
  }
}

/// The "TODAY'S PATH" chapter chips.
class _PathStrip extends StatelessWidget {
  const _PathStrip({required this.chapters});

  final List<StudyChapter> chapters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: chapters.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Center(child: _PathLabel());
          }
          final chapter = chapters[index - 1];
          return Center(child: _ChapterChip(chapter: chapter));
        },
      ),
    );
  }
}

class _PathLabel extends StatelessWidget {
  const _PathLabel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        "TODAY'S PATH",
        style: GoogleFonts.inter(
          color: AppColors.inkSoft,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ChapterChip extends StatelessWidget {
  const _ChapterChip({required this.chapter});

  final StudyChapter chapter;

  @override
  Widget build(BuildContext context) {
    final done = chapter.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFF0E9DC) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? Colors.transparent : AppColors.inkFaint.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            const Icon(Icons.check, size: 14, color: AppColors.inkSoft),
            const SizedBox(width: 4),
          ],
          Text(
            'Ch ${chapter.number}',
            style: GoogleFonts.inter(
              color: done ? AppColors.ink : AppColors.inkSoft,
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
    required this.book,
    required this.chapter,
    required this.texture,
    required this.tint,
  });

  final BibleBook book;
  final StudyChapter chapter;
  final String texture;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 236,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(tint, BlendMode.color),
              child: Image.asset(texture, fit: BoxFit.cover, cacheWidth: 700),
            ),
            // Legibility scrim, heavier toward the bottom where the text sits.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22000000),
                    Color(0x11000000),
                    Color(0xCC000000),
                  ],
                  stops: [0.0, 0.4, 1.0],
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
                      _NumberPill(label: '${book.title} ${chapter.number}'.toUpperCase()),
                      const Spacer(),
                      _CardCheckbox(checked: chapter.completed),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    chapter.title,
                    style: GoogleFonts.newsreader(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.05,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chapter.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
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
        style: GoogleFonts.inter(
          color: AppColors.ink,
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
          ? const Icon(Icons.check, size: 17, color: AppColors.ink)
          : null,
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2EEE6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 22, color: AppColors.ink),
        ),
      ),
    );
  }
}
