import 'package:flutter/material.dart';
import '../../data/fish_species_data.dart';
import '../../services/language/app_language.dart';
import '../../theme/app_theme.dart';
import '../../widgets/underwater_background.dart';

/// Fish Info & Guide (SRS FR-32): how to take a clear photo, plus the six
/// supported species.
class FishInfoScreen extends StatelessWidget {
  const FishInfoScreen({super.key});

  static const List<String> _guideKeys = [
    'guide_step1',
    'guide_step2',
    'guide_step3',
    'guide_step4',
    'guide_step5',
  ];

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final tagalog = AppLanguageScope.of(context).lang == AppLang.tl;

    return UnderwaterBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            context.tr('fishinfo_title'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // ---- Guide ----
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(context, context.tr('fishinfo_guide_title')),
                    for (var i = 0; i < _guideKeys.length; i++)
                      _step(context, i + 1, context.tr(_guideKeys[i])),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---- Species ----
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  context.tr('fishinfo_species_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final s in supportedSpecies)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _card(
                    context,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _photo(pal, s),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: TextStyle(
                                  color: pal.text,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (s.englishName != null)
                                Text(
                                  s.englishName!,
                                  style: TextStyle(
                                    color: pal.link,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                tagalog ? s.descTl : s.descEn,
                                style: TextStyle(
                                  color: pal.muted,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo(AppPalette pal, FishSpecies s) {
    const size = 80.0;
    final fallback = Container(
      width: size,
      height: size,
      color: pal.link.withValues(alpha: 0.12),
      child: Icon(Icons.set_meal_rounded, color: pal.link, size: 34),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: s.imageAsset == null
          ? fallback
          : Image.asset(
              s.imageAsset!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: 240, // decode a small copy, not the full photo
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.pal.surface.withValues(alpha: 0.95),
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

  Widget _title(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: context.pal.text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _step(BuildContext context, int number, String text) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: pal.badge, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: TextStyle(color: pal.text, fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
