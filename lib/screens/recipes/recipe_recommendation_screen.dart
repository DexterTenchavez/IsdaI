import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/recipe_data.dart';
import '../../models/recipe.dart';
import '../../services/language/app_language.dart';
import '../../services/storage/recipe_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/underwater_background.dart';
import 'recipe_detail_screen.dart';

class RecipeRecommendationScreen extends StatefulWidget {
  /// Species from the scan (null if unclear).
  final String? species;

  const RecipeRecommendationScreen({super.key, this.species});

  @override
  State<RecipeRecommendationScreen> createState() =>
      _RecipeRecommendationScreenState();
}

enum _Filter { thisFish, allFish, saved }

class _RecipeRecommendationScreenState
    extends State<RecipeRecommendationScreen> {
  bool _showAll = false;
  late _Filter _filter;
  Set<String> _saved = {};
  late final List<Recipe> _suggestions;

  bool get _hasSpecies =>
      widget.species != null &&
      allRecipes.any((r) => r.suits(widget.species) && r.species.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _filter = _hasSpecies ? _Filter.thisFish : _Filter.allFish;

    // 3 random recipes for this fish (or any fish if the species is unclear)
    final pool = allRecipes.where((r) => r.suits(widget.species)).toList()
      ..shuffle(Random());
    _suggestions = pool.take(3).toList();

    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final s = await RecipeStore.loadSaved();
    if (mounted) setState(() => _saved = s);
  }

  Future<void> _open(Recipe r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
    );
    _loadSaved(); // refresh bookmark icons after coming back
  }

  List<Recipe> get _visible {
    if (!_showAll) return _suggestions;
    switch (_filter) {
      case _Filter.thisFish:
        return allRecipes.where((r) => r.suits(widget.species)).toList();
      case _Filter.allFish:
        return allRecipes;
      case _Filter.saved:
        return allRecipes.where((r) => _saved.contains(r.id)).toList();
    }
  }

  Widget _chip(String label, _Filter value) {
    final pal = context.pal;
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        // Readable in both themes: solid card color, accent when selected
        backgroundColor: pal.surface.withValues(alpha: 0.9),
        selectedColor: AppColors.accent,
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: selected ? Colors.white : pal.text,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final recipes = _visible;
    final fishName = widget.species ?? context.tr('fish_word');

    return UnderwaterBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            context.tr(_showAll ? 'rec_all' : 'rec_suggestions'),
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
              Text(
                _showAll
                    ? context.tr('rec_all_intro')
                    : context.tr('rec_intro', args: {'fish': fishName}),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              if (_showAll) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_hasSpecies)
                        _chip(
                          context.tr(
                            'chip_this',
                            args: {'species': widget.species!},
                          ),
                          _Filter.thisFish,
                        ),
                      _chip(context.tr('chip_all'), _Filter.allFish),
                      _chip(context.tr('chip_saved'), _Filter.saved),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (recipes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: pal.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.tr('rec_none_saved'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: pal.muted),
                  ),
                )
              else
                for (final r in recipes)
                  _RecipeCard(
                    recipe: r,
                    saved: _saved.contains(r.id),
                    onTap: () => _open(r),
                  ),
              const SizedBox(height: 8),
              if (!_showAll)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showAll = true),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(context.tr('btn_view_all')),
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
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool saved;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.saved,
    required this.onTap,
  });

  Widget _pill(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: pal.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: TextStyle(
                          color: pal.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (saved)
                      const Icon(
                        Icons.bookmark_rounded,
                        color: AppColors.accent,
                        size: 22,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (recipe.species.isNotEmpty)
                      _pill(recipe.species.first, color: AppColors.accent),
                    for (final t in recipe.tags) _pill(t, color: pal.link),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: pal.muted),
                    const SizedBox(width: 6),
                    Text(
                      recipeTimeLabel(context, recipe),
                      style: TextStyle(color: pal.muted, fontSize: 13),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: pal.muted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
