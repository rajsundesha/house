import 'package:flutter/material.dart';

class AmenitySelector extends StatelessWidget {
  final List<String> selectedAmenities;
  final Function(List<String>) onChanged;

  final List<Map<String, dynamic>> _availableAmenities = [
    {'name': 'Air Conditioning', 'icon': Icons.ac_unit},
    {'name': 'Heating', 'icon': Icons.whatshot},
    {'name': 'Washing Machine', 'icon': Icons.local_laundry_service},
    {'name': 'TV', 'icon': Icons.tv},
    {'name': 'WiFi', 'icon': Icons.wifi},
    {'name': 'Parking', 'icon': Icons.local_parking},
    {'name': 'Elevator', 'icon': Icons.elevator},
    {'name': 'Security', 'icon': Icons.security},
    {'name': 'Gym', 'icon': Icons.fitness_center},
    {'name': 'Swimming Pool', 'icon': Icons.pool},
  ];

  AmenitySelector({
    Key? key,
    required this.selectedAmenities,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableAmenities.map((amenity) {
        final isSelected = selectedAmenities.contains(amenity['name']);
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                amenity['icon'],
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              SizedBox(width: 8),
              Text(
                amenity['name'],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
          onSelected: (bool selected) {
            final newSelection = List<String>.from(selectedAmenities);
            if (selected) {
              newSelection.add(amenity['name']);
            } else {
              newSelection.remove(amenity['name']);
            }
            onChanged(newSelection);
          },
          selectedColor: Theme.of(context).primaryColor,
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }
}
