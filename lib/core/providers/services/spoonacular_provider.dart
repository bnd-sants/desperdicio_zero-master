import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/services/spoonacular_service.dart';
import 'package:desperdicio_zero/models/spoonacular_models.dart';

final spoonacularServiceProvider = Provider<SpoonacularService>((ref) {
  return SpoonacularService();
});

final recipeSuggestionsProvider = FutureProvider.family<List<SpoonacularRecipe>, List<String>>((ref, ingredients) async {
  final service = ref.watch(spoonacularServiceProvider);
  return await service.findRecipesByIngredients(ingredients);
});

final recipeDetailsProvider = FutureProvider.family<RecipeDetails, int>((ref, recipeId) async {
  final service = ref.watch(spoonacularServiceProvider);
  return await service.getRecipeDetails(recipeId);
});
