import 'package:flutter/material.dart';
import 'package:house_rental_app/data/models/tenant.dart';
import 'package:intl/intl.dart';

class TenantTile extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onTap;

  TenantTile({required this.tenant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysLeft = tenant.leaseEndDate.difference(DateTime.now()).inDays;
    final isLeaseEnding = daysLeft <= 30;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
          child: Icon(Icons.person),
          backgroundColor: Colors.blue.withOpacity(0.1)),
      title: Text(tenant.name),
      subtitle: Text(
          'Lease ends: ${DateFormat('yyyy-MM-dd').format(tenant.leaseEndDate)}'),
      trailing: isLeaseEnding
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('$daysLeft days left',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
