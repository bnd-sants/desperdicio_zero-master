import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get redirectUrl => dotenv.env['SUPABASE_REDIRECT_URL'] ?? 'com.example.desperdicio_zero://auth-callback';
  static String get resetPasswordUrl => dotenv.env['SUPABASE_RESET_PASSWORD_URL'] ?? 'com.example.desperdicio_zero://reset-password';

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
      if (url.isEmpty || anonKey.isEmpty) {
        throw Exception('Supabase environment variables are missing');
      }
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
