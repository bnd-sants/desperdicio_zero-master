import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static TextTheme light(TextTheme base, ColorScheme colorScheme) {
    final tuned = _baseTextTheme(base);
    return tuned.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }

  static TextTheme dark(TextTheme base, ColorScheme colorScheme) {
    final tuned = _baseTextTheme(base);
    return tuned.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }

  static TextTheme _baseTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      titleMedium: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      titleSmall: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
