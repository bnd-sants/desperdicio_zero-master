import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:desperdicio_zero/features/auth/domain/auth_state.dart' as app_auth;
import 'package:desperdicio_zero/services/auth_service_wrapper.dart';

// Alias for our app's AuthState
typedef AppAuthState = app_auth.AuthState;

class AuthNotifier extends StateNotifier<AppAuthState> {
  final AuthService _authService;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  AuthNotifier(this._authService, Ref _) : super(const app_auth.AuthState.initial()) {
    // Inicializa o listener de mudança de estado de autenticação
    _authSubscription = _authService.onAuthStateChange.listen((authState) async {
      final event = authState.event;
      final session = authState.session;

      if (event == supabase.AuthChangeEvent.signedIn && session != null) {
        try {
          final userProfile = await _authService.getUserProfile(session.user.id);
          state = app_auth.AuthState.authenticated(userProfile);
        } catch (e) {
state = const app_auth.AuthState.error('Falha ao carregar perfil do usuário');
        }
} else if (event == supabase.AuthChangeEvent.signedOut) {
        state = const app_auth.AuthState.unauthenticated();
} else if (event == supabase.AuthChangeEvent.passwordRecovery) {
        // Lógica para recuperação de senha
      }
    });
  }

  Future<void> checkAuthStatus() async {
    try {
      state = const app_auth.AuthState.loading();
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        final userProfile = await _authService.getUserProfile(currentUser.id);
        state = app_auth.AuthState.authenticated(userProfile);
      } else {
        state = const app_auth.AuthState.unauthenticated();
      }
    } catch (e) {
      state = const app_auth.AuthState.error('Erro ao verificar status de autenticação');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const app_auth.AuthState.loading();
      final response = await _authService.signIn(email, password);
      if (response.user != null) {
        final userProfile = await _authService.getUserProfile(response.user!.id);
        state = app_auth.AuthState.authenticated(userProfile);
      }
    } catch (e) {
      state = app_auth.AuthState.error('Falha no login: $e');
    } 
  }

  Future<void> signUp(String email, String password, Map<String, dynamic> userData) async {
    try {
      state = const app_auth.AuthState.loading();
      await _authService.signUp(email, password, userData);
      // O listener onAuthStateChange irá atualizar o estado após a confirmação do email
} on supabase.AuthException catch (e) {
      state = app_auth.AuthState.error(e.message);
    } catch (e) {
      state = const app_auth.AuthState.error('Erro desconhecido ao criar conta');
    }
  }

  Future<void> signOut() async {
    try {
      state = const app_auth.AuthState.loading();
      await _authService.signOut();
      // O listener onAuthStateChange irá atualizar o estado para unauthenticated
    } catch (e) {
      state = app_auth.AuthState.error('Erro ao fazer logout: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    state = const app_auth.AuthState.loading();
    try {
      await _authService.resetPassword(email);
      state = const app_auth.AuthState.unauthenticated();
    } catch (e) {
      state = app_auth.AuthState.error('Falha ao redefinir senha: $e');
    }
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
