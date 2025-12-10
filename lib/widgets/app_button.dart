import 'package:flutter/material.dart';
import 'package:desperdicio_zero/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final double elevation;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.borderRadius = 8.0,
    this.padding,
    this.icon,
    this.elevation = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonChild = isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? theme.colorScheme.onPrimary,
              ),
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: textColor ?? theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: textColor ?? theme.colorScheme.onPrimary,
        elevation: elevation,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        minimumSize: Size(
          isFullWidth ? double.infinity : (width ?? 0),
          height!,
        ),
      ),
      child: buttonChild,
    );

    return isFullWidth
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }
}

class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final bool isUnderlined;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? padding;

  const AppTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.isUnderlined = false,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: padding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? theme.colorScheme.primary,
          fontSize: fontSize,
          fontWeight: fontWeight,
          decoration: isUnderlined ? TextDecoration.underline : null,
          decorationColor: color ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}
