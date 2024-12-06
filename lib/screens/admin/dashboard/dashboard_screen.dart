//lib/screens/admin/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/tenant_provider.dart';
import '../../../providers/payment_provider.dart';
import 'alerts_dashboard.dart';
import 'revenue_dashboard.dart';
import 'occupancy_dashboard.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _refreshData(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshData(context),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            QuickActions(),
            SizedBox(height: 16),
            RevenueDashboard(),
            SizedBox(height: 16),
            OccupancyDashboard(),
            SizedBox(height: 16),
            AlertsDashboard(),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData(BuildContext context) async {
    try {
      await Future.wait([
        context.read<PropertyProvider>().fetchProperties(),
        context.read<TenantProvider>().fetchTenants(),
        context.read<PaymentProvider>().fetchPayments(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing data: $e')),
      );
    }
  }
}
