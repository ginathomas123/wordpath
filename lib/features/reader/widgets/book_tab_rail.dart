import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/bible_data.dart';
import '../theme/bible_theme.dart';

// Landmark books shown in the tab rail — full list navigable via the book panel
const _landmarkAbbrevs = [
  'Gen', 'Exo', 'Lev', 'Num', 'Deu', 'Jos', 'Jdg', 'Rut',
  '1Sa', '2Sa', '1Ki', '2Ki', 'Psa', 'Pro', 'Isa',
  // NT separator inserted between Isa and Mat
  'Mat', 'Mar', 'Luk', 'Joh', 'Act', 'Rom', 'Rev',
];

class BookTabRail extends StatefulWidget {
  final int currentBookIndex;
  final void Function(int bookIndex) onBookTapped;

  const BookTabRail({
    super.key,
    required this.currentBookIndex,
    required this.onBookTapped,
  });

  @override
  State<BookTabRail> createState() => _BookTabRailState();
}

class _BookTabRailState extends State<BookTabRail> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  @override
  void didUpdateWidget(BookTabRail old) {
    super.didUpdateWidget(old);
    if (old.currentBookIndex != widget.currentBookIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  void _scrollToActive() {
    if (!_scroll.hasClients) return;
    final activeAbbrev = bibleBooks[widget.currentBookIndex].abbrev;
    // Find index in landmark list
    int landmarkIdx = _landmarkAbbrevs.indexOf(activeAbbrev);
    if (landmarkIdx == -1) return; // not a landmark book

    // Calculate offset: each tab is 32px, NT header is 24px, OT header is 24px
    final ntSeparatorIdx = _landmarkAbbrevs.indexOf('Mat');
    double offset = 24.0; // OT header height
    for (int i = 0; i < landmarkIdx; i++) {
      offset += 32.0;
      if (i == ntSeparatorIdx - 1) offset += 24.0; // NT header
    }
    _scroll.animateTo(
      offset.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String get _currentAbbrev => bibleBooks[widget.currentBookIndex].abbrev;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      color: const Color(0xFFEAE6DE),
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        clipBehavior: Clip.none,
        children: [
          _TestamentLabel(label: 'O.T.'),
          ..._buildOTTabs(),
          _TestamentLabel(label: 'N.T.'),
          ..._buildNTTabs(),
        ],
      ),
    );
  }

  List<Widget> _buildOTTabs() {
    return _landmarkAbbrevs
        .where((a) => _isOT(a))
        .map((abbrev) {
          final bookIndex = _bookIndexFor(abbrev);
          return _BookTab(
            abbrev: abbrev,
            bookIndex: bookIndex,
            isActive: abbrev == _currentAbbrev,
            onTap: bookIndex != -1 ? () => widget.onBookTapped(bookIndex) : null,
          );
        })
        .toList();
  }

  List<Widget> _buildNTTabs() {
    return _landmarkAbbrevs
        .where((a) => !_isOT(a))
        .map((abbrev) {
          final bookIndex = _bookIndexFor(abbrev);
          return _BookTab(
            abbrev: abbrev,
            bookIndex: bookIndex,
            isActive: abbrev == _currentAbbrev,
            onTap: bookIndex != -1 ? () => widget.onBookTapped(bookIndex) : null,
          );
        })
        .toList();
  }

  bool _isOT(String abbrev) {
    final idx = _bookIndexFor(abbrev);
    return idx != -1 && bibleBooks[idx].isOT;
  }

  int _bookIndexFor(String abbrev) =>
      bibleBooks.indexWhere((b) => b.abbrev == abbrev);
}

class _TestamentLabel extends StatelessWidget {
  final String label;
  const _TestamentLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
            color: BibleColors.inkLight.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _BookTab extends StatelessWidget {
  final String abbrev;
  final int bookIndex;
  final bool isActive;
  final VoidCallback? onTap;

  const _BookTab({
    required this.abbrev,
    required this.bookIndex,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = BibleColors.tabColors[abbrev] ?? const Color(0xFF7A4828);
    final bgColor = isActive
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.38), baseColor)
        : baseColor;

    if (isActive) {
      return GestureDetector(
        onTap: onTap,
        // Stack(clipBehavior: Clip.none) lets the Positioned child paint outside
        // the SizedBox bounds without triggering debug overflow warnings.
        // Positioned(left: -26) extends the tab 26px to the left over the card
        // while width: 74 keeps the right edge flush with the inactive tabs.
        child: SizedBox(
          height: 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -26,
                top: 2,
                width: 74,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(-5, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 28,
                        offset: const Offset(-12, 7),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    abbrev,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Text(
          abbrev,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
      ),
    );
  }
}
