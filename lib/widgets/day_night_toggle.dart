import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Day / night switch. Sun slides to a moon, clouds sink away and stars
/// fade in while the sky changes color. Tap anywhere on it to toggle.
class DayNightToggle extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const DayNightToggle({
    super.key,
    required this.isDark,
    required this.onChanged,
  });

  static const double _w = 84;
  static const double _h = 40;
  static const double _pad = 4;
  static const double _thumb = _h - _pad * 2;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: isDark,
      button: true,
      label: 'Day and night theme',
      child: GestureDetector(
        onTap: () => onChanged(!isDark),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: isDark ? 1 : 0),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
          builder: (context, t, _) => _body(t),
        ),
      ),
    );
  }

  Widget _body(double t) {
    final sky = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(const Color(0xFF6EC6FF), const Color(0xFF0B1230), t)!,
        Color.lerp(const Color(0xFF2F80ED), const Color(0xFF26337A), t)!,
      ],
    );

    return Container(
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_h / 2),
        gradient: sky,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_h / 2),
        child: Stack(
          children: [
            // Stars (night)
            for (final s in _stars) _star(s, t),

            // Clouds (day) sink down as it gets dark
            Positioned(
              right: 6,
              bottom: -10 - 34 * t,
              child: Opacity(
                opacity: (1 - t * 1.4).clamp(0.0, 1.0),
                child: _cloud(30),
              ),
            ),
            Positioned(
              right: 28,
              bottom: -14 - 34 * t,
              child: Opacity(
                opacity: (1 - t * 1.4).clamp(0.0, 1.0),
                child: _cloud(22),
              ),
            ),

            // Sun -> Moon
            Positioned(
              left: _pad + (_w - _pad * 2 - _thumb) * t,
              top: _pad,
              child: Transform.rotate(
                angle: t * math.pi * 0.9,
                child: _sunMoon(t),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sunMoon(double t) {
    final color = Color.lerp(
      const Color(0xFFFFC93C),
      const Color(0xFFE9ECF5),
      t,
    )!;
    return Container(
      width: _thumb,
      height: _thumb,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.65 * (1 - t)),
            blurRadius: 12,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.28 * t),
            blurRadius: 9,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Opacity(
        opacity: t,
        child: Stack(
          children: [_crater(20, 6, 8), _crater(7, 14, 6), _crater(19, 20, 5)],
        ),
      ),
    );
  }

  Widget _crater(double x, double y, double size) => Positioned(
    left: x,
    top: y,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFB8BFD6).withValues(alpha: 0.8),
      ),
    ),
  );

  Widget _cloud(double size) {
    Widget puff(double s) => Container(
      width: s,
      height: s,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
    return SizedBox(
      width: size * 1.7,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, bottom: 0, child: puff(size * 0.6)),
          Positioned(left: size * 0.35, bottom: 0, child: puff(size)),
          Positioned(left: size * 0.9, bottom: 0, child: puff(size * 0.7)),
        ],
      ),
    );
  }

  static const List<_Star> _stars = [
    _Star(0.14, 0.24, 3.2),
    _Star(0.30, 0.62, 2.2),
    _Star(0.40, 0.20, 2.6),
    _Star(0.24, 0.45, 1.8),
    _Star(0.52, 0.68, 2.0),
    _Star(0.58, 0.30, 1.6),
  ];

  Widget _star(_Star s, double t) {
    return Positioned(
      left: _w * s.dx,
      top: _h * s.dy,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.4 + 0.6 * t,
          child: Container(
            width: s.size,
            height: s.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Star {
  final double dx;
  final double dy;
  final double size;
  const _Star(this.dx, this.dy, this.size);
}
