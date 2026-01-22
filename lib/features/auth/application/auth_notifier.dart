import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:desperdicio_zero/features/auth/domain/auth_state.dart' as app_auth;
import 'package:desperdicio_zero/services/auth_service_wrapper.dart';

// Alias for our app's AuthState
typedef AppAuthState = app_auth.AuthState;

class AuthNotifier extends Notifier<AppAuthState> {
  late final AuthService _authService;
  StreamSubscription<supabase.AuthState>? _authSubscription;
  bool _initialized = false;

  @override
  AppAuthState build() {
    _authService = ref.watch(authServiceProvider);

    _subscribeToAuthChanges();

    if (!_initialized) {
      _initialized = true;
      unawaited(Future.microtask(checkAuthStatus));
    }

    ref.onDispose(() => _authSubscription?.cancel());

    return const app_auth.AuthState.initial();
  }

  void _subscribeToAuthChanges() {
    if (_authSubscription != null) return;

    _authSubscription = _authService.onAuthStateChange.listen((authState) {
      // Ignora eventos sem sessão
      final event = authState.event;
      final session = authState.session;

      if (event == supabase.AuthChangeEvent.signedIn && session != null) {
        unawaited(_handleSignedIn(session.user.id));
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        state = const app_auth.AuthState.unauthenticated();
      } else if (event == supabase.AuthChangeEvent.passwordRecovery &&
          session?.user != null) {
        unawaited(_handleSignedIn(session!.user.id));
      }
    });
  }

  Future<void> _handleSignedIn(String userId) async {
    try {
      final userProfile = await _authService.getUserProfile(userId);
      if (!ref.mounted) return;
      state = app_auth.AuthState.authenticated(userProfile);
    } catch (_) {
      if (!ref.mounted) return;
      state = const app_auth.AuthState.error('Falha ao carregar perfil do usuário');
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      state = const app_auth.AuthState.loading();
      final currentUser = _authService.currentUser;

      if (currentUser != null) {
        await _handleSignedIn(currentUser.id);
      } else {
        if (!ref.mounted) return;
        state = const app_auth.AuthState.unauthenticated();
      }
    } catch (_) {
      if (!ref.mounted) return;
      state = const app_auth.AuthState.error('Erro ao verificar status de autenticação');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const app_auth.AuthState.loading();
      final response = await _authService.signIn(email, password);
      final user = response.user;

      if (user != null) {
        await _handleSignedIn(user.id);
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = app_auth.AuthState.error('Falha no login: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) =>
      signIn(email, password);

  Future<void> signUp(String email, String password, Map<String, dynamic> userData) async {
    try {
      state = const app_auth.AuthState.loading();
      await _authService.signUp(email, password, userData);
      // O listener onAuthStateChange irá atualizar o estado após a confirmação do email
    } on supabase.AuthException catch (e) {
      if (!ref.mounted) return;
      state = app_auth.AuthState.error(e.message);
    } catch (_) {
      if (!ref.mounted) return;
      state = const app_auth.AuthState.error('Erro desconhecido ao criar conta');
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    await signUp(email, password, {'full_name': name});
  }

  Future<void> signOut() async {
    try {
      state = const app_auth.AuthState.loading();
      await _authService.signOut();
      if (!ref.mounted) return;
      state = const app_auth.AuthState.unauthenticated();
    } catch (e) {
      if (!ref.mounted) return;
      state = app_auth.AuthState.error('Erro ao fazer logout: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    state = const app_auth.AuthState.loading();
    try {
      await _authService.resetPassword(email);
      if (!ref.mounted) return;
      state = const app_auth.AuthState.unauthenticated();
    } catch (e) {
      if (!ref.mounted) return;
      state = app_auth.AuthState.error('Falha ao redefinir senha: $e');
    }
  }
}
