import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/fonts.dart';
import '../../../data/study_progress.dart';

/// Opens the progressive first-letter memorization flow for a key verse.
///
/// The screen walks the reader through five passes over the verse. Each pass
/// replaces more of the words with just their first letter, so the brain is
/// forced to *retrieve* the words rather than read them (active recall via
/// cued recall — the fastest, best-evidenced way to move a verse from
/// "recognized" to "known by heart"). A "say it aloud" nudge is built in, which
/// research shows further strengthens verbatim recall.
///
/// Returns `true` if the user finished and the verse was marked memorized.
Future<bool> openMemorizeSession(
  BuildContext context, {
  required String studyId,
  required String ref,
  required String text,
  required Color accent,
}) async {
  final result = await Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) =>
          _MemorizeSession(studyId: studyId, ref: ref, text: text, accent: accent),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
  return result ?? false;
}

class _MemorizeSession extends StatefulWidget {
  const _MemorizeSession({
    required this.studyId,
    required this.ref,
    required this.text,
    required this.accent,
  });

  final String studyId;
  final String ref;
  final String text;
  final Color accent;

  @override
  State<_MemorizeSession> createState() => _MemorizeSessionState();
}

class _MemorizeSessionState extends State<_MemorizeSession> {
  /// How much of the verse is reduced to first letters at each pass.
  static const _fractions = [0.0, 0.3, 0.55, 0.8, 1.0];

  late final List<String> _words;
  late final List<int> _hideOrder;

  int _step = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _words = widget.text.trim().split(RegExp(r'\s+'));
    // A stable pseudo-random order in which words fade out. Seeding from the
    // verse keeps the sequence consistent across passes so hiding is additive.
    var seed = 0;
    for (final c in widget.text.codeUnits) {
      seed = (seed * 31 + c) & 0x7fffffff;
    }
    _hideOrder = List.generate(_words.length, (i) => i)..shuffle(math.Random(seed));
  }

  double get _fraction => _fractions[_step];
  bool get _isFirstStep => _step == 0;
  bool get _isLastStep => _step == _fractions.length - 1;

  Set<int> get _hiddenIndices {
    final count = (_fraction * _words.length).round();
    return _hideOrder.take(count).toSet();
  }

  void _next() {
    if (_isLastStep) return;
    setState(() {
      _step++;
      _revealed = false;
    });
  }

  Future<void> _finish() async {
    await StudyProgress.setMemorized(widget.studyId, widget.ref, true);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Serene landscape backdrop…
          Image.asset('assets/covers/memorize_bg.jpg', fit: BoxFit.cover),
          // …under a fixed black 80% scrim so the text is always white-on-dark
          // and legible over any part of the photo, regardless of app theme.
          const ColoredBox(color: Color(0xCC000000)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(LucideIcons.x, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.ref,
                    style: AppFonts.sans(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ProgressSegments(
                    total: _fractions.length,
                    current: _step,
                    accent: widget.accent,
                    trackColor: Colors.white.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 24),
                  _InstructionLine(step: _step, isLast: _isLastStep, accent: widget.accent),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text.rich(
                        TextSpan(children: _buildSpans()),
                        style: AppFonts.serif(color: Colors.white, fontSize: 24, height: 1.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _actions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildSpans() {
    final hidden = _hiddenIndices;
    final spans = <InlineSpan>[];
    for (var i = 0; i < _words.length; i++) {
      final isHidden = hidden.contains(i);
      final showFull = _revealed || !isHidden;
      if (showFull) {
        spans.add(TextSpan(
          text: _words[i],
          // On reveal, tint the words that were hidden so the check is obvious.
          style: TextStyle(color: (_revealed && isHidden) ? widget.accent : Colors.white),
        ));
      } else {
        spans.add(TextSpan(
          text: _reduce(_words[i]),
          style: TextStyle(color: widget.accent, fontWeight: FontWeight.w700),
        ));
      }
      if (i != _words.length - 1) spans.add(const TextSpan(text: ' '));
    }
    return spans;
  }

  /// Reduces a word to its leading punctuation + first letter + trailing
  /// punctuation, e.g. "nothing;" → "n;".
  String _reduce(String w) {
    final lead = RegExp(r'^[^A-Za-z0-9]*').stringMatch(w) ?? '';
    final trail = RegExp(r'[^A-Za-z0-9]*$').stringMatch(w) ?? '';
    final coreStart = lead.length;
    final coreEnd = w.length - trail.length;
    if (coreEnd <= coreStart) return w;
    return '$lead${w[coreStart]}$trail';
  }

  Widget _actions() {
    if (_isFirstStep) {
      return _PrimaryButton(
        label: 'Begin',
        accent: widget.accent,
        onTap: _next,
      );
    }
    return Row(
      children: [
        Expanded(
          child: _SecondaryButton(
            label: _revealed ? 'Hide' : 'Reveal',
            icon: _revealed ? LucideIcons.eyeOff : LucideIcons.eye,
            onTap: () => setState(() => _revealed = !_revealed),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PrimaryButton(
            label: _isLastStep ? 'I know it' : 'Next',
            accent: widget.accent,
            onTap: _isLastStep ? _finish : _next,
          ),
        ),
      ],
    );
  }
}

class _ProgressSegments extends StatelessWidget {
  const _ProgressSegments({
    required this.total,
    required this.current,
    required this.accent,
    required this.trackColor,
  });

  final int total;
  final int current;
  final Color accent;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i <= current ? accent : trackColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InstructionLine extends StatelessWidget {
  const _InstructionLine({required this.step, required this.isLast, required this.accent});

  final int step;
  final bool isLast;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (step == 0) {
      text = 'Read it aloud, slowly, twice.';
    } else if (isLast) {
      text = 'Now say the whole verse from memory.';
    } else {
      text = 'Recite it aloud from memory, then reveal to check.';
    }
    return Row(
      children: [
        Icon(LucideIcons.volume2, size: 16, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppFonts.sans(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.accent, required this.onTap});

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: AppFonts.sans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: Colors.white),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppFonts.sans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
