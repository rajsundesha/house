import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;
  final String? errorText;
  final String? helperText;
  final bool showIcon;
  final String? dateFormat;
  final EdgeInsetsGeometry? contentPadding;

  const CustomDatePicker({
    Key? key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
    this.errorText,
    this.helperText,
    this.showIcon = true,
    this.dateFormat,
    this.contentPadding,
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat(dateFormat ?? 'MMM d, y');

    return FormField<DateTime>(
      initialValue: selectedDate,
      validator: isRequired
          ? (value) => value == null ? '$label is required' : null
          : null,
      builder: (FormFieldState<DateTime> state) {
        return InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label + (isRequired ? ' *' : ''),
              errorText: errorText ?? state.errorText,
              helperText: helperText,
              contentPadding: contentPadding,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: showIcon ? Icon(Icons.calendar_today) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? formatter.format(selectedDate!)
                      : 'Select Date',
                  style: TextStyle(
                    color: selectedDate != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor,
                  ),
                ),
                if (!showIcon) Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }
}
