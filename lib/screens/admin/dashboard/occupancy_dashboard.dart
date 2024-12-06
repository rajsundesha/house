import 'package:flutter/material.dart';
import 'package:house_rental_app/providers/property_provider.dart';
import 'package:provider/provider.dart';

class OccupancyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AsyncValueBuilder<Map<String, int>>(
      future: context.read<PropertyProvider>().getOccupancyStats(),
      builder: (stats) => Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Occupancy Status',
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOccupancyIndicator(
                    context,
                    'Occupied',
                    stats['occupied']!,
                    stats['total']!,
                    Colors.green,
                  ),
                  _buildOccupancyIndicator(
                    context,
                    'Vacant',
                    stats['vacant']!,
                    stats['total']!,
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccupancyIndicator(
    BuildContext context,
    String label,
    int value,
    int total,
    Color color,
  ) {
    final percentage = (value / total * 100).round();

    return Column(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: CircularProgressIndicator(
            value: value / total,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 10,
          ),
        ),
        SizedBox(height: 8),
        Text(label),
        Text(
          '$value/$total ($percentage%)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
