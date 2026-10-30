import 'package:flutter/material.dart';
import '../services/app_language.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/underwater_background.dart';

/// One row in the bottom-sheet picker (used for Language and Theme).
class _Choice {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onSelect;

  const _Choice({
    required this.label,
    required this.selected,
    required this.onSelect,
    this.icon,
  });
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showSheet(BuildContext context, String title, List<_Choice> choices) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final pal = sheetContext.pal;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: pal.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final c in choices)
                  ListTile(
                    leading: c.icon == null
                        ? null
                        : Icon(c.icon, color: pal.link),
                    title: Text(
                      c.label,
                      style: TextStyle(
                        color: pal.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: c.selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: () {
                      c.onSelect();
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickLanguage(BuildContext context) {
    final language = AppLanguageScope.of(context);
    _showSheet(context, context.tr('lang_choose'), [
      for (final l in AppLang.values)
        _Choice(
          label: AppLanguage.nativeName(l),
          selected: language.lang == l,
          onSelect: () => language.set(l),
        ),
    ]);
  }

  void _pickTheme(BuildContext context) {
    final controller = ThemeController.instance;
    _showSheet(context, context.tr('theme_choose'), [
      _Choice(
        label: context.tr('theme_light'),
        icon: Icons.light_mode_rounded,
        selected: !controller.isDark,
        onSelect: () => controller.set(ThemeMode.light),
      ),
      _Choice(
        label: context.tr('theme_dark'),
        icon: Icons.dark_mode_rounded,
        selected: controller.isDark,
        onSelect: () => controller.set(ThemeMode.dark),
      ),
    ]);
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'IsdaAI',
      applicationVersion: '1.0.0',
      children: [Text(context.tr('home_sub'))],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Space for the floating nav bar (main Scaffold uses extendBody)
    final bottomReserved = MediaQuery.paddingOf(context).bottom;
    final language = AppLanguageScope.of(context);

    return UnderwaterBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            context.tr('settings_title'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListenableBuilder(
          // refresh the Theme subtitle right after a change
          listenable: ThemeController.instance,
          builder: (context, _) {
            return ListView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomReserved + 20),
              children: [
                _sectionLabel(context.tr('sec_general')),
                _tile(
                  context,
                  Icons.language_rounded,
                  context.tr('set_language'),
                  AppLanguage.nativeName(language.lang),
                  onTap: () => _pickLanguage(context),
                ),
                _tile(
                  context,
                  ThemeController.instance.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  context.tr('set_theme'),
                  context.tr(
                    ThemeController.instance.isDark
                        ? 'theme_dark'
                        : 'theme_light',
                  ),
                  onTap: () => _pickTheme(context),
                ),
                const SizedBox(height: 20),
                _sectionLabel(context.tr('sec_data')),
                _tile(
                  context,
                  Icons.history_rounded,
                  context.tr('set_history'),
                  context.tr('set_history_sub'),
                ),
                _tile(
                  context,
                  Icons.storage_rounded,
                  context.tr('set_storage'),
                  context.tr('set_storage_sub'),
                ),
                const SizedBox(height: 20),
                _sectionLabel(context.tr('sec_about')),
                _tile(
                  context,
                  Icons.info_outline_rounded,
                  context.tr('set_about'),
                  context.tr('set_about_sub'),
                  onTap: () => _showAbout(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.9),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    final pal = context.pal;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: pal.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: pal.link.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: pal.link, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: pal.text),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: pal.muted),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: pal.muted),
        onTap: onTap ?? () {},
      ),
    );
  }
}
