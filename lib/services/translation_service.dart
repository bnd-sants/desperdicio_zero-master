import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranslationService {
  static const Map<String, String> _ingredientTranslations = {
    'arroz': 'rice',
    'feijão': 'beans',
    'feijao': 'beans',
    'frango': 'chicken',
    'carne': 'beef',
    'batata': 'potato',
    'cenoura': 'carrot',
    'cebola': 'onion',
    'alho': 'garlic',
    'ovo': 'egg',
    'ovos': 'eggs',
    'leite': 'milk',
    'pão': 'bread',
    'pao': 'bread',
    'queijo': 'cheese',
    'tomate': 'tomato',
    'alface': 'lettuce',
    'pepino': 'cucumber',
    'pimentão': 'bell pepper',
    'pimentao': 'bell pepper',
    'macarrão': 'pasta',
    'macarrao': 'pasta',
    'peixe': 'fish',
    'camarão': 'shrimp',
    'camarao': 'shrimp',
    'fruta': 'fruit',
    'maçã': 'apple',
    'maca': 'apple',
    'banana': 'banana',
    'laranja': 'orange',
    'limão': 'lemon',
    'limao': 'lemon',
    'batata doce': 'sweet potato',
    'batata-doce': 'sweet potato',
    'batata inglesa': 'potato',
    'batata-inglesa': 'potato',
    'cebolinha': 'green onion',
    'salsinha': 'parsley',
    'coentro': 'cilantro',
    'manjericão': 'basil',
    'manjericao': 'basil',
    'orégano': 'oregano',
    'oregano': 'oregano',
    'azeite': 'olive oil',
    'óleo': 'oil',
    'oleo': 'oil',
    'manteiga': 'butter',
    'açúcar': 'sugar',
    'acucar': 'sugar',
    'sal': 'salt',
    'pimenta': 'pepper',
    'farinha': 'flour',
    'farinha de trigo': 'wheat flour',
    'açúcar mascavo': 'brown sugar',
    'acucar mascavo': 'brown sugar',
    'canela': 'cinnamon',
    'chocolate': 'chocolate',
    'café': 'coffee',
    'cafe': 'coffee',
    'chá': 'tea',
    'cha': 'tea',
  };

  // Translate ingredient to English for API calls
  static String translateIngredientToEnglish(String ingredient) {
    return _ingredientTranslations[ingredient.toLowerCase()] ?? ingredient;
  }

  // Cache para armazenar traduções já realizadas
  static final Map<String, Map<String, String>> _translationCache = {};
  static const int _maxRetries = 3;
  static const Duration _timeoutDuration = Duration(seconds: 10);
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Traduz um texto usando a API do Spoonacular com tratamento de erros robusto
  /// 
  /// Parâmetros:
  /// - [text]: O texto a ser traduzido
  /// - [from]: Código do idioma de origem (padrão: 'en')
  /// - [to]: Código do idioma de destino (padrão: 'pt')
  /// - [maxLength]: Tamanho máximo do texto a ser traduzido (evita erros de tamanho)
  /// 
  /// Retorna:
  /// - O texto traduzido em caso de sucesso
  /// - O texto original em caso de falha após todas as tentativas
  static Future<String> translateText(
    String text, {
    String from = 'en',
    String to = 'pt',
    int maxLength = 500,
  }) async {
    // Validação de entrada
    if (text.isEmpty || text.trim().isEmpty) {
      debugPrint('TranslationService: Texto vazio fornecido para tradução');
      return text;
    }

    // Verifica o cache primeiro
    final cacheKey = '${from}_$to';
    final cachedTranslation = _translationCache[cacheKey]?[text];
    if (cachedTranslation != null) {
      return cachedTranslation;
    }

    // Limita o tamanho do texto para evitar erros
    final truncatedText = text.length > maxLength 
        ? '${text.substring(0, maxLength)}...' 
        : text;

    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('❌ TranslationService: Chave da API não configurada');
      return truncatedText;
    }

    int attempt = 0;
    Exception? lastError;
    StackTrace? stackTrace;

    while (attempt < _maxRetries) {
      attempt++;
      
      try {
        final url = Uri.parse('https://api.spoonacular.com/food/translate?apiKey=$apiKey');
        
        debugPrint('🔄 Attempt $attempt: Traduzindo "${truncatedText.replaceAll('\n', ' ')}" de $from para $to');
        
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'text': truncatedText,
            'sourceLang': from,
            'targetLang': to,
          }),
        ).timeout(_timeoutDuration);

        // Log detalhado da resposta
        debugPrint('📥 Status Code: ${response.statusCode}');
        debugPrint('📦 Response Body: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            final translatedText = data['translatedText'] as String? ?? truncatedText;
            
            // Atualiza o cache
            _translationCache.putIfAbsent(cacheKey, () => {})[text] = translatedText;
            
            debugPrint('✅ Tradução bem-sucedida: "$truncatedText" → "$translatedText"');
            return translatedText;
          } catch (e, st) {
            debugPrint('❌ Erro ao decodificar resposta: $e');
            debugPrint('📋 Stack trace: $st');
            lastError = e as Exception? ?? Exception('Erro desconhecido ao decodificar resposta');
            stackTrace = st;
          }
        } else if (response.statusCode == 401) {
          debugPrint('❌ Erro de autenticação: Verifique sua chave da API do Spoonacular');
          return truncatedText; // Não tente novamente para erros de autenticação
        } else if (response.statusCode == 429) {
          final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 5;
          debugPrint('⚠️ Rate limit atingido. Tentando novamente em ${retryAfter}s...');
          await Future.delayed(Duration(seconds: retryAfter));
          continue; // Tenta novamente após o atraso
        } else {
          debugPrint('❌ Erro na API (${response.statusCode}): ${response.body}');
          lastError = Exception('API retornou status ${response.statusCode}');
        }
      } on FormatException catch (e, st) {
        debugPrint('❌ Formato de resposta inválido: $e');
        lastError = e;
        stackTrace = st;
      } on http.ClientException catch (e, st) {
        debugPrint('❌ Erro de conexão: ${e.message}');
        lastError = e;
        stackTrace = st;
      } on Exception catch (e, st) {
        // Captura qualquer outra exceção, incluindo TimeoutException
        if (e.toString().contains('TimeoutException')) {
          debugPrint('⏱️ Timeout ao tentar traduzir: $e');
        } else {
          debugPrint('❌ Erro inesperado: $e');
        }
        lastError = e;
        stackTrace = st;
      } catch (e, st) {
        debugPrint('❌ Erro crítico inesperado: $e');
        lastError = Exception('Erro crítico inesperado: $e');
        stackTrace = st;
      }

      // Aguarda antes de tentar novamente
      if (attempt < _maxRetries) {
        final delay = Duration(seconds: _retryDelay.inSeconds * attempt);
        debugPrint('⏳ Tentando novamente em ${delay.inSeconds}s... (tentativa $attempt de $_maxRetries)');
        await Future.delayed(delay);
      }
    }

    // Se chegou aqui, todas as tentativas falharam
    debugPrint('❌ Falha ao traduzir após $_maxRetries tentativas. Último erro: $lastError');
    if (lastError != null && stackTrace != null) {
      // Aqui você pode adicionar um serviço de rastreamento de erros como Sentry ou Firebase Crashlytics
      // Exemplo: await Sentry.captureException(lastError, stackTrace: stackTrace);
    }
    
    return truncatedText; // Retorna o texto original em caso de falha
  }
}

// Language provider for the app
class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('pt', 'BR');
  
  Locale get locale => _locale;
  bool get isPortuguese => _locale.languageCode == 'pt';
  
  void toggleLanguage() {
    _locale = _locale.languageCode == 'pt' 
        ? const Locale('en', 'US') 
        : const Locale('pt', 'BR');
    notifyListeners();
  }
  
  void setLanguage(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
