import 'package:flutter/material.dart';
import 'package:house_rental_app/data/repositories/report_repository.dart';

class ReportProvider with ChangeNotifier {
  final ReportRepository _reportRepository;

  double _monthlyRevenue = 0.0;
  double get monthlyRevenue => _monthlyRevenue;

  int _expiringLeasesCount = 0;
  int get expiringLeasesCount => _expiringLeasesCount;

  double _occupancyRate = 0.0;
  double get occupancyRate => _occupancyRate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ReportProvider(this._reportRepository);

  // Add new methods for occupancy rate
  Future<double> getOccupancyRate() async {
    try {
      _occupancyRate = await _reportRepository.getOccupancyRate();
      notifyListeners();
      return _occupancyRate;
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<double> getOccupancyRateForMonth(int year, int month) async {
    try {
      final DateTime startDate = DateTime(year, month, 1);
      final DateTime endDate = DateTime(year, month + 1, 0);

      // Count occupied properties for the specific month
      final properties =
          await _reportRepository.getPropertiesForPeriod(startDate, endDate);
      if (properties.isEmpty) return 0.0;

      final occupiedCount =
          properties.where((p) => p.status.toLowerCase() == 'occupied').length;
      return occupiedCount / properties.length;
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<void> loadMonthlyRevenue(
      int year, int month, List<String> propertyIds) async {
    _isLoading = true;
    try {
      _monthlyRevenue =
          await _reportRepository.getMonthlyRevenue(year, month, propertyIds);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadExpiringLeasesCount(int daysAhead) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _expiringLeasesCount =
          await _reportRepository.getExpiringLeasesCount(daysAhead);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOccupancyRate() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _occupancyRate = await _reportRepository.getOccupancyRate();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new property-specific methods
  Future<double> getPropertyOccupancyRate(
      String propertyId, DateTime startDate, DateTime endDate) async {
    try {
      // Get total days in period
      final totalDays = endDate.difference(startDate).inDays;

      // Get vacancy data for the period
      final vacancyData =
          await getPropertyVacancyData(propertyId, startDate, endDate);
      final vacantDays = vacancyData['totalDays'] as int;

      // Calculate occupancy rate
      return (totalDays - vacantDays) / totalDays;
    } catch (e) {
      throw Exception('Failed to calculate property occupancy rate: $e');
    }
  }

  Future<double> getPropertyMaintenanceCost(
    String propertyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final maintenanceRecords =
          await _reportRepository.getPropertyMaintenanceRecords(
        propertyId,
        startDate,
        endDate,
      );

      // Use a simple loop instead of fold to avoid Future type issues
      double totalCost = 0.0;
      for (var record in maintenanceRecords) {
        totalCost += record.cost;
      }
      return totalCost;
    } catch (e) {
      throw Exception('Failed to get property maintenance cost: $e');
    }
  }

  Future<Map<String, dynamic>> getPropertyVacancyData(
      String propertyId, DateTime startDate, DateTime endDate) async {
    try {
      final vacancyPeriods = await _reportRepository.getPropertyVacancyPeriods(
        propertyId,
        startDate,
        endDate,
      );

      int totalDays = 0;
      for (var period in vacancyPeriods) {
        final periodStart = period['start'] as DateTime;
        final periodEnd = period['end'] as DateTime;
        totalDays += periodEnd.difference(periodStart).inDays;
      }

      return {
        'totalDays': totalDays,
        'periods': vacancyPeriods,
      };
    } catch (e) {
      throw Exception('Failed to get property vacancy data: $e');
    }
  }

  Future<Map<String, dynamic>> getPropertyTenancyData(
      String propertyId, DateTime startDate, DateTime endDate) async {
    try {
      final tenancyPeriods = await _reportRepository.getPropertyTenancyPeriods(
        propertyId,
        startDate,
        endDate,
      );

      int totalDays = 0;
      int totalTenants = tenancyPeriods.length;

      for (var period in tenancyPeriods) {
        final periodStart = period['start'] as DateTime;
        final periodEnd = period['end'] as DateTime;
        totalDays += periodEnd.difference(periodStart).inDays;
      }

      return {
        'totalDays': totalDays,
        'averageDuration': totalTenants > 0 ? totalDays ~/ totalTenants : 0,
        'totalTenants': totalTenants,
        'periods': tenancyPeriods,
      };
    } catch (e) {
      throw Exception('Failed to get property tenancy data: $e');
    }
  }

  Future<double> getMonthlyRevenue(
      int year, int month, List<String> propertyIds) async {
    try {
      double totalRevenue = 0.0;

      // Get payments for the specified month
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      for (String propertyId in propertyIds) {
        final revenue = await _reportRepository
            .getMonthlyRevenue(year, month, [propertyId]);
        totalRevenue += revenue;
      }

      return totalRevenue;
    } catch (e) {
      throw Exception('Failed to get monthly revenue: $e');
    }
  }
}
