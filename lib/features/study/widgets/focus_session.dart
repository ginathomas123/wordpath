import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/fonts.dart';
import '../../../app/theme.dart';

/// A persistent, calm bar shown at the top of the study while a focus session
/// is running. Fixed-length sessions show a countdown ring; open-ended ones
/// count up. Leaving the app pauses the timer (shown as "Paused").
class FocusBar extends StatelessWidget {
  const FocusBar({
    super.key,
    required this.elapsed,
    required this.total,
    required this.away,
    required this.accent,
    required this.onEnd,
  });

  final Duration elapsed;
  final Duration? total;
  final bool away;
  final Color accent;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fixed = total != null;
    final progress =
        fixed ? (elapsed.inSeconds / total!.inSeconds).clamp(0.0, 1.0) : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: palette.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: fixed
                ? CircularProgressIndicator(
                    value: away ? null : progress,
                    strokeWidth: 2.5,
                    backgroundColor: accent.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation(accent),
                  )
                : Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: away ? accent.withValues(alpha: 0.4) : accent,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              away ? 'Focus paused' : 'In focus',
              style: AppFonts.sans(
                color: accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: onEnd,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'End',
                style: AppFonts.sans(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The start sheet: pick a duration (or open-ended) for a focus session.
/// Returns minutes (5/10/15), 0 for "until I finish", or null if dismissed.
Future<int?> showFocusStarter(BuildContext context, {required Color accent}) {
  final palette = context.palette;
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: palette.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: palette.inkFaint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(LucideIcons.timer, size: 20, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'Focus session',
                    style: AppFonts.serif(
                        color: palette.ink, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Quiet the noise and stay with the Word. If you leave the app, '
                'your focus simply pauses \u2014 no pressure.',
                style: AppFonts.sans(color: palette.inkSoft, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 10),
              for (final o in const <(String, String?, int)>[
                ('5 minutes', null, 5),
                ('10 minutes', null, 10),
                ('15 minutes', null, 15),
                ('Until I finish', 'Open-ended \u2014 end whenever you\u2019re done', 0),
              ]) ...[
                if (o.$3 != 5)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: palette.inkFaint.withValues(alpha: 0.4),
                  ),
                _FocusOption(
                  label: o.$1,
                  subtitle: o.$2,
                  accent: accent,
                  palette: palette,
                  onTap: () => Navigator.of(context).pop(o.$3),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _FocusOption extends StatelessWidget {
  const _FocusOption({
    required this.label,
    required this.accent,
    required this.palette,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final Color accent;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppFonts.sans(
                        color: palette.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppFonts.sans(color: palette.inkSoft, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// A gentle celebration shown when a fixed-length focus session completes.
Future<void> showFocusComplete(
  BuildContext context, {
  required int minutes,
  required String studyTitle,
  required Color accent,
}) {
  final palette = context.palette;
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: palette.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.14),
              ),
              child: Icon(LucideIcons.partyPopper, color: accent, size: 30),
            ),
            const SizedBox(height: 18),
            Text(
              'Well focused',
              style: AppFonts.serif(
                  color: palette.ink, fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'You stayed with $studyTitle for $minutes '
              '${minutes == 1 ? 'minute' : 'minutes'} of undivided attention.',
              textAlign: TextAlign.center,
              style: AppFonts.sans(color: palette.inkSoft, fontSize: 14.5, height: 1.4),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Amen',
                  style: AppFonts.sans(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
