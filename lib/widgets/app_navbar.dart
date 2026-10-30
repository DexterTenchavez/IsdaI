import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'liquid_glass.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavBar({super.key, required this.currentIndex, required this.onTap});

  /// Flutter has no official "which navigation mode?" API, so we read the
  /// system bottom inset instead:
  ///   - 3-button bar (Back / Home / Recents): about 48dp
  ///   - gesture pill: about 16-24dp
  ///   - no inset (older Android, not edge-to-edge): 0
  static const double _threeButtonInset = 32;
  static const double _barHeight = 68;
  static const int _itemCount = 4;

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.viewPaddingOf(context);
    final threeButton = view.bottom >= _threeButtonInset;

    final bottomGap = threeButton
        ? view.bottom + 10
        : math.max(view.bottom + 6, 18.0);

    final leftGap = 20.0 + view.left;
    final rightGap = 20.0 + view.right;

    final pal = context.pal;

    return Padding(
      padding: EdgeInsets.fromLTRB(leftGap, 0, rightGap, bottomGap),
      child: LiquidGlass(
        height: _barHeight,
        radius: 34,
        tint: pal.navGlass,
        blur: 16,
        // A bit more solid in 3-button mode so it doesn't blur into the buttons
        opacity: threeButton ? 1.3 : 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotW = constraints.maxWidth / _itemCount;
            const inset = 6.0;

            return Stack(
              children: [
                // Liquid "lens" that slides (with a little overshoot) to the
                // selected item.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutBack,
                  left: currentIndex * slotW + inset,
                  top: 7,
                  width: slotW - inset * 2,
                  height: _barHeight - 14,
                  child: const _LensPill(),
                ),
                Row(
                  children: [
                    _slot(
                      child: _icon(context, Icons.home_rounded, 0),
                      index: 0,
                    ),
                    _slot(
                      child: _icon(context, Icons.camera_alt_rounded, 1),
                      index: 1,
                    ),
                    _slot(
                      child: _LiveIcon(selected: currentIndex == 2),
                      index: 2,
                    ),
                    _slot(
                      child: _icon(context, Icons.settings_rounded, 3),
                      index: 3,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _slot({required Widget child, required int index}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Center(child: child),
      ),
    );
  }

  Widget _icon(BuildContext context, IconData icon, int index) {
    final pal = context.pal;
    final selected = currentIndex == index;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: selected ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => Transform.scale(
        scale: 1 + 0.12 * t,
        child: Icon(
          icon,
          size: 26,
          color: Color.lerp(pal.muted, pal.link, t.clamp(0.0, 1.0)),
        ),
      ),
    );
  }
}

/// The glass bubble behind the selected icon.
class _LensPill extends StatelessWidget {
  const _LensPill();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const r = 26.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.22 : 0.55),
            Colors.white.withValues(alpha: isDark ? 0.06 : 0.16),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const CustomPaint(foregroundPainter: LiquidRimPainter(radius: r)),
    );
  }
}

/// Live item with a video-camera icon + pulsing "LIVE" badge.
class _LiveIcon extends StatefulWidget {
  final bool selected;
  const _LiveIcon({required this.selected});

  @override
  State<_LiveIcon> createState() => _LiveIconState();
}

class _LiveIconState extends State<_LiveIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final color = widget.selected ? pal.link : pal.muted;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedScale(
          scale: widget.selected ? 1.12 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: Icon(Icons.videocam_rounded, size: 26, color: color),
        ),
        Positioned(
          top: -6,
          right: -14,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final glow = 4 + (_pulse.value * 6);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.6),
                      blurRadius: glow,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
