import 'dart:io';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/user_profile.dart';
import 'package:gotrue/gotrue.dart' as gotrue;

import '../config/supabase_config.dart';
import '../utils/logger_util.dart';

/// Interface que define o contrato para o serviço de autenticação
abstract class IAuthService {
  // Getters
  GoTrueClient get auth;
  SupabaseClient get client;
  User? get currentUser;
  bool get isLoggedIn;
  
  // Streams
  Stream<AuthState> get onAuthStateChange;
  
  // Authentication methods
  Future<void> initialize();
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String newPassword);
  Future<UserProfile?> getCurrentUserProfile();
  Future<UserProfile> updateProfile({String? fullName, String? avatarUrl});
  Future<String?> uploadAvatar(String filePath);
}

class AuthService implements IAuthService {
  final _supabase = Supabase.instance.client;
  final _authStateController = StreamController<AuthState>.broadcast();
  
  // Stream de mudanças de estado de autenticação para o Riverpod
  Stream<User?> get authStateChanges => _supabase.auth.onAuthStateChange
      .map((authState) => authState.session?.user);
  
  @override
  GoTrueClient get auth => _supabase.auth;
  
  @override
  SupabaseClient get client => _supabase;
  
  @override
  User? get currentUser => _supabase.auth.currentUser;
  
  @override
  bool get isLoggedIn => _supabase.auth.currentUser != null;
  
  @override
  Stream<AuthState> get onAuthStateChange => _authStateController.stream;

  @override
  Future<void> initialize() async {
    try {
      // Configura o listener de mudanças de estado de autenticação
      _supabase.auth.onAuthStateChange.listen((data) {
        logDebug('Auth state changed: ${data.event}');
        _authStateController.add(data);
      });
      logInfo('AuthService inicializado com sucesso');
    } catch (e, stackTrace) {
      logError('Erro ao inicializar AuthService', e, stackTrace);
      rethrow;
    }
  }
  
  // Get user profile data by user ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response as Map<String, dynamic>?;
    } catch (e, stackTrace) {
      logError('Erro ao buscar perfil do usuário', e, stackTrace);
      return null;
    }
  }
  
  // Método estático para criar uma instância do AuthService
  // Útil para injeção de dependência com Riverpod
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  
  // Factory constructor to return the same instance
  factory AuthService() => _instance;
  
  // Internal constructor
  AuthService._internal();

  // Provider for Riverpod
  static final provider = Provider<AuthService>((ref) {
    final authService = _instance;
    // Inicializa o serviço quando o provider for criado
    authService.initialize();
    return authService;
  });
  
  // Getter for the singleton instance
  static AuthService get instance => _instance;

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      logError('Erro ao buscar perfil do usuário', e);
      return null;
    }
  }

  /// Tratamento de erros de autenticação
  /// Retorna uma mensagem de erro amigável para o usuário
  String _handleAuthError(gotrue.AuthException e) {
    logWarning('Erro de autenticação: ${e.message}');
    
    switch (e.message) {
      case 'Invalid login credentials':
        return 'E-mail ou senha inválidos';
      case 'Email not confirmed':
        return 'Por favor, verifique seu e-mail para confirmar sua conta';
      case 'User already registered':
        return 'Este e-mail já está cadastrado';
      case 'Email rate limit exceeded':
        return 'Muitas tentativas. Tente novamente mais tarde';
      default:
        LoggerUtil.logger.severe('Erro de autenticação não tratado', e);
        return 'Erro na autenticação: ${e.message}';
    }
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      LoggerUtil.logger.fine('Tentando login com e-mail: $email');
      
      // Primeiro tenta fazer login normalmente
      try {
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        LoggerUtil.logger.info('Login realizado com sucesso para: $email');
        return response;
      } on gotrue.AuthException catch (e) {
        // Se o erro for de e-mail não verificado, tenta confirmar o e-mail automaticamente
        if (e.message.contains('Email not confirmed')) {
          LoggerUtil.logger.info('E-mail não verificado, reenviando confirmação para: $email');
          // Envia novamente o e-mail de confirmação
          await _supabase.auth.resend(
            type: OtpType.signup,
            email: email,
            emailRedirectTo: SupabaseConfig.redirectUrl,
          );
          
          // Tenta fazer login novamente
          final response = await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          LoggerUtil.logger.info('Login realizado com sucesso após reenvio de confirmação');
          return response;
        }
        throw _handleAuthError(e);
      }
    } on gotrue.AuthException catch (e) {
      LoggerUtil.logger.severe('Erro de autenticação', e);
      throw _handleAuthError(e);
    } catch (e, stackTrace) {
      LoggerUtil.logger.severe('Erro inesperado durante o login', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    LoggerUtil.logger.fine('Iniciando cadastro para: $email');
    
    try {
      // Validação básica dos dados
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Por favor, insira um e-mail válido');
      }
      
      if (password.length < 6) {
        throw Exception('A senha deve ter pelo menos 6 caracteres');
      }
      
      if (name.isEmpty) {
        throw Exception('Por favor, insira seu nome');
      }
      
      LoggerUtil.logger.fine('Criando usuário no sistema de autenticação');
      
      // Usa a URL de redirecionamento do SupabaseConfig
      final redirectUrl = SupabaseConfig.redirectUrl;
      LoggerUtil.logger.fine('URL de redirecionamento: $redirectUrl');
      
      // First, sign up the user
      final signUpResponse = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim()},
        emailRedirectTo: redirectUrl,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Tempo limite excedido ao tentar se conectar ao servidor');
        },
      );

      if (signUpResponse.user == null) {
        LoggerUtil.logger.severe('Falha ao criar usuário: resposta sem usuário');
        throw Exception('Não foi possível criar sua conta. Tente novamente.');
      }
      
      // Log do status de confirmação de e-mail
      if (signUpResponse.session != null) {
        LoggerUtil.logger.info('Usuário criado e logado automaticamente (e-mail verificado)');
      } else {
        LoggerUtil.logger.info('E-mail de confirmação enviado para: $email');
      }

      LoggerUtil.logger.info('Usuário criado com sucesso - ID: ${signUpResponse.user!.id} - Email: $email');
      LoggerUtil.logger.info('Por favor, verifique seu e-mail para confirmar sua conta.');
      
      // Não é necessário chamar refreshSession() aqui, pois o e-mail ainda não foi confirmado
      // O usuário precisará confirmar o e-mail antes de fazer login
      
      return signUpResponse;
      
    } on SocketException catch (e) {
      LoggerUtil.logger.severe('Erro de conexão', e);
      throw Exception('Sem conexão com a internet. Verifique sua conexão e tente novamente.');
    } on TimeoutException catch (e) {
      LoggerUtil.logger.severe('Tempo limite excedido', e);
      throw Exception('Tempo limite excedido. Por favor, verifique sua conexão e tente novamente.');
    } on gotrue.AuthException catch (e) {
      LoggerUtil.logger.severe('Erro de autenticação', e);
      final errorMessage = _handleAuthError(e);
      LoggerUtil.logger.severe('Detalhes do erro', e);
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      LoggerUtil.logger.severe('Erro inesperado durante o cadastro', e, stackTrace);
      throw Exception('Ocorreu um erro inesperado. Por favor, tente novamente mais tarde.');
    }
  }

  @override
  /// Faz logout do usuário atual
  Future<void> signOut() async {
    try {
      LoggerUtil.logger.fine('Efetuando logout do usuário');
      await _supabase.auth.signOut();
      // Create a new AuthState with signedOut event
      _authStateController.add(const AuthState(
        AuthChangeEvent.signedOut,
        null,
      ));
      LoggerUtil.logger.info('Logout realizado com sucesso');
    } catch (e, stackTrace) {
      LoggerUtil.logger.severe('Erro ao fazer logout', e, stackTrace);
      rethrow;
    }
  }

  @override
  /// Solicita redefinição de senha para o e-mail informado
  Future<void> resetPassword(String email) async {
    try {
      LoggerUtil.logger.fine('Solicitando redefinição de senha para: $email');
      
      // Usa a URL de redirecionamento do SupabaseConfig
      final redirectTo = SupabaseConfig.resetPasswordUrl;
      
      // Verifica se o e-mail é válido
      if (email.trim().isEmpty) {
        throw Exception('Por favor, informe um e-mail válido');
      }
      
      LoggerUtil.logger.fine('Enviando e-mail de redefinição para: $email');
      LoggerUtil.logger.fine('URL de redirecionamento: $redirectTo');
      
      // Envia o e-mail de redefinição
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo,
      );
      
      LoggerUtil.logger.info('E-mail de redefinição de senha enviado para: $email');
      LoggerUtil.logger.fine('Redirecionamento configurado para: $redirectTo');
    } on gotrue.AuthException catch (e) {
      LoggerUtil.logger.severe('Erro de autenticação ao redefinir senha', e);
      // Não revelamos se o e-mail existe ou não por questões de segurança
      LoggerUtil.logger.info('Erro ao processar solicitação para o e-mail: $email');
      // Relança a exceção para ser tratada pela UI
      rethrow;
    } catch (e, stackTrace) {
      LoggerUtil.logger.severe('Erro ao solicitar redefinição de senha', e, stackTrace);
      rethrow;
    }
  }

  @override
  /// Atualiza a senha do usuário atual
  Future<void> updatePassword(String newPassword) async {
    try {
      LoggerUtil.logger.fine('Atualizando senha do usuário');
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      LoggerUtil.logger.info('Senha atualizada com sucesso');
    } on gotrue.AuthException catch (e) {
      LoggerUtil.logger.severe('Erro de autenticação ao atualizar senha', e);
      throw _handleAuthError(e);
    } catch (e, stackTrace) {
      LoggerUtil.logger.severe('Erro ao atualizar senha', e, stackTrace);
      rethrow;
    }
  }


  @override
  /// Atualiza o perfil do usuário com os dados fornecidos
  /// Retorna o perfil atualizado em caso de sucesso
  /// Lança uma exceção em caso de erro
  Future<UserProfile> updateProfile({String? fullName, String? avatarUrl}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final updates = <String, dynamic>{
        'id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) {
        updates['full_name'] = fullName.trim();
        // Update the user's metadata in auth.users
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {'full_name': fullName.trim()},
          ),
        );
      }
      
      if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
      }

      // If there's nothing to update, return the current profile
      if (updates.length <= 2) {
        final currentProfile = await getCurrentUserProfile();
        if (currentProfile == null) {
          throw Exception('Perfil não encontrado');
        }
        return currentProfile;
      }

      // Update the profiles table and get the updated profile
      final updatedProfile = await _supabase
          .from('profiles')
          .upsert(updates)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));

      return UserProfile.fromJson({
        ...updatedProfile,
        'email': user.email,
      });
    } catch (e, stackTrace) {
      LoggerUtil.logger.severe('Falha ao atualizar perfil', e, stackTrace);
      throw Exception('Falha ao atualizar perfil: $e');
    }
  }

  @override
  /// Faz upload de uma imagem de avatar para o storage
  Future<String?> uploadAvatar(String filePath) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado: $filePath');
      }
      
      final fileExt = filePath.split('.').last.toLowerCase();
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = 'avatars/$fileName';
      
      LoggerUtil.logger.fine('Iniciando upload do avatar para: $storagePath');
      
      // Upload the file to storage
      await _supabase.storage
          .from('avatars')
          .upload(
            storagePath, 
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Get the public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(storagePath);
      
      LoggerUtil.logger.fine('Avatar enviado com sucesso. URL: $publicUrl');
      
      // Update the user's profile with the new avatar URL
      await updateProfile(avatarUrl: publicUrl);
      
      return publicUrl;
    } catch (e, stackTrace) {
      LoggerUtil.logger.severe('Erro ao fazer upload do avatar', e, stackTrace);
      rethrow;
    }
  }
}