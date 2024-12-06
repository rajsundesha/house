import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle logout
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _DashboardCard(
            title: 'Properties',
            icon: Icons.home,
            onTap: () => Navigator.pushNamed(context, '/properties'),
          ),
          _DashboardCard(
            title: 'Tenants',
            icon: Icons.people,
            onTap: () => Navigator.pushNamed(context, '/tenants'),
          ),
          _DashboardCard(
            title: 'Leases',
            icon: Icons.description,
            onTap: () => Navigator.pushNamed(context, '/leases'),
          ),
          _DashboardCard(
            title: 'Payments',
            icon: Icons.payment,
            onTap: () => Navigator.pushNamed(context, '/payments'),
          ),
          _DashboardCard(
            title: 'Managers',
            icon: Icons.manage_accounts,
            onTap: () => Navigator.pushNamed(context, '/managers'),
          ),
          _DashboardCard(
            title: 'Reports',
            icon: Icons.bar_chart,
            onTap: () => Navigator.pushNamed(context, '/reports'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}