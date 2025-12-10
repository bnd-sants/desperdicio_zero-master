import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UIUtils {
  static void showSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
    Color? textColor,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onActionPressed ?? () {},
                textColor: Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
    );
  }

  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    showSnackBar(
      context: context,
      message: message,
      duration: duration,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.onError,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    showSnackBar(
      context: context,
      message: message,
      duration: duration,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: child,
        ),
      ),
    );
  }

  static Future<T?> showLoadingDialog<T>({
    required BuildContext context,
    String message = 'Carregando...',
    bool barrierDismissible = false,
  }) {
    return showAppDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDestructive = false,
  }) async {
    return showAppDialog<bool>(
      context: context,
      child: AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
}
