
import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/data/models/tenant.dart';
import 'package:house_rental_app/data/models/payment.dart';
import 'package:house_rental_app/presentation/providers/payment_provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';

import 'package:house_rental_app/utils/currency_utils.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TenantPaymentHistoryScreen extends StatefulWidget {
  final Tenant tenant;

  TenantPaymentHistoryScreen({required this.tenant});

  @override
  _TenantPaymentHistoryScreenState createState() =>
      _TenantPaymentHistoryScreenState();
}

class _TenantPaymentHistoryScreenState extends State<TenantPaymentHistoryScreen> {
  bool _isLoading = false;
  List<Payment> _payments = [];
  String _selectedFilter = 'all'; // 'all', 'completed', 'pending'
  String _selectedTimeRange = '6months'; // '3months', '6months', '1year', 'all'
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final payments = await Provider.of<PaymentProvider>(context, listen: false)
          .fetchPaymentsByTenantId(widget.tenant.id);

      // Apply filters
      _payments = payments.where((payment) {
        bool matchesStatus = _selectedFilter == 'all' ||
            payment.paymentStatus.toLowerCase() == _selectedFilter;

        bool matchesTimeRange = true;
        if (_startDate != null && _endDate != null) {
          matchesTimeRange = payment.paymentDate.isAfter(_startDate!) &&
              payment.paymentDate.isBefore(_endDate!);
        } else {
          switch (_selectedTimeRange) {
            case '3months':
              matchesTimeRange = payment.paymentDate
                  .isAfter(DateTime.now().subtract(Duration(days: 90)));
              break;
            case '6months':
              matchesTimeRange = payment.paymentDate
                  .isAfter(DateTime.now().subtract(Duration(days: 180)));
              break;
            case '1year':
              matchesTimeRange = payment.paymentDate
                  .isAfter(DateTime.now().subtract(Duration(days: 365)));
              break;
          }
        }

        return matchesStatus && matchesTimeRange;
      }).toList();

      // Sort by date
      _payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    } catch (e) {
      showErrorDialog(context, 'Error loading payments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPaymentTrends() {
    if (_payments.isEmpty) return Container();

    // Group payments by month
    final monthlyTotals = <DateTime, double>{};
    for (var payment in _payments) {
      final date = DateTime(payment.paymentDate.year, payment.paymentDate.month);
      monthlyTotals[date] = (monthlyTotals[date] ?? 0) + payment.amount;
    }

    final sortedEntries = monthlyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries
        .asMap()
        .entries
        .map((entry) =>
            FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
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
                      value.toInt() < sortedEntries.length) {
                    return Text(
                      DateFormat('MMM')
                          .format(sortedEntries[value.toInt()].key),
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
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatistics() {
    final totalPaid = _payments
        .where((p) => p.paymentStatus.toLowerCase() == 'completed')
        .fold(0.0, (sum, payment) => sum + payment.amount);

    final pendingAmount = _payments
        .where((p) => p.paymentStatus.toLowerCase() == 'pending')
        .fold(0.0, (sum, payment) => sum + payment.amount);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Statistics',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Paid',
                    CurrencyUtils.formatCurrency(totalPaid),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    CurrencyUtils.formatCurrency(pendingAmount),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) => Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Filter Payments',
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedFilter,
                          decoration: InputDecoration(
                            labelText: 'Payment Status',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'all', child: Text('All')),
                            DropdownMenuItem(
                                value: 'completed',
                                child: Text('Completed')),
                            DropdownMenuItem(
                                value: 'pending', child: Text('Pending')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedFilter = value!);
                          },
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedTimeRange,
                          decoration: InputDecoration(
                            labelText: 'Time Range',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'all', child: Text('All Time')),
                            DropdownMenuItem(
                                value: '3months',
                                child: Text('Last 3 Months')),
                            DropdownMenuItem(
                                value: '6months',
                                child: Text('Last 6 Months')),
                            DropdownMenuItem(
                                value: '1year', child: Text('Last Year')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedTimeRange = value!);
                          },
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _loadPayments();
                          },
                          child: Text('Apply Filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _payments.isEmpty
            ? Center(
                child: Text('No payment history available'),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPaymentTrends(),
                    SizedBox(height: 16),
                    _buildPaymentStatistics(),
                    SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        final payment = _payments[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: payment.paymentStatus
                                          .toLowerCase() ==
                                      'completed'
                                  ? Colors.green
                                  : Colors.orange,
                              child: Icon(
                                payment.paymentStatus.toLowerCase() ==
                                        'completed'
                                    ? Icons.check
                                    : Icons.pending,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              CurrencyUtils.formatCurrency(payment.amount),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              DateFormat('MMM d, y')
                                  .format(payment.paymentDate),
                            ),
                            trailing: Chip(
                              label: Text(
                                payment.paymentStatus.toUpperCase(),
                                style: TextStyle(
                                  color: payment.paymentStatus
                                              .toLowerCase() ==
                                          'completed'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              backgroundColor: payment.paymentStatus
                                          .toLowerCase() ==
                                      'completed'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                            ),
                            onTap: () {
                              // Navigate to payment details
                              Navigator.pushNamed(
                                context,
                                '/payment_detail',
                                arguments: payment,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
