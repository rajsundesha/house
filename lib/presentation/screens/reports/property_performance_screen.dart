import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/presentation/providers/payment_provider.dart';
import 'package:house_rental_app/presentation/providers/report_provider.dart';
// import 'package:house_rental_app/presentation/shared/widgets/custom_components.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/utils/currency_utils.dart';

class PropertyMetrics {
  final double totalRevenue;
  final double averageMonthlyRevenue;
  final double occupancyRate;
  final double maintenanceCost;
  final double netIncome;
  final int totalDaysVacant;
  final int averageTenancyDuration;
  final double returnOnInvestment;

  PropertyMetrics({
    required this.totalRevenue,
    required this.averageMonthlyRevenue,
    required this.occupancyRate,
    required this.maintenanceCost,
    required this.netIncome,
    required this.totalDaysVacant,
    required this.averageTenancyDuration,
    required this.returnOnInvestment,
  });
}

class PropertyPerformanceScreen extends StatefulWidget {
  final Property property;

  const PropertyPerformanceScreen({required this.property});

  @override
  _PropertyPerformanceScreenState createState() =>
      _PropertyPerformanceScreenState();
}

class _PropertyPerformanceScreenState extends State<PropertyPerformanceScreen> {
  bool _isLoading = false;
  List<Property> _properties = [];
  Map<String, PropertyMetrics> _propertyMetrics = {};
  String _selectedProperty = '';
  String _selectedTimeRange = '6months';
  List<Map<String, dynamic>> _monthlyPerformance = [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      _properties = await propertyProvider.fetchProperties();

      if (_properties.isNotEmpty) {
        _selectedProperty = _properties.first.id;
        await _loadPropertyMetrics();
      }
    } catch (e) {
      showErrorDialog(context, 'Error loading properties: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPropertyMetrics() async {
    if (_selectedProperty.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);

      final now = DateTime.now();
      DateTime startDate;
      switch (_selectedTimeRange) {
        case '3months':
          startDate = DateTime(now.year, now.month - 3);
          break;
        case '6months':
          startDate = DateTime(now.year, now.month - 6);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month);
          break;
        default:
          startDate = DateTime(now.year, now.month - 6);
      }

      // Calculate metrics
      final payments =
          await paymentProvider.fetchPaymentsByPropertyId(_selectedProperty);
      final filteredPayments =
          payments.where((p) => p.paymentDate.isAfter(startDate)).toList();

      final totalRevenue = filteredPayments.fold<double>(
          0, (sum, payment) => sum + payment.amount);

      final monthsDiff = now.difference(startDate).inDays / 30;
      final averageMonthlyRevenue = totalRevenue / monthsDiff;

      final occupancyRate = await reportProvider.getPropertyOccupancyRate(
        _selectedProperty,
        startDate,
        now,
      );

      final maintenanceCost = await reportProvider.getPropertyMaintenanceCost(
        _selectedProperty,
        startDate,
        now,
      );

      final netIncome = totalRevenue - maintenanceCost;

      final vacancyData = await reportProvider.getPropertyVacancyData(
        _selectedProperty,
        startDate,
        now,
      );

      final tenancyData = await reportProvider.getPropertyTenancyData(
        _selectedProperty,
        startDate,
        now,
      );

      _propertyMetrics[_selectedProperty] = PropertyMetrics(
        totalRevenue: totalRevenue,
        averageMonthlyRevenue: averageMonthlyRevenue,
        occupancyRate: occupancyRate,
        maintenanceCost: maintenanceCost,
        netIncome: netIncome,
        totalDaysVacant: vacancyData['totalDays'] ?? 0,
        averageTenancyDuration: tenancyData['averageDuration'] ?? 0,
        returnOnInvestment: (netIncome / maintenanceCost) * 100,
      );

      // Calculate monthly performance
      _monthlyPerformance = [];
      DateTime current = startDate;
      while (current.isBefore(now)) {
        final monthPayments = filteredPayments
            .where((p) =>
                p.paymentDate.year == current.year &&
                p.paymentDate.month == current.month)
            .toList();

        final monthRevenue =
            monthPayments.fold<double>(0, (sum, p) => sum + p.amount);

        final monthMaintenance =
            await reportProvider.getPropertyMaintenanceCost(
          _selectedProperty,
          DateTime(current.year, current.month, 1),
          DateTime(current.year, current.month + 1, 0),
        );

        _monthlyPerformance.add({
          'date': current,
          'revenue': monthRevenue,
          'maintenance': monthMaintenance,
          'net': monthRevenue - monthMaintenance,
        });

        current = DateTime(current.year, current.month + 1);
      }
    } catch (e) {
      showErrorDialog(context, 'Error loading property metrics: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPerformanceMetrics() {
    if (_selectedProperty.isEmpty) return Container();

    final metrics = _propertyMetrics[_selectedProperty];
    if (metrics == null) return Container();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  'Total Revenue',
                  CurrencyUtils.formatCurrency(metrics.totalRevenue),
                  Icons.monetization_on,
                  Colors.green,
                ),
                _buildMetricItem(
                  'Net Income',
                  CurrencyUtils.formatCurrency(metrics.netIncome),
                  Icons.account_balance,
                  Theme.of(context).primaryColor,
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  'Occupancy Rate',
                  '${(metrics.occupancyRate * 100).toStringAsFixed(1)}%',
                  Icons.home,
                  Colors.blue,
                ),
                _buildMetricItem(
                  'Maintenance Cost',
                  CurrencyUtils.formatCurrency(metrics.maintenanceCost),
                  Icons.build,
                  Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  'Vacant Days',
                  metrics.totalDaysVacant.toString(),
                  Icons.hotel,
                  Colors.red,
                ),
                _buildMetricItem(
                  'ROI',
                  '${metrics.returnOnInvestment.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildPerformanceChart() {
    if (_monthlyPerformance.isEmpty) return Container();

    final revenueSpots = _monthlyPerformance.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value['revenue'] as double,
      );
    }).toList();

    final maintenanceSpots = _monthlyPerformance.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value['maintenance'] as double,
      );
    }).toList();

    final netSpots = _monthlyPerformance.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value['net'] as double,
      );
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Performance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                              CurrencyUtils.formatCompactCurrency(value));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < _monthlyPerformance.length) {
                            return Text(
                              DateFormat('MMM').format(
                                  _monthlyPerformance[value.toInt()]['date']),
                              style: TextStyle(fontSize: 10),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: revenueSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: maintenanceSpots,
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: netSpots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegend('Revenue', Colors.green),
                SizedBox(width: 16),
                _buildChartLegend('Maintenance', Colors.orange),
                SizedBox(width: 16),
                _buildChartLegend('Net Income', Theme.of(context).primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Performance'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedTimeRange = value);
              _loadPropertyMetrics();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: '3months', child: Text('Last 3 Months')),
              PopupMenuItem(value: '6months', child: Text('Last 6 Months')),
              PopupMenuItem(value: 'year', child: Text('Last Year')),
            ],
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: RefreshIndicator(
          onRefresh: _loadPropertyMetrics,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_properties.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedProperty,
                    decoration: InputDecoration(
                      labelText: 'Select Property',
                      border: OutlineInputBorder(),
                    ),
                    items: _properties.map((property) {
                      return DropdownMenuItem<String>(
                        value: property.id,
                        child: Text(property.address),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedProperty = value);
                        _loadPropertyMetrics();
                      }
                    },
                  ),
                  SizedBox(height: 24),
                ],
                _buildPerformanceMetrics(),
                SizedBox(height: 24),
                _buildPerformanceChart(),
                SizedBox(height: 24),
                _buildPerformanceDetails(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceDetails() {
    if (_selectedProperty.isEmpty) return Container();

    final metrics = _propertyMetrics[_selectedProperty];
    if (metrics == null) return Container();

    final selectedPropertyData =
        _properties.firstWhere((p) => p.id == _selectedProperty);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Average Monthly Revenue'),
              trailing: Text(
                CurrencyUtils.formatCurrency(metrics.averageMonthlyRevenue),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Average Tenancy Duration'),
              trailing: Text(
                '${metrics.averageTenancyDuration} days',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Maintenance Cost Ratio'),
              trailing: Text(
                '${((metrics.maintenanceCost / metrics.totalRevenue) * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Current Rent Amount'),
              trailing: Text(
                CurrencyUtils.formatCurrency(
                    selectedPropertyData.currentRentAmount),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Property Status'),
              trailing: Chip(
                label: Text(
                  selectedPropertyData.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(selectedPropertyData.status),
                  ),
                ),
                backgroundColor: _getStatusColor(selectedPropertyData.status)
                    .withOpacity(0.1),
              ),
            ),
            if (selectedPropertyData.description?.isNotEmpty ?? false) ...[
              Divider(),
              ListTile(
                title: Text('Property Description'),
                subtitle: Text(selectedPropertyData.description!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'occupied':
        return Colors.green;
      case 'vacant':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Extension methods to help with calculations
extension DateTimeExtension on DateTime {
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }
}

extension IterableExtension<T> on Iterable<T> {
  double averageBy(num Function(T element) selector) {
    if (isEmpty) return 0;
    return map(selector).reduce((a, b) => a + b) / length;
  }
}
