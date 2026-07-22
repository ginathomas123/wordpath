import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/fonts.dart';

import '../../app/theme.dart';
import '../../app/widgets/app_icon_button.dart';
import '../../data/bible_data.dart';
import '../../data/read_progress.dart';
import '../../data/study_data.dart';
import '../../data/study_progress.dart';
import '../reader/data/bible_data.dart' as reader;
import '../reader/reader_launch.dart';
import 'data/key_verses.dart';
import 'data/study_circle.dart';
import 'widgets/circle_discussion.dart';
import 'widgets/focus_session.dart';
import 'widgets/study_tools.dart';

/// Finds the reader's canonical book for a reference name, tolerating the
/// singular "Psalm" → "Psalms".
reader.BibleBook? _findReaderBook(String name) {
  final n = name.trim().toLowerCase();
  for (final b in reader.bibleBooks) {
    if (b.name.toLowerCase() == n) return b;
  }
  for (final b in reader.bibleBooks) {
    if (b.name.toLowerCase() == '${n}s') return b;
  }
  return null;
}

/// One card on a study path, already resolved to the real scripture it opens
/// and records progress against — so the reader location and the study
/// checkmarks always agree.
class _StudyEntry {
  const _StudyEntry({
    required this.readerBook,
    required this.readerChapter,
    required this.pillLabel,
    required this.title,
    required this.preview,
    required this.seededComplete,
  });

  /// Reader book name + chapter this card opens and tracks.
  final String readerBook;
  final int readerChapter;

  /// Reference label shown on the card (e.g. "PHILIPPIANS 4").
  final String pillLabel;
  final String title;
  final String preview;

  /// Seeded-complete flag from the curated study data.
  final bool seededComplete;

  String get readKey => ReadProgress.keyFor(readerBook, readerChapter);
}

/// Builds the study path for [book]. Canonical books (whose `attribution` is an
/// author, e.g. "Moses") use their curated/generic chapters. Topical studies
/// (whose `attribution` is a reference, e.g. "Ephesians 5") map to consecutive
/// real chapters starting at the reference — only as many as actually exist, so
/// each card is a distinct passage.
List<_StudyEntry> buildStudyEntries(BibleBook book) {
  final parts = book.attribution.trim().split(RegExp(r'\s+'));
  final refChapter = parts.length >= 2 ? int.tryParse(parts.last) : null;

  if (refChapter != null) {
    final refName = parts.sublist(0, parts.length - 1).join(' ');
    final rb = _findReaderBook(refName);
    if (rb != null) {
      final available = rb.chapterCount - refChapter + 1;
      final count = available.clamp(1, 4);
      return List.generate(count, (i) {
        final ch = refChapter + i;
        return _StudyEntry(
          readerBook: rb.name,
          readerChapter: ch,
          pillLabel: '${rb.name} $ch',
          title: book.title,
          preview: book.about ?? 'Read ${rb.name} $ch.',
          seededComplete: false,
        );
      });
    }
  }

  return [
    for (final c in chaptersFor(book))
      _StudyEntry(
        readerBook: book.title,
        readerChapter: c.number,
        pillLabel: '${book.title} ${c.number}',
        title: c.title,
        preview: c.preview,
        seededComplete: c.completed,
      ),
  ];
}

/// The "Path to [book]" study screen reached from a book's Study action: a
/// header, a horizontally scrolling chapter checklist, and a vertical stack of
/// dreamy, soft-focus chapter cards.
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.book, this.circle});

  final BibleBook book;

  /// When non-null, this is a "study with friends" session: the same study,
  /// with a discussion thread woven under each task, a group forum at the
  /// bottom, and the participants tucked behind a header "more" menu. When
  /// null, the page renders as a solo study.
  final StudyCircle? circle;

  /// A wide pool of atmospheric photos and textures the chapter cards draw
  /// from — nature (dune light, water, clouds, forest, sun, bokeh, topical
  /// moods) plus a few patterns (plaster, concrete, plaid, slate). Each study
  /// starts at a different offset into this pool (see [_imageFor]) so no two
  /// studies look alike.
  static const List<String> _cardImages = [
    'assets/covers/blur_dune.jpg',
    'assets/covers/blur_water.jpg',
    'assets/covers/blur_clouds.jpg',
    'assets/covers/blur_forest.jpg',
    'assets/covers/blur_sun.jpg',
    'assets/covers/blur_gold.jpg',
    'assets/covers/topic_hope.jpg',
    'assets/covers/topic_gratitude.jpg',
    'assets/covers/topic_fear.jpg',
    'assets/covers/topic_anxiety.jpg',
    'assets/covers/topic_marriage.jpg',
    'assets/covers/topic_anger.jpg',
    'assets/covers/uns_plaster.jpg',
    'assets/covers/uns_concrete.jpg',
    'assets/covers/uns_plaid.jpg',
    'assets/covers/uns_blackboard.jpg',
  ];

  /// Deterministic per-study image selection: each book title yields a distinct
  /// starting offset, and chapters step through the pool by a coprime stride so
  /// images stay distinct within a study and the whole set differs per study.
  static String _imageFor(String bookTitle, int chapterIndex) {
    var seed = 0;
    for (final c in bookTitle.codeUnits) {
      seed = (seed * 31 + c) & 0x7fffffff;
    }
    final offset = seed % _cardImages.length;
    final index = (offset + chapterIndex * 3) % _cardImages.length;
    return _cardImages[index];
  }

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with WidgetsBindingObserver {
  Set<String> _read = {};
  StudyProgressData _progress = const StudyProgressData(
    understood: {},
    memorized: {},
    reflected: {},
  );

  final _scrollController = ScrollController();
  final _reflectFocus = FocusNode();

  // ─── Focus session (Layer 1: soft focus, gentle accountability) ─────────────
  Timer? _focusTicker;
  bool _focusActive = false;
  bool _focusAway = false; // true while the app is backgrounded mid-session
  Duration _focusElapsed = Duration.zero;
  Duration? _focusTotal; // null == open-ended ("until I finish")

  // Study-with-friends state (only used when widget.circle != null).
  bool get _friends => widget.circle != null;
  Map<int, String> _answers = {};
  List<String> _ideas = [];
  Map<String, String> _reactions = {};
  Map<String, List<String>> _threadReplies = {};

  String get _studyId => widget.book.title;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
    if (_friends) _loadCircle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_focusActive) return;
    if (state == AppLifecycleState.resumed) {
      // Gentle accountability: no penalty — the timer simply paused while away.
      if (_focusAway) {
        setState(() => _focusAway = false);
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Welcome back — your focus is still going.'),
              duration: Duration(seconds: 2),
            ));
        }
      }
    } else {
      // paused / inactive / hidden: stop counting until they return.
      if (!_focusAway) setState(() => _focusAway = true);
    }
  }

  Future<void> _loadCircle() async {
    final answers = await CircleStore.loadAnswers(_studyId);
    final ideas = await CircleStore.loadIdeas(_studyId);
    final reactions = await CircleStore.loadReactions(_studyId);
    final threads = await CircleStore.loadThreads(_studyId);
    if (!mounted) return;
    setState(() {
      _answers = answers;
      _ideas = ideas;
      _reactions = reactions;
      _threadReplies = threads;
    });
  }

  bool _liked(String postId) => _reactions[postId] == 'like';

  int _likeCount(CirclePost post) => post.likes + (_liked(post.id) ? 1 : 0);

  Future<void> _like(String postId) async {
    await CircleStore.toggleReaction(_studyId, postId, 'like');
    setState(() {
      if (_reactions[postId] == 'like') {
        _reactions.remove(postId);
      } else {
        _reactions[postId] = 'like';
      }
    });
  }

  Future<void> _addThreadReply(String threadId) async {
    final text = await composeCircleText(
      context,
      title: 'Add a comment',
      hint: 'Share what this stirred in you\u2026',
      accent: widget.book.color,
    );
    if (text == null || text.trim().isEmpty) return;
    await CircleStore.addThreadReply(_studyId, threadId, text);
    setState(() {
      _threadReplies[threadId] = [...?_threadReplies[threadId], text.trim()];
    });
  }

  Future<void> _answerQuestion(int index) async {
    final text = await composeCircleText(
      context,
      title: widget.circle!.questions[index],
      hint: 'Share your thoughts\u2026',
      accent: widget.book.color,
      initial: _answers[index],
    );
    if (text == null) return;
    await CircleStore.saveAnswer(_studyId, index, text);
    setState(() {
      if (text.trim().isEmpty) {
        _answers.remove(index);
      } else {
        _answers[index] = text.trim();
      }
    });
  }

  Future<void> _shareThought() async {
    final text = await composeCircleText(
      context,
      title: 'Share your thoughts',
      hint: 'A verse, a connection, a question for the group\u2026',
      accent: widget.book.color,
    );
    if (text == null || text.trim().isEmpty) return;
    await CircleStore.addIdea(_studyId, text);
    setState(() => _ideas.add(text.trim()));
  }

  DiscussionThread _thread(String threadId) {
    return DiscussionThread(
      seededPosts: widget.circle!.seedThreadPosts(threadId),
      yourReplies: _threadReplies[threadId] ?? const [],
      accent: widget.book.color,
      liked: _liked,
      likeCount: _likeCount,
      onLike: _like,
      onAddReply: () => _addThreadReply(threadId),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusTicker?.cancel();
    _scrollController.dispose();
    _reflectFocus.dispose();
    super.dispose();
  }

  // ─── Focus session control ──────────────────────────────────────────────────

  Future<void> _openFocusStarter() async {
    if (_focusActive) return; // already in a session; the bar handles ending
    final minutes = await showFocusStarter(context, accent: widget.book.color);
    if (minutes == null || !mounted) return;
    _startFocus(minutes <= 0 ? null : Duration(minutes: minutes));
  }

  void _startFocus(Duration? total) {
    _focusTicker?.cancel();
    setState(() {
      _focusActive = true;
      _focusAway = false;
      _focusElapsed = Duration.zero;
      _focusTotal = total;
    });
    _focusTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_focusActive || _focusAway) return; // pause counting while away
      setState(() => _focusElapsed += const Duration(seconds: 1));
      final total = _focusTotal;
      if (total != null && _focusElapsed >= total) _completeFocus();
    });
  }

  void _endFocus() {
    _focusTicker?.cancel();
    setState(() => _focusActive = false);
  }

  void _completeFocus() {
    _focusTicker?.cancel();
    final minutes = _focusElapsed.inMinutes;
    setState(() => _focusActive = false);
    showFocusComplete(
      context,
      minutes: minutes < 1 ? 1 : minutes,
      studyTitle: widget.book.title,
      accent: widget.book.color,
    );
  }

  Future<void> _reload() async {
    final read = await ReadProgress.load();
    final progress = await StudyProgress.load();
    if (mounted) setState(() { _read = read; _progress = progress; });
  }

  /// A card is checked when its real passage has been read (persisted) or it
  /// was seeded complete.
  bool _isRead(_StudyEntry entry) =>
      entry.seededComplete || _read.contains(entry.readKey);

  bool _isUnderstood(_StudyEntry entry) =>
      _progress.isUnderstood(_studyId, entry.readerBook, entry.readerChapter);

  Future<void> _openEntry(_StudyEntry entry) async {
    await openReader(
      context,
      bookTitle: entry.readerBook,
      chapter: entry.readerChapter,
      immersive: true,
    );
    // Reading marks chapters read — refresh the checkmarks on return.
    _reload();
  }

  Future<void> _openCommentary(_StudyEntry entry) async {
    await showCommentarySheet(
      context,
      studyId: _studyId,
      book: entry.readerBook,
      chapter: entry.readerChapter,
      accent: widget.book.color,
    );
    _reload();
  }

  // ─── Mastery-circle shortcuts ──────────────────────────────────────────────
  // Tapping a circle jumps straight into that track's next action: the first
  // item that isn't yet complete (falling back to the first item once done).

  void _jumpRead(List<_StudyEntry> entries) {
    if (entries.isEmpty) return;
    _openEntry(entries.firstWhere((e) => !_isRead(e), orElse: () => entries.first));
  }

  void _jumpLearn(List<_StudyEntry> entries) {
    if (entries.isEmpty) return;
    _openCommentary(
        entries.firstWhere((e) => !_isUnderstood(e), orElse: () => entries.first));
  }

  Future<void> _jumpMemorize(List<KeyVerse> keyVerses) async {
    if (keyVerses.isEmpty) return;
    final kv = keyVerses.firstWhere(
      (k) => !_progress.isMemorized(_studyId, k.ref),
      orElse: () => keyVerses.first,
    );
    await startMemorizeForKeyVerse(
      context,
      studyId: _studyId,
      keyVerse: kv,
      accent: widget.book.color,
    );
    _reload();
  }

  Future<void> _jumpReflect() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
    if (mounted) _reflectFocus.requestFocus();
  }

  /// A gentle bottom sheet listing which tracks still need work — shown when the
  /// mastery ring is tapped before the study is complete.
  void _showWhatsLeft({
    required double read,
    required double understand,
    required double memorize,
    required double apply,
  }) {
    final accent = widget.book.color;
    final rows = <(String, bool)>[
      ('Read every chapter', read >= 0.999),
      ('Learn the commentary', understand >= 0.999),
      ('Memorize the key verses', memorize >= 0.999),
      ('Reflect & apply', apply >= 0.999),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final palette = context.palette;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\u2019s left',
                  style: AppFonts.serif(
                      color: palette.ink, fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Finish all four tracks to unlock your capstone.',
                  style: AppFonts.sans(color: palette.inkSoft, fontSize: 13.5),
                ),
                const SizedBox(height: 18),
                for (final r in rows) ...[
                  Row(
                    children: [
                      Icon(
                        r.$2 ? LucideIcons.checkCircle2 : LucideIcons.circle,
                        size: 20,
                        color: r.$2 ? accent : palette.inkFaint,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        r.$1,
                        style: AppFonts.sans(
                          color: r.$2 ? palette.inkSoft : palette.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ).copyWith(
                          decoration:
                              r.$2 ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  double _frac(int done, int total) => total == 0 ? 0 : done / total;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final entries = buildStudyEntries(book);
    final keyVerses = keyVersesFor(book.title);
    final accent = book.color;

    final readFrac = _frac(entries.where(_isRead).length, entries.length);
    final understandFrac = _frac(entries.where(_isUnderstood).length, entries.length);
    final memorizeFrac = keyVerses.isEmpty
        ? 1.0
        : _frac(keyVerses.where((kv) => _progress.isMemorized(_studyId, kv.ref)).length,
            keyVerses.length);
    final applyFrac = _progress.isReflected(_studyId) ? 1.0 : 0.0;
    final mastered =
        (readFrac + understandFrac + memorizeFrac + applyFrac) / 4 >= 0.999;

    return Scaffold(
      backgroundColor: context.palette.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              book: book,
              focusActive: _focusActive,
              onFocus: _openFocusStarter,
              onMore: _friends
                  ? () => showCircleMembers(context, widget.circle!)
                  : null,
            ),
            if (_focusActive)
              FocusBar(
                elapsed: _focusElapsed,
                total: _focusTotal,
                away: _focusAway,
                accent: accent,
                onEnd: _endFocus,
              ),
            MasteryMeter(
              readFrac: readFrac,
              understandFrac: understandFrac,
              memorizeFrac: memorizeFrac,
              applyFrac: applyFrac,
              accent: accent,
              onMastery: mastered
                  ? () => showCapstone(context,
                      studyTitle: book.title, keyVerses: keyVerses, accent: accent)
                  : () => _showWhatsLeft(
                        read: readFrac,
                        understand: understandFrac,
                        memorize: memorizeFrac,
                        apply: applyFrac,
                      ),
              onRead: () => _jumpRead(entries),
              onLearn: () => _jumpLearn(entries),
              onMemorize: keyVerses.isEmpty ? null : () => _jumpMemorize(keyVerses),
              onReflect: _jumpReflect,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                physics: const BouncingScrollPhysics(),
                children: [
                  _SectionLabel(text: 'Read'),
                  const SizedBox(height: 14),
                  for (int index = 0; index < entries.length; index++) ...[
                    _ChapterCard(
                      entry: entries[index],
                      image: StudyScreen._imageFor(book.title, index),
                      isRead: _isRead(entries[index]),
                      understood: _isUnderstood(entries[index]),
                      onTap: () => _openEntry(entries[index]),
                      onCommentary: () => _openCommentary(entries[index]),
                    ),
                    if (_friends)
                      _thread('ch:${entries[index].readerBook}:${entries[index].readerChapter}'),
                    const SizedBox(height: 18),
                  ],
                  const SizedBox(height: 10),
                  _SectionLabel(text: 'Learn'),
                  const SizedBox(height: 14),
                  BibleBitesSection(bites: bitesFor(book.title), accent: accent),
                  const SizedBox(height: 28),
                  _SectionLabel(text: 'Memorize'),
                  const SizedBox(height: 14),
                  for (final kv in keyVerses) ...[
                    KeyVerseCard(
                      studyId: _studyId,
                      keyVerse: kv,
                      memorized: _progress.isMemorized(_studyId, kv.ref),
                      accent: accent,
                      onChanged: _reload,
                    ),
                    if (_friends) _thread('kv:${kv.ref}'),
                    const SizedBox(height: 18),
                  ],
                  const SizedBox(height: 10),
                  _SectionLabel(text: 'Reflect'),
                  const SizedBox(height: 14),
                  ReflectCard(
                    studyId: _studyId,
                    prompt: _reflectPrompt(book.title),
                    accent: accent,
                    onChanged: _reload,
                    focusNode: _reflectFocus,
                  ),
                  if (_friends) ...[
                    _thread('reflect'),
                    const SizedBox(height: 28),
                    GroupForum(
                      circle: widget.circle!,
                      answers: _answers,
                      ideas: _ideas,
                      accent: accent,
                      liked: _liked,
                      likeCount: _likeCount,
                      onLike: _like,
                      onReply: _answerQuestion,
                      onShareThought: _shareThought,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small section divider label used in the study scroll.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppFonts.sans(
        color: context.palette.inkSoft,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// A gentle, study-specific reflection prompt.
String _reflectPrompt(String studyTitle) =>
    'How does $studyTitle speak to your life right now — and what is one step '
    'you can take this week in response?';

class _Header extends StatelessWidget {
  const _Header({required this.book, this.onMore, this.onFocus, this.focusActive = false});

  final BibleBook book;

  /// When set, shows a "more" (participants) button — used in friends mode.
  final VoidCallback? onMore;

  /// Starts a focus session; the icon reflects the active state.
  final VoidCallback? onFocus;
  final bool focusActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Row(
        children: [
          AppIconButton(
            icon: LucideIcons.chevronLeft,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: AppFonts.serif(
                    color: context.palette.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onMore != null)
                  Text(
                    'Study with friends',
                    style: AppFonts.sans(
                      color: context.palette.inkSoft,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (onFocus != null)
            AppIconButton(
              icon: LucideIcons.timer,
              tooltip: focusActive ? 'In focus' : 'Focus session',
              onPressed: onFocus!,
            ),
          if (onFocus != null && onMore != null) const SizedBox(width: 12),
          if (onMore != null)
            AppIconButton(
              icon: LucideIcons.users,
              tooltip: 'Participants',
              onPressed: onMore!,
            ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.entry,
    required this.image,
    required this.isRead,
    required this.understood,
    required this.onTap,
    required this.onCommentary,
  });

  final _StudyEntry entry;
  final String image;
  final bool isRead;
  final bool understood;
  final VoidCallback onTap;
  final VoidCallback onCommentary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tapping a chapter card drops straight into that chapter in the reader's
      // distraction-free immersive mode.
      onTap: onTap,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      // The card grows to fit its full summary (min height keeps the shorter
      // cards looking substantial). The photo + scrims fill whatever height the
      // content settles on, so nothing gets clipped.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 236),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(image, fit: BoxFit.cover, cacheWidth: 800),
            ),
            // Uniform 30% black overlay across the whole card for a consistent,
            // moodier tone regardless of the underlying photo/pattern.
            const Positioned.fill(child: ColoredBox(color: Color(0x4D000000))),
            // Legibility scrim, heavier toward the bottom where the text sits.
            // These photos are often bright, so the bottom is nearly opaque.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x14000000),
                      Color(0xE0000000),
                    ],
                    stops: [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _NumberPill(label: entry.pillLabel.toUpperCase()),
                      const Spacer(),
                      _CommentaryButton(active: understood, onTap: onCommentary),
                      const SizedBox(width: 8),
                      _CardCheckbox(checked: isRead),
                    ],
                  ),
                  const SizedBox(height: 96),
                  Text(
                    entry.title,
                    style: AppFonts.serif(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.05,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.preview,
                    style: AppFonts.sans(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _NumberPill extends StatelessWidget {
  const _NumberPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.sans(
          color: AppPalette.light.ink,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Small translucent button on a chapter card that opens Matthew Henry's
/// commentary for that passage. Fills in once the commentary has been opened.
class _CommentaryButton extends StatelessWidget {
  const _CommentaryButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
        ),
        child: Icon(
          LucideIcons.lightbulb,
          size: 15,
          color: active ? AppPalette.light.ink : Colors.white,
        ),
      ),
    );
  }
}

class _CardCheckbox extends StatelessWidget {
  const _CardCheckbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? Colors.white.withValues(alpha: 0.92) : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
      ),
      child: checked
          ? Icon(LucideIcons.check, size: 17, color: AppPalette.light.ink)
          : null,
    );
  }
}

