import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:house_rental_app/firebase_options.dart';
import 'package:house_rental_app/data/repositories/property_repository.dart';
import 'package:house_rental_app/data/repositories/tenant_repository.dart';
import 'package:house_rental_app/data/repositories/payment_repository.dart';
import 'package:house_rental_app/data/repositories/user_repository.dart';
import 'package:house_rental_app/data/repositories/report_repository.dart';

import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:house_rental_app/presentation/providers/payment_provider.dart';
import 'package:house_rental_app/presentation/providers/user_provider.dart';
import 'package:house_rental_app/presentation/providers/report_provider.dart';

import 'package:house_rental_app/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
 
// Add storage initialization logging
  try {
    final storage = FirebaseStorage.instance;
    print('Storage initialized successfully');
  } catch (e) {
    print('Storage initialization error: $e');
  }
  await Future.delayed(Duration(seconds: 1)); // Add small delay

  
  final propertyRepository = PropertyRepository();
  final tenantRepository = TenantRepository();
  final paymentRepository = PaymentRepository();
  final userRepository = UserRepository();
  final reportRepository = ReportRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => PropertyProvider(propertyRepository)),
        ChangeNotifierProvider(create: (_) => TenantProvider(tenantRepository)),
        ChangeNotifierProvider(
            create: (_) => PaymentProvider(paymentRepository)),
        ChangeNotifierProvider(create: (_) => UserProvider(userRepository)),
        ChangeNotifierProvider(create: (_) => ReportProvider(reportRepository)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'House Rental App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
