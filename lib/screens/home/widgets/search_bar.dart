import 'package:flutter/material.dart';
import 'package:desperdicio_zero/widgets/app_text_field.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const SearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Buscar produtos...',
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hintText,
      prefixIcon: const Icon(Icons.search),
      onChanged: onChanged,
      borderRadius: 30,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 20,
      ),
    );
  }
}
