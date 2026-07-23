import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/bible_data.dart';
import '../data/bookmark_data.dart';
import '../theme/bible_theme.dart';

/// A list of every bookmarked chapter. Tap to jump; swipe to remove.
class BookmarksScreen extends StatefulWidget {
  final List<BookmarkEntry> bookmarks;
  final void Function(int bookIndex, int chapter) onNavigate;
  final void Function(BookmarkEntry) onRemove;

  const BookmarksScreen({
    super.key,
    required this.bookmarks,
    required this.onNavigate,
    required this.onRemove,
  });

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late List<BookmarkEntry> _bookmarks;

  @override
  void initState() {
    super.initState();
    _bookmarks = List.from(widget.bookmarks);
  }

  void _remove(BookmarkEntry b) {
    widget.onRemove(b);
    setState(() => _bookmarks.remove(b));
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
          'Bookmarks',
          style: GoogleFonts.cormorantSc(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: BibleColors.inkDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _bookmarks.isEmpty
          ? Center(
              child: Text(
                'No bookmarks yet.\nTap the ribbon to bookmark a chapter.',
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
              itemCount: _bookmarks.length,
              separatorBuilder: (_, _) => Container(height: 0.5, color: BibleColors.divider),
              itemBuilder: (context, i) {
                final b = _bookmarks[i];
                final book = bibleBooks[b.bookIndex];
                final ribbonColor =
                    BibleColors.tabColors[book.abbrev] ?? const Color(0xFF7A1828);

                return Dismissible(
                  key: ValueKey('${b.bookIndex}_${b.chapter}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: const Color(0xFF7B2030),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                  ),
                  onDismissed: (_) => _remove(b),
                  child: InkWell(
                    onTap: () {
                      widget.onNavigate(b.bookIndex, b.chapter);
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
                              color: ribbonColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              '${book.name}  \u00b7  Chapter ${b.chapter}',
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
