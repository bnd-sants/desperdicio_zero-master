import 'package:flutter/material.dart';
import 'app_typography.dart';
import 'style_tokens.dart';

class AppTheme {
  // WhatsApp Color Palette
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color whatsappDarkGreen = Color(0xFF128C7E);
  static const Color whatsappTealGreen = Color(0xFF075E54);
  static const Color whatsappLightGreen = Color(0xFFDCF8C6);
  
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF128C7E); // WhatsApp dark green
  static const Color lightSecondary = Color(0xFF25D366); // WhatsApp green
  static const Color lightBackground = Color(0xFFF0F2F5); // Light gray background
  static const Color lightSurface = Color(0xFFFFFFFF); // White surface
  static const Color lightError = Color(0xFFE53E3E);
  
  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF075E54); // Darker teal green
  static const Color darkSecondary = Color(0xFF128C7E); // WhatsApp dark green
  static const Color darkBackground = Color(0xFF0D1418); // Darker background
  static const Color darkSurface = Color(0xFF1F2C34); // Dark surface
  static const Color darkError = Color(0xFFF56565);

  // Common Colors
  static const Color textPrimary = Color(0xFF3B4A54); // Dark gray for text
  static const Color textSecondary = Color(0xFF667781); // Medium gray
  static const Color textLight = Color(0xFFFFFFFF); // White text
  static const Color textDark = Color(0xFF111B21); // Almost black text

  // Light Theme
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: lightPrimary, // WhatsApp dark green
        primaryContainer: whatsappTealGreen, // Darker teal for containers
        secondary: lightSecondary, // WhatsApp green
        surface: lightSurface, // White surface
        surfaceContainer: lightBackground, // Light gray background
        error: lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary, // Dark gray text
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: lightBackground, // Light gray background
      appBarTheme: const AppBarTheme(
        backgroundColor: lightPrimary, // WhatsApp dark green
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary, // WhatsApp dark green
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // More rounded corners
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary, // WhatsApp dark green
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!), // Lighter border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!), // Lighter border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightPrimary, width: 2), // WhatsApp green border
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightError, width: 2),
        ),
        labelStyle: const TextStyle(
          color: textSecondary, // Medium gray
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentTextStyle: const TextStyle(color: Colors.white),
        backgroundColor: darkSurface,
        actionTextColor: lightPrimary,
      ),
      textTheme: AppTypography.light(base.textTheme, base.colorScheme),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleTokens.radiusM),
        ),
        color: lightBackground,
        surfaceTintColor: lightBackground,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StyleTokens.radiusXL),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: StyleTokens.spacingL,
            vertical: StyleTokens.spacingM,
          ),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      useMaterial3: true,
      colorScheme: base.colorScheme.copyWith(
        primary: darkPrimary, // Dark teal
        primaryContainer: whatsappTealGreen, // Teal for containers
        secondary: darkSecondary, // WhatsApp dark green
        surface: darkSurface, // Dark surface
        surfaceContainer: darkBackground, // Dark background
        error: darkError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textLight, // White text
        onSurfaceVariant: textSecondary, // Medium gray for variants
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackground, // Dark background
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPrimary, // Dark teal
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkSecondary, // WhatsApp dark green
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // More rounded corners
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkSecondary, // WhatsApp dark green
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface, // Dark surface for input fields
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!), // Darker border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkError),
        ),
        labelStyle: TextStyle(color: Colors.grey[400]),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      // SnackBar para tema escuro
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: darkPrimary,
      ),
      // Cards para tema escuro
      textTheme: AppTypography.dark(base.textTheme, base.colorScheme),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleTokens.radiusM),
        ),
        color: darkSurface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StyleTokens.radiusXL),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: StyleTokens.spacingL,
            vertical: StyleTokens.spacingM,
          ),
        ),
      ),
    );
  }
}
