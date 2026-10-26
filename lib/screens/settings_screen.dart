import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/underwater_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Space for the floating nav bar (main Scaffold uses extendBody)
    final bottomReserved = MediaQuery.paddingOf(context).bottom;

    return UnderwaterBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomReserved + 20),
          children: [
            _sectionLabel('General'),
            _tile(Icons.language_rounded, 'Language', 'English'),
            _tile(Icons.color_lens_rounded, 'Theme', 'Light'),
            const SizedBox(height: 20),
            _sectionLabel('Data'),
            _tile(Icons.history_rounded, 'Scan History', 'View past results'),
            _tile(Icons.storage_rounded, 'Storage', 'Manage saved scans'),
            const SizedBox(height: 20),
            _sectionLabel('About'),
            _tile(
              Icons.info_outline_rounded,
              'About IsdaAI',
              'App info & version',
            ),
          ],
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

  Widget _tile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: AppColors.textMuted,
        ),
        onTap: () {},
      ),
    );
  }
}
