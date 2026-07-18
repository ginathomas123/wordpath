import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../app/fonts.dart';

import '../../../app/theme.dart';
import '../../../data/bible_data.dart';
import 'book_spine.dart';
import 'intro_item.dart';

/// A titled section: a header row plus a horizontally scrolling row of books
/// standing in a case, fronted by a frosted glass panel that blurs the lower
/// half of each cover (their colors bleed through the frost).
class BookShelf extends StatelessWidget {
  const BookShelf({
    super.key,
    required this.section,
    required this.intro,
    required this.introStart,
    this.onBookTap,
  });

  final BibleSection section;

  /// Shared intro timeline and this section's start fraction within it.
  final Animation<double> intro;
  final double introStart;

  final void Function(BibleBook book, Rect origin)? onBookTap;

  static const double _bookWidth = 118;
  static const double _bookHeight = 176;
  static const double _glassTop = 104;
  static const double _caseHeight = 192;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntroItem(
          animation: intro,
          start: introStart,
          end: introStart + 0.15,
          dy: 12,
          slideCurve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.title,
                    style: AppFonts.sans(
                      color: context.palette.inkSoft,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Text(
                  '${section.books.length} ${section.itemNoun}',
                  style: AppFonts.sans(
                    color: context.palette.inkFaint,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: _caseHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: section.books.length,
                  clipBehavior: Clip.none,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final book = section.books[index];
                    final bookStart = introStart + 0.04 + index * 0.045;
                    return IntroItem(
                      animation: intro,
                      start: bookStart,
                      end: (bookStart + 0.22).clamp(0.0, 1.0),
                      dy: 30,
                      scaleFrom: 0.9,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Builder(
                          builder: (bookContext) => GestureDetector(
                            onTap: onBookTap == null
                                ? null
                                : () {
                                    final box = bookContext.findRenderObject()
                                        as RenderBox?;
                                    if (box == null) return;
                                    final origin =
                                        box.localToGlobal(Offset.zero) &
                                            box.size;
                                    onBookTap!(book, origin);
                                  },
                            behavior: HitTestBehavior.opaque,
                            child: BookSpine(
                              book: book,
                              width: _bookWidth,
                              height: _bookHeight,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                top: _glassTop,
                bottom: 0,
                child: IgnorePointer(
                  child: IntroItem(
                    animation: intro,
                    start: introStart + 0.12,
                    end: introStart + 0.32,
                    dy: 8,
                    scaleFrom: 0.97,
                    slideCurve: Curves.easeOut,
                    child: const _FrostedGlass(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The frosted glass panel that fronts the lower portion of the shelf.
class _FrostedGlass extends StatelessWidget {
  const _FrostedGlass();

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.palette.paper.withValues(alpha: 0.42),
                context.palette.paper.withValues(alpha: 0.20),
                context.palette.paper.withValues(alpha: 0.34),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
            border: Border.all(
              // The white hairline reads much harder against the dark shelf, so
              // pull it back so the glass edge is felt more than seen.
              color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.35),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Top sheen highlight.
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.10 : 0.30),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Little knob on the left.
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.55),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
