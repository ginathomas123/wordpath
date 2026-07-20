import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../app/fonts.dart';
import '../../../app/theme.dart';
import '../../../data/study_progress.dart';
import '../../reader/data/bible_data.dart' as reader;
import '../../reader/data/bible_repository.dart';
import '../data/commentary_repository.dart';
import '../data/key_verses.dart';
import 'memorize_session.dart';

// ─── Mastery meter ────────────────────────────────────────────────────────────

/// A study's overall mastery, shown as a progress ring plus four track pips:
/// Read · Understand · Memorize · Apply. Each track is a 0–1 fraction; the ring
/// is their average. When all four are full, a capstone action appears.
class MasteryMeter extends StatelessWidget {
  const MasteryMeter({
    super.key,
    required this.readFrac,
    required this.understandFrac,
    required this.memorizeFrac,
    required this.applyFrac,
    required this.accent,
    this.onCapstone,
  });

  final double readFrac;
  final double understandFrac;
  final double memorizeFrac;
  final double applyFrac;
  final Color accent;
  final VoidCallback? onCapstone;

  double get overall =>
      (readFrac + understandFrac + memorizeFrac + applyFrac) / 4;

  bool get mastered => overall >= 0.999;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mastery',
            style: AppFonts.sans(
              color: palette.inkSoft,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              _MeterCell(
                onTap: mastered ? onCapstone : null,
                child: _ProgressItem(value: overall, accent: accent, mastered: mastered),
              ),
              const SizedBox(width: 8),
              _MeterCell(child: _TrackItem(icon: LucideIcons.bookOpen, label: 'Read', frac: readFrac, accent: accent)),
              const SizedBox(width: 8),
              _MeterCell(child: _TrackItem(icon: LucideIcons.bookMarked, label: 'Learn', frac: understandFrac, accent: accent)),
              const SizedBox(width: 8),
              _MeterCell(child: _TrackItem(icon: LucideIcons.brain, label: 'Memorize', frac: memorizeFrac, accent: accent)),
              const SizedBox(width: 8),
              _MeterCell(child: _TrackItem(icon: LucideIcons.sprout, label: 'Reflect', frac: applyFrac, accent: accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One outlined cell in the mastery row, holding a single track item.
class _MeterCell extends StatelessWidget {
  const _MeterCell({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: palette.inkFaint.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The leading "Progress" item: a small ring showing the overall percentage.
class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.value,
    required this.accent,
    required this.mastered,
  });
  final double value;
  final Color accent;
  final bool mastered;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: CustomPaint(
            painter: _RingPainter(
              value: value,
              accent: accent,
              track: palette.inkFaint.withValues(alpha: 0.3),
            ),
            child: Center(
              child: mastered
                  ? Icon(LucideIcons.award, color: accent, size: 18)
                  : Text(
                      '${(value * 100).round()}%',
                      style: AppFonts.sans(
                        color: palette.ink,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Progress',
          style: AppFonts.sans(
            color: palette.inkSoft,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.accent, required this.track});
  final double value;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (value > 0) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = accent;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * value.clamp(0.0, 1.0),
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.accent != accent || old.track != track;
}

/// One track badge in the mastery row: a circular icon that fills with the
/// accent and shows a check when the track is complete.
class _TrackItem extends StatelessWidget {
  const _TrackItem({required this.icon, required this.label, required this.frac, required this.accent});
  final IconData icon;
  final String label;
  final double frac;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final done = frac >= 0.999;
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? accent : Colors.transparent,
            border: Border.all(
              color: done ? accent : palette.inkFaint.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Icon(
            done ? LucideIcons.check : icon,
            size: 17,
            color: done ? Colors.white : palette.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppFonts.sans(
            color: palette.inkSoft,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Commentary sheet (Understand) ─────────────────────────────────────────────

/// Opens Matthew Henry's commentary for a passage in a bottom sheet, and marks
/// the passage "understood" for the study.
Future<void> showCommentarySheet(
  BuildContext context, {
  required String studyId,
  required String book,
  required int chapter,
  required Color accent,
}) async {
  await StudyProgress.markUnderstood(studyId, book, chapter);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => _CommentarySheet(book: book, chapter: chapter, accent: accent),
  );
}

class _CommentarySheet extends StatelessWidget {
  const _CommentarySheet({required this.book, required this.chapter, required this.accent});
  final String book;
  final int chapter;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.inkFaint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Icon(LucideIcons.lightbulb, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$book $chapter',
                          style: AppFonts.serif(
                            color: palette.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Matthew Henry's Commentary",
                          style: AppFonts.sans(color: palette.inkSoft, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.inkFaint.withValues(alpha: 0.3)),
            Expanded(
              child: FutureBuilder<List<CommentaryVerse>>(
                future: CommentaryRepository.fetch(book, chapter),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: accent));
                  }
                  if (snap.hasError || (snap.data?.isEmpty ?? true)) {
                    return _sheetMessage(
                      context,
                      snap.hasError
                          ? "Couldn't load commentary. Check your connection."
                          : 'No commentary available for this passage.',
                    );
                  }
                  final verses = snap.data!;
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    itemCount: verses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 18),
                    itemBuilder: (context, i) {
                      final v = verses[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verse ${v.number}',
                            style: AppFonts.sans(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            v.text,
                            style: AppFonts.serif(
                              color: palette.ink,
                              fontSize: 16,
                              height: 1.55,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sheetMessage(BuildContext context, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppFonts.sans(color: context.palette.inkSoft, fontSize: 14),
          ),
        ),
      );
}

// ─── Key verse (Memorize) ───────────────────────────────────────────────────

/// A memorization card: the real verse text (fetched), a self-test hide toggle,
/// a "memorized" switch, and — where verified — a Spurgeon reflection.
class KeyVerseCard extends StatefulWidget {
  const KeyVerseCard({
    super.key,
    required this.studyId,
    required this.keyVerse,
    required this.memorized,
    required this.accent,
    required this.onChanged,
  });

  final String studyId;
  final KeyVerse keyVerse;
  final bool memorized;
  final Color accent;
  final VoidCallback onChanged;

  @override
  State<KeyVerseCard> createState() => _KeyVerseCardState();
}

class _KeyVerseCardState extends State<KeyVerseCard> {
  String? _text;
  bool _loading = true;
  bool _error = false;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rb = _readerBook(widget.keyVerse.book);
      if (rb == null) throw Exception('unknown book');
      final content = await BibleRepository.fetchChapter(rb.chapterUrl(widget.keyVerse.chapter));
      final text = content.verses
          .where((v) => widget.keyVerse.verses.contains(v.number))
          .map((v) => v.text)
          .join(' ');
      if (mounted) setState(() { _text = text; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = true; _loading = false; });
    }
  }

  /// Launches the progressive first-letter memorization flow. Completing it
  /// marks the key verse memorized.
  Future<void> _startMemorize() async {
    final text = _text;
    if (text == null || text.isEmpty) return;
    final done = await openMemorizeSession(
      context,
      studyId: widget.studyId,
      ref: widget.keyVerse.ref,
      text: text,
      accent: widget.accent,
    );
    if (done && mounted) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final kv = widget.keyVerse;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.paperDim.withValues(alpha: palette.isDark ? 0.5 : 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.brain, size: 16, color: widget.accent),
              const SizedBox(width: 8),
              Text(
                'KEY VERSE · ${kv.ref.toUpperCase()}',
                style: AppFonts.sans(
                  color: widget.accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: widget.accent),
              ),
            )
          else if (_error)
            Text(
              'Couldn\u2019t load the verse. Check your connection.',
              style: AppFonts.sans(color: palette.inkSoft, fontSize: 14),
            )
          else
            _VerseText(text: _text ?? '', hidden: _hidden, palette: palette),
          const SizedBox(height: 14),
          Row(
            children: [
              if (!_error && !_loading)
                _smallButton(
                  context,
                  icon: _hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                  label: _hidden ? 'Reveal' : 'Test myself',
                  onTap: () => setState(() => _hidden = !_hidden),
                ),
              const Spacer(),
              if (!_error && !_loading)
                _MemorizedToggle(
                  on: widget.memorized,
                  accent: widget.accent,
                  onTap: _startMemorize,
                ),
            ],
          ),
          if (kv.spurgeon != null) ...[
            const SizedBox(height: 16),
            _SpurgeonBlock(excerpt: kv.spurgeon!, accent: widget.accent),
          ],
        ],
      ),
    );
  }

  Widget _smallButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: palette.inkSoft),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.sans(color: palette.inkSoft, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _VerseText extends StatelessWidget {
  const _VerseText({required this.text, required this.hidden, required this.palette});
  final String text;
  final bool hidden;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      '\u201C$text\u201D',
      style: AppFonts.serif(color: palette.ink, fontSize: 18, height: 1.6),
    );
    if (!hidden) return child;
    return ClipRect(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: child,
      ),
    );
  }
}

class _MemorizedToggle extends StatelessWidget {
  const _MemorizedToggle({required this.on, required this.accent, required this.onTap});
  final bool on;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              on ? LucideIcons.check : LucideIcons.brain,
              size: 15,
              color: on ? Colors.white : accent,
            ),
            const SizedBox(width: 5),
            Text(
              on ? 'Memorized' : 'Memorize',
              style: AppFonts.sans(
                color: on ? Colors.white : accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpurgeonBlock extends StatelessWidget {
  const _SpurgeonBlock({required this.excerpt, required this.accent});
  final SpurgeonExcerpt excerpt;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPURGEON ON THIS VERSE',
            style: AppFonts.sans(
              color: palette.inkSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            excerpt.text,
            style: AppFonts.serif(
              color: palette.ink,
              fontSize: 15,
              height: 1.55,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            excerpt.source,
            style: AppFonts.sans(color: palette.inkFaint, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Reflect (Apply) ───────────────────────────────────────────────────────

/// A reflection prompt with a saved journal entry. Writing anything marks the
/// Apply track complete.
class ReflectCard extends StatefulWidget {
  const ReflectCard({
    super.key,
    required this.studyId,
    required this.prompt,
    required this.accent,
    required this.onChanged,
  });

  final String studyId;
  final String prompt;
  final Color accent;
  final VoidCallback onChanged;

  @override
  State<ReflectCard> createState() => _ReflectCardState();
}

class _ReflectCardState extends State<ReflectCard> {
  final _controller = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    StudyProgress.reflectionText(widget.studyId).then((t) {
      if (mounted && t.isNotEmpty) {
        setState(() { _controller.text = t; _saved = true; });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    await StudyProgress.saveReflectionText(widget.studyId, text);
    await StudyProgress.setReflected(widget.studyId, text.isNotEmpty);
    if (!mounted) return;
    setState(() => _saved = text.isNotEmpty);
    widget.onChanged();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.paperDim.withValues(alpha: palette.isDark ? 0.5 : 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sprout, size: 16, color: widget.accent),
              const SizedBox(width: 8),
              Text(
                'REFLECT & APPLY',
                style: AppFonts.sans(
                  color: widget.accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (_saved) Icon(LucideIcons.check, size: 16, color: widget.accent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.prompt,
            style: AppFonts.serif(color: palette.ink, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 3,
            style: AppFonts.sans(color: palette.ink, fontSize: 14, height: 1.4),
            decoration: InputDecoration(
              hintText: 'Write your reflection\u2026',
              hintStyle: AppFonts.sans(color: palette.inkFaint, fontSize: 14),
              filled: true,
              fillColor: palette.paper,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.inkFaint.withValues(alpha: 0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.inkFaint.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.accent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Save',
                  style: AppFonts.sans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Capstone ────────────────────────────────────────────────────────────────

/// A celebratory summary shown when all four tracks are complete.
Future<void> showCapstone(
  BuildContext context, {
  required String studyTitle,
  required List<KeyVerse> keyVerses,
  required Color accent,
}) async {
  final palette = context.palette;
  await showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: palette.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.15)),
              child: Icon(LucideIcons.award, size: 32, color: accent),
            ),
            const SizedBox(height: 16),
            Text(
              'Mastered',
              style: AppFonts.sans(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              studyTitle,
              textAlign: TextAlign.center,
              style: AppFonts.serif(color: palette.ink, fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'You\u2019ve read the passages, studied the commentary, hidden the '
              'Word in your heart, and put it into practice.',
              textAlign: TextAlign.center,
              style: AppFonts.sans(color: palette.inkSoft, fontSize: 14, height: 1.5),
            ),
            if (keyVerses.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'VERSES LEARNED',
                style: AppFonts.sans(
                  color: palette.inkFaint,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              for (final kv in keyVerses)
                Text(
                  kv.ref,
                  style: AppFonts.serif(color: palette.ink, fontSize: 16),
                ),
            ],
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(24)),
                child: Text(
                  'Amen',
                  textAlign: TextAlign.center,
                  style: AppFonts.sans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── BibleBites (video section) ───────────────────────────────────────────────

/// A short-form "BibleBite" video. When [youtubeId] is set the player embeds the
/// real YouTube Short; otherwise the thumbnail is an Unsplash portrait
/// placeholder and playback is a styled preview. The [title] is the
/// topic-related heading shown on the card and player.
class BibleBite {
  const BibleBite({required this.image, required this.title, this.youtubeId});
  final String image;
  final String title;
  final String? youtubeId;
}

const List<String> _peoplePool = [
  'assets/people/person_1.jpg',
  'assets/people/person_2.jpg',
  'assets/people/person_3.jpg',
  'assets/people/person_4.jpg',
  'assets/people/person_5.jpg',
  'assets/people/person_6.jpg',
  'assets/people/person_7.jpg',
  'assets/people/person_8.jpg',
];

/// Two bites per study. Anxiety is wired to real YouTube Shorts as a preview of
/// what finished bites will look like; every other study still uses placeholder
/// portraits chosen deterministically so each shows a distinct pair of faces.
/// Headings are always tied to the topic.
List<BibleBite> bitesFor(String studyTitle) {
  if (studyTitle.trim().toLowerCase() == 'anxiety') {
    return const [
      BibleBite(
        image: 'assets/people/anxiety_bite1.jpg',
        title: 'What the Bible says about Anxiety',
        youtubeId: 'I1RUy1jOx4U',
      ),
      BibleBite(
        image: 'assets/people/anxiety_bite2.jpg',
        title: '3 verses on Anxiety',
        youtubeId: 'k_DWoaS-4LI',
      ),
    ];
  }
  var seed = 0;
  for (final c in studyTitle.codeUnits) {
    seed = (seed * 31 + c) & 0x7fffffff;
  }
  final a = seed % _peoplePool.length;
  final b = (a + 3) % _peoplePool.length;
  return [
    BibleBite(image: _peoplePool[a], title: 'What the Bible says about $studyTitle'),
    BibleBite(image: _peoplePool[b], title: '3 verses on $studyTitle'),
  ];
}

/// The two-card "BibleBites" video row.
class BibleBitesSection extends StatelessWidget {
  const BibleBitesSection({super.key, required this.bites, required this.accent});
  final List<BibleBite> bites;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.play, size: 15, color: accent),
            const SizedBox(width: 6),
            Text(
              'BIBLEBITES',
              style: AppFonts.sans(
                color: palette.inkSoft,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (int i = 0; i < bites.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(child: _BiteCard(bites: bites, index: i, accent: accent)),
            ],
          ],
        ),
      ],
    );
  }
}

class _BiteCard extends StatelessWidget {
  const _BiteCard({required this.bites, required this.index, required this.accent});
  final List<BibleBite> bites;
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bite = bites[index];
    return GestureDetector(
      onTap: () => _openBitePlayer(context, bites, index, accent),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(bite.image, fit: BoxFit.cover, cacheWidth: 600),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x00000000), Color(0xB3000000)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              const Positioned(top: 10, right: 10, child: _PlayBadge()),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  bite.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.sans(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          child: const Icon(LucideIcons.play, color: Colors.black, size: 13),
        ),
      ),
    );
  }
}

/// Opens the full-screen, TikTok-style placeholder player. Swipe vertically to
/// move to the next bite in the study.
void _openBitePlayer(BuildContext context, List<BibleBite> bites, int index, Color accent) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => _BitePlayer(bites: bites, initialIndex: index, accent: accent),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _BitePlayer extends StatefulWidget {
  const _BitePlayer({required this.bites, required this.initialIndex, required this.accent});
  final List<BibleBite> bites;
  final int initialIndex;
  final Color accent;

  @override
  State<_BitePlayer> createState() => _BitePlayerState();
}

class _BitePlayerState extends State<_BitePlayer> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Vertical swipe moves to the next card, TikTok-style.
      body: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: widget.bites.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, i) => _BitePage(
          bite: widget.bites[i],
          isActive: i == _current,
        ),
      ),
    );
  }
}

class _BitePage extends StatefulWidget {
  const _BitePage({required this.bite, required this.isActive});
  final BibleBite bite;
  final bool isActive;

  @override
  State<_BitePage> createState() => _BitePageState();
}

class _BitePageState extends State<_BitePage> {
  YoutubePlayerController? _yt;

  @override
  void initState() {
    super.initState();
    final id = widget.bite.youtubeId;
    if (id != null) {
      _yt = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: widget.isActive,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: false,
          strictRelatedVideos: true,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(_BitePage old) {
    super.didUpdateWidget(old);
    // Play only the visible page; pause the neighbours the PageView keeps alive.
    if (_yt != null && widget.isActive != old.isActive) {
      if (widget.isActive) {
        _yt!.playVideo();
      } else {
        _yt!.pauseVideo();
      }
    }
  }

  @override
  void dispose() {
    _yt?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_yt != null)
          // Real YouTube Short, centered and sized to fill the height.
          LayoutBuilder(
            builder: (context, c) {
              final width = math.min(c.maxWidth, c.maxHeight * 9 / 16);
              return Center(
                child: SizedBox(
                  width: width,
                  child: YoutubePlayer(controller: _yt!, aspectRatio: 9 / 16),
                ),
              );
            },
          )
        else ...[
          Image.asset(widget.bite.image, fit: BoxFit.cover),
          const Center(child: _PlayBadgeLarge()),
        ],
        // Scrims only over placeholder pages (they'd dim a real video).
        if (_yt == null)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Color(0x00000000), Color(0x00000000), Color(0xB3000000)],
                stops: [0.0, 0.25, 0.6, 1.0],
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: const _CloseBadge(),
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Only the topic-related heading.
                    Expanded(
                      child: Text(
                        widget.bite.title,
                        style: AppFonts.sans(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _RailIcon(icon: LucideIcons.share2, label: 'Share'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Close affordance with a subtle dark disc so it stays visible over a bright
/// video frame.
class _CloseBadge extends StatelessWidget {
  const _CloseBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.4),
      ),
      child: const Icon(LucideIcons.x, color: Colors.white, size: 24),
    );
  }
}

class _PlayBadgeLarge extends StatelessWidget {
  const _PlayBadgeLarge();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          child: const Icon(LucideIcons.play, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(label, style: AppFonts.sans(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}

/// Finds the reader's canonical book for a name, tolerating "Psalm" → "Psalms".
reader.BibleBook? _readerBook(String name) {
  final n = name.trim().toLowerCase();
  for (final b in reader.bibleBooks) {
    if (b.name.toLowerCase() == n) return b;
  }
  for (final b in reader.bibleBooks) {
    if (b.name.toLowerCase() == '${n}s') return b;
  }
  return null;
}
