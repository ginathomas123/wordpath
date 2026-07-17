import 'package:flutter/material.dart';

/// Drives a single element's entrance during the library intro: a fade paired
/// with an upward slide (and optional scale) over a slice [start, end] of the
/// shared intro timeline. Use an overshooting [slideCurve] for a "settle".
class IntroItem extends StatelessWidget {
  const IntroItem({
    super.key,
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
    this.dy = 24,
    this.scaleFrom = 1.0,
    this.slideCurve = Curves.easeOutBack,
  });

  final Animation<double> animation;

  /// Slice of the [0,1] timeline this element animates within.
  final double start;
  final double end;

  /// Starting vertical offset (positive = starts below its final spot).
  final double dy;

  /// Starting scale; eases to 1.0.
  final double scaleFrom;

  final Curve slideCurve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final raw = ((animation.value - start) / (end - start)).clamp(0.0, 1.0);
        final fade = Curves.easeOut.transform(raw);
        final slide = slideCurve.transform(raw);
        final scale = scaleFrom + (1 - scaleFrom) * slide;
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, (1 - slide) * dy),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: child,
    );
  }
}
