import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/models/user_profile.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Perfil do usuário
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> createProfile(UserProfile profile) async {
    await _supabase.from('profiles').upsert(profile.toJson());
  }

  // Produtos
  Future<List<Map<String, dynamic>>> getUserProducts() async {
    final response = await _supabase
        .from('products')
        .select()
        .order('expiration_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> product) async {
    final response = await _supabase
        .from('products')
        .insert(product)
        .select()
        .single();
    return response;
  }

  // Receitas
  Future<List<Map<String, dynamic>>> getUserRecipes() async {
    final response = await _supabase
        .from('recipes')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Métodos adicionais para atualizar e excluir produtos/receitas podem ser adicionados aqui
}
