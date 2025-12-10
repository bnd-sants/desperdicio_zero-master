import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // URLs e chaves para produção
  static const String _prodUrl = 'https://buuzrnplodxzzmcgstxw.supabase.co';
  static const String _prodAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1dXpybnBsb2R4enptY2dzdHh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzODk5ODEsImV4cCI6MjA3MTk2NTk4MX0.6ze2FEZ74cDKAbNFp7ra_lrkO4uIwZxwNBCPp42OVEE';

  // URLs de redirecionamento
  static const String _redirectUrl = 'com.example.desperdicio_zero://auth-callback';
  static const String _resetPasswordUrl = 'com.example.desperdicio_zero://reset-password';

  // Configuração para sempre usar produção
  static String get url => _prodUrl;
  static String get anonKey => _prodAnonKey;
  static String get redirectUrl => _redirectUrl;
  static String get resetPasswordUrl => _resetPasswordUrl;

  // Configurações de tempo limite (opcional)
  static const int authTimeout = 30; // segundos
  static const int refreshTokenThreshold = 60; // segundos
  static const String localStorageKey = 'supabase.auth.token';

  // Nomes das tabelas no Supabase (ajuste conforme sua estrutura)
  static const String usersTable = 'users';
  static const String profilesTable = 'profiles';

  // Configuração de debug
  static const bool debug = kDebugMode;
  
  // Método para inicializar o Supabase
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('🔵 Inicializando Supabase...');
        print('🔵 URL: $url');
        print('🔵 Modo debug: $debug');
      }
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: debug,
      );
      
      if (kDebugMode) {
        print('✅ Supabase inicializado com sucesso!');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Erro ao inicializar Supabase:');
        print('❌ $e');
        print('❌ $stackTrace');
      }
      rethrow;
    }
  }
}
