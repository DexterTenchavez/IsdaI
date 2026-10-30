import 'dart:ui';
import 'package:flutter/material.dart';

/// "Liquid glass" surface: blurred + color-boosted backdrop, a soft tinted
/// fill, a bright rim that fades around the edge (light catching the glass),
/// a top sheen and a floating shadow.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double? height;
  final Color tint;
  final double blur;

  /// Overall strength of the fill (0 = clear glass, 1 = frosted).
  final double opacity;

  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = 32,
    this.height,
    this.tint = Colors.white,
    this.blur = 14,
    this.opacity = 1,
  });

  // Saturation boost (1.6x) so the water behind the glass looks richer,
  // like real refraction, instead of just washed out.
  static const ColorFilter _saturate = ColorFilter.matrix(<double>[
    1.4722, -0.4290, -0.0432, 0, 0, //
    -0.1278, 1.1710, -0.0432, 0, 0, //
    -0.1278, -0.4290, 1.5568, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = opacity;
    final top = tint.withValues(alpha: (isDark ? 0.30 : 0.36) * a);
    final bottom = tint.withValues(alpha: (isDark ? 0.10 : 0.12) * a);
    final r = BorderRadius.circular(radius);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: _saturate, // was ImageFilter.colorFilter(_saturate)
            inner: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [top, bottom],
              ),
            ),
            child: CustomPaint(
              foregroundPainter: LiquidRimPainter(radius: radius),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the glossy rim + top sheen. Also used by the sliding "lens" pill.
class LiquidRimPainter extends CustomPainter {
  final double radius;
  const LiquidRimPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Top sheen (upper half only)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.5), Radius.circular(radius)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.26),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5)),
    );
    canvas.restore();

    // Rim: bright top-left, fades, bright again bottom-right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(0.8),
        Radius.circular((radius - 0.8).clamp(0, double.infinity)),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.60),
          ],
          stops: const [0, 0.35, 0.65, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant LiquidRimPainter old) => old.radius != radius;
}
