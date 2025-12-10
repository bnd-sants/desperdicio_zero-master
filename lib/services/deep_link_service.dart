import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/utils/logger_util.dart' show LoggerUtil;

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final StreamController<Uri> _linkStreamController = StreamController<Uri>.broadcast();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// Inicializa o serviço de deep linking
  Future<void> initialize() async {
    _appLinks = AppLinks();
    
    // Configura o gerenciador de links do Supabase
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      
      LoggerUtil.logger.info('Auth state changed: $event');
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        LoggerUtil.logger.info('Usuário autenticado via deep link');
        // Navega para a tela inicial após o login bem-sucedido
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      } else if (event == AuthChangeEvent.signedOut) {
        LoggerUtil.logger.info('Usuário deslogado');
        // Navega para a tela de login após o logout
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } else if (event == AuthChangeEvent.passwordRecovery) {
        LoggerUtil.logger.info('Recuperação de senha solicitada');
      } else if (event == AuthChangeEvent.userUpdated) {
        LoggerUtil.logger.info('Usuário atualizado');
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        LoggerUtil.logger.info('Token atualizado');
      }
    });

    // Configura o listener para links profundos
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      LoggerUtil.logger.info('Link recebido: $uri');
      _linkStreamController.add(uri);
      await handleDeepLink(uri);
    });

    // Verifica se o app foi aberto por um link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        LoggerUtil.logger.info('App aberto por link: $initialUri');
        _linkStreamController.add(initialUri);
        await handleDeepLink(initialUri);
      } else {
        // Se não houver link inicial, verifica se há uma sessão ativa
        final currentSession = _supabase.auth.currentSession;
        if (currentSession != null) {
          // Atualiza a sessão para garantir que ainda é válida
          try {
            await _supabase.auth.refreshSession();
            LoggerUtil.logger.info('Sessão atualizada com sucesso');
          } catch (e) {
            LoggerUtil.logger.warning('Erro ao atualizar sessão', e);
            await _supabase.auth.signOut();
          }
        }
      }
    } catch (e) {
      LoggerUtil.logger.severe('Erro ao obter link inicial', e);
    }
  }

  /// Retorna um stream de links recebidos
  Stream<Uri> get linkStream => _linkStreamController.stream;

  /// Adiciona um link ao stream
  void addLink(Uri uri) {
    if (!_linkStreamController.isClosed) {
      _linkStreamController.add(uri);
      handleDeepLink(uri);
    }
  }

  /// Processa um deep link recebido
  Future<void> handleDeepLink(Uri? uri) async {
    if (uri == null) {
      LoggerUtil.logger.warning('URI nula recebida no handleDeepLink');
      return;
    }
    
    LoggerUtil.logger.info('Processando deep link: $uri');
    LoggerUtil.logger.info('Esquema: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
    
    // Verifica se é um link do Supabase
    final isSupabaseLink = 
        uri.host.endsWith('.supabase.co') ||
        uri.scheme == 'com.example.desperdicio_zero' ||
        uri.host == 'auth-callback' ||
        uri.host == 'reset-password' ||
        uri.host == 'confirm-email';
    
    if (!isSupabaseLink) {
      LoggerUtil.logger.info('Link não é do Supabase, ignorando');
      return;
    }
    
    // Verifica se é um link de redefinição de senha
    final isResetPasswordLink = 
        uri.host == 'reset-password' || 
        uri.host == 'recover' ||
        uri.path.contains('reset-password') ||
        uri.path.contains('recover') ||
        uri.path.contains('auth/v1/verify') ||
        (uri.queryParameters['type']?.toLowerCase() == 'recovery');
    
    // Verifica se é um link de confirmação de e-mail
    bool isEmailConfirmationLink = 
        uri.host == 'confirm-email' ||
        uri.host == 'login-callback' ||
        uri.path.contains('auth/v1/verify') ||
        (uri.queryParameters['type']?.toLowerCase() == 'signup') ||
        (uri.queryParameters['type']?.toLowerCase() == 'email_change');
    
    LoggerUtil.logger.info('Tipo de link detectado - Reset: $isResetPasswordLink, Confirmação: $isEmailConfirmationLink');
    
    // Se for um link de confirmação de e-mail ou redefinição de senha
    if (isResetPasswordLink || isEmailConfirmationLink) {
      await _handleAuthDeepLink(uri, isEmailConfirmationLink);
    }
  }

  /// Processa links de autenticação (confirmação de e-mail e redefinição de senha)
  Future<void> _handleAuthDeepLink(Uri uri, bool isEmailConfirmationLink) async {
    LoggerUtil.logger.info('Processando link de ${isEmailConfirmationLink ? 'confirmação de e-mail' : 'redefinição de senha'}: $uri');
    
    try {
      // Tenta extrair o token do fragmento primeiro
      String? accessToken;
      String? tokenType;
      
      // Verifica se há fragmento na URL
      if (uri.fragment.isNotEmpty) {
        final params = Uri.splitQueryString(uri.fragment);
        accessToken = params['access_token'] ?? params['token'];
        tokenType = params['token_type'] ?? params['type'];
        LoggerUtil.logger.info('Parâmetros extraídos do fragmento - Token: ${accessToken != null ? 'presente' : 'ausente'}, Tipo: $tokenType');
      }
      
      // Se não encontrou no fragmento, tenta nos parâmetros de consulta
      if (accessToken == null) {
        accessToken = uri.queryParameters['access_token'] ?? uri.queryParameters['token'];
        tokenType = uri.queryParameters['token_type'] ?? uri.queryParameters['type'];
        LoggerUtil.logger.info('Parâmetros extraídos da query - Token: ${accessToken != null ? 'presente' : 'ausente'}, Tipo: $tokenType');
      }
      
      if (accessToken != null && tokenType != null) {
        await _processAuthToken(accessToken, tokenType, isEmailConfirmationLink);
      } else {
        // Se não encontrou token, tenta atualizar a sessão
        await _refreshSessionAndNavigate(isEmailConfirmationLink);
      }
    } catch (error, stackTrace) {
      LoggerUtil.logger.severe('Erro ao processar link de autenticação', error, stackTrace);
      _showErrorSnackBar('Erro ao processar o link. Por favor, tente novamente.');
    }
  }

  /// Processa o token de autenticação
  Future<void> _processAuthToken(
    String accessToken, 
    String tokenType, 
    bool isEmailConfirmationLink
  ) async {
    try {
      LoggerUtil.logger.info('Configurando sessão com token: ${accessToken.substring(0, 10)}...');
      
      // Configura a sessão com o token
      await _supabase.auth.setSession(accessToken);
      LoggerUtil.logger.info('Sessão atualizada com sucesso via deep link');
      
      // Navega para a tela apropriada
      await _navigateAfterAuth(isEmailConfirmationLink);
      
      // Mostra mensagem de sucesso
      if (isEmailConfirmationLink) {
        _showSuccessSnackBar('E-mail confirmado com sucesso!');
      }
    } catch (error, stackTrace) {
      LoggerUtil.logger.severe('Erro ao configurar sessão', error, stackTrace);
      _showErrorSnackBar('Falha ao processar o link. Por favor, tente novamente.');
    }
  }

  /// Atualiza a sessão e navega para a tela apropriada
  Future<void> _refreshSessionAndNavigate(bool isEmailConfirmationLink) async {
    try {
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        await _supabase.auth.refreshSession();
        LoggerUtil.logger.info('Sessão atualizada com sucesso');
        await _navigateAfterAuth(isEmailConfirmationLink);
      } else {
        LoggerUtil.logger.warning('Nenhuma sessão ativa encontrada');
        _navigateToLogin();
      }
    } catch (error, stackTrace) {
      LoggerUtil.logger.severe('Erro ao atualizar sessão', error, stackTrace);
      _navigateToLogin();
    }
  }

  /// Navega para a tela apropriada após a autenticação
  Future<void> _navigateAfterAuth(bool isEmailConfirmationLink) async {
    if (navigatorKey.currentState == null) {
      LoggerUtil.logger.warning('navigatorKey.currentState é nulo');
      return;
    }

    // Pequeno delay para garantir que a navegação seja processada corretamente
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (isEmailConfirmationLink) {
      navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    } else {
      navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/reset-password',
        (route) => false,
      );
    }
  }

  /// Navega para a tela de login
  void _navigateToLogin() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  /// Exibe uma mensagem de sucesso em um SnackBar
  void _showSuccessSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      LoggerUtil.logger.warning('Não foi possível exibir a mensagem de sucesso: contexto nulo ou não montado');
    }
  }

  /// Exibe uma mensagem de erro em um SnackBar
  void _showErrorSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      LoggerUtil.logger.warning('Não foi possível exibir a mensagem de erro: contexto nulo ou não montado');
    }
  }

  /// Libera recursos
  void dispose() {
    _linkSubscription?.cancel();
    _linkStreamController.close();
  }
}
