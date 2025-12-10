import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

import '../models/spoonacular_models.dart';
import '../models/recipe_model.dart';
import 'auth_service.dart';

final _logger = Logger('SpoonacularService');

bool _loggingInitialized = false;

void setupLogging() {
  // Only initialize logging once
  if (_loggingInitialized) {
    return;
  }
  
  Logger.root.level = Level.INFO; // Set to INFO to reduce verbosity
  
  // Use print instead of logger to avoid potential loops
  Logger.root.onRecord.listen((record) {
    final buffer = StringBuffer();
    buffer.write('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');

    if (record.error != null) {
      buffer.write('\nError: ${record.error}');
    }
    if (record.stackTrace != null) {
      buffer.write('\nStack trace: ${record.stackTrace}');
    }

    // Use debugPrint for Flutter to avoid potential issues with print in release mode
    debugPrint(buffer.toString(), wrapWidth: 1024);
  });
  
  _loggingInitialized = true;
}

class SpoonacularService {
  static final SpoonacularService _instance = SpoonacularService._internal();
  final String _baseUrl = 'https://api.spoonacular.com/recipes';
  late final String _apiKey;
  final AuthService _authService;

  factory SpoonacularService() {
    return _instance;
  }

  SpoonacularService._internal() : _authService = AuthService() {
    _apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';
    setupLogging();
    if (_apiKey.isEmpty) {
      throw Exception('SPOONACULAR_API_KEY não encontrada no arquivo .env');
    }
  }

  // Lista de dietas suportadas
  static const List<String> availableDiets = [
    'vegetarian',
    'vegan',
    'gluten free',
    'ketogenic',
    'lacto-vegetarian',
    'ovo-vegetarian',
    'pescetarian',
    'paleo',
    'primal',
    'whole30',
  ];

  // Lista de intolerâncias suportadas
  static const List<String> availableIntolerances = [
    'dairy',
    'egg',
    'gluten',
    'grain',
    'peanut',
    'seafood',
    'sesame',
    'shellfish',
    'soy',
    'sulfite',
    'tree nut',
    'wheat',
  ];

  // Find recipes by ingredients (simplified version for suggestions)
  Future<List<SpoonacularRecipe>> findRecipesByIngredients(List<String> ingredients) async {
    try {
      if (ingredients.isEmpty) {
        _logger.warning('No ingredients provided for recipe search');
        return [];
      }

      // Log the ingredients being used for the search
      _logger.info('Searching for recipes with ingredients: ${ingredients.join(', ')}');
      
      final params = {
        'apiKey': _apiKey,
        'ingredients': ingredients.join(','),
        'number': '5',
        'ranking': '2',
        'ignorePantry': 'true',
      };

      _logger.fine('API Request Params: $params');
      final uri = Uri.https('api.spoonacular.com', '/recipes/findByIngredients', params);
      
      _logger.info('Making request to: $uri');
      final response = await http.get(uri);

      _logger.info('Response status: ${response.statusCode}');
      _logger.fine('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _logger.info('Found ${data.length} recipes');
        return data.map((json) => SpoonacularRecipe.fromJson(json)).toList();
      } else {
        final errorMsg = 'Failed to load recipes: ${response.statusCode} - ${response.body}';
        _logger.severe(errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      _logger.severe('Error finding recipes by ingredients', e, stackTrace);
      rethrow;
    }
  }

  // Get detailed recipe information
  Future<RecipeDetails> getRecipeDetails(int id) async {
    try {
      _logger.info('Fetching recipe details for ID: $id');
      
      // First, get the recipe details
      final response = await http.get(
        Uri.parse('$_baseUrl/$id/information?apiKey=$_apiKey&includeNutrition=true'),
      );

      if (response.statusCode == 200) {
        final recipe = RecipeDetails.fromJson(jsonDecode(response.body));
        
        // Get nutrition information
        final nutritionResponse = await http.get(
          Uri.parse('$_baseUrl/$id/nutritionWidget.json?apiKey=$_apiKey'),
        );

        if (nutritionResponse.statusCode == 200) {
          // Nutrition data is available as HTML, we'll handle it in the UI
          _logger.fine('Successfully fetched nutrition data for recipe $id');
        } else {
          _logger.warning('Failed to fetch nutrition data: ${nutritionResponse.statusCode}');
        }
        
        return recipe;
      } else {
        _logger.warning('Failed to load recipe details: ${response.statusCode}');
        throw Exception('Failed to load recipe details');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error in getRecipeDetails', e, stackTrace);
      rethrow;
    }
  }

  // Busca receitas por ingredientes com suporte a paginação
  Future<List<Recipe>> searchRecipesByIngredients({
    required List<String> ingredients,
    required String userId,
    int number = 10,
    int offset = 0,
    bool ignorePantry = true,
    int ranking = 2,
    List<String>? diets,
    List<String>? intolerances,
    bool? budgetFriendly = false,
  }) async {
    try {
      final ingredientsParam = ingredients.join(',');
      // Constrói a URL base
      final params = {
        'ingredients': ingredientsParam,
        'number': number.toString(),
        'offset': offset.toString(),
        'ignorePantry': ignorePantry.toString(),
        'ranking': ranking.toString(),
        'apiKey': _apiKey,
      };

      // Adiciona filtros de dieta, se fornecidos
      if (diets != null && diets.isNotEmpty) {
        params['diet'] = diets.join(',');
      }

      // Adiciona filtros de intolerância, se fornecidos
      if (intolerances != null && intolerances.isNotEmpty) {
        params['intolerances'] = intolerances.join(',');
      }

      // Constrói a URL com os parâmetros
      final uri = Uri.https(
        'api.spoonacular.com',
        '/recipes/findByIngredients',
        params,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Busca os detalhes completos de cada receita
        final recipes = await Future.wait(
          data.map((recipe) => getRecipeInformation(recipe['id'], userId: userId)),
        );

        return recipes.whereType<Recipe>().toList();
      } else {
        throw Exception('Falha ao carregar receitas: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Obtém informações detalhadas de uma receita
  Future<Recipe?> getRecipeInformation(int id, {required String userId}) async {
    try {
      _logger.info('Buscando detalhes da receita $id');
      final url = Uri.parse(
        '$_baseUrl/$id/information?includeNutrition=true&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recipe = SpoonacularRecipe.fromJson(data);
        return recipe.toRecipe(userId);
      } else {
        _logger.severe('Erro na requisição: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.severe('Erro ao buscar detalhes da receita', e);
      return null;
    }
  }

  // Busca receitas por nome com filtros avançados
  Future<List<Recipe>> searchRecipes({
    required String query,
    int number = 10,
    String? cuisine,
    List<String>? diets,
    List<String>? intolerances,
    String? type,
    int? maxReadyTime,
    bool? ignorePantry = true,
    bool? budgetFriendly = false,
  }) async {
    try {
      _logger.info('Buscando receitas aleatórias');
      // Constrói a URL base
      final params = {
        'query': query,
        'number': number.toString(),
        'apiKey': _apiKey,
        'instructionsRequired': 'true',
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
      };

      // Adiciona filtros opcionais
      if (cuisine != null) {
        params['cuisine'] = cuisine;
      }
      if (type != null) {
        params['type'] = type;
      }
      if (maxReadyTime != null) {
        params['maxReadyTime'] = maxReadyTime.toString();
      }
      if (ignorePantry != null) {
        params['ignorePantry'] = ignorePantry.toString();
      }

      // Adiciona filtros de dieta, se fornecidos
      if (diets != null && diets.isNotEmpty) {
        params['diet'] = diets.join(',');
      }

      // Adiciona filtros de intolerância, se fornecidos
      if (intolerances != null && intolerances.isNotEmpty) {
        params['intolerances'] = intolerances.join(',');
      }

      // Constrói a URL final
      final uri = Uri.https(
        'api.spoonacular.com',
        '/recipes/complexSearch',
        params,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;

        // Busca os detalhes completos de cada receita
        final recipes = await Future.wait(
          results.map((recipe) => getRecipeInformation(recipe['id'], userId: _authService.currentUser?.id ?? '')),
        );

        return recipes.whereType<Recipe>().toList();
      } else {
        throw Exception('Falha ao carregar receitas: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Erro ao buscar receitas', e);
      rethrow;
    }
  }

  // Obtém receitas aleatórias com suporte a paginação
  Future<List<Recipe>> getRandomRecipes({
    int number = 10,
    int offset = 0,
    List<String>? tags,
    List<String>? diets,
    List<String>? intolerances,
    int? maxReadyTime,
    bool? budgetFriendly = false,
  }) async {
    try {
      _logger.info('Buscando receitas aleatórias');
      // Constrói a URL base
      final params = {
        'number': number.toString(),
        'offset': offset.toString(),
        'apiKey': _apiKey,
        'instructionsRequired': 'true',
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
      };

      // Adiciona tags, se fornecidas
      if (tags != null && tags.isNotEmpty) {
        params['tags'] = tags.join(',');
      }

      // Adiciona filtros de dieta, se fornecidos
      if (diets != null && diets.isNotEmpty) {
        params['diet'] = diets.join(',');
      }

      // Adiciona filtros de intolerância, se fornecidos
      if (intolerances != null && intolerances.isNotEmpty) {
        params['intolerances'] = intolerances.join(',');
      }

      // Adiciona filtro de tempo máximo de preparo, se fornecido
      if (maxReadyTime != null) {
        params['maxReadyTime'] = maxReadyTime.toString();
      }

      // Constrói a URL final
      final uri = Uri.https('api.spoonacular.com', '/recipes/random', params);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recipes = data['recipes'] as List<dynamic>;

        // Busca os detalhes completos de cada receita
        final recipesWithDetails = await Future.wait(
          recipes.map((recipe) => getRecipeInformation(recipe['id'], userId: _authService.currentUser?.id ?? '')),
        );

        final filteredRecipes = recipesWithDetails.whereType<Recipe>().toList();
        return _filterRecipesByCost(
          filteredRecipes,
          budgetFriendly: budgetFriendly,
        );
      } else {
        throw Exception(
          'Falha ao carregar receitas aleatórias: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.severe('Erro ao buscar receitas aleatórias', e);
      rethrow;
    }
  }

  // Obtém informações detalhadas sobre um ingrediente
  Future<Map<String, dynamic>?> getIngredientInfo(int id) async {
    try {
      final url = Uri.parse(
        'https://api.spoonacular.com/food/ingredients/$id/information?amount=1&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        _logger.fine('Resposta da API: ${response.body}');
        return json.decode(response.body);
      } else {
        _logger.warning(
          'Falha ao carregar informações do ingrediente $id: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      _logger.severe('Erro ao buscar informações do ingrediente', e);
      return null;
    }
  }

  // Obtém substitutos para um ingrediente
  Future<List<Map<String, dynamic>>> getIngredientSubstitutes(int id) async {
    try {
      final url = Uri.parse(
        'https://api.spoonacular.com/food/ingredients/substitutes?ingredientId=$id&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['substitutes'] != null) {
          return (data['substitutes'] as List<dynamic>)
              .map(
                (sub) => {'name': sub, 'id': null},
              ) // IDs não estão disponíveis na API de substitutos
              .toList();
        }
      } else {
        _logger.warning(
          'Falha ao carregar substitutos para o ingrediente $id: ${response.statusCode}',
        );
      }
      return [];
    } catch (e) {
      _logger.severe('Erro ao buscar substitutos de ingrediente', e);
      return [];
    }
  }

  // Busca receitas que usam ingredientes específicos
  Future<List<Recipe>> findRecipesByIngredientsOptimized({
    required List<String> ingredients,
    required String userId,
    int number = 10,
    int offset = 0,
    bool ignorePantry = true,
    int ranking = 2,
    List<String>? diets,
    List<String>? intolerances,
    bool? budgetFriendly = false,
  }) async {
    try {
      final ingredientsParam = ingredients.join(',');
      final params = {
        'ingredients': ingredientsParam,
        'number': number.toString(),
        'offset': offset.toString(),
        'ignorePantry': ignorePantry.toString(),
        'ranking': '2', // Maximiza o uso de ingredientes fornecidos
        'apiKey': _apiKey,
        'limitLicense': 'true',
        'instructionsRequired': 'true',
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
      };

      // Adiciona filtros de dieta, se fornecidos
      if (diets != null && diets.isNotEmpty) {
        params['diet'] = diets.join(',');
      }

      // Adiciona filtros de intolerância, se fornecidos
      if (intolerances != null && intolerances.isNotEmpty) {
        params['intolerances'] = intolerances.join(',');
      }

      final uri = Uri.https(
        'api.spoonacular.com',
        '/recipes/findByIngredients',
        params,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Busca os detalhes completos de cada receita
        final recipes = await Future.wait(
          data.map((recipe) => getRecipeInformation(recipe['id'], userId: userId)),
        );

        return recipes.whereType<Recipe>().toList();
      } else {
        throw Exception('Falha ao carregar receitas: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Erro ao buscar receitas por ingredientes', e);
      rethrow;
    }
  }

  // Filtra receitas pelo tempo de preparo (quando disponível)
  List<Recipe> _filterRecipesByCost(
    List<Recipe> recipes, {
    bool? budgetFriendly,
  }) {
    if (budgetFriendly != true) return recipes;

    // Remove receitas sem tempo de preparo
    final recipesWithPrepTime = recipes
        .where((r) => r.prepTime != null)
        .toList();

    // Se não houver receitas com tempo de preparo, retorna as originais
    if (recipesWithPrepTime.isEmpty) return recipes;

    // Ordena as receitas pelo tempo de preparo (menor primeiro)
    recipesWithPrepTime.sort((a, b) {
      final timeA =
          a.prepTime ?? 9999; // Valor alto para receitas sem tempo definido
      final timeB = b.prepTime ?? 9999;
      return timeA.compareTo(timeB);
    });

    // Retorna as 50% mais rápidas
    final count = max(1, (recipesWithPrepTime.length * 0.5).ceil());
    return recipesWithPrepTime.sublist(
      0,
      min(count, recipesWithPrepTime.length),
    );
  }

  // Busca receitas similares
  Future<List<Recipe>> getSimilarRecipes(int recipeId, {int number = 5}) async {
    try {
      _logger.info('Buscando receitas similares para $recipeId');
      final url = Uri.parse(
        '$_baseUrl/$recipeId/similar?number=$number&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Busca os detalhes completos de cada receita similar
        final recipes = await Future.wait(
          data.map((recipe) => getRecipeInformation(recipe['id'], userId: _authService.currentUser?.id ?? '')),
        );

        return recipes.whereType<Recipe>().toList();
      } else {
        throw Exception(
          'Falha ao carregar receitas similares: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.severe('Erro ao buscar receitas similares', e);
      rethrow;
    }
  }
}
