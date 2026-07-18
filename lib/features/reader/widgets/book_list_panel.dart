import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/bible_data.dart';
import '../theme/bible_theme.dart';

class BookListPanel extends StatefulWidget {
  final int currentBookIndex;
  final int currentChapter;
  final void Function(int bookIndex, int chapter) onSelectBook;
  final VoidCallback onDismiss;

  const BookListPanel({
    super.key,
    required this.currentBookIndex,
    required this.currentChapter,
    required this.onSelectBook,
    required this.onDismiss,
  });

  @override
  State<BookListPanel> createState() => _BookListPanelState();
}

class _BookListPanelState extends State<BookListPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final ScrollController _scroll;
  late final TextEditingController _searchCtrl;

  String _query = '';
  int? _expandedBook; // book index whose chapter grid is open

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scroll = ScrollController();
    _searchCtrl = TextEditingController();
    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  void _scrollToActive() {
    final idx = widget.currentBookIndex;
    final isNT = !bibleBooks[idx].isOT;
    final offset = 32.0 + idx * 44.0 + (isNT ? 32.0 : 0.0);
    if (_scroll.hasClients) {
      _scroll.jumpTo(offset.clamp(0.0, _scroll.position.maxScrollExtent));
    }
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  void _onBookTapped(int bookIndex) {
    final book = bibleBooks[bookIndex];
    if (book.chapterCount == 1) {
      // Single-chapter book — navigate directly
      widget.onSelectBook(bookIndex, 1);
      _dismiss();
      return;
    }
    setState(() {
      _expandedBook = _expandedBook == bookIndex ? null : bookIndex;
    });
  }

  void _onChapterTapped(int bookIndex, int chapter) {
    widget.onSelectBook(bookIndex, chapter);
    _dismiss();
  }

  List<({int index, BibleBook book})> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return [
      for (int i = 0; i < bibleBooks.length; i++)
        if (bibleBooks[i].name.toLowerCase().contains(q)) (index: i, book: bibleBooks[i]),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black.withValues(alpha: 0.25),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: SlideTransition(
                position: _slide,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.72,
                  color: BibleColors.ivoryPaper,
                  child: SafeArea(
                    child: Column(
                      children: [
                        _SearchField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() {
                            _query = v;
                            if (v.isNotEmpty) _expandedBook = null;
                          }),
                        ),
                        Expanded(
                          child: _query.isNotEmpty
                              ? _buildSearchResults()
                              : _buildFullList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── full list with OT / NT headers ────────────────────────────────────────

  Widget _buildFullList() {
    final otBooks = bibleBooks.where((b) => b.isOT).length;
    // items: OT header + 39 OT entries + NT header + 27 NT entries = 68 items
    final itemCount = bibleBooks.length + 2;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) return const _TestamentHeader(label: 'Old Testament');
        if (index == otBooks + 1) return const _TestamentHeader(label: 'New Testament');
        final bookIndex = index <= otBooks ? index - 1 : index - 2;
        return _buildBookEntry(bookIndex);
      },
    );
  }

  // ── search results (no headers) ───────────────────────────────────────────

  Widget _buildSearchResults() {
    final results = _filtered;
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No books found',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 15, color: BibleColors.inkLight, fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: results.length,
      itemBuilder: (_, i) => _buildBookEntry(results[i].index),
    );
  }

  // ── single book row + optional chapter grid ───────────────────────────────

  Widget _buildBookEntry(int bookIndex) {
    final book = bibleBooks[bookIndex];
    final isActive = bookIndex == widget.currentBookIndex;
    final isExpanded = _expandedBook == bookIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BookRow(
          book: book,
          bookIndex: bookIndex,
          isActive: isActive,
          isExpanded: isExpanded,
          hasChapters: book.chapterCount > 1,
          onTap: () => _onBookTapped(bookIndex),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: isExpanded
              ? _ChapterGrid(
                  book: book,
                  bookIndex: bookIndex,
                  currentChapter: isActive ? widget.currentChapter : null,
                  onChapterTap: (ch) => _onChapterTapped(bookIndex, ch),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Search field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: BibleColors.ivoryPaper,
        border: Border(bottom: BorderSide(color: BibleColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 18,
              color: BibleColors.inkLight.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                color: BibleColors.inkDark,
                letterSpacing: 0.3,
              ),
              decoration: InputDecoration(
                hintText: 'Search books…',
                hintStyle: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  color: BibleColors.inkLight.withValues(alpha: 0.45),
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              cursorColor: BibleColors.goldAccent,
              cursorWidth: 1.2,
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Icon(LucideIcons.x, size: 16,
                  color: BibleColors.inkLight.withValues(alpha: 0.5)),
            ),
        ],
      ),
    );
  }
}

// ─── Book row ─────────────────────────────────────────────────────────────────

class _BookRow extends StatelessWidget {
  final BibleBook book;
  final int bookIndex;
  final bool isActive;
  final bool isExpanded;
  final bool hasChapters;
  final VoidCallback onTap;

  const _BookRow({
    required this.book,
    required this.bookIndex,
    required this.isActive,
    required this.isExpanded,
    required this.hasChapters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: isActive
            ? BibleColors.divider.withValues(alpha: 0.5)
            : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                book.name,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? BibleColors.inkDark : BibleColors.inkMid,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (hasChapters)
              AnimatedRotation(
                turns: isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: BibleColors.inkLight.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Chapter grid ─────────────────────────────────────────────────────────────

class _ChapterGrid extends StatelessWidget {
  final BibleBook book;
  final int bookIndex;
  final int? currentChapter;
  final void Function(int) onChapterTap;

  const _ChapterGrid({
    required this.book,
    required this.bookIndex,
    required this.currentChapter,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    final abbrev = book.abbrev;
    final bookColor = BibleColors.tabColors[abbrev] ?? BibleColors.goldAccent;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      color: BibleColors.divider.withValues(alpha: 0.18),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (int ch = 1; ch <= book.chapterCount; ch++)
            _ChapterChip(
              chapter: ch,
              isCurrent: ch == currentChapter,
              bookColor: bookColor,
              onTap: () => onChapterTap(ch),
            ),
        ],
      ),
    );
  }
}

class _ChapterChip extends StatelessWidget {
  final int chapter;
  final bool isCurrent;
  final Color bookColor;
  final VoidCallback onTap;

  const _ChapterChip({
    required this.chapter,
    required this.isCurrent,
    required this.bookColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isCurrent ? bookColor : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          '$chapter',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 13,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: isCurrent ? Colors.white : BibleColors.inkMid,
          ),
        ),
      ),
    );
  }
}

// ─── Testament header ─────────────────────────────────────────────────────────

class _TestamentHeader extends StatelessWidget {
  final String label;
  const _TestamentHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.cormorantGaramond(
          fontSize: 10, letterSpacing: 2.5,
          fontWeight: FontWeight.w600, color: BibleColors.inkLight,
        ),
      ),
    );
  }
}
