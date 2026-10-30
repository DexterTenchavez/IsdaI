import 'package:shared_preferences/shared_preferences.dart';

/// Saves the ids of the recipes the user bookmarked, on the device.
class RecipeStore {
  static const String _key = 'saved_recipe_ids';

  static Future<Set<String>> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? <String>[]).toSet();
  }

  /// Toggles a recipe. Returns true if it is now saved.
  static Future<bool> toggle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? <String>[]).toList();
    final nowSaved = !ids.contains(id);
    if (nowSaved) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    await prefs.setStringList(_key, ids);
    return nowSaved;
  }
}
