import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/utils/currency_utils.dart';

class MaintenanceReportScreen extends StatefulWidget {
  @override
  _MaintenanceReportScreenState createState() =>
      _MaintenanceReportScreenState();
}

class _MaintenanceReportScreenState extends State<MaintenanceReportScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _selectedTimeRange = '6months';
  List<MaintenanceRecord> _maintenanceRecords = [];
  Map<String, double> _costByStatus = {};
  Map<String, int> _countByStatus = {};
  List<Map<String, dynamic>> _monthlyCosts = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMaintenanceData();
  }

  Future<void> _loadMaintenanceData() async {
    setState(() => _isLoading = true);
    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      // First fetch properties
      await propertyProvider.fetchProperties();
      final List<Property> properties = propertyProvider.properties;

      // Clear existing maintenance records
      _maintenanceRecords = [];

      // Only proceed if we have properties
      if (properties.isNotEmpty) {
        // Collect all maintenance records
        for (var property in properties) {
          if (property.maintenanceRecords.isNotEmpty) {
            _maintenanceRecords.addAll(property.maintenanceRecords);
          }
        }

        // Filter by time range
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

        _maintenanceRecords = _maintenanceRecords
            .where((record) => record.date.isAfter(startDate))
            .toList();

        // Calculate costs by status
        _costByStatus = {
          'pending': 0,
          'in_progress': 0,
          'completed': 0,
        };
        _countByStatus = {
          'pending': 0,
          'in_progress': 0,
          'completed': 0,
        };

        for (var record in _maintenanceRecords) {
          _costByStatus[record.status] =
              (_costByStatus[record.status] ?? 0) + record.cost;
          _countByStatus[record.status] =
              (_countByStatus[record.status] ?? 0) + 1;
        }

        // Calculate monthly costs
        _monthlyCosts = [];
        var monthlyData = <DateTime, double>{};
        for (var record in _maintenanceRecords) {
          final month = DateTime(record.date.year, record.date.month);
          monthlyData[month] = (monthlyData[month] ?? 0) + record.cost;
        }

        _monthlyCosts = monthlyData.entries
            .map((e) => {'date': e.key, 'cost': e.value})
            .toList()
          ..sort((a, b) =>
              (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      }
    } catch (e) {
      showErrorDialog(context, 'Error loading maintenance data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
    

  Widget _buildMaintenanceSummary() {
    final totalCost = _costByStatus.values.fold(0.0, (a, b) => a + b);
    final totalCount = _countByStatus.values.fold(0, (a, b) => a + b);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Cost',
                  CurrencyUtils.formatCurrency(totalCost),
                  Icons.monetization_on,
                  Theme.of(context).primaryColor,
                ),
                _buildSummaryItem(
                  'Total Records',
                  totalCount.toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Pending',
                  _countByStatus['pending'].toString(),
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'In Progress',
                  _countByStatus['in_progress'].toString(),
                  Icons.trending_up,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Completed',
                  _countByStatus['completed'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
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

  Widget _buildCostTrend() {
    if (_monthlyCosts.isEmpty) return Container();

    final spots = _monthlyCosts.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value['cost'] as double,
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
              'Maintenance Cost Trend',
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
                          return Text(CurrencyUtils.formatCompactCurrency(value));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < _monthlyCosts.length) {
                            return Text(
                              DateFormat('MMM')
                                  .format(_monthlyCosts[value.toInt()]['date']),
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
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceRecordsList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Completed'),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecordsList(_maintenanceRecords),
                _buildRecordsList(_maintenanceRecords
                    .where((r) => r.status == 'pending')
                    .toList()),
                _buildRecordsList(_maintenanceRecords
                    .where((r) => r.status == 'completed')
                    .toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<MaintenanceRecord> records) {
    if (records.isEmpty) {
      return Center(child: Text('No records found'));
    }

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return ListTile(
          title: Text(record.title),
          subtitle: Text(
            '${record.description}\n${DateFormat('MMM d, y').format(record.date)}',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.formatCurrency(record.cost),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Chip(
                label: Text(
                  record.status.toUpperCase(),
                  style: TextStyle(fontSize: 10),
                ),
                backgroundColor: _getStatusColor(record.status).withOpacity(0.1),
                labelStyle: TextStyle(color: _getStatusColor(record.status)),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maintenance Report'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedTimeRange = value);
              _loadMaintenanceData();
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
          onRefresh: _loadMaintenanceData,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMaintenanceSummary(),
                SizedBox(height: 24),
                _buildCostTrend(),
                SizedBox(height: 24),
                _buildMaintenanceRecordsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
