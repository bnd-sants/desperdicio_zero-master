import 'package:flutter/material.dart';
import '../theme/style_tokens.dart';

/// Card genérico para manter consistência de espaçamentos e cantos arredondados.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool elevated;
  final BorderRadius? borderRadius;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevated = true,
    this.borderRadius,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedRadius =
        borderRadius ?? BorderRadius.circular(StyleTokens.radiusL);

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? colorScheme.surface) : null,
        gradient: gradient,
        borderRadius: resolvedRadius,
        boxShadow: elevated ? [StyleTokens.lightShadow] : null,
      ),
      child: Padding(
        padding: padding ??
            const EdgeInsets.all(StyleTokens.spacingL),
        child: child,
      ),
    );
  }
}
