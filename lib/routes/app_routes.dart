import 'package:flutter/material.dart';
import 'package:house_rental_app/models/payment.dart';
import 'package:house_rental_app/models/property.dart';
import 'package:house_rental_app/models/tenant.dart';
import 'package:house_rental_app/screens/admin/admin_dashboard.dart';
import 'package:house_rental_app/screens/admin/property_management/add_property_screen.dart';
import 'package:house_rental_app/screens/admin/property_management/property_detail_screen.dart';
import 'package:house_rental_app/screens/admin/property_management/property_list_screen.dart';
import 'package:house_rental_app/screens/admin/tenant_management/add_tenant_screen.dart';
import 'package:house_rental_app/screens/admin/tenant_management/tenant_detail_screen.dart';
import 'package:house_rental_app/screens/admin/tenant_management/tenant_list_screen.dart';
import 'package:house_rental_app/screens/admin/user_management/add_user_screen.dart';
import 'package:house_rental_app/screens/admin/user_management/user_list_screen.dart';
import 'package:house_rental_app/screens/auth/login_screen.dart';
import 'package:house_rental_app/screens/auth/otp_verification_screen.dart';
import 'package:house_rental_app/screens/auth/phone_number_screen.dart';
import 'package:house_rental_app/screens/auth/registration_screen.dart';
import 'package:house_rental_app/screens/manager/AssignManagerScreen.dart';
import 'package:house_rental_app/screens/manager/assigned_properties_screen.dart';
import 'package:house_rental_app/screens/manager/manager_dashboard.dart';
import 'package:house_rental_app/screens/manager/payment_detail_screen.dart';
import 'package:house_rental_app/screens/manager/payment_list_screen.dart';
import 'package:house_rental_app/screens/manager/record_payment_screen.dart';
// // NEW IMPORTS FOR WIZARD
// import 'package:house_rental_app/screens/admin/rental_setup/rental_setup_wizard_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/admin_dashboard':
        return MaterialPageRoute(builder: (_) => AdminDashboard());
      case '/manager_dashboard':
        return MaterialPageRoute(builder: (_) => ManagerDashboard());
      case '/property_list':
        return MaterialPageRoute(
            builder: (_) =>
                PropertyListScreen()); // This will now work with StatefulWidget
      case '/tenant_list':
        return MaterialPageRoute(
            builder: (_) =>
                TenantListScreen()); // This will now work with StatefulWidget
      case '/assigned_properties':
        return MaterialPageRoute(builder: (_) => AssignedPropertiesScreen());
      case '/record_payment':
        return MaterialPageRoute(builder: (_) => RecordPaymentScreen());
      case '/add_property':
        return MaterialPageRoute(builder: (_) => AddPropertyScreen());
      case '/property_detail':
        Property property = settings.arguments as Property;
        return MaterialPageRoute(
            builder: (_) => PropertyDetailScreen(property: property));
      case '/add_tenant':
        return MaterialPageRoute(builder: (_) => AddTenantScreen());
      case '/tenant_detail':
        Tenant tenant = settings.arguments as Tenant;
        return MaterialPageRoute(
            builder: (_) => TenantDetailScreen(tenant: tenant));
      case '/assign_manager':
        String propertyId = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => AssignManagerScreen(propertyId: propertyId));
      case '/phone_login':
        return MaterialPageRoute(builder: (_) => PhoneLoginScreen());

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
      case '/user_list':
        return MaterialPageRoute(builder: (_) => UserListScreen());
      case '/add_user':
        return MaterialPageRoute(builder: (_) => AddUserScreen());
      case '/payments':
        return MaterialPageRoute(builder: (_) => PaymentListScreen());
      case '/payment_detail':
        Payment payment = settings.arguments as Payment;
        return MaterialPageRoute(
          builder: (_) => PaymentDetailsScreen(payment: payment),
        );
      // NEW ROUTE FOR WIZARD
      // case '/rental_setup_wizard':
      //   return MaterialPageRoute(builder: (_) => RentalSetupWizardScreen());
      default:
        return MaterialPageRoute(builder: (_) => LoginScreen());
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:house_rental_app/models/property.dart';
// import 'package:house_rental_app/models/tenant.dart';
// import 'package:house_rental_app/screens/admin/admin_dashboard.dart';
// import 'package:house_rental_app/screens/admin/property_management/add_property_screen.dart';
// import 'package:house_rental_app/screens/admin/property_management/property_detail_screen.dart';
// import 'package:house_rental_app/screens/admin/property_management/property_list_screen.dart';
// import 'package:house_rental_app/screens/admin/tenant_management/add_tenant_screen.dart';
// import 'package:house_rental_app/screens/admin/tenant_management/tenant_detail_screen.dart';
// import 'package:house_rental_app/screens/admin/tenant_management/tenant_list_screen.dart';
// import 'package:house_rental_app/screens/auth/login_screen.dart';
// import 'package:house_rental_app/screens/auth/otp_verification_screen.dart';
// import 'package:house_rental_app/screens/auth/phone_number_screen.dart';
// import 'package:house_rental_app/screens/auth/registration_screen.dart';
// import 'package:house_rental_app/screens/manager/AssignManagerScreen.dart';
// import 'package:house_rental_app/screens/manager/assigned_properties_screen.dart';
// import 'package:house_rental_app/screens/manager/manager_dashboard.dart';
// import 'package:house_rental_app/screens/manager/record_payment_screen.dart';


// class AppRoutes {
//   static Route<dynamic> generateRoute(RouteSettings settings) {
//     switch (settings.name) {
//       case '/':
//         return MaterialPageRoute(builder: (_) => LoginScreen());
//       case '/admin_dashboard':
//         return MaterialPageRoute(builder: (_) => AdminDashboard());
//       case '/manager_dashboard':
//         return MaterialPageRoute(builder: (_) => ManagerDashboard());
//             case '/property_list':
//         return MaterialPageRoute(builder: (_) => PropertyListScreen());
//       case '/tenant_list':
//         return MaterialPageRoute(builder: (_) => TenantListScreen());
//       case '/assigned_properties':
//         return MaterialPageRoute(builder: (_) => AssignedPropertiesScreen());
//       case '/record_payment':
//         return MaterialPageRoute(builder: (_) => RecordPaymentScreen());
//          case '/add_property':
//         return MaterialPageRoute(builder: (_) => AddPropertyScreen());
//       case '/property_detail':
//         Property property = settings.arguments as Property;
//         return MaterialPageRoute(
//             builder: (_) => PropertyDetailScreen(property: property));
//       case '/add_tenant':
//         return MaterialPageRoute(builder: (_) => AddTenantScreen());
//       case '/tenant_detail':
//         Tenant tenant = settings.arguments as Tenant;
//         return MaterialPageRoute(
//             builder: (_) => TenantDetailScreen(tenant: tenant));
//       case '/assign_manager':
//         String propertyId = settings.arguments as String;
//         return MaterialPageRoute(
//             builder: (_) => AssignManagerScreen(propertyId: propertyId));
//             case '/assigned_properties':
//         return MaterialPageRoute(builder: (_) => AssignedPropertiesScreen());
//         case '/phone_login':
//         return MaterialPageRoute(builder: (_) => PhoneNumberScreen());
//       case '/otp_verification':
//         final args = settings.arguments as Map<String, dynamic>;
//         return MaterialPageRoute(
//           builder: (_) => OTPVerificationScreen(
//             verificationId: args['verificationId'],
//           ),
//         );
//         case '/register':
//         return MaterialPageRoute(builder: (_) => RegistrationScreen());
//       // Add other routes
//       default:
//         return MaterialPageRoute(builder: (_) => LoginScreen());
//     }
//   }
// }
