import 'package:excel/excel.dart';
import '../models/payment.dart';
import '../models/property.dart';
import '../models/tenant.dart';

class ReportGenerator {
  static Future<List<int>> generateExcelReport({
    required List<Payment> payments,
    required List<Property> properties,
    required List<Tenant> tenants,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();

    // Payment Sheet
    final paymentSheet = excel['Payments'];
    _addPaymentData(paymentSheet, payments);

    // Property Sheet
    final propertySheet = excel['Properties'];
    _addPropertyData(propertySheet, properties);

    // Tenant Sheet
    final tenantSheet = excel['Tenants'];
    _addTenantData(tenantSheet, tenants);

    return excel.encode()!;
  }

  static void _addPaymentData(Sheet sheet, List<Payment> payments) {
    // Add headers
    sheet.insertRow(0, [
      'Payment ID',
      'Date',
      'Amount',
      'Method',
      'Status',
    ]);

    // Add data
    for (var i = 0; i < payments.length; i++) {
      final payment = payments[i];
      sheet.insertRow(i + 1, [
        payment.id,
        payment.paymentDate.toString(),
        payment.amount,
        payment.paymentMethod,
        payment.paymentStatus,
      ]);
    }
  }

  // Other helper methods...
}
