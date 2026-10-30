import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'liquid_glass.dart';

/// A content card made of [LiquidGlass]. Use it instead of a plain white
/// Container so every screen shares the same glass look.
///
/// Readability: on top of the blurred glass there is a soft surface fill
/// ([fill]) so dark text (light mode) or light text (dark mode) stays
/// readable even when bright water or a fish passes behind the card.
///
///   GlassCard(child: ...)                       // normal content card
///   GlassCard(onTap: ..., child: ...)           // tappable (ripple included)
///   GlassCard(tint: AppColors.accent, ...)      // colored glass
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Blur strength. Keep it small on cards (8 to 12) to save GPU time.
  final double blur;

  /// Strength of the glass tint (see LiquidGlass.opacity).
  final double opacity;

  /// Glass tint. Defaults to the theme's glass color.
  final Color? tint;

  /// Fill drawn over the glass for readability. Defaults to the theme
  /// surface color at 55%. Pass Colors.transparent for pure glass.
  final Color? fill;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.blur = 10,
    this.opacity = 2.0,
    this.tint,
    this.fill,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    return LiquidGlass(
      radius: radius,
      blur: blur,
      opacity: opacity,
      tint: tint ?? pal.navGlass,
      child: Material(
        // Material (not a Container) so the InkWell ripple shows up.
        color: fill ?? pal.surface.withValues(alpha: 0.55),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
