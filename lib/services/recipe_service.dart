import 'package:desperdicio_zero/models/recipe_model.dart';
import 'package:desperdicio_zero/utils/logger_util.dart' as logger;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension PostgrestFilterBuilderExtensions on PostgrestFilterBuilder {
  PostgrestFilterBuilder filterByList(String column, List<dynamic> values) {
    if (values.isEmpty) return this;
    return or(values.map((value) => '$column.eq.$value').join(','));
  }
}

class RecipeService {
  final SupabaseClient _supabase;

  RecipeService(this._supabase);

  int? _parseTimeString(String? timeStr) {
    if (timeStr == null) return null;
    final directNumber = int.tryParse(timeStr);
    if (directNumber != null) return directNumber;

    final cleanStr = timeStr.trim().toLowerCase();
    final match = RegExp(r'^(\d+)(?:-\d+)?\s*min(?:s|ute)?s?').firstMatch(cleanStr);
    if (match != null && match.groupCount >= 1) {
      return int.tryParse(match.group(1) ?? '0');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchRecipeIngredients(List<String> recipeIds) async {
    try {
      final recipeItems = await _supabase
          .from('recipe_itens')
          .select('''
            *,
            itens:itens(name)
          ''')
          .filterByList('recipe_id', recipeIds);
      return (recipeItems as List).cast<Map<String, dynamic>>();
    } catch (_) {
      logger.logWarning('Tabela recipe_itens indisponivel, tentando recipe_products');
    }

    final fallback = await _supabase
        .from('recipe_products')
        .select('''
          *,
          products:products(name)
        ''')
        .filterByList('recipe_id', recipeIds);
    return (fallback as List).cast<Map<String, dynamic>>();
  }

  Future<List<Recipe>> getRecipes() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id ?? '';
      logger.logInfo('Buscando receitas para o usuario: $currentUserId');

      final recipesResponse = await _supabase.from('recipes').select('*').order('created_at', ascending: false);

      if (recipesResponse.isEmpty) return [];

      final recipeIds = recipesResponse.map((r) => r['id'].toString()).toList();
      final recipeProductsResponse = await _fetchRecipeIngredients(recipeIds);

      if (kDebugMode) {
        logger.logDebug('Total de associacoes de produtos de receitas: ${recipeProductsResponse.length}');
      }

      final recipes = <Recipe>[];

      for (final recipeData in recipesResponse) {
        try {
          final recipeId = recipeData['id'].toString();
          final recipeProductsData = recipeProductsResponse.where((rp) => rp['recipe_id'].toString() == recipeId).toList();

          final recipeProducts = recipeProductsData.map<RecipeProduct>((rp) {
            final itemName = (rp['itens'] != null && rp['itens'] is Map)
                ? (rp['itens'] as Map)['name']?.toString()
                : (rp['products'] != null && rp['products'] is Map)
                    ? (rp['products'] as Map)['name']?.toString()
                    : null;

            return RecipeProduct(
              id: rp['id']?.toString() ?? '',
              recipeId: rp['recipe_id']?.toString() ?? '',
              productId: rp['product_id']?.toString() ?? '',
              name: itemName ?? rp['name']?.toString() ?? 'Ingrediente sem nome',
              quantity: (rp['quantity'] as num?)?.toDouble() ?? 1.0,
              unit: rp['unit']?.toString() ?? 'un',
              stepOrder: (rp['step_order'] as num?)?.toInt() ?? 0,
              createdAt: rp['created_at'] != null
                  ? DateTime.parse(rp['created_at'].toString())
                  : DateTime.now(),
              updatedAt: rp['updated_at'] != null
                  ? DateTime.parse(rp['updated_at'].toString())
                  : DateTime.now(),
            );
          }).toList();

          final recipe = Recipe(
            id: recipeId,
            userId: currentUserId,
            title: recipeData['title']?.toString() ?? 'Sem titulo',
            description: recipeData['description']?.toString() ?? '',
            instructions: recipeData['modo_preparo']?.toString() ?? recipeData['instructions']?.toString() ?? '',
            imageUrl: recipeData['link_imagem']?.toString() ?? recipeData['image_url']?.toString(),
            prepTime: _parseTimeString(recipeData['prep_time']?.toString()),
            cookTime: _parseTimeString(recipeData['cook_time']?.toString()),
            servings: (recipeData['servings'] as num?)?.toInt(),
            createdAt: recipeData['created_at'] != null
                ? DateTime.parse(recipeData['created_at'].toString())
                : DateTime.now(),
            updatedAt: recipeData['updated_at'] != null
                ? DateTime.parse(recipeData['updated_at'].toString())
                : DateTime.now(),
            products: recipeProducts,
          );

          recipes.add(recipe);
        } catch (e) {
          logger.logError('Erro ao processar receita ${recipeData['id']}: $e', e);
        }
      }

      return recipes;
    } catch (e) {
      logger.logError('Erro ao buscar receitas: $e', e);
      rethrow;
    }
  }
}
