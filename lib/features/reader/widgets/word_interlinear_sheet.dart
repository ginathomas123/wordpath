import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/fonts.dart';
import '../data/bible_data.dart';
import '../data/interlinear_repository.dart';
import '../data/lexicon.dart';
import '../theme/bible_theme.dart';

/// Opens the reverse-interlinear popover for a tapped English word.
///
/// [wordIndex] is the ordinal of the word within the verse (0-based); it is used
/// to align the displayed word with the KJV+Strong's tag stream.
void showWordInterlinear(
  BuildContext context, {
  required int bookIndex,
  required int chapter,
  required int verse,
  required int wordIndex,
  required String word,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _WordSheet(
      bookIndex: bookIndex,
      chapter: chapter,
      verse: verse,
      wordIndex: wordIndex,
      word: word,
    ),
  );
}

class _WordSheet extends StatefulWidget {
  final int bookIndex;
  final int chapter;
  final int verse;
  final int wordIndex;
  final String word;

  const _WordSheet({
    required this.bookIndex,
    required this.chapter,
    required this.verse,
    required this.wordIndex,
    required this.word,
  });

  @override
  State<_WordSheet> createState() => _WordSheetState();
}

class _WordSheetState extends State<_WordSheet> {
  bool _loading = true;
  LexEntry? _entry;

  bool get _isHebrew => bibleBooks[widget.bookIndex].isOT;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final strong = await InterlinearRepository.strongForWord(
        widget.bookIndex,
        widget.chapter,
        widget.verse,
        widget.wordIndex,
        widget.word,
      );
      LexEntry? entry;
      if (strong != null) {
        entry = await Lexicon.lookup(strong, hebrew: _isHebrew);
      }
      if (mounted) setState(() { _entry = entry; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = '${bibleBooks[widget.bookIndex].name} ${widget.chapter}:${widget.verse}';
    final cleanWord = widget.word.replaceAll(RegExp(r"[^A-Za-z'-]"), '');

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BibleColors.ivoryPaper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BibleColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Tapped English word + reference
              Text(
                cleanWord.isEmpty ? widget.word : cleanWord,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: BibleColors.inkDark,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                ref,
                style: AppFonts.sans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BibleColors.inkLight,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Center(
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: BibleColors.goldAccent),
                    ),
                  ),
                )
              else if (_entry == null)
                _empty()
              else
                _content(_entry!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          'No original-language data for this word.\nHelper words (e.g. “the”, “and”) often have no separate term.',
          style: AppFonts.serif(
            fontSize: 15,
            height: 1.5,
            color: BibleColors.inkLight,
          ),
        ),
      );

  Widget _content(LexEntry e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 0.5, color: BibleColors.divider),
        const SizedBox(height: 18),
        // Original word + Strong's chip
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                e.lemma,
                textDirection: e.isHebrew ? TextDirection.rtl : TextDirection.ltr,
                // No explicit family: let the platform pick a font that covers
                // Hebrew/Greek glyphs (Android's Noto fallback) rather than the
                // Latin-only bundled serif.
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: BibleColors.inkDark,
                  height: 1.15,
                ),
              ),
            ),
            _StrongChip(e.strong),
          ],
        ),
        const SizedBox(height: 8),
        // Transliteration + pronunciation
        Row(
          children: [
            Flexible(
              child: Text(
                e.translit,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  color: BibleColors.inkMid,
                ),
              ),
            ),
            if (e.pron.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                '/${e.pron}/',
                style: AppFonts.sans(fontSize: 13, color: BibleColors.inkLight),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        if (e.derivation.isNotEmpty)
          _field('ORIGIN', _tidy(e.derivation)),
        if (e.definition.isNotEmpty)
          _field('MEANING', _tidy(e.definition)),
        if (e.kjvUsage.isNotEmpty)
          _field('KJV RENDERS IT', _tidy(e.kjvUsage)),
        const SizedBox(height: 14),
        Text(
          'Strong’s Concordance · openscriptures',
          style: AppFonts.sans(
            fontSize: 10,
            color: BibleColors.inkLight.withValues(alpha: 0.6),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.sans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: BibleColors.sectionGold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: AppFonts.serif(
                fontSize: 16,
                height: 1.5,
                color: BibleColors.inkDark,
              ),
            ),
          ],
        ),
      );

  // Strips leading conjunctions/semicolons Strong left in the raw fields.
  String _tidy(String s) {
    var t = s.trim();
    if (t.endsWith(';')) t = t.substring(0, t.length - 1);
    if (t.startsWith('(') && t.contains(')')) {
      // keep parenthetical language notes, they're informative
    }
    return t.trim();
  }
}

class _StrongChip extends StatelessWidget {
  final String strong;
  const _StrongChip(this.strong);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BibleColors.goldAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        strong,
        style: AppFonts.sans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: BibleColors.inkMid,
        ),
      ),
    );
  }
}
