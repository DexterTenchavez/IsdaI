import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/language/app_language.dart';
import '../../theme/app_theme.dart';
import '../../widgets/underwater_background.dart';

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

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('coming_soon', args: {'what': what}))),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'IsdaAI',
      applicationVersion: '1.0.0',
      children: [Text(context.tr('home_sub'))],
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

              const SizedBox(height: 28),
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

              const SizedBox(height: 24),

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

              const SizedBox(height: 28),
              Text(
                context.tr('quick_actions'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: [
                  _ActionCard(
                    icon: Icons.camera_alt_rounded,
                    label: context.tr('act_scan'),
                    hint: context.tr('act_scan_hint'),
                    highlight: true,
                    onTap: () => widget.onNavigate(1),
                  ),
                  _ActionCard(
                    icon: Icons.videocam_rounded,
                    label: context.tr('act_live'),
                    hint: context.tr('act_live_hint'),
                    onTap: () => widget.onNavigate(2),
                  ),
                  _ActionCard(
                    icon: Icons.history_rounded,
                    label: context.tr('act_history'),
                    hint: context.tr('act_history_hint'),
                    onTap: () => _comingSoon(context.tr('act_history')),
                  ),
                  _ActionCard(
                    icon: Icons.info_outline_rounded,
                    label: context.tr('act_about'),
                    hint: context.tr('act_about_hint'),
                    onTap: _showAbout,
                  ),
                ],
              ),
            ],
          ),
        ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Translucent so the fish stay visible behind the card
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.72),
            AppColors.primary.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
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
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final bool highlight;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.92);
    final fg = highlight ? Colors.white : AppColors.textDark;
    final sub = highlight
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.textMuted;
    final iconBg = highlight
        ? Colors.white.withValues(alpha: 0.22)
        : AppColors.primary.withValues(alpha: 0.1);
    final iconFg = highlight ? Colors.white : AppColors.primary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconFg, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(hint, style: TextStyle(color: sub, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
