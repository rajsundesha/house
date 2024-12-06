import 'package:flutter/material.dart';
import 'package:house_rental_app/models/tenant.dart';
import 'package:intl/intl.dart';

class LeaseExpiryAlerts extends StatelessWidget {
  final List<Tenant> tenants;

  @override
  Widget build(BuildContext context) {
    final expiringLeases = tenants.where((tenant) {
      final daysLeft = tenant.leaseEndDate.difference(DateTime.now()).inDays;
      return daysLeft <= 30 && daysLeft > 0;
    }).toList();

    if (expiringLeases.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No lease renewals due soon'),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Upcoming Lease Renewals',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: expiringLeases.length,
            itemBuilder: (context, index) {
              final tenant = expiringLeases[index];
              final daysLeft =
                  tenant.leaseEndDate.difference(DateTime.now()).inDays;

              return ListTile(
                leading: CircleAvatar(child: Text(daysLeft.toString())),
                title: Text(tenant.name),
                subtitle:
                    Text(DateFormat('dd MMM yyyy').format(tenant.leaseEndDate)),
                trailing: TextButton(
                  onPressed: () {
                    // Navigate to tenant details
                  },
                  child: Text('View Details'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
