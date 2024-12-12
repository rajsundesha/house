import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:house_rental_app/presentation/providers/payment_provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/presentation/providers/report_provider.dart';
// import 'package:house_rental_app/presentation/shared/widgets/custom_components.dart';
import 'package:house_rental_app/utils/currency_utils.dart';

class RevenueReportScreen extends StatefulWidget {
  @override
  _RevenueReportScreenState createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  bool _isLoading = false;
  String _selectedTimeRange =
      '6months'; // 'month', '3months', '6months', 'year', 'custom'
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic> _revenueData = {};
  List<Map<String, dynamic>> _monthlyRevenue = [];

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    setState(() => _isLoading = true);
    try {
      final DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate =
          DateTime(now.year, now.month + 1, 0); // End of current month

      switch (_selectedTimeRange) {
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case '3months':
          startDate = DateTime(now.year, now.month - 2, 1);
          break;
        case '6months':
          startDate = DateTime(now.year, now.month - 5, 1);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month + 1, 1);
          break;
        case 'custom':
          if (_startDate == null || _endDate == null) return;
          startDate = _startDate!;
          endDate = _endDate!;
          break;
        default:
          startDate = DateTime(now.year, now.month - 5, 1);
      }

      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      final properties = await propertyProvider.fetchProperties();
      final propertyIds = properties.map((p) => p.id).toList();

      // Load monthly revenue data
      _monthlyRevenue = [];
      DateTime current = startDate;
      while (current.isBefore(endDate)) {
        final revenue =
            await Provider.of<ReportProvider>(context, listen: false)
                .getMonthlyRevenue(current.year, current.month, propertyIds);

        _monthlyRevenue.add({
          'date': current,
          'revenue': revenue,
        });

        current = DateTime(current.year, current.month + 1, 1);
      }

      // Calculate summary data
      final totalRevenue = _monthlyRevenue.fold<double>(
          0, (sum, item) => sum + (item['revenue'] as double));

      final averageRevenue = totalRevenue / _monthlyRevenue.length;

      final maxRevenue = _monthlyRevenue.isEmpty
          ? 0.0
          : _monthlyRevenue
              .map((item) => item['revenue'] as double)
              .reduce((a, b) => a > b ? a : b);

      final minRevenue = _monthlyRevenue.isEmpty
          ? 0.0
          : _monthlyRevenue
              .map((item) => item['revenue'] as double)
              .reduce((a, b) => a < b ? a : b);

      setState(() {
        _revenueData = {
          'totalRevenue': totalRevenue,
          'averageRevenue': averageRevenue,
          'maxRevenue': maxRevenue,
          'minRevenue': minRevenue,
        };
      });
    } catch (e) {
      showErrorDialog(context, 'Error loading revenue data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedTimeRange = 'custom';
      });
      _loadRevenueData();
    }
  }

  Widget _buildRevenueChart() {
    if (_monthlyRevenue.isEmpty) return Container();

    final spots = _monthlyRevenue.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value['revenue'] as double,
      );
    }).toList();

    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue Trend',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
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
                                value.toInt() < _monthlyRevenue.length) {
                              return Text(
                                DateFormat('MMM').format(
                                    _monthlyRevenue[value.toInt()]['date']),
                                style: TextStyle(fontSize: 10),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
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
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Revenue',
                    CurrencyUtils.formatCurrency(
                        _revenueData['totalRevenue'] ?? 0),
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Average Revenue',
                    CurrencyUtils.formatCurrency(
                        _revenueData['averageRevenue'] ?? 0),
                    Icons.show_chart,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Highest Revenue',
                    CurrencyUtils.formatCurrency(
                        _revenueData['maxRevenue'] ?? 0),
                    Icons.arrow_upward,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Lowest Revenue',
                    CurrencyUtils.formatCurrency(
                        _revenueData['minRevenue'] ?? 0),
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revenue Report'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
                _startDate = null;
                _endDate = null;
              });
              _loadRevenueData();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'month', child: Text('This Month')),
              PopupMenuItem(value: '3months', child: Text('Last 3 Months')),
              PopupMenuItem(value: '6months', child: Text('Last 6 Months')),
              PopupMenuItem(value: 'year', child: Text('Last Year')),
            ],
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRevenueSummary(),
              SizedBox(height: 24),
              _buildRevenueChart(),
              SizedBox(height: 24),
              // Add more sections like monthly breakdown, property-wise revenue, etc.
            ],
          ),
        ),
      ),
    );
  }
}
