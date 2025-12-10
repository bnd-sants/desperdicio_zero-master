import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';

class ExternalRecipeService {
  final SupabaseClient _supabase;

  ExternalRecipeService() : _supabase = Supabase.instance.client;
  
  Recipe? _mapToRecipe(Map<String, dynamic> json) {
    try {
      return Recipe(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? 'system',
        title: json['title']?.toString() ?? 'Receita sem nome',
        description: json['description']?.toString(),
        imageUrl: json['image_url']?.toString(),
        instructions: json['instructions']?.toString() ?? 'Instruções não disponíveis',
        prepTime: (json['prep_time'] as num?)?.toInt(),
        cookTime: (json['cook_time'] as num?)?.toInt(),
        servings: (json['servings'] as num?)?.toInt(),
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
        products: (json['recipe_products'] as List<dynamic>?)
            ?.map((rp) => RecipeProduct.fromJson(rp as Map<String, dynamic>))
            .toList() ?? [],
      );
    } catch (e) {
      debugPrint('Erro ao converter receita: $e');
      debugPrint('Dados da receita com problema: $json');
      return null;
    }
  }

  Future<List<Recipe>> searchRecipes({
    List<String>? ingredients,
    List<String>? recipeIdsParam,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('Buscando receitas no Supabase (Ambiente: ${kDebugMode ? 'Desenvolvimento' : 'Produção'})');
      
      // Se recebemos IDs específicos, usamos eles diretamente
      if (recipeIdsParam != null && recipeIdsParam.isNotEmpty) {
        debugPrint('Buscando receitas pelos IDs: $recipeIdsParam');
        final response = await _supabase
            .from('recipes')
            .select('''
              *,
              recipe_products(*, products(*))
            ''')
            .inFilter('id', recipeIdsParam)
            .order('created_at', ascending: false)
            .limit(limit)
            .range(offset, offset + limit - 1);
            
        final recipes = (response as List<dynamic>)
            .map<Recipe?>((json) => _mapToRecipe(json as Map<String, dynamic>))
            .whereType<Recipe>()
            .toList();
            
        debugPrint('Encontradas ${recipes.length} receitas');
        return recipes;
      }
      
      // Se não há ingredientes para filtrar, retorna as receitas mais recentes
      if (ingredients == null || ingredients.isEmpty) {
        debugPrint('Buscando todas as receitas (sem filtro)');
        final response = await _supabase
            .from('recipes')
            .select('''
              *,
              recipe_products(*, products(*))
            ''')
            .order('created_at', ascending: false)
            .limit(limit)
            .range(offset, offset + limit - 1);
            
        final recipes = (response as List<dynamic>)
            .map<Recipe?>((json) => _mapToRecipe(json as Map<String, dynamic>))
            .whereType<Recipe>()
            .toList();
            
        debugPrint('Encontradas ${recipes.length} receitas');
        return recipes;
      }
      
      // Se chegou aqui, vamos filtrar por ingredientes
      debugPrint('Filtrando por ingredientes: $ingredients');
      
      try {
        // Primeiro, buscar os produtos que correspondem aos ingredientes
        final searchTerm = ingredients.map((ing) => ing.trim().toLowerCase()).first;
        debugPrint('Buscando produtos que contêm: $searchTerm');
        
        // Primeiro, buscar todos os produtos que correspondem ao termo de busca
        final productsResponse = await _supabase
            .from('products')
            .select('id, name')
            .ilike('name', '%$searchTerm%');
            
        if (productsResponse.isEmpty) {
          debugPrint('Nenhum produto encontrado para os ingredientes: $ingredients');
          return [];
        }
        
        final productIds = (productsResponse as List<dynamic>)
            .map((e) => (e as Map<String, dynamic>)['id']?.toString())
            .whereType<String>()
            .toList();
            
        debugPrint('Produtos encontrados: $productIds');
        
        if (productIds.isEmpty) {
          return [];
        }
        
        // Agora buscar as receitas que usam esses produtos
        final recipesResponse = await _supabase
            .from('recipe_itens')
            .select('recipe_id')
            .inFilter('product_id', productIds);
            
        if (recipesResponse.isEmpty) {
          debugPrint('Nenhuma receita encontrada para os produtos: $productIds');
          return [];
        }
        
        final recipeIds = (recipesResponse as List<dynamic>)
            .map((e) => (e as Map<String, dynamic>)['recipe_id']?.toString())
            .whereType<String>()
            .toSet() // Remove duplicatas
            .toList();
            
        debugPrint('Receitas encontradas: $recipeIds');
        
        final response = await _supabase
            .from('recipes')
            .select('''
              *,
              recipe_products(*, products(*))
            ''')
            .inFilter('id', recipeIds)
            .order('created_at', ascending: false)
            .limit(limit)
            .range(offset, offset + limit - 1);
            
        final recipes = (response as List<dynamic>)
            .map<Recipe?>((json) => _mapToRecipe(json as Map<String, dynamic>))
            .whereType<Recipe>()
            .toList();
            
        debugPrint('Retornando ${recipes.length} receitas');
        return recipes;
      } catch (e, stackTrace) {
        debugPrint('Erro ao buscar receitas por ingredientes: $e');
        debugPrint('Stack trace: $stackTrace');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('Erro ao buscar receitas: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<Recipe?> getRecipeById(String id) async {
    try {
      final response = await _supabase
          .from('recipes')
          .select('''
            *,
            recipe_products(*, products(*))
          ''')
          .eq('id', id)
          .single();

      return _mapToRecipe(response);
    } catch (e) {
      debugPrint('Erro ao buscar receita por ID: $e');
      return null;
    }
  }

  Future<List<Recipe>> findRecipesByIngredients(List<String> ingredients) async {
    debugPrint('Buscando receitas por ingredientes: $ingredients');
    
    try {
      // Se não houver ingredientes, retorna todas as receitas
      if (ingredients.isEmpty) {
        debugPrint('Nenhum ingrediente especificado, retornando todas as receitas');
        return await searchRecipes();
      }
      
      // Se houver ingredientes, faz a busca filtrada
      return await searchRecipes(ingredients: ingredients);
    } catch (e, stackTrace) {
      debugPrint('Erro em findRecipesByIngredients: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }
}
