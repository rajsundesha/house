class ReportData {
  final double totalRevenue;
  final double pendingPayments;
  final int totalProperties;
  final int occupiedProperties;
  final int totalTenants;
  final int activeLeases;
  final int pendingMaintenance;
  final Map<String, double> monthlyRevenue;
  final Map<String, int> maintenanceByType;
  final double occupancyRate;

  ReportData({
    required this.totalRevenue,
    required this.pendingPayments,
    required this.totalProperties,
    required this.occupiedProperties,
    required this.totalTenants,
    required this.activeLeases,
    required this.pendingMaintenance,
    required this.monthlyRevenue,
    required this.maintenanceByType,
    required this.occupancyRate,
  });

  factory ReportData.empty() {
    return ReportData(
      totalRevenue: 0,
      pendingPayments: 0,
      totalProperties: 0,
      occupiedProperties: 0,
      totalTenants: 0,
      activeLeases: 0,
      pendingMaintenance: 0,
      monthlyRevenue: {},
      maintenanceByType: {},
      occupancyRate: 0,
    );
  }
}