import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/report_data.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ReportData> generateOverallReport() async {
    try {
      // Get total revenue
      final paymentsSnapshot = await _firestore.collection('payments').get();
      double totalRevenue = 0;
      double pendingPayments = 0;

      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          totalRevenue += data['amount'];
        } else if (data['status'] == 'pending') {
          pendingPayments += data['amount'];
        }
      }

      // Get property stats
      final propertiesSnapshot = await _firestore.collection('properties').get();
      final totalProperties = propertiesSnapshot.size;
      final occupiedProperties = propertiesSnapshot.docs
          .where((doc) => doc.data()['isOccupied'] == true)
          .length;

      // Get tenant count
      final tenantsSnapshot = await _firestore.collection('tenants').get();
      final totalTenants = tenantsSnapshot.size;

      // Get lease stats
      final leasesSnapshot = await _firestore.collection('leases')
          .where('status', isEqualTo: 'active')
          .get();
      final activeLeases = leasesSnapshot.size;

      // Get maintenance stats
      final maintenanceSnapshot = await _firestore.collection('maintenance')
          .where('status', isEqualTo: 'pending')
          .get();
      final pendingMaintenance = maintenanceSnapshot.size;

      // Calculate monthly revenue
      Map<String, double> monthlyRevenue = {};
      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          final date = DateTime.parse(data['paidDate']);
          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + data['amount'];
        }
      }

      // Calculate maintenance by type
      Map<String, int> maintenanceByType = {};
      for (var doc in maintenanceSnapshot.docs) {
        final type = doc.data()['type'];
        maintenanceByType[type] = (maintenanceByType[type] ?? 0) + 1;
      }

      // Calculate occupancy rate
      final occupancyRate = totalProperties > 0
          ? (occupiedProperties / totalProperties) * 100
          : 0;

      return ReportData(
        totalRevenue: totalRevenue,
        pendingPayments: pendingPayments,
        totalProperties: totalProperties,
        occupiedProperties: occupiedProperties,
        totalTenants: totalTenants,
        activeLeases: activeLeases,
        pendingMaintenance: pendingMaintenance,
        monthlyRevenue: monthlyRevenue,
        maintenanceByType: maintenanceByType,
        occupancyRate: occupancyRate,
      );
    } catch (e) {
      print('Error generating report: $e');
      return ReportData.empty();
    }
  }
}