import 'package:desperdicio_zero/models/product_model.dart';
import 'package:desperdicio_zero/models/ranked_recipe.dart';
import 'package:desperdicio_zero/models/recipe_model.dart';

class RecipeRelevanceService {
  List<RankedRecipe> rankRecipes({
    required List<Recipe> recipes,
    required List<Product> products,
    bool prioritizeExpiringSoon = true,
    bool onlyAvailable = false,
  }) {
    final now = DateTime.now();
    final normalizedProducts = products
        .where((p) => !p.isConsumed)
        .map((p) => p.name.trim().toLowerCase())
        .toSet();
    final expiringSoonProducts = products
        .where(
          (p) =>
              !p.isConsumed &&
              p.expirationDate != null &&
              p.expirationDate!.difference(now).inDays >= 0 &&
              p.expirationDate!.difference(now).inDays <= 3,
        )
        .map((p) => p.name.trim().toLowerCase())
        .toSet();

    final ranked = recipes.map((recipe) {
      final ingredients = recipe.products
          .map((p) => p.name.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toList();

      if (ingredients.isEmpty) {
        return RankedRecipe(
          recipe: recipe,
          availableIngredientRatio: 0,
          expiringSoonCoverage: 0,
          missingIngredientsCount: 0,
          finalScore: 0,
        );
      }

      final availableCount =
          ingredients.where((name) => normalizedProducts.contains(name)).length;
      final expiringCount =
          ingredients.where((name) => expiringSoonProducts.contains(name)).length;
      final missingCount = ingredients.length - availableCount;
      final availableRatio = availableCount / ingredients.length;
      final expiringRatio = expiringCount / ingredients.length;
      final finalScore = prioritizeExpiringSoon
          ? (availableRatio * 0.7) + (expiringRatio * 0.3)
          : availableRatio;

      return RankedRecipe(
        recipe: recipe,
        availableIngredientRatio: availableRatio,
        expiringSoonCoverage: expiringRatio,
        missingIngredientsCount: missingCount,
        finalScore: finalScore,
      );
    }).toList();

    final filtered = onlyAvailable
        ? ranked.where((item) => item.missingIngredientsCount == 0).toList()
        : ranked;
    filtered.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return filtered;
  }
}
