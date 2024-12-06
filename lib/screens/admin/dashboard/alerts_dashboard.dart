//lib/screens/admin/dashboard/alerts_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/tenant_provider.dart';
import '../../../models/tenant.dart';
import '../../../widgets/common/async_value_builder.dart';

class AlertsDashboard extends StatelessWidget {
  const AlertsDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alerts & Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildLeaseExpiryAlerts(context),
            _buildMaintenanceAlerts(context),
            _buildPaymentAlerts(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaseExpiryAlerts(BuildContext context) {
    return AsyncValueBuilder<List<Tenant>>(
      future: context.read<TenantProvider>().getExpiringLeases(),
      builder: (tenants) => _buildAlertSection(
        context,
        'Lease Expiry',
        tenants
            .map((tenant) => AlertItem(
                  title: tenant.name,
                  subtitle:
                      'Lease expires on ${DateFormat('MMM dd, yyyy').format(tenant.leaseEndDate)}',
                  icon: Icons.event_busy,
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/tenant_detail',
                    arguments: tenant,
                  ),
                ))
            .toList(),
      ),
      loadingWidget: Center(child: CircularProgressIndicator()),
      errorBuilder: (error) => Text('Error loading alerts: $error'),
    );
  }

  Widget _buildMaintenanceAlerts(BuildContext context) {
    // TODO: Implement maintenance alerts
    return SizedBox();
  }

  Widget _buildPaymentAlerts(BuildContext context) {
    // TODO: Implement payment alerts
    return SizedBox();
  }

  Widget _buildAlertSection(
    BuildContext context,
    String title,
    List<AlertItem> alerts,
  ) {
    if (alerts.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        ...alerts,
        Divider(),
      ],
    );
  }
}

class AlertItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AlertItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
