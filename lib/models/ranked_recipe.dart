import 'package:desperdicio_zero/models/recipe_model.dart';

class RankedRecipe {
  final Recipe recipe;
  final double availableIngredientRatio;
  final double expiringSoonCoverage;
  final int missingIngredientsCount;
  final double finalScore;

  const RankedRecipe({
    required this.recipe,
    required this.availableIngredientRatio,
    required this.expiringSoonCoverage,
    required this.missingIngredientsCount,
    required this.finalScore,
  });
}
