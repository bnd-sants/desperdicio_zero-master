import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final bool disabled;
  final double elevation;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.borderRadius = 12,
    this.padding,
    this.icon,
    this.disabled = false,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = backgroundColor ?? const Color(0xFF25D366);
    final disabledColor = Colors.grey[400];
    final buttonTextColor = textColor ?? Colors.white;

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: ElevatedButton(
        onPressed: (disabled || isLoading || onPressed == null) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? disabledColor : buttonColor,
          foregroundColor: buttonTextColor,
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(buttonTextColor),
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      color: buttonTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
