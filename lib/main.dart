import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:house_rental_app/providers/payment_provider.dart';
import 'package:house_rental_app/providers/property_provider.dart';
import 'package:house_rental_app/providers/tenant_provider.dart';
import 'package:house_rental_app/providers/user_provider.dart';

import 'package:house_rental_app/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Ensure this file exists in lib/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
  
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
      ),
      initialRoute: '/',
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
