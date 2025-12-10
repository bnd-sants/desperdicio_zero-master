import 'package:flutter/material.dart';
import 'package:desperdicio_zero/screens/add_product/add_product_constants.dart';

class DropdownFormField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final String hint;
  final bool isExpanded;
  final bool isDense;
  final Widget? icon;
  final bool enabled;

  const DropdownFormField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    required this.hint,
    this.isExpanded = false,
    this.isDense = false,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: enabled 
                ? Theme.of(context).cardColor 
                : Theme.of(context).disabledColor.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            isDense: isDense,
            suffixIcon: icon ?? const Icon(Icons.arrow_drop_down),
          ),
          icon: const SizedBox.shrink(),
          isExpanded: isExpanded,
          dropdownColor: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
          menuMaxHeight: 300,
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((DropdownMenuItem<T> item) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.value.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }
}
