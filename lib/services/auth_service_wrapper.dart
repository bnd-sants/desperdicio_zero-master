import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/models/user_profile.dart';
import 'package:desperdicio_zero/utils/logger_util.dart' as logger;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final SupabaseClient supabaseClient;

  AuthService(this.supabaseClient);

  // Getter para acessar o cliente Supabase
  SupabaseClient get client => supabaseClient;

  // Método para fazer login
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      logger.logInfo('Tentando fazer login com email: $email');
      
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      logger.logInfo('Resposta do login: ${response.user?.email}');
      logger.logInfo('Sessão: ${response.session != null ? 'válida' : 'inválida'}');
      
      return response;
    } catch (e, stackTrace) {
      logger.logError('Erro durante o login: $e', e, stackTrace);
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
    try {
      final response = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromJson(response);
      }

      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null || currentUser.id != userId) {
        throw Exception('Perfil não encontrado para o usuário informado.');
      }

      final now = DateTime.now().toUtc();
      final generatedProfile = <String, dynamic>{
        'id': currentUser.id,
        'email': currentUser.email ?? '',
        'full_name': (currentUser.userMetadata?['full_name'] as String?) ??
            (currentUser.email?.split('@').first ?? 'Usuário'),
        'avatar_url': currentUser.userMetadata?['avatar_url'],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await supabaseClient.from('profiles').upsert(generatedProfile);

      return UserProfile.fromJson(generatedProfile);
    } catch (e, stackTrace) {
      logger.logError('Erro ao carregar perfil do usuário', e, stackTrace);
      rethrow;
    }
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
