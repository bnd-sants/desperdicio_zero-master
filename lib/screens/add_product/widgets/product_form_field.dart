import 'package:flutter/material.dart';
import 'package:desperdicio_zero/screens/add_product/add_product_constants.dart';

class ProductFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final void Function()? onTap;
  final bool readOnly;

  const ProductFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: suffixIcon,
            counterText: '',
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          onChanged: onChanged,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          focusNode: focusNode,
          onTap: onTap,
          readOnly: readOnly,
        ),
      ],
    );
  }
}
