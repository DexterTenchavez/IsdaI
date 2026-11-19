import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which screens already showed their first-time tour (SRS FR-01).
class GuideStore {
  /// Every tour id. Used by "How to use IsdaAI" in Settings to reset them all.
  static const List<String> allIds = ['home', 'camera', 'live', 'result'];

  static String _key(String id) => 'guide_seen_$id';

  /// True when the tour was already seen (or storage is not available, so
  /// users are not stuck seeing the tour every time).
  static Future<bool> isDone(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key(id)) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> markDone(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(id), true);
    } catch (_) {}
  }

  /// Makes every tour show again.
  static Future<void> resetAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final id in allIds) {
        await prefs.remove(_key(id));
      }
    } catch (_) {}
  }
}
