import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/models/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class AuthService {
  final SupabaseClient supabaseClient;

  AuthService(this.supabaseClient);

  // Getter para acessar o cliente Supabase
  SupabaseClient get client => supabaseClient;

  // Método para fazer login
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      print('Tentando fazer login com email: $email');
      
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('Resposta do login: ${response.user?.email}');
      print('Sessão: ${response.session != null ? 'válida' : 'inválida'}');
      
      return response;
    } catch (e, stackTrace) {
      print('Erro durante o login: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Método para registrar um novo usuário
  Future<AuthResponse> signUp(String email, String password, Map<String, dynamic> userData) async {
    final response = await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );

    if (response.user != null) {
      await supabaseClient
          .from('profiles')
          .upsert({
            'id': response.user!.id,
            'email': email,
            ...userData,
          });
    }

    return response;
  }

  // Método para obter o perfil do usuário
  Future<UserProfile> getUserProfile(String userId) async {
    final response = await supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserProfile.fromJson(response);
  }

  // Método para fazer logout
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  // Método para redefinir senha
  Future<void> resetPassword(String email) async {
    await supabaseClient.auth.resetPasswordForEmail(email);
  }

  // Getter para o usuário atual
  User? get currentUser => supabaseClient.auth.currentUser;

  // Stream de autenticação
  Stream<AuthState> get onAuthStateChange => supabaseClient.auth.onAuthStateChange;
}

// Provider para o serviço de autenticação
final authServiceProvider = Provider<AuthService>((ref) {
  final supabase = Supabase.instance.client;
  return AuthService(supabase);
});
