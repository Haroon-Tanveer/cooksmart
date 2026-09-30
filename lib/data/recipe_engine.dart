import '../models/recipe.dart';
import 'recipes.dart';

/// Result of scoring one library recipe against the user's ingredient list.
class RecipeScore {
  const RecipeScore({
    required this.recipe,
    required this.have,
    required this.missing,
    required this.match,
    required this.hits,
  });

  final Recipe recipe;
  final List<Ingredient> have;
  final List<Ingredient> missing;
  final int match;
  final int hits;
}

List<String> _tokenize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z\s]'), '')
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty)
    .toList();

RecipeScore scoreRecipe(Recipe recipe, List<String> owned) {
  final pool = owned.expand(_tokenize).toSet();
  final have = <Ingredient>[];
  final missing = <Ingredient>[];

  for (final ing in recipe.ingredients) {
    final tokens = _tokenize(ing.name);
    final matched = tokens.any((t) =>
        pool.contains(t) || pool.any((p) => p.startsWith(t) && t.length > 2));
    if (matched) {
      have.add(ing);
    } else {
      missing.add(ing);
    }
  }

  final ratio = recipe.ingredients.isEmpty ? 0 : have.length / recipe.ingredients.length;
  final bonus = owned.isEmpty ? 0 : 30;
  final match = ((ratio * 70) + bonus).round().clamp(0, 100);

  return RecipeScore(
    recipe: recipe,
    have: have,
    missing: missing,
    match: match,
    hits: have.length,
  );
}

/// Builds a recipe from whatever the user typed in: ranks the library by
/// ingredient overlap, then reports what they own and what they still need.
Recipe? generateRecipe(List<String> ownedIngredients) {
  final owned = ownedIngredients
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (owned.isEmpty) return null;

  final ranked = kRecipes.map((r) => scoreRecipe(r, owned)).toList()
    ..sort((a, b) {
      final byHits = b.hits.compareTo(a.hits);
      return byHits != 0 ? byHits : b.match.compareTo(a.match);
    });

  final best = ranked.first;
  final matchPct = best.match < 20 ? 20 : best.match;
  final label = best.hits == 0 ? 'Creative match' : '$matchPct% match';

  return best.recipe.copyWith(
    match: matchPct,
    matchLabel: label,
    basedOn: owned,
    have: best.have.map((i) => i.name).toList(),
    missing: best.missing.map((i) => i.name).toList(),
    savedAt: DateTime.now().millisecondsSinceEpoch,
  );
}
