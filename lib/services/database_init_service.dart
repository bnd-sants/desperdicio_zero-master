import 'package:desperdicio_zero/models/food_model.dart';
import 'package:desperdicio_zero/models/recipe_model.dart';
import 'package:desperdicio_zero/services/local_food_service.dart';

class DatabaseInitService {
  final LocalFoodService _localFoodService = LocalFoodService();

  Future<void> initializeDatabase() async {
    // Inicializa o banco de dados
    await _localFoodService.database;
    
    // Adiciona alimentos iniciais
    await _addInitialFoods();
    
    // Adiciona receitas iniciais
    await _addInitialRecipes();
  }

  Future<void> _addInitialFoods() async {
    final foods = [
      Food(
        name: 'Arroz',
        category: 'Grãos e Cereais',
        calories: 130,
        protein: 2.7,
        carbs: 28.2,
        fat: 0.3,
      ),
      Food(
        name: 'Feijão',
        category: 'Leguminosas',
        calories: 127,
        protein: 8.6,
        carbs: 22.8,
        fat: 0.5,
      ),
      Food(
        name: 'Frango',
        category: 'Carnes',
        calories: 165,
        protein: 31.0,
        carbs: 0.0,
        fat: 3.6,
      ),
      Food(
        name: 'Batata',
        category: 'Tubérculos',
        calories: 77,
        protein: 2.0,
        carbs: 17.5,
        fat: 0.1,
      ),
      Food(
        name: 'Cenoura',
        category: 'Legumes',
        calories: 41,
        protein: 0.9,
        carbs: 9.6,
        fat: 0.2,
      ),
      Food(
        name: 'Cebola',
        category: 'Temperos',
        calories: 40,
        protein: 1.1,
        carbs: 9.3,
        fat: 0.1,
      ),
      Food(
        name: 'Alho',
        category: 'Temperos',
        calories: 149,
        protein: 6.4,
        carbs: 33.1,
        fat: 0.5,
      ),
      Food(
        name: 'Óleo de Soja',
        category: 'Gorduras',
        calories: 884,
        protein: 0.0,
        carbs: 0.0,
        fat: 100.0,
      ),
      Food(
        name: 'Sal',
        category: 'Temperos',
        calories: 0,
        protein: 0.0,
        carbs: 0.0,
        fat: 0.0,
      ),
      Food(
        name: 'Água',
        category: 'Bebidas',
        calories: 0,
        protein: 0.0,
        carbs: 0.0,
        fat: 0.0,
      ),
    ];

    await _localFoodService.insertFoods(foods);
  }

  Future<void> _addInitialRecipes() async {
    final recipes = [
      Recipe(
        id: 'rec1',
        userId: 'system',
        title: 'Arroz com Frango',
        description: 'Um clássico da culinária brasileira, simples e saboroso.',
        instructions: '1. Cozinhe o arroz na água com sal.\n2. Tempere o frango com sal e alho.\n3. Grelhe o frango até dourar.\n4. Sirva o arroz com o frango grelhado.',
        imageUrl: 'assets/images/arroz_frango.jpg',
        prepTime: 10,
        cookTime: 30,
        servings: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        products: [
          RecipeProduct(
            id: 'rec1_ing1',
            recipeId: 'rec1',
            productId: '1',
            name: 'Arroz',
            quantity: 2,
            unit: 'xícaras',
            stepOrder: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          RecipeProduct(
            id: 'rec1_ing2',
            recipeId: 'rec1',
            productId: '3',
            name: 'Frango',
            quantity: 500,
            unit: 'gramas',
            stepOrder: 2,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          RecipeProduct(
            id: 'rec1_ing3',
            recipeId: 'rec1',
            productId: '8',
            name: 'Sal',
            quantity: 1,
            unit: 'colher de chá',
            stepOrder: 3,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          RecipeProduct(
            id: 'rec1_ing4',
            recipeId: 'rec1',
            productId: '7',
            name: 'Alho',
            quantity: 2,
            unit: 'dentes',
            stepOrder: 4,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      // Adicione mais receitas conforme necessário
    ];

    await _localFoodService.insertRecipes(recipes);
  }
}
