import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';

class RentalApp extends ConsumerWidget {
  const RentalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Rental Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}