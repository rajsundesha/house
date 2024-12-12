import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/presentation/providers/report_provider.dart';
// import 'package:house_rental_app/presentation/shared/widgets/custom_components.dart';
import 'package:house_rental_app/data/models/property.dart';

class OccupancyReportScreen extends StatefulWidget {
  @override
  _OccupancyReportScreenState createState() => _OccupancyReportScreenState();
}

// class _OccupancyReportScreenState extends State<OccupancyReportScreen> {
//   bool _isLoading = false;
//   double _overallOccupancyRate = 0.0;
//   List<Property> _properties = [];
//   Map<String, int> _statusDistribution = {};
//   List<Map<String, dynamic>> _monthlyOccupancy = [];
//   String _selectedTimeRange = '6months';
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _loadOccupancyData();
//   }

class _OccupancyReportScreenState extends State<OccupancyReportScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Property> _properties = [];
  Map<String, int> _statusDistribution = {};
  double _overallOccupancyRate = 0.0;
  List<Map<String, dynamic>> _monthlyOccupancy = [];
  String _selectedTimeRange = '6months';

  Future<void> _loadOccupancyData() async {
    setState(() => _isLoading = true);
    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);

      // Fetch properties and store the returned list
      _properties = await propertyProvider.fetchProperties();

      // Get overall occupancy rate
      _overallOccupancyRate = await reportProvider.getOccupancyRate();

      // Calculate monthly occupancy rates
      final now = DateTime.now();
      _monthlyOccupancy = [];

      int monthsToLoad = 6;
      switch (_selectedTimeRange) {
        case '3months':
          monthsToLoad = 3;
          break;
        case '6months':
          monthsToLoad = 6;
          break;
        case 'year':
          monthsToLoad = 12;
          break;
      }

      for (int i = monthsToLoad - 1; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i);
        final rate = await reportProvider.getOccupancyRateForMonth(
          month.year,
          month.month,
        );
        _monthlyOccupancy.add({
          'date': month,
          'rate': rate,
        });
      }

      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      showErrorDialog(context, 'Error loading occupancy data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildOccupancyOverview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Occupancy Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOccupancyIndicator(
                  'Overall Rate',
                  '${(_overallOccupancyRate * 100).toStringAsFixed(1)}%',
                  Theme.of(context).primaryColor,
                ),
                _buildOccupancyIndicator(
                  'Total Properties',
                  _properties.length.toString(),
                  Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOccupancyIndicator(
                  'Occupied',
                  _statusDistribution['occupied']?.toString() ?? '0',
                  Colors.green,
                ),
                _buildOccupancyIndicator(
                  'Vacant',
                  _statusDistribution['vacant']?.toString() ?? '0',
                  Colors.red,
                ),
                _buildOccupancyIndicator(
                  'Maintenance',
                  _statusDistribution['maintenance']?.toString() ?? '0',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }

  Widget _buildOccupancyTrend() {
    if (_monthlyOccupancy.isEmpty) return Container();

    final spots = _monthlyOccupancy.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['rate'] as double) * 100,
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
              'Occupancy Trend',
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < _monthlyOccupancy.length) {
                            return Text(
                              DateFormat('MMM').format(
                                  _monthlyOccupancy[value.toInt()]['date']),
                              style: TextStyle(fontSize: 10),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 100,
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

  Widget _buildPropertyList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _properties.length,
              itemBuilder: (context, index) {
                final property = _properties[index];
                return ListTile(
                  title: Text(property.address),
                  subtitle: Text(property.size),
                  trailing: Chip(
                    label: Text(
                      property.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(property.status),
                      ),
                    ),
                    backgroundColor:
                        _getStatusColor(property.status).withOpacity(0.1),
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/property_detail',
                    arguments: property,
                  ),
                );
              },
            ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Occupancy Report'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedTimeRange = value);
              _loadOccupancyData();
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
          onRefresh: _loadOccupancyData,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOccupancyOverview(),
                SizedBox(height: 24),
                _buildOccupancyTrend(),
                SizedBox(height: 24),
                _buildPropertyList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
