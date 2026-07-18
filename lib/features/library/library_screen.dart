import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/fonts.dart';
import '../../app/theme.dart';
import '../../app/theme_mode_controller.dart';
import '../../app/widgets/app_icon_button.dart';
import '../reader/reader_launch.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _intro.forward());
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
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
                onBookTap: (book, origin) =>
                    Navigator.of(context).push(bookOpenRoute(book, origin)),
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
