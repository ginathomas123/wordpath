import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/fonts.dart';

import '../../app/theme.dart';
import '../../app/widgets/app_icon_button.dart';
import '../../data/bible_data.dart';
import '../study/study_circle_screen.dart';
import '../study/study_screen.dart';
import 'widgets/book_spine.dart';

/// Builds the transparent overlay route that animates a tapped [book] from its
/// spot on the shelf ([origin], in global coordinates) to the center of the
/// screen and then swings its front cover open in 3D to reveal the inside page.
Route<void> bookOpenRoute(BibleBook book, Rect origin) {
  return PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 680),
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

        final fly = phase(0.0, 0.5);
        final scrim = phase(0.0, 0.42, Curves.easeOut);
        final open = phase(0.34, 1.0, Curves.easeInOutCubic);
        final chrome = phase(0.8, 1.0, Curves.easeOut);

        final rect = Rect.lerp(origin, target, fly)!;

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
                  open: open,
                  lift: fly,
                ),
              ),
              Positioned(
                top: media.padding.top + 8,
                right: 12,
                child: Opacity(
                  opacity: chrome,
                  child: AppIconButton(
                    icon: LucideIcons.x,
                    background: Colors.white.withValues(alpha: 0.14),
                    foreground: Colors.white,
                    onPressed: () => Navigator.of(context).maybePop(),
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

/// The book itself at its current [rect]: the inside page beneath, with the
/// front cover lifting straight up and dissolving away on top ([open] 0→1).
class _BookStage extends StatelessWidget {
  const _BookStage({
    required this.book,
    required this.open,
    required this.lift,
  });

  final BibleBook book;

  /// 0 = closed (cover down), 1 = open (cover lifted away, page revealed).
  final double open;

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
        // The inside page sits solid underneath and settles in quickly, so the
        // cover reveals a crisp page rather than a muddy cross-fade.
        Positioned.fill(
          child: _InsidePage(book: book, opacity: (open / 0.3).clamp(0.0, 1.0)),
        ),
        // The front cover — a lid that lifts up and off to unveil the page.
        Positioned.fill(child: _LiftCover(book: book, progress: open)),
      ],
    );
  }
}

/// The leather front cover treated as a lid: it drifts straight up, scales up a
/// touch (toward the viewer), and fades out to reveal the page beneath. No side
/// flap, so it never clips and the composition stays centered.
class _LiftCover extends StatelessWidget {
  const _LiftCover({required this.book, required this.progress});

  final BibleBook book;

  /// 0 = fully covering the page, 1 = lifted away and gone.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    if (p >= 1.0) return const SizedBox.shrink();

    // The cover stays solid while it visibly travels up (so you read the lift),
    // then fades out only in the final stretch as it clears the page — a clear
    // "unveil what's underneath" rather than a blur.
    final opacity = 1 - Curves.easeIn.transform(((p - 0.6) / 0.4).clamp(0.0, 1.0));

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: LayoutBuilder(
          builder: (context, c) {
            // Travels up most of its own height and lifts slightly toward the
            // viewer, casting a growing shadow so it reads as a lid coming off.
            return Transform.translate(
              offset: Offset(0, -c.maxHeight * 0.72 * p),
              child: Transform.scale(
                scale: 1 + 0.05 * p,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30 * p),
                        blurRadius: 20 + 30 * p,
                        offset: Offset(0, 10 + 22 * p),
                      ),
                    ],
                  ),
                  child: BookSpine(
                    book: book,
                    width: c.maxWidth,
                    height: c.maxHeight,
                  ),
                ),
              ),
            );
          },
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
                      style: AppFonts.sans(
                        color: AppPalette.light.inkFaint,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.title,
                      style: AppFonts.serif(
                        color: AppPalette.light.ink,
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
                            style: AppFonts.serif(
                              color: AppPalette.light.inkSoft,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        _PageButton(
                          label: 'Study alone',
                          filled: true,
                          fullWidth: true,
                          // Replace the opened-book overlay so backing out of
                          // the Study screen returns to the shelf, not the book.
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => StudyScreen(book: book),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PageButton(
                          label: 'Study with friends',
                          filled: false,
                          fullWidth: true,
                          // Replace the opened-book overlay so backing out of
                          // the circle returns to the shelf, not the book.
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => StudyCircleScreen(book: book),
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
    this.fullWidth = false,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: filled ? AppPalette.light.ink : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: filled
            ? BorderSide.none
            : BorderSide(color: AppPalette.light.ink.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.sans(
              color: filled ? AppPalette.light.paper : AppPalette.light.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
