import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:house_rental_app/presentation/providers/report_provider.dart';
import 'package:house_rental_app/presentation/providers/payment_provider.dart';
import 'package:house_rental_app/utils/currency_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/data/models/tenant.dart';
import 'package:house_rental_app/data/models/payment.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  bool _showExpiringLeases = true;
  String _selectedTimeRange = '6months';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        Provider.of<PropertyProvider>(context, listen: false).fetchProperties(),
        Provider.of<TenantProvider>(context, listen: false).fetchTenants(),
        Provider.of<PaymentProvider>(context, listen: false).fetchPayments(),
        Provider.of<ReportProvider>(context, listen: false).loadMonthlyRevenue(
          DateTime.now().year,
          DateTime.now().month,
          [],
        ),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: FittedBox(
            alignment: Alignment.topLeft,
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon row
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                // Value text
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List<Payment> payments) {
    final monthlySums = <DateTime, double>{};
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5);

    // Initialize all months with zero
    for (var i = 0; i <= 5; i++) {
      final month = DateTime(now.year, now.month - i);
      monthlySums[month] = 0;
    }

    // Sum up the payments
    for (var payment in payments) {
      if (payment.paymentDate.isAfter(sixMonthsAgo)) {
        final date =
            DateTime(payment.paymentDate.year, payment.paymentDate.month);
        monthlySums[date] = (monthlySums[date] ?? 0) + payment.amount;
      }
    }

    // Convert to list and sort by date
    final sortedEntries = monthlySums.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries
        .map((e) => FlSpot(
              e.key.millisecondsSinceEpoch.toDouble(),
              e.value,
            ))
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Revenue',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1000,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            CurrencyUtils.formatCompactCurrency(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(date),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot spot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              spot.x.toInt());
                          return LineTooltipItem(
                            '${DateFormat('MMM yyyy').format(date)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: CurrencyUtils.formatCurrency(spot.y),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final recentPayments = paymentProvider.payments.take(5).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activities',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: recentPayments.length,
              itemBuilder: (context, index) {
                final payment = recentPayments[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: Icon(Icons.payment, color: Colors.green),
                  ),
                  title: Text(
                    CurrencyUtils.formatCurrency(payment.amount),
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(payment.paymentDate),
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Chip(
                    label: Text(
                      payment.paymentStatus.toUpperCase(),
                      style: TextStyle(
                        color:
                            payment.paymentStatus.toLowerCase() == 'completed'
                                ? Colors.green
                                : Colors.orange,
                        fontSize: 10,
                      ),
                    ),
                    backgroundColor:
                        (payment.paymentStatus.toLowerCase() == 'completed'
                                ? Colors.green
                                : Colors.orange)
                            .withOpacity(0.1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  context: context,
                  icon: Icons.add_home,
                  label: 'Add Property',
                  route: '/add_property',
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.person_add,
                  label: 'Add Tenant',
                  route: '/add_tenant',
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.payment,
                  label: 'Record Payment',
                  route: '/record_payment',
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.build,
                  label: 'Maintenance',
                  route: '/maintenance_schedule',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => Navigator.pushNamed(context, route),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reduced childAspectRatio to give more vertical space.
                    GridView.count(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      // More height per cell:
                      childAspectRatio: 0.8,
                      children: [
                        _buildStatCard(
                          context,
                          title: 'Properties',
                          value: propertyProvider.properties.length.toString(),
                          subtitle: '',
                          icon: Icons.home,
                          color: Colors.blue,
                          onTap: () =>
                              Navigator.pushNamed(context, '/property_list'),
                        ),
                        _buildStatCard(
                          context,
                          title: 'Tenants',
                          value: tenantProvider.tenants.length.toString(),
                          subtitle: '',
                          icon: Icons.people,
                          color: Colors.green,
                          onTap: () =>
                              Navigator.pushNamed(context, '/tenant_list'),
                        ),
                        _buildStatCard(
                          context,
                          title: 'Revenue',
                          value: CurrencyUtils.formatCurrency(
                              reportProvider.monthlyRevenue),
                          subtitle: 'This Month',
                          icon: Icons.monetization_on,
                          color: Colors.orange,
                          onTap: () =>
                              Navigator.pushNamed(context, '/revenue_report'),
                        ),
                        _buildStatCard(
                          context,
                          title: 'Occupancy',
                          value:
                              '${(reportProvider.occupancyRate * 100).toStringAsFixed(1)}%',
                          subtitle: '',
                          icon: Icons.pie_chart,
                          color: Colors.purple,
                          onTap: () =>
                              Navigator.pushNamed(context, '/occupancy_report'),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildRevenueChart(paymentProvider.payments),
                    SizedBox(height: 16),
                    _buildQuickActions(context),
                    SizedBox(height: 16),
                    _buildRecentActivities(context),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildQuickActions(context),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text('Admin'),
            accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Properties'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/property_list');
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Tenants'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/tenant_list');
            },
          ),
          ListTile(
            leading: Icon(Icons.payments),
            title: Text('Payments'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/payments');
            },
          ),
          ListTile(
            leading: Icon(Icons.build),
            title: Text('Maintenance'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/maintenance_schedule');
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Calendar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/calendar');
            },
          ),
          Divider(),
          ExpansionTile(
            leading: Icon(Icons.analytics),
            title: Text('Reports'),
            children: [
              ListTile(
                leading: Icon(Icons.trending_up),
                title: Text('Revenue'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/revenue_report');
                },
              ),
              ListTile(
                leading: Icon(Icons.pie_chart),
                title: Text('Occupancy'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/occupancy_report');
                },
              ),
              ListTile(
                leading: Icon(Icons.build),
                title: Text('Maintenance'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/maintenance_report');
                },
              ),
              ListTile(
                leading: Icon(Icons.assessment),
                title: Text('Property Performance'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/property_performance');
                },
              ),
            ],
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.people_outline),
            title: Text('Manage Users'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/user_list');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _showProfileDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email ?? "N/A"}'),
            SizedBox(height: 8),
            Text(
                'Last Login: ${user?.metadata.lastSignInTime?.toString() ?? "N/A"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/edit_profile');
            },
            child: Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotificationSettings() async {
    Navigator.pushNamed(context, '/notification_settings');
  }

  @override
  void dispose() {
    super.dispose();
  }
}
