import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageProvider = ChangeNotifierProvider<LanguageProvider>((ref) {
  return LanguageProvider();
});

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
