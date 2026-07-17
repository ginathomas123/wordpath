import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// WordPath visual language: warm paper background, near-black ink, and a
/// serif display face (Playfair Display) paired with a clean sans (Inter).
class AppColors {
  const AppColors._();

  static const paper = Color(0xFFFFFFFF);
  static const paperDim = Color(0xFFEAE5DA);
  static const ink = Color(0xFF1A1815);
  static const inkSoft = Color(0xFF6B6459);
  static const inkFaint = Color(0xFFA79E90);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B4226),
        brightness: Brightness.light,
        surface: AppColors.paper,
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.newsreader(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: GoogleFonts.newsreader(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.newsreader(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.newsreader(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
