import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  });

  final BibleBook book;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final foil = _foilColor(book.tint ?? book.color);

    Widget leather = Image.asset(book.texture, fit: BoxFit.cover);
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
                      style: GoogleFonts.inter(
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
                      style: GoogleFonts.newsreader(
                        color: foil,
                        fontSize: 17,
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
