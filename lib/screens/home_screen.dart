import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _guideController = PageController();
  int _guidePage = 0;

  final List<_GuideSlide> _slides = const [
    _GuideSlide(
      icon: Icons.visibility_rounded,
      title: 'Check the Eye or Gill',
      description: 'IsdaAI reads freshness cues from the fish eye or gill, the two most reliable spots for spotting spoilage.',
    ),
    _GuideSlide(
      icon: Icons.bolt_rounded,
      title: 'Instant AI Analysis',
      description: 'Snap a photo and get a freshness result with a confidence score in seconds.',
    ),
    _GuideSlide(
      icon: Icons.wifi_off_rounded,
      title: 'Works Fully Offline',
      description: 'No internet needed — the model runs entirely on your device, anywhere in the market or dock.',
    ),
  ];

  @override
  void dispose() {
    _guideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IsdaAI', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Know your catch is fresh',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Offline fish freshness detection powered by on-device AI.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Guidance / how-it-works slideshow
            SizedBox(
              height: 190,
              child: PageView.builder(
                controller: _guideController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _guidePage = i),
                itemBuilder: (context, i) => _GuideCard(slide: _slides[i]),
              ),
            ),
            const SizedBox(height: 10),
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
                    color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),
            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.15,
              children: [
                _ActionCard(
                  icon: Icons.camera_alt_rounded,
                  label: 'Start Capture',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CameraScreen()),
                  ),
                ),
                _ActionCard(icon: Icons.photo_library_rounded, label: 'Select Gallery', onTap: () {}),
                _ActionCard(icon: Icons.history_rounded, label: 'History', onTap: () {}),
                _ActionCard(icon: Icons.info_outline_rounded, label: 'About IsdaAI', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideSlide {
  final IconData icon;
  final String title;
  final String description;
  const _GuideSlide({required this.icon, required this.title, required this.description});
}

class _GuideCard extends StatelessWidget {
  final _GuideSlide slide;
  const _GuideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
            child: Icon(slide.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 14),
          Text(slide.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            slide.description,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}