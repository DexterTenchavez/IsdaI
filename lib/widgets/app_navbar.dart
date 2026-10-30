import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    // viewPadding = the real system bars (not changed by Scaffold/keyboard)
    final view = MediaQuery.viewPaddingOf(context);
    final threeButton = view.bottom >= _threeButtonInset;

    // 3-button: sit fully above the buttons with a clear gap.
    // Gesture / none: hug the bottom, just above the gesture pill.
    final bottomGap = threeButton
        ? view.bottom + 10
        : math.max(view.bottom + 6, 18.0);

    // In landscape the 3-button bar can move to the side, so respect that too.
    final leftGap = 20.0 + view.left;
    final rightGap = 20.0 + view.right;

    // A bit more solid in 3-button mode so it doesn't blur into the buttons.
    final glassAlpha = threeButton ? 0.78 : 0.55;
    final pal = context.pal;

    return Padding(
      padding: EdgeInsets.fromLTRB(leftGap, 0, rightGap, bottomGap),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: pal.navGlass.withValues(alpha: glassAlpha),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: pal.navBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.camera_alt_rounded,
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _LiveNavItem(
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  selected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? context.pal.link.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          size: 26,
          color: selected ? context.pal.link : context.pal.muted,
        ),
      ),
    );
  }
}

/// Live item with a video-camera icon + pulsing "LIVE" badge.
class _LiveNavItem extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;

  const _LiveNavItem({required this.selected, required this.onTap});

  @override
  State<_LiveNavItem> createState() => _LiveNavItemState();
}

class _LiveNavItemState extends State<_LiveNavItem>
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
    final color = widget.selected ? context.pal.link : context.pal.muted;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: widget.selected
              ? context.pal.link.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(Icons.videocam_rounded, size: 26, color: color),
            Positioned(
              top: -6,
              right: -14,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final glow = 4 + (_pulse.value * 6);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
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
        ),
      ),
    );
  }
}
