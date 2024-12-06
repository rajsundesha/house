import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/report_data.dart';
import '../../data/report_service.dart';

final reportServiceProvider = Provider((ref) => ReportService());

final reportProvider = FutureProvider<ReportData>((ref) async {
  final reportService = ref.watch(reportServiceProvider);
  return await reportService.generateOverallReport();
});

final propertyReportProvider = FutureProvider.family<ReportData, String>(
  (ref, propertyId) async {
    final reportService = ref.watch(reportServiceProvider);
    return await reportService.generatePropertyReport(propertyId);
  },
);

final reportFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

final filteredReportProvider = FutureProvider<ReportData>((ref) async {
  final reportService = ref.watch(reportServiceProvider);
  final dateRange = ref.watch(reportFilterProvider);
  
  if (dateRange == null) {
    return await reportService.generateOverallReport();
  }
  
  return await reportService.generateFilteredReport(dateRange);
});