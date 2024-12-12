import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/screens/admin/change_password_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/edit_profile_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/setting_screen.dart';
import 'package:house_rental_app/presentation/screens/auth/login_screen.dart';
import 'package:house_rental_app/presentation/screens/auth/phone_number_screen.dart';
import 'package:house_rental_app/presentation/screens/auth/otp_verification_screen.dart';
import 'package:house_rental_app/presentation/screens/auth/registration_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/admin_dashboard.dart';
import 'package:house_rental_app/presentation/screens/admin/property_management/property_list_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/property_management/add_property_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/property_management/property_detail_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/property_management/property_images_gallery_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/property_management/document_viewer_screen.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/presentation/screens/admin/tenant_management/tenant_list_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/tenant_management/add_tenant_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/tenant_management/tenant_detail_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/tenant_management/tenant_documents_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/tenant_management/tenant_family_members_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/tenant_management/tenant_payment_history_screen.dart';
import 'package:house_rental_app/data/models/tenant.dart';
import 'package:house_rental_app/presentation/screens/admin/user_management/user_list_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/user_management/add_user_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/report_analysis_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/lease_management_screen.dart';
import 'package:house_rental_app/presentation/screens/admin/assign_manager_screen.dart';
import 'package:house_rental_app/presentation/screens/calendar/calendar_screen.dart';
import 'package:house_rental_app/presentation/screens/maintenance/maintenance_schedule_screen.dart';
import 'package:house_rental_app/presentation/screens/manager/manager_dashboard.dart';
import 'package:house_rental_app/presentation/screens/manager/assigned_properties_screen.dart';
import 'package:house_rental_app/presentation/screens/manager/record_payment_screen.dart';
import 'package:house_rental_app/presentation/screens/manager/payment_list_screen.dart';
import 'package:house_rental_app/presentation/screens/manager/payment_detail_screen.dart';
import 'package:house_rental_app/data/models/payment.dart';
import 'package:house_rental_app/presentation/screens/reports/maintenance_report_screen.dart';
import 'package:house_rental_app/presentation/screens/maintenance/add_maintenance_task_screen.dart';
import 'package:house_rental_app/presentation/screens/maintenance/edit_maintenance_task_screen.dart';
import 'package:house_rental_app/presentation/screens/reports/occupancy_report_screen.dart';
import 'package:house_rental_app/presentation/screens/reports/property_performance_screen.dart';
import 'package:house_rental_app/presentation/screens/reports/revenue_report_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case '/':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/phone_login':
        return MaterialPageRoute(builder: (_) => PhoneNumberScreen());
      case '/otp_verification':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            verificationId: args['verificationId'],
            phoneNumber: args['phoneNumber'],
            resendToken: args['resendToken'],
          ),
        );
      case '/register':
        return MaterialPageRoute(builder: (_) => RegistrationScreen());

      // Dashboard Routes
      case '/admin_dashboard':
        return MaterialPageRoute(builder: (_) => AdminDashboard());
      case '/manager_dashboard':
        return MaterialPageRoute(builder: (_) => ManagerDashboard());

      // Property Management Routes
      case '/property_list':
        return MaterialPageRoute(builder: (_) => PropertyListScreen());
      case '/add_property':
        return MaterialPageRoute(builder: (_) => AddPropertyScreen());
      case '/property_detail':
        final property = settings.arguments as Property;
        return MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(property: property),
        );
      case '/property_images':
        final property = settings.arguments as Property;
        return MaterialPageRoute(
          builder: (_) => PropertyImagesGalleryScreen(property: property),
        );
      case '/document_viewer':
        final property = settings.arguments as Property;
        return MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(property: property),
        );
      case '/property_performance':
        final property = settings.arguments as Property;
        return MaterialPageRoute(
          builder: (_) => PropertyPerformanceScreen(property: property),
        );

      // Tenant Management Routes
      case '/tenant_list':
        return MaterialPageRoute(builder: (_) => TenantListScreen());
      case '/add_tenant':
        final propertyId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => AddTenantScreen(propertyId: propertyId),
        );
      case '/tenant_detail':
        final tenant = settings.arguments as Tenant;
        return MaterialPageRoute(
          builder: (_) => TenantDetailScreen(tenant: tenant),
        );
      case '/tenant_documents':
        final tenant = settings.arguments as Tenant;
        return MaterialPageRoute(
          builder: (_) => TenantDocumentsScreen(tenant: tenant),
        );
      case '/tenant_family':
        final tenant = settings.arguments as Tenant;
        return MaterialPageRoute(
          builder: (_) => TenantFamilyMembersScreen(tenant: tenant),
        );
      case '/tenant_payment_history':
        final tenant = settings.arguments as Tenant;
        return MaterialPageRoute(
          builder: (_) => TenantPaymentHistoryScreen(tenant: tenant),
        );

      // User Management Routes
      case '/user_list':
        return MaterialPageRoute(builder: (_) => UserListScreen());
      case '/add_user':
        return MaterialPageRoute(builder: (_) => AddUserScreen());

      // Report Routes
      case '/report_analysis':
        return MaterialPageRoute(builder: (_) => ReportAnalysisScreen());
      case '/maintenance_report':
        return MaterialPageRoute(builder: (_) => MaintenanceReportScreen());
      case '/occupancy_report':
        return MaterialPageRoute(builder: (_) => OccupancyReportScreen());
      case '/revenue_report':
        return MaterialPageRoute(builder: (_) => RevenueReportScreen());

      // Maintenance Routes
      case '/maintenance_schedule':
        return MaterialPageRoute(builder: (_) => MaintenanceScheduleScreen());
      case '/lease_management':
        return MaterialPageRoute(builder: (_) => LeaseManagementScreen());
        case '/add_maintenance_task':
        final propertyId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => AddMaintenanceTaskScreen(propertyId: propertyId),
        );

      case '/edit_maintenance_task':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => EditMaintenanceTaskScreen(
            propertyId: args['propertyId'],
            record: args['record'],
          ),
        );

      // Manager Assignment Route
      case '/assign_manager':
        final propId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => AssignManagerScreen(propertyId: propId),
        );

      // Manager Specific Routes
      case '/assigned_properties':
        return MaterialPageRoute(builder: (_) => AssignedPropertiesScreen());
      case '/record_payment':
        return MaterialPageRoute(builder: (_) => RecordPaymentScreen());
      case '/payments':
        return MaterialPageRoute(builder: (_) => PaymentListScreen());
      case '/payment_detail':
        final payment = settings.arguments as Payment;
        return MaterialPageRoute(
          builder: (_) => PaymentDetailsScreen(payment: payment),
        );

      // Settings Routes
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsScreen());
      case '/edit_profile':
        return MaterialPageRoute(builder: (_) => EditProfileScreen());
      case '/change_password':
        return MaterialPageRoute(builder: (_) => ChangePasswordScreen());

      // Calendar Route
      case '/calendar':
        return MaterialPageRoute(builder: (_) => CalendarScreen());

      // Default Route
      default:
        return MaterialPageRoute(builder: (_) => LoginScreen());
    }
  }
}
