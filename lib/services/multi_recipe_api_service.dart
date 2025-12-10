import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_model.dart';

/// Serviço que gerencia múltiplas APIs de receitas com fallback automático e cache
class MultiRecipeApiService {
  static const Duration _cacheExpiration = Duration(hours: 24);
  static const Duration _apiTimeout = Duration(seconds: 5);
  
  // TheMealDB - API gratuita, sem necessidade de chave
  static const String _mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1/';
  
  // APIs alternativas para expansão futura:
  // - Tasty API (RapidAPI): 'https://tasty.p.rapidapi.com/'
  // - Edamam Recipe Search API: 'https://api.edamam.com/api/recipes/v2'
  // - Spoonacular API: 'https://api.spoonacular.com/recipes/'

  /// Busca uma refeição aleatória com fallback automático entre APIs
  static Future<Meal?> getRandomMeal() async {
    try {
      // Tenta buscar do cache primeiro
      final cachedMeal = await _getCachedRandomMeal();
      if (cachedMeal != null) {
        debugPrint('✅ Refeição aleatória carregada do cache');
        return cachedMeal;
      }

      // Tenta TheMealDB primeiro (mais rápida e gratuita)
      debugPrint('🍽️  Buscando refeição aleatória via TheMealDB...');
      final mealDbResult = await _getRandomMealFromMealDB();
      if (mealDbResult != null) {
        await _cacheRandomMeal(mealDbResult);
        return mealDbResult;
      }

      debugPrint('⚠️ TheMealDB falhou, tentando APIs alternativas...');
      
      // Se TheMealDB falhar, tenta buscar receitas populares
      final fallbackMeals = await searchMeals('popular');
      if (fallbackMeals.isNotEmpty) {
        final randomMeal = fallbackMeals[0];
        await _cacheRandomMeal(randomMeal);
        return randomMeal;
      }

      debugPrint('❌ Todas as APIs falharam');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao buscar refeição aleatória: $e\n$stackTrace');
      return null;
    }
  }

  /// Busca refeição aleatória do TheMealDB
  static Future<Meal?> _getRandomMealFromMealDB() async {
    try {
      final response = await http
          .get(
            Uri.parse('${_mealDbBaseUrl}random.php'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          final meal = Meal.fromJson(data['meals'][0]);
          debugPrint('✅ TheMealDB: ${meal.name}');
          return meal;
        }
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ TheMealDB timeout ou erro: $e');
      return null;
    }
  }

  /// Busca receitas com fallback entre múltiplas APIs
  static Future<List<Meal>> searchMeals(String query) async {
    if (query.isEmpty) return [];

    try {
      // Tenta buscar do cache primeiro
      final cachedResults = await _getCachedSearchResults(query);
      if (cachedResults.isNotEmpty) {
        debugPrint('✅ ${cachedResults.length} receitas carregadas do cache para: $query');
        return cachedResults;
      }

      debugPrint('🔍 Buscando receitas para: $query');

      // Executa buscas em paralelo para melhor performance
      final results = await Future.wait([
        _searchMealsInMealDB(query),
        _searchMealsInMealDBByIngredient(query),
      ]);

      // Combina resultados únicos
      final allMeals = <String, Meal>{};
      for (final mealList in results) {
        for (final meal in mealList) {
          allMeals[meal.id] = meal;
        }
      }

      final uniqueMeals = allMeals.values.toList();
      
      if (uniqueMeals.isNotEmpty) {
        await _cacheSearchResults(query, uniqueMeals);
        debugPrint('✅ ${uniqueMeals.length} receitas encontradas para: $query');
      } else {
        debugPrint('ℹ️ Nenhuma receita encontrada para: $query');
      }

      return uniqueMeals;
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao buscar receitas: $e\n$stackTrace');
      return [];
    }
  }

  /// Busca no TheMealDB por nome
  static Future<List<Meal>> _searchMealsInMealDB(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse('${_mealDbBaseUrl}search.php?s=$query'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          final meals = (data['meals'] as List)
              .map((meal) => Meal.fromJson(meal))
              .toList();
          debugPrint('✅ TheMealDB (nome): ${meals.length} receitas');
          return meals;
        }
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ TheMealDB (nome) falhou: $e');
      return [];
    }
  }

  /// Busca no TheMealDB por ingrediente
  static Future<List<Meal>> _searchMealsInMealDBByIngredient(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse('${_mealDbBaseUrl}filter.php?i=$query'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          // Limita a 5 receitas para não sobrecarregar
          final basicMeals = (data['meals'] as List).take(5).toList();
          
          // Busca detalhes em paralelo
          final detailFutures = basicMeals.map((meal) => 
            getMealById(meal['idMeal'].toString())
          ).toList();
          
          final detailedMeals = await Future.wait(detailFutures);
          final validMeals = detailedMeals.whereType<Meal>().toList();
          
          debugPrint('✅ TheMealDB (ingrediente): ${validMeals.length} receitas');
          return validMeals;
        }
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ TheMealDB (ingrediente) falhou: $e');
      return [];
    }
  }

  /// Busca detalhes de uma refeição por ID
  static Future<Meal?> getMealById(String id) async {
    if (id.isEmpty) return null;

    try {
      // Tenta buscar do cache primeiro
      final cachedMeal = await _getCachedMealById(id);
      if (cachedMeal != null) {
        debugPrint('✅ Refeição $id carregada do cache');
        return cachedMeal;
      }

      final response = await http
          .get(
            Uri.parse('${_mealDbBaseUrl}lookup.php?i=$id'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          final meal = Meal.fromJson(data['meals'][0]);
          await _cacheMealById(id, meal);
          return meal;
        }
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Erro ao buscar refeição $id: $e');
      return null;
    }
  }

  /// Busca receitas por ingrediente com otimização
  static Future<List<Meal>> filterByIngredient(String ingredient) async {
    if (ingredient.isEmpty) return [];

    try {
      // Tenta buscar do cache primeiro
      final cachedResults = await _getCachedSearchResults('ingredient:$ingredient');
      if (cachedResults.isNotEmpty) {
        debugPrint('✅ ${cachedResults.length} receitas carregadas do cache para ingrediente: $ingredient');
        return cachedResults;
      }

      debugPrint('🥕 Filtrando por ingrediente: $ingredient');

      final response = await http
          .get(
            Uri.parse('${_mealDbBaseUrl}filter.php?i=$ingredient'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          // Limita a 10 receitas para melhor performance
          final basicMeals = (data['meals'] as List).take(10).toList();
          
          // Busca detalhes em paralelo (máximo 3 por vez)
          final detailedMeals = <Meal>[];
          for (var i = 0; i < basicMeals.length; i += 3) {
            final batch = basicMeals.skip(i).take(3);
            final batchFutures = batch.map((meal) => 
              getMealById(meal['idMeal'].toString())
            ).toList();
            
            final batchResults = await Future.wait(batchFutures);
            detailedMeals.addAll(batchResults.whereType<Meal>());
          }

          if (detailedMeals.isNotEmpty) {
            await _cacheSearchResults('ingredient:$ingredient', detailedMeals);
          }

          debugPrint('✅ ${detailedMeals.length} receitas encontradas com ingrediente: $ingredient');
          return detailedMeals;
        }
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao filtrar por ingrediente: $e\n$stackTrace');
      return [];
    }
  }

  /// Busca categorias de refeições
  static Future<List<MealCategory>> getCategories() async {
    try {
      // Tenta buscar do cache primeiro
      final cachedCategories = await _getCachedCategories();
      if (cachedCategories.isNotEmpty) {
        debugPrint('✅ ${cachedCategories.length} categorias carregadas do cache');
        return cachedCategories;
      }

      debugPrint('📋 Buscando categorias...');

      final response = await http
          .get(
            Uri.parse('${_mealDbBaseUrl}categories.php'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['categories'] != null) {
          final categories = (data['categories'] as List)
              .map((cat) => MealCategory.fromJson(cat))
              .toList();
          
          await _cacheCategories(categories);
          debugPrint('✅ ${categories.length} categorias encontradas');
          return categories;
        }
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao buscar categorias: $e\n$stackTrace');
      return [];
    }
  }

  // ==================== MÉTODOS DE CACHE ====================

  static Future<Meal?> _getCachedRandomMeal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('random_meal');
      final timestamp = prefs.getInt('random_meal_timestamp');
      
      if (cached != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (cacheAge < _cacheExpiration.inMilliseconds) {
          return Meal.fromJson(json.decode(cached));
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _cacheRandomMeal(Meal meal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('random_meal', json.encode(meal.toJson()));
      await prefs.setInt('random_meal_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ Erro ao cachear refeição aleatória: $e');
    }
  }

  static Future<List<Meal>> _getCachedSearchResults(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'search_$query';
      final cached = prefs.getString(cacheKey);
      final timestamp = prefs.getInt('${cacheKey}_timestamp');
      
      if (cached != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (cacheAge < _cacheExpiration.inMilliseconds) {
          final List<dynamic> jsonList = json.decode(cached);
          return jsonList.map((json) => Meal.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> _cacheSearchResults(String query, List<Meal> meals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'search_$query';
      final jsonList = meals.map((meal) => meal.toJson()).toList();
      await prefs.setString(cacheKey, json.encode(jsonList));
      await prefs.setInt('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ Erro ao cachear resultados de busca: $e');
    }
  }

  static Future<Meal?> _getCachedMealById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'meal_$id';
      final cached = prefs.getString(cacheKey);
      final timestamp = prefs.getInt('${cacheKey}_timestamp');
      
      if (cached != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (cacheAge < _cacheExpiration.inMilliseconds) {
          return Meal.fromJson(json.decode(cached));
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _cacheMealById(String id, Meal meal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'meal_$id';
      await prefs.setString(cacheKey, json.encode(meal.toJson()));
      await prefs.setInt('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ Erro ao cachear refeição: $e');
    }
  }

  static Future<List<MealCategory>> _getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('categories');
      final timestamp = prefs.getInt('categories_timestamp');
      
      if (cached != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (cacheAge < _cacheExpiration.inMilliseconds) {
          final List<dynamic> jsonList = json.decode(cached);
          return jsonList.map((json) => MealCategory.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> _cacheCategories(List<MealCategory> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = categories.map((cat) => cat.toJson()).toList();
      await prefs.setString('categories', json.encode(jsonList));
      await prefs.setInt('categories_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ Erro ao cachear categorias: $e');
    }
  }

  /// Limpa todo o cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('random_meal') || 
        key.startsWith('search_') || 
        key.startsWith('meal_') || 
        key.startsWith('categories')
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('✅ Cache limpo com sucesso');
    } catch (e) {
      debugPrint('⚠️ Erro ao limpar cache: $e');
    }
  }
}
