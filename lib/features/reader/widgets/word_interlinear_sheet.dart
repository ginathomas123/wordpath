import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/fonts.dart';
import '../data/bible_data.dart';
import '../data/interlinear_repository.dart';
import '../data/lexicon.dart';
import '../maps/bible_atlas_screen.dart';
import '../maps/bible_map_data.dart';
import '../theme/bible_theme.dart';

/// Matches the reader's word tokenization so word indices line up with
/// [wordAtOffset] in the reading screen.
final RegExp _wordToken = RegExp(r"[A-Za-z][A-Za-z'\-]*");

/// Opens the reverse-interlinear popover for a tapped English word. The phrase
/// can then be extended left/right with the ‹ / › controls to reveal the
/// original-language words behind a multi-word span.
///
/// [wordIndex] is the ordinal of the tapped word within the verse (0-based);
/// [verseText] is the full verse so the sheet can walk to neighboring words.
void showWordInterlinear(
  BuildContext context, {
  required int bookIndex,
  required int chapter,
  required int verse,
  required int wordIndex,
  required String word,
  required String verseText,
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
      verseText: verseText,
    ),
  );
}

class _WordSheet extends StatefulWidget {
  final int bookIndex;
  final int chapter;
  final int verse;
  final int wordIndex;
  final String verseText;

  const _WordSheet({
    required this.bookIndex,
    required this.chapter,
    required this.verse,
    required this.wordIndex,
    required this.verseText,
  });

  @override
  State<_WordSheet> createState() => _WordSheetState();
}

class _WordSheetState extends State<_WordSheet> {
  late final List<String> _words =
      _wordToken.allMatches(widget.verseText).map((m) => m.group(0)!).toList();

  late int _start = widget.wordIndex.clamp(0, _words.isEmpty ? 0 : _words.length - 1);
  late int _end = _start;

  bool _loading = true;
  List<LexEntry> _entries = [];
  int _reqId = 0;

  bool get _isHebrew => bibleBooks[widget.bookIndex].isOT;
  bool get _canExtendLeft => _start > 0;
  bool get _canExtendRight => _end < _words.length - 1;
  bool get _isPhrase => _end > _start;

  String get _phrase =>
      _words.isEmpty ? '' : _words.sublist(_start, _end + 1).join(' ');

  @override
  void initState() {
    super.initState();
    _resolve();
    // Usually already preloaded by the reader; rebuild if it lands mid-sheet.
    BibleGeo.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// The place matched by the currently selected word/phrase, if any.
  /// [BibleGeo.match] is null-safe before the atlas loads; [_geoReady] just
  /// forces a rebuild once it has (in case the sheet opened mid-load).
  MapPlace? get _place => BibleGeo.match(_words.sublist(_start, _end + 1));

  void _openMap(MapPlace place) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BibleAtlasScreen(focus: place),
    ));
  }

  Future<void> _resolve() async {
    final req = ++_reqId;
    setState(() => _loading = true);
    try {
      final strongs = await InterlinearRepository.strongsForRange(
        widget.bookIndex,
        widget.chapter,
        widget.verse,
        _start,
        _end,
        _words,
      );
      final entries = <LexEntry>[];
      for (final s in strongs) {
        final e = await Lexicon.lookup(s, hebrew: _isHebrew);
        if (e != null) entries.add(e);
      }
      if (mounted && req == _reqId) {
        setState(() { _entries = entries; _loading = false; });
      }
    } catch (_) {
      if (mounted && req == _reqId) setState(() { _loading = false; });
    }
  }

  void _extendLeft() {
    if (!_canExtendLeft) return;
    setState(() => _start--);
    _resolve();
  }

  void _extendRight() {
    if (!_canExtendRight) return;
    setState(() => _end++);
    _resolve();
  }

  void _reset() {
    setState(() { _start = widget.wordIndex; _end = widget.wordIndex; });
    _resolve();
  }

  @override
  Widget build(BuildContext context) {
    final ref =
        '${bibleBooks[widget.bookIndex].name} ${widget.chapter}:${widget.verse}';
    final maxH = MediaQuery.of(context).size.height * 0.82;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BibleColors.ivoryPaper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                _phraseHeader(),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      ref,
                      style: AppFonts.sans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: BibleColors.inkLight,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (_isPhrase) ...[
                      Text('  ·  ',
                          style: AppFonts.sans(
                              fontSize: 12, color: BibleColors.inkLight)),
                      GestureDetector(
                        onTap: _reset,
                        child: Text(
                          'Reset',
                          style: AppFonts.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: BibleColors.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_place != null) ...[
                  const SizedBox(height: 14),
                  _MapChip(place: _place!, onTap: () => _openMap(_place!)),
                ],
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: _body(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The selected English phrase flanked by extend controls.
  Widget _phraseHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ExtendButton(
          icon: Icons.chevron_left,
          enabled: _canExtendLeft,
          onTap: _extendLeft,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _phrase,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: _isPhrase ? 24 : 30,
              fontWeight: FontWeight.w600,
              color: BibleColors.inkDark,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _ExtendButton(
          icon: Icons.chevron_right,
          enabled: _canExtendRight,
          onTap: _extendRight,
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: BibleColors.goldAccent),
          ),
        ),
      );
    }
    if (_entries.isEmpty) return _empty();
    if (_entries.length == 1) return _single(_entries.first);
    return _multi(_entries);
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          _isPhrase
              ? 'No original-language terms for this phrase.\nTry extending to include a content word.'
              : 'No original-language data for this word.\nHelper words (e.g. “the”, “and”) often have no separate term.',
          style: AppFonts.serif(
            fontSize: 15,
            height: 1.5,
            color: BibleColors.inkLight,
          ),
        ),
      );

  /// Detailed layout for a single original word.
  Widget _single(LexEntry e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 0.5, color: BibleColors.divider),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                e.lemma,
                textDirection:
                    e.isHebrew ? TextDirection.rtl : TextDirection.ltr,
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
        if (e.derivation.isNotEmpty) _field('ORIGIN', _tidy(e.derivation)),
        if (e.definition.isNotEmpty) _field('MEANING', _tidy(e.definition)),
        if (e.kjvUsage.isNotEmpty) _field('KJV RENDERS IT', _tidy(e.kjvUsage)),
        const SizedBox(height: 14),
        _credit(),
      ],
    );
  }

  /// Compact ordered list of the original words behind a multi-word phrase.
  Widget _multi(List<LexEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 0.5, color: BibleColors.divider),
        const SizedBox(height: 6),
        Text(
          '${entries.length} original words · in reading order',
          style: AppFonts.sans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: BibleColors.inkLight,
          ),
        ),
        const SizedBox(height: 4),
        for (final e in entries) _TermRow(entry: e),
        const SizedBox(height: 12),
        _credit(),
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

  Widget _credit() => Text(
        'Strong’s Concordance · openscriptures',
        style: AppFonts.sans(
          fontSize: 10,
          color: BibleColors.inkLight.withValues(alpha: 0.6),
          letterSpacing: 0.3,
        ),
      );

  String _tidy(String s) {
    var t = s.trim();
    if (t.endsWith(';')) t = t.substring(0, t.length - 1);
    return t.trim();
  }
}

/// One original word inside the multi-word phrase view.
class _TermRow extends StatelessWidget {
  final LexEntry entry;
  const _TermRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  e.lemma,
                  textDirection:
                      e.isHebrew ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: BibleColors.inkDark,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (e.translit.isNotEmpty)
                Flexible(
                  child: Text(
                    e.translit,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      color: BibleColors.inkMid,
                    ),
                  ),
                ),
              const Spacer(),
              _StrongChip(e.strong),
            ],
          ),
          if (e.definition.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _shorten(e.definition),
              style: AppFonts.serif(
                fontSize: 15,
                height: 1.45,
                color: BibleColors.inkDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _shorten(String s) {
    var t = s.trim();
    if (t.endsWith(';')) t = t.substring(0, t.length - 1);
    return t.trim();
  }
}

class _ExtendButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _ExtendButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? BibleColors.goldAccent.withValues(alpha: 0.14)
              : BibleColors.divider.withValues(alpha: 0.35),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? BibleColors.inkMid : BibleColors.inkLight.withValues(alpha: 0.4),
        ),
      ),
    );
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

/// "View on map" affordance shown when the selected word is a known place.
class _MapChip extends StatelessWidget {
  final MapPlace place;
  final VoidCallback onTap;
  const _MapChip({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: BibleColors.ribbonBurgundy.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.mapPin,
                size: 17, color: BibleColors.ribbonBurgundy),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'View ${place.name} on map',
                style: AppFonts.sans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BibleColors.inkDark,
                ),
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: BibleColors.inkLight),
          ],
        ),
      ),
    );
  }
}
