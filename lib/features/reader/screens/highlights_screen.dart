import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/bible_data.dart';
import '../data/highlight_data.dart';
import '../theme/bible_theme.dart';

/// A list of every saved highlight. Tap to jump to the verse; swipe to remove.
class HighlightsScreen extends StatefulWidget {
  final List<HighlightEntry> highlights;
  final void Function(int bookIndex, int chapter) onNavigate;
  final void Function(HighlightEntry) onRemove;

  const HighlightsScreen({
    super.key,
    required this.highlights,
    required this.onNavigate,
    required this.onRemove,
  });

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  late List<HighlightEntry> _highlights;

  @override
  void initState() {
    super.initState();
    // Newest first (most recently added is at the end of the stored list).
    _highlights = widget.highlights.reversed.toList();
  }

  void _remove(HighlightEntry h) {
    widget.onRemove(h);
    setState(() => _highlights.remove(h));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BibleColors.ivoryPaper,
      appBar: AppBar(
        backgroundColor: BibleColors.ivoryPaper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: BibleColors.inkDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Highlights',
          style: GoogleFonts.cormorantSc(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: BibleColors.inkDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _highlights.isEmpty
          ? Center(
              child: Text(
                'No highlights yet.\nPress and drag any verse to highlight.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: BibleColors.inkLight,
                  height: 1.8,
                ),
              ),
            )
          : ListView.separated(
              itemCount: _highlights.length,
              separatorBuilder: (_, _) => Container(height: 0.5, color: BibleColors.divider),
              itemBuilder: (context, i) {
                final h = _highlights[i];
                final book = bibleBooks[h.bookIndex];
                final chipColor =
                    (BibleColors.tabColors[book.abbrev] ?? const Color(0xFF7A4828))
                        .withValues(alpha: 0.45);

                return Dismissible(
                  key: ValueKey('${h.bookIndex}_${h.chapter}_${h.verseNumber}_${h.start}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: const Color(0xFF7B2030),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                  ),
                  onDismissed: (_) => _remove(h),
                  child: InkWell(
                    onTap: () {
                      widget.onNavigate(h.bookIndex, h.chapter);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 36,
                            decoration: BoxDecoration(
                              color: chipColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              '${book.name}  ${h.chapter}:${h.verseNumber}',
                              style: GoogleFonts.cormorantSc(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: BibleColors.inkDark,
                              ),
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight,
                              color: BibleColors.inkLight, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
