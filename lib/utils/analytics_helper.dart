import 'package:collection/collection.dart';
import '../models/payment.dart';
import '../models/property.dart';

class AnalyticsHelper {
  static Map<String, double> calculateMonthlyRevenue(List<Payment> payments) {
    return groupBy(payments,
            (Payment p) => '${p.paymentDate.year}-${p.paymentDate.month}')
        .map((key, value) => MapEntry(
              key,
              value.fold<double>(0, (sum, payment) => sum + payment.amount),
            ));
  }

  static Map<String, double> calculateOccupancyRate(List<Property> properties) {
    int total = properties.length;
    int occupied = properties.where((p) => p.status == 'occupied').length;

    return {
      'total': total.toDouble(),
      'occupied': occupied.toDouble(),
      'rate': total > 0 ? occupied / total : 0,
    };
  }

  static List<Map<String, dynamic>> getTopPerformingProperties(
    List<Property> properties,
    List<Payment> payments,
  ) {
    // Group payments by property
    var propertyPayments = groupBy(payments, (Payment p) => p.propertyId);

    // Calculate total revenue per property
    var propertyRevenue = propertyPayments.map((propertyId, payments) {
      var total = payments.fold<double>(
        0,
        (sum, payment) => sum + payment.amount,
      );
      return MapEntry(propertyId, total);
    });

    // Sort and return top properties
    return propertyRevenue.entries
        .map((e) => {
              'propertyId': e.key,
              'revenue': e.value,
              'property': properties.firstWhere((p) => p.id == e.key),
            })
        .toList()
      ..sort(
          (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
  }
}
