//lib/screens/admin/dashboard/base_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/tenant_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../models/tenant.dart';
import '../../../widgets/common/async_value_builder.dart';
import 'alerts_dashboard.dart';
import 'revenue_dashboard.dart';
import 'occupancy_dashboard.dart';
