import 'package:flutter/material.dart';

import '../theme.dart';

/// The app's single circular icon-button system.
///
/// Standardizes container shape, size, and icon sizing so every icon affordance
/// (theme toggle, reader back, close, etc.) looks identical. Icons come from the
/// Lucide set (one consistent stroke weight). Use [AppIconButton.primary] for the
/// single elevated accent action — the library FAB.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.background,
    this.foreground,
    this.tooltip,
  }) : size = 44,
       iconSize = 21,
       elevation = 0;

  /// Elevated, filled primary action (the FAB): larger and shadowed.
  const AppIconButton.primary({
    super.key,
    required this.icon,
    required this.onPressed,
    this.background,
    this.foreground,
    this.tooltip,
  }) : size = 52,
       iconSize = 24,
       elevation = 4;

  final IconData icon;
  final VoidCallback? onPressed;

  /// Container fill. Defaults to a subtle surface (or paper for the primary FAB).
  final Color? background;

  /// Icon color. Defaults to the primary ink color.
  final Color? foreground;

  final String? tooltip;
  final double size;
  final double iconSize;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final bg =
        background ??
        (elevation > 0 ? context.palette.paper : context.palette.paperDim);
    final fg = foreground ?? context.palette.ink;

    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        elevation: elevation,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, size: iconSize, color: fg),
        ),
      ),
    );

    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
  }
}
