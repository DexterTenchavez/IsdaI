class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final int? prepMinutes;
  final int? cookMinutes;
  final int? totalMinutes;

  /// Not in your recipe files, so it is empty for now.
  /// Add servings: 4 to a recipe in recipe_data.dart to show it.
  final int? servings;

  final List<String> ingredients;
  final List<String> equipment;
  final List<String> instructions;

  /// Fish species this recipe suits (e.g. ['Carabalyas']).
  /// Empty list = suits any species.
  final List<String> species;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.ingredients,
    required this.equipment,
    required this.instructions,
    this.prepMinutes,
    this.cookMinutes,
    this.totalMinutes,
    this.servings,
    this.species = const [],
  });

  /// Short time text for cards.
  String get timeLabel {
    if (totalMinutes != null) return '$totalMinutes min';
    if (cookMinutes != null) return '$cookMinutes min cook';
    return 'Time not listed';
  }

  String get servingsLabel =>
      servings != null ? '$servings servings' : 'Servings not listed';

  bool suits(String? fishSpecies) {
    if (species.isEmpty || fishSpecies == null) return true;
    final s = fishSpecies.toLowerCase();
    return species.any((x) => x.toLowerCase() == s);
  }
}
