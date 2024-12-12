import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:intl/intl.dart';

class LeaseManagementScreen extends StatefulWidget {
  @override
  _LeaseManagementScreenState createState() => _LeaseManagementScreenState();
}

class _LeaseManagementScreenState extends State<LeaseManagementScreen> {
  bool _isLoading = false;
  bool _showExpiringIn30Days = true;

  @override
  void initState() {
    super.initState();
    _fetchTenants();
  }

  Future<void> _fetchTenants() async {
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    setState(() => _isLoading = true);
    await tenantProvider.fetchTenants();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = Provider.of<TenantProvider>(context);
    final tenants = tenantProvider.tenants.where((t) {
      final daysLeft = t.leaseEndDate.difference(DateTime.now()).inDays;
      return daysLeft <= (_showExpiringIn30Days ? 30 : 60) && daysLeft >= 0;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Lease Management'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (val) {
              setState(() {
                _showExpiringIn30Days = (val == 30);
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 30, child: Text('Expiring in <=30 days')),
              PopupMenuItem(value: 60, child: Text('Expiring in <=60 days')),
            ],
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : tenants.isEmpty
              ? Center(child: Text('No leases expiring soon.'))
              : ListView.builder(
                  itemCount: tenants.length,
                  itemBuilder: (context, index) {
                    final tenant = tenants[index];
                    final daysLeft =
                        tenant.leaseEndDate.difference(DateTime.now()).inDays;
                    return ListTile(
                      title: Text(tenant.name),
                      subtitle: Text(
                          'Lease ends: ${DateFormat('yyyy-MM-dd').format(tenant.leaseEndDate)}\nEffective Rent: ${tenant.rentAdjustment > 0 ? 'Base - ' + tenant.rentAdjustment.toString() : 'No discount'}'),
                      trailing: daysLeft <= 30
                          ? Text('$daysLeft days left',
                              style: TextStyle(color: Colors.red))
                          : Text('$daysLeft days left'),
                      onTap: () {
                        // Could navigate to a TenantDetail screen to renew lease or adjust rent
                      },
                    );
                  },
                ),
    );
  }
}
