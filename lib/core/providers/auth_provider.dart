import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/secure_storage.dart';
import 'supabase_provider.dart';

/// Auth state
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User user;
  final String? fullName;
  
  const Authenticated(this.user, {this.fullName});
  
  String get displayName => fullName ?? user.email?.split('@')[0] ?? 'Usuário';
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
}

/// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _supabase;
  final SecureStorage _secureStorage;
  
  AuthNotifier({
    required SupabaseClient supabase,
    SecureStorage? secureStorage,
  })  : _supabase = supabase,
        _secureStorage = secureStorage ?? SecureStorage.instance,
        super(const AuthInitial()) {
    _init();
  }
  
  Future<void> _init() async {
    // Try to restore session from secure storage
    try {
      state = const AuthLoading();
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        state = Authenticated(currentUser);
        return;
      }
      
      // Try to restore session from token
      final token = await _secureStorage.getAuthToken();
      if (token != null) {
        try {
          // Try to get the current session
          final session = _supabase.auth.currentSession;
          if (session != null) {
            state = Authenticated(session.user);
            return;
          }
        } catch (e) {
          // If there's an error checking the session, consider as unauthenticated
          state = const Unauthenticated();
        }
      }
      
      state = const Unauthenticated();
    } catch (e) {
      state = AuthError('Erro ao restaurar sessão: $e');
    }
  }
  
  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = const AuthLoading();
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Falha ao fazer login');
      }
      
      // Save tokens to secure storage
      await _secureStorage.saveAuthToken(response.session?.accessToken ?? '');
      await _secureStorage.saveRefreshToken(response.session?.refreshToken ?? '');
      
      state = Authenticated(response.user!);
    } catch (e) {
      state = AuthError('Erro ao fazer login: $e');
      rethrow;
    }
  }
  
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      state = const AuthLoading();
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      
      if (response.user == null) {
        throw Exception('Falha ao criar conta');
      }
      
      // Save tokens to secure storage
      await _secureStorage.saveAuthToken(response.session?.accessToken ?? '');
      await _secureStorage.saveRefreshToken(response.session?.refreshToken ?? '');
      
      state = Authenticated(response.user!);
    } catch (e) {
      state = AuthError('Erro ao criar conta: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      state = const AuthLoading();
      
      await _supabase.auth.signOut();
      await _secureStorage.clearAll();
      
      state = const Unauthenticated();
    } catch (e) {
      state = AuthError('Erro ao sair: $e');
      rethrow;
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      state = const AuthLoading();
      await _supabase.auth.resetPasswordForEmail(email);
      state = const Unauthenticated();
    } catch (e) {
      state = AuthError('Erro ao redefinir senha: $e');
      rethrow;
    }
  }
}

/// Provider for the auth notifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthNotifier(supabase: supabase);
});

/// Provider for the current user
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authNotifierProvider);
  return state is Authenticated ? state.user : null;
});

/// Provider for checking if the user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final state = ref.watch(authNotifierProvider);
  return state is Authenticated;
});
