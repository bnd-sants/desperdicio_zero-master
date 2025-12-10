import 'package:flutter/material.dart';

/// A reusable loading indicator widget
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// A full screen loading indicator with optional message
class FullScreenLoader extends StatelessWidget {
  final String? message;
  final bool showLogo;
  final Color? backgroundColor;

  const FullScreenLoader({
    super.key,
    this.message,
    this.showLogo = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLogo) ...[
              // Replace with your app logo
              const FlutterLogo(size: 80),
              const SizedBox(height: 24),
            ],
            const AppLoadingIndicator(size: 32),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
