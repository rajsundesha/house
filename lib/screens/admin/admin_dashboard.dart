import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:house_rental_app/models/payment.dart'; // Ensure Payment model and its imports are correct.

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = false;
  Map<String, dynamic> _dashboardStats = {
    'totalProperties': 0,
    'occupiedProperties': 0,
    'vacantProperties': 0,
    'totalTenants': 0,
    'totalManagers': 0,
    'monthlyRevenue': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoading = true);

    try {
      // Get properties stats
      final propertiesSnapshot =
          await FirebaseFirestore.instance.collection('properties').get();

      final properties = propertiesSnapshot.docs;
      _dashboardStats['totalProperties'] = properties.length;
      _dashboardStats['occupiedProperties'] =
          properties.where((doc) => doc.data()['status'] == 'occupied').length;
      _dashboardStats['vacantProperties'] =
          properties.where((doc) => doc.data()['status'] == 'vacant').length;

      // Get tenants count
      final tenantsSnapshot =
          await FirebaseFirestore.instance.collection('tenants').get();
      _dashboardStats['totalTenants'] = tenantsSnapshot.size;

      // Get managers count
      final managersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'manager')
          .get();
      _dashboardStats['totalManagers'] = managersSnapshot.size;

      // Calculate monthly revenue
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;
      final startOfMonth = DateTime(currentYear, currentMonth, 1);
      final endOfMonth = DateTime(currentYear, currentMonth + 1, 0, 23, 59, 59);

      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('paymentDate', isGreaterThanOrEqualTo: startOfMonth)
          .where('paymentDate', isLessThanOrEqualTo: endOfMonth)
          .get();

      double monthlyRevenue = 0;
      for (var doc in paymentsSnapshot.docs) {
        final payment =
            Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        monthlyRevenue += payment.amount;
      }
      _dashboardStats['monthlyRevenue'] = monthlyRevenue;
    } catch (e) {
      print('Error loading dashboard stats: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard statistics')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardStats,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardStats,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    SizedBox(height: 24),
                    _buildStatisticsGrid(),
                    SizedBox(height: 24),
                    _buildQuickActions(),
                    SizedBox(height: 24),
                    _buildRecentActivities(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.admin_panel_settings,
                size: 30,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    'Manage your properties and tenants',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Properties',
          _dashboardStats['totalProperties'].toString(),
          Icons.home,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Tenants',
          _dashboardStats['totalTenants'].toString(),
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Vacant Properties',
          _dashboardStats['vacantProperties'].toString(),
          Icons.home_work,
          Colors.orange,
        ),
        _buildStatCard(
          'Monthly Revenue',
          '\$${_dashboardStats['monthlyRevenue'].toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            _buildActionButton(
              context,
              'Properties',
              Icons.home,
              '/property_list',
              Colors.blue,
            ),
            _buildActionButton(
              context,
              'Tenants',
              Icons.people,
              '/tenant_list',
              Colors.green,
            ),
            _buildActionButton(
              context,
              'Users',
              Icons.manage_accounts,
              '/user_list',
              Colors.orange,
            ),
            _buildActionButton(
              context,
              'Payments',
              Icons.payment,
              '/payments',
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color color,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          width: MediaQuery.of(context).size.width / 2 - 24,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        _buildActivityList(),
      ],
    );
  }

  Widget _buildActivityList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error loading activities');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent activities'),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: Icon(Icons.payment, color: Colors.green),
                ),
                title: Text('Payment Received'),
                subtitle: Text(
                  'Amount: \$${(data['amount'] ?? 0).toStringAsFixed(2)}',
                ),
                trailing: Text(
                  _formatDate(data['paymentDate'] as Timestamp),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}


// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:house_rental_app/models/payment.dart'; // Add this package to pubspec.yaml

// class AdminDashboard extends StatefulWidget {
//   @override
//   _AdminDashboardState createState() => _AdminDashboardState();
// }

// class _AdminDashboardState extends State<AdminDashboard> {
//   bool _isLoading = false;
//   Map<String, dynamic> _dashboardStats = {
//     'totalProperties': 0,
//     'occupiedProperties': 0,
//     'vacantProperties': 0,
//     'totalTenants': 0,
//     'totalManagers': 0,
//     'monthlyRevenue': 0.0,
//   };

//   @override
//   void initState() {
//     super.initState();
//     _loadDashboardStats();
//   }

//   Future<void> _loadDashboardStats() async {
//     setState(() => _isLoading = true);

//     try {
//       // Get properties stats
//       final propertiesSnapshot =
//           await FirebaseFirestore.instance.collection('properties').get();

//       final properties = propertiesSnapshot.docs;
//       _dashboardStats['totalProperties'] = properties.length;
//       _dashboardStats['occupiedProperties'] =
//           properties.where((doc) => doc.data()['status'] == 'occupied').length;
//       _dashboardStats['vacantProperties'] =
//           properties.where((doc) => doc.data()['status'] == 'vacant').length;

//       // Get tenants count
//       final tenantsSnapshot =
//           await FirebaseFirestore.instance.collection('tenants').get();
//       _dashboardStats['totalTenants'] = tenantsSnapshot.size;

//       // Get managers count
//       final managersSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .where('role', isEqualTo: 'manager')
//           .get();
//       _dashboardStats['totalManagers'] = managersSnapshot.size;

//       // Calculate monthly revenue
//       final currentMonth = DateTime.now().month;
//       final currentYear = DateTime.now().year;
//       final startOfMonth = DateTime(currentYear, currentMonth, 1);
//       final endOfMonth = DateTime(currentYear, currentMonth + 1, 0, 23, 59, 59);

//       final paymentsSnapshot = await FirebaseFirestore.instance
//           .collection('payments')
//           .where('paymentDate', isGreaterThanOrEqualTo: startOfMonth)
//           .where('paymentDate', isLessThanOrEqualTo: endOfMonth)
//           .get();

//       double monthlyRevenue = 0;
//       for (var doc in paymentsSnapshot.docs) {
//         final payment =
//             Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
//         monthlyRevenue += payment.amount;
//       }
//       _dashboardStats['monthlyRevenue'] = monthlyRevenue;
//     } catch (e) {
//       print('Error loading dashboard stats: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading dashboard statistics')),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _handleLogout() async {
//     try {
//       await FirebaseAuth.instance.signOut();
//       Navigator.pushReplacementNamed(context, '/');
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error signing out')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _loadDashboardStats,
//           ),
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: _handleLogout,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: _loadDashboardStats,
//               child: SingleChildScrollView(
//                 physics: AlwaysScrollableScrollPhysics(),
//                 padding: EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildWelcomeCard(),
//                     SizedBox(height: 24),
//                     _buildStatisticsGrid(),
//                     SizedBox(height: 24),
//                     _buildQuickActions(),
//                     SizedBox(height: 24),
//                     _buildRecentActivities(),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _buildWelcomeCard() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
//               child: Icon(
//                 Icons.admin_panel_settings,
//                 size: 30,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Welcome, Admin',
//                     style: Theme.of(context).textTheme.headlineSmall,
//                   ),
//                   Text(
//                     'Manage your properties and tenants',
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                           color: Colors.grey,
//                         ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatisticsGrid() {
//     return GridView.count(
//       crossAxisCount: 2,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       children: [
//         _buildStatCard(
//           'Total Properties',
//           _dashboardStats['totalProperties'].toString(),
//           Icons.home,
//           Colors.blue,
//         ),
//         _buildStatCard(
//           'Total Tenants',
//           _dashboardStats['totalTenants'].toString(),
//           Icons.people,
//           Colors.green,
//         ),
//         _buildStatCard(
//           'Vacant Properties',
//           _dashboardStats['vacantProperties'].toString(),
//           Icons.home_work,
//           Colors.orange,
//         ),
//         _buildStatCard(
//           'Monthly Revenue',
//           '\$${_dashboardStats['monthlyRevenue'].toStringAsFixed(2)}',
//           Icons.attach_money,
//           Colors.purple,
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard(
//       String title, String value, IconData icon, Color color) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 32, color: color),
//             SizedBox(height: 8),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 4),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActions() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Quick Actions',
//           style: Theme.of(context).textTheme.titleLarge,
//         ),
//         SizedBox(height: 16),
//         Wrap(
//           spacing: 16.0,
//           runSpacing: 16.0,
//           children: [
//             _buildActionButton(
//               context,
//               'Properties',
//               Icons.home,
//               '/property_list',
//               Colors.blue,
//             ),
//             _buildActionButton(
//               context,
//               'Tenants',
//               Icons.people,
//               '/tenant_list',
//               Colors.green,
//             ),
//             _buildActionButton(
//               context,
//               'Users',
//               Icons.manage_accounts,
//               '/user_list',
//               Colors.orange,
//             ),
//             _buildActionButton(
//               context,
//               'Payments',
//               Icons.payment,
//               '/payments', // Make sure this route exists in app_routes.dart
//               Colors.purple,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton(
//     BuildContext context,
//     String title,
//     IconData icon,
//     String route,
//     Color color,
//   ) {
//     return Material(
//       color: color.withOpacity(0.1),
//       borderRadius: BorderRadius.circular(8),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(8),
//         onTap: () => Navigator.pushNamed(context, route),
//         child: Container(
//           width: MediaQuery.of(context).size.width / 2 - 24,
//           padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, size: 32, color: color),
//               SizedBox(height: 8),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivities() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Recent Activities',
//           style: Theme.of(context).textTheme.titleLarge,
//         ),
//         SizedBox(height: 16),
//         _buildActivityList(),
//       ],
//     );
//   }

//   Widget _buildActivityList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('payments')
//           .orderBy('paymentDate', descending: true)
//           .limit(5)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Text('Error loading activities');
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Card(
//             child: Padding(
//               padding: EdgeInsets.all(16.0),
//               child: Text('No recent activities'),
//             ),
//           );
//         }

//         return Column(
//           children: snapshot.data!.docs.map((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return Card(
//               margin: EdgeInsets.only(bottom: 8),
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: Colors.green.withOpacity(0.1),
//                   child: Icon(Icons.payment, color: Colors.green),
//                 ),
//                 title: Text('Payment Received'),
//                 subtitle: Text(
//                   'Amount: \$${(data['amount'] ?? 0).toStringAsFixed(2)}',
//                 ),
//                 trailing: Text(
//                   _formatDate(data['paymentDate'] as Timestamp),
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ),
//             );
//           }).toList(),
//         );
//       },
//     );
//   }

//   String _formatDate(Timestamp timestamp) {
//     final date = timestamp.toDate();
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }
