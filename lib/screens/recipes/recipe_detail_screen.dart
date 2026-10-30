import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/language/app_language.dart';
import '../../services/storage/recipe_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/underwater_background.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _saved = false;

  Recipe get r => widget.recipe;

  @override
  void initState() {
    super.initState();
    RecipeStore.loadSaved().then((s) {
      if (mounted) setState(() => _saved = s.contains(r.id));
    });
  }

  Future<void> _toggleSave() async {
    final nowSaved = await RecipeStore.toggle(r.id);
    if (!mounted) return;
    setState(() => _saved = nowSaved);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(nowSaved ? 'snack_saved' : 'snack_removed')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    return UnderwaterBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            context.tr('detail_title'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _toggleSave,
              icon: Icon(
                _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: TextStyle(
                        color: pal.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.description,
                      style: TextStyle(
                        color: pal.muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        _info(
                          Icons.timer_outlined,
                          recipeTimeLabel(context, r),
                        ),
                        _info(
                          Icons.people_outline_rounded,
                          recipeServingsLabel(context, r),
                        ),
                      ],
                    ),
                    if (r.prepMinutes != null || r.cookMinutes != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (r.prepMinutes != null)
                            context.tr(
                              'prep_min',
                              args: {'n': '${r.prepMinutes}'},
                            ),
                          if (r.cookMinutes != null)
                            context.tr(
                              'cook_min',
                              args: {'n': '${r.cookMinutes}'},
                            ),
                        ].join('  •  '),
                        style: TextStyle(color: pal.muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(context.tr('ingredients')),
                    for (final i in r.ingredients) _bullet(i),
                    if (r.equipment.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _title(context.tr('equipment')),
                      for (final e in r.equipment) _bullet(e),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(context.tr('instructions')),
                    for (var i = 0; i < r.instructions.length; i++)
                      _step(i + 1, r.instructions[i]),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _toggleSave,
                icon: Icon(
                  _saved
                      ? Icons.bookmark_remove_rounded
                      : Icons.bookmark_add_rounded,
                ),
                label: Text(context.tr(_saved ? 'remove_saved' : 'save')),
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.pal.surface,
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

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _info(IconData icon, String text) {
    final pal = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: pal.link),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: pal.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.pal.text,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(int number, String text) {
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
