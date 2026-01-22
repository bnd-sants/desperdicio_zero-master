import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:desperdicio_zero/models/recipe_model.dart';
import 'package:desperdicio_zero/models/food_model.dart';

class LocalFoodService {
  static final LocalFoodService _instance = LocalFoodService._internal();
  static Database? _database;
  static bool _factoryInitialized = false;

  factory LocalFoodService() => _instance;

  LocalFoodService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  void _ensureDatabaseFactory() {
    if (_factoryInitialized) {
      return;
    }

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _factoryInitialized = true;
  }

  Future<Database> _initDatabase() async {
    _ensureDatabaseFactory();
    // CORREÇÃO 1: Mudei o nome para forçar a criação de um banco novo e limpo
    final path = join(await getDatabasesPath(), 'food_database_v2.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Tabela de alimentos
    await db.execute('''
      CREATE TABLE foods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        calories REAL,
        protein REAL,
        carbs REAL,
        fat REAL,
        image_url TEXT,
        barcode TEXT
      )
    ''');

    // Tabela de receitas
    // CORREÇÃO 2: Adicionei a coluna user_id
    await db.execute('''
      CREATE TABLE recipes(
        id TEXT PRIMARY KEY,
        user_id TEXT, 
        title TEXT NOT NULL,
        description TEXT,
        instructions TEXT,
        image_url TEXT,
        prep_time INTEGER,
        cook_time INTEGER,
        servings INTEGER,
        created_at TEXT, 
        updated_at TEXT
      )
    ''');
    // Nota: Mudei created_at/updated_at para TEXT pois o erro mostrava strings ISO8601

    // Tabela de ingredientes das receitas
    await db.execute('''
      CREATE TABLE recipe_ingredients(
        id TEXT PRIMARY KEY,
        recipe_id TEXT,
        food_id INTEGER,
        quantity REAL,
        unit TEXT,
        notes TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id),
        FOREIGN KEY (food_id) REFERENCES foods(id)
      )
    ''');
  }

  // Métodos para alimentos
  Future<List<Food>> searchFoods(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return List.generate(maps.length, (i) => Food.fromJson(maps[i]));
  }

  // Métodos para receitas
  Future<List<Recipe>> searchRecipes(List<String> ingredients) async {
    final db = await database;
    
    // Converte a lista de ingredientes para uma string de parâmetros
    final placeholders = List.filled(ingredients.length, '?').join(',');
    
    // Busca receitas que contenham pelo menos um dos ingredientes fornecidos
    final List<Map<String, dynamic>> recipes = await db.rawQuery('''
      SELECT DISTINCT r.* FROM recipes r
      JOIN recipe_ingredients ri ON r.id = ri.recipe_id
      JOIN foods f ON ri.food_id = f.id
      WHERE f.name IN ($placeholders)
      ORDER BY 
        (SELECT COUNT(*) FROM recipe_ingredients ri2 WHERE ri2.recipe_id = r.id) 
        - 
        (SELECT COUNT(*) FROM recipe_ingredients ri3 
         JOIN foods f2 ON ri3.food_id = f2.id 
         WHERE ri3.recipe_id = r.id AND f2.name IN ($placeholders))
      LIMIT 10
    ''', [...ingredients, ...ingredients]);

    return recipes.map((json) => Recipe.fromJson(json)).toList();
  }

  // Método para adicionar alimentos ao banco de dados
  Future<void> insertFoods(List<Food> foods) async {
    final db = await database;
    final batch = db.batch();
    
    for (var food in foods) {
      batch.insert('foods', food.toJson(), 
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }

  // Método para adicionar receitas ao banco de dados
  Future<void> insertRecipes(List<Recipe> recipes) async {
    final db = await database;
    final batch = db.batch();
    
    for (var recipe in recipes) {
      // CORREÇÃO 3: Remover a lista 'products' do JSON antes de salvar na tabela 'recipes'
      // O sqflite tenta salvar tudo que vem no toJson(), e a lista 'products' causaria erro
      final recipeMap = recipe.toJson();
      recipeMap.remove('products'); 

      batch.insert('recipes', recipeMap, 
          conflictAlgorithm: ConflictAlgorithm.replace);
      
      // Adiciona os ingredientes da receita na tabela relacional
      for (var product in recipe.products) {
        batch.insert('recipe_ingredients', {
          'id': '${recipe.id}_${product.id}',
          'recipe_id': recipe.id,
          'food_id': product.productId,
          'quantity': product.quantity,
          'unit': product.unit,
          'notes': ''
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    
    await batch.commit(noResult: true);
  }

  Future<void> clearAll() async {
    final dbPath = join(await getDatabasesPath(), 'food_database_v2.db');

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Nota: deleteDatabase na web pode não funcionar como esperado dependendo da implementação,
    // mas mudar o nome do arquivo no _initDatabase resolve o problema de cache.
    await deleteDatabase(dbPath);
  }
}