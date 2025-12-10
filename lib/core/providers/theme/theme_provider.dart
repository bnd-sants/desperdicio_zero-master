import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cores do WhatsApp
class WhatsAppColors {
  static const Color primary = Color(0xFF25D366); // Verde WhatsApp
  static const Color primaryDark = Color(0xFF128C7E); // Verde escuro
  static const Color background = Color(0xFFFFFFFF); // Branco de fundo
  static const Color surface = Color(0xFFF0F2F5); // Cinza claro para fundos
  static const Color onBackground = Color(0xFF3B4A54); // Cinza escuro para textos
  static const Color error = Color(0xFFE53935); // Vermelho para erros
}

/// Tema claro baseado no WhatsApp
final lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: WhatsAppColors.primary,
    primaryContainer: WhatsAppColors.primaryDark,
    secondary: WhatsAppColors.primary,
    secondaryContainer: WhatsAppColors.primaryDark,
    surface: WhatsAppColors.surface,
    surfaceContainer: WhatsAppColors.background,
    error: WhatsAppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: WhatsAppColors.onBackground,
    onSurfaceVariant: WhatsAppColors.onBackground,
    onError: Colors.white,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: WhatsAppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: WhatsAppColors.primaryDark,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: WhatsAppColors.primary,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: WhatsAppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: WhatsAppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
  ),
);

/// Tema escuro baseado no WhatsApp
final darkTheme = ThemeData(
  colorScheme: const ColorScheme.dark(
    primary: WhatsAppColors.primary,
    primaryContainer: WhatsAppColors.primaryDark,
    secondary: WhatsAppColors.primary,
    secondaryContainer: WhatsAppColors.primaryDark,
    surface: Color(0xFF1F2C34),
    surfaceContainer: Color(0xFF0B141A),
    error: Color(0xFFCF6679),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.white,
    onError: Colors.black,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF0B141A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1F2C34),
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: WhatsAppColors.primary,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: WhatsAppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1F2C34),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
  ),
);

/// Provider para gerenciar o tema
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'isDarkMode';
  
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemePreference();
  }
  
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool(_themeKey);
      
      if (isDarkMode != null) {
        state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      } else {
        // Se não houver preferência salva, usa o tema do sistema
        state = ThemeMode.system;
      }
    } catch (e) {
      // Em caso de erro, usa o tema claro como padrão
      state = ThemeMode.light;
    }
  }
  
  Future<void> toggleTheme() async {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _themeKey, 
        state == ThemeMode.dark || 
        (state == ThemeMode.system && 
         PlatformDispatcher.instance.platformBrightness == Brightness.dark)
      );
    } catch (e) {
      // Ignora erros ao salvar a preferência
    }
  }
  
  /// Retorna o tema atual baseado no modo selecionado
  ThemeData getTheme(BuildContext context) {
    final brightness = state == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : state == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light;
    
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }
  
  /// Retorna o modo de tema atual
  bool get isDarkMode => state == ThemeMode.dark;
}
