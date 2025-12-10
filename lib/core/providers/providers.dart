import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:desperdicio_zero/services/recipe_service.dart';

/// Provider for the Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for the current user
final currentUserProvider = Provider<User?>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.currentUser;
});

/// Provider for the current user's session
final sessionProvider = StreamProvider<AuthState>((ref) async* {
  final supabase = ref.watch(supabaseProvider);
  
  // Emit the current session if it exists
  final currentSession = supabase.auth.currentSession;
  if (currentSession != null) {
    yield Authenticated(currentSession.user);
  } else {
    yield Unauthenticated();
  }
  
  // Listen for auth state changes
  final authChanges = supabase.auth.onAuthStateChange;
  await for (final event in authChanges) {
    if (event.session?.user != null) {
      yield Authenticated(event.session!.user);
    } else {
      yield Unauthenticated();
    }
  }
});

/// Base auth state
sealed class AuthState {}

class Authenticated extends AuthState {
  final User user;
  final String? fullName;
  
  Authenticated(this.user, {this.fullName});
  
  String get displayName => fullName ?? user.email?.split('@')[0] ?? 'Usuário';
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  AuthError(this.message);
}

/// Provider for auth-related operations
final authProvider = Provider<AuthProvider>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthProvider(supabase);
});

class AuthProvider {
  final SupabaseClient _supabase;
  
  AuthProvider(this._supabase);
  
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthError(e.toString());
    }
  }
  
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      
      if (response.user == null) {
        throw AuthError('Falha ao criar conta');
      }
    } catch (e) {
      throw AuthError(e.toString());
    }
  }
  
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthError(e.toString());
    }
  }
}

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
