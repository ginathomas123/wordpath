import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/fonts.dart';
import '../../app/theme.dart';
import '../../app/theme_mode_controller.dart';
import '../../app/widgets/app_icon_button.dart';
import '../../data/home_widget_service.dart';
import '../reader/data/bible_data.dart' as reader;
import '../reader/reader_launch.dart';
import '../study/data/study_mastery.dart';
import 'add_menu.dart';
import 'book_open_route.dart';
import 'library_controller.dart';
import 'widgets/book_shelf.dart';
import 'widgets/intro_item.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  static const routeName = 'library';
  static const routePath = '/library';

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  StreamSubscription<Uri?>? _widgetClickSub;

  /// Titles of books whose study is fully complete — drives the cover seal.
  Set<String> _mastered = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _intro.forward());
    _initWidgetLaunch();
    _loadMastery();
  }

  /// Reloads which studies are complete from persisted progress. Called on
  /// entry and whenever we return from a book (a study may have just finished).
  Future<void> _loadMastery() async {
    final books = [
      for (final s in ref.read(libraryProvider)) ...s.books,
    ];
    final map = await loadMasteredTitles(books);
    if (!mounted) return;
    final done = {
      for (final e in map.entries)
        if (e.value) e.key,
    };
    if (done.length != _mastered.length ||
        !done.containsAll(_mastered)) {
      setState(() => _mastered = done);
    }
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
    _intro.dispose();
    super.dispose();
  }

  /// Refresh the widget's card and wire up "tap the widget → resume reading".
  Future<void> _initWidgetLaunch() async {
    await HomeWidgetService.refreshFromLastRead();
    _widgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetUri);
    final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _handleWidgetUri(launchUri);
  }

  Future<void> _handleWidgetUri(Uri? uri) async {
    if (uri == null || uri.host != 'continue') return;
    final (book, chapter) = await HomeWidgetService.lastRead();
    if (!mounted) return;
    final safe = book.clamp(0, reader.bibleBooks.length - 1);
    openReader(
      context,
      bookTitle: reader.bibleBooks[safe].name,
      chapter: chapter,
      immersive: true,
    );
  }

  /// Fraction of the timeline where each section begins its cascade.
  double _sectionStart(int index) => 0.10 + index * 0.20;

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(libraryProvider);
    return Scaffold(
      backgroundColor: context.palette.paper,
      floatingActionButton: IntroItem(
        animation: _intro,
        start: 0.6,
        end: 0.9,
        dy: 0,
        scaleFrom: 0.4,
        child: _AddButton(onPressed: () => showAddMenu(context)),
      ),
      bottomNavigationBar: IntroItem(
        animation: _intro,
        start: 0.55,
        end: 0.9,
        dy: 24,
        slideCurve: Curves.easeOut,
        child: const _ExploreBar(),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Breathing space below the status bar before content begins.
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: IntroItem(
                animation: _intro,
                start: 0.0,
                end: 0.24,
                dy: -10,
                slideCurve: Curves.easeOut,
                child: const _Header(),
              ),
            ),
            SliverList.separated(
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 30),
              itemBuilder: (context, index) => BookShelf(
                section: sections[index],
                intro: _intro,
                introStart: _sectionStart(index),
                masteredTitles: _mastered,
                onBookTap: (book, origin) async {
                  await Navigator.of(context).push(bookOpenRoute(book, origin));
                  // A study may have been completed while inside — re-check.
                  _loadMastery();
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Stack(
        children: [
          Column(
            children: [
              Transform.translate(
                offset: const Offset(-10, 0),
                child: Text(
                  'WORD',
                  style: AppFonts.sans(
                    color: context.palette.inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PATH',
                style: AppFonts.serif(
                  color: context.palette.ink,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Positioned(top: 4, right: 0, child: _ThemeToggle()),
        ],
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return AppIconButton(
      icon: isDark ? LucideIcons.sun : LucideIcons.moon,
      tooltip: isDark ? 'Light mode' : 'Dark mode',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppIconButton.primary(
      icon: LucideIcons.plus,
      tooltip: 'Add to library',
      onPressed: onPressed,
    );
  }
}

class _ExploreBar extends StatelessWidget {
  const _ExploreBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.ink,
              foregroundColor: context.palette.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => openReader(context),
            child: Text(
              'Read the Bible',
              style: AppFonts.sans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
