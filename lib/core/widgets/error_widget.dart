import 'package:flutter/material.dart';

/// A reusable error widget
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final double iconSize;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
    this.iconSize = 48.0,
    this.spacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: iconSize,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: spacing),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: spacing),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A full screen error widget with retry option
class FullScreenError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;
  final Widget? icon;

  const FullScreenError({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon ??
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                message,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(retryText ?? 'Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
