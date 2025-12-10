import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF25D366); // WhatsApp green
  static const Color primaryDark = Color(0xFF128C7E); // Dark green
  static const Color primaryLight = Color(0xFFDCF8C6); // Light green
  
  // Light Theme colors
  static const Color lightBackground = Color(0xFFF0F2F5); // Light gray background
  static const Color lightSurface = Color(0xFFFFFFFF); // White surface
  static const Color lightTextPrimary = Color(0xFF3B4A54); // Dark gray
  static const Color lightTextSecondary = Color(0xFF667781); // Medium gray
  static const Color lightTextTertiary = Color(0xFF8696A0); // Light gray
  static const Color lightBorder = Color(0xFFE9EDEF); // Very light gray
  
  // Dark Theme colors
  static const Color darkBackground = Color(0xFF0B141A); // Dark background
  static const Color darkSurface = Color(0xFF1F2C34); // Dark surface
  static const Color darkTextPrimary = Color(0xFFE9EDEF); // Light gray
  static const Color darkTextSecondary = Color(0xFF8696A0); // Medium gray
  static const Color darkBorder = Color(0xFF2A3942); // Dark border
  
  // Common colors
  static const Color success = Color(0xFF34B7F1); // Blue
  static const Color error = Color(0xFFFF3B30); // Red
  static const Color warning = Color(0xFFFFCC00); // Yellow
  static const Color info = Color(0xFF5AC8FA); // Light blue
  
  // Get colors based on theme
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackground 
        : lightBackground;
  }
  
  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkSurface 
        : lightSurface;
  }
  
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextPrimary 
        : lightTextPrimary;
  }
  
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextSecondary 
        : lightTextSecondary;
  }
  
  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBorder 
        : lightBorder;
  }
}
