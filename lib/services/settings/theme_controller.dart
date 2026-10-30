import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the current theme (Light or Dark, SRS FR-28), saves it on the
/// device, and tells MaterialApp to rebuild when it changes.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const String _key = 'app_theme';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  /// Call once before runApp.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = prefs.getString(_key) == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
    } catch (_) {
      _mode = ThemeMode.light;
    }
  }

  Future<void> set(ThemeMode mode) async {
    // The app only offers Light and Dark.
    final next = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    if (next == _mode) return;
    _mode = next;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, next == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
