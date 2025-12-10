import 'package:flutter/material.dart';
import 'recipe_model.dart';
import 'localized_text.dart';
import '../services/translation_service.dart';

class RecipeDetails {
  final int id;
  final LocalizedText title;
  final String image;
  final LocalizedText summary;
  final List<dynamic> extendedIngredients;
  final List<dynamic> analyzedInstructions;
  final int readyInMinutes;
  final int servings;
  final bool vegetarian;
  final bool vegan;
  final bool glutenFree;
  final bool dairyFree;
  
  // Cache for translated instructions
  Map<String, dynamic>? _translatedInstructions;

  RecipeDetails({
    required this.id,
    required this.title,
    required this.image,
    required this.summary,
    required this.extendedIngredients,
    required this.analyzedInstructions,
    required this.readyInMinutes,
    required this.servings,
    required this.vegetarian,
    required this.vegan,
    required this.glutenFree,
    required this.dairyFree,
  });

  factory RecipeDetails.fromJson(Map<String, dynamic> json) {
    return RecipeDetails(
      id: json['id'] ?? 0,
      title: LocalizedText(
        en: json['title'] ?? '',
        pt: json['title'], // Will be updated with translation
      ),
      image: json['image'] ?? '',
      summary: LocalizedText(
        en: (json['summary'] ?? '').replaceAll(RegExp(r'<[^>]*>'), ''),
        // Portuguese translation will be fetched later
      ),
      extendedIngredients: json['extendedIngredients'] ?? [],
      analyzedInstructions: json['analyzedInstructions'] ?? [],
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 1,
      vegetarian: json['vegetarian'] ?? false,
      vegan: json['vegan'] ?? false,
      glutenFree: json['glutenFree'] ?? false,
      dairyFree: json['dairyFree'] ?? false,
    );
  }
  
  // Get instructions in the current app language
  List<dynamic> getLocalizedInstructions(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isPortuguese = locale.languageCode == 'pt';
    
    if (!isPortuguese) {
      return analyzedInstructions;
    }
    
    // Return cached translations if available
    if (_translatedInstructions != null) {
      return [_translatedInstructions!];
    }
    
    // Otherwise return English instructions (will be translated on demand)
    return analyzedInstructions;
  }
  
  // Translate recipe details to Portuguese
  Future<void> translateToPortuguese() async {
    title.pt ??= await TranslationService.translateText(title.en, from: 'en', to: 'pt');
    summary.pt ??= await TranslationService.translateText(summary.en, from: 'en', to: 'pt');
    
    // Translate instructions if not already translated
    _translatedInstructions ??= {};
    if (analyzedInstructions.isNotEmpty) {
      final instructions = analyzedInstructions.first;
      final steps = List<Map<String, dynamic>>.from(instructions['steps'] ?? []);
      
      // Translate each step
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        final translatedStep = await TranslationService.translateText(
          step['step'] ?? '',
          from: 'en',
          to: 'pt',
        );
        steps[i] = {
          ...step,
          'step': translatedStep,
        };
      }
      
      _translatedInstructions = {
        ...instructions,
        'steps': steps,
      };
    }
  }
}

class SpoonacularRecipe {
  final int id;
  final String title;
  final String? image;
  final String? summary;
  final String? instructions;
  final int? readyInMinutes;
  final int? servings;
  final List<SpoonacularIngredient>? extendedIngredients;
  final SpoonacularNutrition? nutrition;
  final List<SpoonacularAnalyzedInstruction>? analyzedInstructions;
  final List<String>? dishTypes;
  final List<String>? diets;
  final List<String>? cuisines;
  final int usedIngredientCount;
  final int missedIngredientCount;
  final List<dynamic> usedIngredients;
  final List<dynamic> missedIngredients;

  SpoonacularRecipe({
    required this.id,
    required this.title,
    this.image,
    this.summary,
    this.instructions,
    this.readyInMinutes,
    this.servings,
    this.extendedIngredients,
    this.nutrition,
    this.analyzedInstructions,
    this.dishTypes,
    this.diets,
    this.cuisines,
    this.usedIngredientCount = 0,
    this.missedIngredientCount = 0,
    this.usedIngredients = const [],
    this.missedIngredients = const [],
  });

  factory SpoonacularRecipe.fromJson(Map<String, dynamic> json) {
    return SpoonacularRecipe(
      id: json['id'] as int,
      title: json['title'] ?? 'Sem título',
      image: json['image'],
      summary: json['summary']?.replaceAll(RegExp(r'<[^>]*>'), ''),
      instructions: json['instructions'],
      readyInMinutes: json['readyInMinutes'],
      servings: json['servings'],
      usedIngredientCount: json['usedIngredientCount'] ?? 0,
      missedIngredientCount: json['missedIngredientCount'] ?? 0,
      usedIngredients: json['usedIngredients'] ?? [],
      missedIngredients: json['missedIngredients'] ?? [],
      extendedIngredients: json['extendedIngredients'] != null
          ? (json['extendedIngredients'] as List)
                .map((e) => SpoonacularIngredient.fromJson(e))
                .toList()
          : null,
      nutrition: json['nutrition'] != null
          ? SpoonacularNutrition.fromJson(json['nutrition'])
          : null,
      analyzedInstructions: json['analyzedInstructions'] != null
          ? (json['analyzedInstructions'] as List)
                .map((e) => SpoonacularAnalyzedInstruction.fromJson(e))
                .toList()
          : null,
      dishTypes: json['dishTypes'] != null
          ? List<String>.from(json['dishTypes'])
          : null,
      diets: json['diets'] != null ? List<String>.from(json['diets']) : null,
      cuisines: json['cuisines'] != null
          ? List<String>.from(json['cuisines'])
          : null,
    );
  }

  // Converte para o modelo de Recipe existente
  Recipe toRecipe(String userId) {
    final now = DateTime.now();
    
    return Recipe(
      id: id.toString(),
      userId: userId,
      title: title,
      description: summary,
      imageUrl: image,
      instructions: _getFormattedInstructions(),
      prepTime: readyInMinutes,
      cookTime: readyInMinutes,
      servings: servings,
      createdAt: now,
      updatedAt: now,
      products: [], // Will be populated separately if needed
    );
  }

  String _getFormattedInstructions() {
    if (instructions?.isNotEmpty == true) {
      return instructions!;
    }

    if (analyzedInstructions?.isNotEmpty == true) {
      return analyzedInstructions!
          .expand((i) => i.steps)
          .map((step) => '${step.number}. ${step.step}')
          .join('\n\n');
    }

    return 'Instruções não disponíveis';
  }
}

class SpoonacularIngredient {
  final int id;
  final String name;
  final String? nameClean;
  final String? original;
  final double? amount;
  final String? unit;
  final String? unitShort;
  final String? unitLong;
  final String? image;

  SpoonacularIngredient({
    required this.id,
    required this.name,
    this.nameClean,
    this.original,
    this.amount,
    this.unit,
    this.unitShort,
    this.unitLong,
    this.image,
  });

  factory SpoonacularIngredient.fromJson(Map<String, dynamic> json) {
    return SpoonacularIngredient(
      id: json['id'],
      name: json['name'],
      nameClean: json['nameClean'],
      original: json['original'],
      amount: json['amount']?.toDouble(),
      unit: json['unit'],
      unitShort: json['unitShort'],
      unitLong: json['unitLong'],
      image: json['image'],
    );
  }
}

class SpoonacularNutrition {
  final List<SpoonacularNutrient>? nutrients;
  final List<SpoonacularIngredient>? ingredients;

  SpoonacularNutrition({this.nutrients, this.ingredients});

  factory SpoonacularNutrition.fromJson(Map<String, dynamic> json) {
    return SpoonacularNutrition(
      nutrients: json['nutrients'] != null
          ? (json['nutrients'] as List)
                .map((e) => SpoonacularNutrient.fromJson(e))
                .toList()
          : null,
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List)
                .map((e) => SpoonacularIngredient.fromJson(e))
                .toList()
          : null,
    );
  }

  Nutrition? toNutrition() {
    if (nutrients == null) return null;

    double? getNutrientValue(String name) {
      try {
        return double.tryParse(
          nutrients
                  ?.firstWhere(
                    (n) =>
                        n.name?.toLowerCase().contains(name.toLowerCase()) ==
                        true,
                    orElse: () => SpoonacularNutrient(amount: 0, name: name),
                  )
                  .amount
                  ?.toString() ??
              '0',
        );
      } catch (e) {
        return 0.0;
      }
    }

    return Nutrition(
      calories: getNutrientValue('calories'),
      protein: getNutrientValue('protein'),
      carbs: getNutrientValue('carbohydrate'),
      fat: getNutrientValue('fat'),
    );
  }
}

class SpoonacularNutrient {
  final String? name;
  final double? amount;
  final String? unit;
  final double? percentOfDailyNeeds;

  SpoonacularNutrient({
    this.name,
    this.amount,
    this.unit,
    this.percentOfDailyNeeds,
  });

  factory SpoonacularNutrient.fromJson(Map<String, dynamic> json) {
    return SpoonacularNutrient(
      name: json['name'],
      amount: json['amount']?.toDouble(),
      unit: json['unit'],
      percentOfDailyNeeds: json['percentOfDailyNeeds']?.toDouble(),
    );
  }
}

class SpoonacularAnalyzedInstruction {
  final String? name;
  final List<SpoonacularInstructionStep> steps;

  SpoonacularAnalyzedInstruction({this.name, required this.steps});

  factory SpoonacularAnalyzedInstruction.fromJson(Map<String, dynamic> json) {
    return SpoonacularAnalyzedInstruction(
      name: json['name'],
      steps: (json['steps'] as List)
          .map((e) => SpoonacularInstructionStep.fromJson(e))
          .toList(),
    );
  }
}

class SpoonacularInstructionStep {
  final int number;
  final String step;
  final List<SpoonacularIngredient>? ingredients;
  final List<SpoonacularEquipment>? equipment;
  final dynamic length;

  SpoonacularInstructionStep({
    required this.number,
    required this.step,
    this.ingredients,
    this.equipment,
    this.length,
  });

  factory SpoonacularInstructionStep.fromJson(Map<String, dynamic> json) {
    return SpoonacularInstructionStep(
      number: json['number'],
      step: json['step'],
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List)
                .map((e) => SpoonacularIngredient.fromJson(e))
                .toList()
          : null,
      equipment: json['equipment'] != null
          ? (json['equipment'] as List)
                .map((e) => SpoonacularEquipment.fromJson(e))
                .toList()
          : null,
      length: json['length'],
    );
  }
}

class SpoonacularEquipment {
  final int id;
  final String name;
  final String? localizedName;
  final String? image;

  SpoonacularEquipment({
    required this.id,
    required this.name,
    this.localizedName,
    this.image,
  });

  factory SpoonacularEquipment.fromJson(Map<String, dynamic> json) {
    return SpoonacularEquipment(
      id: json['id'],
      name: json['name'],
      localizedName: json['localizedName'],
      image: json['image'],
    );
  }
}
