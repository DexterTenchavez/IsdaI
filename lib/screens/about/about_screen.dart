import 'package:flutter/material.dart';
import '../../data/fish_species_data.dart';
import '../../services/language/app_language.dart';
import '../../theme/app_theme.dart';
import '../../widgets/underwater_background.dart';

/// Shown in the About screen and the licenses page.
const String kAppVersion = '1.0.0';

const String _projectTitle =
    'IsdaAi: An Offline Fish Freshness Detection Using Image Recognition';

const List<String> _developers = [
  'Ricianin L. Bontog',
  'Dexter B. Tenchaves',
  'Niño B. Labos',
  'Charity Cuysona',
  'Jejomar T. Bermoy',
];

/// About IsdaAI (SRS FR-31): app name, version, description and
/// open-source licenses, plus features, species and project info.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    return UnderwaterBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            context.tr('about_title'),
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
              // ---- Logo, name, tagline, version ----
              _card(
                context,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/logo/logo_isdaai.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'IsdaAI',
                      style: TextStyle(
                        color: pal.text,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('about_tagline'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: pal.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _pill(
                      pal,
                      context.tr('about_version', args: {'v': kAppVersion}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- What is IsdaAI ----
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(context, context.tr('about_desc_title')),
                    Text(
                      context.tr('about_desc'),
                      style: TextStyle(
                        color: pal.text,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- Features ----
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(context, context.tr('about_features_title')),
                    _feature(
                      pal,
                      Icons.camera_alt_rounded,
                      context.tr('about_f_scan'),
                    ),
                    _feature(
                      pal,
                      Icons.videocam_rounded,
                      context.tr('about_f_live'),
                    ),
                    _feature(
                      pal,
                      Icons.history_rounded,
                      context.tr('about_f_history'),
                    ),
                    _feature(
                      pal,
                      Icons.menu_book_rounded,
                      context.tr('about_f_info'),
                    ),
                    _feature(
                      pal,
                      Icons.restaurant_menu_rounded,
                      context.tr('about_f_recipe'),
                    ),
                    _feature(
                      pal,
                      Icons.language_rounded,
                      context.tr('about_f_lang'),
                      last: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- Supported species ----
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(context, context.tr('about_species_title')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in supportedSpecies) _pill(pal, s.name),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr('about_species_body'),
                      style: TextStyle(
                        color: pal.muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- Offline and private ----
              _card(
                context,
                child: _iconBlock(
                  pal,
                  Icons.wifi_off_rounded,
                  context.tr('about_offline_title'),
                  context.tr('about_offline_body'),
                ),
              ),
              const SizedBox(height: 16),

              // ---- Disclaimer ----
              _card(
                context,
                child: _iconBlock(
                  pal,
                  Icons.info_outline_rounded,
                  context.tr('about_disclaimer_title'),
                  context.tr('disclaimer'),
                ),
              ),
              const SizedBox(height: 16),

              // ---- Project and developers ----
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(context, context.tr('about_project_title')),
                    Text(
                      _projectTitle,
                      style: TextStyle(
                        color: pal.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('about_school'),
                      style: TextStyle(color: pal.muted, fontSize: 13),
                    ),
                    Text(
                      context.tr('about_capstone'),
                      style: TextStyle(color: pal.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('about_devs_title'),
                      style: TextStyle(
                        color: pal.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final name in _developers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: pal.link,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(color: pal.text, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---- Open-source licenses ----
              ElevatedButton.icon(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'IsdaAI',
                  applicationVersion: kAppVersion,
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/logo/logo_isdaai.png',
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
                icon: const Icon(Icons.description_outlined),
                label: Text(context.tr('about_licenses')),
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
            ],
          ),
        ),
      ),
    );
  }

  // --- small building blocks ------------------------------------------------

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

  Widget _pill(AppPalette pal, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: pal.link.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: pal.link,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _feature(
    AppPalette pal,
    IconData icon,
    String text, {
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pal.link.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: pal.link, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: pal.text, fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBlock(AppPalette pal, IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: pal.link, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: pal.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(color: pal.muted, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
