import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/manager_dashboard_screen.dart';
import '../../features/properties/presentation/screens/add_property_screen.dart';
import '../../features/properties/presentation/screens/property_list_screen.dart';
import '../../features/tenants/presentation/screens/add_tenant_screen.dart';
import '../../features/tenants/presentation/screens/tenant_list_screen.dart';
import '../../features/leases/presentation/screens/add_lease_screen.dart';
import '../../features/leases/presentation/screens/lease_list_screen.dart';
import '../../features/payments/presentation/screens/record_payment_screen.dart';
import '../../features/payments/presentation/screens/payment_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoginRoute = state.location == '/login';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn && isLoginRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerDashboardScreen(),
      ),
      GoRoute(
        path: '/properties',
        builder: (context, state) => const PropertyListScreen(),
      ),
      GoRoute(
        path: '/properties/add',
        builder: (context, state) => const AddPropertyScreen(),
      ),
      GoRoute(
        path: '/tenants',
        builder: (context, state) => const TenantListScreen(),
      ),
      GoRoute(
        path: '/tenants/add',
        builder: (context, state) => const AddTenantScreen(),
      ),
      GoRoute(
        path: '/leases',
        builder: (context, state) => const LeaseListScreen(),
      ),
      GoRoute(
        path: '/leases/add',
        builder: (context, state) => const AddLeaseScreen(),
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentListScreen(),
      ),
      GoRoute(
        path: '/payments/record',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RecordPaymentScreen(
            leaseId: extra['leaseId'],
            tenantId: extra['tenantId'],
            propertyId: extra['propertyId'],
            expectedAmount: extra['expectedAmount'],
          );
        },
      ),
    ],
  );
});