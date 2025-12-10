import 'package:flutter/material.dart';

class FormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsetsGeometry? contentPadding;
  final bool showDivider;
  final Widget? trailing;

  const FormSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.contentPadding,
    this.showDivider = true,
    this.trailing,
  });

  /// Validates that the children list is not empty
  void _validateChildren() {
    assert(children.isNotEmpty, 'FormSection must have at least one child');
  }

  @override
  Widget build(BuildContext context) {
    _validateChildren();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider) const Divider(height: 32),
        
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ],
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        
        Padding(
          padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: child,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
