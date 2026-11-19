import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/language/app_language.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/underwater_background.dart';
import '../history/history_screen.dart';
import '../info/fish_info_screen.dart';
import '../about/about_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Switches tabs in MainNavigationWrapper:
  /// 0 = home, 1 = camera, 2 = live scan, 3 = settings.
  final ValueChanged<int> onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _guideController = PageController();
  Timer? _autoSlide;
  int _guidePage = 0;

  // Text comes from the translation table by key.
  final List<_GuideSlide> _slides = const [
    _GuideSlide(
      icon: Icons.visibility_rounded,
      titleKey: 'guide1_title',
      descKey: 'guide1_desc',
    ),
    _GuideSlide(
      icon: Icons.bolt_rounded,
      titleKey: 'guide2_title',
      descKey: 'guide2_desc',
    ),
    _GuideSlide(
      icon: Icons.wifi_off_rounded,
      titleKey: 'guide3_title',
      descKey: 'guide3_desc',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _autoSlide = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_guideController.hasClients) return;
      _guideController.animateToPage(
        (_guidePage + 1) % _slides.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlide?.cancel();
    _guideController.dispose();
    super.dispose();
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  void _openFishInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FishInfoScreen()),
    );
  }

  void _showAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The main Scaffold uses extendBody, so padding.bottom here equals the
    // floating nav bar's height (including the system navigation inset).
    final bottomReserved = MediaQuery.paddingOf(context).bottom;

    return UnderwaterBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomReserved + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo/logo_isdaai.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'IsdaAI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(
                context.tr('home_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('home_sub'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 22),

              // How-it-works slideshow
              SizedBox(
                height: 176,
                child: PageView.builder(
                  controller: _guideController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _guidePage = i),
                  itemBuilder: (context, i) => _GuideCard(slide: _slides[i]),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _guidePage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: active ? 0.95 : 0.4,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 26),
              Text(
                context.tr('quick_actions'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              // Main action: full-width orange card
              _ActionCard(
                wide: true,
                icon: Icons.camera_alt_rounded,
                label: context.tr('act_scan'),
                hint: context.tr('act_scan_hint'),
                highlight: true,
                onTap: () => widget.onNavigate(1),
              ),
              const SizedBox(height: 14),

              // Row 1: Live detection + Fish Info & Guide
              _cardRow(
                _ActionCard(
                  icon: Icons.videocam_rounded,
                  label: context.tr('act_live'),
                  hint: context.tr('act_live_hint'),
                  onTap: () => widget.onNavigate(2),
                ),
                _ActionCard(
                  icon: Icons.menu_book_rounded,
                  label: context.tr('act_fishinfo'),
                  hint: context.tr('act_fishinfo_hint'),
                  onTap: _openFishInfo,
                ),
              ),
              const SizedBox(height: 14),

              // Row 2: History + About
              _cardRow(
                _ActionCard(
                  icon: Icons.history_rounded,
                  label: context.tr('act_history'),
                  hint: context.tr('act_history_hint'),
                  onTap: _openHistory,
                ),
                _ActionCard(
                  icon: Icons.info_outline_rounded,
                  label: context.tr('act_about'),
                  hint: context.tr('act_about_hint'),
                  onTap: _showAbout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Two equal cards side by side, same height.
  Widget _cardRow(Widget left, Widget right) {
    return SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 14),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _GuideSlide {
  final IconData icon;
  final String titleKey;
  final String descKey;
  const _GuideSlide({
    required this.icon,
    required this.titleKey,
    required this.descKey,
  });
}

class _GuideCard extends StatelessWidget {
  final _GuideSlide slide;
  const _GuideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      // Dark blue glass: the text on it is white, so the tint and the fill
      // are blue instead of the white used by normal cards.
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(20),
        opacity: 1.6,
        tint: AppColors.primaryDark,
        fill: AppColors.primaryDark.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(slide.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr(slide.titleKey),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(slide.descKey),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quick-action card.
///  - wide: false -> compact square-ish card (icon on top, text below)
///  - wide: true  -> full-width card (icon left, text middle, arrow right)
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final bool highlight;
  final bool wide;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.highlight = false,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    // Uses the theme palette (not AppColors.textDark) so it also reads
    // correctly in Dark mode.
    final fg = highlight ? Colors.white : pal.text;
    final sub = highlight ? Colors.white.withValues(alpha: 0.9) : pal.muted;
    final iconBg = highlight
        ? Colors.white.withValues(alpha: 0.22)
        : pal.link.withValues(alpha: 0.12);
    final iconFg = highlight ? Colors.white : pal.link;

    final iconBox = Container(
      padding: EdgeInsets.all(wide ? 14 : 10),
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(wide ? 16 : 12),
      ),
      child: Icon(icon, color: iconFg, size: wide ? 30 : 22),
    );

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: wide ? 18 : 15,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: sub, fontSize: 12, height: 1.25),
        ),
      ],
    );

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      // The main action is orange glass; the others are normal glass.
      opacity: highlight ? 1.2 : 2.0,
      tint: highlight ? AppColors.accent : null,
      fill: highlight ? AppColors.accent.withValues(alpha: 0.7) : null,
      child: wide
          ? Row(
              children: [
                iconBox,
                const SizedBox(width: 16),
                Expanded(child: texts),
                Icon(Icons.chevron_right_rounded, color: fg, size: 28),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [iconBox, texts],
            ),
    );
  }
}
