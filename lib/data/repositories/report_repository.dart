import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/data/models/property.dart';

class ReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<double> getMonthlyRevenue(
      int year, int month, List<String> propertyIds) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    if (propertyIds.isEmpty) return 0.0;

    QuerySnapshot snapshot = await _db
        .collection('payments')
        .where('propertyId', whereIn: propertyIds)
        .where('paymentStatus', isEqualTo: 'completed')
        .where('paymentDate', isGreaterThanOrEqualTo: startOfMonth)
        .where('paymentDate', isLessThanOrEqualTo: endOfMonth)
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc['amount'] ?? 0).toDouble();
    }
    return total;
  }


Future<List<Property>> getPropertiesForPeriod(
      DateTime startDate, DateTime endDate) async {
    final snapshot = await _db
        .collection('properties')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .get();

    return snapshot.docs
        .map((doc) => Property.fromMap(doc.data(), doc.id))
        .toList();
  }


  Future<int> getExpiringLeasesCount(int daysAhead) async {
    final now = DateTime.now();
    final limitDate = now.add(Duration(days: daysAhead));

    QuerySnapshot snapshot = await _db
        .collection('tenants')
        .where('leaseEndDate', isLessThanOrEqualTo: limitDate)
        .get();
    return snapshot.size;
  }

  Future<double> getOccupancyRate() async {
    // occupancy rate = occupied properties / total properties
    QuerySnapshot propSnapshot = await _db.collection('properties').get();
    if (propSnapshot.size == 0) return 0.0;

    int occupiedCount = propSnapshot.docs.where((doc) {
      return doc.data() is Map<String, dynamic> &&
          (doc.data() as Map<String, dynamic>)['status'] == 'occupied';
    }).length;

    return occupiedCount / propSnapshot.size;
  }



Future<List<MaintenanceRecord>> getPropertyMaintenanceRecords(
    String propertyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final propertyDoc =
        await _db.collection('properties').doc(propertyId).get();
    if (!propertyDoc.exists) return [];

    final property = Property.fromMap(propertyDoc.data()!, propertyDoc.id);
    return property.maintenanceRecords
        .where((record) =>
            record.date.isAfter(startDate) && record.date.isBefore(endDate))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPropertyVacancyPeriods(
    String propertyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _db
        .collection('properties')
        .doc(propertyId)
        .collection('status_history')
        .where('status', isEqualTo: 'vacant')
        .where('startDate', isGreaterThanOrEqualTo: startDate)
        .where('endDate', isLessThanOrEqualTo: endDate)
        .get();

    return snapshot.docs
        .map((doc) => {
              'start': (doc.data()['startDate'] as Timestamp).toDate(),
              'end': (doc.data()['endDate'] as Timestamp).toDate(),
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPropertyTenancyPeriods(
    String propertyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _db
        .collection('tenants')
        .where('propertyId', isEqualTo: propertyId)
        .where('leaseStartDate', isGreaterThanOrEqualTo: startDate)
        .where('leaseEndDate', isLessThanOrEqualTo: endDate)
        .get();

    return snapshot.docs
        .map((doc) => {
              'start': (doc.data()['leaseStartDate'] as Timestamp).toDate(),
              'end': (doc.data()['leaseEndDate'] as Timestamp).toDate(),
              'tenantId': doc.id,
            })
        .toList();
  }

}
