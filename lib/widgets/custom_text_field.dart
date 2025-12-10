import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final void Function()? onTap;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final String? initialValue;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool showCounter;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.onSaved,
    this.onTap,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.initialValue,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.showCounter = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: suffixIcon,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF25D366), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            counterStyle: const TextStyle(fontSize: 12),
            counterText: showCounter ? null : '',
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[800],
          ),
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          onChanged: onChanged,
          onSaved: onSaved,
          onTap: onTap,
          readOnly: readOnly,
          textCapitalization: textCapitalization,
          initialValue: initialValue,
          autofocus: autofocus,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }
}
