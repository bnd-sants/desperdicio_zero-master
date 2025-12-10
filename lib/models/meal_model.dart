class Meal {
  final String id;
  final String name;
  final String? drinkAlternate;
  final String category;
  final String area;
  final String instructions;
  final String? thumbnailUrl;
  final List<String> tags;
  final String? youtubeUrl;
  final List<Ingredient> ingredients;
  final String? source;
  final String? imageSource;
  final String? creativeCommonsConfirmed;
  final String? dateModified;

  Meal({
    required this.id,
    required this.name,
    this.drinkAlternate,
    required this.category,
    required this.area,
    required this.instructions,
    this.thumbnailUrl,
    required this.tags,
    this.youtubeUrl,
    required this.ingredients,
    this.source,
    this.imageSource,
    this.creativeCommonsConfirmed,
    this.dateModified,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    // Extract ingredients and measures
    final ingredients = <Ingredient>[];
    for (var i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i']?.toString().trim();
      final measure = json['strMeasure$i']?.toString().trim();

      if (ingredient != null && ingredient.isNotEmpty) {
        ingredients.add(Ingredient(name: ingredient, measure: measure ?? ''));
      }
    }

    // Extract tags
    final tags = <String>[];
    if (json['strTags'] != null) {
      tags.addAll((json['strTags'] as String).split(',').map((t) => t.trim()));
    }

    return Meal(
      id: json['idMeal'],
      name: json['strMeal'],
      drinkAlternate: json['strDrinkAlternate'],
      category: json['strCategory'] ?? '',
      area: json['strArea'] ?? '',
      instructions: json['strInstructions'] ?? '',
      thumbnailUrl: json['strMealThumb'],
      tags: tags,
      youtubeUrl: json['strYoutube'],
      ingredients: ingredients,
      source: json['strSource'],
      imageSource: json['strImageSource'],
      creativeCommonsConfirmed: json['strCreativeCommonsConfirmed'],
      dateModified: json['dateModified'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strDrinkAlternate': drinkAlternate,
      'strCategory': category,
      'strArea': area,
      'strInstructions': instructions,
      'strMealThumb': thumbnailUrl,
      'strTags': tags.join(','),
      'strYoutube': youtubeUrl,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'strSource': source,
      'strImageSource': imageSource,
      'strCreativeCommonsConfirmed': creativeCommonsConfirmed,
      'dateModified': dateModified,
    };
  }
}

class Ingredient {
  final String name;
  final String measure;

  Ingredient({required this.name, required this.measure});

  Map<String, dynamic> toJson() => {'name': name, 'measure': measure};
}

class MealCategory {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String description;

  MealCategory({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.description,
  });

  factory MealCategory.fromJson(Map<String, dynamic> json) {
    return MealCategory(
      id: json['idCategory'],
      name: json['strCategory'],
      thumbnailUrl: json['strCategoryThumb'],
      description: json['strCategoryDescription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCategory': id,
      'strCategory': name,
      'strCategoryThumb': thumbnailUrl,
      'strCategoryDescription': description,
    };
  }
}
