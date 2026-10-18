import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
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
