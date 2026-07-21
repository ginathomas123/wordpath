import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/fonts.dart';
import '../../../app/widgets/app_icon_button.dart';
import '../../../data/home_widget_service.dart';
import '../../../data/read_progress.dart';
import '../data/bible_data.dart';
import '../data/bible_repository.dart';
import '../data/highlight_data.dart';
import '../data/section_data.dart';
import '../theme/bible_theme.dart';
import '../widgets/book_tab_rail.dart';
import '../widgets/book_list_panel.dart';
import '../widgets/word_interlinear_sheet.dart';

/// Locates the word at a character [offset] within [text], returning its
/// 0-based word ordinal and the raw word. Used to map a tapped character to a
/// word for the reverse-interlinear popover.
(int, String)? wordAtOffset(String text, int offset) {
  final matches = RegExp(r"[A-Za-z][A-Za-z'\-]*").allMatches(text).toList();
  if (matches.isEmpty) return null;
  for (int i = 0; i < matches.length; i++) {
    final m = matches[i];
    if (offset >= m.start && offset <= m.end) return (i, m.group(0)!);
  }
  // Nearest word if the tap landed on punctuation/whitespace.
  int best = 0, bestDist = 1 << 30;
  for (int i = 0; i < matches.length; i++) {
    final m = matches[i];
    final d = offset < m.start ? m.start - offset : offset - m.end;
    if (d < bestDist) { bestDist = d; best = i; }
  }
  return (best, matches[best].group(0)!);
}

/// Clean white reading surface.
const _paper = Color(0xFFFFFFFF);

class ReadingScreen extends StatefulWidget {
  final int initialBookIndex;
  final int initialChapter;

  /// Start in distraction-free reading mode (chrome hidden). Used when a
  /// specific chapter card is tapped so the reader opens straight into scripture.
  final bool initialImmersive;

  const ReadingScreen({
    super.key,
    this.initialBookIndex = 0,
    this.initialChapter = 1,
    this.initialImmersive = false,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> with TickerProviderStateMixin {
  late int _bookIndex;
  late int _chapter;
  bool _showBookPanel = false;
  bool _immersive = false;

  // 3-page sliding window: prev | curr | next
  ChapterContent? _prevContent, _currContent, _nextContent;
  int _prevBookIdx = 0, _prevChap = 1;
  int _nextBookIdx = 0, _nextChap = 1;
  bool _loading = true;
  String? _error;

  List<HighlightEntry> _highlights = [];
  late final PageController _pagCtrl;

  // One-time coach hint teaching the press-and-drag highlight gesture.
  bool _showHighlightHint = false;

  // Marks the current chapter read after a brief dwell (so quick swipe-throughs
  // don't count as "read").
  Timer? _readTimer;

  // bookmark ribbon — persisted, null = no bookmark set
  int? _bmkBookIdx, _bmkChap;

  // ── adjacent-chapter helpers ───────────────────────────────────────────────

  (int, int) get _prevBC {
    if (_chapter > 1) return (_bookIndex, _chapter - 1);
    if (_bookIndex > 0) return (_bookIndex - 1, bibleBooks[_bookIndex - 1].chapterCount);
    return (_bookIndex, _chapter);
  }

  (int, int) get _nextBC {
    if (_chapter < bibleBooks[_bookIndex].chapterCount) return (_bookIndex, _chapter + 1);
    if (_bookIndex < bibleBooks.length - 1) return (_bookIndex + 1, 1);
    return (_bookIndex, _chapter);
  }

  bool get _hasPrev {
    final (b, c) = _prevBC;
    return b != _bookIndex || c != _chapter;
  }

  bool get _hasNext {
    final (b, c) = _nextBC;
    return b != _bookIndex || c != _chapter;
  }

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _bookIndex = widget.initialBookIndex;
    _chapter = widget.initialChapter;
    _immersive = widget.initialImmersive;
    _pagCtrl = PageController(initialPage: 1);
    _load();
    _loadHighlights();
    _loadBookmark();
    _maybeShowHighlightHint();
  }

  /// Show the highlight coaching hint once ever, shortly after the reader opens.
  Future<void> _maybeShowHighlightHint() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seenHighlightHint') ?? false) return;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _showHighlightHint = true);
    await prefs.setBool('seenHighlightHint', true);
  }

  void _dismissHighlightHint() {
    if (_showHighlightHint) setState(() => _showHighlightHint = false);
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    _pagCtrl.dispose();
    super.dispose();
  }

  /// After the reader lingers on a chapter for a few seconds, record it as read
  /// so the study path can show a checkmark.
  void _scheduleMarkRead() {
    _readTimer?.cancel();
    final book = bibleBooks[_bookIndex].name;
    final chapter = _chapter;
    _readTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (bibleBooks[_bookIndex].name == book && _chapter == chapter) {
        ReadProgress.mark(book, chapter);
      }
    });
  }

  // ── bookmark ───────────────────────────────────────────────────────────────

  bool get _onBookmarkedChapter =>
      _bmkBookIdx == _bookIndex && _bmkChap == _chapter;

  void _toggleBookmark() {
    if (_onBookmarkedChapter) {
      setState(() { _bmkBookIdx = null; _bmkChap = null; });
      _saveBookmark(null, null);
    } else {
      // Set bookmark — persists until explicitly removed
      setState(() { _bmkBookIdx = _bookIndex; _bmkChap = _chapter; });
      _saveBookmark(_bookIndex, _chapter);
    }
  }

  Future<void> _saveBookmark(int? book, int? chap) async {
    final prefs = await SharedPreferences.getInstance();
    if (book == null || chap == null) {
      await prefs.remove('bmk_book');
      await prefs.remove('bmk_chap');
    } else {
      await prefs.setInt('bmk_book', book);
      await prefs.setInt('bmk_chap', chap);
    }
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getInt('bmk_book');
    final c = prefs.getInt('bmk_chap');
    if (b != null && c != null && mounted) {
      setState(() { _bmkBookIdx = b; _bmkChap = c; });
    }
  }

  // ── data loading ───────────────────────────────────────────────────────────

  Future<void> _loadHighlights() async {
    final h = await loadHighlights();
    if (mounted) setState(() => _highlights = h);
  }

  void _addHighlight(HighlightEntry entry) {
    final updated = [..._highlights, entry];
    setState(() => _highlights = updated);
    saveHighlights(updated);
  }

  void _removeHighlightsOverlapping(int verseNumber, int start, int end) {
    final updated = _highlights.where((h) =>
      !(h.bookIndex == _bookIndex && h.chapter == _chapter &&
        h.verseNumber == verseNumber && h.start < end && h.end > start)
    ).toList();
    setState(() => _highlights = updated);
    saveHighlights(updated);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _currContent = null; });
    try {
      final content = await BibleRepository.fetchChapter(
          bibleBooks[_bookIndex].chapterUrl(_chapter));
      if (!mounted) return;
      setState(() { _currContent = content; _loading = false; });
      _persist();
      _loadNeighbors();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _loadNeighbors() {
    final (pb, pc) = _prevBC;
    final (nb, nc) = _nextBC;
    _prevBookIdx = pb; _prevChap = pc;
    _nextBookIdx = nb; _nextChap = nc;
    setState(() { _prevContent = null; _nextContent = null; });

    if (_hasPrev) {
      BibleRepository.fetchChapter(bibleBooks[pb].chapterUrl(pc))
          .then((c) { if (mounted) setState(() => _prevContent = c); })
          .catchError((_) {});
    }
    if (_hasNext) {
      BibleRepository.fetchChapter(bibleBooks[nb].chapterUrl(nc))
          .then((c) { if (mounted) setState(() => _nextContent = c); })
          .catchError((_) {});
    }
  }

  Future<void> _persist() async {
    _scheduleMarkRead();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastBookIndex', _bookIndex);
    await prefs.setInt('lastChapter', _chapter);
    // Keep the home-screen widget's "continue reading" card in sync.
    HomeWidgetService.update(_bookIndex, _chapter);
  }

  // ── navigation ─────────────────────────────────────────────────────────────

  void _go(int bookIndex, int chapter) {
    setState(() {
      _bookIndex = bookIndex;
      _chapter = chapter;
      _showBookPanel = false;
      _prevContent = null;
      _nextContent = null;
    });
    _load();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _pagCtrl.jumpToPage(1));
  }

  void _onPageSettled(int index) {
    if (index == 1) return;

    if (index == 0 && _hasPrev && _prevContent != null) {
      HapticFeedback.lightImpact();
      final saved = _prevContent!;
      setState(() {
        _nextContent = _currContent;
        _nextBookIdx = _bookIndex; _nextChap = _chapter;
        _currContent = saved;
        _bookIndex = _prevBookIdx; _chapter = _prevChap;
        _prevContent = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pagCtrl.jumpToPage(1);
      });
      _persist();
      _loadNeighbors();
    } else if (index == 2 && _hasNext && _nextContent != null) {
      HapticFeedback.lightImpact();
      final saved = _nextContent!;
      setState(() {
        _prevContent = _currContent;
        _prevBookIdx = _bookIndex; _prevChap = _chapter;
        _currContent = saved;
        _bookIndex = _nextBookIdx; _chapter = _nextChap;
        _nextContent = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pagCtrl.jumpToPage(1);
      });
      _persist();
      _loadNeighbors();
    } else {
      // Not loaded yet or at Bible boundary — snap back to center
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          _pagCtrl.animateToPage(
            1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          ));
    }
  }

  String get _prevLabel {
    if (!_hasPrev) return '';
    final (b, c) = _prevBC;
    if (b != _bookIndex) return '< ${bibleBooks[b].name}';
    return '< Chapter $c';
  }

  String get _nextLabel {
    if (!_hasNext) return '';
    final (b, c) = _nextBC;
    if (b != _bookIndex) return '${bibleBooks[b].name} >';
    return 'Chapter $c >';
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _paper,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor: _paper,
      body: Stack(
        children: [
          // White background behind the status-bar + top gap
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).padding.top + 10,
            child: const ColoredBox(color: _paper),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Reading card — PageView with 3-chapter buffer
                  Expanded(
                    child: Container(
                      color: _paper,
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                if (_loading)
                                  const Center(
                                    child: SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: BibleColors.goldAccent,
                                      ),
                                    ),
                                  )
                                else if (_error != null)
                                  Center(
                                    child: GestureDetector(
                                      onTap: _load,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Could not load scripture.\nCheck your connection.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.cormorantGaramond(
                                              fontSize: 15,
                                              color: BibleColors.inkLight,
                                              height: 1.8,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Tap to retry',
                                            style: GoogleFonts.cormorantGaramond(
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                              color: BibleColors.goldAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  PageView(
                                    controller: _pagCtrl,
                                    onPageChanged: _onPageSettled,
                                    children: [
                                      _buildPage(_prevBookIdx, _prevChap, _prevContent),
                                      _buildPage(_bookIndex, _chapter, _currContent),
                                      _buildPage(_nextBookIdx, _nextChap, _nextContent),
                                    ],
                                  ),
                                // Page-curl overlay
                                if (!_loading && _error == null)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: _PageCurlPainter(_pagCtrl),
                                      ),
                                    ),
                                  ),
                                // Double-tap overlay — translucent so gestures pass through
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onDoubleTap: () =>
                                        setState(() => _immersive = !_immersive),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ChapterNavBar(
                            prevLabel: _prevLabel,
                            nextLabel: _nextLabel,
                            onPrev: _hasPrev ? () { final (b,c)=_prevBC; _go(b,c); } : null,
                            onNext: _hasNext ? () { final (b,c)=_nextBC; _go(b,c); } : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab rail — slides away in immersive mode
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    clipBehavior: Clip.hardEdge,
                    child: _immersive
                        ? const SizedBox()
                        : BookTabRail(
                            currentBookIndex: _bookIndex,
                            onBookTapped: (i) {
                              if (i == _bookIndex) {
                                setState(() => _showBookPanel = !_showBookPanel);
                              } else {
                                _go(i, 1);
                              }
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Back arrow — top-left, always present (even in immersive reading)
          // so the reader is never a dead end. Softens in immersive mode to keep
          // the page calm, but stays tappable.
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 8,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              opacity: _immersive ? 0.55 : 1,
              child: AppIconButton(
                icon: LucideIcons.arrowLeft,
                tooltip: 'Back',
                background: const Color(0xFFEAE6DE),
                foreground: BibleColors.inkMid,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),

          // One-time coach hint: teaches press-and-drag to highlight.
          if (_showHighlightHint)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 78,
              child: Center(
                child: _HighlightHint(onDismiss: _dismissHighlightHint),
              ),
            ),

          // Book list panel overlay
          if (_showBookPanel)
            Positioned.fill(
              child: BookListPanel(
                currentBookIndex: _bookIndex,
                currentChapter: _chapter,
                onSelectBook: (i, ch) => _go(i, ch),
                onDismiss: () => setState(() => _showBookPanel = false),
              ),
            ),
        ],
      ),
    )); // closes Scaffold + AnnotatedRegion
  }

  Widget _buildPage(int bookIndex, int chapter, ChapterContent? content) {
    if (content == null) {
      return const Center(
        child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 1.5, color: BibleColors.goldAccent),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 118, 44, 24),
      child: _ScriptureContent(
        bookIndex: bookIndex,
        book: bibleBooks[bookIndex],
        chapter: chapter,
        content: content,
        highlights: _highlights,
        onHighlight: _addHighlight,
        onRemoveHighlight: _removeHighlightsOverlapping,
        onBookmarkTap: bookIndex == _bookIndex && chapter == _chapter ? _toggleBookmark : null,
        bookmarkActive: bookIndex == _bmkBookIdx && chapter == _bmkChap,
      ),
    );
  }
}

// ─── Scripture Content ────────────────────────────────────────────────────────

class _ScriptureContent extends StatelessWidget {
  final int bookIndex;
  final BibleBook book;
  final int chapter;
  final ChapterContent content;
  final List<HighlightEntry> highlights;
  final void Function(HighlightEntry) onHighlight;
  final void Function(int verseNumber, int start, int end) onRemoveHighlight;
  final VoidCallback? onBookmarkTap;
  final bool bookmarkActive;

  const _ScriptureContent({
    required this.bookIndex,
    required this.book,
    required this.chapter,
    required this.content,
    required this.highlights,
    required this.onHighlight,
    required this.onRemoveHighlight,
    this.onBookmarkTap,
    this.bookmarkActive = false,
  });

  List<HighlightEntry> _forVerse(int verseNumber) => highlights
      .where((h) => h.bookIndex == bookIndex && h.chapter == chapter && h.verseNumber == verseNumber)
      .toList();

  @override
  Widget build(BuildContext context) {
    final sectionKey = '${bookIndex}_$chapter';
    final sectionTitle = chapterSections[sectionKey];

    // Body copy uses Newsreader — a text-optimized serif — so long passages
    // read comfortably. The display bits (chapter number, drop cap, small-caps
    // section heading) stay Cormorant for character.
    final bodyStyle = AppFonts.serif(
      fontSize: 18, height: 1.7, color: BibleColors.inkDark, letterSpacing: 0.1,
    );
    final verseNumStyle = AppFonts.serif(
      fontSize: 10, fontWeight: FontWeight.w600, color: BibleColors.verseNumber, height: 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${book.name} $chapter',
                style: GoogleFonts.cormorantSc(
                  fontSize: 37, fontWeight: FontWeight.w600,
                  letterSpacing: 3, color: BibleColors.inkDark,
                ),
              ),
              const SizedBox(width: 12),
              _BookmarkControl(
                active: bookmarkActive,
                onTap: onBookmarkTap,
                color: BibleColors.tabColors[book.abbrev] ?? const Color(0xFF7A4828),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(width: 32, height: 1, color: BibleColors.divider),
        const SizedBox(height: 48),
        if (sectionTitle != null) ...[
          _SectionHeading(title: sectionTitle),
          const SizedBox(height: 2),
        ],
        if (content.verses.isNotEmpty)
          _buildVerseBody(
            verses: content.verses,
            hasSectionHeading: sectionTitle != null,
            bodyStyle: bodyStyle,
            verseNumStyle: verseNumStyle,
          ),
      ],
    );
  }

  Widget _buildVerseBody({
    required List<BibleVerse> verses,
    required bool hasSectionHeading,
    required TextStyle bodyStyle,
    required TextStyle verseNumStyle,
  }) {
    if (!hasSectionHeading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DropCapVerse(
            bookIndex: bookIndex,
            chapter: chapter,
            verse: verses.first,
            bodyStyle: bodyStyle,
            verseNumStyle: verseNumStyle,
            storedHighlights: _forVerse(verses.first.number),
            onHighlight: onHighlight,
            onRemove: onRemoveHighlight,
          ),
          if (verses.length > 1) ...[
            const SizedBox(height: 2),
            _verseColumn(verses.skip(1).toList(), bodyStyle, verseNumStyle),
          ],
        ],
      );
    }
    return _verseColumn(verses, bodyStyle, verseNumStyle, skipFirstNumber: true);
  }

  Widget _verseColumn(
    List<BibleVerse> verses,
    TextStyle bodyStyle,
    TextStyle verseNumStyle, {
    bool skipFirstNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < verses.length; i++)
          _VerseRow(
            bookIndex: bookIndex,
            chapter: chapter,
            verse: verses[i],
            showNumber: !(skipFirstNumber && i == 0),
            bodyStyle: bodyStyle,
            verseNumStyle: verseNumStyle,
            storedHighlights: _forVerse(verses[i].number),
            onHighlight: onHighlight,
            onRemove: onRemoveHighlight,
          ),
      ],
    );
  }
}

// ─── Section Heading ──────────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    final dropLetter = title[0].toUpperCase();
    final rest = title.substring(1).toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dropLetter,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 66,
            fontWeight: FontWeight.w300,
            color: BibleColors.inkDark,
            height: 0.80,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            rest,
            style: GoogleFonts.cormorantSc(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: BibleColors.sectionGold,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Drop Cap Verse ───────────────────────────────────────────────────────────

class _DropCapVerse extends StatefulWidget {
  final int bookIndex;
  final int chapter;
  final BibleVerse verse;
  final TextStyle bodyStyle;
  final TextStyle verseNumStyle;
  final List<HighlightEntry> storedHighlights;
  final void Function(HighlightEntry) onHighlight;
  final void Function(int verseNumber, int start, int end) onRemove;

  const _DropCapVerse({
    required this.bookIndex,
    required this.chapter,
    required this.verse,
    required this.bodyStyle,
    required this.verseNumStyle,
    this.storedHighlights = const [],
    required this.onHighlight,
    required this.onRemove,
  });

  @override
  State<_DropCapVerse> createState() => _DropCapVerseState();
}

class _DropCapVerseState extends State<_DropCapVerse> {
  final _textKey = GlobalKey();
  int? _start;
  int? _end;
  bool _active = false;

  // Returns index in verse.text; min=1 so the drop cap letter is never part of a highlight
  int? _charAt(Offset local) {
    final ro = _textKey.currentContext?.findRenderObject();
    if (ro is! RenderParagraph) return null;
    final pos = ro.getPositionForOffset(local);
    // p=0 is the WidgetSpan (verse number), p=1..N maps to verse.text[1..N]
    return pos.offset.clamp(1, widget.verse.text.length);
  }

  void _onLongPressStart(LongPressStartDetails d) {
    final c = _charAt(d.localPosition);
    if (c == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _active = true;
      _start = c;
      _end = (c + 1).clamp(1, widget.verse.text.length);
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails d) {
    if (!_active || _start == null) return;
    final c = _charAt(d.localPosition);
    if (c == null) return;
    setState(() {
      if (c <= _start!) {
        _end = (_start! + 1).clamp(1, widget.verse.text.length);
        _start = c;
      } else {
        _end = (c + 1).clamp(1, widget.verse.text.length);
      }
    });
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (!_active || _start == null || _end == null) return;
    var s = _start!;
    var e = _end!;
    final t = widget.verse.text;
    while (s > 1 && t[s - 1] != ' ') { s--; }
    while (e < t.length && t[e] != ' ') { e++; }
    setState(() { _active = false; _start = null; _end = null; });
    if (e > s) {
      widget.onHighlight(HighlightEntry(
        bookIndex: widget.bookIndex,
        chapter: widget.chapter,
        verseNumber: widget.verse.number,
        start: s,
        end: e,
      ));
    }
  }

  void _onLongPressCancel() =>
      setState(() { _active = false; _start = null; _end = null; });

  void _onTapUp(TapUpDetails d) {
    final c = _charAt(d.localPosition);
    if (c == null) return;
    final w = wordAtOffset(widget.verse.text, c);
    if (w == null) return;
    showWordInterlinear(
      context,
      bookIndex: widget.bookIndex,
      chapter: widget.chapter,
      verse: widget.verse.number,
      wordIndex: w.$1,
      word: w.$2,
    );
  }

  List<HighlightEntry> _shift(List<HighlightEntry> list) => list
      .map((h) => HighlightEntry(
            bookIndex: h.bookIndex,
            chapter: h.chapter,
            verseNumber: h.verseNumber,
            start: max(0, h.start - 1),
            end: max(0, h.end - 1),
          ))
      .toList();

  @override
  Widget build(BuildContext context) {
    if (widget.verse.text.isEmpty) return const SizedBox.shrink();
    final first = widget.verse.text[0];
    final rest = widget.verse.text.substring(1);

    final allHighlights = (_active && _start != null && _end != null)
        ? [
            ...widget.storedHighlights,
            HighlightEntry(
              bookIndex: widget.bookIndex,
              chapter: widget.chapter,
              verseNumber: widget.verse.number,
              start: _start!,
              end: _end!,
            ),
          ]
        : widget.storedHighlights;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          first,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 82, fontWeight: FontWeight.w300,
            color: BibleColors.inkDark, height: 0.80,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: GestureDetector(
              onTapUp: _onTapUp,
              onLongPressStart: _onLongPressStart,
              onLongPressMoveUpdate: _onLongPressMoveUpdate,
              onLongPressEnd: _onLongPressEnd,
              onLongPressCancel: _onLongPressCancel,
              child: RichText(
                key: _textKey,
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: widget.bodyStyle,
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 3, top: 5),
                        child: Text('${widget.verse.number}', style: widget.verseNumStyle),
                      ),
                    ),
                    ...buildHighlightedSpans(rest, _shift(allHighlights), widget.bodyStyle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Chapter Nav Bar ──────────────────────────────────────────────────────────

class _ChapterNavBar extends StatelessWidget {
  final String prevLabel;
  final String nextLabel;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _ChapterNavBar({
    required this.prevLabel,
    required this.nextLabel,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.cormorantGaramond(
      fontSize: 13,
      fontStyle: FontStyle.italic,
      letterSpacing: 0.3,
      color: BibleColors.inkLight,
    );

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _paper,
        border: Border(top: BorderSide(color: BibleColors.divider, width: 0.5)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onPrev != null)
            GestureDetector(onTap: onPrev, child: Text(prevLabel, style: style))
          else
            const SizedBox.shrink(),
          if (onNext != null)
            GestureDetector(onTap: onNext, child: Text(nextLabel, style: style))
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

// ─── Highlight coach hint ─────────────────────────────────────────────────────
// A soft, warm pill that fades in on first reader open, teaching the
// press-and-drag highlight gesture, then fades itself away after a few seconds
// (or when tapped). Shown only once ever (persisted by the reading screen).

class _HighlightHint extends StatefulWidget {
  final VoidCallback onDismiss;
  const _HighlightHint({required this.onDismiss});

  @override
  State<_HighlightHint> createState() => _HighlightHintState();
}

class _HighlightHintState extends State<_HighlightHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    )..forward();
    // Auto-dismiss after it has had time to be read.
    Future<void>.delayed(const Duration(milliseconds: 4600), _fadeOut);
  }

  Future<void> _fadeOut() async {
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(curve),
        child: GestureDetector(
          onTap: _fadeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: BibleColors.inkMid.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.highlighter,
                  size: 18,
                  color: BibleColors.goldAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  'Press and hold, then drag to highlight',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 15,
                    height: 1.1,
                    letterSpacing: 0.2,
                    color: const Color(0xFFF4ECDD),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Per-verse row: long-press + drag to highlight ───────────────────────────

class _VerseRow extends StatefulWidget {
  final int bookIndex;
  final int chapter;
  final BibleVerse verse;
  final bool showNumber;
  final TextStyle bodyStyle;
  final TextStyle verseNumStyle;
  final List<HighlightEntry> storedHighlights;
  final void Function(HighlightEntry) onHighlight;
  final void Function(int verseNumber, int start, int end) onRemove;

  const _VerseRow({
    required this.bookIndex,
    required this.chapter,
    required this.verse,
    required this.showNumber,
    required this.bodyStyle,
    required this.verseNumStyle,
    required this.storedHighlights,
    required this.onHighlight,
    required this.onRemove,
  });

  @override
  State<_VerseRow> createState() => _VerseRowState();
}

class _VerseRowState extends State<_VerseRow> {
  final _textKey = GlobalKey();
  int? _start;
  int? _end;
  bool _active = false;

  // Maps a local Offset to a character index within verse.text
  int? _charAt(Offset local) {
    final ro = _textKey.currentContext?.findRenderObject();
    if (ro is! RenderParagraph) return null;
    final pos = ro.getPositionForOffset(local);
    // When showNumber=true, a WidgetSpan occupies position 0 (U+FFFC placeholder).
    // Subtract 1 to convert from span-text index to verse.text index.
    final raw = widget.showNumber ? pos.offset - 1 : pos.offset;
    return raw.clamp(0, widget.verse.text.length);
  }

  void _onLongPressStart(LongPressStartDetails d) {
    final c = _charAt(d.localPosition);
    if (c == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _active = true;
      _start = c;
      _end = (c + 1).clamp(0, widget.verse.text.length);
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails d) {
    if (!_active || _start == null) return;
    final c = _charAt(d.localPosition);
    if (c == null) return;
    setState(() {
      if (c <= _start!) {
        _end = (_start! + 1).clamp(0, widget.verse.text.length);
        _start = c;
      } else {
        _end = (c + 1).clamp(0, widget.verse.text.length);
      }
    });
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (!_active || _start == null || _end == null) return;
    var s = _start!;
    var e = _end!;
    final t = widget.verse.text;
    // Snap to whole words on commit
    while (s > 0 && t[s - 1] != ' ') { s--; }
    while (e < t.length && t[e] != ' ') { e++; }
    setState(() { _active = false; _start = null; _end = null; });
    if (e > s) {
      widget.onHighlight(HighlightEntry(
        bookIndex: widget.bookIndex,
        chapter: widget.chapter,
        verseNumber: widget.verse.number,
        start: s,
        end: e,
      ));
    }
  }

  void _onLongPressCancel() =>
      setState(() { _active = false; _start = null; _end = null; });

  // Single tap → reverse-interlinear popover for the tapped word.
  void _onTapUp(TapUpDetails d) {
    final c = _charAt(d.localPosition);
    if (c == null) return;
    final w = wordAtOffset(widget.verse.text, c);
    if (w == null) return;
    showWordInterlinear(
      context,
      bookIndex: widget.bookIndex,
      chapter: widget.chapter,
      verse: widget.verse.number,
      wordIndex: w.$1,
      word: w.$2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allHighlights = (_active && _start != null && _end != null)
        ? [
            ...widget.storedHighlights,
            HighlightEntry(
              bookIndex: widget.bookIndex,
              chapter: widget.chapter,
              verseNumber: widget.verse.number,
              start: _start!,
              end: _end!,
            ),
          ]
        : widget.storedHighlights;

    return GestureDetector(
      onTapUp: _onTapUp,
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      child: RichText(
        key: _textKey,
        textAlign: TextAlign.justify,
        text: TextSpan(
          style: widget.bodyStyle,
          children: [
            if (widget.showNumber)
              WidgetSpan(
                alignment: PlaceholderAlignment.top,
                child: Padding(
                  padding: const EdgeInsets.only(right: 3, top: 5),
                  child: Text('${widget.verse.number}', style: widget.verseNumStyle),
                ),
              ),
            ...buildHighlightedSpans(
              '${widget.verse.text} ',
              allHighlights,
              widget.bodyStyle,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bookmark Ribbon ─────────────────────────────────────────────────────────

/// Inline bookmark control beside the chapter title.
///
/// Empty state = a bookmark outline icon. Tapping it drops the burgundy ribbon
/// pennant in from just above (a short ease-in fall) and settles it in place.
/// Tapping again removes the bookmark, returning to the icon.
class _BookmarkControl extends StatefulWidget {
  final bool active;
  final VoidCallback? onTap;
  final Color color; // matches the book's tab color
  const _BookmarkControl({required this.active, this.onTap, required this.color});

  @override
  State<_BookmarkControl> createState() => _BookmarkControlState();
}

class _BookmarkControlState extends State<_BookmarkControl>
    with SingleTickerProviderStateMixin {
  static const _w = 24.0;
  static const _h = 40.0;
  static const _drop = 24.0; // how far above it starts — kept low, per spec

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
    _ctrl.value = widget.active ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(covariant _BookmarkControl old) {
    super.didUpdateWidget(old);
    if (!old.active && widget.active) {
      _ctrl.forward(from: 0); // dropped in
    } else if (old.active && !widget.active) {
      _ctrl.value = 0; // removed — snap back to the icon
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _w,
        height: _h,
        child: widget.active
            ? AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  final t = Curves.easeIn.transform(_ctrl.value);
                  final dy = -_drop * (1 - t);
                  final opacity = (_ctrl.value * 2.6).clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Opacity(
                      opacity: opacity,
                      child: CustomPaint(
                        size: const Size(_w, _h),
                        painter: _BookmarkPainter(widget.color),
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Icon(
                  LucideIcons.bookmark,
                  size: 20,
                  color: BibleColors.inkLight.withValues(alpha: 0.75),
                ),
              ),
      ),
    );
  }
}

class _BookmarkPainter extends CustomPainter {
  final Color color;
  const _BookmarkPainter(this.color);

  static Color _darken(Color c, double amt) =>
      Color.alphaBlend(Colors.black.withValues(alpha: amt), c);
  static Color _lighten(Color c, double amt) =>
      Color.alphaBlend(Colors.white.withValues(alpha: amt), c);

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;
    final notch = H * 0.26; // depth of the V-cut at the bottom

    // Ribbon shading derived from the book's tab color, so each bookmark
    // matches its book. Slightly lit left edge → darker core → base at right.
    final grad = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [_lighten(color, 0.10), _darken(color, 0.26), color],
      stops: const [0.0, 0.45, 1.0],
    );

    // ── Shape ────────────────────────────────────────────────────────────────
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(W, 0)
      ..lineTo(W, H - notch)
      ..lineTo(W / 2, H)
      ..lineTo(0, H - notch)
      ..close();

    // ── Main fill: gradient from the book color ───────────────────────────────
    canvas.drawPath(
      path,
      Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, W, H)),
    );

    // ── Subtle vertical texture lines (fabric/ribbon grain) ───────────────────
    final grainPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.07)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.clipPath(path);
    for (double x = 6; x < W; x += 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, H), grainPaint);
    }
    canvas.restore();

    // ── Left sheen highlight ──────────────────────────────────────────────────
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, W * 0.28, H),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, W, H)),
    );
    canvas.restore();

    // ── Drop shadow under the ribbon ──────────────────────────────────────────
    canvas.drawPath(
      path.shift(const Offset(2, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Redraw foreground over shadow (shadow drawn first = wrong order, fix below)
    canvas.drawPath(
      path,
      Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, W, H)),
    );

    // ── Thin top fold line (hint of thickness at the top edge) ────────────────
    canvas.drawLine(
      Offset.zero,
      Offset(W, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..strokeWidth = 1.5,
    );

    // ── Dark outline ─────────────────────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_BookmarkPainter old) => old.color != color;
}

// ─── Page Curl ───────────────────────────────────────────────────────────────
// Draws a realistic corner-peel effect driven by PageController.page.
// P1 = fold point on right edge (moves up as swipe progresses)
// P2 = fold point on bottom edge (moves left as swipe progresses)
// CP = slightly beyond the bottom-right corner → creates the characteristic
//      outward-bowing curve that looks like real flexible paper.

class _PageCurlPainter extends CustomPainter {
  final PageController ctrl;
  _PageCurlPainter(this.ctrl) : super(repaint: ctrl);

  @override
  void paint(Canvas canvas, Size size) {
    if (!ctrl.hasClients) return;
    final page = ctrl.page ?? 1.0;
    final rawT = page - 1.0;
    if (rawT.abs() < 0.005) return;
    final t = rawT.abs().clamp(0.0, 1.0);
    _draw(canvas, size, t, forward: rawT > 0);
  }

  void _draw(Canvas canvas, Size size, double t, {required bool forward}) {
    final W = size.width;
    final H = size.height;

    // Fold line endpoints — bottom-right corner peel:
    //   P1 on the right edge, climbs upward  (t=0→H, t=1→0.28H)
    //   P2 on the bottom edge, moves leftward (t=0→W, t=1→0.08W)
    final p1x = forward ? W              : 0.0;
    final p1y = H * (1.0 - t * 0.72);
    final p2x = forward ? W * (1.0 - t * 0.92) : W * (t * 0.92);
    final p2y = H;

    // Bezier control point: pushed ~50px BEYOND the corner so the curve
    // bows outward toward the corner — the hallmark of a paper fold.
    final cpx = forward ? W + 50.0 * t : -50.0 * t;
    final cpy = H + 50.0 * t;

    // ─── 1. Curved shadow on the flat page (left of fold) ────────────────────
    final flatClip = Path();
    if (forward) {
      flatClip
        ..moveTo(0, 0)
        ..lineTo(p1x, p1y)
        ..quadraticBezierTo(cpx, cpy, p2x, p2y)
        ..lineTo(0, H)
        ..close();
    } else {
      flatClip
        ..moveTo(W, 0)
        ..lineTo(p1x, p1y)
        ..quadraticBezierTo(cpx, cpy, p2x, p2y)
        ..lineTo(W, H)
        ..close();
    }
    canvas.save();
    canvas.clipPath(flatClip);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, W, H),
      Paint()
        ..shader = LinearGradient(
          begin: forward ? Alignment.centerRight : Alignment.centerLeft,
          end:   forward ? Alignment.centerLeft  : Alignment.centerRight,
          colors: [
            Colors.black.withValues(alpha: (t * 0.38).clamp(0, 0.38)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.75],
        ).createShader(Rect.fromLTWH(0, 0, W, H)),
    );
    canvas.restore();

    // ─── 2. Parchment flap (back of the turning page) ─────────────────────────
    // Polygon: P1 → right edge down → corner (W,H) → P2 → bezier back to P1
    final flap = Path();
    if (forward) {
      flap
        ..moveTo(p1x, p1y)
        ..lineTo(W, p1y)   // right edge to p1 (same x, no-op if p1x=W)
        ..lineTo(W, H)     // bottom-right corner
        ..lineTo(p2x, p2y) // along bottom edge to P2
        ..quadraticBezierTo(cpx, cpy, p1x, p1y); // curved fold back to P1
    } else {
      flap
        ..moveTo(p1x, p1y)
        ..lineTo(0, p1y)
        ..lineTo(0, H)
        ..lineTo(p2x, p2y)
        ..quadraticBezierTo(cpx, cpy, p1x, p1y);
    }
    flap.close();

    // Warm parchment fill
    canvas.drawPath(flap, Paint()..color = const Color(0xFFF2EAD8));

    // Depth gradient: bright near the fold edge (catching light), darker at corner
    canvas.drawPath(
      flap,
      Paint()
        ..shader = LinearGradient(
          begin: forward ? Alignment.centerLeft : Alignment.centerRight,
          end:   forward ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.12),
          ],
        ).createShader(Rect.fromLTWH(0, 0, W, H)),
    );

    // ─── 3. Fold-line highlight (paper edge catching light) ──────────────────
    final fold = Path()
      ..moveTo(p1x, p1y)
      ..quadraticBezierTo(cpx, cpy, p2x, p2y);
    canvas.drawPath(
      fold,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.88)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // ─── 4. Crease shadow on the flat page just left of the fold ─────────────
    final dx = forward ? -5.0 : 5.0;
    final crease = Path()
      ..moveTo(p1x + dx, p1y)
      ..quadraticBezierTo(cpx + dx * 0.6, cpy, p2x + dx * 0.4, p2y);
    canvas.drawPath(
      crease,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_PageCurlPainter old) => true;
}

// ─── Paper Grain (subtle, on white card) ─────────────────────────────────────

class _PaperGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(99);
    final paint = Paint()..strokeWidth = 0.4;
    for (int i = 0; i < 250; i++) {
      paint.color = Color.fromRGBO(160, 140, 110, rng.nextDouble() * 0.03);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 0.9,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
