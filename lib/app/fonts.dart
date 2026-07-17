import 'package:flutter/material.dart';

/// App typography backed by fonts bundled in the app (see `pubspec.yaml`).
///
/// We bundle the fonts instead of fetching them at runtime (as `google_fonts`
/// does) so the serif/sans always render on real devices — a runtime fetch can
/// silently fail offline or behind a proxy and fall back to the system font.
///
/// Both families are variable fonts, so any [FontWeight] is honored from the
/// single bundled file.
class AppFonts {
  const AppFonts._();

  /// Serif display face used for titles/headings.
  static const String serifFamily = 'Newsreader';

  /// Sans face used for body copy, labels, and UI.
  static const String sansFamily = 'Inter';

  static TextStyle serif({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) => TextStyle(
    fontFamily: serifFamily,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    shadows: shadows,
  );

  static TextStyle sans({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) => TextStyle(
    fontFamily: sansFamily,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    shadows: shadows,
  );
}
