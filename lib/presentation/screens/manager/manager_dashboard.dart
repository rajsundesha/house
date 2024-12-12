import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:house_rental_app/presentation/providers/payment_provider.dart';
import 'package:house_rental_app/presentation/providers/report_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManagerDashboard extends StatefulWidget {
  @override
  _ManagerDashboardState createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final managerId = FirebaseAuth.instance.currentUser!.uid;
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      final tenantProvider =
          Provider.of<TenantProvider>(context, listen: false);
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);

      // Fetch manager's properties
      final props =
          await propertyProvider.fetchPropertiesByManagerId(managerId);
      // Fetch tenants for these properties
      final tens = await tenantProvider.fetchTenantsByManagerId(managerId);
      // Load monthly revenue for these properties
      final propertyIds = props.map((p) => p.id).toList();
      DateTime now = DateTime.now();
      await reportProvider.loadMonthlyRevenue(now.year, now.month, propertyIds);
      await reportProvider.loadExpiringLeasesCount(30);
      await reportProvider.loadOccupancyRate();

      // If needed, fetch payments
      // (not mandatory to store, just show info from providers)
      await paymentProvider.fetchPayments();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manager Dashboard'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Properties Assigned: ${propertyProvider.properties.length}'),
                        Text(
                            'Tenants Managed: ${tenantProvider.tenants.length}'),
                        Text(
                            'Monthly Revenue: \$${reportProvider.monthlyRevenue.toStringAsFixed(2)}'),
                        Text(
                            'Expiring Leases(30 days): ${reportProvider.expiringLeasesCount}'),
                        Text(
                            'Occupancy Rate: ${(reportProvider.occupancyRate * 100).toStringAsFixed(2)}%'),
                        SizedBox(height: 24),
                        Text('Quick Actions',
                            style: Theme.of(context).textTheme.headlineLarge),
                        SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            ElevatedButton.icon(
                                icon: Icon(Icons.home),
                                label: Text('My Properties'),
                                onPressed: () => Navigator.pushNamed(
                                    context, '/assigned_properties')),
                            ElevatedButton.icon(
                              icon: Icon(Icons.payment),
                              label: Text('Record Payment'),
                              onPressed: () => Navigator.pushNamed(
                                  context, '/record_payment'),
                            ),
                            ElevatedButton.icon(
                              icon: Icon(Icons.receipt),
                              label: Text('View Payments'),
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/payments'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
    );
  }
}
