import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/products/product_provider.dart';
import 'package:desperdicio_zero/screens/recipe_suggestions_screen.dart';

// Simple Portuguese to English ingredient translations
const Map<String, String> _ingredientTranslations = {
  'arroz': 'rice',
  'feijão': 'beans',
  'feijao': 'beans',
  'frango': 'chicken',
  'carne': 'beef',
  'batata': 'potato',
  'cenoura': 'carrot',
  'cebola': 'onion',
  'alho': 'garlic',
  'ovo': 'egg',
  'ovos': 'eggs',
  'leite': 'milk',
  'pão': 'bread',
  'pao': 'bread',
  'queijo': 'cheese',
  'tomate': 'tomato',
  'alface': 'lettuce',
  'pepino': 'cucumber',
  'pimentão': 'bell pepper',
  'pimentao': 'bell pepper',
  'macarrão': 'pasta',
  'macarrao': 'pasta',
  'peixe': 'fish',
  'camarão': 'shrimp',
  'camarao': 'shrimp',
  'fruta': 'fruit',
  'maçã': 'apple',
  'maca': 'apple',
  'banana': 'banana',
  'laranja': 'orange',
  'limão': 'lemon',
  'limao': 'lemon',
  'batata doce': 'sweet potato',
  'batata-doce': 'sweet potato',
  'batata inglesa': 'potato',
  'batata-inglesa': 'potato',
  'cebolinha': 'green onion',
  'salsinha': 'parsley',
  'coentro': 'cilantro',
  'manjericão': 'basil',
  'manjericao': 'basil',
  'orégano': 'oregano',
  'oregano': 'oregano',
  'azeite': 'olive oil',
  'óleo': 'oil',
  'oleo': 'oil',
  'manteiga': 'butter',
  'açúcar': 'sugar',
  'acucar': 'sugar',
  'sal': 'salt',
  'pimenta': 'pepper',
  'farinha': 'flour',
  'farinha de trigo': 'wheat flour',
  'açúcar mascavo': 'brown sugar',
  'acucar mascavo': 'brown sugar',
  'canela': 'cinnamon',
  'chocolate': 'chocolate',
  'café': 'coffee',
  'cafe': 'coffee',
  'chá': 'tea',
  'cha': 'tea',
};

class RecipeNavigationHelper {
  static Future<void> navigateToRecipeSuggestions(
    BuildContext context, 
    WidgetRef ref
  ) async {
    // Get user's products
    final productsState = ref.read(productsProvider);
    
    // Extract and translate product names for the API
    final ingredients = productsState.maybeWhen<List<String>>(
      loading: () => <String>[],
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $error')),
        );
        return <String>[];
      },
      data: (products) => products
          .where((p) => !p.isExpired) // Only use non-expired products
          .map((p) {
            final name = p.name.toLowerCase().trim();
            // Try to translate the ingredient name to English
            return _ingredientTranslations[name] ?? name;
          })
          .toList(),
      orElse: () => <String>[],
    );
    
    // Log the translated ingredients for debugging
    debugPrint('Translated ingredients: $ingredients');

    if (ingredients.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adicione produtos para receber sugestões de receitas'),
            backgroundColor: Color(0xFF128C7E), // WhatsApp green
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeSuggestionsScreen(
            userIngredients: ingredients,
          ),
        ),
      );
    }
  }
}
