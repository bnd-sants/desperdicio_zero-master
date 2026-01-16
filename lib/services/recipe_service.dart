import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/models/recipe_model.dart';
import 'package:flutter/foundation.dart';
import 'package:desperdicio_zero/utils/logger_util.dart' as logger;

// Extensão para filtrar por múltiplos valores
extension PostgrestFilterBuilderExtensions on PostgrestFilterBuilder {
  PostgrestFilterBuilder filterByList(String column, List<dynamic> values) {
    if (values.isEmpty) return this;
    return or(values.map((value) => '$column.eq.$value').join(','));
  }
}

class RecipeService {
  final SupabaseClient _supabase;
  
  RecipeService(this._supabase);
  
  // Converte strings de tempo como '10 min' ou '50-70 min' para minutos (int)
  int? _parseTimeString(String? timeStr) {
    if (timeStr == null) return null;
    
    // Tenta converter diretamente para número primeiro
    final directNumber = int.tryParse(timeStr);
    if (directNumber != null) return directNumber;
    
    // Remove espaços e converte para minúsculas
    final cleanStr = timeStr.trim().toLowerCase();
    
    // Verifica se está no formato 'X min' ou 'X-Y min'
    final match = RegExp(r'^(\d+)(?:-\d+)?\s*min(?:s|ute)?s?').firstMatch(cleanStr);
    if (match != null && match.groupCount >= 1) {
      return int.tryParse(match.group(1) ?? '0');
    }
    
    // Se não conseguir extrair o tempo, retorna null
    return null;
  }

  Future<List<Recipe>> getRecipes() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id ?? '';
      logger.logInfo('🔄 Buscando receitas para o usuário: $currentUserId');
      
      // Busca todas as receitas
      logger.logInfo('🔍 Buscando receitas...');
      final recipesResponse = await _supabase
          .from('recipes')
          .select('*')
          .order('created_at', ascending: false);
          
      if (kDebugMode) {
        logger.logDebug('📋 Estrutura da resposta das receitas:');
        logger.logDebug('- Total de receitas: ${recipesResponse.length}');
        if (recipesResponse.isNotEmpty) {
          logger.logDebug('- Chaves disponíveis: ${recipesResponse[0].keys.toList()}');
          logger.logDebug('- Primeira receita: ${recipesResponse[0]}');
        } else {
          logger.logDebug('Nenhuma receita encontrada no banco de dados');
        }
      }

      if (recipesResponse.isEmpty) {
        return [];
      }

      final recipeIds = recipesResponse.map((r) => r['id'].toString()).toList();
      
      logger.logInfo('🔍 Buscando produtos para ${recipeIds.length} receitas...');
      // Busca os produtos das receitas com JOIN na tabela itens para pegar o nome
      final recipeProductsResponse = await _supabase
          .from('recipe_itens')
          .select('''
            *,
            itens:itens(name)
          ''')
          .filterByList('recipe_id', recipeIds);
          
      if (kDebugMode) {
        logger.logDebug('📦 Produtos de receitas encontrados:');
        logger.logDebug('- Total de itens: ${recipeProductsResponse.length}');
        if (recipeProductsResponse.isNotEmpty) {
          logger.logDebug('- Primeiro item: ${recipeProductsResponse[0]}');
        }
      }
          
      if (kDebugMode) {
        logger.logDebug('📦 Produtos de receitas encontrados:');
        logger.logDebug('- Total de associações: ${recipeProductsResponse.length}');
        if (recipeProductsResponse.isNotEmpty) {
          logger.logDebug('- Primeiro produto de receita: ${recipeProductsResponse[0]}');
        }
      }

      logger.logInfo('✨ Total de associações de produtos de receitas: ${recipeProductsResponse.length}');
      final recipes = <Recipe>[];
      
      for (var recipeData in recipesResponse) {
        try {
          final recipeId = recipeData['id'].toString();
          
          // Filtra os produtos desta receita
          final recipeProductsData = (recipeProductsResponse as List)
              .where((rp) => rp['recipe_id'].toString() == recipeId)
              .toList();

          final recipeProducts = recipeProductsData.map<RecipeProduct>((rp) {
            // Pega o nome do item da tabela itens se disponível, senão usa um valor padrão
            final itemName = (rp['itens'] != null && rp['itens'] is Map) 
                ? (rp['itens'] as Map)['name']?.toString() 
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

          // Mapeia os dados da receita baseado na estrutura real da tabela
          final recipe = Recipe(
            id: recipeId,
            userId: currentUserId,
            title: recipeData['title']?.toString() ?? 'Sem título',
            // Usando valores padrão para campos que podem não existir
            description: recipeData['description']?.toString() ?? '',
            instructions: recipeData['modo_preparo']?.toString() ?? 
                         recipeData['instructions']?.toString() ?? '',
            imageUrl: recipeData['link_imagem']?.toString() ?? 
                     recipeData['image_url']?.toString(),
            // Campos opcionais
            prepTime: _parseTimeString(recipeData['prep_time']?.toString()),
            cookTime: _parseTimeString(recipeData['cook_time']?.toString()),
            servings: (recipeData['servings'] as num?)?.toInt(),
            // Datas com fallback para agora
            createdAt: recipeData['created_at'] != null
                ? DateTime.parse(recipeData['created_at'].toString())
                : DateTime.now(),
            updatedAt: recipeData['updated_at'] != null
                ? DateTime.parse(recipeData['updated_at'].toString())
                : DateTime.now(),
            // Produtos da receita
            products: recipeProducts,
          );
          
          if (kDebugMode) {
            logger.logDebug('✅ Receita processada: ${recipe.title} (${recipe.products.length} produtos)');
          }

          recipes.add(recipe);
        } catch (e) {
          logger.logError('❌ Erro ao processar receita ${recipeData['id']}: $e', e);
        }
      }

      logger.logInfo('✨ Total de receitas processadas com sucesso: ${recipes.length}');
      return recipes;
    } catch (e) {
      logger.logError('❌ Erro ao buscar receitas: $e', e);
      rethrow;
    }
  }
}
