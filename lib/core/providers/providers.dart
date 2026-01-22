import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:desperdicio_zero/services/recipe_service.dart';
import 'package:desperdicio_zero/core/providers/auth/auth_provider.dart'
    as feature_auth_provider;

/// Provider for the Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for the current user
final currentUserProvider = feature_auth_provider.currentUserProvider;

/// Provider para o estado de autenticação utilizando a nova feature
final authNotifierProvider = feature_auth_provider.authNotifierProvider;

// Theme provider is now in theme/theme_provider.dart
/// Provider for product-related operations
final productProvider = Provider<ProductProvider>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ProductProvider(supabase);
});

class ProductProvider {
  final SupabaseClient _supabase;
  
  ProductProvider(this._supabase);
  
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    try {
      await _supabase.from('products').insert(product);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> product) async {
    try {
      await _supabase.from('products').update(product).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}

/// Provider for Spoonacular API operations
final spoonacularProvider = Provider<SpoonacularProvider>((ref) {
  return SpoonacularProvider();
});

/// Provider for recipe-related operations
final recipeServiceProvider = Provider<RecipeService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return RecipeService(supabase);
});

class SpoonacularProvider {
  final String _apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.spoonacular.com/recipes';

  Future<List<Map<String, dynamic>>> searchRecipesByIngredients(List<String> ingredients) async {
    if (_apiKey.isEmpty) {
      throw Exception('Spoonacular API key is not set.');
    }

    final ingredientsString = ingredients.join(',');
    final url = Uri.parse('$_baseUrl/findByIngredients?ingredients=$ingredientsString&number=10&apiKey=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((recipe) => recipe as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load recipes: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load recipes: $e');
    }
  }
}
