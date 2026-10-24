import 'dart:io';
import 'package:flutter/material.dart';
import '../services/classifier_service.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  final ClassificationResult result;
  final String? imagePath;

  const ResultScreen({super.key, required this.result, this.imagePath});

  bool get _isOk => result.status == ScanStatus.ok;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan result',
          style: TextStyle(fontWeight: FontWeight.w700),
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
            _isOk ? _verdictCard() : _problemCard(),
            const SizedBox(height: 16),
            if (_isOk) ...[_tipsCard(), const SizedBox(height: 16)],
            Text(
              'IsdaAI gives an estimate from the photo. It is not a food-safety '
              'guarantee. If the fish smells bad or feels slimy, do not eat it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(_isOk ? 'Scan another fish' : 'Retake photo'),
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
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

  Widget _verdictCard() {
    final fresh = result.isFresh;
    final color = fresh ? AppColors.success : AppColors.danger;
    final speciesName = result.speciesConfidence < 0.5
        ? 'Species unclear'
        : (result.species ?? 'Unknown');

    return _card(
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
                Text(
                  fresh ? 'FRESH' : 'STALE',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fish',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            speciesName,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          _meter('Freshness confidence', result.freshnessConfidence, color),
          const SizedBox(height: 16),
          _meter(
            'Species match',
            result.speciesConfidence,
            AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _meter(String label, double value, Color color) {
    final v = value.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(v * 100).round()}%',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
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

  Widget _problemCard() {
    late final IconData icon;
    late final String title;
    late final String body;

    switch (result.status) {
      case ScanStatus.notFish:
        icon = Icons.search_off_rounded;
        title = 'No fish detected';
        body =
            'Point the camera at one fish and show the eye or gills, then try again.';
        break;
      case ScanStatus.multipleFish:
        icon = Icons.grid_view_rounded;
        title = 'Too many fish in the photo';
        body = 'Please take a photo of one fish at a time.';
        break;
      case ScanStatus.lowConfidence:
      case ScanStatus.ok:
        icon = Icons.blur_on_rounded;
        title = "Couldn't tell clearly";
        body =
            'The photo was hard to judge. Try better light, move closer to the eye or gills, and hold steady.';
        break;
    }

    return _card(
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
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsCard() {
    const tips = [
      'Eyes are clear and slightly bulging',
      'Gills are bright red or pink, not brown or gray',
      'Flesh is firm and springs back when pressed',
      'Smell is mild and sea-like, not sour or sharp',
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Check it yourself too',
            style: TextStyle(
              color: AppColors.textDark,
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
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: AppColors.textDark,
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
