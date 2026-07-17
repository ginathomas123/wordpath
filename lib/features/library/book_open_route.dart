import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../data/bible_data.dart';
import '../study/study_screen.dart';
import 'widgets/book_spine.dart';

/// Builds the transparent overlay route that animates a tapped [book] from its
/// spot on the shelf ([origin], in global coordinates) to the center of the
/// screen and then swings its front cover open in 3D to reveal the inside page.
Route<void> bookOpenRoute(BibleBook book, Rect origin) {
  return PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 700),
    reverseTransitionDuration: const Duration(milliseconds: 560),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _BookOpenScreen(book: book, origin: origin, animation: animation),
  );
}

/// The deep focus backdrop the library dims to (matches the inspiration).
const Color _kBackdrop = Color(0xFF23293D);

class _BookOpenScreen extends StatelessWidget {
  const _BookOpenScreen({
    required this.book,
    required this.origin,
    required this.animation,
  });

  final BibleBook book;
  final Rect origin;
  final Animation<double> animation;

  /// How far the front cover swings open, in radians (~155°).
  static const double _maxCoverAngle = 2.70;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final aspect = origin.width / origin.height;

    // Enlarged, centered resting place for the book.
    final targetW = math.min(size.width * 0.64, 300.0);
    final targetH = targetW / aspect;
    final target = Rect.fromLTWH(
      (size.width - targetW) / 2,
      (size.height - targetH) / 2 - 24,
      targetW,
      targetH,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;

        double phase(double a, double b, [Curve c = Curves.easeOutCubic]) =>
            c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

        final fly = phase(0.0, 0.55);
        final scrim = phase(0.0, 0.45, Curves.easeOut);
        final cover = phase(0.48, 1.0, Curves.easeInOutCubic);
        final chrome = phase(0.75, 1.0, Curves.easeOut);

        final rect = Rect.lerp(origin, target, fly)!;
        final angle = cover * _maxCoverAngle;

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: ColoredBox(
                    color: _kBackdrop.withValues(alpha: 0.94 * scrim),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: rect,
                child: _BookStage(
                  book: book,
                  coverAngle: angle,
                  contentOpacity: cover,
                  lift: fly,
                ),
              ),
              Positioned(
                top: media.padding.top + 8,
                right: 12,
                child: Opacity(
                  opacity: chrome,
                  child: _CircleIcon(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The book itself at its current [rect]: a revealed inside page with the front
/// cover hinged on the spine ([coverAngle] radians) swinging open on top.
class _BookStage extends StatelessWidget {
  const _BookStage({
    required this.book,
    required this.coverAngle,
    required this.contentOpacity,
    required this.lift,
  });

  final BibleBook book;
  final double coverAngle;

  /// 0 while closed, 1 when fully open — drives the inside page reveal.
  final double contentOpacity;

  /// 0 on the shelf, 1 at center — grows the drop shadow as the book lifts.
  final double lift;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Growing contact shadow beneath the lifted book.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10 + 0.35 * lift),
                  blurRadius: 24 + 34 * lift,
                  offset: Offset(0, 14 + 26 * lift),
                ),
              ],
            ),
          ),
        ),
        // The inside page revealed as the cover swings away.
        Positioned.fill(child: _InsidePage(book: book, opacity: contentOpacity)),
        // The hinged front cover.
        Positioned.fill(
          child: _HingedCover(book: book, angle: coverAngle),
        ),
      ],
    );
  }
}

/// The leather front cover, hinged on its left (spine) edge. Past 90° it shows a
/// parchment endpaper back-face so it reads like a real opening cover.
class _HingedCover extends StatelessWidget {
  const _HingedCover({required this.book, required this.angle});

  final BibleBook book;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final showBack = angle > math.pi / 2;

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..rotateY(-angle);

    return Transform(
      alignment: Alignment.centerLeft,
      transform: transform,
      child: showBack
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: const _Endpaper(),
            )
          : LayoutBuilder(
              builder: (context, c) => BookSpine(
                book: book,
                width: c.maxWidth,
                height: c.maxHeight,
              ),
            ),
    );
  }
}

/// The inside of the front cover (shown once it has swung past vertical).
class _Endpaper extends StatelessWidget {
  const _Endpaper();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Color(0xFFF3ECDD), Color(0xFFE7DDC6)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.black.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The first page revealed under the cover: title, attribution, blurb and the
/// primary reading actions.
class _InsidePage extends StatelessWidget {
  const _InsidePage({required this.book, required this.opacity});

  final BibleBook book;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final about = book.about ??
        'A book of the Holy Bible, traditionally attributed to '
            '${book.attribution}. Tap read to begin.';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFBF7EE), Color(0xFFF3ECDD)],
          ),
        ),
        child: Stack(
          children: [
            // Spine crease shadow on the left where the pages bind.
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: opacity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 30, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.attribution.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppColors.inkFaint,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.title,
                      style: GoogleFonts.newsreader(
                        color: AppColors.ink,
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.88, 1.0],
                        ).createShader(rect),
                        blendMode: BlendMode.dstIn,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            about,
                            style: GoogleFonts.newsreader(
                              color: AppColors.inkSoft,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _PageButton(
                          label: 'Read',
                          filled: true,
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        _PageButton(
                          label: 'Study',
                          filled: false,
                          // Replace the opened-book overlay so backing out of
                          // the Study screen returns to the shelf, not the book.
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => StudyScreen(book: book),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.ink : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: filled
            ? BorderSide.none
            : BorderSide(color: AppColors.ink.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: filled ? AppColors.paper : AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
