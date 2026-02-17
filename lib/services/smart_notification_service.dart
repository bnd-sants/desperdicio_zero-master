import 'package:desperdicio_zero/models/notification_suggestion.dart';
import 'package:desperdicio_zero/models/product_model.dart';
import 'package:desperdicio_zero/models/recipe_model.dart';
import 'package:desperdicio_zero/services/recipe_relevance_service.dart';

class SmartNotificationService {
  final RecipeRelevanceService _relevanceService = RecipeRelevanceService();

  Future<List<NotificationSuggestion>> generateSuggestions(
    List<Product> products,
    List<Recipe> recipes,
  ) async {
    final now = DateTime.now();
    final criticalProducts = products.where((product) {
      if (product.isConsumed || product.expirationDate == null) return false;
      final days = product.expirationDate!.difference(now).inDays;
      return days == 1 || days == 2;
    }).toList();

    if (criticalProducts.isEmpty || recipes.isEmpty) {
      return [];
    }

    final ranked = _relevanceService.rankRecipes(
      recipes: recipes,
      products: products,
      prioritizeExpiringSoon: true,
      onlyAvailable: false,
    );
    if (ranked.isEmpty) return [];

    final topRecipe = ranked.first.recipe;
    return criticalProducts.map((product) {
      final days = product.expirationDate!.difference(now).inDays;
      final label = days == 1 ? 'amanha' : 'em 2 dias';
      final key = '${product.id}_${topRecipe.id}_${DateTime(now.year, now.month, now.day).toIso8601String()}';
      return NotificationSuggestion(
        key: key,
        title: 'Dica de consumo inteligente',
        body: 'Tempo de cozinhar ${topRecipe.title} com ${product.name} vencendo $label.',
        scheduledAt: now.add(const Duration(minutes: 2)),
        payload: {
          'productId': product.id,
          'recipeId': topRecipe.id,
          'route': '/recipes',
        },
      );
    }).toList();
  }
}
