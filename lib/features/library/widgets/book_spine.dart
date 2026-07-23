import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/fonts.dart';

import '../../../data/bible_data.dart';

/// A single leather-bound book cover built from a real Unsplash leather photo.
/// When [BibleBook.tint] is set, the leather is recolored via a hue blend so a
/// single texture can present as different colored leather while keeping grain.
class BookSpine extends StatelessWidget {
  const BookSpine({
    super.key,
    required this.book,
    this.width = 118,
    this.height = 176,
    this.isMastered = false,
  });

  final BibleBook book;
  final double width;
  final double height;

  /// When true, the study for this book is fully complete — the cover earns a
  /// small gold "mastered" seal in the top corner.
  final bool isMastered;

  @override
  Widget build(BuildContext context) {
    final foil = _foilColor(book.tint ?? book.color);

    // Cap the decoded bitmap size: the source leather photos are multi-megapixel
    // but never render wider than the enlarged (opened) cover, so decoding them
    // full-res just wastes GPU memory and causes jank on the emulator.
    Widget leather = Image.asset(
      book.texture,
      fit: BoxFit.cover,
      cacheWidth: 700,
    );
    if (book.tint != null) {
      leather = ColorFiltered(
        colorFilter: ColorFilter.mode(book.tint!, BlendMode.color),
        child: leather,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              leather,
              // Legibility scrim: darken the top where the text sits.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.34),
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.10),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Spine shadow on the left edge.
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 13, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.attribution.toUpperCase(),
                      style: AppFonts.sans(
                        color: foil.withValues(alpha: 0.78),
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.title,
                      maxLines: 3,
                      style: AppFonts.serif(
                        color: Colors.white,
                        fontSize: 18.7,
                        height: 1.02,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Gold "study complete" seal, kept in the top corner clear of the
              // frosted-glass strip so it always reads.
              if (isMastered)
                const Positioned(top: 9, right: 9, child: _MasterySeal()),
            ],
          ),
        ),
      ),
    );
  }

  /// Gold-ish foil for dark covers, cream for lighter ones.
  Color _foilColor(Color base) {
    final luminance = base.computeLuminance();
    return luminance < 0.4
        ? const Color(0xFFEBDCB0)
        : const Color(0xFFF7F2E7);
  }
}

/// A small gold wax-seal medallion that pops (scale + fade) with a brief shine
/// the first time it appears on a completed book cover.
class _MasterySeal extends StatefulWidget {
  const _MasterySeal();

  @override
  State<_MasterySeal> createState() => _MasterySealState();
}

class _MasterySealState extends State<_MasterySeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const double _size = 26;

  @override
  Widget build(BuildContext context) {
    // Pop the medallion in, then let a soft shine ring bloom out behind it.
    final pop = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.62, curve: Curves.easeOutBack),
    );
    final fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
    );
    final shine = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Shine ring blooming outward and fading.
              Opacity(
                opacity: (1 - shine.value) * 0.6,
                child: Transform.scale(
                  scale: 1 + shine.value * 0.9,
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF6E3A6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: fade.value.clamp(0.0, 1.0),
                child: Transform.scale(scale: pop.value, child: child),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7DE93), Color(0xFFD9A83E), Color(0xFFB07E22)],
            stops: [0.0, 0.55, 1.0],
          ),
          border: Border.all(color: const Color(0xFFFBEFC4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(LucideIcons.check, size: 15, color: Colors.white),
      ),
    );
  }
}
