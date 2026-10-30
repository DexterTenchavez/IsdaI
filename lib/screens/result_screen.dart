import 'dart:io';
import 'package:flutter/material.dart';
import '../services/app_language.dart';
import '../services/classifier_service.dart';
import '../theme/app_theme.dart';
import 'recipe_recommendation_screen.dart';

class ResultScreen extends StatelessWidget {
  final ClassificationResult result;
  final String? imagePath;

  const ResultScreen({super.key, required this.result, this.imagePath});

  bool get _isOk => result.status == ScanStatus.ok;
  bool get _isFreshOk => _isOk && result.isFresh;
  bool get _isStaleOk => _isOk && !result.isFresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('result_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (imagePath != null) ...[
              _photoCard(),
              const SizedBox(height: 16),
            ],
            _isOk ? _verdictCard(context) : _problemCard(context),
            const SizedBox(height: 16),
            if (_isStaleOk) ...[
              _staleWarningCard(context),
              const SizedBox(height: 16),
            ],
            if (_isFreshOk) ...[_tipsCard(context), const SizedBox(height: 16)],
            Text(
              context.tr('disclaimer'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Recipe button: only for a Fresh result
            if (_isFreshOk) ...[
              ElevatedButton.icon(
                onPressed: () {
                  final species = result.speciesConfidence < 0.5
                      ? null
                      : result.species;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RecipeRecommendationScreen(species: species),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu_rounded),
                label: Text(context.tr('btn_recipe')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(context.tr(_isOk ? 'btn_scan_again' : 'btn_retake')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.pal.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _photoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.file(
          File(imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            child: const Icon(
              Icons.image_not_supported_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _verdictCard(BuildContext context) {
    final pal = context.pal;
    final fresh = result.isFresh;
    final color = fresh ? pal.good : pal.bad;
    final speciesName = result.speciesConfidence < 0.5
        ? context.tr('species_unclear')
        : (result.species ?? context.tr('species_unknown'));

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  fresh ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.tr(fresh ? 'badge_fresh' : 'badge_stale'),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('fish_label'),
            style: TextStyle(color: pal.muted, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            speciesName,
            style: TextStyle(
              color: pal.text,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          _meter(
            context,
            context.tr('meter_fresh'),
            result.freshnessConfidence,
            color,
          ),
          const SizedBox(height: 16),
          _meter(
            context,
            context.tr('meter_species'),
            result.speciesConfidence,
            AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _meter(BuildContext context, String label, double value, Color color) {
    final pal = context.pal;
    final v = value.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: pal.muted, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '${(v * 100).round()}%',
              style: TextStyle(color: pal.text, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: v,
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  Widget _staleWarningCard(BuildContext context) {
    final pal = context.pal;
    return _card(
      context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.dangerous_rounded, color: pal.bad, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('stale_title'),
                  style: TextStyle(
                    color: pal.bad,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('stale_body'),
                  style: TextStyle(color: pal.text, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _problemCard(BuildContext context) {
    final pal = context.pal;
    final IconData icon;
    final String title;
    final String body;

    switch (result.status) {
      case ScanStatus.notFish:
        icon = Icons.search_off_rounded;
        title = context.tr('notfish_title');
        body = context.tr('notfish_body');
        break;
      case ScanStatus.multipleFish:
        icon = Icons.grid_view_rounded;
        title = context.tr('multi_title');
        body = context.tr('multi_body');
        break;
      case ScanStatus.lowConfidence:
      case ScanStatus.ok:
        icon = Icons.blur_on_rounded;
        title = context.tr('low_title');
        body = context.tr('low_body');
        break;
    }

    return _card(
      context,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pal.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: pal.muted, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _tipsCard(BuildContext context) {
    final pal = context.pal;
    final tips = [
      context.tr('tip1'),
      context.tr('tip2'),
      context.tr('tip3'),
      context.tr('tip4'),
    ];

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('tips_title'),
            style: TextStyle(
              color: pal.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, color: pal.link, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: pal.text,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
