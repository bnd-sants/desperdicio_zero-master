import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:desperdicio_zero/screens/add_product/add_product_constants.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final bool isRequired;
  final String? Function(DateTime?)? validator;

  const DatePickerField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.isRequired = false,
    this.validator,
  });

  Future<void> _selectDate(BuildContext context) async {
    try {
      // Validate date range
      final now = DateTime.now();
      final initial = selectedDate ?? initialDate ?? now;
      final first = firstDate ?? DateTime(2000);
      final last = lastDate ?? DateTime(now.year + 10);
      
      if (first.isAfter(last)) {
        throw ArgumentError('firstDate cannot be after lastDate');
      }
      
      if (initial.isBefore(first) || initial.isAfter(last)) {
        throw ArgumentError('initialDate must be between firstDate and lastDate');
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Theme.of(context).colorScheme.onPrimary,
                surface: Theme.of(context).colorScheme.surface,
                onSurface: Theme.of(context).colorScheme.onSurface,
              ),
              // Using the app's dialog theme instead of creating a new one
              dialogTheme: Theme.of(context).dialogTheme.copyWith(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
                elevation: 24.0,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && picked != selectedDate) {
        onDateSelected(picked);
      }
    } catch (e) {
      debugPrint('Error in date picker: $e');
      // Show error to user if possible
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao selecionar data. Tente novamente.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(AddProductConstants.borderRadius),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Selecione uma data',
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
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              icon: Icon(
                AddProductConstants.calendarIcon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? DateFormat(AddProductConstants.dateFormat).format(selectedDate!)
                      : 'Selecione uma data',
                  style: selectedDate != null
                      ? Theme.of(context).textTheme.bodyLarge
                      : Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                ),
              ],
            ),
          ),
        ),
        if (validator != null && isRequired && selectedDate == null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              'Por favor, selecione uma data',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }
}
