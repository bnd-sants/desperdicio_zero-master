import 'package:flutter/material.dart';

/// Centraliza as constantes visuais compartilhadas em todo o app.
class StyleTokens {
  StyleTokens._();

  // Espaçamentos
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 12;
  static const double spacingL = 16;
  static const double spacingXL = 24;
  static const double spacingXXL = 32;

  // Raios de borda
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;
  static const double radiusXXL = 28;
  static const double radiusPill = 999;

  // Sombras
  static final BoxShadow lightShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 20,
    spreadRadius: 1,
    offset: const Offset(0, 8),
  );

  static final BoxShadow mediumShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 24,
    spreadRadius: 1,
    offset: const Offset(0, 12),
  );

  // Gradientes
  static LinearGradient heroGradient(Color primary, Color container) =>
      LinearGradient(
        colors: [primary, container],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
