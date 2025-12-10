import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/services/external_recipe_service.dart';
import 'package:desperdicio_zero/models/recipe_model.dart';

final externalRecipeProvider = Provider((ref) => ExternalRecipeService());

final recipeSuggestionsProvider = FutureProvider.family.autoDispose<List<Recipe>, String>((ref, ingredientsKey) async {
  debugPrint('🔍 [ExternalRecipeProvider] Buscando sugestões de receitas para: "$ingredientsKey"');
  
  try {
    // Converte a chave em lista de ingredientes
    final ingredients = ingredientsKey
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    
    final recipeService = ref.read(externalRecipeProvider);
    final result = await recipeService.findRecipesByIngredients(ingredients);
    debugPrint('✅ [ExternalRecipeProvider] ${result.length} receitas encontradas');
    return result;
  } catch (e, stackTrace) {
    debugPrint('❌ [ExternalRecipeProvider] Erro ao buscar receitas: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
});

final recipeDetailsProvider = FutureProvider.family.autoDispose<Recipe, String>((ref, recipeId) async {
  try {
    debugPrint('🔍 [ExternalRecipeProvider] Buscando detalhes da receita ID: $recipeId');
    
    // Para simplificar, vamos apenas retornar uma receita vazia
    // Em uma implementação real, você buscaria os detalhes da receita pelo ID
    return Recipe(
      id: recipeId,
      userId: 'external',
      title: 'Detalhes da receita',
      instructions: 'Detalhes da receita não disponíveis',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ [ExternalRecipeProvider] Erro ao carregar detalhes da receita: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
});

// Extensão para adicionar funcionalidade de cache
extension CacheForExtension on AutoDisposeRef<Object?> {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, () {
      link.close();
    });
    onDispose(() {
      timer.cancel();
    });
  }
}
