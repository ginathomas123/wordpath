import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/fonts.dart';
import '../../app/theme.dart';
import '../../data/bible_data.dart';
import 'library_controller.dart';

/// Opens the floating "+" menu anchored to the bottom-right (above the FAB),
/// listing books and topics the user can add to their shelves.
Future<void> showAddMenu(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add to library',
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => const _AddMenu(),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          alignment: Alignment.bottomRight,
          child: child,
        ),
      );
    },
  );
}

class _AddMenu extends ConsumerWidget {
  const _AddMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(availableToAddProvider);
    final topics = [
      for (final i in items)
        if (i.section == SectionTitles.topics) i,
    ];
    final books = [
      for (final i in items)
        if (i.section != SectionTitles.topics) i,
    ];

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 92),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 340,
              maxHeight: MediaQuery.of(context).size.height * 0.62,
            ),
            child: Material(
              color: AppColors.paper,
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _MenuHeader(),
                  Flexible(
                    child: items.isEmpty
                        ? const _EmptyState()
                        : ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              if (topics.isNotEmpty) ...[
                                const _GroupLabel('TOPICS'),
                                for (final item in topics)
                                  _AddRow(item: item),
                              ],
                              if (books.isNotEmpty) ...[
                                const _GroupLabel('BOOKS'),
                                for (final item in books)
                                  _AddRow(item: item),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add to your library',
                  style: AppFonts.serif(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Books and topics to explore',
                  style: AppFonts.sans(
                    color: AppColors.inkSoft,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: AppColors.inkSoft, size: 22),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        text,
        style: AppFonts.sans(
          color: AppColors.inkFaint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _AddRow extends ConsumerWidget {
  const _AddRow({required this.item});

  final AddableItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = item.book;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref.read(libraryProvider.notifier).add(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _MiniCover(book: book),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: AppFonts.serif(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      book.attribution,
                      style: AppFonts.sans(
                        color: AppColors.inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small rounded cover thumbnail mirroring the shelf styling.
class _MiniCover extends StatelessWidget {
  const _MiniCover({required this.book});

  final BibleBook book;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(book.texture, fit: BoxFit.cover, cacheWidth: 160);
    if (book.tint != null) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(book.tint!, BlendMode.color),
        child: image,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 58,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.inkFaint, size: 34),
          const SizedBox(height: 10),
          Text(
            "Everything's on your shelf",
            style: AppFonts.serif(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'ve added all the available books and topics.',
            textAlign: TextAlign.center,
            style: AppFonts.sans(color: AppColors.inkSoft, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
