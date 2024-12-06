import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/providers/property_provider.dart';
import 'package:house_rental_app/providers/tenant_provider.dart';
import 'package:house_rental_app/providers/payment_provider.dart';
import 'package:house_rental_app/models/property.dart';
import 'package:house_rental_app/models/tenant.dart';
import 'package:house_rental_app/models/payment.dart';

class ManagerDashboard extends StatefulWidget {
  @override
  _ManagerDashboardState createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  bool _isLoading = false;
  Map<String, dynamic> _stats = {
    'totalProperties': 0,
    'vacantProperties': 0,
    'totalTenants': 0,
    'totalRevenue': 0.0,
    'pendingRenewals': 0,
  };
  List<Property> _recentProperties = [];
  List<Payment> _recentPayments = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final managerId = FirebaseAuth.instance.currentUser!.uid;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Load properties
      final properties =
          await Provider.of<PropertyProvider>(context, listen: false)
              .fetchPropertiesByManagerId(managerId);

      // Load tenants
      final tenants = await Provider.of<TenantProvider>(context, listen: false)
          .fetchTenantsByManagerId(managerId);

      // Get property IDs managed by this manager
      final propertyIds = properties.map((p) => p.id).toList();

      // Load payments
      final QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('paymentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .where('paymentStatus', isEqualTo: 'completed')
          .get();

      // Filter and calculate revenue
      double managerRevenue = 0;
      List<Payment> recentPayments = [];

      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (propertyIds.contains(data['propertyId'])) {
          managerRevenue += (data['amount'] ?? 0).toDouble();
          recentPayments.add(Payment.fromMap(data, doc.id));
        }
      }

      setState(() {
        _stats = {
          'totalProperties': properties.length,
          'vacantProperties':
              properties.where((p) => p.status == 'vacant').length,
          'totalTenants': tenants.length,
          'pendingRenewals': tenants.where((t) {
            final daysLeft = t.leaseEndDate.difference(now).inDays;
            return daysLeft <= 30 && daysLeft >= 0;
          }).length,
          'totalRevenue': managerRevenue,
        };

        _recentProperties = properties.take(3).toList();
        _recentPayments = recentPayments.take(5).toList();
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "en_US");

    return Scaffold(
      appBar: AppBar(
        title: Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          'Properties',
                          '${_stats['totalProperties']}',
                          'Vacant: ${_stats['vacantProperties']}',
                          Icons.home,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Tenants',
                          '${_stats['totalTenants']}',
                          'Renewals: ${_stats['pendingRenewals']}',
                          Icons.people,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Monthly Revenue',
                          '\$${formatter.format(_stats['totalRevenue'])}',
                          'This Month',
                          Icons.attach_money,
                          Colors.purple,
                        ),
                        _buildActionCard(),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildActionButton(
                            'View Properties',
                            Icons.home,
                            '/assigned_properties',
                            Colors.blue,
                          ),
                          _buildActionButton(
                            'Record Payment',
                            Icons.payment,
                            '/record_payment',
                            Colors.green,
                          ),
                          _buildActionButton(
                            'View Payments',
                            Icons.receipt,
                            '/payments',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Recent Properties
                    if (_recentProperties.isNotEmpty) ...[
                      Text(
                        'Recent Properties',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      ..._recentProperties
                          .map((property) => Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: property.status == 'vacant'
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    child: Icon(
                                      Icons.home,
                                      color: property.status == 'vacant'
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                  title: Text(property.address),
                                  subtitle: Text(
                                      '\$${formatter.format(property.rentAmount)}/month'),
                                  trailing: Chip(
                                    label: Text(
                                      property.status.toUpperCase(),
                                      style: TextStyle(
                                        color: property.status == 'vacant'
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    backgroundColor: property.status == 'vacant'
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                  ),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/property_detail',
                                    arguments: property,
                                  ),
                                ),
                              ))
                          .toList(),
                    ],
                    SizedBox(height: 24),

                    // Recent Payments
                    if (_recentPayments.isNotEmpty) ...[
                      Text(
                        'Recent Payments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      ..._recentPayments
                          .map((payment) => Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Colors.green.withOpacity(0.1),
                                    child: Icon(Icons.payment,
                                        color: Colors.green),
                                  ),
                                  title: Text(
                                      '\$${formatter.format(payment.amount)}'),
                                  subtitle: Text(
                                    DateFormat('MMM dd, yyyy')
                                        .format(payment.paymentDate),
                                  ),
                                  trailing: Icon(Icons.chevron_right),
                                  onTap: () {
                                    // Navigate to payment details
                                  },
                                ),
                              ))
                          .toList(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 130),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              SizedBox(height: 8),
              FittedBox(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/assigned_properties'),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard, size: 32, color: Colors.white),
              SizedBox(height: 8),
              Text(
                'View All',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Properties',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, String route, Color color) {
    return Card(
      margin: EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
