import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/language_provider.dart';

class Language {
  final String code;
  final String name;
  final String flag;
  final Locale locale;

  const Language({
    required this.code,
    required this.name,
    required this.flag,
    required this.locale,
  });
}

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  final List<Language> languages = const [
    Language(
      code: 'pt',
      name: 'Português (Brasil)',
      flag: '🇧🇷',
      locale: Locale('pt', 'BR'),
    ),
    Language(
      code: 'en',
      name: 'English (US)',
      flag: '🇺🇸',
      locale: Locale('en', 'US'),
    ),
    // Adicione mais idiomas conforme necessário
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageNotifier = ref.watch(languageProvider);
    final currentLocale = languageNotifier.locale;

    return RadioGroup<Locale>(
      groupValue: currentLocale,
      onChanged: (Locale? value) {
        if (value != null) {
          languageNotifier.setLanguage(value);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final language in languages)
            RadioListTile<Locale>(
              title: Row(
                children: [
                  Text(language.flag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Text(language.name),
                ],
              ),
              value: language.locale,
              selected: language.locale == currentLocale,
            ),
        ],
      ),
    );
  }
}
