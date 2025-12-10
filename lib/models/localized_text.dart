import 'package:flutter/material.dart';
import 'package:desperdicio_zero/services/translation_service.dart';

class LocalizedText {
  final String en;
  String? pt;
  
  LocalizedText({
    required this.en,
    this.pt,
  });
  
  // Get the text in the current app language
  String getText(BuildContext context) {
    final locale = Localizations.localeOf(context);
    
    // If Portuguese is requested and available, return it
    if (locale.languageCode == 'pt' && pt != null) {
      return pt!;
    }
    
    // Fall back to English
    return en;
  }
  
  // Create from English text and optionally translate to Portuguese
  static Future<LocalizedText> create(String englishText, {bool translate = true}) async {
    if (!translate) {
      return LocalizedText(en: englishText);
    }
    
    // Translate to Portuguese if needed
    final translated = await TranslationService.translateText(englishText, from: 'en', to: 'pt');
    return LocalizedText(
      en: englishText,
      pt: translated,
    );
  }
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'en': en,
    'pt': pt,
  };
  
  // Create from JSON
  factory LocalizedText.fromJson(Map<String, dynamic> json) {
    return LocalizedText(
      en: json['en'] ?? '',
      pt: json['pt'],
    );
  }
}
