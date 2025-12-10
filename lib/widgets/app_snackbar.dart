import 'package:flutter/material.dart';
import '../theme/style_tokens.dart';

class AppSnackbar {
  const AppSnackbar._();

  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: colorScheme.primary,
      icon: Icons.check_circle_outline,
      iconColor: colorScheme.onPrimary,
      textColor: colorScheme.onPrimary,
      duration: duration,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: colorScheme.error,
      icon: Icons.error_outline,
      iconColor: colorScheme.onError,
      textColor: colorScheme.onError,
      duration: duration,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: colorScheme.secondaryContainer,
      icon: Icons.info_outline,
      iconColor: colorScheme.onSecondaryContainer,
      textColor: colorScheme.onSecondaryContainer,
      duration: duration,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: colorScheme.tertiaryContainer,
      icon: Icons.warning_amber_rounded,
      iconColor: colorScheme.onTertiaryContainer,
      textColor: colorScheme.onTertiaryContainer,
      duration: duration,
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Color? iconColor,
    Color? textColor,
    Duration? duration,
  }) {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            left: StyleTokens.spacingL,
            right: StyleTokens.spacingL,
            bottom: 80,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StyleTokens.radiusM),
          ),
          duration: duration ?? const Duration(seconds: 3),
          backgroundColor: backgroundColor,
          content: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: StyleTokens.spacingM),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor ?? theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'OK',
            textColor: textColor ?? theme.colorScheme.onPrimary,
            onPressed: messenger.hideCurrentSnackBar,
          ),
        ),
      );
  }
}
