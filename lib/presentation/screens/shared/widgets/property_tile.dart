import 'package:flutter/material.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/utils/currency_utils.dart';

class PropertyTile extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  PropertyTile({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title:
          Text(property.address, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
          '${CurrencyUtils.formatCurrency(property.currentRentAmount)}/month - ${property.status.toUpperCase()}'),
      trailing: Icon(Icons.chevron_right),
    );
  }
}
