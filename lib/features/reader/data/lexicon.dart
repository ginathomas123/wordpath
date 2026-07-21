import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// A single Strong's lexicon entry (original word + gloss).
///
/// Source: openscriptures/strongs — James Strong's Hebrew & Greek dictionaries
/// (public-domain text, JSON edition CC BY-SA). Bundled as an asset so word
/// look-ups are instant and work offline.
class LexEntry {
  final String strong; // e.g. "H1254" / "G26"
  final String lemma; // original-language word (Hebrew/Greek script)
  final String translit; // transliteration
  final String pron; // pronunciation
  final String definition; // Strong's definition
  final String kjvUsage; // how the KJV renders it
  final String derivation; // etymology / part-of-speech hints
  final bool isHebrew;

  const LexEntry({
    required this.strong,
    required this.lemma,
    required this.translit,
    required this.pron,
    required this.definition,
    required this.kjvUsage,
    required this.derivation,
    required this.isHebrew,
  });
}

class Lexicon {
  Lexicon._();

  static Map<String, dynamic>? _hebrew;
  static Map<String, dynamic>? _greek;

  static Future<void> _ensureLoaded(bool hebrew) async {
    if (hebrew) {
      if (_hebrew != null) return;
      final raw = await rootBundle.loadString('assets/lexicon/strongs_hebrew.json');
      _hebrew = jsonDecode(raw) as Map<String, dynamic>;
    } else {
      if (_greek != null) return;
      final raw = await rootBundle.loadString('assets/lexicon/strongs_greek.json');
      _greek = jsonDecode(raw) as Map<String, dynamic>;
    }
  }

  /// Look up a bare Strong's [number] in the Hebrew (OT) or Greek (NT) dictionary.
  static Future<LexEntry?> lookup(int number, {required bool hebrew}) async {
    await _ensureLoaded(hebrew);
    final map = hebrew ? _hebrew : _greek;
    final e = map?[number.toString()];
    if (e is! Map) return null;
    return LexEntry(
      strong: '${hebrew ? 'H' : 'G'}$number',
      lemma: (e['w'] ?? '') as String,
      translit: (e['t'] ?? '') as String,
      pron: (e['p'] ?? '') as String,
      definition: (e['d'] ?? '') as String,
      kjvUsage: (e['k'] ?? '') as String,
      derivation: (e['r'] ?? '') as String,
      isHebrew: hebrew,
    );
  }
}
