import 'package:flutter/material.dart';

import 'fonts.dart';

/// WordPath visual language: a warm paper/ink light palette and a deep charcoal
/// dark palette (#292827 background, white text), served through [AppPalette].
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.paper,
    required this.paperDim,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
  });

  final Brightness brightness;

  /// Primary background.
  final Color paper;

  /// Slightly recessed surface (chips, wells).
  final Color paperDim;

  /// Primary text/icon color.
  final Color ink;

  /// Secondary text.
  final Color inkSoft;

  /// Tertiary / faint text.
  final Color inkFaint;

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette(
    brightness: Brightness.light,
    paper: Color(0xFFFFFFFF),
    paperDim: Color(0xFFEAE5DA),
    ink: Color(0xFF1A1815),
    inkSoft: Color(0xFF6B6459),
    inkFaint: Color(0xFFA79E90),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    paper: Color(0xFF292827),
    paperDim: Color(0xFF34322F),
    ink: Color(0xFFFFFFFF),
    inkSoft: Color(0xFFBDB7AC),
    inkFaint: Color(0xFF7E786E),
  );
}

/// Resolves the active [AppPalette] from the ambient theme brightness, so
/// widgets can read `context.palette.ink` and follow light/dark automatically.
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B4226),
        brightness: p.brightness,
        surface: p.paper,
      ),
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: AppFonts.sansFamily,
          bodyColor: p.ink,
          displayColor: p.ink,
        )
        .copyWith(
          displayLarge: AppFonts.serif(color: p.ink, fontWeight: FontWeight.w600),
          displayMedium: AppFonts.serif(
            color: p.ink,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: AppFonts.serif(
            color: p.ink,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: AppFonts.serif(color: p.ink, fontWeight: FontWeight.w600),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
