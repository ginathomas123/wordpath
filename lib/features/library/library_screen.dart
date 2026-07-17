import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../data/bible_data.dart';
import 'book_open_route.dart';
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
    return Scaffold(
      backgroundColor: AppColors.paper,
      floatingActionButton: IntroItem(
        animation: _intro,
        start: 0.6,
        end: 0.9,
        dy: 0,
        scaleFrom: 0.4,
        child: _AddButton(onPressed: () {}),
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
              itemCount: kBibleSections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 30),
              itemBuilder: (context, index) => BookShelf(
                section: kBibleSections[index],
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
      child: Column(
        children: [
          Text(
            'THE HOLY',
            style: GoogleFonts.inter(
              color: AppColors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'BIBLE',
            style: GoogleFonts.newsreader(
              color: AppColors.ink,
              fontSize: 36,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Icon(Icons.add, color: AppColors.ink, size: 26),
        ),
      ),
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
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {},
            child: Text(
              'Explore All Books',
              style: GoogleFonts.inter(
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
