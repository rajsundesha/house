import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final Function(T?) onChanged;
  final String Function(T) getLabel;
  final bool isRequired;
  final String? errorText;
  final String? helperText;
  final Widget? prefix;
  final Widget? suffix;
  final EdgeInsetsGeometry? contentPadding;
  final bool isExpanded;
  final bool isDense;

  const CustomDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.getLabel,
    this.isRequired = false,
    this.errorText,
    this.helperText,
    this.prefix,
    this.suffix,
    this.contentPadding,
    this.isExpanded = true,
    this.isDense = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: isRequired
          ? (value) => value == null ? '$label is required' : null
          : null,
      builder: (FormFieldState<T> state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label + (isRequired ? ' *' : ''),
            errorText: errorText ?? state.errorText,
            helperText: helperText,
            prefixIcon: prefix,
            suffixIcon: suffix,
            contentPadding: contentPadding,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          isEmpty: value == null,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: isDense,
              isExpanded: isExpanded,
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    getLabel(item),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (T? newValue) {
                onChanged(newValue);
                state.didChange(newValue);
              },
            ),
          ),
        );
      },
    );
  }
}
