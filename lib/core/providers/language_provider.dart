import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final languageProvider = NotifierProvider<LanguageNotifier, Locale>(LanguageNotifier.new);

class LanguageNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    Future.microtask(_loadFromPreferences);
    return const Locale('pt', 'BR');
  }

  bool get isPortuguese => state.languageCode == 'pt';
  
  Future<void> _loadFromPreferences() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('user_preferences')
            .select('language')
            .eq('user_id', user.id)
            .maybeSingle();
        if (response != null && response['language'] != null) {
          final lang = response['language'] as String;
          if (lang.startsWith('en')) {
            state = const Locale('en', 'US');
          } else if (lang.startsWith('es')) {
            state = const Locale('es', 'ES');
          }
        }
      }
    } catch (_) {
      // Mantém locale padrão em caso de erro
    }
  }

  Future<void> setLanguage(String languageCode) async {
    Locale newLocale;
    switch (languageCode) {
      case 'en':
        newLocale = const Locale('en', 'US');
        break;
      case 'es':
        newLocale = const Locale('es', 'ES');
        break;
      case 'pt':
      default:
        newLocale = const Locale('pt', 'BR');
        break;
    }
    state = newLocale;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('user_preferences')
            .upsert({'user_id': user.id, 'language': languageCode});
      }
    } catch (_) {
      // Continua com o locale alterado mesmo se falhar ao salvar
    }
  }
}
