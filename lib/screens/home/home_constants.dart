import 'package:flutter/material.dart';

class HomeConstants {
  // Colors
  static const Color primaryColor = Color(0xFF25D366);
  static const Color primaryDarkColor = Color(0xFF128C7E);
  static const Color backgroundColor = Color(0xFFF0F2F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF3B4A54);
  static const Color textSecondary = Color(0xFF667781);
  static const Color borderColor = Color(0xFFE9EDEF);

  // Quick Actions
  static const List<Map<String, dynamic>> quickActions = [
    {
      'title': 'Adicionar Produto',
      'icon': Icons.add_circle_outline,
      'color': Color(0xFF25D366),
    },
    {
      'title': 'Receitas',
      'icon': Icons.restaurant_menu,
      'color': Color(0xFF34B7F1),
    },
  ];

  // Categories
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Alimentos', 'icon': Icons.fastfood_rounded, 'count': 0},
    {'name': 'Bebidas', 'icon': Icons.local_drink_rounded, 'count': 0},
    {'name': 'Limpeza', 'icon': Icons.cleaning_services_rounded, 'count': 0},
    {'name': 'Higiene', 'icon': Icons.soap_rounded, 'count': 0},
  ];

  // Text Styles
  static const TextStyle sectionHeaderStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3B4A54),
  );

  static const TextStyle productNameStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  // Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double mediumPadding = 12.0;
}
