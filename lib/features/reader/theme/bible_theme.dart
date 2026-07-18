import 'package:flutter/material.dart';

class BibleColors {
  BibleColors._();

  static const leatherDark    = Color(0xFF2E1206);
  static const leatherMid     = Color(0xFF4A2012);
  static const ivoryPaper     = Color(0xFFF9F7F3);
  static const inkDark        = Color(0xFF1A110A);
  static const inkMid         = Color(0xFF2C1810);
  static const inkLight       = Color(0xFF6B4A32);
  static const ribbonBurgundy = Color(0xFF7A1828);
  static const goldAccent     = Color(0xFFB8956A);
  static const sectionGold    = Color(0xFFA07840);
  static const verseNumber    = Color(0xFFB09070);
  static const divider        = Color(0xFFD8D0BE);

  // Earth tone colors per landmark book abbreviation
  static const Map<String, Color> tabColors = {
    'Gen': Color(0xFFD4AF7A),
    'Exo': Color(0xFFCDB995),
    'Lev': Color(0xFFA85040),
    'Num': Color(0xFF7A4520),
    'Deu': Color(0xFF8B5A30),
    'Jos': Color(0xFF4A3A28),
    'Jdg': Color(0xFFC0A058),
    'Rut': Color(0xFF9B6A38),
    '1Sa': Color(0xFF5A3018),
    '2Sa': Color(0xFF7A4828),
    '1Ki': Color(0xFF8B5530),
    '2Ki': Color(0xFF7A4A28),
    'Psa': Color(0xFF6B3A20),
    'Pro': Color(0xFF4A2810),
    'Isa': Color(0xFF6B3820),
    'Mat': Color(0xFFC4A068),
    'Mar': Color(0xFFB09050),
    'Luk': Color(0xFFC09840),
    'Joh': Color(0xFF8B6040),
    'Act': Color(0xFF6B4020),
    'Rom': Color(0xFF7A3820),
    'Rev': Color(0xFF4A2010),
  };
}
