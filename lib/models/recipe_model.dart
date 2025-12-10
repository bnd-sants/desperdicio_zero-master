// Recipe Model for the Desperdício Zero app
// This model represents a recipe with its associated products and tags

/// A class representing a product used in a recipe.
class RecipeProduct {
  final String id;
  final String recipeId;
  final String productId;
  final String name;
  final double quantity;
  final String unit;
  final int stepOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeProduct({
    required this.id,
    required this.recipeId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.stepOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecipeProduct.fromJson(Map<String, dynamic> json) {
    return RecipeProduct(
      id: json['id']?.toString() ?? '',
      recipeId: json['recipe_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Ingrediente sem nome',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'un',
      stepOrder: (json['step_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'step_order': stepOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// A class representing a Recipe in the application.
/// Contains all the necessary information about a recipe including its ingredients and tags.
class Recipe {
  final String id;
  final String userId;
  final String title;
  /// Optional description of the recipe
  final String? description;
  
  /// URL to the recipe image
  final String? imageUrl;
  
  /// Cooking instructions
  final String? instructions;
  
  /// Preparation time in minutes
  final int? prepTime;
  
  /// Cooking time in minutes
  final int? cookTime;
  
  /// Number of servings
  final int? servings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RecipeProduct> products; // List of ingredients/products needed
  final List<String>? tags; // Optional list of tags for filtering/categorization

  Recipe({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.imageUrl,
    this.instructions,
    this.prepTime,
    this.cookTime,
    this.servings,
    required this.createdAt,
    required this.updatedAt,
    List<RecipeProduct>? products,
    this.tags,
  }) : products = products ?? [];

  // Legacy getters for compatibility
  String get receita => title;
  String? get modoPreparo => instructions;
  String? get linkImagem => imageUrl;
  
  List<String> get listaDeIngredientes => products
      .map((p) => '${p.quantity} ${p.unit} de ${p.name}')
      .toList();

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Receita sem título',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      instructions: json['instructions']?.toString(),
      prepTime: (json['prep_time'] as num?)?.toInt(),
      cookTime: (json['cook_time'] as num?)?.toInt(),
      servings: (json['servings'] as num?)?.toInt(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      products: json['products'] != null
          ? (json['products'] as List)
              .map((p) => RecipeProduct.fromJson(
                  p is Map<String, dynamic> ? p : p.toJson()))
              .toList()
          : [],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'instructions': instructions,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'servings': servings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'products': products.map((p) => p.toJson()).toList(),
      if (tags != null) 'tags': tags,
    }..removeWhere((key, value) => value == null);
  }

  Recipe copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? imageUrl,
    String? instructions,
    int? prepTime,
    int? cookTime,
    int? servings,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RecipeProduct>? products,
    List<String>? tags,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      instructions: instructions ?? this.instructions,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      products: products ?? this.products,
      tags: tags ?? this.tags,
    );
  }
}

class Nutrition {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  const Nutrition({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class IngredienteBase {
  final int id;
  final List<String> nomesIngrediente;
  final int receitaId;
  final double? quantidade;
  final String? unidade;

  const IngredienteBase({
    required this.id,
    required this.nomesIngrediente,
    required this.receitaId,
    this.quantidade,
    this.unidade,
  });

  factory IngredienteBase.fromJson(Map<String, dynamic> json) {
    return IngredienteBase(
      id: json['id'] as int,
      nomesIngrediente: List<String>.from((json['nomesIngrediente'] as List<dynamic>?) ?? []),
      receitaId: json['receitaId'] as int? ?? 0,
      quantidade: (json['quantidade'] as num?)?.toDouble(),
      unidade: json['unidade'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomesIngrediente': nomesIngrediente,
      'receitaId': receitaId,
      'quantidade': quantidade,
      'unidade': unidade,
    };
  }
}
