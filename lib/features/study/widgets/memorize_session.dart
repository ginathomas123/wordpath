import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  late final List<String> _normWords;
  late final List<int> _hideOrder;
  late final int _scorableCount;

  int _step = 0;
  bool _revealed = false;

  // Voice recall (final step).
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  String _transcript = '';
  Set<int> _matched = <int>{};
  double? _accuracy; // null until an attempt has been scored

  @override
  void initState() {
    super.initState();
    _words = widget.text.trim().split(RegExp(r'\s+'));
    _normWords = _words.map(_norm).toList();
    _scorableCount = _normWords.where((w) => w.isNotEmpty).length;
    // A stable pseudo-random order in which words fade out. Seeding from the
    // verse keeps the sequence consistent across passes so hiding is additive.
    var seed = 0;
    for (final c in widget.text.codeUnits) {
      seed = (seed * 31 + c) & 0x7fffffff;
    }
    _hideOrder = List.generate(_words.length, (i) => i)..shuffle(math.Random(seed));
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final ready = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (mounted) setState(() => _speechReady = ready);
    } catch (_) {
      if (mounted) setState(() => _speechReady = false);
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    final done = status == 'notListening' || status == 'done';
    if (done && _listening) {
      setState(() {
        _listening = false;
        _accuracy = _scorableCount == 0 ? 0 : _matched.length / _scorableCount;
      });
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  bool get _voiceMode => _isLastStep && _speechReady;

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    setState(() {
      _listening = true;
      _transcript = '';
      _matched = <int>{};
      _accuracy = null;
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final spoken = result.recognizedWords
            .split(RegExp(r'\s+'))
            .map(_norm)
            .where((w) => w.isNotEmpty)
            .toList();
        setState(() {
          _transcript = result.recognizedWords;
          _matched = _alignMatched(_normWords, spoken);
          if (result.finalResult) {
            _accuracy = _scorableCount == 0 ? 0 : _matched.length / _scorableCount;
          }
        });
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
      ),
    );
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
                  _InstructionLine(
                    step: _step,
                    isLast: _isLastStep,
                    accent: widget.accent,
                    voiceMode: _voiceMode,
                    listening: _listening,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text.rich(
                        TextSpan(children: _buildSpans()),
                        style: AppFonts.serif(color: Colors.white, fontSize: 24, height: 1.7),
                      ),
                    ),
                  ),
                  _resultLine(),
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
    // Karaoke recall: words light up (full, in accent) as they're spoken;
    // everything else stays reduced to first letters so it's still a memory test.
    if (_voiceMode && !_revealed) {
      final spans = <InlineSpan>[];
      for (var i = 0; i < _words.length; i++) {
        final matched = _matched.contains(i);
        spans.add(TextSpan(
          text: matched ? _words[i] : _reduce(_words[i]),
          style: TextStyle(
            color: matched ? widget.accent : Colors.white.withValues(alpha: 0.4),
            fontWeight: matched ? FontWeight.w700 : FontWeight.w400,
          ),
        ));
        if (i != _words.length - 1) spans.add(const TextSpan(text: ' '));
      }
      return spans;
    }
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

  /// Feedback shown under the verse during the voice-recall step: the live
  /// transcript while listening, and a score once an attempt is scored.
  Widget _resultLine() {
    if (!_voiceMode) return const SizedBox.shrink();
    if (_listening) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          _transcript.isEmpty ? 'Listening\u2026' : _transcript,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.sans(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    final acc = _accuracy;
    if (acc == null) return const SizedBox.shrink();
    final pct = (acc * 100).round();
    final passed = acc >= 0.85;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(
            passed ? LucideIcons.partyPopper : LucideIcons.rotateCcw,
            size: 18,
            color: passed ? widget.accent : Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              passed
                  ? '$pct% \u2014 you\u2019ve got it by heart!'
                  : '$pct% \u2014 close! give it another go',
              style: AppFonts.sans(
                color: passed ? widget.accent : Colors.white.withValues(alpha: 0.85),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    if (_isFirstStep) {
      return _PrimaryButton(
        label: 'Begin',
        accent: widget.accent,
        onTap: _next,
      );
    }
    // Final step with a working mic: recite it out loud for the karaoke check.
    if (_voiceMode) {
      return Column(
        children: [
          _MicButton(
            listening: _listening,
            attempted: _accuracy != null,
            accent: widget.accent,
            onTap: _toggleListen,
          ),
          const SizedBox(height: 12),
          Row(
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
                  label: 'Mark memorized',
                  accent: widget.accent,
                  onTap: _finish,
                ),
              ),
            ],
          ),
        ],
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

// ─── Lenient verse matching ──────────────────────────────────────────────────

/// Strips a word down to its lowercase letters/digits, e.g. "nothing;" →
/// "nothing". Punctuation and case never count against the reciter.
String _norm(String w) {
  final b = StringBuffer();
  for (final c in w.toLowerCase().codeUnits) {
    final isLower = c >= 0x61 && c <= 0x7a;
    final isDigit = c >= 0x30 && c <= 0x39;
    if (isLower || isDigit) b.writeCharCode(c);
  }
  return b.toString();
}

/// Levenshtein edit distance, capped for short strings.
int _lev(String a, String b) {
  final n = a.length, m = b.length;
  if (n == 0) return m;
  if (m == 0) return n;
  var prev = List<int>.generate(m + 1, (j) => j);
  var curr = List<int>.filled(m + 1, 0);
  for (var i = 1; i <= n; i++) {
    curr[0] = i;
    for (var j = 1; j <= m; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      curr[j] = math.min(
        math.min(curr[j - 1] + 1, prev[j] + 1),
        prev[j - 1] + cost,
      );
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[m];
}

/// Two spoken words count as the same word if they're identical after
/// normalizing, or within one edit for words of length ≥ 4 (tolerates STT
/// near-misses and KJV variants like "thou"/"thee").
bool _fuzzyEq(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  if (math.max(a.length, b.length) < 4) return false;
  return _lev(a, b) <= 1;
}

/// Aligns the [spoken] words against the [target] words with an LCS so that
/// dropped or extra words don't derail the sequence, and returns the set of
/// TARGET indices that were matched (in order). Used both for the live karaoke
/// highlight and the final accuracy score.
Set<int> _alignMatched(List<String> target, List<String> spoken) {
  final n = target.length, m = spoken.length;
  if (n == 0 || m == 0) return <int>{};
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      dp[i][j] = _fuzzyEq(target[i - 1], spoken[j - 1])
          ? dp[i - 1][j - 1] + 1
          : math.max(dp[i - 1][j], dp[i][j - 1]);
    }
  }
  final matched = <int>{};
  var i = n, j = m;
  while (i > 0 && j > 0) {
    if (_fuzzyEq(target[i - 1], spoken[j - 1])) {
      matched.add(i - 1);
      i--;
      j--;
    } else if (dp[i - 1][j] >= dp[i][j - 1]) {
      i--;
    } else {
      j--;
    }
  }
  return matched;
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
  const _InstructionLine({
    required this.step,
    required this.isLast,
    required this.accent,
    this.voiceMode = false,
    this.listening = false,
  });

  final int step;
  final bool isLast;
  final Color accent;
  final bool voiceMode;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final String text;
    final IconData icon;
    if (voiceMode) {
      icon = LucideIcons.mic;
      text = listening
          ? 'Listening\u2026 say the whole verse.'
          : 'Tap the mic and recite the verse from memory.';
    } else if (step == 0) {
      icon = LucideIcons.volume2;
      text = 'Read it aloud, slowly, twice.';
    } else if (isLast) {
      icon = LucideIcons.volume2;
      text = 'Now say the whole verse from memory.';
    } else {
      icon = LucideIcons.volume2;
      text = 'Recite it aloud from memory, then reveal to check.';
    }
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
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

/// The hero "say it" control for the voice-recall step. Pulses a soft glow
/// while listening so it's obvious the mic is live.
class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.listening,
    required this.attempted,
    required this.accent,
    required this.onTap,
  });

  final bool listening;
  final bool attempted;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final label = widget.listening
        ? 'Listening\u2026 tap to stop'
        : (widget.attempted ? 'Try again' : 'Say it');
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = widget.listening ? _pulse.value : 0.0;
          return Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.5 * t),
                  blurRadius: 16 + 16 * t,
                  spreadRadius: 1 + 5 * t,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.listening ? Icons.stop_rounded : LucideIcons.mic,
              size: 21,
              color: Colors.white,
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: AppFonts.sans(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
