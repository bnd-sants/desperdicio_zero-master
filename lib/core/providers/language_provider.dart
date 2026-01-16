import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final languageProvider = ChangeNotifierProvider<LanguageProvider>((ref) {
  return LanguageProvider();
});

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('pt', 'BR');
  LanguageProvider() {
    Future.microtask(_loadFromPreferences);
  }
  
  Locale get locale => _locale;
  bool get isPortuguese => _locale.languageCode == 'pt';
  
  Future<void> _loadFromPreferences() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final remote = await supabase
            .from('user_preferences')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        if (remote != null) {
          final lang = remote['language'] as String?;
          if (lang != null && lang.isNotEmpty) {
            if (lang.toLowerCase().startsWith('pt')) {
              _locale = const Locale('pt', 'BR');
            } else if (lang.toLowerCase().startsWith('en')) {
              _locale = const Locale('en', 'US');
            }
            notifyListeners();
          }
        }
      }
    } catch (_) {}
  }
  
  void toggleLanguage() {
    _locale = _locale.languageCode == 'pt' 
        ? const Locale('en', 'US') 
        : const Locale('pt', 'BR');
    _persist();
    notifyListeners();
  }
  
  void setLanguage(Locale locale) {
    _locale = locale;
    _persist();
    notifyListeners();
  }
  
  Future<void> _persist() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final code = _locale.languageCode.toLowerCase() == 'pt' ? 'pt-BR' : 'en-US';
        await supabase.from('user_preferences').upsert({
          'user_id': user.id,
          'language': code,
        });
      }
    } catch (_) {}
  }
}
