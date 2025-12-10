import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desperdicio_zero/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final String? initialValue;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final bool showCounter;
  final String? errorText;
  final String? helperText;
  final bool isRequired;
  final bool showRequiredIndicator;
  final bool showErrorBorder;
  final double borderRadius;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.readOnly = false,
    this.initialValue,
    this.contentPadding,
    this.fillColor,
    this.showCounter = false,
    this.errorText,
    this.helperText,
    this.isRequired = false,
    this.showRequiredIndicator = true,
    this.showErrorBorder = true,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isRequired && showRequiredIndicator) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: fillColor ?? theme.inputDecorationTheme.fillColor,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: showErrorBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: colorScheme.error,
                      width: 1,
                    ),
                  )
                : null,
            focusedErrorBorder: showErrorBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: colorScheme.error,
                      width: 2,
                    ),
                  )
                : null,
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: IconTheme(
                      data: IconThemeData(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 24,
                      ),
                      child: prefixIcon!,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16, left: 8),
                    child: IconTheme(
                      data: IconThemeData(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 24,
                      ),
                      child: suffixIcon!,
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
            errorText: errorText,
            errorStyle: textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              height: 1.2,
            ),
            errorMaxLines: 2,
            helperText: helperText,
            helperStyle: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
            counterStyle: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            counterText: showCounter ? null : '',
          ),
          style: textTheme.bodyLarge?.copyWith(
            color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          autofocus: autofocus,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          textInputAction: textInputAction,
          focusNode: focusNode,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
        ),
      ],
    );
  }
}
